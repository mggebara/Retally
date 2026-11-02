suppressPackageStartupMessages({
  library(stats)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code"
prep_file <- file.path(base_dir, "after_preparation.RData")
pap_file <- file.path(base_dir, "after_papier.RData")

env_prep <- new.env()
env_pap <- new.env()
ok_prep <- tryCatch({ load(prep_file, envir = env_prep); TRUE }, error = function(e) { message("prep load failed: ", conditionMessage(e)); FALSE })
ok_pap <- tryCatch({ load(pap_file, envir = env_pap); TRUE }, error = function(e) { message("papier load failed: ", conditionMessage(e)); FALSE })

if (ok_prep && exists("s", envir = env_prep, inherits = FALSE)) {
  s_raw <- get("s", envir = env_prep)
} else {
  s_raw <- get("s", envir = env_pap)
}

# --- Low-level cleaning that never triggers S4 class lookup (memisc is not installed) ---
strip_plain <- function(x) {
  y <- x
  attributes(y) <- NULL
  if (isS4(y)) y <- asS4(y, FALSE, FALSE)
  y
}

clean_col <- function(x) {
  tryCatch({
    cl <- oldClass(x)
    lv <- attr(x, "levels", exact = TRUE)
    vl <- attr(x, "value.labels", exact = TRUE)
    if (!is.null(cl) && ("factor" %in% cl) && !is.null(lv)) {
      codes <- strip_plain(x)
      levs <- strip_plain(lv)
      return(factor(levs[codes], levels = unique(levs)))
    }
    y <- strip_plain(x)
    if (!is.null(vl) && (is.numeric(y))) {
      vals <- strip_plain(attr(vl, "values", exact = TRUE))
      labs <- strip_plain(vl)
      if (length(vals) == length(labs) && length(vals) > 0) {
        nn <- y[!is.na(y)]
        if (length(nn) > 0 && all(nn %in% vals)) {
          y <- labs[match(y, vals)]
        }
      }
    }
    if (!(typeof(y) %in% c("logical", "integer", "double", "character", "complex"))) return(NULL)
    y
  }, error = function(e) NULL)
}

lst <- if (isS4(s_raw)) strip_plain(s_raw) else unclass(s_raw)
nms <- attr(s_raw, "names", exact = TRUE)
if (is.null(nms)) nms <- attr(lst, "names", exact = TRUE)
newl <- list()
nr <- NA_integer_
for (i in seq_along(lst)) {
  cc <- clean_col(lst[[i]])
  if (is.null(cc)) next
  if (is.na(nr)) nr <- length(cc)
  if (length(cc) != nr) next
  newl[[nms[i]]] <- cc
}
s <- as.data.frame(newl, stringsAsFactors = FALSE, check.names = FALSE)
rm(s_raw, lst, newl)

getobj <- function(name) {
  o <- NULL
  if (ok_prep && exists(name, envir = env_prep, inherits = FALSE)) o <- get(name, envir = env_prep)
  else if (ok_pap && exists(name, envir = env_pap, inherits = FALSE)) o <- get(name, envir = env_pap)
  if (is.null(o)) return(NULL)
  o <- tryCatch(as.character(strip_plain(o)), error = function(e) NULL)
  o
}

piece.formula <- function(var.names, knots, vector=F) {
  formula.sign <- rep(" - ", length(knots))
  formula.sign[knots < 0] <- " + "
  formulas <- c()
  for (v in var.names) formulas <- c(formulas, paste(v, "+", paste("I(pmin(", v, formula.sign, abs(knots), ", 0))", collapse = " + ", sep="")))
  formula <- paste(formulas, collapse = ' + ')
  if (vector) return(strsplit(formula, ' + ', fixed=T)[[1]])
  else return(formula)
}

excl <- c("revenu", "rev_tot", "age", "age_65_plus")
variables_demo <- getobj("variables_demo")
pieces <- piece.formula(c("percentile_revenu", "percentile_revenu_conjoint"), c(20,70), vector=T)
if (!is.null(variables_demo)) {
  variables_reg_self_interest <- c("prog_na", "Simule_gain", "Simule_gain2", "taxe_efficace", "single", "hausse_depenses_par_uc", variables_demo, pieces)
  variables_reg_self_interest <- variables_reg_self_interest[!(variables_reg_self_interest %in% excl)]
  demo_f <- variables_demo[!(variables_demo %in% excl)]
} else {
  vref <- getobj("variables_reg_effect_feedback")
  if (is.null(vref)) vref <- getobj("variables_reg_self_interest")
  variables_reg_self_interest <- vref
  demo_f <- vref[-(1:6)]
  demo_f <- demo_f[!(demo_f %in% pieces)]
}
variables_reg_effect_feedback <- variables_reg_self_interest
variables_reg_ee <- c("Revenu", "Revenu2", "Revenu_conjoint", "Revenu_conjoint2", "single", "Simule_gain", "Simule_gain2", "gagnant_categorie", demo_f)
variables_reg_ee <- variables_reg_ee[!(variables_reg_ee %in% excl)]

ctrl_fb <- paste(variables_reg_effect_feedback, collapse = ' + ')

getc <- function(m, must, mustnot = character(0)) {
  cf <- coef(m)
  nm <- names(cf)
  ok <- rep(TRUE, length(nm))
  for (p in must) ok <- ok & grepl(p, nm)
  for (p in mustnot) ok <- ok & !grepl(p, nm)
  cand <- nm[ok & !is.na(cf)]
  if (length(cand) == 0) return(NA_real_)
  unname(cf[cand[1]])
}

res <- list()

# ---------------- Table 4: effect of feedback on beliefs ----------------
gj_num <- suppressWarnings(as.numeric(s$gilets_jaunes))
if (!is.null(s$gilets_jaunes_soutien) && is.logical(s$gilets_jaunes_soutien)) {
  s$gj <- (s$gilets_jaunes_soutien %in% TRUE)
  s$gj[is.na(s$gilets_jaunes_soutien) & is.na(s$gilets_jaunes)] <- NA
} else if (is.numeric(s$gilets_jaunes) || (sum(!is.na(gj_num)) > 0.9 * sum(!is.na(s$gilets_jaunes)))) {
  s$gj <- gj_num == 1
} else {
  gjl <- tolower(as.character(s$gilets_jaunes))
  s$gj <- grepl("soutien|support", gjl)
  s$gj[is.na(gjl)] <- NA
}
cat('DEVIATION: Yellow Vests supporter dummy defined as "supports" only (excluding "is part of"); exact definition not given in the provided text\n')
cat(sprintf("DEBUG: gj share TRUE = %.3f\n", mean(s$gj, na.rm = TRUE)))

f1 <- as.formula(paste("gagnant_feedback_categorie!='Perdant' ~ simule_gagnant + tax_acceptance + (taxe_approbation=='NSP') + ", ctrl_fb))
reg1 <- tryCatch(lm(f1, data=s, subset=variante_taxe_info=='f' & abs(simule_gain) < 50, weights = weight, na.action='na.exclude'),
                 error = function(e) { message("reg1: ", conditionMessage(e)); NULL })
if (!is.null(reg1)) {
  res$predicted_winner_believes_not_lose_table4_col1 <- getc(reg1, "^simule_gagnant", ":")
  res$initial_acceptance_believes_not_lose_table4_col1 <- getc(reg1, "^tax_acceptance", ":")
  res$n_obs_table4_col1 <- nrow(model.frame(reg1))
}

reg2 <- tryCatch(lm(f1, data=s, subset=variante_taxe_info=='f', weights = weight, na.action='na.exclude'),
                 error = function(e) { message("reg2: ", conditionMessage(e)); NULL })
if (!is.null(reg2)) {
  res$predicted_winner_believes_not_lose_full_sample_table4_col2 <- getc(reg2, "^simule_gagnant", ":")
}

f3 <- as.formula(paste("gagnant_feedback_categorie!='Perdant' ~ (gagnant_categorie!='Perdant') * simule_gagnant + simule_gagnant * gj + simule_gagnant * tax_acceptance + (taxe_approbation=='NSP') + ", ctrl_fb))
reg3 <- tryCatch(lm(f3, data=s, subset=variante_taxe_info=='f' & abs(simule_gain) < 50, weights = weight, na.action='na.exclude'),
                 error = function(e) { message("reg3: ", conditionMessage(e)); NULL })
if (!is.null(reg3)) {
  res$predicted_winner_heterogeneity_table4_col3 <- getc(reg3, "^simule_gagnant", ":")
  res$initial_acceptance_heterogeneity_table4_col3 <- getc(reg3, "^tax_acceptance", ":")
  res$yellow_vests_supporter_heterogeneity_table4_col3 <- getc(reg3, "^gj", ":")
  res$winner_x_initial_acceptance_table4_col3 <- getc(reg3, c("simule_gagnant", "tax_acceptance", ":"))
  res$winner_x_yellow_vests_supporter_table4_col3 <- getc(reg3, c("simule_gagnant", "gj", ":"))
  res$winner_x_initial_win_belief_table4_col3 <- getc(reg3, c("simule_gagnant", "gagnant_categorie", ":"))
}

f4 <- as.formula(paste("gagnant_feedback_categorie=='Gagnant' ~ simule_gagnant + tax_acceptance + (taxe_approbation=='NSP') + ", ctrl_fb))
reg4 <- tryCatch(lm(f4, data=s, subset=variante_taxe_info=='f' & abs(simule_gain) < 50, weights = weight, na.action='na.exclude'),
                 error = function(e) { message("reg4: ", conditionMessage(e)); NULL })
if (!is.null(reg4)) {
  res$predicted_winner_believes_wins_table4_col4 <- getc(reg4, "^simule_gagnant", ":")
}

# ---------------- Table 6 col 1: self-interest, targeted dividend, 2SLS ----------------
ctrl_si <- paste(variables_reg_self_interest, collapse = ' + ')
cond_si <- with(s, (percentile_revenu <= 60 & percentile_revenu >= 10) | (percentile_revenu_conjoint <= 60 & percentile_revenu_conjoint >= 10))
cond_si[is.na(cond_si)] <- FALSE
s$sub_si <- cond_si

si_val <- tryCatch({
  fs1 <- as.formula(paste("gagnant_cible_categorie!='Perdant' ~ traite_cible*traite_cible_conjoint + cible + I(taxe_approbation=='NSP') + tax_acceptance + ", ctrl_si))
  tsls1_si1 <- lm(fs1, data=s, subset = sub_si, weights = weight)
  s$non_perdant <- NA_real_
  idx <- which(s$sub_si)
  s$non_perdant[idx] <- as.numeric(predict(tsls1_si1, newdata = s[idx, ]))
  fs2 <- as.formula(paste("taxe_cible_approbation!='Non' ~ ", ctrl_si, "+ cible + I(taxe_approbation=='NSP') + tax_acceptance + non_perdant"))
  tsls2_si1 <- lm(fs2, data=s, subset = sub_si, weights = weight)
  unname(coef(tsls2_si1)["non_perdant"])
}, error = function(e) { message("tsls si1: ", conditionMessage(e)); NA_real_ })

if (is.na(si_val)) {
  si_val <- tryCatch({
    suppressPackageStartupMessages(library(AER))
    fiv <- as.formula(paste("taxe_cible_approbation!='Non' ~ ", ctrl_si,
      " + cible + I(taxe_approbation=='NSP') + tax_acceptance + (gagnant_cible_categorie!='Perdant') | . - (gagnant_cible_categorie!='Perdant') + traite_cible*traite_cible_conjoint"))
    iv <- AER::ivreg(fiv, data = s, subset = sub_si, weights = weight)
    getc(iv, "gagnant_cible_categorie")
  }, error = function(e) { message("ivreg si1: ", conditionMessage(e)); NA_real_ })
}
res$believes_not_lose_on_acceptance_iv_table6_col1 <- si_val

# ---------------- Table 8 col 1: effectiveness, 2SLS ----------------
ctrl_ee <- paste(variables_reg_ee, collapse = ' + ')
ee_val <- tryCatch({
  fe1 <- as.formula(paste("taxe_efficace=='Oui' ~", ctrl_ee, " + apres_modifs + info_CC"))
  tsls1_ee1 <- lm(fe1, data=s, weights = weight, na.action='na.exclude')
  fv <- fitted(tsls1_ee1)
  if (length(fv) != nrow(s)) fv <- predict(tsls1_ee1, newdata = s)
  s$taxe_efficace.hat <- as.numeric(fv)
  fe2 <- as.formula(paste("(taxe_approbation=='Oui') ~", ctrl_ee, " + taxe_efficace.hat"))
  tsls2_ee1 <- lm(fe2, data=s, weights = weight)
  unname(coef(tsls2_ee1)["taxe_efficace.hat"])
}, error = function(e) { message("tsls ee1: ", conditionMessage(e)); NA_real_ })
res$believes_effective_on_approval_iv_table8_col1 <- ee_val

# ---------------- Output ----------------
for (nm in names(res)) {
  val <- res[[nm]]
  if (length(val) == 1 && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", nm, as.numeric(val)))
}