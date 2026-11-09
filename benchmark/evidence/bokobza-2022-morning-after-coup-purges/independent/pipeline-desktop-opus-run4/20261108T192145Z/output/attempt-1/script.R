suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
strip_labels <- function(df) {
  df <- as.data.frame(df)
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled")) {
      df[[v]] <- as.vector(zap_labels(x))
    }
  }
  df
}

find_var <- function(nms, patterns, exclude = NULL) {
  for (p in patterns) {
    hits <- grep(p, nms, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) {
      for (e in exclude) hits <- hits[!grepl(e, hits, ignore.case = TRUE)]
    }
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

emit <- function(name, value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(value)))
  }
}

get_coef <- function(model, pattern) {
  if (is.null(model)) return(NA)
  cf <- coef(model)
  hit <- grep(pattern, names(cf), value = TRUE)
  if (length(hit) == 0) return(NA)
  cf[hit[1]]
}

# ---------------------------------------------------------------------------
# Country level
# ---------------------------------------------------------------------------
cl <- strip_labels(read_dta(file.path(base_dir, "morning_after_dataset_countrylevel.dta")))
nms <- names(cl)
cat("Country-level columns:\n"); print(nms)

v_year    <- if ("YEAR_DATA" %in% nms) "YEAR_DATA" else find_var(nms, c("^year"))
v_country <- if ("COUNTRY_ID" %in% nms) "COUNTRY_ID" else find_var(nms, c("country"))
v_leader  <- if ("leader_cab_id" %in% nms) "leader_cab_id" else find_var(nms, c("leader.*id"))
v_dv      <- "replacement_rateadj_minister"
v_ldem    <- if ("ldemocracy_br" %in% nms) "ldemocracy_br" else find_var(nms, c("ldemocracy", "democracy.*lag"))

# failed coup indicator
v_fail <- find_var(nms, c("fail"), exclude = c("_br", "lag", "last"))
if (is.na(v_fail)) {
  v_att <- if ("coupattempt_whogov" %in% nms) "coupattempt_whogov" else find_var(nms, c("coupattempt"), exclude = c("_br", "mon"))
  v_succ <- find_var(nms, c("^coup_whogov$", "^coup_whogov", "coupsuccess", "^coup_present", "^coup$"), exclude = c("attempt", "_br"))
  cat("Failed coup built from:", v_att, v_succ, "\n")
  if (!is.na(v_succ)) {
    cl$failed_coup <- as.numeric(cl[[v_att]] > 0 & !(cl[[v_succ]] > 0 & !is.na(cl[[v_succ]])))
    cl$failed_coup[is.na(cl[[v_att]])] <- NA
  } else {
    cl$failed_coup <- as.numeric(cl[[v_att]] > 0)
  }
} else {
  cat("Failed coup variable:", v_fail, "\n")
  cl$failed_coup <- as.numeric(cl[[v_fail]] > 0)
}

# controls: lagged log GDP pc and log population
v_gdp <- find_var(nms, c("^l.*gdp.*pc.*ln", "^l.*ln.*gdp", "^l.*rgdpe.*pc", "^l.*gdp", "gdp.*pc.*ln", "ln.*gdp", "gdp"), exclude = c("growth"))
v_pop <- find_var(nms, c("^l.*pop.*ln", "^l.*ln.*pop", "^l.*pop", "pop.*ln", "ln.*pop", "pop"), exclude = c("oil"))
cat("GDP var:", v_gdp, " Pop var:", v_pop, "\n")

cl <- cl[order(cl[[v_country]], cl[[v_year]]), ]
make_lag <- function(df, v) {
  out <- rep(NA_real_, nrow(df))
  idx <- split(seq_len(nrow(df)), df[[v_country]])
  for (ii in idx) {
    yrs <- df[[v_year]][ii]
    x <- df[[v]][ii]
    out[ii] <- x[match(yrs - 1, yrs)]
  }
  out
}
to_log <- function(x) if (all(x[!is.na(x)] > 0) && max(x, na.rm = TRUE) > 100) log(x) else x

already_lagged <- function(v) grepl("^l", v) && !grepl("^ln", v) || grepl("lag", v, ignore.case = TRUE)
cl$gdp_raw <- to_log(cl[[v_gdp]])
cl$pop_raw <- to_log(cl[[v_pop]])
cl$l_gdp <- if (already_lagged(v_gdp)) cl$gdp_raw else make_lag(cl, "gdp_raw")
cl$l_pop <- if (already_lagged(v_pop)) cl$pop_raw else make_lag(cl, "pop_raw")

