suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
base <- file.path(root, "3 replication package", "Data", "AnalysisData")
d <- tryCatch(
  read_dta(file.path(base, "bills_analysis_101-111_replication.dta")),
  error = function(e) readr::read_csv(file.path(base, "bills_analysis_101-111_replication.csv"), show_col_types = FALSE)
)
d <- as.data.frame(zap_labels(d))
nm <- names(d)
cat("Rows:", nrow(d), "\n")
cat("Columns:", paste(nm, collapse = ", "), "\n")

has <- function(x) x %in% names(d)
num <- function(x) suppressWarnings(as.numeric(x))

# ---- sample: public bills only ----
if (has("private")) {
  pv <- num(d$private)
  d <- d[is.na(pv) | pv == 0, , drop = FALSE]
}
cat("Rows after private filter:", nrow(d), "\n")

# ---- party ----
p <- d$sponsor_party
if (is.character(p) || is.factor(p)) {
  p <- as.character(p)
  d$rep <- as.integer(grepl("^\\s*R", p, ignore.case = TRUE))
  d$dem <- as.integer(grepl("^\\s*D", p, ignore.case = TRUE))
} else {
  p <- num(p)
  if (any(p == 200, na.rm = TRUE)) {
    d$rep <- as.integer(p == 200); d$dem <- as.integer(p == 100)
  } else {
    d$rep <- as.integer(p == 1); d$dem <- as.integer(p == 0)
  }
}
print(table(d$sponsor_party, useNA = "ifany"))

# ---- ids ----
d$cong <- num(d$v2)
idparts <- intersect(c("v2", "sponsor_state_abbrev", "sponsor_district", "sponsor_term_served", "sponsor_name"), names(d))
d$cl <- do.call(paste, c(d[idparts], sep = "_"))
d$sponsor_female <- num(d$sponsor_female)

# ---- outcomes ----
d$ncosp <- num(d$numb_cosponsors)
# Paper: % opposite-party cosponsors out of (cosponsors + sponsor), i.e. divided by n+1,
# so bills with zero cosponsors are kept (value 0). Expressed in percentage points.
nopp <- num(d$numb_cosponsors_opposite)
nopp[is.na(nopp) & !is.na(d$ncosp) & d$ncosp == 0] <- 0
d$pctopp <- 100 * nopp / (d$ncosp + 1)
cat("pctopp summary:\n"); print(summary(d$pctopp))

# ---- bill controls ----
if (has("minor")) {
  mn <- as.character(d$minor); mn[is.na(mn)] <- "missing"; d$minor_f <- mn
} else d$minor_f <- "none"
comm <- grep("^house_", names(d), value = TRUE)
comm <- comm[sapply(comm, function(v) {
  x <- num(d[[v]]); ux <- unique(x[!is.na(x)])
  length(ux) == 2 && all(ux %in% c(0, 1)) && mean(is.na(x)) < 0.1
})]
for (v in comm) { x <- num(d[[v]]); x[is.na(x)] <- 0; d[[v]] <- x }

ok_ctrl <- function(v) {
  if (!has(v)) return(FALSE)
  x <- num(d[[v]])
  mean(is.na(x)) < 0.10 && isTRUE(sd(x, na.rm = TRUE) > 0)
}

# ---- sponsor controls ----
d$nbills_sp <- ave(rep(1, nrow(d)), d$cl, FUN = length)
if (has("rookie")) d$rookie_c <- num(d$rookie) else if (has("sponsor_rookie")) d$rookie_c <- num(d$sponsor_rookie) else if (has("sponsor_tenure_run")) d$rookie_c <- as.integer(num(d$sponsor_tenure_run) <= 1)
if (has("comc") || has("comr")) {
  a <- if (has("comc")) num(d$comc) else 0
  b <- if (has("comr")) num(d$comr) else 0
  a[is.na(a)] <- 0; b[is.na(b)] <- 0
  d$leader_c <- as.integer((a + b) > 0)
}
occ <- grep("^occ[0-9]+$", names(d), value = TRUE)
if (length(occ) > 0) occ <- occ[-1]
spons_cand <- c("sponsor_age", "sponsor_tenure_run", "rookie_c", "leader_c", "black", "ivycoll",
                "borninstate", occ, "nbills_sp")
