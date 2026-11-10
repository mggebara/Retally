suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(width = 200, warn = 1)

root <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy.script-free"
dp <- function(f) file.path(root, "data", f)

res <- list()
put <- function(nm, v) {
  v <- suppressWarnings(as.numeric(v)[1])
  if (length(v) == 1 && is.finite(v)) res[[nm]] <<- v
}
safe <- function(expr, what) tryCatch(expr, error = function(e) {
  cat("ERROR in", what, ":", conditionMessage(e), "\n"); NULL
})

# ---------------------------------------------------------------- helpers
getlab <- function(x) { l <- attr(x, "label"); if (is.null(l)) "" else as.character(l)[1] }
unlab <- function(x) if (inherits(x, "haven_labelled")) zap_labels(x) else x
nonempty <- function(x) {
  x <- unlab(x)
  if (is.character(x)) !is.na(x) & trimws(x) != "" else !is.na(x)
}
num <- function(x) {
  x <- unlab(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    x[!is.na(x) & trimws(x) == ""] <- NA
    y <- suppressWarnings(as.numeric(x))
    if (sum(!is.na(y)) < 0.5 * sum(!is.na(x))) y <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", x)))
    return(y)
  }
  as.numeric(x)
}
seen <- function(x) { v <- num(x); !is.na(v) & v > 0 }
txt <- function(x) {
  if (inherits(x, "haven_labelled")) return(tolower(trimws(as.character(as_factor(x, levels = "both")))))
  tolower(trimws(as.character(unlab(x))))
}
fac <- function(x) { x <- as.character(x); x[is.na(x) | x == ""] <- "NA"; factor(x) }
coalesce_num <- function(df, cols) {
  out <- rep(NA_real_, nrow(df))
  for (cc in cols) { v <- num(df[[cc]]); out[is.na(out)] <- v[is.na(out)] }
  out
}
keyfun <- function(x) {
  x <- unlab(x)
  if (is.numeric(x)) {
    return(ifelse(is.na(x), NA_character_,
                  ifelse(abs(x - round(x)) < 1e-9, sprintf("%.0f", x), as.character(x))))
  }
  out <- trimws(as.character(x)); out[!is.na(out) & out == ""] <- NA; out
}
zc <- function(x, ref) {
  m <- mean(x[ref], na.rm = TRUE); s <- sd(x[ref], na.rm = TRUE)
  (x - m) / s
}
anderson <- function(Z, ref) {
  Z <- as.matrix(Z)
  keep <- colSums(!is.na(Z[ref, , drop = FALSE])) > 10
  cat("Index items used:", paste(colnames(Z)[keep], collapse = ", "), "\n")
  Z <- Z[, keep, drop = FALSE]
  S0 <- cov(Z[ref, , drop = FALSE], use = "pairwise.complete.obs")
  w <- rowSums(solve(S0))
  idx <- apply(Z, 1, function(z) { ok <- !is.na(z); if (!any(ok)) NA_real_ else sum(w[ok] * z[ok]) / sum(w[ok]) })
  zc(idx, ref)
}
item_val <- function(x, ref = NULL) {
  v <- num(x); vl <- attr(x, "labels")
  if (!is.null(vl) && length(vl) >= 2) {
    bad <- grepl("know|prefer not|no answer|not sure|n/a", names(vl), ignore.case = TRUE)
    v[v %in% unclass(vl[bad])] <- NA
    vl <- vl[!bad]
    vl <- vl[order(unclass(vl))]
    if (length(vl) >= 2) {
      lo <- tolower(names(vl)[1]); hi <- tolower(names(vl)[length(vl)])
      neg <- "disagree|oppose|not |small|none|never|against|^no\\b|less"
      pos <- "agree|support|large|yes|definitely|favou?r|more|very"
      if (grepl(pos, lo) && !grepl(neg, lo)) return(-v)
      if (grepl(neg, lo) || (grepl(pos, hi) && !grepl(neg, hi))) return(v)
    }
  }
  if (!is.null(ref) && any(!is.na(ref))) {
    cc <- suppressWarnings(cor(v, ref, use = "complete.obs"))
    if (is.finite(cc) && cc < 0) return(-v)
  }
  v
}
find_var <- function(df, pats, exclude = "Time$|order$", taken = character(0), exl_lab = NULL, min_n = 30) {
  nm <- names(df)
  labs <- vapply(nm, function(v) getlab(df[[v]]), "")
  cnt <- vapply(nm, function(v) sum(nonempty(df[[v]])), 0)
  ok <- !grepl(exclude, nm, perl = TRUE) & !(nm %in% taken) & cnt >= min_n
  if (!is.null(exl_lab)) ok <- ok & !grepl(exl_lab, labs, ignore.case = TRUE)
  for (i in seq_along(pats)) {
    tgt <- if (names(pats)[i] == "n") nm else labs
    h <- nm[ok & grepl(pats[[i]], tgt, ignore.case = TRUE, perl = TRUE)]
    if (length(h)) return(h[1])
  }
  NA_character_
}
find_by_values <- function(df, pat) {
  out <- character(0); cv <- numeric(0)
  for (v in names(df)) {
    if (grepl("Time$", v)) next
    x <- df[[v]]
    vals <- names(attr(x, "labels"))
    xx <- unlab(x)
    if (is.character(xx)) { u <- unique(xx); if (length(u) <= 30) vals <- c(vals, u) }
    vals <- tolower(vals[!is.na(vals)])
    if (length(vals) && any(grepl(pat, vals))) { out <- c(out, v); cv <- c(cv, sum(nonempty(x))) }
  }
  out[order(-cv)]
}
describe <- function(df, tag) {
  cat("\n=== DATA", tag, ":", nrow(df), "x", ncol(df), "===\n")
  tcols <- grep("Time$", names(df), value = TRUE)
  for (v in setdiff(names(df), tcols)) {
    x <- df[[v]]; vl <- attr(x, "labels"); xx <- unlab(x)
    u <- unique(xx[nonempty(xx)])
    ex <- tryCatch(substr(paste(head(as.character(u), 6), collapse = "|"), 1, 60), error = function(e) "?")
    vls <- if (!is.null(vl)) paste0(" {", substr(paste(paste0(unclass(vl), "=", names(vl)), collapse = "; "), 1, 150), "}") else ""
    cat(sprintf("%s n=%d nu=%d L=%s V=%s%s\n", v, sum(nonempty(xx)), length(u),
                substr(getlab(x), 1, 100), ex, vls))
  }
  if (length(tcols)) {
    sh <- sapply(tcols, function(v) round(mean(seen(df[[v]])), 2))
    cat("Time cols seen-share:", paste0(tcols, "=", sh, collapse = " "), "\n")
  }
}

