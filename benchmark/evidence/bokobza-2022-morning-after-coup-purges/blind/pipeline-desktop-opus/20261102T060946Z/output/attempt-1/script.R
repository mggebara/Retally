suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

ddir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"

res <- list()
put <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0) v <- NA_real_
  res[[name]] <<- v[1]
}

to_plain <- function(df) {
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled")) {
      if (is.character(unclass(x))) {
        df[[v]] <- as.character(zap_labels(x))
      } else {
        df[[v]] <- as.numeric(zap_labels(x))
      }
    } else if (is.factor(x)) {
      df[[v]] <- as.character(x)
    }
    attr(df[[v]], "label") <- NULL
    attr(df[[v]], "format.stata") <- NULL
  }
  df
}

lab_chr <- function(x) {
  if (inherits(x, "haven_labelled")) return(as.character(as_factor(x)))
  as.character(x)
}

# lag by matching (id, year-1)
lag_by <- function(df, v, id, yr) {
  k0 <- paste(df[[id]], df[[yr]])
  k1 <- paste(df[[id]], as.numeric(df[[yr]]) - 1)
  df[[v]][match(k1, k0)]
}

score_name <- function(x) {
  2 * grepl("ln|log", x, ignore.case = TRUE) + grepl("pwt", x, ignore.case = TRUE)
}

# returns list(var = lagged vector, name = source name)
get_lagged <- function(df, inc, exc, id, yr) {
  nms <- names(df)
  cand <- nms[grepl(inc, nms, ignore.case = TRUE)]
  if (!is.null(exc)) cand <- cand[!grepl(exc, cand, ignore.case = TRUE)]
  cand <- cand[sapply(cand, function(v) is.numeric(df[[v]]))]
  if (!length(cand)) return(NULL)
  is_lag <- grepl("lag", cand, ignore.case = TRUE) |
    (substr(cand, 1, 1) %in% c("l", "L") & substring(cand, 2) %in% nms)
  base <- cand[!is_lag]
  lagged <- cand[is_lag]
  dolog <- function(x, nm) {
    if (!grepl("ln|log", nm, ignore.case = TRUE)) {
      xx <- x[is.finite(x)]
      if (length(xx) && min(xx) > 0 && max(xx) > 100) return(log(x))
    }
    x
  }
  if (length(base)) {
    b <- base[order(-score_name(base), nchar(base))][1]
    x <- dolog(df[[b]], b)
    tmp <- df[, c(id, yr)]
    tmp$.x <- x
    return(list(var = lag_by(tmp, ".x", id, yr), name = paste0("lag(", b, ")")))
  }
  b <- lagged[order(-score_name(lagged), nchar(lagged))][1]
  list(var = dolog(df[[b]], b), name = b)
}

GDP_INC <- "gdp"
GDP_EXC <- "growth|_gr|gr_"
POP_INC <- "pop"
POP_EXC <- "oil|popul.*share|popular"

# =====================================================================
# Country-level
# =====================================================================
cl <- tryCatch(to_plain(read_dta(file.path(ddir, "morning_after_dataset_countrylevel.dta"))),
               error = function(e) NULL)

