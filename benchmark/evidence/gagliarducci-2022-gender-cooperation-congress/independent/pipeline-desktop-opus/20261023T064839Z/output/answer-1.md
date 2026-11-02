```r
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
f_csv <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv")
f_dta <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")

d <- tryCatch(
  as.data.frame(haven::zap_labels(haven::read_dta(f_dta))),
  error = function(e) as.data.frame(read_csv(f_csv, guess_max = 70000, show_col_types = FALSE))
)
nm <- names(d)
cat("Columns:", paste(nm, collapse = ", "), "\n")

has <- function(v) v %in% names(d)
findcol <- function(patterns, exclude = NULL) {
  for (p in patterns) {
    hits <- grep(p, names(d), value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
    hits <- hits[!grepl("^cosp|cosponsor", hits, ignore.case = TRUE)]
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# ---------------- sample ----------------
if (has("private")) d <- d[is.na(d$private) | num(d$private) == 0, ]
d$female <- num(d$sponsor_female)
d$congress <- num(d$v2)

# party
pr <- d$sponsor_party
prn <- num(pr)
if (all(is.na(prn) == is.na(pr))) {
  d$dem <- as.integer(prn == 100)
  d$rep <- as.integer(prn == 200)
} else {
  prc <- toupper(substr(as.character(pr), 1, 1))
  d$dem <- as.integer(prc == "D")
  d$rep <- as.integer(prc == "R")
}

# cluster: sponsor x Congress
idparts <- intersect(c("sponsor", "sponsor_name", "sponsor_state_icpsr", "sponsor_state_abbrev", "sponsor_district"), names(d))
d$clus <- do.call(paste, c(list(d$v2), lapply(idparts, function(v) d[[v]]), sep = "_"))

# outcomes
d$y_n <- num(d$numb_cosponsors)
if (has("pct_cosponsors_opposite")) {
  d$y_pct <- num(d$pct_cosponsors_opposite)
} else {
  d$y_pct <- 100 * num(d$numb_cosponsors_opposite) / (d$y_n + 1)
}
if (max(d$y_pct, na.rm = TRUE) <= 1.0001) d$y_pct <- 100 * d$y_pct

# ---------------- controls ----------------
# bill characteristics: minor topic FE + committee dummies
comm <- grep("^house_", names(d), value = TRUE)
comm <- comm[sapply(comm, function(v) { x <- num(d[[v]]); all(x[!is.na(x)] %in% c(0, 1)) })]
for (v in comm) d[[v]] <- num(d[[v]])
d$minor_f <- d$minor

# sponsor characteristics
d$s_age <- num(d$sponsor_age)
d$s_tenure <- num(d$sponsor_tenure_run)
rk <- findcol(c("^rookie$", "sponsor_rookie", "rookie"))
if (!is.na(rk)) d$s_rookie <- num(d[[rk]]) else d$s_rookie <- as.integer(d$s_tenure <= min(d$s_tenure, na.rm = TRUE))
leadv <- intersect(c("comc", "comr"), names(d))
if (length(leadv) > 0) {
  d$s_lead <- as.integer(rowSums(sapply(leadv, function(v) num(d[[v]]) > 0), na.rm = TRUE) > 0)
} else {
  lc <- findcol(c("leadcomm", "chair"))
  d$s_lead <- if (!is.na(lc)) num(d[[lc]]) else 0
}
d$s_ivy <- if (has("ivycoll")) num(d$ivycoll) else 0
d$s_black <- if (has("black")) num(d$black) else 0
bis <- findcol(c("borninstate", "born_in_state", "born"))
d$s_born <- if (!is.na(bis)) num(d[[bis]]) else NA
occs <- intersect(paste0("occ", 1:5), names(d))
for (v in occs) d[[v]] <- num(d[[v]])
d <- d %>% group_by(clus) %>% mutate(s_nbills = n()) %>% ungroup() %>% as.data.frame()

spons_vars <- c("s_age", "s_tenure", "s_rookie", "s_lead", "s_ivy", "s_black", occs, "s_nbills")
if (!all(is.na(d$s_born))) spons_vars <- c(spons_vars, "s_born")
spons_vars <- spons_vars[sapply(spons_vars, function(v) sd(d[[v]], na.rm = TRUE) > 0)]

# district characteristics
st <- num(d$sponsor_state_icpsr)
d$region <- ifelse(st <= 14, "NE", ifelse(st <= 37, "MW", ifelse(st <= 56, "S", "W")))
d$reg_mw <- as.integer(d$region == "MW"); d$reg_s <- as.integer(d$region == "S"); d$reg_w <- as.integer(d$region == "W")
dv <- c()
addd <- function(newname, col, logit = FALSE) {
  if (is.na(col)) return(invisible(NULL))
  x <- num(d[[col]])
  if (logit && !grepl("^(ln|log)", col, ignore.case = TRUE) && min(x, na.rm = TRUE) > 0 && max(x, na.rm = TRUE) > 50) x <- log(x)
  d[[newname]] <<- x
  dv <<- c(dv, newname)
}
addd("d_black", findcol(c("^pct_black$", "pct_black")))
addd("d_urban", findcol(c("^pct_urban$", "pct_urban")))
addd("d_forborn", findcol(c("^pct_for_born$", "for_born", "foreign")))
addd("d_over65", findcol(c("pct_over65", "pct_65", "over65", "age65", "65")))
addd("d_inc", findcol(c("ln_?med", "log_?med", "median_?inc", "med_?inc", "medinc", "income")), logit = TRUE)
addd("d_dens", findcol(c("ln_?dens", "log_?dens", "pop_?dens", "density", "dens")), logit = TRUE)
dist_vars <- c("reg_mw", "reg_s", "reg_w", dv)
cat("Sponsor controls:", paste(spons_vars, collapse = ","), "\n")
cat("District controls:", paste(dist_vars, collapse = ","), "\n")

bt <- function(v) paste0("`", v, "`")
bill_rhs <- if (length(comm)) paste(bt(comm), collapse = " + ") else "1"

run_ols <- function(sub, y, pooled) {
  rhs <- c("female", bt(comm), spons_vars, dist_vars)
  if (pooled) rhs <- c(rhs, "rep")
  fml <- as.formula(paste(y, "~", paste(rhs, collapse = " + "), "| congress + minor_f"))
  feols(fml, data = sub, cluster = ~clus)
}

# propensity score weights (estimated at sponsor-Congress level)
ps_w <- function(sub, covs) {
  covs <- covs[sapply(covs, function(v) sd(sub[[v]], na.rm = TRUE) > 0)]
  s <- sub[!duplicated(sub$clus), c("clus", "female", "congress", covs)]
  s <- s[complete.cases(s), ]
  fml <- as.formula(paste("female ~", paste(c(covs, "factor(congress)"), collapse = " + ")))
  m <- glm(fml, data = s, family = binomial("logit"))
  p <- pmin(pmax(fitted(m), 0.01), 0.99)
  s$ipw <- ifelse(s$female == 1, 1 / p, 1 / (1 - p))
  sub$ipw <- s$ipw[match(sub$clus, s$clus)]
  sub[!is.na(sub$ipw), ]
}
run_wls <- function(sub, y) {
  fml <- as.formula(paste(y, "~ female +", bill_rhs, "| congress + minor_f"))
  feols(fml, data = sub, weights = ~ipw, cluster = ~clus)
}

# margin of victory of elected candidate
if (has("MV1_democrat")) d$mv_elected <- abs(num(d$MV1_democrat)) else d$mv_elected <- abs(num(d$MV1_female))
d$MV <- num(d$MV1_female)
mvscale <- if (max(abs(d$MV), na.rm = TRUE) <= 1.5) 0.01 else 1
d$fxmv <- d$female * d$MV
d$mge <- if (has("mixed_gender_election")) num(d$mixed_gender_election) else as.integer(!is.na(d$MV))

D <- d[d$dem == 1, ]
R <- d[d$rep == 1, ]

out <- list()
safe <- function(expr) tryCatch(expr, error = function(e) { message("ERR: ", conditionMessage(e)); NULL })

# ---------- OLS column 1 ----------
m_all_n <- safe(run_ols(d, "y_n", TRUE))
if (!is.null(m_all_n)) {
  out$female_sponsor_ncosponsors_all_ols <- coef(m_all_n)["female"]
  out$n_bills_ncosponsors_all_ols <- nobs(m_all_n)
  used <- d$clus[obs(m_all_n)]
  out$n_sponsor_terms_ncosponsors_all_ols <- length(unique(used))
}
m_rep_n <- safe(run_ols(R, "y_n", FALSE))
if (!is.null(m_rep_n)) out$female_sponsor_ncosponsors_rep_ols <- coef(m_rep_n)["female"]
m_dem_p <- safe(run_ols(D, "y_pct", FALSE))
if (!is.null(m_dem_p)) {
  out$female_sponsor_pct_opposite_dem_ols <- coef(m_dem_p)["female"]
  out$n_bills_pct_opposite_dem_ols <- nobs(m_dem_p)
}
m_rep_p <- safe(run_ols(R, "y_pct", FALSE))
if (!is.null(m_rep_p)) {
  out$female_sponsor_pct_opposite_rep_ols <- coef(m_rep_p)["female"]
  out$n_bills_pct_opposite_rep_ols <- nobs(m_rep_p)
}

# ---------- RD (column 2): Dem, pct opposite, bw = 24 ----------
safe({
  s <- D[D$mge == 1 & !is.na(D$MV) & abs(D$MV) < 24 * mvscale, ]
  m <- feols(y_pct ~ female + MV + fxmv | congress, data = s, cluster = ~clus)
  out$female_sponsor_pct_opposite_dem_rd <- coef(m)["female"]
})

# ---------- RD with IPW (column 3): Rep, n cosponsors, bw = 13 ----------
safe({
  s <- R[R$mge == 1 & !is.na(R$MV) & abs(R$MV) < 13 * mvscale, ]
  s <- ps_w(s, dist_vars)
  fml <- as.formula(paste("y_n ~ female + MV + fxmv +", bill_rhs, "| congress + minor_f"))
  m <- feols(fml, data = s, weights = ~ipw, cluster = ~clus)
  out$female_sponsor_ncosponsors_rep_rd_ipw <- coef(m)["female"]
})

# ---------- PS weighting, full sample ----------
safe({
  s <- ps_w(R, c(dist_vars, "mv_elected"))
  m <- run_wls(s, "y_pct")
  out$female_sponsor_pct_opposite_rep_ipw_district <- coef(m)["female"]
})
safe({
  s <- ps_w(R, c(dist_vars, "mv_elected", spons_vars))
  m <- run_wls(s, "y_n")
  out$female_sponsor_ncosponsors_rep_ipw_sponsor <- coef(m)["female"]
})
safe({
  s <- ps_w(D, c(dist_vars, "mv_elected", spons_vars))
  m <- run_wls(s, "y_pct")
  out$female_sponsor_pct_opposite_dem_ipw_sponsor <- coef(m)["female"]
})

for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, as.numeric(out[[k]])))
```
