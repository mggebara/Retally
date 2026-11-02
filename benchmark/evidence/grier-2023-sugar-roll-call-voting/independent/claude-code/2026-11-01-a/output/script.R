# Independent reproduction: Grier, Grier & Mkrtchian (2023, APSR), Tables 1 and 3.
# Logit of aye (1 = aye on the sugar-reform amendment, 0 otherwise) on inflation-adjusted
# sugar contributions, ACU score, tenure, poverty, % bachelor's, median income, % over 65,
# agriculture-committee dummy, plus district (or incumbent) dummies.  Estimated as an
# unconditional logit with FE dummies (Stata-style `logit ... i.fe, robust`), which keeps
# only units whose vote switched between 2013 and 2018.  Robust (HC0-type) p-values printed.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-01-a/mount/grier_2023_sugar_roll_call_voting"

# CPI-U annual averages (BLS): 2013 = 232.957, 2018 = 251.107. 2018 money expressed in 2013 dollars.
cpi13 <- 232.957; cpi18 <- 251.107

prep <- function(f) {
  read_dta(file.path(D, f)) %>%
    mutate(aye = as.integer(vote == "Aye"),
           realcont = ifelse(cong == 115, totalcont * cpi13 / cpi18, totalcont),
           district_id = factor(id), member_id = factor(cid))
}
ctrl <- c("realcont", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

fit_fe <- function(d, fe) {
  d <- d[complete.cases(d[, c("aye", ctrl)]), ]
  if (fe == "member_id") {
    # incumbents who voted (appear) in both Congresses
    keep <- d %>% group_by(member_id) %>% summarise(nc = n_distinct(cong)) %>% filter(nc == 2)
    d <- d %>% filter(member_id %in% keep$member_id)
  }
  # units with within-unit variation in the outcome (others are perfectly predicted and dropped)
  sw <- d %>% group_by(.data[[fe]]) %>% summarise(v = n_distinct(aye)) %>% filter(v == 2)
  d <- d %>% filter(.data[[fe]] %in% sw[[fe]]) %>% droplevels()
  fml <- as.formula(paste("aye ~", paste(ctrl, collapse = " + "), "+", fe))
  m <- suppressWarnings(glm(fml, data = d, family = binomial(), control = glm.control(maxit = 200, epsilon = 1e-12)))
  rob <- tryCatch(coeftest(m, vcov = vcovHC(m, type = "HC0"))[ctrl, ], error = function(e) NULL)
  m0 <- suppressWarnings(glm(aye ~ 1, data = d, family = binomial()))
  list(m = m, rob = rob, n = nobs(m), units = nlevels(d[[fe]]),
       pr2 = 1 - as.numeric(logLik(m)) / as.numeric(logLik(m0)))
}

files <- c(base = "SugarReplicate.dta", cal = "SugarReplicate_iter1.dta", m12 = "SugarReplicate_iter2.dta")
res <- list()
for (w in names(files)) {
  d <- prep(files[w])
  for (fe in c("district_id", "member_id")) {
    r <- fit_fe(d, fe)
    res[[paste(w, fe)]] <- r
    cat("\n=== window:", w, " FE:", fe, " N =", r$n, " units =", r$units, " pseudoR2 =", round(r$pr2, 3), "\n")
    print(round(cbind(coef = coef(r$m)[ctrl], if (!is.null(r$rob)) r$rob[, c(2, 4)]), 5))
  }
}

b <- function(k, v) unname(coef(res[[k]]$m)[v])
cat(sprintf("RESULT:sugar_contributions_district_fe=%.6g\n", b("base district_id", "realcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.6g\n", b("base member_id", "realcont")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.6g\n", b("base district_id", "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.6g\n", b("base district_id", "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.6g\n", b("base member_id", "tenure")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.6g\n", b("cal district_id", "realcont")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.6g\n", b("cal member_id", "realcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.6g\n", b("m12 district_id", "realcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.6g\n", b("m12 member_id", "realcont")))
cat(sprintf("RESULT:observations_district_fe=%d\n", res[["base district_id"]]$n))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", res[["base member_id"]]$n))
cat("DEVIATION: inflation adjustment uses CPI-U annual averages, 2018 contributions in 2013 dollars (paper does not state deflator/base year)\n")
cat("DEVIATION: mapping of data files to windows assumed: SugarReplicate.dta = baseline, _iter1 = calendar year, _iter2 = 12 months before vote\n")
