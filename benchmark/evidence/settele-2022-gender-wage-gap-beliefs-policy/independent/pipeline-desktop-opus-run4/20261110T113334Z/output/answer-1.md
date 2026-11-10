suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(warn = 1)

base <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy.script-free"
res <- list()
setres <- function(name, val) {
  val <- suppressWarnings(as.numeric(val))
  if (length(val) == 1 && is.finite(val)) res[[name]] <<- unname(val)
}

# ---------------------------------------------------------------- helpers
to_num <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  if (is.character(x)) {
    y <- suppressWarnings(as.numeric(gsub("[^0-9.-]", "", x)))
    y[is.na(x) | trimws(x) == ""] <- NA
    return(y)
  }
  suppressWarnings(as.numeric(x))
}

nonempty <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  x <- as.character(x)
  !is.na(x) & trimws(x) != ""
}

lab_text <- function(x) {
  l <- attr(x, "labels")
  raw <- if (inherits(x, "haven_labelled")) zap_labels(x) else x
  raw <- as.character(raw)
  if (is.null(l)) return(tolower(raw))
  out <- names(l)[match(raw, as.character(unname(l)))]
  out[is.na(out)] <- raw[is.na(out)]
  tolower(out)
}

find_name <- function(df, exact) {
  nm <- names(df)
  for (e in exact) {
    hit <- nm[tolower(nm) == tolower(e)]
    if (length(hit)) return(hit[1])
  }
  NA_character_
}

bad_name <- "(time|order|comment|_oth|other)$"
find_col <- function(df, exact = character(0), patterns = character(0), minfrac = 0.2, avoid = character(0)) {
  nm <- names(df)
  ok <- function(h) {
    if (h %in% avoid) return(FALSE)
    if (grepl(bad_name, tolower(h))) return(FALSE)
    v <- to_num(df[[h]])
    mean(!is.na(v)) >= minfrac
  }
  for (e in exact) {
    hit <- nm[tolower(nm) == tolower(e)]
    hit <- hit[vapply(hit, ok, logical(1))]
    if (length(hit)) return(hit[1])
  }
  for (p in patterns) {
    hit <- nm[grepl(p, nm, ignore.case = TRUE)]
    hit <- hit[vapply(hit, ok, logical(1))]
    if (length(hit)) return(hit[1])
  }
  NA_character_
}

orient <- function(x) {
  v <- to_num(x)
  l <- attr(x, "labels")
  if (!is.null(l) && length(l) >= 2) {
    ln <- tolower(names(l)); lv <- to_num(unname(l))
    dk <- grepl("know|prefer not|n/a|no answer|refuse", ln)
    v[v %in% lv[dk & !is.na(lv)]] <- NA
    keep <- !dk & !is.na(lv); ln <- ln[keep]; lv <- lv[keep]
    if (length(lv) >= 2) {
      lmin <- ln[which.min(lv)]; lmax <- ln[which.max(lv)]
      neg <- "disagree|oppose|not |^no|small|less|decrease|never|none|fewer"
      if (grepl(neg, lmax) && !grepl(neg, lmin)) v <- max(lv) + min(lv) - v
    }
  }
  v
}

coalesce_vec <- function(a, b) { a[is.na(a)] <- b[is.na(a)]; a }

inc_from <- function(x) {
  v <- to_num(x); l <- attr(x, "labels")
  if (!is.null(l)) {
    ln <- names(l); lv <- to_num(unname(l))
    mids <- sapply(ln, function(s) {
      s2 <- gsub(",", "", s)
      nums <- as.numeric(regmatches(s2, gregexpr("[0-9]+(\\.[0-9]+)?", s2))[[1]])
      if (grepl("[0-9]k", tolower(s2))) nums <- nums * 1000
      if (length(nums) >= 2) mean(nums[1:2])
      else if (length(nums) == 1) { if (grepl("less|under|below|<", tolower(s2))) nums / 2 else nums * 1.25 }
      else NA_real_
    })
    out <- unname(mids)[match(v, lv)]
    if (sum(!is.na(out)) > 0.5 * sum(!is.na(v))) return(log(pmax(out, 1)))
  }
  if (isTRUE(median(v, na.rm = TRUE) > 1000)) log(pmax(v, 1)) else v
}

