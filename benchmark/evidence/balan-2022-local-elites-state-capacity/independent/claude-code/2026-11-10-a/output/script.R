# Balan et al. (2022 AER) "Local Elites as State Capacity" -- independent reproduction
# Reconstructed from the paper text only.  Builds the property-level analysis file
# from the raw admin data (registration + tax roll + payment receipts) and estimates
# equation (1): y = b*Local + stratum FE (+ campaign-period FE) (+ house-band FE),
# SEs clustered by neighborhood (a7).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) zap_labels(read_dta(file.path(B, f), ...))

# ---------------- neighborhood level: treatment and strata ----------------
rs <- rd("admin_data/randomization_schedule.dta")          # a7, treatment, month
ra <- rd("admin_data/randomization_assignment.dta")        # a7, stratum (randomization strata)
nb <- rs[, c("a7", "treatment")] %>% left_join(ra[, c("a7", "stratum")], by = "a7")
# de facto assignment: one neighborhood assigned to CXL was run by the chief alone (Local).
# Registration records show chief-only teams in CXL neighborhood 654 (and 639); we use 654.
nb$trt <- nb$treatment
nb$trt[nb$a7 == 654] <- 2
# trt: 0 Control, 1 Central, 2 Local, 3 CLI, 4 CXL

# ---------------- property level: registration x tax roll ----------------
rg <- rd("admin_data/registration_noPII.dta")
tr <- rd("admin_data/taxroll_noPII.dta")
tr$liab <- suppressWarnings(as.numeric(gsub("[^0-9]", "", tr$MontantIF)))
tr$liab[!grepl("FC", tr$MontantIF)] <- NA        # villas ("Mesurage"), "Voir le tract", "Paye", blanks: no liability on roll
s <- rg %>% filter(pilot == 0, house %in% c(1, 2)) %>%
  select(compound1, a7, start, house, exempt) %>%
  inner_join(tr %>% filter(!is.na(liab)) %>% select(compound1, liab), by = "compound1") %>%
  distinct(compound1, .keep_all = TRUE) %>%
  inner_join(nb, by = "a7")
s$high <- as.integer(s$house == 2)
s$exempt1 <- as.integer(s$exempt %in% 1)
s$t <- as.numeric(as.Date(s$start))          # registration date (campaign timing)

# ---------------- outcomes: matched payment receipts ----------------
tp <- rd("admin_data/tax_payments_noPII.dta") %>% filter(!is.na(compound1)) %>% distinct(compound1, .keep_all = TRUE)
s$paid <- as.integer(s$compound1 %in% tp$compound1)
s$revenue <- tp$amountCF[match(s$compound1, tp$compound1)]
s$revenue[is.na(s$revenue) & s$paid == 1] <- s$liab[is.na(s$revenue) & s$paid == 1]
# two receipts carry implausible amounts (>1.4 million CF, max liability is 13,200 CF): set to the liability
bad <- !is.na(s$revenue) & s$revenue > 13200
s$revenue[bad] <- s$liab[bad]
s$revenue[s$paid == 0] <- 0

# ---------------- campaign-period (time) fixed effects ----------------
# two-month periods starting at the midpoint between the first days of the two arms compared
# and ending at the midpoint between their last days; observations outside are dropped.
add_period <- function(d, a, b) {
  x <- d %>% filter(trt %in% c(a, b))
  f <- tapply(x$t, x$trt, min); l <- tapply(x$t, x$trt, max)
  ms <- floor(mean(f)); me <- floor(mean(l))
  x$period <- ifelse(x$t >= ms & x$t <= me, floor((x$t - ms) / 61) + 1, NA)
  x
}
lc <- add_period(s, 1, 2); lc$local <- as.integer(lc$trt == 2)
lcw <- lc %>% filter(!is.na(period))
cat("LC sample:", nrow(lc), "props,", length(unique(lc$a7)), "nbhds; with period:", nrow(lcw), "props,", length(unique(lcw$a7)), "nbhds\n")
cat("Central means: compliance", round(mean(lc$paid[lc$local == 0]), 4), " revenue", round(mean(lc$revenue[lc$local == 0]), 2), "\n")

m1 <- feols(paid ~ local | stratum, data = lc, cluster = ~a7)
m2 <- feols(paid ~ local | stratum + period, data = lcw, cluster = ~a7)
m4 <- feols(paid ~ local | stratum + period + high, data = lcw, cluster = ~a7)
m5 <- feols(paid ~ local | stratum + period + high, data = lcw %>% filter(exempt1 == 0), cluster = ~a7)
r2 <- feols(revenue ~ local | stratum + period, data = lcw, cluster = ~a7)
r4 <- feols(revenue ~ local | stratum + period + high, data = lcw, cluster = ~a7)
etable(m1, m2, m4, m5, r2, r4)

