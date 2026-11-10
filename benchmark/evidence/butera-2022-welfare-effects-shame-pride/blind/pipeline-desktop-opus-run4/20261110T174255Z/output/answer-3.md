suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride.script-free"
raw_dir <- file.path(base_dir, "Packet", "Raw Data")

read_survey <- function(f, prefix) {
  d <- readr::read_csv(file.path(raw_dir, f), show_col_types = FALSE, guess_max = 100000)
  d <- as.data.frame(d)
  d$id <- paste0(prefix, "_", as.character(d$id))
  d
}

prolific <- read_survey("prolific_survey_data.csv", "pro")
berkeley <- read_survey("berkeley_survey_data.csv", "ber")
bu1 <- read_survey("bu_qm221_survey_data.csv", "bu221")
bu2 <- read_survey("bu_qm222_survey_data.csv", "bu222")
common_bu <- intersect(names(bu1), names(bu2))
bu <- rbind(bu1[, common_bu, drop = FALSE], bu2[, common_bu, drop = FALSE])

message("Prolific columns: ", paste(names(prolific), collapse = ", "))
message("Berkeley columns: ", paste(names(berkeley), collapse = ", "))
message("BU columns: ", paste(names(bu), collapse = ", "))

to_num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  y <- suppressWarnings(as.numeric(gsub("[$,]", "", as.character(x))))
  y
}

# ---------------- attention check ----------------
attention_pass <- function(x) {
  message("attention_check values: ", paste(utils::head(names(table(x, useNA = "ifany")), 20), collapse = " | "))
  if (is.logical(x)) return(!is.na(x) & x)
  xn <- suppressWarnings(as.numeric(as.character(x)))
  if (all(is.na(x) | !is.na(xn))) {
    u <- sort(unique(xn[!is.na(xn)]))
    if (length(u) > 0 && all(u %in% c(0, 1))) return(!is.na(xn) & xn == 1)
    frac_nonmiss <- mean(!is.na(xn))
    if (frac_nonmiss < 0.5) {
      # Only a handful of respondents have a recorded value: these are the
      # flagged (failed) attention checks; missing means no failure recorded.
      message("attention_check mostly missing (non-missing share=", round(frac_nonmiss, 4),
              "); treating non-missing values as failures")
      return(is.na(xn))
    }
    message("attention_check is numeric with values outside {0,1}; keeping non-missing")
    return(!is.na(xn))
  }
  xc <- tolower(trimws(as.character(x)))
  passvals <- c("pass", "passed", "correct", "true", "yes", "1", "t", "y")
  !is.na(xc) & xc %in% passvals
}

# ---------------- WTP profile ----------------
get_wtp <- function(d) {
  pcols <- grep("^preference_", names(d), value = TRUE)
  levs <- as.numeric(sub("^preference_([0-9]+).*$", "\\1", pcols))
  ord <- order(levs)
  pcols <- pcols[ord]; levs <- levs[ord]
  W <- matrix(NA_real_, nrow(d), length(pcols))
  for (j in seq_along(pcols)) {
    lab <- sub("^preference_", "", pcols[j])
    cand <- grep(paste0("^(wtp|price|amount|value|pay)_?", lab, "$"), names(d), value = TRUE)
    pref <- d[[pcols[j]]]
    if (length(cand) >= 1) {
      amt <- abs(to_num(d[[cand[1]]]))
      pn <- suppressWarnings(as.numeric(as.character(pref)))
      if (all(is.na(pref) | !is.na(pn))) {
        sgn <- ifelse(pn > 0, 1, -1)
      } else {
        pc <- tolower(as.character(pref))
        sgn <- ifelse(grepl("^y|public|recogn|shar|want", pc) & !grepl("not|don|^n", pc), 1, -1)
      }
      W[, j] <- sgn * amt
    } else {
      W[, j] <- to_num(pref)
    }
  }
  list(W = W, levs = levs)
}

coherent <- function(W) {
  apply(W, 1, function(w) {
    w <- w[!is.na(w)]
    if (length(w) < 2) return(length(w) >= 1)
    s <- sign(diff(w))
    s <- s[s != 0]
    if (length(s) == 0) return(TRUE)
    # incoherent if a decrease is ever followed by an increase
    first_neg <- which(s < 0)
    if (length(first_neg) == 0) return(TRUE)
    !any(s[first_neg[1]:length(s)] > 0)
  })
}

