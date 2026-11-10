suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy.script-free"
dd <- file.path(root, "data")
s1a <- read_dta(file.path(dd, "SurveyStageI_WaveA_raw.dta"))
s1b <- read_dta(file.path(dd, "SurveyStageI_WaveB_raw.dta"))
s2a <- read_dta(file.path(dd, "SurveyStageII_WaveA_raw.dta"))
s2b <- read_dta(file.path(dd, "SurveyStageII_WaveB_raw.dta"))

# ------------------------------------------------------------------ helpers
tonum <- function(x) {
  if (is.null(x)) return(NULL)
  x <- zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.logical(x)) return(as.numeric(x))
  if (inherits(x, c("Date", "POSIXct", "POSIXt"))) return(as.numeric(x))
  if (is.character(x)) {
    x[!is.na(x) & trimws(x) %in% c("", "NA", ".")] <- NA
    y <- suppressWarnings(as.numeric(x))
    nn <- !is.na(x)
    if (sum(nn) > 0 && mean(is.na(y[nn])) > 0.5) {
      y <- suppressWarnings(as.numeric(gsub("[^0-9.\\-]", "", x)))
    }
    return(y)
  }
  as.numeric(x)
}

getlab <- function(x) {
  l <- attr(x, "label")
  if (is.null(l)) "" else as.character(l)[1]
}

describe_df <- function(df, nm) {
  message("==== ", nm, " (", nrow(df), " x ", ncol(df), ")")
  for (v in names(df)) {
    x <- df[[v]]
    ex <- tryCatch(paste(head(unique(as.character(zap_labels(x))), 4), collapse = "|"),
                   error = function(e) "")
    message(sprintf("  %s [%s] %s :: %s", v, class(x)[1], substr(getlab(x), 1, 70), substr(ex, 1, 50)))
  }
}
for (pair in list(list(s1a, "StageI_A"), list(s1b, "StageI_B"), list(s2a, "StageII_A"), list(s2b, "StageII_B"))) {
  tryCatch(describe_df(pair[[1]], pair[[2]]), error = function(e) message("describe error: ", conditionMessage(e)))
}

nonempty <- function(df, v) {
  x <- tryCatch(as.character(zap_labels(df[[v]])), error = function(e) as.character(df[[v]]))
  sum(!is.na(x) & trimws(x) != "") > 0
}

EXCL <- "time$|anchor|order|calculation|summary|^any|note$"
findcol <- function(df, exact = character(0), regex = character(0), labrx = character(0), excl = EXCL) {
  nms <- names(df); low <- tolower(nms)
  for (e in exact) {
    i <- which(low == tolower(e))
    i <- i[vapply(i, function(j) nonempty(df, nms[j]), logical(1))]
    if (length(i)) return(nms[i[1]])
  }
  ok <- !grepl(excl, nms, ignore.case = TRUE)
  for (r in regex) {
    i <- which(grepl(r, nms, ignore.case = TRUE) & ok)
    i <- i[vapply(i, function(j) nonempty(df, nms[j]), logical(1))]
    if (length(i)) return(nms[i[1]])
  }
  if (length(labrx)) {
    labs <- vapply(nms, function(v) getlab(df[[v]]), "")
    for (r in labrx) {
      i <- which(grepl(r, labs, ignore.case = TRUE) & ok)
      i <- i[vapply(i, function(j) nonempty(df, nms[j]), logical(1))]
      if (length(i)) return(nms[i[1]])
    }
  }
  NA_character_
}

is_reversed <- function(x) {
  labs <- attr(x, "labels")
  if (is.null(labs) || length(labs) < 2) return(FALSE)
  lv <- tonum(unname(labs)); nm <- tolower(names(labs))
  ok <- !is.na(lv)
  if (sum(ok) < 2) return(FALSE)
  lv <- lv[ok]; nm <- nm[ok]
  first <- nm[which.min(lv)]
  pos <- "strongly agree|^agree|strongly support|^support|very large|definitely|very much|a great deal"
  neg <- "disagree|oppose|not |small|no "
  grepl(pos, first) && !grepl(neg, first)
}

orient <- function(x) {
  v <- tonum(x)
  if (is_reversed(x) && any(!is.na(v))) {
    v <- max(v, na.rm = TRUE) + min(v, na.rm = TRUE) - v
  }
  v
}

