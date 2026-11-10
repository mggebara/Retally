# Corno, La Ferrara & Burns (2022) "Interaction, Stereotypes, and Performance" -- blind independent reproduction
# Tables 3 and 4: effect of being assigned a roommate of a different race (Mixed Room).
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-d/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
d <- zap_labels(read_dta(paste0(D, "uctdata_balanced.dta")))

# Working sample: students observed at baseline and follow-up with both IATs (balanced panel);
# keep the follow-up round; baseline IAT is carried in DscoreraceIATbas.
w <- d %>% filter(round == 2, !is.na(DscoreraceIAT), !is.na(DscoreacaIAT),
                  !is.na(DscoreraceIATbas), !is.na(DscoreacaIATbas))
# Race codes: 1 black, 2 coloured, 3 white, 4/5 Indian/Asian/other
w <- w %>% mutate(racegrp = case_when(Race == 1 ~ "black", Race == 3 ~ "white", TRUE ~ "other"),
                  raceres = paste(racegrp, Res_base, sep = "_"),
                  room = roomnum_base)
cat("Working sample:", nrow(w), " black:", sum(w$racegrp == "black"), " white:", sum(w$racegrp == "white"), "\n")

# Own baseline controls (missing replaced by mean + missing dummies; all-zero dummies are dropped by fixest)
own <- c("Female", "Falseuct2012", "missfalse", "durpcabas_nomiss", "durpcabas_miss",
         "consbas_nomiss", "consbas_miss", "Foreign", "foreign_missing",
         "privateschool_nomiss", "privateschool_miss")
# Roommate baseline controls, all but female
ro <- c("roFalseuct2012", "missrofalse", "rodurpcabas_nomiss", "rodurpcabas_miss",
        "roconsbas_nomiss", "roconsbas_missing", "roForeign_bas", "roforeign_missingbas",
        "roprivschool_nomiss", "roprivschool_miss")
ctrl <- paste(c(own, ro), collapse = " + ")

# OLS with dummy variables (as Stata reg/areg): keep observations that are alone in their FE cell
# (they do not move the Mixed Room coefficient but belong to the estimation sample / No. Obs.).
est <- function(f, data) feols(as.formula(f), data = data, cluster = ~room, notes = FALSE, fixef.rm = "none")

wW <- w %>% filter(racegrp == "white")
wB <- w %>% filter(racegrp == "black")

# ---- Table 3: Race IAT, by race ----
f3 <- paste("DscoreraceIAT ~ mixracebas + DscoreraceIATbas +", ctrl, "| Res_base")
t3w <- est(f3, wW); t3b <- est(f3, wB)
print(summary(t3w)$coeftable["mixracebas", ]); print(summary(t3b)$coeftable["mixracebas", ])

# ---- Table 4: academic performance (no lagged outcome; + academic program FE) ----
outs <- c(gpa = "GPA", exams = "examspassed", elig = "continue", idx = "PCAperf")
f4s <- function(y) paste(y, "~ mixracebas +", ctrl, "| Res_base + regprogram")
f4f <- function(y) paste(y, "~ mixracebas + white + coloured + Else +", ctrl, "| raceres + regprogram")
t4B <- lapply(outs, function(y) est(f4s(y), wB))
t4A <- lapply(outs, function(y) est(f4s(y), wW))
t4C <- lapply(outs, function(y) est(f4f(y), w))
for (nm in names(outs)) {
  cat(nm, "B:", coef(t4B[[nm]])["mixracebas"], se(t4B[[nm]])["mixracebas"], nobs(t4B[[nm]]),
      " A:", coef(t4A[[nm]])["mixracebas"], se(t4A[[nm]])["mixracebas"], nobs(t4A[[nm]]),
      " C:", coef(t4C[[nm]])["mixracebas"], se(t4C[[nm]])["mixracebas"], nobs(t4C[[nm]]), "\n")
}

b <- function(m) unname(coef(m)["mixracebas"])
res <- c(
  race_iat_mixed_room_whites_table3_col1 = b(t3w),
  race_iat_mixed_room_blacks_table3_col2 = b(t3b),
  n_obs_table3_whites = nobs(t3w),
  n_obs_table3_blacks = nobs(t3b),
  gpa_mixed_room_blacks_table4_panelB_col1 = b(t4B$gpa),
  exams_passed_mixed_room_blacks_table4_panelB_col2 = b(t4B$exams),
  eligible_mixed_room_blacks_table4_panelB_col3 = b(t4B$elig),
  performance_index_mixed_room_blacks_table4_panelB_col4 = b(t4B$idx),
  gpa_mixed_room_whites_table4_panelA_col1 = b(t4A$gpa),
  gpa_mixed_room_full_table4_panelC_col1 = b(t4C$gpa),
  exams_passed_mixed_room_full_table4_panelC_col2 = b(t4C$exams),
  performance_index_mixed_room_full_table4_panelC_col4 = b(t4C$idx),
  n_obs_table4_panelC_cols1_2 = nobs(t4C$gpa)
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