scan_group <- function(df, y, k, subset = rep(TRUE, nrow(df))) {
  skip <- "prior|post|womenwages|time$|order$|weight|date|seed|^ipaddr|lastpage|startlang|submit|refurl|^id$|panelid|token|controlgroupnote"
  best <- NA_character_; bestr2 <- -1
  for (h in names(df)) {
    if (grepl(skip, tolower(h))) next
    x <- df[[h]]; if (inherits(x, "haven_labelled")) x <- zap_labels(x)
    x <- as.character(x); x[!is.na(x) & trimws(x) == ""] <- NA
    x[!subset] <- NA
    if (mean(!is.na(x[subset])) < 0.9) next
    u <- unique(x[!is.na(x)]); if (length(u) != k) next
    sel <- !is.na(x) & !is.na(y)
    if (sum(sel) < 50) next
    cnt <- table(x[sel]); if (min(cnt) < 0.1 * sum(sel)) next
    m <- tapply(y[sel], x[sel], mean); yb <- mean(y[sel])
    r2 <- sum(as.numeric(cnt[names(m)]) * (m - yb)^2) / sum((y[sel] - yb)^2)
    if (is.finite(r2) && r2 > bestr2) { bestr2 <- r2; best <- h }
  }
  list(col = best, r2 = bestr2)
}

as_chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  x <- as.character(x); x[!is.na(x) & trimws(x) == ""] <- NA; x
}

