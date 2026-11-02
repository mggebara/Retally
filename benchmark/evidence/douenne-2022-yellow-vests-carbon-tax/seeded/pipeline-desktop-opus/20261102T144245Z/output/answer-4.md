## Reproduction of Douenne & Fabre (2022), Tables 4, 6 (col 1) and 8 (col 1)
## Follows papier.R: weighted lm() LPMs and manual two-step 2SLS as in the authors' code.
## Fix: memisc is not installed, so the memisc S4 item columns must be stripped
## without triggering any S4 class lookup (no inherits()/is.factor()/[[<- on them).
set.seed(42)
suppressWarnings(suppressMessages({ library(stats) }))

base_dir <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code"
f_prep <- file.path(base_dir, "after_preparation.RData")
f_pap  <- file.path(base_dir, "after_papier.RData")

e_prep <- new.env()
ok_prep <- tryCatch({ suppressWarnings(suppressMessages(load(f_prep, envir = e_prep))); TRUE }, error = function(e) { message("load prep failed: ", conditionMessage(e)); FALSE })
e_pap <- new.env()
ok_pap <- tryCatch({ suppressWarnings(suppressMessages(load(f_pap, envir = e_pap))); TRUE }, error = function(e) { message("load papier failed: ", conditionMessage(e)); FALSE })

if (ok_prep && exists("s", envir = e_prep, inherits = FALSE)) {
  s_raw <- get("s", envir = e_prep)
} else {
  s_raw <- get("s", envir = e_pap)
}

## ---------- helpers ----------
`%||%` <- function(a, b) if (is.null(a)) b else a

piece.formula <- function(var.names, knots, vector = FALSE) {
  formula.sign <- rep(" - ", length(knots))
  formula.sign[knots < 0] <- " + "
  formulas <- c()
  for (v in var.names) formulas <- c(formulas, paste(v, "+", paste("I(pmin(", v, formula.sign, abs(knots), ", 0))", collapse = " + ", sep = "")))
  formula <- paste(formulas, collapse = ' + ')
  if (vector) return(strsplit(formula, ' + ', fixed = TRUE)[[1]])
  else return(formula)
}

## strip all attributes (also clears the S4 bit) without any S4 dispatch
strip_plain <- function(x) {
  if (is.null(x)) return(NULL)
  attributes(x) <- NULL
  x
}

label_map <- list()   # columns with value labels: list(values, labels)

sanitize_col <- function(x, nm) {
  ## S4 check FIRST: inherits()/is.factor() on a memisc object triggers class lookup
  if (isS4(x)) {
    vl <- attr(x, "value.labels", exact = TRUE)
    ms <- attr(x, "measurement", exact = TRUE)
    base <- strip_plain(x)
    if (!is.null(vl)) {
      vals <- tryCatch(as.numeric(strip_plain(attr(vl, "values", exact = TRUE))), error = function(e) NULL)
      labs <- tryCatch(as.character(strip_plain(vl)), error = function(e) NULL)
      if (!is.null(vals) && !is.null(labs) && length(vals) == length(labs) && length(vals) > 0) {
        label_map[[nm]] <<- list(values = vals, labels = labs)
        msc <- tryCatch(as.character(strip_plain(ms))[1], error = function(e) NA_character_)
        if (!is.na(msc) && msc %in% c("nominal", "ordinal") && is.numeric(base)) {
          ch <- as.character(base)
          idx <- match(base, vals)
          ch[!is.na(idx)] <- labs[idx[!is.na(idx)]]
          return(factor(ch))
        }
      }
    }
    return(base)
  }
  if (is.factor(x)) {
    cl <- class(x); cl <- cl[cl != "labelled"]; class(x) <- cl
    attr(x, "label") <- NULL
    return(x)
  }
  if (inherits(x, c("Date", "POSIXct", "POSIXt"))) return(x)
  if (is.atomic(x) && !is.null(attr(x, "class"))) {
    cl <- class(x)
    if (any(cl == "labelled")) {
      vl <- attr(x, "labels", exact = TRUE)
      if (!is.null(vl)) {
        label_map[[nm]] <<- list(values = as.numeric(unname(vl)), labels = names(vl))
      }
      x <- unclass(x); attr(x, "label") <- NULL; attr(x, "labels") <- NULL
    }
    return(x)
  }
  if (is.atomic(x)) { attr(x, "label") <- NULL }
  x
}

