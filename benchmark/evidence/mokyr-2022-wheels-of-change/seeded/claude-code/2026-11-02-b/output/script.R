suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/seeded/2026-11-02-b/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta"
d <- as.data.frame(read_dta(f))
# main.do: encode GAZ_CNTY (empty string -> missing -> dropped by cluster())
g <- as.character(d$GAZ_CNTY); g[g == ""] <- NA
d$county_id <- as.integer(factor(g))
d$mills_pc   <- d$mills / d$pcmean
d$wrights_pc <- d$wrights / d$pcmean
d$wheat_suit <- ifelse(is.na(d$wheat_tmean), NA, as.numeric(d$wheat_tmean <= 5))
d$riv_rug26count <- d$riv_rug26count / 1000
d$msuit26mean <- d$wheat_suit * d$riv_rug26count
mind <- grep("^min_dist", names(d), value = TRUE)
cat("min_dist* vars:", paste(mind, collapse = ","), "\n")
cat("missing county_id:", sum(is.na(d$county_id)), " non-missing mills_pc:", sum(!is.na(d$mills_pc)), "\n")

geo  <- c("latitude","longitude","dist_rug_mean","dist_elevation_mean")
agr3 <- c("suitmean","wheat_suit","dist_grass_mean")
cli  <- c("precip_mean_dist","temp_mean_dist")
oth  <- c("pcmean","min_harbor","DIST_London", mind, "area")
cl <- ~county_id
fm <- function(rhs) as.formula(paste("wrights_pc ~", paste(c("mills_pc", rhs), collapse = " + ")))
# Stata reg, cluster: small-sample adj (N-1)/(N-K) * G/(G-1) -- fixest default
cols <- list(character(0), geo, c(geo, agr3), c(geo, agr3, cli), c(geo, agr3, cli, oth))
t2 <- lapply(cols, function(r) feols(fm(r), d, cluster = cl))
for (i in seq_along(t2)) cat(sprintf("T2 c%d b=%.4f se=%.4f N=%d\n", i, coef(t2[[i]])["mills_pc"], se(t2[[i]])["mills_pc"], nobs(t2[[i]])))

# Table 3 col5 OLS (", r cluster()" -> cluster-robust)
t3c5 <- feols(fm(c("wheat_suit","riv_rug26count", geo, "suitmean","dist_grass_mean", cli, "min_harbor","DIST_London", mind, "pcmean","area")), d, cluster = cl)
cat(sprintf("T3 c5 b=%.4f N=%d\n", coef(t3c5)["mills_pc"], nobs(t3c5)))

# IVs (ivreg2, cluster, no 'small': no finite-sample adjustment); widstat = KP rk Wald F = t^2 with 1 instrument
ivx <- list(c2 = c("riv_rug26count","wheat_suit"),
            c4 = c("wheat_suit","riv_rug26count", geo, "suitmean","dist_grass_mean", cli),
            c6 = c("wheat_suit","riv_rug26count", geo, "suitmean","dist_grass_mean", cli, "min_harbor","DIST_London", mind, "pcmean","area"))
res <- list()
for (k in names(ivx)) {
  fo <- as.formula(paste("wrights_pc ~", paste(ivx[[k]], collapse = " + "), "| mills_pc ~ msuit26mean"))
  m <- feols(fo, d, cluster = cl, ssc = ssc(adj = FALSE, cluster.adj = FALSE))
  fs0 <- m$iv_first_stage$mills_pc
  # first-stage cluster-robust Wald F for the excluded instrument, with Stata's
  # small-sample factor (N-1)/(N-K) * G/(G-1) (fixest default ssc)
  fs <- summary(fs0, cluster = cl, ssc = ssc(adj = TRUE, cluster.adj = TRUE))
  tt <- coef(fs)["msuit26mean"] / se(fs)["msuit26mean"]
  fsN <- summary(fs0, cluster = cl, ssc = ssc(adj = FALSE, cluster.adj = FALSE))
  cat(sprintf("IV %s b=%.4f se=%.4f N=%d  F(full adj)=%.3f  F(noadj)=%.3f\n", k,
      coef(m)["fit_mills_pc"], se(m)["fit_mills_pc"], nobs(m), tt^2,
      (coef(fsN)["msuit26mean"]/se(fsN)["msuit26mean"])^2))
  res[[k]] <- list(b = unname(coef(m)["fit_mills_pc"]), F = unname(tt^2), n = nobs(m))
}

nm <- c("watermills_table2_col1","watermills_table2_col2","watermills_table2_col3","watermills_table2_col4","watermills_table2_col5")
for (i in 1:5) cat(sprintf("RESULT:%s=%.6f\n", nm[i], coef(t2[[i]])["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(t3c5)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", res$c2$b))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", res$c4$b))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", res$c6$b))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.6f\n", res$c2$F))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.6f\n", res$c4$F))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.6f\n", res$c6$F))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(t2[[1]])))