# ---------------------------------------------------------------- Stage I builder
build1 <- function(df, waveB) {
  n <- nrow(df)
  cat("# ---- Stage I wave", ifelse(waveB == 1, "B", "A"), "N =", n, "\n")
  cat("# columns:", paste(names(df), collapse = " "), "\n")
  out <- data.frame(waveB = rep(waveB, n))

  pidc <- find_name(df, c("panelID", "panelid", "pid", "token", "id"))
  out$pid <- if (!is.na(pidc)) trimws(as_chr(df[[pidc]])) else NA_character_

  pc <- find_col(df, c("prior", "priorbelief", "womenwages", "prior1"), c("^prior"), 0.5)
  out$prior <- if (!is.na(pc)) to_num(df[[pc]]) else NA_real_
  cat("# prior column:", pc, "\n")

  nm <- names(df)
  pnames <- nm[grepl("^posterior|^post[0-9_]|^post$|^womenwages.+", nm, ignore.case = TRUE) &
                 !grepl("time|order|anchor", tolower(nm))]
  pnames <- setdiff(pnames, pc)
  pnames <- pnames[vapply(pnames, function(h) mean(!is.na(to_num(df[[h]]))) > 0.03, logical(1))]
  post <- rep(NA_real_, n)
  for (h in pnames) post <- coalesce_vec(post, to_num(df[[h]]))
  out$post <- post
  cat("# posterior columns:", paste(pnames, collapse = " "), " nonmissing:", sum(!is.na(post)), "\n")

  # treatment groups
  cgn <- NULL
  for (cn in c("controlgroupnote", "controlgroupnotenoin")) {
    if (cn %in% names(df)) cgn <- if (is.null(cgn)) nonempty(df[[cn]]) else (cgn | nonempty(df[[cn]]))
  }
  grp <- rep(NA_character_, n)
  sc <- scan_group(df, post, 3)
  cat("# 3-level group scan:", sc$col, "R2 =", sc$r2, "\n")
  if (!is.na(sc$col) && sc$r2 > 0.01) {
    x <- as_chr(df[[sc$col]])
    m <- tapply(post, x, mean, na.rm = TRUE)
    clev <- NA
    if (!is.null(cgn)) {
      sh <- tapply(cgn, x, mean)
      if (max(sh) > 0.5) clev <- names(sh)[which.max(sh)]
    }
    if (is.na(clev)) clev <- names(sort(m))[2]
    rest <- setdiff(names(m), clev); t74lev <- rest[which.min(m[rest])]
    grp[!is.na(x) & x == clev] <- "control"
    grp[!is.na(x) & x == t74lev] <- "T74"
    grp[!is.na(x) & x %in% setdiff(rest, t74lev)] <- "T94"
  } else if (!is.null(cgn)) {
    grp[cgn] <- "control"
    sc2 <- scan_group(df, post, 2, subset = !cgn)
    cat("# 2-level group scan among treated:", sc2$col, "R2 =", sc2$r2, "\n")
    if (!is.na(sc2$col)) {
      x <- as_chr(df[[sc2$col]]); x[cgn] <- NA
      m <- tapply(post, x, mean, na.rm = TRUE)
      t74lev <- names(m)[which.min(m)]
      grp[!cgn & !is.na(x) & x == t74lev] <- "T74"
      grp[!cgn & !is.na(x) & x != t74lev] <- "T94"
    }
  }
  out$group <- grp
  print(table(grp, useNA = "ifany"))
  print(tapply(post, grp, mean, na.rm = TRUE))

  # gender
  gc <- find_name(df, c("female", "gender", "sex"))
  female <- rep(NA_real_, n)
  if (!is.na(gc)) {
    g <- df[[gc]]; lt <- lab_text(g)
    fpat <- "female|woman|^f$"
    if (any(grepl(fpat, lt))) {
      female <- as.numeric(grepl(fpat, lt)); female[is.na(lt) | lt == ""] <- NA
    } else {
      v <- to_num(g)
      if (all(v %in% c(0, 1, NA))) female <- v else if (all(v %in% c(1, 2, NA))) female <- as.numeric(v == 2)
    }
  }
  out$female <- female
  cat("# gender column:", gc, " share female:", mean(female, na.rm = TRUE), "\n")

  # party
  party <- rep(NA_character_, n)
  if ("democrat" %in% names(df)) {
    d <- to_num(df$democrat)
    i <- if ("indep" %in% names(df)) to_num(df$indep) else rep(0, n)
    o <- if ("otherpol" %in% names(df)) to_num(df$otherpol) else rep(0, n)
    party <- ifelse(d == 1, "dem", ifelse(i == 1, "indep", ifelse(o == 1, "other", "rep")))
  } else {
    cand <- character(0)
    for (h in names(df)) {
      if (grepl("time$|order$|comment", tolower(h))) next
      x <- df[[h]]; l <- attr(x, "labels")
      lt <- if (!is.null(l)) tolower(names(l)) else if (is.character(x)) tolower(unique(x[!is.na(x)])) else character(0)
      if (length(lt) && length(lt) < 50 && any(grepl("democrat", lt)) && any(grepl("republican", lt))) cand <- c(cand, h)
    }
    cat("# party candidate columns:", paste(cand, collapse = " "), "\n")
    if (length(cand)) {
      covg <- sapply(cand, function(h) sum(nonempty(df[[h]])))
      cand <- cand[order(-covg)]
      pt <- lab_text(df[[cand[1]]])
      lt2 <- if (length(cand) > 1) lab_text(df[[cand[2]]]) else rep("", n)
      lt2[is.na(lt2)] <- ""
      isd <- grepl("democrat", pt); isr <- grepl("republican", pt); isi <- grepl("independent", pt)
      ld <- grepl("democrat", lt2) & !grepl("republican", lt2)
      lr <- grepl("republican", lt2) & !grepl("democrat", lt2)
      party <- ifelse(isd | (isi & ld), "dem", ifelse(isr | (isi & lr), "rep", ifelse(isi, "indep", "other")))
      party[is.na(pt) | pt == ""] <- NA
    }
  }
  out$party <- party
  print(table(party, useNA = "ifany"))

  # region
  rc <- find_name(df, c("region", "censusregion"))
  if (!is.na(rc)) out$region <- lab_text(df[[rc]])
  else if (all(c("midwest", "south", "west") %in% names(df)))
    out$region <- paste(to_num(df$midwest), to_num(df$south), to_num(df$west))
  else out$region <- "NA"

  # age
  if (all(paste0("age", 1:4) %in% names(df))) {
    out$agecat <- paste(to_num(df$age1), to_num(df$age2), to_num(df$age3), to_num(df$age4))
  } else {
    ac <- find_name(df, c("age", "agegroup", "agecat", "agecategory"))
    if (!is.na(ac)) {
      v <- to_num(df[[ac]])
      if (length(unique(v[!is.na(v)])) > 10) out$agecat <- as.character(cut(v, c(-Inf, 24, 34, 44, 54, Inf)))
      else out$agecat <- lab_text(df[[ac]])
    } else out$agecat <- "NA"
  }

  # children
  carecols <- names(df)[grepl("care", tolower(names(df)))]
  kc <- find_col(df, c("anychildren", "children", "kids", "nchildren", "haschildren", "child"),
                 c("^anychild", "^child", "children", "kids"), 0.5, avoid = carecols)
  out$kids <- if (!is.na(kc)) lab_text(df[[kc]]) else "NA"

  # income
  if ("loghhinc" %in% names(df)) out$loghhinc <- to_num(df$loghhinc)
  else {
    ic <- find_name(df, c("hhincome", "income", "hhinc"))
    out$loghhinc <- if (!is.na(ic)) inc_from(df[[ic]]) else NA_real_
  }

  # education
  if ("associatemore" %in% names(df)) out$college <- as.character(to_num(df$associatemore))
  else {
    ec <- NA_character_
    for (h in names(df)) {
      l <- attr(df[[h]], "labels")
      if (!is.null(l) && any(grepl("bachelor", tolower(names(l))))) { ec <- h; break }
    }
    if (!is.na(ec)) {
      lt <- lab_text(df[[ec]])
      col <- grepl("associate|bachelor|master|doctor|professional|post-?graduate|graduate degree|phd|2-year|4-year|two-year|four-year", lt) &
        !grepl("high school|no degree", lt)
      out$college <- as.character(as.numeric(col))
      out$college[is.na(lt)] <- "NA"
    } else {
      ec <- find_col(df, c("education", "educ"), c("educ"), 0.5)
      out$college <- if (!is.na(ec)) lab_text(df[[ec]]) else "NA"
    }
  }

  # employment
  if (all(c("fulltime", "parttime") %in% names(df))) {
    ev <- c("fulltime", "parttime", "selfemp", "unemployed", "student")
    ev <- ev[ev %in% names(df)]
    out$employ <- do.call(paste, lapply(ev, function(v) to_num(df[[v]])))
  } else {
    emc <- find_name(df, c("employment", "employ", "empstatus"))
    out$employ <- if (!is.na(emc)) lab_text(df[[emc]]) else "NA"
  }

  # weights
  wc <- find_col(df, c("pweight", "weight", "weights", "wgt"), c("weight"), 0.5)
  out$w <- if (!is.na(wc)) to_num(df[[wc]]) else 1
  cat("# weight column:", wc, "\n")

  # outcome items
  item <- function(exact, patterns, minfrac = 0.5) {
    h <- find_col(df, exact, patterns, minfrac)
    if (is.na(h)) return(list(name = NA, v = rep(NA_real_, n)))
    list(name = h, v = orient(df[[h]]))
  }
  item_coalesce <- function(prefix) {
    hs <- names(df)[grepl(prefix, names(df), ignore.case = TRUE) & !grepl(bad_name, tolower(names(df)))]
    hs <- hs[vapply(hs, function(h) mean(!is.na(to_num(df[[h]]))) > 0.05, logical(1))]
    v <- rep(NA_real_, n)
    for (h in hs) v <- coalesce_vec(v, orient(df[[h]]))
    list(name = paste(hs, collapse = "+"), v = v)
  }
  it <- list()
  it$large <- item(c("large", "gaplarge", "wagegaplarge", "largegap"), c("large", "big"))
  it$problem <- item(c("problem", "wageproblem", "gapproblem"), c("^wageproblem", "problem"))
  it$gov <- item(c("govwomen", "govmore", "government"), c("^govwomen", "^gov", "government"))
  it$quota <- item(c("quota", "quotas"), c("quota"))
  it$affirm <- item(c("affirmative", "affirmativeaction", "antidiscr"), c("affirm", "antidiscr", "affact"))
  it$legis <- item_coalesce("^legislation")
  if (all(is.na(it$legis$v))) it$legis <- item(c("equalpay"), c("legislation", "equalpay"))
  tr <- item_coalesce("^transparen")
  if (waveB == 1) {
    wb <- item(c("website", "reportingwebsite"), c("website", "reporting"))
    it$transweb <- if (!all(is.na(wb$v))) wb else tr
  } else it$transweb <- tr
  it$childcare <- item(c("childcare", "fampolicy", "daycare"), c("childcare", "child.?care", "fampolicy", "daycare", "subsid"))
  for (k in names(it)) {
    out[[k]] <- it[[k]]$v
    cat("# item", k, "<-", it[[k]]$name, " table:", paste(names(table(it[[k]]$v)), table(it[[k]]$v), sep = ":", collapse = " "), "\n")
  }
  out
}

