suppressPackageStartupMessages({
  library(fixest)
  library(haven)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))
agg <- as.data.frame(data.all)
sv <- as.data.frame(survey_raw)

res <- list()
emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v[1])) cat(sprintf("RESULT:%s=NA\n", name))
  else cat(sprintf("RESULT:%s=%.6f\n", name, v[1]))
}

norm <- function(x) gsub("[^a-z0-9]", "", tolower(as.character(x)))

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x, levels = "labels")
  if (is.factor(x)) x <- as.character(x)
  x
}

to01 <- function(x) {
  x <- to_chr(x)
  if (is.character(x)) {
    s <- tolower(trimws(x))
    num <- suppressWarnings(as.numeric(s))
    if (all(is.na(s) | s == "" | !is.na(num))) {
      x <- num
    } else {
      out <- rep(NA_real_, length(s))
      out[grepl("^(yes|y|true|voted|treat|treated|treatment|assigned|attended|1)", s)] <- 1
      out[grepl("^(no|n|false|did not|didn|not|control|none|0)", s)] <- 0
      return(out)
    }
  }
  x <- as.numeric(x)
  v <- unique(x[!is.na(x)])
  if (all(v %in% c(0, 1))) return(x)
  if (all(v %in% c(1, 2))) return(ifelse(x == 1, 1, 0))
  x[!(x %in% c(0, 1))] <- NA
  x
}

likert <- function(x) {
  if (inherits(x, "haven_labelled")) {
    labs <- attr(x, "labels")
    xv <- as.numeric(zap_labels(x))
    if (!is.null(labs) && length(labs) > 0) {
      bad <- labs[grepl("know|refus|answer|^dk|^na$|n/a|no opinion", tolower(names(labs)))]
      if (length(bad) > 0) xv[xv %in% as.numeric(bad)] <- NA
      ok <- labs[!(labs %in% bad)]
      if (length(ok) >= 2) {
        lo <- names(ok)[which.min(ok)]
        lo <- tolower(lo)
        if (grepl("agree", lo) && !grepl("disagree", lo)) {
          rng <- range(as.numeric(ok))
          xv <- rng[1] + rng[2] - xv
        }
      }
    }
    return(xv)
  }
  if (is.factor(x) || is.character(x)) {
    s <- tolower(trimws(as.character(x)))
    num <- suppressWarnings(as.numeric(s))
    if (sum(!is.na(num)) >= sum(!is.na(s) & s != "") * 0.9) {
      x <- num
    } else {
      out <- rep(NA_real_, length(s))
      out[grepl("strongly disagree", s)] <- 1
      out[is.na(out) & grepl("disagree", s)] <- 2
      out[is.na(out) & grepl("neither|neutral|undecided|unsure", s)] <- 3
      out[is.na(out) & grepl("strongly agree", s)] <- 5
      out[is.na(out) & grepl("agree", s)] <- 4
      return(out)
    }
  }
  x <- as.numeric(x)
  v <- x[!is.na(x)]
  if (length(v) > 0 && mean(v <= 5) > 0.8) x[x %in% c(8, 9, 88, 97, 98, 99)] <- NA
  x
}

pct <- function(x) { x <- as.numeric(x); if (max(x, na.rm = TRUE) <= 1.0001) x * 100 else x }

## ---------------- Barangay level ----------------
agg$Z <- to01(agg$assignment)
agg$cityn <- norm(to_chr(agg$city))
agg$brgyn <- norm(to_chr(agg$barangay))

sa <- if ("share.akbayan" %in% names(agg)) as.numeric(agg$share.akbayan) else rep(NA, nrow(agg))
su <- if ("share.umalabka" %in% names(agg)) as.numeric(agg$share.umalabka) else rep(NA, nrow(agg))

pt_raw <- to_chr(agg$partytreat)
pt_s <- tolower(as.character(pt_raw))
codemap <- NULL
if (any(grepl("ak", pt_s), na.rm = TRUE)) {
  agg$party <- ifelse(grepl("ak", pt_s), "A", ifelse(grepl("um|ul|ma", pt_s), "U", NA))
} else {
  tb <- table(pt_s)
  levs <- names(tb)
  if (length(levs) == 2 && any(tb == 18) && any(tb == 21)) {
    alev <- levs[tb == 18]
  } else {
    sc <- sapply(levs, function(l) {
      i <- pt_s == l
      mean(sa[i], na.rm = TRUE) / mean(sa, na.rm = TRUE) - mean(su[i], na.rm = TRUE) / mean(su, na.rm = TRUE)
    })
    alev <- levs[which.max(sc)]
  }
  agg$party <- ifelse(pt_s == alev, "A", ifelse(is.na(pt_s), NA, "U"))
  codemap <- c(setNames("A", alev), setNames(rep("U", length(setdiff(levs, alev))), setdiff(levs, alev)))
}
# city-level party (constant within city)
city_party <- tapply(agg$party, agg$cityn, function(z) names(sort(table(z), decreasing = TRUE))[1])

