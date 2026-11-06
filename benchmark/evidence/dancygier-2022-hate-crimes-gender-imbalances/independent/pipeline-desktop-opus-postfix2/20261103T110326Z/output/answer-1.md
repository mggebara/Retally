suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

strip <- function(d) {
  d <- haven::zap_labels(haven::zap_formats(d))
  as.data.frame(d)
}

## =====================================================================
## Part 1: Survey analysis (Table 1)
## =====================================================================
sv <- strip(read_dta(file.path(base_dir, "survey.dta")))
cat(sprintf("SAMPLE:table1_col1:loaded=%d\n", nrow(sv)))

w4 <- sv[!is.na(sv$wave) & sv$wave == max(sv$wave, na.rm = TRUE), ]
# Wave 4 is the last wave (December 2017)
if (any(sv$wave == 4, na.rm = TRUE)) w4 <- sv[!is.na(sv$wave) & sv$wave == 4, ]
cat(sprintf("SAMPLE:table1_col1:wave4=%d\n", nrow(w4)))

have <- function(v) v[v %in% names(w4)]

dv <- "hate_violence_means"
key <- "MateComp.cont"
b2 <- have(c("JobComp.cont", "LifeSatis.cont"))

socio_num <- have(c("age", "eduyrs", "household_size", "self_econ"))
socio_fac <- have(c("gender", "income", "occupation", "citizenship", "religion", "state"))

nat_att <- have(c("ref_citizenship", "ref_reduce", "ref_crime", "ref_integrating",
                  "ref_moredone", "ref_cultgiveup", "ref_economy", "ref_terror"))
loc_att <- have(grep("^ref_loc_", names(w4), value = TRUE))
add_ctrl <- have(c("contact_ind", "distance_ref", "settle_ref", "refugee_ind",
                   "afd", "afd_ind", "lrscale", "muslim_ind"))

for (v in socio_fac) w4[[v]] <- factor(w4[[v]])

rhs_list <- list(
  c(key),
  c(key, b2),
  c(key, b2, socio_num, socio_fac),
  c(key, b2, socio_num, socio_fac, nat_att),
  c(key, b2, socio_num, socio_fac, nat_att, loc_att),
  c(key, b2, socio_num, socio_fac, nat_att, loc_att, add_ctrl)
)

models <- list()
for (j in seq_along(rhs_list)) {
  rhs <- rhs_list[[j]]
  vars <- c(dv, rhs)
  bq <- function(x) paste0("`", x, "`")
  f <- as.formula(paste(bq(dv), "~", paste(bq(rhs), collapse = " + ")))
  dd <- w4[complete.cases(w4[, vars, drop = FALSE]), vars, drop = FALSE]
  sname <- paste0("table1_col", j)
  if (j > 1) {
    cat(sprintf("SAMPLE:%s:loaded=%d\n", sname, nrow(sv)))
    cat(sprintf("SAMPLE:%s:wave4=%d\n", sname, nrow(w4)))
  }
  cat(sprintf("SAMPLE:%s:complete_cases=%d\n", sname, nrow(dd)))
  m <- lm(f, data = dd)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nobs(m)))
  models[[j]] <- m
}

getc <- function(m, nm) {
  cf <- coef(m)
  k <- which(names(cf) %in% c(nm, paste0("`", nm, "`")))
  if (length(k) == 0) return(NA_real_)
  unname(cf[k[1]])
}

## =====================================================================
## Part 2: Ecological analysis (SI Table C1, cols 5 and 6)
## =====================================================================
cx <- strip(read_dta(file.path(base_dir, "context.dta")))
cat(sprintf("SAMPLE:annual_c1_col6:loaded=%d\n", nrow(cx)))

ctrls <- c("log_population_muni_2015", "log_popdens_muni_2015", "d_pop1511_muni",
           "log_unemp_all_muni_2015", "unemp_gendergap_2015", "log_pop_ref_2014",
           "log_ref_inflow_1514", "pc_hidegree_all2011", "pc_manufacturing_2015",
           "d_manuf1115", "vote_afd_2013_muni", "log_violence_percap_2015")
ctrls <- ctrls[ctrls %in% names(cx)]
xm <- "pop_15_44_muni_gendergap_2015"

