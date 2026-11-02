suppressPackageStartupMessages({
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free"
rdata <- file.path(root, "yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
env <- new.env()
load(rdata, envir = env)
s <- as.data.frame(env$s, stringsAsFactors = FALSE)
nm <- names(s)
message("Columns of s (", length(nm), "): ", paste(nm, collapse = ", "))

results <- list()
emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v[1])) cat(sprintf("RESULT:%s=NA\n", name))
  else cat(sprintf("RESULT:%s=%s\n", name, format(v[1], digits = 10)))
}

tochr <- function(x) {
  tryCatch(as.character(x), error = function(e) rep(NA_character_, length(x)))
}

first_col <- function(cands, patterns = NULL, exclude = NULL) {
  for (c in cands) if (c %in% nm) return(c)
  low <- tolower(nm)
  for (c in cands) {
    i <- which(low == tolower(c))
    if (length(i)) return(nm[i[1]])
  }
  if (!is.null(patterns)) {
    ok <- rep(TRUE, length(nm))
    for (p in patterns) ok <- ok & grepl(p, nm, ignore.case = TRUE)
    if (!is.null(exclude)) for (p in exclude) ok <- ok & !grepl(p, nm, ignore.case = TRUE)
    if (any(ok)) return(nm[which(ok)[1]])
  }
  NA_character_
}

getcol <- function(col) if (is.na(col)) rep(NA, nrow(s)) else s[[col]]

to01 <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x))
  ch <- tolower(trimws(tochr(x)))
  out <- rep(NA_real_, length(ch))
  out[ch %in% c("true", "1", "oui", "yes", "t")] <- 1
  out[ch %in% c("false", "0", "non", "no")] <- 0
  num <- suppressWarnings(as.numeric(ch))
  idx <- is.na(out) & !is.na(num)
  out[idx] <- num[idx]
  out
}

# Yes / No / PNR helpers
is_yes <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x > 0))
  ch <- tolower(trimws(tochr(x)))
  out <- as.numeric(grepl("^(oui|yes)", ch))
  out[is.na(ch) | ch == ""] <- NA
  out
}
is_not_no <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x >= 0))
  ch <- tolower(trimws(tochr(x)))
  out <- 1 - as.numeric(grepl("^(non|no)($|[^a-z])", ch))
  out[is.na(ch) | ch == ""] <- NA
  out
}
is_loser <- function(x) {
  if (is.numeric(x)) return(as.numeric(x < 0))
  ch <- tolower(trimws(tochr(x)))
  out <- as.numeric(grepl("perd|los", ch))
  out[is.na(ch) | ch == ""] <- NA
  out
}
is_winner <- function(x) {
  if (is.numeric(x)) return(as.numeric(x > 0))
  ch <- tolower(trimws(tochr(x)))
  out <- as.numeric(grepl("gagn|win", ch) & !grepl("^non|^not|unaff", ch))
  out[is.na(ch) | ch == ""] <- NA
  out
}

# ---------------- Core variables ----------------
c_weight <- first_col(c("weight", "poids", "weights"))
c_gain_sim <- first_col(c("simule_gain", "simulated_gain", "gain_simule", "estimated_gain", "objective_gain"),
                        patterns = c("simul", "gain"), exclude = c("cible", "target", "inelast", "fuel", "chauff", "housing", "transport", "repondant"))
c_winner_sim <- first_col(c("simule_gagnant", "simulated_winner", "predicted_winner"),
                          patterns = c("simul", "gagnant|winner"), exclude = c("cible", "target", "interaction", "fuel", "chauff"))
c_fb_cat <- first_col(c("gagnant_feedback_categorie", "winning_feedback_category", "feedback_winning_category"),
                      patterns = c("feedback", "categ"))
c_init_cat <- first_col(c("gagnant_categorie", "winning_category"), patterns = c("^(gagnant|winning)_categ"))
c_appr <- first_col(c("taxe_approbation", "tax_approval", "approval_tax", "initial_tax_approval"),
                    patterns = c("^tax", "approb|approv"), exclude = c("cible", "target", "feedback", "progress", "fuel", "chauff", "info", "modif"))
