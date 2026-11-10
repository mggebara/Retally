suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)
options(warn = 1)

root <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy.script-free"
dd <- file.path(root, "data")
msg <- function(...) message(paste0(...))
dlog <- character(0)
dg <- function(...) { s <- paste0(...); dlog <<- c(dlog, s); message(s) }

s1A <- read_dta(file.path(dd, "SurveyStageI_WaveA_raw.dta"))
s1B <- read_dta(file.path(dd, "SurveyStageI_WaveB_raw.dta"))
s2A <- read_dta(file.path(dd, "SurveyStageII_WaveA_raw.dta"))
s2B <- read_dta(file.path(dd, "SurveyStageII_WaveB_raw.dta"))

# ------------------------------------------------------------------ helpers
varlab <- function(x) { l <- attr(x, "label"); if (is.null(l)) "" else as.character(l)[1] }

num <- function(x) {
  x <- zap_labels(x)
  if (is.character(x)) {
    x <- trimws(x); x[x == ""] <- NA
    return(suppressWarnings(as.numeric(gsub("[^0-9.-]", "", x))))
  }
  as.numeric(x)
}

labtxt <- function(x) {
  if (inherits(x, "haven_labelled")) t <- as.character(as_factor(x, levels = "default")) else t <- as.character(zap_labels(x))
  t <- tolower(trimws(t)); t[!is.na(t) & t == ""] <- NA
  t
}

item_num <- function(x) {
  n <- suppressWarnings(num(x))
  lb <- attr(x, "labels")
  if (!is.null(lb)) {
    bad <- lb[grepl("know|unsure|not sure|prefer not|no answer|refuse", tolower(names(lb)))]
    if (length(bad)) n[n %in% suppressWarnings(as.numeric(bad))] <- NA
  }
  zx <- zap_labels(x)
  if (is.character(zx)) { t <- tolower(zx); n[!is.na(t) & grepl("know|unsure|prefer", t)] <- NA }
  n[!is.na(n) & n < 0] <- NA
  n
}

exact <- function(d, cands) {
  nms <- names(d)
  for (cc in cands) { h <- nms[tolower(nms) == tolower(cc)]; if (length(h)) return(h[1]) }
  NA_character_
}
okname <- function(nms) nms[!grepl("(time|order)$", nms, ignore.case = TRUE)]
findcols <- function(d, name_pats, label_pats = character(0)) {
  nms <- okname(names(d))
  hits <- unique(unlist(lapply(name_pats, function(p) nms[grepl(p, nms, ignore.case = TRUE)])))
  if (!length(hits) && length(label_pats)) {
    labs <- vapply(nms, function(v) varlab(d[[v]]), "")
    hits <- unique(unlist(lapply(label_pats, function(p) nms[grepl(p, labs, ignore.case = TRUE)])))
  }
  hits
}
findcol <- function(d, pats) { h <- findcols(d, pats); if (length(h)) h[1] else NA_character_ }

rawtab <- function(x, k = 8) {
  t <- as.character(zap_labels(x)); t[is.na(t) | trimws(t) == ""] <- "<NA>"
  tb <- sort(table(t), decreasing = TRUE)
  tb <- tb[seq_len(min(k, length(tb)))]
  paste(substr(names(tb), 1, 25), tb, sep = "=", collapse = "; ")
}

get_item <- function(d, name_pats, label_pats = character(0), tag = "") {
  hits <- findcols(d, name_pats, label_pats)
  if (length(hits)) hits <- hits[vapply(hits, function(h) sum(!is.na(item_num(d[[h]]))) > 0, TRUE)]
  if (!length(hits)) { msg("  item ", tag, ": NOT FOUND"); return(rep(NA_real_, nrow(d))) }
  x <- item_num(d[[hits[1]]]); used <- hits[1]
  for (h in hits[-1]) {
    y <- item_num(d[[h]])
    if (mean(!is.na(x) & !is.na(y)) < 0.02) { x <- ifelse(is.na(x), y, x); used <- c(used, h) }
  }
  tb <- table(x, useNA = "ifany")
  msg("  item ", tag, " <- ", paste(used, collapse = "+"), " ; values: ",
      if (length(tb) <= 15) paste(names(tb), tb, sep = "=", collapse = ", ") else paste(round(summary(x), 2), collapse = " "))
  x
}

coalesce_cols <- function(d, cols) {
  x <- rep(NA_real_, nrow(d)); used <- character(0)
  for (cc in cols) {
    y <- item_num(d[[cc]])
    if (!length(used) || mean(!is.na(x) & !is.na(y)) < 0.02) { x <- ifelse(is.na(x), y, x); used <- c(used, cc) }
  }
  list(x = x, used = used)
}

