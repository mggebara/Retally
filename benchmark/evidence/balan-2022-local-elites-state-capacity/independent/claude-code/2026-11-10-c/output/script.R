# Independent reproduction: Balan, Bergeron, Tourek & Weigel (2022, AER)
# "Local Elites as State Capacity" -- Tables 4, 5 (endline bribe), 6 (col 1), 7 (cols 1-2), 8 (Panel A col 2)
#
# Construction (from the paper text and the data files only):
#  * Property universe: properties listed in admin_data/hh_distances.dta (45,177 properties; its arm counts
#    reproduce Table 2 almost exactly once neighborhood 654 -- the CXL neighborhood whose registration was
#    done by the chief alone -- is moved to Local, per footnote 40 "de facto assignment").
#    Property attributes (registration date, house band, exemption) come from the registration survey
#    (admin_data/registration_noPII.dta), first record per compound code.
#  * Treatment: randomization_assignment.dta (1 Central, 2 Local, 3 CLI, 4 CXL), a7 = 654 recoded to Local.
#  * Stratum FE: randomization stratum from randomization_assignment.dta.
#  * Compliance: property's tax ID appears in the tax payment records (tax_payments_noPII.dta), excluding
#    receipts flagged error_code == 1 (receipt tax-ID / neighborhood code mismatch).
#  * Revenue: amount paid in CF (0 for non-payers); the few amounts that are not one of the official
#    liabilities (e.g. 1,662,800 CF typos) are replaced by the official liability implied by the receipt's
#    USD rate (rateUSD * 1900 CF, snapped to the nearest official amount).
#  * Time FE: two-month campaign periods starting at the midpoint between the first registration days of
#    the two arms compared and ending at the midpoint between their last registration days (midpoints
#    floored to whole days); properties registered outside [start, end] are dropped.
#  * House FE: high-value band (registration house type 2) vs low-value band.
#  * SEs clustered by neighborhood (a7).
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
options(width = 200, warn = 1)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"

ra  <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>% zap_labels()
ra$tf <- ra$treatment; ra$tf[ra$a7 == 654] <- 2          # de facto assignment (misassigned CXL -> Local)
reg <- read_dta(file.path(B, "admin_data/registration_noPII.dta"),
                col_select = c(a7, compound1, start, house, exempt)) %>% zap_labels()
hh  <- read_dta(file.path(B, "admin_data/hh_distances.dta"), col_select = c(compound1, a7)) %>% zap_labels()
pay <- read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")) %>% zap_labels()
cons <- read_dta(file.path(B, "survey_data/chief_consultations.dta"), col_select = c(compound1, a7, pay_ease, willingness)) %>% zap_labels()

# ---- property universe ----
r1 <- reg %>% filter(compound1 %in% hh$compound1) %>% arrange(compound1, start) %>% distinct(compound1, .keep_all = TRUE) %>% select(-a7)
u <- hh %>% filter(!is.na(compound1), !is.na(a7)) %>% left_join(r1, by = "compound1")
u$t <- ra$tf[match(u$a7, ra$a7)]
u$stratum <- ra$stratum[match(u$a7, ra$a7)]
u <- u %>% filter(!is.na(t))
u$d <- as.numeric(as.Date(u$start))
u$high <- as.integer(u$house == 2)
u$exempt1 <- as.integer(u$exempt %in% 1)
cat("Universe by arm:\n"); print(table(u$t))

# ---- payments ----
off <- c(1500, 2000, 2500, 3000, 6600, 8800, 11000, 13200)
snap <- function(x) off[which.min(abs(off - x))]
pv <- pay %>% filter(!is.na(compound1), !(error_code %in% 1))
pv$amt <- pv$amountCF
bad <- is.na(pv$amt) | !(pv$amt %in% off)
pv$amt[bad] <- sapply(pv$rateUSD[bad] * 1900, function(z) if (is.na(z)) NA else snap(z))
cat("payment amounts replaced:", sum(bad), "\n")
pv <- pv %>% group_by(compound1) %>% summarise(amt = sum(amt, na.rm = TRUE), .groups = "drop")
u$paid <- as.integer(u$compound1 %in% pv$compound1)
u$rev <- pv$amt[match(u$compound1, pv$compound1)]; u$rev[is.na(u$rev)] <- 0

# ---- time periods ----
window <- function(dat, arms) {
  s <- dat %>% filter(t %in% arms)
  first <- tapply(s$d, s$t, min, na.rm = TRUE); last <- tapply(s$d, s$t, max, na.rm = TRUE)
  st <- floor(mean(first)); en <- floor(mean(last))
  cat(sprintf("Window arms %s: first days %s; last days %s; start %s end %s\n", paste(arms, collapse = "/"),
      paste(as.Date(first, origin = "1970-01-01"), collapse = ","), paste(as.Date(last, origin = "1970-01-01"), collapse = ","),
      as.Date(st, origin = "1970-01-01"), as.Date(en, origin = "1970-01-01")))
  s <- s %>% filter(!is.na(d), d >= st, d <= en)
  s$period <- floor((s$d - st) / 61) + 1
  s
}