c_accept <- first_col(c("tax_acceptance", "taxe_acceptation", "initial_tax_acceptance"))
c_yv <- first_col(c("Gilets_jaunes", "gilets_jaunes", "yellow_vests", "Yellow_vests", "gilets_jaunes_soutien"),
                  patterns = c("gilets_jaunes|yellow_vest"), exclude = c("dedans|soutien|compris|oppose|NSP"))
c_variante <- first_col(c("variante_taxe_info", "variant_tax_info", "variante_info"))
c_eff <- first_col(c("taxe_efficace", "tax_effective", "effective", "tax_effectiveness"),
                   patterns = c("efficac|effectiv"), exclude = c("info", "cible", "target"))
c_prog <- first_col(c("progressivite", "progressivity", "taxe_progressive", "progressive"))

message("Detected: weight=", c_weight, " gain_sim=", c_gain_sim, " winner_sim=", c_winner_sim,
        " fb_cat=", c_fb_cat, " init_cat=", c_init_cat, " appr=", c_appr, " accept=", c_accept,
        " yv=", c_yv, " variante=", c_variante, " eff=", c_eff, " prog=", c_prog)

d <- data.frame(row = seq_len(nrow(s)))
d$w <- if (!is.na(c_weight)) as.numeric(s[[c_weight]]) else 1
d$w[is.na(d$w)] <- 0
d$gain <- as.numeric(to01(getcol(c_gain_sim)))
d$gain2 <- d$gain^2
if (!is.na(c_winner_sim)) {
  d$winner <- to01(s[[c_winner_sim]])
  if (all(is.na(d$winner))) d$winner <- as.numeric(d$gain > 0)
} else {
  d$winner <- as.numeric(d$gain > 0)
}
d$winner <- as.numeric(d$winner > 0)

d$nl_fb <- 1 - is_loser(getcol(c_fb_cat))
d$win_fb <- is_winner(getcol(c_fb_cat))
d$G <- 1 - is_loser(getcol(c_init_cat))
d$G_win <- is_winner(getcol(c_init_cat))

if (!is.na(c_accept)) {
  d$accept0 <- to01(s[[c_accept]])
} else {
  d$accept0 <- is_not_no(getcol(c_appr))
}
d$approve0 <- is_yes(getcol(c_appr))

yvx <- getcol(c_yv)
if (is.numeric(yvx)) {
  d$yv <- as.numeric(yvx >= 1)
} else {
  ch <- tolower(tochr(yvx))
  d$yv <- as.numeric(grepl("soutien|dedans|support|is_part|part of|est_dedans|member", ch))
  d$yv[is.na(ch)] <- NA
}

if (!is.na(c_variante)) {
  vv <- tolower(trimws(tochr(s[[c_variante]])))
  if (any(vv == "f", na.rm = TRUE)) {
    d$fb <- as.numeric(vv == "f" & !is.na(d$nl_fb))
  } else d$fb <- as.numeric(!is.na(d$nl_fb))
} else {
  d$fb <- as.numeric(!is.na(d$nl_fb))
}
d$fb[is.na(d$fb)] <- 0

d$eff_yes <- is_yes(getcol(c_eff))
d$prog_yes <- if (!is.na(c_prog)) is_yes(s[[c_prog]]) else NA

# ---------------- Controls ----------------
demo_cands <- list(
  c("sexe", "sex", "gender"),
  c("age", "age_group"),
  c("diplome", "diplome4", "education"),
  c("csp", "socioprofessional"),
  c("taille_agglo", "town_size"),
  c("region"),
  c("statut_emploi", "employment_status"),
  c("taille_menage", "household_size"),
  c("nb_14_et_plus", "nb_adultes")
)
income_cands <- list(c("revenu", "income"), c("rev_tot", "household_income"))