## Build a plain data.frame column by column using primitives only
col_names <- attr(s_raw, "names", exact = TRUE)
if (is.null(col_names)) col_names <- names(s_raw)
cols <- vector("list", length(col_names))
for (i in seq_along(col_names)) {
  nm <- col_names[i]
  xi <- .subset2(s_raw, i)
  cols[[i]] <- tryCatch(sanitize_col(xi, nm), error = function(e) {
    message("sanitize failed for ", nm, ": ", conditionMessage(e))
    tryCatch(strip_plain(xi), error = function(e2) NULL)
  })
}
lens <- vapply(cols, function(z) if (is.null(z) || !is.null(dim(z))) NA_integer_ else length(z), integer(1))
n_rows <- as.integer(names(sort(table(lens), decreasing = TRUE))[1])
keep <- !is.na(lens) & lens == n_rows
cols <- cols[keep]
names(cols) <- col_names[keep]
cols <- cols[!duplicated(names(cols))]
d <- cols
attr(d, "row.names") <- .set_row_names(n_rows)
class(d) <- "data.frame"
message("Data: ", nrow(d), " rows, ", ncol(d), " columns")

chr <- function(nm) {
  x <- d[[nm]]
  if (is.null(x)) stop("missing variable ", nm)
  if (is.factor(x)) return(as.character(x))
  if (is.character(x)) return(x)
  if (is.logical(x)) return(as.character(x))
  if (!is.null(label_map[[nm]])) {
    lm_ <- label_map[[nm]]
    ch <- as.character(x)
    idx <- match(x, lm_$values)
    ch[!is.na(idx)] <- lm_$labels[idx[!is.na(idx)]]
    return(ch)
  }
  as.character(x)
}

to_num <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x) || is.character(x)) {
    ch <- as.character(x)
    r <- suppressWarnings(as.numeric(ch))
    nonmiss <- !is.na(ch) & ch != ""
    if (sum(nonmiss) > 0 && all(is.na(r[nonmiss]))) {
      r <- ifelse(ch %in% c("TRUE", "T", "Oui", "oui"), 1, ifelse(ch %in% c("FALSE", "F", "Non", "non"), 0, NA))
    }
    return(r)
  }
  as.numeric(x)
}

getc <- function(m, cands) {
  cf <- coef(m)
  for (c0 in cands) if (c0 %in% names(cf)) return(unname(cf[c0]))
  NA_real_
}

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
  else message("Could not compute ", name)
}

## ---------- control sets (as in papier.R) ----------
drop_vars <- c("revenu", "rev_tot", "age", "age_65_plus")
base6 <- c("prog_na", "Simule_gain", "Simule_gain2", "taxe_efficace", "single", "hausse_depenses_par_uc")
piece_terms <- piece.formula(c("percentile_revenu", "percentile_revenu_conjoint"), c(20, 70), vector = TRUE)

safe_chr_vec <- function(v) {
  if (is.null(v)) return(NULL)
  v <- tryCatch(as.character(strip_plain(v)), error = function(e) NULL)
  if (length(v) == 0) NULL else v
}

vd <- NULL
if (ok_prep) vd <- safe_chr_vec(get0("variables_demo", envir = e_prep, inherits = FALSE))
if (is.null(vd) && ok_pap) vd <- safe_chr_vec(get0("variables_demo", envir = e_pap, inherits = FALSE))

if (!is.null(vd)) {
  ctrl_fb <- c(base6, vd, piece_terms)
  ctrl_fb <- ctrl_fb[!(ctrl_fb %in% drop_vars)]
  ctrl_ee <- c("Revenu", "Revenu2", "Revenu_conjoint", "Revenu_conjoint2", "single", "Simule_gain", "Simule_gain2", "gagnant_categorie", vd)
  ctrl_ee <- ctrl_ee[!(ctrl_ee %in% drop_vars)]
} else {
  vref <- NULL
  if (ok_pap) vref <- safe_chr_vec(get0("variables_reg_effect_feedback", envir = e_pap, inherits = FALSE))
  if (is.null(vref) && ok_pap) vref <- safe_chr_vec(get0("variables_reg_self_interest", envir = e_pap, inherits = FALSE))
  if (is.null(vref)) {
    vd_guess <- c("sexe", "age_18_24", "age_25_34", "age_35_49", "age_50_64", "csp", "diplome4", "taille_agglo",
                  "region", "statut_emploi", "nb_adultes", "nb_14_et_plus", "uc", "niveau_vie", "taille_menage")
    vref <- c(base6, vd_guess, piece_terms)
  }
  ctrl_fb <- vref[!(vref %in% drop_vars)]
  demo_minus <- setdiff(ctrl_fb, c(base6, piece_terms))
  ctrl_ee <- c("Revenu", "Revenu2", "Revenu_conjoint", "Revenu_conjoint2", "single", "Simule_gain", "Simule_gain2", "gagnant_categorie", demo_minus)
}

