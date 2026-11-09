# Independent reproduction: Hanushek et al. (2022, EJ) "Patience, Risk-Taking, and Human Capital
# Investment across Countries", Table 1 (cols 1,2,3,5) and Table 2 (cols 1,3,4), math scores.
suppressMessages({library(data.table); library(fixest)})
set.seed(42)
setFixest_nthreads(1)
D <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-07-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/CSV"
t0 <- Sys.time()

## ---------- Table 2: migrant analysis, eq. (2) ----------
# Sample: migrants (both parents foreign-born) with GPS data for the origin country, waves 2003-2018.
# Outcome pv1math (PISA math / 100). Regressors: origin-country GPS measures (z-standardised at the
# individual level, collapsed to country means, as provided in the working data).
# Residence-country x wave FE; controls: gender, age, OECD-origin dummy, imputation dummies;
# weighted by sampling weights; SEs clustered by country of origin.
m <- fread(file.path(D, "pisa_full_gps_final_imcoo.csv"),
  select = c("country","wave","coo","pv1math","wgt","coo_patience","coo_risktaking",
             "coo_posrecip","coo_negrecip","coo_altruism","coo_trust","coo_oecd",
             "female","age","imfemale","image","countrywave"))
m <- m[wave >= 2003]
ctl2 <- "female + age + coo_oecd + imfemale + image"
t2 <- function(rhs) feols(as.formula(paste("pv1math ~", rhs, "+", ctl2, "| countrywave")),
                          data = m, weights = ~wgt, cluster = ~coo)
r21 <- t2("coo_patience")
r23 <- t2("coo_patience + coo_risktaking")
r24 <- t2("coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust")
print(etable(r21, r23, r24))
cat("Table 2 FE cells:", uniqueN(m$countrywave), " origins:", uniqueN(m$coo), "\n")
print(Sys.time() - t0)

## ---------- Table 1: cross-country baseline, eq. (1) ----------
# All PISA waves 2000-2018, 49 GPS countries. Controls: gender, age, migration status
# (first/second generation), imputation dummies, wave FE. Weights wgtc = sampling weights
# rescaled to give each country equal weight. SEs clustered by country.
x <- fread(file.path(D, "pisa_full_gps_final.csv"),
  select = c("country","wave","pv1math","wgtc","patience","risktaking",
             "female","age","imfemale","image","migra0","migra1","migra2",
             "immigra0","immigra1","immigra2"))
print(Sys.time() - t0)
cat("rows:", nrow(x), " countries:", uniqueN(x$country), " country-waves:", uniqueN(x[, .(country, wave)]), "\n")
print(x[, .N, by = .(migra0, migra1, migra2, immigra0)])
ctl1 <- "female + age + migra1 + migra2 + imfemale + image + immigra1 + immigra2"
t1 <- function(rhs, d = x) feols(as.formula(paste("pv1math ~", rhs, "+", ctl1, "| wave")),
                                 data = d, weights = ~wgtc, cluster = ~country)
r11 <- t1("patience")
r12 <- t1("risktaking")
r13 <- t1("patience + risktaking")
# Natives: everyone except migrants (both parents born abroad = first or second generation)
nat <- x[!(migra1 %in% 1 | migra2 %in% 1)]
r15 <- t1("patience + risktaking", nat)
print(etable(r11, r12, r13, r15))
print(Sys.time() - t0)

cat(sprintf("RESULT:table1_col3_patience=%.4f\n", coef(r13)["patience"]))
cat(sprintf("RESULT:table1_col3_risk_taking=%.4f\n", coef(r13)["risktaking"]))
cat(sprintf("RESULT:table1_col1_patience=%.4f\n", coef(r11)["patience"]))
cat(sprintf("RESULT:table1_col2_risk_taking=%.4f\n", coef(r12)["risktaking"]))
cat(sprintf("RESULT:table1_col5_natives_patience=%.4f\n", coef(r15)["patience"]))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.4f\n", coef(r15)["risktaking"]))
cat(sprintf("RESULT:table1_col3_observations=%d\n", nobs(r13)))
cat(sprintf("RESULT:table2_col3_patience=%.4f\n", coef(r23)["coo_patience"]))
cat(sprintf("RESULT:table2_col3_risk_taking=%.4f\n", coef(r23)["coo_risktaking"]))
cat(sprintf("RESULT:table2_col1_patience=%.4f\n", coef(r21)["coo_patience"]))
cat(sprintf("RESULT:table2_col4_patience=%.4f\n", coef(r24)["coo_patience"]))
cat(sprintf("RESULT:table2_col4_risk_taking=%.4f\n", coef(r24)["coo_risktaking"]))
cat(sprintf("RESULT:table2_col3_observations=%d\n", nobs(r23)))
