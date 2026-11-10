suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(warn = 1)

base <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy.script-free"
results <- list()
emit <- function(name, val) {
  val <- suppressWarnings(as.numeric(val))
  if (length(val) == 1 && is.finite(val)) results[[name]] <<- val
}
late <- character(0)
note <- function(s) { message(s); late <<- c(late, s) }
outdiag <- character(0)
diag_out <- function(s) { message(s); outdiag <<- c(outdiag, s) }
likert_used_any <- FALSE

# ------------------------------------------------------------------ helpers
getlab <- function(x) {
  l <- attr(x, "label", exact = TRUE)
  if (is.null(l)) "" else paste(as.character(l), collapse = " ")
}

to_num <- function(x) {
  if (is.null(x)) return(NULL)
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.logical(x)) return(as.numeric(x))
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  if (is.character(x)) {
    x <- trimws(x); x[x == ""] <- NA
    v <- suppressWarnings(as.numeric(x))
    nn <- !is.na(x)
    if (any(nn) && mean(is.na(v[nn])) > 0.5) {
      v <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", x)))
    }
    return(v)
  }
  as.numeric(x)
}

# answer-text Likert responses -> ordinal score (higher = more agreement / larger / more problem)
likert_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  xc <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(xc))
  pats <- list(
    list("strongly disagree|completely disagree|not at all|very small|not a problem at all|much less|definitely not|much too small", 1),
    list("strongly agree|completely agree|very large|very big|very serious|much more|definitely|very much|very important", 5),
    list("somewhat disagree|disagree|rather small|small|not a (big |serious |major )?problem|less|probably not|rather not|slightly", 2),
    list("neither|neutral|undecided|about right|don't know|do not know|indifferent|moderate", 3),
    list("somewhat agree|agree|rather large|large|big|problem|more|probably|rather|important", 4)
  )
  for (p in pats) {
    hit <- is.na(out) & !is.na(xc) & xc != "" & grepl(p[[1]], xc, perl = TRUE)
    out[hit] <- p[[2]]
  }
  out
}

num_or_likert <- function(x, tag = "") {
  v <- to_num(x)
  if (all(is.na(v)) && (is.character(x) || is.factor(x))) {
    vl <- likert_num(x)
    if (sum(!is.na(vl)) > 5) {
      uv <- unique(trimws(as.character(x))); uv <- uv[!is.na(uv) & uv != ""]
      diag_out(sprintf("[likert %s] text answers mapped: %s", tag, substr(paste(head(uv, 8), collapse = "|"), 1, 200)))
      likert_used_any <<- TRUE
      return(list(x = vl, likert = TRUE))
    }
  }
  list(x = v, likert = FALSE)
}

as_id <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  x <- trimws(as.character(as.vector(x)))
  x <- sub("\\.0+$", "", x)
  x[x == "" | x == "NA"] <- NA
  x
}

shown_flag <- function(x) {
  if (is.null(x)) return(NULL)
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) return(!is.na(x) & trimws(x) != "")
  !is.na(x)
}

orient_sign <- function(x) {
  labs <- attr(x, "labels", exact = TRUE)
  if (is.null(labs) || length(labs) < 2) return(NA_real_)
  lv <- suppressWarnings(as.numeric(to_num(as.vector(labs))))
  ok <- !is.na(lv)
  if (sum(ok) < 2) return(NA_real_)
  labs <- labs[ok]; lv <- lv[ok]
  hi <- tolower(names(labs)[which.max(lv)])
  lo <- tolower(names(labs)[which.min(lv)])
  neg <- "disagree|not at all|oppose|no problem|not a problem|too small|small|^no\\b|decrease|less|none"
  if (grepl(neg, hi) && !grepl(neg, lo)) return(-1)
  if (grepl(neg, lo) && !grepl(neg, hi)) return(1)
  NA_real_
}

find_cols <- function(df, include, exclude = NULL, max_unique = 12) {
  nm <- names(df); lnm <- tolower(nm)
  labs <- vapply(df, getlab, character(1))
  txt <- tolower(paste(nm, labs))
  ok <- grepl(include, txt, perl = TRUE) &
    !grepl("time$|order$|date|other$|comment", lnm)
  if (!is.null(exclude)) ok <- ok & !grepl(exclude, txt, perl = TRUE)
  cand <- nm[ok]
  if (!length(cand)) return(character(0))
  keep <- vapply(cand, function(v) {
    z <- num_or_likert(df[[v]])$x; u <- unique(z[!is.na(z)])
    length(u) >= 2 && length(u) <= max_unique
  }, logical(1))
  cand[keep]
}

get_item <- function(df, include = NULL, exclude = NULL, exact = NULL,
                     fallback = NULL, tag = "") {
  n <- nrow(df); nm <- names(df); lnm <- tolower(nm)
  col <- NA_character_
  if (!is.null(exact)) for (e in tolower(exact)) {
    i <- which(lnm == e); if (length(i)) { col <- nm[i[1]]; break }
  }
  if (is.na(col) && !is.null(include)) {
    cs <- find_cols(df, include, exclude)
    if (length(cs)) col <- cs[1]
  }
  if (is.na(col) && !is.null(fallback)) for (e in tolower(fallback)) {
    i <- which(lnm == e); if (length(i)) { col <- nm[i[1]]; break }
  }
  if (is.na(col)) {
    message(sprintf("[item %s] NOT FOUND", tag))
    return(list(x = rep(NA_real_, n), sign = NA_real_, col = NA_character_))
  }
  nl <- num_or_likert(df[[col]], paste(tag, col))
  x <- nl$x
  key <- function(s) sub("^([a-z_]*?)[0-9]*((sq|_)[0-9]+)$", "\\1\\2", tolower(s), perl = TRUE)
  if (grepl("(sq|_)[0-9]+$", tolower(col))) {
    sibs <- setdiff(nm[key(nm) == key(col)], col)
    sibs <- sibs[!grepl("time$|order$", tolower(sibs))]
    for (s in sibs) {
      z <- num_or_likert(df[[s]])$x
      if (mean(!is.na(x) & !is.na(z)) < 0.05) {
        x[is.na(x)] <- z[is.na(x)]
        message(sprintf("[item %s] coalesced sibling %s", tag, s))
      }
    }
  }
  sg <- if (nl$likert) 1 else orient_sign(df[[col]])
  tb <- table(x, useNA = "ifany")
  message(sprintf("[item %s] col=%s sign=%s label=%s | values: %s", tag, col, sg,
                  substr(getlab(df[[col]]), 1, 120),
                  paste(names(tb), tb, sep = ":", collapse = " ")))
  list(x = x, sign = sg, col = col)
}

