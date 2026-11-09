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

# convert factor / character / logical to numeric 0/1 (or numeric codes)
to_num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  ch <- as.character(x)
  ok <- !is.na(ch) & trimws(ch) != ""
  y <- suppressWarnings(as.numeric(ch))
  if (sum(ok) == 0 || sum(!is.na(y[ok])) >= 0.9 * sum(ok)) return(y)
  lc <- tolower(trimws(ch))
  ifelse(!ok, NA_real_,
         ifelse(grepl("^(no|none|false|non|not)|^0$|no coup|no attempt", lc), 0, 1))
}

# autocracy indicator from a (lagged) democracy variable of any type
is_autocracy <- function(x) {
  if (is.numeric(x) || is.logical(x)) return(!is.na(x) & as.numeric(x) == 0)
  ch <- as.character(x)
  y <- suppressWarnings(as.numeric(ch))
  ok <- !is.na(ch) & trimws(ch) != ""
  if (sum(ok) > 0 && sum(!is.na(y[ok])) >= 0.9 * sum(ok)) return(!is.na(y) & y == 0)
  lc <- tolower(trimws(ch))
  !is.na(ch) & grepl("autoc|dictat|non-?democ|not democ|^no$|^0$", lc)
}

safe_filter <- function(df, keep, label) {
  keep[is.na(keep)] <- FALSE
  cat(sprintf("Filter '%s': keeps %d of %d rows\n", label, sum(keep), nrow(df)))
  if (sum(keep) == 0) {
    cat(sprintf("DEVIATION: filter '%s' would drop all rows (coding mismatch); filter skipped\n", label))
    return(df)
  }
  df[keep, , drop = FALSE]
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
cat("Individual-level rows:", nrow(il), "\n")
cat("Column classes:\n"); print(sapply(il, function(z) class(z)[1]))
for (v in c("democracy_lag_br", "leader", "coupattempt_presentyear", "coup_presentyear", "purged_y1")) {
  if (v %in% inms) { cat(v, ":\n"); print(head(table(il[[v]], useNA = "ifany"), 20)) }
}

il$year <- suppressWarnings(as.numeric(as.character(il$year)))

# failed coup
iv_fail <- find_var(inms, c("fail"), exclude = c("_br"))
if (!is.na(iv_fail)) {
  il$failed_coup <- as.numeric(to_num(il[[iv_fail]]) > 0)
} else {
  att_raw <- il$coupattempt_presentyear
  if (!is.numeric(att_raw) && any(grepl("fail", as.character(att_raw), ignore.case = TRUE))) {
    il$failed_coup <- as.numeric(grepl("fail", as.character(att_raw), ignore.case = TRUE))
    il$failed_coup[is.na(att_raw)] <- NA
  } else {
    att <- to_num(att_raw)
    suc <- if ("coup_presentyear" %in% inms) to_num(il$coup_presentyear) else rep(0, nrow(il))
    il$failed_coup <- as.numeric(att > 0 & !(suc > 0 & !is.na(suc)))
    il$failed_coup[is.na(att)] <- NA
  }
}
cat("Failed coup (individual):\n"); print(table(il$failed_coup, useNA = "ifany"))

# autocracy sample
if ("democracy_lag_br" %in% inms) il <- safe_filter(il, is_autocracy(il$democracy_lag_br), "autocracy")
il <- safe_filter(il, il$year >= 1967 & il$year <= 2016, "years 1967-2016")

# exclude the leader
if ("leader" %in% inms) {
  ldn <- to_num(il$leader)
  il <- safe_filter(il, is.na(ldn) | ldn != 1, "exclude leader")
}

# controls: lagged log GDP pc and log population from individual data
if (all(c("gdp_cap_pwt_ln_lag", "pop_pwt_ln_lag") %in% names(il))) {
  il$l_gdp <- to_num(il$gdp_cap_pwt_ln_lag)
  il$l_pop <- to_num(il$pop_pwt_ln_lag)
} else {
  ig <- find_var(names(il), c("gdp"), exclude = c("growth"))
  ip <- find_var(names(il), c("pop"))
  il$l_gdp <- to_log(to_num(il[[ig]])); il$l_pop <- to_log(to_num(il[[ip]]))
}

il$cty <- as.character(il$country_isocode)
il$exp <- to_num(il$experience)
il$exp2 <- il$exp^2
il$exp3 <- il$exp^3
il$purged <- to_num(il$purged_y1)
cat("Purged:\n"); print(table(il$purged, useNA = "ifany"))

cat("Tables of moderators:\n")
for (v in c("experience_group", "party_group", "Group", "portfolio_1", "prestige_1", "importance_factor", "importance_numeric", "classification")) {
  if (v %in% names(il)) { cat(v, ":\n"); print(head(table(il[[v]], useNA = "ifany"), 40)) }
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
if ("prestige_1" %in% names(il)) lowrank <- lowrank | grepl("junior|low", as.character(il$prestige_1), ignore.case = TRUE)
if ("classification" %in% names(il)) lowrank <- lowrank | grepl("junior", as.character(il$classification), ignore.case = TRUE)
lowrank[is.na(lowrank)] <- FALSE
cat("Low-ranking/junior excluded for experience model:", sum(lowrank), "\n")

# H2a experience: groups <2, 2-3, 4-6, >6 (reference <2)
if (sum(!is.na(il$exp)) > 0) {
  il$expg <- cut(il$exp, c(-Inf, 1, 3, 6, Inf), labels = c("lt2", "y2_3", "y4_6", "gt6"))
} else {
  il$expg <- relevel_to(il$experience_group, "<\\s*2|less|under|^0|^1")
}
print(table(il$expg, useNA = "ifany"))
d_exp <- il[!lowrank, ]
m_exp <- run_lpm(purged ~ failed_coup * expg + l_gdp + l_pop | cty + year, d_exp)
if (!is.null(m_exp)) print(summary(m_exp))

# H2b affiliation, ref: other party
il$aff <- relevel_to(il$party_group, "other|another")
m_aff <- run_lpm(purged ~ failed_coup * aff + exp + exp2 + exp3 + l_gdp + l_pop | cty + year, il)
if (!is.null(m_aff)) print(summary(m_aff))

# H3a responsibility, ref: defense
port_var <- if ("Group" %in% names(il) && any(grepl("defen", as.character(il$Group), ignore.case = TRUE))) "Group" else "portfolio_1"
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
imp <- if ("importance_factor" %in% names(il)) il$importance_factor else if ("prestige_1" %in% names(il)) il$prestige_1 else il$importance_numeric
imp_ch <- as.character(imp)
if (any(grepl("prime|presid", imp_ch, ignore.case = TRUE))) {
  il$imp <- relevel_to(imp_ch, "prime|presid")
} else {
  impn <- suppressWarnings(as.numeric(imp_ch))
  f <- factor(imp_ch)
  if (sum(!is.na(impn)) > 0) f <- relevel(f, ref = as.character(max(impn, na.rm = TRUE)))
  il$imp <- f
}
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
emit("failed_coup_x_over_6_years_experience", get_coef(m_exp, "failed_coup:expg(gt6|.*>|.*over|.*more)"))
emit("failed_coup_affiliation_model", get_coef(m_aff, "^failed_coup$"))
emit("failed_coup_x_leaders_party", get_coef(m_aff, "failed_coup:aff.*leader"))
emit("failed_coup_responsibility_model", get_coef(m_resp, "^failed_coup$"))
emit("failed_coup_x_natural_resources", get_coef(m_resp, "failed_coup:port.*(natural|resource)"))
emit("failed_coup_importance_model", get_coef(m_imp, "^failed_coup$"))