keep_terms <- function(terms) {
  terms <- unique(terms)
  ok <- vapply(terms, function(t) {
    vs <- tryCatch(all.vars(as.formula(paste("~", t))), error = function(e) character(0))
    length(vs) > 0 && all(vs %in% names(d))
  }, logical(1))
  if (any(!ok)) message("Dropping unavailable controls: ", paste(terms[!ok], collapse = ", "))
  terms[ok]
}
ctrl_fb <- keep_terms(ctrl_fb)
ctrl_ee <- keep_terms(ctrl_ee)
message("Feedback/SI controls: ", paste(ctrl_fb, collapse = ", "))
message("EE controls: ", paste(ctrl_ee, collapse = ", "))

## ---------- derived variables ----------
d$weight <- to_num(d$weight)
d$y_notlose_fb <- as.numeric(chr("gagnant_feedback_categorie") != "Perdant")
d$y_win_fb     <- as.numeric(chr("gagnant_feedback_categorie") == "Gagnant")
d$sg   <- to_num(d$simule_gagnant)
d$ta   <- to_num(d$tax_acceptance)
d$nsp  <- as.numeric(chr("taxe_approbation") == "NSP")
d$G0   <- as.numeric(chr("gagnant_categorie") != "Perdant")
## Yellow Vests supporter dummy (gilets_jaunes > 0: supports or is part of the movement)
gj_raw <- d$gilets_jaunes
gjn <- rep(NA_real_, nrow(d))
if (is.numeric(gj_raw)) {
  gjn <- as.numeric(gj_raw)
} else if (!is.null(gj_raw)) {
  ch_gj <- as.character(gj_raw)
  num_gj <- suppressWarnings(as.numeric(ch_gj))
  if (sum(!is.na(num_gj)) > 0.5 * sum(!is.na(ch_gj) & ch_gj != "")) {
    gjn <- num_gj
  } else {
    if (!is.null(label_map[["gilets_jaunes"]])) {
      lmg <- label_map[["gilets_jaunes"]]
      gjn <- lmg$values[match(ch_gj, lmg$labels)]
    }
    if (all(is.na(gjn))) {
      gjn <- ifelse(is.na(ch_gj) | ch_gj == "" | grepl("NSP|ne sait", ch_gj, ignore.case = TRUE), NA,
                    ifelse(grepl("soutien|dedans|support|part", ch_gj, ignore.case = TRUE), 1, 0))
    }
  }
}
d$gj <- as.numeric(gjn > 0)
## Table 4 col 3 "Yellow Vests supporter": use the dataset's own supporter dummy (gilets_jaunes_soutien) when available
if ("gilets_jaunes_soutien" %in% names(d)) {
  gjs <- to_num(d$gilets_jaunes_soutien)
  if (sum(!is.na(gjs)) > 0 && length(unique(gjs[!is.na(gjs)])) == 2) {
    gjs[is.na(gjs)] <- 0
    d$gj <- gjs
  }
}
if (all(is.na(d$gj)) && "gilets_jaunes_soutien" %in% names(d)) d$gj <- to_num(d$gilets_jaunes_soutien)
message("gj table: ", paste(names(table(d$gj, useNA = "ifany")), table(d$gj, useNA = "ifany"), collapse = "; "))
sim_gain <- to_num(d$simule_gain)
is_fb <- chr("variante_taxe_info") == "f"
is_fb[is.na(is_fb)] <- FALSE

sub_close <- which(is_fb & !is.na(sim_gain) & abs(sim_gain) < 50)
sub_fb    <- which(is_fb)

rhs_fb <- paste(ctrl_fb, collapse = " + ")

## ---------- Table 4 ----------
## (1) believes does not lose, |gain|<50
m1 <- tryCatch(lm(as.formula(paste("y_notlose_fb ~ sg + ta + nsp +", rhs_fb)), data = d[sub_close, ], weights = weight, na.action = na.exclude),
               error = function(e) { message("T4c1: ", conditionMessage(e)); NULL })
