suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
nm <- names(d)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
show <- function(v) { cat("==", v, ":", lab[v], "\n"); print(table(d[[v]], useNA = "always")) }
for (v in c("dropme","bobs","nobs","patient","type_observation","screeningOK","patient_complete_survey","treat_morning_clean","treat_scheduled","used_vouchers_admin","vouchers_received_used","voucher_used_DV","voucher_used_PV","in_home_survey","cscomnum_OS","patient_info","infotreat")) if (v %in% nm) show(v)
cat("dropme x patient\n"); print(table(d$dropme, d$patient, useNA="always"))
s <- d[!is.na(d$dropme) & d$dropme == 0, ]
cat("N dropme==0:", nrow(s), "\n")
for (v in c("used_vouchers_admin","RXtreat_sev_simple_mal","treat_sev_simple_mal","RXtreat_severe_mal","treat_severe_mal","RXtreat_simple_mal","treat_simple_mal","treat_sev_simple_mal_alt","RXtreat_sev_simple_mal_alt")) {
  cat(v, ":", lab[v], " nonmiss=", sum(!is.na(s[[v]])), " mean=", mean(s[[v]], na.rm=TRUE), "\n")
  cat("  control mean:", mean(s[[v]][s$patient_voucher==0 & s$doctor_voucher==0], na.rm=TRUE), "\n")
}
cat("PV/DV table in sample\n"); print(table(s$patient_voucher, s$doctor_voucher))
cat("clinics:", length(unique(s$cscomnum_OS)), " dates:", length(unique(s$date_today_survey)), "\n")
ix <- nm[grepl("^(CC|M0)[0-9A-Za-z_]+x(CC|M0)", nm)]
cat("interaction vars:", length(ix), "\n"); print(head(ix, 30)); print(tail(ix, 10))
xs <- nm[grepl("x", nm) & grepl("^(CC|M0|MSS)", nm)]
cat("CC/M0 with x:", length(xs), "\n")
cat("DD:", sum(grepl("^DD[0-9]+$", nm)), " CL:", sum(grepl("^CL[0-9]+$", nm)), "\n")
for (v in c("DD1","DD2","CL1","CL2","CL59", ix[1:5], "CC28xCC39")) if (v %in% nm) cat(v, ":", lab[v], " sd=", sd(s[[v]], na.rm=TRUE), " nmiss=", sum(is.na(s[[v]])), "\n")
# check CL dummies vs clinic
cl <- as.matrix(s[, grep("^CL[0-9]+$", nm, value=TRUE)])
cat("rowSums CL table:\n"); print(table(rowSums(cl)))
dd <- as.matrix(s[, grep("^DD[0-9]+$", nm, value=TRUE)])
cat("rowSums DD table:\n"); print(table(rowSums(dd)))
cat("date_ dummies in sample: ", sum(grepl("^date_[0-9]+$", nm)), "\n")
# any constant CC* in sample
cc <- grep("^CC[0-9]", nm, value = TRUE)
cat("all CC-prefixed vars:", length(cc), "\n")
sds <- sapply(s[, cc], function(x) sd(as.numeric(x), na.rm=TRUE))
cat("constant among them:", sum(sds == 0 | is.na(sds)), "\n")
cat("labels sample of CC interactions:\n"); for (v in head(setdiff(cc, grep("^CC[0-9]+$", cc, value=TRUE)), 8)) cat(v, lab[v], "\n")
cat("other prefixes in names before CC vars:\n"); print(table(sub("[0-9].*$", "", cc)))
