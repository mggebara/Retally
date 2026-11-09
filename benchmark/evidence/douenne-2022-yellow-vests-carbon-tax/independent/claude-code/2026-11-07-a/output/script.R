# Independent reproduction: Douenne & Fabre (2022), Tables 4, 6, 8
suppressPackageStartupMessages(library(fixest))
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-07-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
e <- new.env(); load(D, envir = e)
s <- e$s
# strip memisc (S4) / Hmisc labelled classes without needing those packages
strip <- function(y) {
  if (isS4(y)) { attributes(y) <- NULL; return(y) }
  if (is.factor(y)) return(as.character(y))
  y <- unclass(y); attributes(y) <- NULL; y
}
num <- function(y) as.numeric(strip(y))
lgl <- function(y) { y <- strip(y); if (is.character(y)) y == "TRUE" else as.logical(y) }

d <- data.frame(
  wfc   = strip(s$winning_feedback_category),
  wc    = strip(s$winning_category),
  Gamma = num(s$simule_gagnant),
  gam   = num(s$simule_gain),
  A0    = as.numeric(lgl(s$tax_acceptance)),
  appr  = as.numeric(lgl(s$tax_approval)),
  gj    = num(s$gilets_jaunes),
  p1    = num(s$percentile_revenu),
  p2    = num(s$percentile_revenu_conjoint),
  single = num(s$single),
  cible = strip(s$cible),
  T1    = num(s$traite_cible),
  T2    = num(s$traite_cible_conjoint),
  AT    = num(s$tax_cible_acceptance),
  GT    = num(s$win_cible_category),
  eff   = strip(s$taxe_efficace),
  ZE    = as.numeric(lgl(s$apres_modifs)),
  ZCC   = num(s$info_CC),
  prog  = strip(s$prog_na),
  sexe  = strip(s$sexe),
  age   = factor(num(s$age)),
  statut = strip(s$statut_emploi),
  csp   = strip(s$csp),
  region = strip(s$region),
  diplome = factor(num(s$diplome4)),
  agglo = factor(num(s$taille_agglo)),
  taille_menage = num(s$taille_menage),
  nb14  = num(s$nb_14_et_plus),
  fume  = strip(s$fume),
  stringsAsFactors = FALSE
)
d$cible <- as.character(d$cible)
d$prog[is.na(d$prog)] <- "NA"
d$effcat <- d$eff
d$GF <- ifelse(is.na(d$wfc), NA, as.numeric(d$wfc != "Loser"))
d$WF <- ifelse(is.na(d$wfc), NA, as.numeric(d$wfc == "Winner"))
d$G0 <- as.numeric(d$wc != "Loser")
d$YV <- as.numeric(d$gj >= 1)
d$E  <- as.numeric(d$eff == "Oui")
for (j in 1:2) for (k in c(20, 70)) d[[paste0("p", j, "m", k)]] <- pmin(d[[paste0("p", j)]] - k, 0)
d$gam2 <- d$gam^2

inc   <- "p1 + p2 + p1m20 + p1m70 + p2m20 + p2m70"
demo  <- "sexe + age + statut + csp + region + diplome + agglo + taille_menage + nb14 + fume"
mot4  <- "prog"                     # other motives: progressivity belief (effectiveness belief dropped: it absorbs initial acceptance)
ctrl4 <- paste(inc, demo, mot4, sep = " + ")

fb  <- subset(d, !is.na(GF))
fb50 <- subset(fb, abs(gam) < 50)
cat("N feedback:", nrow(fb), " N |gain|<50:", nrow(fb50), "\n")

f1 <- as.formula(paste("GF ~ Gamma + A0 + gam + gam2 +", ctrl4))
m1 <- feols(f1, data = fb50, vcov = "hetero")
m2 <- feols(f1, data = fb,   vcov = "hetero")
f3 <- as.formula(paste("GF ~ Gamma*A0 + Gamma*YV + Gamma*G0 + wc + gam + gam2 +", ctrl4))
m3 <- feols(f3, data = fb50, vcov = "hetero")
f4 <- as.formula(paste("WF ~ Gamma + A0 + gam + gam2 +", ctrl4))
m4 <- feols(f4, data = fb50, vcov = "hetero")
print(etable(m1, m2, m3, m4, keep = c("Gamma", "A0", "YV", "G0")))

# Table 6 col 1: 2SLS, random eligibility for targeted dividend, sample [p10;p60]
s6 <- subset(d, (p1 >= 10 & p1 <= 60) | (p2 >= 10 & p2 <= 60))
cat("N Table 6 col1:", nrow(s6), "\n")
f6 <- as.formula(paste("AT ~ single + A0 + gam + gam2 +", ctrl4, "| cible | GT ~ T1 + T2 + T1:T2"))
m6 <- feols(f6, data = s6, vcov = "hetero")
print(summary(m6, stage = 1:2))

# Table 8 col 1: 2SLS, approval on belief in effectiveness, instruments info E.E. and C.C.
mot8 <- "prog + wc"
f8 <- as.formula(paste("appr ~", inc, "+", demo, "+", mot8, "+ gam + gam2 | E ~ ZE + ZCC"))
m8 <- feols(f8, data = d, vcov = "hetero")
print(summary(m8, stage = 1:2))

g <- function(m, v) unname(coef(m)[v])
cat(sprintf("RESULT:predicted_winner_believes_not_lose_table4_col1=%.4f\n", g(m1, "Gamma")))
cat(sprintf("RESULT:initial_acceptance_believes_not_lose_table4_col1=%.4f\n", g(m1, "A0")))
cat(sprintf("RESULT:predicted_winner_believes_not_lose_full_sample_table4_col2=%.4f\n", g(m2, "Gamma")))
cat(sprintf("RESULT:predicted_winner_heterogeneity_table4_col3=%.4f\n", g(m3, "Gamma")))
cat(sprintf("RESULT:initial_acceptance_heterogeneity_table4_col3=%.4f\n", g(m3, "A0")))
cat(sprintf("RESULT:yellow_vests_supporter_heterogeneity_table4_col3=%.4f\n", g(m3, "YV")))
cat(sprintf("RESULT:winner_x_initial_acceptance_table4_col3=%.4f\n", g(m3, "Gamma:A0")))
cat(sprintf("RESULT:winner_x_yellow_vests_supporter_table4_col3=%.4f\n", g(m3, "Gamma:YV")))
cat(sprintf("RESULT:winner_x_initial_win_belief_table4_col3=%.4f\n", g(m3, "Gamma:G0")))
cat(sprintf("RESULT:predicted_winner_believes_wins_table4_col4=%.4f\n", g(m4, "Gamma")))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(m1)))
cat(sprintf("RESULT:believes_not_lose_on_acceptance_iv_table6_col1=%.4f\n", g(m6, "fit_GT")))
cat(sprintf("RESULT:believes_effective_on_approval_iv_table8_col1=%.4f\n", g(m8, "fit_E")))
