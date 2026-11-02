# Hanushek et al. (2022) Table 1 cols 1,2,3,5 and Table 2 cols 1,3,4 (seeded: follows 3_analysis_crosscountry.do / 3_analysis_migrants.do)
suppressPackageStartupMessages({library(data.table); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-b/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/CSV"
setFixest_nthreads(1)

# ---------------- TABLE 1 ----------------
cols1 <- c("pv1math","patience","risktaking","female","age","migra0","migra1","migra2",
           "image","imfemale","immigra1","wave","wgtc","country")
t0 <- Sys.time()
d <- fread(file.path(base, "pisa_full_gps_final.csv"), select = cols1, na.strings = c("", ".", "NA"),
           showProgress = FALSE, nThread = 1)
cat("read full:", nrow(d), "rows,", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s\n")
cat("DEVIATION: read only the 14 columns used by the Table 1 regressions from the CSV form of pisa_full_gps_final (column subsetting, all rows kept) to fit the sandbox time/memory limits\n")

ctrl <- "female + age + migra1 + migra2 + image + imfemale + immigra1"
f1 <- function(rhs, data) feols(as.formula(paste("pv1math ~", rhs, "| wave")), data = data,
                                weights = ~wgtc, cluster = ~country, fixef.rm = "none", lean = TRUE)
m1 <- f1(paste("patience +", ctrl), d)
m2 <- f1(paste("risktaking +", ctrl), d)
m3 <- f1(paste("patience + risktaking +", ctrl), d)
m5 <- f1("patience + risktaking + female + age + image + imfemale", d[migra0 == 1])
cat("T1 col3 N =", nobs(m3), " col5 N =", nobs(m5), "\n")
print(coeftable(m3)[1:2, ]); print(coeftable(m5)[1:2, ])
res <- list(
  table1_col3_patience = coef(m3)[["patience"]],
  table1_col3_risk_taking = coef(m3)[["risktaking"]],
  table1_col1_patience = coef(m1)[["patience"]],
  table1_col2_risk_taking = coef(m2)[["risktaking"]],
  table1_col5_natives_patience = coef(m5)[["patience"]],
  table1_col5_natives_risk_taking = coef(m5)[["risktaking"]],
  table1_col3_observations = nobs(m3))
rm(d, m1, m2, m3, m5); invisible(gc())

# ---------------- TABLE 2 ----------------
cols2 <- c("pv1math","coo_patience","coo_risktaking","coo_posrecip","coo_negrecip","coo_altruism","coo_trust",
           "female","age","imfemale","image","coo_oecd","countrywave","coo")
m <- fread(file.path(base, "pisa_full_gps_final_imcoo.csv"), select = cols2, na.strings = c("", ".", "NA"),
           showProgress = FALSE, nThread = 1)
cat("read imcoo:", nrow(m), "rows\n")
c2 <- "female + age + imfemale + image + coo_oecd"
f2 <- function(rhs) feols(as.formula(paste("pv1math ~", rhs, "| countrywave")), data = m,
                          cluster = ~coo, fixef.rm = "none")
n1 <- f2(paste("coo_patience +", c2))
n3 <- f2(paste("coo_patience + coo_risktaking +", c2))
n4 <- f2(paste("coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust +", c2))
cat("T2 col3 N =", nobs(n3), "\n"); print(coeftable(n3)[1:2, ])
res <- c(res, list(
  table2_col3_patience = coef(n3)[["coo_patience"]],
  table2_col3_risk_taking = coef(n3)[["coo_risktaking"]],
  table2_col1_patience = coef(n1)[["coo_patience"]],
  table2_col4_patience = coef(n4)[["coo_patience"]],
  table2_col4_risk_taking = coef(n4)[["coo_risktaking"]],
  table2_col3_observations = nobs(n3)))

for (k in names(res)) cat(sprintf("RESULT:%s=%.6f\n", k, res[[k]]))
