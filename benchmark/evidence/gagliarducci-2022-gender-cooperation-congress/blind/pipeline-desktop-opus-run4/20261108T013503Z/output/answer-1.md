suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free/3 replication package/Data/AnalysisData/"
d <- tryCatch(haven::read_dta(paste0(base, "bills_analysis_101-111_replication.dta")), error = function(e) NULL)
if (is.null(d)) d <- readr::read_csv(paste0(base, "bills_analysis_101-111_replication.csv"), show_col_types = FALSE)
d <- as.data.frame(haven::zap_labels(d))
nm <- names(d)
num <- function(x) suppressWarnings(as.numeric(x))

# ---- public bills only ----
if ("private" %in% nm) {
  pv <- num(d$private)
  if (any(pv == 1, na.rm = TRUE)) d <- d[!(pv %in% 1), ]
}

# ---- basic variables ----
d$v2 <- num(d$v2)
d$sponsor_female <- num(d$sponsor_female)
if ("minor" %in% nm) d$minor <- num(d$minor) else d$minor <- 1

# sponsor-Congress cluster
id_parts <- list(d$v2)
for (v in c("sponsor_state_icpsr", "sponsor_state_abbrev", "sponsor_district", "sponsor_name")) {
  if (v %in% nm) id_parts[[length(id_parts) + 1]] <- as.character(d[[v]])
}
d$clus <- do.call(paste, c(id_parts, sep = "_"))

# ---- party ----
p <- d$sponsor_party
if (is.character(p) || is.factor(p)) {
  pu <- toupper(as.character(p))
  d$rep <- as.integer(grepl("^R|REP", pu))
  d$dem <- as.integer(grepl("^D|DEM", pu))
} else {
  p <- num(p)
  if (any(p == 100, na.rm = TRUE) && any(p == 200, na.rm = TRUE)) {
    d$dem <- as.integer(p %in% 100); d$rep <- as.integer(p %in% 200)
  } else {
    u <- sort(unique(p[!is.na(p)]))
    if (length(u) >= 2) {
      a <- u[1]; b <- u[length(u)]
      repval <- b
      if ("dwnom1" %in% nm) {
        dw <- num(d$dwnom1)
        if (mean(dw[p %in% a], na.rm = TRUE) > mean(dw[p %in% b], na.rm = TRUE)) repval <- a
      }
      demval <- if (repval == a) b else a
      d$rep <- as.integer(p %in% repval); d$dem <- as.integer(p %in% demval)
    } else {
      d$rep <- 0L; d$dem <- 1L
    }
  }
}
d$rep[is.na(d$sponsor_party)] <- NA
d$dem[is.na(d$sponsor_party)] <- NA

# ---- outcomes ----
d$ncos <- num(d$numb_cosponsors)
po <- num(d$pct_cosponsors_opposite)
if (max(po, na.rm = TRUE) <= 1.0001) po <- 100 * po
d$pctopp <- po

# ---- bill controls: committees of referral (minor topic as FE) ----
comm <- grep("^house_", names(d), value = TRUE)
for (v in comm) d[[v]] <- num(d[[v]])
comm <- comm[sapply(comm, function(v) { x <- d[[v]]; all(x %in% c(0, 1, NA)) && var(x, na.rm = TRUE) > 0 })]

# ---- sponsor controls ----
spc <- c()
if ("sponsor_age" %in% nm) { d$sp_age <- num(d$sponsor_age); spc <- c(spc, "sp_age") }
if ("sponsor_tenure_run" %in% nm) {
  d$sp_tenure <- num(d$sponsor_tenure_run); spc <- c(spc, "sp_tenure")
}
if ("rookie" %in% nm) {
  d$sp_rookie <- num(d$rookie); spc <- c(spc, "sp_rookie")
} else if ("sp_tenure" %in% names(d)) {
  mt <- min(d$sp_tenure, na.rm = TRUE)
  d$sp_rookie <- as.integer(d$sp_tenure <= mt); d$sp_rookie[is.na(d$sp_tenure)] <- NA
  spc <- c(spc, "sp_rookie")
}
if (all(c("comc", "comr") %in% nm)) {
  cc <- num(d$comc); cr <- num(d$comr)
  d$sp_leader <- as.integer((cc > 0 & !is.na(cc)) | (cr > 0 & !is.na(cr)))
  d$sp_leader[is.na(cc) & is.na(cr)] <- NA
  spc <- c(spc, "sp_leader")
} else if ("comc" %in% nm) {
  d$sp_leader <- as.integer(num(d$comc) > 0); spc <- c(spc, "sp_leader")
}
if ("black" %in% nm) { d$sp_black <- num(d$black); spc <- c(spc, "sp_black") }
if ("ivycoll" %in% nm) { d$sp_ivy <- num(d$ivycoll); spc <- c(spc, "sp_ivy") }
occs <- grep("^occ[0-9]+$", nm, value = TRUE)
for (v in occs) { d[[paste0("sp_", v)]] <- num(d[[v]]); spc <- c(spc, paste0("sp_", v)) }
if ("borninstate" %in% nm) { d$sp_born <- num(d$borninstate); spc <- c(spc, "sp_born") }
d$sp_nbills <- ave(rep(1, nrow(d)), d$clus, FUN = length)
spc <- c(spc, "sp_nbills")

