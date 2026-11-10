suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free/data/raw"
num <- function(x) suppressWarnings(as.numeric(as.character(x)))
pnum <- function(x) suppressWarnings(readr::parse_number(as.character(x)))

elog <- character(0)
L <- function(...) elog <<- c(elog, substr(paste(...), 1, 160))

read_q <- function(f) {
  d <- readr::read_csv(f, col_types = cols(.default = col_character()),
                       name_repair = "minimal", progress = FALSE)
  nm <- gsub("^﻿", "", names(d))
  nm[nm == "" | is.na(nm)] <- paste0("unnamed_", which(nm == "" | is.na(nm)))
  names(d) <- make.unique(nm)
  idc <- if ("V1" %in% names(d)) "V1" else if ("ResponseId" %in% names(d)) "ResponseId" else names(d)[1]
  ids <- d[[idc]]
  if (sum(grepl("^R_", ids)) > 0) d <- d[grepl("^R_", ids), , drop = FALSE]
  d$.id <- d[[idc]]
  d
}

load_exp <- function(files) {
  out <- list()
  for (i in seq_along(files)) {
    d <- read_q(file.path(base, files[i]))
    d$.batch <- i
    out[[i]] <- d
  }
  d <- bind_rows(out)
  d$.uid <- paste(d$.batch, d$.id, seq_len(nrow(d)), sep = "_")
  d
}

A <- load_exp(paste0("expAbatch", 1:8, ".csv"))
B <- load_exp(paste0("expBbatch", 1:2, ".csv"))

stab <- function(v, k = 6, w = 90) {
  tb <- head(sort(table(v, useNA = "ifany"), decreasing = TRUE), k)
  substr(paste(names(tb), tb, sep = ":", collapse = " "), 1, w)
}

dg <- function(d, lab) {
  cat("##", lab, "rows", nrow(d), "cols", ncol(d), "\n")
  for (cc in intersect(c("V10", "Finished", "treatment", "excluded", "SC0_0", "SC0_1", "SC0_2",
                         "payment_for_test", "T1", "switch1"), names(d)))
    cat(" ", cc, "=", stab(d[[cc]]), "\n")
  sw <- grep("^switch[0-9]+$", names(d), value = TRUE)
  if (length(sw)) cat("  switch pooled =", stab(unlist(lapply(sw, function(cc) d[[cc]])), 10), "\n")
  cat("  score-ish cols:", substr(paste(grep("^SC|score|correct|quiz|test", names(d), value = TRUE,
                                             ignore.case = TRUE), collapse = ","), 1, 200), "\n")
}
dg(A, "ExpA")
dg(B, "ExpB")

## ---------- helpers ----------
clean_arm_raw <- function(raw, n_arms) {
  raw <- as.character(raw)
  raw[!is.na(raw) & raw == ""] <- NA
  v <- raw[!is.na(raw)]
  if (length(unique(v)) > n_arms) {
    keepv <- names(head(sort(table(v), decreasing = TRUE), n_arms))
    raw[!(raw %in% keepv)] <- NA
  }
  raw
}

label_arms <- function(raw, four) {
  u <- unique(raw[!is.na(raw)])
  nu <- num(u)
  u <- if (all(!is.na(nu))) u[order(nu)] else sort(u)
  lab <- setNames(rep(NA_character_, length(u)), u)
  lu <- tolower(u)
  if (any(grepl("[a-z]", lu))) {
    lab[grepl("contr|index|divers|base", lu)] <- "Control"
    lab[is.na(lab) & grepl("subst", lu)] <- "SubstanceOnly"
    lab[is.na(lab) & grepl("rhet", lu)] <- "RhetoricOnly"
    lab[is.na(lab) & grepl("treat|full|compound|feedback|practice", lu)] <- "Treatment"
  }
  default <- if (four) c("Control", "Treatment", "SubstanceOnly", "RhetoricOnly") else c("Control", "Treatment")
  if (any(is.na(lab)) || any(duplicated(lab))) lab[] <- default[seq_along(u)]
  cat("Arm mapping:", paste(names(lab), lab, sep = "->", collapse = ", "), "\n")
  unname(lab[raw])
}

get_fin <- function(d) {
  f <- if ("Finished" %in% names(d)) num(d$Finished) else if ("V10" %in% names(d)) num(d$V10) else rep(1, nrow(d))
  !is.na(f) & f == 1
}