from_dummies <- function(d, vs, base) {
  have <- vapply(vs, function(v) !is.na(exact(d, v)), TRUE)
  if (!all(have)) return(NULL)
  out <- rep(base, nrow(d)); allna <- rep(TRUE, nrow(d))
  for (v in vs) {
    x <- num(d[[exact(d, v)]])
    allna <- allna & is.na(x)
    out[!is.na(x) & x == 1] <- v
  }
  out[allna] <- "missing"
  out
}
rawfac <- function(d, pats, tag) {
  v <- findcol(d, pats)
  if (is.na(v)) { msg("  control ", tag, ": not found"); return(rep("all", nrow(d))) }
  t <- labtxt(d[[v]]); t[is.na(t)] <- "missing"
  msg("  control ", tag, " <- raw ", v, " (", length(unique(t)), " levels)")
  t
}
female_from <- function(g) {
  t <- labtxt(g)
  if (any(grepl("[a-z]", t[!is.na(t)]))) return(ifelse(is.na(t), NA_real_, as.numeric(grepl("female|woman|^f", t))))
  n <- num(g); u <- sort(unique(n[!is.na(n)]))
  if (all(u %in% c(0, 1))) return(n)
  if (all(u %in% c(1, 2))) return(as.numeric(n == 2))
  as.numeric(n == max(u))
}

prep_common <- function(d, tag) {
  n <- nrow(d)
  out <- data.frame(row = seq_len(n))
  v <- exact(d, c("pweight", "pw", "weight", "weights", "wgt"))
  pw <- if (!is.na(v)) num(d[[v]]) else rep(NA_real_, n)
  if (all(is.na(pw))) { msg("  ", tag, ": no weights found, using 1"); pw <- rep(1, n) }
  pw[is.na(pw)] <- mean(pw, na.rm = TRUE)
  out$pw <- pw
  v <- exact(d, c("panelID", "panelid", "pid", "id", "respondentid"))
  out$id <- if (!is.na(v)) trimws(as.character(zap_labels(d[[v]]))) else NA_character_
  v <- exact(d, "female")
  gv <- exact(d, "gender")
  out$female <- if (!is.na(v)) num(d[[v]]) else if (!is.na(gv)) female_from(d[[gv]]) else NA_real_
  pol <- from_dummies(d, c("democrat", "indep", "otherpol"), "republican")
  if (is.null(pol)) {
    pv <- exact(d, c("demrep", "party", "partisanship"))
    if (is.na(pv)) pv <- findcol(d, c("^demrep$", "^party", "partisan", "^polit", "political", "^pol$"))
    if (is.na(pv)) { pol <- rep("missing", n); msg("  ", tag, ": no party variable") } else {
      t <- labtxt(d[[pv]])
      pol <- ifelse(is.na(t), "missing",
             ifelse(grepl("democ", t), "democrat",
             ifelse(grepl("republ", t), "republican",
             ifelse(grepl("indep", t), "indep", "otherpol"))))
      lv <- findcol(d, c("lean"))
      if (!is.na(lv)) {
        l <- labtxt(d[[lv]])
        pol[pol == "indep" & !is.na(l) & grepl("democ", l)] <- "democrat"
        pol[pol == "indep" & !is.na(l) & grepl("republ", l)] <- "republican"
      }
      dg("# ", tag, " party var ", pv, if (!is.na(lv)) paste0(" + lean ", lv) else "", ": ", rawtab(d[[pv]], 6))
    }
  }
  out$c_pol <- pol
  out$democrat <- as.numeric(pol == "democrat")
  out$indep <- as.numeric(pol == "indep")
  out$otherpol <- as.numeric(pol == "otherpol")

  rg <- from_dummies(d, c("midwest", "south", "west"), "northeast")
  if (is.null(rg)) rg <- rawfac(d, c("^region$", "region"), "region")
  out$c_region <- rg

  ag <- from_dummies(d, paste0("age", 1:4), "age5")
  if (is.null(ag)) {
    av <- exact(d, "age")
    if (!is.na(av)) {
      a <- num(d[[av]])
      if (length(unique(na.omit(a))) > 10) ag <- as.character(cut(a, c(-Inf, 24, 34, 44, 54, Inf))) else ag <- labtxt(d[[av]])
      ag[is.na(ag)] <- "missing"
    } else ag <- rawfac(d, c("^age"), "age")
  }
  out$c_age <- ag

  kv <- exact(d, "anychildren")
  if (!is.na(kv)) { k <- as.character(num(d[[kv]])); k[is.na(k)] <- "missing" } else
    k <- rawfac(d, c("^anychild", "^children", "^nchild", "^numchild", "^kids", "haschild", "^child$"), "kids")
  out$c_kids <- k

  cv <- exact(d, "associatemore")
  if (!is.na(cv)) { cc <- as.character(num(d[[cv]])); cc[is.na(cc)] <- "missing" } else
    cc <- rawfac(d, c("^educ", "education", "degree"), "college")
  out$c_coll <- cc

  em <- from_dummies(d, c("fulltime", "parttime", "selfemp", "unemployed", "student"), "olf")
  if (is.null(em)) em <- rawfac(d, c("^employment$", "^employ"), "employment")
  out$c_emp <- em

  iv <- exact(d, "loghhinc")
  out$inc_num <- if (!is.na(iv)) num(d[[iv]]) else NA_real_
  out$inc_chr <- rawfac(d, c("^hhincome$", "hhinc", "income"), "income")

  pv <- exact(d, "prior")
  if (is.na(pv)) pv <- findcol(d, c("^prior"))
  if (!is.na(pv)) {
    out$prior <- item_num(d[[pv]]); pused <- pv
  } else {
    pc <- okname(grep("^elicitb|^elicit", names(d), ignore.case = TRUE, value = TRUE))
    pc <- pc[vapply(pc, function(cc) { y <- item_num(d[[cc]]); md <- suppressWarnings(median(y, na.rm = TRUE)); is.finite(md) && md >= 30 && md <= 200 }, TRUE)]
    if (length(pc)) { cr <- coalesce_cols(d, pc); out$prior <- cr$x; pused <- paste(cr$used, collapse = "+") } else { out$prior <- NA_real_; pused <- "NONE" }
  }
  dg("# ", tag, ": prior <- ", pused, "; N=", sum(!is.na(out$prior)), "; summ ", paste(round(summary(out$prior), 1), collapse = " "),
     "; female ", round(mean(out$female, na.rm = TRUE), 3),
     "; pol ", paste(names(table(pol)), table(pol), sep = "=", collapse = ","))
  out
}