if (!is.null(cl)) {
  nms <- names(cl)
  cid <- if ("COUNTRY_ID" %in% nms) "COUNTRY_ID" else "COUNTRY_DATA"
  yr <- "YEAR_DATA"
  cl[[yr]] <- as.numeric(cl[[yr]])

  # dependent variable
  dv <- "replacement_rateadj_minister"
  if (!dv %in% nms) {
    dv <- nms[grepl("^replacement_rate", nms)][1]
  }
  cl$rr <- as.numeric(cl[[dv]])
  if (max(cl$rr, na.rm = TRUE) > 1.5) cl$rr <- cl$rr / 100

  # failed coup indicator
  cc <- nms[grepl("^coupattempt", nms, ignore.case = TRUE)]
  cc <- cc[!grepl("month|_br|type|lag|success|lead", cc, ignore.case = TRUE)]
  if ("coupattempt_whogov" %in% cc) {
    fv <- "coupattempt_whogov"
  } else if (any(grepl("whogov", cc))) {
    fv <- cc[grepl("whogov", cc)][order(nchar(cc[grepl("whogov", cc)]))][1]
  } else if (length(cc)) {
    fv <- cc[order(nchar(cc))][1]
  } else {
    fv <- nms[grepl("fail", nms, ignore.case = TRUE)][1]
  }
  x <- as.numeric(cl[[fv]])
  cl$fca <- ifelse(is.na(x), NA, as.numeric(x >= 1))
  message("Country-level failed coup var: ", fv)

  g <- get_lagged(cl, GDP_INC, GDP_EXC, cid, yr)
  p <- get_lagged(cl, POP_INC, POP_EXC, cid, yr)
  cl$lgdp <- if (!is.null(g)) g$var else NA
  cl$lpop <- if (!is.null(p)) p$var else NA
  message("GDP: ", if (!is.null(g)) g$name, "  POP: ", if (!is.null(p)) p$name)

  for (v in c("military_c", "party_c", "monarchy_c")) {
    lv <- paste0("l", v)
    if (lv %in% nms) cl[[paste0("lag_", v)]] <- as.numeric(cl[[lv]])
    else if (v %in% nms) cl[[paste0("lag_", v)]] <- lag_by(cl, v, cid, yr)
    else cl[[paste0("lag_", v)]] <- NA
  }

  # autocracy sample: lagged BMR democracy == 0
  if ("ldemocracy_br" %in% nms) {
    ldem <- as.numeric(cl$ldemocracy_br)
  } else {
    ldem <- lag_by(cl, "democracy_br", cid, yr)
  }
  s <- cl[!is.na(ldem) & ldem == 0 & cl[[yr]] >= 1967 & cl[[yr]] <= 2016, ]
  s$cfe <- s[[cid]]
  s$yfe <- s[[yr]]
  s$lfe <- if ("leader_cab_id" %in% nms) s$leader_cab_id else NA

  fb <- rr ~ fca + lgdp + lpop
  fm <- rr ~ fca + lgdp + lpop + lag_military_c + lag_party_c + lag_monarchy_c

  m1 <- tryCatch(feols(update(fb, . ~ . | cfe + yfe), data = s, cluster = ~cfe), error = function(e) {message(e$message); NULL})
  m2 <- tryCatch(feols(update(fm, . ~ . | cfe + yfe), data = s, cluster = ~cfe), error = function(e) {message(e$message); NULL})
  m3 <- tryCatch(feols(update(fb, . ~ . | lfe + yfe), data = s, cluster = ~cfe), error = function(e) {message(e$message); NULL})
  m4 <- tryCatch(feols(update(fm, . ~ . | lfe + yfe), data = s, cluster = ~cfe), error = function(e) {message(e$message); NULL})

  if (!is.null(m1)) { put("failed_coup_base_country_fe", coef(m1)["fca"]); message("N base cfe: ", nobs(m1)) }
  if (!is.null(m2)) { put("failed_coup_main_country_fe", coef(m2)["fca"]); message("N main cfe: ", nobs(m2)) }
  if (!is.null(m3)) put("failed_coup_base_leader_fe", coef(m3)["fca"])
  if (!is.null(m4)) put("failed_coup_main_leader_fe", coef(m4)["fca"])
}

# =====================================================================
# Individual-level
# =====================================================================
ind_raw <- tryCatch(readRDS(file.path(ddir, "morning_after_dataset_individuallevel.rds")),
                    error = function(e) NULL)