female_from <- function(x, nm = "") {
  if (tolower(nm) == "female") return(to_num(x))
  nonconst <- function(v) length(unique(v[!is.na(v)])) > 1
  labs <- attr(x, "labels", exact = TRUE)
  if (!is.null(labs)) {
    f <- labs[grepl("^f|fem|wom", names(labs), ignore.case = TRUE)]
    if (length(f)) {
      xv <- as.vector(zap_labels(x))
      out <- as.numeric(xv %in% as.vector(f)); out[is.na(xv)] <- NA
      if (nonconst(out)) return(out)
    }
  }
  if (is.character(x) || is.factor(x)) {
    xc <- if (inherits(x, "haven_labelled")) as.vector(zap_labels(x)) else x
    xx <- tolower(trimws(as.character(xc)))
    out <- as.numeric(grepl("^f|fem|wom", xx)); out[is.na(xx) | xx == ""] <- NA
    if (nonconst(out)) return(out)
  }
  xn <- to_num(x); u <- sort(unique(na.omit(xn)))
  if (length(u) < 2) return(rep(NA_real_, length(xn)))
  if (all(u %in% c(0, 1))) return(xn)
  tb <- sort(table(xn), decreasing = TRUE)
  fcode <- as.numeric(names(tb)[1])
  message(sprintf("[female] coded gender without labels; codes %s; taking most frequent code %s as female (women oversampled)",
                  paste(names(tb), tb, sep = ":", collapse = " "), fcode))
  out <- as.numeric(xn == fcode); out[is.na(xn)] <- NA
  out
}

controls_from <- function(df) {
  n <- nrow(df); nm <- names(df); lnm <- tolower(nm)
  ex <- function(c) {
    for (e in tolower(c)) { i <- which(lnm == e); if (length(i)) return(nm[i[1]]) }
    NA_character_
  }
  numv <- function(col) if (is.na(col)) rep(NA_real_, n) else to_num(df[[col]])
  lab_dummy <- function(col, regex, exclude = NULL) {
    if (is.na(col)) return(NULL)
    x <- df[[col]]; labs <- attr(x, "labels", exact = TRUE)
    if (is.null(labs)) return(NULL)
    sel <- grepl(regex, names(labs), ignore.case = TRUE, perl = TRUE)
    if (!is.null(exclude)) sel <- sel & !grepl(exclude, names(labs), ignore.case = TRUE, perl = TRUE)
    if (!any(sel)) return(NULL)
    xv <- as.vector(zap_labels(x))
    out <- as.numeric(xv %in% as.vector(labs[sel])); out[is.na(xv)] <- NA
    out
  }
  pick <- function(exacts, fb = NULL) {
    c0 <- ex(exacts)
    if (!is.na(c0)) return(numv(c0))
    r <- if (is.null(fb)) NULL else fb()
    if (is.null(r)) rep(NA_real_, n) else r
  }
  o <- data.frame(row = seq_len(n))
  gcol <- ex(c("female", "gender", "sex"))
  o$female <- if (is.na(gcol)) NA_real_ else female_from(df[[gcol]], gcol)
  if (!is.na(gcol)) {
    rv <- df[[gcol]]; if (inherits(rv, "haven_labelled")) rv <- zap_labels(rv)
    tbg <- table(as.character(rv), useNA = "ifany")
    message(sprintf("[controls] gender col=%s raw: %s ; female share=%s", gcol,
                    paste(names(tbg), tbg, sep = ":", collapse = " "),
                    round(mean(o$female, na.rm = TRUE), 3)))
  }
  rc <- ex(c("region", "censusregion"))
  o$midwest <- pick("midwest", function() lab_dummy(rc, "mid ?west"))
  o$south <- pick("south", function() lab_dummy(rc, "south"))
  o$west <- pick("west", function() lab_dummy(rc, "west", "mid"))
  ac <- ex(c("age", "ageyears", "agebracket", "ageii"))
  agev <- numv(ac)
  if (!is.na(ac)) {
    labs <- attr(df[[ac]], "labels", exact = TRUE)
    if (!is.null(labs)) {
      lo <- sapply(names(labs), function(s) {
        m <- regmatches(s, regexpr("[0-9]+", s))
        if (length(m)) as.numeric(m) else NA_real_
      })
      if (sum(!is.na(lo)) >= 2) {
        agev <- as.numeric(lo[match(agev, to_num(as.vector(labs)))])
      }
    }
  }
  agecat <- !is.na(ac) && any(!is.na(agev)) && max(agev, na.rm = TRUE) <= 10
  if (agecat) {
    ak <- match(agev, sort(unique(agev[!is.na(agev)])))
    message(sprintf("[controls] age col=%s treated as bracket codes: %s", ac,
                    paste(names(table(agev)), table(agev), sep = ":", collapse = " ")))
    o$age1 <- pick("age1", function() as.numeric(ak == 1))
    o$age2 <- pick("age2", function() as.numeric(ak == 2))
    o$age3 <- pick("age3", function() as.numeric(ak == 3))
    o$age4 <- pick("age4", function() as.numeric(ak == 4))
  } else {
    o$age1 <- pick("age1", function() if (is.na(ac)) NULL else as.numeric(agev < 25))
    o$age2 <- pick("age2", function() if (is.na(ac)) NULL else as.numeric(agev >= 25 & agev < 35))
    o$age3 <- pick("age3", function() if (is.na(ac)) NULL else as.numeric(agev >= 35 & agev < 45))
    o$age4 <- pick("age4", function() if (is.na(ac)) NULL else as.numeric(agev >= 45 & agev < 55))
  }
  o$anychildren <- pick(c("anychildren", "haschildren", "anychild"), function() {
    c0 <- ex(c("children", "nchild", "numchildren", "kids"))
    if (is.na(c0)) NULL else as.numeric(numv(c0) > 0)
  })
  o$loghhinc <- pick("loghhinc", function() {
    hc <- ex(c("hhincome", "hhincbracket", "income", "hhinc"))
    if (is.na(hc)) return(NULL)
    x <- df[[hc]]; labs <- attr(x, "labels", exact = TRUE); xv <- to_num(x)
    if (!is.null(labs)) {
      mids <- sapply(names(labs), function(s) {
        nums <- suppressWarnings(as.numeric(gsub(",", "", regmatches(s, gregexpr("[0-9][0-9,]*", s))[[1]])))
        nums <- nums[!is.na(nums)]
        if (!length(nums)) NA else mean(nums)
      })
      out <- mids[match(xv, to_num(as.vector(labs)))]
      log(pmax(as.numeric(out), 1))
    } else log(pmax(xv, 1))
  })
  o$college <- pick(c("associatemore", "college", "collegedegree", "atleastassociate"), function() {
    r <- NULL
    for (cn in c("education", "educ", "edu", "demo1", "demo2", "demo3")) {
      edc <- ex(cn)
      r <- lab_dummy(edc, "associate|bachelor|master|doctor|professional|graduate|ph\\.?d")
      if (!is.null(r)) break
    }
    r
  })
  emc <- ex(c("employment", "empstatus", "employ"))
  o$fulltime <- pick("fulltime", function() lab_dummy(emc, "full"))
  o$parttime <- pick("parttime", function() lab_dummy(emc, "part"))
  o$selfemp <- pick(c("selfemp", "selfemployed"), function() lab_dummy(emc, "self"))
  o$unemployed <- pick("unemployed", function() lab_dummy(emc, "unemploy"))
  o$student <- pick("student", function() lab_dummy(emc, "student"))
  pc <- ex(c("party", "demrep", "politics", "political", "polorientation", "partisanship", "polview"))
  o$democrat <- pick("democrat", function() lab_dummy(pc, "democrat"))
  o$indep <- pick(c("indep", "independent"), function() lab_dummy(pc, "independ", "lean"))
  o$otherpol <- pick("otherpol", function() lab_dummy(pc, "other"))
  o$row <- NULL
  o
}

