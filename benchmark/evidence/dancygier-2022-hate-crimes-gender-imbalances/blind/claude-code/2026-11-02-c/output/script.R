## Independent, blind reproduction: Dancygier, Egami, Jamal & Rischke (2022, AJPS)
## Table 1 (survey OLS) and SI Table C1 columns (5)-(6) (municipality logit).
suppressPackageStartupMessages({
  library(haven); library(sandwich); library(lmtest)
})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/blind/2026-11-02-c/mount/dancygier_2022_hate_crimes_gender_imbalances"

## ---------------- Survey: Table 1 ----------------
s <- read_dta(file.path(D, "survey.dta"))
s <- s[as.numeric(s$wave) == 4, ]
lab_num <- function(x) {            # numeric value from the label text (e.g. "10 ( TOP )")
  ch <- as.character(as_factor(x))
  suppressWarnings(as.numeric(sub("^\\s*([0-9]+).*$", "\\1", ch)))
}
lab_fac <- function(x) droplevels(as_factor(x))

d <- data.frame(
  means   = as.numeric(s$hate_violence_means),
  mate    = as.numeric(s$MateComp.cont),
  job     = as.numeric(s$JobComp.cont),
  life    = as.numeric(s$LifeSatis.cont),
  age     = as.numeric(s$age),
  gender  = lab_fac(s$gender),
  eduyrs  = as.numeric(s$eduyrs),
  income  = lab_fac(s$income),            # includes "No answer" as its own category
  occup   = lab_fac(s$occupation),        # main activity / employment status
  citizen = as.numeric(s$citizenship),
  hhsize  = lab_num(s$household_size),
  selfecon= lab_num(s$self_econ),
  religion= lab_fac(s$religion),
  state   = lab_fac(s$state),
  contact = as.numeric(s$contact_ind),
  dist    = lab_fac(s$distance_ref),      # includes "Don't know" category
  settle  = lab_fac(s$settle_ref),
  afd     = as.numeric(s$afd),
  afd_ind = as.numeric(s$afd_ind),
  lr      = as.numeric(s$lrscale),
  muslim  = as.numeric(s$muslim_ind)
)
nat <- c("ref_integrating","ref_citizenship","ref_reduce","ref_moredone",
         "ref_cultgiveup","ref_economy","ref_crime","ref_terror")
loc <- c("ref_loc_services","ref_loc_economy","ref_loc_crime","ref_loc_culture",
         "ref_loc_islam","ref_loc_schools","ref_loc_housing","ref_loc_wayoflife")
for (v in c(nat, loc)) d[[v]] <- as.numeric(s[[v]])

socio <- c("age","gender","eduyrs","income","occup","citizen","hhsize","selfecon","religion","state")
addl  <- c("contact","dist","settle","afd","afd_ind","lr","muslim")
rhs <- list(
  c1 = c("mate"),
  c2 = c("mate","job","life"),
  c3 = c("mate","job","life", socio),
  c4 = c("mate","job","life", socio, nat),
  c5 = c("mate","job","life", socio, nat, loc),
  c6 = c("mate","job","life", socio, nat, loc, addl)
)
## Columns (1)-(2) use respondents with non-missing core variables; (3)-(6) share
## the sample with complete sociodemographics (and all other controls).
core_ok <- complete.cases(d[, c("means","mate","job","life")])
full_ok <- complete.cases(d[, c("means","mate","job","life", socio, nat, loc, addl)])
fits <- list()
for (k in names(rhs)) {
  dd <- if (k %in% c("c1","c2")) d[core_ok, ] else d[full_ok, ]
  f <- reformulate(rhs[[k]], response = "means")
  fits[[k]] <- lm(f, data = dd)
  ct <- coeftest(fits[[k]])            # conventional OLS SEs
  cat(sprintf("Table1 %s: mate=%.4f (se %.4f)  N=%d  R2=%.3f\n", k,
              ct["mate",1], ct["mate",2], nobs(fits[[k]]), summary(fits[[k]])$r.squared))
}

## ---------------- Context: SI Table C1 cols (5) Sum and (6) Annual ----------------
cx <- read_dta(file.path(D, "context.dta"))
cx$ags_muni <- as.numeric(cx$ags_muni)
ctrl <- c("log_population_muni_2015","log_popdens_muni_2015","d_pop1511_muni",
          "log_unemp_all_muni_2015","unemp_gendergap_2015","log_pop_ref_2014",
          "log_ref_inflow_1514","pc_hidegree_all2011","pc_manufacturing_2015",
          "d_manuf1115","vote_afd_2013_muni","log_violence_percap_2015")
em <- "pop_15_44_muni_gendergap_2015"

## municipality cross-section (time-invariant 2015 covariates)
m15 <- as.data.frame(cx[cx$year == 2015, c("ags_muni","ags_county","ags_state", em, ctrl)])
tot <- aggregate(Hate_all_muni ~ ags_muni, data = as.data.frame(cx), FUN = sum)
m15 <- merge(m15, tot, by = "ags_muni")
m15$hate_sum_bin <- as.numeric(m15$Hate_all_muni > 0)
## exclude top/bottom 2.5 percentiles of Excess Males (across municipalities)
q <- quantile(m15[[em]], c(0.025, 0.975), na.rm = TRUE)
keep_muni <- m15$ags_muni[!is.na(m15[[em]]) & m15[[em]] >= q[1] & m15[[em]] <= q[2]]
cat("Excess males cutoffs:", q, " municipalities kept:", length(keep_muni), "\n")

fsum <- reformulate(c(em, ctrl, "factor(ags_state)"), response = "hate_sum_bin")
ms <- m15[m15$ags_muni %in% keep_muni, ]
ms <- ms[complete.cases(ms[, c("hate_sum_bin", em, ctrl, "ags_state", "ags_county")]), ]
g_sum <- glm(fsum, data = ms, family = binomial("logit"))
ct_s <- coeftest(g_sum, vcov = vcovCL(g_sum, cluster = ~ags_county))
cat(sprintf("C1 col5 Sum: EM=%.4f (cl se %.4f) N=%d\n", ct_s[em,1], ct_s[em,2], nobs(g_sum)))

ann <- as.data.frame(cx[cx$ags_muni %in% keep_muni, ])
fann <- reformulate(c(em, ctrl, "factor(ags_state)", "factor(year)"), response = "Hate_all_muni_bin")
ann <- ann[complete.cases(ann[, c("Hate_all_muni_bin", em, ctrl, "ags_state", "ags_county", "year")]), ]
g_ann <- glm(fann, data = ann, family = binomial("logit"))
ct_a <- coeftest(g_ann, vcov = vcovCL(g_ann, cluster = ~ags_county))
cat(sprintf("C1 col6 Annual: EM=%.4f (cl se %.4f) N=%d\n", ct_a[em,1], ct_a[em,2], nobs(g_ann)))

## ---------------- RESULT lines ----------------
for (k in names(rhs)) cat(sprintf("RESULT:mate_competition_table1_col%s=%.6f\n", sub("c","",k), coef(fits[[k]])["mate"]))
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", coef(fits$c2)["job"]))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(fits$c1)))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(fits$c3)))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(g_sum)[em]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(g_ann)[em]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", nobs(g_sum)))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", nobs(g_ann)))
