suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"

results <- list()
put <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0) v <- NA_real_
  results[[name]] <<- v[1]
}

# convert character vector to numeric if every non-NA value parses as a number
maybe_num <- function(x) {
  if (!is.character(x)) return(x)
  xx <- trimws(x)
  xx[xx == ""] <- NA
  nn <- suppressWarnings(as.numeric(xx))
  if (sum(!is.na(xx)) > 0 && all(is.na(xx) == is.na(nn))) return(nn)
  x
}

zap <- function(df) {
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled")) {
      if (is.numeric(unclass(x))) x <- as.numeric(unclass(x)) else x <- as.character(haven::as_factor(x))
    }
    if (is.factor(x)) x <- maybe_num(as.character(x))
    attr(x, "label") <- NULL
    attr(x, "format.stata") <- NULL
    attr(x, "labels") <- NULL
    df[[v]] <- x
  }
  as.data.frame(df, stringsAsFactors = FALSE)
}

# robust 0/1 coding for numeric or labelled-character variables
to_binary <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x > 0))
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(s))
  ok <- !is.na(s) & s != ""
  zero <- grepl("^(no\\b|no$|non|not|none|0|false|n$|autoc|without)", s)
  out[ok] <- ifelse(zero[ok], 0, 1)
  out
}

lag_marker <- function(nm) grepl("lag|_l$|^l_|^l(?!n|og)[a-z]", nm, perl = TRUE, ignore.case = TRUE)
log_marker <- function(nm) grepl("ln|log", nm, ignore.case = TRUE)

find_var <- function(df, include, exclude = NULL) {
  nm <- names(df)
  cand <- nm[grepl(include, nm, ignore.case = TRUE)]
  if (!is.null(exclude)) cand <- cand[!grepl(exclude, cand, ignore.case = TRUE)]
  cand <- cand[sapply(cand, function(v) is.numeric(df[[v]]))]
  cand <- cand[sapply(cand, function(v) sum(!is.na(df[[v]])) > 0)]
  if (length(cand) == 0) return(NULL)
  score <- 2 * lag_marker(cand) + 1 * log_marker(cand)
  cand <- cand[order(-score, nchar(cand))]
  cand[1]
}

# lag a variable within id by one year, using (id, year) lookup
lag_by <- function(id, yr, x) {
  key_src <- paste(id, yr + 1)
  key_dst <- paste(id, yr)
  ok <- !is.na(x)
  src_keys <- key_src[ok]; src_vals <- x[ok]
  keep <- !duplicated(src_keys)
  src_keys <- src_keys[keep]; src_vals <- src_vals[keep]
  src_vals[match(key_dst, src_keys)]
}

prepare_control <- function(df, include, exclude, id, yr, label) {
  v <- find_var(df, include, exclude)
  if (is.null(v)) { message("No variable found for ", label); return(rep(NA_real_, nrow(df))) }
  x <- df[[v]]
  if (!log_marker(v) && max(x, na.rm = TRUE) > 50) x <- log(ifelse(x > 0, x, NA))
  if (!lag_marker(v)) x <- lag_by(df[[id]], df[[yr]], x)
  message("Control ", label, ": using ", v, if (!lag_marker(v)) " (lagged here)" else " (already lagged)")
  x
}

safe_coef <- function(m, nm) {
  if (is.null(m) || is.null(nm) || length(nm) == 0 || is.na(nm[1])) return(NA_real_)
  cf <- tryCatch(coef(m), error = function(e) NULL)
  if (is.null(cf) || !(nm[1] %in% names(cf))) return(NA_real_)
  unname(cf[nm[1]])
}

get_inter <- function(r, lev) {
  if (is.null(r) || is.null(r$m) || is.null(lev) || length(lev) == 0 || is.na(lev[1])) return(NA_real_)
  mp <- r$map[[as.character(lev[1])]]
  if (is.null(mp)) return(NA_real_)
  safe_coef(r$m, mp[2])
}

## ===================== Country level =====================
cl <- tryCatch(zap(read_dta(file.path(base_dir, "morning_after_dataset_countrylevel.dta"))),
               error = function(e) { message("country load failed: ", e$message); NULL })