sa_p <- if (all(is.na(sa))) sa else pct(sa)
su_p <- if (all(is.na(su))) su else pct(su)
agg$vshare <- ifelse(agg$party == "A", sa_p, ifelse(agg$party == "U", su_p, NA))
if (any(is.na(agg$vshare)) && "share.treated" %in% names(agg)) {
  st <- pct(agg$share.treated)
  agg$vshare[is.na(agg$vshare)] <- st[is.na(agg$vshare)]
}

turn <- as.numeric(agg$turnout.party)
if (max(turn, na.rm = TRUE) > 100 && all(c("vote.num.party", "reg.num") %in% names(agg))) {
  turn <- as.numeric(agg$vote.num.party) / as.numeric(agg$reg.num) * 100
}
agg$turn <- pct(turn)

fit_coef <- function(fml, data, w = NULL) {
  m <- if (is.null(w)) feols(fml, data = data) else feols(fml, data = data, weights = w)
  list(b = unname(coef(m)["Z"]), n = nobs(m))
}

r <- tryCatch(fit_coef(turn ~ Z | cityn, agg), error = function(e) NULL)
res$itt_turnout_barangay_table1_col1 <- if (!is.null(r)) r$b else NA
res$n_obs_barangay_table1_cols1_2 <- if (!is.null(r)) r$n else sum(!is.na(agg$turn))

r <- tryCatch(fit_coef(vshare ~ Z | cityn, agg), error = function(e) NULL)
res$itt_vote_overall_barangay_table1_col2 <- if (!is.null(r)) r$b else NA
if (is.null(res$n_obs_barangay_table1_cols1_2) || is.na(res$n_obs_barangay_table1_cols1_2)) res$n_obs_barangay_table1_cols1_2 <- if (!is.null(r)) r$n else NA

dA <- agg[agg$party %in% "A", ]
dU <- agg[agg$party %in% "U", ]
r <- tryCatch(fit_coef(vshare ~ Z | cityn, dA), error = function(e) NULL)
res$itt_vote_akbayan_barangay_table1_col3 <- if (!is.null(r)) r$b else NA
res$n_obs_barangay_akbayan_table1_col3 <- if (!is.null(r)) r$n else nrow(dA)
r <- tryCatch(fit_coef(vshare ~ Z | cityn, dU), error = function(e) NULL)
res$itt_vote_umalabka_barangay_table1_col4 <- if (!is.null(r)) r$b else NA
res$n_obs_barangay_umalabka_table1_col4 <- if (!is.null(r)) r$n else nrow(dU)

## ---------------- Individual level ----------------
sv$Z <- to01(sv$assignment)
sv$cityn <- norm(to_chr(sv$city))
sv$brgyn <- norm(to_chr(sv$barangay))

# party of municipality
sp <- tolower(as.character(to_chr(sv$partytreat)))
if (any(grepl("ak", sp), na.rm = TRUE)) {
  sv$party <- ifelse(grepl("ak", sp), "A", ifelse(grepl("um|ul|ma", sp), "U", NA))
} else {
  sv$party <- unname(city_party[sv$cityn])
  if (mean(is.na(sv$party)) > 0.2 && !is.null(codemap)) sv$party <- unname(codemap[sp])
}
# fill from city mapping where still missing
miss <- is.na(sv$party)
if (any(miss)) sv$party[miss] <- unname(city_party[sv$cityn[miss]])

# exclusions: three municipalities lacking both treatment and control samples
excl <- grepl("imus|pateros|santamaria|stamaria", sv$cityn)
sv <- sv[!excl, ]
var_ok <- tapply(sv$Z, sv$cityn, function(z) length(unique(z[!is.na(z)])) == 2)
sv <- sv[sv$cityn %in% names(var_ok)[var_ok], ]

# turnout
tvar <- if ("turnout_pl" %in% names(sv)) "turnout_pl" else "turnout_all"
sv$turnout <- to01(sv[[tvar]])
if (all(is.na(sv$turnout)) && "turnout_all" %in% names(sv)) sv$turnout <- to01(sv$turnout_all)
sv <- sv[!is.na(sv$turnout), ]

# vote for treating party
va <- if ("vote.akbayan" %in% names(sv)) to01(sv$vote.akbayan) else rep(NA, nrow(sv))
vu <- if ("vote.umalabka" %in% names(sv)) to01(sv$vote.umalabka) else rep(NA, nrow(sv))
sv$vtreat <- ifelse(sv$party == "A", va, ifelse(sv$party == "U", vu, NA))
if ("vote" %in% names(sv)) {
  vv <- to01(sv$vote)
  fill <- is.na(sv$vtreat) & sv$turnout == 1
  sv$vtreat[fill] <- vv[fill]
}
# voters who turned out but no vote recorded for the treating party -> 0
sv$vtreat[is.na(sv$vtreat) & sv$turnout == 1 & !is.na(sv$party) &
            ((sv$party == "A" & all(is.na(va)) == FALSE) | (sv$party == "U" & all(is.na(vu)) == FALSE))] <- NA

