# Independent reproduction: Corno, La Ferrara & Burns (2022), Tables 3 and 4
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
raw <- read_dta(paste0(D, "uctdata_balanced.dta"))

# Working sample: balanced panel (baseline + follow-up, both IATs non-missing) -> follow-up round
d <- raw %>% filter(round == 2) %>% zap_labels() %>% as.data.frame()
d$room <- paste(d$Res_base, d$roomnum_base, sep = "_")
d$racegrp <- ifelse(d$black == 1, "B", ifelse(d$white == 1, "W", "O"))
d$racegrp_res <- paste(d$racegrp, d$Res_base, sep = "_")
cat("Follow-up rows:", nrow(d), " whites:", sum(d$white), " blacks:", sum(d$black), "\n")
cat("Unique rooms (res x roomnum):", length(unique(d$room)), " unique roomnum:", length(unique(d$roomnum_base)), "\n")

# Own controls (mean-imputed with missing dummies, as provided in the data)
own <- c("Female", "Falseuct2012", "missfalse", "durpcabas_nomiss", "durpcabas_miss",
         "consbas_nomiss", "consbas_miss", "Foreign", "foreign_missing",
         "privateschool_nomiss", "privateschool_miss")
# Roommate controls (no female: rooms are single-sex)
ro <- c("roFalseuct2012", "missrofalse", "rodurpcabas_nomiss", "rodurpcabas_miss",
        "roconsbas_nomiss", "roconsbas_missing", "roForeign_bas", "roforeign_missingbas",
        "roprivschool_nomiss", "roprivschool_miss")
ctrl <- paste(c(own, ro), collapse = " + ")

est <- function(y, extra, fe, data) {
  f <- as.formula(paste0(y, " ~ mixracebas + ", extra, ctrl, " | ", fe))
  m <- feols(f, data = data, cluster = ~room, warn = FALSE, notes = FALSE)
  list(b = unname(coef(m)["mixracebas"]), se = unname(se(m)["mixracebas"]), n = nobs(m))
}

W <- d[d$white == 1, ]; B <- d[d$black == 1, ]

# Table 3: follow-up Race IAT on Mixed Room + baseline Race IAT + controls, residence FE
t3w <- est("DscoreraceIAT", "DscoreraceIATbas + ", "Res_base", W)
t3b <- est("DscoreraceIAT", "DscoreraceIATbas + ", "Res_base", B)
t3wa <- est("DscoreacaIAT", "DscoreacaIATbas + ", "Res_base", W)
t3ba <- est("DscoreacaIAT", "DscoreacaIATbas + ", "Res_base", B)
cat(sprintf("T3 race W: %.3f (%.3f) n=%d | race B: %.3f (%.3f) n=%d\n", t3w$b, t3w$se, t3w$n, t3b$b, t3b$se, t3b$n))
cat(sprintf("T3 aca  W: %.3f (%.3f) n=%d | aca  B: %.3f (%.3f) n=%d\n", t3wa$b, t3wa$se, t3wa$n, t3ba$b, t3ba$se, t3ba$n))

# Table 4: academic outcomes; residence FE (subsamples) or race-group x residence FE + race dummies (full)
ys <- c(gpa = "GPA", exams = "examspassed", elig = "continue", idx = "PCAperf")
res4 <- list()
for (k in names(ys)) {
  res4[[paste0("W_", k)]] <- est(ys[[k]], "", "Res_base + regprogram", W)
  res4[[paste0("B_", k)]] <- est(ys[[k]], "", "Res_base + regprogram", B)
  res4[[paste0("F_", k)]] <- est(ys[[k]], "white + coloured + Else + ", "racegrp_res + regprogram", d)
}
for (nm in names(res4)) cat(sprintf("T4 %-8s %.3f (%.3f) n=%d\n", nm, res4[[nm]]$b, res4[[nm]]$se, res4[[nm]]$n))

out <- c(
  race_iat_mixed_room_whites_table3_col1 = t3w$b,
  race_iat_mixed_room_blacks_table3_col2 = t3b$b,
  n_obs_table3_whites = t3w$n,
  n_obs_table3_blacks = t3b$n,
  gpa_mixed_room_blacks_table4_panelB_col1 = res4$B_gpa$b,
  exams_passed_mixed_room_blacks_table4_panelB_col2 = res4$B_exams$b,
  eligible_mixed_room_blacks_table4_panelB_col3 = res4$B_elig$b,
  performance_index_mixed_room_blacks_table4_panelB_col4 = res4$B_idx$b,
  gpa_mixed_room_whites_table4_panelA_col1 = res4$W_gpa$b,
  gpa_mixed_room_full_table4_panelC_col1 = res4$F_gpa$b,
  exams_passed_mixed_room_full_table4_panelC_col2 = res4$F_exams$b,
  performance_index_mixed_room_full_table4_panelC_col4 = res4$F_idx$b,
  n_obs_table4_panelC_cols1_2 = res4$F_gpa$n
)
for (nm in names(out)) cat(sprintf("RESULT:%s=%.6f\n", nm, out[[nm]]))