get_female <- function(df) {
  c1 <- findcol(df, exact = c("female"))
  if (!is.na(c1)) return(tonum(df[[c1]]))
  c2 <- findcol(df, exact = c("gender", "sex"))
  if (is.na(c2)) return(rep(NA_real_, nrow(df)))
  x <- df[[c2]]
  labs <- attr(x, "labels")
  raw <- zap_labels(x)
  if (is.character(raw)) {
    s <- toupper(trimws(raw))
    if (any(s %in% c("F", "FEMALE", "W", "WOMAN"), na.rm = TRUE)) {
      out <- as.numeric(s %in% c("F", "FEMALE", "W", "WOMAN"))
      out[is.na(s) | s == ""] <- NA
      return(out)
    }
  }
  v <- tonum(x)
  if (!is.null(labs)) {
    fl <- labs[grepl("female|woman|women", names(labs), ignore.case = TRUE)]
    if (length(fl)) return(as.numeric(v == tonum(unname(fl[1]))))
  }
  uv <- sort(unique(v[!is.na(v)]))
  if (length(uv) && all(uv %in% c(0, 1))) return(v)
  if (length(uv) && all(uv %in% c(1, 2))) return(as.numeric(v == 2))
  rep(NA_real_, nrow(df))
}

CTRL <- c("midwest", "south", "west", "age1", "age2", "age3", "age4", "anychildren",
          "loghhinc", "associatemore", "fulltime", "parttime", "selfemp", "unemployed",
          "student", "democrat", "indep", "otherpol")

get_posterior <- function(df, pattern = "^posterior") {
  n <- nrow(df)
  nms <- names(df)
  pc <- nms[grepl(pattern, nms, ignore.case = TRUE) &
              !grepl("time$|order|anchor|version|rand|type", nms, ignore.case = TRUE)]
  post <- rep(NA_real_, n)
  used <- character(0)
  for (p in pc) {
    v <- tonum(df[[p]])
    vv <- v[!is.na(v)]
    if (length(vv) && median(vv) > 20 && median(vv) <= 200) {
      post <- ifelse(is.na(post), v, post)
      used <- c(used, p)
    }
  }
  message("Posterior columns used: ", paste(used, collapse = ","))
  post
}

detect_group <- function(df, post, wname) {
  n <- nrow(df)
  nulres <- list(group = rep(NA_character_, n), map = NULL, var = NA_character_)
  c74 <- findcol(df, exact = c("t74", "treat74", "treatment74"))
  c94 <- findcol(df, exact = c("t94", "treat94", "treatment94"))
  if (!is.na(c74) && !is.na(c94)) {
    a <- tonum(df[[c74]]); b <- tonum(df[[c94]])
    g <- ifelse(a %in% 1, "T74", ifelse(b %in% 1, "T94", "C"))
    message("Group from T74/T94 dummies in ", wname)
    return(list(group = g, map = NULL, var = NA_character_))
  }
  rc <- findcol(df, exact = c("rand", "treatment", "treat", "group", "treatmentgroup",
                              "condition", "arm", "randtreat", "treatmentarm"))
  if (is.na(rc)) { message("No treatment variable found in ", wname); return(nulres) }
  x <- df[[rc]]
  key <- as.character(zap_labels(x))
  key[!is.na(key) & trimws(key) == ""] <- NA
  uk <- sort(unique(key[!is.na(key)]))
  message("Treatment var '", rc, "' in ", wname, ": ", length(uk), " levels: ",
          paste(head(uk, 10), collapse = ","))
  if (length(uk) > 5 || length(uk) < 2) { message("Unusable treatment variable"); return(nulres) }
  for (k in uk) {
    p <- post[key %in% k]
    message(sprintf("   level %s: n=%d, mean post=%.2f, share~74=%.3f, share~94=%.3f", k, sum(key %in% k),
                    mean(p, na.rm = TRUE), mean(abs(p - 74) <= 2.5, na.rm = TRUE), mean(abs(p - 94) <= 2.5, na.rm = TRUE)))
  }
  message("   NA level n=", sum(is.na(key)))
  map <- setNames(rep(NA_character_, length(uk)), uk)
  labs <- attr(x, "labels")
  for (k in uk) {
    nmk <- k
    if (!is.null(labs)) {
      j <- which(as.character(labs) == k)
      if (length(j)) nmk <- paste(k, names(labs)[j[1]])
    }
    if (grepl("74", nmk)) map[k] <- "T74"
    else if (grepl("94", nmk)) map[k] <- "T94"
    else if (grepl("control|pure|no.?info|none", nmk, ignore.case = TRUE)) map[k] <- "C"
  }
  if (any(is.na(map)) && length(uk) %in% c(2, 3)) {
    s74 <- sapply(uk, function(k) { p <- post[key %in% k]; p <- p[!is.na(p)]
      if (length(p)) mean(abs(p - 74) <= 2.5) else -1 })
    s94 <- sapply(uk, function(k) { p <- post[key %in% k]; p <- p[!is.na(p)]
      if (length(p)) mean(abs(p - 94) <= 2.5) else -1 })
    map[] <- NA_character_
    i74 <- which.max(s74)
    s94b <- s94; s94b[i74] <- -Inf
    i94 <- which.max(s94b)
    map[i74] <- "T74"; map[i94] <- "T94"
    if (length(uk) == 3) map[setdiff(seq_along(uk), c(i74, i94))] <- "C"
    message("   heuristic mapping used")
  }
  message("   mapping: ", paste(names(map), map, sep = "->", collapse = ", "))
  g <- unname(map[key])
  if (length(uk) == 2) g[is.na(key)] <- "C"
  list(group = g, map = map, var = rc)
}