# Decode raw main-survey demographic codes (A1, A2, ...) using respondents matched to the
# follow-up files, which carry the authors' coded dummies (female, party, college, kids, log income).
learn_fix <- function(d, out, fu, tag) {
  if (is.null(fu) || all(is.na(out$id)) || all(is.na(fu$id))) return(out)
  mt <- match(out$id, fu$id, incomparables = c(NA, ""))
  ok <- !is.na(mt)
  dg("# ", tag, " matched to follow-up for decoding: ", sum(ok))
  if (sum(ok) < 100) return(out)
  excl <- "^groupTime|^RAND|panelID|date|seed|lastpage|^extra|^elicit|^manicheck|anchor$|^treatment|^Scenario|^reasons|^petition|^attention|donat|amount|^AAUW|^fill|^payoff|^infodemand|^infointro|^womenwage|^menwage|^ownwage|^childcare$|^note$|^controlgroup|^introtreat"
  cand <- okname(names(d)); cand <- cand[!grepl(excl, cand, ignore.case = TRUE)]
  codes <- list()
  for (v in cand) {
    t <- tryCatch(trimws(as.character(zap_labels(d[[v]]))), error = function(e) NULL)
    if (is.null(t) || length(t) != nrow(d)) next
    t[is.na(t) | t == ""] <- "NA"
    nl <- length(unique(t))
    if (nl >= 2 && nl <= 40) codes[[v]] <- t
  }
  if (!length(codes)) return(out)
  pick <- function(y, prefer, label) {
    y <- as.character(y)
    y[!is.na(y) & y %in% c("missing", "NA", "all")] <- NA
    k <- !is.na(y)
    if (sum(k) < 100) { dg("# ", tag, " decode ", label, ": target too sparse"); return(NULL) }
    base <- max(table(y[k])) / sum(k)
    fm <- function(t) {
      tt <- t[ok]; tb <- table(tt[k], y[k])
      mp <- colnames(tb)[apply(tb, 1, which.max)]; names(mp) <- rownames(tb)
      list(pur = sum(apply(tb, 1, max)) / sum(tb), map = mp)
    }
    res <- lapply(codes, fm)
    pur <- vapply(res, function(r) r$pur, 1)
    pv <- intersect(prefer, names(codes)); pv <- pv[pur[pv] >= 0.9]
    v <- if (length(pv)) pv[1] else names(pur)[which.max(pur)]
    dg("# ", tag, " decode ", label, " <- ", v, " (purity ", round(pur[v], 3), ", base ", round(base, 3), "): ",
       paste(names(res[[v]]$map), res[[v]]$map, sep = "->", collapse = ", "))
    if (pur[v] < 0.85 || pur[v] < base + 0.05) { dg("# ", tag, " decode ", label, ": rejected"); return(NULL) }
    unname(res[[v]]$map[codes[[v]]])
  }
  fm_rows <- mt[ok]
  m <- pick(fu$female[fm_rows], c("gender"), "female")
  if (!is.null(m)) out$female <- as.numeric(m)
  m <- pick(fu$c_pol[fm_rows], c("demrep"), "party")
  if (!is.null(m)) {
    m[is.na(m)] <- "missing"
    out$c_pol <- m
    out$democrat <- as.numeric(m == "democrat"); out$indep <- as.numeric(m == "indep"); out$otherpol <- as.numeric(m == "otherpol")
    out$democrat[m == "missing"] <- NA; out$indep[m == "missing"] <- NA; out$otherpol[m == "missing"] <- NA
  }
  m <- pick(fu$c_coll[fm_rows], character(0), "college")
  if (!is.null(m)) { m[is.na(m)] <- "missing"; out$c_coll <- m }
  m <- pick(fu$c_kids[fm_rows], c("childrenSQ001"), "kids")
  if (!is.null(m)) { m[is.na(m)] <- "missing"; out$c_kids <- m }
  yi <- fu$inc_num[fm_rows]; yi <- ifelse(is.na(yi), NA, sprintf("%.6f", yi))
  m <- pick(yi, c("hhincbracket"), "income")
  if (!is.null(m)) { x <- as.numeric(m); x[is.na(x)] <- mean(x, na.rm = TRUE); out$inc_num <- x }
  dg("# ", tag, " after decoding: female ", round(mean(out$female, na.rm = TRUE), 3),
     "; pol ", paste(names(table(out$c_pol)), table(out$c_pol), sep = "=", collapse = ","),
     "; coll ", paste(names(table(out$c_coll)), table(out$c_coll), sep = "=", collapse = ","),
     "; inc nonmiss ", sum(!is.na(out$inc_num)))
  out
}