ctrl_names <- c("female", "midwest", "south", "west", "age1", "age2", "age3", "age4",
                "anychildren", "loghhinc", "college", "fulltime", "parttime", "selfemp",
                "unemployed", "student", "democrat", "indep", "otherpol")

anderson_index <- function(Z, ref) {
  Z <- as.matrix(Z)
  ref <- ref %in% TRUE
  if (sum(ref) < 10) ref <- rep(TRUE, nrow(Z))
  keep <- apply(Z[ref, , drop = FALSE], 2, function(c) sum(!is.na(c)) > 5)
  Z <- Z[, keep, drop = FALSE]
  if (ncol(Z) == 0) stop("no usable index components")
  Zr <- Z[ref, , drop = FALSE]
  cc <- complete.cases(Zr)
  if (sum(cc) < 3) stop("too few complete cases for index covariance")
  S <- cov(Zr[cc, , drop = FALSE])
  W <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  w <- rowSums(W)
  idx <- apply(Z, 1, function(z) {
    a <- !is.na(z)
    if (!any(a)) NA_real_ else sum(w[a] * z[a]) / sum(w[a])
  })
  m <- mean(idx[ref], na.rm = TRUE); s <- sd(idx[ref], na.rm = TRUE)
  (idx - m) / s
}

zref <- function(x, ref) {
  ref <- ref %in% TRUE
  if (sum(ref & !is.na(x)) < 10) ref <- rep(TRUE, length(x))
  s <- sd(x[ref], na.rm = TRUE)
  if (!is.finite(s) || s == 0) return(rep(NA_real_, length(x)))
  (x - mean(x[ref], na.rm = TRUE)) / s
}

dump_names <- function(df, tag) {
  nm <- names(df)
  keep <- !grepl("time$", tolower(nm))
  labs <- vapply(df, getlab, character(1))
  message(sprintf("=== %s: %d x %d", tag, nrow(df), ncol(df)))
  message(paste(sprintf("%s{%s}", nm[keep], substr(labs[keep], 1, 50)), collapse = "; "))
}

compact_names <- function(df) {
  nm <- names(df)
  nm <- nm[!grepl("time$|order$|^petition|^attention|^manicheck|^grouptime", tolower(nm))]
  nm <- unique(sub("SQ[0-9]+$", "[SQ]", nm))
  paste(nm, collapse = ",")
}

qsum <- function(v) {
  v <- v[!is.na(v)]
  if (!length(v)) return("n=0")
  sprintf("n=%d q=%s", length(v), paste(round(quantile(v, c(0, .1, .5, .9, 1)), 1), collapse = "/"))
}

raw_peek <- function(x) {
  cl <- class(x)[1]
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  xc <- trimws(as.character(x)); xc <- xc[!is.na(xc) & xc != ""]
  sprintf("%s ne=%d u=%s", cl, length(xc), substr(paste(head(unique(xc), 4), collapse = "|"), 1, 60))
}

diag_labels <- function(df, tag) {
  pat <- "genderroleatt|attitudes|importance|tenyears|fairown|genderpolanch|^aa$|^ez$|^fa$|^md$|^mf$|^ff$|^fg$|^ml$|^mn$|^gl$|^gm$|^gp$|elicit|womenwage|menwage|ownwage|treatment|controlgroup|^rand|^demo[0-9]|agebracket|gender$|demrep|children|trustgov|effectiveness|problem|large|gov|petitiont1dec"
  nm <- names(df)
  sel <- nm[grepl(pat, tolower(nm)) & !grepl("order$", tolower(nm))]
  for (v in sel) {
    x <- df[[v]]; labs <- attr(x, "labels", exact = TRUE)
    z <- suppressWarnings(to_num(x))
    sh <- shown_flag(x)
    message(sprintf("[diag %s] %s: class=%s nonmiss=%d shown=%d mean=%s med=%s labels=%s", tag, v,
                    class(x)[1], sum(!is.na(z)), sum(sh),
                    round(suppressWarnings(mean(z, na.rm = TRUE)), 2),
                    round(suppressWarnings(median(z, na.rm = TRUE)), 2),
                    if (is.null(labs)) "" else substr(paste(labs, names(labs), sep = "=", collapse = "|"), 1, 250)))
  }
}

