suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
to_num <- function(x) {
  if (inherits(x, "haven_labelled") || inherits(x, "labelled")) x <- zap_labels(x)
  if (is.factor(x)) x <- as.numeric(as.character(x))
  suppressWarnings(as.numeric(x))
}
to_fac <- function(x) {
  if (inherits(x, "haven_labelled")) x <- as_factor(x, levels = "default")
  x <- as.character(x)
  factor(x)
}
pick <- function(nms, candidates) {
  out <- intersect(candidates, nms)
  if (length(out) == 0) return(NULL)
  out[1]
}

# ------------------------------------------------------------------
# Individual-level survey: Table 1
# ------------------------------------------------------------------
sv_raw <- read_dta(file.path(base_dir, "survey.dta"))
nms <- names(sv_raw)
cat(sprintf("SAMPLE:table1:loaded=%d\n", nrow(sv_raw)))

wave_num <- to_num(sv_raw$wave)
w4 <- if (any(wave_num == 4, na.rm = TRUE)) 4 else max(wave_num, na.rm = TRUE)
sv <- sv_raw[!is.na(wave_num) & wave_num == w4, ]
cat(sprintf("SAMPLE:table1:wave4=%d\n", nrow(sv)))

d <- data.frame(
  only_means = to_num(sv$hate_violence_means),
  mate = to_num(sv[["MateComp.cont"]]),
  job = to_num(sv[["JobComp.cont"]]),
  lifesat = to_num(sv[["LifeSatis.cont"]])
)

# Sociodemographics
socio_num <- c()
socio_fac <- c()
add_num <- function(v, newname) {
  if (!is.null(v)) { d[[newname]] <<- to_num(sv[[v]]); socio_num <<- c(socio_num, newname) }
}
add_fac <- function(v, newname) {
  if (!is.null(v)) { d[[newname]] <<- to_fac(sv[[v]]); socio_fac <<- c(socio_fac, newname) }
}
add_num(pick(nms, c("age")), "s_age")
add_fac(pick(nms, c("gender")), "s_gender")
add_num(pick(nms, c("eduyrs", "education", "edu")), "s_edu")
add_fac(pick(nms, c("income")), "s_income")
add_fac(pick(nms, c("occupation", "main_activity")), "s_occupation")
emp_var <- pick(nms, c("employment", "employment_status", "empl_status", "employed", "emp_status", "work_status"))
if (is.null(emp_var)) {
  g <- grep("employ|empl", nms, value = TRUE, ignore.case = TRUE)
  g <- setdiff(g, c("occupation"))
  if (length(g) > 0) emp_var <- g[1]
}
add_fac(emp_var, "s_employment")
add_fac(pick(nms, c("citizenship")), "s_citizen")
add_num(pick(nms, c("household_size")), "s_hhsize")
add_num(pick(nms, c("self_econ", "social_status", "self_status")), "s_status")
add_fac(pick(nms, c("religion")), "s_religion")
add_fac(pick(nms, c("state")), "s_state")

# National refugee attitudes: ref_* but not ref_loc_*
excluded_ref <- c("ref_id")
nat_vars <- setdiff(grep("^ref_", nms, value = TRUE), grep("^ref_loc_", nms, value = TRUE))
nat_vars <- setdiff(nat_vars, excluded_ref)
loc_vars <- grep("^ref_loc_", nms, value = TRUE)
nat_names <- paste0("n_", nat_vars)
loc_names <- paste0("l_", loc_vars)
for (i in seq_along(nat_vars)) d[[nat_names[i]]] <- to_num(sv[[nat_vars[i]]])
for (i in seq_along(loc_vars)) d[[loc_names[i]]] <- to_num(sv[[loc_vars[i]]])

# Additional controls (column 6)
add_vars <- intersect(c("contact_ind", "distance_ref", "settle_ref", "refugee_ind",
                        "afd", "afd_ind", "lrscale", "muslim_ind"), nms)
add_names <- paste0("a_", add_vars)
for (i in seq_along(add_vars)) d[[add_names[i]]] <- to_num(sv[[add_vars[i]]])

mk <- function(vars) as.formula(paste("only_means ~", paste(vars, collapse = " + ")))

v1 <- c("mate")
v2 <- c(v1, "job", "lifesat")
v3 <- c(v2, socio_num, socio_fac)
v4 <- c(v3, nat_names)
v5 <- c(v4, loc_names)
v6 <- c(v5, add_names)

# Columns 1-2 common sample; columns 3-6 common sample on the col-3 variables
s12 <- complete.cases(d[, c("only_means", v2)])
s36 <- complete.cases(d[, c("only_means", v3)])

m1 <- lm(mk(v1), data = d[s12, ])
m2 <- lm(mk(v2), data = d[s12, ])
m3 <- lm(mk(v3), data = d[s36, ])
m4 <- lm(mk(v4), data = d[s36, ])
m5 <- lm(mk(v5), data = d[s36, ])
m6 <- lm(mk(v6), data = d[s36, ])

