## Hanushek et al. (2022 EJ) -- independent reproduction of Table 1 (cols 1,2,3,5) and Table 2 (cols 1,3,4)
suppressPackageStartupMessages({library(data.table); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-02-b/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/CSV/"

## ---------------- Table 1: cross-country analysis ----------------
cols <- c("country","wave","pv1math","patience","risktaking","wgtc","female","imfemale",
          "age","image","migra0","migra1","migra2","immigra0","immigra1","immigra2")
d <- fread(paste0(base, "pisa_full_gps_final.csv"), select = cols, showProgress = FALSE)
cat("DEVIATION: read only the", length(cols), "needed columns of pisa_full_gps_final.csv (CSV form) for speed; no rows dropped\n")
# pv1math is already the PISA score / 100 (summary: mean ~4.65)
# GPS measures: the country-level variables in the files are the collapsed, (individual-level) z-standardised
# GPS measures; used as provided (no re-standardisation across countries).
zs <- function(dt, v, g) dt[[v]]
d[, pat_z := zs(d, "patience", "country")]
d[, risk_z := zs(d, "risktaking", "country")]
ctrl <- "female + age + migra1 + migra2 + imfemale + image + immigra0 + immigra1 + immigra2"
f1 <- as.formula(paste("pv1math ~ pat_z +", ctrl, "| wave"))
f2 <- as.formula(paste("pv1math ~ risk_z +", ctrl, "| wave"))
f3 <- as.formula(paste("pv1math ~ pat_z + risk_z +", ctrl, "| wave"))
m1 <- feols(f1, data = d, weights = ~wgtc, cluster = ~country)
m2 <- feols(f2, data = d, weights = ~wgtc, cluster = ~country)
m3 <- feols(f3, data = d, weights = ~wgtc, cluster = ~country)
# natives: students not classified as migrants (migra0 == 1); migration controls drop out
nat <- d[migra0 == 1]
f5 <- pv1math ~ pat_z + risk_z + female + age + imfemale + image | wave
m5 <- feols(f5, data = nat, weights = ~wgtc, cluster = ~country)
print(etable(m1, m2, m3, m5, keep = c("pat_z","risk_z")))
t1n <- nobs(m3)
rm(d, nat); gc()

## ---------------- Table 2: migrant analysis ----------------
im <- fread(paste0(base, "pisa_full_gps_final_imcoo.csv"),
            select = c("country","wave","coo","countrywave","pv1math","coo_patience","coo_risktaking",
                       "coo_posrecip","coo_negrecip","coo_altruism","coo_trust","coo_oecd","wgt",
                       "female","imfemale","age","image"), showProgress = FALSE)
for (v in c("coo_patience","coo_risktaking","coo_posrecip","coo_negrecip","coo_altruism","coo_trust"))
  im[, paste0(v, "_z") := zs(im, v, "coo")]
c2 <- "female + age + coo_oecd + imfemale + image"
g1 <- as.formula(paste("pv1math ~ coo_patience_z +", c2, "| countrywave"))
g3 <- as.formula(paste("pv1math ~ coo_patience_z + coo_risktaking_z +", c2, "| countrywave"))
g4 <- as.formula(paste("pv1math ~ coo_patience_z + coo_risktaking_z + coo_posrecip_z + coo_negrecip_z + coo_altruism_z + coo_trust_z +", c2, "| countrywave"))
n1 <- feols(g1, data = im, weights = ~wgt, cluster = ~coo, fixef.rm = "none")
n3 <- feols(g3, data = im, weights = ~wgt, cluster = ~coo, fixef.rm = "none")
n4 <- feols(g4, data = im, weights = ~wgt, cluster = ~coo, fixef.rm = "none")
print(etable(n1, n3, n4, keep = c("coo_patience_z","coo_risktaking_z")))

cat(sprintf("RESULT:table1_col3_patience=%.4f\n", coef(m3)["pat_z"]))
cat(sprintf("RESULT:table1_col3_risk_taking=%.4f\n", coef(m3)["risk_z"]))
cat(sprintf("RESULT:table1_col1_patience=%.4f\n", coef(m1)["pat_z"]))
cat(sprintf("RESULT:table1_col2_risk_taking=%.4f\n", coef(m2)["risk_z"]))
cat(sprintf("RESULT:table1_col5_natives_patience=%.4f\n", coef(m5)["pat_z"]))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.4f\n", coef(m5)["risk_z"]))
cat(sprintf("RESULT:table1_col3_observations=%d\n", t1n))
cat(sprintf("RESULT:table2_col3_patience=%.4f\n", coef(n3)["coo_patience_z"]))
cat(sprintf("RESULT:table2_col3_risk_taking=%.4f\n", coef(n3)["coo_risktaking_z"]))
cat(sprintf("RESULT:table2_col1_patience=%.4f\n", coef(n1)["coo_patience_z"]))
cat(sprintf("RESULT:table2_col4_patience=%.4f\n", coef(n4)["coo_patience_z"]))
cat(sprintf("RESULT:table2_col4_risk_taking=%.4f\n", coef(n4)["coo_risktaking_z"]))
cat(sprintf("RESULT:table2_col3_observations=%d\n", nobs(n3)))
