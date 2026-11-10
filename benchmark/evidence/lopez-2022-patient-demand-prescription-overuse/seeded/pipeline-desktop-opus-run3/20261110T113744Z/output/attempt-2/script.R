suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse"
fpath <- file.path(base, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")

d <- read_dta(fpath)
d <- as.data.frame(zap_labels(d))
# Stata: drop if dropme==1 (missing dropme is kept)
if ("dropme" %in% names(d)) {
  d <- d[is.na(d$dropme) | d$dropme != 1, , drop = FALSE]
}
cat("Rows after dropme filter:", nrow(d), "\n")

# ---------------------------------------------------------------------------
# Resolve variable names robustly (the error was an undefined column)
# ---------------------------------------------------------------------------
diag_hits <- grep("vouch|cscom|clinic|treat|^rx|^pv|^dv|arm|sev|mal", names(d),
                  ignore.case = TRUE, value = TRUE)
cat("Candidate-relevant variables:\n")
print(head(diag_hits, 200))

normz <- function(x) gsub("[^a-z0-9]", "", tolower(x))
resolve_var <- function(target, cands = character(0), pattern = NULL, exclude = NULL) {
  nmx <- names(d)
  isn <- vapply(d, is.numeric, logical(1))
  if (target %in% nmx) return(target)
  for (t in c(target, cands)) {
    if (t %in% nmx) return(t)
    i <- which(tolower(nmx) == tolower(t))
    if (length(i)) return(nmx[i[1]])
    i <- which(normz(nmx) == normz(t))
    if (length(i)) return(nmx[i[1]])
  }
  if (!is.null(pattern)) {
    hits <- grep(pattern, nmx, ignore.case = TRUE, value = TRUE)
    if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
    hits <- hits[isn[hits]]
    if (length(hits)) return(hits[1])
  }
  a <- agrep(target, nmx, max.distance = 0.15, ignore.case = TRUE, value = TRUE)
  a <- a[isn[a]]
  if (length(a)) return(a[1])
  NA_character_
}

map_var <- function(target, ...) {
  r <- resolve_var(target, ...)
  if (is.na(r)) {
    cat("WARNING: could not find variable", target, "\n")
    return(FALSE)
  }
  if (r != target) {
    cat("Mapping", target, "<-", r, "\n")
    d[[target]] <<- d[[r]]
  }
  TRUE
}

ok_pv <- map_var("patient_voucher",
                 cands = c("patientvoucher", "pat_voucher", "PV", "patient_vouch", "T_patient_voucher"),
                 pattern = "pat.*vouch|^pv$", exclude = "used|admin|doc")
ok_dv <- map_var("doctor_voucher",
                 cands = c("doctorvoucher", "doc_voucher", "DV", "doctor_vouch", "T_doctor_voucher"),
                 pattern = "doc.*vouch|^dv$", exclude = "used|admin|pat")

ok_cl <- map_var("cscomnum", cands = c("cscom", "cscom_num", "cscomid", "clinic", "clinicid",
                                       "clinic_id", "clinicnum"),
                 pattern = "^cscom|clinic.?(id|num)")

cl_names0 <- paste0("CL", 1:59)
cl_names0 <- cl_names0[cl_names0 %in% names(d)]
if (!ok_cl) {
  if (length(cl_names0) > 0) {
    cat("Building cluster id from clinic dummies CL*\n")
    M <- as.matrix(d[, cl_names0])
    M[is.na(M)] <- 0
    rs <- rowSums(M)
    cid <- max.col(M, ties.method = "first")
    cid[rs == 0] <- 0
    d$cscomnum <- cid
  } else {
    stop("No clinic/cluster identifier found")
  }
}
if (!ok_pv || !ok_dv) stop("Treatment variables patient_voucher / doctor_voucher not found")

outcomes <- c("used_vouchers_admin", "RXtreat_sev_simple_mal", "treat_sev_simple_mal",
              "RXtreat_severe_mal", "treat_severe_mal")
out_ok <- c(
  used_vouchers_admin = map_var("used_vouchers_admin",
                                cands = c("used_voucher_admin", "usedvoucher_admin", "used_vouchers",
                                          "used_voucher", "voucher_used"),
                                pattern = "used.*vouch"),
  RXtreat_sev_simple_mal = map_var("RXtreat_sev_simple_mal",
                                   cands = c("rx_treat_sev_simple_mal", "RXtreat_simple_sev_mal"),
                                   pattern = "^rx.*sev.*simple.*mal|^rx.*simple.*sev.*mal"),
  treat_sev_simple_mal = map_var("treat_sev_simple_mal",
                                 cands = c("treat_simple_sev_mal"),
                                 pattern = "^treat.*sev.*simple.*mal|^treat.*simple.*sev.*mal"),
  RXtreat_severe_mal = map_var("RXtreat_severe_mal",
                               cands = c("rx_treat_severe_mal", "RXtreat_sev_mal"),
                               pattern = "^rx.*severe.*mal"),
  treat_severe_mal = map_var("treat_severe_mal",
                             cands = c("treat_sev_mal"),
                             pattern = "^treat.*severe.*mal")
)

nm <- names(d)
isnum <- vapply(d, is.numeric, logical(1))

# $date = DD1-DD35 (partialled out), $clinic = CL1-CL59, $patient = CC*
dd_names <- paste0("DD", 1:35)
dd_names <- dd_names[dd_names %in% nm]
cl_names <- paste0("CL", 1:59)
cl_names <- cl_names[cl_names %in% nm]
cc_names <- grep("^CC", nm, value = TRUE)
cc_names <- cc_names[isnum[cc_names]]

if (length(dd_names) == 0) {
  # fallback: build date dummies from the visit date
  dfac <- factor(d$date)
  mm <- model.matrix(~ dfac)[, -1, drop = FALSE]
  colnames(mm) <- paste0("DDgen", seq_len(ncol(mm)))
  d <- cbind(d, mm)
  dd_names <- colnames(mm)
}
cat("Date dummies:", length(dd_names), " Clinic dummies:", length(cl_names),
    " Patient controls (CC*):", length(cc_names), "\n")

# ---------------------------------------------------------------------------
# Rigorous (cluster-robust) lasso a la lassopack::rlasso, used by pdslasso
# ---------------------------------------------------------------------------
lasso_cd <- function(X, y, pen, maxit = 100000, tol = 1e-9) {
  p <- ncol(X)
  xx <- colSums(X^2)
  b <- numeric(p)
  r <- y
  scale_ref <- sqrt(sum(y^2)) + 1e-12
  active <- integer(0)
  for (outer in 1:200) {
    g <- drop(crossprod(X, r))
    viol <- which(b == 0 & abs(g) > pen * (1 + 1e-10))
    if (length(viol) == 0) break
    active <- sort(unique(c(active, viol)))
    for (it in 1:maxit) {
      maxd <- 0
      for (j in active) {
        if (xx[j] <= 0) next
        xj <- X[, j]
        bo <- b[j]
        z <- sum(xj * r) + xx[j] * bo
        bn <- if (z > pen[j]) (z - pen[j]) / xx[j] else if (z < -pen[j]) (z + pen[j]) / xx[j] else 0
        if (bn != bo) {
          r <- r - xj * (bn - bo)
          b[j] <- bn
          dd <- abs(bn - bo) * sqrt(xx[j])
          if (dd > maxd) maxd <- dd
        }
      }
      if (maxd < tol * scale_ref) break
    }
  }
  b
}

rlasso_select <- function(y, X, clus, c = 1.1, maxpsiiter = 2) {
  n <- length(y)
  p <- ncol(X)
  if (p == 0) return(character(0))
  G <- length(unique(clus))
  gamma <- 0.1 / log(G)
  lambda <- 2 * c * sqrt(n) * qnorm(1 - gamma / (2 * p))
  # initial residuals: regress y on the 5 most correlated regressors
  cr <- abs(suppressWarnings(cor(X, y)))
  cr[is.na(cr)] <- 0
  top <- order(-cr)[seq_len(min(5, p))]
  e <- y - X[, top, drop = FALSE] %*% qr.coef(qr(X[, top, drop = FALSE]), y)
  e <- drop(e)
  e[is.na(e)] <- 0
  sel <- integer(0)
  for (k in seq_len(maxpsiiter)) {
    S <- rowsum(X * e, clus)
    psi <- sqrt(colSums(S^2) / n)
    if (any(psi > 0)) psi[psi <= 0] <- min(psi[psi > 0]) else psi[] <- 1
    b <- lasso_cd(X, y, lambda * psi / 2)
    sel <- which(b != 0)
    if (length(sel) > 0) {
      Xs <- X[, sel, drop = FALSE]
      cf <- qr.coef(qr(Xs), y)
      cf[is.na(cf)] <- 0
      e <- drop(y - Xs %*% cf)
    } else {
      e <- y
    }
  }
  colnames(X)[sel]
}

pds_reg <- function(yname, data) {
  need <- c(yname, "patient_voucher", "doctor_voucher", "cscomnum", dd_names)
  miss <- setdiff(need, names(data))
  if (length(miss) > 0) {
    cat("  missing columns for", yname, ":", paste(miss, collapse = ", "), "\n")
    return(NULL)
  }
  keep <- complete.cases(data[, need])
  dat <- data[keep, , drop = FALSE]
  xnames <- setdiff(c(cl_names, cc_names), c(yname, "patient_voucher", "doctor_voucher", "cscomnum"))
  # drop candidate controls with missing values in this sample
  hasna <- vapply(xnames, function(v) anyNA(dat[[v]]), logical(1))
  if (any(hasna)) cat("  dropping", sum(hasna), "controls with missing values\n")
  xnames <- xnames[!hasna]

  Z <- cbind(1, as.matrix(dat[, dd_names]))
  qz <- qr(Z)
  y <- qr.resid(qz, as.numeric(dat[[yname]]))
  pv <- qr.resid(qz, as.numeric(dat$patient_voucher))
  dv <- qr.resid(qz, as.numeric(dat$doctor_voucher))
  X <- as.matrix(dat[, xnames, drop = FALSE])
  storage.mode(X) <- "double"
  X <- qr.resid(qz, X)
  X <- matrix(X, nrow = nrow(dat))
  colnames(X) <- xnames
  ss <- colSums(X^2)
  X <- X[, ss > 1e-8, drop = FALSE]
  clus <- dat$cscomnum

  s_y <- rlasso_select(y, X, clus)
  s_p <- rlasso_select(pv, X, clus)
  s_d <- rlasso_select(dv, X, clus)
  sel <- unique(c(s_y, s_p, s_d))
  cat(sprintf("  %s: selected %d (y) %d (PV) %d (DV) -> union %d\n",
              yname, length(s_y), length(s_p), length(s_d), length(sel)))

  rhs <- c("patient_voucher", "doctor_voucher", dd_names, sel)
  fml <- as.formula(paste0("`", yname, "` ~ ", paste0("`", rhs, "`", collapse = " + ")))
  m <- feols(fml, data = dat, cluster = ~cscomnum)
  m
}

models <- list()
for (o in outcomes) {
  m <- tryCatch(pds_reg(o, d), error = function(e) {
    cat("  ERROR for", o, ":", conditionMessage(e), "\n")
    NULL
  })
  if (is.null(m)) next
  models[[o]] <- m
  cf <- coef(m)[c("patient_voucher", "doctor_voucher")]
  se <- sqrt(diag(vcov(m)))[c("patient_voucher", "doctor_voucher")]
  cat(sprintf("  %s: PV=%.4f (%.4f) DV=%.4f (%.4f) N=%d\n", o, cf[1], se[1], cf[2], se[2],
              nobs(m)))
  w <- tryCatch(wald(m, keep = "^patient_voucher$|^doctor_voucher$", print = FALSE),
                error = function(e) NULL)
  if (!is.null(w)) cat(sprintf("  joint PV=DV=0 p-value: %.4f\n", w$p))
}

getb <- function(o, v) {
  if (is.null(models[[o]])) return(NA_real_)
  unname(coef(models[[o]])[v])
}
getn <- function(o) {
  if (is.null(models[[o]])) return(NA_real_)
  as.numeric(nobs(models[[o]]))
}

cat(sprintf("RESULT:voucher_used_patient_voucher_table3_col1=%.6f\n", getb("used_vouchers_admin", "patient_voucher")))
cat(sprintf("RESULT:voucher_used_doctor_voucher_table3_col1=%.6f\n", getb("used_vouchers_admin", "doctor_voucher")))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_patient_voucher_table3_col2=%.6f\n", getb("RXtreat_sev_simple_mal", "patient_voucher")))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_doctor_voucher_table3_col2=%.6f\n", getb("RXtreat_sev_simple_mal", "doctor_voucher")))
cat(sprintf("RESULT:any_malaria_treatment_purchased_patient_voucher_table3_col3=%.6f\n", getb("treat_sev_simple_mal", "patient_voucher")))
cat(sprintf("RESULT:any_malaria_treatment_purchased_doctor_voucher_table3_col3=%.6f\n", getb("treat_sev_simple_mal", "doctor_voucher")))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_patient_voucher_table3_col4=%.6f\n", getb("RXtreat_severe_mal", "patient_voucher")))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_doctor_voucher_table3_col4=%.6f\n", getb("RXtreat_severe_mal", "doctor_voucher")))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_patient_voucher_table3_col5=%.6f\n", getb("treat_severe_mal", "patient_voucher")))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_doctor_voucher_table3_col5=%.6f\n", getb("treat_severe_mal", "doctor_voucher")))
cat(sprintf("RESULT:n_obs_table3_col1=%.0f\n", getn("used_vouchers_admin")))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%.0f\n", getn("RXtreat_sev_simple_mal")))