zc <- function(x, ref) {
  m <- mean(x[ref], na.rm = TRUE); s <- sd(x[ref], na.rm = TRUE)
  if (!is.finite(s) || s == 0) return(rep(NA_real_, length(x)))
  (x - m) / s
}

anderson <- function(Z, ref) {
  Z <- as.matrix(Z)
  keep <- colSums(!is.na(Z[ref, , drop = FALSE])) > 10
  Z <- Z[, keep, drop = FALSE]
  if (ncol(Z) == 0) return(rep(NA_real_, nrow(Z)))
  S <- cov(Z[ref, , drop = FALSE], use = "pairwise.complete.obs")
  S[is.na(S)] <- 0
  Si <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  w <- rowSums(Si)
  idx <- apply(Z, 1, function(z) {
    ok <- !is.na(z)
    if (!any(ok)) NA_real_ else sum(w[ok] * z[ok]) / sum(w[ok])
  })
  zc(idx, ref)
}

# ------------------------------------------------------------------ Stage I
build1 <- function(df, w) {
  n <- nrow(df)
  post <- get_posterior(df)
  gi <- detect_group(df, post, paste("StageI", w))
  pc <- findcol(df, exact = c("prior"), regex = c("^prior"))
  wc <- findcol(df, exact = c("pweight", "weight", "weights", "wgt"))
  pid <- findcol(df, exact = c("panelid"))
  out <- data.frame(wave = rep(w, n), waveB = as.numeric(w == "B"), stringsAsFactors = FALSE)
  out$group <- gi$group
  out$female <- get_female(df)
  out$prior <- if (is.na(pc)) NA_real_ else tonum(df[[pc]])
  out$post <- post
  out$pweight <- if (is.na(wc)) 1 else tonum(df[[wc]])
  out$panelID <- if (is.na(pid)) NA_character_ else as.character(zap_labels(df[[pid]]))
  for (cv in CTRL) {
    cc <- findcol(df, exact = cv)
    if (is.na(cc)) message("Missing control ", cv, " in StageI ", w)
    out[[cv]] <- if (is.na(cc)) NA_real_ else tonum(df[[cc]])
  }
  items <- list(
    large = findcol(df, exact = c("large", "wagegaplarge", "gaplarge", "sizelarge"), regex = c("large"), labrx = c("large")),
    problem = findcol(df, exact = c("problem", "wageproblem", "gapproblem"), regex = c("problem"), labrx = c("problem")),
    gov = findcol(df, exact = c("gov", "government", "govmore", "govdo"), regex = c("^gov", "government"), labrx = c("government should")),
    quota = findcol(df, exact = c("quota", "quotas"), regex = c("quota"), labrx = c("quota")),
    affirm = findcol(df, exact = c("affirmative", "affirmativeaction", "aa"), regex = c("affirm"), labrx = c("affirmative")),
    legis = findcol(df, exact = c("legislation", "equalpay"), regex = c("legislation", "equalpay"), labrx = c("equal pay|legislation")),
    transp = if (w == "A") findcol(df, exact = c("transparency"), regex = c("transparen"), labrx = c("transparen")) else NA_character_,
    website = if (w == "B") findcol(df, exact = c("website", "reporting", "reportingwebsite"), regex = c("website", "reporting"), labrx = c("website")) else NA_character_,
    childcare = findcol(df, exact = c("childcare", "daycare"), regex = c("childcare", "daycare", "child.?care"), labrx = c("child.?care|day.?care"))
  )
  message("StageI ", w, " items: ", paste(names(items), unlist(items), sep = "=", collapse = ", "))
  for (k in names(items)) {
    out[[k]] <- if (is.na(items[[k]])) NA_real_ else orient(df[[items[[k]]]])
  }
  message("Group table StageI ", w, ": ", paste(capture.output(print(table(out$group, useNA = "ifany"))), collapse = " "))
  message("Female table StageI ", w, ": ", paste(capture.output(print(table(out$female, useNA = "ifany"))), collapse = " "))
  list(data = out, gi = gi)
}

