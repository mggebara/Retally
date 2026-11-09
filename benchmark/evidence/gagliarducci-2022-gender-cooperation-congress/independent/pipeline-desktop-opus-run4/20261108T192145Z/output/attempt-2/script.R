suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
f_dta <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")
f_csv <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv")

raw <- tryCatch(haven::read_dta(f_dta), error = function(e) NULL)
if (is.null(raw)) raw <- readr::read_csv(f_csv, show_col_types = FALSE, guess_max = 100000)
d <- as.data.table(raw)
nm <- names(d)
cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")
cat("Columns:", paste(nm, collapse = ", "), "\n")

# ---------------- party coding ----------------
party_raw <- d[["sponsor_party"]]
party_chr <- NULL
if (inherits(party_raw, "haven_labelled")) {
  party_chr <- as.character(haven::as_factor(party_raw, levels = "labels"))
  if (!any(grepl("^(D|R)", toupper(party_chr)))) party_chr <- NULL
}
if (is.null(party_chr) && is.character(party_raw)) party_chr <- party_raw
d[] <- lapply(d, function(x) if (inherits(x, "haven_labelled")) as.vector(haven::zap_labels(x)) else x)
d[] <- lapply(d, function(x) { attr(x, "label") <- NULL; attr(x, "format.stata") <- NULL; x })

dem <- rep(NA_integer_, nrow(d))
if (!is.null(party_chr)) {
  pc <- toupper(trimws(party_chr))
  dem <- ifelse(grepl("^D", pc), 1L, ifelse(grepl("^R", pc), 0L, NA_integer_))
} else {
  pv <- d[["sponsor_party"]]
  if (all(c(100, 200) %in% unique(pv))) {
    dem <- ifelse(pv == 100, 1L, ifelse(pv == 200, 0L, NA_integer_))
  } else if ("MV1_democrat" %in% nm) {
    u <- sort(unique(na.omit(pv)))
    sh <- sapply(u, function(v) mean(d$MV1_democrat[pv == v] > 0, na.rm = TRUE))
    dv <- u[which.max(sh)]; rv <- u[which.min(sh)]
    dem <- ifelse(pv == dv, 1L, ifelse(pv == rv, 0L, NA_integer_))
  }
}
d[, dem := dem]
cat("Party table (dem):\n"); print(table(d$dem, useNA = "ifany"))

# ---------------- sample ----------------
if ("private" %in% nm) d <- d[is.na(private) | private == 0]
d[, fem := as.numeric(sponsor_female)]
d[, cong := as.integer(v2)]
d[, minor_f := as.character(minor)]

if ("sponsor_name" %in% nm) {
  d[, clus := paste(sponsor_name, cong, sep = "_")]
} else {
  d[, clus := paste(sponsor_state_icpsr, sponsor_district, cong, sep = "_")]
}

d[, y_ncos := as.numeric(numb_cosponsors)]
# Paper: % opposite-party cosponsors = opposite / (number of cosponsors + 1), in
# percentage points, so the sponsor is counted and zero-cosponsor bills are kept.
if ("numb_cosponsors_opposite" %in% nm) {
  d[, y_pct := 100 * as.numeric(numb_cosponsors_opposite) / (as.numeric(numb_cosponsors) + 1)]
} else {
  d[, y_pct := as.numeric(pct_cosponsors_opposite)]
  if (max(d$y_pct, na.rm = TRUE) <= 1.5) d[, y_pct := 100 * y_pct]
}
cat("Summary pct opposite:\n"); print(summary(d$y_pct))

# ---------------- controls ----------------
comm <- grep("^house_", names(d), value = TRUE)
comm <- comm[sapply(comm, function(v) is.numeric(d[[v]]) && length(unique(na.omit(d[[v]]))) > 1)]

# sponsor controls
spons <- character(0)
if ("sponsor_age" %in% names(d)) spons <- c(spons, "sponsor_age")
if ("sponsor_tenure_run" %in% names(d)) {
  spons <- c(spons, "sponsor_tenure_run")
  if (!("rookie" %in% names(d))) d[, rookie := as.integer(sponsor_tenure_run <= 1)]
}
if ("rookie" %in% names(d)) spons <- c(spons, "rookie")
if (all(c("comc", "comr") %in% names(d))) {
  d[, leader := as.integer(pmax(comc, comr, na.rm = TRUE) > 0)]
  spons <- c(spons, "leader")
} else if ("comc" %in% names(d)) {
  d[, leader := as.integer(comc > 0)]; spons <- c(spons, "leader")
}
for (v in c("black", "ivycoll", "borninstate")) if (v %in% names(d)) spons <- c(spons, v)
occ <- grep("^occ[0-9]+$", names(d), value = TRUE)
spons <- c(spons, occ)
d[, nbills_spons := .N, by = clus]
spons <- c(spons, "nbills_spons")
spons <- spons[sapply(spons, function(v) is.numeric(d[[v]]))]