for (v in c("military_c", "monarchy_c", "party_c")) {
  cl[[paste0("l_", v)]] <- if (v %in% nms) make_lag(cl, v) else NA
}

# autocracy sample: lagged BMR democracy == 0
if (!is.na(v_ldem)) {
  aut <- cl[!is.na(cl[[v_ldem]]) & cl[[v_ldem]] == 0, ]
} else {
  cl$ldem_tmp <- make_lag(cl, "democracy_br")
  aut <- cl[!is.na(cl$ldem_tmp) & cl$ldem_tmp == 0, ]
}
aut <- aut[aut[[v_year]] >= 1967 & aut[[v_year]] <= 2016, ]
aut$cty <- aut[[v_country]]
aut$yr <- aut[[v_year]]
aut$ldr <- aut[[v_leader]]
aut$P <- aut[[v_dv]]
cat("Autocracy country-years with DV:", sum(!is.na(aut$P)), "\n")

run_fe <- function(fml, data) {
  tryCatch(feols(fml, data = data, cluster = ~cty), error = function(e) { message(e$message); NULL })
}

m_base_c <- run_fe(P ~ failed_coup + l_gdp + l_pop | cty + yr, aut)
m_main_c <- run_fe(P ~ failed_coup + l_gdp + l_pop + l_military_c + l_party_c + l_monarchy_c | cty + yr, aut)
m_base_l <- run_fe(P ~ failed_coup + l_gdp + l_pop | ldr + yr, aut)
m_main_l <- run_fe(P ~ failed_coup + l_gdp + l_pop + l_military_c + l_party_c + l_monarchy_c | ldr + yr, aut)
for (m in list(m_base_c, m_main_c, m_base_l, m_main_l)) if (!is.null(m)) print(summary(m))

# ---------------------------------------------------------------------------
# Individual level
# ---------------------------------------------------------------------------
il <- readRDS(file.path(base_dir, "morning_after_dataset_individuallevel.rds"))
il <- strip_labels(il)
inms <- names(il)
cat("Individual-level columns:\n"); print(inms)

# failed coup
iv_fail <- find_var(inms, c("fail"), exclude = c("_br"))
if (!is.na(iv_fail)) {
  il$failed_coup <- as.numeric(il[[iv_fail]] > 0)
} else {
  att <- il$coupattempt_presentyear
  suc <- if ("coup_presentyear" %in% inms) il$coup_presentyear else 0
  il$failed_coup <- as.numeric(att > 0 & !(suc > 0 & !is.na(suc)))
  il$failed_coup[is.na(att)] <- NA
}

# autocracy sample
if ("democracy_lag_br" %in% inms) il <- il[!is.na(il$democracy_lag_br) & il$democracy_lag_br == 0, ]
il <- il[il$year >= 1967 & il$year <= 2016, ]

# exclude the leader
if ("leader" %in% inms) {
  ld <- il$leader
  if (is.numeric(ld)) il <- il[is.na(ld) | ld != 1, ] else il <- il[is.na(ld) | !(tolower(as.character(ld)) %in% c("1", "yes", "true", "leader")), ]
}

# controls: try to find in individual data, else merge from country-level
ig <- find_var(inms, c("gdp"), exclude = c("growth"))
ip <- find_var(inms, c("pop"))
if (!is.na(ig) && !is.na(ip)) {
  il$l_gdp <- to_log(il[[ig]]); il$l_pop <- to_log(il[[ip]])
} else {
  iso_cl <- find_var(nms, c("isocode", "iso"))
  if (!is.na(iso_cl)) {
    key <- data.frame(country_isocode = cl[[iso_cl]], year = cl[[v_year]], l_gdp = cl$l_gdp, l_pop = cl$l_pop)
  } else {
    key <- data.frame(country_name = cl[[v_country]], year = cl[[v_year]], l_gdp = cl$l_gdp, l_pop = cl$l_pop)
  }
  key <- key[!duplicated(key[, 1:2]), ]
  il <- left_join(il, key, by = names(key)[1:2])
}

il$cty <- il$country_isocode
il$exp <- as.numeric(il$experience)
il$exp2 <- il$exp^2
il$exp3 <- il$exp^3
il$purged <- as.numeric(il$purged_y1)