# ------------------------------------------------------------------ Stage I builder
build_stage1 <- function(df, wb) {
  n <- nrow(df); nm <- names(df); lnm <- tolower(nm)
  ex <- function(c) {
    for (e in tolower(c)) { i <- which(lnm == e); if (length(i)) return(nm[i[1]]) }
    NA_character_
  }
  numv <- function(col) if (is.na(col)) rep(NA_real_, n) else to_num(df[[col]])
  inr <- function(v) { md <- suppressWarnings(median(v, na.rm = TRUE)); is.finite(md) && md >= 20 && md <= 200 }
  coal <- function(vs) Reduce(function(a, b) { a[is.na(a)] <- b[is.na(a)]; a }, vs)
  o <- data.frame(waveB = rep(wb, n))
  idc <- ex(c("panelID", "panelid", "pid", "respondentid", "id"))
  o$pid <- if (is.na(idc)) rep(NA_character_, n) else as_id(df[[idc]])
  o$w <- numv(ex(c("pweight", "weight", "pw", "wgt", "weights")))

  # prior belief: elicited BEFORE the information treatment (elicitb* items,
  # incentivized / non-incentivized versions), in dollars per $100
  prior_set <- FALSE
  c0 <- ex(c("prior", "priorbelief"))
  if (!is.na(c0) && inr(numv(c0))) {
    o$prior <- numv(c0); prior_set <- TRUE
    message(sprintf("[stage1 wave %d] prior from %s", wb, c0))
  }
  if (!prior_set) {
    pcs <- nm[grepl("^elicitb", lnm) & !grepl("time$|order$", lnm)]
    vs <- lapply(pcs, numv)
    ok <- vapply(vs, inr, logical(1))
    message(sprintf("[stage1 wave %d] elicitb prior candidates: %s", wb,
                    paste(pcs, ifelse(ok, "in-range", "out"), sep = "=", collapse = ",")))
    if (any(ok)) { o$prior <- coal(vs[ok]); prior_set <- TRUE }
  }
  if (!prior_set) {
    for (pc0 in c("womenwage", "womenwages")) {
      cc0 <- ex(pc0)
      if (is.na(cc0)) next
      if (inr(numv(cc0))) { o$prior <- numv(cc0); prior_set <- TRUE
        message(sprintf("[stage1 wave %d] prior (fallback) from %s", wb, cc0)); break }
    }
  }
  if (!prior_set) o$prior <- NA_real_

  # posterior belief: elicited AFTER the information treatment.  Each respondent
  # answers one of several randomly assigned related statistics, so each column is
  # mostly empty; non-answers may be coded 0 -> treat values outside (0, 300] as missing.
  post_set <- FALSE
  qc <- ex(c("posterior", "posteriorbelief"))
  if (!is.na(qc) && inr(numv(qc))) { o$post <- numv(qc); post_set <- TRUE }
  pw_cols <- nm[lnm %in% c("womenwage", "womenwages", "menwage", "ownwage") |
                  (grepl("^post", lnm) & !grepl("time$|order$|postal|zip|code", lnm))]
  for (cn in pw_cols) {
    v <- numv(cn)
    diag_out(sprintf("[w%d post-cand] %s raw %s | %s", wb, cn, qsum(v), raw_peek(df[[cn]])))
  }
  clean <- function(v) { v[!is.na(v) & (v <= 0 | v > 300)] <- NA; v }
  if (!post_set) {
    direct <- unique(c(nm[lnm %in% c("womenwage")],
                       nm[grepl("^post", lnm) & !grepl("time$|order$|postal|zip|code", lnm)]))
    pieces <- list()
    for (cn in direct) {
      v <- clean(numv(cn))
      if (sum(!is.na(v)) >= 0.03 * n && inr(v)) pieces[[cn]] <- v
    }
    wc <- ex("womenwages"); mc <- ex("menwage")
    if (!is.na(wc) && !is.na(mc)) {
      wv <- numv(wc); mv <- numv(mc)
      r <- ifelse(is.finite(wv) & is.finite(mv) & wv > 0 & mv > 0, 100 * wv / mv, NA_real_)
      r <- clean(r)
      diag_out(sprintf("[w%d post-cand] ratio 100*womenwages/menwage %s", wb, qsum(r)))
      if (sum(!is.na(r)) >= 0.03 * n && inr(r)) pieces[["ratio"]] <- r
      wv2 <- clean(wv)
      if (!length(pieces) && sum(!is.na(wv2)) >= 0.03 * n && inr(wv2)) pieces[["womenwages"]] <- wv2
    }
    if (length(pieces)) {
      o$post <- coal(pieces); post_set <- TRUE
      diag_out(sprintf("[w%d post] built from %s -> %s", wb, paste(names(pieces), collapse = "+"), qsum(o$post)))
    }
  }
  if (!post_set) o$post <- NA_real_
  note(sprintf("[stage1 wave %d] prior summary: %s ; post summary: %s", wb,
               paste(round(summary(o$prior), 2), collapse = " "),
               paste(round(summary(o$post), 2), collapse = " ")))

  # ---------------- treatment groups from what was displayed to the respondent
  flag_cols <- function(rx) {
    cols <- nm[grepl(rx, lnm, perl = TRUE) & !grepl("order$", lnm)]
    if (!length(cols)) return(NULL)
    m <- sapply(cols, function(t) {
      if (grepl("time$", tolower(t))) { z <- numv(t); !is.na(z) & z > 0 } else shown_flag(df[[t]])
    })
    rowSums(matrix(m, nrow = n)) > 0
  }
  grp_from <- function(rxs, tag) {
    S <- lapply(rxs, flag_cols)
    if (any(vapply(S, is.null, logical(1)))) { message(sprintf("[stage1 wave %d] %s: columns missing", wb, tag)); return(NULL) }
    S <- do.call(cbind, S)
    k <- rowSums(S)
    g <- rep(NA_character_, n); one <- k == 1
    if (any(one)) g[one] <- names(rxs)[max.col(S[one, , drop = FALSE], ties.method = "first")]
    sh <- as.numeric(table(factor(g, levels = names(rxs)))) / n
    message(sprintf("[stage1 wave %d] %s groups: shares %s, assigned %.3f, multi %.3f", wb, tag,
                    paste(names(rxs), round(sh, 3), sep = "=", collapse = " "),
                    mean(!is.na(g)), mean(k > 1)))
    if (mean(!is.na(g)) < 0.8 || any(sh < 0.1) || any(sh > 0.6)) return(NULL)
    g
  }
  g_src <- "display"
  g_sem <- grp_from(list(A = "^treatment(c)?acs", B = "^treatment(c)?cps", C = "^controlgroupnote"), "display")
  if (is.null(g_sem)) {
    g_src <- "petition"
    g_sem <- grp_from(list(A = "^petitiont1", B = "^petitiont2", C = "^petitionc"), "petition")
  }

  best <- NULL
  if (!is.null(g_sem)) {
    mA <- mean(o$post[g_sem %in% "A"], na.rm = TRUE)
    mB <- mean(o$post[g_sem %in% "B"], na.rm = TRUE)
    mC <- mean(o$post[g_sem %in% "C"], na.rm = TRUE)
    t74code <- "A"
    if (is.finite(mA) && is.finite(mB) && mB < mA - 3) t74code <- "B"
    message(sprintf("[stage1 wave %d] groups via %s: posterior means A=%.2f B=%.2f C=%.2f ; T74 group=%s",
                    wb, g_src, mA, mB, mC, t74code))
    o$ctrl <- g_sem %in% "C"
    o$t74 <- ifelse(g_sem %in% c("A", "B"), as.numeric(g_sem == t74code), NA_real_)
  } else {
    # control indicator (old heuristics)
    ctrl <- rep(NA, n)
    cc <- ex(c("control", "controlgroup", "purecontrol", "pure_control"))
    if (!is.na(cc)) {
      ctrl <- numv(cc) == 1
    } else {
      ncols <- nm[grepl("^controlgroupnote", lnm) & !grepl("time$|order$", lnm)]
      if (length(ncols)) {
        m <- matrix(sapply(ncols, function(t) shown_flag(df[[t]])), nrow = n)
        s <- rowSums(m) > 0
        if (mean(s) > 0.03 && mean(s) < 0.7) ctrl <- s
      }
    }
    cands <- unique(c(nm[lnm %in% c("t74", "treat74", "treatment", "treat", "rand", "group", "arm",
                                    "condition", "treatmentgroup", "t94", "info", "acs")],
                      nm[grepl("treat|^t74|^t94|^arm|^rand|group", lnm) &
                           !grepl("time$|order$|note|controlgroup", lnm)]))
    for (cn in cands) {
      g <- numv(cn); u <- sort(unique(g[!is.na(g)]))
      if (length(u) < 2 || length(u) > 3) next
      ctrl_c <- ctrl
      if (length(u) == 3) {
        rates <- sapply(u, function(v) mean(ctrl[!is.na(g) & g == v], na.rm = TRUE))
        if (!all(is.na(rates)) && max(rates, na.rm = TRUE) > 0.5) {
          cv0 <- u[which.max(rates)]
        } else {
          miss <- sapply(u, function(v) mean(is.na(o$post[!is.na(g) & g == v])))
          pm0 <- sapply(u, function(v) mean(o$post[!is.na(g) & g == v], na.rm = TRUE))
          if (sum(miss > 0.8) == 1 && sum(miss < 0.5) == 2) {
            cv0 <- u[which.max(miss)]
          } else {
            oo <- u[order(pm0, na.last = NA)]
            if (length(oo) < 3) next
            cv0 <- oo[2]
          }
        }
        ctrl_c <- !is.na(g) & g == cv0
        tv <- setdiff(u, cv0)
      } else {
        tv <- u
      }
      ctrl_c[is.na(ctrl_c)] <- FALSE
      trt <- !is.na(g) & g %in% tv & !ctrl_c
      pm <- sapply(tv, function(v) mean(o$post[trt & g == v], na.rm = TRUE))
      d <- abs(diff(pm))
      message(sprintf("[stage1 wave %d] treatment candidate %s: values %s, treated posterior means %s",
                      wb, cn, paste(u, collapse = "/"), paste(round(pm, 2), collapse = "/")))
      if (length(d) == 1 && is.finite(d) && d > 3 && (is.null(best) || d > best$d))
        best <- list(cn = cn, d = d, ctrl = ctrl_c, t74val = tv[which.min(pm)], tvals = tv, g = g)
    }
    if (!is.null(best)) {
      o$ctrl <- best$ctrl
      o$t74 <- ifelse(best$ctrl | is.na(best$g) | !(best$g %in% best$tvals), NA_real_,
                      as.numeric(best$g == best$t74val))
      message(sprintf("[stage1 wave %d] treatment var=%s T74 value=%s", wb, best$cn, best$t74val))
    } else {
      o$ctrl <- ifelse(is.na(ctrl), FALSE, ctrl)
      o$t74 <- NA_real_
      message(sprintf("[stage1 wave %d] treatment NOT identified", wb))
    }
  }
  attr(o, "tvar") <- if (is.null(best)) NA_character_ else best$cn
  attr(o, "t74val") <- if (is.null(best)) NA else best$t74val
  attr(o, "tvals") <- if (is.null(best)) NA else best$tvals

  o <- cbind(o, controls_from(df))

  # diagnostic peek at possible perception items (gap large / problem / government)
  labs_all <- vapply(df, getlab, character(1))
  pp <- nm[grepl("large|problem|gov|attitud|^gl$|^gp$|^gm$|^fa$|^ez$|^ml$|^mn$|^md$|^mf$|^ff$|^fg$",
                 tolower(paste(nm, labs_all))) & !grepl("time$|order$", lnm)]
  for (cn in head(pp, 12)) diag_out(sprintf("[w%d perc-cand] %s: %s", wb, cn, raw_peek(df[[cn]])))

  tagw <- paste0("w", wb, ":")
  its <- list(
    perc_large = get_item(df, exact = c("large", "gaplarge", "wagegaplarge", "gapsize", "sizegap", "biggap", "gl"),
                          include = "large|gap ?size|\\bbig\\b", exclude = "compan|firm|employ|city|town|affirm|quota",
                          tag = paste(tagw, "large")),
    perc_problem = get_item(df, exact = c("problem", "gapproblem", "wageproblemSQ001", "wageproblem", "gp"),
                            include = "problem", exclude = "high.?skill|low.?skill", tag = paste(tagw, "problem")),
    perc_gov = get_item(df, exact = c("govmore", "govdo", "government", "gov", "govwomen", "gm"),
                        include = "government|^gov|\\bgov",
                        exclude = "effectiv|trust|census|petition|white house|donat|quota|affirm|legislat|transparen|website|child",
                        tag = paste(tagw, "gov")),
    pol_quota = get_item(df, exact = c("quotaanchor"), include = "quota",
                         exclude = "formyquota|calculation|petition", tag = paste(tagw, "quota")),
    pol_aa = get_item(df, exact = c("AAanchor"), include = "affirmative", tag = paste(tagw, "affirmative")),
    pol_leg = get_item(df, exact = c("legislationanchor"), include = "equal pay|legislation",
                       exclude = "affirmative|quota|transparen|website", tag = paste(tagw, "legislation")),
    pol_trans = get_item(df, exact = c("transparencyanchor"), include = "transparen|website",
                         exclude = "petition", tag = paste(tagw, "transparency")),
    pol_child = get_item(df, exact = c("childcare"), include = "child ?care|day ?care|kindergarten|pre-?school",
                         tag = paste(tagw, "childcare"))
  )
  # perception fallback: array "attitudes[SQ00x]" (gap large / problem / government should do more)
  pk <- c("perc_large", "perc_problem", "perc_gov")
  att <- sort(nm[grepl("^attitudes", lnm) & !grepl("time$|order$|other$", lnm)])
  for (i in seq_along(pk)) {
    if ((is.na(its[[pk[i]]]$col) || sum(!is.na(its[[pk[i]]]$x)) < 0.2 * n) && length(att) >= i) {
      nl <- num_or_likert(df[[att[i]]], paste(tagw, att[i]))
      xa <- nl$x
      if (sum(!is.na(xa)) > max(5, sum(!is.na(its[[pk[i]]]$x)))) {
        its[[pk[i]]] <- list(x = xa, sign = if (nl$likert) 1 else orient_sign(df[[att[i]]]), col = att[i])
      }
    }
  }
  for (k in names(its)) {
    x <- its[[k]]$x
    note(sprintf("[w%d item] %s <- %s nonmiss=%d mean=%s", wb, k, its[[k]]$col, sum(!is.na(x)),
                 round(suppressWarnings(mean(x, na.rm = TRUE)), 2)))
  }
  for (k in names(its)) {
    o[[k]] <- its[[k]]$x
    o[[paste0(k, "_sgn")]] <- its[[k]]$sign
  }
  o
}

