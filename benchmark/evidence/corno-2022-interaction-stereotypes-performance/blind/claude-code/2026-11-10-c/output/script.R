# Independent, blind reproduction: Corno, La Ferrara & Burns (2022)
# "Interaction, Stereotypes, and Performance: Evidence from South Africa"
# Tables 3 (Race IAT) and 4 (academic performance), Mixed Room coefficients.
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})

base <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean"
raw <- read_dta(file.path(base, "uctdata_balanced.dta"))

# Working sample: students interviewed at baseline and follow-up with both IATs
# (the balanced panel). One row per student = the follow-up (round 2) row, which
# carries follow-up IATs, baseline IATs (…bas), baseline controls and 2012 academic outcomes.
d <- raw %>% filter(round == 2) %>%
  filter(!is.na(DscoreraceIAT), !is.na(DscoreacaIAT), !is.na(DscoreraceIATbas), !is.na(DscoreacaIATbas)) %>%
  mutate(regprogram = as.character(regprogram),
         Res_base = as.integer(Res_base),
         room = as.integer(roomnum_base),
         racegrp = case_when(black == 1 ~ "black", white == 1 ~ "white", TRUE ~ "other"))
stopifnot(!any(duplicated(d$nstudent)))

# Own baseline controls (missing values replaced by means, with missing dummies)
own <- c("Female", "Falseuct2012", "missfalse", "durpcabas_nomiss", "durpcabas_miss",
         "consbas_nomiss", "consbas_miss", "Foreign", "foreign_missing",
         "privateschool_nomiss", "privateschool_miss")
# Roommate baseline controls (all but female), mean-imputed with missing dummies
ro  <- c("roFalseuct2012", "missrofalse", "rodurpcabas_nomiss", "rodurpcabas_miss",
         "roconsbas_nomiss", "roconsbas_missing", "roForeign_bas", "roforeign_missingbas",
         "roprivschool_nomiss", "roprivschool_miss")
# drop controls that are constant in the working sample (all-zero missing dummies)
keep_var <- function(v) length(unique(d[[v]])) > 1
own <- own[sapply(own, keep_var)]; ro <- ro[sapply(ro, keep_var)]
ctrl <- paste(c(own, ro), collapse = " + ")

# Academic performance index: first principal component of GPA, exams passed,
# eligible to continue (correlation-matrix PCA over working-sample students with all three)
pc_ok <- with(d, !is.na(GPA) & !is.na(examspassed) & !is.na(continue))
pc <- prcomp(as.data.frame(d[pc_ok, c("GPA", "examspassed", "continue")]), center = TRUE, scale. = TRUE)
sc <- pc$x[, 1]
if (cor(sc, d$GPA[pc_ok]) < 0) sc <- -sc
d$perf_index <- NA_real_; d$perf_index[pc_ok] <- sc
cat(sprintf("PCA: eigenvalues %s; loadings %s\n", paste(round(pc$sdev^2, 3), collapse = ","),
            paste(round(abs(pc$rotation[, 1]), 3), collapse = ",")))
cat(sprintf("Diagnostic: cor(own index, dataset PCAperf) = %.4f; sd own = %.4f, sd PCAperf = %.4f\n",
            cor(d$perf_index, d$PCAperf, use = "complete.obs"), sd(d$perf_index, na.rm = TRUE), sd(d$PCAperf, na.rm = TRUE)))

whites <- d %>% filter(white == 1)
blacks <- d %>% filter(black == 1)
cat(sprintf("Working sample N = %d (whites %d, blacks %d, mixed %d)\n", nrow(d), nrow(whites), nrow(blacks), sum(d$mixracebas)))

cl <- ~room
co <- function(m) unname(coef(m)["mixracebas"])
show <- function(lbl, m) cat(sprintf("%-28s b=%8.4f se=%7.4f N=%d R2=%.3f\n", lbl, co(m), se(m)["mixracebas"], nobs(m), r2(m, "r2")))

# ---- Table 3: Race IAT, residence FE, by race
f3 <- as.formula(paste("DscoreraceIAT ~ mixracebas + DscoreraceIATbas +", ctrl, "| Res_base"))
t3w <- feols(f3, data = whites, cluster = cl, fixef.rm = "none")
t3b <- feols(f3, data = blacks, cluster = cl, fixef.rm = "none")
show("T3 col1 whites race IAT", t3w); show("T3 col2 blacks race IAT", t3b)

# ---- Table 4: academic outcomes, residence + program FE (subsamples)
f4 <- function(y) as.formula(paste(y, "~ mixracebas +", ctrl, "| Res_base + regprogram"))
f4c <- function(y) as.formula(paste(y, "~ mixracebas + white + coloured + Else +", ctrl, "| racegrp^Res_base + regprogram"))
ys <- c("GPA", "examspassed", "continue", "perf_index")
A <- lapply(ys, function(y) feols(f4(y), data = whites, cluster = cl, fixef.rm = "none"))
B <- lapply(ys, function(y) feols(f4(y), data = blacks, cluster = cl, fixef.rm = "none"))
C <- lapply(ys, function(y) feols(f4c(y), data = d, cluster = cl, fixef.rm = "none"))
for (i in seq_along(ys)) { show(paste("T4 A whites", ys[i]), A[[i]]); show(paste("T4 B blacks", ys[i]), B[[i]]); show(paste("T4 C full", ys[i]), C[[i]]) }

cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%.6f\n", co(t3w)))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%.6f\n", co(t3b)))
cat(sprintf("RESULT:n_obs_table3_whites=%d\n", nobs(t3w)))
cat(sprintf("RESULT:n_obs_table3_blacks=%d\n", nobs(t3b)))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%.6f\n", co(B[[1]])))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%.6f\n", co(B[[2]])))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%.6f\n", co(B[[3]])))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%.6f\n", co(B[[4]])))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%.6f\n", co(A[[1]])))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%.6f\n", co(C[[1]])))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%.6f\n", co(C[[2]])))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%.6f\n", co(C[[4]])))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%d\n", nobs(C[[1]])))