add_controls <- function(d, cand_list, prefix) {
  terms <- c()
  for (k in seq_along(cand_list)) {
    col <- first_col(cand_list[[k]])
    if (is.na(col)) next
    x <- s[[col]]
    vname <- paste0(prefix, k)
    if (is.numeric(x) || is.logical(x)) {
      x <- as.numeric(x)
      if (mean(is.na(x)) > 0.1) next
      x[is.na(x)] <- median(x, na.rm = TRUE)
      if (length(unique(x)) < 2) next
      d[[vname]] <- x
    } else {
      ch <- tochr(x)
      ch[is.na(ch) | ch == ""] <- "missing"
      nl <- length(unique(ch))
      if (nl < 2 || nl > 60) next
      d[[vname]] <- factor(ch)
    }
    terms <- c(terms, vname)
    message("control ", vname, " <- ", col)
  }
  list(d = d, terms = terms)
}
r1 <- add_controls(d, demo_cands, "dem")
d <- r1$d; demo_terms <- r1$terms
r2 <- add_controls(d, income_cands, "inc")
d <- r2$d; inc_terms <- r2$terms
if (length(inc_terms)) {
  for (t in inc_terms) if (is.numeric(d[[t]])) {
    d[[paste0(t, "_sq")]] <- d[[t]]^2
    inc_terms <- c(inc_terms, paste0(t, "_sq"))
  }
}
motive_terms <- c()
if (!all(is.na(d$eff_yes))) {
  d$mot_eff <- ifelse(is.na(d$eff_yes), 0, d$eff_yes)
  motive_terms <- c(motive_terms, "mot_eff")
}
if (!all(is.na(d$prog_yes))) {
  d$mot_prog <- ifelse(is.na(d$prog_yes), 0, d$prog_yes)
  motive_terms <- c(motive_terms, "mot_prog")
}

base_ctrl <- c(inc_terms, demo_terms)

run_ols <- function(y, xs, data) {
  data <- data[!is.na(data[[y]]), , drop = FALSE]
  f <- as.formula(paste(y, "~", paste(xs, collapse = " + ")))
  feols(f, data = data, weights = ~w, vcov = "hetero", warn = FALSE, notes = FALSE)
}
getc <- function(m, v) {
  cf <- tryCatch(coef(m), error = function(e) NULL)
  if (is.null(cf) || !(v %in% names(cf))) return(NA)
  cf[[v]]
}

# ---------------- Table 4 ----------------
fbdat <- d[d$fb == 1 & !is.na(d$gain) & !is.na(d$winner) & d$w > 0, ]
rddat <- fbdat[abs(fbdat$gain) < 50, ]
message("Feedback sample: ", nrow(fbdat), "; RD sample (|gain|<50): ", nrow(rddat))

x_main <- c("winner", "accept0", "gain", "gain2", base_ctrl, setdiff(motive_terms, character(0)))

m1 <- tryCatch(run_ols("nl_fb", x_main, rddat), error = function(e) { message("m1: ", e$message); NULL })
m2 <- tryCatch(run_ols("nl_fb", x_main, fbdat), error = function(e) { message("m2: ", e$message); NULL })
m4 <- tryCatch(run_ols("win_fb", x_main, rddat), error = function(e) { message("m4: ", e$message); NULL })

rddat3 <- rddat
rddat3$G0 <- ifelse(is.na(rddat3$G), 0, rddat3$G)
rddat3$Gw0 <- ifelse(is.na(rddat3$G_win), 0, rddat3$G_win)
rddat3$yv0 <- ifelse(is.na(rddat3$yv), 0, rddat3$yv)
rddat3$winner_x_accept <- rddat3$winner * rddat3$accept0
rddat3$winner_x_yv <- rddat3$winner * rddat3$yv0
rddat3$winner_x_G <- rddat3$winner * rddat3$G0
x_het <- c("winner", "winner_x_accept", "winner_x_yv", "winner_x_G", "accept0", "yv0", "G0",
           "gain", "gain2", "Gw0", base_ctrl, motive_terms)