if (!is.null(cl)) {
  message("Country-level columns: ", paste(names(cl), collapse = ", "))
  cl$cid <- cl$COUNTRY_ID
  if (all(is.na(cl$cid))) cl$cid <- cl$COUNTRY_DATA
  cl$yr <- as.numeric(cl$YEAR_DATA)

  if ("replacement_rateadj_minister" %in% names(cl)) {
    cl$dv <- cl$replacement_rateadj_minister
  } else {
    rv <- find_var(cl, "retention_rate")
    cl$dv <- 1 - cl[[rv]]
  }
  if (max(cl$dv, na.rm = TRUE) > 1.5) cl$dv <- cl$dv / 100

  fv <- if ("coupattempt_whogov" %in% names(cl)) "coupattempt_whogov" else find_var(cl, "coupattempt")
  cl$fca <- to_binary(cl[[fv]])
  message("Failed coup var: ", fv)

  if ("ldemocracy_br" %in% names(cl)) {
    cl$ldem <- to_binary(cl$ldemocracy_br)
  } else {
    cl$ldem <- lag_by(cl$cid, cl$yr, to_binary(cl$democracy_br))
  }

  cl$l_gdp <- prepare_control(cl, "gdp", "growth|grow", "cid", "yr", "GDP pc")
  cl$l_pop <- prepare_control(cl, "pop", "oil|valuepop", "cid", "yr", "population")

  for (rv in c("military_c", "monarchy_c", "party_c")) {
    lname <- paste0("l", rv)
    if (lname %in% names(cl)) {
      cl[[paste0("L_", rv)]] <- cl[[lname]]
    } else {
      cl[[paste0("L_", rv)]] <- lag_by(cl$cid, cl$yr, cl[[rv]])
    }
  }

  cs <- cl[!is.na(cl$ldem) & cl$ldem == 0 & cl$yr >= 1967 & cl$yr <= 2016, ]
  message("Country-level sample rows: ", nrow(cs))

  base_ctrl <- c("l_gdp", "l_pop")
  main_ctrl <- c(base_ctrl, "L_military_c", "L_monarchy_c", "L_party_c")

  run_cl <- function(ctrl, fe) {
    f <- as.formula(paste("dv ~ fca +", paste(ctrl, collapse = " + "), "|", fe, "+ yr"))
    m <- tryCatch(feols(f, data = cs, cluster = ~cid), error = function(e) { message(e$message); NULL })
    if (!is.null(m)) message("N = ", nobs(m), "; fca = ", safe_coef(m, "fca"))
    m
  }
  put("failed_coup_base_country_fe", safe_coef(run_cl(base_ctrl, "cid"), "fca"))
  put("failed_coup_main_country_fe", safe_coef(run_cl(main_ctrl, "cid"), "fca"))
  put("failed_coup_base_leader_fe", safe_coef(run_cl(base_ctrl, "leader_cab_id"), "fca"))
  put("failed_coup_main_leader_fe", safe_coef(run_cl(main_ctrl, "leader_cab_id"), "fca"))
}

## ===================== Individual level =====================
il <- tryCatch(readRDS(file.path(base_dir, "morning_after_dataset_individuallevel.rds")),
               error = function(e) { message("individual load failed: ", e$message); NULL })