# ------------------------------------------------------------------ Stage II builder
build_stage2 <- function(df, wb) {
  n <- nrow(df); nm <- names(df); lnm <- tolower(nm)
  ex <- function(c) {
    for (e in tolower(c)) { i <- which(lnm == e); if (length(i)) return(nm[i[1]]) }
    NA_character_
  }
  numv <- function(col) if (is.na(col)) rep(NA_real_, n) else to_num(df[[col]])
  o <- data.frame(waveB = rep(wb, n))
  idc <- ex(c("panelID", "panelid", "pid", "respondentid", "id"))
  o$pid <- if (is.na(idc)) rep(NA_character_, n) else as_id(df[[idc]])
  o$w <- numv(ex(c("pweight", "weight", "pw")))
  o$prior <- numv(ex(c("prior")))
  o$rand <- numv(ex(c("rand", "t74", "treatment", "treat")))
  o$postII <- numv(ex(c("posteriorII", "posterior")))
  o <- cbind(o, controls_from(df))
  tagw <- paste0("FU w", wb, ":")
  its <- list(
    fu_problem = get_item(df, exact = c("wageproblemSQ001", "wageproblem2SQ001"), include = "problem",
                          exclude = "high|low|skill|govern", tag = paste(tagw, "problem")),
    fu_gov = get_item(df, exact = c("govwomen"), include = "support women|government.*women",
                      tag = paste(tagw, "gov women")),
    fu_high = get_item(df, exact = c("wageproblemSQ002", "wageproblem2SQ002"),
                       include = "high.?skill|high.?paid", exclude = "low|govern|^gov|associate|degree",
                       tag = paste(tagw, "high-skilled")),
    fu_low = get_item(df, exact = c("wageproblemSQ003", "wageproblem2SQ003"),
                      include = "low.?skill|low.?paid", exclude = "high|govern|^gov",
                      tag = paste(tagw, "low-skilled"))
  )
  for (k in names(its)) {
    o[[k]] <- its[[k]]$x
    o[[paste0(k, "_sgn")]] <- its[[k]]$sign
  }
  o
}

