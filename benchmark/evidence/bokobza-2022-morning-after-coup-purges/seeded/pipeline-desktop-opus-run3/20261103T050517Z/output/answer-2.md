suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges"

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

safe <- function(expr) tryCatch(expr, error = function(e) { message("ERROR: ", conditionMessage(e)); NULL })

###########################
# Country-level analysis  #
###########################

cl <- safe(as.data.frame(zap_labels(read_dta(file.path(base_dir, "morning_after_dataset_countrylevel.dta")))))

find_col <- function(df, candidates) {
  for (c in candidates) if (c %in% names(df)) return(c)
  NA_character_
}

lag_var <- function(df, var, id, time) {
  df <- df[order(df[[id]], df[[time]]), ]
  key <- paste(df[[id]], df[[time]])
  prev <- paste(df[[id]], df[[time]] - 1)
  df[[paste0("lag__", var)]] <- df[[var]][match(prev, key)]
  df
}

if (!is.null(cl)) {
  nms <- names(cl)
  idv <- find_col(cl, c("COUNTRY_ID", "ccode", "country_id"))
  tv <- find_col(cl, c("YEAR_DATA", "year"))
  cl[[tv]] <- as.numeric(cl[[tv]])

  # Get (lagged) control variable: prefer existing lagged version, else construct
  get_lagged <- function(df, pats_lag, pats_raw) {
    nm <- names(df)
    for (p in pats_lag) { h <- nm[grepl(p, nm, ignore.case = TRUE)]; if (length(h)) return(list(df = df, v = h[1])) }
    for (p in pats_raw) {
      h <- nm[grepl(p, nm, ignore.case = TRUE)]
      if (length(h)) { df <- lag_var(df, h[1], idv, tv); return(list(df = df, v = paste0("lag__", h[1]))) }
    }
    list(df = df, v = NA_character_)
  }

  r <- get_lagged(cl, c("^l_?gdp.*ln", "^l_?ln_?gdp", "gdp.*ln.*_l(ag)?$", "^lag_?gdp"), c("gdp.*pwt.*ln", "gdp.*ln", "ln.*gdp"))
  cl <- r$df; gdpv <- r$v
  r <- get_lagged(cl, c("^l_?pop.*ln", "^l_?ln_?pop", "pop.*ln.*_l(ag)?$", "^lag_?pop"), c("pop.*pwt.*ln", "pop.*ln", "ln.*pop"))
  cl <- r$df; popv <- r$v

  regv <- c()
  for (base in c("military_c", "party_c", "monarchy_c")) {
    lagn <- find_col(cl, c(paste0("l", base), paste0("l_", base), paste0(base, "_l"), paste0("lag_", base)))
    if (!is.na(lagn)) { regv <- c(regv, lagn) } else if (base %in% names(cl)) {
      cl <- lag_var(cl, base, idv, tv); regv <- c(regv, paste0("lag__", base))
    }
  }

  coupv <- find_col(cl, c("coupattempt_whogov", grep("^coupattem", nms, value = TRUE)))
  dv <- "replacement_rateadj_minister"
  # Leader FE: use the leader identifier (not the leader-cabinet spell id)
  leadv <- find_col(cl, c("leader_id", "leaderid", "leader_whogov_id", "leader_name", "leader_cab_id"))
  cat(sprintf("DEVIATION: Leader FE variable set to '%s' (leader identifier preferred over leader-cabinet spell id)\n", leadv))

  samp <- cl
  if ("democracy1" %in% names(samp)) {
    samp <- samp[!is.na(samp$democracy1) & samp$democracy1 == 0, ]
  } else if ("ldemocracy_br" %in% names(samp)) {
    samp <- samp[!is.na(samp$ldemocracy_br) & samp$ldemocracy_br == 0, ]
  }
  if ("independent" %in% names(samp)) samp <- samp[!is.na(samp$independent) & samp$independent == 1, ]

  run_cl <- function(ctrls, fe) {
    ctrls <- ctrls[!is.na(ctrls)]
    f <- as.formula(paste0(dv, " ~ ", paste(c(coupv, ctrls), collapse = " + "), " | ", fe, " + ", tv))
    m <- feols(f, data = samp, cluster = as.formula(paste0("~", idv)), warn = FALSE, notes = FALSE)
    coef(m)[coupv]
  }

  base_ctrl <- c(gdpv, popv)
  main_ctrl <- c(gdpv, popv, regv)
  emit("failed_coup_base_country_fe", safe(run_cl(base_ctrl, idv)))
  emit("failed_coup_main_country_fe", safe(run_cl(main_ctrl, idv)))
  emit("failed_coup_base_leader_fe", safe(run_cl(base_ctrl, leadv)))
  emit("failed_coup_main_leader_fe", safe(run_cl(main_ctrl, leadv)))
} else {
  for (n in c("failed_coup_base_country_fe", "failed_coup_main_country_fe",
              "failed_coup_base_leader_fe", "failed_coup_main_leader_fe")) emit(n, NA)
}

