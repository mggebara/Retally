# Exploratory run 15: outcome definitions and sample counts for Tables 4-8 (counts and Central means only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, start, tot_complete, house, exempt)))
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
hd <- merge(hd[, c("compound1","a7")], ra[, c("a7","trt","stratum")], by = "a7")
u0 <- rg[rg$compound1 %in% hd$compound1, ] %>% arrange(compound1, desc(tot_complete), start) %>% filter(!duplicated(compound1))
u <- merge(hd, u0[, c("compound1","start","house","exempt")], by = "compound1")
u$d <- as.numeric(as.Date(u$start))
tp <- zap_labels(read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")))
tp <- tp[!is.na(tp$compound1), ]
cat("error_code==1 rows: amounts, lateCollection, unmatched, dup_receipt, mult_tax:\n")
print(table(tp$amountCF[tp$error_code %in% 1])); print(table(tp$lateCollection[tp$error_code %in% 1], useNA="a")); print(table(tp$unmatched_compound[tp$error_code %in% 1], useNA="a"))
print(table(tp$rate_verified, tp$error_code, useNA="a"))
cat("house in payments vs registration house (matched):\n")
x <- merge(tp[, c("compound1","amountCF","error_code","rateUSD")], u[, c("compound1","house","trt")], by = "compound1")
print(table(x$amountCF, x$house, useNA = "a"))
print(table(x$error_code, x$house, useNA="a"))
u$pay_all <- as.numeric(u$compound1 %in% tp$compound1)
u$pay_noerr <- as.numeric(u$compound1 %in% tp$compound1[tp$error_code %in% 0])
amt <- tp %>% group_by(compound1) %>% summarise(a_all = sum(amountCF, na.rm = TRUE), a_noerr = sum(amountCF[error_code %in% 0], na.rm = TRUE), a_cap = sum(pmin(amountCF, 13200), na.rm = TRUE), .groups = "drop")
u <- merge(u, amt, by = "compound1", all.x = TRUE)
for (v in c("a_all","a_noerr","a_cap")) u[[v]][is.na(u[[v]])] <- 0
u$a_noerr_cap <- ifelse(u$a_noerr > 13200, 0, u$a_noerr)
u$a_all_cap <- ifelse(u$a_all > 13200, 0, u$a_all)
s <- u[u$trt %in% c(1,2), ]
st <- floor(mean(tapply(s$d, s$trt, min))); en <- ceiling(mean(tapply(s$d, s$trt, max)))
s$win <- s$d >= st & s$d <= en
cat("\nC/L means by arm (full / window):\n")
print(s %>% group_by(trt) %>% summarise(n = n(), pay_all = mean(pay_all), pay_noerr = mean(pay_noerr), a_all = mean(a_all), a_noerr = mean(a_noerr), a_cap = mean(a_cap), a_noerr_cap = mean(a_noerr_cap), a_all_cap = mean(a_all_cap)))
print(s[s$win, ] %>% group_by(trt) %>% summarise(n = n(), pay_all = mean(pay_all), pay_noerr = mean(pay_noerr), a_all = mean(a_all), a_noerr = mean(a_noerr), a_noerr_cap = mean(a_noerr_cap), a_all_cap = mean(a_all_cap)))
cat("overall rev mean C+L full (a_noerr_cap, a_all_cap):", mean(s$a_noerr_cap), mean(s$a_all_cap), "\n")
cat("exempt in window C/L:\n"); print(table(s$exempt[s$win], useNA = "a"))
cat("win & exempt!=1:", sum(s$win & !(s$exempt %in% 1)), " win & exempt==0:", sum(s$win & s$exempt %in% 0), "\n")
cat("Central mean pay_noerr exempt excluded:", mean(s$pay_noerr[s$win & !(s$exempt %in% 1) & s$trt == 1]), mean(s$pay_all[s$win & !(s$exempt %in% 1) & s$trt == 1]), "\n")

# Table 8: chief consultations
cc <- zap_labels(read_dta(file.path(B, "survey_data/chief_consultations.dta"), col_select = c(a7, compound1, pay_ease, willingness)))
cc$pay_ease[cc$pay_ease == 8888] <- NA; cc$willingness[cc$willingness == 8888] <- NA
c3 <- merge(u[u$trt == 3, ], cc[, c("compound1","pay_ease","willingness")], by = "compound1", all.x = TRUE)
cat("\nCLI universe:", nrow(c3), " pay_ease nonNA:", sum(!is.na(c3$pay_ease)), " clusters:", length(unique(c3$a7[!is.na(c3$pay_ease)])), "\n")
cat("pay_ease nonNA & exempt!=1:", sum(!is.na(c3$pay_ease) & !(c3$exempt %in% 1)), " & exempt==0:", sum(!is.na(c3$pay_ease) & c3$exempt %in% 0), "\n")
cat("willingness nonNA:", sum(!is.na(c3$willingness)), " clusters:", length(unique(c3$a7[!is.na(c3$willingness)])), "\n")
cat("mean pay_noerr among pay_ease nonNA:", mean(c3$pay_noerr[!is.na(c3$pay_ease)]), " all:", mean(c3$pay_all[!is.na(c3$pay_ease)]), "\n")
cc2 <- merge(cc, ra[, c("a7","trt")], by = "a7"); print(table(cc2$trt, !is.na(cc2$pay_ease)))

# Table 5: endline bribe
e1 <- zap_labels(read_dta(file.path(B, "survey_data/endline_round1_noPII.dta"), col_select = c(a7, treatment, code, bribe, dup_respondent, dup_compound)))
e1 <- merge(e1, ra[, c("a7","trt")], by = "a7", all.x = TRUE)
cat("\nendline1 bribe nonNA by trt:\n"); print(table(e1$trt, !is.na(e1$bribe)))
cat("by endline treatment var:\n"); print(table(e1$treatment, !is.na(e1$bribe), useNA = "a"))
cat("bribe mean by trt:\n"); print(tapply(e1$bribe, e1$trt, mean, na.rm = TRUE))
cat("dup_respondent among bribe nonNA:\n"); print(table(e1$dup_respondent[!is.na(e1$bribe)], useNA = "a"))
e16 <- zap_labels(read_dta(file.path(B, "survey_data/endline_2016campaign_noPII.dta"), col_select = any_of(c("a7","treatment","bribe","bribe_self","transport","code","visited"))))
cat("\nendline_2016campaign cols:", names(e16), "\n")
if ("a7" %in% names(e16)) { e16 <- merge(e16, ra[, c("a7","trt")], by = "a7", all.x = TRUE); print(table(e16$trt, !is.na(e16$bribe), useNA = "a")); print(table(e16$bribe, useNA = "a")) }
for (v in c("bribe","bribe_self","transport")) if (v %in% names(e16)) cat(v, ":", attr(read_dta(file.path(B, "survey_data/endline_2016campaign_noPII.dta"), col_select = all_of(v))[[v]], "label"), "\n")

# Table 6: midline visits
md <- zap_labels(read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = c(a7, compound, visited, visits, tot_complete, dup_real, dup_compound, unknown_compound, monitoring_survey_twice, pilot, today, start)))
md$compound1 <- ifelse(md$compound < 1e5, md$a7 * 1000 + md$compound, md$compound)
cat("\nmidline visited labels:", paste(names(attr(read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = "visited")$visited, "labels")), attr(read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = "visited")$visited, "labels"), collapse = "; "), "\n")
mm <- md[md$compound1 %in% u$compound1[u$trt %in% c(1,2)], ]
cat("midline rows matched to C/L universe:", nrow(mm), " unique:", length(unique(mm$compound1)), "\n")
print(table(mm$visited, useNA = "a")); print(table(pmin(mm$visits, 20), useNA = "a"))
print(table(mm$tot_complete, useNA="a")); print(table(mm$dup_compound, useNA="a")); print(table(mm$dup_real, useNA="a"))
mm <- merge(mm, s[, c("compound1","trt","win","house")], by = "compound1")
cat("visited nonNA in window:", sum(!is.na(mm$visited) & mm$win), " unique:", length(unique(mm$compound1[!is.na(mm$visited) & mm$win])), "\n")
cat("Central mean visited==1:", mean(mm$visited[mm$trt == 1 & mm$win] == 1, na.rm = TRUE), " visits>=2:", mean(mm$visits[mm$trt == 1 & mm$win] >= 2, na.rm = TRUE), "\n")
print(table(mm$visited, pmin(mm$visits, 5), useNA = "a"))