# ------------------------------------------------------------------ load
p1A <- read_dta(file.path(base, "data/SurveyStageI_WaveA_raw.dta"))
p1B <- read_dta(file.path(base, "data/SurveyStageI_WaveB_raw.dta"))
p2A <- read_dta(file.path(base, "data/SurveyStageII_WaveA_raw.dta"))
p2B <- read_dta(file.path(base, "data/SurveyStageII_WaveB_raw.dta"))

dump_names(p1A, "StageI WaveA")
message("StageI WaveB extra names: ", paste(setdiff(names(p1B)[!grepl("time$", tolower(names(p1B)))], names(p1A)), collapse = ", "))
message("StageI WaveA time columns (first 60): ", paste(head(names(p1A)[grepl("time$", tolower(names(p1A)))], 60), collapse = ", "))
dump_names(p2A, "StageII WaveA")
dump_names(p2B, "StageII WaveB")
tryCatch(diag_labels(p1A, "I-A"), error = function(e) message("diag error: ", conditionMessage(e)))
tryCatch(diag_labels(p1B, "I-B"), error = function(e) message("diag error: ", conditionMessage(e)))

S1A <- build_stage1(p1A, 0)
S1B <- build_stage1(p1B, 1)

# compact diagnostics at the very top of stdout (stderr middle is truncated)
tryCatch({
  nmA <- names(p1A)
  fn <- which(tolower(nmA) == "finalnote")
  tailA <- if (length(fn)) nmA[seq(fn, length(nmA))] else character(0)
  tailA <- tailA[!grepl("time$|^grouptime|order$", tolower(tailA))]
  extraB <- setdiff(names(p1B), nmA)
  extraB <- extraB[!grepl("time$|^grouptime|order$|^petition", tolower(extraB))]
  extraB <- unique(sub("SQ[0-9]+$", "[SQ]", extraB))
  txt <- c(paste0("TAIL_I_A: ", substr(paste(tailA, collapse = ","), 1, 400)),
           paste0("EXTRA_I_B: ", substr(paste(extraB, collapse = ","), 1, 500)),
           vapply(outdiag, function(s) substr(s, 1, 160), character(1)))
  cat(substr(paste(txt, collapse = "\n"), 1, 2800), "\n", sep = "")
}, error = function(e) cat("diag print error:", conditionMessage(e), "\n"))

# ------------------------------------------------------------------ follow-up sample (T74/T94 only)
S2 <- tryCatch({
  s2 <- bind_rows(build_stage2(p2A, 0), build_stage2(p2B, 1))
  s2$t74fu <- NA_real_
  for (wb in c(0, 1)) {
    rows <- which(s2$waveB == wb)
    g <- s2$rand[rows]; u <- sort(unique(g[!is.na(g)]))
    if (length(u) == 2) {
      pm <- sapply(u, function(v) mean(s2$postII[rows][g %in% v], na.rm = TRUE))
      if (all(is.finite(pm))) {
        s2$t74fu[rows] <- ifelse(is.na(g), NA_real_, as.numeric(g == u[which.min(pm)]))
        note(sprintf("[fu wave %d] rand values %s, follow-up posterior means %s", wb,
                     paste(u, collapse = "/"), paste(round(pm, 2), collapse = "/")))
      }
    } else note(sprintf("[fu wave %d] rand has %d values", wb, length(u)))
  }
  s2
}, error = function(e) { note(paste("FU build error:", conditionMessage(e))); NULL })

# Identify Stage I arms by matching follow-up respondents (only T74/T94 were re-contacted):
# the Stage I assignment variable must separate followers' arms, and values never seen among
# followers form the pure control group.
identify_from_fu <- function(df, S, S2w, wb) {
  n <- nrow(df)
  ft <- S2w$t74fu[match(S$pid, S2w$pid)]
  ft[is.na(S$pid)] <- NA
  f <- !is.na(ft)
  nf <- sum(f)
  note(sprintf("[fu-id wave %d] followers matched in Stage I: %d of %d", wb, nf, nrow(S2w)))
  if (nf < 50) return(NULL)
  nm <- names(df); lnm <- tolower(nm)
  cands <- list()
  for (j in seq_along(nm)) {
    if (grepl("time$|order$|date|^panelid$|^id$|^seed$|weight", lnm[j])) next
    x <- df[[j]]
    if (inherits(x, "haven_labelled")) x <- zap_labels(x)
    if (is.character(x) || is.factor(x)) {
      xc <- trimws(as.character(x)); xc[xc == ""] <- NA
      v <- suppressWarnings(as.numeric(xc))
      if (any(!is.na(xc) & is.na(v))) v <- as.numeric(factor(xc))
    } else v <- suppressWarnings(as.numeric(x))
    if (length(v) != n) next
    v[is.na(v)] <- -999
    u <- unique(v)
    if (length(u) < 2 || length(u) > 8) next
    cands[[nm[j]]] <- v
  }
  disp <- function(rx) {
    cols <- nm[grepl(rx, lnm, perl = TRUE) & !grepl("order$|time$", lnm)]
    if (!length(cols)) return(rep(FALSE, n))
    rowSums(matrix(sapply(cols, function(t) shown_flag(df[[t]])), nrow = n)) > 0
  }
  cands[["display_composite"]] <- 1 * disp("^treatment(c)?acs") + 2 * disp("^treatment(c)?cps") + 4 * disp("^controlgroupnote")
  cands[["petition_composite"]] <- 1 * disp("^petitiont1") + 2 * disp("^petitiont2") + 4 * disp("^petitionc")
  best <- NULL
  for (cn in names(cands)) {
    v <- cands[[cn]]
    tb1 <- tapply(ft[f], v[f], sum); tbn <- tapply(ft[f], v[f], length)
    acc <- sum(pmax(tb1, tbn - tb1)) / sum(tbn)
    sig <- tbn >= max(5, 0.02 * nf)
    if (!any(sig)) next
    vals <- as.numeric(names(tbn))
    shr <- tb1 / tbn
    t74v <- vals[sig & shr > 0.5]; t94v <- vals[sig & shr <= 0.5]
    if (!length(t74v) || !length(t94v)) next
    ctrl <- !(v %in% c(t74v, t94v))
    cs <- mean(ctrl)
    folc <- mean(ctrl[f])
    if (acc < 0.9 || cs < 0.15 || cs > 0.5 || folc > 0.05) next
    score <- acc - 0.1 * abs(cs - 1/3) + 0.01 * grepl("rand", tolower(cn))
    if (is.null(best) || score > best$score)
      best <- list(cn = cn, score = score, acc = acc, cs = cs, ctrl = ctrl,
                   t74 = ifelse(ctrl, NA_real_, as.numeric(v %in% t74v)),
                   t74v = t74v, t94v = t94v)
  }
  if (is.null(best)) return(NULL)
  note(sprintf("[fu-id wave %d] assignment var=%s acc=%.3f control share=%.3f T74 vals=%s T94 vals=%s",
               wb, best$cn, best$acc, best$cs, paste(best$t74v, collapse = "/"), paste(best$t94v, collapse = "/")))
  best
}