# ---------------- rounds: points and order ----------------
classify_round <- function(nm) {
  l <- tolower(nm)
  paid <- grepl("paid|pay|incent|money|financ|bonus|cash", l)
  anon <- grepl("anon", l) & !paid
  pub <- grepl("public|shar|recog|named|visib|_pr$|^pr_|_pr_", l) & !paid
  if (paid) return("paid")
  if (pub) return("public")
  if (anon) return("anon")
  NA_character_
}

build_long <- function(d) {
  nm <- names(d)
  # Pattern 0: AnomPts / EarnPts / RecogPts with round order coded in the
  # timer column names, e.g. anom_aer_timer_PageSubmit (a = anonymous,
  # e = earn / financial incentive, r = recognition / public).
  if (all(c("AnomPts", "EarnPts", "RecogPts") %in% nm)) {
    seqs <- c("aer", "ear", "are", "era", "rea", "rae")
    seq_id <- rep(NA_character_, nrow(d))
    for (s in seqs) {
      cols <- grep(paste0("^(anom|earn|rec)_", s, "_timer"), nm, value = TRUE)
      if (length(cols) == 0) next
      M <- sapply(cols, function(cc) to_num(d[[cc]]))
      if (is.null(dim(M))) M <- matrix(M, nrow = nrow(d))
      has <- rowSums(!is.na(M)) > 0
      seq_id[is.na(seq_id) & has] <- s
    }
    message("round sequence assignment: ",
            paste(names(table(seq_id, useNA = "ifany")), table(seq_id, useNA = "ifany"),
                  sep = "=", collapse = ", "))
    letter <- c(anon = "a", paid = "e", public = "r")
    colmap <- c(anon = "AnomPts", paid = "EarnPts", public = "RecogPts")
    out <- list()
    for (t in names(colmap)) {
      pos <- vapply(seq_id, function(s) {
        if (is.na(s)) NA_character_ else as.character(regexpr(letter[[t]], s, fixed = TRUE))
      }, character(1))
      out[[t]] <- data.frame(
        id = d$id, round = t,
        points = to_num(d[[colmap[[t]]]]),
        order = unname(pos),
        stringsAsFactors = FALSE
      )
    }
    return(do.call(rbind, out))
  }
  excl <- grepl("prefer|wtp|belief|guess|predict|forecast|expect|estimat|attention", tolower(nm))
  # Pattern A: round-specific named columns
  pts_c <- nm[grepl("point|score|effort|press|click|perf|count", tolower(nm)) &
                !grepl("order|position|seq|rank", tolower(nm)) & !excl]
  ord_c <- nm[grepl("order|position|seq|rank", tolower(nm)) & !excl]
  pts_type <- vapply(pts_c, classify_round, character(1))
  ord_type <- vapply(ord_c, classify_round, character(1))
  message("points candidate columns: ", paste(pts_c, "(", pts_type, ")", collapse = ", "))
  message("order candidate columns: ", paste(ord_c, "(", ord_type, ")", collapse = ", "))
  types <- c("anon", "paid", "public")
  if (all(types %in% pts_type)) {
    out <- list()
    for (t in types) {
      pc <- pts_c[which(pts_type == t)[1]]
      oc <- if (t %in% ord_type) ord_c[which(ord_type == t)[1]] else NA
      out[[t]] <- data.frame(
        id = d$id, round = t,
        points = to_num(d[[pc]]),
        order = if (!is.na(oc)) as.character(d[[oc]]) else NA_character_,
        stringsAsFactors = FALSE
      )
    }
    return(do.call(rbind, out))
  }
  # Pattern B: round1_points / round1_type etc.
  rp <- grep("^round_?[123].*(point|score)", nm, value = TRUE, ignore.case = TRUE)
  rt <- grep("^round_?[123].*(type|treat|cond|name)", nm, value = TRUE, ignore.case = TRUE)
  if (length(rp) == 3 && length(rt) == 3) {
    out <- list()
    for (k in 1:3) {
      pc <- rp[grepl(paste0("^round_?", k), rp, ignore.case = TRUE)][1]
      tc <- rt[grepl(paste0("^round_?", k), rt, ignore.case = TRUE)][1]
      tt <- vapply(as.character(d[[tc]]), classify_round, character(1))
      out[[k]] <- data.frame(id = d$id, round = tt, points = to_num(d[[pc]]),
                             order = as.character(k), stringsAsFactors = FALSE)
    }
    return(do.call(rbind, out))
  }
  stop("Could not identify round-level points columns")
}

