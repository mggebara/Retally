suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
path <- file.path(root, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv")
raw <- as.data.frame(read_csv(path, show_col_types = FALSE, guess_max = 100000))
nm <- names(raw)
num <- function(x) suppressWarnings(as.numeric(x))
has <- function(v) v %in% names(raw)
find_cols <- function(pattern, exclude = NULL) {
  out <- grep(pattern, nm, value = TRUE, ignore.case = TRUE)
  if (!is.null(exclude)) out <- out[!grepl(exclude, out, ignore.case = TRUE)]
  out
}
is_dummy <- function(x) { u <- unique(x[!is.na(x)]); length(u) > 0 && all(u %in% c(0, 1)) }

d <- raw
n_loaded <- nrow(d)

# ---------------- core variables ----------------
d$female <- num(d$sponsor_female)
d$v2 <- num(d$v2)

p <- d$sponsor_party
party <- rep(NA_character_, nrow(d))
if (is.numeric(p)) {
  party[p == 100] <- "D"; party[p == 200] <- "R"
  if (all(is.na(party))) { party[p == 1] <- "D"; party[p == 2] <- "R" }
} else {
  pp <- toupper(trimws(as.character(p)))
  party[grepl("^D", pp) | pp == "100"] <- "D"
  party[grepl("^R", pp) | pp == "200"] <- "R"
}
d$party <- party
d$rep <- as.integer(d$party == "R")

d$ncosp <- num(d$numb_cosponsors)
d$pct_opp <- num(d$pct_cosponsors_opposite)
if (max(d$pct_opp, na.rm = TRUE) <= 1.0001) d$pct_opp <- 100 * d$pct_opp

d$cl <- paste(d$v2, d$sponsor_state_abbrev, d$sponsor_district, d$sponsor_term_served, sep = "_")

# Bill characteristics: committee-of-referral dummies + minor topic FE
house_cols <- grep("^house_", nm, value = TRUE)
house_cols <- house_cols[sapply(house_cols, function(v) is_dummy(num(raw[[v]])))]
for (v in house_cols) d[[v]] <- num(d[[v]])
d$minor_f <- d$minor

# Sponsor characteristics
d$s_age <- num(d$sponsor_age)
d$s_tenure <- num(d$sponsor_tenure_run)
rk <- find_cols("rookie")
d$s_rookie <- if (length(rk) > 0) num(d[[rk[1]]]) else as.integer(d$s_tenure == 1)
lead_src <- intersect(c("comc", "comr"), nm)
if (length(lead_src) > 0) {
  m <- sapply(lead_src, function(v) num(d[[v]]) > 0)
  d$s_leader <- as.integer(rowSums(as.matrix(m), na.rm = TRUE) > 0)
} else d$s_leader <- 0
d$s_black <- num(d$black)
d$s_ivy <- if (has("ivycoll")) num(d$ivycoll) else 0
d$s_borninstate <- if (has("borninstate")) num(d$borninstate) else NA
occ_cols <- sort(grep("^occ[0-9]+$", nm, value = TRUE))
if (length(occ_cols) > 1) occ_cols <- occ_cols[-1]
for (v in occ_cols) d[[v]] <- num(d[[v]])
nb <- find_cols("nbills|numb_bills|bills_sponsored|total_bills|sponsor_nbill", exclude = "cospons")
if (length(nb) > 0) {
  d$s_nbills <- num(d[[nb[1]]])
} else d$s_nbills <- NA

# District characteristics
dist_vars <- c()
for (v in c("pct_black", "pct_urban", "pct_for_born")) if (has(v)) { d[[v]] <- num(d[[v]]); dist_vars <- c(dist_vars, v) }
o65 <- find_cols("65|over_?65|elder", exclude = "^cosp|numb_|pct_cosp")
if (length(o65) > 0) { d$d_over65 <- num(d[[o65[1]]]); dist_vars <- c(dist_vars, "d_over65") }
inc <- find_cols("income|medinc", exclude = "^cosp")
if (length(inc) > 0) {
  x <- num(d[[inc[1]]])
  d$d_lninc <- if (grepl("^(ln|log)", inc[1], ignore.case = TRUE)) x else log(x)
  dist_vars <- c(dist_vars, "d_lninc")
}
den <- find_cols("dens", exclude = "^cosp")
if (length(den) > 0) {
  x <- num(d[[den[1]]])
  d$d_lndens <- if (grepl("^(ln|log)", den[1], ignore.case = TRUE)) x else log(x)
  dist_vars <- c(dist_vars, "d_lndens")
}
reg <- find_cols("region|northeast|midwest|south|^west|_west", exclude = "^cosp")
if (length(reg) == 1 && length(unique(na.omit(d[[reg]]))) > 2) {
  rf <- factor(d[[reg]])
  lv <- levels(rf)[-1]
  for (k in seq_along(lv)) { vn <- paste0("d_region", k); d[[vn]] <- as.integer(rf == lv[k]); dist_vars <- c(dist_vars, vn) }
} else if (length(reg) > 0) {
  rr <- reg[sapply(reg, function(v) is_dummy(num(d[[v]])))]
  if (length(rr) >= 4) rr <- rr[-1]
  for (v in rr) { d[[v]] <- num(d[[v]]); dist_vars <- c(dist_vars, v) }
}
for (v in dist_vars) d[[v]][!is.finite(d[[v]])] <- NA

# Margins
d$MV <- num(d$MV1_female)
mv_scale <- if (max(abs(d$MV), na.rm = TRUE) <= 1.0001) 0.01 else 1
d$femXMV <- d$female * d$MV
d$mv_elected <- if (has("MV1_democrat")) abs(num(d$MV1_democrat)) else NA

# ---------------- sample: public bills ----------------
if (has("private")) d <- d[!is.na(num(d$private)) & num(d$private) == 0, ]
n_public <- nrow(d)
if (all(is.na(d$s_nbills))) {
  d$s_nbills <- ave(rep(1, nrow(d)), d$cl, FUN = sum)
}

spons_vars <- c("s_age", "s_tenure", "s_rookie", "s_leader", "s_black", "s_ivy", "s_borninstate", occ_cols, "s_nbills")
spons_vars <- spons_vars[sapply(spons_vars, function(v) !all(is.na(d[[v]])))]
bq <- function(v) paste0("`", v, "`")

subset_party <- function(dat, grp) {
  if (grp == "all") dat[!is.na(dat$party), ] else dat[!is.na(dat$party) & dat$party == grp, ]
}

print_sample <- function(name, steps) {
  for (s in names(steps)) cat(sprintf("SAMPLE:%s:%s=%d\n", name, s, as.integer(steps[[s]])))
}

n_clusters <- function(model, dat) {
  idx <- obs(model)
  length(unique(dat$cl[idx]))
}

run_ols <- function(y, grp, name) {
  dat <- subset_party(d, grp)
  rhs <- c("female", house_cols, spons_vars, dist_vars)
  if (grp == "all") rhs <- c(rhs, "rep")
  f <- as.formula(paste(y, "~", paste(bq(rhs), collapse = " + "), "| v2 + minor_f"))
  m <- feols(f, data = dat, cluster = ~cl, warn = FALSE, notes = FALSE)
  print_sample(name, list(loaded = n_loaded, public_bills = n_public,
                          party = nrow(dat), estimation = nobs(m)))
  list(m = m, dat = dat)
}

collapse_sponsor <- function(dat, vars) {
  sp <- dat[!duplicated(dat$cl), c("cl", "female", vars), drop = FALSE]
  sp
}

estimate_ps <- function(sp, vars) {
  vars <- vars[sapply(vars, function(v) length(unique(na.omit(sp[[v]]))) > 1)]
  f <- as.formula(paste("female ~", paste(bq(vars), collapse = " + ")))
  g <- suppressWarnings(glm(f, data = sp, family = binomial(link = "logit")))
  ps <- rep(NA_real_, nrow(sp))
  ps[as.integer(rownames(model.frame(g)))] <- fitted(g)
  sp$ps <- ps
  sp$w <- ifelse(sp$female == 1, 1 / sp$ps, 1 / (1 - sp$ps))
  sp[, c("cl", "w")]
}

run_rd <- function(y, grp, h_pp, name, ipw = FALSE) {
  dat <- subset_party(d, grp)
  n_party <- nrow(dat)
  dat <- dat[!is.na(num(dat$mixed_gender_election)) & num(dat$mixed_gender_election) == 1, ]
  n_mixed <- nrow(dat)
  h <- h_pp * mv_scale
  dat <- dat[!is.na(dat$MV) & abs(dat$MV) < h, ]
  n_bw <- nrow(dat)
  rownames(dat) <- NULL
  if (ipw) {
    sp <- collapse_sponsor(dat, dist_vars)
    rownames(sp) <- NULL
    wt <- estimate_ps(sp, dist_vars)
    dat <- merge(dat, wt, by = "cl", all.x = TRUE, sort = FALSE)
    dat <- dat[is.finite(dat$w), ]
    rhs <- c("female", "MV", "femXMV", house_cols)
    f <- as.formula(paste(y, "~", paste(bq(rhs), collapse = " + "), "| v2 + minor_f"))
    m <- feols(f, data = dat, weights = ~w, cluster = ~cl, warn = FALSE, notes = FALSE)
  } else {
    f <- as.formula(paste(y, "~ female + MV + femXMV | v2"))
    m <- feols(f, data = dat, cluster = ~cl, warn = FALSE, notes = FALSE)
  }
  print_sample(name, list(loaded = n_loaded, public_bills = n_public, party = n_party,
                          mixed_gender_election = n_mixed, optimal_bandwidth = n_bw,
                          estimation = nobs(m)))
  m
}

run_ipw_full <- function(y, grp, with_sponsor, name) {
  dat <- subset_party(d, grp)
  n_party <- nrow(dat)
  psvars <- c(dist_vars, "mv_elected")
  psvars <- psvars[sapply(psvars, function(v) !all(is.na(dat[[v]])))]
  if (with_sponsor) psvars <- c(psvars, setdiff(spons_vars, "s_nbills"))
  sp <- collapse_sponsor(dat, psvars)
  rownames(sp) <- NULL
  wt <- estimate_ps(sp, psvars)
  dat <- merge(dat, wt, by = "cl", all.x = TRUE, sort = FALSE)
  dat <- dat[is.finite(dat$w), ]
  rhs <- c("female", house_cols)
  f <- as.formula(paste(y, "~", paste(bq(rhs), collapse = " + "), "| v2 + minor_f"))
  m <- feols(f, data = dat, weights = ~w, cluster = ~cl, warn = FALSE, notes = FALSE)
  print_sample(name, list(loaded = n_loaded, public_bills = n_public, party = n_party,
                          estimation = nobs(m)))
  m
}

# ---------------- estimation ----------------
o_all_n <- run_ols("ncosp", "all", "ncosp_all_ols")
o_rep_n <- run_ols("ncosp", "R", "ncosp_rep_ols")
rd_rep_n_ipw <- run_rd("ncosp", "R", 13, "ncosp_rep_rd_ipw", ipw = TRUE)
ipw_rep_n_s <- run_ipw_full("ncosp", "R", TRUE, "ncosp_rep_ipw_sponsor")
o_dem_p <- run_ols("pct_opp", "D", "pctopp_dem_ols")
rd_dem_p <- run_rd("pct_opp", "D", 24, "pctopp_dem_rd", ipw = FALSE)
ipw_dem_p_s <- run_ipw_full("pct_opp", "D", TRUE, "pctopp_dem_ipw_sponsor")
o_rep_p <- run_ols("pct_opp", "R", "pctopp_rep_ols")
ipw_rep_p_d <- run_ipw_full("pct_opp", "R", FALSE, "pctopp_rep_ipw_district")

cf <- function(m) unname(coef(m)["female"])

cat(sprintf("RESULT:female_sponsor_ncosponsors_all_ols=%.6f\n", cf(o_all_n$m)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ols=%.6f\n", cf(o_rep_n$m)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%.6f\n", cf(rd_rep_n_ipw)))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%.6f\n", cf(ipw_rep_n_s)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ols=%.6f\n", cf(o_dem_p$m)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_rd=%.6f\n", cf(rd_dem_p)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%.6f\n", cf(ipw_dem_p_s)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ols=%.6f\n", cf(o_rep_p$m)))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ipw_district=%.6f\n", cf(ipw_rep_p_d)))
cat(sprintf("RESULT:n_bills_ncosponsors_all_ols=%d\n", as.integer(nobs(o_all_n$m))))
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n", as.integer(n_clusters(o_all_n$m, o_all_n$dat))))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%d\n", as.integer(nobs(o_dem_p$m))))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%d\n", as.integer(nobs(o_rep_p$m))))