if (!is.null(ind_raw)) {
  ind_raw <- as.data.frame(ind_raw, stringsAsFactors = FALSE)
  # keep character versions of label-type string columns
  chr_cols <- intersect(c("party", "leader_party", "party_group", "portfolio_1", "prestige_1",
                          "position", "title", "name", "experience_group", "Group",
                          "country_isocode", "country_name", "classification"), names(ind_raw))
  chrs <- lapply(chr_cols, function(v) lab_chr(ind_raw[[v]]))
  names(chrs) <- chr_cols
  ind <- to_plain(ind_raw)
  for (v in chr_cols) ind[[v]] <- chrs[[v]]
  rm(ind_raw); invisible(gc())
  inms <- names(ind)
  ind$year <- as.numeric(ind$year)
  ind$cid <- ind$country_isocode

  # ---- controls: lagged log GDP pc and log population ----
  ig <- NULL; ip <- NULL
  gc_ind <- inms[grepl(GDP_INC, inms, ignore.case = TRUE) & !grepl(GDP_EXC, inms, ignore.case = TRUE)]
  pc_ind <- inms[grepl(POP_INC, inms, ignore.case = TRUE) & !grepl(POP_EXC, inms, ignore.case = TRUE)]
  if (length(gc_ind) && length(pc_ind)) {
    cy <- unique(ind[, unique(c("cid", "year", gc_ind, pc_ind))])
    cy <- cy[!duplicated(paste(cy$cid, cy$year)), ]
    ig <- get_lagged(cy, GDP_INC, GDP_EXC, "cid", "year")
    ip <- get_lagged(cy, POP_INC, POP_EXC, "cid", "year")
    if (!is.null(ig) && !is.null(ip)) {
      k <- match(paste(ind$cid, ind$year), paste(cy$cid, cy$year))
      ind$lgdp <- ig$var[k]
      ind$lpop <- ip$var[k]
      message("Ind GDP: ", ig$name, " POP: ", ip$name)
    }
  }
  if (is.null(ind$lgdp) && !is.null(cl)) {
    # merge from country-level
    cly <- cl[, c(cid, yr, "lgdp", "lpop", intersect(c("COUNTRY_DATA", "COUNTRY_ID"), names(cl)))]
    best <- NULL; bestrate <- -1
    for (ik in intersect(c("country_isocode", "country_name"), inms)) {
      for (ck in intersect(c("COUNTRY_ID", "COUNTRY_DATA", names(cl)[grepl("iso|ccode|country", names(cl), ignore.case = TRUE)]), names(cl))) {
        u <- unique(as.character(ind[[ik]]))
        rate <- mean(u %in% as.character(cl[[ck]]))
        if (rate > bestrate) { bestrate <- rate; best <- c(ik, ck) }
      }
    }
    message("Merge key: ", paste(best, collapse = " <-> "), " rate ", round(bestrate, 3))
    key_c <- paste(as.character(cl[[best[2]]]), cl[[yr]])
    key_i <- paste(as.character(ind[[best[1]]]), ind$year)
    k <- match(key_i, key_c)
    ind$lgdp <- cl$lgdp[k]
    ind$lpop <- cl$lpop[k]
  }

  # ---- sample ----
  dem <- as.numeric(ind$democracy_lag_br)
  keep <- !is.na(dem) & dem == 0 & ind$year >= 1967 & ind$year <= 2016
  if ("leader" %in% inms) {
    L <- ind$leader
    if (is.numeric(L) || is.logical(L)) {
      keep <- keep & (is.na(L) | as.numeric(L) == 0)
    } else if ("name" %in% inms) {
      keep <- keep & (is.na(L) | as.character(L) != as.character(ind$name))
    }
  }
  d <- ind[keep, ]
  rm(ind); invisible(gc())

  d$y <- as.numeric(d$purged_y1)
  fx <- as.numeric(d$coupattempt_presentyear)
  d$fca <- ifelse(is.na(fx), NA, as.numeric(fx >= 1))
  d$t1 <- as.numeric(d$experience)
  d$t2 <- d$t1^2
  d$t3 <- d$t1^3

  # ---- importance tiers ----
  imp_var <- NULL
  for (v in c("importance_numeric", "prestige_numeric")) {
    if (v %in% names(d)) {
      nl <- length(unique(na.omit(as.numeric(d[[v]]))))
      if (nl == 5) { imp_var <- v; break }
    }
  }
  if (is.null(imp_var)) {
    for (v in c("importance_numeric", "prestige_numeric")) {
      if (v %in% names(d)) {
        nl <- length(unique(na.omit(as.numeric(d[[v]]))))
        if (nl >= 4 && nl <= 7) { imp_var <- v; break }
      }
    }
  }
  ref_tier <- NA; excl_tiers <- c()
  if (!is.null(imp_var)) {
    d$imp <- as.numeric(d[[imp_var]])
    txt <- tolower(paste(if ("position" %in% names(d)) d$position else "",
                         if ("title" %in% names(d)) d$title else "",
                         if ("portfolio_1" %in% names(d)) d$portfolio_1 else ""))
    pmpres <- grepl("prime minister|president|premier", txt) & !grepl("vice|deputy|first deputy", txt)
    levs <- sort(unique(na.omit(d$imp)))
    sh <- sapply(levs, function(l) mean(pmpres[!is.na(d$imp) & d$imp == l]))
    # PM/President tier is at an extreme of the ordering
    ext <- c(min(levs), max(levs))
    ref_tier <- ext[which.max(sh[match(ext, levs)])]
    if (ref_tier == min(levs)) excl_tiers <- tail(levs, 2) else excl_tiers <- head(levs, 2)
    message("Importance var: ", imp_var, " ref tier: ", ref_tier, " excluded (junior/low): ", paste(excl_tiers, collapse = ","))
  }

  runm <- function(f, dat) {
    tryCatch(feols(f, data = dat, cluster = ~cid), error = function(e) {message(e$message); NULL})
  }

  # ---- H2a: Experience ----
  de <- d
  if (length(excl_tiers)) de <- de[is.na(de$imp) | !(de$imp %in% excl_tiers), ]
  de <- de[!is.na(de$t1), ]
  de$e23 <- as.numeric(de$t1 >= 2 & de$t1 < 4)
  de$e46 <- as.numeric(de$t1 >= 4 & de$t1 < 7)
  de$e6p <- as.numeric(de$t1 >= 7)
  de$fca_e23 <- de$fca * de$e23
  de$fca_e46 <- de$fca * de$e46
  de$fca_e6p <- de$fca * de$e6p
  m5 <- runm(y ~ fca + e23 + e46 + e6p + fca_e23 + fca_e46 + fca_e6p + lgdp + lpop | cid + year, de)
  if (!is.null(m5)) {
    put("failed_coup_experience_model", coef(m5)["fca"])
    put("failed_coup_x_over_6_years_experience", coef(m5)["fca_e6p"])
    message("N exp: ", nobs(m5))
  }

  # ---- H2b: Affiliation ----
  grp <- rep(NA_character_, nrow(d))
  if ("party_group" %in% names(d)) {
    pg <- tolower(trimws(as.character(d$party_group)))
    levs <- unique(na.omit(pg))
    nop <- grepl("^no|non|none|indep|without|no party", levs)
    oth <- grepl("other|differ|another", levs) & !nop
    lpp <- grepl("leader|same|own|ruling", levs) & !nop & !oth
    if (sum(nop) == 1 && sum(oth) == 1 && sum(lpp) == 1) {
      grp[pg == levs[nop]] <- "nop"
      grp[pg == levs[oth]] <- "oth"
      grp[pg == levs[lpp]] <- "lp"
    }
  }
  if (all(is.na(grp)) && all(c("party", "leader_party") %in% names(d))) {
    pa <- tolower(trimws(as.character(d$party)))
    lpa <- tolower(trimws(as.character(d$leader_party)))
    nopv <- is.na(pa) | pa %in% c("", "none", "na", "independent", "non-party", "nonparty", "no party", "military", "-")
    grp <- ifelse(nopv, "nop", ifelse(!is.na(lpa) & pa == lpa, "lp", "oth"))
  }
  da <- d
  da$g_lp <- as.numeric(grp == "lp")
  da$g_nop <- as.numeric(grp == "nop")
  da <- da[!is.na(grp), ]
  da$fca_lp <- da$fca * da$g_lp
  da$fca_nop <- da$fca * da$g_nop
  m7 <- runm(y ~ fca + g_lp + g_nop + fca_lp + fca_nop + t1 + t2 + t3 + lgdp + lpop | cid + year, da)
  if (!is.null(m7)) {
    put("failed_coup_affiliation_model", coef(m7)["fca"])
    put("failed_coup_x_leaders_party", coef(m7)["fca_lp"])
  }

  # ---- H3a: Responsibility (portfolio) ----
  if ("portfolio_1" %in% names(d)) {
    pf <- tolower(as.character(d$portfolio_1))
    pf[is.na(pf)] <- ""
    is_def <- grepl("defen[cs]e", pf)
    is_for <- grepl("foreign", pf) & !is_def
    is_fin <- grepl("financ|treasur", pf) & !is_def & !is_for
    nat_pat <- if (any(grepl("natural res", pf))) "natural res" else "natural|oil|petrol|mining|mines|energy"
    is_nat <- grepl(nat_pat, pf) & !is_def & !is_for & !is_fin
    dr <- d
    dr$p_for <- as.numeric(is_for)
    dr$p_fin <- as.numeric(is_fin)
    dr$p_nat <- as.numeric(is_nat)
    dr$p_oth <- as.numeric(!is_def & !is_for & !is_fin & !is_nat)
    dr <- dr[!is.na(d$portfolio_1) & d$portfolio_1 != "", ]
    dr$fca_for <- dr$fca * dr$p_for
    dr$fca_fin <- dr$fca * dr$p_fin
    dr$fca_nat <- dr$fca * dr$p_nat
    dr$fca_oth <- dr$fca * dr$p_oth
    m9 <- runm(y ~ fca + p_for + p_fin + p_nat + p_oth + fca_for + fca_fin + fca_nat + fca_oth +
                 t1 + t2 + t3 + lgdp + lpop | cid + year, dr)
    if (!is.null(m9)) {
      put("failed_coup_responsibility_model", coef(m9)["fca"])
      put("failed_coup_x_natural_resources", coef(m9)["fca_nat"])
    }
  }

  # ---- H3b: Importance ----
  if (!is.null(imp_var) && !is.na(ref_tier)) {
    di <- d[!is.na(d$imp), ]
    levs <- sort(unique(di$imp))
    others <- setdiff(levs, ref_tier)
    rhs <- c("fca")
    for (j in seq_along(others)) {
      nm <- paste0("tier", j)
      di[[nm]] <- as.numeric(di$imp == others[j])
      di[[paste0("fca_", nm)]] <- di$fca * di[[nm]]
      rhs <- c(rhs, nm, paste0("fca_", nm))
    }
    f11 <- as.formula(paste("y ~", paste(c(rhs, "t1", "t2", "t3", "lgdp", "lpop"), collapse = " + "), "| cid + year"))
    m11 <- runm(f11, di)
    if (!is.null(m11)) put("failed_coup_importance_model", coef(m11)["fca"])
  }
}

all_names <- c("failed_coup_base_country_fe", "failed_coup_main_country_fe",
               "failed_coup_base_leader_fe", "failed_coup_main_leader_fe",
               "failed_coup_experience_model", "failed_coup_x_over_6_years_experience",
               "failed_coup_affiliation_model", "failed_coup_x_leaders_party",
               "failed_coup_responsibility_model", "failed_coup_x_natural_resources",
               "failed_coup_importance_model")
for (n in all_names) {
  v <- if (!is.null(res[[n]])) res[[n]] else NA
  cat(sprintf("RESULT:%s=%s\n", n, ifelse(is.na(v), "NA", format(v, digits = 6))))
}