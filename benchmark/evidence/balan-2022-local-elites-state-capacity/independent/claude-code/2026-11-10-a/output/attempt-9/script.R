# Exploratory 9: payments merge, midline visits and endline bribe sample sizes (no estimates)
suppressMessages({library(haven); library(dplyr)})
options(width = 250)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rs <- zap_labels(read_dta(file.path(B, "admin_data/randomization_schedule.dta")))
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta")))
tr <- zap_labels(read_dta(file.path(B, "admin_data/taxroll_noPII.dta")))
tp <- zap_labels(read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")))
tr$amt <- suppressWarnings(as.numeric(gsub("[^0-9]", "", tr$MontantIF))); tr$amt[!grepl("FC", tr$MontantIF)] <- NA
s <- rg %>% filter(pilot == 0) %>% left_join(rs[, c("a7", "treatment", "month")], by = "a7") %>%
  inner_join(tr[!is.na(tr$amt), c("compound1", "amt")], by = "compound1") %>% distinct(compound1, .keep_all = TRUE)
s$trt <- s$treatment; s$trt[s$a7 == 654] <- 2
cat("house vs amt band\n"); print(table(s$house, s$amt >= 6600))
tpp <- tp %>% filter(!is.na(compound1))
cat("payments in sample:", sum(tpp$compound1 %in% s$compound1), "\n")
x <- tpp %>% filter(compound1 %in% s$compound1)
print(table(x$amountCF)); print(table(x$error_code, useNA = "ifany")); print(table(x$unmatched_compound, useNA = "ifany"))
print(as.data.frame(x %>% filter(amountCF > 13200) %>% select(compound1, a7, amountCF, date, house, error_code)))
s$paid <- as.integer(s$compound1 %in% tpp$compound1)
s$rev <- tpp$amountCF[match(s$compound1, tpp$compound1)]; s$rev[is.na(s$rev)] <- 0
cat("means by trt (paid, rev, rev capped)\n")
print(as.data.frame(s %>% group_by(trt) %>% summarise(n = n(), paid = mean(paid), rev = mean(rev), rev2 = mean(pmin(rev, 13200)))))
cat("payments a7 vs registration a7 mismatch:", sum(x$a7 != s$a7[match(x$compound1, s$compound1)], na.rm = TRUE), "\n")

# midline
m <- zap_labels(read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = c("a7", "compound", "compound2", "today", "month", "visited", "visits", "tot_complete", "tot_complete_short", "dup_compound", "dup_real", "unknown_compound", "first_attempt", "exempt")))
cat("\nmidline compound in sample:", sum(m$compound %in% s$compound1), " tot_complete==1 & in:", sum(m$compound %in% s$compound1 & m$tot_complete == 1), "\n")
mm <- m %>% filter(compound %in% s$compound1) %>% left_join(s[, c("compound1", "trt")], by = c("compound" = "compound1"))
print(table(mm$tot_complete, mm$trt, useNA = "ifany"))
print(table(mm$visited, mm$visits, useNA = "ifany"))
mlc <- mm %>% filter(trt %in% c(1, 2))
cat("LC midline rows", nrow(mlc), " unique compounds", length(unique(mlc$compound)), "\n")
cat("LC visits nonNA", sum(!is.na(mlc$visits)), " visited nonNA", sum(!is.na(mlc$visited)), "\n")
cat("LC tot_complete: visits nonNA", sum(!is.na(mlc$visits) & mlc$tot_complete == 1), " visited nonNA", sum(!is.na(mlc$visited) & mlc$tot_complete == 1), "\n")
print(table(mlc$dup_compound, useNA = "ifany")); print(table(mlc$first_attempt, useNA = "ifany"))
cat("LC means: visits-1>0 among visits nonNA:", mean(mlc$visits[!is.na(mlc$visits)] > 1), " mean(visits-1):", mean(pmax(mlc$visits - 1, 0), na.rm = TRUE), "\n")
print(summary(mlc$visits))

# endline
e <- zap_labels(read_dta(file.path(B, "survey_data/endline_round1_noPII.dta"), col_select = c("a7", "treatment", "compound_code", "today", "visited", "visits", "paid_self", "bribe", "bribe3", "replacement", "dup_compound")))
e <- e %>% left_join(rs[, c("a7", "treatment")], by = "a7", suffix = c("", ".rs"))
cat("\nendline round1: treatment vs rs\n"); print(table(e$treatment, e$treatment.rs, useNA = "ifany"))
e$trt <- e$treatment.rs; e$trt[e$a7 %in% 654] <- 2
el <- e %>% filter(trt %in% c(1, 2))
cat("LC rows", nrow(el), " bribe nonNA", sum(!is.na(el$bribe)), "\n")
print(table(el$bribe, el$visited, useNA = "ifany"))
print(table(el$treatment, useNA = "ifany"))
cat("LC with endline treatment nonNA:", sum(!is.na(el$treatment)), " bribe nonNA & treatment nonNA:", sum(!is.na(el$bribe) & !is.na(el$treatment)), "\n")
cat("visited>0 count:", sum(el$visited %in% c(1, 2)), " visited==1:", sum(el$visited %in% 1), "\n")
e2 <- zap_labels(read_dta(file.path(B, "survey_data/endline_round2_noPII.dta")))
cat("round2 names with bribe/transport/visit:", grep("bribe|transport|visit|paid", names(e2), value = TRUE), "\n")
e3 <- zap_labels(read_dta(file.path(B, "survey_data/endline_2016campaign_noPII.dta"), col_select = any_of(c("a7", "today", "transport", "bribe", "visited", "visit", "paid_self", "bribe_self", "treatment"))))
cat("endline_2016campaign:", nrow(e3), "\n"); print(summary(e3$today)); print(table(e3$bribe, useNA = "ifany")); print(table(e3$transport, useNA = "ifany")[1:5])