# ---------------------------------------------------------------- load Stage I
dA <- read_dta(file.path(base, "data/SurveyStageI_WaveA_raw.dta"))
dB <- read_dta(file.path(base, "data/SurveyStageI_WaveB_raw.dta"))
bA <- build1(dA, 0)
bB <- build1(dB, 1)
dd <- rbind(bA, bB)
dd$w[is.na(dd$w) | dd$w <= 0] <- NA
ctrl <- !is.na(dd$group) & dd$group == "control"
cat("# Combined N =", nrow(dd), " control N =", sum(ctrl), "\n")

zc <- function(v, c) (v - mean(v[c], na.rm = TRUE)) / sd(v[c], na.rm = TRUE)
for (k in c("large", "problem", "gov", "quota", "affirm", "legis", "childcare")) dd[[paste0("z_", k)]] <- zc(dd[[k]], ctrl)
dd$z_transweb <- NA_real_
for (wv in c(0, 1)) {
  s <- dd$waveB == wv
  dd$z_transweb[s] <- zc(dd$transweb[s], ctrl[s])
}

anderson <- function(M, c) {
  M <- as.matrix(M)
  keep <- colSums(!is.na(M)) > 0 & apply(M, 2, function(x) isTRUE(sd(x, na.rm = TRUE) > 0))
  M <- M[, keep, drop = FALSE]
  if (ncol(M) == 0) return(rep(NA_real_, nrow(M)))
  if (ncol(M) == 1) idx <- M[, 1]
  else {
    S <- cov(M, use = "pairwise.complete.obs")
    w <- rowSums(solve(S))
    idx <- apply(M, 1, function(r) { ok <- !is.na(r); if (!any(ok)) NA_real_ else sum(w[ok] * r[ok]) / sum(w[ok]) })
  }
  (idx - mean(idx[c], na.rm = TRUE)) / sd(idx[c], na.rm = TRUE)
}
dd$perc_idx <- anderson(dd[, c("z_large", "z_problem", "z_gov")], ctrl)
dd$pol_idx <- anderson(dd[, c("z_quota", "z_affirm", "z_legis", "z_transweb", "z_childcare")], ctrl)