# Municipality-level percentiles of Excess Males (one value per municipality)
muni_em <- cx %>% group_by(ags_muni) %>%
  summarise(em = first(na.omit(.data[[xm]])), .groups = "drop")
qs <- quantile(muni_em$em, c(0.025, 0.975), na.rm = TRUE)
keep_munis <- muni_em$ags_muni[!is.na(muni_em$em) & muni_em$em >= qs[1] & muni_em$em <= qs[2]]

# Annual panel
an <- cx[cx$year %in% 2015:2017, ]
cat(sprintf("SAMPLE:annual_c1_col6:years_2015_2017=%d\n", nrow(an)))
an <- an[an$ags_muni %in% keep_munis, ]
cat(sprintf("SAMPLE:annual_c1_col6:drop_extreme_excess_males=%d\n", nrow(an)))
if (!"Hate_all_muni_bin" %in% names(an)) an$Hate_all_muni_bin <- as.integer(an$Hate_all_muni > 0)
an$y <- as.integer(an$Hate_all_muni_bin > 0)
avars <- c("y", xm, ctrls, "ags_state", "ags_county", "year")
an <- an[complete.cases(an[, avars]), ]
cat(sprintf("SAMPLE:annual_c1_col6:complete_cases=%d\n", nrow(an)))
fa <- as.formula(paste("y ~", paste(c(xm, ctrls), collapse = " + "), "| ags_state + year"))
m_an <- feglm(fa, data = an, family = binomial("logit"), cluster = ~ags_county)
cat(sprintf("SAMPLE:annual_c1_col6:estimation=%d\n", nobs(m_an)))

# Sum cross-section
cat(sprintf("SAMPLE:sum_c1_col5:loaded=%d\n", nrow(cx)))
cs <- cx %>% filter(year %in% 2015:2017) %>%
  group_by(ags_muni) %>%
  summarise(hate_sum = sum(Hate_all_muni, na.rm = TRUE),
            hate_nonmiss = sum(!is.na(Hate_all_muni)),
            ags_state = first(ags_state), ags_county = first(ags_county),
            across(all_of(c(xm, ctrls)), ~ first(na.omit(.x))),
            .groups = "drop") %>% as.data.frame()
cat(sprintf("SAMPLE:sum_c1_col5:collapse_to_municipality=%d\n", nrow(cs)))
cs <- cs[cs$ags_muni %in% keep_munis, ]
cat(sprintf("SAMPLE:sum_c1_col5:drop_extreme_excess_males=%d\n", nrow(cs)))
cs$y <- ifelse(cs$hate_nonmiss > 0, as.integer(cs$hate_sum > 0), NA_integer_)
svars <- c("y", xm, ctrls, "ags_state", "ags_county")
cs <- cs[complete.cases(cs[, svars]), ]
cat(sprintf("SAMPLE:sum_c1_col5:complete_cases=%d\n", nrow(cs)))
fs <- as.formula(paste("y ~", paste(c(xm, ctrls), collapse = " + "), "| ags_state"))
m_cs <- feglm(fs, data = cs, family = binomial("logit"), cluster = ~ags_county)
cat(sprintf("SAMPLE:sum_c1_col5:estimation=%d\n", nobs(m_cs)))

if (nobs(m_cs) != 9282) cat(sprintf("DEVIATION: Sum model N=%d differs from paper's 9282\n", nobs(m_cs)))
if (nobs(m_an) != 27846) cat(sprintf("DEVIATION: Annual model N=%d differs from paper's 27846\n", nobs(m_an)))
if (nobs(models[[1]]) != 3019) cat(sprintf("DEVIATION: Table 1 col1 N=%d differs from paper's 3019\n", nobs(models[[1]])))
if (nobs(models[[3]]) != 3008) cat(sprintf("DEVIATION: Table 1 col3 N=%d differs from paper's 3008\n", nobs(models[[3]])))

## =====================================================================
## Results
## =====================================================================
for (j in 1:6) {
  cat(sprintf("RESULT:mate_competition_table1_col%d=%.6f\n", j, getc(models[[j]], key)))
}
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", getc(models[[2]], "JobComp.cont")))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(models[[1]])))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(models[[3]])))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", unname(coef(m_cs)[xm])))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", unname(coef(m_an)[xm])))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", nobs(m_cs)))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", nobs(m_an)))
