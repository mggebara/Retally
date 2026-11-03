suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"

res <- list(
  failed_coup_base_country_fe = NA_real_,
  failed_coup_main_country_fe = NA_real_,
  failed_coup_base_leader_fe = NA_real_,
  failed_coup_main_leader_fe = NA_real_,
  failed_coup_experience_model = NA_real_,
  failed_coup_x_over_6_years_experience = NA_real_,
  failed_coup_affiliation_model = NA_real_,
  failed_coup_x_leaders_party = NA_real_,
  failed_coup_responsibility_model = NA_real_,
  failed_coup_x_natural_resources = NA_real_,
  failed_coup_importance_model = NA_real_
)

getcoef <- function(m, nm) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (nm %in% names(cf)) return(unname(cf[nm]))
  NA_real_
}

to_plain <- function(df) {
  df <- as.data.frame(df)
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled")) {
      df[[v]] <- as.vector(zap_labels(x))
    }
  }
  df
}

# robust numeric conversion: handles factors, characters with numeric text or yes/no labels
num <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x))
  xc <- tolower(trimws(as.character(x)))
  n <- suppressWarnings(as.numeric(xc))
  n[is.na(n) & grepl("^(yes|true|purged|coup attempt|attempt|failed)", xc)] <- 1
  n[is.na(n) & grepl("^(no|false|not |none)", xc)] <- 0
  n
}

# autocracy indicator from a (lagged) democracy variable: numeric 0 = autocracy; text labels handled
autoc <- function(x) {
  if (is.logical(x)) return(!x)
  if (is.numeric(x)) return(x == 0)
  xc <- tolower(trimws(as.character(x)))
  n <- suppressWarnings(as.numeric(xc))
  out <- n == 0
  txt <- is.na(n) & !is.na(xc) & xc != ""
  out[txt] <- grepl("autoc|dictat|non-?democ|not democ|^no$|^false$", xc[txt])
  out
}

# ---- control variable finders ----
pick_ctrl <- function(nms, pat, excl, prefer = NULL) {
  cands <- nms[grepl(pat, nms, ignore.case = TRUE) & !grepl(excl, nms, ignore.case = TRUE)]
  if (length(cands) == 0) return(NULL)
  is_lag <- sapply(cands, function(n) {
    grepl("lag", n, ignore.case = TRUE) || grepl("_l1?$", n) ||
      (startsWith(tolower(n), "l") && substring(n, 2) %in% cands)
  })
  score <- function(cs) {
    s <- rep(0, length(cs))
    if (!is.null(prefer)) s <- s + 2 * grepl(prefer, cs, ignore.case = TRUE)
    s <- s + grepl("ln|log", cs, ignore.case = TRUE)
    cs[order(-s, nchar(cs))]
  }
  if (any(is_lag)) {
    return(list(var = score(cands[is_lag])[1], lagged = TRUE, all = cands))
  }
  list(var = score(cands)[1], lagged = FALSE, all = cands)
}

maybe_log <- function(x, nm) {
  x <- num(x)
  if (grepl("ln|log", nm, ignore.case = TRUE)) return(x)
  if (all(is.na(x))) return(x)
  if (min(x, na.rm = TRUE) > 0 && max(x, na.rm = TRUE) > 100) return(log(x))
  x
}

panel_lag <- function(x, id, t) {
  key <- paste(id, t)
  lk <- paste(id, t - 1)
  x[match(lk, key)]
}

##############################################################
# COUNTRY LEVEL
##############################################################
cl <- tryCatch(to_plain(read_dta(file.path(base_dir, "morning_after_dataset_countrylevel.dta"))),
               error = function(e) { message("country load error: ", e$message); NULL })

