suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
fcsv <- file.path(root, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv")
fdta <- file.path(root, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")

df <- tryCatch(as.data.frame(readr::read_csv(fcsv, guess_max = 100000, show_col_types = FALSE)),
               error = function(e) NULL)
if (is.null(df)) {
  df <- as.data.frame(haven::zap_labels(haven::read_dta(fdta)))
}
message("Loaded ", nrow(df), " rows, ", ncol(df), " cols")
nm <- names(df)

res <- list()
put <- function(name, val) { res[[name]] <<- val }

numify <- function(x) {
  if (is.numeric(x)) return(x)
  if (is.logical(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}

# ---------------- Sample: public bills ----------------
if ("private" %in% nm) {
  pv <- numify(df$private)
  df <- df[is.na(pv) | pv == 0, ]
}
message("Public bills: ", nrow(df))

# ---------------- Core variables ----------------
df$female <- numify(df$sponsor_female)
df$congress <- df$v2

# party
pr <- df$sponsor_party
if (is.numeric(pr)) {
  if (any(pr %in% c(100, 200), na.rm = TRUE)) {
    df$dem <- as.numeric(pr == 100); df$rep <- as.numeric(pr == 200)
  } else {
    # fallback: assume 1 = Republican
    df$rep <- as.numeric(pr == 1); df$dem <- as.numeric(pr == 0)
  }
} else {
  p1 <- toupper(substr(trimws(as.character(pr)), 1, 1))
  df$dem <- as.numeric(p1 == "D"); df$rep <- as.numeric(p1 == "R")
}
message("Dem bills: ", sum(df$dem == 1, na.rm = TRUE), "  Rep bills: ", sum(df$rep == 1, na.rm = TRUE))

# sponsor-Congress cluster
idparts <- intersect(c("sponsor_name", "sponsor_state_abbrev", "sponsor_district", "v2"), nm)
df$cl <- do.call(paste, c(lapply(idparts, function(v) as.character(df[[v]])), sep = "_"))

# outcomes
df$ncosp <- numify(df$numb_cosponsors)
if ("pct_cosponsors_opposite" %in% nm) {
  df$pctopp <- numify(df$pct_cosponsors_opposite)
} else {
  df$pctopp <- numify(df$numb_cosponsors_opposite) / (df$ncosp + 1) * 100
}
if (max(df$pctopp, na.rm = TRUE) <= 1.0001) df$pctopp <- df$pctopp * 100

# ---------------- Bill controls ----------------
df$minor_f <- df$minor
comm <- grep("^house_", nm, value = TRUE)
comm <- comm[sapply(comm, function(v) {
  x <- numify(df[[v]]); u <- unique(x[!is.na(x)])
  length(u) >= 2 && all(u %in% c(0, 1))
})]
for (v in comm) df[[v]] <- numify(df[[v]])
message("Committee dummies: ", length(comm))

okcov <- function(v, thr = 0.8) {
  v %in% names(df) && mean(!is.na(numify(df[[v]]))) >= thr && length(unique(na.omit(numify(df[[v]])))) > 1
}

# ---------------- Sponsor controls ----------------
df$nbills_sp <- ave(rep(1, nrow(df)), df$cl, FUN = sum)
if (!("rookie" %in% nm) && "sponsor_tenure_run" %in% nm) {
  df$rookie <- as.numeric(numify(df$sponsor_tenure_run) <= 1)
}
if (all(c("comc", "comr") %in% nm)) {
  df$leader <- pmax(numify(df$comc), numify(df$comr), na.rm = TRUE)
} else if ("leadcomm" %in% nm) {
  df$leader <- numify(df$leadcomm)
}
occ <- grep("^occ[0-9]+$", nm, value = TRUE)
born <- grep("born.*state|borninstate", nm, value = TRUE)
spcand <- unique(c("sponsor_age", "sponsor_tenure_run", "rookie", "leader", "black",
                   "ivycoll", born, occ, "nbills_sp"))
spc <- spcand[sapply(spcand, okcov)]
if (length(occ) > 0) { # drop one occupation as base
  occin <- intersect(occ, spc)
  if (length(occin) > 1) spc <- setdiff(spc, occin[1])
}
for (v in spc) df[[v]] <- numify(df[[v]])
message("Sponsor controls: ", paste(spc, collapse = ", "))

# ---------------- District controls ----------------
dc <- c()
for (v in c("pct_black", "pct_urban", "pct_for_born")) if (okcov(v)) dc <- c(dc, v)
o65 <- grep("65", nm, value = TRUE); o65 <- o65[grepl("pct|over|age", o65, ignore.case = TRUE)]
o65 <- o65[!grepl("cosp", o65)]
if (length(o65) > 0 && okcov(o65[1])) dc <- c(dc, o65[1])
inc <- grep("inc", nm, value = TRUE, ignore.case = TRUE)
inc <- inc[grepl("med", inc, ignore.case = TRUE)]
if (length(inc) > 0 && okcov(inc[1])) {
  x <- numify(df[[inc[1]]])
  if (max(x, na.rm = TRUE) > 50) { df$ln_medinc <- log(x); dc <- c(dc, "ln_medinc") } else dc <- c(dc, inc[1])
}
dens <- grep("dens", nm, value = TRUE, ignore.case = TRUE)
if (length(dens) > 0 && okcov(dens[1])) {
  x <- numify(df[[dens[1]]])
  if (!grepl("^(ln|log)", dens[1]) && min(x, na.rm = TRUE) >= 0 && max(x, na.rm = TRUE) > 50) {
    df$ln_dens <- log(pmax(x, 1e-6)); dc <- c(dc, "ln_dens")
  } else dc <- c(dc, dens[1])
}
reg <- grep("^(region|northeast|midwest|south|west|north_east|mid_west)", nm, value = TRUE, ignore.case = TRUE)
reg <- reg[sapply(reg, okcov)]
if (length(reg) == 1 && length(unique(na.omit(df[[reg]]))) > 2) {
  df$region_f <- factor(df[[reg]])
  rd <- model.matrix(~ region_f, data = df, na.action = na.pass)[, -1, drop = FALSE]
  for (j in seq_len(ncol(rd))) { df[[paste0("regd", j)]] <- rd[, j]; dc <- c(dc, paste0("regd", j)) }
} else if (length(reg) >= 1) {
  regin <- reg
  if (length(regin) >= 4) regin <- regin[1:3]
  dc <- c(dc, regin)
}
for (v in dc) df[[v]] <- numify(df[[v]])
message("District controls: ", paste(dc, collapse = ", "))

bq <- function(v) paste0("`", v, "`")
billpart <- if (length(comm)) paste(bq(comm), collapse = " + ") else NULL

# ---------------- OLS full spec (col 1) ----------------
run_ols <- function(y, sub, pooled) {
  d <- df[sub, ]
  rhs <- c("female", if (pooled) "rep", billpart, bq(spc), bq(dc))
  f <- as.formula(paste(y, "~", paste(rhs, collapse = " + "), "| congress + minor_f"))
  feols(f, data = d, cluster = ~cl)
}
getn <- function(m, d) {
  obs <- obs(m)
  list(n = nobs(m), ncl = length(unique(d$cl[obs])))
}

allsub <- !is.na(df$female) & (df$dem == 1 | df$rep == 1)
demsub <- !is.na(df$female) & df$dem == 1
repsub <- !is.na(df$female) & df$rep == 1

tryCatch({
  m <- run_ols("ncosp", allsub, TRUE)
  put("female_sponsor_ncosponsors_all_ols", coef(m)["female"])
  d <- df[allsub, ]
  put("n_bills_ncosponsors_all_ols", nobs(m))
  put("n_sponsor_terms_ncosponsors_all_ols", length(unique(d$cl[obs(m)])))
}, error = function(e) message("all ols: ", conditionMessage(e)))

tryCatch({
  m <- run_ols("ncosp", repsub, FALSE)
  put("female_sponsor_ncosponsors_rep_ols", coef(m)["female"])
}, error = function(e) message("rep ols: ", conditionMessage(e)))

tryCatch({
  m <- run_ols("pctopp", demsub, FALSE)
  put("female_sponsor_pct_opposite_dem_ols", coef(m)["female"])
  put("n_bills_pct_opposite_dem_ols", nobs(m))
}, error = function(e) message("dem pct ols: ", conditionMessage(e)))

tryCatch({
  m <- run_ols("pctopp", repsub, FALSE)
  put("female_sponsor_pct_opposite_rep_ols", coef(m)["female"])
  put("n_bills_pct_opposite_rep_ols", nobs(m))
}, error = function(e) message("rep pct ols: ", conditionMessage(e)))

# ---------------- Propensity scores ----------------
if ("MV1_democrat" %in% nm) {
  df$mv_elected <- abs(numify(df$MV1_democrat))
} else {
  df$mv_elected <- abs(numify(df$MV1_female))
}

ipw <- function(sub, covs) {
  d <- df[sub, ]
  f <- as.formula(paste("female ~", paste(c(bq(covs), "factor(congress)"), collapse = " + ")))
  g <- suppressWarnings(glm(f, data = d, family = binomial(), na.action = na.exclude))
  p <- as.numeric(predict(g, newdata = d, type = "response"))
  p <- pmin(pmax(p, 1e-6), 1 - 1e-6)
  w <- ifelse(d$female == 1, 1 / p, 1 / (1 - p))
  out <- rep(NA_real_, nrow(df)); out[which(sub)] <- w
  out
}

run_wls <- function(y, sub, w) {
  d <- df[sub, ]; d$w <- w[sub]
  d <- d[!is.na(d$w), ]
  rhs <- c("female", billpart)
  f <- as.formula(paste(y, "~", paste(rhs, collapse = " + "), "| congress + minor_f"))
  feols(f, data = d, weights = ~w, cluster = ~cl)
}

tryCatch({
  w <- ipw(repsub, c(dc, "mv_elected", spc))
  m <- run_wls("ncosp", repsub, w)
  put("female_sponsor_ncosponsors_rep_ipw_sponsor", coef(m)["female"])
}, error = function(e) message("rep ipw sponsor: ", conditionMessage(e)))

tryCatch({
  w <- ipw(demsub, c(dc, "mv_elected", spc))
  m <- run_wls("pctopp", demsub, w)
  put("female_sponsor_pct_opposite_dem_ipw_sponsor", coef(m)["female"])
}, error = function(e) message("dem ipw sponsor: ", conditionMessage(e)))

tryCatch({
  w <- ipw(repsub, c(dc, "mv_elected"))
  m <- run_wls("pctopp", repsub, w)
  put("female_sponsor_pct_opposite_rep_ipw_district", coef(m)["female"])
}, error = function(e) message("rep ipw district: ", conditionMessage(e)))

# ---------------- RD ----------------
df$mv <- numify(df$MV1_female)
mvscale <- if (max(abs(df$mv), na.rm = TRUE) > 1.5) 1 else 0.01
df$fXmv <- df$female * df$mv
mixed <- numify(df$mixed_gender_election) == 1 & !is.na(df$mv) & !is.na(df$female)
mixed[is.na(mixed)] <- FALSE

tryCatch({
  h <- 24 * mvscale
  sub <- mixed & df$dem == 1 & abs(df$mv) < h
  sub[is.na(sub)] <- FALSE
  d <- df[sub, ]
  m <- feols(pctopp ~ female + mv + fXmv | congress, data = d, cluster = ~cl)
  put("female_sponsor_pct_opposite_dem_rd", coef(m)["female"])
}, error = function(e) message("dem rd: ", conditionMessage(e)))

tryCatch({
  h <- 13 * mvscale
  base <- mixed & df$rep == 1
  base[is.na(base)] <- FALSE
  w <- ipw(base, dc)
  sub <- base & abs(df$mv) < h
  d <- df[sub, ]; d$w <- w[sub]; d <- d[!is.na(d$w), ]
  rhs <- c("female", "mv", "fXmv", billpart)
  f <- as.formula(paste("ncosp ~", paste(rhs, collapse = " + "), "| congress + minor_f"))
  m <- feols(f, data = d, weights = ~w, cluster = ~cl)
  put("female_sponsor_ncosponsors_rep_rd_ipw", coef(m)["female"])
}, error = function(e) message("rep rd ipw: ", conditionMessage(e)))

# ---------------- Output ----------------
names_out <- c("female_sponsor_ncosponsors_all_ols",
               "female_sponsor_ncosponsors_rep_ols",
               "female_sponsor_ncosponsors_rep_rd_ipw",
               "female_sponsor_ncosponsors_rep_ipw_sponsor",
               "female_sponsor_pct_opposite_dem_ols",
               "female_sponsor_pct_opposite_dem_rd",
               "female_sponsor_pct_opposite_dem_ipw_sponsor",
               "female_sponsor_pct_opposite_rep_ols",
               "female_sponsor_pct_opposite_rep_ipw_district",
               "n_bills_ncosponsors_all_ols",
               "n_sponsor_terms_ncosponsors_all_ols",
               "n_bills_pct_opposite_dem_ols",
               "n_bills_pct_opposite_rep_ols")
for (n in names_out) {
  v <- if (is.null(res[[n]])) NA else as.numeric(res[[n]])
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 10)))
}