fix_groups <- function(S, df, wb) {
  if (sum(S$ctrl %in% TRUE) >= 10 && any(!is.na(S$t74))) return(S)
  if (is.null(S2)) return(S)
  r <- tryCatch(identify_from_fu(df, S, S2[S2$waveB == wb, ], wb),
                error = function(e) { note(paste("fu-id error:", conditionMessage(e))); NULL })
  if (is.null(r)) { note(sprintf("[fu-id wave %d] no assignment variable found", wb)); return(S) }
  S$ctrl <- r$ctrl
  S$t74 <- r$t74
  note(sprintf("[fu-id wave %d] N: ctrl=%d T74=%d T94=%d ; posterior means ctrl=%.2f T74=%.2f T94=%.2f", wb,
               sum(S$ctrl), sum(S$t74 %in% 1), sum(S$t74 %in% 0),
               mean(S$post[S$ctrl], na.rm = TRUE), mean(S$post[S$t74 %in% 1], na.rm = TRUE),
               mean(S$post[S$t74 %in% 0], na.rm = TRUE)))
  S
}
S1A <- fix_groups(S1A, p1A, 0)
S1B <- fix_groups(S1B, p1B, 1)

S1 <- bind_rows(S1A, S1B)
S1$ctrl <- S1$ctrl %in% TRUE
note(sprintf("Stage I: N=%d, control=%d, T74=%d, T94=%d", nrow(S1), sum(S1$ctrl),
             sum(S1$t74 == 1, na.rm = TRUE), sum(S1$t74 == 0, na.rm = TRUE)))
cat(sprintf("POSTERIOR by arm: ctrl %s | T74 %s | T94 %s\n",
            qsum(S1$post[S1$ctrl]), qsum(S1$post[S1$t74 %in% 1]), qsum(S1$post[S1$t74 %in% 0])))
if (likert_used_any) cat("DEVIATION: Text-coded answer options for some Stage I items were mapped to a 1-5 ordinal scale by keyword (raw export stored answer text)\n")

orient_items <- function(D, items, ref) {
  ref <- ref %in% TRUE
  for (k in items) {
    if (all(is.na(D[[k]]))) next
    sg <- D[[paste0(k, "_sgn")]]
    for (wb in unique(D$waveB)) {
      rows <- D$waveB == wb
      if (all(is.na(D[[k]][rows]))) next
      s <- unique(sg[rows])[1]
      if (is.na(s)) {
        rr <- rows & ref
        if (sum(rr & !is.na(D[[k]]) & !is.na(D$female)) < 5) rr <- rows
        okk <- rr & !is.na(D[[k]]) & !is.na(D$female)
        r <- if (sum(okk) < 3) NA_real_ else
          suppressWarnings(cor(D[[k]][okk], D$female[okk]))
        s <- if (is.na(r) || r >= 0) 1 else -1
        message(sprintf("[orient] %s wave %d: sign from female correlation (r=%s) -> %d", k, wb, round(r, 3), s))
      }
      D[[k]][rows] <- D[[k]][rows] * s
    }
  }
  D
}

wf <- function(D) if (all(is.na(D$w))) NULL else ~w

ctrl_string <- function(D, extra = c("waveB", "prior")) {
  vs <- c(extra, ctrl_names)
  vs <- vs[vs %in% names(D)]
  vs <- vs[vapply(vs, function(v) {
    x <- D[[v]]; mean(!is.na(x)) > 0.5 && length(unique(x[!is.na(x)])) > 1
  }, logical(1))]
  paste(vs, collapse = " + ")
}

# ------------------------------------------------------------------ Stage I outcomes
perc_items <- c("perc_large", "perc_problem", "perc_gov")
pol_items <- c("pol_quota", "pol_aa", "pol_leg", "pol_trans", "pol_child")
S1 <- orient_items(S1, c(perc_items, pol_items), S1$ctrl)

for (k in c(perc_items, pol_items)) {
  if (k == "pol_trans") {
    z <- rep(NA_real_, nrow(S1))
    for (wb in unique(S1$waveB)) {
      rows <- S1$waveB == wb
      z[rows] <- zref(S1[[k]][rows], S1$ctrl[rows])
    }
    S1[[paste0(k, "_z")]] <- z
  } else {
    S1[[paste0(k, "_z")]] <- zref(S1[[k]], S1$ctrl)
  }
}
S1$perc_idx <- tryCatch(anderson_index(S1[, paste0(perc_items, "_z")], S1$ctrl),
                        error = function(e) { note(paste("perc index error:", conditionMessage(e))); NA_real_ })
S1$pol_idx <- tryCatch(anderson_index(S1[, paste0(pol_items, "_z")], S1$ctrl),
                       error = function(e) { note(paste("policy index error:", conditionMessage(e))); NA_real_ })

# posterior z-scored with the pure control group
S1$post_z <- zref(S1$post, S1$ctrl)

