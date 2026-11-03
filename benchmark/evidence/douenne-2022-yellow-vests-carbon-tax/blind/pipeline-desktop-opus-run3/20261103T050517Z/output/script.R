suppressPackageStartupMessages({
  library(fixest)
})
set.seed(42)

rdata <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
env <- new.env()
load(rdata, envir = env)
s <- env$s

# Convert memisc-style (S4 / value.labels) columns to plain vectors without loading memisc
demem <- function(x) {
  has_lab <- !is.null(attr(x, "value.labels"))
  if (!(isS4(x) || has_lab)) return(x)
  labs <- attr(x, "value.labels")
  vals <- NULL; labtxt <- NULL
  if (!is.null(labs)) {
    vals <- tryCatch({ v <- attr(labs, "values"); if (isS4(v)) v <- asS4(v, FALSE, FALSE); attributes(v) <- NULL; v }, error = function(e) NULL)
    labtxt <- tryCatch({ l <- labs; if (isS4(l)) l <- asS4(l, FALSE, FALSE); attributes(l) <- NULL; as.character(l) }, error = function(e) NULL)
  }
  d <- x
  if (isS4(d)) d <- asS4(d, FALSE, FALSE)
  attributes(d) <- NULL
  if (is.character(d) || is.logical(d)) return(d)
  if (!is.null(vals) && !is.null(labtxt) && length(vals) == length(labtxt) && length(vals) > 0) {
    m <- match(d, vals)
    nn <- !is.na(d)
    if (sum(nn) > 0 && mean(!is.na(m[nn])) >= 0.5) {
      out <- labtxt[m]
      out[nn & is.na(m)] <- as.character(d[nn & is.na(m)])
      return(out)
    }
  }
  d
}
L <- lapply(seq_along(s), function(j) tryCatch(demem(s[[j]]), error = function(e) {
  d <- s[[j]]; if (isS4(d)) d <- asS4(d, FALSE, FALSE); attributes(d) <- NULL; d
}))
nms_s <- names(s)
nms_s[is.na(nms_s) | nms_s == ""] <- paste0("V_unnamed_", which(is.na(nms_s) | nms_s == ""))
names(L) <- nms_s
s <- data.frame(L, check.names = FALSE, stringsAsFactors = FALSE)
rm(L)
nm <- names(s)
cat("Rows in s:", nrow(s), "\n")

pick <- function(c) { c <- c[c %in% nm]; if (length(c)) c[1] else NA_character_ }
grepcol <- function(p) { x <- grep(p, nm, value = TRUE, ignore.case = TRUE); if (length(x)) x[1] else NA_character_ }
chr <- function(x) {
  if (inherits(x, "haven_labelled")) return(as.character(haven::as_factor(x)))
  as.character(x)
}
lc <- function(x) trimws(tolower(chr(x)))
miss <- function(x) is.na(x) | lc(x) %in% c("", "na", "nan")
isyes <- function(x) lc(x) %in% c("oui", "yes", "true", "1")
isno <- function(x) lc(x) %in% c("non", "no", "false", "0")
islose <- function(x) grepl("perdant|lose|loser|perd", lc(x))
iswin <- function(x) { v <- lc(x); grepl("gagnant|win", v) & !grepl("perdant|lose|non affect|unaff", v) }
tonum <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x))
  as.numeric(lc(x) %in% c("true", "oui", "yes", "1", "t"))
}
showtab <- function(col) {
  if (!is.na(col)) { cat("--", col, "--\n"); print(table(chr(s[[col]]), useNA = "ifany")) }
}
fmt <- function(x) if (is.null(x) || length(x) == 0 || is.na(x[1])) "NA" else format(unname(x[1]), digits = 10)

w <- if ("weight" %in% nm) as.numeric(s$weight) else rep(1, nrow(s))
w[is.na(w)] <- 0

# ---------------- key variables ----------------
gcol <- pick(c("simule_gain", "simulated_gain", "gain_simule", "estimated_gain"))
if (is.na(gcol)) gcol <- grepcol("^simul.*gain$")
cat("gain column:", gcol, "\n")
gain <- as.numeric(s[[gcol]])

