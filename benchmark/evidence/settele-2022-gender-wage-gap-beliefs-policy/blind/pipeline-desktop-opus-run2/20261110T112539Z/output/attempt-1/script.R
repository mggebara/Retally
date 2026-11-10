suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(scipen = 999, warn = 1)

base <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy.script-free"
rd <- function(f) read_dta(file.path(base, "data", f))

A <- rd("SurveyStageI_WaveA_raw.dta")
B <- rd("SurveyStageI_WaveB_raw.dta")
FA <- rd("SurveyStageII_WaveA_raw.dta")
FB <- rd("SurveyStageII_WaveB_raw.dta")

# ---------------- helpers ----------------
to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    y <- suppressWarnings(as.numeric(gsub("[^0-9.-]", "", x)))
    y[is.na(x) | x == ""] <- NA
    return(y)
  }
  suppressWarnings(as.numeric(x))
}
lab_text <- function(x) {
  if (inherits(x, "haven_labelled")) return(as.character(as_factor(x, levels = "default")))
  if (is.numeric(x)) return(ifelse(is.na(x), NA_character_, as.character(round(x, 6))))
  as.character(x)
}
conv_num <- function(df) as.data.frame(lapply(df, to_num), stringsAsFactors = FALSE, optional = TRUE)
conv_chr <- function(df) as.data.frame(lapply(df, lab_text), stringsAsFactors = FALSE, optional = TRUE)
get_labs <- function(df) lapply(df, function(x) attr(x, "labels"))
get_vlab <- function(df) vapply(df, function(x) {
  l <- attr(x, "label"); if (is.null(l)) "" else as.character(l)[1]
}, character(1))
merge_labs <- function(a, b) {
  out <- a
  for (n in names(b)) if (is.null(out[[n]]) && !is.null(b[[n]])) out[[n]] <- b[[n]]
  out
}

dn <- bind_rows(conv_num(A), conv_num(B))
dc <- bind_rows(conv_chr(A), conv_chr(B))
labs <- merge_labs(get_labs(A), get_labs(B))
vA <- get_vlab(A); vB <- get_vlab(B)
vl <- c(vA, vB[setdiff(names(vB), names(vA))])
src_wave <- c(rep(0, nrow(A)), rep(1, nrow(B)))

cat("Stage I rows:", nrow(dn), " cols:", ncol(dn), "\n")
cat("---- Stage I variables (name : label) ----\n")
for (n in names(dn)) cat(n, ":", substr(vl[n], 1, 90), "\n")

excl_default <- "Time$|anchor|calculation|order|summary"
find_var <- function(dfn, vlab, name_pats, lab_pats = NULL, exclude = excl_default, min_n = 50) {
  nms <- names(dfn)
  ok <- function(v) !grepl(exclude, v, ignore.case = TRUE) && sum(!is.na(dfn[[v]])) >= min_n
  for (p in name_pats) {
    m <- nms[grepl(p, nms, ignore.case = TRUE)]
    m <- m[vapply(m, ok, logical(1))]
    if (length(m)) return(m[1])
  }
  if (!is.null(lab_pats)) for (p in lab_pats) {
    m <- nms[grepl(p, vlab[nms], ignore.case = TRUE)]
    m <- m[vapply(m, ok, logical(1))]
    if (length(m)) return(m[1])
  }
  NA_character_
}

orient <- function(x, v, labset) {
  l <- labset[[v]]
  if (!is.null(l) && length(l) > 1) {
    lv <- suppressWarnings(as.numeric(l)); lt <- tolower(names(l))
    lo <- lt[which.min(lv)]
    cat("  labels of", v, ":", paste(paste0(lv, "=", lt), collapse = " | "), "\n")
    pos <- "strongly agree|^agree|very large|very serious|very big|much more|completely|definitely|strongly support|^large|extremely"
    if (length(lo) && grepl(pos, lo) && !grepl("disagree|not |oppose|small|less", lo)) {
      cat("  -> reversing scale of", v, "\n")
      return(max(x, na.rm = TRUE) + min(x, na.rm = TRUE) - x)
    }
  }
  x
}

