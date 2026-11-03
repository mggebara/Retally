suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

ddir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"

res <- list()
put <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0) v <- NA_real_
  res[[name]] <<- v[1]
}

lagv <- function(x, id, yr) {
  key <- paste(id, yr)
  lk <- paste(id, yr - 1)
  x[match(lk, key)]
}

needs_log <- function(x, v) {
  if (grepl("ln|log", v, ignore.case = TRUE)) return(FALSE)
  x <- x[is.finite(x)]
  if (!length(x)) return(FALSE)
  if (min(x) <= 0) return(FALSE)
  med <- median(x)
  (med > 50) || (mean(x) / med > 1.5)
}

get_lagged_ctrl <- function(df, pat, excl, idv, yrv, prefer = NULL) {
  nm <- names(df)
  c <- nm[grepl(pat, nm, ignore.case = TRUE) & !grepl(excl, nm, ignore.case = TRUE)]
  c <- c[sapply(c, function(v) is.numeric(df[[v]]))]
  if (!length(c)) return(NULL)
  score <- function(v) {
    s <- mean(is.finite(df[[v]]))
    if (!is.null(prefer) && grepl(prefer, v, ignore.case = TRUE)) s <- s + 1
    s
  }
  lagged_name <- (grepl(paste0("^l(ag)?_?[a-z0-9_]*", pat), c, ignore.case = TRUE) &
                    !grepl("^ln|^log", c, ignore.case = TRUE)) |
    grepl("lag", c, ignore.case = TRUE)
  if (any(lagged_name)) {
    cc <- c[lagged_name]
    v <- cc[which.max(sapply(cc, score))]
    x <- df[[v]]
    if (needs_log(x, v)) x <- log(ifelse(x > 0, x, NA))
    cat("Control for", pat, "from pre-lagged column", v, "\n")
    return(x)
  }
  v <- c[which.max(sapply(c, score))]
  x <- df[[v]]
  if (needs_log(x, v)) x <- log(ifelse(x > 0, x, NA))
  cat("Control for", pat, "from column", v, "(lagged here)\n")
  lagv(x, df[[idv]], df[[yrv]])
}

# convert a coup indicator (numeric or labelled character such as
# "Coup attempt" / "No coup attempt") into 0/1
to_coup01 <- function(z) {
  if (is.character(z) || is.factor(z)) {
    s <- trimws(tolower(as.character(z)))
    out <- ifelse(is.na(s) | s == "", NA_real_,
                  ifelse(grepl("^no\\b|^no |^none|^0$|^false$|^not ", s), 0,
                         ifelse(grepl("coup|^1$|^yes$|^true$|success|fail|attempt", s), 1, NA_real_)))
    return(as.numeric(out))
  }
  y <- suppressWarnings(as.numeric(z))
  ifelse(is.na(y), NA_real_, as.numeric(y > 0))
}

make_failed <- function(df, att_cands, coup_cands) {
  att <- NULL
  for (a in att_cands) if (a %in% names(df)) { att <- a; break }
  if (is.null(att)) return(NULL)
  x <- to_coup01(df[[att]])
  cp <- NULL
  for (a in coup_cands) if (a %in% names(df)) { cp <- a; break }
  if (!is.null(cp)) {
    y <- to_coup01(df[[cp]])
    ov <- sum(x == 1 & y > 0, na.rm = TRUE)
    cat("Coup attempt var:", att, " success var:", cp, " overlap:", ov, "\n")
    if (ov > 0) x <- ifelse(!is.na(y) & y > 0, 0, x)
  } else cat("Coup attempt var:", att, "\n")
  cat("Attempt indicator table:\n"); print(table(x, useNA = "ifany"))
  x
}

## ---------------------------------------------------------------- country level
cl <- tryCatch(as.data.frame(zap_labels(read_dta(file.path(ddir, "morning_after_dataset_countrylevel.dta")))),
               error = function(e) NULL)

