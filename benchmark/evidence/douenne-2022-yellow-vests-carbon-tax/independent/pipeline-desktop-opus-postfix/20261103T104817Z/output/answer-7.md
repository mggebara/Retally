suppressPackageStartupMessages({
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free"
rdata <- file.path(base, "yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
env <- new.env()
load(rdata, envir = env)
s <- env$s
n_loaded <- nrow(s)

# ---- clean column classes (strip labelled / memisc S4 classes WITHOUT dispatch) ----
base_cls <- c("factor", "ordered", "Date", "POSIXct", "POSIXt", "difftime")
strip_attrs <- function(x) {
  y <- x
  attributes(y) <- NULL
  if (isS4(y)) y <- tryCatch(asS4(y, FALSE), error = function(e) y)
  y
}
nr <- n_loaded
newcols <- list()
labmaps <- list()
for (v in names(s)) {
  x <- s[[v]]
  cls <- oldClass(x)
  s4 <- isS4(x) || (!is.null(cls) && !is.null(attr(cls, "package")))
  if (!s4 && is.null(cls)) {
    if (is.numeric(x) || is.character(x) || is.logical(x)) { newcols[[v]] <- strip_attrs(x); next }
  }
  if (!s4 && !is.null(cls) && all(cls %in% base_cls)) { newcols[[v]] <- x; next }
  if (!s4 && !is.null(cls) && "haven_labelled" %in% cls) {
    hl <- tryCatch(attr(x, "labels"), error = function(e) NULL)
    if (!is.null(hl) && !is.null(names(hl))) labmaps[[v]] <- list(codes = as.numeric(strip_attrs(hl)), labs = names(hl))
    newcols[[v]] <- tryCatch(strip_attrs(x), error = function(e) x); next
  }
  vl <- tryCatch(attr(x, "value.labels"), error = function(e) NULL)
  y <- tryCatch(strip_attrs(x), error = function(e) NULL)
  if (is.null(y) || length(y) != nr) next
  if (!is.null(vl)) {
    codes <- tryCatch(strip_attrs(attr(vl, "values")), error = function(e) NULL)
    labs <- tryCatch(as.character(strip_attrs(vl)), error = function(e) NULL)
    if (!is.null(codes) && !is.null(labs) && length(codes) == length(labs) && length(codes) > 0) {
      labmaps[[v]] <- list(codes = codes, labs = labs)
      if (is.numeric(y) || is.integer(y)) {
        u <- unique(y[!is.na(y)])
        if (length(u) > 0 && all(u %in% codes)) {
          y <- labs[match(y, codes)]
        }
      }
    }
  }
  newcols[[v]] <- y
}
s <- as.data.frame(newcols, stringsAsFactors = FALSE, optional = TRUE)
names(s) <- names(newcols)

cols <- names(s)
pick <- function(cands, pattern = NULL, exclude = NULL) {
  for (c in cands) if (c %in% cols) return(c)
  if (!is.null(pattern)) {
    m <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) m <- m[!grepl(exclude, m, ignore.case = TRUE)]
    if (length(m) > 0) return(m[1])
  }
  NA_character_
}
lc <- function(x) tolower(trimws(as.character(x)))

# Decode a winner/unaffected/loser category into -1 / 0 / 1 (NA when missing)
str_sign <- function(l) {
  out <- rep(NA_real_, length(l))
  ok <- !is.na(l) & l != "" & l != "na"
  los <- grepl("perdant|perd|los|^-", l)
  win <- grepl("gagn|win", l) & !grepl("non|unaff|not|perd|los", l)
  out[ok] <- 0
  out[ok & win] <- 1
  out[ok & los] <- -1
  out
}
cat_sign <- function(col) {
  x <- s[[col]]
  if (is.factor(x) || is.logical(x)) x <- as.character(x)
  if (is.character(x)) {
    l <- lc(x)
    num <- suppressWarnings(as.numeric(l))
    nn <- sum(!is.na(l) & l != "")
    if (nn > 0 && sum(!is.na(num)) >= 0.9 * nn) {
      x <- num
    } else {
      return(str_sign(l))
    }
  }
  x <- as.numeric(x)
  if (any(x < 0, na.rm = TRUE)) return(sign(x))
  lm_ <- labmaps[[col]]
  if (!is.null(lm_)) {
    labs <- lc(lm_$labs[match(x, lm_$codes)])
    if (sum(!is.na(labs)) > 0) {
      out <- str_sign(labs)
      if (length(unique(out[!is.na(out)])) > 1) return(out)
    }
  }
  u <- sort(unique(x[!is.na(x)]))
  if (length(u) == 3) {
    cat(sprintf("DEVIATION: %s has codes %s without usable labels; mapping lowest->winner, middle->unaffected, highest->loser (factor levels Gagnant < Non affecte < Perdant)\n",
                col, paste(u, collapse = ",")))
    return(c(1, 0, -1)[match(x, u)])
  }
  sign(x)
}
yesno <- function(x, accept = FALSE) {
  if (is.factor(x)) x <- as.character(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) {
    u <- unique(x[!is.na(x)])
    if (all(u %in% c(0, 1))) return(as.numeric(x))
    return(as.numeric(if (accept) x >= 0 else x > 0))
  }
  l <- lc(x)
  out <- as.numeric(grepl("^(oui|yes|true|1)", l))
  if (accept) out <- as.numeric(!grepl("^(non|no$|no |false|0)", l))
  out[is.na(x)] <- NA
  out
}

wcol <- pick(c("weight", "poids"))
s$w_ <- if (!is.na(wcol)) as.numeric(s[[wcol]]) else 1
s$w_[is.na(s$w_)] <- 1

# ---- key variables ----
gain_col <- pick(c("simule_gain", "simulated_gain", "gain_simule", "estimated_gain"), "^simul.*gain$")
cat("INFO: estimated gain column =", gain_col, "\n")
s$g_hat <- as.numeric(s[[gain_col]])
s$g_hat2 <- s$g_hat^2
s$predicted_winner <- as.numeric(s$g_hat > 0)
sw <- pick(c("simule_gagnant", "simulated_winner"))
if (!is.na(sw)) {
  tmp <- yesno(s[[sw]])
  if (sum(!is.na(tmp)) > 0 && length(unique(tmp[!is.na(tmp)])) == 2) s$predicted_winner <- tmp
}

fb_col <- pick(c("winning_feedback_category", "gagnant_feedback_categorie"))
init_col <- pick(c("winning_category", "gagnant_categorie"))
sg_fb <- cat_sign(fb_col)
sg_init <- cat_sign(init_col)
cat("INFO: feedback category raw values:", paste(head(names(table(s[[fb_col]], useNA = "ifany")), 6), collapse = " | "), "\n")
cat("INFO: feedback sign table:", paste(names(table(sg_fb, useNA = "ifany")), table(sg_fb, useNA = "ifany"), sep = "=", collapse = " "), "\n")
cat("INFO: initial sign table:", paste(names(table(sg_init, useNA = "ifany")), table(sg_init, useNA = "ifany"), sep = "=", collapse = " "), "\n")
s$not_lose_post <- as.numeric(sg_fb >= 0)
s$win_post <- as.numeric(sg_fb > 0)
s$G_init <- as.numeric(sg_init >= 0)
s$init_cat <- factor(as.character(s[[init_col]]))

acc_col <- pick(c("tax_acceptance", "taxe_acceptation"))
app_col <- pick(c("tax_approval", "taxe_approbation"))
s$init_accept <- yesno(s[[acc_col]], accept = TRUE)
s$init_approve <- yesno(s[[app_col]])

# Yellow vests supporter
gj_sup <- NULL
d1 <- pick(c("gilets_jaunes_soutien", "yellow_vests_support"))
d2 <- pick(c("gilets_jaunes_dedans", "yellow_vests_part"))
if (!is.na(d1)) {
  a <- yesno(s[[d1]]); a[is.na(a)] <- 0
  b <- if (!is.na(d2)) { bb <- yesno(s[[d2]]); bb[is.na(bb)] <- 0; bb } else 0
  gj_sup <- as.numeric(a + b > 0)
} else {
  gf <- pick(c("Gilets_jaunes", "gilets_jaunes", "yellow_vests"))
  if (!is.na(gf)) {
    x <- s[[gf]]
    if (is.numeric(x)) gj_sup <- as.numeric(x >= 1)
    else gj_sup <- as.numeric(grepl("soutien|support|dedans|part|est_", lc(x)))
  }
}
if (is.null(gj_sup)) { cat("DEVIATION: Yellow Vests supporter variable not found; set to 0\n"); gj_sup <- 0 }
s$yv_supporter <- gj_sup

# ---- controls ----
num_or_fac <- function(v) {
  x <- s[[v]]
  if (is.character(x) || is.logical(x)) x <- factor(x)
  x
}
ctrl_cands <- c("sexe", "age", "diplome", "Diplome", "csp", "statut_emploi", "taille_agglo",
                "region", "nb_adultes", "nb_14_et_plus", "taille_menage", "single",
                "revenu", "revenu_conjoint", "rev_tot", "fume", "diesel", "essence",
                "gauche_droite", "Gauche_droite", "ecologiste", "conservateur")
raw_ctrls <- c()
for (v in ctrl_cands) {
  if (!(v %in% cols)) next
  if (v == "Diplome" && "c_diplome" %in% raw_ctrls) next
  if (v == "Gauche_droite" && "c_gauche_droite" %in% raw_ctrls) next
  if (v == "rev_tot" && "c_revenu" %in% raw_ctrls) next
  x <- num_or_fac(v)
  if (is.factor(x)) {
    x <- droplevels(x)
    if (nlevels(x) < 2 || nlevels(x) > 40) next
  } else if (!is.numeric(x)) next
  if (is.numeric(x)) { x <- as.numeric(x); x[is.na(x)] <- 0 }
  else { x <- addNA(x, ifany = TRUE) }
  nm <- paste0("c_", v)
  s[[nm]] <- x
  raw_ctrls <- c(raw_ctrls, nm)
}
if ("c_revenu" %in% raw_ctrls) { s$c_revenu2 <- s$c_revenu^2; raw_ctrls <- c(raw_ctrls, "c_revenu2") }
if ("c_revenu_conjoint" %in% raw_ctrls) { s$c_revenu_conjoint2 <- s$c_revenu_conjoint^2; raw_ctrls <- c(raw_ctrls, "c_revenu_conjoint2") }

# Expand controls into numeric dummy columns and drop collinear ones (full sample)
mm <- model.matrix(as.formula(paste("~", paste(raw_ctrls, collapse = " + "))), data = s)
mm <- mm[, colnames(mm) != "(Intercept)", drop = FALSE]
cn <- make.unique(paste0("x_", make.names(colnames(mm))), sep = "_")
cn <- gsub("\\.", "_", cn)
colnames(mm) <- make.unique(cn, sep = "_")
keepv <- apply(mm, 2, function(z) var(z) > 0)
mm <- mm[, keepv, drop = FALSE]
q <- qr(cbind(1, mm), tol = 1e-7)
kidx <- sort(q$pivot[seq_len(q$rank)])
kidx <- kidx[kidx > 1] - 1
mm <- mm[, kidx, drop = FALSE]
for (j in colnames(mm)) s[[j]] <- mm[, j]
ctrls <- colnames(mm)

# prune numeric regressors collinear within a given sample
prune <- function(d, vars) {
  vars <- vars[vapply(vars, function(v) { z <- d[[v]]; sum(!is.na(z)) > 1 && var(z, na.rm = TRUE) > 0 }, logical(1))]
  X <- as.matrix(d[, vars, drop = FALSE])
  X[is.na(X)] <- 0
  q <- qr(cbind(1, X), tol = 1e-7)
  k <- sort(q$pivot[seq_len(q$rank)])
  vars[k[k > 1] - 1]
}

# other motives: effectiveness and progressivity beliefs
eff_col <- pick(c("taxe_efficace", "tax_effective", "tax_efficacy"), "efficac|effective", exclude = "feedback|info|cible|progres")
prog_col <- pick(c("progressivite", "tax_progressivity", "progressivity"), "progressiv", exclude = "info|feedback")
cat("INFO: effectiveness column =", eff_col, "; progressivity column =", prog_col, "\n")
if (!is.na(eff_col)) s$believes_effective <- yesno(s[[eff_col]]) else s$believes_effective <- NA
motives <- c()
if (!is.na(eff_col)) { s$m_eff <- s$believes_effective; s$m_eff[is.na(s$m_eff)] <- 0; motives <- c(motives, "m_eff") }
if (!is.na(prog_col)) { s$m_prog <- yesno(s[[prog_col]]); s$m_prog[is.na(s$m_prog)] <- 0; motives <- c(motives, "m_prog") }

cat("INFO: controls =", paste(c(raw_ctrls, motives), collapse = ", "), "\n")

fml <- function(lhs, rhs) as.formula(paste(lhs, "~", paste(rhs, collapse = " + ")))
getc <- function(m, v) { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA }

results <- list()

# ---- feedback sample ----
var_col <- pick(c("variante_taxe_info", "variant_tax_info", "feedback_variant"))
if (!is.na(var_col) && any(grepl("f", lc(s[[var_col]])))) {
  s$got_feedback <- grepl("f", lc(s[[var_col]])) & !is.na(s[[fb_col]])
} else {
  s$got_feedback <- !is.na(s[[fb_col]]) & lc(s[[fb_col]]) != ""
}
fb <- s[s$got_feedback & !is.na(s$g_hat), ]
cat(sprintf("SAMPLE:table4_col2:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:table4_col2:received_feedback=%d\n", nrow(fb)))
if (nrow(fb) != 1968) cat(sprintf("DEVIATION: feedback sample has %d rows vs 1968 in paper\n", nrow(fb)))

fb50 <- fb[abs(fb$g_hat) < 50, ]
cat(sprintf("SAMPLE:table4_col1:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:table4_col1:received_feedback=%d\n", nrow(fb)))
cat(sprintf("SAMPLE:table4_col1:abs_gain_lt_50=%d\n", nrow(fb50)))

rhs1 <- c("predicted_winner", "init_accept", "g_hat", "g_hat2", ctrls, motives)

m1 <- tryCatch(feols(fml("not_lose_post", rhs1), data = fb50, weights = ~w_, vcov = "hetero"),
               error = function(e) { cat("ERROR m1:", conditionMessage(e), "\n"); NULL })
if (!is.null(m1)) {
  cat(sprintf("SAMPLE:table4_col1:estimation=%d\n", nobs(m1)))
  results$predicted_winner_believes_not_lose_table4_col1 <- getc(m1, "predicted_winner")
  results$initial_acceptance_believes_not_lose_table4_col1 <- getc(m1, "init_accept")
  results$n_obs_table4_col1 <- nobs(m1)
}

m2 <- tryCatch(feols(fml("not_lose_post", rhs1), data = fb, weights = ~w_, vcov = "hetero"),
               error = function(e) { cat("ERROR m2:", conditionMessage(e), "\n"); NULL })
if (!is.null(m2)) {
  cat(sprintf("SAMPLE:table4_col2:estimation=%d\n", nobs(m2)))
  results$predicted_winner_believes_not_lose_full_sample_table4_col2 <- getc(m2, "predicted_winner")
}

fb50$w_x_acc <- fb50$predicted_winner * fb50$init_accept
fb50$w_x_yv <- fb50$predicted_winner * fb50$yv_supporter
fb50$w_x_G <- fb50$predicted_winner * fb50$G_init
rhs3 <- c("predicted_winner", "init_accept", "yv_supporter", "G_init", "w_x_acc", "w_x_yv", "w_x_G",
          "g_hat", "g_hat2", "init_cat", ctrls, motives)
cat(sprintf("SAMPLE:table4_col3:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:table4_col3:received_feedback=%d\n", nrow(fb)))
cat(sprintf("SAMPLE:table4_col3:abs_gain_lt_50=%d\n", nrow(fb50)))
m3 <- tryCatch(feols(fml("not_lose_post", rhs3), data = fb50, weights = ~w_, vcov = "hetero"),
               error = function(e) { cat("ERROR m3:", conditionMessage(e), "\n"); NULL })
if (!is.null(m3)) {
  cat(sprintf("SAMPLE:table4_col3:estimation=%d\n", nobs(m3)))
  results$predicted_winner_heterogeneity_table4_col3 <- getc(m3, "predicted_winner")
  results$initial_acceptance_heterogeneity_table4_col3 <- getc(m3, "init_accept")
  results$yellow_vests_supporter_heterogeneity_table4_col3 <- getc(m3, "yv_supporter")
  results$winner_x_initial_acceptance_table4_col3 <- getc(m3, "w_x_acc")
  results$winner_x_yellow_vests_supporter_table4_col3 <- getc(m3, "w_x_yv")
  results$winner_x_initial_win_belief_table4_col3 <- getc(m3, "w_x_G")
}

cat(sprintf("SAMPLE:table4_col4:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:table4_col4:received_feedback=%d\n", nrow(fb)))
cat(sprintf("SAMPLE:table4_col4:abs_gain_lt_50=%d\n", nrow(fb50)))
m4 <- tryCatch(feols(fml("win_post", rhs1), data = fb50, weights = ~w_, vcov = "hetero"),
               error = function(e) { cat("ERROR m4:", conditionMessage(e), "\n"); NULL })
if (!is.null(m4)) {
  cat(sprintf("SAMPLE:table4_col4:estimation=%d\n", nobs(m4)))
  results$predicted_winner_believes_wins_table4_col4 <- getc(m4, "predicted_winner")
}

# ---- Table 6: targeted dividend, fuzzy design via random eligibility ----
tryCatch({
  tacc <- pick(c("tax_cible_acceptance", "taxe_cible_acceptation"))
  tcat <- pick(c("win_cible_category", "gagnant_cible_categorie"))
  s$cible_accept <- yesno(s[[tacc]], accept = TRUE)
  cat("INFO: targeted category column =", tcat, "; raw values:",
      paste(names(table(s[[tcat]], useNA = "ifany")), table(s[[tcat]], useNA = "ifany"), sep = "=", collapse = " | "), "\n")
  if (!is.null(labmaps[[tcat]])) cat("INFO: targeted category labels:", paste(labmaps[[tcat]]$codes, labmaps[[tcat]]$labs, sep = "=", collapse = " | "), "\n")
  sg_c <- cat_sign(tcat)
  cat("INFO: targeted sign table:", paste(names(table(sg_c, useNA = "ifany")), table(sg_c, useNA = "ifany"), sep = "=", collapse = " "), "\n")
  # If the chosen column yields no 'loser' category, look for another targeted-category column that does
  if (!any(sg_c < 0, na.rm = TRUE)) {
    alt <- grep("cible", cols, value = TRUE, ignore.case = TRUE)
    alt <- alt[grepl("categ|gagn|perd|win|los", alt, ignore.case = TRUE) & !grepl("feedback|accept", alt, ignore.case = TRUE)]
    alt <- setdiff(alt, tcat)
    for (a in alt) {
      sa <- tryCatch(cat_sign(a), error = function(e) NULL)
      if (is.null(sa)) next
      cat("INFO: alternative targeted column", a, "sign table:",
          paste(names(table(sa, useNA = "ifany")), table(sa, useNA = "ifany"), sep = "=", collapse = " "), "\n")
      if (any(sa < 0, na.rm = TRUE) && any(sa >= 0, na.rm = TRUE)) {
        cat("DEVIATION: using", a, "instead of", tcat, "for targeted winner category\n")
        sg_c <- sa; tcat <- a; break
      }
    }
  }
  if (any(sg_c < 0, na.rm = TRUE)) {
    s$not_lose_cible <- as.numeric(sg_c >= 0)
  } else {
    # Only two categories present (no explicit loser code): lower category treated as 'loses',
    # higher category as 'does not lose'
    u <- sort(unique(sg_c[!is.na(sg_c)]))
    cat(sprintf("DEVIATION: targeted category has no loser code (values %s); treating lowest category as 'loses'\n",
                paste(u, collapse = ",")))
    s$not_lose_cible <- as.numeric(sg_c > min(u))
  }
  cat("INFO: not_lose_cible table:", paste(names(table(s$not_lose_cible, useNA = "ifany")), table(s$not_lose_cible, useNA = "ifany"), sep = "=", collapse = " "), "\n")
  pr <- as.numeric(s[[pick(c("percentile_revenu"))]])
  prc <- as.numeric(s[[pick(c("percentile_revenu_conjoint"))]])
  s$pr <- pr; s$prc <- ifelse(is.na(prc), 0, prc)
  cib <- pick(c("cible", "threshold_cible", "seuil_cible"), "^cible$")
  t1 <- pick(c("traite_cible", "eligible_cible", "treated_cible"))
  t2 <- pick(c("traite_cible_conjoint", "eligible_cible_conjoint", "treated_cible_conjoint"))
  if (!is.na(cib)) s$cible_fe <- factor(s[[cib]]) else s$cible_fe <- factor(1)
  if (!is.na(t1)) {
    s$elig <- yesno(s[[t1]])
  } else {
    s$elig <- as.numeric(s$pr <= as.numeric(as.character(s$cible_fe)))
  }
  if (!is.na(t2)) {
    s$elig_c <- yesno(s[[t2]]); s$elig_c[is.na(s$elig_c)] <- 0
  } else {
    s$elig_c <- as.numeric(!is.na(prc) & prc <= as.numeric(as.character(s$cible_fe)))
  }
  s$elig_x <- s$elig * s$elig_c
  sgl <- pick(c("single"))
  s$single_ <- if (!is.na(sgl)) yesno(s[[sgl]]) else as.numeric(s$prc == 0)
  s$pr2 <- s$pr^2; s$prc2 <- s$prc^2
  t6 <- s[!is.na(s$cible_accept) & !is.na(s$not_lose_cible) & !is.na(s[[tcat]]), ]
  cat(sprintf("SAMPLE:table6_col1:loaded=%d\n", n_loaded))
  cat(sprintf("SAMPLE:table6_col1:answered_targeted_tax=%d\n", nrow(t6)))
  t6 <- t6[(t6$pr >= 10 & t6$pr <= 60) | (t6$prc >= 10 & t6$prc <= 60), ]
  t6 <- t6[!is.na(t6$pr) & !is.na(t6$elig) & !is.na(t6$init_accept) & !is.na(t6$single_), ]
  cat(sprintf("SAMPLE:table6_col1:income_percentile_10_60=%d\n", nrow(t6)))
  fe_names <- c()
  lv <- levels(droplevels(t6$cible_fe))
  if (length(lv) > 1) {
    for (k in lv[-1]) {
      nmk <- paste0("cfe_", make.names(k))
      t6[[nmk]] <- as.numeric(as.character(t6$cible_fe) == k)
      fe_names <- c(fe_names, nmk)
    }
  }
  ex <- prune(t6, c(fe_names, "single_", "init_accept", "pr", "pr2", "prc", "prc2"))
  f6 <- as.formula(paste("cible_accept ~", paste(ex, collapse = " + "),
                         "| not_lose_cible ~ elig + elig_c + elig_x"))
  m6 <- feols(f6, data = t6, weights = ~w_, vcov = "hetero")
  cat(sprintf("SAMPLE:table6_col1:estimation=%d\n", nobs(m6)))
  cat("INFO: table6 coef names:", paste(names(coef(m6)), collapse = ", "), "\n")
  results$believes_not_lose_on_acceptance_iv_table6_col1 <- getc(m6, "fit_not_lose_cible")
}, error = function(e) cat("ERROR table6:", conditionMessage(e), "\n"))

# ---- Table 8: effectiveness IV ----
tryCatch({
  i1 <- pick(c("apres_modifs", "info_efficacite", "info_scientists", "info_effectiveness"), "apres_modif|info_effic")
  i2 <- pick(c("info_CC", "info_climate"), "^info_cc$")
  cat("INFO: Table 8 instruments =", i1, i2, "\n")
  s$z1 <- yesno(s[[i1]])
  if (!is.na(i2)) s$z2 <- yesno(s[[i2]]) else {
    ic <- pick(c("info"))
    s$z2 <- as.numeric(grepl("cc", lc(s[[ic]])))
  }
  # Effectiveness belief as "does not think the tax is ineffective" (Yes or PNR vs No),
  # mirroring the acceptance-style (not "No") coding used for the binary beliefs
  ex_raw <- s[[eff_col]]
  if (is.numeric(ex_raw) && !is.null(labmaps[[eff_col]])) {
    lm_ <- labmaps[[eff_col]]
    ex_lab <- lc(lm_$labs[match(ex_raw, lm_$codes)])
  } else {
    ex_lab <- lc(ex_raw)
  }
  num_ex <- suppressWarnings(as.numeric(ex_lab))
  if (sum(!is.na(num_ex)) >= 0.9 * sum(!is.na(ex_lab))) {
    s$eff_notno <- as.numeric(num_ex >= 0)
  } else {
    s$eff_notno <- as.numeric(!grepl("^(non|no$|no |false)", ex_lab))
    s$eff_notno[is.na(ex_lab)] <- NA
  }
  cat("INFO: effectiveness (not No) table:", paste(names(table(s$eff_notno, useNA = "ifany")), table(s$eff_notno, useNA = "ifany"), sep = "=", collapse = " "), "\n")
  cat("DEVIATION: Table 8 endogenous belief coded as 'does not believe the tax is ineffective' (not No) and instrumented by the scientists-agree information and the climate-change information only\n")
  s$g_full <- s$g_hat; s$g_full[is.na(s$g_full)] <- 0
  s$g_full2 <- s$g_full^2
  s$nl_init <- s$G_init; s$nl_init[is.na(s$nl_init)] <- 0
  t8 <- s[!is.na(s$init_approve) & !is.na(s$eff_notno) & !is.na(s$z1) & !is.na(s$z2), ]
  cat(sprintf("SAMPLE:table8_col1:loaded=%d\n", n_loaded))
  cat(sprintf("SAMPLE:table8_col1:all_respondents=%d\n", nrow(t8)))
  ex8 <- prune(t8, c(ctrls, "nl_init", if ("m_prog" %in% motives) "m_prog", "g_full", "g_full2"))
  f8 <- as.formula(paste("init_approve ~", paste(ex8, collapse = " + "),
                         "| eff_notno ~ z1 + z2"))
  m8 <- feols(f8, data = t8, weights = ~w_, vcov = "hetero")
  cat(sprintf("SAMPLE:table8_col1:estimation=%d\n", nobs(m8)))
  results$believes_effective_on_approval_iv_table8_col1 <- getc(m8, "fit_eff_notno")
}, error = function(e) cat("ERROR table8:", conditionMessage(e), "\n"))

for (nm in names(results)) {
  v <- results[[nm]]
  if (!is.null(v) && !is.na(v)) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
}
