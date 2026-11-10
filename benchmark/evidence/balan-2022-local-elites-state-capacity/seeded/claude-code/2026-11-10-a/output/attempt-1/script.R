# Exploratory: column names and key structure of the files merged in 2_Data_Construction.do
suppressPackageStartupMessages({library(haven)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/seeded/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
f <- c(fl="admin_data/fliers_campaign.dta", st="admin_data/stratum.dta", c16="admin_data/campaign_2016_neighborhoods.dta",
       rs="admin_data/randomization_schedule.dta", reg="admin_data/registration_noPII.dta", tr="admin_data/taxroll_noPII.dta",
       mid="survey_data/midline_noPII.dta", tp="admin_data/tax_payments_noPII.dta", cc="survey_data/chief_consultations.dta")
nm <- list()
for (k in names(f)) { d <- read_dta(file.path(B, f[[k]]), n_max = 5); nm[[k]] <- names(d)
  cat("==", k, length(names(d)), "\n"); cat(paste(names(d), collapse=" "), "\n") }
el <- read_dta(file.path(B,"survey_data/endline_round1_noPII.dta"), n_max=5)
cat("== el has: ", intersect(c("code","a7","compound_code","compound_code_prev","tot_complete","bribe","bribe2a","bribe2b","bribe3","bribe_amt","move","visits","inc_mo"), names(el)), "\n")
cat("chefferies csv head:\n"); print(head(read.csv(file.path(B,"admin_data/concessions_chefferies.csv"))))
acc <- unique(c(nm$fl, "compound1","a7","assign_flier_rate","assign_treatment_fr","flier_all", nm$st, "chefferie", "tmt_2016", "tmt","month"))
for (k in c("reg","tr","mid","tp")) { cat("overlap master vs", k, ":", intersect(acc, nm[[k]]), "\n"); acc <- unique(c(acc, nm[[k]])) }
reg <- read_dta(file.path(B, f[["reg"]]))
cat("reg rows", nrow(reg), " tot_complete:\n"); print(table(reg$tot_complete, useNA="a"))
for (v in intersect(c("house","exempt","tmt","code_same","pilot","rate","mm_rate","a7","what_rate_periph"), names(reg))) { cat("reg", v, class(reg[[v]])[1], "\n"); print(head(sort(table(reg[[v]], useNA="a"), decreasing=TRUE), 12)) }
cat("reg today class:", class(reg$today), " range:", format(range(reg$today, na.rm=TRUE)), "\n")
cat("reg dup compound1 among complete:", sum(duplicated(reg$compound1[reg$tot_complete %in% 1])), "\n")
tp <- read_dta(file.path(B, f[["tp"]]))
cat("tp rows", nrow(tp), "dup compound1:", sum(duplicated(tp$compound1[!(tp$unmatched_compound %in% 1) & !is.na(tp$compound1)])), " date class", class(tp$date)[1], "\n")
print(summary(tp$amountCF))
tr <- read_dta(file.path(B, f[["tr"]])); cat("tr rows", nrow(tr), "dup:", sum(duplicated(tr$compound1)), "\n")
fl <- read_dta(file.path(B, f[["fl"]])); cat("fl rows", nrow(fl), "dup code:", sum(duplicated(fl$code)), "\n"); print(table(fl$rate, useNA="a"))
rs <- read_dta(file.path(B, f[["rs"]])); print(table(rs$treatment, useNA="a")); cat("rs rows", nrow(rs), "\n")
st <- read_dta(file.path(B, f[["st"]])); cat("stratum rows", nrow(st), "dup a7", sum(duplicated(st$a7)), "\n")
cc <- read_dta(file.path(B, f[["cc"]])); cat("cc rows", nrow(cc), "dup compound1", sum(duplicated(cc$compound1)), "\n"); print(table(cc$pay_ease, useNA="a"))