find_post <- function(d, prior, tag) {
  pc <- exact(d, "posterior")
  if (!is.na(pc)) { x <- item_num(d[[pc]]); attr(x, "src") <- rep("posterior", nrow(d)); return(x) }
  tcols <- which(names(d) %in% c("treatmentACS", "treatmentCPS", "treatmentACSnoinc", "treatmentCPSnoin", "controlgroupnote", "introtreat"))
  start <- if (length(tcols)) max(tcols) else 0
  have_prior <- sum(!is.na(prior)) > 50
  info <- data.frame(v = character(0), n = numeric(0), md = numeric(0), r = numeric(0), stringsAsFactors = FALSE)
  for (v in okname(names(d))) {
    pos <- match(v, names(d))
    if (pos <= start) next
    if (grepl("donat|aauw|lottery|^rand|seed|lastpage|panelid|^id$|elicitb|^prior", v, ignore.case = TRUE)) next
    y <- tryCatch(item_num(d[[v]]), error = function(e) NULL)
    if (is.null(y)) next
    ok <- !is.na(y); n <- sum(ok)
    if (n < 50) next
    md <- median(y[ok]); if (md < 30 || md > 150) next
    if (mean(y[ok] >= 0 & y[ok] <= 200) < 0.9) next
    if (length(unique(y[ok])) < 10) next
    r <- if (have_prior) tryCatch(suppressWarnings(cor(y, prior, use = "complete.obs")), error = function(e) NA) else NA
    if (have_prior && (!is.finite(r) || r < 0.15)) next
    info <- rbind(info, data.frame(v = v, n = n, md = md, r = ifelse(is.finite(r), r, NA), stringsAsFactors = FALSE))
  }
  dg("# ", tag, " posterior candidates: ",
     if (nrow(info)) paste(sprintf("%s(n=%d,md=%.0f,r=%.2f)", info$v, info$n, info$md, info$r), collapse = " ") else "none")
  if (!nrow(info)) { x <- rep(NA_real_, nrow(d)); attr(x, "src") <- rep(NA_character_, nrow(d)); return(x) }
  pref <- grepl("wage|gap|post|belief|earn|stat|elicit", info$v, ignore.case = TRUE)
  info <- info[order(-pref, -info$n), ]
  cr <- coalesce_cols(d, info$v)
  src <- rep(NA_character_, nrow(d))
  for (cc in cr$used) { y <- item_num(d[[cc]]); src[is.na(src) & !is.na(y)] <- cc }
  dg("# ", tag, " posterior <- ", paste(cr$used, collapse = "+"), "; N=", sum(!is.na(cr$x)), "; mean ", round(mean(cr$x, na.rm = TRUE), 2))
  x <- cr$x; attr(x, "src") <- src
  x
}

arm_screens <- function(d, tag) {
  flag <- function(vs) {
    vs <- vs[!is.na(vapply(vs, function(v) exact(d, v), ""))]
    if (!length(vs)) return(NULL)
    Reduce(`|`, lapply(vs, function(v) {
      x <- zap_labels(d[[exact(d, v)]])
      if (is.character(x)) !is.na(x) & trimws(x) != "" else !is.na(x) & x != 0
    }))
  }
  a <- flag(c("treatmentACS", "treatmentACSnoinc"))
  b <- flag(c("treatmentCPS", "treatmentCPSnoin"))
  c0 <- flag(c("controlgroupnote"))
  if (is.null(a) || is.null(b)) return(NULL)
  dg("# ", tag, " screen flags: ACS=", sum(a), " CPS=", sum(b), " ctrlnote=", if (is.null(c0)) "NA" else sum(c0), " overlapAB=", sum(a & b), " n=", nrow(d))
  n <- nrow(d)
  if (sum(a & b) > 0.01 * n || mean(a) < 0.1 || mean(b) < 0.1 || mean(a) > 0.6 || mean(b) > 0.6) return(NULL)
  arm <- ifelse(a, "T74", ifelse(b, "T94", "control"))
  if (mean(arm == "control") < 0.1) return(NULL)
  arm
}

