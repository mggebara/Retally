suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
f <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv")
df <- suppressWarnings(readr::read_csv(f, guess_max = 100000, show_col_types = FALSE))
df <- as.data.frame(df)
n_loaded <- nrow(df)

has <- function(v) v %in% names(df)
num <- function(x) suppressWarnings(as.numeric(x))

# ---------------- party coding ----------------
p <- df$sponsor_party
if (is.character(p) && all(is.na(num(p[!is.na(p)])))) {
  pc <- toupper(substr(trimws(p), 1, 1))
  df$dem <- as.integer(pc == "D")
  df$rep <- as.integer(pc == "R")
} else {
  pn <- num(p)
  if (any(pn %in% c(100, 200))) {
    df$dem <- as.integer(pn == 100)
    df$rep <- as.integer(pn == 200)
  } else {
    # fallback: 1 = Democrat, 2 (or 0) = Republican
    df$dem <- as.integer(pn == 1)
    df$rep <- as.integer(pn %in% c(0, 2))
  }
}
df$party_f <- factor(ifelse(df$dem == 1, "D", ifelse(df$rep == 1, "R", "O")))

df$female <- num(df$sponsor_female)

# ---------------- identifiers ----------------
df$cl_id <- paste(df$v2, df$sponsor_state_abbrev, df$sponsor_district, df$sponsor_term_served, sep = "_")

# ---------------- outcomes ----------------
df$ncosp <- num(df$numb_cosponsors)
df$pctopp <- NA_real_
opp_cnt_var <- if (has("numb_cosponsors_opposite")) "numb_cosponsors_opposite" else {
  cand <- grep("^numb?_.*opp", names(df), value = TRUE, ignore.case = TRUE)
  if (length(cand) > 0) cand[1] else NA_character_
}
if (!is.na(opp_cnt_var)) {
  # paper's definition: opposite-party cosponsors / (cosponsors + 1 sponsor), in percent
  df$pctopp <- 100 * num(df[[opp_cnt_var]]) / (df$ncosp + 1)
  cat(sprintf("INFO: pct opposite built from %s / (numb_cosponsors + 1) * 100\n", opp_cnt_var))
}
if (has("pct_cosponsors_opposite")) {
  pv0 <- num(df$pct_cosponsors_opposite)
  cat(sprintf("INFO: pct_cosponsors_opposite summary: min=%.4f q50=%.4f q99=%.4f max=%.4f\n",
              min(pv0, na.rm = TRUE), median(pv0, na.rm = TRUE), quantile(pv0, 0.99, na.rm = TRUE), max(pv0, na.rm = TRUE)))
  if (quantile(pv0, 0.99, na.rm = TRUE) <= 1.0001) pv0 <- 100 * pv0
  df$pctopp[is.na(df$pctopp)] <- pv0[is.na(df$pctopp)]
}
cat(sprintf("INFO: pctopp summary: mean=%.4f q99=%.4f max=%.4f\n",
            mean(df$pctopp, na.rm = TRUE), quantile(df$pctopp, 0.99, na.rm = TRUE), max(df$pctopp, na.rm = TRUE)))

# ---------------- sample restriction: public bills ----------------
if (has("private")) {
  pv <- num(df$private)
  df <- df[is.na(pv) | pv == 0, ]
  cat(sprintf("SAMPLE:all_ols:drop_private_bills=%d\n", nrow(df)))
} else {
  cat("DEVIATION: no 'private' column; private-bill exclusion assumed already applied\n")
}

# total bills sponsored per sponsor-Congress
df <- df %>% group_by(cl_id) %>% mutate(nbills = n()) %>% ungroup() %>% as.data.frame()