# ---------------- Table 7: CLI vs Central ----------------
cc <- add_period(s, 1, 3); cc$cli <- as.integer(cc$trt == 3)
ccw <- cc %>% filter(!is.na(period))
cat("CC sample with period:", nrow(ccw), "props,", length(unique(ccw$a7)), "nbhds\n")
c1 <- feols(paid ~ cli | stratum + period + high, data = ccw, cluster = ~a7)
c2 <- feols(revenue ~ cli | stratum + period + high, data = ccw, cluster = ~a7)
etable(c1, c2)

# ---------------- Table 8: chiefs' ease-of-payment rating within CLI ----------------
cons <- rd("survey_data/chief_consultations.dta") %>% select(compound1, pay_ease) %>% distinct(compound1, .keep_all = TRUE)
cons$ease <- ifelse(cons$pay_ease %in% c(0, 1, 2), cons$pay_ease, NA)
cl <- s %>% filter(trt == 3) %>% inner_join(cons, by = "compound1") %>% filter(!is.na(ease))
cat("Table 8 sample:", nrow(cl), "props,", length(unique(cl$a7)), "nbhds\n")
t8 <- feols(paid ~ ease | high + stratum, data = cl, cluster = ~a7)
etable(t8)

# ---------------- Table 6: midline-reported tax visits after registration ----------------
mid <- rd("survey_data/midline_noPII.dta", col_select = c("compound", "visited", "visits", "tot_complete"))
mid <- mid %>% filter(tot_complete == 1, !is.na(compound)) %>% distinct(compound, .keep_all = TRUE)
mid$visits[mid$visits >= 99999] <- NA
mid$visited_after <- ifelse(mid$visited %in% 0, 0, ifelse(is.na(mid$visits), NA, as.integer(mid$visits >= 2)))
mv <- lcw %>% inner_join(mid %>% select(compound, visited_after), by = c("compound1" = "compound")) %>% filter(!is.na(visited_after))
cat("Table 6 sample:", nrow(mv), "props,", length(unique(mv$a7)), "nbhds; Central mean", round(mean(mv$visited_after[mv$local == 0]), 3), "\n")
v1 <- feols(visited_after ~ local | high + stratum + period, data = mv, cluster = ~a7)
etable(v1)

# ---------------- Table 5: bribe paid to collectors (endline) ----------------
en <- rd("survey_data/endline_round1_noPII.dta", col_select = c("a7", "visited", "bribe"))
en <- en %>% inner_join(nb, by = "a7") %>% filter(trt %in% c(1, 2))
# bribe question asked only of households visited with someone present; others did not pay transport
en$bribe_end <- ifelse(en$bribe %in% c(0, 1), en$bribe, ifelse(en$visited %in% c(0, 2), 0, NA))
en$local <- as.integer(en$trt == 2)
eb <- en %>% filter(!is.na(bribe_end))
cat("Table 5 bribe sample:", nrow(eb), "respondents,", length(unique(eb$a7)), "nbhds; Central mean", round(mean(eb$bribe_end[eb$local == 0]), 3), "\n")
b1 <- feols(bribe_end ~ local | stratum, data = eb, cluster = ~a7)
etable(b1)

cf <- function(m, v) unname(coef(m)[v])
cat(sprintf("RESULT:compliance_local_table4_panelA_col1=%.6f\n", cf(m1, "local")))
cat(sprintf("RESULT:compliance_local_table4_panelA_col2=%.6f\n", cf(m2, "local")))
cat(sprintf("RESULT:compliance_local_house_fe_table4_panelA_col4=%.6f\n", cf(m4, "local")))
cat(sprintf("RESULT:compliance_local_exempt_excluded_table4_panelA_col5=%.6f\n", cf(m5, "local")))
cat(sprintf("RESULT:revenue_local_table4_panelB_col2=%.6f\n", cf(r2, "local")))
cat(sprintf("RESULT:revenue_local_house_fe_table4_panelB_col4=%.6f\n", cf(r4, "local")))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table4_col2=%d\n", nobs(m2)))
cat(sprintf("RESULT:paid_bribe_endline_local_table5_panelB=%.6f\n", cf(b1, "local")))
cat(sprintf("RESULT:visited_by_collector_local_table6_col1=%.6f\n", cf(v1, "local")))
cat(sprintf("RESULT:compliance_cli_table7_col1=%.6f\n", cf(c1, "cli")))
cat(sprintf("RESULT:revenue_cli_table7_col2=%.6f\n", cf(c2, "cli")))
cat(sprintf("RESULT:compliance_ease_of_payment_cli_table8_panelA_col2=%.6f\n", cf(t8, "ease")))
