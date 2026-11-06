suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
f <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv")
df <- read_csv(f, guess_max = 100000, show_col_types = FALSE)
df <- as.data.frame(df)
nm <- names(df)

num <- function(x) suppressWarnings(as.numeric(x))
has <- function(v) v %in% names(df)

# ---------- basic variables ----------
df$sponsor_female <- num(df$sponsor_female)
df$v2 <- num(df$v2)
df$cl_id <- paste(df$v2, df$sponsor_state_abbrev, df$sponsor_district, df$sponsor_term_served, sep = "_")

pv <- df$sponsor_party
if (is.numeric(pv)) {
  df$is_dem <- as.integer(pv == 100)
  df$is_rep <- as.integer(pv == 200)
} else {
  pvc <- toupper(trimws(as.character(pv)))
  df$is_dem <- as.integer(grepl("^D|^100$", pvc))
  df$is_rep <- as.integer(grepl("^R|^200$", pvc))
}

df$numb_cosponsors <- num(df$numb_cosponsors)
df$pct_cosponsors_opposite <- num(df$pct_cosponsors_opposite)
if (max(df$pct_cosponsors_opposite, na.rm = TRUE) <= 1.0001) {
  df$pct_cosponsors_opposite <- 100 * df$pct_cosponsors_opposite
}

# ---------- sample: public bills ----------
cat(sprintf("SAMPLE:base:loaded=%d\n", nrow(df)))
if (has("private")) {
  pr <- num(df$private)
  df <- df[is.na(pr) | pr == 0, ]
}
cat(sprintf("SAMPLE:base:public_bills=%d\n", nrow(df)))

# ---------- bill characteristics ----------
comm_vars <- grep("^house_", names(df), value = TRUE)
for (v in comm_vars) df[[v]] <- num(df[[v]])
comm_vars <- comm_vars[sapply(comm_vars, function(v) { x <- df[[v]]; sum(!is.na(x)) > 0 && length(unique(x[!is.na(x)])) > 1 })]
df$minor_f <- as.character(df$minor)

# ---------- sponsor characteristics ----------
df$sponsor_age <- num(df$sponsor_age)
df$sponsor_tenure_run <- num(df$sponsor_tenure_run)
if (has("rookie")) {
  df$rookie_d <- num(df$rookie)
} else {
  df$rookie_d <- as.integer(df$sponsor_tenure_run == 1)
}
lc <- rep(0, nrow(df))
for (v in intersect(c("comc", "comr"), names(df))) {
  x <- num(df[[v]]); x[is.na(x)] <- 0; lc <- pmax(lc, as.numeric(x > 0))
}
df$leader_d <- lc
df$nbills_spons <- ave(rep(1, nrow(df)), df$cl_id, FUN = sum)
occ_vars <- grep("^occ[0-9]+$", names(df), value = TRUE)
for (v in occ_vars) df[[v]] <- num(df[[v]])
occ_vars <- occ_vars[sapply(occ_vars, function(v) { x <- df[[v]]; length(unique(x[!is.na(x)])) > 1 })]
if (length(occ_vars) > 1) occ_vars <- occ_vars[-1]
indiv_extra <- intersect(c("ivycoll", "black", "borninstate"), names(df))
for (v in indiv_extra) df[[v]] <- num(df[[v]])
indiv_vars <- c("sponsor_age", "sponsor_tenure_run", "rookie_d", "leader_d", indiv_extra, occ_vars, "nbills_spons")