# ---------------------------------------------------------------- treatment detection
detect_arm <- function(df, post, prior, tag) {
  n <- nrow(df); nm <- names(df)
  ctrl <- NULL
  for (cn in intersect(c("controlgroupnoteTime", "controlgroupnote", "controlgroupnotenoinTime", "controlgroupnotenoin"), nm)) {
    f <- if (grepl("Time$", cn)) seen(df[[cn]]) else nonempty(df[[cn]])
    sh <- mean(f); cat(tag, "control flag", cn, "share", round(sh, 3), "\n")
    if (sh > 0.1 && sh < 0.6) ctrl <- if (is.null(ctrl)) f else (ctrl | f)
  }
  if (!is.null(ctrl)) cat(tag, "control share used:", round(mean(ctrl), 3), "\n")
  arm <- rep(NA_character_, n)
  best <- NULL; bestsc <- -Inf
  rows <- if (is.null(ctrl)) rep(TRUE, n) else !ctrl
  for (v in nm) {
    x <- df[[v]]
    key <- if (grepl("Time$", v)) ifelse(seen(x), "seen", "unseen") else {
      xx <- unlab(x); ifelse(nonempty(xx), as.character(xx), NA_character_)
    }
    if (!is.null(ctrl)) {
      k <- key[rows]; u <- unique(k[!is.na(k)])
      if (length(u) != 2 || mean(!is.na(k)) < 0.9) next
      sh <- mean(k == u[1], na.rm = TRUE); if (sh < 0.3 || sh > 0.7) next
      g <- ifelse(rows, key, NA_character_)
    } else {
      u <- unique(key[!is.na(key)])
      if (length(u) != 3 || mean(!is.na(key)) < 0.9) next
      if (any(table(key) / sum(!is.na(key)) < 0.2)) next
      g <- key
    }
    m <- tapply(post, g, mean, na.rm = TRUE); m <- m[is.finite(m)]
    if (length(m) < 2) next
    sc <- diff(range(m))
    if (grepl("treat|rand|group|arm|info|acs|cps|74|94|signal|condition", v, ignore.case = TRUE)) sc <- sc + 1
    if (is.finite(sc) && sc > bestsc) { bestsc <- sc; best <- list(v = v, g = g, m = m) }
  }
  if (is.null(best)) {
    cat(tag, "NO treatment variable detected\n")
    if (!is.null(ctrl)) arm[ctrl] <- "C"
    return(arm)
  }
  cat(tag, "treatment split var:", best$v, "| posterior means:", paste(names(best$m), round(best$m, 2), collapse = "; "), "\n")
  g <- best$g; m <- best$m
  if (!is.null(ctrl)) {
    arm[ctrl] <- "C"
    lowg <- names(m)[which.min(m)]
    arm[!ctrl & !is.na(g) & g == lowg] <- "T74"
    arm[!ctrl & !is.na(g) & g != lowg] <- "T94"
  } else {
    dev <- tapply(abs(post - prior), g, mean, na.rm = TRUE)
    cg <- names(dev)[which.min(dev)]
    rest <- setdiff(names(m), cg); lowg <- rest[which.min(m[rest])]
    arm[!is.na(g) & g == cg] <- "C"
    arm[!is.na(g) & g == lowg] <- "T74"
    arm[!is.na(g) & !(g %in% c(cg, lowg))] <- "T94"
  }
  print(table(arm, useNA = "ifany"))
  arm
}

