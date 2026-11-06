suppressPackageStartupMessages({
  library(haven)
  library(readr)
  library(fixest)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation"

## ---------------- Table 2: weighted OLS on public goods game -----------------
pg <- haven::read_dta(file.path(base_dir, "publicgoodgame_dataAug27.dta"))
pg <- as.data.frame(lapply(pg, function(x) {
  if (inherits(x, "haven_labelled")) as.numeric(haven::zap_labels(x)) else x
}))

pg$p_type_f <- factor(pg$p_type)

vars_t2 <- c("contribution", "decentralized", "p_type_f", "communication", "round",
             "lag_groupcontribution", "num_players", "knownpeople", "Q2_female",
             "Q1_Edad", "Q2_Educacion", "Q3_YrsSalud", "Q5_Trust1Base",
             "weights_games_full_scaled", "publicid")
pg_cc <- pg[complete.cases(pg[, vars_t2]), ]

# Stata: reg contribution $xlistfinal [pweight=...], vce(cluster publicid)
m1 <- feols(contribution ~ decentralized + p_type_f + communication + round +
              lag_groupcontribution + num_players + knownpeople + Q2_female +
              Q1_Edad + Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base,
            data = pg_cc, weights = ~weights_games_full_scaled,
            cluster = ~publicid)

# Stata: i.decentralized##i.communication
m2 <- feols(contribution ~ decentralized * communication + p_type_f + round +
              lag_groupcontribution + num_players + knownpeople + Q2_female +
              Q1_Edad + Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base,
            data = pg_cc, weights = ~weights_games_full_scaled,
            cluster = ~publicid)

c1 <- coef(m1)
c2 <- coef(m2)
int_name <- grep("decentralized:communication|communication:decentralized", names(c2), value = TRUE)[1]

se1 <- sqrt(diag(vcov(m1)))
se2 <- sqrt(diag(vcov(m2)))

## ---------------- Table 3: weighted Poisson on cross-level ties --------------
cl <- readr::read_csv(file.path(base_dir, "clanalysis_anondata_vNov16.csv"),
                      show_col_types = FALSE)
cl <- as.data.frame(cl)

clse_f <- function(dat, fm, cluster) {
  not <- attr(fm$model, "na.action")
  if (!is.null(not)) {
    cluster <- cluster[-not]
  }
  M <- length(unique(cluster))
  N <- length(cluster)
  K <- fm$rank
  dfc <- (M / (M - 1)) * ((N - 1) / (N - K))
  uj <- apply(estfun(fm), 2, function(x) tapply(x, cluster, sum))
  vc <- dfc * sandwich(fm, meat = crossprod(uj) / N)
  coeftest(fm, vc)
}

fit_pois <- function(formula, dat) {
  fm <- tryCatch(
    suppressWarnings(glm(formula, family = "poisson",
                         weights = weights_games_full_scaled, data = dat)),
    error = function(e) NULL)
  fm
}

f_kb <- net_crosslevel_propnumknown ~ decentralized + offset(log(net_crosslevel_propdenomknown))
f_fb <- net_crosslevel_propnumfriends ~ decentralized + offset(log(net_crosslevel_propdenomfriends))
f_kf <- net_crosslevel_propnumknown ~ decentralized + Mujer + Q2_Educacion + Q1_Edad +
  Q3_YrsSalud + gen_trust + Participant_C + Participant_G + Participant_R +
  offset(log(net_crosslevel_propdenomknown))
f_ff <- net_crosslevel_propnumfriends ~ decentralized + Mujer + Q2_Educacion + Q1_Edad +
  Q3_YrsSalud + gen_trust + Participant_C + Participant_G + Participant_R +
  offset(log(net_crosslevel_propdenomfriends))

fit_with_fallback <- function(formula, denom) {
  fm <- fit_pois(formula, cl)
  dat <- cl
  if (is.null(fm)) {
    dat <- cl[!is.na(cl[[denom]]) & cl[[denom]] > 0, ]
    fm <- fit_pois(formula, dat)
  }
  list(fm = fm, dat = dat)
}

r_kb <- fit_with_fallback(f_kb, "net_crosslevel_propdenomknown")
r_fb <- fit_with_fallback(f_fb, "net_crosslevel_propdenomfriends")
r_kf <- fit_with_fallback(f_kf, "net_crosslevel_propdenomknown")
r_ff <- fit_with_fallback(f_ff, "net_crosslevel_propdenomfriends")

cse_kb <- clse_f(r_kb$dat, r_kb$fm, r_kb$dat$publicid_muni)
cse_fb <- clse_f(r_fb$dat, r_fb$fm, r_fb$dat$publicid_muni)
cse_kf <- clse_f(r_kf$dat, r_kf$fm, r_kf$dat$publicid_muni)
cse_ff <- clse_f(r_ff$dat, r_ff$fm, r_ff$dat$publicid_muni)

## ---------------- Output ------------------------------------------------------
fmt <- function(x) format(unname(x), digits = 10)

cat(paste0("RESULT:decentralized_table2_col1=", fmt(c1["decentralized"]), "\n"))
cat(paste0("RESULT:communication_table2_col1=", fmt(c1["communication"]), "\n"))
cat(paste0("RESULT:decentralized_table2_col2=", fmt(c2["decentralized"]), "\n"))
cat(paste0("RESULT:communication_table2_col2=", fmt(c2["communication"]), "\n"))
cat(paste0("RESULT:decentralized_x_communication_table2_col2=", fmt(c2[int_name]), "\n"))
cat(paste0("RESULT:n_obs_table2=", nobs(m1), "\n"))
cat(paste0("RESULT:decentralized_table3_allties_base=", fmt(coef(r_kb$fm)["decentralized"]), "\n"))
cat(paste0("RESULT:decentralized_table3_allties_full=", fmt(coef(r_kf$fm)["decentralized"]), "\n"))
cat(paste0("RESULT:decentralized_table3_strongties_base=", fmt(coef(r_fb$fm)["decentralized"]), "\n"))
cat(paste0("RESULT:decentralized_table3_strongties_full=", fmt(coef(r_ff$fm)["decentralized"]), "\n"))
cat(paste0("RESULT:n_obs_table3_base=", nobs(r_kb$fm), "\n"))
cat(paste0("RESULT:n_obs_table3_full=", nobs(r_kf$fm), "\n"))