# ---------- district characteristics ----------
dist_vars <- c()
for (v in intersect(c("pct_black", "pct_urban", "pct_for_born"), names(df))) {
  df[[v]] <- num(df[[v]]); dist_vars <- c(dist_vars, v)
}
p65 <- grep("65", names(df), value = TRUE)
p65 <- p65[grepl("pct|perc|share|over|age", p65, ignore.case = TRUE)]
if (length(p65) > 0) { df$pct65_d <- num(df[[p65[1]]]); dist_vars <- c(dist_vars, "pct65_d") }
inc <- grep("income|medinc|inc_med", names(df), value = TRUE, ignore.case = TRUE)
if (length(inc) > 0) {
  x <- num(df[[inc[1]]])
  df$lninc_d <- if (grepl("^ln|^log|_ln|_log", inc[1], ignore.case = TRUE) || max(x, na.rm = TRUE) < 30) x else log(ifelse(x > 0, x, NA))
  dist_vars <- c(dist_vars, "lninc_d")
}
dens <- grep("dens", names(df), value = TRUE, ignore.case = TRUE)
if (length(dens) > 0) {
  x <- num(df[[dens[1]]])
  df$lndens_d <- if (grepl("^ln|^log|_ln|_log", dens[1], ignore.case = TRUE)) x else log(ifelse(x > 0, x, NA))
  dist_vars <- c(dist_vars, "lndens_d")
}
reg <- grep("region|^south|^west|^northeast|^midwest|^north_east|^mid_west", names(df), value = TRUE, ignore.case = TRUE)
region_terms <- c()
if (length(reg) == 1) {
  df$region_f <- as.character(df[[reg]])
  region_terms <- "factor(region_f)"
} else if (length(reg) > 1) {
  for (v in reg) df[[v]] <- num(df[[v]])
  region_terms <- reg
}
dist_vars <- c(dist_vars, region_terms)

# margin of victory variables
df$MV1_female <- num(df$MV1_female)
if (max(abs(df$MV1_female), na.rm = TRUE) <= 1.0001) {
  mvscale <- 0.01
} else {
  mvscale <- 1
}
if (has("MV1_democrat")) df$mv_elected <- abs(num(df$MV1_democrat)) else df$mv_elected <- NA
df$mixed <- num(df$mixed_gender_election)

# ---------- helpers ----------
bill_x <- comm_vars
build_fml <- function(y, xs, fe) {
  rhs <- paste(c("sponsor_female", xs), collapse = " + ")
  as.formula(paste(y, "~", rhs, "|", paste(fe, collapse = " + ")))
}
nclus <- function(m, d) length(unique(d$cl_id[obs(m)]))

party_sub <- function(d, p) {
  if (p == "all") d else if (p == "dem") d[d$is_dem == 1, ] else d[d$is_rep == 1, ]
}

ols_full <- function(y, p, name) {
  d <- party_sub(df, p)
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, nrow(df)))
  cat(sprintf("SAMPLE:%s:public_bills=%d\n", name, nrow(df)))
  if (p != "all") cat(sprintf("SAMPLE:%s:party_%s=%d\n", name, p, nrow(d)))
  xs <- c(bill_x, indiv_vars, dist_vars)
  if (p == "all") xs <- c(xs, "is_rep")
  m <- feols(build_fml(y, xs, c("v2", "minor_f")), data = d, cluster = ~cl_id)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(m)))
  list(m = m, d = d)
}

# ---------- propensity scores ----------
all.vars_safe <- function(t) all.vars(as.formula(paste("~", t)))

compute_ps <- function(d, covs) {
  vars <- unique(unlist(lapply(covs, all.vars_safe)))
  sp <- d[!duplicated(d$cl_id), unique(c("cl_id", "sponsor_female", "v2", intersect(vars, names(d)))), drop = FALSE]
  fml <- as.formula(paste("sponsor_female ~", paste(c(covs, "factor(v2)"), collapse = " + ")))
  g <- suppressWarnings(glm(fml, data = sp, family = binomial()))
  pr <- predict(g, newdata = sp, type = "response")
  sp$ps <- pr
  sp$ipw <- ifelse(sp$sponsor_female == 1, 1 / sp$ps, 1 / (1 - sp$ps))
  w <- sp$ipw[match(d$cl_id, sp$cl_id)]
  w
}