## (2) full feedback sample
m2 <- tryCatch(lm(as.formula(paste("y_notlose_fb ~ sg + ta + nsp +", rhs_fb)), data = d[sub_fb, ], weights = weight, na.action = na.exclude),
               error = function(e) { message("T4c2: ", conditionMessage(e)); NULL })
## (3) heterogeneity
m3 <- tryCatch(lm(as.formula(paste("y_notlose_fb ~ G0 * sg + sg * gj + sg * ta + nsp +", rhs_fb)), data = d[sub_close, ], weights = weight, na.action = na.exclude),
               error = function(e) { message("T4c3: ", conditionMessage(e)); NULL })
## (4) believes wins
m4 <- tryCatch(lm(as.formula(paste("y_win_fb ~ sg + ta + nsp +", rhs_fb)), data = d[sub_close, ], weights = weight, na.action = na.exclude),
               error = function(e) { message("T4c4: ", conditionMessage(e)); NULL })

## ---------- Table 6 col 1: 2SLS, targeted dividend, sample [p10;p60] ----------
b6 <- NA_real_
tryCatch({
  pr  <- to_num(d$percentile_revenu)
  prc <- to_num(d$percentile_revenu_conjoint)
  cond <- (pr <= 60 & pr >= 10) | (prc <= 60 & prc >= 10)
  cond[is.na(cond)] <- FALSE
  idx <- which(cond)
  d$y_notlose_t <- as.numeric(chr("gagnant_cible_categorie") != "Perdant")
  d$acc_t <- as.numeric(chr("taxe_cible_approbation") != "Non")
  fs <- lm(as.formula(paste("y_notlose_t ~ traite_cible * traite_cible_conjoint + cible + nsp + ta +", rhs_fb)),
           data = d[idx, ], weights = weight, na.action = na.exclude)
  d$non_perdant <- NA_real_
  d$non_perdant[idx] <- as.numeric(fitted(fs))
  ss <- lm(as.formula(paste("acc_t ~", rhs_fb, "+ cible + nsp + ta + non_perdant")),
           data = d[idx, ], weights = weight)
  b6 <<- getc(ss, "non_perdant")
  message("T6 N = ", nobs(ss))
}, error = function(e) message("T6: ", conditionMessage(e)))

## ---------- Table 8 col 1: 2SLS, environmental effectiveness ----------
b8 <- NA_real_
tryCatch({
  rhs_ee <- paste(ctrl_ee, collapse = " + ")
  d$eff_yes <- as.numeric(chr("taxe_efficace") == "Oui")
  d$approve <- as.numeric(chr("taxe_approbation") == "Oui")
  fs8 <- lm(as.formula(paste("eff_yes ~", rhs_ee, "+ apres_modifs + info_CC")), data = d, weights = weight, na.action = na.exclude)
  d$taxe_efficace.hat <- as.numeric(fitted(fs8))
  ss8 <- lm(as.formula(paste("approve ~", rhs_ee, "+ taxe_efficace.hat")), data = d, weights = weight)
  b8 <<- getc(ss8, "taxe_efficace.hat")
  message("T8 N = ", nobs(ss8))
}, error = function(e) message("T8: ", conditionMessage(e)))

## ---------- output ----------
if (!is.null(m1)) {
  emit("predicted_winner_believes_not_lose_table4_col1", getc(m1, "sg"))
  emit("initial_acceptance_believes_not_lose_table4_col1", getc(m1, "ta"))
}
if (!is.null(m2)) emit("predicted_winner_believes_not_lose_full_sample_table4_col2", getc(m2, "sg"))
if (!is.null(m3)) {
  emit("predicted_winner_heterogeneity_table4_col3", getc(m3, "sg"))
  emit("initial_acceptance_heterogeneity_table4_col3", getc(m3, "ta"))
  emit("yellow_vests_supporter_heterogeneity_table4_col3", getc(m3, "gj"))
  emit("winner_x_initial_acceptance_table4_col3", getc(m3, c("sg:ta", "ta:sg")))
  emit("winner_x_yellow_vests_supporter_table4_col3", getc(m3, c("sg:gj", "gj:sg")))
  emit("winner_x_initial_win_belief_table4_col3", getc(m3, c("G0:sg", "sg:G0")))
}
if (!is.null(m4)) emit("predicted_winner_believes_wins_table4_col4", getc(m4, "sg"))
if (!is.null(m1)) emit("n_obs_table4_col1", as.numeric(nobs(m1)))
emit("believes_not_lose_on_acceptance_iv_table6_col1", b6)
emit("believes_effective_on_approval_iv_table8_col1", b8)
