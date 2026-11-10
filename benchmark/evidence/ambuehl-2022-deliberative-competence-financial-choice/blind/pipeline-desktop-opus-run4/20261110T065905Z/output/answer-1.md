suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(warn = 1)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"
rawdir <- file.path(base, "data", "raw")

msgp <- function(x) message(paste(capture.output(print(x)), collapse = "\n"))
num <- function(x) suppressWarnings(as.numeric(gsub("[$,% ]", "", as.character(x))))

RES <- list()
setres <- function(n, v) {
  if (is.null(v) || length(v) == 0) v <- NA
  RES[[n]] <<- suppressWarnings(as.numeric(v)[1])
}

# ---------------------------------------------------------------- reading
read_q <- function(f) {
  d <- tryCatch(
    readr::read_csv(f, col_types = readr::cols(.default = readr::col_character()),
                    progress = FALSE, name_repair = "minimal"),
    error = function(e) { message("read fail ", f, ": ", conditionMessage(e)); NULL })
  if (is.null(d)) return(NULL)
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  nm <- trimws(gsub("^﻿", "", names(d)))
  nm[nm == ""] <- paste0("X", which(nm == ""))
  names(d) <- make.unique(nm)
  idcol <- intersect(c("V1", "ResponseId", "ResponseID"), names(d))
  if (length(idcol) > 0) {
    id <- d[[idcol[1]]]
    isR <- grepl("^R_", id)
    if (mean(isR) > 0.5) {
      d <- d[isR, , drop = FALSE]
    } else {
      d <- d[!(id %in% c("ResponseID", "Response ID", "ResponseId") | grepl("ImportId", id, fixed = TRUE)), , drop = FALSE]
    }
  }
  d$.file <- rep(basename(f), nrow(d))
  d
}

filt_fin <- function(d, tag) {
  fc <- if ("Finished" %in% names(d)) "Finished" else if ("V10" %in% names(d)) "V10" else NA
  if (!is.na(fc)) {
    fv <- tolower(trimws(d[[fc]]))
    message(tag, ": Finished column (", fc, ") values")
    msgp(table(fv, useNA = "ifany"))
    keep <- fv %in% c("1", "true")
    if (sum(keep) > 0) d <- d[keep, , drop = FALSE]
  }
  message(tag, ": rows after Finished filter = ", nrow(d))
  d
}

# ---------------------------------------------------------------- scores
get_scores <- function(d, tag) {
  nm <- names(d)
  sc <- grep("^SC\\d*(_\\d+)?$", nm, value = TRUE)
  valid <- character(0)
  for (cn in sc) {
    x <- num(d[[cn]])
    if (sum(!is.na(x)) > 0.5 * nrow(d)) {
      mx <- max(x, na.rm = TRUE); mn <- min(x, na.rm = TRUE)
      message(tag, " score col ", cn, ": min ", mn, " max ", mx, " mean ", round(mean(x, na.rm = TRUE), 3))
      if (mx <= 5 && mn >= 0) valid <- c(valid, cn)
    }
  }
  comp <- if (length(valid) >= 1) num(d[[valid[1]]]) else rep(NA_real_, nrow(d))
  ctrl <- if (length(valid) >= 2) num(d[[valid[2]]]) else rep(NA_real_, nrow(d))
  message(tag, ": comp score col = ", valid[1], "; ctrl score col = ", valid[2])
  list(comp = comp, ctrl = ctrl)
}

# ---------------------------------------------------------------- arms
map_arms <- function(tr, comp, ctrl, tag) {
  t <- tolower(trimws(as.character(tr)))
  t[is.na(t) | t %in% c("", "na", "nan")] <- NA
  message(tag, ": raw treatment values")
  msgp(table(t, useNA = "ifany"))
  lab <- rep(NA_character_, length(t))
  lab[grepl("rhet", t)] <- "Rhetoric"
  lab[is.na(lab) & grepl("subst", t)] <- "Substance"
  lab[is.na(lab) & grepl("control|ctrl|index|divers|portf", t)] <- "Control"
  lab[is.na(lab) & grepl("treat|compound|interest|full", t)] <- "Treatment"
  if (any(!is.na(lab)) && all(!is.na(lab[!is.na(t)]))) {
    message(tag, ": arms mapped from text labels")
    msgp(table(t, lab, useNA = "ifany"))
    return(lab)
  }
  tab <- table(t)
  lv <- names(tab)[tab >= 10]
  if (length(lv) < 2) { message(tag, ": could not identify arms"); return(rep(NA_character_, length(t))) }
  mc <- sapply(lv, function(l) mean(ctrl[which(t == l)], na.rm = TRUE))
  mp <- sapply(lv, function(l) mean(comp[which(t == l)], na.rm = TRUE))
  message(tag, ": mean comp score by level"); msgp(mp)
  message(tag, ": mean ctrl score by level"); msgp(mc)
  ctrl_lv <- if (all(is.na(mc))) lv[which.min(mp)] else lv[which.max(mc)]
  if (length(ctrl_lv) == 0) ctrl_lv <- lv[1]
  rest <- setdiff(lv, ctrl_lv)
  map <- setNames(rep(NA_character_, length(lv)), lv)
  map[ctrl_lv] <- "Control"
  if (length(rest) == 1) {
    map[rest] <- "Treatment"
  } else {
    rh <- if (all(is.na(mp[rest]))) rest[length(rest)] else rest[which.min(mp[rest])]
    map[rh] <- "Rhetoric"
    rest2 <- setdiff(rest, rh)
    rest2 <- rest2[order(-mp[rest2])]
    map[rest2[1]] <- "Treatment"
    if (length(rest2) >= 2) map[rest2[2]] <- "Substance"
  }
  message(tag, ": data-driven arm map"); msgp(map)
  unname(map[t])
}