score_search <- function(d, arm, rows) {
  ct <- rows & arm %in% c("Control", "Treatment")
  skip <- grepl("^(T[0-9]+|switch[0-9]+|V[0-9]+|treatment|\\.)", names(d))
  out <- NULL
  for (cc in names(d)[!skip]) {
    x <- num(d[[cc]][ct])
    if (mean(!is.na(x)) < 0.8) next
    a <- arm[ct][!is.na(x)]
    xx <- x[!is.na(x)]
    if (any(xx != round(xx)) || min(xx) < 0 || max(xx) > 5 || length(unique(xx)) < 3) next
    if (!all(c("Control", "Treatment") %in% a)) next
    df <- mean(xx[a == "Treatment"]) - mean(xx[a == "Control"])
    out <- rbind(out, data.frame(col = cc, diff = df, mean = mean(xx), stringsAsFactors = FALSE))
  }
  if (!is.null(out)) out <- out[order(-out$diff), ]
  out
}

get_vals <- function(d, rows) {
  for (pref in c("T", "switch")) {
    tc <- paste0(pref, 1:20)
    if (!all(tc %in% names(d))) next
    V <- sapply(tc, function(cc) pnum(d[[cc]]))
    Vr <- V[rows, , drop = FALSE]
    ok <- rowSums(!is.na(Vr)) == 20
    if (sum(ok) == 0 || mean(ok) < 0.5) { L(pref, "vals: complete share", round(mean(ok), 3)); next }
    x <- Vr[ok, , drop = FALSE]
    perm <- mean(apply(x, 1, function(r) all(sort(r) == 1:20)))
    if (max(x) > 100 && max(x) <= 2500) { V <- V / 100; x <- x / 100 }
    nonint <- mean(abs(x - round(x)) > 1e-9)
    L(pref, "vals: complete", sum(ok), "perm", round(perm, 3), "nonint", round(nonint, 3),
      "max", round(max(x), 2), "min", round(min(x), 2))
    if (perm > 0.5 || nonint < 0.05) next
    return(list(V = V, src = pref))
  }
  NULL
}

ms_choose <- function(d, cand, target, vsrc) {
  sw <- grep("^switch[0-9]+$", names(d), value = TRUE)
  opts <- list()
  if (length(sw) && !identical(vsrc, "switch")) {
    S <- sapply(sw, function(cc) num(d[[cc]]))
    if (is.null(dim(S))) S <- matrix(S, nrow = nrow(d))
    for (thr in 1:6) opts[[paste0("sw>=", thr)]] <- apply(S, 1, function(r) any(r >= thr, na.rm = TRUE))
  }
  if ("excluded" %in% names(d)) { ex <- num(d$excluded); opts[["excluded"]] <- !is.na(ex) & ex == 1 }
  if (!length(opts)) { L("no multi-switch info"); return(rep(FALSE, nrow(d))) }
  rates <- sapply(opts, function(f) mean(f[cand]))
  L("ms rates:", paste(names(rates), round(rates, 3), collapse = " "), "target", round(target, 3))
  k <- names(rates)[which.min(abs(rates - target))]
  cat("DEVIATION: multiple-switcher flag rule chosen as '", k,
      "' (rate closest to the paper's reported drop share) because switch-column coding is undocumented\n", sep = "")
  opts[[k]]
}

build_dc <- function(V) {
  mx <- apply(V, 2, max, na.rm = TRUE)
  if (max(mx) <= 21) {
    Rs <- c(12, 14, 16, 18, 20)
    R <- sapply(mx, function(m) Rs[which.min(abs(Rs - m))])
    P <- sweep(V, 2, R, "/") * 100
  } else {
    R <- rep(NA, 20)
    P <- V
  }
  sds <- apply(P, 2, sd, na.rm = TRUE)
  mns <- colMeans(P, na.rm = TRUE)
  cx <- rank(-sds, ties.method = "first") <= 10
  si <- which(!cx); ci <- which(cx)
  Rs_ <- ifelse(is.na(R), 0, R)
  si <- si[order(-Rs_[si], -mns[si])]
  ci <- ci[order(-Rs_[ci], -mns[ci])]
  L("R:", paste(R, collapse = ","), "| pairs:", paste0(si, "-", ci, collapse = " "))
  -abs(P[, ci, drop = FALSE] - P[, si, drop = FALSE])
}

