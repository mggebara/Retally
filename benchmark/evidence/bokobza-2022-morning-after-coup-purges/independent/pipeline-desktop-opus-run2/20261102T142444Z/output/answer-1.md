suppressPackageStartupMessages({
  library(fixest)
  library(data.table)
  library(haven)
})
set.seed(42)

base <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"

results <- list()
setres <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) return(invisible(NULL))
  results[[name]] <<- as.numeric(val)
}

## ---------------- helpers ----------------
to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) return(as.character(haven::as_factor(x)))
  if (is.factor(x)) return(as.character(x))
  as.character(x)
}
to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}
is_lagname <- function(n, all) {
  b <- sub("^l_?", "", n)
  (grepl("^l", n) && b != n && b %in% all) || grepl("lag", n, ignore.case = TRUE)
}
pick_var <- function(df, inc, exc = NULL, prefer = NULL) {
  cands <- names(df)[grepl(inc, names(df), ignore.case = TRUE)]
  if (!is.null(exc)) cands <- cands[!grepl(exc, cands, ignore.case = TRUE)]
  cands <- cands[vapply(cands, function(v) {
    x <- to_num(df[[v]]); sum(!is.na(x)) > 0
  }, logical(1))]
  if (!length(cands)) return(NULL)
  sc <- vapply(cands, function(v) {
    s <- 0
    if (is_lagname(v, names(df))) s <- s + 10
    if (!is.null(prefer)) for (p in prefer) if (grepl(p, v, ignore.case = TRUE)) s <- s + 1
    s - nchar(v) / 1000
  }, numeric(1))
  v <- cands[which.max(sc)]
  list(name = v, lagged = is_lagname(v, names(df)))
}
panel_lag <- function(id, t, x) {
  o <- order(id, t)
  idv <- id[o]; tv <- t[o]; xv <- x[o]
  n <- length(xv)
  prev <- c(NA, xv[-n])
  ok <- c(FALSE, !is.na(idv[-1]) & !is.na(idv[-n]) & idv[-1] == idv[-n] &
            !is.na(tv[-1]) & !is.na(tv[-n]) & tv[-1] == tv[-n] + 1)
  prev[!ok] <- NA
  res <- rep(NA_real_, n)
  res[o] <- prev
  res
}
maybe_log <- function(x, thr) {
  x <- to_num(x)
  if (all(is.na(x))) return(x)
  if (max(x, na.rm = TRUE) > thr) { x[x <= 0] <- NA; x <- log(x) }
  x
}
getcoef <- function(m, nm) {
  if (is.null(m)) return(NA)
  cf <- coef(m)
  if (nm %in% names(cf)) unname(cf[nm]) else NA
}

## ---------------- country-level ----------------
cl <- as.data.table(haven::zap_labels(haven::read_dta(file.path(base, "morning_after_dataset_countrylevel.dta"))))
cn <- names(cl)
cat("Country-level columns:", paste(cn, collapse = ", "), "\n")

cl[, cid := COUNTRY_ID]
cl[, yr := to_num(YEAR_DATA)]

# outcome
if ("replacement_rateadj_minister" %in% cn) {
  cl[, yvar := to_num(replacement_rateadj_minister)]
} else {
  rv <- grep("retention_rate_adj_minister|retention_rateadj_minister", cn, value = TRUE)[1]
  cl[, yvar := 1 - to_num(get(rv))]
}
if (max(cl$yvar, na.rm = TRUE) > 1.5) cl[, yvar := yvar / 100]

# failed coup attempt
cc <- cn[grepl("^coupattempt", cn, ignore.case = TRUE)]
cc <- cc[!grepl("month|_br|type|lag|bjorn|_l$", cc, ignore.case = TRUE)]
if (!length(cc)) cc <- cn[grepl("coupattempt", cn, ignore.case = TRUE) & !grepl("month|lag", cn, ignore.case = TRUE)]
pref <- cc[grepl("whogov", cc, ignore.case = TRUE)]
coupvar <- if (length(pref)) pref[which.min(nchar(pref))] else cc[which.min(nchar(cc))]
cat("Country coup var:", coupvar, "\n")
cl[, fca := to_num(get(coupvar))]
cl[, fca := as.numeric(fca > 0)]

# autocracy (lagged BMR = 0)
if ("ldemocracy_br" %in% cn) {
  cl[, ldem := to_num(ldemocracy_br)]
} else {
  cl[, ldem := panel_lag(cid, yr, to_num(democracy_br))]
}