# ---------------------------------------------------------------- Stage I harmonisation
specs <- list(
  large = list(p = list(l = "(gap|differen|wage)[^\\]]{0,80}\\blarge|large[^\\]]{0,40}(gap|differen)", n = "large"), xl = "skill|company|firm"),
  problem = list(p = list(l = "problem", n = "problem"), xl = "skill|high|low"),
  gov = list(p = list(l = "government should|government[^.]{0,60}(mitigat|reduc|effort|more|support)", n = "^gov"), xl = "effective|trust|skill"),
  quota = list(p = list(l = "quota", n = "quota")),
  affirm = list(p = list(l = "affirmative", n = "affirm")),
  legis = list(p = list(n = "^legislation$", l = "equal pay", n = "legislation")),
  transp = list(p = list(n = "^transparency$", l = "transparen", n = "transparen")),
  website = list(p = list(l = "website", n = "website")),
  childcare = list(p = list(l = "child ?care|day ?care", n = "childcare|daycare"))
)

harm1 <- function(df, wB, tag) {
  n <- nrow(df); nm <- names(df)
  o <- data.frame(waveB = rep(wB, n))
  medin <- function(cols, lo, hi) cols[vapply(cols, function(v) {
    m <- suppressWarnings(median(num(df[[v]]), na.rm = TRUE)); is.finite(m) && m >= lo && m <= hi }, TRUE)]
  # prior
  pc <- grep("^prior", nm, value = TRUE, ignore.case = TRUE); pc <- pc[!grepl("Time$|order$", pc)]
  pc <- medin(pc, 30, 150)
  if (!length(pc)) {
    v <- find_var(df, list(n = "^womenwages$", l = "prior", l = "for every \\$ ?100"))
    if (!is.na(v)) pc <- v
  }
  cat(tag, "prior cols:", pc, "\n")
  o$prior <- coalesce_num(df, pc)
  # posterior
  qc <- grep("posterior|^post", nm, value = TRUE, ignore.case = TRUE)
  qc <- qc[!grepl("Time$|order$|postal|postcode|zip", qc, ignore.case = TRUE)]
  qc <- medin(qc, 30, 150)
  cat(tag, "posterior cols:", qc, "\n")
  o$post <- coalesce_num(df, qc)
  ver <- rep(NA_integer_, n)
  for (i in seq_along(qc)) { v <- num(df[[qc[i]]]); ver[is.na(ver) & !is.na(v)] <- i }
  o$postver <- ver
  # arm
  o$arm <- detect_arm(df, o$post, o$prior, tag)
  # female
  if ("female" %in% nm) {
    o$female <- num(df$female)
  } else if ("gender" %in% nm) {
    g <- txt(df$gender); f <- grepl("female|woman|^f$|\\] f$", g)
    if (!any(f)) { gv <- num(df$gender); f <- !is.na(gv) & gv == max(gv, na.rm = TRUE) }
    o$female <- as.numeric(f); o$female[!nonempty(df$gender)] <- NA
  } else o$female <- NA_real_
  # party
  if ("democrat" %in% nm) {
    o$democrat <- num(df$democrat)
    o$indep <- if ("indep" %in% nm) num(df$indep) else NA_real_
    o$otherpol <- if ("otherpol" %in% nm) num(df$otherpol) else NA_real_
    o$pol_f <- ifelse(o$democrat %in% 1, "dem", ifelse(o$indep %in% 1, "ind", ifelse(o$otherpol %in% 1, "oth", "rep")))
  } else {
    pv <- find_by_values(df, "democrat")
    cat(tag, "party vars:", pv, "\n")
    if (length(pv)) {
      p <- txt(df[[pv[1]]])
      dem <- grepl("democrat", p); rep <- grepl("republican", p); ind <- grepl("independent", p)
      if (length(pv) > 1) {
        l <- txt(df[[pv[2]]])
        d2 <- !dem & !rep & grepl("democrat", l); r2 <- !dem & !rep & grepl("republican", l)
        dem <- dem | d2; rep <- rep | r2
      }
      ind <- ind & !dem & !rep
      o$democrat <- as.numeric(dem); o$indep <- as.numeric(ind); o$otherpol <- as.numeric(!dem & !rep & !ind)
      o$pol_f <- ifelse(dem, "dem", ifelse(rep, "rep", ifelse(ind, "ind", "oth")))
      print(table(o$pol_f, useNA = "ifany"))
    } else {
      o$democrat <- NA_real_; o$indep <- NA_real_; o$otherpol <- NA_real_; o$pol_f <- NA_character_
    }
  }
  # region
  o$region_f <- if ("region" %in% nm) txt(df$region) else NA_character_
  # age
  av <- find_var(df, list(n = "^age$", n = "^age", l = "how old|^age|your age"),
                 exclude = "Time$|order$|(?i)(agree|wage|page|average|language|stage)")
  cat(tag, "age var:", av, "\n")
  if (!is.na(av)) {
    a <- num(df[[av]]); md <- suppressWarnings(median(a, na.rm = TRUE))
    o$age_f <- if (isTRUE(md > 17 && md < 70)) as.character(cut(a, c(-Inf, 24, 34, 44, 54, Inf))) else txt(df[[av]])
  } else o$age_f <- NA_character_
  # children
  cvv <- find_var(df, list(n = "^anychildren$", n = "child|kids", l = "children"),
                  exclude = "Time$|order$|(?i)(care)")
  cat(tag, "children var:", cvv, "\n")
  if (!is.na(cvv)) {
    t <- txt(df[[cvv]])
    o$anychild <- if (any(grepl("yes", t))) as.numeric(grepl("yes", t)) else as.numeric(num(df[[cvv]]) > 0)
  } else o$anychild <- NA_real_
  # income
  iv <- find_var(df, list(n = "^loghhinc$", n = "hhincome", n = "income", l = "income"),
                 exclude = "Time$|order$")
  cat(tag, "income var:", iv, "\n")
  o$inc <- if (!is.na(iv)) txt(df[[iv]]) else NA_character_
  # education
  ev <- find_var(df, list(n = "^associatemore$", n = "educ|degree", l = "education|degree|highest"),
                 exclude = "Time$|order$")
  cat(tag, "education var:", ev, "\n")
  o$educ_f <- if (!is.na(ev)) txt(df[[ev]]) else NA_character_
  # employment
  o$emp_f <- if ("employment" %in% nm) txt(df$employment) else NA_character_
  # weights
  wv <- find_var(df, list(n = "^pweight$", n = "weight"), exclude = "Time$|order$")
  cat(tag, "weight var:", wv, "\n")
  o$w <- if (!is.na(wv)) num(df[[wv]]) else 1
  # outcome items
  taken <- character(0)
  exI <- "Time$|order$|(?i)(anchor|note|size|trust|effective|comment|infodemand)"
  for (it in names(specs)) {
    if (it == "transp" && wB == 1) next
    if (it == "website" && wB == 0) next
    sp <- specs[[it]]
    v <- find_var(df, sp$p, exclude = exI, taken = taken, exl_lab = sp$xl)
    cat(tag, "item", it, "->", v, if (!is.na(v)) substr(getlab(df[[v]]), 1, 90) else "", "\n")
    if (!is.na(v)) { taken <- c(taken, v); o[[it]] <- item_val(df[[v]], o$democrat) } else o[[it]] <- NA_real_
  }
  o
}

