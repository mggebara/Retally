set.seed(42)
suppressPackageStartupMessages({library(data.table); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-02-c/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/CSV"
cat("DEVIATION: read the CSV form of pisa_full_gps_final with data.table::fread(select=) on only the columns needed (sandbox time/memory limits); all rows kept\n")
cat("DEVIATION: first plausible value (pv1math, already /100) only; GPS preference variables used as provided in the data files (country-level, standardised as shipped)\n")

## ---- Table 2: migrant analysis (load small file first) ----
m <- fread(file.path(D,"pisa_full_gps_final_imcoo.csv"),
  select=c("countrywave","wgt","coo","coo_patience","coo_risktaking","coo_posrecip","coo_negrecip",
           "coo_altruism","coo_trust","coo_oecd","age","image","female","imfemale","pv1math"))
ctl2 <- "female + age + coo_oecd + imfemale + image"
f2 <- function(rhs) as.formula(paste("pv1math ~", rhs, "+", ctl2, "| countrywave"))
t2c1 <- feols(f2("coo_patience"), data=m, weights=~wgt, cluster=~coo)
t2c3 <- feols(f2("coo_patience + coo_risktaking"), data=m, weights=~wgt, cluster=~coo)
t2c4 <- feols(f2("coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust"), data=m, weights=~wgt, cluster=~coo)
print(etable(t2c1,t2c3,t2c4))
rm(m); gc()

## ---- Table 1: cross-country ----
x <- fread(file.path(D,"pisa_full_gps_final.csv"),
  select=c("country","wave","wgtc","patience","risktaking","age","image","female","imfemale",
           "pv1math","migra0","migra1","migra2","immigra0","immigra1","immigra2"))
ctl1 <- "female + age + migra1 + migra2 + imfemale + image + immigra0 + immigra1 + immigra2"
f1 <- function(rhs, ctl=ctl1) as.formula(paste("pv1math ~", rhs, "+", ctl, "| wave"))
t1c1 <- feols(f1("patience"), data=x, weights=~wgtc, cluster=~country)
t1c2 <- feols(f1("risktaking"), data=x, weights=~wgtc, cluster=~country)
t1c3 <- feols(f1("patience + risktaking"), data=x, weights=~wgtc, cluster=~country)
nat <- x[migra0 == 1]
t1c5 <- feols(f1("patience + risktaking", "female + age + imfemale + image + immigra0 + immigra1 + immigra2"),
              data=nat, weights=~wgtc, cluster=~country)
print(etable(t1c1,t1c2,t1c3,t1c5))

cat(sprintf("RESULT:table1_col3_patience=%.4f\n", coef(t1c3)["patience"]))
cat(sprintf("RESULT:table1_col3_risk_taking=%.4f\n", coef(t1c3)["risktaking"]))
cat(sprintf("RESULT:table1_col1_patience=%.4f\n", coef(t1c1)["patience"]))
cat(sprintf("RESULT:table1_col2_risk_taking=%.4f\n", coef(t1c2)["risktaking"]))
cat(sprintf("RESULT:table1_col5_natives_patience=%.4f\n", coef(t1c5)["patience"]))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.4f\n", coef(t1c5)["risktaking"]))
cat(sprintf("RESULT:table1_col3_observations=%d\n", nobs(t1c3)))
cat(sprintf("RESULT:table2_col3_patience=%.4f\n", coef(t2c3)["coo_patience"]))
cat(sprintf("RESULT:table2_col3_risk_taking=%.4f\n", coef(t2c3)["coo_risktaking"]))
cat(sprintf("RESULT:table2_col1_patience=%.4f\n", coef(t2c1)["coo_patience"]))
cat(sprintf("RESULT:table2_col4_patience=%.4f\n", coef(t2c4)["coo_patience"]))
cat(sprintf("RESULT:table2_col4_risk_taking=%.4f\n", coef(t2c4)["coo_risktaking"]))
cat(sprintf("RESULT:table2_col3_observations=%d\n", nobs(t2c3)))
