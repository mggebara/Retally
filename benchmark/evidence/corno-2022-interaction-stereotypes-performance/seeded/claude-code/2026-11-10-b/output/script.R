# Corno, La Ferrara & Burns (2022) - Table 3 (Race IAT) and Table 4 (academic performance)
# Translation of 1_main_tables.do into fixest.
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)

d <- read_dta("<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-b/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/uctdata_balanced.dta")
d <- zap_labels(d)
d <- as.data.frame(d)

# Lag of race IAT (xtset individual round; L.DscoreraceIAT = round-1 value)
lagdat <- d[d$round == 1, c("individual", "DscoreraceIAT")]
names(lagdat)[2] <- "L_DscoreraceIAT"
r2 <- merge(d[d$round == 2, ], lagdat, by = "individual", all.x = TRUE)

# Stata abbreviation 'roconsbas_miss' resolves to roconsbas_missing (varabbrev on)
controls_sub <- c("Female", "Falseuct2012", "missfalse", "Foreign", "foreign_missing",
                  "privateschool_nomiss", "privateschool_miss", "durpcabas_nomiss",
                  "durpcabas_miss", "consbas_nomiss", "consbas_miss")
controls_full <- c("white", "coloured", "Else", controls_sub)
rocontrols <- c("roFalseuct2012", "missrofalse", "roForeign_bas", "roforeign_missingbas",
                "roprivschool_nomiss", "roprivschool_miss", "rodurpcabas_nomiss",
                "rodurpcabas_miss", "roconsbas_nomiss", "roconsbas_missing")

fit <- function(y, rhs, fe, sub) {
  f <- as.formula(paste(y, "~", paste(rhs, collapse = " + "), "|", fe))
  feols(f, data = sub, cluster = ~roomnum_base, fixef.rm = "none")
}

wh <- r2[r2$white == 1, ]
bl <- r2[r2$black == 1, ]

# Table 3
t3w <- fit("DscoreraceIAT", c("mixracebas", "L_DscoreraceIAT", controls_sub, rocontrols), "Res_base", wh)
t3b <- fit("DscoreraceIAT", c("mixracebas", "L_DscoreraceIAT", controls_sub, rocontrols), "Res_base", bl)

# Table 4
rhs_sub <- c("mixracebas", controls_sub, rocontrols)
rhs_full <- c("mixracebas", controls_full, rocontrols)
fe_sub <- "Res_base + regprogram"
fe_full <- "blackRes + whiteRes + Res_base + regprogram"

res <- list()
for (y in c("GPA", "examspassed", "continue", "PCAperf")) {
  res[[paste0(y, "_w")]] <- fit(y, rhs_sub, fe_sub, wh)
  res[[paste0(y, "_b")]] <- fit(y, rhs_sub, fe_sub, bl)
  res[[paste0(y, "_f")]] <- fit(y, rhs_full, fe_full, r2)
}
b <- function(m) unname(coef(m)["mixracebas"])

for (nm in names(res)) cat(nm, "b =", round(b(res[[nm]]), 4), "se =",
                           round(unname(se(res[[nm]])["mixracebas"]), 4), "N =", nobs(res[[nm]]), "\n")
cat("t3w b =", b(t3w), "N =", nobs(t3w), "; t3b b =", b(t3b), "N =", nobs(t3b), "\n")

out <- c(
  race_iat_mixed_room_whites_table3_col1 = b(t3w),
  race_iat_mixed_room_blacks_table3_col2 = b(t3b),
  n_obs_table3_whites = nobs(t3w),
  n_obs_table3_blacks = nobs(t3b),
  gpa_mixed_room_blacks_table4_panelB_col1 = b(res$GPA_b),
  exams_passed_mixed_room_blacks_table4_panelB_col2 = b(res$examspassed_b),
  eligible_mixed_room_blacks_table4_panelB_col3 = b(res$continue_b),
  performance_index_mixed_room_blacks_table4_panelB_col4 = b(res$PCAperf_b),
  gpa_mixed_room_whites_table4_panelA_col1 = b(res$GPA_w),
  gpa_mixed_room_full_table4_panelC_col1 = b(res$GPA_f),
  exams_passed_mixed_room_full_table4_panelC_col2 = b(res$examspassed_f),
  performance_index_mixed_room_full_table4_panelC_col4 = b(res$PCAperf_f),
  n_obs_table4_panelC_cols1_2 = nobs(res$GPA_f)
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
