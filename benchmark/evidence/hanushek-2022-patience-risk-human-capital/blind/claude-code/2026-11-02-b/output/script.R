# Hanushek, Kinne, Lergetporer & Woessmann (2022, EJ) -- blind independent reproduction
# Table 1 (cols 1,2,3,5) and Table 2 (cols 1,3,4)
set.seed(42)
suppressMessages({library(data.table); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-02-b/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/CSV"

cat("DEVIATION: Read only the needed columns of the 2.8 GB pisa_full_gps_final.csv (fread select=) to fit the sandbox time/memory limits; all rows kept.\n")
cat("DEVIATION: Achievement uses the first plausible value only (pv1math, already divided by 100 in the data), not all ten PVs.\n")
cat("DEVIATION: Preference measures are the dataset's prepared country-level GPS variables (patience, risktaking; coo_* for origin), used as provided (already standardised); individual GPS data are not in the package so the standardisation could not be redone.\n")
cat("DEVIATION: Table 2 regressions are unweighted (the Table 2 notes describe plain least squares, unlike Table 1's weighted regressions).\n")

## ---------------- Table 1 ----------------
cols <- c("country","wave","pv1math","patience","risktaking","female","imfemale","age","image",
          "migra0","migra1","migra2","immigra0","immigra1","immigra2","wgtc")
d <- fread(file.path(D,"pisa_full_gps_final.csv"), select=cols, showProgress=FALSE)
d <- d[!is.na(pv1math) & !is.na(patience) & !is.na(risktaking)]
ctrl <- "female + age + migra1 + migra2 + imfemale + image + immigra1 + immigra2"
f1 <- as.formula(paste("pv1math ~ patience +", ctrl, "| wave"))
f2 <- as.formula(paste("pv1math ~ risktaking +", ctrl, "| wave"))
f3 <- as.formula(paste("pv1math ~ patience + risktaking +", ctrl, "| wave"))
m1 <- feols(f1, d, weights=~wgtc, cluster=~country)
m2 <- feols(f2, d, weights=~wgtc, cluster=~country)
m3 <- feols(f3, d, weights=~wgtc, cluster=~country)
nat <- d[migra0 == 1 & immigra0 == 0]
m5 <- feols(f3, nat, weights=~wgtc, cluster=~country)
etable(m1, m2, m3, m5)
cat("Table1 col3 N:", nobs(m3), " countries:", uniqueN(d$country), " natives N:", nobs(m5), "\n")
t1 <- list(p1=coef(m1)["patience"], r2=coef(m2)["risktaking"], p3=coef(m3)["patience"], r3=coef(m3)["risktaking"],
           p5=coef(m5)["patience"], r5=coef(m5)["risktaking"], n3=nobs(m3))
rm(d, nat); invisible(gc())

## ---------------- Table 2 ----------------
m <- fread(file.path(D,"pisa_full_gps_final_imcoo.csv"),
           select=c("country","wave","coo","countrywave","pv1math","coo_patience","coo_risktaking","coo_posrecip",
                    "coo_negrecip","coo_altruism","coo_trust","coo_oecd","female","imfemale","age","image"), showProgress=FALSE)
m <- m[complete.cases(m)]
cat("Table2 sample:", nrow(m), " coo:", uniqueN(m$coo), " residence:", uniqueN(m$country), " cells:", uniqueN(m$countrywave), "\n")
c2 <- "female + age + coo_oecd + imfemale + image"
g1 <- feols(as.formula(paste("pv1math ~ coo_patience +", c2, "| countrywave")), m, cluster=~coo)
g3 <- feols(as.formula(paste("pv1math ~ coo_patience + coo_risktaking +", c2, "| countrywave")), m, cluster=~coo)
g4 <- feols(as.formula(paste("pv1math ~ coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust +", c2, "| countrywave")), m, cluster=~coo)
etable(g1, g3, g4)

cat(sprintf("RESULT:table1_col3_patience=%.6f\n", t1$p3))
cat(sprintf("RESULT:table1_col3_risk_taking=%.6f\n", t1$r3))
cat(sprintf("RESULT:table1_col1_patience=%.6f\n", t1$p1))
cat(sprintf("RESULT:table1_col2_risk_taking=%.6f\n", t1$r2))
cat(sprintf("RESULT:table1_col5_natives_patience=%.6f\n", t1$p5))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.6f\n", t1$r5))
cat(sprintf("RESULT:table1_col3_observations=%d\n", as.integer(t1$n3)))
cat(sprintf("RESULT:table2_col3_patience=%.6f\n", coef(g3)["coo_patience"]))
cat(sprintf("RESULT:table2_col3_risk_taking=%.6f\n", coef(g3)["coo_risktaking"]))
cat(sprintf("RESULT:table2_col1_patience=%.6f\n", coef(g1)["coo_patience"]))
cat(sprintf("RESULT:table2_col4_patience=%.6f\n", coef(g4)["coo_patience"]))
cat(sprintf("RESULT:table2_col4_risk_taking=%.6f\n", coef(g4)["coo_risktaking"]))
cat(sprintf("RESULT:table2_col3_observations=%d\n", as.integer(nobs(g3))))