b1a <- build1(s1a, "A")
b1b <- build1(s1b, "B")
s1 <- rbind(b1a$data, b1b$data)
if (all(is.na(s1$pweight))) s1$pweight <- 1

ctrl <- s1$group %in% "C"
for (k in c("large", "problem", "gov", "quota", "affirm", "legis", "transp", "website", "childcare")) {
  s1[[paste0("z_", k)]] <- zc(s1[[k]], ctrl)
}
s1$z_tw <- ifelse(!is.na(s1$z_transp), s1$z_transp, s1$z_website)
s1$perc_idx <- anderson(s1[, c("z_large", "z_problem", "z_gov")], ctrl)
s1$pol_idx <- anderson(s1[, c("z_quota", "z_affirm", "z_legis", "z_tw", "z_childcare")], ctrl)

ref_p <- ctrl & !is.na(s1$post)
if (sum(ref_p) < 30) ref_p <- s1$group %in% c("T74", "T94") & !is.na(s1$post)
s1$post_z <- zc(s1$post, ref_p)

safe_coef <- function(fml, data, term) {
  tryCatch({
    data <- data[!is.na(data$pweight), , drop = FALSE]
    m <- feols(fml, data = data, weights = ~pweight, vcov = "hetero")
    cf <- coef(m)
    message("Model: ", deparse(fml), " | N=", nobs(m), " | ", term, "=",
            if (term %in% names(cf)) signif(cf[term], 6) else "NA")
    if (term %in% names(cf)) list(b = unname(cf[term]), n = nobs(m))
    else { message("term ", term, " not in ", paste(names(cf), collapse = ",")); list(b = NA_real_, n = nobs(m)) }
  }, error = function(e) { message("ERR (", term, "): ", conditionMessage(e)); list(b = NA_real_, n = NA_real_) })
}

avail_ctrls <- function(d, vars) {
  vars[vapply(vars, function(v) v %in% names(d) && sum(!is.na(d[[v]])) > 0 &&
                length(unique(na.omit(d[[v]]))) > 1, logical(1))]
}

# ------------------------------------------------------------------ Table 3 / 4
cg <- s1[ctrl & !is.na(s1$prior), ]
q <- quantile(cg$prior, c(0.05, 0.95), type = 2, na.rm = TRUE)
message("Prior trimming percentiles: ", paste(q, collapse = ", "))
t3 <- cg[cg$prior > q[1] & cg$prior < q[2], ]
t3$prior_z <- (t3$prior - mean(t3$prior)) / sd(t3$prior)

fA_perc <- perc_idx ~ democrat + female + indep + otherpol + waveB
fB_perc <- perc_idx ~ prior_z + waveB
fA_pol <- pol_idx ~ democrat + female + indep + otherpol + waveB
fB_pol <- pol_idx ~ prior_z + waveB

r1 <- safe_coef(fA_perc, t3, "democrat")
r2 <- safe_coef(fA_perc, t3, "female")
r3 <- safe_coef(fB_perc, t3, "prior_z")
n3 <- r1$n
if (is.na(n3)) n3 <- nrow(t3)
r5 <- safe_coef(fA_pol, t3, "democrat")
r6 <- safe_coef(fB_pol, t3, "prior_z")

