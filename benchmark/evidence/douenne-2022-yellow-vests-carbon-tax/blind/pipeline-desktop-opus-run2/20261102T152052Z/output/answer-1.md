suppressPackageStartupMessages({
  library(AER)
})
set.seed(42)

path <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
env <- new.env()
load(path, envir = env)
s <- as.data.frame(env$s)
nm <- names(s)
message("N rows: ", nrow(s))

pick <- function(cands, rx = NULL, exclude = NULL) {
  for (c in cands) if (c %in% nm) return(c)
  if (!is.null(rx)) {
    h <- grep(rx, nm, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) h <- h[!grepl(exclude, h, ignore.case = TRUE)]
    if (length(h)) return(h[1])
  }
  NA_character_
}
lc <- function(x) tolower(trimws(as.character(x)))
miss <- function(x) { v <- lc(x); is.na(x) | v == "" | v == "na" }
is_yes <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x > 0))
  v <- lc(x); r <- as.numeric(grepl("^(oui|yes|true|1$)", v)); r[miss(x)] <- NA; r
}
is_no <- function(x) {
  if (is.logical(x)) return(as.numeric(!x))
  if (is.numeric(x)) {
    u <- unique(x[!is.na(x)])
    if (all(u %in% c(0, 1))) return(as.numeric(x == 0))
    return(as.numeric(x < 0))
  }
  v <- lc(x); r <- as.numeric(v %in% c("non", "no", "false", "0")); r[miss(x)] <- NA; r
}
not_lose <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x >= 0))
  v <- lc(x); r <- as.numeric(!grepl("perd|los", v)); r[miss(x)] <- NA; r
}
wins_f <- function(x) {
  if (is.numeric(x)) return(as.numeric(x > 0))
  v <- lc(x); r <- as.numeric(grepl("gagn|win", v) & !grepl("non|not|un", v)); r[miss(x)] <- NA; r
}
to01 <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x > 0))
  v <- lc(x); r <- as.numeric(v %in% c("true", "1", "oui", "yes", "t")); r[miss(x)] <- NA; r
}
show <- function(lab, v) { if (!is.na(v)) { message(lab, " -> ", v); print(utils::head(table(s[[v]], useNA = "ifany"), 12)) } else message(lab, " -> NOT FOUND") }

# ---------------- core variables ----------------
v_w    <- pick(c("weight", "poids", "weights"))
w <- if (!is.na(v_w)) as.numeric(s[[v_w]]) else rep(1, nrow(s))
w[is.na(w)] <- 0

v_fb   <- pick(c("winning_feedback_category", "gagnant_feedback_categorie"), "feedback.*categ")
v_init <- pick(c("winning_category", "gagnant_categorie"))
v_eg   <- pick(c("simule_gain", "simulated_gain", "gain_simule", "estimated_gain", "objective_gain"), "simul.*gain", exclude = "^Simule|2$|interaction|repondant|cible")
v_win  <- pick(c("simule_gagnant", "simulated_winner", "predicted_winner"), "simul.*gagn")
v_acc  <- pick(c("tax_acceptance", "taxe_acceptation"))
v_appr <- pick(c("taxe_approbation", "tax_approval", "initial_approval"))
v_yv   <- pick(c("gilets_jaunes", "yellow_vests"))
v_eff  <- pick(c("taxe_efficace", "tax_effective", "effective"))
v_prog <- pick(c("progressivite", "progressif", "taxe_progressive", "progressivity"))
v_vti  <- pick(c("variante_taxe_info"))
for (p in list(c("fb", v_fb), c("init", v_init), c("win", v_win), c("acc", v_acc), c("appr", v_appr), c("yv", v_yv), c("eff", v_eff), c("prog", v_prog), c("vti", v_vti))) show(p[1], p[2])
message("eg -> ", v_eg)

eg <- if (!is.na(v_eg)) as.numeric(s[[v_eg]]) else rep(NA_real_, nrow(s))
winner <- if (!is.na(v_win)) to01(s[[v_win]]) else as.numeric(eg > 0)
if (all(is.na(winner))) winner <- as.numeric(eg > 0)

accept <- if (!is.na(v_acc) && (is.logical(s[[v_acc]]) || is.numeric(s[[v_acc]]))) as.numeric(s[[v_acc]]) else if (!is.na(v_appr)) 1 - is_no(s[[v_appr]]) else NA
approve <- if (!is.na(v_appr)) is_yes(s[[v_appr]]) else NA