# ---------------- final samples ----------------
prep <- function(d, label) {
  n0 <- nrow(d)
  keep_att <- attention_pass(d$attention_check)
  wt <- get_wtp(d)
  coh <- coherent(wt$W)
  keep <- keep_att & coh
  message(label, ": N=", n0, ", pass attention=", sum(keep_att), ", coherent=", sum(coh),
          ", final=", sum(keep))
  list(d = d[keep, , drop = FALSE], W = wt$W[keep, , drop = FALSE], levs = wt$levs)
}

S_pro <- prep(prolific, "Prolific")
S_ber <- prep(berkeley, "Berkeley")
S_bu <- prep(bu, "BU")

run_t5 <- function(S, label) {
  L <- build_long(S$d)
  L <- L[!is.na(L$round), ]
  L$public <- as.numeric(L$round == "public")
  L$paid <- as.numeric(L$round == "paid")
  message(label, " order values: ", paste(unique(L$order), collapse = ","))
  if (all(is.na(L$order)) || length(unique(L$order[!is.na(L$order)])) < 2) {
    m <- feols(points ~ public + paid, data = L, cluster = ~id)
  } else {
    # order dummies; the first (sorted) level is the omitted reference category
    L$order <- factor(L$order, levels = sort(unique(L$order[!is.na(L$order)])))
    m <- feols(points ~ public + paid + factor(order), data = L, cluster = ~id)
  }
  print(summary(m))
  list(m = m, L = L)
}

T_pro <- run_t5(S_pro, "Prolific")
T_ber <- run_t5(S_ber, "Berkeley")
T_bu <- run_t5(S_bu, "BU")

cf <- function(m, v) unname(coef(m)[v])

# ---------------- Table 6 col 4 (Berkeley): quadratic OLS PRU ----------------
W <- S_ber$W; levs <- S_ber$levs
panel <- data.frame(
  id = rep(S_ber$d$id, times = length(levs)),
  lev = rep(levs, each = nrow(W)),
  wtp = as.vector(W)
)
panel <- panel[panel$lev < 1700 & !is.na(panel$wtp), ]
panel$a <- (panel$lev + 50) / 100
panel$a2 <- panel$a^2
m6 <- feols(wtp ~ a + a2, data = panel, cluster = ~id)
print(summary(m6))
r0 <- cf(m6, "(Intercept)"); r1 <- cf(m6, "a"); r2 <- cf(m6, "a2")

# ---------------- Structural action-signaling (Berkeley) ----------------
Lb <- T_ber$L
anon_mean <- mean(Lb$points[Lb$round == "anon"], na.rm = TRUE) / 100
pr_eff <- cf(T_ber$m, "public") / 100
abar <- anon_mean + pr_eff

# R(a) = gamma1 (a - k) + gamma2 (a - k)^2 with k = rho*abar  => R(k) = 0
if (abs(r2) < 1e-12) {
  k <- -r0 / r1
} else {
  disc <- r1^2 - 4 * r2 * r0
  if (disc < 0) {
    k <- NA_real_
  } else {
    roots <- c((-r1 + sqrt(disc)) / (2 * r2), (-r1 - sqrt(disc)) / (2 * r2))
    slope <- r1 + 2 * r2 * roots
    ok <- roots[slope > 0]
    if (length(ok) == 1) k <- ok else k <- roots[which.min(abs(roots - abar))]
  }
}
gamma1 <- r1 + 2 * r2 * k
rho <- k / abar
# FOC: c * (a1 - a0) = R'(a1); averaging => c = (r1 + 2 r2 abar) / effect
c_par <- (r1 + 2 * r2 * abar) / pr_eff
p_incent <- 0.05 * 10  # 5 cents per 10 points = $0.50 per hundred points
pred_fi <- p_incent / c_par

message("r0=", r0, " r1=", r1, " r2=", r2, " abar=", abar, " k=", k)

cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.6f\n", cf(T_pro$m, "public")))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.6f\n", cf(T_pro$m, "paid")))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.6f\n", cf(T_ber$m, "public")))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.6f\n", cf(T_ber$m, "paid")))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.6f\n", cf(T_bu$m, "public")))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.6f\n", cf(T_bu$m, "paid")))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", as.integer(nobs(T_pro$m))))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", as.integer(nobs(T_ber$m))))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", as.integer(nobs(T_bu$m))))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.6f\n", gamma1))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.6f\n", rho))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.6f\n", c_par))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.6f\n", pred_fi))
