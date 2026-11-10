## Independent reproduction: Corno, La Ferrara & Burns (2022), Tables 3 and 4
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-b/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean"
raw <- read_dta(file.path(D, "uctdata_balanced.dta")) %>% zap_labels() %>% zap_formats()

## Working sample: students interviewed at baseline and follow-up with both IATs
## (the balanced panel, 499 students x 2 rounds). Use the follow-up row.
d <- raw %>% filter(round == 2)
cat("students in working sample:", nrow(d), " unique ids:", length(unique(d$nstudent)), "\n")
cat("rooms (res x room):", length(unique(paste(d$Res_base, d$roomnum_base))),
    " rooms (room only):", length(unique(d$roomnum_base)), "\n")
## sanity: baseline IAT equals round-1 IAT
b <- raw %>% filter(round == 1) %>% select(nstudent, iat1 = DscoreraceIAT)
chk <- d %>% left_join(b, by = "nstudent")
cat("max |DscoreraceIATbas - round1 IAT|:", max(abs(chk$DscoreraceIATbas - chk$iat1)), "\n")

d <- d %>% mutate(
  room = paste(Res_base, roomnum_base, sep = "_"),
  racegrp = ifelse(black == 1, "B", ifelse(white == 1, "W", "O")),
  racegrp_res = paste(racegrp, Res_base, sep = "_"),
  program = as.character(regprogram)
)

## Own controls (mean-imputed with missing dummies, as constructed in the data)
own <- c("Female", "Falseuct2012", "missfalse", "durpcabas_nomiss", "durpcabas_miss",
         "consbas_nomiss", "consbas_miss", "Foreign", "foreign_missing",
         "privateschool_nomiss", "privateschool_miss")
## Roommate controls (all but female)
ro <- c("roFalseuct2012", "missrofalse", "rodurpcabas_nomiss", "rodurpcabas_miss",
        "roconsbas_nomiss", "roconsbas_missing", "roForeign_bas", "roforeign_missingbas",
        "roprivschool_nomiss", "roprivschool_miss")
for (v in c(own, ro)) cat(sprintf("%-22s NA=%d\n", v, sum(is.na(d[[v]]))))
ctrl <- paste(c(own, ro), collapse = " + ")

dw <- d %>% filter(white == 1)
db <- d %>% filter(black == 1)
cat("N whites:", nrow(dw), " N blacks:", nrow(db), "\n")

est <- function(fml, data) {
  m <- feols(as.formula(fml), data = data, cluster = ~room, warn = FALSE, notes = FALSE)
  cat(sprintf("  %s\n    b=%.4f se=%.4f N=%d R2=%.3f\n", fml, coef(m)["mixracebas"],
              se(m)["mixracebas"], nobs(m), r2(m, "r2")))
  m
}

## Table 3: Race IAT
cat("\nTable 3\n")
t3w <- est(paste("DscoreraceIAT ~ mixracebas + DscoreraceIATbas +", ctrl, "| Res_base"), dw)
t3b <- est(paste("DscoreraceIAT ~ mixracebas + DscoreraceIATbas +", ctrl, "| Res_base"), db)

## Table 4: academic performance
ys <- c(gpa = "GPA", exams = "examspassed", elig = "continue", idx = "PCAperf")
cat("\nTable 4 Panel A (whites)\n")
t4w <- lapply(ys, function(y) est(paste(y, "~ mixracebas +", ctrl, "| Res_base + program"), dw))
cat("\nTable 4 Panel B (blacks)\n")
t4b <- lapply(ys, function(y) est(paste(y, "~ mixracebas +", ctrl, "| Res_base + program"), db))
cat("\nTable 4 Panel C (full)\n")
t4c <- lapply(ys, function(y) est(paste(y, "~ mixracebas + white + coloured + Else +", ctrl,
                                         "| racegrp_res + program"), d))

b <- function(m) unname(coef(m)["mixracebas"])
cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%.6f\n", b(t3w)))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%.6f\n", b(t3b)))
cat(sprintf("RESULT:n_obs_table3_whites=%d\n", nobs(t3w)))
cat(sprintf("RESULT:n_obs_table3_blacks=%d\n", nobs(t3b)))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%.6f\n", b(t4b$gpa)))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%.6f\n", b(t4b$exams)))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%.6f\n", b(t4b$elig)))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%.6f\n", b(t4b$idx)))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%.6f\n", b(t4w$gpa)))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%.6f\n", b(t4c$gpa)))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%.6f\n", b(t4c$exams)))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%.6f\n", b(t4c$idx)))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%d\n", nobs(t4c$gpa)))