if (!is.null(cl)) {
  nms <- names(cl)
  message("Country-level columns: ", paste(nms, collapse = ", "))
  cl$cid <- cl$COUNTRY_ID
  cl$yr <- num(cl$YEAR_DATA)

  # failed coup variable
  pri <- c("coupattempt_whogov", "failedcoup_whogov", "failed_coup", "failedcoup",
           "coupattempt_presentyear", "coupattempt")
  fc <- pri[pri %in% nms][1]
  if (is.na(fc)) {
    cc <- nms[grepl("^coupattem|failed", nms, ignore.case = TRUE) &
                !grepl("month|_br|type|lag|lead|last|next", nms, ignore.case = TRUE)]
    fc <- if (length(cc)) cc[1] else NA
  }
  message("Failed coup var (country): ", fc)
  cl$fca <- as.numeric(num(cl[[fc]]) > 0)

  # DV
  dv <- "replacement_rateadj_minister"
  cl$rr <- num(cl[[dv]])
  if (max(cl$rr, na.rm = TRUE) > 1.5) cl$rr <- cl$rr / 100

  # GDP pc and population
  g <- pick_ctrl(nms, "gdp", "growth|grow|oil", prefer = "pc|cap|per")
  p <- pick_ctrl(nms, "pop", "oil|valuepop")
  message("GDP candidates: ", paste(g$all, collapse = ","), " -> ", g$var, " lagged=", g$lagged)
  message("Pop candidates: ", paste(p$all, collapse = ","), " -> ", p$var, " lagged=", p$lagged)
  gx <- maybe_log(cl[[g$var]], g$var)
  px <- maybe_log(cl[[p$var]], p$var)
  cl$lgdp <- if (g$lagged) gx else panel_lag(gx, cl$cid, cl$yr)
  cl$lpop <- if (p$lagged) px else panel_lag(px, cl$cid, cl$yr)

  lag_or_make <- function(v) {
    lv <- paste0("l", v)
    if (lv %in% nms) return(num(cl[[lv]]))
    panel_lag(num(cl[[v]]), cl$cid, cl$yr)
  }
  cl$lmil <- lag_or_make("military_c")
  cl$lparty <- lag_or_make("party_c")
  cl$lmon <- lag_or_make("monarchy_c")

  # autocracy: lagged BMR == 0
  if ("ldemocracy_br" %in% nms) {
    cl$auto <- num(cl$ldemocracy_br) == 0
  } else {
    cl$auto <- panel_lag(num(cl$democracy_br), cl$cid, cl$yr) == 0
  }
  s <- cl[!is.na(cl$auto) & cl$auto & cl$yr >= 1967 & cl$yr <= 2016 & !is.na(cl$rr) & !is.na(cl$fca), ]
  message("Country sample rows: ", nrow(s))

  fit <- function(f) tryCatch(feols(f, data = s, cluster = ~cid),
                              error = function(e) { message("err: ", e$message); NULL })
  m1 <- fit(rr ~ fca + lgdp + lpop | cid + yr)
  m2 <- fit(rr ~ fca + lgdp + lpop + lmil + lparty + lmon | cid + yr)
  m3 <- fit(rr ~ fca + lgdp + lpop | leader_cab_id + yr)
  m4 <- fit(rr ~ fca + lgdp + lpop + lmil + lparty + lmon | leader_cab_id + yr)
  for (m in list(m1, m2, m3, m4)) if (!is.null(m)) print(summary(m))
  res$failed_coup_base_country_fe <- getcoef(m1, "fca")
  res$failed_coup_main_country_fe <- getcoef(m2, "fca")
  res$failed_coup_base_leader_fe <- getcoef(m3, "fca")
  res$failed_coup_main_leader_fe <- getcoef(m4, "fca")
}

##############################################################
# INDIVIDUAL LEVEL
##############################################################
il <- tryCatch(as.data.frame(readRDS(file.path(base_dir, "morning_after_dataset_individuallevel.rds"))),
               error = function(e) { message("ind load error: ", e$message); NULL })