# ------------------------------------------------------------------ Table 5
t5 <- s1[s1$group %in% c("T74", "T94"), ]
t5$T74 <- as.numeric(t5$group == "T74")
ctrl5 <- avail_ctrls(t5, c("waveB", "female", "prior", CTRL))
message("Table 5 controls: ", paste(ctrl5, collapse = ","))
rhs <- paste(c("T74", ctrl5), collapse = " + ")
exo <- if (length(ctrl5)) paste(ctrl5, collapse = " + ") else "1"

r7 <- safe_coef(as.formula(paste("post ~", rhs)), t5, "T74")
r8 <- safe_coef(as.formula(paste("post_z ~", rhs)), t5, "T74")
r9 <- safe_coef(as.formula(paste("perc_idx ~", rhs)), t5, "T74")
r10 <- safe_coef(as.formula(paste0("z_affirm ~ ", exo, " | post_z ~ T74")), t5, "fit_post_z")
r11 <- safe_coef(as.formula(paste0("z_legis ~ ", exo, " | post_z ~ T74")), t5, "fit_post_z")
r12 <- safe_coef(as.formula(paste0("pol_idx ~ ", exo, " | post_z ~ T74")), t5, "fit_post_z")

# ------------------------------------------------------------------ Table 6 (follow-up)
pick_wp <- function(df) {
  nms <- names(df)
  res <- list(general = character(0), high = character(0), low = character(0))
  for (pref in c("wageproblem", "wageproblem2")) {
    cols <- nms[grepl(paste0("^", pref, "SQ00[0-9]$"), nms, ignore.case = TRUE)]
    if (!length(cols)) next
    labs <- vapply(cols, function(v) tolower(getlab(df[[v]])), "")
    hi <- cols[grepl("high", labs)]; lo <- cols[grepl("low", labs)]
    ge <- cols[!grepl("high|low|skill", labs)]
    if (!length(hi)) hi <- cols[grepl("SQ002$", cols, ignore.case = TRUE)]
    if (!length(lo)) lo <- cols[grepl("SQ003$", cols, ignore.case = TRUE)]
    if (!length(ge) || all(labs == "")) ge <- cols[grepl("SQ001$", cols, ignore.case = TRUE)]
    res$general <- c(res$general, ge[1]); res$high <- c(res$high, hi[1]); res$low <- c(res$low, lo[1])
  }
  res
}

coalesce_cols <- function(df, cols) {
  cols <- cols[!is.na(cols)]
  out <- rep(NA_real_, nrow(df))
  for (cc in cols) { v <- orient(df[[cc]]); out <- ifelse(is.na(out), v, out) }
  out
}

build2 <- function(df, w, b1) {
  n <- nrow(df)
  s1w <- b1$data; gi1 <- b1$gi
  g <- rep(NA_character_, n)
  pid2 <- findcol(df, exact = c("panelid"))
  if (!is.na(pid2) && any(!is.na(s1w$panelID))) {
    k2 <- as.character(zap_labels(df[[pid2]]))
    g <- s1w$group[match(k2, s1w$panelID)]
    message("StageII ", w, " matched via panelID: ", sum(g %in% c("T74", "T94")), " of ", n)
  }
  if (sum(g %in% c("T74", "T94")) < 0.5 * n && !is.na(gi1$var) && !is.null(gi1$map)) {
    c2 <- findcol(df, exact = gi1$var)
    if (!is.na(c2)) {
      key <- as.character(zap_labels(df[[c2]]))
      g2 <- unname(gi1$map[key])
      message("StageII ", w, " mapped via StageI coding of ", c2, ": ", sum(g2 %in% c("T74", "T94")))
      if (sum(g2 %in% c("T74", "T94")) > sum(g %in% c("T74", "T94"))) g <- g2
    }
  }
  if (sum(g %in% c("T74", "T94")) < 0.5 * n) {
    p2 <- get_posterior(df, "^posterior")
    gi2 <- detect_group(df, p2, paste("StageII", w))
    if (sum(gi2$group %in% c("T74", "T94")) > sum(g %in% c("T74", "T94"))) g <- gi2$group
  }
  wp <- pick_wp(df)
  gw <- findcol(df, exact = c("govwomen"), regex = c("govwomen"))
  message("StageII ", w, " items: general=", paste(wp$general, collapse = "/"), " high=", paste(wp$high, collapse = "/"),
          " low=", paste(wp$low, collapse = "/"), " gov=", gw)
  pc <- findcol(df, exact = c("prior"))
  wc <- findcol(df, exact = c("pweight", "weight"))
  out <- data.frame(wave = rep(w, n), waveB = as.numeric(w == "B"), stringsAsFactors = FALSE)
  out$group <- g
  out$female <- get_female(df)
  out$prior <- if (is.na(pc)) NA_real_ else tonum(df[[pc]])
  out$pweight <- if (is.na(wc)) 1 else tonum(df[[wc]])
  for (cv in CTRL) {
    cc <- findcol(df, exact = cv)
    out[[cv]] <- if (is.na(cc)) NA_real_ else tonum(df[[cc]])
  }
  out$fu_problem <- coalesce_cols(df, wp$general)
  out$fu_gov <- if (is.na(gw)) NA_real_ else orient(df[[gw]])
  out$fu_high <- coalesce_cols(df, wp$high)
  out$fu_low <- coalesce_cols(df, wp$low)
  message("Group table StageII ", w, ": ", paste(capture.output(print(table(out$group, useNA = "ifany"))), collapse = " "))
  out
}

