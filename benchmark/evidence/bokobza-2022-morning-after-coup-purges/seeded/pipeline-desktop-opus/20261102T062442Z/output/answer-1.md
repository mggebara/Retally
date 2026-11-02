suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges"

results <- list()
emit <- function(name, value) {
  if (!is.null(value) && length(value) == 1 && is.finite(value)) {
    results[[name]] <<- value
  }
}

safe_coef <- function(m, nm) {
  cf <- coef(m)
  if (nm %in% names(cf)) return(unname(cf[nm]))
  NA_real_
}

#############################
# Country-level analysis    #
#############################

tryCatch({
  dc <- haven::read_dta(file.path(base_dir, "morning_after_dataset_countrylevel.dta"))
  dc <- haven::zap_labels(dc)
  dc <- as.data.frame(dc)
  nms <- names(dc)
  message("Country-level columns: ", paste(nms, collapse = ", "))

  pick_first <- function(cands) {
    cands <- cands[cands %in% nms]
    if (length(cands)) cands[1] else NA_character_
  }

  cid <- pick_first(c("COUNTRY_ID", "country_id", "COUNTRY_DATA", "ccode", "cowcode"))
  yr  <- pick_first(c("YEAR_DATA", "year", "YEAR"))
  coupv <- pick_first(c("coupattempt_whogov", "coupattempt_presentyear"))
  dv <- "replacement_rateadj_minister"
  leadv <- pick_first(c("leader_cab_id", "leader_id", "leaderid"))
  if (is.na(leadv)) {
    lc <- grep("leader", nms, value = TRUE, ignore.case = TRUE)
    lc <- lc[grepl("id", lc, ignore.case = TRUE)]
    if (length(lc)) leadv <- lc[1]
  }

  # Find a "level" variable and whether it needs lagging
  find_var <- function(pattern, exclude = NULL, exact = NULL) {
    ex <- exact[exact %in% nms]
    if (length(ex)) return(list(var = ex[1], lagged = FALSE))
    c1 <- grep(pattern, nms, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) c1 <- c1[!grepl(exclude, c1, ignore.case = TRUE)]
    if (!length(c1)) return(NULL)
    # base names (whose "l"+name might also exist)
    base <- c1[!(substring(c1, 2) %in% c1 & substring(c1, 1, 1) == "l")]
    pref <- base[grepl("ln|log", base, ignore.case = TRUE)]
    if (length(pref)) {
      v <- pref[1]
      # if it starts with "l" and stripping gives a non-existent var containing ln/log, it's a lag already
      if (substring(v, 1, 1) == "l" && !(substring(v, 2) %in% nms) &&
          grepl("ln|log", substring(v, 2), ignore.case = TRUE) && !grepl("^ln|^log", v, ignore.case = TRUE)) {
        return(list(var = v, lagged = TRUE))
      }
      return(list(var = v, lagged = FALSE))
    }
    list(var = base[1], lagged = FALSE)
  }

  gdp <- find_var("gdp", exclude = "growth|gr_",
                  exact = c("gdp_cap_pwt_ln", "gdppc_pwt_ln", "gdp_pc_pwt_ln", "ln_gdp_pwt", "gdp_pwt_ln"))
  pop <- find_var("pop", exclude = "oil|valuepop",
                  exact = c("pop_pwt_ln", "ln_pop_pwt", "population_pwt_ln"))
  message("GDP var: ", gdp$var, " (lagged already: ", gdp$lagged, ")")
  message("Pop var: ", pop$var, " (lagged already: ", pop$lagged, ")")

  dc$cid__ <- dc[[cid]]
  dc$yr__ <- as.numeric(dc[[yr]])

  make_lag <- function(df, v) {
    tmp <- df[, c("cid__", "yr__", v)]
    names(tmp)[3] <- "val__"
    tmp$yr__ <- tmp$yr__ + 1
    tmp <- tmp[!duplicated(tmp[, c("cid__", "yr__")]), ]
    out <- merge(df[, c("cid__", "yr__")], tmp, by = c("cid__", "yr__"), all.x = TRUE, sort = FALSE)
    # align order
    key_df <- paste(df$cid__, df$yr__)
    key_out <- paste(out$cid__, out$yr__)
    out$val__[match(key_df, key_out)]
  }

  dc$L_gdp <- if (isTRUE(gdp$lagged)) dc[[gdp$var]] else make_lag(dc, gdp$var)
  dc$L_pop <- if (isTRUE(pop$lagged)) dc[[pop$var]] else make_lag(dc, pop$var)
  for (rv in c("military_c", "monarchy_c", "party_c")) {
    lv <- paste0("l", rv)
    if (lv %in% nms) dc[[paste0("L_", rv)]] <- dc[[lv]] else dc[[paste0("L_", rv)]] <- make_lag(dc, rv)
  }

  dsamp <- dc %>% filter(democracy1 == 0 & independent == 1 &
                           !is.na(.data[[coupv]]) & !is.na(.data[[dv]]))
  dsamp$coup__ <- as.numeric(dsamp[[coupv]])
  dsamp$dv__ <- as.numeric(dsamp[[dv]])
  if (!is.na(leadv)) dsamp$leader__ <- dsamp[[leadv]]

  # Base, country FE
  m1 <- feols(dv__ ~ coup__ + L_gdp + L_pop | cid__ + yr__, data = dsamp, cluster = ~cid__)
  message("Base country FE N=", nobs(m1))
  emit("failed_coup_base_country_fe", safe_coef(m1, "coup__"))

  # Main, country FE
  m2 <- feols(dv__ ~ coup__ + L_gdp + L_pop + L_military_c + L_monarchy_c + L_party_c | cid__ + yr__,
              data = dsamp, cluster = ~cid__)
  message("Main country FE N=", nobs(m2))
  emit("failed_coup_main_country_fe", safe_coef(m2, "coup__"))

  if (!is.na(leadv)) {
    m3 <- feols(dv__ ~ coup__ + L_gdp + L_pop | leader__ + yr__, data = dsamp, cluster = ~cid__)
    message("Base leader FE N=", nobs(m3))
    emit("failed_coup_base_leader_fe", safe_coef(m3, "coup__"))

    m4 <- feols(dv__ ~ coup__ + L_gdp + L_pop + L_military_c + L_monarchy_c + L_party_c | leader__ + yr__,
                data = dsamp, cluster = ~cid__)
    message("Main leader FE N=", nobs(m4))
    emit("failed_coup_main_leader_fe", safe_coef(m4, "coup__"))
  }
}, error = function(e) message("Country-level error: ", conditionMessage(e)))