if (!is.null(il)) {
  il <- to_plain(il)
  inm <- names(il)
  message("Individual-level columns: ", paste(inm, collapse = ", "))
  chr <- function(x) as.character(x)

  # diagnostics for the key filter variables
  for (v in c("year", "purged_y1", "coupattempt_presentyear", "democracy_lag_br", "experience")) {
    if (v %in% inm) {
      message("Var ", v, " class: ", paste(class(il[[v]]), collapse = "/"))
      tb <- table(il[[v]], useNA = "ifany")
      if (length(tb) <= 20) print(tb) else print(head(tb, 20))
    }
  }

  il$yr <- num(il$year)
  il$ctry <- chr(il$country_isocode)
  il$purged <- num(il$purged_y1)
  il$fca <- as.numeric(num(il$coupattempt_presentyear) > 0)
  il$exper <- num(il$experience)

  # autocracy
  if ("democracy_lag_br" %in% inm) {
    il$auto <- autoc(il$democracy_lag_br)
  } else il$auto <- TRUE
  message("Autocracy rows: ", sum(il$auto %in% TRUE),
          "; purged non-NA: ", sum(!is.na(il$purged)),
          "; fca non-NA: ", sum(!is.na(il$fca)),
          "; yr in range: ", sum(il$yr >= 1967 & il$yr <= 2016, na.rm = TRUE))

  # controls: GDP pc, population (lagged one year, country-year)
  g <- pick_ctrl(inm, "gdp", "growth|grow|oil", prefer = "pc|cap|per")
  p <- pick_ctrl(inm, "pop", "oil|valuepop")
  message("Ind GDP: ", paste(g$all, collapse = ","), " -> ", g$var, " lagged=", g$lagged)
  message("Ind Pop: ", paste(p$all, collapse = ","), " -> ", p$var, " lagged=", p$lagged)
  mk_ctrl <- function(info) {
    x <- maybe_log(il[[info$var]], info$var)
    if (info$lagged) return(x)
    cy <- unique(data.frame(ctry = il$ctry, yr = il$yr, x = x)[!is.na(x), ])
    cy <- cy[!duplicated(paste(cy$ctry, cy$yr)), ]
    key <- paste(cy$ctry, cy$yr)
    cy$x[match(paste(il$ctry, il$yr - 1), key)]
  }
  il$lgdp <- mk_ctrl(g)
  il$lpop <- mk_ctrl(p)

  # leader exclusion
  is_leader <- rep(FALSE, nrow(il))
  if ("leader" %in% inm) {
    L <- il$leader
    if (is.numeric(L) || is.logical(L)) {
      is_leader <- !is.na(L) & as.numeric(L) == 1
    } else {
      Lc <- chr(L)
      if (all(na.omit(unique(Lc)) %in% c("0", "1", "yes", "no", "Yes", "No", "TRUE", "FALSE"))) {
        is_leader <- Lc %in% c("1", "yes", "Yes", "TRUE")
      } else if ("name" %in% inm) {
        is_leader <- !is.na(Lc) & chr(il$name) == Lc
      }
    }
  }
  pres <- if ("prestige_1" %in% inm) tolower(chr(il$prestige_1)) else rep(NA_character_, nrow(il))
  print(table(il$prestige_1, useNA = "ifany"))
  if ("importance_numeric" %in% inm) print(table(il$importance_numeric, useNA = "ifany"))
  is_leader <- is_leader | (!is.na(pres) & grepl("^leader|^the leader", pres))
  message("Leader rows: ", sum(is_leader))

  # importance tiers
  tier <- rep(NA_character_, nrow(il))
  tier[grepl("junior", pres)] <- "junior"
  tier[is.na(tier) & grepl("low", pres)] <- "low"
  tier[is.na(tier) & grepl("medium|middle|mid", pres)] <- "medium"
  tier[is.na(tier) & grepl("vice|deputy|top", pres)] <- "vptop"
  tier[is.na(tier) & grepl("prime|president|^pm", pres)] <- "pmpres"
  tier[is_leader] <- NA
  ntier <- length(unique(na.omit(tier)))
  message("Tiers from prestige_1: ", ntier)
  use_imp_numeric <- FALSE
  if (ntier < 4 && "importance_numeric" %in% inm) {
    use_imp_numeric <- TRUE
    imp <- num(il$importance_numeric)
    imp[is_leader] <- NA
    tier <- ifelse(is.na(imp), NA, paste0("imp", imp))
  }
  print(table(tier, useNA = "ifany"))

  sel <- il$auto %in% TRUE & !is_leader & il$yr >= 1967 & il$yr <= 2016 &
    !is.na(il$purged) & !is.na(il$fca)
  sel[is.na(sel)] <- FALSE
  if (sum(sel) == 0) {
    message("No rows under autocracy filter; relaxing autocracy restriction")
    sel <- !is_leader & il$yr >= 1967 & il$yr <= 2016 & !is.na(il$purged) & !is.na(il$fca)
    sel[is.na(sel)] <- FALSE
  }
  base <- il[sel, ]
  base$tier <- tier[sel]
  base$t1 <- base$exper; base$t2 <- base$exper^2; base$t3 <- base$exper^3
  message("Individual base rows: ", nrow(base))

  fiti <- function(f, d) tryCatch(feols(f, data = d, cluster = ~ctry),
                                  error = function(e) { message("err: ", e$message); NULL })
  safe_relevel <- function(f, ref) {
    f <- factor(f)
    if (ref %in% levels(f)) relevel(f, ref = ref) else f
  }

  if (nrow(base) > 0) {
    # ---- H2a experience ----
    d <- base
    if (!use_imp_numeric) {
      d <- d[is.na(d$tier) | !(d$tier %in% c("junior", "low")), ]
    }
    eg <- NULL
    if ("experience_group" %in% inm && length(unique(na.omit(chr(d$experience_group)))) >= 4) {
      egc <- chr(d$experience_group)
      mexp <- tapply(d$exper, egc, mean, na.rm = TRUE)
      lv <- names(sort(mexp))
      if (length(lv) == 4) {
        map <- setNames(c("lt2", "y2_3", "y4_6", "over6"), lv)
        eg <- unname(map[egc])
      }
    }
    if (is.null(eg)) {
      e <- d$exper
      eg <- ifelse(is.na(e), NA, ifelse(e < 2, "lt2", ifelse(e <= 3, "y2_3", ifelse(e <= 6, "y4_6", "over6"))))
    }
    d$eg <- safe_relevel(eg, "lt2")
    print(table(d$eg, useNA = "ifany"))
    mE <- fiti(purged ~ fca * eg + lgdp + lpop | ctry + yr, d)
    if (!is.null(mE)) print(summary(mE))
    res$failed_coup_experience_model <- getcoef(mE, "fca")
    res$failed_coup_x_over_6_years_experience <- getcoef(mE, "fca:egover6")

    # ---- H2b affiliation ----
    d <- base
    aff <- NULL
    if ("party_group" %in% inm) {
      pg <- tolower(chr(d$party_group))
      print(table(d$party_group, useNA = "ifany"))
      a <- rep(NA_character_, nrow(d))
      a[grepl("other", pg)] <- "other"
      a[is.na(a) & grepl("leader", pg)] <- "leaderparty"
      a[is.na(a) & grepl("no |none|^no$|independ|non-|nonpart|no party|without", pg)] <- "noparty"
      if (length(unique(na.omit(a))) == 3) aff <- a
    }
    if (is.null(aff)) {
      pty <- chr(d$party); lp <- chr(d$leader_party)
      nop <- is.na(pty) | pty == "" | grepl("^none$|independ|non-party|nonpartisan|^na$", pty, ignore.case = TRUE)
      aff <- ifelse(nop, "noparty", ifelse(!is.na(lp) & pty == lp, "leaderparty", "other"))
    }
    d$aff <- safe_relevel(aff, "other")
    print(table(d$aff, useNA = "ifany"))
    mA <- fiti(purged ~ fca * aff + t1 + t2 + t3 + lgdp + lpop | ctry + yr, d)
    if (!is.null(mA)) print(summary(mA))
    res$failed_coup_affiliation_model <- getcoef(mA, "fca")
    res$failed_coup_x_leaders_party <- getcoef(mA, "fca:affleaderparty")

    # ---- H3a responsibility ----
    d <- base
    classify_port <- function(x) {
      x <- tolower(x)
      out <- rep("other", length(x))
      out[is.na(x) | x == ""] <- NA
      out[!is.na(x) & grepl("natural|resource|oil|petrol|mining|mines|energy|hydrocarbon", x)] <- "natres"
      out[!is.na(x) & grepl("financ|treasury", x)] <- "finance"
      out[!is.na(x) & grepl("foreign", x)] <- "foreign"
      out[!is.na(x) & grepl("defen|armed forces", x)] <- "defense"
      out
    }
    port <- NULL
    if ("Group" %in% inm) {
      gv <- chr(d$Group)
      print(table(d$Group, useNA = "ifany"))
      lv <- unique(na.omit(gv))
      if (length(lv) <= 8 && any(grepl("defen", lv, ignore.case = TRUE)) &&
          any(grepl("natural|resource", lv, ignore.case = TRUE))) {
        port <- classify_port(gv)
      }
    }
    if (is.null(port)) {
      src <- if ("portfolio_1" %in% inm) chr(d$portfolio_1) else chr(d$position)
      port <- classify_port(src)
    }
    d$port <- safe_relevel(port, "defense")
    print(table(d$port, useNA = "ifany"))
    mR <- fiti(purged ~ fca * port + t1 + t2 + t3 + lgdp + lpop | ctry + yr, d)
    if (!is.null(mR)) print(summary(mR))
    res$failed_coup_responsibility_model <- getcoef(mR, "fca")
    res$failed_coup_x_natural_resources <- getcoef(mR, "fca:portnatres")

    # ---- H3b importance ----
    d <- base[!is.na(base$tier), ]
    if (nrow(d) > 0) {
      d$tier <- factor(d$tier)
      if ("pmpres" %in% levels(d$tier)) {
        d$tier <- relevel(d$tier, ref = "pmpres")
      } else {
        tb <- table(d$tier)
        d$tier <- relevel(d$tier, ref = names(tb)[which.min(tb)])
      }
      print(table(d$tier, useNA = "ifany"))
      mI <- fiti(purged ~ fca * tier + t1 + t2 + t3 + lgdp + lpop | ctry + yr, d)
      if (!is.null(mI)) print(summary(mI))
      res$failed_coup_importance_model <- getcoef(mI, "fca")
    }
  }
}

for (n in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", n, format(res[[n]], digits = 8)))
}