m3 <- tryCatch(run_ols("nl_fb", x_het, rddat3), error = function(e) { message("m3: ", e$message); NULL })

if (!is.null(m1)) print(summary(m1)$coeftable[1:4, ])
if (!is.null(m3)) print(summary(m3)$coeftable[1:8, ])

# ---------------- Table 6: self-interest IV ----------------
t6 <- tryCatch({
  c_tc_appr <- first_col(c("taxe_cible_approbation", "targeted_tax_approval", "tax_targeted_approval", "approval_targeted"),
                         patterns = c("cible|target", "approb|approv"), exclude = c("feedback", "progress", "info"))
  c_tc_cat <- first_col(c("gagnant_cible_categorie", "winning_targeted_category", "targeted_winning_category"),
                        patterns = c("cible|target", "categ"))
  c_elig <- first_col(c("traite_cible", "eligible", "targeted_eligible", "treated_targeted", "eligibility"),
                      patterns = c("traite_cible|eligib"), exclude = c("conjoint|spouse|second"))
  c_elig_c <- first_col(c("traite_cible_conjoint", "eligible_conjoint", "eligible_spouse", "traite_conjoint"),
                        patterns = c("traite|eligib", "conjoint|spouse|second"))
  c_cible <- first_col(c("cible", "percentile_cible", "threshold_targeted", "targeted_percentile", "targeted_threshold"))
  c_rev <- first_col(c("revenu", "income"))
  c_rev_c <- first_col(c("revenu_conjoint", "income_conjoint", "income_spouse", "spouse_income"))
  c_single <- first_col(c("single", "celibataire"))
  message("T6: appr=", c_tc_appr, " cat=", c_tc_cat, " elig=", c_elig, " elig_c=", c_elig_c,
          " cible=", c_cible, " rev=", c_rev, " rev_c=", c_rev_c, " single=", c_single)

  e <- d
  e$acc_t <- is_not_no(getcol(c_tc_appr))
  e$nl_t <- 1 - is_loser(getcol(c_tc_cat))
  rev <- as.numeric(to01(getcol(c_rev)))
  revc <- as.numeric(to01(getcol(c_rev_c)))
  cib <- getcol(c_cible)
  cibn <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", tochr(cib))))
  thr <- rep(NA_real_, length(cibn))
  thr[cibn %in% c(20, 30, 40, 50)] <- c(`20` = 780, `30` = 1140, `40` = 1430, `50` = 1670)[as.character(cibn[cibn %in% c(20, 30, 40, 50)])]
  thr[is.na(thr) & cibn > 100] <- cibn[is.na(thr) & cibn > 100]
  if (!is.na(c_single)) e$single <- to01(s[[c_single]]) else e$single <- NA
  if (all(is.na(e$single))) {
    c_nad <- first_col(c("nb_adultes", "n_adults"))
    e$single <- if (!is.na(c_nad)) as.numeric(to01(s[[c_nad]]) == 1) else as.numeric(is.na(revc))
  }
  e$single[is.na(e$single)] <- 0
  if (!is.na(c_elig)) e$elig <- to01(s[[c_elig]]) else e$elig <- as.numeric(rev < thr)
  if (!is.na(c_elig_c)) e$elig_c <- to01(s[[c_elig_c]]) else e$elig_c <- as.numeric(revc < thr)
  e$elig <- as.numeric(e$elig > 0)
  e$elig_c <- as.numeric(e$elig_c > 0)
  e$elig_c[is.na(e$elig_c)] <- 0
  e$elig_x <- e$elig * e$elig_c
  e$cible_fe <- factor(ifelse(is.na(tochr(cib)), "missing", tochr(cib)))
  e$rev1 <- ifelse(is.na(rev), 0, rev); e$rev2 <- e$rev1^2
  e$revc1 <- ifelse(is.na(revc), 0, revc); e$revc2 <- e$revc1^2
  e <- e[!is.na(e$acc_t) & !is.na(e$nl_t) & !is.na(e$elig) & !is.na(e$accept0) & e$w > 0, ]
  message("T6 N=", nrow(e))
  exo <- c("single", "accept0", "rev1", "rev2", "revc1", "revc2")
  if (length(unique(e$cible_fe)) > 1) exo <- c("cible_fe", exo)
  f6 <- as.formula(paste("acc_t ~", paste(exo, collapse = " + "), "| nl_t ~ elig + elig_c + elig_x"))
  m6 <- feols(f6, data = e, weights = ~w, vcov = "hetero", warn = FALSE, notes = FALSE)
  print(summary(m6, stage = 1))
  getc(m6, "fit_nl_t")
}, error = function(err) { message("T6 error: ", err$message); NA })

