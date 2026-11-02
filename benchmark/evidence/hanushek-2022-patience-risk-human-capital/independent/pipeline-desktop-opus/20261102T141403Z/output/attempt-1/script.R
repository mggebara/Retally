suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
  library(haven)
})
set.seed(42)
options(warn = 1)
setFixest_nthreads(max(1, min(4, parallel::detectCores(), na.rm = TRUE)))

root <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free/Replication/Data"
full_csv  <- file.path(root, "CSV/pisa_full_gps_final.csv")
full_dta  <- file.path(root, "Working/pisa_full_gps_final.dta")
imcoo_csv <- file.path(root, "CSV/pisa_full_gps_final_imcoo.csv")
imcoo_dta <- file.path(root, "Working/pisa_full_gps_final_imcoo.dta")

msg <- function(...) message(paste0(...))

get_header <- function(csv, dta) {
  h <- tryCatch(names(fread(csv, nrows = 0, showProgress = FALSE)), error = function(e) NULL)
  src <- "csv"
  if (is.null(h) || length(h) == 0) {
    h <- names(haven::read_dta(dta, n_max = 1))
    src <- "dta"
  }
  list(names = h, src = src)
}

read_cols <- function(csv, dta, cols, src) {
  d <- NULL
  if (src == "csv") {
    d <- tryCatch(fread(csv, select = cols, showProgress = FALSE),
                  error = function(e) { msg("fread failed: ", conditionMessage(e)); NULL })
  }
  if (is.null(d)) {
    d <- haven::read_dta(dta, col_select = dplyr::all_of(cols))
    d <- haven::zap_labels(d)
    d <- as.data.table(d)
  }
  d
}

find_weight <- function(h) {
  exact <- h[tolower(h) %in% c("w_fstuwt", "w_fstuwt_orig", "stuwgt", "weight", "wgt", "sweight")]
  if (length(exact)) return(exact[1])
  cand <- grep("fstuwt|weight|wgt", h, ignore.case = TRUE, value = TRUE)
  cand <- cand[!grepl("^w_fstr", cand, ignore.case = TRUE)]
  if (length(cand)) return(cand[1])
  NA_character_
}

num <- function(x) suppressWarnings(as.numeric(x))

fill_control <- function(d, v) {
  # fill missing control values with mean; add/augment imputation dummy
  if (!v %in% names(d)) return(character(0))
  d[, (v) := num(get(v))]
  imv <- paste0("im", v)
  miss <- is.na(d[[v]])
  if (imv %in% names(d)) {
    d[, (imv) := num(get(imv))]
    d[is.na(get(imv)), (imv) := 0]
    if (any(miss)) d[miss, (imv) := 1]
  } else if (any(miss)) {
    d[, (imv) := as.numeric(miss)]
  }
  if (any(miss)) d[miss, (v) := mean(d[[v]], na.rm = TRUE)]
  out <- v
  if (imv %in% names(d) && length(unique(d[[imv]])) > 1) out <- c(out, imv)
  out
}

prep_outcome <- function(d) {
  d[, y := num(pv1math)]
  if (mean(d$y, na.rm = TRUE) > 20) d[, y := y / 100]
  d
}

make_weights <- function(d, wcol, ctry) {
  if (!is.na(wcol) && wcol %in% names(d)) {
    d[, w0 := num(get(wcol))]
  } else {
    d[, w0 := 1]
  }
  d[is.na(w0) | w0 <= 0, w0 := NA_real_]
  # sampling weights normalised so that each country receives equal total weight
  d[, w := w0 / sum(w0, na.rm = TRUE), by = ctry]
  d[, w := w * 1000]
  d
}

safe_coef <- function(m, v) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

run_feols <- function(fml, data, cl) {
  tryCatch(feols(as.formula(fml), data = data, weights = ~w, cluster = cl, lean = TRUE,
                 notes = FALSE),
           error = function(e) { msg("feols failed: ", conditionMessage(e)); NULL })
}

# ===================== Table 1: cross-country analysis =====================
hf <- get_header(full_csv, full_dta)
H <- hf$names
msg("Full data header (", length(H), " cols, src=", hf$src, ")")
msg(paste(head(H, 300), collapse = ", "))

wcol_f <- find_weight(H)
msg("Weight column (full): ", wcol_f)