# controls: GDP pc, population (lagged logs)
gv <- pick_var(cl, "gdp", "grow|growth", prefer = c("ln|log", "pc|cap"))
pv <- pick_var(cl, "pop", "oil|valuepop", prefer = c("ln|log"))
cat("Country GDP var:", gv$name, " lagged:", gv$lagged, "\n")
cat("Country pop var:", pv$name, " lagged:", pv$lagged, "\n")
cl[, gdp0 := maybe_log(get(gv$name), 30)]
cl[, pop0 := maybe_log(get(pv$name), 30)]
cl[, lgdp := if (gv$lagged) gdp0 else panel_lag(cid, yr, gdp0)]
cl[, lpop := if (pv$lagged) pop0 else panel_lag(cid, yr, pop0)]

for (b in c("military_c", "monarchy_c", "party_c")) {
  lb <- paste0("l", b)
  if (lb %in% cn) {
    cl[, (paste0("L_", b)) := to_num(get(lb))]
  } else if (b %in% cn) {
    cl[, (paste0("L_", b)) := panel_lag(cid, yr, to_num(get(b)))]
  } else {
    cl[, (paste0("L_", b)) := NA_real_]
  }
}

cs <- cl[!is.na(ldem) & ldem == 0 & yr >= 1967 & yr <= 2016 & !is.na(yvar)]
if (mean(is.na(cs$fca)) > 0.2) cs[is.na(fca), fca := 0]
cat("Country-level autocracy sample N:", nrow(cs), " coups:", sum(cs$fca, na.rm = TRUE), "\n")

run <- function(fml, data, cl_var) {
  tryCatch(feols(fml, data = data, cluster = cl_var, warn = FALSE, notes = FALSE),
           error = function(e) { cat("Model error:", conditionMessage(e), "\n"); NULL })
}

m_base_c <- run(yvar ~ fca + lgdp + lpop | cid + yr, cs, ~cid)
m_main_c <- run(yvar ~ fca + lgdp + lpop + L_military_c + L_monarchy_c + L_party_c | cid + yr, cs, ~cid)
if ("leader_cab_id" %in% cn) {
  m_base_l <- run(yvar ~ fca + lgdp + lpop | leader_cab_id + yr, cs, ~cid)
  m_main_l <- run(yvar ~ fca + lgdp + lpop + L_military_c + L_monarchy_c + L_party_c | leader_cab_id + yr, cs, ~cid)
} else {
  m_base_l <- NULL; m_main_l <- NULL
}
for (m in list(m_base_c, m_main_c, m_base_l, m_main_l)) if (!is.null(m)) print(summary(m))

setres("failed_coup_base_country_fe", getcoef(m_base_c, "fca"))
setres("failed_coup_main_country_fe", getcoef(m_main_c, "fca"))
setres("failed_coup_base_leader_fe", getcoef(m_base_l, "fca"))
setres("failed_coup_main_leader_fe", getcoef(m_main_l, "fca"))

## ---------------- individual-level ----------------
ind <- tryCatch(as.data.table(readRDS(file.path(base, "morning_after_dataset_individuallevel.rds"))),
                error = function(e) NULL)