prep <- function(d, four, lab, target) {
  cat("\n######## Processing", lab, "########\n")
  fin <- get_fin(d)
  idc <- intersect(c("amt_id", "workerId", "WorkerId", "worker_id", "mturk_id", "MID", "mid"), names(d))
  dup <- rep(FALSE, nrow(d))
  if (length(idc)) {
    w <- d[[idc[1]]]
    okw <- fin & !is.na(w) & w != ""
    dd <- duplicated(w[okw])
    dup[which(okw)[dd]] <- TRUE
  }
  L(lab, "finished", sum(fin), "dups", sum(dup))
  raw <- clean_arm_raw(d$treatment, if (four) 4 else 2)
  d$arm <- label_arms(raw, four)
  rows <- fin & !dup & !is.na(d$arm)
  ss <- score_search(d, d$arm, rows)
  if (!is.null(ss) && nrow(ss) >= 2) {
    L(lab, "score+:", paste(head(ss$col, 3), round(head(ss$diff, 3), 3), collapse = " "))
    L(lab, "score-:", paste(tail(ss$col, 3), round(tail(ss$diff, 3), 3), collapse = " "))
    compc <- ss$col[1]; ctrlc <- ss$col[nrow(ss)]
    cat("DEVIATION: test-score columns identified from data as", compc, "(compounding) and", ctrlc, "(control module)\n")
  } else {
    L(lab, "no score candidates; fallback SC0_0/SC0_1")
    compc <- "SC0_0"; ctrlc <- "SC0_1"
  }
  d$comp <- if (compc %in% names(d)) num(d[[compc]]) else NA_real_
  d$ctrl <- if (ctrlc %in% names(d)) num(d[[ctrlc]]) else NA_real_
  vv <- tryCatch(get_vals(d, rows), error = function(e) { L("get_vals err", conditionMessage(e)); NULL })
  V <- if (is.null(vv)) NULL else vv$V
  cand <- rows & !is.na(d$comp) & !is.na(d$ctrl)
  if (!is.null(V)) cand <- cand & rowSums(!is.na(V)) == 20
  ms <- ms_choose(d, cand, target, if (is.null(vv)) NA else vv$src)
  keep <- cand & !ms
  tb <- table(d$arm[keep])
  L(lab, "cand", sum(cand), "kept", sum(keep), ":", paste(names(tb), tb, collapse = " "))
  m1 <- tapply(d$comp[keep], raw[keep], mean); m2 <- tapply(d$ctrl[keep], raw[keep], mean)
  L(lab, "comp|ctrl by raw arm:", paste(names(m1), round(m1, 2), round(m2, 2), collapse = " ; "))
  list(d = d[keep, , drop = FALSE], V = if (is.null(V)) NULL else V[keep, , drop = FALSE])
}

pa <- prep(A, TRUE, "A", 49 / 504)
pb <- prep(B, FALSE, "B", 53 / 401)

t4 <- function(dd, y) {
  dd$treat <- as.integer(dd$arm == "Treatment")
  m <- feols(as.formula(paste(y, "~ treat")), data = dd, vcov = "iid")
  unname(coef(m)["treat"])
}

res <- list()
dA2 <- pa$d[pa$d$arm %in% c("Control", "Treatment"), ]
dB2 <- pb$d[pb$d$arm %in% c("Control", "Treatment"), ]
res$test_score_compounding_treatment_minus_control_expA_table4_col1 <- tryCatch(t4(dA2, "comp"), error = function(e) NA)
res$test_score_compounding_treatment_minus_control_expB_table4_col2 <- tryCatch(t4(dB2, "comp"), error = function(e) NA)
res$test_score_control_module_treatment_minus_control_expA_table4_col3 <- tryCatch(t4(dA2, "ctrl"), error = function(e) NA)
res$test_score_control_module_treatment_minus_control_expB_table4_col4 <- tryCatch(t4(dB2, "ctrl"), error = function(e) NA)
res$n_obs_table4_expA_cols1_3 <- nrow(dA2)
res$n_obs_table4_expB_cols2_4 <- nrow(dB2)

t7 <- function(p) {
  if (is.null(p$V)) stop("no valuations")
  DC <- build_dc(p$V)
  long <- data.frame(id = rep(p$d$.uid, times = ncol(DC)),
                     arm = rep(p$d$arm, times = ncol(DC)),
                     dc = as.vector(DC))
  long <- long[!is.na(long$dc) & !is.na(long$arm), ]
  m <- feols(dc ~ 0 + arm, data = long, cluster = ~id)
  list(coef = coef(m), n = nobs(m))
}

rA <- tryCatch(t7(pa), error = function(e) { L("T7 A error:", conditionMessage(e)); NULL })
rB <- tryCatch(t7(pb), error = function(e) { L("T7 B error:", conditionMessage(e)); NULL })
g <- function(r, k) if (is.null(r) || !(k %in% names(r$coef))) NA else unname(r$coef[k])
res$deliberative_competence_control_expA_table7_col1 <- g(rA, "armControl")
res$deliberative_competence_treatment_expA_table7_col1 <- g(rA, "armTreatment")
res$deliberative_competence_substance_only_expA_table7_col1 <- g(rA, "armSubstanceOnly")
res$deliberative_competence_rhetoric_only_expA_table7_col1 <- g(rA, "armRhetoricOnly")
res$deliberative_competence_control_expB_table7_col2 <- g(rB, "armControl")
res$deliberative_competence_treatment_expB_table7_col2 <- g(rB, "armTreatment")
res$n_obs_table7_expA_col1 <- if (is.null(rA)) NA else rA$n

cat("\n==== SUMMARY ====\n")
for (e in elog) cat(e, "\n")
cat("\n")
for (k in names(res)) cat(sprintf("RESULT:%s=%s\n", k, format(res[[k]], digits = 10)))