zsc <- function(x, ref) {
  m <- mean(x[ref], na.rm = TRUE); s <- sd(x[ref], na.rm = TRUE)
  (x - m) / s
}

anderson <- function(Z, ref) {
  Z <- as.matrix(Z)
  S <- cov(Z[ref, , drop = FALSE], use = "pairwise.complete.obs")
  S[is.na(S)] <- 0
  w <- rowSums(solve(S))
  cat("  Anderson weights:", round(w, 3), "\n")
  idx <- apply(Z, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) NA_real_ else sum(w[ok] * r[ok]) / sum(w[ok])
  })
  (idx - mean(idx[ref], na.rm = TRUE)) / sd(idx[ref], na.rm = TRUE)
}

res <- list()
setres <- function(name, expr) {
  v <- tryCatch(expr, error = function(e) { cat("ERROR in", name, ":", conditionMessage(e), "\n"); NA_real_ })
  res[[name]] <<- as.numeric(v)[1]
}

# ---------------- treatment ----------------
detect_treat <- function() {
  nms <- names(dn); low <- tolower(nms)
  if ("t74" %in% low && "t94" %in% low) {
    a <- dn[[nms[low == "t74"][1]]]; b <- dn[[nms[low == "t94"][1]]]
    a[is.na(a)] <- 0; b[is.na(b)] <- 0
    return(list(t74 = as.numeric(a == 1), treated = (a == 1 | b == 1), src = "t74/t94 dummies"))
  }
  for (v in nms) {
    x <- dn[[v]]; u <- sort(unique(x[!is.na(x)]))
    if (length(u) >= 2 && length(u) <= 3 && all(u %in% c(0, 74, 94)) && all(c(74, 94) %in% u)) {
      return(list(t74 = as.numeric(!is.na(x) & x == 74), treated = !is.na(x) & x %in% c(74, 94), src = v))
    }
  }
  cands <- nms[grepl("treat|^group|^rand|condition|^arm|^info|signal|control", nms, ignore.case = TRUE) &
                 !grepl("Time$|order", nms, ignore.case = TRUE)]
  for (v in cands) {
    x <- dn[[v]]; u <- sort(unique(x[!is.na(x)]))
    if (length(u) == 3) {
      tx <- tolower(dc[[v]])
      cat("Treatment candidate", v, ":\n"); print(table(tx, useNA = "ifany"))
      if (any(grepl("74", tx)) && any(grepl("94", tx)))
        return(list(t74 = as.numeric(grepl("74", tx)), treated = grepl("74|94", tx), src = v))
      if (any(grepl("acs", tx)) && any(grepl("cps", tx)))
        return(list(t74 = as.numeric(grepl("acs", tx)), treated = grepl("acs|cps", tx), src = v))
      return(list(t74 = as.numeric(!is.na(x) & x == u[2]), treated = !is.na(x) & x != u[1],
                  src = paste(v, "(guessed coding)")))
    }
  }
  NULL
}
tr <- detect_treat()
if (is.null(tr)) stop("Could not detect treatment variable")
cat("Treatment source:", tr$src, "\n")
T74 <- tr$t74
treated <- tr$treated
treated[is.na(treated)] <- FALSE
control <- !treated
cat("Arms: T74 =", sum(treated & T74 == 1), " T94 =", sum(treated & T74 == 0), " control =", sum(control), "\n")

# ---------------- weights, prior, posterior ----------------
wv <- if ("pweight" %in% names(dn)) "pweight" else find_var(dn, vl, c("pweight", "weight"), NULL, "Time$")
pw <- if (!is.na(wv)) dn[[wv]] else rep(1, nrow(dn))
pw[is.na(pw)] <- 1
cat("Weight var:", wv, "\n")

pv <- if ("prior" %in% names(dn)) "prior" else find_var(dn, vl, c("^prior$", "^prior"), c("prior"), "Time$|incent|order|summary")
prior <- dn[[pv]]
cat("Prior var:", pv, "\n"); print(summary(prior))