# ---------------------------------------------------------------- exclusion
get_multi <- function(d, tag) {
  sw <- grep("^switch_?\\d+$", names(d), value = TRUE, ignore.case = TRUE)
  multi <- rep(NA, nrow(d))
  if (length(sw) > 0) {
    S <- sapply(sw, function(cn) num(d[[cn]]))
    if (is.null(dim(S))) S <- matrix(S, ncol = length(sw))
    mx <- apply(S, 1, function(r) if (all(is.na(r))) NA else max(r, na.rm = TRUE))
    gmax <- suppressWarnings(max(mx, na.rm = TRUE))
    message(tag, ": ", length(sw), " switch cols; distribution of per-subject max")
    msgp(table(mx, useNA = "ifany"))
    multi <- if (is.finite(gmax) && gmax >= 2) mx >= 2 else mx >= 1
    multi[is.na(multi)] <- FALSE
  }
  exc <- grep("^excluded$", names(d), value = TRUE, ignore.case = TRUE)
  ex <- NULL
  if (length(exc)) {
    ev <- tolower(trimws(d[[exc[1]]]))
    ex <- ifelse(ev %in% c("1", "true", "yes"), TRUE, ifelse(ev %in% c("0", "false", "no"), FALSE, NA))
    message(tag, ": excluded column values"); msgp(table(ev, useNA = "ifany"))
    if (length(sw)) msgp(table(multi, ex, useNA = "ifany"))
  }
  share <- if (all(is.na(multi))) NA else mean(multi)
  if (is.na(share) || share > 0.35 || share == 0) {
    if (!is.null(ex) && any(!is.na(ex))) {
      message(tag, ": using 'excluded' column for multiple-switch exclusion")
      multi <- ifelse(is.na(ex), FALSE, ex)
    } else if (all(is.na(multi))) {
      multi <- rep(FALSE, nrow(d))
    }
  }
  message(tag, ": multiple switchers = ", sum(multi))
  multi
}

# ---------------------------------------------------------------- valuations
get_vals <- function(d, tag) {
  nm <- names(d)
  tc <- sapply(1:20, function(k) { m <- nm[tolower(nm) == paste0("t", k)]; if (length(m)) m[1] else NA })
  vc <- NULL
  if (all(!is.na(tc))) {
    vc <- tc
  } else {
    cand <- grep("^(val|value|wtp|ce)_?\\d+$", nm, value = TRUE, ignore.case = TRUE)
    if (length(cand) == 20) vc <- cand
  }
  if (is.null(vc)) { message(tag, ": no valuation columns found"); return(NULL) }
  message(tag, ": valuation cols = ", paste(vc, collapse = ","))
  V <- sapply(vc, function(cn) num(d[[cn]]))
  if (is.null(dim(V))) V <- matrix(V, nrow = 1)
  V
}

