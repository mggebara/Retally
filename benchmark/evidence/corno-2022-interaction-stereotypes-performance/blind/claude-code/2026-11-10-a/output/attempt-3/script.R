# Independent, blind reproduction of Corno, La Ferrara & Burns (2022), Tables 3 and 4
# Equation (2): OLS of outcome on Mixed Room, own baseline controls, roommate baseline controls
# (missing values mean-imputed with missing dummies), residence FE (subsamples) or
# race dummies + race-group x residence FE (full sample); academic program FE for performance
# outcomes; lagged dependent variable for IAT outcomes. SEs clustered by room.
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"

d <- read_dta(paste0(base, "uctdata_balanced.dta")) %>% zap_labels()
# Working sample: students interviewed at baseline and follow-up with both IATs (balanced panel);
# one row per student, using the follow-up round.
w <- d %>% filter(round == 2,
                  !is.na(DscoreraceIAT), !is.na(DscoreacaIAT),
                  !is.na(DscoreraceIATbas), !is.na(DscoreacaIATbas))
w <- w %>% mutate(
  racegrp = case_when(Race == 1 ~ "black", Race == 3 ~ "white", TRUE ~ "other"),
  racegrp_res = paste(racegrp, Res_base, sep = "_"),
  room = roomnum_base,
  program = regprogram
)
cat("Working sample N:", nrow(w), "\n")

own <- "Female + Falseuct2012 + missfalse + durpcabas_nomiss + durpcabas_miss + consbas_nomiss + consbas_miss + Foreign + foreign_missing + privateschool_nomiss + privateschool_miss"
ro  <- "roFalseuct2012 + missrofalse + rodurpcabas_nomiss + rodurpcabas_miss + roconsbas_nomiss + roconsbas_missing + roForeign_bas + roforeign_missingbas + roprivschool_nomiss + roprivschool_miss"

whites <- w %>% filter(Race == 3)
blacks <- w %>% filter(Race == 1)

est <- function(y, data, extra = "", fe = "Res_base") {
  f <- as.formula(paste0(y, " ~ mixracebas + ", extra, own, " + ", ro, " | ", fe))
  m <- feols(f, data = data, cluster = ~room, warn = FALSE, notes = FALSE)
  m
}

# Table 3: follow-up Race IAT, controlling for baseline Race IAT
t3w <- est("DscoreraceIAT", whites, extra = "DscoreraceIATbas + ")
t3b <- est("DscoreraceIAT", blacks, extra = "DscoreraceIATbas + ")
print(coeftable(t3w)["mixracebas", ]); print(coeftable(t3b)["mixracebas", ])

# Table 4: performance outcomes. GPA = provided standardized GPA; index = provided PCAperf
# (first principal component of GPA, exams passed, eligible to continue).
sub_fe  <- "Res_base + program"
full_fe <- "racegrp_res + program"
t4 <- list(
  gpa_b   = est("GPA", blacks, fe = sub_fe),
  ex_b    = est("examspassed", blacks, fe = sub_fe),
  el_b    = est("continue", blacks, fe = sub_fe),
  idx_b   = est("PCAperf", blacks, fe = sub_fe),
  gpa_w   = est("GPA", whites, fe = sub_fe),
  gpa_f   = est("GPA", w, extra = "white + coloured + Else + ", fe = full_fe),
  ex_f    = est("examspassed", w, extra = "white + coloured + Else + ", fe = full_fe),
  idx_f   = est("PCAperf", w, extra = "white + coloured + Else + ", fe = full_fe)
)
for (n in names(t4)) { cat(n, " N=", nobs(t4[[n]]), "\n"); print(coeftable(t4[[n]])["mixracebas", ]) }

b <- function(m) unname(coef(m)["mixracebas"])
cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%.6f\n", b(t3w)))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%.6f\n", b(t3b)))
cat(sprintf("RESULT:n_obs_table3_whites=%d\n", nobs(t3w)))
cat(sprintf("RESULT:n_obs_table3_blacks=%d\n", nobs(t3b)))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%.6f\n", b(t4$gpa_b)))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%.6f\n", b(t4$ex_b)))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%.6f\n", b(t4$el_b)))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%.6f\n", b(t4$idx_b)))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%.6f\n", b(t4$gpa_w)))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%.6f\n", b(t4$gpa_f)))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%.6f\n", b(t4$ex_f)))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%.6f\n", b(t4$idx_f)))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%d\n", nobs(t4$gpa_f)))
