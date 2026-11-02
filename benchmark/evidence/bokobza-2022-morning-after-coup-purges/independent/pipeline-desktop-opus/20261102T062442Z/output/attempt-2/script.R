suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
is01 <- function(x) {
  if (!is.numeric(x)) return(FALSE)
  v <- unique(x[!is.na(x)])
  length(v) > 0 && all(v %in% c(0, 1))
}
is012 <- function(x) {
  if (!is.numeric(x)) return(FALSE)
  v <- unique(x[!is.na(x)])
  length(v) > 0 && all(v %in% c(0, 1, 2))
}

# Robust numeric conversion (handles character / logical codings)
to_num <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x))
  if (is.factor(x)) x <- as.character(x)
  xc <- trimws(as.character(x))
  xc[xc == ""] <- NA
  n <- suppressWarnings(as.numeric(xc))
  nonmiss <- sum(!is.na(xc))
  if (nonmiss == 0 || mean(!is.na(n[!is.na(xc)])) > 0.9) return(n)
  xl <- tolower(xc)
  out <- rep(NA_real_, length(xl))
  out[grepl("^(no|not|non|false|autoc|0)", xl)] <- 0
  out[is.na(out) & grepl("^(yes|true|purged|demo|1)", xl)] <- 1
  out[is.na(out) & !is.na(n)] <- n[is.na(out) & !is.na(n)]
  out
}

lag_cy <- function(id, time, x) {
  d <- data.frame(id = as.character(id), t = as.numeric(time), x = as.numeric(x),
                  stringsAsFactors = FALSE)
  u <- d %>% group_by(id, t) %>%
    summarise(x = if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE), .groups = "drop")
  u$x[match(paste(d$id, d$t - 1), paste(u$id, u$t))]
}

lagish <- function(nm, all) {
  grepl("lag", nm, ignore.case = TRUE) |
    (substr(nm, 1, 1) %in% c("l", "L") & substring(nm, 2) %in% all)
}

to_log <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  if (all(is.na(x))) return(x)
  if (max(x, na.rm = TRUE) > 50) {
    x[!is.na(x) & x <= 0] <- NA
    x <- log(x)
  }
  x
}

# Return lagged (t-1) logged control
get_ctrl <- function(df, include, exclude, id, time, prefer = NULL, label = "") {
  nm <- names(df)
  cc <- nm[grepl(include, nm, ignore.case = TRUE)]
  if (!is.null(exclude)) cc <- cc[!grepl(exclude, cc, ignore.case = TRUE)]
  cc <- cc[vapply(cc, function(v) is.numeric(df[[v]]), logical(1))]
  if (!length(cc)) return(NULL)
  score <- function(v) {
    s <- 0
    if (!is.null(prefer)) s <- s + 2 * grepl(prefer, v, ignore.case = TRUE)
    s + grepl("ln|log", v, ignore.case = TRUE)
  }
  lg <- lagish(cc, nm)
  nonlag <- cc[!lg]
  if (length(nonlag)) {
    sc <- vapply(nonlag, score, numeric(1))
    v <- nonlag[order(-sc)][1]
    cat("Control", label, "uses", v, "(lagged by script)\n")
    return(lag_cy(df[[id]], df[[time]], to_log(df[[v]])))
  } else {
    l <- cc[lg]
    sc <- vapply(l, score, numeric(1))
    v <- l[order(-sc)][1]
    cat("Control", label, "uses pre-lagged", v, "\n")
    return(to_log(df[[v]]))
  }
}

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && !is.na(val)) {
    cat(sprintf("RESULT:%s=%.6f\n", name, val))
  }
}

results <- list()

gdp_inc <- "gdp"
gdp_exc <- "grow|growth|_gr$|gr_|change|diff|chg"
pop_inc <- "pop"
pop_exc <- "oil|valuepop|grow|growth|change"

# ------------------------------------------------------------------
# Country-level
# ------------------------------------------------------------------
cl <- haven::read_dta(file.path(base_dir, "morning_after_dataset_countrylevel.dta"))
cl <- as.data.frame(haven::zap_labels(cl))
cat("Country-level columns:", paste(names(cl), collapse = ", "), "\n")
nmc <- names(cl)

