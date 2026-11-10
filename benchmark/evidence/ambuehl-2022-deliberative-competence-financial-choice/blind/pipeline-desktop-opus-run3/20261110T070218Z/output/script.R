suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"
num <- function(x) suppressWarnings(as.numeric(as.character(x)))

rd <- function(f) {
  d <- suppressMessages(suppressWarnings(read_csv(file.path(base, "data", "raw", f),
                col_types = cols(.default = col_character()),
                show_col_types = FALSE, progress = FALSE, name_repair = "unique")))
  nm <- gsub("^﻿", "", names(d))
  nm <- gsub('^"|"$', "", trimws(nm))
  names(d) <- make.unique(nm)
  d$batch_file <- f
  d
}

res <- list()
setres <- function(k, v) res[[k]] <<- v

# ---------------------------------------------------------------- helpers
prep <- function(d, label) {
  cat("\n====", label, "====\n")
  cat("rows with response id:", nrow(d), "\n")
  fincol <- intersect(c("Finished", "V10"), names(d))
  if (length(fincol)) {
    f <- d[[fincol[1]]]
    cat("Finished values (", fincol[1], "):\n"); print(table(f, useNA = "ifany"))
    fv <- tolower(trimws(f)) %in% c("1", "true")
    if (sum(fv) > 0.3 * nrow(d)) d <- d[fv, ]
  }
  cat("after finished filter:", nrow(d), "\n")
  if ("excluded" %in% names(d)) {
    cat("excluded values:\n"); print(table(d$excluded, useNA = "ifany"))
    ex <- num(d$excluded)
    d <- d[is.na(ex) | ex != 1, ]
    cat("after excluded filter:", nrow(d), "\n")
  }
  if ("treatment" %in% names(d)) {
    cat("treatment values:\n"); print(table(d$treatment, useNA = "ifany"))
    d <- d[!is.na(d$treatment) & trimws(d$treatment) != "", ]
  }
  d <- d[!duplicated(d$id), ]
  cat("after treatment non-missing & dedup:", nrow(d), "\n")
  d
}

switch_filter <- function(d) {
  swc <- grep("^switch\\d+$", names(d), value = TRUE)
  cat("switch columns:", length(swc), "\n")
  if (!length(swc)) {
    cat("other switch-like columns:", grep("switch|multi", names(d), value = TRUE, ignore.case = TRUE), "\n")
    return(d)
  }
  S <- matrix(sapply(swc, function(cc) num(d[[cc]])), nrow = nrow(d))
  vals <- S[!is.na(S)]
  cat("switch values table:\n"); print(head(table(vals), 30))
  mx <- apply(S, 1, function(z) if (all(is.na(z))) NA else max(z, na.rm = TRUE))
  allv <- sort(unique(vals))
  if (length(allv) && max(allv) > 10) {
    cat("WARNING: switch values look like switch rows, not counts; no switch filter applied\n")
    return(d)
  }
  if (all(allv %in% c(0, 1)) && mean(vals == 1) < 0.2) {
    multi <- !is.na(mx) & mx >= 1
  } else {
    multi <- !is.na(mx) & mx >= 2
  }
  cat("multiple switchers dropped:", sum(multi), "\n")
  d <- d[!multi, ]
  cat("after switch filter:", nrow(d), "\n")
  d
}

pick_scores <- function(d) {
  scs <- grep("^SC", names(d), value = TRUE)
  cat("score columns:", scs, "\n")
  for (s in scs) { cat(s, ":\n"); print(table(d[[s]], useNA = "ifany")) }
  if (all(c("SC0_0", "SC0_1") %in% scs)) return(c("SC0_0", "SC0_1"))
  if (all(c("SC0", "SC1") %in% scs)) return(c("SC0", "SC1"))
  scs[1:2]
}

map_arms <- function(tr, comp, ctrl, four) {
  lt <- tolower(trimws(tr))
  arm <- rep(NA_character_, length(lt))
  if (any(grepl("control|rhet|subst|treat|index|divers|portfolio|placebo", lt))) {
    if (four) {
      arm[grepl("rhet", lt)] <- "Rhetoric"
      arm[is.na(arm) & grepl("subst", lt)] <- "Substance"
      arm[is.na(arm) & grepl("control|index|placebo", lt)] <- "Control"
      arm[is.na(arm) & !is.na(lt) & lt != ""] <- "Treatment"
    } else {
      arm[grepl("control|divers|portfolio|placebo", lt)] <- "Control"
      arm[is.na(arm) & !is.na(lt) & lt != ""] <- "Treatment"
    }
    return(arm)
  }
  lv <- sort(unique(lt[!is.na(lt) & lt != ""]))
  mc <- sapply(lv, function(l) mean(ctrl[lt == l], na.rm = TRUE))
  mp <- sapply(lv, function(l) mean(comp[lt == l], na.rm = TRUE))
  cat("level means (control-module score):\n"); print(mc)
  cat("level means (compounding score):\n"); print(mp)
  map <- setNames(rep(NA_character_, length(lv)), lv)
  ctl <- lv[which.max(mc)]
  map[ctl] <- "Control"
  rest <- setdiff(lv, ctl)
  if (four && length(rest) >= 3) {
    rh <- rest[which.min(mp[rest])]
    map[rh] <- "Rhetoric"
    rest2 <- setdiff(rest, rh)
    map[rest2[1]] <- "Treatment"
    map[rest2[2]] <- "Substance"
  } else {
    map[rest] <- "Treatment"
  }
  cat("arm mapping:\n"); print(map)
  unname(map[lt])
}