# district controls
cand <- names(d)
dist <- cand[grepl("^pct_", cand) & !grepl("cosp|fem", cand)]
dist <- c(dist, cand[grepl("income|medinc|dens", cand, ignore.case = TRUE) & !grepl("cosp", cand)])
regcols <- cand[grepl("region|^south$|^midwest$|^northeast$|^west$", cand, ignore.case = TRUE)]
dist <- unique(dist)
dist <- dist[sapply(dist, function(v) is.numeric(d[[v]]))]
for (v in dist) {
  if (grepl("income|medinc|dens", v, ignore.case = TRUE) && !grepl("^ln|^log|_ln|_log", v, ignore.case = TRUE)) {
    x <- d[[v]]
    if (max(x, na.rm = TRUE) > 50) d[[v]] <- log(pmax(x, 1e-6))
  }
}
region_terms <- character(0)
for (v in regcols) {
  x <- d[[v]]
  ux <- unique(na.omit(x))
  if (length(ux) > 2) {
    nv <- paste0(v, "_f"); d[[nv]] <- as.character(x); region_terms <- c(region_terms, paste0("factor(", nv, ")"))
  } else if (length(ux) == 2 && is.numeric(x)) {
    region_terms <- c(region_terms, v)
  }
}
dist_terms <- c(dist, region_terms)
cat("Committee dummies:", length(comm), "\n")
cat("Sponsor controls:", paste(spons, collapse = ", "), "\n")
cat("District controls:", paste(dist_terms, collapse = ", "), "\n")

# margin of victory of elected candidate
if ("MV1_democrat" %in% names(d)) {
  d[, mv_elect := abs(MV1_democrat)]
} else {
  d[, mv_elect := abs(MV1_female)]
}

safe <- function(expr) tryCatch(expr, error = function(e) { message("ERROR: ", conditionMessage(e)); NULL })
getb <- function(m) if (is.null(m)) NA_real_ else unname(coef(m)["fem"])

build_fml <- function(y, rhs, fe) {
  rhs <- c("fem", rhs)
  as.formula(paste(y, "~", paste(rhs, collapse = " + "), "|", paste(fe, collapse = " + ")))
}

# ---------------- OLS (Table 5 col 1) ----------------
ols <- function(y, sub, add_party = FALSE) {
  rhs <- c(comm, spons, dist_terms)
  if (add_party) rhs <- c(rhs, "dem")
  feols(build_fml(y, rhs, c("cong", "minor_f")), data = sub, cluster = ~clus)
}

dA <- d
dD <- d[dem == 1]
dR <- d[dem == 0]

m_all_n <- safe(ols("y_ncos", dA, add_party = TRUE))
m_rep_n <- safe(ols("y_ncos", dR))
m_dem_p <- safe(ols("y_pct", dD))
m_rep_p <- safe(ols("y_pct", dR))
if (!is.null(m_all_n)) print(coeftable(m_all_n)["fem", ])

n_bills_all <- if (is.null(m_all_n)) NA else nobs(m_all_n)
n_clus_all <- if (is.null(m_all_n)) NA else length(unique(dA$clus[obs(m_all_n)]))
n_bills_dem_p <- if (is.null(m_dem_p)) NA else nobs(m_dem_p)
n_bills_rep_p <- if (is.null(m_rep_p)) NA else nobs(m_rep_p)