##############################
# Individual-level analysis  #
##############################

ind <- safe(readRDS(file.path(base_dir, "morning_after_dataset_individuallevel.rds")))

if (!is.null(ind)) {
  ind <- as.data.frame(ind)
  for (v in c("minister_type", "importance_factor", "experience_group", "party_group"))
    if (v %in% names(ind)) ind[[v]] <- as.character(ind[[v]])

  df_aut <- ind %>% filter(democracy_lag == 0 & leader == 0 & !is.na(purged_y1) &
                             !is.na(gdp_cap_pwt_ln) & !is.na(pop_pwt_ln))
  df_aut$fca <- as.numeric(df_aut$coupattempt_presentyear)
  df_aut$exp1 <- df_aut$experience
  df_aut$exp2 <- df_aut$experience^2
  df_aut$exp3 <- df_aut$experience^3

  # Build dummies + interactions for factor 'fac' with reference 'ref'
  run_int <- function(df, fac, ref, cubic) {
    df <- df[!is.na(df[[fac]]), ]
    lv <- setdiff(sort(unique(df[[fac]])), ref)
    dnames <- character(0); inames <- character(0)
    for (i in seq_along(lv)) {
      d <- paste0("D", i); ii <- paste0("I", i)
      df[[d]] <- as.numeric(df[[fac]] == lv[i])
      df[[ii]] <- df[[d]] * df$fca
      dnames <- c(dnames, d); inames <- c(inames, ii)
    }
    rhs <- c("fca", dnames, inames, "gdp_cap_pwt_ln", "pop_pwt_ln")
    if (cubic) rhs <- c(rhs, "exp1", "exp2", "exp3")
    f <- as.formula(paste0("purged_y1 ~ ", paste(rhs, collapse = " + "), " | country_isocode + year"))
    m <- feols(f, data = df, cluster = ~country_isocode, warn = FALSE, notes = FALSE)
    cf <- coef(m)
    ints <- setNames(cf[inames], lv)
    list(fca = cf["fca"], ints = ints, levels = lv)
  }

  pick <- function(lv, pat) { h <- lv[grepl(pat, lv, ignore.case = TRUE)]; if (length(h)) h[1] else NA_character_ }

  # H2a: Experience
  res <- safe({
    df_experience <- df_aut %>% filter(importance_factor != "0.5")
    lvs <- sort(unique(df_experience$experience_group[!is.na(df_experience$experience_group)]))
    ref <- pick(lvs, "less|<|^0|^1")
    if (is.na(ref)) ref <- lvs[1]
    out <- run_int(df_experience, "experience_group", ref, cubic = FALSE)
    over <- pick(out$levels, "over|>|\\+")
    if (is.na(over)) over <- tail(out$levels, 1)
    list(a = out$fca, b = out$ints[over])
  })
  emit("failed_coup_experience_model", res$a)
  emit("failed_coup_x_over_6_years_experience", res$b)

  # H2b: Affiliation
  res <- safe({
    df_party <- df_aut %>% filter(party_group != "unknown")
    out <- run_int(df_party, "party_group", "other_party", cubic = TRUE)
    list(a = out$fca, b = out$ints["leader_party"])
  })
  emit("failed_coup_affiliation_model", res$a)
  emit("failed_coup_x_leaders_party", res$b)

  # H3a: Responsibility
  res <- safe({
    lvs <- unique(df_aut$minister_type[!is.na(df_aut$minister_type)])
    ref <- pick(lvs, "defen")
    out <- run_int(df_aut, "minister_type", ref, cubic = TRUE)
    nr <- pick(out$levels, "natural")
    list(a = out$fca, b = out$ints[nr])
  })
  emit("failed_coup_responsibility_model", res$a)
  emit("failed_coup_x_natural_resources", res$b)

  # H3b: Importance
  res <- safe({
    df_importance <- df_aut %>% filter(importance_factor != "0" & !is.na(importance_factor))
    lvs <- unique(df_importance$importance_factor)
    ref <- pick(lvs, "^Prime minister")
    if (is.na(ref)) ref <- pick(lvs, "prime minister/president")
    out <- run_int(df_importance, "importance_factor", ref, cubic = TRUE)
    list(a = out$fca)
  })
  emit("failed_coup_importance_model", res$a)
} else {
  for (n in c("failed_coup_experience_model", "failed_coup_x_over_6_years_experience",
              "failed_coup_affiliation_model", "failed_coup_x_leaders_party",
              "failed_coup_responsibility_model", "failed_coup_x_natural_resources",
              "failed_coup_importance_model")) emit(n, NA)