yv_sup <- rep(NA_real_, nrow(s))
if (all(c("gilets_jaunes_soutien", "gilets_jaunes_dedans") %in% nm)) {
  yv_sup <- as.numeric(to01(s$gilets_jaunes_soutien) == 1 | to01(s$gilets_jaunes_dedans) == 1)
} else if (!is.na(v_yv)) {
  x <- s[[v_yv]]
  if (is.numeric(x)) yv_sup <- as.numeric(x >= 1) else {
    v <- lc(x); yv_sup <- as.numeric(grepl("soutien|dedans|support|part|member", v)); yv_sup[miss(x)] <- NA
  }
}
G <- if (!is.na(v_init)) not_lose(s[[v_init]]) else NA
y_nl <- if (!is.na(v_fb)) not_lose(s[[v_fb]]) else NA
y_w  <- if (!is.na(v_fb)) wins_f(s[[v_fb]]) else NA
eff_yes <- if (!is.na(v_eff)) is_yes(s[[v_eff]]) else rep(NA_real_, nrow(s))
prog_yes <- if (!is.na(v_prog)) is_yes(s[[v_prog]]) else rep(NA_real_, nrow(s))

fb <- !is.na(y_nl)
if (!is.na(v_vti)) {
  alt <- lc(s[[v_vti]]) %in% c("f")
  if ((sum(fb) < 1800 || sum(fb) > 2150) && sum(alt) > 1800 && sum(alt) < 2150) fb <- alt & !is.na(y_nl)
}
message("feedback sample: ", sum(fb))

# ---------------- controls ----------------
inc_c <- intersect(c("Revenu", "Revenu2", "Revenu_conjoint", "Revenu_conjoint2"), nm)
D <- data.frame(w = w, eg = eg / 1000, eg2 = (eg / 1000)^2, winner = winner, accept = accept,
                approve = approve, yv = yv_sup, G = G, y_nl = y_nl, y_w = y_w,
                eff = eff_yes, prog = prog_yes)
if (length(inc_c) == 0) {
  vr <- pick(c("revenu", "rev_tot"))
  if (!is.na(vr)) { D$Revenu <- as.numeric(s[[vr]]) / 1000; D$Revenu2 <- D$Revenu^2; inc_c <- c("Revenu", "Revenu2") }
} else for (v in inc_c) D[[v]] <- as.numeric(s[[v]])
demo_c <- intersect(c("sexe", "age", "diplome4", "taille_agglo", "csp", "region", "statut_emploi", "taille_menage", "single"), nm)
if (!("diplome4" %in% demo_c) && "diplome" %in% nm) demo_c <- c(demo_c, "diplome")
for (v in demo_c) {
  x <- s[[v]]
  if (is.logical(x)) x <- as.numeric(x)
  if (is.character(x) || is.factor(x)) {
    x <- as.character(x)
    if (length(unique(x)) > 40) next
    x <- factor(x)
  }
  D[[paste0("c_", v)]] <- x
}
demo_cc <- intersect(paste0("c_", demo_c), names(D))

usable <- function(d, vars) {
  keep <- c()
  for (v in vars) {
    x <- d[[v]]
    if (mean(is.na(x)) > 0.05) next
    if (length(unique(x[!is.na(x)])) < 2) next
    keep <- c(keep, v)
  }
  keep
}
motives <- c("eff", "prog")

fit_lm <- function(y, rhs_main, ctrl, sub) {
  d <- D[sub, , drop = FALSE]
  d <- d[d$w > 0, , drop = FALSE]
  ctrl <- usable(d, ctrl)
  f <- as.formula(paste(y, "~", paste(c(rhs_main, ctrl), collapse = " + ")))
  m <- lm(f, data = d, weights = w)
  message("lm ", y, ": n=", nobs(m), " controls: ", paste(ctrl, collapse = ","))
  m
}
safe <- function(expr) tryCatch(expr, error = function(e) { message("ERROR: ", conditionMessage(e)); NULL })
gc_ <- function(m, nmv) if (is.null(m)) NA else unname(coef(m)[nmv])

ctrl4 <- c("eg", "eg2", inc_c, demo_cc, motives)
D$w_acc <- D$winner * D$accept
D$w_yv  <- D$winner * D$yv
D$w_G   <- D$winner * D$G
near <- fb & !is.na(eg) & abs(eg) < 50

m1 <- safe(fit_lm("y_nl", c("winner", "accept"), ctrl4, near))
m2 <- safe(fit_lm("y_nl", c("winner", "accept"), ctrl4, fb))
m3 <- safe(fit_lm("y_nl", c("winner", "accept", "yv", "G", "w_acc", "w_yv", "w_G"), ctrl4, near))
m4 <- safe(fit_lm("y_w", c("winner", "accept"), ctrl4, near))