dc_long <- function(V, ids, arms, tag) {
  if (is.null(V) || all(is.na(V))) return(NULL)
  M <- max(V, na.rm = TRUE)
  scl <- if (M <= 1.01) "frac" else if (M <= 21) "dollar" else if (M <= 101) "pct" else "cents"
  if (scl == "cents") { V <- V / 100; scl <- "dollar" }
  cmax <- apply(V, 2, function(x) if (all(is.na(x))) NA else max(x, na.rm = TRUE))
  cmean <- colMeans(V, na.rm = TRUE)
  Rset <- c(12, 14, 16, 18, 20)
  Rdir <- sapply(cmax, function(m) { k <- which(Rset >= m - 0.21); if (length(k)) Rset[k[1]] else NA })
  if (scl == "dollar" && all(!is.na(Rdir)) && all(table(factor(Rdir, levels = Rset)) == 4)) {
    Rk <- Rdir
  } else {
    ord <- order(-cmax, -cmean)
    Rk <- numeric(ncol(V))
    Rk[ord] <- rep(rev(Rset), each = 4)[seq_len(ncol(V))]
  }
  message(tag, ": valuation scale = ", scl)
  msgp(rbind(cmax = round(cmax, 2), cmean = round(cmean, 2), R = Rk))
  PA <- cbind(1:10, 11:20)
  PB <- cbind(seq(1, 19, 2), seq(2, 20, 2))
  mA <- sum(Rk[PA[, 1]] == Rk[PA[, 2]])
  mB <- sum(Rk[PB[, 1]] == Rk[PB[, 2]])
  grp <- do.call(rbind, lapply(Rset, function(r) {
    g <- which(Rk == r)
    if (length(g) == 4) rbind(c(g[1], g[3]), c(g[2], g[4])) else NULL
  }))
  if (scl != "dollar" || mA >= max(8, mB)) {
    P <- PA; message(tag, ": pairing T_k with T_(k+10); R matches = ", mA)
  } else if (mB >= 8) {
    P <- PB; message(tag, ": pairing T_(2k-1) with T_2k; R matches = ", mB)
  } else if (!is.null(grp) && nrow(grp) == 10) {
    P <- grp; message(tag, ": pairing within inferred-R groups")
  } else {
    P <- PA; message(tag, ": fallback pairing T_k with T_(k+10)")
  }
  out <- vector("list", nrow(P))
  for (p in seq_len(nrow(P))) {
    i <- P[p, 1]; j <- P[p, 2]
    if (scl == "dollar") {
      ri <- 100 * V[, i] / Rk[i]; rj <- 100 * V[, j] / Rk[j]
    } else if (scl == "frac") {
      ri <- 100 * V[, i]; rj <- 100 * V[, j]
    } else {
      ri <- V[, i]; rj <- V[, j]
    }
    out[[p]] <- data.frame(id = ids, arm = arms, pair = p, d = -abs(ri - rj), stringsAsFactors = FALSE)
  }
  L <- do.call(rbind, out)
  L[!is.na(L$d) & !is.na(L$arm), ]
}

# ---------------------------------------------------------------- regressions
diff_reg <- function(S, y, tag) {
  base_s <- S[S$arm %in% c("Control", "Treatment") & !S$multi, ]
  s <- base_s[!is.na(base_s[[y]]), ]
  if (nrow(s) < 5 || length(unique(s$arm)) < 2) return(list(b = NA, n = nrow(base_s)))
  s$treat <- as.numeric(s$arm == "Treatment")
  s$y <- s[[y]]
  f <- feols(y ~ treat, data = s, vcov = "iid")
  message(tag, " ", y, ": diff = ", round(coef(f)["treat"], 4), " se = ", round(se(f)["treat"], 4), " n = ", nobs(f))
  list(b = unname(coef(f)["treat"]), se = unname(se(f)["treat"]), n = nobs(f))
}

dc_reg <- function(L, levs, tag) {
  L <- L[L$arm %in% levs, ]
  levs <- levs[levs %in% unique(L$arm)]
  L$armf <- factor(L$arm, levels = levs)
  f <- feols(d ~ 0 + armf, data = L, cluster = ~id)
  cf <- coef(f); names(cf) <- sub("^armf", "", names(cf))
  s <- se(f); names(s) <- sub("^armf", "", names(s))
  message(tag, ": deliberative competence levels"); msgp(rbind(coef = cf, se = s))
  message(tag, ": n obs = ", nobs(f), "; subjects = ", length(unique(L$id)))
  list(cf = cf, n = nobs(f))
}

