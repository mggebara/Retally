# Hanushek et al. (2022) EJ: Patience, risk-taking and human capital -- independent blind reproduction
suppressMessages({library(data.table); library(fixest)})
set.seed(42)
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-02-c/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/CSV/"
res <- list()
fmt <- function(x) formatC(x, digits = 10, format = "g")

## ---------------- Table 2: migrant analysis (narrow definition: both parents born abroad) ----------------
m <- fread(paste0(B, "pisa_full_gps_final_imcoo.csv"),
           select = c("country","wave","wgt","coo","countrywave","coo_patience","coo_risktaking",
                      "coo_posrecip","coo_negrecip","coo_altruism","coo_trust","coo_oecd",
                      "age","image","female","imfemale","pv1math"))
m <- m[complete.cases(m)]
# controls: gender, age, OECD-origin dummy, imputation dummies; residence-country-by-wave FE;
# weights: student sampling weights (country-wave normalised, as supplied); SE clustered by country of origin
c2 <- "female + age + coo_oecd + imfemale + image"
t2_1 <- feols(as.formula(paste("pv1math ~ coo_patience +", c2, "| countrywave")), data = m, weights = ~wgt, cluster = ~coo)
t2_3 <- feols(as.formula(paste("pv1math ~ coo_patience + coo_risktaking +", c2, "| countrywave")), data = m, weights = ~wgt, cluster = ~coo)
t2_4 <- feols(as.formula(paste("pv1math ~ coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust +", c2, "| countrywave")), data = m, weights = ~wgt, cluster = ~coo)
print(etable(t2_1, t2_3, t2_4))
cat("Table 2: countries of origin", uniqueN(m$coo), " residence countries", uniqueN(m$country), " cw cells", uniqueN(m$countrywave), "\n")
res$table2_col3_patience    <- coef(t2_3)[["coo_patience"]]
res$table2_col3_risk_taking <- coef(t2_3)[["coo_risktaking"]]
res$table2_col1_patience    <- coef(t2_1)[["coo_patience"]]
res$table2_col4_patience    <- coef(t2_4)[["coo_patience"]]
res$table2_col4_risk_taking <- coef(t2_4)[["coo_risktaking"]]
res$table2_col3_observations <- nobs(t2_3)
rm(m); invisible(gc())

## ---------------- Table 1: cross-country analysis, PISA 2000-2018, 49 GPS countries ----------------
b <- fread(paste0(B, "pisa_full_gps_final.csv"),
           select = c("country","wave","wgtc","patience","risktaking","migra0","migra1","migra2",
                      "immigra0","immigra1","immigra2","age","image","female","imfemale","pv1math"))
b <- b[complete.cases(b)]
# controls: gender, age, migration status (1st/2nd generation; natives omitted), imputation dummies; wave FE
# weights: sampling weights rescaled so each country has equal total weight (wgtc); SE clustered by country
c1 <- "female + age + migra1 + migra2 + imfemale + image + immigra0 + immigra1 + immigra2"
t1_1 <- feols(as.formula(paste("pv1math ~ patience +", c1, "| wave")), data = b, weights = ~wgtc, cluster = ~country)
t1_2 <- feols(as.formula(paste("pv1math ~ risktaking +", c1, "| wave")), data = b, weights = ~wgtc, cluster = ~country)
t1_3 <- feols(as.formula(paste("pv1math ~ patience + risktaking +", c1, "| wave")), data = b, weights = ~wgtc, cluster = ~country)
# natives: students with migra0 == 1 (not both parents born abroad); migration controls drop out
nat <- b[migra0 == 1]
t1_5 <- feols(pv1math ~ patience + risktaking + female + age + imfemale + image | wave, data = nat, weights = ~wgtc, cluster = ~country)
print(etable(t1_1, t1_2, t1_3, t1_5))
cat("Table 1: countries", uniqueN(b$country), " country-waves", uniqueN(b[, .(country, wave)]), "\n")
res$table1_col3_patience    <- coef(t1_3)[["patience"]]
res$table1_col3_risk_taking <- coef(t1_3)[["risktaking"]]
res$table1_col1_patience    <- coef(t1_1)[["patience"]]
res$table1_col2_risk_taking <- coef(t1_2)[["risktaking"]]
res$table1_col5_natives_patience    <- coef(t1_5)[["patience"]]
res$table1_col5_natives_risk_taking <- coef(t1_5)[["risktaking"]]
res$table1_col3_observations <- nobs(t1_3)

cat("DEVIATION: the 2.8 GB pisa_full_gps_final.csv was read with only the 16 columns the Table 1 models need (fread select=); all rows kept\n")
cat("DEVIATION: GPS preference variables used as supplied (already z-standardised in the analytical sample and collapsed to country level by the authors); not re-standardised\n")
cat("DEVIATION: natives defined as migra0 == 1; students with imputed migration status are excluded from the natives subsample\n")
cat("DEVIATION: Table 2 weights are the supplied sampling weights (wgt, normalised within country-wave over all students); SEs clustered by country of origin\n")
ord <- c("table1_col3_patience","table1_col3_risk_taking","table1_col1_patience","table1_col2_risk_taking",
         "table1_col5_natives_patience","table1_col5_natives_risk_taking","table1_col3_observations",
         "table2_col3_patience","table2_col3_risk_taking","table2_col1_patience","table2_col4_patience",
         "table2_col4_risk_taking","table2_col3_observations")
for (k in ord) cat(sprintf("RESULT:%s=%s\n", k, fmt(res[[k]])))
