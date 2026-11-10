# Independent, blind reproduction: Corno, La Ferrara & Burns (2022)
# "Interaction, Stereotypes, and Performance: Evidence from South Africa"
# Tables 3 (Race IAT) and 4 (academic performance), Mixed Room coefficients and N.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})

D <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-b/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
d <- read_dta(paste0(D, "uctdata_balanced.dta"))

# Working sample: balanced panel (baseline + follow-up, both IATs non-missing) -> keep the
# follow-up round, one row per student. Baseline IATs are carried in *_bas columns.
f <- d %>% filter(as.numeric(round) == 2) %>% mutate(across(where(is.labelled), ~ as.numeric(.x)))
stopifnot(!anyNA(f$DscoreraceIAT), !anyNA(f$DscoreraceIATbas),
          !anyNA(f$DscoreacaIAT), !anyNA(f$DscoreacaIATbas))
cat("Working sample (students):", nrow(f), "\n")

# Race group for race x residence FE: Black, White, residual (coloured, Indian/Asian, other)
f <- f %>% mutate(
  racegrp = ifelse(black == 1, "B", ifelse(white == 1, "W", "O")),
  racegrp_res = paste(racegrp, Res_base, sep = "_"),
  room = roomnum_base
)

# Own controls (mean-imputed with missing dummies, as constructed in the data)
own <- c("Female", "Falseuct2012", "missfalse", "durpcabas_nomiss", "durpcabas_miss",
         "consbas_nomiss", "consbas_miss", "Foreign", "foreign_missing",
         "privateschool_nomiss", "privateschool_miss")
# Roommate controls (all but female; rooms are single-sex)
ro <- c("roFalseuct2012", "missrofalse", "rodurpcabas_nomiss", "rodurpcabas_miss",
        "roconsbas_nomiss", "roconsbas_missing", "roForeign_bas", "roforeign_missingbas",
        "roprivschool_nomiss", "roprivschool_miss")
# drop controls with no variation in the working sample (missing dummies that are all 0)
nonconst <- function(v, dd) length(unique(dd[[v]])) > 1
ctrl <- function(dd) paste(c(own, ro)[sapply(c(own, ro), nonconst, dd = dd)], collapse = " + ")

wh <- f %>% filter(white == 1)
bl <- f %>% filter(black == 1)

est <- function(y, dd, extra = "", fe = "Res_base") {
  fml <- as.formula(paste0(y, " ~ mixracebas", extra, " + ", ctrl(dd), " | ", fe))
  m <- feols(fml, data = dd, cluster = ~room, fixef.rm = "none", notes = FALSE)
  list(b = unname(coef(m)["mixracebas"]), se = unname(se(m)["mixracebas"]), n = nobs(m), m = m)
}

# ---- Table 3: follow-up Race IAT on Mixed Room, baseline Race IAT, controls, residence FE
t3w <- est("DscoreraceIAT", wh, extra = " + DscoreraceIATbas")
t3b <- est("DscoreraceIAT", bl, extra = " + DscoreraceIATbas")
# Academic IAT columns (3)-(4), for reference only
t3wa <- est("DscoreacaIAT", wh, extra = " + DscoreacaIATbas")
t3ba <- est("DscoreacaIAT", bl, extra = " + DscoreacaIATbas")
cat(sprintf("T3 col1 white  RaceIAT: b=%.4f se=%.4f n=%d\n", t3w$b, t3w$se, t3w$n))
cat(sprintf("T3 col2 black  RaceIAT: b=%.4f se=%.4f n=%d\n", t3b$b, t3b$se, t3b$n))
cat(sprintf("T3 col3 white  AcaIAT : b=%.4f se=%.4f n=%d\n", t3wa$b, t3wa$se, t3wa$n))
cat(sprintf("T3 col4 black  AcaIAT : b=%.4f se=%.4f n=%d\n", t3ba$b, t3ba$se, t3ba$n))

# ---- Table 4: academic performance, + academic program FE
# GPA: provided standardized first-year GPA (mean 0, sd 1 over the full sample)
# Index: provided first principal component of GPA, exams passed and eligible to continue (PCAperf)
outs <- c(gpa = "GPA", exams = "examspassed", elig = "continue", idx = "PCAperf")
t4A <- lapply(outs, est, dd = wh, fe = "Res_base + regprogram")
t4B <- lapply(outs, est, dd = bl, fe = "Res_base + regprogram")
t4C <- lapply(outs, est, dd = f, extra = " + white + coloured + Else", fe = "racegrp_res + regprogram")
for (p in c("A", "B", "C")) {
  L <- get(paste0("t4", p))
  for (k in names(L)) cat(sprintf("T4 panel %s %-6s: b=%.4f se=%.4f n=%d\n", p, k, L[[k]]$b, L[[k]]$se, L[[k]]$n))
}

# Robustness (not scored): index recomputed as PC1 of the three standardized outcomes in the working sample
ok <- complete.cases(f[, c("GPA", "examspassed", "continue")])
pc <- prcomp(f[ok, c("GPA", "examspassed", "continue")], scale. = TRUE)
s <- sign(pc$rotation[1, 1])
f$idx_own <- NA_real_; f$idx_own[ok] <- s * pc$x[, 1]
r1 <- est("idx_own", f, extra = " + white + coloured + Else", fe = "racegrp_res + regprogram")
r2 <- est("idx_own", f %>% filter(black == 1), fe = "Res_base + regprogram")
cat(sprintf("Robustness own-PC1 index: full b=%.4f (n=%d); black b=%.4f (n=%d)\n", r1$b, r1$n, r2$b, r2$n))

cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%.6f\n", t3w$b))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%.6f\n", t3b$b))
cat(sprintf("RESULT:n_obs_table3_whites=%d\n", t3w$n))
cat(sprintf("RESULT:n_obs_table3_blacks=%d\n", t3b$n))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%.6f\n", t4B$gpa$b))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%.6f\n", t4B$exams$b))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%.6f\n", t4B$elig$b))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%.6f\n", t4B$idx$b))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%.6f\n", t4A$gpa$b))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%.6f\n", t4C$gpa$b))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%.6f\n", t4C$exams$b))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%.6f\n", t4C$idx$b))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%d\n", t4C$gpa$n))