if (!is.null(cl)) {
  cat("Country-level columns:\n"); print(names(cl))
  idv <- if ("COUNTRY_ID" %in% names(cl)) "COUNTRY_ID" else grep("country", names(cl), ignore.case = TRUE, value = TRUE)[1]
  yrv <- if ("YEAR_DATA" %in% names(cl)) "YEAR_DATA" else grep("year", names(cl), ignore.case = TRUE, value = TRUE)[1]
  cl$id_ <- cl[[idv]]
  cl$yr_ <- as.numeric(cl[[yrv]])

  if ("replacement_rateadj_minister" %in% names(cl)) {
    cl$dv <- cl$replacement_rateadj_minister
  } else if ("retention_rateadj_minister" %in% names(cl)) {
    cl$dv <- 1 - cl$retention_rateadj_minister
  }

  att_c <- grep("^coupattem", names(cl), value = TRUE)
  att_c <- att_c[!grepl("month|_br|type|last|lag|^l", att_c, ignore.case = TRUE)]
  att_c <- c(att_c[grepl("whogov", att_c)], att_c[!grepl("whogov", att_c)])
  cp_c <- grep("^coup_", names(cl), value = TRUE)
  cp_c <- cp_c[!grepl("month|_br|type|last|lag", cp_c, ignore.case = TRUE)]
  cp_c <- c(cp_c[grepl("whogov", cp_c)], cp_c[!grepl("whogov", cp_c)])
  cl$fca <- make_failed(cl, att_c, cp_c)
  cat("Failed coups (all years):", sum(cl$fca, na.rm = TRUE), "\n")

  if ("ldemocracy_br" %in% names(cl)) cl$ldem <- cl$ldemocracy_br else
    cl$ldem <- lagv(cl$democracy_br, cl$id_, cl$yr_)

  g <- get_lagged_ctrl(cl, "gdp", "grow", "id_", "yr_", prefer = "pc|cap|pop")
  p <- get_lagged_ctrl(cl, "pop", "oil|valuepop|gdp", "id_", "yr_")
  cl$lgdp <- if (is.null(g)) NA_real_ else g
  cl$lpop <- if (is.null(p)) NA_real_ else p

  for (v in c("military_c", "party_c", "monarchy_c")) {
    nv <- paste0("l_", v)
    if (paste0("l", v) %in% names(cl)) cl[[nv]] <- cl[[paste0("l", v)]]
    else if (v %in% names(cl)) cl[[nv]] <- lagv(cl[[v]], cl$id_, cl$yr_)
    else cl[[nv]] <- NA_real_
  }

  d <- cl[!is.na(cl$ldem) & cl$ldem == 0, ]
  cat("Autocracy country-years:", nrow(d), "\n")
  leadv <- if ("leader_cab_id" %in% names(d)) "leader_cab_id" else NULL

  fit <- function(rhs, fe) {
    f <- as.formula(paste("dv ~", rhs, "|", fe))
    tryCatch(feols(f, data = d, cluster = ~id_), error = function(e) { cat("ERR:", conditionMessage(e), "\n"); NULL })
  }
  base_rhs <- "fca + lgdp + lpop"
  main_rhs <- "fca + lgdp + lpop + l_military_c + l_party_c + l_monarchy_c"

  m1 <- fit(base_rhs, "id_ + yr_")
  m2 <- fit(main_rhs, "id_ + yr_")
  if (!is.null(m1)) { print(summary(m1)); put("failed_coup_base_country_fe", coef(m1)["fca"]) }
  if (!is.null(m2)) { print(summary(m2)); put("failed_coup_main_country_fe", coef(m2)["fca"]) }
  if (!is.null(leadv)) {
    m3 <- fit(base_rhs, paste(leadv, "+ yr_"))
    m4 <- fit(main_rhs, paste(leadv, "+ yr_"))
    if (!is.null(m3)) { print(summary(m3)); put("failed_coup_base_leader_fe", coef(m3)["fca"]) }
    if (!is.null(m4)) { print(summary(m4)); put("failed_coup_main_leader_fe", coef(m4)["fca"]) }
  }
}

## ---------------------------------------------------------------- individual level
ind <- tryCatch(readRDS(file.path(ddir, "morning_after_dataset_individuallevel.rds")), error = function(e) NULL)