wcol <- pick(c("simule_gagnant", "simulated_winner", "predicted_winner"))
winner <- rep(NA_real_, nrow(s))
if (!is.na(wcol)) {
  v <- s[[wcol]]
  showtab(wcol)
  if (is.numeric(v) || is.logical(v)) {
    winner <- as.numeric(v)
  } else {
    lv <- lc(v)
    winner <- ifelse(lv %in% c("true", "t", "oui", "yes", "1") | iswin(v), 1,
              ifelse(lv %in% c("false", "f", "non", "no", "0") | islose(v), 0, NA_real_))
  }
}
winner[is.na(winner)] <- as.numeric(gain[is.na(winner)] > 0)
if (length(unique(winner[!is.na(winner)])) < 2) {
  cat("winner column constant; falling back to gain > 0\n")
  winner <- as.numeric(gain > 0)
}
cat("winner column:", wcol, " mean:", mean(winner, na.rm = TRUE), " agreement with gain>0:", mean(winner == (gain > 0), na.rm = TRUE), "\n")

fcol <- pick(c("winning_feedback_category", "gagnant_feedback_categorie"))
icol <- pick(c("winning_category", "gagnant_categorie"))
showtab(fcol); showtab(icol)
fbv <- s[[fcol]]
y_notlose <- as.numeric(!islose(fbv))
y_wins <- as.numeric(iswin(fbv))
G <- as.numeric(!islose(s[[icol]]))
cat_init <- chr(s[[icol]]); cat_init[miss(s[[icol]])] <- "missing"; cat_init <- factor(cat_init)

apcol <- pick(c("taxe_approbation", "tax_approval_initial"))
showtab(apcol)
acol <- pick(c("tax_acceptance", "taxe_acceptation"))
if (!is.na(acol)) {
  v <- s[[acol]]
  acc <- if (is.numeric(v) || is.logical(v)) as.numeric(v) else as.numeric(!isno(v) & !miss(v))
} else acc <- as.numeric(!isno(s[[apcol]]) & !miss(s[[apcol]]))
acc[is.na(acc)] <- 0
apprcol <- pick(c("tax_approval"))
if (!is.na(apprcol) && (is.numeric(s[[apprcol]]) || is.logical(s[[apprcol]]))) {
  appr <- as.numeric(s[[apprcol]])
} else appr <- as.numeric(isyes(s[[apcol]]))
appr[is.na(appr)] <- 0
cat("mean acceptance", mean(acc), " mean approval", mean(appr), "\n")

if (all(c("gilets_jaunes_soutien", "gilets_jaunes_dedans") %in% nm)) {
  yv <- as.numeric(tonum(s$gilets_jaunes_soutien) == 1 | tonum(s$gilets_jaunes_dedans) == 1)
} else {
  gj <- pick(c("gilets_jaunes", "Gilets_jaunes", "yellow_vests"))
  showtab(gj)
  v <- s[[gj]]
  if (is.numeric(v)) yv <- as.numeric(v >= 1) else yv <- as.numeric(grepl("soutien|dedans|support|part|member", lc(v)))
}
yv[is.na(yv)] <- 0
cat("mean YV supporter", mean(yv), "\n")

effcol <- pick(c("taxe_efficace", "tax_effective"))
showtab(effcol)
eff <- as.numeric(isyes(s[[effcol]]))
progcol <- pick(c("progressivite", "progressivity"))
prog <- if (!is.na(progcol)) { p <- chr(s[[progcol]]); p[miss(s[[progcol]])] <- "missing"; factor(p) } else factor(rep("a", nrow(s)))

# income
rcol <- pick(c("revenu", "Revenu", "income"))
rccol <- pick(c("revenu_conjoint", "Revenu_conjoint", "income_spouse"))
rev <- if (!is.na(rcol)) as.numeric(s[[rcol]]) else rep(0, nrow(s))
revc <- if (!is.na(rccol)) as.numeric(s[[rccol]]) else rep(0, nrow(s))
rev[is.na(rev)] <- 0; revc[is.na(revc)] <- 0
rev <- rev / 1000; revc <- revc / 1000

# socio-demographics
demo_default <- c("sexe", "age", "diplome", "csp", "statut_emploi", "taille_agglo", "region", "taille_menage")
demo <- demo_default
if (exists("variables_demo", envir = env) && is.character(get("variables_demo", envir = env))) {
  vd <- intersect(get("variables_demo", envir = env), nm)
  if (length(vd) >= 3) demo <- vd
}
demo <- intersect(demo, nm)
demo <- setdiff(demo, c(rcol, rccol, "revenu", "revenu_conjoint", "Revenu", "Revenu_conjoint", "weight"))
cat("demo controls:", paste(demo, collapse = ", "), "\n")