pcols <- names(dn)[grepl("^posterior", names(dn), ignore.case = TRUE) &
                     !grepl("Time$|order|version|rand|summary", names(dn), ignore.case = TRUE)]
pcols <- pcols[vapply(pcols, function(v) { x <- dn[[v]]; sum(!is.na(x)) > 20 && median(x, na.rm = TRUE) > 10 }, logical(1))]
cat("Posterior columns:", paste(pcols, collapse = ", "), "\n")
posterior <- rep(NA_real_, nrow(dn))
for (v in pcols) posterior <- ifelse(is.na(posterior), dn[[v]], posterior)
print(summary(posterior))

# ---------------- controls ----------------
has <- function(v) all(v %in% names(dn))
M <- data.frame(waveB = src_wave, T74 = T74, pw = pw, prior = prior, posterior = posterior)
ctrl <- c("waveB")

# female
if (has("female")) {
  M$female <- dn$female
} else {
  gv <- if (has("gender")) "gender" else find_var(dn, vl, c("^gender", "^sex"), c("gender"), "Time$|II")
  tx <- tolower(dc[[gv]])
  if (any(grepl("[a-z]", tx[!is.na(tx)]))) {
    M$female <- ifelse(is.na(tx), NA, as.numeric(grepl("^f|female|woman|women", tx)))
  } else {
    x <- dn[[gv]]; u <- sort(unique(na.omit(x)))
    M$female <- if (all(u %in% c(0, 1))) x else as.numeric(x == u[2])
  }
}
cat("Female share:", mean(M$female, na.rm = TRUE), "\n")
ctrl <- c(ctrl, "female", "prior")

# party
if (has(c("democrat", "indep", "otherpol"))) {
  M$democrat <- dn$democrat; M$indep <- dn$indep; M$otherpol <- dn$otherpol
} else {
  ptv <- find_var(dn, vl, c("^polit", "party", "^pol"), c("democrat|republican|politic"), "Time$")
  tx <- tolower(dc[[ptv]])
  cat("Party var:", ptv, "\n"); print(table(tx, useNA = "ifany"))
  dem <- grepl("democrat", tx); rep_ <- grepl("republican", tx)
  ind <- grepl("independent", tx) & !dem & !rep_
  M$democrat <- as.numeric(dem); M$indep <- as.numeric(ind); M$otherpol <- as.numeric(!dem & !rep_ & !ind)
}
ctrl <- c(ctrl, "democrat", "indep", "otherpol")

# region
if (has(c("midwest", "south", "west"))) {
  M$midwest <- dn$midwest; M$south <- dn$south; M$west <- dn$west
  ctrl <- c(ctrl, "midwest", "south", "west")
} else if (has("region")) {
  M$f_region <- dc$region; ctrl <- c(ctrl, "f_region")
}
# age
if (has(c("age1", "age2", "age3", "age4"))) {
  for (a in paste0("age", 1:4)) M[[a]] <- dn[[a]]
  ctrl <- c(ctrl, paste0("age", 1:4))
} else {
  av <- find_var(dn, vl, c("^age$", "^age"), NULL, "Time$|II")
  if (!is.na(av)) {
    M$f_age <- as.character(cut(dn[[av]], c(-Inf, 24, 34, 44, 54, Inf)))
    ctrl <- c(ctrl, "f_age")
  }
}
# children
if (has("anychildren")) { M$anychildren <- dn$anychildren; ctrl <- c(ctrl, "anychildren") }
# income
if (has("loghhinc")) { M$loghhinc <- dn$loghhinc; ctrl <- c(ctrl, "loghhinc")
} else if (has("hhincome")) { M$f_inc <- dc$hhincome; ctrl <- c(ctrl, "f_inc") }
# education
if (has("associatemore")) { M$associatemore <- dn$associatemore; ctrl <- c(ctrl, "associatemore")
} else {
  ev <- find_var(dn, vl, c("^educ", "degree"), NULL, "Time$")
  if (!is.na(ev)) { M$f_educ <- dc[[ev]]; ctrl <- c(ctrl, "f_educ") }
}
# employment
emp <- c("fulltime", "parttime", "selfemp", "unemployed", "student")
if (has(emp)) {
  for (e in emp) M[[e]] <- dn[[e]]
  ctrl <- c(ctrl, emp)
} else if (has("employment")) { M$f_emp <- dc$employment; ctrl <- c(ctrl, "f_emp") }
cat("Controls:", paste(ctrl, collapse = " + "), "\n")
ctrl_str <- paste(ctrl, collapse = " + ")