if (!is.null(ind)) {
  ind <- as.data.frame(zap_labels(as.data.frame(ind)))
  for (v in names(ind)) if (is.factor(ind[[v]])) ind[[v]] <- as.character(ind[[v]])
  cat("Individual-level columns:\n"); print(names(ind))
  for (v in names(ind)) {
    if (is.character(ind[[v]])) {
      u <- unique(ind[[v]])
      if (length(u) <= 15) { cat("Levels of", v, ":\n"); print(table(ind[[v]], useNA = "ifany")) }
    }
  }

  ind$cid <- if ("country_isocode" %in% names(ind)) ind$country_isocode else ind$country_name
  ind$yr <- as.numeric(ind$year)

  # purged
  pv <- ind$purged_y1
  if (is.character(pv)) {
    s <- trimws(tolower(pv))
    pv <- ifelse(is.na(s) | s == "", NA_real_,
                 ifelse(grepl("^not|^no\\b|^no |^0$|^false$|retain|stay|remain", s), 0,
                        ifelse(grepl("purg|^1$|^yes$|^true$|remov|dismiss", s), 1, NA_real_)))
  }
  ind$purged <- as.numeric(pv)
  cat("Purged table:\n"); print(table(ind$purged, useNA = "ifany"))

  ind$fca <- make_failed(ind, c("coupattempt_presentyear"), c("coup_presentyear"))

  # experience
  ind$e1 <- suppressWarnings(as.numeric(ind$experience))
  ind$e2 <- ind$e1^2
  ind$e3 <- ind$e1^3

  # country-year controls
  gcand <- names(ind)[grepl("gdp", names(ind), ignore.case = TRUE)]
  ind$lgdp <- NA_real_; ind$lpop <- NA_real_; ind$ldem <- NA_real_
  ind_has_gdp <- length(gcand) > 0
  if (ind_has_gdp) {
    cy <- ind[!duplicated(paste(ind$cid, ind$yr)), ]
    g <- get_lagged_ctrl(cy, "gdp", "grow", "cid", "yr", prefer = "pc|cap|pop")
    p <- get_lagged_ctrl(cy, "pop", "oil|valuepop|gdp", "cid", "yr")
    cy$lgdp_ <- if (is.null(g)) NA_real_ else g
    cy$lpop_ <- if (is.null(p)) NA_real_ else p
    k <- match(paste(ind$cid, ind$yr), paste(cy$cid, cy$yr))
    ind$lgdp <- cy$lgdp_[k]; ind$lpop <- cy$lpop_[k]
  }
  dem01 <- function(z) {
    if (is.character(z)) {
      s <- trimws(tolower(z))
      return(ifelse(is.na(s) | s == "", NA_real_,
                    ifelse(grepl("autoc", s), 0, ifelse(grepl("democ", s), 1, suppressWarnings(as.numeric(s))))))
    }
    as.numeric(z)
  }
  if ("ldemocracy_br" %in% names(ind)) {
    ind$ldem <- dem01(ind$ldemocracy_br)
  } else if ("democracy_lag_br" %in% names(ind)) {
    ind$ldem <- dem01(ind$democracy_lag_br)
  } else if ("democracy_br" %in% names(ind)) {
    cy <- ind[!duplicated(paste(ind$cid, ind$yr)), ]
    cy$ld <- lagv(dem01(cy$democracy_br), cy$cid, cy$yr)
    ind$ldem <- cy$ld[match(paste(ind$cid, ind$yr), paste(cy$cid, cy$yr))]
  }
  cat("Lagged democracy table:\n"); print(table(ind$ldem, useNA = "ifany"))

  # merge from country-level data where needed
  if (!is.null(cl) && (all(is.na(ind$lgdp)) || all(is.na(ind$ldem)))) {
    best <- NULL; bestov <- 0; bestik <- NULL
    for (col in names(cl)) {
      x <- cl[[col]]
      if (!(is.character(x) || is.numeric(x))) next
      ux <- unique(as.character(x))
      if (length(ux) < 20) next
      for (ik in intersect(c("country_isocode", "country_name"), names(ind))) {
        ov <- mean(unique(as.character(ind[[ik]])) %in% ux)
        if (ov > bestov) { bestov <- ov; best <- col; bestik <- ik }
      }
    }
    cat("Merge key:", best, "<->", bestik, " overlap:", bestov, "\n")
    if (!is.null(best) && bestov > 0.3) {
      key_c <- paste(as.character(cl[[best]]), cl$yr_)
      key_i <- paste(as.character(ind[[bestik]]), ind$yr)
      k <- match(key_i, key_c)
      if (all(is.na(ind$lgdp))) { ind$lgdp <- cl$lgdp[k]; ind$lpop <- cl$lpop[k] }
      if (all(is.na(ind$ldem))) ind$ldem <- cl$ldem[k]
    }
  }

  # exclude the leader
  is_leader <- rep(FALSE, nrow(ind))
  if ("leader" %in% names(ind)) {
    lv <- ind$leader
    if (is.numeric(lv) || is.logical(lv)) {
      is_leader <- !is.na(lv) & as.numeric(lv) == 1
    } else if (all(unique(na.omit(lv)) %in% c("0", "1", "Yes", "No", "yes", "no", "TRUE", "FALSE"))) {
      is_leader <- tolower(lv) %in% c("1", "yes", "true")
    } else if ("name" %in% names(ind)) {
      is_leader <- !is.na(lv) & !is.na(ind$name) & lv == ind$name
    }
  }
  for (v in intersect(c("classification", "prestige_1", "minister_classification", "Group"), names(ind))) {
    if (is.character(ind[[v]])) is_leader <- is_leader | (!is.na(ind[[v]]) & tolower(trimws(ind[[v]])) == "leader")
  }
  cat("Leader rows:", sum(is_leader), "\n")

  S <- ind[!is_leader & !is.na(ind$ldem) & ind$ldem == 0 &
             !is.na(ind$purged) & !is.na(ind$fca), ]
  if (nrow(S) == 0) S <- ind[!is_leader & !is.na(ind$purged) & !is.na(ind$fca), ]
  cat("Individual sample (autocracy, non-leader):", nrow(S), "\n")

  find_cat <- function(df, regs, prefer) {
    out <- c()
    for (v in names(df)) {
      x <- df[[v]]
      if (!is.character(x)) next
      u <- unique(x[!is.na(x)])
      if (length(u) < 2 || length(u) > 40) next
      if (all(sapply(regs, function(r) any(grepl(r, u, ignore.case = TRUE))))) out <- c(out, v)
    }
    if (!length(out)) return(NULL)
    pr <- intersect(prefer, out)
    if (length(pr)) pr[1] else out[1]
  }

  run_mod <- function(df, gvar, ref, cubic = TRUE) {
    df$g_ <- gvar
    df <- df[!is.na(df$g_), ]
    lev <- setdiff(sort(unique(df$g_)), ref)
    rhs <- "fca"
    for (i in seq_along(lev)) {
      df[[paste0("D", i)]] <- as.numeric(df$g_ == lev[i])
      df[[paste0("FD", i)]] <- df$fca * df[[paste0("D", i)]]
    }
    rhs <- c("fca", paste0("D", seq_along(lev)), paste0("FD", seq_along(lev)))
    if (cubic) rhs <- c(rhs, "e1", "e2", "e3")
    rhs <- c(rhs, "lgdp", "lpop")
    f <- as.formula(paste("purged ~", paste(rhs, collapse = " + "), "| cid + yr"))
    m <- tryCatch(feols(f, data = df, cluster = ~cid), error = function(e) { cat("ERR:", conditionMessage(e), "\n"); NULL })
    if (!is.null(m)) { cat("Reference:", ref, " levels:", paste(lev, collapse = " | "), "\n"); print(summary(m)) }
    list(m = m, lev = lev)
  }
  getint <- function(r, L) {
    if (is.null(r$m) || is.null(L) || is.na(L) || !(L %in% r$lev)) return(NA)
    coef(r$m)[paste0("FD", which(r$lev == L))]
  }

  if (nrow(S) > 0) {
    # importance variable
    impv <- find_cat(S, c("junior", "low"), c("prestige_1", "classification", "Group", "minister_classification", "importance_factor"))
    imp <- NULL; imp_ref <- NULL; drop_lowjr <- rep(FALSE, nrow(S))
    if (!is.null(impv)) {
      imp <- S[[impv]]
      u <- unique(imp[!is.na(imp)])
      refs <- u[grepl("prime|presid|\\bpm\\b", u, ignore.case = TRUE) &
                  !grepl("vice|deputy|leader|top", u, ignore.case = TRUE)]
      if (length(refs) > 1) { imp[imp %in% refs] <- "REF_PM_PRES"; imp_ref <- "REF_PM_PRES" } else if (length(refs) == 1) imp_ref <- refs
      drop_lowjr <- !is.na(imp) & grepl("junior|low", imp, ignore.case = TRUE)
      cat("Importance var:", impv, " ref:", imp_ref, "\n")
    } else if ("importance_numeric" %in% names(S)) {
      iv <- suppressWarnings(as.numeric(S$importance_numeric))
      if (any(is.finite(iv))) {
        tb <- table(iv)
        lv <- as.numeric(names(tb))
        lo <- min(lv); hi <- max(lv)
        if (tb[as.character(lo)] < tb[as.character(hi)]) { refl <- lo; lowside <- sort(lv, decreasing = TRUE)[1:2] } else { refl <- hi; lowside <- sort(lv)[1:2] }
        imp <- as.character(iv); imp_ref <- as.character(refl)
        drop_lowjr <- !is.na(iv) & iv %in% lowside
        cat("Importance numeric fallback, ref:", imp_ref, "\n")
      }
    }

    # fallback for the importance tiers (five ordered tiers, leader excluded);
    # reference = the most important (rarest extreme) tier
    if (is.null(imp) || is.null(imp_ref) || !length(imp_ref) || is.na(imp_ref[1])) {
      cands <- intersect(c("importance_factor", "importance_numeric", "importance", "prestige_1", "classification"), names(S))
      for (cv in cands) {
        x <- S[[cv]]
        if (is.numeric(x)) {
          tb <- table(x)
          if (length(tb) < 3 || length(tb) > 10) next
          lv <- as.numeric(names(tb)); lo <- min(lv); hi <- max(lv)
          refl <- if (tb[as.character(lo)] < tb[as.character(hi)]) lo else hi
          imp <- as.character(x); imp_ref <- as.character(refl)
        } else {
          x <- as.character(x)
          x[!is.na(x) & tolower(trimws(x)) == "leader"] <- NA
          tb <- table(x)
          if (length(tb) < 3 || length(tb) > 10) next
          u <- names(tb)
          top <- u[grepl("top|prime|presid|deputy|vice|^1|tier ?1|highest", u, ignore.case = TRUE)]
          imp <- x
          imp_ref <- if (length(top)) top[which.min(tb[top])] else u[which.min(tb)]
        }
        cat("Importance fallback var:", cv, " ref:", imp_ref, "\n"); print(table(imp, useNA = "ifany"))
        break
      }
    }

    # H2a experience
    if ("experience_group" %in% names(S)) {
      SE <- S[!drop_lowjr, ]
      eg <- as.character(SE$experience_group)
      mexp <- tapply(SE$e1, eg, mean, na.rm = TRUE)
      if (all(is.na(mexp))) { lv <- sort(unique(na.omit(eg))); ref <- lv[1]; top <- lv[length(lv)] } else {
        ref <- names(mexp)[which.min(mexp)]; top <- names(mexp)[which.max(mexp)]
      }
      r <- run_mod(SE, eg, ref, cubic = FALSE)
      if (!is.null(r$m)) {
        put("failed_coup_experience_model", coef(r$m)["fca"])
        put("failed_coup_x_over_6_years_experience", getint(r, top))
      }
    }

    # H2b affiliation
    affv <- find_cat(S, c("other", "leader"), c("party_group", "leader_party", "party"))
    if (!is.null(affv)) {
      a <- S[[affv]]
      u <- unique(a[!is.na(a)])
      lp <- u[grepl("leader", u, ignore.case = TRUE) & !grepl("other", u, ignore.case = TRUE)][1]
      # binary contrast: leader's party vs all other ministers (other party, unaffiliated, unknown pooled)
      a <- ifelse(is.na(a), NA_character_, ifelse(a == lp, lp, "ZZ_not_leader_party"))
      ref <- "ZZ_not_leader_party"
      cat("Affiliation var:", affv, " ref:", ref, " leader party level:", lp, "\n")
      cat("DEVIATION: Affiliation model contrasts leader's-party ministers with all other ministers pooled (other party, unaffiliated, unknown); paper does not state the omitted category\n")
      r <- run_mod(S, a, ref, cubic = TRUE)
      if (!is.null(r$m)) {
        put("failed_coup_affiliation_model", coef(r$m)["fca"])
        put("failed_coup_x_leaders_party", getint(r, lp))
      }
    }

    # H3a responsibility
    resv <- find_cat(S, c("defen", "natur|resour"), c("minister_type", "minister_classification", "classification", "Group", "portfolio_1"))
    if (!is.null(resv)) {
      a <- S[[resv]]; u <- unique(a[!is.na(a)])
      ref <- u[grepl("defen", u, ignore.case = TRUE)][1]
      nr <- u[grepl("natur|resour", u, ignore.case = TRUE)][1]
      cat("Responsibility var:", resv, "\n")
      r <- run_mod(S, a, ref, cubic = TRUE)
      if (!is.null(r$m)) {
        put("failed_coup_responsibility_model", coef(r$m)["fca"])
        put("failed_coup_x_natural_resources", getint(r, nr))
      }
    }

    # H3b importance
    if (!is.null(imp) && !is.null(imp_ref)) {
      r <- run_mod(S, imp, imp_ref, cubic = TRUE)
      if (!is.null(r$m)) put("failed_coup_importance_model", coef(r$m)["fca"])
    }
  }
}

nms <- c("failed_coup_base_country_fe", "failed_coup_main_country_fe",
         "failed_coup_base_leader_fe", "failed_coup_main_leader_fe",
         "failed_coup_experience_model", "failed_coup_x_over_6_years_experience",
         "failed_coup_affiliation_model", "failed_coup_x_leaders_party",
         "failed_coup_responsibility_model", "failed_coup_x_natural_resources",
         "failed_coup_importance_model")
for (n in nms) {
  v <- if (!is.null(res[[n]])) res[[n]] else NA
  cat(sprintf("RESULT:%s=%s\n", n, ifelse(is.na(v), "NA", format(v, digits = 6))))
}