detect_arm <- function(d, post, tag) {
  n <- nrow(d)
  sa <- arm_screens(d, tag)
  if (!is.null(sa)) {
    m <- tapply(post, sa, mean, na.rm = TRUE)
    dg("# ", tag, " arm from screens: ", paste(names(table(sa)), table(sa), sep = "=", collapse = ","),
       "; posterior means ", paste(names(m), round(m, 2), sep = "=", collapse = ","))
    return(sa)
  }
  pri <- c("treatment", "treat", "group", "arm", "t74", "info", "rand", "treatgroup", "condition", "infotreatment", "treatmentgroup")
  best <- NULL; bestscore <- -Inf
  for (v in okname(names(d))) {
    x <- zap_labels(d[[v]])
    if (is.character(x)) { x <- trimws(x); x[x == ""] <- NA }
    g <- as.character(x); g[is.na(g)] <- "NA"
    tb <- table(g)
    if (length(tb) != 3 || min(tb) < 0.1 * n) next
    m <- tapply(post, g, function(z) if (sum(!is.na(z)) < 10) NA_real_ else mean(z, na.rm = TRUE))
    if (sum(!is.na(m)) < 2) next
    sc <- diff(range(m, na.rm = TRUE)) + if (tolower(v) %in% pri) 5 else 0
    if (sc > bestscore) { bestscore <- sc; best <- list(v = v, g = g, m = m) }
  }
  if (is.null(best)) { dg("# ", tag, ": could not detect treatment arm"); return(rep(NA_character_, n)) }
  m <- best$m
  if (sum(is.na(m)) == 1) {
    ctl <- names(m)[is.na(m)]; mm <- m[!is.na(m)]
    t74 <- names(mm)[which.min(mm)]; t94 <- names(mm)[which.max(mm)]
  } else {
    o <- names(sort(m)); t74 <- o[1]; ctl <- o[2]; t94 <- o[3]
  }
  arm <- rep(NA_character_, n)
  arm[best$g == t74] <- "T74"; arm[best$g == t94] <- "T94"; arm[best$g == ctl] <- "control"
  dg("# ", tag, ": arm var = ", best$v, "; post means: ",
     paste(names(m), round(m, 2), sep = "=", collapse = ", "), " -> T74=", t74, " T94=", t94, " ctl=", ctl)
  arm
}

mk_main <- function(d, waveB, tag, fu = NULL) {
  msg("---- building ", tag)
  out <- prep_common(d, tag)
  out <- learn_fix(d, out, fu, tag)
  out$waveB <- waveB
  post <- find_post(d, out$prior, tag)
  src <- attr(post, "src"); if (is.null(src)) src <- rep("all", nrow(d))
  out$posterior <- as.numeric(post)
  out$post_src <- src
  out$arm <- detect_arm(d, out$posterior, tag)
  out$p_large <- get_item(d, c("^large$", "large"), c("large"), "large")
  out$p_problem <- get_item(d, c("^problem$", "^wageproblem$", "problem"), c("problem"), "problem")
  out$p_gov <- get_item(d, c("^govmore$", "^gov$", "^government$", "^govdo", "^gov", "govwomen"), c("government"), "gov")
  mc <- vapply(sprintf("manicheckSQ%03d", 1:3), function(v) exact(d, v), "")
  for (k in 1:3) if (!is.na(mc[k])) dg("# ", tag, " ", mc[k], ": ", rawtab(d[[mc[k]]], 7))
  if (all(is.na(out$p_large)) && all(is.na(out$p_problem)) && all(is.na(out$p_gov)) && all(!is.na(mc))) {
    out$p_large <- item_num(d[[mc[1]]]); out$p_problem <- item_num(d[[mc[2]]]); out$p_gov <- item_num(d[[mc[3]]])
    dg("# ", tag, " perception items <- manicheckSQ001-003; nonmissing ", sum(!is.na(out$p_large)), ",", sum(!is.na(out$p_problem)), ",", sum(!is.na(out$p_gov)))
  }
  out$q_quota <- get_item(d, c("^quotaanchor$", "^genderquota", "quota"), c("quota"), "quota")
  out$q_aa <- get_item(d, c("^aaanchor$", "affirm", "antidiscr", "^aa$"), c("affirmative"), "affirmative action")
  out$q_legis <- get_item(d, c("^legislation$", "equalpay", "legislation"), c("equal pay", "legislation"), "equal pay legislation")
  out$q_tw <- if (waveB == 0) get_item(d, c("^transparency$", "transparen"), c("transparen"), "transparency") else
    get_item(d, c("website", "^reporting", "^report", "web"), c("website"), "website")
  out$q_child <- get_item(d, c("childcare", "child.?care", "daycare", "fampol", "subsid"), c("child ?care", "day ?care"), "childcare")
  dg("# ", tag, " items nonmissing: large ", sum(!is.na(out$p_large)), " problem ", sum(!is.na(out$p_problem)), " gov ", sum(!is.na(out$p_gov)),
     " quota ", sum(!is.na(out$q_quota)), " aa ", sum(!is.na(out$q_aa)), " legis ", sum(!is.na(out$q_legis)),
     " tw ", sum(!is.na(out$q_tw)), " child ", sum(!is.na(out$q_child)))
  out
}

zc <- function(x, base) {
  m <- mean(x[base], na.rm = TRUE); s <- sd(x[base], na.rm = TRUE)
  if (!is.finite(s) || s == 0) return(rep(NA_real_, length(x)))
  (x - m) / s
}