# attendance weights
sv$att <- if ("attendance" %in% names(sv)) to01(sv$attendance) else rep(NA, nrow(sv))
sv$att[is.na(sv$att)] <- 0
ap <- as.numeric(agg$att.prop)
ap[is.na(ap)] <- 0
if (max(ap, na.rm = TRUE) > 1) ap <- ap / 100
agg$ap <- ap
key_agg <- paste(agg$cityn, agg$brgyn)
key_sv <- paste(sv$cityn, sv$brgyn)
sv$ap <- agg$ap[match(key_sv, key_agg)]
um <- is.na(sv$ap)
if (any(um)) {
  bcount <- table(agg$brgyn)
  uniq <- names(bcount)[bcount == 1]
  idx <- match(sv$brgyn[um], agg$brgyn)
  idx[!(sv$brgyn[um] %in% uniq)] <- NA
  sv$ap[um] <- agg$ap[idx]
}
sv$w <- 1
for (b in unique(sv$brgyn)) {
  i <- which(sv$brgyn == b)
  if (length(i) == 0) next
  pa <- suppressWarnings(max(sv$ap[i], na.rm = TRUE))
  if (!is.finite(pa) || pa <= 0) next
  ps <- mean(sv$att[i])
  if (ps <= 0 || ps >= 1) next
  sv$w[i] <- ifelse(sv$att[i] == 1, pa / ps, (1 - pa) / (1 - ps))
}

## Unweighted vote ITT (Table F.1)
dv <- sv[sv$turnout == 1 & !is.na(sv$vtreat), ]
dv$y <- dv$vtreat * 100
r <- tryCatch(fit_coef(y ~ Z | cityn, dv), error = function(e) NULL)
res$itt_vote_overall_unweighted_tableF1_col2 <- if (!is.null(r)) r$b else NA
r <- tryCatch(fit_coef(y ~ Z | cityn, dv[dv$party %in% "A", ]), error = function(e) NULL)
res$itt_vote_akbayan_unweighted_tableF1_col3 <- if (!is.null(r)) r$b else NA

## Attitude indices (Anderson 2008)
anderson <- function(M, ctrl) {
  M <- as.matrix(M)
  Zs <- M
  for (j in seq_len(ncol(M))) {
    mu <- mean(M[ctrl, j], na.rm = TRUE); s <- sd(M[ctrl, j], na.rm = TRUE)
    Zs[, j] <- (M[, j] - mu) / s
  }
  S <- cov(Zs, use = "pairwise.complete.obs")
  Si <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  wt <- rowSums(Si)
  idx <- apply(Zs, 1, function(z) {
    ok <- !is.na(z)
    if (!any(ok)) return(NA_real_)
    sum(wt[ok] * z[ok]) / sum(wt[ok])
  })
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}

pick <- function(cands) { h <- cands[cands %in% names(sv)]; if (length(h)) h[1] else NA }
gender_items <- c(pick(c("femhouse", "female.rep", "femrep")), pick(c("fempol", "female.pol")),
                  pick("equality"), pick("discrimination"), pick("harassment"))
gender_items <- gender_items[!is.na(gender_items)]
pov_items <- c(pick("poverty"), pick("gap"), pick("cct"), pick("corruption"))
pov_items <- pov_items[!is.na(pov_items)]

index_itt <- function(items, pty) {
  d <- sv[sv$party %in% pty & !is.na(sv$Z), ]
  M <- sapply(items, function(v) likert(d[[v]]))
  if (is.null(dim(M))) M <- matrix(M, ncol = length(items))
  ctrl <- d$Z == 0
  d$idx <- anderson(M, ctrl)
  d <- d[!is.na(d$idx), ]
  m <- feols(idx ~ Z | cityn, data = d, weights = ~w, cluster = ~brgyn)
  unname(coef(m)["Z"])
}
res$itt_poverty_index_akbayan_tableC3 <- tryCatch(index_itt(pov_items, "A"), error = function(e) NA)
res$itt_poverty_index_umalabka_tableC3 <- tryCatch(index_itt(pov_items, "U"), error = function(e) NA)
res$itt_gender_index_akbayan_tableC4 <- tryCatch(index_itt(gender_items, "A"), error = function(e) NA)
res$itt_gender_index_umalabka_tableC4 <- tryCatch(index_itt(gender_items, "U"), error = function(e) NA)

nm <- c("itt_turnout_barangay_table1_col1", "itt_vote_overall_barangay_table1_col2",
        "itt_vote_akbayan_barangay_table1_col3", "itt_vote_umalabka_barangay_table1_col4",
        "n_obs_barangay_table1_cols1_2", "n_obs_barangay_akbayan_table1_col3",
        "n_obs_barangay_umalabka_table1_col4", "itt_poverty_index_akbayan_tableC3",
        "itt_poverty_index_umalabka_tableC3", "itt_gender_index_akbayan_tableC4",
        "itt_gender_index_umalabka_tableC4", "itt_vote_overall_unweighted_tableF1_col2",
        "itt_vote_akbayan_unweighted_tableF1_col3")
for (n in nm) emit(n, if (is.null(res[[n]])) NA else res[[n]])