# ---------------------------------------------------------------- Stage II harmonisation
arm2 <- function(df, tag) {
  post <- if ("posteriorII" %in% names(df)) num(df$posteriorII) else rep(NA_real_, nrow(df))
  best <- NULL; bs <- -Inf
  for (v in grep("rand|treat|t74|group|arm", names(df), value = TRUE, ignore.case = TRUE)) {
    if (grepl("Time$|order", v)) next
    k <- as.character(unlab(df[[v]])); u <- unique(k[!is.na(k)]); if (length(u) != 2) next
    m <- tapply(post, k, mean, na.rm = TRUE); sc <- abs(diff(m))
    if (is.finite(sc) && sc > bs) { bs <- sc; best <- list(v = v, k = k, m = m) }
  }
  if (is.null(best)) { cat(tag, "no follow-up treatment var\n"); return(rep(NA_real_, nrow(df))) }
  cat(tag, "follow-up T74 from", best$v, "posteriorII means", paste(names(best$m), round(best$m, 2), collapse = "; "), "\n")
  as.numeric(best$k == names(best$m)[which.min(best$m)])
}
mk_idmap <- function(raw, harm, F2, tag) {
  if (!("panelID" %in% names(F2))) return(NULL)
  ids <- unique(keyfun(F2$panelID)); ids <- ids[!is.na(ids)]
  best <- NA; bs <- 0
  for (v in names(raw)) {
    if (grepl("Time$", v)) next
    k <- keyfun(raw[[v]])
    if (sum(!is.na(unique(k))) < 0.5 * nrow(raw)) next
    s <- mean(ids %in% k)
    if (s > bs) { bs <- s; best <- v }
  }
  cat(tag, "ID var in Stage I:", best, "match share", round(bs, 3), "\n")
  if (is.na(best) || bs < 0.5) return(NULL)
  k <- keyfun(raw[[best]])
  t74 <- ifelse(harm$arm %in% "T74", 1, ifelse(harm$arm %in% "T94", 0, NA_real_))
  ok <- !is.na(k) & !duplicated(k)
  setNames(t74[ok], k[ok])
}
harm2 <- function(df, wB, idmap, tag) {
  n <- nrow(df); nm <- names(df)
  o <- data.frame(waveB = rep(wB, n))
  cl <- c("gender", "prior", "midwest", "south", "west", "age1", "age2", "age3", "age4", "anychildren",
          "loghhinc", "associatemore", "fulltime", "parttime", "selfemp", "unemployed", "student",
          "democrat", "indep", "otherpol")
  for (cn in cl) {
    if (cn %in% nm) {
      v <- num(df[[cn]]); if (all(is.na(v))) v <- as.numeric(factor(txt(df[[cn]])))
      o[[cn]] <- v
    } else o[[cn]] <- NA_real_
  }
  o$w <- if ("pweight" %in% nm) num(df$pweight) else 1
  o$T74 <- NA_real_
  if (!is.null(idmap) && "panelID" %in% nm) o$T74 <- unname(idmap[keyfun(df$panelID)])
  if (all(is.na(o$T74))) o$T74 <- arm2(df, tag)
  cat(tag, "T74 distribution:\n"); print(table(o$T74, useNA = "ifany"))
  if ("rand" %in% nm) { cat(tag, "T74 x rand:\n"); print(table(o$T74, num(df$rand), useNA = "ifany")) }
  gp <- function(k) {
    cols <- intersect(c(paste0("wageproblemSQ00", k), paste0("wageproblem2SQ00", k)), nm)
    if (!length(cols)) return(list(v = rep(NA_real_, n), lab = ""))
    v <- rep(NA_real_, n)
    for (cc in cols) { x <- item_val(df[[cc]], o$democrat); v[is.na(v)] <- x[is.na(v)] }
    list(v = v, lab = getlab(df[[cols[1]]]))
  }
  wp <- lapply(1:4, gp); labs <- tolower(sapply(wp, `[[`, "lab"))
  cat(tag, "wageproblem labels:", paste(1:4, substr(labs, 1, 80), collapse = " || "), "\n")
  hi <- which(grepl("high", labs))[1]; lo <- which(grepl("low", labs))[1]
  if (is.na(hi) || is.na(lo) || hi == lo) {
    gen <- 1; hi <- 2; lo <- 3
  } else {
    rest <- setdiff(1:4, c(hi, lo))
    pref <- rest[!grepl("large", labs[rest])]
    gen <- if (length(pref)) pref[1] else rest[1]
  }
  cat(tag, "follow-up items: general=SQ", gen, " high=SQ", hi, " low=SQ", lo, "\n")
  o$fu_problem <- wp[[gen]]$v; o$fu_high <- wp[[hi]]$v; o$fu_low <- wp[[lo]]$v
  o$fu_gov <- if ("govwomen" %in% nm) item_val(df$govwomen, o$democrat) else NA_real_
  o
}

