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
    z <- to_num(df[[v]]); u <- unique(z[!is.na(z)])
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
  x <- to_num(df[[col]])
  key <- function(s) sub("^([a-z_]*?)[0-9]*((sq|_)[0-9]+)$", "\\1\\2", tolower(s), perl = TRUE)
  if (grepl("(sq|_)[0-9]+$", tolower(col))) {
    sibs <- setdiff(nm[key(nm) == key(col)], col)
    sibs <- sibs[!grepl("time$|order$", tolower(sibs))]
    for (s in sibs) {
      z <- to_num(df[[s]])
      if (mean(!is.na(x) & !is.na(z)) < 0.05) {
        x[is.na(x)] <- z[is.na(x)]
        message(sprintf("[item %s] coalesced sibling %s", tag, s))
      }
    }
  }
  sg <- orient_sign(df[[col]])
  tb <- table(x, useNA = "ifany")
  message(sprintf("[item %s] col=%s sign=%s label=%s | values: %s", tag, col, sg,
                  substr(getlab(df[[col]]), 1, 120),
                  paste(names(tb), tb, sep = ":", collapse = " ")))
  list(x = x, sign = sg, col = col)
}

female_from <- function(x, nm = "") {
  if (tolower(nm) == "female") return(to_num(x))
  labs <- attr(x, "labels", exact = TRUE)
  if (!is.null(labs)) {
    f <- labs[grepl("fem|wom", names(labs), ignore.case = TRUE)]
    if (length(f)) {
      xv <- as.vector(zap_labels(x))
      out <- as.numeric(xv %in% as.vector(f)); out[is.na(xv)] <- NA
      return(out)
    }
  }
  if (is.character(x)) {
    xx <- tolower(trimws(x))
    out <- as.numeric(grepl("^f|fem|wom", xx)); out[is.na(xx) | xx == ""] <- NA
    return(out)
  }
  xn <- to_num(x); u <- sort(unique(na.omit(xn)))
  if (all(u %in% c(0, 1))) return(xn)
  if (all(u %in% c(1, 2))) return(as.numeric(xn == 2))
  as.numeric(xn == max(u))
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
  o$age1 <- pick("age1", function() if (is.na(ac)) NULL else as.numeric(agev < 25))
  o$age2 <- pick("age2", function() if (is.na(ac)) NULL else as.numeric(agev >= 25 & agev < 35))
  o$age3 <- pick("age3", function() if (is.na(ac)) NULL else as.numeric(agev >= 35 & agev < 45))
  o$age4 <- pick("age4", function() if (is.na(ac)) NULL else as.numeric(agev >= 45 & agev < 55))
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

diag_labels <- function(df, tag) {
  pat <- "genderroleatt|attitudes|importance|tenyears|fairown|genderpolanch|^aa$|^ez$|^fa$|^md$|^mf$|^ff$|^fg$|^ml$|^mn$|^gl$|^gm$|elicit|womenwage|menwage|treatment|controlgroup|^rand$|^demo[0-9]|agebracket|demrep|children|trustgov|effectiveness"
  nm <- names(df)
  sel <- nm[grepl(pat, tolower(nm)) & !grepl("time$|order$", tolower(nm))]
  for (v in sel) {
    x <- df[[v]]; labs <- attr(x, "labels", exact = TRUE)
    z <- suppressWarnings(to_num(x))
    sh <- shown_flag(x)
    message(sprintf("[diag %s] %s: class=%s nonmiss=%d shown=%d mean=%s labels=%s", tag, v,
                    class(x)[1], sum(!is.na(z)), sum(sh),
                    round(suppressWarnings(mean(z, na.rm = TRUE)), 2),
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
  o <- data.frame(waveB = rep(wb, n))
  idc <- ex(c("panelID", "panelid", "pid", "respondentid", "id"))
  o$pid <- if (is.na(idc)) rep(NA_character_, n) else as_id(df[[idc]])
  o$w <- numv(ex(c("pweight", "weight", "pw", "wgt", "weights")))

  # prior belief (cents per dollar): pick a candidate in a plausible range
  prior_set <- FALSE
  for (pc0 in c("prior", "priorbelief", "womenwage", "womenwages")) {
    cc0 <- ex(pc0)
    if (is.na(cc0)) next
    v <- numv(cc0); md <- suppressWarnings(median(v, na.rm = TRUE))
    message(sprintf("[stage1 wave %d] prior candidate %s median=%s", wb, cc0, md))
    if (is.finite(md) && md >= 20 && md <= 200) { o$prior <- v; prior_set <- TRUE
      message(sprintf("[stage1 wave %d] prior from %s", wb, cc0)); break }
  }
  if (!prior_set) {
    wc <- ex("womenwage"); mc <- ex("menwage")
    if (!is.na(wc) && !is.na(mc)) {
      wv <- numv(wc); mv <- numv(mc)
      r <- ifelse(is.finite(wv) & is.finite(mv) & mv > 0, 100 * wv / mv, NA_real_)
      if (is.finite(median(r, na.rm = TRUE)) && median(r, na.rm = TRUE) > 20 && median(r, na.rm = TRUE) < 200) {
        o$prior <- r; prior_set <- TRUE
        message(sprintf("[stage1 wave %d] prior = 100*womenwage/menwage", wb))
      }
    }
  }
  if (!prior_set) o$prior <- numv(ex(c("prior", "priorbelief", "womenwages", "womenwage")))

  qc <- ex(c("posterior", "posteriorbelief", "post"))
  if (!is.na(qc)) {
    o$post <- numv(qc)
  } else {
    pcs <- nm[(grepl("^post", lnm) | grepl("^elicitb", lnm)) & !grepl("time$|order$|postal|zip|code", lnm)]
    message("[stage1 wave ", wb, "] posterior candidates: ", paste(pcs, collapse = ","))
    o$post <- if (length(pcs)) Reduce(function(a, b) { a[is.na(a)] <- b[is.na(a)]; a }, lapply(pcs, numv)) else NA_real_
  }
  message(sprintf("[stage1 wave %d] prior summary: %s ; post summary: %s", wb,
                  paste(round(summary(o$prior), 2), collapse = " "),
                  paste(round(summary(o$post), 2), collapse = " ")))

  # control indicator
  ctrl <- rep(NA, n)
  cc <- ex(c("control", "controlgroup", "purecontrol", "pure_control"))
  if (!is.na(cc)) {
    ctrl <- numv(cc) == 1
  } else {
    ncols <- nm[grepl("^controlgroupnote", lnm) & !grepl("time$|order$", lnm)]
    if (length(ncols)) {
      m <- matrix(sapply(ncols, function(t) shown_flag(df[[t]])), nrow = n)
      s <- rowSums(m) > 0
      message(sprintf("[stage1 wave %d] control-note shown share: %.3f", wb, mean(s)))
      if (mean(s) > 0.03 && mean(s) < 0.7) ctrl <- s
    }
    if (all(is.na(ctrl))) {
      tcols <- nm[grepl("^controlgroupnote.*time$", lnm)]
      if (length(tcols)) {
        m <- sapply(tcols, function(t) { z <- numv(t); !is.na(z) & z > 0 })
        m <- matrix(m, nrow = n)
        s <- rowSums(m) > 0
        if (mean(s) > 0.05 && mean(s) < 0.7) ctrl <- s
      }
    }
  }
  message(sprintf("[stage1 wave %d] control flag share: %s", wb, round(mean(ctrl, na.rm = TRUE), 3)))

  cands <- unique(c(nm[lnm %in% c("t74", "treat74", "treatment", "treat", "rand", "group", "arm",
                                  "condition", "treatmentgroup", "t94", "info", "acs")],
                    nm[grepl("treat|^t74|^t94|^arm|^rand|group", lnm) &
                         !grepl("time$|order$|note|controlgroup", lnm)]))
  best <- NULL
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
    acs <- nm[grepl("^treatment(c)?acs", lnm) & !grepl("time$|order$", lnm)]
    cps <- nm[grepl("^treatment(c)?cps", lnm) & !grepl("time$|order$", lnm)]
    if (length(acs) && length(cps)) {
      sA <- rowSums(matrix(sapply(acs, function(t) shown_flag(df[[t]])), nrow = n)) > 0
      sC <- rowSums(matrix(sapply(cps, function(t) shown_flag(df[[t]])), nrow = n)) > 0
      grp <- ifelse(sA & !sC, 1, ifelse(sC & !sA, 0, NA_real_))
      grp[o$ctrl] <- NA
      mA <- mean(o$post[grp %in% 1], na.rm = TRUE); mC <- mean(o$post[grp %in% 0], na.rm = TRUE)
      message(sprintf("[stage1 wave %d] treatment display: ACS n=%d (post %.2f), CPS n=%d (post %.2f)",
                      wb, sum(grp %in% 1), mA, sum(grp %in% 0), mC))
      if (is.finite(mA) && is.finite(mC)) {
        o$t74 <- if (mA <= mC) grp else 1 - grp
      }
    }
    message(sprintf("[stage1 wave %d] treatment via display columns", wb))
  }
  attr(o, "tvar") <- if (is.null(best)) NA_character_ else best$cn
  attr(o, "t74val") <- if (is.null(best)) NA else best$t74val
  attr(o, "tvals") <- if (is.null(best)) NA else best$tvals

  o <- cbind(o, controls_from(df))

  tagw <- paste0("w", wb, ":")
  its <- list(
    perc_large = get_item(df, "large", "compan|firm|employ|size|city|town|affirm|quota", tag = paste(tagw, "large")),
    perc_problem = get_item(df, "problem", "high.?skill|low.?skill", tag = paste(tagw, "problem")),
    perc_gov = get_item(df, "government|^gov|\\bgov", "effectiv|trust|census|petition|white house|donat|quota|affirm|legislat|transparen|website|child",
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
    fu_problem = get_item(df, "problem", "high|low|skill|govern", fallback = c("wageproblemSQ001", "wageproblem2SQ001"),
                          tag = paste(tagw, "problem")),
    fu_gov = get_item(df, exact = c("govwomen"), include = "support women|government.*women",
                      tag = paste(tagw, "gov women")),
    fu_high = get_item(df, "high.?skill|high.?paid|high.?educ|college", "low|govern|^gov",
                       fallback = c("wageproblemSQ002", "wageproblem2SQ002"), tag = paste(tagw, "high-skilled")),
    fu_low = get_item(df, "low.?skill|low.?paid|low.?educ", "high|govern|^gov",
                      fallback = c("wageproblemSQ003", "wageproblem2SQ003"), tag = paste(tagw, "low-skilled"))
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
dump_names(p2A, "StageII WaveA")
dump_names(p2B, "StageII WaveB")
tryCatch(diag_labels(p1A, "I-A"), error = function(e) message("diag error: ", conditionMessage(e)))
tryCatch(diag_labels(p1B, "I-B"), error = function(e) message("diag error: ", conditionMessage(e)))

S1A <- build_stage1(p1A, 0)
S1B <- build_stage1(p1B, 1)
S1 <- bind_rows(S1A, S1B)
S1$ctrl <- S1$ctrl %in% TRUE
message(sprintf("Stage I: N=%d, control=%d, T74=%d, T94=%d", nrow(S1), sum(S1$ctrl),
                sum(S1$t74 == 1, na.rm = TRUE), sum(S1$t74 == 0, na.rm = TRUE)))

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
                        error = function(e) { message("perc index error: ", conditionMessage(e)); NA_real_ })
S1$pol_idx <- tryCatch(anderson_index(S1[, paste0(pol_items, "_z")], S1$ctrl),
                       error = function(e) { message("policy index error: ", conditionMessage(e)); NA_real_ })

# posterior z-scored with the pure control group
S1$post_z <- zref(S1$post, S1$ctrl)

# ------------------------------------------------------------------ Table 3 / 4
tryCatch({
  if (sum(S1$ctrl) < 10) stop("no pure control group identified")
  cp <- S1$prior[S1$ctrl & !is.na(S1$prior)]
  p5 <- quantile(cp, 0.05, type = 2); p95 <- quantile(cp, 0.95, type = 2)
  t3 <- S1[S1$ctrl & !is.na(S1$prior) & S1$prior > p5 & S1$prior < p95, ]
  message(sprintf("Table 3 sample: p5=%s p95=%s N=%d", p5, p95, nrow(t3)))
  emit("n_obs_table3", nrow(t3))
  t3$prior_z <- (t3$prior - mean(t3$prior)) / sd(t3$prior)
  if (any(!is.na(t3$perc_idx))) {
    m3a <- feols(perc_idx ~ democrat + female + indep + otherpol + waveB, data = t3, weights = wf(t3), vcov = "hetero")
    print(summary(m3a))
    emit("perception_index_democrat_table3_panelA_col4", coef(m3a)["democrat"])
    emit("perception_index_female_table3_panelA_col4", coef(m3a)["female"])
    m3b <- feols(perc_idx ~ prior_z + waveB, data = t3, weights = wf(t3), vcov = "hetero")
    print(summary(m3b))
    emit("perception_index_prior_table3_panelB_col4", coef(m3b)["prior_z"])
  }
  m4a <- feols(pol_idx ~ democrat + female + indep + otherpol + waveB, data = t3, weights = wf(t3), vcov = "hetero")
  print(summary(m4a))
  emit("policy_demand_index_democrat_table4_panelA_col7", coef(m4a)["democrat"])
  m4b <- feols(pol_idx ~ prior_z + waveB, data = t3, weights = wf(t3), vcov = "hetero")
  print(summary(m4b))
  emit("policy_demand_index_prior_table4_panelB_col7", coef(m4b)["prior_z"])
}, error = function(e) message("Table 3/4 error: ", conditionMessage(e)))

# ------------------------------------------------------------------ Table 5
tryCatch({
  tr <- S1[!S1$ctrl & !is.na(S1$t74), ]
  if (nrow(tr) < 20) stop("no treated sample identified")
  cs <- ctrl_string(tr)
  message("Table 5 controls: ", cs, " ; N=", nrow(tr))
  m5a <- feols(as.formula(paste("post ~ t74 +", cs)), data = tr, weights = wf(tr), vcov = "hetero")
  print(coeftable(m5a)["t74", ])
  emit("first_stage_posterior_raw_t74_table5_panelA_col1", coef(m5a)["t74"])
  m5b <- feols(as.formula(paste("post_z ~ t74 +", cs)), data = tr, weights = wf(tr), vcov = "hetero")
  emit("first_stage_posterior_z_t74_table5_panelA_col2", coef(m5b)["t74"])
  if (any(!is.na(tr$perc_idx))) {
    m5p <- feols(as.formula(paste("perc_idx ~ t74 +", cs)), data = tr, weights = wf(tr), vcov = "hetero")
    print(coeftable(m5p)["t74", ])
    emit("perception_index_t74_table5_panelA_col6", coef(m5p)["t74"])
  }
  tryCatch({
    iv_aa <- feols(as.formula(paste("pol_aa_z ~", cs, "| post_z ~ t74")), data = tr, weights = wf(tr), vcov = "hetero")
    emit("iv_affirmative_action_posterior_table5_panelC_col2", coef(iv_aa)["fit_post_z"])
  }, error = function(e) message("IV AA error: ", conditionMessage(e)))
  tryCatch({
    iv_leg <- feols(as.formula(paste("pol_leg_z ~", cs, "| post_z ~ t74")), data = tr, weights = wf(tr), vcov = "hetero")
    emit("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(iv_leg)["fit_post_z"])
  }, error = function(e) message("IV leg error: ", conditionMessage(e)))
  tryCatch({
    iv_idx <- feols(as.formula(paste("pol_idx ~", cs, "| post_z ~ t74")), data = tr, weights = wf(tr), vcov = "hetero")
    emit("iv_policy_demand_index_posterior_table5_panelC_col7", coef(iv_idx)["fit_post_z"])
  }, error = function(e) message("IV index error: ", conditionMessage(e)))
}, error = function(e) message("Table 5 error: ", conditionMessage(e)))

# ------------------------------------------------------------------ Table 6 (follow-up)
tryCatch({
  S2 <- bind_rows(build_stage2(p2A, 0), build_stage2(p2B, 1))
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
      S2[[v]] <- ifelse(is.na(mi) | is.na(sv), S2[[v]], sv)
    }
    S2$prior <- ifelse(is.na(S2$prior) & !is.na(mi), S1$prior[mi], S2$prior)
    if (all(is.na(S2$w))) S2$w <- S1$w[mi]
  }
  if (all(is.na(S2$t74))) {
    for (wb in c(0, 1)) {
      rows <- S2$waveB == wb
      g <- S2$rand[rows]; u <- sort(unique(g[!is.na(g)]))
      a <- if (wb == 0) S1A else S1B
      if (identical(tolower(attr(a, "tvar")), "rand") && all(u %in% attr(a, "tvals"))) {
        S2$t74[rows] <- as.numeric(g == attr(a, "t74val"))
        message("Follow-up wave ", wb, ": T74 from Stage I rand mapping")
      } else if (length(u) == 2) {
        pm <- sapply(u, function(v) mean(S2$postII[rows][g == v], na.rm = TRUE))
        S2$t74[rows] <- as.numeric(g == u[which.min(pm)])
        message("Follow-up wave ", wb, ": T74 from lower follow-up posterior; means ", paste(round(pm, 2), collapse = "/"))
      }
    }
  }
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
}, error = function(e) message("Table 6 error: ", conditionMessage(e)))

# ------------------------------------------------------------------ output
for (nm in names(results)) cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))