dd$dem <- as.numeric(dd$party == "dem")
dd$indep <- as.numeric(dd$party == "indep")
dd$other <- as.numeric(dd$party == "other")

# ---------------------------------------------------------------- Table 3 / 4
tryCatch({
  cg <- dd[ctrl, ]
  q <- quantile(cg$prior, c(0.05, 0.95), type = 2, na.rm = TRUE)
  t3 <- cg[!is.na(cg$prior) & cg$prior > q[1] & cg$prior < q[2], ]
  cat("# Table 3 trimming cutoffs:", q, " N trimmed control:", nrow(t3), "\n")
  t3$prior_z <- (t3$prior - mean(t3$prior)) / sd(t3$prior)

  mA <- feols(perc_idx ~ dem + female + indep + other + waveB, data = t3, weights = ~w, vcov = "hetero")
  print(coeftable(mA))
  setres("perception_index_democrat_table3_panelA_col4", coef(mA)["dem"])
  setres("perception_index_female_table3_panelA_col4", coef(mA)["female"])
  setres("n_obs_table3", nobs(mA))
  mB <- feols(perc_idx ~ prior_z + waveB, data = t3, weights = ~w, vcov = "hetero")
  print(coeftable(mB))
  setres("perception_index_prior_table3_panelB_col4", coef(mB)["prior_z"])

  m4A <- feols(pol_idx ~ dem + female + indep + other + waveB, data = t3, weights = ~w, vcov = "hetero")
  print(coeftable(m4A))
  setres("policy_demand_index_democrat_table4_panelA_col7", coef(m4A)["dem"])
  m4B <- feols(pol_idx ~ prior_z + waveB, data = t3, weights = ~w, vcov = "hetero")
  print(coeftable(m4B))
  setres("policy_demand_index_prior_table4_panelB_col7", coef(m4B)["prior_z"])
}, error = function(e) cat("# Table 3/4 error:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------- Table 5
tryCatch({
  trd <- dd[!is.na(dd$group) & dd$group %in% c("T74", "T94"), ]
  trd$T74 <- as.numeric(trd$group == "T74")
  trd$post_z <- (trd$post - mean(dd$post[ctrl], na.rm = TRUE)) / sd(dd$post[ctrl], na.rm = TRUE)
  for (f in c("region", "agecat", "kids", "college", "employ", "party")) {
    x <- as.character(trd[[f]]); x[is.na(x) | x == ""] <- "NA"; trd[[f]] <- x
  }
  trd$inc_miss <- as.numeric(is.na(trd$loghhinc))
  trd$loghhinc[is.na(trd$loghhinc)] <- mean(trd$loghhinc, na.rm = TRUE)
  usable <- function(v) { x <- trd[[v]]; !is.null(x) && length(unique(x[!is.na(x)])) > 1 }
  num_c <- c("waveB", "female", "prior", "loghhinc", "inc_miss")
  fac_c <- c("region", "agecat", "kids", "college", "employ", "party")
  terms <- c(num_c[sapply(num_c, usable)], paste0("factor(", fac_c[sapply(fac_c, usable)], ")"))
  cstr <- paste(terms, collapse = " + ")
  cat("# Table 5 controls:", cstr, " N treated:", nrow(trd), "\n")

  f1 <- feols(as.formula(paste("post ~ T74 +", cstr)), data = trd, weights = ~w, vcov = "hetero")
  setres("first_stage_posterior_raw_t74_table5_panelA_col1", coef(f1)["T74"])
  f2 <- feols(as.formula(paste("post_z ~ T74 +", cstr)), data = trd, weights = ~w, vcov = "hetero")
  setres("first_stage_posterior_z_t74_table5_panelA_col2", coef(f2)["T74"])
  f6 <- feols(as.formula(paste("perc_idx ~ T74 +", cstr)), data = trd, weights = ~w, vcov = "hetero")
  setres("perception_index_t74_table5_panelA_col6", coef(f6)["T74"])
  cat("# first stage raw/z, perception:", coef(f1)["T74"], coef(f2)["T74"], coef(f6)["T74"], "\n")

  iv <- function(y) {
    m <- feols(as.formula(paste(y, "~", cstr, "| post_z ~ T74")), data = trd, weights = ~w, vcov = "hetero")
    coef(m)["fit_post_z"]
  }
  setres("iv_affirmative_action_posterior_table5_panelC_col2", iv("z_affirm"))
  setres("iv_equal_pay_legislation_posterior_table5_panelC_col3", iv("z_legis"))
  setres("iv_policy_demand_index_posterior_table5_panelC_col7", iv("pol_idx"))
}, error = function(e) cat("# Table 5 error:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------- Table 6 (follow-up)
tryCatch({
  fa <- read_dta(file.path(base, "data/SurveyStageII_WaveA_raw.dta"))
  fb <- read_dta(file.path(base, "data/SurveyStageII_WaveB_raw.dta"))
  cat("# Stage II A columns:", paste(names(fa), collapse = " "), "\n")
  cat("# Stage II B columns:", paste(names(fb), collapse = " "), "\n")
  cvars <- c("wave", "gender", "prior", "midwest", "south", "west", "age1", "age2", "age3", "age4",
             "anychildren", "loghhinc", "associatemore", "fulltime", "parttime", "selfemp",
             "unemployed", "student", "democrat", "indep", "otherpol")
  build2 <- function(df, wv) {
    n <- nrow(df)
    get <- function(nm) if (nm %in% names(df)) to_num(df[[nm]]) else rep(NA_real_, n)
    oi <- function(nm) if (nm %in% names(df)) orient(df[[nm]]) else rep(NA_real_, n)
    out <- data.frame(waveB_f = rep(wv, n))
    out$problem <- coalesce_vec(oi("wageproblemSQ001"), oi("wageproblem2SQ001"))
    out$high <- coalesce_vec(oi("wageproblemSQ002"), oi("wageproblem2SQ002"))
    out$low <- coalesce_vec(oi("wageproblemSQ003"), oi("wageproblem2SQ003"))
    out$gov <- oi("govwomen")
    for (v in cvars) out[[v]] <- get(v)
    out$w <- if ("pweight" %in% names(df)) to_num(df$pweight) else 1
    out$rand <- if ("rand" %in% names(df)) as_chr(df$rand) else NA_character_
    out$pid <- if ("panelID" %in% names(df)) trimws(as_chr(df$panelID)) else NA_character_
    out$post2 <- get("posteriorII")
    out
  }
  fu <- rbind(build2(fa, 0), build2(fb, 1))
  cat("# follow-up N =", nrow(fu), "\n")

  # treatment assignment: merge from Stage I via panel ID, else via rand
  fu$T74 <- NA_real_
  if (any(!is.na(dd$pid))) {
    key <- dd[!is.na(dd$pid) & !is.na(dd$group), c("pid", "group")]
    key <- key[!duplicated(key$pid), ]
    g <- key$group[match(fu$pid, key$pid)]
    if (mean(!is.na(g)) > 0.8) {
      fu$T74 <- ifelse(g == "T74", 1, ifelse(g == "T94", 0, NA))
      cat("# follow-up treatment merged from Stage I; match rate", mean(!is.na(g)), "\n")
    }
  }
  if (mean(!is.na(fu$T74)) < 0.8 && any(!is.na(fu$rand))) {
    m <- tapply(fu$post2, fu$rand, mean, na.rm = TRUE)
    print(m)
    if (length(m) == 2) {
      t74lev <- names(m)[which.min(m)]
      fu$T74 <- ifelse(is.na(fu$rand), NA, as.numeric(fu$rand == t74lev))
      cat("# follow-up treatment from rand; T74 level =", t74lev, "\n")
    }
  }
  print(table(fu$T74, useNA = "ifany"))

  allc <- rep(TRUE, nrow(fu))
  for (k in c("problem", "high", "low", "gov")) fu[[paste0("z_", k)]] <- zc(fu[[k]], allc)
  fu$perc_fu <- anderson(fu[, c("z_problem", "z_gov", "z_high", "z_low")], allc)
  fu$w[is.na(fu$w) | fu$w <= 0] <- NA
  if (all(is.na(fu$w))) fu$w <- 1
  fu$wave_ctrl <- if (any(!is.na(fu$wave)) && length(unique(fu$wave[!is.na(fu$wave)])) > 1) fu$wave else fu$waveB_f
  cv <- setdiff(cvars, "wave")
  cv <- c("wave_ctrl", cv[sapply(cv, function(v) { x <- fu[[v]]; length(unique(x[!is.na(x)])) > 1 })])
  m6 <- feols(as.formula(paste("perc_fu ~ T74 +", paste(cv, collapse = " + "))), data = fu, weights = ~w, vcov = "hetero")
  print(coeftable(m6)[1:2, , drop = FALSE])
  setres("followup_perception_index_t74_table6_panelA_col7", coef(m6)["T74"])
}, error = function(e) cat("# Table 6 error:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------- output
for (nm in names(res)) cat(sprintf("RESULT:%s=%.6f\n", nm, res[[nm]]))