# ---- district controls ----
dc <- c()
for (v in c("pct_black", "pct_urban", "pct_for_born")) if (v %in% nm) { d[[paste0("d_", v)]] <- num(d[[v]]); dc <- c(dc, paste0("d_", v)) }
o65 <- grep("65", nm, value = TRUE)
o65 <- o65[!grepl("^(sponsor|cosp|numb|house_)", o65)]
if (length(o65)) { d$d_over65 <- num(d[[o65[1]]]); dc <- c(dc, "d_over65") }
loglike <- function(vname, x) {
  if (!grepl("^(l|ln|log)", vname, ignore.case = TRUE) && min(x, na.rm = TRUE) > 0 && max(x, na.rm = TRUE) > 100) log(x) else x
}
inc <- grep("medinc|med_inc|median_inc|income", nm, value = TRUE, ignore.case = TRUE)
if (length(inc)) { d$d_lninc <- loglike(inc[1], num(d[[inc[1]]])); dc <- c(dc, "d_lninc") }
den <- grep("dens", nm, value = TRUE, ignore.case = TRUE)
if (length(den)) { d$d_lndens <- loglike(den[1], num(d[[den[1]]])); dc <- c(dc, "d_lndens") }
reg <- grep("^(region|south|northeast|north_east|midwest|mid_west|west|northcentral)", nm, value = TRUE, ignore.case = TRUE)
if (length(reg) == 1 && length(unique(na.omit(d[[reg]]))) > 2) {
  rf <- factor(d[[reg]])
  lv <- levels(rf)[-1]
  for (k in seq_along(lv)) { vn <- paste0("d_reg", k); d[[vn]] <- as.integer(rf == lv[k]); dc <- c(dc, vn) }
} else if (length(reg) >= 1) {
  for (k in seq_along(reg)) { vn <- paste0("d_reg", k); d[[vn]] <- num(d[[reg[k]]]); dc <- c(dc, vn) }
}

# margin of victory of the elected candidate
if ("MV1_democrat" %in% nm) {
  d$mv_elect <- abs(num(d$MV1_democrat))
} else {
  mvc <- grep("margin|^MV", nm, value = TRUE)
  mvc <- setdiff(mvc, c("MV1_female", "femaleXMV1_female"))
  d$mv_elect <- if (length(mvc)) abs(num(d[[mvc[1]]])) else NA
}

# RD running variable
d$mvf <- num(d$MV1_female)
d$mixed <- num(d$mixed_gender_election)
mvscale <- if (max(abs(d$mvf), na.rm = TRUE) > 1.5) 1 else 0.01

bt <- function(v) paste0("`", v, "`")
nonconst <- function(sub, vars) vars[sapply(vars, function(v) { x <- sub[[v]]; sum(!is.na(x)) > 0 && isTRUE(var(x, na.rm = TRUE) > 0) })]

# ---- OLS full spec ----
ols <- function(y, sub, add_party = FALSE) {
  ctrl <- c(comm, spc, dc)
  if (add_party) ctrl <- c(ctrl, "rep")
  ctrl <- nonconst(sub, ctrl)
  f <- as.formula(paste(y, "~ sponsor_female +", paste(bt(ctrl), collapse = " + "), "| v2 + minor"))
  feols(f, data = sub, cluster = ~clus)
}
nclus <- function(m, sub) {
  ix <- tryCatch(obs(m), error = function(e) NULL)
  if (is.null(ix)) return(NA)
  length(unique(sub$clus[ix]))
}

# ---- propensity score weights (sponsor-Congress level) ----
ipw_weights <- function(sub, covs) {
  s <- sub[!duplicated(sub$clus), c("clus", "sponsor_female", covs), drop = FALSE]
  s <- s[complete.cases(s), ]
  covs2 <- nonconst(s, covs)
  f <- as.formula(paste("sponsor_female ~", paste(bt(covs2), collapse = " + ")))
  g <- suppressWarnings(glm(f, data = s, family = binomial()))
  ps <- pmin(pmax(fitted(g), 1e-4), 1 - 1e-4)
  s$w <- ifelse(s$sponsor_female == 1, 1 / ps, 1 / (1 - ps))
  sub$w <- s$w[match(sub$clus, s$clus)]
  sub
}
ipw_reg <- function(y, sub, covs) {
  sub <- ipw_weights(sub, covs)
  sub <- sub[!is.na(sub$w), ]
  ctrl <- nonconst(sub, comm)
  rhs <- if (length(ctrl)) paste("+", paste(bt(ctrl), collapse = " + ")) else ""
  f <- as.formula(paste(y, "~ sponsor_female", rhs, "| v2 + minor"))
  feols(f, data = sub, weights = ~w, cluster = ~clus)
}