mig_vars <- intersect(c("migra0", "migra1", "migra2"), H)
mig_flag_cands <- grep("^(im|mm)_?mig|^immigr|^immig", H, ignore.case = TRUE, value = TRUE)
mig_flag_cands <- setdiff(mig_flag_cands, mig_vars)
want_f <- unique(c("wave", "country", "pv1math", "patience", "risktaking",
                   intersect(c("female", "imfemale", "age", "image"), H),
                   mig_vars, mig_flag_cands,
                   if (!is.na(wcol_f)) wcol_f))
want_f <- want_f[want_f %in% H]
msg("Reading full data columns: ", paste(want_f, collapse = ", "))
d1 <- read_cols(full_csv, full_dta, want_f, hf$src)
msg("Full data rows: ", nrow(d1))

d1 <- prep_outcome(d1)
d1[, patience := num(patience)]
d1[, risktaking := num(risktaking)]
d1 <- d1[!is.na(y) & !is.na(patience) & !is.na(risktaking)]
d1 <- make_weights(d1, wcol_f, "country")
d1 <- d1[!is.na(w)]
msg("Analysis rows: ", nrow(d1), "; countries: ", uniqueN(d1$country))

ctrl1 <- c(fill_control(d1, "female"), fill_control(d1, "age"))

# migration status
native <- rep(NA, nrow(d1))
mig_ctrl <- character(0)
if (length(mig_vars)) {
  for (v in mig_vars) d1[, (v) := num(get(v))]
  shares <- sapply(mig_vars, function(v) mean(d1[[v]] == 1, na.rm = TRUE))
  msg("Migration dummy shares: ", paste(names(shares), round(shares, 4), collapse = "; "))
  natv <- names(shares)[which.max(shares)]
  othv <- setdiff(mig_vars, natv)
  s <- rowSums(as.matrix(d1[, ..mig_vars]), na.rm = FALSE)
  missing_mig <- is.na(s) | abs(s - 1) > 1e-6
  # imputation flag for migration status, if present (0/1 variable)
  flag <- NULL
  for (fv in mig_flag_cands) {
    x <- num(d1[[fv]])
    ux <- unique(x[!is.na(x)])
    if (length(ux) <= 2 && all(ux %in% c(0, 1))) { flag <- fv; break }
  }
  if (!is.null(flag)) {
    d1[, (flag) := num(get(flag))]
    d1[is.na(get(flag)), (flag) := 0]
    missing_mig <- missing_mig | d1[[flag]] == 1
  }
  msg("Migration status missing/imputed: ", sum(missing_mig))
  native <- (d1[[natv]] == 1) & !missing_mig
  migrant <- (rowSums(as.matrix(d1[, ..othv]) == 1, na.rm = TRUE) > 0) & !missing_mig
  for (v in mig_vars) d1[is.na(get(v)), (v) := 0]
  d1[, immig_auto := as.numeric(missing_mig)]
  mig_ctrl <- othv
  if (!is.null(flag)) mig_ctrl <- c(mig_ctrl, flag) else if (any(missing_mig)) mig_ctrl <- c(mig_ctrl, "immig_auto")
  d1[, native_ := native]
  msg("Natives: ", sum(native, na.rm = TRUE), "; migrants: ", sum(migrant, na.rm = TRUE))
} else {
  st <- grep("^immig$", H, ignore.case = TRUE, value = TRUE)
  d1[, native_ := NA]
}

ctrl_all <- c(ctrl1, mig_ctrl)
ctrl_str <- if (length(ctrl_all)) paste("+", paste(ctrl_all, collapse = " + ")) else ""

m1 <- run_feols(paste("y ~ patience", ctrl_str, "| wave"), d1, ~country)
m2 <- run_feols(paste("y ~ risktaking", ctrl_str, "| wave"), d1, ~country)
m3 <- run_feols(paste("y ~ patience + risktaking", ctrl_str, "| wave"), d1, ~country)
if (!is.null(m3)) try(print(m3), silent = TRUE)

ctrl_nat <- if (length(ctrl1)) paste("+", paste(ctrl1, collapse = " + ")) else ""
dn <- d1[native_ == TRUE]
m5 <- if (nrow(dn) > 0) run_feols(paste("y ~ patience + risktaking", ctrl_nat, "| wave"), dn, ~country) else NULL
if (!is.null(m5)) try(print(m5), silent = TRUE)
n3 <- if (!is.null(m3)) nobs(m3) else nrow(d1)
rm(d1, dn); invisible(gc())

# ===================== Table 2: migrant analysis =====================
hm <- get_header(imcoo_csv, imcoo_dta)
HM <- hm$names
msg("Migrant data header: ", paste(HM, collapse = ", "))
wcol_m <- find_weight(HM)
msg("Weight column (migrant): ", wcol_m)