spons <- spons_cand[sapply(spons_cand, ok_ctrl)]
for (v in spons) d[[v]] <- num(d[[v]])

# ---- district controls ----
sti <- if (has("sponsor_state_icpsr")) num(d$sponsor_state_icpsr) else rep(NA, nrow(d))
d$reg_mw <- as.integer(sti >= 21 & sti <= 37)
d$reg_s  <- as.integer(sti >= 40 & sti <= 56)
d$reg_w  <- as.integer(sti >= 61)
nn <- names(d)
pick1 <- function(pat) {
  v <- grep(pat, nn, value = TRUE, ignore.case = TRUE)
  v <- v[!grepl("cosp|numb_|_fem$|share|MV", v)]
  if (length(v) == 0) NA else v[1]
}
dvars <- c()
for (v in c("pct_black", "pct_urban", "pct_for_born")) if (ok_ctrl(v)) dvars <- c(dvars, v)
v65 <- pick1("65|over65|elder|old")
if (!is.na(v65) && ok_ctrl(v65)) dvars <- c(dvars, v65)
vinc <- pick1("inc")
if (!is.na(vinc) && ok_ctrl(vinc)) {
  x <- num(d[[vinc]])
  if (!grepl("ln|log", vinc) && min(x, na.rm = TRUE) > 0) d$linc_c <- log(x) else d$linc_c <- x
  dvars <- c(dvars, "linc_c")
}
vden <- pick1("dens")
if (!is.na(vden) && ok_ctrl(vden)) {
  x <- num(d[[vden]])
  if (!grepl("ln|log", vden) && min(x, na.rm = TRUE) > 0) d$lden_c <- log(x) else d$lden_c <- x
  dvars <- c(dvars, "lden_c")
}
for (v in dvars) d[[v]] <- num(d[[v]])
dist <- c(dvars, c("reg_mw", "reg_s", "reg_w")[sapply(c("reg_mw", "reg_s", "reg_w"), ok_ctrl)])
cat("Committees:", length(comm), " Sponsor ctrls:", paste(spons, collapse = ","), " District ctrls:", paste(dist, collapse = ","), "\n")

# ---- RD variables ----
d$mv <- num(d$MV1_female)
mvscale <- if (max(abs(d$mv), na.rm = TRUE) <= 1.0001) 0.01 else 1
d$femXmv <- d$sponsor_female * d$mv
d$mixed <- if (has("mixed_gender_election")) num(d$mixed_gender_election) else as.integer(!is.na(d$mv))
d$mv_el <- if (has("MV1_democrat")) abs(num(d$MV1_democrat)) else NA

results <- list()
put <- function(k, v) { if (!is.null(v) && length(v) == 1 && is.finite(v)) results[[k]] <<- v }

rhs_join <- function(v) if (length(v) == 0) "" else paste0(" + ", paste(v, collapse = " + "))

run_ols <- function(y, sub, pooled = FALSE) {
  ctr <- c(comm, spons, dist, if (pooled) "rep")
  f <- as.formula(paste0(y, " ~ sponsor_female", rhs_join(ctr), " | cong + minor_f"))
  feols(f, data = sub, cluster = ~cl)
}

ps_weights <- function(sub, vars) {
  s <- sub[!duplicated(sub$cl), , drop = FALSE]
  vars <- vars[sapply(vars, function(v) { x <- s[[v]]; !all(is.na(x)) && isTRUE(sd(x, na.rm = TRUE) > 0) })]
  f <- as.formula(paste0("sponsor_female ~ ", if (length(vars)) paste(vars, collapse = " + ") else "1"))
  g <- suppressWarnings(glm(f, data = s, family = binomial(), na.action = na.exclude))
  ph <- predict(g, newdata = s, type = "response")
  ph <- pmin(pmax(ph, 0.01), 0.99)
  w <- ifelse(s$sponsor_female == 1, 1 / ph, 1 / (1 - ph))
  w[match(sub$cl, s$cl)]
}

run_ipw <- function(y, sub, vars) {
  sub$w <- ps_weights(sub, vars)
  sub <- sub[!is.na(sub$w), , drop = FALSE]
  f <- as.formula(paste0(y, " ~ sponsor_female", rhs_join(comm), " | cong + minor_f"))
  feols(f, data = sub, weights = ~w, cluster = ~cl)
}