cat(sprintf("SAMPLE:table1:complete_cases_col1_2=%d\n", sum(s12)))
cat(sprintf("SAMPLE:table1:estimation=%d\n", nobs(m1)))
cat(sprintf("SAMPLE:table1_controls:loaded=%d\n", nrow(sv_raw)))
cat(sprintf("SAMPLE:table1_controls:wave4=%d\n", nrow(sv)))
cat(sprintf("SAMPLE:table1_controls:complete_cases_sociodemographics=%d\n", sum(s36)))
cat(sprintf("SAMPLE:table1_controls:estimation=%d\n", nobs(m3)))
cat(sprintf("SAMPLE:table1_col6:estimation=%d\n", nobs(m6)))

# ------------------------------------------------------------------
# Ecological analysis: SI Table C1, columns 5 (Sum) and 6 (Annual)
# ------------------------------------------------------------------
ctx_raw <- read_dta(file.path(base_dir, "context.dta"))
ctx <- as.data.frame(lapply(ctx_raw, to_num))
cat(sprintf("SAMPLE:annual:loaded=%d\n", nrow(ctx)))
cat(sprintf("SAMPLE:sum:loaded=%d\n", nrow(ctx)))

ctx <- ctx[!is.na(ctx$year) & ctx$year %in% 2015:2017, ]
cat(sprintf("SAMPLE:annual:years_2015_2017=%d\n", nrow(ctx)))

controls <- c("log_population_muni_2015", "log_popdens_muni_2015", "d_pop1511_muni",
              "log_unemp_all_muni_2015", "unemp_gendergap_2015",
              "log_pop_ref_2014", "log_ref_inflow_1514",
              "pc_hidegree_all2011", "pc_manufacturing_2015", "d_manuf1115",
              "vote_afd_2013_muni", "log_violence_percap_2015")
controls <- intersect(controls, names(ctx))

# Municipality-level cross-section
muni <- ctx %>%
  group_by(ags_muni) %>%
  summarise(
    hate_sum_bin = if (all(is.na(Hate_all_muni_bin))) NA_real_ else as.numeric(max(Hate_all_muni_bin, na.rm = TRUE) > 0),
    across(all_of(c("pop_15_44_muni_gendergap_2015", controls, "ags_county", "ags_state")),
           ~ first(na.omit(.x))),
    .groups = "drop"
  ) %>% as.data.frame()
cat(sprintf("SAMPLE:sum:aggregate_to_municipality=%d\n", nrow(muni)))

# Trim top/bottom 2.5 percentiles of Excess Males (municipality distribution)
qs <- quantile(muni$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
keep_m <- !is.na(muni$pop_15_44_muni_gendergap_2015) &
  muni$pop_15_44_muni_gendergap_2015 >= qs[1] & muni$pop_15_44_muni_gendergap_2015 <= qs[2]
muni_t <- muni[keep_m, ]
cat(sprintf("SAMPLE:sum:drop_extreme_excess_males=%d\n", nrow(muni_t)))

ctx_t <- ctx[!is.na(ctx$pop_15_44_muni_gendergap_2015) &
               ctx$pop_15_44_muni_gendergap_2015 >= qs[1] &
               ctx$pop_15_44_muni_gendergap_2015 <= qs[2], ]
cat(sprintf("SAMPLE:annual:drop_extreme_excess_males=%d\n", nrow(ctx_t)))

f_sum <- as.formula(paste("hate_sum_bin ~ pop_15_44_muni_gendergap_2015 +",
                          paste(controls, collapse = " + "), "| ags_state"))
f_ann <- as.formula(paste("Hate_all_muni_bin ~ pop_15_44_muni_gendergap_2015 +",
                          paste(controls, collapse = " + "), "| ags_state + year"))

m_sum <- feglm(f_sum, data = muni_t, family = binomial("logit"), cluster = ~ags_county)
m_ann <- feglm(f_ann, data = ctx_t, family = binomial("logit"), cluster = ~ags_county)

cat(sprintf("SAMPLE:sum:estimation=%d\n", nobs(m_sum)))
cat(sprintf("SAMPLE:annual:estimation=%d\n", nobs(m_ann)))

# ------------------------------------------------------------------
# Results
# ------------------------------------------------------------------
cat(sprintf("RESULT:mate_competition_table1_col1=%.6f\n", coef(m1)["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col2=%.6f\n", coef(m2)["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col3=%.6f\n", coef(m3)["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col4=%.6f\n", coef(m4)["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col5=%.6f\n", coef(m5)["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col6=%.6f\n", coef(m6)["mate"]))
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", coef(m2)["job"]))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", as.integer(nobs(m3))))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(m_sum)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(m_ann)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", as.integer(nobs(m_sum))))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", as.integer(nobs(m_ann))))
