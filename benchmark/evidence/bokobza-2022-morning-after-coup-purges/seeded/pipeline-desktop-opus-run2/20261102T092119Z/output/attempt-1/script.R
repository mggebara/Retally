suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(data.table)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges"
results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}

# -------------------------------------------------------------------
# Country-level models (Tables A1, A2)
# -------------------------------------------------------------------
tryCatch({
  cl <- read_dta(file.path(base_dir, "morning_after_dataset_countrylevel.dta"))
  cl <- as.data.frame(zap_labels(cl))
  nm <- names(cl)
  cat("Country-level columns:", paste(nm, collapse = ", "), "\n")

  pick <- function(exact, pattern, exclude = NULL) {
    if (exact %in% nm) return(exact)
    cand <- grep(pattern, nm, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) cand <- cand[!grepl(exclude, cand, ignore.case = TRUE)]
    if (length(cand) == 0) return(NA_character_)
    cand[1]
  }

  dv <- "replacement_rateadj_minister"
  coupv <- pick("coupattempt_whogov", "^coupattempt_whogov$|^coupattempt", "month|type|br|_l|lag")
  gdpv <- pick("gdp_cap_pwt_ln", "gdp.*(ln|log)|(ln|log).*gdp", "growth|^l")
  if (is.na(gdpv)) gdpv <- pick("gdp_cap_pwt_ln", "gdp", "growth")
  popv <- pick("pop_pwt_ln", "^pop.*(ln|log)|^(ln|log).*pop|pop_pwt", "valuepop|oil")
  if (is.na(popv)) popv <- pick("pop_pwt_ln", "pop", "valuepop|oil")
  cat("Using coup:", coupv, " gdp:", gdpv, " pop:", popv, "\n")

  cl$cid <- cl$COUNTRY_ID
  cl$yr <- as.numeric(cl$YEAR_DATA)

  # Lag one year (respecting gaps) via merge on year - 1
  lagvars <- intersect(c(gdpv, popv, "military_c", "party_c", "monarchy_c", "democracy_br"), nm)
  lagdf <- cl[, c("cid", "yr", lagvars)]
  lagdf$yr <- lagdf$yr + 1
  names(lagdf)[-(1:2)] <- paste0("L_", lagvars)
  lagdf <- lagdf[!duplicated(lagdf[, c("cid", "yr")]), ]
  cl <- merge(cl, lagdf, by = c("cid", "yr"), all.x = TRUE)

  if ("ldemocracy_br" %in% nm) {
    cl$aut_lag <- cl$ldemocracy_br
  } else if ("L_democracy_br" %in% names(cl)) {
    cl$aut_lag <- cl$L_democracy_br
  } else {
    cl$aut_lag <- cl$democracy1
  }

  d <- cl[!is.na(cl$aut_lag) & cl$aut_lag == 0 & !is.na(cl[[dv]]) & !is.na(cl[[coupv]]), ]
  d$y <- as.numeric(d[[dv]])
  d$fca <- as.numeric(d[[coupv]])
  d$lgdp <- d[[paste0("L_", gdpv)]]
  d$lpop <- d[[paste0("L_", popv)]]
  d$lmil <- d$L_military_c
  d$lpar <- d$L_party_c
  d$lmon <- d$L_monarchy_c
  d$leader_fe <- paste(d$cid, d$leader_cab_id, sep = "_")
  d$leader_fe[is.na(d$leader_cab_id)] <- NA
  cat("Country-level autocratic sample N:", nrow(d), "\n")

  f_base_c <- feols(y ~ fca + lgdp + lpop | cid + yr, data = d, cluster = ~cid)
  f_main_c <- feols(y ~ fca + lgdp + lpop + lmil + lpar + lmon | cid + yr, data = d, cluster = ~cid)
  f_base_l <- feols(y ~ fca + lgdp + lpop | leader_fe + yr, data = d, cluster = ~cid)
  f_main_l <- feols(y ~ fca + lgdp + lpop + lmil + lpar + lmon | leader_fe + yr, data = d, cluster = ~cid)

  for (m in list(f_base_c, f_main_c, f_base_l, f_main_l)) print(summary(m))

  emit("failed_coup_base_country_fe", unname(coef(f_base_c)["fca"]))
  emit("failed_coup_main_country_fe", unname(coef(f_main_c)["fca"]))
  emit("failed_coup_base_leader_fe", unname(coef(f_base_l)["fca"]))
  emit("failed_coup_main_leader_fe", unname(coef(f_main_l)["fca"]))
  emit("failed_coup_base_country_fe_se", unname(se(f_base_c)["fca"]))
  emit("failed_coup_main_country_fe_se", unname(se(f_main_c)["fca"]))
  emit("failed_coup_base_leader_fe_se", unname(se(f_base_l)["fca"]))
  emit("failed_coup_main_leader_fe_se", unname(se(f_main_l)["fca"]))
}, error = function(e) cat("Country-level error:", conditionMessage(e), "\n"))

# -------------------------------------------------------------------
# Individual-level models (Tables K1, K2)
# -------------------------------------------------------------------
safe_relevel <- function(x, lv) {
  x <- as.character(x)
  present <- unique(x[!is.na(x)])
  lv <- lv[lv %in% present]
  factor(x, levels = c(lv, sort(setdiff(present, lv))))
}

find_int <- function(model, level_pattern) {
  cn <- names(coef(model))
  ints <- cn[grepl("coupattempt_presentyear", cn) & grepl(":", cn)]
  hit <- ints[grepl(level_pattern, ints, ignore.case = TRUE)]
  if (length(hit) == 0) return(NA_real_)
  unname(coef(model)[hit[1]])
}

