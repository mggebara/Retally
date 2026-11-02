# Grier, Grier & Mkrtchian (2023 APSR): sugar contributions and roll-call voting.
# Independent, blind reproduction of Table 1 and Table 3 (sugar-contribution rows).
# Model: logit of Aye (=1; 0 otherwise) on inflation-adjusted sugar contributions,
# ACU score, tenure, poverty rate, % bachelor's, median income, % over 65,
# agriculture-committee dummy, with district (or incumbent) fixed effects
# (unconditional FE logit, as Stata `logit ... i.district`, which drops
# districts that do not switch). Robust SEs.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-10-22-a/mount/grier_2023_sugar_roll_call_voting"

# Files: the readme says the three dta files hold author-aggregated sugar
# contributions (variable totalcont) over the three windows in the text.
#  SugarReplicate.dta       -> baseline window (largest; superset of the others)
#  SugarReplicate_iter2.dta -> calendar year of the vote (2013 / 2018)
#  SugarReplicate_iter1.dta -> 12 months before the vote up to the vote date
# (assignment of iter1/iter2 inferred from election-cycle seasonality, see notes)
files <- c(base = "SugarReplicate.dta", cal = "SugarReplicate_iter2.dta", m12 = "SugarReplicate_iter1.dta")

# CPI-U annual averages (BLS, 1982-84=100): 2013 = 232.957, 2018 = 251.107.
# Contributions expressed in constant 2013 dollars.
cpi <- c(`113` = 232.957, `115` = 251.107)

prep <- function(f) {
  d <- read_dta(file.path(D, f))
  d <- zap_labels(d)
  d$y <- as.numeric(d$vote == "Aye")
  d$realsug <- d$totalcont * cpi["113"] / cpi[as.character(d$cong)]
  vars <- c("y", "realsug", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom", "id")
  d[complete.cases(d[, vars]), ]
}

fml <- y ~ realsug + ncu + tenure + poverty + bach + medincome + over65 + agcom | id

fit_pair <- function(d) {
  m_d <- feglm(fml, data = d, family = binomial("logit"), vcov = "hetero")
  # incumbent FE: same member voted on both amendments (both == 1); within these
  # rows the district FE is the incumbent FE
  di <- d %>% filter(both == 1)
  m_i <- feglm(fml, data = di, family = binomial("logit"), vcov = "hetero")
  list(d = m_d, i = m_i)
}

res <- lapply(files, function(f) fit_pair(prep(f)))

for (nm in names(res)) {
  cat("\n==== window:", nm, "====\n")
  cat("-- District FE --\n"); print(coeftable(res[[nm]]$d))
  cat("nobs:", nobs(res[[nm]]$d), " groups:", res[[nm]]$d$fixef_sizes, "\n")
  cat("-- Incumbent FE --\n"); print(coeftable(res[[nm]]$i))
  cat("nobs:", nobs(res[[nm]]$i), " groups:", res[[nm]]$i$fixef_sizes, "\n")
}

# Cross-check with glm + dummies on the switching sample (baseline, district FE)
d0 <- prep(files["base"])
sw <- d0 %>% group_by(id) %>% filter(n() == 2, mean(y) > 0, mean(y) < 1) %>% ungroup()
g <- glm(y ~ realsug + ncu + tenure + poverty + bach + medincome + over65 + agcom + factor(id),
         data = sw, family = binomial)
cat("\nglm cross-check realsug:", coef(g)["realsug"], " nobs:", nobs(g),
    " McFadden pseudo R2:", 1 - g$deviance / g$null.deviance, "\n")

b <- function(m, v) unname(coef(m)[v])
cat(sprintf("RESULT:sugar_contributions_district_fe=%.10g\n", b(res$base$d, "realsug")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.10g\n", b(res$base$i, "realsug")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.10g\n", b(res$base$d, "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.10g\n", b(res$base$d, "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.10g\n", b(res$base$i, "tenure")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.10g\n", b(res$cal$d, "realsug")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.10g\n", b(res$cal$i, "realsug")))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.10g\n", b(res$m12$d, "realsug")))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.10g\n", b(res$m12$i, "realsug")))
cat(sprintf("RESULT:observations_district_fe=%d\n", nobs(res$base$d)))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", nobs(res$base$i)))
cat("DEVIATION: inflation adjustment uses CPI-U annual averages to express contributions in constant 2013 dollars (base year not stated in the paper)\n")
cat("DEVIATION: iter1/iter2 file-to-window mapping inferred (iter2 = calendar year, iter1 = 12 months before vote); not stated in the readme\n")