# ---------------- Table 8: effectiveness IV ----------------
t8 <- tryCatch({
  c_info_eff <- first_col(c("apres_modifs", "info_efficacite", "info_effectiveness", "info_effective", "scientists_info", "info_scientists"),
                          patterns = c("info", "effic|effect|scien"))
  c_info_cc <- first_col(c("info_CC", "info_climate", "climate_info", "info_cc"))
  message("T8: info_eff=", c_info_eff, " info_cc=", c_info_cc)
  e <- d
  e$z_eff <- to01(getcol(c_info_eff))
  e$z_cc <- to01(getcol(c_info_cc))
  e$z_eff <- as.numeric(e$z_eff > 0)
  e$z_cc <- as.numeric(e$z_cc > 0)
  e$eff <- e$eff_yes
  e$G0 <- ifelse(is.na(e$G), 0, e$G)
  e$gain0 <- ifelse(is.na(e$gain), 0, e$gain)
  e <- e[!is.na(e$approve0) & !is.na(e$eff) & !is.na(e$z_eff) & !is.na(e$z_cc) & e$w > 0, ]
  message("T8 N=", nrow(e))
  mot8 <- c("G0", if ("mot_prog" %in% names(e)) "mot_prog")
  exo <- c(base_ctrl, mot8, "gain0")
  f8 <- as.formula(paste("approve0 ~", paste(exo, collapse = " + "), "| eff ~ z_eff + z_cc"))
  m8 <- feols(f8, data = e, weights = ~w, vcov = "hetero", warn = FALSE, notes = FALSE)
  print(summary(m8, stage = 1))
  getc(m8, "fit_eff")
}, error = function(err) { message("T8 error: ", err$message); NA })

# ---------------- Output ----------------
emit("predicted_winner_believes_not_lose_table4_col1", if (!is.null(m1)) getc(m1, "winner") else NA)
emit("initial_acceptance_believes_not_lose_table4_col1", if (!is.null(m1)) getc(m1, "accept0") else NA)
emit("predicted_winner_believes_not_lose_full_sample_table4_col2", if (!is.null(m2)) getc(m2, "winner") else NA)
emit("predicted_winner_heterogeneity_table4_col3", if (!is.null(m3)) getc(m3, "winner") else NA)
emit("initial_acceptance_heterogeneity_table4_col3", if (!is.null(m3)) getc(m3, "accept0") else NA)
emit("yellow_vests_supporter_heterogeneity_table4_col3", if (!is.null(m3)) getc(m3, "yv0") else NA)
emit("winner_x_initial_acceptance_table4_col3", if (!is.null(m3)) getc(m3, "winner_x_accept") else NA)
emit("winner_x_yellow_vests_supporter_table4_col3", if (!is.null(m3)) getc(m3, "winner_x_yv") else NA)
emit("winner_x_initial_win_belief_table4_col3", if (!is.null(m3)) getc(m3, "winner_x_G") else NA)
emit("predicted_winner_believes_wins_table4_col4", if (!is.null(m4)) getc(m4, "winner") else NA)
emit("n_obs_table4_col1", if (!is.null(m1)) nobs(m1) else NA)
emit("believes_not_lose_on_acceptance_iv_table6_col1", t6)
emit("believes_effective_on_approval_iv_table8_col1", t8)