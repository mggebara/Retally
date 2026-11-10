suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride.script-free/Packet/Raw Data"

read_chr <- function(f) {
  d <- readr::read_csv(file.path(base, f), col_types = readr::cols(.default = readr::col_character()),
                       show_col_types = FALSE)
  d
}
conv <- function(d) suppressMessages(readr::type_convert(d, guess_integer = FALSE))

prolific <- conv(read_chr("prolific_survey_data.csv"))
berkeley <- conv(read_chr("berkeley_survey_data.csv"))
bu1 <- read_chr("bu_qm221_survey_data.csv"); bu1$source_file <- "qm221"
bu2 <- read_chr("bu_qm222_survey_data.csv"); bu2$source_file <- "qm222"
bu <- conv(bind_rows(bu1, bu2))
bu$id <- paste0(bu$source_file, "_", bu$id)

prolific <- as.data.frame(prolific)
berkeley <- as.data.frame(berkeley)
bu <- as.data.frame(bu)

# ------------------------------------------------------------------
# WTP profiles
# ------------------------------------------------------------------
pref_sign <- function(x) {
  if (is.logical(x)) return(ifelse(x, 1, -1))
  if (is.numeric(x)) {
    u <- sort(unique(x[!is.na(x)]))
    if (all(u %in% c(0, 1))) return(ifelse(x == 1, 1, -1))
    if (all(u %in% c(1, 2))) return(ifelse(x == 1, 1, -1))
    return(sign(x))
  }
  xl <- tolower(as.character(x))
  neg <- grepl("not|don|^no|anonym|private", xl)
  pos <- grepl("yes|public|shar|recogn|want|name", xl)
  ifelse(is.na(xl), NA, ifelse(neg, -1, ifelse(pos, 1, NA)))
}

build_wtp <- function(d) {
  pc <- grep("^preference_[0-9]+$", names(d), value = TRUE)
  ks <- as.numeric(sub("preference_", "", pc))
  ord <- order(ks); pc <- pc[ord]; ks <- ks[ord]
  W <- matrix(NA_real_, nrow(d), length(pc))
  for (j in seq_along(pc)) {
    k <- ks[j]
    x <- d[[pc[j]]]
    comp <- grep(paste0("^(wtp|amount|value|price|willing|pay|bid)[A-Za-z_]*_", k, "$"),
                 names(d), value = TRUE, ignore.case = TRUE)
    if (is.numeric(x) && any(x < 0, na.rm = TRUE)) {
      W[, j] <- x
    } else if (length(comp) > 0) {
      s <- pref_sign(x)
      W[, j] <- s * abs(suppressWarnings(as.numeric(d[[comp[1]]])))
    } else {
      W[, j] <- suppressWarnings(as.numeric(x))
    }
  }
  colnames(W) <- as.character(ks)
  list(W = W, ks = ks)
}

coherent_profile <- function(w) {
  w <- w[!is.na(w)]
  if (length(w) < 2) return(length(w) > 0)
  s <- sign(diff(w)); s <- s[s != 0]
  if (length(s) == 0) return(TRUE)
  v <- rle(s)$values
  length(v) == 1 || identical(as.numeric(v), c(1, -1))
}

# ------------------------------------------------------------------
# Effort rounds: AnomPts (anonymous), EarnPts (paid), RecogPts (public)
# Round order inferred from which permutation's page timers are non-missing
# (a = anon, e = earn/paid, r = recognition/public)
# ------------------------------------------------------------------
get_rounds <- function(d) {
  ptsmap <- c(anon = "AnomPts", paid = "EarnPts", public = "RecogPts")
  letmap <- c(anon = "a", paid = "e", public = "r")
  perms <- c("aer", "ear", "are", "era", "rea", "rae")
  code <- rep(NA_character_, nrow(d))
  for (p in perms) {
    cols <- grep(paste0("^(anom|earn|rec)_", p, "_timer"), names(d), value = TRUE)
    if (length(cols) == 0) next
    sub_d <- as.data.frame(d[, cols, drop = FALSE])
    has <- rowSums(!is.na(sub_d) & sapply(sub_d, function(v) as.character(v) != "")) > 0
    has[is.na(has)] <- FALSE
    code[is.na(code) & has] <- p
  }
  cat("Order permutation codes:\n"); print(table(code, useNA = "ifany"))
  rows <- list()
  for (r in names(ptsmap)) {
    if (!(ptsmap[[r]] %in% names(d))) next
    o <- ifelse(is.na(code), NA_real_, as.numeric(regexpr(letmap[[r]], code, fixed = TRUE)))
    rows[[r]] <- data.frame(id = d$id, round = r,
                            points = suppressWarnings(as.numeric(d[[ptsmap[[r]]]])),
                            order = as.numeric(o), stringsAsFactors = FALSE)
  }
  out <- bind_rows(rows)
  out$public <- as.integer(out$round == "public")
  out$paid <- as.integer(out$round == "paid")
  out
}