D <- data.frame(y_notlose = y_notlose, y_wins = y_wins, winner = winner, gain = gain,
                gain2 = gain^2, acc = acc, yv = yv, G = G, cat_init = cat_init,
                eff = eff, appr = appr, prog = prog, rev = rev, rev2 = rev^2,
                revc = revc, revc2 = revc^2, w = w)
demo_names <- c()
for (i in seq_along(demo)) {
  v <- s[[demo[i]]]
  nmv <- paste0("d_", i)
  if (is.numeric(v) || is.logical(v)) {
    x <- as.numeric(v); x[is.na(x)] <- 0
  } else {
    x <- chr(v); x[miss(v)] <- "missing"; x <- factor(x)
    if (nlevels(x) > 60) next
  }
  D[[nmv]] <- x
  demo_names <- c(demo_names, nmv)
}

keep_vars <- function(df, vars) {
  out <- c()
  for (v in vars) {
    if (is.na(v) || v == "") next
    x <- df[[v]]
    if (is.null(x)) next
    if (is.factor(x)) { if (nlevels(droplevels(x)) > 1) out <- c(out, v) }
    else if (length(unique(x[!is.na(x)])) > 1) out <- c(out, v)
  }
  out
}
fit_lm <- function(df, y, terms_fixed, ctrls) {
  df <- df[df$w > 0, , drop = FALSE]
  for (v in names(df)) if (is.factor(df[[v]])) df[[v]] <- droplevels(df[[v]])
  ctrls <- keep_vars(df, ctrls)
  f <- as.formula(paste(y, "~", paste(c(terms_fixed, ctrls), collapse = " + ")))
  lm(f, data = df, weights = w)
}

# ---------------- Table 4 ----------------
fb <- !miss(fbv) & !is.na(gain)
vt <- pick(c("variante_taxe_info", "variante_feedback"))
showtab(vt)
cat("feedback sample size:", sum(fb), "\n")
ctrl4 <- c("rev", "rev2", "revc", "revc2", demo_names, "eff", "prog")
res <- list()

sub1 <- D[fb & abs(gain) < 50, ]
m1 <- tryCatch(fit_lm(sub1, "y_notlose", c("winner", "acc", "gain", "gain2"), ctrl4), error = function(e) { print(e); NULL })
if (!is.null(m1)) {
  cm <- summary(m1)$coefficients
  print(cm[1:min(6, nrow(cm)), ])
  res$predicted_winner_believes_not_lose_table4_col1 <- coef(m1)["winner"]
  res$initial_acceptance_believes_not_lose_table4_col1 <- coef(m1)["acc"]
  res$n_obs_table4_col1 <- nobs(m1)
}

sub2 <- D[fb, ]
m2 <- tryCatch(fit_lm(sub2, "y_notlose", c("winner", "acc", "gain", "gain2"), ctrl4), error = function(e) { print(e); NULL })
if (!is.null(m2)) res$predicted_winner_believes_not_lose_full_sample_table4_col2 <- coef(m2)["winner"]

m3 <- tryCatch(fit_lm(sub1, "y_notlose",
                      c("winner", "acc", "yv", "G", "winner:acc", "winner:yv", "winner:G", "gain", "gain2"),
                      c(ctrl4, "cat_init")), error = function(e) { print(e); NULL })
if (!is.null(m3)) {
  cf <- coef(m3)
  getc <- function(a, b) { k <- c(paste0(a, ":", b), paste0(b, ":", a)); k <- k[k %in% names(cf)]; if (length(k)) cf[k[1]] else NA }
  res$predicted_winner_heterogeneity_table4_col3 <- cf["winner"]
  res$initial_acceptance_heterogeneity_table4_col3 <- cf["acc"]
  res$yellow_vests_supporter_heterogeneity_table4_col3 <- cf["yv"]
  res$winner_x_initial_acceptance_table4_col3 <- getc("winner", "acc")
  res$winner_x_yellow_vests_supporter_table4_col3 <- getc("winner", "yv")
  res$winner_x_initial_win_belief_table4_col3 <- getc("winner", "G")
}

m4 <- tryCatch(fit_lm(sub1, "y_wins", c("winner", "acc", "gain", "gain2"), ctrl4), error = function(e) { print(e); NULL })
if (!is.null(m4)) res$predicted_winner_believes_wins_table4_col4 <- coef(m4)["winner"]

