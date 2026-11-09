# Grier, Grier & Mkrtchian (2023) -- independent, blind reproduction of Table 1 and Table 3
# Fixed-effects logit (unconditional ML with district / incumbent dummies) of an "aye" vote on
# the 2013 Pitts and 2018 Foxx sugar-reform amendments, robust (HC) standard errors.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-07-a/mount/grier_2023_sugar_roll_call_voting"

# Contribution windows (inferred from the data; see notes):
#   SugarReplicate.dta       totalcont = baseline window (1 yr before vote -> end of vote's calendar year; largest sums)
#   SugarReplicate_iter2.dta totalcont = calendar year of the vote (2013, 2018)
#   SugarReplicate_iter1.dta totalcont = 12 months before the vote up to the vote date
files <- c(base = "SugarReplicate.dta", cal = "SugarReplicate_iter2.dta", m12 = "SugarReplicate_iter1.dta")

# CPI-U (all items, U.S. city average) annual averages; contributions expressed in 2018 dollars
cpi <- c(`113` = 232.957, `115` = 251.107)

prep <- function(f) {
  d <- zap_labels(read_dta(file.path(D, f)))
  d$y <- as.integer(d$vote == "Aye")                      # 1 = aye (against sugar), 0 otherwise
  d$realcont <- d$totalcont * cpi["115"] / cpi[as.character(d$cong)]
  d <- d[complete.cases(d[, c("y","realcont","ncu","tenure","poverty","bach","medincome","over65","agcom","id")]), ]
  # incumbent sample: districts where the same member cast both votes (both == 1 in both rows)
  inc_ids <- d %>% group_by(id) %>% summarise(k = n(), b = all(both == 1 & !is.na(both)), .groups = "drop") %>%
    filter(k == 2, b) %>% pull(id)
  d$inc <- d$id %in% inc_ids
  d
}

fml <- y ~ realcont + ncu + tenure + poverty + bach + medincome + over65 + agcom | id
est <- function(d) feglm(fml, data = d, family = binomial("logit"), vcov = "hetero")

res <- list()
for (w in names(files)) {
  d <- prep(files[[w]])
  m_d <- est(d)
  m_i <- est(d[d$inc, ])
  cat("\n==== window:", w, "====\n"); print(summary(m_d)); print(summary(m_i))
  res[[w]] <- list(d = m_d, i = m_i)
}

b <- function(m, v) unname(coef(m)[v])
out <- c(
  sugar_contributions_district_fe = b(res$base$d, "realcont"),
  sugar_contributions_incumbent_fe = b(res$base$i, "realcont"),
  acu_ideology_district_fe = b(res$base$d, "ncu"),
  tenure_district_fe = b(res$base$d, "tenure"),
  tenure_incumbent_fe = b(res$base$i, "tenure"),
  sugar_contributions_calendar_year_district_fe = b(res$cal$d, "realcont"),
  sugar_contributions_calendar_year_incumbent_fe = b(res$cal$i, "realcont"),
  sugar_contributions_12_months_district_fe = b(res$m12$d, "realcont"),
  sugar_contributions_12_months_incumbent_fe = b(res$m12$i, "realcont"),
  observations_district_fe = nobs(res$base$d),
  observations_incumbent_fe = nobs(res$base$i)
)
cat("\nDEVIATION: inflation adjustment uses CPI-U annual averages (2013=232.957, 2018=251.107), contributions in 2018 dollars; the paper does not state its deflator.\n")
cat("DEVIATION: window-to-file mapping (iter2=calendar year, iter1=12 months) inferred from election-year timing of contribution totals.\n")
for (n in names(out)) cat(sprintf("RESULT:%s=%.10g\n", n, out[[n]]))
