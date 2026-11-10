# Reproduction of Corno, La Ferrara & Burns (2022), Tables 3 and 4 (selected cells)
# Translates 1_main_tables.do: Table 3 (IAT) and Table 4 (academic performance).
suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/seeded/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance"
d <- read_dta(file.path(base, "ForJournals_a/Data/Clean/uctdata_balanced.dta"))
d <- zap_labels(d)
d <- as.data.frame(d)

controls_subsample <- c("Female", "Falseuct2012", "missfalse", "Foreign", "foreign_missing",
                        "privateschool_nomiss", "privateschool_miss", "durpcabas_nomiss",
                        "durpcabas_miss", "consbas_nomiss", "consbas_miss")
controls <- c("white", "coloured", "Else", controls_subsample)
rocontrols <- c("roFalseuct2012", "missrofalse", "roForeign_bas", "roforeign_missingbas",
                "roprivschool_nomiss", "roprivschool_miss", "rodurpcabas_nomiss",
                "rodurpcabas_miss", "roconsbas_nomiss", "roconsbas_miss")

needed <- c("individual", "round", "white", "black", "mixracebas", "Res_base", "blackRes",
            "whiteRes", "regprogram", "roomnum_base", "DscoreraceIAT", "GPA",
            "examspassed", "continue", "PCAperf", controls, rocontrols)
miss <- setdiff(needed, names(d))
# The do-files run with `set varabbrev on`: a name that is not a variable resolves
# to the unique variable it abbreviates.  Mirror that.
for (v in miss) {
  cand <- names(d)[startsWith(names(d), v)]
  if (length(cand) != 1) stop("Cannot resolve variable ", v, ": ", paste(cand, collapse = ", "))
  cat("varabbrev:", v, "->", cand, "\n")
  d[[v]] <- d[[cand]]
}

# xtset individual round; L.x = value of x in the previous round for the same individual
d <- d %>% arrange(individual, round)
lagdf <- d %>% transmute(individual, round = round + 1, L_DscoreraceIAT = DscoreraceIAT)
d <- d %>% left_join(lagdf, by = c("individual", "round"))

r2 <- d %>% filter(round == 2)
cat("round-2 rows:", nrow(r2), "\n")

rhs <- function(...) paste(c(...), collapse = " + ")

# ---- Table 3: Race IAT ----
f3 <- as.formula(paste("DscoreraceIAT ~", rhs("mixracebas", "L_DscoreraceIAT",
                                               controls_subsample, rocontrols, "factor(Res_base)")))
t3w <- feols(f3, data = subset(r2, white == 1), cluster = ~roomnum_base)
t3b <- feols(f3, data = subset(r2, black == 1), cluster = ~roomnum_base)

# ---- Table 4: performance ----
t4 <- list()
for (y in c("GPA", "examspassed", "continue", "PCAperf")) {
  fs <- as.formula(paste(y, "~", rhs("mixracebas", controls_subsample, rocontrols,
                                     "factor(Res_base)", "factor(regprogram)")))
  ff <- as.formula(paste(y, "~", rhs("mixracebas", controls, rocontrols,
                                     "factor(blackRes)", "factor(whiteRes)",
                                     "factor(Res_base)", "factor(regprogram)")))
  t4[[paste0(y, "_w")]] <- feols(fs, data = subset(r2, white == 1), cluster = ~roomnum_base)
  t4[[paste0(y, "_b")]] <- feols(fs, data = subset(r2, black == 1), cluster = ~roomnum_base)
  t4[[paste0(y, "_f")]] <- feols(ff, data = r2, cluster = ~roomnum_base)
}

show <- function(nm, m) {
  cat(sprintf("%-22s b=%8.4f se=%7.4f N=%d\n", nm, coef(m)["mixracebas"],
              se(m)["mixracebas"], nobs(m)))
}
show("T3 race IAT white", t3w)
show("T3 race IAT black", t3b)
for (nm in names(t4)) show(paste("T4", nm), t4[[nm]])

b <- function(m) unname(coef(m)["mixracebas"])
res <- c(
  race_iat_mixed_room_whites_table3_col1 = b(t3w),
  race_iat_mixed_room_blacks_table3_col2 = b(t3b),
  n_obs_table3_whites = nobs(t3w),
  n_obs_table3_blacks = nobs(t3b),
  gpa_mixed_room_blacks_table4_panelB_col1 = b(t4$GPA_b),
  exams_passed_mixed_room_blacks_table4_panelB_col2 = b(t4$examspassed_b),
  eligible_mixed_room_blacks_table4_panelB_col3 = b(t4$continue_b),
  performance_index_mixed_room_blacks_table4_panelB_col4 = b(t4$PCAperf_b),
  gpa_mixed_room_whites_table4_panelA_col1 = b(t4$GPA_w),
  gpa_mixed_room_full_table4_panelC_col1 = b(t4$GPA_f),
  exams_passed_mixed_room_full_table4_panelC_col2 = b(t4$examspassed_f),
  performance_index_mixed_room_full_table4_panelC_col4 = b(t4$PCAperf_f),
  n_obs_table4_panelC_cols1_2 = nobs(t4$GPA_f)
)
for (nm in names(res)) cat(sprintf("RESULT:%s=%.6f\n", nm, res[[nm]]))