ctrl_ok <- function(d, vars) vars[vapply(vars, function(v) {
  if (!(v %in% names(d))) return(FALSE)
  x <- d[[v]]
  sum(!is.na(x)) > 0.8 * nrow(d) && length(unique(x[!is.na(x)])) > 1
}, TRUE)]

# ---------------------------------------------------------------- load
A <- read_dta(dp("SurveyStageI_WaveA_raw.dta"))
B <- read_dta(dp("SurveyStageI_WaveB_raw.dta"))
FA <- read_dta(dp("SurveyStageII_WaveA_raw.dta"))
FB <- read_dta(dp("SurveyStageII_WaveB_raw.dta"))

safe(describe(A, "StageI_WaveA"), "describe A")
safe(describe(B, "StageI_WaveB"), "describe B")
safe(describe(FA, "StageII_WaveA"), "describe FA")
safe(describe(FB, "StageII_WaveB"), "describe FB")

hA <- harm1(A, 0, "[A]")
hB <- harm1(B, 1, "[B]")
S <- bind_rows(hA, hB)
for (v in c("region_f", "age_f", "educ_f", "emp_f", "pol_f", "inc")) if (v %in% names(S)) S[[v]] <- fac(S[[v]])
S$w[is.na(S$w)] <- NA
gc_ <- function(d, v) if (v %in% names(d)) as.numeric(d[[v]]) else rep(NA_real_, nrow(d))
isC <- S$arm %in% "C"
cat("\nArms by wave:\n"); print(table(S$arm, S$waveB, useNA = "ifany"))
if (all(S$w == 1, na.rm = TRUE)) cat("NOTE: no probability weight found in Stage I data; using unit weights\n")