find_val <- function(d) {
  nm <- names(d)
  has <- grepl("\\d+$", nm)
  pre <- sub("\\d+$", "", nm[has])
  ix <- as.integer(sub("^.*?(\\d+)$", "\\1", nm[has], perl = TRUE))
  out <- list()
  for (p in unique(pre)) {
    if (p %in% c("V", "switch", "")) next
    ii <- ix[pre == p]
    if (!all(1:20 %in% ii)) next
    cols <- paste0(p, 1:20)
    M <- matrix(sapply(cols, function(cc) num(d[[cc]])), nrow = nrow(d))
    fr <- mean(!is.na(M))
    if (fr < 0.3) next
    perm <- mean(apply(M, 1, function(z) !any(is.na(z)) && all(sort(z) == 1:20)))
    v <- M[!is.na(M)]
    mx <- max(v); mn <- min(v)
    nonint <- mean(v != round(v))
    cat(sprintf("family '%s': frac=%.2f perm=%.2f min=%.2f max=%.2f nonint=%.2f mean=%.2f\n",
                p, fr, perm, mn, mx, nonint, mean(v)))
    out[[p]] <- list(M = M, fr = fr, perm = perm, mx = mx, mn = mn, nonint = nonint)
  }
  out
}

dc_long <- function(d) {
  fv <- find_val(d)
  if (!length(fv)) { cat("No valuation family found. Columns:\n"); print(names(d)); return(NULL) }
  good <- names(fv)[sapply(fv, function(f) f$perm < 0.5 && f$mn >= 0 && f$mx <= 105 && f$fr > 0.5)]
  if (!length(good)) { cat("No acceptable valuation family. Columns:\n"); print(names(d)); return(NULL) }
  pri <- c(good[grepl("val|equiv|ce|indiff|price|eq", good, ignore.case = TRUE)],
           intersect("T", good),
           good[order(-sapply(fv[good], function(f) f$nonint))])
  p <- unique(pri)[1]
  cat("Using valuation family:", p, "\n")
  M <- fv[[p]]$M
  mx <- fv[[p]]$mx
  Rs <- c(12, 14, 16, 18, 20)
  Rk <- rep(NA_real_, 20)
  if (mx <= 1.05) {
    r <- M * 100
  } else if (mx > 25) {
    r <- M
  } else {
    Rk <- sapply(1:20, function(k) {
      q <- suppressWarnings(max(M[, k], na.rm = TRUE))
      cand <- Rs[Rs >= q - 0.5]
      if (length(cand)) cand[1] else 20
    })
    cat("Inferred R per task:", Rk, "\n")
    r <- sweep(M, 2, Rk, "/") * 100
  }
  cat("task means (pp):", round(colMeans(r, na.rm = TRUE), 1), "\n")
  PA <- cbind(1:10, 11:20)
  PB <- cbind(seq(1, 19, 2), seq(2, 20, 2))
  P <- PA
  if (!any(is.na(Rk))) {
    agA <- mean(Rk[PA[, 1]] == Rk[PA[, 2]])
    agB <- mean(Rk[PB[, 1]] == Rk[PB[, 2]])
    cat("pairing agreement A(k,k+10)=", agA, " B(2j-1,2j)=", agB, "\n")
    if (agB > agA) P <- PB
  }
  L <- do.call(rbind, lapply(1:10, function(j)
    data.frame(id = d$id, arm = d$arm, pair = j,
               dc = -abs(r[, P[j, 1]] - r[, P[j, 2]]), stringsAsFactors = FALSE)))
  L[!is.na(L$dc) & !is.na(L$arm), ]
}

diff_reg <- function(d, y) {
  dd <- d[d$arm %in% c("Control", "Treatment"), ]
  dd$y <- num(dd[[y]])
  dd$treat <- as.numeric(dd$arm == "Treatment")
  dd <- dd[!is.na(dd$y), ]
  m <- lm(y ~ treat, data = dd)
  list(b = unname(coef(m)["treat"]), se = sqrt(diag(vcov(m)))["treat"], n = nrow(dd))
}

