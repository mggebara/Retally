suppressPackageStartupMessages({
  library(readr)
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
f_csv <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv")
f_dta <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")

df <- tryCatch(as.data.frame(read_csv(f_csv, guess_max = 100000, show_col_types = FALSE)),
               error = function(e) NULL)
if (is.null(df) || ncol(df) < 10) {
  df <- as.data.frame(zap_labels(read_dta(f_dta)))
}
names(df) <- trimws(names(df))
nm <- names(df)

pick <- function(patterns, exclude = NULL) {
  for (p in patterns) {
    hits <- nm[grepl(p, nm, ignore.case = TRUE)]
    if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(as.character(x)))

# ---------------- Basic variables ----------------
cong_col <- if ("v2" %in% nm) "v2" else pick(c("^congress$", "congress"))
df$cong <- num(df[[cong_col]])
if (!all(df$cong[!is.na(df$cong)] %in% 101:111)) {
  alt <- pick(c("^congress$"))
  if (!is.na(alt)) df$cong <- num(df[[alt]])
}
df <- df[!is.na(df$cong) & df$cong >= 101 & df$cong <= 111, ]

if ("private" %in% names(df)) {
  pv <- num(df$private)
  df <- df[is.na(pv) | pv == 0, ]
}

df$female <- as.numeric(num(df$sponsor_female) == 1)

# party
pty <- df$sponsor_party
if (is.numeric(pty) || all(grepl("^[0-9.]+$", na.omit(as.character(pty))))) {
  pn <- num(pty)
  if (any(pn == 100, na.rm = TRUE) || any(pn == 200, na.rm = TRUE)) {
    df$dem <- as.numeric(pn == 100); df$rep <- as.numeric(pn == 200)
  } else {
    df$dem <- as.numeric(pn == 1); df$rep <- as.numeric(pn == 2)
    if (all(pn %in% c(0, 1, NA))) { df$dem <- as.numeric(pn == 1); df$rep <- as.numeric(pn == 0) }
  }
} else {
  ps <- toupper(as.character(pty))
  df$dem <- as.numeric(grepl("^D", ps)); df$rep <- as.numeric(grepl("^R", ps))
}

# sponsor-Congress cluster
idcols <- intersect(c("sponsor_name", "sponsor_state_abbrev", "sponsor_state_icpsr",
                      "sponsor_district", "sponsor_term_served"), names(df))
df$clus <- do.call(paste, c(lapply(idcols, function(v) as.character(df[[v]])), list(df$cong), sep = "_"))

# outcomes
df$ncosp <- num(df$numb_cosponsors)
pct_ok <- FALSE
if ("pct_cosponsors_opposite" %in% names(df)) {
  pc <- num(df$pct_cosponsors_opposite)
  zero <- !is.na(df$ncosp) & df$ncosp == 0
  if (sum(!is.na(pc[zero])) >= 0.9 * sum(zero)) {
    if (max(pc, na.rm = TRUE) <= 1.0001) pc <- 100 * pc
    df$pctopp <- pc; pct_ok <- TRUE
  }
}
if (!pct_ok && "numb_cosponsors_opposite" %in% names(df)) {
  df$pctopp <- 100 * num(df$numb_cosponsors_opposite) / (df$ncosp + 1)
}

# ---------------- Bill characteristics ----------------
df$minor_f <- as.character(df$minor)
comm_cols <- nm[grepl("^house_", nm) & !grepl("pass|vote|floor|report|reach", nm, ignore.case = TRUE)]
comm_cols <- comm_cols[sapply(comm_cols, function(v) {
  x <- num(df[[v]]); all(x[!is.na(x)] %in% c(0, 1)) && length(unique(na.omit(x))) == 2
})]
for (v in comm_cols) df[[v]] <- num(df[[v]])
bill_ctrls <- comm_cols

# ---------------- Sponsor characteristics ----------------
df$s_age <- num(df$sponsor_age)
df$s_tenure <- num(df$sponsor_tenure_run)
rk <- pick(c("rookie", "freshman"))
if (!is.na(rk)) df$s_rookie <- num(df[[rk]]) else df$s_rookie <- as.numeric(df$s_tenure <= 1)
lead_parts <- intersect(c("comc", "comr"), names(df))
if (length(lead_parts) > 0) {
  lm_ <- sapply(lead_parts, function(v) num(df[[v]]))
  if (is.null(dim(lm_))) lm_ <- matrix(lm_, ncol = 1)
  df$s_leader <- as.numeric(rowSums(lm_ > 0, na.rm = TRUE) > 0)
  df$s_leader[apply(is.na(lm_), 1, all)] <- NA
} else {
  ld <- pick(c("leader", "chair"), exclude = "numb_|cosponsor")
  df$s_leader <- if (!is.na(ld)) num(df[[ld]]) else 0
}
df$s_black <- if ("black" %in% names(df)) num(df$black) else 0
df$s_ivy <- if ("ivycoll" %in% names(df)) num(df$ivycoll) else 0
occs <- sort(nm[grepl("^occ[0-9]+$", nm)])
occs <- setdiff(occs, "occ0")
for (v in occs) df[[v]] <- num(df[[v]])
bis <- pick(c("borninstate", "born_in"))
if (!is.na(bis)) df$s_born <- num(df[[bis]])
nb <- pick(c("^sponsor_n?bills", "nbills_sponsored", "numb_bills", "bills_sponsored",
             "total_bills", "sponsor_total_bills"), exclude = "cospons")
if (!is.na(nb)) {
  df$s_nbills <- num(df[[nb]])
} else {
  df$s_nbills <- ave(rep(1, nrow(df)), df$clus, FUN = sum)
}
spons_ctrls <- c("s_age", "s_tenure", "s_rookie", "s_leader", "s_black", "s_ivy", occs,
                 if (!is.na(bis)) "s_born", "s_nbills")
spons_ctrls_ps <- setdiff(spons_ctrls, "s_nbills")

# ---------------- District characteristics ----------------
dist_ctrls <- c()
rg <- pick(c("^region$", "region"))
if (!is.na(rg)) {
  df$d_region <- as.character(df[[rg]])
  rl <- sort(unique(na.omit(df$d_region)))
  for (k in rl[-1]) { vn <- paste0("d_reg_", make.names(k)); df[[vn]] <- as.numeric(df$d_region == k); df[[vn]][is.na(df$d_region)] <- NA; dist_ctrls <- c(dist_ctrls, vn) }
} else {
  rd <- nm[grepl("^(northeast|midwest|south|west|north_east|mid_west|ne|mw)$", nm, ignore.case = TRUE)]
  if (length(rd) >= 4) rd <- rd[1:3]
  for (v in rd) df[[v]] <- num(df[[v]])
  dist_ctrls <- c(dist_ctrls, rd)
}
for (v in c("pct_black", "pct_urban", "pct_for_born")) {
  if (v %in% names(df)) { df[[v]] <- num(df[[v]]); dist_ctrls <- c(dist_ctrls, v) }
}
p65 <- pick(c("65", "over_?65", "elder", "old"), exclude = "^MV|cospons")
if (!is.na(p65)) { df$d_p65 <- num(df[[p65]]); dist_ctrls <- c(dist_ctrls, "d_p65") }
inc <- pick(c("income", "medinc"))
if (!is.na(inc)) {
  x <- num(df[[inc]])
  df$d_linc <- if (grepl("log|^ln|_ln", inc, ignore.case = TRUE) || max(x, na.rm = TRUE) < 30) x else log(x)
  dist_ctrls <- c(dist_ctrls, "d_linc")
}
den <- pick(c("dens"))
if (!is.na(den)) {
  x <- num(df[[den]])
  df$d_ldens <- if (grepl("log|^ln|_ln", den, ignore.case = TRUE) || min(x, na.rm = TRUE) < 0) x else log(pmax(x, 1e-6))
  dist_ctrls <- c(dist_ctrls, "d_ldens")
}

# ---------------- Running variables ----------------
df$mge <- num(df$mixed_gender_election)
df$mvf <- num(df$MV1_female)
mv_scale <- if (max(abs(df$mvf), na.rm = TRUE) <= 1.5) 0.01 else 1
# margin of victory of the elected candidate (full sample)
mvw <- pick(c("^MV1_winner", "^MV_winner", "^MV1$", "margin_?vic"))
if (!is.na(mvw)) df$mv_el <- abs(num(df[[mvw]])) else df$mv_el <- abs(num(df$MV1_democrat))
df$uncont <- 0
if (mean(is.na(df$mv_el)) > 0.02) {
  df$uncont <- as.numeric(is.na(df$mv_el))
  df$mv_el[is.na(df$mv_el)] <- max(df$mv_el, na.rm = TRUE)
}

# ---------------- Helpers ----------------
fit <- function(y, ctrls, data, fe = "cong + minor_f", wts = NULL) {
  ctrls <- ctrls[ctrls %in% names(data)]
  ctrls <- ctrls[sapply(ctrls, function(v) length(unique(na.omit(data[[v]]))) > 1)]
  rhs <- paste(c("female", ctrls), collapse = " + ")
  fml <- as.formula(paste(y, "~", rhs, "|", fe))
  if (is.null(wts)) feols(fml, data = data, cluster = ~clus)
  else feols(fml, data = data, cluster = ~clus, weights = as.formula(paste0("~", wts)))
}
getb <- function(m) unname(coef(m)["female"])
nclus <- function(m, data) {
  idx <- obs(m)
  length(unique(data$clus[idx]))
}

ps_weights <- function(data, covs) {
  covs <- covs[covs %in% names(data)]
  sp <- data[!duplicated(data$clus), c("clus", "female", covs)]
  covs <- covs[sapply(covs, function(v) length(unique(na.omit(sp[[v]]))) > 1)]
  fml <- as.formula(paste("female ~", paste(covs, collapse = " + ")))
  g <- glm(fml, data = sp, family = binomial())
  p <- predict(g, newdata = sp, type = "response")
  p <- pmin(pmax(p, 1e-6), 1 - 1e-6)
  w <- ifelse(sp$female == 1, 1 / p, 1 / (1 - p))
  w[match(data$clus, sp$clus)]
}

res <- list()
safe <- function(name, expr) {
  v <- tryCatch(expr, error = function(e) { message(name, ": ", conditionMessage(e)); NA })
  res[[name]] <<- v
}

ols_ctrls_all <- c(bill_ctrls, spons_ctrls, dist_ctrls, "rep")
ols_ctrls_party <- c(bill_ctrls, spons_ctrls, dist_ctrls)

dD <- df[df$dem == 1, ]
dR <- df[df$rep == 1, ]

# ---------------- Column 1: OLS ----------------
m_all <- tryCatch(fit("ncosp", ols_ctrls_all, df), error = function(e) { message(e$message); NULL })
safe("female_sponsor_ncosponsors_all_ols", getb(m_all))
safe("n_bills_ncosponsors_all_ols", nobs(m_all))
safe("n_sponsor_terms_ncosponsors_all_ols", nclus(m_all, df))

safe("female_sponsor_ncosponsors_rep_ols", getb(fit("ncosp", ols_ctrls_party, dR)))

m_pD <- tryCatch(fit("pctopp", ols_ctrls_party, dD), error = function(e) { message(e$message); NULL })
safe("female_sponsor_pct_opposite_dem_ols", getb(m_pD))
safe("n_bills_pct_opposite_dem_ols", nobs(m_pD))

m_pR <- tryCatch(fit("pctopp", ols_ctrls_party, dR), error = function(e) { message(e$message); NULL })
safe("female_sponsor_pct_opposite_rep_ols", getb(m_pR))
safe("n_bills_pct_opposite_rep_ols", nobs(m_pR))

# ---------------- Column 2: RD (Democrats, pct opposite, bw = 24 pp) ----------------
safe("female_sponsor_pct_opposite_dem_rd", {
  h <- 24 * mv_scale
  d <- dD[!is.na(dD$mge) & dD$mge == 1 & !is.na(dD$mvf) & abs(dD$mvf) <= h, ]
  d$mv <- d$mvf; d$fXmv <- d$female * d$mvf
  getb(fit("pctopp", c("mv", "fXmv"), d, fe = "cong"))
})

# ---------------- Column 3: RD with IPW (Republicans, ncosponsors, bw = 13 pp) ----------------
safe("female_sponsor_ncosponsors_rep_rd_ipw", {
  h <- 13 * mv_scale
  d <- dR[!is.na(dR$mge) & dR$mge == 1 & !is.na(dR$mvf) & abs(dR$mvf) <= h, ]
  d$mv <- d$mvf; d$fXmv <- d$female * d$mvf
  d$w <- ps_weights(d, dist_ctrls)
  d <- d[!is.na(d$w), ]
  getb(fit("ncosp", c("mv", "fXmv", bill_ctrls), d, fe = "cong + minor_f", wts = "w"))
})

# ---------------- Columns 4-5: PS weighting, full sample ----------------
mv_covs <- c("mv_el", if (sum(df$uncont) > 0) "uncont")

safe("female_sponsor_pct_opposite_rep_ipw_district", {
  d <- dR
  d$w <- ps_weights(d, c(dist_ctrls, mv_covs))
  d <- d[!is.na(d$w), ]
  getb(fit("pctopp", bill_ctrls, d, wts = "w"))
})

safe("female_sponsor_ncosponsors_rep_ipw_sponsor", {
  d <- dR
  d$w <- ps_weights(d, c(dist_ctrls, mv_covs, spons_ctrls_ps))
  d <- d[!is.na(d$w), ]
  getb(fit("ncosp", bill_ctrls, d, wts = "w"))
})

safe("female_sponsor_pct_opposite_dem_ipw_sponsor", {
  d <- dD
  d$w <- ps_weights(d, c(dist_ctrls, mv_covs, spons_ctrls_ps))
  d <- d[!is.na(d$w), ]
  getb(fit("pctopp", bill_ctrls, d, wts = "w"))
})

# ---------------- Output ----------------
order_names <- c("female_sponsor_ncosponsors_all_ols", "female_sponsor_ncosponsors_rep_ols",
                 "female_sponsor_ncosponsors_rep_rd_ipw", "female_sponsor_ncosponsors_rep_ipw_sponsor",
                 "female_sponsor_pct_opposite_dem_ols", "female_sponsor_pct_opposite_dem_rd",
                 "female_sponsor_pct_opposite_dem_ipw_sponsor", "female_sponsor_pct_opposite_rep_ols",
                 "female_sponsor_pct_opposite_rep_ipw_district", "n_bills_ncosponsors_all_ols",
                 "n_sponsor_terms_ncosponsors_all_ols", "n_bills_pct_opposite_dem_ols",
                 "n_bills_pct_opposite_rep_ols")
for (n in order_names) {
  v <- res[[n]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(as.numeric(v), digits = 10)))
}