# z-scores on pure control group
for (v in c("large", "problem", "gov", "quota", "affirm", "legis", "childcare")) S[[paste0(v, "_z")]] <- zc(gc_(S, v), isC)
S$tw_z <- ifelse(S$waveB == 0, zc(gc_(S, "transp"), isC & S$waveB == 0), zc(gc_(S, "website"), isC & S$waveB == 1))
S$perc_idx <- safe(anderson(S[, c("large_z", "problem_z", "gov_z")], isC), "perception index")
S$pol_idx <- safe(anderson(S[, c("quota_z", "affirm_z", "legis_z", "tw_z", "childcare_z")], isC), "policy index")

# posterior z-score by version using control-group moments
S$post_z <- NA_real_
for (v in unique(S$postver[!is.na(S$postver)])) {
  r <- S$postver %in% v
  ref <- r & isC
  if (sum(ref & !is.na(S$post)) < 20) ref <- r & S$arm %in% c("T74", "T94")
  S$post_z[r] <- zc(S$post, ref)[r]
}

# ---------------------------------------------------------------- Table 3 / 4
safe({
  q <- quantile(S$prior[isC], c(0.05, 0.95), na.rm = TRUE)
  cat("Control prior 5/95 pct:", q, "\n")
  T3 <- S[isC & !is.na(S$prior) & S$prior > q[1] & S$prior < q[2], ]
  T3$prior_z <- zc(T3$prior, rep(TRUE, nrow(T3)))
  T3 <- T3[!is.na(T3$w), ]
  cat("Table 3 N:", nrow(T3), "\n")
  put("n_obs_table3", nrow(T3))
  m3a <- safe(feols(perc_idx ~ democrat + female + indep + otherpol + waveB, T3, weights = ~w, vcov = "hetero"), "T3A")
  if (!is.null(m3a)) {
    print(summary(m3a))
    put("perception_index_democrat_table3_panelA_col4", coef(m3a)["democrat"])
    put("perception_index_female_table3_panelA_col4", coef(m3a)["female"])
  }
  m3b <- safe(feols(perc_idx ~ prior_z + waveB, T3, weights = ~w, vcov = "hetero"), "T3B")
  if (!is.null(m3b)) { print(summary(m3b)); put("perception_index_prior_table3_panelB_col4", coef(m3b)["prior_z"]) }
  m4a <- safe(feols(pol_idx ~ democrat + female + indep + otherpol + waveB, T3, weights = ~w, vcov = "hetero"), "T4A")
  if (!is.null(m4a)) { print(summary(m4a)); put("policy_demand_index_democrat_table4_panelA_col7", coef(m4a)["democrat"]) }
  m4b <- safe(feols(pol_idx ~ prior_z + waveB, T3, weights = ~w, vcov = "hetero"), "T4B")
  if (!is.null(m4b)) { print(summary(m4b)); put("policy_demand_index_prior_table4_panelB_col7", coef(m4b)["prior_z"]) }
}, "Tables 3-4")