# ---------------------------------------------------------------- Experiment A
tryCatch({
  A <- bind_rows(lapply(sprintf("expAbatch%d.csv", 1:8), rd))
  cat("ExpA raw rows:", nrow(A), "\n")
  idA <- if ("V1" %in% names(A)) "V1" else names(A)[1]
  A$id <- A[[idA]]
  A <- A[grepl("^R_", A$id), ]
  A <- prep(A, "Experiment A")
  scA <- pick_scores(A)
  A$comp <- num(A[[scA[1]]]); A$ctrl <- num(A[[scA[2]]])
  A$arm <- map_arms(A$treatment, A$comp, A$ctrl, four = TRUE)
  cat("arms before switch filter:\n"); print(table(A$arm, useNA = "ifany"))
  A <- A[!is.na(A$arm), ]
  A <- switch_filter(A)
  cat("arms after switch filter:\n"); print(table(A$arm, useNA = "ifany"))
  print(A %>% group_by(arm) %>% summarise(comp = mean(comp, na.rm = TRUE), ctrl = mean(ctrl, na.rm = TRUE), n = n()))

  r1 <- diff_reg(A, "comp"); r3 <- diff_reg(A, "ctrl")
  setres("test_score_compounding_treatment_minus_control_expA_table4_col1", r1$b)
  setres("test_score_control_module_treatment_minus_control_expA_table4_col3", r3$b)
  setres("n_obs_table4_expA_cols1_3", r1$n)
  cat("SE col1:", r1$se, " SE col3:", r3$se, "\n")

  LA <- dc_long(A)
  if (!is.null(LA)) {
    LA$arm <- factor(LA$arm, levels = c("Control", "Treatment", "Substance", "Rhetoric"))
    mA <- feols(dc ~ 0 + arm, data = LA, cluster = ~id)
    print(summary(mA))
    co <- coef(mA)
    setres("deliberative_competence_control_expA_table7_col1", unname(co["armControl"]))
    setres("deliberative_competence_treatment_expA_table7_col1", unname(co["armTreatment"]))
    setres("deliberative_competence_substance_only_expA_table7_col1", unname(co["armSubstance"]))
    setres("deliberative_competence_rhetoric_only_expA_table7_col1", unname(co["armRhetoric"]))
    setres("n_obs_table7_expA_col1", nobs(mA))
  }
}, error = function(e) cat("ERROR in Experiment A:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------- Experiment B
tryCatch({
  B <- bind_rows(lapply(sprintf("expBbatch%d.csv", 1:2), rd))
  cat("ExpB raw rows:", nrow(B), "\n")
  idB <- if ("ResponseId" %in% names(B)) "ResponseId" else names(B)[1]
  B$id <- B[[idB]]
  B <- B[grepl("^R_", B$id), ]
  B <- prep(B, "Experiment B")
  scB <- pick_scores(B)
  B$comp <- num(B[[scB[1]]]); B$ctrl <- num(B[[scB[2]]])
  B$arm <- map_arms(B$treatment, B$comp, B$ctrl, four = FALSE)
  B <- B[!is.na(B$arm), ]
  B <- switch_filter(B)
  cat("arms after switch filter:\n"); print(table(B$arm, useNA = "ifany"))
  print(B %>% group_by(arm) %>% summarise(comp = mean(comp, na.rm = TRUE), ctrl = mean(ctrl, na.rm = TRUE), n = n()))

  r2 <- diff_reg(B, "comp"); r4 <- diff_reg(B, "ctrl")
  setres("test_score_compounding_treatment_minus_control_expB_table4_col2", r2$b)
  setres("test_score_control_module_treatment_minus_control_expB_table4_col4", r4$b)
  setres("n_obs_table4_expB_cols2_4", r2$n)
  cat("SE col2:", r2$se, " SE col4:", r4$se, "\n")

  LB <- dc_long(B)
  if (!is.null(LB)) {
    LB$arm <- factor(LB$arm, levels = c("Control", "Treatment"))
    mB <- feols(dc ~ 0 + arm, data = LB, cluster = ~id)
    print(summary(mB))
    co <- coef(mB)
    setres("deliberative_competence_control_expB_table7_col2", unname(co["armControl"]))
    setres("deliberative_competence_treatment_expB_table7_col2", unname(co["armTreatment"]))
  }
}, error = function(e) cat("ERROR in Experiment B:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------- output
keys <- c(
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
cat("\n")
for (k in keys) {
  v <- res[[k]]
  if (is.null(v) || length(v) == 0 || is.na(v)) v <- NA
  cat(sprintf("RESULT:%s=%s\n", k, if (is.na(v)) "NA" else format(v, digits = 10)))
}