cat("Tables of moderators:\n")
for (v in c("experience_group", "party_group", "Group", "portfolio_1", "prestige_1", "classification")) {
  if (v %in% inms) { cat(v, ":\n"); print(table(il[[v]], useNA = "ifany")) }
}

run_lpm <- function(fml, data) {
  tryCatch(feols(fml, data = data, cluster = ~cty), error = function(e) { message(e$message); NULL })
}

relevel_to <- function(x, pat) {
  f <- factor(as.character(x))
  lv <- levels(f)
  hit <- grep(pat, lv, value = TRUE, ignore.case = TRUE)
  if (length(hit) > 0) f <- relevel(f, ref = hit[1])
  f
}

# low-ranking / junior identification for H2a exclusion
lowrank <- rep(FALSE, nrow(il))
if ("prestige_1" %in% inms) lowrank <- lowrank | grepl("junior|low", as.character(il$prestige_1), ignore.case = TRUE)

# H2a experience: groups <2, 2-3, 4-6, >6
if ("experience_group" %in% inms) {
  il$expg <- relevel_to(il$experience_group, "<\\s*2|less|under|^0|^1")
} else {
  il$expg <- cut(il$exp, c(-Inf, 1, 3, 6, Inf), labels = c("lt2", "2-3", "4-6", "gt6"))
}
d_exp <- il[!lowrank, ]
m_exp <- run_lpm(purged ~ failed_coup * expg + l_gdp + l_pop | cty + year, d_exp)
if (!is.null(m_exp)) print(summary(m_exp))

# H2b affiliation, ref: other party
il$aff <- relevel_to(il$party_group, "other|another")
m_aff <- run_lpm(purged ~ failed_coup * aff + exp + exp2 + exp3 + l_gdp + l_pop | cty + year, il)
if (!is.null(m_aff)) print(summary(m_aff))

# H3a responsibility, ref: defense
port_var <- if ("Group" %in% inms && any(grepl("defen", il$Group, ignore.case = TRUE))) "Group" else "portfolio_1"
pv <- as.character(il[[port_var]])
if (port_var == "portfolio_1" && length(unique(pv)) > 10) {
  pv <- ifelse(grepl("defen", pv, ignore.case = TRUE), "Defense",
        ifelse(grepl("foreign", pv, ignore.case = TRUE), "Foreign",
        ifelse(grepl("financ", pv, ignore.case = TRUE), "Finance",
        ifelse(grepl("natural|oil|petrol|mine|mining|energy", pv, ignore.case = TRUE), "NaturalResources", "Other"))))
}
il$port <- relevel_to(pv, "defen")
m_resp <- run_lpm(purged ~ failed_coup * port + exp + exp2 + exp3 + l_gdp + l_pop | cty + year, il)
if (!is.null(m_resp)) print(summary(m_resp))

# H3b importance, ref: PM/President (not leader)
imp <- if ("prestige_1" %in% inms) il$prestige_1 else il$importance_numeric
il$imp <- relevel_to(imp, "prime|president|^5$|^1$")
m_imp <- run_lpm(purged ~ failed_coup * imp + exp + exp2 + exp3 + l_gdp + l_pop | cty + year, il)
if (!is.null(m_imp)) print(summary(m_imp))

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
emit("failed_coup_base_country_fe", get_coef(m_base_c, "^failed_coup$"))
emit("failed_coup_main_country_fe", get_coef(m_main_c, "^failed_coup$"))
emit("failed_coup_base_leader_fe", get_coef(m_base_l, "^failed_coup$"))
emit("failed_coup_main_leader_fe", get_coef(m_main_l, "^failed_coup$"))
emit("failed_coup_experience_model", get_coef(m_exp, "^failed_coup$"))
emit("failed_coup_x_over_6_years_experience", get_coef(m_exp, "failed_coup:expg.*(>|over|more|gt|6)"))
emit("failed_coup_affiliation_model", get_coef(m_aff, "^failed_coup$"))
emit("failed_coup_x_leaders_party", get_coef(m_aff, "failed_coup:aff.*leader"))
emit("failed_coup_responsibility_model", get_coef(m_resp, "^failed_coup$"))
emit("failed_coup_x_natural_resources", get_coef(m_resp, "failed_coup:port.*(natural|resource)"))
emit("failed_coup_importance_model", get_coef(m_imp, "^failed_coup$"))