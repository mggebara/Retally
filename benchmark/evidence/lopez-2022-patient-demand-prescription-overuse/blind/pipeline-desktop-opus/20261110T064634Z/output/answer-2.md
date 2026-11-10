suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse.script-free"
fpath <- file.path(base_dir, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
raw <- haven::read_dta(fpath)
df <- as.data.frame(haven::zap_labels(raw))
nms <- names(df)
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")

num <- function(x) suppressWarnings(as.numeric(x))

find_var <- function(patterns, exclude = NULL, must_binary = FALSE) {
  for (p in patterns) {
    hits <- grep(p, nms, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
    if (length(hits) == 0) next
    if (must_binary) {
      hits <- hits[vapply(hits, function(h) {
        v <- num(df[[h]]); u <- unique(v[!is.na(v)])
        isTRUE(length(u) >= 2 && all(u %in% c(0, 1)))
      }, logical(1))]
    }
    if (length(hits) == 0) next
    hits <- hits[vapply(hits, function(h) isTRUE(sum(!is.na(num(df[[h]]))) > 100), logical(1))]
    if (length(hits) > 0) {
      cat("Pattern", p, "->", paste(head(hits, 10), collapse = ", "), "\n")
      return(hits[1])
    }
  }
  NA_character_
}

# ---------------- Treatment indicators ----------------
pv_var <- find_var(c("^patient_voucher$", "^PV$", "^pv_day$", "patient_voucher"), must_binary = TRUE)
dv_var <- find_var(c("^doctor_voucher$", "^DV$", "^dv_day$", "doctor_voucher"), must_binary = TRUE)
cat("PV var:", pv_var, " DV var:", dv_var, "\n")
df$PV <- num(df[[pv_var]])
df$DV <- num(df[[dv_var]])

# ---------------- Clinic and date ----------------
clinic_var <- find_var(c("^cscomnum$", "^cscom$", "^cscom_id$", "^cscomnum", "^cscom", "^clinic$", "^clinic_id$", "clinic", "cscom"),
                       exclude = "census|dist|name")
date_var <- if ("date" %in% nms) "date" else find_var(c("^date$", "^visit_date", "^date_"), exclude = "home")
cat("Clinic var:", clinic_var, " Date var:", date_var, "\n")
df$clinic_id <- as.character(df[[clinic_var]])
df$date_fe <- as.character(df[[date_var]])

# ---------------- Sample: in-clinic survey patients ----------------
samp <- df
if ("patient" %in% nms) {
  pv <- num(samp$patient); u <- unique(pv[!is.na(pv)])
  if (length(u) <= 2 && all(u %in% c(0, 1)) && sum(pv == 1, na.rm = TRUE) > 1000) {
    samp <- samp[!is.na(pv) & pv == 1, ]
    cat("Restricted to patient==1:", nrow(samp), "\n")
  }
}
samp <- samp[!is.na(samp$PV) & !is.na(samp$DV) & !is.na(samp$clinic_id) & samp$clinic_id != "" &
               !is.na(samp$date_fe) & samp$date_fe != "", ]
cat("Analysis sample:", nrow(samp), " clinics:", length(unique(samp$clinic_id)),
    " control obs:", sum(samp$PV == 0 & samp$DV == 0), "\n")

# ---------------- Outcomes ----------------
yes <- function(x) { v <- num(x); ifelse(is.na(v), 0, as.numeric(v == 1)) }

used_var <- find_var(c("^voucher_used$", "^used_voucher$", "^vouchers?_used$", "^any_voucher_used"), must_binary = TRUE)
if (!is.na(used_var)) {
  samp$y_used <- num(samp[[used_var]])
  samp$y_used[is.na(samp$y_used)] <- 0
} else {
  u_pv <- if ("voucher_used_PV" %in% nms) yes(samp$voucher_used_PV) else 0
  u_dv <- if ("voucher_used_DV" %in% nms) yes(samp$voucher_used_DV) else 0
  samp$y_used <- ifelse(samp$PV == 1, u_pv, ifelse(samp$DV == 1, u_dv, 0))
}
cat("Mean voucher used by arm:\n"); print(tapply(samp$y_used, paste(samp$PV, samp$DV), mean))

any_presc_var <- find_var(c("^prescribed_any_antimalarial$", "^any_antimalarial_presc", "^presc.*any.*mal", "^rx_any.*mal",
                            "any.*mal.*presc", "^presc.*antimal", "antimal.*presc", "^prescribed_malaria", "presc.*malaria"),
                          exclude = "severe|simple|act$|_act|home|control|pred|rdt", must_binary = TRUE)
any_purch_var <- find_var(c("^purchased_any_antimalarial$", "^any_antimalarial_purch", "^purch.*any.*mal", "any.*mal.*purch",
                            "^purch.*antimal", "antimal.*purch", "^purchased_malaria", "purch.*malaria", "bought.*mal", "obtain.*mal"),
                          exclude = "severe|simple|act$|_act|home|control|pred|rdt", must_binary = TRUE)
sev_presc_var <- find_var(c("^prescribed_severe", "^presc.*severe", "severe.*presc", "^rx_severe", "severe.*rx"),
                          exclude = "home|control|pred|rdt", must_binary = TRUE)
sev_purch_var <- find_var(c("^purchased_severe", "^purch.*severe", "severe.*purch", "bought.*severe", "severe.*bought"),
                          exclude = "home|control|pred|rdt", must_binary = TRUE)
cat("Outcomes:", any_presc_var, any_purch_var, sev_presc_var, sev_purch_var, "\n")

# Fallbacks built from treatment components if named outcomes are absent
build_or <- function(pats, excl) {
  vs <- unique(unlist(lapply(pats, function(p) grep(p, nms, value = TRUE, ignore.case = TRUE))))
  if (!is.null(excl)) vs <- vs[!grepl(excl, vs, ignore.case = TRUE)]
  if (length(vs) == 0) return(NULL)
  vs <- vs[vapply(vs, function(h) { v <- num(df[[h]]); u <- unique(v[!is.na(v)]); isTRUE(length(u) >= 2 && all(u %in% c(0, 1))) }, logical(1))]
  if (length(vs) == 0) return(NULL)
  cat("Building from:", paste(vs, collapse = ", "), "\n")
  m <- matrix(sapply(vs, function(h) num(samp[[h]])), nrow = nrow(samp))
  allna <- apply(is.na(m), 1, all)
  out <- as.numeric(rowSums(m == 1, na.rm = TRUE) > 0)
  out[allna] <- NA
  out
}
get_y <- function(v, pats, excl) {
  if (!is.na(v)) return(num(samp[[v]]))
  b <- build_or(pats, excl)
  if (is.null(b)) rep(NA_real_, nrow(samp)) else b
}
samp$y_any_presc <- get_y(any_presc_var, c("^presc.*act", "^presc.*quinine", "^presc.*artem"), "home|pred")
samp$y_any_purch <- get_y(any_purch_var, c("^purch.*act", "^purch.*quinine", "^purch.*artem"), "home|pred")
samp$y_sev_presc <- get_y(sev_presc_var, c("^presc.*quinine_inj", "^presc.*artem.*mono"), "home|pred")
samp$y_sev_purch <- get_y(sev_purch_var, c("^purch.*quinine_inj", "^purch.*artem.*mono"), "home|pred")

# ---------------- Post-double-selection lasso (BCH rigorous penalty) ----------------
excl_ctrl <- paste0("voucher|presc|purch|treat|quinine|artem|act|rdt|test|antibiotic|injection|inject|iv$|home|video|",
                    "result|redeem|used|cost|paid|spend|spent|price|_dv|_pv|pred|pos|neg|match|follow|consent|",
                    "selected|date|time|week|cscom|clinic|patient$|^id|_id$|doctor|trust|train|surveyor|enum|record|",
                    "diagnos|referr|bought|obtain|drug|medic|pharm|bill|fee|satisf|comments|number")
incl_ctrl <- paste0("^age|_age|gender|female|male|french|educ|school|symptom|fever|chill|sweat|naus|vomit|diarr|",
                    "appetite|headache|cough|weak|fatigue|conscious|duration|days_ill|days_sick|illness_days|",
                    "pregnan|literate|married|wealth|asset|distance|travel|child|adult|under5|bambara|respondent|",
                    "relation|head|employ|occup|income|household|hh_")
cand <- nms[grepl(incl_ctrl, nms, ignore.case = TRUE) & !grepl(excl_ctrl, nms, ignore.case = TRUE)]
cand <- cand[vapply(cand, function(h) {
  v <- num(samp[[h]])
  if (all(is.na(v))) return(FALSE)
  if (mean(is.na(v)) > 0.05) return(FALSE)
  if (is.character(samp[[h]]) && mean(is.na(v)) > 0) return(FALSE)
  s <- sd(v, na.rm = TRUE)
  !is.na(s) && s > 0
}, logical(1))]
cat("Candidate controls (", length(cand), "):", paste(head(cand, 60), collapse = ", "), "\n")

lasso_select <- function(y, X) {
  n <- nrow(X); p <- ncol(X)
  if (p == 0) return(integer(0))
  lambda <- 2 * 1.1 * sqrt(n) * qnorm(1 - (0.1 / log(n)) / (2 * p))
  sel_from <- function(psi) {
    b <- rep(0, p); r <- y
    xx <- colSums(X^2) / n
    for (it in 1:500) {
      bold <- b
      for (j in 1:p) {
        rj <- r + X[, j] * b[j]
        z <- sum(X[, j] * rj) / n
        thr <- lambda * psi[j] / (2 * n)
        bj <- sign(z) * max(abs(z) - thr, 0) / xx[j]
        r <- rj - X[, j] * bj
        b[j] <- bj
      }
      if (max(abs(b - bold)) < 1e-7) break
    }
    which(b != 0)
  }
  e <- y - mean(y)
  psi <- sqrt(colMeans(X^2 * e^2))
  psi[psi == 0] <- 1e-8
  sel <- integer(0)
  for (k in 1:5) {
    sel <- sel_from(psi)
    if (length(sel) > 0) {
      fit <- lm.fit(cbind(1, X[, sel, drop = FALSE]), y)
      e <- fit$residuals
    } else e <- y - mean(y)
    psi_new <- sqrt(colMeans(X^2 * e^2)); psi_new[psi_new == 0] <- 1e-8
    if (max(abs(psi_new - psi)) < 1e-6) break
    psi <- psi_new
  }
  sel
}

demean_by <- function(v, g) v - ave(v, g, FUN = mean)

pds_controls <- function(d, ycol) {
  out <- tryCatch({
    if (length(cand) == 0) return(character(0))
    X <- sapply(cand, function(h) { v <- num(d[[h]]); v[is.na(v)] <- mean(v, na.rm = TRUE); v })
    X <- as.matrix(X)
    keep <- apply(X, 2, function(z) sd(z) > 0)
    X <- X[, keep, drop = FALSE]
    g <- d$date_fe
    Xd <- apply(X, 2, demean_by, g = g)
    sds <- apply(Xd, 2, sd)
    Xd <- Xd[, sds > 1e-10, drop = FALSE]
    cn <- colnames(Xd)
    y <- demean_by(d[[ycol]], g); pv <- demean_by(d$PV, g); dv <- demean_by(d$DV, g)
    s1 <- lasso_select(y, Xd); s2 <- lasso_select(pv, Xd); s3 <- lasso_select(dv, Xd)
    unique(cn[c(s1, s2, s3)])
  }, error = function(e) { cat("Lasso error:", conditionMessage(e), "\n"); character(0) })
  out
}

run_reg <- function(ycol) {
  d <- samp[!is.na(samp[[ycol]]), ]
  if (nrow(d) < 50) return(list(bP = NA, bD = NA, n = NA))
  ctrls <- pds_controls(d, ycol)
  cat("\nOutcome", ycol, " N =", nrow(d), " selected controls:", paste(ctrls, collapse = ", "), "\n")
  for (h in ctrls) { v <- num(d[[h]]); v[is.na(v)] <- mean(v, na.rm = TRUE); d[[paste0("c_", h)]] <- v }
  rhs <- c("PV", "DV", if (length(ctrls)) paste0("c_", ctrls))
  f <- as.formula(paste(ycol, "~", paste(rhs, collapse = " + "), "| date_fe"))
  m <- tryCatch(feols(f, data = d, cluster = ~clinic_id),
                error = function(e) feols(as.formula(paste(ycol, "~ PV + DV | date_fe")), data = d, cluster = ~clinic_id))
  print(coeftable(m)[c("PV", "DV"), , drop = FALSE])
  tryCatch({
    w <- wald(m, keep = "^PV$|^DV$", print = FALSE); cat("Joint p:", w$p, "\n")
  }, error = function(e) NULL)
  list(bP = unname(coef(m)["PV"]), bD = unname(coef(m)["DV"]), n = nobs(m))
}

r1 <- run_reg("y_used")
r2 <- run_reg("y_any_presc")
r3 <- run_reg("y_any_purch")
r4 <- run_reg("y_sev_presc")
r5 <- run_reg("y_sev_purch")

n25 <- r2$n
if (is.na(n25)) n25 <- r3$n

cat(sprintf("RESULT:voucher_used_patient_voucher_table3_col1=%.6f\n", r1$bP))
cat(sprintf("RESULT:voucher_used_doctor_voucher_table3_col1=%.6f\n", r1$bD))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_patient_voucher_table3_col2=%.6f\n", r2$bP))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_doctor_voucher_table3_col2=%.6f\n", r2$bD))
cat(sprintf("RESULT:any_malaria_treatment_purchased_patient_voucher_table3_col3=%.6f\n", r3$bP))
cat(sprintf("RESULT:any_malaria_treatment_purchased_doctor_voucher_table3_col3=%.6f\n", r3$bD))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_patient_voucher_table3_col4=%.6f\n", r4$bP))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_doctor_voucher_table3_col4=%.6f\n", r4$bD))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_patient_voucher_table3_col5=%.6f\n", r5$bP))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_doctor_voucher_table3_col5=%.6f\n", r5$bD))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", as.integer(r1$n)))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", as.integer(n25)))