res <- list()
cf <- function(m, v) unname(coef(m)[v])
# ---- Table 4 ----
lc <- u %>% filter(t %in% 1:2) %>% mutate(local = as.integer(t == 2))
m1 <- feols(paid ~ local | stratum, lc, cluster = ~a7)
lw <- window(u, 1:2) %>% mutate(local = as.integer(t == 2))
m2 <- feols(paid ~ local | stratum + period, lw, cluster = ~a7)
m4 <- feols(paid ~ local | stratum + period + high, lw, cluster = ~a7)
m5 <- feols(paid ~ local | stratum + period + high, lw %>% filter(exempt1 == 0), cluster = ~a7)
b2 <- feols(rev ~ local | stratum + period, lw, cluster = ~a7)
b4 <- feols(rev ~ local | stratum + period + high, lw, cluster = ~a7)
etable(m1, m2, m4, m5, b2, b4)
cat("Central means: col1 paid", mean(lc$paid[lc$t == 1]), " col2 paid", mean(lw$paid[lw$t == 1]), " col1 rev", mean(lc$rev[lc$t == 1]), " col2 rev", mean(lw$rev[lw$t == 1]), "\n")
cat("Clusters col1", length(unique(lc$a7)), " col2", length(unique(lw$a7)), " N col5", nobs(m5), "\n")
res$compliance_local_table4_panelA_col1 <- cf(m1, "local")
res$compliance_local_table4_panelA_col2 <- cf(m2, "local")
res$compliance_local_house_fe_table4_panelA_col4 <- cf(m4, "local")
res$compliance_local_exempt_excluded_table4_panelA_col5 <- cf(m5, "local")
res$revenue_local_table4_panelB_col2 <- cf(b2, "local")
res$revenue_local_house_fe_table4_panelB_col4 <- cf(b4, "local")
res$n_obs_table4_col1 <- nobs(m1)
res$n_obs_table4_col2 <- nobs(m2)

# ---- Table 5: paid bribe (endline) ----
e1 <- read_dta(file.path(B, "survey_data/endline_round1_noPII.dta"), col_select = c(a7, code, today, visited, bribe)) %>% zap_labels()
e1$t <- ra$tf[match(e1$a7, ra$a7)]; e1$stratum <- ra$stratum[match(e1$a7, ra$a7)]
# The bribe ("transport") question was asked only of households reporting a collector visit;
# households reporting no visit (or no one home) did not pay a bribe -> coded 0.
e1$bribe_e <- ifelse(e1$visited %in% c(0, 2), 0, ifelse(e1$bribe %in% c(0, 1), e1$bribe, NA))
eb <- e1 %>% filter(t %in% 1:2, !is.na(bribe_e)) %>% arrange(code, today) %>% distinct(code, .keep_all = TRUE) %>% mutate(local = as.integer(t == 2))
m5b <- feols(bribe_e ~ local | stratum, eb, cluster = ~a7)
print(summary(m5b)); cat("Endline bribe: N", nobs(m5b), " Central mean", mean(eb$bribe_e[eb$t == 1]), "\n")
res$paid_bribe_endline_local_table5_panelB <- cf(m5b, "local")

# ---- Table 6 col 1: visited by collector after registration (midline) ----
mid <- read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = c(a7, compound, visited, visits, pilot, tot_complete, today)) %>% zap_labels()
mid <- mid %>% filter(pilot == 0, tot_complete == 1, !is.na(visited)) %>% arrange(compound, today) %>% distinct(compound, .keep_all = TRUE)
# visits counts all collector visits since June including the registration visit -> any later visit = visits >= 2
mid$vis_after <- ifelse(mid$visited == 0, 0, ifelse(!is.na(mid$visits) & mid$visits < 99, as.integer(mid$visits >= 2), NA))
mv <- lw %>% inner_join(mid %>% select(compound, vis_after), by = c("compound1" = "compound")) %>% filter(!is.na(vis_after))
m6 <- feols(vis_after ~ local | high + stratum + period, mv, cluster = ~a7)
print(summary(m6)); cat("Table 6: Central mean", mean(mv$vis_after[mv$t == 1]), "\n")
res$visited_by_collector_local_table6_col1 <- cf(m6, "local")

# ---- Table 7: CLI vs Central ----
cw <- window(u, c(1, 3)) %>% mutate(cli = as.integer(t == 3))
m71 <- feols(paid ~ cli | high + stratum + period, cw, cluster = ~a7)
m72 <- feols(rev ~ cli | high + stratum + period, cw, cluster = ~a7)
etable(m71, m72); cat("Table 7: N", nobs(m71), " clusters", length(unique(cw$a7)), " Central mean", mean(cw$paid[cw$t == 1]), "\n")
res$compliance_cli_table7_col1 <- cf(m71, "cli")
res$revenue_cli_table7_col2 <- cf(m72, "cli")

# ---- Table 8 Panel A col 2: within CLI, compliance on chief's ease-of-payment rating ----
cons <- cons %>% arrange(compound1) %>% distinct(compound1, .keep_all = TRUE)
cons$ease <- ifelse(cons$pay_ease %in% 0:2, cons$pay_ease, NA)
ci <- u %>% filter(t == 3) %>% inner_join(cons %>% select(compound1, ease), by = "compound1") %>% filter(!is.na(ease))
m8 <- feols(paid ~ ease | high + stratum, ci, cluster = ~a7)
print(summary(m8)); cat("Table 8: N", nobs(m8), " clusters", length(unique(ci$a7)), " mean", mean(ci$paid), "\n")
res$compliance_ease_of_payment_cli_table8_panelA_col2 <- cf(m8, "ease")

for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