ipw_full <- function(y, p, name, with_sponsor) {
  d <- party_sub(df, p)
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, nrow(df)))
  cat(sprintf("SAMPLE:%s:public_bills=%d\n", name, nrow(df)))
  if (p != "all") cat(sprintf("SAMPLE:%s:party_%s=%d\n", name, p, nrow(d)))
  covs <- c(dist_vars, "mv_elected")
  if (with_sponsor) covs <- c(covs, setdiff(indiv_vars, "nbills_spons"))
  d$ipw <- compute_ps(d, covs)
  d <- d[!is.na(d$ipw) & is.finite(d$ipw), ]
  cat(sprintf("SAMPLE:%s:propensity_score_available=%d\n", name, nrow(d)))
  m <- feols(build_fml(y, bill_x, c("v2", "minor_f")), data = d, weights = ~ipw, cluster = ~cl_id)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(m)))
  m
}

rd_est <- function(y, p, name, bw, ipw) {
  d <- party_sub(df, p)
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, nrow(df)))
  cat(sprintf("SAMPLE:%s:public_bills=%d\n", name, nrow(df)))
  if (p != "all") cat(sprintf("SAMPLE:%s:party_%s=%d\n", name, p, nrow(d)))
  d <- d[!is.na(d$mixed) & d$mixed == 1 & !is.na(d$MV1_female), ]
  cat(sprintf("SAMPLE:%s:mixed_gender_election=%d\n", name, nrow(d)))
  h <- bw * mvscale
  d <- d[abs(d$MV1_female) <= h, ]
  cat(sprintf("SAMPLE:%s:within_bandwidth=%d\n", name, nrow(d)))
  d$mv <- d$MV1_female
  d$fem_mv <- d$sponsor_female * d$mv
  if (ipw) {
    d$ipw <- compute_ps(d, dist_vars)
    d <- d[!is.na(d$ipw) & is.finite(d$ipw), ]
    cat(sprintf("SAMPLE:%s:propensity_score_available=%d\n", name, nrow(d)))
    m <- feols(build_fml(y, c("mv", "fem_mv", bill_x), c("v2", "minor_f")), data = d, weights = ~ipw, cluster = ~cl_id)
  } else {
    m <- feols(build_fml(y, c("mv", "fem_mv"), "v2"), data = d, cluster = ~cl_id)
  }
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(m)))
  m
}

cf <- function(m) unname(coef(m)["sponsor_female"])

# ---------- estimates ----------
r1 <- ols_full("numb_cosponsors", "all", "ncosp_all_ols")
r2 <- ols_full("numb_cosponsors", "rep", "ncosp_rep_ols")
m3 <- rd_est("numb_cosponsors", "rep", "ncosp_rep_rd_ipw", 13, TRUE)
m4 <- ipw_full("numb_cosponsors", "rep", "ncosp_rep_ipw_sponsor", TRUE)
r5 <- ols_full("pct_cosponsors_opposite", "dem", "pctopp_dem_ols")
m6 <- rd_est("pct_cosponsors_opposite", "dem", "pctopp_dem_rd", 24, FALSE)
m7 <- ipw_full("pct_cosponsors_opposite", "dem", "pctopp_dem_ipw_sponsor", TRUE)
r8 <- ols_full("pct_cosponsors_opposite", "rep", "pctopp_rep_ols")
m9 <- ipw_full("pct_cosponsors_opposite", "rep", "pctopp_rep_ipw_district", FALSE)

cat(sprintf("RESULT:female_sponsor_ncosponsors_all_ols=%.6f\n", cf(r1$m)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ols=%.6f\n", cf(r2$m)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%.6f\n", cf(m3)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%.6f\n", cf(m4)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ols=%.6f\n", cf(r5$m)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_rd=%.6f\n", cf(m6)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%.6f\n", cf(m7)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ols=%.6f\n", cf(r8$m)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ipw_district=%.6f\n", cf(m9)))
cat(sprintf("RESULT:n_bills_ncosponsors_all_ols=%d\n", nobs(r1$m)))
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n", nclus(r1$m, r1$d)))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%d\n", nobs(r5$m)))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%d\n", nobs(r8$m)))