cid_var <- if ("COUNTRY_ID" %in% nmc) "COUNTRY_ID" else "COUNTRY_DATA"
cl$cid <- as.character(cl[[cid_var]])
cl$yr <- as.numeric(cl$YEAR_DATA)
cl$y <- as.numeric(cl$replacement_rateadj_minister)

cl$lgdp <- get_ctrl(cl, gdp_inc, gdp_exc, "cid", "yr", prefer = "pc|cap|percap", label = "gdp(cl)")
cl$lpop <- get_ctrl(cl, pop_inc, pop_exc, "cid", "yr", label = "pop(cl)")

lag_dummy <- function(df, v) {
  lv <- paste0("l", v)
  if (lv %in% names(df)) return(as.numeric(df[[lv]]))
  lag_cy(df$cid, df$yr, df[[v]])
}
cl$lmil <- if ("military_c" %in% nmc) lag_dummy(cl, "military_c") else NA
cl$lpar <- if ("party_c" %in% nmc) lag_dummy(cl, "party_c") else NA
cl$lmon <- if ("monarchy_c" %in% nmc) lag_dummy(cl, "monarchy_c") else NA

if ("ldemocracy_br" %in% nmc) {
  cl$ldem <- as.numeric(cl$ldemocracy_br)
} else {
  cl$ldem <- lag_cy(cl$cid, cl$yr, cl$democracy_br)
}

cl$lid <- if ("leader_cab_id" %in% nmc) as.character(cl$leader_cab_id) else NA

s_cl <- !is.na(cl$ldem) & cl$ldem == 0 & cl$yr >= 1967 & cl$yr <= 2016 &
  !is.na(cl$y) & !is.na(cl$lgdp) & !is.na(cl$lpop)
cat("Country-level base sample rows (pre-coup var):", sum(s_cl), "\n")

# Candidate failed coup indicators
cands <- list()
for (v in nmc[grepl("fail", nmc, ignore.case = TRUE)]) {
  if (is012(cl[[v]])) cands[[v]] <- as.numeric(cl[[v]] > 0)
}
if ("independent" %in% nmc && is01(cl$independent)) cands[["independent"]] <- as.numeric(cl$independent)
att_vars <- nmc[grepl("attempt", nmc, ignore.case = TRUE)]
succ_vars <- nmc[grepl("success|^coup_|^coup$", nmc, ignore.case = TRUE) &
                   !grepl("attempt|fail", nmc, ignore.case = TRUE)]
succ_vars <- succ_vars[vapply(succ_vars, function(v) is012(cl[[v]]), logical(1))]
for (v in att_vars) {
  if (is012(cl[[v]])) {
    cands[[paste0(v, "_any")]] <- as.numeric(cl[[v]] > 0)
    if (any(cl[[v]] == 2, na.rm = TRUE)) cands[[paste0(v, "_eq1")]] <- as.numeric(cl[[v]] == 1)
    for (s in succ_vars) {
      sv <- cl[[s]]; sv[is.na(sv)] <- 0
      cands[[paste0(v, "_minus_", s)]] <- as.numeric(cl[[v]] > 0 & sv == 0)
    }
  }
}
fca_cl_name <- NA
if (length(cands)) {
  cnt <- vapply(cands, function(z) sum(z[s_cl] == 1, na.rm = TRUE), numeric(1))
  print(cnt)
  fca_cl_name <- names(cands)[which.min(abs(cnt - 95))]
  cl$fca <- cands[[fca_cl_name]]
  cat("Chosen country-level failed coup variable:", fca_cl_name, "\n")
}

d_cl <- cl[s_cl & !is.na(cl$fca), ]
cat("Country-level N:", nrow(d_cl), " failed coups:", sum(d_cl$fca), "\n")

safe_coef <- function(m, v) {
  if (is.null(m)) return(NA)
  if (is.null(v) || length(v) != 1 || is.na(v)) return(NA)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA
}

m1 <- tryCatch(feols(y ~ fca + lgdp + lpop | cid + yr, data = d_cl, cluster = ~cid),
               error = function(e) { cat("m1 error:", conditionMessage(e), "\n"); NULL })
m2 <- tryCatch(feols(y ~ fca + lgdp + lpop + lmil + lpar + lmon | cid + yr, data = d_cl, cluster = ~cid),
               error = function(e) { cat("m2 error:", conditionMessage(e), "\n"); NULL })