# ---------------------------------------------------------------- Table 5
safe({
  tr <- S[S$arm %in% c("T74", "T94") & !is.na(S$w), ]
  tr$T74 <- as.numeric(tr$arm == "T74")
  cv <- ctrl_ok(tr, c("waveB", "female", "prior", "region_f", "age_f", "anychild", "inc", "educ_f", "emp_f", "pol_f"))
  cat("Table 5 controls:", cv, "\n")
  rhs <- paste(c("T74", cv), collapse = " + ")
  rhs0 <- if (length(cv)) paste(cv, collapse = " + ") else "1"
  m1 <- safe(feols(as.formula(paste("post ~", rhs)), tr, weights = ~w, vcov = "hetero"), "T5 col1")
  if (!is.null(m1)) { cat("T5 col1 N:", nobs(m1), "\n"); print(coeftable(m1)["T74", ]); put("first_stage_posterior_raw_t74_table5_panelA_col1", coef(m1)["T74"]) }
  m2 <- safe(feols(as.formula(paste("post_z ~", rhs)), tr, weights = ~w, vcov = "hetero"), "T5 col2")
  if (!is.null(m2)) { print(coeftable(m2)["T74", ]); put("first_stage_posterior_z_t74_table5_panelA_col2", coef(m2)["T74"]) }
  m6 <- safe(feols(as.formula(paste("perc_idx ~", rhs)), tr, weights = ~w, vcov = "hetero"), "T5 col6")
  if (!is.null(m6)) { print(coeftable(m6)["T74", ]); put("perception_index_t74_table5_panelA_col6", coef(m6)["T74"]) }
  ivs <- list(c("affirm_z", "iv_affirmative_action_posterior_table5_panelC_col2"),
              c("legis_z", "iv_equal_pay_legislation_posterior_table5_panelC_col3"),
              c("pol_idx", "iv_policy_demand_index_posterior_table5_panelC_col7"))
  for (iv in ivs) {
    mi <- safe(feols(as.formula(paste(iv[1], "~", rhs0, "| post_z ~ T74")), tr, weights = ~w, vcov = "hetero"), iv[2])
    if (!is.null(mi)) { cat(iv[2], ":\n"); print(coeftable(mi)["fit_post_z", ]); put(iv[2], coef(mi)["fit_post_z"]) }
  }
}, "Table 5")