# ---------------- Table 6: targeted dividend fuzzy RDD / IV ----------------
res$believes_not_lose_on_acceptance_iv_table6_col1 <- tryCatch({
  tcol <- pick(c("taxe_cible_approbation", "targeted_tax_approval"))
  if (is.na(tcol)) tcol <- grepcol("cible.*approbation")
  bcol <- pick(c("gagnant_cible_categorie", "winning_targeted_category"))
  if (is.na(bcol)) bcol <- grepcol("cible.*categorie")
  e1 <- pick(c("traite_cible", "eligible", "targeted_eligible"))
  e2 <- pick(c("traite_cible_conjoint", "eligible_conjoint", "targeted_eligible_spouse"))
  ccol <- pick(c("cible", "target_threshold", "percentile_cible"))
  cat("Table6 cols:", tcol, bcol, e1, e2, ccol, "\n")
  showtab(tcol); showtab(bcol); showtab(e1); showtab(e2); showtab(ccol)
  T6 <- D
  T6$yacc <- as.numeric(!isno(s[[tcol]]) & !miss(s[[tcol]]))
  T6$notlose <- as.numeric(!islose(s[[bcol]]))
  T6$e1 <- tonum(s[[e1]]); T6$e1[is.na(T6$e1)] <- 0
  T6$e2 <- if (!is.na(e2)) tonum(s[[e2]]) else 0; T6$e2[is.na(T6$e2)] <- 0
  T6$e12 <- T6$e1 * T6$e2
  T6$cible <- if (!is.na(ccol)) factor(chr(s[[ccol]])) else factor("a")
  T6$single <- if ("single" %in% nm) tonum(s$single) else 0
  ok <- !miss(s[[tcol]]) & !miss(s[[bcol]]) & T6$w > 0
  T6 <- T6[ok, ]
  T6$cible <- droplevels(T6$cible)
  ctr <- keep_vars(T6, c("cible", "single", "acc", "rev", "rev2", "revc", "revc2"))
  insts <- keep_vars(T6, c("e1", "e2", "e12"))
  rhs <- if (length(ctr)) paste(ctr, collapse = " + ") else "1"
  f <- as.formula(paste("yacc ~", rhs, "| notlose ~", paste(insts, collapse = " + ")))
  m6 <- feols(f, data = T6, weights = ~w)
  print(summary(m6))
  coef(m6)["fit_notlose"]
}, error = function(e) { print(e); NA })

# ---------------- Table 8: effectiveness IV ----------------
res$believes_effective_on_approval_iv_table8_col1 <- tryCatch({
  i1 <- pick(c("apres_modifs", "info_scientists", "info_efficacite"))
  i2 <- pick(c("info_CC", "info_cc"))
  cat("Table8 instruments:", i1, i2, "\n")
  T8 <- D
  T8$z1 <- tonum(s[[i1]]); T8$z2 <- tonum(s[[i2]])
  T8$z1[is.na(T8$z1)] <- 0; T8$z2[is.na(T8$z2)] <- 0
  cat("z means:", mean(T8$z1), mean(T8$z2), "\n")
  T8 <- T8[T8$w > 0 & !is.na(T8$gain), ]
  for (v in names(T8)) if (is.factor(T8[[v]])) T8[[v]] <- droplevels(T8[[v]])
  ctr <- keep_vars(T8, c(demo_names, "prog", "cat_init", "rev", "rev2", "revc", "revc2", "gain", "gain2"))
  rhs <- if (length(ctr)) paste(ctr, collapse = " + ") else "1"
  f <- as.formula(paste("appr ~", rhs, "| eff ~ z1 + z2"))
  m8 <- feols(f, data = T8, weights = ~w)
  tryCatch(print(fitstat(m8, "ivf")), error = function(e) NULL)
  coef(m8)["fit_eff"]
}, error = function(e) { print(e); NA })

nms <- c("predicted_winner_believes_not_lose_table4_col1",
         "initial_acceptance_believes_not_lose_table4_col1",
         "predicted_winner_believes_not_lose_full_sample_table4_col2",
         "predicted_winner_heterogeneity_table4_col3",
         "initial_acceptance_heterogeneity_table4_col3",
         "yellow_vests_supporter_heterogeneity_table4_col3",
         "winner_x_initial_acceptance_table4_col3",
         "winner_x_yellow_vests_supporter_table4_col3",
         "winner_x_initial_win_belief_table4_col3",
         "predicted_winner_believes_wins_table4_col4",
         "n_obs_table4_col1",
         "believes_not_lose_on_acceptance_iv_table6_col1",
         "believes_effective_on_approval_iv_table8_col1")
for (n in nms) {
  val <- tryCatch(fmt(res[[n]]), error = function(e) "NA")
  cat(sprintf("RESULT:%s=%s\n", n, val))
}