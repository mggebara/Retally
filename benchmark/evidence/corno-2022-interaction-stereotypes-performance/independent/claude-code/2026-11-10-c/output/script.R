# Independent reproduction: Corno, La Ferrara & Burns (2022), Tables 3 and 4
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
d <- read_dta(paste0(D, "uctdata_balanced.dta")) %>% zap_labels()

# Working sample: balanced panel (499 students x 2 rounds); keep follow-up round
fu <- d %>% filter(round == 2) %>%
  mutate(room = paste(Res_base, roomnum_base),
         racegrp = ifelse(black == 1, "B", ifelse(white == 1, "W", "O")),
         racegrp_res = paste(racegrp, Res_base),
         regprogram = as.character(regprogram))
cat("Follow-up N:", nrow(fu), " whites:", sum(fu$white), " blacks:", sum(fu$black), "\n")
cat("Rooms:", length(unique(fu$room)), " roomnum unique:", length(unique(fu$roomnum_base)), "\n")

own <- "Female + Falseuct2012 + missfalse + durpcabas_nomiss + durpcabas_miss + consbas_nomiss + consbas_miss + Foreign + foreign_missing + privateschool_nomiss + privateschool_miss"
ro  <- "roFalseuct2012 + missrofalse + rodurpcabas_nomiss + rodurpcabas_miss + roconsbas_nomiss + roconsbas_missing + roForeign_bas + roforeign_missingbas + roprivschool_nomiss + roprivschool_miss"

est <- function(f, data) {
  # keep singleton FE groups (as with dummy-variable OLS) so N is the full working sample
  m <- feols(as.formula(f), data = data, cluster = ~room, fixef.rm = "none", warn = FALSE, notes = FALSE)
  list(b = unname(coef(m)["mixracebas"]), se = unname(se(m)["mixracebas"]), n = nobs(m))
}

W <- fu %>% filter(white == 1); B <- fu %>% filter(black == 1)

# Table 3: follow-up Race IAT on Mixed Room + baseline IAT + controls, residence FE
f3 <- paste("DscoreraceIAT ~ mixracebas + DscoreraceIATbas +", own, "+", ro, "| Res_base")
t3w <- est(f3, W); t3b <- est(f3, B)
cat(sprintf("T3 col1 whites: b=%.4f se=%.4f n=%d\n", t3w$b, t3w$se, t3w$n))
cat(sprintf("T3 col2 blacks: b=%.4f se=%.4f n=%d\n", t3b$b, t3b$se, t3b$n))

# Table 4 subsamples: residence FE + program FE
f4 <- function(y) paste(y, "~ mixracebas +", own, "+", ro, "| Res_base + regprogram")
# Table 4 full: race dummies + race group x residence FE + program FE
f4c <- function(y) paste(y, "~ mixracebas + white + coloured + Else +", own, "+", ro, "| racegrp_res + regprogram")

res <- list()
for (y in c("GPA", "examspassed", "continue", "PCAperf")) {
  res[[paste0("A_", y)]] <- est(f4(y), W)
  res[[paste0("B_", y)]] <- est(f4(y), B)
  res[[paste0("C_", y)]] <- est(f4c(y), fu)
}
for (k in names(res)) cat(sprintf("T4 %-14s b=%.4f se=%.4f n=%d\n", k, res[[k]]$b, res[[k]]$se, res[[k]]$n))

cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%.4f\n", t3w$b))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%.4f\n", t3b$b))
cat(sprintf("RESULT:n_obs_table3_whites=%d\n", t3w$n))
cat(sprintf("RESULT:n_obs_table3_blacks=%d\n", t3b$n))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%.4f\n", res$B_GPA$b))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%.4f\n", res$B_examspassed$b))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%.4f\n", res$B_continue$b))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%.4f\n", res$B_PCAperf$b))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%.4f\n", res$A_GPA$b))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%.4f\n", res$C_GPA$b))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%.4f\n", res$C_examspassed$b))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%.4f\n", res$C_PCAperf$b))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%d\n", res$C_GPA$n))