# Anderson (2008) summary index: inverse-covariance weighted mean of the (control-group)
# standardized outcomes.  rescale = FALSE keeps Anderson's definition (the weighted mean of
# z-scores, centered on the control group, not re-divided by its SD).
anderson <- function(Z, base, orient, tag, rescale = TRUE) {
  Z <- as.matrix(Z)
  keep <- apply(Z, 2, function(z) sum(!is.na(z)) > 30)
  Z <- Z[, keep, drop = FALSE]
  if (ncol(Z) == 0) return(rep(NA_real_, nrow(Z)))
  for (j in seq_len(ncol(Z))) {
    r <- tryCatch(suppressWarnings(cor(Z[, j], orient, use = "complete.obs")), error = function(e) NA)
    if (is.finite(r) && r < 0) Z[, j] <- -Z[, j]
  }
  S <- cov(Z, use = "pairwise.complete.obs")
  w <- tryCatch(rowSums(solve(S)), error = function(e) rep(1, ncol(Z)))
  if (any(!is.finite(w))) w <- rep(1, ncol(Z))
  msg("  index ", tag, " cols: ", paste(colnames(Z), collapse = ","), " weights: ", paste(round(w, 3), collapse = ","))
  Z0 <- ifelse(is.na(Z), 0, Z)
  numr <- as.vector(Z0 %*% w)
  den <- as.vector((!is.na(Z)) %*% w)
  idx <- ifelse(rowSums(!is.na(Z)) == 0 | den == 0, NA, numr / den)
  dg("# index ", tag, ": control-group SD of weighted mean = ", round(sd(idx[base], na.rm = TRUE), 4), "; rescale = ", rescale)
  if (rescale) (idx - mean(idx[base], na.rm = TRUE)) / sd(idx[base], na.rm = TRUE) else idx - mean(idx[base], na.rm = TRUE)
}

ctrl_terms <- function(df) {
  nz <- function(x) length(unique(x[!is.na(x)])) > 1
  tm <- character(0)
  if (nz(df$waveB)) tm <- c(tm, "waveB")
  if (nz(df$female)) tm <- c(tm, "female")
  if (nz(df$prior)) tm <- c(tm, "prior")
  for (v in c("c_region", "c_age", "c_kids", "c_coll", "c_emp", "c_pol")) if (nz(df[[v]])) tm <- c(tm, sprintf("factor(%s)", v))
  if (mean(!is.na(df$inc_num)) > 0.9 && nz(df$inc_num)) tm <- c(tm, "inc_num") else if (nz(df$inc_chr)) tm <- c(tm, "factor(inc_chr)")
  tm
}

safe_fit <- function(expr, tag) tryCatch(expr, error = function(e) { msg("fit error (", tag, "): ", conditionMessage(e)); NULL })
cf <- function(m, v) {
  if (is.null(m)) return(NA_real_)
  b <- coef(m); if (!(v %in% names(b))) return(NA_real_)
  s <- tryCatch(sqrt(diag(vcov(m)))[v], error = function(e) NA)
  msg("   coef ", v, " = ", round(b[v], 4), " (se ", round(s, 4), "), N = ", nobs(m))
  unname(b[v])
}

res <- list()

# ------------------------------------------------------------------ follow-up (built first: used to decode raw demographics)
mk_follow <- function(d, waveB, tag) {
  msg("---- building ", tag)
  out <- prep_common(d, tag)
  out$waveB <- waveB
  pv <- exact(d, "posteriorII")
  out$posteriorII <- if (!is.na(pv)) item_num(d[[pv]]) else NA_real_
  rv <- exact(d, "rand")
  out$rand <- if (!is.na(rv)) num(d[[rv]]) else NA_real_
  wp <- function(k) {
    a <- exact(d, sprintf("wageproblemSQ%03d", k)); b <- exact(d, sprintf("wageproblem2SQ%03d", k))
    x <- if (!is.na(a)) item_num(d[[a]]) else rep(NA_real_, nrow(d))
    if (!is.na(b)) { y <- item_num(d[[b]]); x <- ifelse(is.na(x), y, x) }
    x
  }
  labs <- vapply(1:4, function(k) { a <- exact(d, sprintf("wageproblemSQ%03d", k)); if (is.na(a)) "" else tolower(varlab(d[[a]])) }, "")
  hi <- which(grepl("high", labs)); lo <- which(grepl("low", labs)); ge <- which(!grepl("skill|high|low", labs) & labs != "")
  sel <- if (length(hi) && length(lo) && length(ge)) c(ge[1], hi[1], lo[1]) else 1:3
  out$f_a <- wp(sel[1]); out$f_b <- wp(sel[2]); out$f_c <- wp(sel[3])
  gv <- exact(d, "govwomen")
  out$f_gw <- if (!is.na(gv)) item_num(d[[gv]]) else NA_real_
  out
}
fu <- rbind(mk_follow(s2A, 0, "S2A"), mk_follow(s2B, 1, "S2B"))

# ------------------------------------------------------------------ main survey
main <- rbind(mk_main(s1A, 0, "S1A", fu), mk_main(s1B, 1, "S1B", fu))
dg("# Arms: ", paste(names(table(main$arm, useNA = "ifany")), table(main$arm, useNA = "ifany"), sep = "=", collapse = ", "))
ctrl <- !is.na(main$arm) & main$arm == "control"
pmb <- tapply(main$posterior, main$arm, mean, na.rm = TRUE)
dg("# Posterior mean by arm: ", paste(names(pmb), round(pmb, 2), sep = "=", collapse = ", "))