# ---------------- outcomes ----------------
get_item <- function(key, name_pats, lab_pats, exclude = excl_default) {
  v <- find_var(dn, vl, name_pats, lab_pats, exclude)
  cat("Item", key, "->", v, if (!is.na(v)) paste0("[", substr(vl[v], 1, 80), "]") else "", "\n")
  if (is.na(v)) return(rep(NA_real_, nrow(dn)))
  x <- dn[[v]]
  x <- orient(x, v, labs)
  print(table(x, useNA = "ifany"))
  x
}
it_large <- get_item("large", c("^large", "gaplarge", "large"), c("are large|large"))
it_problem <- get_item("problem", c("^problem", "wageproblem", "problem"), c("problem"),
                       paste0(excl_default, "|skilled"))
it_gov <- get_item("gov", c("^govmore", "^government", "^gov"), c("government"),
                   paste0(excl_default, "|effective|trust"))
it_quota <- get_item("quota", c("^quota$", "^quota"), c("quota"))
it_aa <- get_item("aa", c("affirm", "antidiscr", "^aa$"), c("affirmative"))
it_leg <- get_item("legislation", c("^legislation$", "^legislation", "equalpay"), c("legislation|equal pay"))
it_tra <- get_item("transparency", c("^transparency$", "^transparency"), c("transparen"))
it_web <- get_item("website", c("website", "^report"), c("website"))
it_cc <- get_item("childcare", c("childcare", "daycare", "fampolicy", "^care"), c("child ?care|day ?care"),
                  paste0(excl_default, "|anychild|nchild|children"))

M$z_large <- zsc(it_large, control)
M$z_problem <- zsc(it_problem, control)
M$z_gov <- zsc(it_gov, control)
M$z_quota <- zsc(it_quota, control)
M$z_aa <- zsc(it_aa, control)
M$z_leg <- zsc(it_leg, control)
z_tra <- zsc(it_tra, control); z_web <- zsc(it_web, control)
M$z_tw <- ifelse(is.na(z_tra), z_web, z_tra)
M$z_cc <- zsc(it_cc, control)

cat("Perception index:\n")
M$perc_idx <- tryCatch(anderson(M[, c("z_large", "z_problem", "z_gov")], control),
                       error = function(e) { cat("index error:", conditionMessage(e), "\n"); NA_real_ })
cat("Policy index:\n")
M$pol_idx <- tryCatch(anderson(M[, c("z_quota", "z_aa", "z_leg", "z_tw", "z_cc")], control),
                      error = function(e) { cat("index error:", conditionMessage(e), "\n"); NA_real_ })

# ---------------- Table 3 / 4: correlates in trimmed control group ----------------
pc <- prior[control]
q <- quantile(pc, c(0.05, 0.95), na.rm = TRUE, type = 2)
cat("Prior 5/95 pct (control):", q, "\n")
M$prior_z <- zsc(prior, control)
trim <- control & !is.na(prior) & prior > q[1] & prior < q[2]
Mt <- M[trim, ]
cat("Trimmed control N:", nrow(Mt), "\n")

m3a <- tryCatch(feols(perc_idx ~ democrat + female + indep + otherpol + waveB, data = Mt,
                      weights = ~pw, vcov = "hetero"), error = function(e) { print(e); NULL })
