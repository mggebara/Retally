# Independent reproduction: Corno, La Ferrara & Burns (2022), Tables 3 and 4
# Specification reconstructed from the paper text (eq. 2 and table footnotes).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-d/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"

raw <- read_dta(paste0(D, "uctdata_balanced.dta"))
raw$regprogram <- as.character(raw$regprogram)
raw <- zap_labels(raw)

# Balanced panel: 499 students x 2 rounds. Outcomes measured at follow-up (round 2);
# baseline IAT scores are carried in DscoreraceIATbas / DscoreacaIATbas.
fu <- raw %>% filter(round == 2)
cat("Follow-up rows:", nrow(fu), " unique students:", length(unique(fu$nstudent)), "\n")
cat("Race counts: black", sum(fu$black), " white", sum(fu$white), " coloured", sum(fu$coloured), " other", sum(fu$Else), "\n")

# Race groups for Race x Residence FE: Black, White, residual
fu <- fu %>% mutate(racegrp = ifelse(black == 1, "B", ifelse(white == 1, "W", "O")),
                    raceres = paste(racegrp, Res_base, sep = "_"),
                    room = paste(Res_base, roomnum_base, sep = "_"))

# Own controls (mean-imputed with missing dummies; constant-zero dummies are dropped by fixest)
own <- "Female + Falseuct2012 + missfalse + durpcabas_nomiss + durpcabas_miss + consbas_nomiss + consbas_miss + Foreign + foreign_missing + privateschool_nomiss + privateschool_miss"
# Roommate controls (no female: rooms are single sex)
ro  <- "roFalseuct2012 + missrofalse + rodurpcabas_nomiss + rodurpcabas_miss + roconsbas_nomiss + roconsbas_missing + roForeign_bas + roforeign_missingbas + roprivschool_nomiss + roprivschool_miss"

est <- function(f, data) feols(as.formula(f), data = data, cluster = ~room, fixef.rm = "none", warn = FALSE, notes = FALSE)  # keep singleton FE cells, as OLS with dummies does
co  <- function(m) unname(coef(m)["mixracebas"])
sef <- function(m) unname(fixest::se(m)["mixracebas"])

wh <- fu %>% filter(white == 1)
bl <- fu %>% filter(black == 1)

# ---- Table 3: follow-up IAT on Mixed Room, baseline IAT, own+roommate controls, residence FE
t3w  <- est(paste("DscoreraceIAT ~ mixracebas + DscoreraceIATbas +", own, "+", ro, "| Res_base"), wh)
t3b  <- est(paste("DscoreraceIAT ~ mixracebas + DscoreraceIATbas +", own, "+", ro, "| Res_base"), bl)
t3wa <- est(paste("DscoreacaIAT ~ mixracebas + DscoreacaIATbas +", own, "+", ro, "| Res_base"), wh)
t3ba <- est(paste("DscoreacaIAT ~ mixracebas + DscoreacaIATbas +", own, "+", ro, "| Res_base"), bl)
cat("\nTable 3 (coef, se, N):\n")
for (m in list(t3w, t3b, t3wa, t3ba)) cat(sprintf("  %.3f (%.3f) N=%d R2=%.3f\n", co(m), sef(m), nobs(m), r2(m, "r2")))

# ---- Table 4: academic outcomes, + academic program FE
outs <- c(gpa = "GPA", exams = "examspassed", elig = "continue", index = "PCAperf")
t4 <- list()
for (s in c("W", "B", "F")) {
  for (o in names(outs)) {
    if (s == "F") {
      f <- paste(outs[o], "~ mixracebas + white + coloured + Else +", own, "+", ro, "| raceres + regprogram")
      dat <- fu
    } else {
      f <- paste(outs[o], "~ mixracebas +", own, "+", ro, "| Res_base + regprogram")
      dat <- if (s == "W") wh else bl
    }
    t4[[paste(s, o)]] <- est(f, dat)
  }
}
cat("\nTable 4 (coef, se, N):\n")
for (n in names(t4)) { m <- t4[[n]]; cat(sprintf("  %-10s %.3f (%.3f) N=%d R2=%.3f\n", n, co(m), sef(m), nobs(m), r2(m, "r2"))) }

cat("\n")
cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%.6f\n", co(t3w)))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%.6f\n", co(t3b)))
cat(sprintf("RESULT:n_obs_table3_whites=%d\n", nobs(t3w)))
cat(sprintf("RESULT:n_obs_table3_blacks=%d\n", nobs(t3b)))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%.6f\n", co(t4[["B gpa"]])))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%.6f\n", co(t4[["B exams"]])))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%.6f\n", co(t4[["B elig"]])))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%.6f\n", co(t4[["B index"]])))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%.6f\n", co(t4[["W gpa"]])))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%.6f\n", co(t4[["F gpa"]])))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%.6f\n", co(t4[["F exams"]])))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%.6f\n", co(t4[["F index"]])))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%d\n", nobs(t4[["F gpa"]])))