# ------------------------------------------------------------------ Table 3 / 4
tryCatch({
  if (sum(S1$ctrl) < 10) stop("no pure control group identified")
  allp <- S1$prior[!is.na(S1$prior)]
  p5 <- quantile(allp, 0.05, type = 2); p95 <- quantile(allp, 0.95, type = 2)
  t3 <- S1[S1$ctrl & !is.na(S1$prior) & S1$prior >= p5 & S1$prior <= p95, ]
  cp <- S1$prior[S1$ctrl & !is.na(S1$prior)]
  q5 <- quantile(cp, 0.05, type = 2); q95 <- quantile(cp, 0.95, type = 2)
  note(sprintf("Table 3 sample: full-sample p5=%s p95=%s N=%d (alt: control-pctile strict N=%d, inclusive N=%d; control N=%d; nonmiss perc_idx=%d pol_idx=%d)",
               p5, p95, nrow(t3), sum(cp > q5 & cp < q95), sum(cp >= q5 & cp <= q95), length(cp),
               sum(!is.na(t3$perc_idx)), sum(!is.na(t3$pol_idx))))
  emit("n_obs_table3", nrow(t3))
  t3$prior_z <- (t3$prior - mean(t3$prior)) / sd(t3$prior)
  tryCatch({
    if (sum(!is.na(t3$perc_idx)) < 30) stop("perception index missing for most of the sample")
    m3a <- feols(perc_idx ~ democrat + female + indep + otherpol + waveB, data = t3, weights = wf(t3), vcov = "hetero")
    print(summary(m3a))
    emit("perception_index_democrat_table3_panelA_col4", coef(m3a)["democrat"])
    emit("perception_index_female_table3_panelA_col4", coef(m3a)["female"])
    m3b <- feols(perc_idx ~ prior_z + waveB, data = t3, weights = wf(t3), vcov = "hetero")
    print(summary(m3b))
    emit("perception_index_prior_table3_panelB_col4", coef(m3b)["prior_z"])
  }, error = function(e) note(paste("Table 3 error:", conditionMessage(e))))
  m4a <- feols(pol_idx ~ democrat + female + indep + otherpol + waveB, data = t3, weights = wf(t3), vcov = "hetero")
  print(coeftable(m4a))
  emit("policy_demand_index_democrat_table4_panelA_col7", coef(m4a)["democrat"])
  m4b <- feols(pol_idx ~ prior_z + waveB, data = t3, weights = wf(t3), vcov = "hetero")
  print(coeftable(m4b))
  emit("policy_demand_index_prior_table4_panelB_col7", coef(m4b)["prior_z"])
}, error = function(e) note(paste("Table 3/4 error:", conditionMessage(e))))

# ------------------------------------------------------------------ Table 5
tryCatch({
  tr <- S1[!S1$ctrl & !is.na(S1$t74), ]
  if (nrow(tr) < 20) stop("no treated sample identified")
  cs <- ctrl_string(tr)
  note(paste0("Table 5 controls: ", cs, " ; N=", nrow(tr), " ; nonmiss post=", sum(!is.na(tr$post))))
  tryCatch({
    m5a <- feols(as.formula(paste("post ~ t74 +", cs)), data = tr, weights = wf(tr), vcov = "hetero")
    print(coeftable(m5a)["t74", ])
    emit("first_stage_posterior_raw_t74_table5_panelA_col1", coef(m5a)["t74"])
    m5b <- feols(as.formula(paste("post_z ~ t74 +", cs)), data = tr, weights = wf(tr), vcov = "hetero")
    emit("first_stage_posterior_z_t74_table5_panelA_col2", coef(m5b)["t74"])
  }, error = function(e) note(paste("first stage error:", conditionMessage(e))))
  tryCatch({
    if (sum(!is.na(tr$perc_idx)) < 30) stop("perception index missing")
    m5p <- feols(as.formula(paste("perc_idx ~ t74 +", cs)), data = tr, weights = wf(tr), vcov = "hetero")
    print(coeftable(m5p)["t74", ])
    emit("perception_index_t74_table5_panelA_col6", coef(m5p)["t74"])
  }, error = function(e) note(paste("perception t74 error:", conditionMessage(e))))
  tryCatch({
    iv_aa <- feols(as.formula(paste("pol_aa_z ~", cs, "| post_z ~ t74")), data = tr, weights = wf(tr), vcov = "hetero")
    emit("iv_affirmative_action_posterior_table5_panelC_col2", coef(iv_aa)["fit_post_z"])
  }, error = function(e) note(paste("IV AA error:", conditionMessage(e))))
  tryCatch({
    iv_leg <- feols(as.formula(paste("pol_leg_z ~", cs, "| post_z ~ t74")), data = tr, weights = wf(tr), vcov = "hetero")
    emit("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(iv_leg)["fit_post_z"])
  }, error = function(e) note(paste("IV leg error:", conditionMessage(e))))
  tryCatch({
    iv_idx <- feols(as.formula(paste("pol_idx ~", cs, "| post_z ~ t74")), data = tr, weights = wf(tr), vcov = "hetero")
    emit("iv_policy_demand_index_posterior_table5_panelC_col7", coef(iv_idx)["fit_post_z"])
  }, error = function(e) note(paste("IV index error:", conditionMessage(e))))
}, error = function(e) note(paste("Table 5 error:", conditionMessage(e))))

# ------------------------------------------------------------------ Table 6 (follow-up)
tryCatch({
  if (is.null(S2)) stop("follow-up data not built")
  key1 <- paste(S1$waveB, S1$pid); key2 <- paste(S2$waveB, S2$pid)
  mi <- match(key2, key1)
  mi[is.na(S2$pid)] <- NA
  share <- mean(!is.na(mi))
  message(sprintf("Follow-up: N=%d, matched to Stage I by panel id: %.3f", nrow(S2), share))
  S2$t74 <- NA_real_
  if (share > 0.5) {
    S2$t74 <- S1$t74[mi]
    for (v in ctrl_names) {
      sv <- S1[[v]][mi]
      if (length(unique(sv[!is.na(sv)])) > 1)
        S2[[v]] <- ifelse(is.na(mi) | is.na(sv), S2[[v]], sv)
    }
    S2$prior <- ifelse(is.na(S2$prior) & !is.na(mi), S1$prior[mi], S2$prior)
    if (all(is.na(S2$w))) S2$w <- S1$w[mi]
  }
  if (all(is.na(S2$t74))) S2$t74 <- S2$t74fu
  message(sprintf("Follow-up T74=%d, T94=%d", sum(S2$t74 == 1, na.rm = TRUE), sum(S2$t74 == 0, na.rm = TRUE)))
  fu_items <- c("fu_problem", "fu_gov", "fu_high", "fu_low")
  allref <- rep(TRUE, nrow(S2))
  S2 <- orient_items(S2, fu_items, allref)
  for (k in fu_items) S2[[paste0(k, "_z")]] <- zref(S2[[k]], allref)
  S2$fu_idx <- anderson_index(S2[, paste0(fu_items, "_z")], allref)
  d6 <- S2[!is.na(S2$t74), ]
  cs6 <- ctrl_string(d6)
  message("Table 6 controls: ", cs6, " ; N=", nrow(d6))
  m6 <- feols(as.formula(paste("fu_idx ~ t74 +", cs6)), data = d6, weights = wf(d6), vcov = "hetero")
  print(coeftable(m6)["t74", ])
  emit("followup_perception_index_t74_table6_panelA_col7", coef(m6)["t74"])
}, error = function(e) note(paste("Table 6 error:", conditionMessage(e))))

# ------------------------------------------------------------------ late diagnostics
message("==== SUMMARY DIAGNOSTICS ====")
for (s in late) message(substr(s, 1, 300))

# ------------------------------------------------------------------ output
for (nm in names(results)) cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