orient_main <- if (isTRUE(sd(main$democrat, na.rm = TRUE) > 0)) main$democrat else main$female

for (v in c("p_large", "p_problem", "p_gov", "q_quota", "q_aa", "q_legis", "q_child")) main[[sub("^(p|q)_", "z_", v)]] <- zc(main[[v]], ctrl)
main$z_tw <- NA_real_
for (w in 0:1) { i <- main$waveB == w; main$z_tw[i] <- zc(main$q_tw[i], ctrl[i]) }

for (v in c("z_aa", "z_legis")) {
  r <- tryCatch(suppressWarnings(cor(main[[v]], orient_main, use = "complete.obs")), error = function(e) NA)
  if (is.finite(r) && r < 0) { main[[v]] <- -main[[v]]; msg("  flipped ", v) }
}

# Summary indices follow Anderson (2008): weighted mean of control-standardized outcomes
# (index itself not re-standardized).
main$perc_index <- anderson(main[, c("z_large", "z_problem", "z_gov")], ctrl, orient_main, "perception", rescale = FALSE)
main$pol_index <- anderson(main[, c("z_quota", "z_aa", "z_legis", "z_tw", "z_child")], ctrl, orient_main, "policy", rescale = FALSE)

# ------------------------------------------------------------------ Table 3 / 4
cg <- main[ctrl, ]
q <- quantile(cg$prior, c(0.05, 0.95), na.rm = TRUE, type = 2)
dg("# Control N=", nrow(cg), "; control prior 5/95 pct: ", paste(q, collapse = ", "))
main$prior_z <- (main$prior - mean(cg$prior, na.rm = TRUE)) / sd(cg$prior, na.rm = TRUE)
t3 <- main[ctrl & !is.na(main$prior) & main$prior > q[1] & main$prior < q[2], ]
dg("# Table 3 trimmed control N = ", nrow(t3))

m3a <- safe_fit(feols(perc_index ~ democrat + female + indep + otherpol + waveB, data = t3, weights = ~pw, vcov = "hetero"), "t3a")
m3b <- safe_fit(feols(perc_index ~ prior_z + waveB, data = t3, weights = ~pw, vcov = "hetero"), "t3b")
m4a <- safe_fit(feols(pol_index ~ democrat + female + indep + otherpol + waveB, data = t3, weights = ~pw, vcov = "hetero"), "t4a")
m4b <- safe_fit(feols(pol_index ~ prior_z + waveB, data = t3, weights = ~pw, vcov = "hetero"), "t4b")

res[["perception_index_democrat_table3_panelA_col4"]] <- cf(m3a, "democrat")
res[["perception_index_female_table3_panelA_col4"]] <- cf(m3a, "female")
res[["perception_index_prior_table3_panelB_col4"]] <- cf(m3b, "prior_z")
res[["n_obs_table3"]] <- if (!is.null(m3a)) nobs(m3a) else nrow(t3)
res[["policy_demand_index_democrat_table4_panelA_col7"]] <- cf(m4a, "democrat")
res[["policy_demand_index_prior_table4_panelB_col7"]] <- cf(m4b, "prior_z")

# ------------------------------------------------------------------ Table 5
# Posterior beliefs expressed in SDs of beliefs: centered on the pure-control-group posterior
# mean and scaled by the SD of (prior) beliefs in the pure control group.
cpost <- main$posterior[ctrl]
if (sum(!is.na(cpost)) >= 30) { pm <- mean(cpost, na.rm = TRUE) } else {
  trp <- main$posterior[!is.na(main$arm) & main$arm %in% c("T74", "T94")]
  pm <- mean(trp, na.rm = TRUE)
}
ps <- sd(cg$prior, na.rm = TRUE)
if (!is.finite(ps) || ps <= 0) ps <- sd(cpost, na.rm = TRUE)
dg("# posterior_z: center ", round(pm, 2), "; scale (control prior SD) ", round(ps, 2),
   "; control posterior SD ", round(sd(cpost, na.rm = TRUE), 2))
main$posterior_z <- (main$posterior - pm) / ps

tr <- main[!is.na(main$arm) & main$arm %in% c("T74", "T94"), ]
tr$T74 <- as.numeric(tr$arm == "T74")
tm5 <- ctrl_terms(tr)
dg("# Table 5 N=", nrow(tr), " controls: ", paste(tm5, collapse = " + "))
rhs <- paste(c("T74", tm5), collapse = " + ")
m5_1 <- safe_fit(feols(as.formula(paste("posterior ~", rhs)), data = tr, weights = ~pw, vcov = "hetero"), "t5c1")
m5_2 <- safe_fit(feols(as.formula(paste("posterior_z ~", rhs)), data = tr, weights = ~pw, vcov = "hetero"), "t5c2")
m5_6 <- safe_fit(feols(as.formula(paste("perc_index ~", rhs)), data = tr, weights = ~pw, vcov = "hetero"), "t5c6")
ivrhs <- if (length(tm5)) paste(tm5, collapse = " + ") else "1"
ivf <- function(y) as.formula(paste(y, "~", ivrhs, "| posterior_z ~ T74"))
m5_iv2 <- safe_fit(feols(ivf("z_aa"), data = tr, weights = ~pw, vcov = "hetero"), "iv aa")
m5_iv3 <- safe_fit(feols(ivf("z_legis"), data = tr, weights = ~pw, vcov = "hetero"), "iv legis")
m5_iv7 <- safe_fit(feols(ivf("pol_index"), data = tr, weights = ~pw, vcov = "hetero"), "iv index")