# ---- RD ----
rd_sample <- function(sub, hpp) {
  h <- hpp * mvscale
  sub[!is.na(sub$mixed) & sub$mixed == 1 & !is.na(sub$mvf) & abs(sub$mvf) <= h, ]
}
rd_reg <- function(y, sub, hpp) {
  s <- rd_sample(sub, hpp)
  feols(as.formula(paste(y, "~ sponsor_female + mvf + sponsor_female:mvf | v2")), data = s, cluster = ~clus)
}
rd_ipw_reg <- function(y, sub, hpp) {
  s <- rd_sample(sub, hpp)
  s <- ipw_weights(s, dc)
  s <- s[!is.na(s$w), ]
  ctrl <- nonconst(s, comm)
  rhs <- if (length(ctrl)) paste("+", paste(bt(ctrl), collapse = " + ")) else ""
  f <- as.formula(paste(y, "~ sponsor_female + mvf + sponsor_female:mvf", rhs, "| v2 + minor"))
  feols(f, data = s, weights = ~w, cluster = ~clus)
}

safe <- function(expr) tryCatch(expr, error = function(e) { message("ERROR: ", conditionMessage(e)); NULL })
cf <- function(m) if (is.null(m)) NA else unname(coef(m)["sponsor_female"])

dAll <- d[!is.na(d$sponsor_female), ]
dDem <- dAll[dAll$dem %in% 1, ]
dRep <- dAll[dAll$rep %in% 1, ]

res <- list()

m1 <- safe(ols("ncos", dAll, add_party = TRUE))
res$female_sponsor_ncosponsors_all_ols <- cf(m1)
res$n_bills_ncosponsors_all_ols <- if (is.null(m1)) NA else nobs(m1)
res$n_sponsor_terms_ncosponsors_all_ols <- if (is.null(m1)) NA else nclus(m1, dAll)

m2 <- safe(ols("ncos", dRep))
res$female_sponsor_ncosponsors_rep_ols <- cf(m2)

m3 <- safe(rd_ipw_reg("ncos", dRep, 13))
res$female_sponsor_ncosponsors_rep_rd_ipw <- cf(m3)

m4 <- safe(ipw_reg("ncos", dRep, c(dc, "mv_elect", spc)))
res$female_sponsor_ncosponsors_rep_ipw_sponsor <- cf(m4)

m5 <- safe(ols("pctopp", dDem))
res$female_sponsor_pct_opposite_dem_ols <- cf(m5)
res$n_bills_pct_opposite_dem_ols <- if (is.null(m5)) NA else nobs(m5)

m6 <- safe(rd_reg("pctopp", dDem, 24))
res$female_sponsor_pct_opposite_dem_rd <- cf(m6)

m7 <- safe(ipw_reg("pctopp", dDem, c(dc, "mv_elect", spc)))
res$female_sponsor_pct_opposite_dem_ipw_sponsor <- cf(m7)

m8 <- safe(ols("pctopp", dRep))
res$female_sponsor_pct_opposite_rep_ols <- cf(m8)
res$n_bills_pct_opposite_rep_ols <- if (is.null(m8)) NA else nobs(m8)

m9 <- safe(ipw_reg("pctopp", dRep, c(dc, "mv_elect")))
res$female_sponsor_pct_opposite_rep_ipw_district <- cf(m9)

ord <- c("female_sponsor_ncosponsors_all_ols", "female_sponsor_ncosponsors_rep_ols",
         "female_sponsor_ncosponsors_rep_rd_ipw", "female_sponsor_ncosponsors_rep_ipw_sponsor",
         "female_sponsor_pct_opposite_dem_ols", "female_sponsor_pct_opposite_dem_rd",
         "female_sponsor_pct_opposite_dem_ipw_sponsor", "female_sponsor_pct_opposite_rep_ols",
         "female_sponsor_pct_opposite_rep_ipw_district", "n_bills_ncosponsors_all_ols",
         "n_sponsor_terms_ncosponsors_all_ols", "n_bills_pct_opposite_dem_ols",
         "n_bills_pct_opposite_rep_ols")
for (k in ord) cat(sprintf("RESULT:%s=%s\n", k, format(res[[k]], digits = 10)))