# ---------------- propensity scores ----------------
ps_weights <- function(sub, xvars, cong_fe = TRUE) {
  sp <- sub[, .SD[1], by = clus]
  vars <- xvars[sapply(xvars, function(v) !grepl("^factor\\(", v))]
  facs <- gsub("^factor\\((.*)\\)$", "\\1", xvars[grepl("^factor\\(", xvars)])
  keep <- c("clus", "fem", "cong", vars, facs)
  sp <- sp[, ..keep]
  sp <- sp[complete.cases(sp)]
  rhs <- c(vars, if (length(facs)) paste0("factor(", facs, ")"), if (cong_fe) "factor(cong)")
  fml <- as.formula(paste("fem ~", paste(rhs, collapse = " + ")))
  g <- glm(fml, data = sp, family = binomial())
  p <- pmin(pmax(fitted(g), 0.01), 0.99)
  sp[, w := ifelse(fem == 1, 1 / p, 1 / (1 - p))]
  w <- sp$w[match(sub$clus, sp$clus)]
  w
}

ipw_reg <- function(y, sub, xvars) {
  sub <- copy(sub)
  sub[, w := ps_weights(sub, xvars)]
  sub <- sub[!is.na(w)]
  feols(build_fml(y, comm, c("cong", "minor_f")), data = sub, weights = ~w, cluster = ~clus)
}

m_rep_n_ipw5 <- safe(ipw_reg("y_ncos", dR, c(dist_terms, "mv_elect", spons)))
m_dem_p_ipw5 <- safe(ipw_reg("y_pct", dD, c(dist_terms, "mv_elect", spons)))
m_rep_p_ipw4 <- safe(ipw_reg("y_pct", dR, c(dist_terms, "mv_elect")))

# ---------------- RD ----------------
rd_bw <- function(y, x) {
  ok <- !is.na(y) & !is.na(x)
  h <- tryCatch({
    b <- rdbwselect(y[ok], x[ok], c = 0, p = 1, kernel = "triangular", bwselect = "mserd")
    b$bws[1, 1]
  }, error = function(e) NA_real_)
  if (is.na(h)) h <- if (max(abs(x), na.rm = TRUE) <= 1) 0.15 else 15
  h
}

rd_est <- function(y, sub, ipw = FALSE) {
  s <- sub[!is.na(MV1_female)]
  if ("mixed_gender_election" %in% names(s)) s <- s[mixed_gender_election == 1]
  s[, mv := as.numeric(MV1_female)]
  h <- rd_bw(s[[y]], s$mv)
  cat("RD bandwidth for", y, ":", h, "\n")
  s <- s[abs(mv) <= h]
  if (!ipw) {
    feols(as.formula(paste(y, "~ fem + mv + fem:mv | cong")), data = s, cluster = ~clus)
  } else {
    s[, w := ps_weights(s, dist_terms)]
    s <- s[!is.na(w)]
    rhs <- c("fem", "mv", "fem:mv", comm)
    feols(as.formula(paste(y, "~", paste(rhs, collapse = " + "), "| cong + minor_f")),
          data = s, weights = ~w, cluster = ~clus)
  }
}

m_rep_n_rdipw <- safe(rd_est("y_ncos", dR, ipw = TRUE))
m_dem_p_rd <- safe(rd_est("y_pct", dD, ipw = FALSE))

fmt <- function(x) if (is.na(x)) "NA" else format(round(x, 6), scientific = FALSE)
cat(sprintf("RESULT:female_sponsor_ncosponsors_all_ols=%s\n", fmt(getb(m_all_n))))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ols=%s\n", fmt(getb(m_rep_n))))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%s\n", fmt(getb(m_rep_n_rdipw))))
cat(sprintf("RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%s\n", fmt(getb(m_rep_n_ipw5))))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ols=%s\n", fmt(getb(m_dem_p))))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_rd=%s\n", fmt(getb(m_dem_p_rd))))
cat(sprintf("RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%s\n", fmt(getb(m_dem_p_ipw5))))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ols=%s\n", fmt(getb(m_rep_p))))
cat(sprintf("RESULT:female_sponsor_pct_opposite_rep_ipw_district=%s\n", fmt(getb(m_rep_p_ipw4))))
cat(sprintf("RESULT:n_bills_ncosponsors_all_ols=%s\n", fmt(as.numeric(n_bills_all))))
cat(sprintf("RESULT:n_sponsor_terms_ncosponsors_all_ols=%s\n", fmt(as.numeric(n_clus_all))))
cat(sprintf("RESULT:n_bills_pct_opposite_dem_ols=%s\n", fmt(as.numeric(n_bills_dem_p))))
cat(sprintf("RESULT:n_bills_pct_opposite_rep_ols=%s\n", fmt(as.numeric(n_bills_rep_p))))