prep <- function(files, tag) {
  files <- files[file.exists(files)]
  D <- bind_rows(lapply(files, read_q))
  message("==== ", tag, ": rows after header removal = ", nrow(D))
  D <- filt_fin(D, tag)
  nm <- names(D)
  noise <- grepl("First Click|Last Click|Page Submit|Click Count|_DO_|^Q\\d", nm)
  message(tag, " columns (", length(nm), " total; filtered list): ", paste(nm[!noise], collapse = ", "))
  idc <- intersect(c("V1", "ResponseId", "ResponseID"), nm)
  id <- if (length(idc)) paste0(D$.file, "_", D[[idc[1]]]) else paste0(D$.file, "_", seq_len(nrow(D)))
  id <- make.unique(id)
  sc <- get_scores(D, tag)
  tcol <- nm[tolower(nm) == "treatment"]
  if (!length(tcol)) tcol <- grep("^(treat|condition|arm$|group)", nm, value = TRUE, ignore.case = TRUE)
  message(tag, ": treatment col = ", paste(tcol, collapse = ","))
  tr <- if (length(tcol)) D[[tcol[1]]] else rep(NA_character_, nrow(D))
  arm <- map_arms(tr, sc$comp, sc$ctrl, tag)
  multi <- get_multi(D, tag)
  V <- get_vals(D, tag)
  S <- data.frame(id = id, arm = arm, comp = sc$comp, ctrl = sc$ctrl, multi = multi, stringsAsFactors = FALSE)
  message(tag, ": arm x multi")
  msgp(table(S$arm, S$multi, useNA = "ifany"))
  list(S = S, V = V)
}

# ---------------------------------------------------------------- Experiment A
tryCatch({
  pa <- prep(file.path(rawdir, paste0("expAbatch", 1:8, ".csv")), "ExpA")
  S <- pa$S
  r1 <- diff_reg(S, "comp", "ExpA")
  r3 <- diff_reg(S, "ctrl", "ExpA")
  setres("test_score_compounding_treatment_minus_control_expA_table4_col1", r1$b)
  setres("test_score_control_module_treatment_minus_control_expA_table4_col3", r3$b)
  setres("n_obs_table4_expA_cols1_3", r1$n)
  keep <- !S$multi & !is.na(S$arm)
  if (!is.null(pa$V)) {
    L <- dc_long(pa$V[keep, , drop = FALSE], S$id[keep], S$arm[keep], "ExpA")
    if (!is.null(L) && nrow(L) > 0) {
      rr <- dc_reg(L, c("Control", "Treatment", "Substance", "Rhetoric"), "ExpA")
      setres("deliberative_competence_control_expA_table7_col1", rr$cf["Control"])
      setres("deliberative_competence_treatment_expA_table7_col1", rr$cf["Treatment"])
      setres("deliberative_competence_substance_only_expA_table7_col1", rr$cf["Substance"])
      setres("deliberative_competence_rhetoric_only_expA_table7_col1", rr$cf["Rhetoric"])
      setres("n_obs_table7_expA_col1", rr$n)
    }
  }
}, error = function(e) message("ExpA error: ", conditionMessage(e)))

# ---------------------------------------------------------------- Experiment B
tryCatch({
  pb <- prep(file.path(rawdir, paste0("expBbatch", 1:2, ".csv")), "ExpB")
  S <- pb$S
  r2 <- diff_reg(S, "comp", "ExpB")
  r4 <- diff_reg(S, "ctrl", "ExpB")
  setres("test_score_compounding_treatment_minus_control_expB_table4_col2", r2$b)
  setres("test_score_control_module_treatment_minus_control_expB_table4_col4", r4$b)
  setres("n_obs_table4_expB_cols2_4", r2$n)
  keep <- !S$multi & !is.na(S$arm)
  if (!is.null(pb$V)) {
    L <- dc_long(pb$V[keep, , drop = FALSE], S$id[keep], S$arm[keep], "ExpB")
    if (!is.null(L) && nrow(L) > 0) {
      rr <- dc_reg(L, c("Control", "Treatment"), "ExpB")
      setres("deliberative_competence_control_expB_table7_col2", rr$cf["Control"])
      setres("deliberative_competence_treatment_expB_table7_col2", rr$cf["Treatment"])
    }
  }
}, error = function(e) message("ExpB error: ", conditionMessage(e)))

# ---------------------------------------------------------------- output
out_names <- c(
  "test_score_compounding_treatment_minus_control_expA_table4_col1",
  "test_score_compounding_treatment_minus_control_expB_table4_col2",
  "test_score_control_module_treatment_minus_control_expA_table4_col3",
  "test_score_control_module_treatment_minus_control_expB_table4_col4",
  "n_obs_table4_expA_cols1_3",
  "n_obs_table4_expB_cols2_4",
  "deliberative_competence_control_expA_table7_col1",
  "deliberative_competence_treatment_expA_table7_col1",
  "deliberative_competence_substance_only_expA_table7_col1",
  "deliberative_competence_rhetoric_only_expA_table7_col1",
  "deliberative_competence_control_expB_table7_col2",
  "deliberative_competence_treatment_expB_table7_col2",
  "n_obs_table7_expA_col1"
)
fmt <- function(v) if (is.null(v) || length(v) == 0 || is.na(v)) "NA" else formatC(v, digits = 8, format = "g")
for (n in out_names) cat(sprintf("RESULT:%s=%s\n", n, fmt(RES[[n]])))