if (!is.null(m3a)) print(summary(m3a))
setres("perception_index_democrat_table3_panelA_col4", coef(m3a)["democrat"])
setres("perception_index_female_table3_panelA_col4", coef(m3a)["female"])
m3b <- tryCatch(feols(perc_idx ~ prior_z + waveB, data = Mt, weights = ~pw, vcov = "hetero"),
                error = function(e) { print(e); NULL })
setres("perception_index_prior_table3_panelB_col4", coef(m3b)["prior_z"])
setres("n_obs_table3", if (!is.null(m3a)) nobs(m3a) else nrow(Mt))

m4a <- tryCatch(feols(pol_idx ~ democrat + female + indep + otherpol + waveB, data = Mt,
                      weights = ~pw, vcov = "hetero"), error = function(e) { print(e); NULL })
if (!is.null(m4a)) print(summary(m4a))
setres("policy_demand_index_democrat_table4_panelA_col7", coef(m4a)["democrat"])
m4b <- tryCatch(feols(pol_idx ~ prior_z + waveB, data = Mt, weights = ~pw, vcov = "hetero"),
                error = function(e) { print(e); NULL })
setres("policy_demand_index_prior_table4_panelB_col7", coef(m4b)["prior_z"])

# ---------------- Table 5: treatment effects and 2SLS ----------------
refp <- if (sum(!is.na(posterior[control])) > 30) control else treated
M$post_z <- zsc(posterior, refp)
Mtr <- M[treated, ]
cat("Treatment-arm N:", nrow(Mtr), "\n")

fit_ols <- function(y) feols(as.formula(paste(y, "~ T74 +", ctrl_str)), data = Mtr, weights = ~pw, vcov = "hetero")
fit_iv <- function(y) feols(as.formula(paste(y, "~", ctrl_str, "| post_z ~ T74")), data = Mtr,
                            weights = ~pw, vcov = "hetero")