tryCatch({
  ind <- readRDS(file.path(base_dir, "morning_after_dataset_individuallevel.rds"))
  ind <- as.data.frame(ind)
  for (v in names(ind)) if (inherits(ind[[v]], "haven_labelled")) ind[[v]] <- zap_labels(ind[[v]])
  cat("Individual-level columns:", paste(names(ind), collapse = ", "), "\n")

  demv <- if ("democracy_lag" %in% names(ind)) "democracy_lag" else "democracy_lag_br"
  ind$dem_lag_use <- as.numeric(ind[[demv]])
  ind$coupattempt_presentyear <- as.numeric(ind$coupattempt_presentyear)
  ind$purged_y1 <- as.numeric(ind$purged_y1)
  ind$experience <- as.numeric(ind$experience)

  df_aut <- ind %>% filter(dem_lag_use == 0 & leader == 0 & !is.na(purged_y1) &
                             !is.na(gdp_cap_pwt_ln) & !is.na(pop_pwt_ln))
  cat("df_aut N:", nrow(df_aut), "\n")

  ctrl_poly <- "gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) + I(experience^3)"

  # ---- H3a Responsibility ----
  tryCatch({
    dr <- df_aut
    dr$minister_type <- safe_relevel(dr$minister_type,
      c("Minister of Defense", "Minister of Foreign Affairs", "Minister of Finance",
        "Other type of minister", "Minister of Natural Resources"))
    m_resp <- feols(as.formula(paste("purged_y1 ~ minister_type*coupattempt_presentyear +", ctrl_poly,
                                     "| country_isocode + year")),
                    data = dr, cluster = ~country_isocode)
    print(summary(m_resp))
    emit("failed_coup_responsibility_model", unname(coef(m_resp)["coupattempt_presentyear"]))
    emit("failed_coup_x_natural_resources", find_int(m_resp, "Natural"))
  }, error = function(e) cat("Responsibility error:", conditionMessage(e), "\n"))

  # ---- H2b Affiliation ----
  tryCatch({
    df_party <- df_aut %>% filter(party_group != "unknown")
    pg <- as.character(df_party$party_group)
    pg <- dplyr::recode(pg, "independent" = "No party affiliation",
                        "leader_party" = "From the leader's party",
                        "other_party" = "From another party")
    df_party$party_group <- safe_relevel(pg, c("From another party", "No party affiliation",
                                               "From the leader's party"))
    m_aff <- feols(as.formula(paste("purged_y1 ~ party_group*coupattempt_presentyear +", ctrl_poly,
                                    "| country_isocode + year")),
                   data = df_party, cluster = ~country_isocode)
    print(summary(m_aff))
    emit("failed_coup_affiliation_model", unname(coef(m_aff)["coupattempt_presentyear"]))
    emit("failed_coup_x_leaders_party", find_int(m_aff, "leader"))
  }, error = function(e) cat("Affiliation error:", conditionMessage(e), "\n"))

  # ---- H3b Importance ----
  tryCatch({
    df_imp <- df_aut %>% filter(as.character(importance_factor) != "0" & !is.na(importance_factor))
    df_imp$importance_factor <- safe_relevel(df_imp$importance_factor,
      c("Prime minister/President\n(not leader)",
        "Vice president,\ndeputy prime minister,\ntop minister",
        "Medium-ranking\nminister", "Low-ranking\nminister",
        "Junior minister\nor other low-\nranking post"))
    cat("Importance levels:", paste(levels(df_imp$importance_factor), collapse = " | "), "\n")
    m_imp <- feols(as.formula(paste("purged_y1 ~ importance_factor*coupattempt_presentyear +", ctrl_poly,
                                    "| country_isocode + year")),
                   data = df_imp, cluster = ~country_isocode)
    print(summary(m_imp))
    emit("failed_coup_importance_model", unname(coef(m_imp)["coupattempt_presentyear"]))
  }, error = function(e) cat("Importance error:", conditionMessage(e), "\n"))

  # ---- H2a Experience ----
  tryCatch({
    df_exp <- df_aut %>% filter(as.character(importance_factor) != "0.5")
    eg <- df_exp$experience_group
    if (is.factor(eg)) {
      lv <- levels(eg)
      eg <- as.character(eg)
    } else {
      u <- unique(eg[!is.na(eg)])
      if (is.numeric(u)) lv <- as.character(sort(u)) else lv <- sort(as.character(u))
      eg <- as.character(eg)
    }
    ref <- lv[grepl("less|<|under|0-1|^1$", lv, ignore.case = TRUE)]
    lv <- c(ref, setdiff(lv, ref))
    df_exp$experience_group <- factor(eg, levels = lv)
    cat("Experience levels:", paste(levels(df_exp$experience_group), collapse = " | "), "\n")
    m_exp <- feols(purged_y1 ~ experience_group*coupattempt_presentyear + gdp_cap_pwt_ln + pop_pwt_ln |
                     country_isocode + year, data = df_exp, cluster = ~country_isocode)
    print(summary(m_exp))
    emit("failed_coup_experience_model", unname(coef(m_exp)["coupattempt_presentyear"]))
    val <- find_int(m_exp, "over|>|more|6\\+")
    if (is.na(val)) {
      last_lv <- tail(levels(df_exp$experience_group), 1)
      val <- find_int(m_exp, paste0("experience_group", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", last_lv), ":"))
    }
    emit("failed_coup_x_over_6_years_experience", val)
  }, error = function(e) cat("Experience error:", conditionMessage(e), "\n"))
}, error = function(e) cat("Individual-level error:", conditionMessage(e), "\n"))

# -------------------------------------------------------------------
for (n in names(results)) cat(sprintf("RESULT:%s=%.6f\n", n, results[[n]]))