# ---------------------------------------------------------------- Table 6 (follow-up)
safe({
  idA <- safe(mk_idmap(A, hA, FA, "[A]"), "idmap A")
  idB <- safe(mk_idmap(B, hB, FB, "[B]"), "idmap B")
  Fd <- bind_rows(harm2(FA, 0, idA, "[FA]"), harm2(FB, 1, idB, "[FB]"))
  Fd <- Fd[!is.na(Fd$T74) & !is.na(Fd$w), ]
  cat("Follow-up N with T74:", nrow(Fd), "\n")
  all1 <- rep(TRUE, nrow(Fd))
  Zf <- sapply(c("fu_problem", "fu_gov", "fu_high", "fu_low"), function(v) zc(Fd[[v]], all1))
  Fd$fu_idx <- anderson(Zf, all1)
  fcv <- ctrl_ok(Fd, c("waveB", "gender", "prior", "midwest", "south", "west", "age1", "age2", "age3", "age4",
                       "anychildren", "loghhinc", "associatemore", "fulltime", "parttime", "selfemp",
                       "unemployed", "student", "democrat", "indep", "otherpol"))
  cat("Follow-up controls:", fcv, "\n")
  mf <- feols(as.formula(paste("fu_idx ~", paste(c("T74", fcv), collapse = " + "))), Fd, weights = ~w, vcov = "hetero")
  cat("T6 N:", nobs(mf), "\n"); print(coeftable(mf)["T74", ])
  put("followup_perception_index_t74_table6_panelA_col7", coef(mf)["T74"])
}, "Table 6")

# ---------------------------------------------------------------- output
cat("\n")
for (nm in c("perception_index_democrat_table3_panelA_col4",
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
             "followup_perception_index_t74_table6_panelA_col7")) {
  if (!is.null(res[[nm]])) cat(sprintf("RESULT:%s=%.6f\n", nm, res[[nm]]))
}