fu <- tryCatch(rbind(build2(s2a, "A", b1a), build2(s2b, "B", b1b)),
               error = function(e) { message("Follow-up build error: ", conditionMessage(e)); NULL })

r13 <- list(b = NA_real_)
if (!is.null(fu)) {
  if (all(is.na(fu$pweight))) fu$pweight <- 1
  allfu <- rep(TRUE, nrow(fu))
  for (k in c("fu_problem", "fu_gov", "fu_high", "fu_low")) fu[[paste0("z_", k)]] <- zc(fu[[k]], allfu)
  fu$fu_idx <- anderson(fu[, c("z_fu_problem", "z_fu_gov", "z_fu_high", "z_fu_low")], allfu)
  t6 <- fu[fu$group %in% c("T74", "T94"), ]
  t6$T74 <- as.numeric(t6$group == "T74")
  ctrl6 <- avail_ctrls(t6, c("waveB", "female", "prior", CTRL))
  r13 <- safe_coef(as.formula(paste("fu_idx ~", paste(c("T74", ctrl6), collapse = " + "))), t6, "T74")
}

# ------------------------------------------------------------------ output
fmt <- function(x) if (is.null(x) || length(x) == 0 || is.na(x)) "NA" else format(x, digits = 10)
cat(sprintf("RESULT:perception_index_democrat_table3_panelA_col4=%s\n", fmt(r1$b)))
cat(sprintf("RESULT:perception_index_female_table3_panelA_col4=%s\n", fmt(r2$b)))
cat(sprintf("RESULT:perception_index_prior_table3_panelB_col4=%s\n", fmt(r3$b)))
cat(sprintf("RESULT:n_obs_table3=%s\n", fmt(n3)))
cat(sprintf("RESULT:policy_demand_index_democrat_table4_panelA_col7=%s\n", fmt(r5$b)))
cat(sprintf("RESULT:policy_demand_index_prior_table4_panelB_col7=%s\n", fmt(r6$b)))
cat(sprintf("RESULT:first_stage_posterior_raw_t74_table5_panelA_col1=%s\n", fmt(r7$b)))
cat(sprintf("RESULT:first_stage_posterior_z_t74_table5_panelA_col2=%s\n", fmt(r8$b)))
cat(sprintf("RESULT:perception_index_t74_table5_panelA_col6=%s\n", fmt(r9$b)))
cat(sprintf("RESULT:iv_affirmative_action_posterior_table5_panelC_col2=%s\n", fmt(r10$b)))
cat(sprintf("RESULT:iv_equal_pay_legislation_posterior_table5_panelC_col3=%s\n", fmt(r11$b)))
cat(sprintf("RESULT:iv_policy_demand_index_posterior_table5_panelC_col7=%s\n", fmt(r12$b)))
cat(sprintf("RESULT:followup_perception_index_t74_table6_panelA_col7=%s\n", fmt(r13$b)))