# ---------------- sponsor controls ----------------
df$age <- if (has("sponsor_age")) num(df$sponsor_age) else NA
df$tenure <- if (has("sponsor_tenure_run")) num(df$sponsor_tenure_run) else NA
df$rookie <- as.integer(df$tenure == 1)
lead <- rep(0, nrow(df))
if (has("comc")) lead <- pmax(lead, as.integer(num(df$comc) > 0), na.rm = TRUE)
if (has("comr")) lead <- pmax(lead, as.integer(num(df$comr) > 0), na.rm = TRUE)
df$leader <- lead
spons_vars <- c("age", "tenure", "rookie", "leader", "nbills")
if (has("ivycoll")) { df$ivy <- num(df$ivycoll); spons_vars <- c(spons_vars, "ivy") }
if (has("black")) { df$blk <- num(df$black); spons_vars <- c(spons_vars, "blk") }
if (has("borninstate")) { df$bis <- num(df$borninstate); spons_vars <- c(spons_vars, "bis") }
occs <- grep("^occ[0-9]+$", names(df), value = TRUE)
if (length(occs) > 1) {
  occs_use <- setdiff(occs, "occ0")
  if (length(occs_use) > 5) occs_use <- occs_use[1:5]
  for (o in occs_use) df[[o]] <- num(df[[o]])
  spons_vars <- c(spons_vars, occs_use)
}

# ---------------- district controls ----------------
dist_vars <- c()
st <- if (has("sponsor_state_icpsr")) num(df$sponsor_state_icpsr) else NA
df$region <- ifelse(st <= 14, "NE", ifelse(st <= 37, "MW", ifelse(st <= 56, "S", "W")))
df$reg_mw <- as.integer(df$region == "MW")
df$reg_s <- as.integer(df$region == "S")
df$reg_w <- as.integer(df$region == "W")
if (any(!is.na(st))) dist_vars <- c(dist_vars, "reg_mw", "reg_s", "reg_w")
for (v in c("pct_black", "pct_urban", "pct_for_born")) if (has(v)) { df[[v]] <- num(df[[v]]); dist_vars <- c(dist_vars, v) }
v65 <- grep("65", names(df), value = TRUE)
v65 <- v65[grepl("pct|over|old|age", v65, ignore.case = TRUE)]
if (length(v65) > 0) { df$pct65 <- num(df[[v65[1]]]); dist_vars <- c(dist_vars, "pct65") }
vinc <- grep("income", names(df), value = TRUE, ignore.case = TRUE)
if (length(vinc) > 0) {
  x <- num(df[[vinc[1]]])
  df$linc <- if (grepl("^l|log", vinc[1])) x else log(pmax(x, 1e-6))
  dist_vars <- c(dist_vars, "linc")
}
vden <- grep("popdens|density", names(df), value = TRUE, ignore.case = TRUE)
if (length(vden) > 0) {
  x <- num(df[[vden[1]]])
  df$ldens <- if (grepl("^l|log", vden[1])) x else log(pmax(x, 1e-6))
  dist_vars <- c(dist_vars, "ldens")
}
cat(sprintf("INFO: sponsor controls: %s\n", paste(spons_vars, collapse = ",")))
cat(sprintf("INFO: district controls: %s\n", paste(dist_vars, collapse = ",")))

# ---------------- bill controls ----------------
comm <- grep("^house_", names(df), value = TRUE)
comm <- comm[!grepl("_m$", comm)]
comm_ok <- c()
for (cc in comm) {
  x <- num(df[[cc]])
  if (all(x[!is.na(x)] %in% c(0, 1)) && length(unique(x[!is.na(x)])) == 2) {
    df[[cc]] <- ifelse(is.na(x), 0, x)
    comm_ok <- c(comm_ok, cc)
  }
}
df$minor_f <- factor(df$minor)
df$v2_f <- factor(df$v2)