res[["first_stage_posterior_raw_t74_table5_panelA_col1"]] <- cf(m5_1, "T74")
res[["first_stage_posterior_z_t74_table5_panelA_col2"]] <- cf(m5_2, "T74")
res[["perception_index_t74_table5_panelA_col6"]] <- cf(m5_6, "T74")
res[["iv_affirmative_action_posterior_table5_panelC_col2"]] <- cf(m5_iv2, "fit_posterior_z")
res[["iv_equal_pay_legislation_posterior_table5_panelC_col3"]] <- cf(m5_iv3, "fit_posterior_z")
res[["iv_policy_demand_index_posterior_table5_panelC_col7"]] <- cf(m5_iv7, "fit_posterior_z")

# ------------------------------------------------------------------ follow-up (Table 6)
fu$arm <- NA_character_
mt <- if (all(is.na(main$id)) || all(is.na(fu$id))) rep(NA_integer_, nrow(fu)) else match(fu$id, main$id, incomparables = c(NA, ""))
if (mean(!is.na(mt)) > 0.5) {
  fu$arm <- main$arm[mt]
  dg("# follow-up merged ", sum(!is.na(mt)), "; rand x arm: ", paste(capture.output(print(table(fu$rand, fu$arm, useNA = "ifany"))), collapse = " / "))
}
if (all(is.na(fu$arm) | fu$arm == "control")) {
  for (w in 0:1) {
    i <- fu$waveB == w
    m <- tapply(fu$posteriorII[i], fu$rand[i], mean, na.rm = TRUE)
    dg("# wave ", w, " posteriorII by rand: ", paste(names(m), round(m, 2), sep = "=", collapse = ", "))
    if (length(m) >= 2) {
      lo <- names(m)[which.min(m)]; hi <- names(m)[which.max(m)]
      fu$arm[i & !is.na(fu$rand) & as.character(fu$rand) == lo] <- "T74"
      fu$arm[i & !is.na(fu$rand) & as.character(fu$rand) == hi] <- "T94"
    }
  }
}
fs <- fu[!is.na(fu$arm) & fu$arm %in% c("T74", "T94"), ]
fs$T74 <- as.numeric(fs$arm == "T74")
dg("# Follow-up sample N = ", nrow(fs), "; T74 share = ", round(mean(fs$T74), 3))
allf <- rep(TRUE, nrow(fs))
for (v in c("f_a", "f_b", "f_c", "f_gw")) fs[[paste0("z", v)]] <- zc(fs[[v]], allf)
orient_f <- if (isTRUE(sd(fs$democrat, na.rm = TRUE) > 0)) fs$democrat else fs$female
fs$f_index <- anderson(fs[, c("zf_a", "zf_gw", "zf_b", "zf_c")], allf, orient_f, "follow-up perception")
tm6 <- ctrl_terms(fs)
m6 <- safe_fit(feols(as.formula(paste("f_index ~", paste(c("T74", tm6), collapse = " + "))), data = fs, weights = ~pw, vcov = "hetero"), "t6")
res[["followup_perception_index_t74_table6_panelA_col7"]] <- cf(m6, "T74")

# ------------------------------------------------------------------ output
for (nm in names(res)) {
  v <- res[[nm]]
  if (length(v) == 1 && is.finite(v)) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
}
if (all(main$pw == 1)) cat("DEVIATION: Survey probability weights not present in raw files; regressions are unweighted\n")
cat("DEVIATION: Raw main-survey demographic answer codes (gender, party, education, children, income bracket) carry no value labels; they were decoded by matching respondents to the follow-up files' coded dummies (female, democrat/indep/otherpol, associatemore, anychildren, loghhinc)\n")
cat("DEVIATION: Main-survey summary indices (perception, policy demand) are the Anderson (2008) inverse-covariance weighted mean of control-standardized outcomes, not re-standardized to unit control-group SD (paper's exact index normalization not stated in the summary)\n")
cat("DEVIATION: Posterior beliefs expressed in SD units using the pure-control-group SD of beliefs (prior belief SD), since posteriors refer to different randomly assigned wage statistics\n")

# compact diagnostics (stdout)
compact_names <- function(d) {
  n <- okname(names(d)); n <- n[!grepl("^petition|^attention", n, ignore.case = TRUE)]
  unique(sub("SQ[0-9]+$", "SQ*", n))
}
for (s in dlog) cat(substr(gsub("[\r\n]+", " ", s), 1, 400), "\n", sep = "")
nA <- compact_names(s1A); nB <- compact_names(s1B)
cat("# S1A names: ", paste(nA, collapse = " "), "\n", sep = "")
cat("# S1B extra names: ", paste(setdiff(nB, nA), collapse = " "), "\n", sep = "")