#############################
# Individual-level analysis #
#############################

tryCatch({
  di <- readRDS(file.path(base_dir, "morning_after_dataset_individuallevel.rds"))
  di <- as.data.frame(di)
  if (inherits(di$year, "haven_labelled")) di <- haven::zap_labels(di)

  df_aut <- di %>% filter(democracy_lag == 0 & leader == 0 & !is.na(purged_y1) &
                            !is.na(gdp_cap_pwt_ln) & !is.na(pop_pwt_ln))
  df_aut$fca <- as.numeric(df_aut$coupattempt_presentyear)

  find_inter <- function(m, pattern) {
    cf <- coef(m)
    nm <- names(cf)
    hit <- nm[grepl(":", nm, fixed = TRUE) & grepl("fca", nm, fixed = TRUE) & grepl(pattern, nm)]
    if (length(hit)) unname(cf[hit[1]]) else NA_real_
  }

  ## Experience (H2a)
  tryCatch({
    df_experience <- df_aut %>% filter(as.character(importance_factor) != "0.5")
    eg <- as.character(df_experience$experience_group)
    ord <- tapply(df_experience$experience, eg, mean, na.rm = TRUE)
    lev <- names(sort(ord))
    df_experience$expg <- factor(eg, levels = lev)
    labs_map <- setNames(paste0("E", seq_along(lev)), lev)
    df_experience$expg <- factor(labs_map[eg], levels = paste0("E", seq_along(lev)))
    message("Experience group order: ", paste(lev, collapse = " | "))
    m_exp <- feols(purged_y1 ~ expg * fca + gdp_cap_pwt_ln + pop_pwt_ln | country_isocode + year,
                   data = df_experience, cluster = ~country_isocode)
    emit("failed_coup_experience_model", safe_coef(m_exp, "fca"))
    toplev <- paste0("E", length(lev))
    emit("failed_coup_x_over_6_years_experience", find_inter(m_exp, paste0("expg", toplev)))
  }, error = function(e) message("Experience error: ", conditionMessage(e)))

  ## Affiliation (H2b)
  tryCatch({
    df_party <- df_aut %>% filter(party_group != "unknown")
    pg <- as.character(df_party$party_group)
    pg <- dplyr::recode(pg, "independent" = "NoParty", "leader_party" = "LeaderParty",
                        "other_party" = "OtherParty",
                        "No party affiliation" = "NoParty", "From the leader's party" = "LeaderParty",
                        "From another party" = "OtherParty")
    df_party$pgrp <- factor(pg, levels = c("OtherParty", "NoParty", "LeaderParty"))
    m_aff <- feols(purged_y1 ~ pgrp * fca + gdp_cap_pwt_ln + pop_pwt_ln +
                     experience + I(experience^2) + I(experience^3) | country_isocode + year,
                   data = df_party, cluster = ~country_isocode)
    emit("failed_coup_affiliation_model", safe_coef(m_aff, "fca"))
    emit("failed_coup_x_leaders_party", find_inter(m_aff, "pgrpLeaderParty"))
  }, error = function(e) message("Affiliation error: ", conditionMessage(e)))

  ## Responsibility (H3a)
  tryCatch({
    mt <- as.character(df_aut$minister_type)
    df_r <- df_aut
    df_r$mtype <- dplyr::case_when(
      mt == "Minister of Defense" ~ "Defense",
      mt == "Minister of Foreign Affairs" ~ "Foreign",
      mt == "Minister of Finance" ~ "Finance",
      mt == "Other type of minister" ~ "Other",
      mt == "Minister of Natural Resources" ~ "NatRes",
      TRUE ~ NA_character_
    )
    df_r$mtype <- factor(df_r$mtype, levels = c("Defense", "Foreign", "Finance", "Other", "NatRes"))
    m_resp <- feols(purged_y1 ~ mtype * fca + gdp_cap_pwt_ln + pop_pwt_ln +
                      experience + I(experience^2) + I(experience^3) | country_isocode + year,
                    data = df_r, cluster = ~country_isocode)
    emit("failed_coup_responsibility_model", safe_coef(m_resp, "fca"))
    emit("failed_coup_x_natural_resources", find_inter(m_resp, "mtypeNatRes"))
  }, error = function(e) message("Responsibility error: ", conditionMessage(e)))

  ## Importance (H3b)
  tryCatch({
    df_importance <- df_aut %>% filter(as.character(importance_factor) != "0" & !is.na(importance_factor))
    imp <- as.character(df_importance$importance_factor)
    levs <- unique(imp)
    message("Importance levels: ", paste(gsub("\n", " ", levs), collapse = " | "))
    ref <- levs[grepl("Prime minister/President", levs, fixed = TRUE)]
    if (!length(ref)) ref <- levs[grepl("not leader", levs, ignore.case = TRUE)]
    if (!length(ref)) {
      # fallback: level with highest importance_numeric
      agg <- tapply(df_importance$importance_numeric, imp, mean, na.rm = TRUE)
      ref <- names(agg)[which.max(agg)]
    }
    ref <- ref[1]
    others <- setdiff(levs, ref)
    codes <- setNames(c("R0", paste0("R", seq_along(others))), c(ref, others))
    df_importance$impf <- factor(codes[imp], levels = c("R0", paste0("R", seq_along(others))))
    m_imp <- feols(purged_y1 ~ impf * fca + gdp_cap_pwt_ln + pop_pwt_ln +
                     experience + I(experience^2) + I(experience^3) | country_isocode + year,
                   data = df_importance, cluster = ~country_isocode)
    emit("failed_coup_importance_model", safe_coef(m_imp, "fca"))
  }, error = function(e) message("Importance error: ", conditionMessage(e)))

}, error = function(e) message("Individual-level error: ", conditionMessage(e)))

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}