safe_coef <- function(m, v = "female") {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

ols_fit <- function(d, y, pooled = FALSE) {
  rhs <- c("female", comm_ok, spons_vars, dist_vars)
  if (pooled) rhs <- c(rhs, "party_f")
  fml <- as.formula(paste(y, "~", paste(rhs, collapse = " + "), "| v2_f + minor_f"))
  feols(fml, data = d, cluster = ~cl_id, warn = FALSE, notes = FALSE)
}

res <- list()

# ================= OLS (column 1) =================
d_all <- df
cat(sprintf("SAMPLE:all_ols:loaded=%d\n", n_loaded))
m_all_n <- tryCatch(ols_fit(d_all, "ncosp", pooled = TRUE), error = function(e) { cat("ERR", conditionMessage(e), "\n"); NULL })
if (!is.null(m_all_n)) {
  cat(sprintf("SAMPLE:all_ols:estimation=%d\n", nobs(m_all_n)))
  res$female_sponsor_ncosponsors_all_ols <- safe_coef(m_all_n)
  res$n_bills_ncosponsors_all_ols <- nobs(m_all_n)
  obs_idx <- obs(m_all_n)
  res$n_sponsor_terms_ncosponsors_all_ols <- length(unique(d_all$cl_id[obs_idx]))
}

d_rep <- df[df$rep %in% 1, ]
d_dem <- df[df$dem %in% 1, ]
cat(sprintf("SAMPLE:rep_ols:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:rep_ols:republican_sponsor=%d\n", nrow(d_rep)))
m_rep_n <- tryCatch(ols_fit(d_rep, "ncosp"), error = function(e) NULL)
if (!is.null(m_rep_n)) {
  cat(sprintf("SAMPLE:rep_ols:estimation=%d\n", nobs(m_rep_n)))
  res$female_sponsor_ncosponsors_rep_ols <- safe_coef(m_rep_n)
}
cat(sprintf("SAMPLE:dem_ols_pct:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:dem_ols_pct:democratic_sponsor=%d\n", nrow(d_dem)))
m_dem_p <- tryCatch(ols_fit(d_dem, "pctopp"), error = function(e) NULL)
if (!is.null(m_dem_p)) {
  cat(sprintf("SAMPLE:dem_ols_pct:estimation=%d\n", nobs(m_dem_p)))
  res$female_sponsor_pct_opposite_dem_ols <- safe_coef(m_dem_p)
  res$n_bills_pct_opposite_dem_ols <- nobs(m_dem_p)
}
cat(sprintf("SAMPLE:rep_ols_pct:loaded=%d\n", n_loaded))
cat(sprintf("SAMPLE:rep_ols_pct:republican_sponsor=%d\n", nrow(d_rep)))
m_rep_p <- tryCatch(ols_fit(d_rep, "pctopp"), error = function(e) NULL)
if (!is.null(m_rep_p)) {
  cat(sprintf("SAMPLE:rep_ols_pct:estimation=%d\n", nobs(m_rep_p)))
  res$female_sponsor_pct_opposite_rep_ols <- safe_coef(m_rep_p)
  res$n_bills_pct_opposite_rep_ols <- nobs(m_rep_p)
}

# ================= Propensity-score weighting (columns 4-5) =================
if (has("MV1_democrat")) {
  mvd <- num(df$MV1_democrat)
  df$mv_elected <- abs(mvd)
} else if (has("MV1_female")) {
  df$mv_elected <- abs(num(df$MV1_female))
} else df$mv_elected <- NA
if (has("lag_demshare1")) df$lag_demshare1 <- num(df$lag_demshare1)

ps_weights <- function(d, xvars) {
  sp <- d %>% group_by(cl_id) %>% summarise(across(all_of(c("female", xvars)), ~ mean(.x, na.rm = TRUE)), .groups = "drop") %>% as.data.frame()
  for (v in names(sp)) if (is.numeric(sp[[v]])) sp[[v]][is.nan(sp[[v]])] <- NA
  keep <- xvars[sapply(xvars, function(v) sum(!is.na(sp[[v]])) > 0 && sd(sp[[v]], na.rm = TRUE) > 0)]
  fml <- as.formula(paste("female ~", paste(keep, collapse = " + ")))
  g <- glm(fml, data = sp, family = binomial())
  sp$ps <- predict(g, newdata = sp, type = "response")
  sp$ps <- pmin(pmax(sp$ps, 0.01), 0.99)
  sp$w <- ifelse(sp$female == 1, 1 / sp$ps, 1 / (1 - sp$ps))
  d$w <- sp$w[match(d$cl_id, sp$cl_id)]
  d
}

ipw_fit <- function(d, y) {
  rhs <- c("female", comm_ok)
  fml <- as.formula(paste(y, "~", paste(rhs, collapse = " + "), "| v2_f + minor_f"))
  feols(fml, data = d[!is.na(d$w), ], weights = ~w, cluster = ~cl_id, warn = FALSE, notes = FALSE)
}

xd <- c(dist_vars, "mv_elected")
xs <- c(xd, spons_vars)

d_rep_raw <- df[df$rep %in% 1, ]
d_dem_raw <- df[df$dem %in% 1, ]

# Rep, ncosp, col 5 (district + MV + sponsor)
tryCatch({
  d <- ps_weights(d_rep_raw, xs)
  m <- ipw_fit(d, "ncosp")
  cat(sprintf("SAMPLE:rep_ipw_sponsor_ncosp:loaded=%d\n", n_loaded))
  cat(sprintf("SAMPLE:rep_ipw_sponsor_ncosp:republican_sponsor=%d\n", nrow(d_rep_raw)))
  cat(sprintf("SAMPLE:rep_ipw_sponsor_ncosp:estimation=%d\n", nobs(m)))
  res$female_sponsor_ncosponsors_rep_ipw_sponsor <- safe_coef(m)
}, error = function(e) cat("ERR rep ipw sponsor:", conditionMessage(e), "\n"))

# Dem, pct, col 5
tryCatch({
  d <- ps_weights(d_dem_raw, xs)
  m <- ipw_fit(d, "pctopp")
  cat(sprintf("SAMPLE:dem_ipw_sponsor_pct:loaded=%d\n", n_loaded))
  cat(sprintf("SAMPLE:dem_ipw_sponsor_pct:democratic_sponsor=%d\n", nrow(d_dem_raw)))
  cat(sprintf("SAMPLE:dem_ipw_sponsor_pct:estimation=%d\n", nobs(m)))
  res$female_sponsor_pct_opposite_dem_ipw_sponsor <- safe_coef(m)
}, error = function(e) cat("ERR dem ipw sponsor:", conditionMessage(e), "\n"))

# Rep, pct, col 4 (district + MV)
tryCatch({
  d <- ps_weights(d_rep_raw, xd)
  m <- ipw_fit(d, "pctopp")
  cat(sprintf("SAMPLE:rep_ipw_district_pct:loaded=%d\n", n_loaded))
  cat(sprintf("SAMPLE:rep_ipw_district_pct:republican_sponsor=%d\n", nrow(d_rep_raw)))
  cat(sprintf("SAMPLE:rep_ipw_district_pct:estimation=%d\n", nobs(m)))
  res$female_sponsor_pct_opposite_rep_ipw_district <- safe_coef(m)
}, error = function(e) cat("ERR rep ipw district:", conditionMessage(e), "\n"))

# ================= Regression discontinuity (columns 2-3) =================
df$mvf <- if (has("MV1_female")) num(df$MV1_female) else NA
mv_scale <- if (max(abs(df$mvf), na.rm = TRUE) <= 1.0001) 0.01 else 1
mge <- if (has("mixed_gender_election")) num(df$mixed_gender_election) else NA

rd_sample <- function(d, h_pp) {
  h <- h_pp * mv_scale
  d <- d[!is.na(d$mixed == 1) & d$mixed == 1 & !is.na(d$mvf), ]
  n_mixed <- nrow(d)
  d <- d[abs(d$mvf) <= h, ]
  d$fxmv <- d$female * d$mvf
  list(d = d, n_mixed = n_mixed)
}
df$mixed <- mge

# info: CCT bandwidths at bill level
cct_bw <- function(d, y) {
  dd <- d[!is.na(d$mixed) & d$mixed == 1 & !is.na(d$mvf) & !is.na(d[[y]]), ]
  out <- tryCatch({
    b <- rdrobust::rdbwselect(y = dd[[y]], x = dd$mvf, c = 0, p = 1, bwselect = "mserd")
    b$bws[1, 1] / mv_scale
  }, error = function(e) NA_real_)
  out
}

# Dem, pct, col 2 (RD, bandwidth 24 pp, no controls, no weights)
tryCatch({
  bw_c <- cct_bw(df[df$dem %in% 1, ], "pctopp")
  cat(sprintf("INFO: CCT bandwidth (dem pct, pp) = %.2f; paper reports 24\n", bw_c))
  s <- rd_sample(df[df$dem %in% 1, ], 24)
  d <- s$d
  cat(sprintf("SAMPLE:dem_rd_pct:loaded=%d\n", n_loaded))
  cat(sprintf("SAMPLE:dem_rd_pct:democratic_sponsor=%d\n", sum(df$dem %in% 1)))
  cat(sprintf("SAMPLE:dem_rd_pct:mixed_gender_election=%d\n", s$n_mixed))
  cat(sprintf("SAMPLE:dem_rd_pct:within_bandwidth=%d\n", nrow(d)))
  m <- feols(pctopp ~ female + mvf + fxmv | v2_f, data = d, cluster = ~cl_id, warn = FALSE, notes = FALSE)
  cat(sprintf("SAMPLE:dem_rd_pct:estimation=%d\n", nobs(m)))
  res$female_sponsor_pct_opposite_dem_rd <- safe_coef(m)
}, error = function(e) cat("ERR dem rd:", conditionMessage(e), "\n"))

# Rep, ncosp, col 3 (RD bandwidth 13 pp, bill controls, IPW)
tryCatch({
  bw_c <- cct_bw(df[df$rep %in% 1, ], "ncosp")
  cat(sprintf("INFO: CCT bandwidth (rep ncosp, pp) = %.2f; paper reports 13\n", bw_c))
  s <- rd_sample(df[df$rep %in% 1, ], 13)
  d <- s$d
  cat(sprintf("SAMPLE:rep_rd_ipw_ncosp:loaded=%d\n", n_loaded))
  cat(sprintf("SAMPLE:rep_rd_ipw_ncosp:republican_sponsor=%d\n", sum(df$rep %in% 1)))
  cat(sprintf("SAMPLE:rep_rd_ipw_ncosp:mixed_gender_election=%d\n", s$n_mixed))
  cat(sprintf("SAMPLE:rep_rd_ipw_ncosp:within_bandwidth=%d\n", nrow(d)))
  d <- ps_weights(d, dist_vars)
  rhs <- c("female", "mvf", "fxmv", comm_ok)
  fml <- as.formula(paste("ncosp ~", paste(rhs, collapse = " + "), "| v2_f + minor_f"))
  m <- feols(fml, data = d[!is.na(d$w), ], weights = ~w, cluster = ~cl_id, warn = FALSE, notes = FALSE)
  cat(sprintf("SAMPLE:rep_rd_ipw_ncosp:estimation=%d\n", nobs(m)))
  res$female_sponsor_ncosponsors_rep_rd_ipw <- safe_coef(m)
}, error = function(e) cat("ERR rep rd ipw:", conditionMessage(e), "\n"))

# ================= Output =================
order_names <- c(
  "female_sponsor_ncosponsors_all_ols",
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
  "n_bills_pct_opposite_rep_ols"
)
for (nm in order_names) {
  v <- res[[nm]]
  if (!is.null(v) && !is.na(v)) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
}