setres("first_stage_posterior_raw_t74_table5_panelA_col1", coef(fit_ols("posterior"))["T74"])
setres("first_stage_posterior_z_t74_table5_panelA_col2", coef(fit_ols("post_z"))["T74"])
setres("perception_index_t74_table5_panelA_col6", coef(fit_ols("perc_idx"))["T74"])
setres("iv_affirmative_action_posterior_table5_panelC_col2", coef(fit_iv("z_aa"))["fit_post_z"])
setres("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(fit_iv("z_leg"))["fit_post_z"])
setres("iv_policy_demand_index_posterior_table5_panelC_col7", coef(fit_iv("pol_idx"))["fit_post_z"])

# ---------------- Table 6: follow-up ----------------
fu <- tryCatch({
  fn <- bind_rows(conv_num(FA), conv_num(FB))
  fc <- bind_rows(conv_chr(FA), conv_chr(FB))
  flabs <- merge_labs(get_labs(FA), get_labs(FB))
  fvA <- get_vlab(FA); fvB <- get_vlab(FB)
  fvl <- c(fvA, fvB[setdiff(names(fvB), names(fvA))])
  cat("Follow-up N:", nrow(fn), "\n")
  for (n in names(fn)) cat("  FU", n, ":", substr(fvl[n], 1, 90), "\n")

  # treatment via panelID merge
  key_s1 <- names(dn)[tolower(names(dn)) == "panelid"]
  if (!length(key_s1)) key_s1 <- names(dn)[grepl("panel", names(dn), ignore.case = TRUE)]
  fT74 <- rep(NA_real_, nrow(fn))
  if (length(key_s1) && "panelID" %in% names(fc)) {
    k1 <- trimws(dc[[key_s1[1]]]); k2 <- trimws(fc$panelID)
    idx <- match(k2, k1)
    cat("Follow-up matched to Stage I:", sum(!is.na(idx)), "\n")
    fT74 <- T74[idx]
    ftr <- treated[idx]
    fT74[!is.na(ftr) & !ftr] <- NA
  }
  if (sum(!is.na(fT74)) < 100 && "rand" %in% names(fn)) {
    cat("Falling back to Stage II 'rand'\n"); print(table(fc$rand, useNA = "ifany"))
    tx <- tolower(fc$rand)
    if (any(grepl("74", tx))) fT74 <- as.numeric(grepl("74", tx)) else {
      u <- sort(unique(na.omit(fn$rand))); fT74 <- as.numeric(fn$rand == u[1])
    }
  }
  cat("Follow-up T74 table:\n"); print(table(fT74, useNA = "ifany"))

  coalesce_cols <- function(a, b) {
    x <- if (a %in% names(fn)) fn[[a]] else rep(NA_real_, nrow(fn))
    if (!is.null(b) && b %in% names(fn)) x <- ifelse(is.na(x), fn[[b]], x)
    x
  }
  wp <- paste0("wageproblemSQ00", 1:4)
  wl <- tolower(fvl[wp]); wl[is.na(wl)] <- ""
  hi_i <- which(grepl("high", wl)); lo_i <- which(grepl("low", wl))
  hi_v <- if (length(hi_i)) wp[hi_i[1]] else wp[2]
  lo_v <- if (length(lo_i)) wp[lo_i[1]] else wp[3]
  rest <- setdiff(wp, c(hi_v, lo_v))
  pr_v <- rest[1]
  cat("FU items: problem =", pr_v, " high =", hi_v, " low =", lo_v, " gov = govwomen\n")
  mk <- function(v) {
    x <- coalesce_cols(v, sub("wageproblem", "wageproblem2", v))
    orient(x, v, flabs)
  }
  f_prob <- mk(pr_v); f_hi <- mk(hi_v); f_lo <- mk(lo_v)
  f_gov <- orient(fn$govwomen, "govwomen", flabs)
  allref <- rep(TRUE, nrow(fn))
  Zf <- data.frame(zsc(f_prob, allref), zsc(f_gov, allref), zsc(f_hi, allref), zsc(f_lo, allref))
  F <- data.frame(T74 = fT74, idx = anderson(Zf, allref),
                  pw = if ("pweight" %in% names(fn)) fn$pweight else 1)
  fctrl_cand <- c("wave", "gender", "prior", "midwest", "south", "west", "age1", "age2", "age3", "age4",
                  "anychildren", "loghhinc", "associatemore", "fulltime", "parttime", "selfemp",
                  "unemployed", "student", "democrat", "indep", "otherpol")
  fctrl <- fctrl_cand[fctrl_cand %in% names(fn)]
  for (v in fctrl) F[[v]] <- fn[[v]]
  F$pw[is.na(F$pw)] <- 1
  fm <- feols(as.formula(paste("idx ~ T74 +", paste(fctrl, collapse = " + "))), data = F,
              weights = ~pw, vcov = "hetero")
  print(summary(fm))
  coef(fm)["T74"]
}, error = function(e) { cat("Follow-up error:", conditionMessage(e), "\n"); NA_real_ })
setres("followup_perception_index_t74_table6_panelA_col7", fu)

# ---------------- output ----------------
nm_order <- c("perception_index_democrat_table3_panelA_col4",
              "perception_index_female_table3_panelA_col4",
              "perception_index_prior_table3_panelB_col4",
              "n_obs_table3",
              "policy_demand_index_democrat_table4_panelA_col7",
              "policy_demand_index_prior_table4_panelB_col7",
              "first_stage_posterior_raw_t74_table5_panelA_col1",
              "first_stage_posterior_z_t74_table5_panelA_col2",
              "perception_index_t74_table5_panelA_col6",
              "iv_affirmative_action_posterior_table5_panelC_col2",
              "iv_equal_pay_legislation_posterior_table5_panelC_col3",
              "iv_policy_demand_index_posterior_table5_panelC_col7",
              "followup_perception_index_t74_table6_panelA_col7")
for (n in nm_order) {
  v <- res[[n]]
  if (is.null(v)) v <- NA_real_
  cat(sprintf("RESULT:%s=%s\n", n, ifelse(is.na(v), "NA", format(v, digits = 10))))
}