final_sample <- function(d, label) {
  n0 <- nrow(d)
  if ("attention_check" %in% names(d)) {
    cat(label, "attention_check values:\n"); print(table(d$attention_check, useNA = "ifany"))
    # attention_check is only recorded (non-missing) for respondents flagged by the check
    d <- d[is.na(d$attention_check), , drop = FALSE]
  }
  n1 <- nrow(d)
  bw <- build_wtp(d)
  coh <- apply(bw$W, 1, coherent_profile)
  d <- d[coh, , drop = FALSE]
  cat(label, ": raw", n0, "after attention", n1, "after coherence", nrow(d), "\n")
  d
}

run_t5 <- function(d, label) {
  lg <- get_rounds(d)
  lg <- lg[!is.na(lg$points), ]
  if (all(is.na(lg$order))) {
    m <- feols(points ~ public + paid, data = lg, cluster = ~id)
  } else {
    m <- feols(points ~ public + paid + i(order, ref = 1), data = lg, cluster = ~id)
  }
  cat("==== Table 5:", label, "====\n"); print(summary(m))
  list(model = m, long = lg)
}

safe <- function(expr) tryCatch(expr, error = function(e) { message("ERROR: ", conditionMessage(e)); NA })

pro_f <- final_sample(prolific, "Prolific")
ber_f <- final_sample(berkeley, "Berkeley")
bu_f <- final_sample(bu, "BU")

t5p <- safe(run_t5(pro_f, "Prolific"))
t5b <- safe(run_t5(ber_f, "Berkeley"))
t5u <- safe(run_t5(bu_f, "BU"))

getc <- function(t, v) if (is.list(t)) unname(coef(t$model)[v]) else NA
getn <- function(t) if (is.list(t)) nobs(t$model) else NA

pr_p <- getc(t5p, "public"); fi_p <- getc(t5p, "paid")
pr_b <- getc(t5b, "public"); fi_b <- getc(t5b, "paid")
pr_u <- getc(t5u, "public"); fi_u <- getc(t5u, "paid")

# ------------------------------------------------------------------
# Table 6 col 4 (Berkeley quadratic PRU, 1700+ excluded) and Table 7 structural
# ------------------------------------------------------------------
gamma1 <- NA; rho <- NA; cpar <- NA; pred <- NA
res7 <- safe({
  if (!is.list(t5b)) stop("Berkeley Table 5 unavailable")
  bw <- build_wtp(ber_f)
  W <- as.data.frame(bw$W); W$id <- ber_f$id
  wl <- pivot_longer(W, -id, names_to = "k", values_to = "wtp")
  wl$k <- as.numeric(wl$k)
  wl <- wl[!is.na(wl$wtp) & wl$k < 1700, ]
  wl$m <- (wl$k + 50) / 100
  wl$m2 <- wl$m^2
  m6 <- feols(wtp ~ m + m2, data = wl, cluster = ~id)
  cat("==== Table 6 col 4 (Berkeley) ====\n"); print(summary(m6))
  r0 <- unname(coef(m6)["(Intercept)"]); r1 <- unname(coef(m6)["m"]); r2 <- unname(coef(m6)["m2"])

  # zero of the PRU where image payoffs switch sign (upward crossing)
  if (abs(r2) < 1e-12) {
    x <- -r0 / r1
  } else {
    disc <- r1^2 - 4 * r2 * r0
    if (disc < 0) stop("no real root of PRU")
    roots <- c((-r1 - sqrt(disc)) / (2 * r2), (-r1 + sqrt(disc)) / (2 * r2))
    up <- roots[(r1 + 2 * r2 * roots) > 0]
    cand <- up[up > 0]
    x <- if (length(cand) > 0) min(cand) else if (length(up) > 0) up[1] else roots[which.min(abs(roots))]
  }
  lg <- t5b$long
  a0 <- mean(lg$points[lg$round == "anon"], na.rm = TRUE) / 100
  delta <- pr_b / 100
  abar_pr <- a0 + delta
  rho_ <- x / abar_pr
  g1 <- r1 + 2 * r2 * x
  # PR effect: delta = (r1 + 2 r2 a0) / (c - 2 r2)
  c_ <- 2 * r2 + (r1 + 2 * r2 * a0) / delta
  p <- 0.05 * 10  # 5 cents per 10 points = $0.50 per hundred points
  cat("r0", r0, "r1", r1, "r2", r2, "root", x, "a0", a0, "delta", delta, "\n")
  list(g1 = g1, rho = rho_, c = c_, pred = p / c_)
})
if (is.list(res7)) { gamma1 <- res7$g1; rho <- res7$rho; cpar <- res7$c; pred <- res7$pred }

cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.6f\n", pr_p))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.6f\n", fi_p))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.6f\n", pr_b))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.6f\n", fi_b))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.6f\n", pr_u))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.6f\n", fi_u))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%s\n", getn(t5p)))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%s\n", getn(t5b)))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%s\n", getn(t5u)))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.6f\n", gamma1))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.6f\n", rho))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.6f\n", cpar))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.6f\n", pred))