if (!is.null(ind)) {
  inn <- names(ind)
  cat("Individual-level columns:", paste(inn, collapse = ", "), "\n")
  ind[, yr := to_num(year)]
  ind[, cty := to_chr(country_isocode)]
  ind[, purged := to_num(purged_y1)]
  if (all(is.na(ind$purged))) {
    pc <- to_chr(ind$purged_y1)
    ind[, purged := as.numeric(grepl("^(1|yes|purged|true)$", tolower(pc)))]
  }
  ind[, fca := as.numeric(to_num(coupattempt_presentyear) > 0)]
  ind[, dlag := to_num(democracy_lag_br)]
  ind[, expv := to_num(experience)]

  # leader exclusion
  is_leader <- rep(FALSE, nrow(ind))
  if ("leader" %in% inn) {
    lv <- ind$leader
    lnum <- to_num(lv)
    if (!all(is.na(lnum)) && all(na.omit(unique(lnum)) %in% c(0, 1))) {
      is_leader <- !is.na(lnum) & lnum == 1
    } else if ("name" %in% inn) {
      is_leader <- !is.na(to_chr(lv)) & to_chr(lv) == to_chr(ind$name)
    }
  }
  if ("position" %in% inn) {
    pos <- tolower(to_chr(ind$position))
    is_leader <- is_leader | (!is.na(pos) & grepl("^leader$", pos))
  }
  ind[, is_leader := is_leader]
  cat("Leader rows flagged:", sum(is_leader), "\n")

  # GDP / population lagged logs
  gvi <- pick_var(ind, "gdp", "grow|growth", prefer = c("ln|log", "pc|cap"))
  pvi <- pick_var(ind, "pop", "oil|valuepop", prefer = c("ln|log"))
  have_ctrl <- FALSE
  if (!is.null(gvi) && !is.null(pvi)) {
    cat("Indiv GDP var:", gvi$name, gvi$lagged, " pop var:", pvi$name, pvi$lagged, "\n")
    ind[, g0 := maybe_log(get(gvi$name), 30)]
    ind[, p0 := maybe_log(get(pvi$name), 30)]
    cy <- ind[!is.na(cty) & !is.na(yr), .(g0 = g0[!is.na(g0)][1], p0 = p0[!is.na(p0)][1]), by = .(cty, yr)]
    cy[, lg := if (gvi$lagged) g0 else panel_lag(cty, yr, g0)]
    cy[, lp := if (pvi$lagged) p0 else panel_lag(cty, yr, p0)]
    ind <- merge(ind, cy[, .(cty, yr, lgdp = lg, lpop = lp)], by = c("cty", "yr"), all.x = TRUE)
    have_ctrl <- sum(!is.na(ind$lgdp)) > 0
  }
  if (!have_ctrl) {
    # merge from country-level data using the best-overlapping key
    uc <- unique(na.omit(ind$cty)); un <- if ("country_name" %in% inn) unique(na.omit(to_chr(ind$country_name))) else character(0)
    best <- NULL; bestov <- 0; bestsrc <- NULL
    for (v in cn) {
      vals <- unique(na.omit(to_chr(cl[[v]])))
      ov1 <- sum(uc %in% vals); ov2 <- sum(un %in% vals)
      if (ov1 > bestov) { bestov <- ov1; best <- v; bestsrc <- "cty" }
      if (ov2 > bestov) { bestov <- ov2; best <- v; bestsrc <- "country_name" }
    }
    cat("Merge key:", best, bestsrc, bestov, "\n")
    if (!is.null(best)) {
      cm <- cl[, .(key = to_chr(get(best)), yr, lgdp, lpop)]
      cm <- cm[, .(lgdp = lgdp[1], lpop = lpop[1]), by = .(key, yr)]
      ind[, key := if (bestsrc == "cty") cty else to_chr(country_name)]
      ind <- merge(ind, cm, by = c("key", "yr"), all.x = TRUE)
    } else {
      ind[, lgdp := NA_real_]; ind[, lpop := NA_real_]
    }
  }

  # importance tiers (needed also for junior exclusion)
  map_prest <- function(x) {
    x <- tolower(x); out <- rep(NA_character_, length(x))
    out[grepl("prime|president|^pm|pm$|head", x)] <- "PMPres"
    out[grepl("vice|deputy|vp|top|high", x)] <- "Top"
    out[grepl("medium|middle|mid", x)] <- "Medium"
    out[grepl("low", x)] <- "Low"
    out[grepl("junior", x)] <- "Junior"
    out
  }
  ind[, prest := if ("prestige_1" %in% inn) map_prest(to_chr(prestige_1)) else NA_character_]
  cat("Prestige mapping:\n"); if ("prestige_1" %in% inn) print(table(to_chr(ind$prestige_1), ind$prest, useNA = "ifany"))

  s <- ind[!is.na(dlag) & dlag == 0 & yr >= 1967 & yr <= 2016 & !is_leader & !is.na(purged)]
  cat("Individual sample N:", nrow(s), "\n")
  s[, t1 := expv]; s[, t2 := expv^2]; s[, t3 := expv^3]

  run_inter <- function(d, grp, ref, poly = TRUE) {
    d <- d[!is.na(get(grp))]
    lv <- sort(unique(d[[grp]]))
    lv <- setdiff(lv, ref)
    terms <- c("fca")
    nmap <- list()
    for (i in seq_along(lv)) {
      dn <- paste0("D", i); xn <- paste0("FX", i)
      d[, (dn) := as.numeric(get(grp) == lv[i])]
      d[, (xn) := fca * get(dn)]
      terms <- c(terms, dn, xn)
      nmap[[lv[i]]] <- xn
    }
    ctrl <- c("lgdp", "lpop")
    if (poly) ctrl <- c(ctrl, "t1", "t2", "t3")
    f <- as.formula(paste("purged ~", paste(c(terms, ctrl), collapse = " + "), "| cty + yr"))
    m <- run(f, d, ~cty)
    if (!is.null(m)) print(summary(m))
    list(m = m, map = nmap)
  }

  ## H2a: experience
  eg <- if ("experience_group" %in% inn) to_chr(s$experience_group) else rep(NA_character_, nrow(s))
  map_exp <- function(x) {
    x <- tolower(x); out <- rep(NA_character_, length(x))
    out[grepl("<\\s*2|less|under|0\\s*-\\s*1|^0|^1$|1 year", x)] <- "E1"
    out[grepl("2\\s*-\\s*3|2 to 3", x)] <- "E2"
    out[grepl("4\\s*-\\s*6|4 to 6", x)] <- "E3"
    out[grepl(">\\s*6|over|more|7|above", x)] <- "E4"
    out
  }
  s[, eg2 := map_exp(eg)]
  if (sum(!is.na(s$eg2)) < 0.5 * nrow(s) || length(unique(na.omit(s$eg2))) < 4) {
    cat("Constructing experience groups from 'experience'\n")
    s[, eg2 := fifelse(expv < 2, "E1", fifelse(expv <= 3, "E2", fifelse(expv <= 6, "E3", "E4")))]
  }
  print(table(eg, s$eg2, useNA = "ifany"))
  se <- s[is.na(prest) | prest != "Junior"]
  r_exp <- run_inter(se, "eg2", "E1", poly = FALSE)
  setres("failed_coup_experience_model", getcoef(r_exp$m, "fca"))
  if (!is.null(r_exp$map[["E4"]])) setres("failed_coup_x_over_6_years_experience", getcoef(r_exp$m, r_exp$map[["E4"]]))

  ## H2b: affiliation
  map_party <- function(x) {
    x <- tolower(x); out <- rep(NA_character_, length(x))
    out[grepl("leader", x)] <- "Leader"
    out[grepl("other|another|different", x)] <- "Other"
    out[grepl("^no |^no$|none|unaff|independ|non-part|nonpart|no party", x)] <- "None"
    out
  }
  pg <- if ("party_group" %in% inn) map_party(to_chr(s$party_group)) else rep(NA_character_, nrow(s))
  if (length(unique(na.omit(pg))) < 3 && all(c("party", "leader_party") %in% inn)) {
    cat("Constructing party groups from party / leader_party\n")
    p <- to_chr(s$party); lp <- to_chr(s$leader_party)
    pg <- ifelse(is.na(p) | p == "" | tolower(p) %in% c("none", "independent", "na", "non-party"), "None",
                 ifelse(!is.na(lp) & p == lp, "Leader", "Other"))
  }
  s[, pg2 := pg]
  if ("party_group" %in% inn) print(table(to_chr(s$party_group), s$pg2, useNA = "ifany"))
  r_aff <- run_inter(s, "pg2", "Other", poly = TRUE)
  setres("failed_coup_affiliation_model", getcoef(r_aff$m, "fca"))
  if (!is.null(r_aff$map[["Leader"]])) setres("failed_coup_x_leaders_party", getcoef(r_aff$m, r_aff$map[["Leader"]]))

  ## H3a: responsibility (portfolio)
  map_port <- function(x) {
    xl <- tolower(x); out <- ifelse(is.na(xl), NA_character_, "Other")
    out[grepl("natur|resourc|oil|petrol|mining|mines|energy|hydrocarb", xl)] <- "Natural"
    out[grepl("financ|treasur", xl)] <- "Finance"
    out[grepl("foreign", xl)] <- "Foreign"
    out[grepl("defen", xl)] <- "Defense"
    out
  }
  if ("portfolio_1" %in% inn) {
    s[, port := map_port(to_chr(portfolio_1))]
    tp <- table(to_chr(s$portfolio_1)); print(head(sort(tp, decreasing = TRUE), 30)); print(table(s$port, useNA = "ifany"))
    r_res <- run_inter(s, "port", "Defense", poly = TRUE)
    setres("failed_coup_responsibility_model", getcoef(r_res$m, "fca"))
    if (!is.null(r_res$map[["Natural"]])) setres("failed_coup_x_natural_resources", getcoef(r_res$m, r_res$map[["Natural"]]))
  }

  ## H3b: importance
  if (sum(!is.na(s$prest)) > 0 && "PMPres" %in% s$prest && length(unique(na.omit(s$prest))) >= 3) {
    r_imp <- run_inter(s, "prest", "PMPres", poly = TRUE)
  } else {
    iv <- if ("importance_numeric" %in% inn) "importance_numeric" else "prestige_numeric"
    s[, prest_n := as.character(to_num(get(iv)))]
    print(table(s$prest_n, useNA = "ifany"))
    refl <- as.character(max(to_num(s[[iv]]), na.rm = TRUE))
    r_imp <- run_inter(s, "prest_n", refl, poly = TRUE)
  }
  setres("failed_coup_importance_model", getcoef(r_imp$m, "fca"))
}

## ---------------- output ----------------
for (nm in names(results)) cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