dall <- d[d$rep == 1 | d$dem == 1 | TRUE, , drop = FALSE]
drep <- d[d$rep == 1, , drop = FALSE]
ddem <- d[d$dem == 1, , drop = FALSE]

# 1, 10, 11: all OLS number of cosponsors
tryCatch({
  m <- run_ols("ncosp", dall, pooled = TRUE)
  put("female_sponsor_ncosponsors_all_ols", unname(coef(m)["sponsor_female"]))
  put("n_bills_ncosponsors_all_ols", nobs(m))
  put("n_sponsor_terms_ncosponsors_all_ols", length(unique(dall$cl[obs(m)])))
}, error = function(e) cat("err1:", conditionMessage(e), "\n"))

# 2: Rep OLS ncosp
tryCatch({
  m <- run_ols("ncosp", drep)
  put("female_sponsor_ncosponsors_rep_ols", unname(coef(m)["sponsor_female"]))
}, error = function(e) cat("err2:", conditionMessage(e), "\n"))

# 3: Rep RD with IPW, bandwidth 13
tryCatch({
  sub <- drep[drep$mixed == 1 & !is.na(drep$mv) & abs(drep$mv) <= 13 * mvscale, , drop = FALSE]
  sub$w <- ps_weights(sub, dist)
  sub <- sub[!is.na(sub$w), , drop = FALSE]
  f <- as.formula(paste0("ncosp ~ sponsor_female + mv + femXmv", rhs_join(comm), " | cong + minor_f"))
  m <- feols(f, data = sub, weights = ~w, cluster = ~cl)
  put("female_sponsor_ncosponsors_rep_rd_ipw", unname(coef(m)["sponsor_female"]))
}, error = function(e) cat("err3:", conditionMessage(e), "\n"))

# 4: Rep IPW, district + MV + sponsor
tryCatch({
  m <- run_ipw("ncosp", drep, c(dist, "mv_el", setdiff(spons, "nbills_sp")))
  put("female_sponsor_ncosponsors_rep_ipw_sponsor", unname(coef(m)["sponsor_female"]))
}, error = function(e) cat("err4:", conditionMessage(e), "\n"))

# 5, 12: Dem OLS pct opposite
tryCatch({
  m <- run_ols("pctopp", ddem)
  put("female_sponsor_pct_opposite_dem_ols", unname(coef(m)["sponsor_female"]))
  put("n_bills_pct_opposite_dem_ols", nobs(m))
}, error = function(e) cat("err5:", conditionMessage(e), "\n"))

# 6: Dem RD, bandwidth 24, no controls
tryCatch({
  sub <- ddem[ddem$mixed == 1 & !is.na(ddem$mv) & abs(ddem$mv) <= 24 * mvscale, , drop = FALSE]
  m <- feols(pctopp ~ sponsor_female + mv + femXmv | cong, data = sub, cluster = ~cl)
  put("female_sponsor_pct_opposite_dem_rd", unname(coef(m)["sponsor_female"]))
}, error = function(e) cat("err6:", conditionMessage(e), "\n"))

# 7: Dem IPW, district + MV + sponsor
tryCatch({
  m <- run_ipw("pctopp", ddem, c(dist, "mv_el", setdiff(spons, "nbills_sp")))
  put("female_sponsor_pct_opposite_dem_ipw_sponsor", unname(coef(m)["sponsor_female"]))
}, error = function(e) cat("err7:", conditionMessage(e), "\n"))

# 8, 13: Rep OLS pct opposite
tryCatch({
  m <- run_ols("pctopp", drep)
  put("female_sponsor_pct_opposite_rep_ols", unname(coef(m)["sponsor_female"]))
  put("n_bills_pct_opposite_rep_ols", nobs(m))
}, error = function(e) cat("err8:", conditionMessage(e), "\n"))

# 9: Rep IPW, district + MV
tryCatch({
  m <- run_ipw("pctopp", drep, c(dist, "mv_el"))
  put("female_sponsor_pct_opposite_rep_ipw_district", unname(coef(m)["sponsor_female"]))
}, error = function(e) cat("err9:", conditionMessage(e), "\n"))

for (k in names(results)) cat(sprintf("RESULT:%s=%.6f\n", k, results[[k]]))