if (!is.null(il)) {
  il <- zap(il)
  message("Individual-level columns: ", paste(names(il), collapse = ", "))
  for (v in c("year", "coupattempt_presentyear", "democracy_lag_br", "purged_y1", "leader", "experience", "prestige_1", "party_group", "experience_group", "importance_numeric")) {
    if (v %in% names(il)) {
      message("Column ", v, " class=", class(il[[v]])[1], " values: ",
              paste(head(unique(il[[v]]), 8), collapse = " | "))
    }
  }
  il$cid <- if ("country_isocode" %in% names(il)) il$country_isocode else il$country_name
  il$yr <- suppressWarnings(as.numeric(as.character(il$year)))
  il$purged <- to_binary(il$purged_y1)
  cv <- if ("coupattempt_presentyear" %in% names(il)) "coupattempt_presentyear" else find_var(il, "coupattempt")
  il$fca <- to_binary(il[[cv]])
  message("fca table: "); print(table(il$fca, useNA = "ifany"))

  il$l_gdp <- prepare_control(il, "gdp", "growth|grow", "cid", "yr", "GDP pc (ind)")
  il$l_pop <- prepare_control(il, "pop", "oil|valuepop", "cid", "yr", "population (ind)")

  keep <- !is.na(il$yr) & il$yr >= 1967 & il$yr <= 2016
  if ("democracy_lag_br" %in% names(il)) {
    dl <- to_binary(il$democracy_lag_br)
    keep <- keep & !is.na(dl) & dl == 0
  }
  il <- il[keep, ]
  message("Individual sample rows after restriction: ", nrow(il))

  # exclude the leader
  is_leader <- rep(FALSE, nrow(il))
  if ("leader" %in% names(il)) {
    if (is.numeric(il$leader) || is.logical(il$leader)) {
      is_leader <- !is.na(il$leader) & as.numeric(il$leader) == 1
    } else if (length(unique(na.omit(il$leader))) <= 3) {
      lb <- to_binary(il$leader)
      is_leader <- !is.na(lb) & lb == 1
    } else if ("name" %in% names(il)) {
      is_leader <- !is.na(il$leader) & !is.na(il$name) & il$leader == il$name
    }
  }
  if ("prestige_1" %in% names(il) && is.character(il$prestige_1)) {
    is_leader <- is_leader | grepl("^\\s*leader", il$prestige_1, ignore.case = TRUE)
  }
  message("Leader rows excluded: ", sum(is_leader))
  il <- il[!is_leader, ]

  il$exp <- suppressWarnings(as.numeric(il$experience))
  il$exp2 <- il$exp^2
  il$exp3 <- il$exp^3

  pres <- if ("prestige_1" %in% names(il)) as.character(il$prestige_1) else rep(NA_character_, nrow(il))
  if (any(!is.na(pres))) print(table(pres, useNA = "ifany"))
  if ("importance_numeric" %in% names(il) && any(!is.na(pres))) {
    print(table(pres, il$importance_numeric, useNA = "ifany"))
  }
  is_junior <- grepl("junior", pres, ignore.case = TRUE)
  is_low <- grepl("low", pres, ignore.case = TRUE)
  if (sum(is_junior | is_low) == 0 && "importance_numeric" %in% names(il) && is.numeric(il$importance_numeric)) {
    vals <- sort(unique(na.omit(il$importance_numeric)))
    if (length(vals) >= 4) {
      is_junior <- il$importance_numeric %in% vals[1]
      is_low <- il$importance_numeric %in% vals[2]
    }
  }

  ctrl_base <- c("l_gdp", "l_pop")
  poly <- c("exp", "exp2", "exp3")

  run_inter <- function(d, g, ref, ctrl) {
    d <- d[!is.na(d[[g]]), ]
    levs <- setdiff(sort(unique(as.character(d[[g]]))), ref)
    map <- list()
    terms <- c("fca")
    for (i in seq_along(levs)) {
      dn <- paste0("g", i); fn <- paste0("fx_g", i)
      d[[dn]] <- as.numeric(as.character(d[[g]]) == levs[i])
      d[[fn]] <- d$fca * d[[dn]]
      map[[levs[i]]] <- c(dn, fn)
      terms <- c(terms, dn, fn)
    }
    f <- as.formula(paste("purged ~", paste(c(terms, ctrl), collapse = " + "), "| cid + yr"))
    m <- tryCatch(feols(f, data = d, cluster = ~cid), error = function(e) { message(e$message); NULL })
    if (!is.null(m)) {
      message("Model ", g, " N = ", nobs(m))
      tt <- terms[terms %in% names(coef(m))]
      if (length(tt)) print(coeftable(m)[tt, , drop = FALSE])
    }
    list(m = m, map = map, levs = levs)
  }

  ## H2a experience
  de <- il[!(is_junior | is_low), ]
  if ("experience_group" %in% names(de) && any(!is.na(de$experience_group))) {
    de$eg <- as.character(de$experience_group)
  } else {
    de$eg <- cut(de$exp, breaks = c(-Inf, 1.999, 3.999, 6.999, Inf), labels = c("lt2", "2to3", "4to6", "gt6"))
    de$eg <- as.character(de$eg)
  }
  mexp <- if (nrow(de) > 0 && any(!is.na(de$eg))) tapply(de$exp, de$eg, mean, na.rm = TRUE) else numeric(0)
  print(mexp)
  ref_e <- if (length(mexp)) names(mexp)[which.min(mexp)] else NA
  top_e <- if (length(mexp)) names(mexp)[which.max(mexp)] else NA
  r <- tryCatch(run_inter(de, "eg", ref_e, ctrl_base), error = function(e) { message(e$message); NULL })
  put("failed_coup_experience_model", if (!is.null(r)) safe_coef(r$m, "fca") else NA)
  put("failed_coup_x_over_6_years_experience", get_inter(r, top_e))

  ## H2b affiliation
  pg <- as.character(il$party_group)
  print(table(pg, useNA = "ifany"))
  da <- il
  da$pg <- pg
  levs_p <- unique(na.omit(pg))
  ref_p <- levs_p[grepl("other|another", levs_p, ignore.case = TRUE)][1]
  lp_lev <- levs_p[grepl("leader", levs_p, ignore.case = TRUE) & !grepl("other|another|not", levs_p, ignore.case = TRUE)][1]
  if (is.na(ref_p) && length(levs_p)) ref_p <- levs_p[1]
  r <- tryCatch(run_inter(da, "pg", ref_p, c(poly, ctrl_base)), error = function(e) { message(e$message); NULL })
  put("failed_coup_affiliation_model", if (!is.null(r)) safe_coef(r$m, "fca") else NA)
  put("failed_coup_x_leaders_party", get_inter(r, lp_lev))

  ## H3a responsibility (portfolio)
  pf <- tolower(as.character(il$portfolio_1))
  port <- ifelse(is.na(pf), NA, "other")
  port[grepl("natural|resource|oil|petrol|mining|mines|energy", pf)] <- "natres"
  port[grepl("financ|treasur", pf)] <- "finance"
  port[grepl("foreign", pf)] <- "foreign"
  port[grepl("defen", pf)] <- "defense"
  print(table(port, useNA = "ifany"))
  dr <- il; dr$port <- port
  r <- tryCatch(run_inter(dr, "port", "defense", c(poly, ctrl_base)), error = function(e) { message(e$message); NULL })
  put("failed_coup_responsibility_model", if (!is.null(r)) safe_coef(r$m, "fca") else NA)
  put("failed_coup_x_natural_resources", get_inter(r, "natres"))

  ## H3b importance
  di <- il
  imp <- NULL; ref_i <- NA
  plev <- unique(na.omit(pres))
  if (length(plev) >= 3 && length(plev) <= 8) {
    imp <- pres
    cand <- plev[grepl("prime|president|\\bpm\\b", plev, ignore.case = TRUE) &
                   !grepl("vice|deputy|top", plev, ignore.case = TRUE)]
    ref_i <- if (length(cand)) cand[1] else NA
  }
  if ((is.null(imp) || is.na(ref_i)) && "importance_numeric" %in% names(di) && any(!is.na(di$importance_numeric))) {
    imp <- as.character(di$importance_numeric)
    vals <- sort(unique(na.omit(di$importance_numeric)))
    jv <- if (any(is_junior) && is.numeric(di$importance_numeric)) suppressWarnings(median(di$importance_numeric[is_junior], na.rm = TRUE)) else NA
    if (!is.na(jv) && jv == max(vals)) ref_i <- as.character(min(vals)) else ref_i <- as.character(max(vals))
  }
  if (!is.null(imp)) {
    di$imp <- imp
    r <- tryCatch(run_inter(di, "imp", ref_i, c(poly, ctrl_base)), error = function(e) { message(e$message); NULL })
    put("failed_coup_importance_model", if (!is.null(r)) safe_coef(r$m, "fca") else NA)
  } else {
    put("failed_coup_importance_model", NA)
  }
}

needed <- c("failed_coup_base_country_fe", "failed_coup_main_country_fe",
            "failed_coup_base_leader_fe", "failed_coup_main_leader_fe",
            "failed_coup_experience_model", "failed_coup_x_over_6_years_experience",
            "failed_coup_affiliation_model", "failed_coup_x_leaders_party",
            "failed_coup_responsibility_model", "failed_coup_x_natural_resources",
            "failed_coup_importance_model")
for (n in needed) {
  v <- if (!is.null(results[[n]])) results[[n]] else NA_real_
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 8)))
}