pick <- function(base) {
  if (base %in% HM) return(base)
  o <- paste0(base, "_orig")
  if (o %in% HM) return(o)
  NA_character_
}
pv_pat <- pick("coo_patience"); pv_risk <- pick("coo_risktaking")
others <- c(pick("coo_posrecip"), pick("coo_negrecip"), pick("coo_altruism"), pick("coo_trust"))
others <- others[!is.na(others)]
want_m <- unique(c("pv1math", pv_pat, pv_risk, others, "coo", "country", "wave",
                   intersect(c("countrywave", "coo_oecd", "female", "imfemale", "age", "image"), HM),
                   if (!is.na(wcol_m)) wcol_m))
want_m <- want_m[!is.na(want_m) & want_m %in% HM]
d2 <- read_cols(imcoo_csv, imcoo_dta, want_m, hm$src)
msg("Migrant rows: ", nrow(d2))
d2 <- prep_outcome(d2)
setnames(d2, pv_pat, "opat"); setnames(d2, pv_risk, "orisk")
d2[, opat := num(opat)]; d2[, orisk := num(orisk)]
oth_names <- character(0)
for (i in seq_along(others)) {
  nm <- paste0("oth", i)
  setnames(d2, others[i], nm)
  d2[, (nm) := num(get(nm))]
  oth_names <- c(oth_names, nm)
}
d2 <- d2[!is.na(y) & !is.na(opat) & !is.na(orisk) & !is.na(coo)]
if (!"countrywave" %in% names(d2)) d2[, countrywave := paste(country, wave, sep = "_")]
d2 <- make_weights(d2, wcol_m, "country")
d2 <- d2[!is.na(w)]
ctrl2 <- c(fill_control(d2, "female"), fill_control(d2, "age"), fill_control(d2, "coo_oecd"))
c2 <- if (length(ctrl2)) paste("+", paste(ctrl2, collapse = " + ")) else ""
msg("Migrant analysis rows: ", nrow(d2), "; origins: ", uniqueN(d2$coo),
    "; residence-waves: ", uniqueN(d2$countrywave))

t2m1 <- run_feols(paste("y ~ opat", c2, "| countrywave"), d2, ~coo)
t2m3 <- run_feols(paste("y ~ opat + orisk", c2, "| countrywave"), d2, ~coo)
if (!is.null(t2m3)) try(print(t2m3), silent = TRUE)
d2c4 <- d2
for (nm in oth_names) d2c4 <- d2c4[!is.na(get(nm))]
t2m4 <- if (length(oth_names))
  run_feols(paste("y ~ opat + orisk +", paste(oth_names, collapse = " + "), c2, "| countrywave"), d2c4, ~coo) else NULL
n2 <- if (!is.null(t2m3)) nobs(t2m3) else nrow(d2)

fmt <- function(x) if (is.na(x)) "NA" else formatC(x, digits = 6, format = "f")
cat(paste0("RESULT:table1_col3_patience=", fmt(safe_coef(m3, "patience")), "\n"))
cat(paste0("RESULT:table1_col3_risk_taking=", fmt(safe_coef(m3, "risktaking")), "\n"))
cat(paste0("RESULT:table1_col1_patience=", fmt(safe_coef(m1, "patience")), "\n"))
cat(paste0("RESULT:table1_col2_risk_taking=", fmt(safe_coef(m2, "risktaking")), "\n"))
cat(paste0("RESULT:table1_col5_natives_patience=", fmt(safe_coef(m5, "patience")), "\n"))
cat(paste0("RESULT:table1_col5_natives_risk_taking=", fmt(safe_coef(m5, "risktaking")), "\n"))
cat(paste0("RESULT:table1_col3_observations=", n3, "\n"))
cat(paste0("RESULT:table2_col3_patience=", fmt(safe_coef(t2m3, "opat")), "\n"))
cat(paste0("RESULT:table2_col3_risk_taking=", fmt(safe_coef(t2m3, "orisk")), "\n"))
cat(paste0("RESULT:table2_col1_patience=", fmt(safe_coef(t2m1, "opat")), "\n"))
cat(paste0("RESULT:table2_col4_patience=", fmt(safe_coef(t2m4, "opat")), "\n"))
cat(paste0("RESULT:table2_col4_risk_taking=", fmt(safe_coef(t2m4, "orisk")), "\n"))
cat(paste0("RESULT:table2_col3_observations=", n2, "\n"))