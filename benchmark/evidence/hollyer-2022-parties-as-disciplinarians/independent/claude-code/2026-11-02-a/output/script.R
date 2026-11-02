set.seed(42)
suppressPackageStartupMessages({library(haven); library(fixest); library(rdrobust)})
M <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians"
d <- as.data.frame(zap_labels(read_dta(file.path(M,"cross-national-data.dta"))))
covs <- c("partysize","unions","business","religious","pluralty","pr","cl","mdmh","polity","demsys","system","gdppc","gini","ethfrac")
d <- d[complete.cases(d[,c("personal","programmatic","ev_total",covs)]),]
d$ethnic_d <- as.numeric(d$ethnic > 0.5)
d$extrem <- d$extremist2
cat("N =", nrow(d), " countries =", length(unique(d$ccode)), "\n")
q <- quantile(d$ev_total, c(.25,.75)); dq <- q[2]-q[1]
ctrl <- "partysize + unions + business + religious + pluralty + pr + i(cl, ref=3) + mdmh + polity + demsys + i(system, ref=0) + gdppc + gini + ethfrac"
fit <- function(y, extra="", data=d) feols(as.formula(paste(y,"~ ev_total",extra,"+",ctrl)), data=data, cluster=~ccode)
res <- list()
for (y in c("personal","programmatic")) {
  nm <- if (y=="personal") "personalism" else "programmaticness"
  m0 <- fit(y); b <- coef(m0)
  res[[paste0(nm,"_volatility_difference_overall")]] <- b["ev_total"]*dq
  m1 <- fit(y, "+ ethnic_d + ev_total:ethnic_d", data=d[!is.na(d$ethnic_d),]); b <- coef(m1)
  res[[paste0(nm,"_volatility_difference_nonethnic")]] <- b["ev_total"]*dq
  res[[paste0(nm,"_ethnic_minus_nonethnic_low_volatility")]] <- b["ethnic_d"]+b["ev_total:ethnic_d"]*q[1]
  res[[paste0(nm,"_ethnic_minus_nonethnic_high_volatility")]] <- b["ethnic_d"]+b["ev_total:ethnic_d"]*q[2]
  m2 <- fit(y, "+ extrem + ev_total:extrem", data=d[!is.na(d$extrem),]); b <- coef(m2)
  cat(y, "ethnic model N =", nobs(m1), " extremism model N =", nobs(m2), "\n")
  res[[paste0(nm,"_volatility_difference_moderate")]] <- b["ev_total"]*dq
  res[[paste0(nm,"_extremist_minus_moderate_low_volatility")]] <- 3*(b["extrem"]+b["ev_total:extrem"]*q[1])
  res[[paste0(nm,"_extremist_minus_moderate_high_volatility")]] <- 3*(b["extrem"]+b["ev_total:extrem"]*q[2])
}
b <- as.data.frame(zap_labels(read_dta(file.path(M,"brazil-RD-data.dta"))))
bo <- b[!is.na(b$dlameduck_runs) & b$dlameduck_runs==0,]
r1 <- rdrobust(bo$youngF_inc_for1, bo$mv_incparty, c=0, p=1); summary(r1)
r2 <- rdrobust(bo$outyg1F_inc_for1, bo$mv_incparty, c=0, p=1); summary(r2)
keep <- c("personalism_volatility_difference_overall","programmaticness_volatility_difference_overall",
 "personalism_volatility_difference_nonethnic","programmaticness_volatility_difference_nonethnic",
 "personalism_ethnic_minus_nonethnic_low_volatility","programmaticness_ethnic_minus_nonethnic_high_volatility",
 "personalism_volatility_difference_moderate","programmaticness_volatility_difference_moderate",
 "personalism_extremist_minus_moderate_low_volatility","programmaticness_extremist_minus_moderate_high_volatility")
for (k in keep) cat(sprintf("RESULT:%s=%.4f\n", k, unname(res[[k]])))
cat(sprintf("RESULT:n_obs_table1=%d\n", nrow(d)))
cat(sprintf("RESULT:rd_effect_young=%.4f\n", r1$coef[1]))
cat(sprintf("RESULT:rd_effect_young_outsider=%.4f\n", r2$coef[1]))