# ---------------- Table 6: IV self-interest, targeted dividend ----------------
r6 <- NA
r6 <- tryCatch({
  v_ta  <- pick(c("taxe_cible_approbation", "targeted_tax_approval", "tax_target_approval"), "cible.*approb|target.*approv")
  v_gc  <- pick(c("gagnant_cible_categorie", "winning_target_category", "winning_targeted_category"), "cible.*categ|target.*categ")
  v_tc  <- pick(c("traite_cible", "eligible", "treated_target"))
  v_tcc <- pick(c("traite_cible_conjoint", "eligible_conjoint", "treated_target_spouse"))
  v_cib <- pick(c("cible", "target_threshold"))
  show("ta", v_ta); show("gc", v_gc); show("tc", v_tc); show("tcc", v_tcc); show("cible", v_cib)
  D$y6 <- 1 - is_no(s[[v_ta]])
  D$x6 <- not_lose(s[[v_gc]])
  D$tc <- to01(s[[v_tc]]); D$tcc <- to01(s[[v_tcc]]); D$tci <- D$tc * D$tcc
  D$c_cible <- factor(as.character(s[[v_cib]]))
  d <- D[D$w > 0 & !is.na(D$y6) & !is.na(D$x6), ]
  ctrl <- usable(d, unique(c("c_cible", "c_single", "accept", inc_c, demo_cc)))
  if (!"c_single" %in% names(d) && "single" %in% nm) NULL
  cs <- paste(ctrl, collapse = " + ")
  f <- as.formula(paste("y6 ~ x6 +", cs, "| tc + tcc + tci +", cs))
  m6 <- ivreg(f, data = d, weights = w)
  message("T6 n=", nobs(m6))
  unname(coef(m6)["x6"])
}, error = function(e) { message("T6 ERROR: ", conditionMessage(e)); NA })

# ---------------- Table 8: IV effectiveness ----------------
r8 <- tryCatch({
  v_am <- pick(c("apres_modifs", "info_scientists", "scientists_agree"), "apres_modif|scien")
  v_cc <- pick(c("info_CC", "info_cc", "info_climate"))
  show("apres_modifs", v_am); show("info_CC", v_cc)
  D$z1 <- to01(s[[v_am]]); D$z2 <- to01(s[[v_cc]])
  d <- D[D$w > 0 & !is.na(D$approve) & !is.na(D$eff), ]
  ctrl <- usable(d, unique(c("eg", "eg2", inc_c, demo_cc, "prog", "G")))
  cs <- paste(ctrl, collapse = " + ")
  f <- as.formula(paste("approve ~ eff +", cs, "| z1 + z2 +", cs))
  m8 <- ivreg(f, data = d, weights = w)
  message("T8 n=", nobs(m8))
  unname(coef(m8)["eff"])
}, error = function(e) { message("T8 ERROR: ", conditionMessage(e)); NA })

fmt <- function(x) if (is.null(x) || length(x) == 0 || is.na(x)) "NA" else sprintf("%.6f", x)
cat("RESULT:predicted_winner_believes_not_lose_table4_col1=", fmt(gc_(m1, "winner")), "\n", sep = "")
cat("RESULT:initial_acceptance_believes_not_lose_table4_col1=", fmt(gc_(m1, "accept")), "\n", sep = "")
cat("RESULT:predicted_winner_believes_not_lose_full_sample_table4_col2=", fmt(gc_(m2, "winner")), "\n", sep = "")
cat("RESULT:predicted_winner_heterogeneity_table4_col3=", fmt(gc_(m3, "winner")), "\n", sep = "")
cat("RESULT:initial_acceptance_heterogeneity_table4_col3=", fmt(gc_(m3, "accept")), "\n", sep = "")
cat("RESULT:yellow_vests_supporter_heterogeneity_table4_col3=", fmt(gc_(m3, "yv")), "\n", sep = "")
cat("RESULT:winner_x_initial_acceptance_table4_col3=", fmt(gc_(m3, "w_acc")), "\n", sep = "")
cat("RESULT:winner_x_yellow_vests_supporter_table4_col3=", fmt(gc_(m3, "w_yv")), "\n", sep = "")
cat("RESULT:winner_x_initial_win_belief_table4_col3=", fmt(gc_(m3, "w_G")), "\n", sep = "")
cat("RESULT:predicted_winner_believes_wins_table4_col4=", fmt(gc_(m4, "winner")), "\n", sep = "")
cat("RESULT:n_obs_table4_col1=", if (is.null(m1)) sum(near) else nobs(m1), "\n", sep = "")
cat("RESULT:believes_not_lose_on_acceptance_iv_table6_col1=", fmt(r6), "\n", sep = "")
cat("RESULT:believes_effective_on_approval_iv_table8_col1=", fmt(r8), "\n", sep = "")