m3 <- tryCatch(feols(y ~ fca + lgdp + lpop | lid + yr, data = d_cl, cluster = ~cid),
               error = function(e) { cat("m3 error:", conditionMessage(e), "\n"); NULL })
m4 <- tryCatch(feols(y ~ fca + lgdp + lpop + lmil + lpar + lmon | lid + yr, data = d_cl, cluster = ~cid),
               error = function(e) { cat("m4 error:", conditionMessage(e), "\n"); NULL })
for (m in list(m1, m2, m3, m4)) if (!is.null(m)) print(summary(m))

results$failed_coup_base_country_fe <- safe_coef(m1, "fca")
results$failed_coup_main_country_fe <- safe_coef(m2, "fca")
results$failed_coup_base_leader_fe <- safe_coef(m3, "fca")
results$failed_coup_main_leader_fe <- safe_coef(m4, "fca")

# ------------------------------------------------------------------
# Individual-level
# ------------------------------------------------------------------
ind <- tryCatch(readRDS(file.path(base_dir, "morning_after_dataset_individuallevel.rds")),
                error = function(e) NULL)
if (!is.null(ind)) tryCatch({
  ind <- as.data.frame(ind)
  ind <- tryCatch(as.data.frame(haven::zap_labels(ind)), error = function(e) ind)
  for (v in names(ind)) if (is.factor(ind[[v]])) ind[[v]] <- as.character(ind[[v]])
  cat("Individual-level columns:", paste(names(ind), collapse = ", "), "\n")
  nmi <- names(ind)
  for (v in c("year", "purged_y1", "democracy_lag_br", "democracy_lag", "gdp_cap_pwt_ln",
              "pop_pwt_ln", "gdp_cap_pwt_ln_lag", "pop_pwt_ln_lag", "experience",
              "coupattempt_presentyear", "coup_presentyear", "leader", "importance_numeric")) {
    if (v %in% nmi) {
      cat("Column", v, "class:", class(ind[[v]])[1], " head values:\n")
      print(head(sort(table(ind[[v]], useNA = "ifany"), decreasing = TRUE), 8))
    }
  }

  ind$cid <- as.character(ind$country_isocode)
  ind$yr <- to_num(ind$year)
  ind$y <- to_num(ind$purged_y1)
  cat("Non-missing y:", sum(!is.na(ind$y)), " non-missing yr:", sum(!is.na(ind$yr)), "\n")

  # Make numeric copies of key numeric columns that may be stored as character
  for (v in c("gdp_cap_pwt_ln", "pop_pwt_ln", "gdp_cap_pwt_ln_lag", "pop_pwt_ln_lag",
              "coupattempt_presentyear", "coup_presentyear", "coupattempt_presentyear_br",
              "coup_presentyear_br", "importance_numeric", "prestige_numeric")) {
    if (v %in% nmi && !is.numeric(ind[[v]])) ind[[v]] <- to_num(ind[[v]])
  }

  # Controls
  ind$lgdp <- NA_real_; ind$lpop <- NA_real_
  g <- tryCatch(get_ctrl(ind, gdp_inc, gdp_exc, "cid", "yr", prefer = "pc|cap|percap", label = "gdp(ind)"),
                error = function(e) NULL)
  p <- tryCatch(get_ctrl(ind, pop_inc, pop_exc, "cid", "yr", label = "pop(ind)"),
                error = function(e) NULL)
  if (!is.null(g)) ind$lgdp <- g
  if (!is.null(p)) ind$lpop <- p
  # Fill with pre-lagged variables where available
  if ("gdp_cap_pwt_ln_lag" %in% nmi) {
    ok <- is.na(ind$lgdp); ind$lgdp[ok] <- as.numeric(ind$gdp_cap_pwt_ln_lag[ok])
  }
  if ("pop_pwt_ln_lag" %in% nmi) {
    ok <- is.na(ind$lpop); ind$lpop[ok] <- as.numeric(ind$pop_pwt_ln_lag[ok])
  }
  cat("Non-missing lgdp:", sum(!is.na(ind$lgdp)), " lpop:", sum(!is.na(ind$lpop)), "\n")
  if (mean(is.na(ind$lgdp)) > 0.5 || mean(is.na(ind$lpop)) > 0.5) {
    # merge from country-level data by name (or iso) and year
    cat("Merging controls from country-level data\n")
    keys_cl <- NULL
    iso_cl <- nmc[grepl("iso", nmc, ignore.case = TRUE)]
    if (length(iso_cl)) {
      k1 <- paste(toupper(trimws(as.character(cl[[iso_cl[1]]]))), cl$yr)
      k2 <- paste(toupper(trimws(ind$cid)), ind$yr)
      mt <- match(k2, k1)
      if (mean(!is.na(mt)) > 0.5) keys_cl <- mt
    }
    if (is.null(keys_cl) && is.character(cl$COUNTRY_DATA)) {
      k1 <- paste(tolower(trimws(cl$COUNTRY_DATA)), cl$yr)
      k2 <- paste(tolower(trimws(as.character(ind$country_name))), ind$yr)
      keys_cl <- match(k2, k1)
    }
    if (!is.null(keys_cl)) {
      if (mean(is.na(ind$lgdp)) > 0.5) ind$lgdp <- cl$lgdp[keys_cl]
      if (mean(is.na(ind$lpop)) > 0.5) ind$lpop <- cl$lpop[keys_cl]
    }
  }

  # Autocracy restriction
  ind$ldem <- NA_real_
  if ("democracy_lag_br" %in% nmi) ind$ldem <- to_num(ind$democracy_lag_br)
  if (all(is.na(ind$ldem)) && "democracy_lag" %in% nmi) ind$ldem <- to_num(ind$democracy_lag)
  if (all(is.na(ind$ldem))) ind$ldem <- 0
  cat("ldem table:\n"); print(table(ind$ldem, useNA = "ifany"))

  # Leader exclusion
  is_leader <- rep(FALSE, nrow(ind))
  if ("leader" %in% nmi) {
    if (is01(ind$leader)) {
      is_leader <- !is.na(ind$leader) & ind$leader == 1
    } else if (is.character(ind$leader) && "name" %in% nmi) {
      is_leader <- !is.na(ind$name) & !is.na(ind$leader) &
        tolower(trimws(ind$name)) == tolower(trimws(ind$leader))
    }
  }
  if ("classification" %in% nmi && is.character(ind$classification)) {
    is_leader <- is_leader | (!is.na(ind$classification) &
                                grepl("^leader", trimws(ind$classification), ignore.case = TRUE))
  }
  cat("Leader rows:", sum(is_leader), "\n")

  conds <- list(
    ldem = !is.na(ind$ldem) & ind$ldem == 0,
    years = !is.na(ind$yr) & ind$yr >= 1967 & ind$yr <= 2016,
    y = !is.na(ind$y),
    notleader = !is_leader,
    gdp = !is.na(ind$lgdp),
    pop = !is.na(ind$lpop)
  )
  for (cn in names(conds)) cat("Condition", cn, "TRUE rows:", sum(conds[[cn]]), "\n")
  s_ind <- Reduce(`&`, conds)
  cat("Individual base sample rows:", sum(s_ind), "\n")
  if (sum(s_ind) == 0) {
    # drop non-essential conditions that are (nearly) never satisfied
    for (cn in c("notleader", "ldem", "gdp", "pop", "years")) {
      if (sum(Reduce(`&`, conds)) > 0) break
      if (sum(conds[[cn]]) < 0.05 * nrow(ind)) {
        cat("Dropping restrictive condition:", cn, "\n")
        conds[[cn]] <- rep(TRUE, nrow(ind))
      }
    }
    s_ind <- Reduce(`&`, conds)
    cat("Individual base sample rows (after relaxing):", sum(s_ind), "\n")
  }
  if (sum(s_ind) == 0) stop("empty individual-level sample")

  # Failed coup candidates
  ic <- list()
  for (v in nmi[grepl("fail", nmi, ignore.case = TRUE)]) if (is012(ind[[v]])) ic[[v]] <- as.numeric(ind[[v]] > 0)
  if ("coupattempt_presentyear" %in% nmi && is012(ind$coupattempt_presentyear)) {
    a <- ind$coupattempt_presentyear
    ic[["att_any"]] <- as.numeric(a > 0)
    if (any(a == 2, na.rm = TRUE)) ic[["att_eq1"]] <- as.numeric(a == 1)
    if ("coup_presentyear" %in% nmi && is012(ind$coup_presentyear)) {
      sv <- ind$coup_presentyear; sv[is.na(sv)] <- 0
      ic[["att_minus_coup"]] <- as.numeric(a > 0 & sv == 0)
    }
  }
  # Merge from country-level chosen variable
  if (!is.na(fca_cl_name)) {
    mt <- NULL
    if (is.character(cl$COUNTRY_DATA)) {
      k1 <- paste(tolower(trimws(cl$COUNTRY_DATA)), cl$yr)
      k2 <- paste(tolower(trimws(as.character(ind$country_name))), ind$yr)
      mt <- match(k2, k1)
    }
    if (!is.null(mt) && sum(s_ind) > 0 && isTRUE(mean(!is.na(mt[s_ind])) > 0.8)) ic[["cl_merge"]] <- cl$fca[mt]
  }
  if (!length(ic)) stop("no failed coup candidate at individual level")
  icnt <- vapply(ic, function(z) {
    ok <- s_ind & !is.na(z) & z == 1
    length(unique(paste(ind$cid[ok], ind$yr[ok])))
  }, numeric(1))
  print(icnt)
  ind$fca <- ic[[names(ic)[which.min(abs(icnt - 95))]]]
  cat("Chosen individual failed coup variable:", names(ic)[which.min(abs(icnt - 95))], "\n")

  d0 <- ind[s_ind & !is.na(ind$fca), ]
  d0$e <- suppressWarnings(as.numeric(d0$experience))
  d0$e1 <- d0$e / 10; d0$e2 <- d0$e1^2; d0$e3 <- d0$e1^3

  run_int <- function(d, gvar, ref, cubic = TRUE) {
    d <- d[!is.na(d[[gvar]]), ]
    lv <- setdiff(sort(unique(d[[gvar]])), ref)
    terms <- c("fca")
    map <- c()
    for (i in seq_along(lv)) {
      mn <- paste0("M", i); fn <- paste0("FxM", i)
      d[[mn]] <- as.numeric(d[[gvar]] == lv[i])
      d[[fn]] <- d$fca * d[[mn]]
      terms <- c(terms, mn, fn)
      map[as.character(lv[i])] <- fn
    }
    terms <- c(terms, "lgdp", "lpop")
    if (cubic) terms <- c(terms, "e1", "e2", "e3")
    f <- as.formula(paste("y ~", paste(terms, collapse = " + "), "| cid + yr"))
    m <- feols(f, data = d, cluster = ~cid)
    print(summary(m))
    print(map)
    list(m = m, map = map)
  }

  # Importance tiers
  imp_var <- if ("importance_numeric" %in% nmi) "importance_numeric" else "prestige_numeric"
  pos <- tolower(paste(ifelse(is.na(d0$position), "", as.character(d0$position)),
                       if ("portfolio_1" %in% nmi) ifelse(is.na(d0$portfolio_1), "", as.character(d0$portfolio_1)) else ""))
  is_pm <- grepl("prime minister|president", pos) & !grepl("vice|deputy|assistant|first minister", pos)
  imp <- to_num(d0[[imp_var]])
  lv_imp <- sort(unique(imp[!is.na(imp)]))
  pm_share <- vapply(lv_imp, function(l) mean(is_pm[!is.na(imp) & imp == l]), numeric(1))
  cat("Importance levels and PM shares:\n"); print(rbind(lv_imp, pm_share, n = vapply(lv_imp, function(l) sum(imp == l, na.rm = TRUE), numeric(1))))
  ref_imp <- lv_imp[which.max(pm_share)]
  ord_imp <- if (ref_imp == max(lv_imp)) rev(lv_imp) else lv_imp
  d0$imp <- imp

  # ---- H2a Experience ----
  tryCatch({
    de <- d0
    excl <- rep(FALSE, nrow(de))
    if (length(ord_imp) >= 5) {
      bottom <- tail(ord_imp, 2)
      excl <- !is.na(de$imp) & de$imp %in% bottom
      cat("Excluding importance tiers:", bottom, "\n")
    } else if ("prestige_1" %in% nmi && is.character(de$prestige_1)) {
      excl <- !is.na(de$prestige_1) & grepl("junior|low", de$prestige_1, ignore.case = TRUE)
    }
    de <- de[!excl & !is.na(de$imp), ]
    de$eg <- cut(de$e, breaks = c(-Inf, 1.5, 3.5, 6.5, Inf), labels = c("a_lt2", "b_2_3", "c_4_6", "d_gt6"))
    de$eg <- as.character(de$eg)
    r <- run_int(de, "eg", "a_lt2", cubic = FALSE)
    results$failed_coup_experience_model <- safe_coef(r$m, "fca")
    results$failed_coup_x_over_6_years_experience <- safe_coef(r$m, unname(r$map["d_gt6"]))
  }, error = function(e) cat("H2a error:", conditionMessage(e), "\n"))

  # ---- H2b Affiliation ----
  tryCatch({
    da <- d0
    aff <- rep(NA_character_, nrow(da))
    if ("party_group" %in% nmi && is.character(da$party_group)) {
      pg <- tolower(da$party_group)
      print(table(da$party_group, useNA = "ifany"))
      aff <- ifelse(is.na(pg), NA,
             ifelse(grepl("no party|^no |none|^no$|independ|unaffil|non-part|nonpart|without", pg), "nopart",
             ifelse(grepl("leader", pg) & !grepl("not|other|non|different", pg), "leaderp", "other")))
    }
    if (all(is.na(aff)) || length(unique(na.omit(aff))) < 3) {
      pty <- trimws(as.character(da$party)); lp <- trimws(as.character(da$leader_party))
      nop <- is.na(pty) | pty == "" | grepl("independent|^none$|non-party|nonpartisan|no party", pty, ignore.case = TRUE)
      aff <- ifelse(nop, "nopart", ifelse(!is.na(lp) & tolower(pty) == tolower(lp), "leaderp", "other"))
    }
    da$aff <- aff
    print(table(da$aff, useNA = "ifany"))
    r <- run_int(da, "aff", "other", cubic = TRUE)
    results$failed_coup_affiliation_model <- safe_coef(r$m, "fca")
    results$failed_coup_x_leaders_party <- safe_coef(r$m, unname(r$map["leaderp"]))
  }, error = function(e) cat("H2b error:", conditionMessage(e), "\n"))

  # ---- H3a Responsibility (portfolio) ----
  tryCatch({
    dr <- d0
    pf <- tolower(ifelse(is.na(dr$portfolio_1), "", as.character(dr$portfolio_1)))
    print(head(sort(table(pf), decreasing = TRUE), 40))
    natre <- if (any(grepl("natural resource", pf))) "natural resource" else "natural|resource|mining|mines|petrol|oil|energy"
    port <- ifelse(grepl("defen", pf), "a_def",
            ifelse(grepl("foreign", pf), "b_for",
            ifelse(grepl("financ|treasury", pf), "c_fin",
            ifelse(grepl(natre, pf), "d_nat", "e_oth"))))
    dr$port <- port
    print(table(dr$port))
    r <- run_int(dr, "port", "a_def", cubic = TRUE)
    results$failed_coup_responsibility_model <- safe_coef(r$m, "fca")
    results$failed_coup_x_natural_resources <- safe_coef(r$m, unname(r$map["d_nat"]))
  }, error = function(e) cat("H3a error:", conditionMessage(e), "\n"))

  # ---- H3b Importance ----
  tryCatch({
    di <- d0[!is.na(d0$imp), ]
    r <- run_int(di, "imp", ref_imp, cubic = TRUE)
    results$failed_coup_importance_model <- safe_coef(r$m, "fca")
  }, error = function(e) cat("H3b error:", conditionMessage(e), "\n"))
}, error = function(e) cat("Individual-level error:", conditionMessage(e), "\n"))

# ------------------------------------------------------------------
# Output
# ------------------------------------------------------------------
for (nm in c("failed_coup_base_country_fe", "failed_coup_main_country_fe",
             "failed_coup_base_leader_fe", "failed_coup_main_leader_fe",
             "failed_coup_experience_model", "failed_coup_x_over_6_years_experience",
             "failed_coup_affiliation_model", "failed_coup_x_leaders_party",
             "failed_coup_responsibility_model", "failed_coup_x_natural_resources",
             "failed_coup_importance_model")) {
  emit(nm, results[[nm]])
}