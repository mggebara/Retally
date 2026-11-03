suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free"
f_dta <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.dta")
f_csv <- file.path(base, "3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv")

d <- tryCatch(read_dta(f_dta), error = function(e) NULL)
if (is.null(d)) d <- readr::read_csv(f_csv, show_col_types = FALSE, guess_max = 100000)
d <- as.data.frame(d)

# party coding (before zapping labels)
pty_raw <- d$sponsor_party
if (inherits(pty_raw, "haven_labelled")) {
  pty_lab <- as.character(haven::as_factor(pty_raw, levels = "default"))
} else pty_lab <- as.character(pty_raw)
pty_num <- suppressWarnings(as.numeric(as.character(haven::zap_labels(pty_raw))))
pl <- tolower(pty_lab)
is_dem <- grepl("^d|democ", pl) | (!is.na(pty_num) & pty_num == 100)
is_rep <- grepl("^r|repub", pl) | (!is.na(pty_num) & pty_num == 200)
d$party_grp <- ifelse(is_dem, "D", ifelse(is_rep, "R", "O"))

d <- haven::zap_labels(d)
d <- as.data.frame(lapply(d, function(x) if (inherits(x, "haven_labelled")) as.vector(x) else x))
nm <- names(d)
message("Columns: ", paste(nm, collapse = ", "))
message("Party table: "); print(table(d$party_grp, useNA = "ifany"))

findcol <- function(pats, exclude = character(0)) {
  for (p in pats) {
    h <- grep(p, nm, ignore.case = TRUE, value = TRUE)
    h <- setdiff(h, exclude)
    if (length(h) > 0) return(h[1])
  }
  NULL
}
isnum01 <- function(x) is.numeric(x) && all(na.omit(unique(x)) %in% c(0, 1))

# sample: public bills
if ("private" %in% nm) d <- d[is.na(d$private) | d$private == 0, ]
d$female <- as.numeric(d$sponsor_female)
d$v2 <- as.numeric(d$v2)

# cluster: sponsor x Congress
idcols <- intersect(c("sponsor_name", "sponsor_state_abbrev", "sponsor_district"), nm)
d$clus <- do.call(paste, c(d[idcols], list(d$v2, sep = "_")))

# outcomes
d$ncosp <- as.numeric(d$numb_cosponsors)
# paper: percent of cosponsors from the opposite party out of (cosponsors + 1),
# so bills with zero cosponsors are kept (value 0)
nopp <- as.numeric(d$numb_cosponsors_opposite)
nopp[is.na(nopp) & !is.na(d$ncosp) & d$ncosp == 0] <- 0
d$pctopp <- 100 * nopp / (d$ncosp + 1)

# bill characteristics: committee dummies + minor topic FE
comm <- grep("^house_", nm, value = TRUE)
comm <- comm[sapply(comm, function(v) isnum01(d[[v]]))]
for (v in comm) d[[v]][is.na(d[[v]])] <- 0
d$minor_f <- as.character(d$minor)
message("Committee dummies: ", length(comm))

# sponsor characteristics
spons <- c()
age <- findcol(c("^sponsor_age$")); if (!is.null(age)) spons <- c(spons, age)
ten <- findcol(c("^sponsor_tenure_run$", "tenure")); if (!is.null(ten)) spons <- c(spons, ten)
rk <- findcol(c("rookie", "freshman"))
if (is.null(rk) && !is.null(ten)) {
  d$rookie_gen <- as.numeric(d[[ten]] == min(d[[ten]], na.rm = TRUE)); rk <- "rookie_gen"
}
if (!is.null(rk)) spons <- c(spons, rk)
for (v in c("comc", "comr", "black", "ivycoll", "borninstate")) if (v %in% nm) spons <- c(spons, v)
lead <- findcol(c("leader", "chair_rank", "comleader"))
if (!is.null(lead) && !all(c("comc", "comr") %in% nm)) spons <- c(spons, lead)
occ <- grep("^occ[0-9]+$", nm, value = TRUE); spons <- c(spons, occ)
nb <- findcol(c("nbills", "numb_bills", "bills_spons", "tot.*bills", "total_bills"))
if (is.null(nb)) {
  d <- d %>% group_by(clus) %>% mutate(nbills_gen = n()) %>% ungroup() %>% as.data.frame()
  nb <- "nbills_gen"
}
spons <- unique(c(spons, nb))
message("Sponsor controls: ", paste(spons, collapse = ", "))

# district characteristics
distr <- c()
reg <- findcol(c("^region$", "census_region", "region"))
if (!is.null(reg)) {
  d$region_f <- as.character(d[[reg]])
}
for (v in c("pct_black", "pct_urban", "pct_for_born")) if (v %in% nm) distr <- c(distr, v)
o65 <- findcol(c("65", "over65", "elder", "old")); if (!is.null(o65)) distr <- c(distr, o65)
inc <- findcol(c("ln.*inc", "log.*inc", "income")); if (!is.null(inc)) distr <- c(distr, inc)
den <- findcol(c("ln.*dens", "log.*dens", "dens")); if (!is.null(den)) distr <- c(distr, den)
distr <- unique(distr)
message("District controls: ", paste(distr, collapse = ", "), " region: ", ifelse(is.null(reg), "none", reg))
distr_terms <- c(distr, if (!is.null(reg)) "factor(region_f)")

ff <- function(y, x, fe) as.formula(paste(y, "~", paste(x, collapse = " + "), "|", paste(fe, collapse = " + ")))

out <- list()
put <- function(k, v) { if (!is.null(v) && length(v) == 1 && is.finite(v)) out[[k]] <<- v }

run_ols <- function(y, sub, party_dummy = FALSE) {
  x <- c("female", comm, spons, distr_terms)
  if (party_dummy) x <- c(x, "factor(party_grp)")
  feols(ff(y, x, c("v2", "minor_f")), data = sub, cluster = ~clus)
}
nclus <- function(m, sub) length(unique(sub$clus[obs(m)]))

dD <- d[d$party_grp == "D", ]; dR <- d[d$party_grp == "R", ]

tryCatch({
  m <- run_ols("ncosp", d, TRUE)
  put("female_sponsor_ncosponsors_all_ols", coef(m)["female"])
  put("n_bills_ncosponsors_all_ols", nobs(m))
  put("n_sponsor_terms_ncosponsors_all_ols", nclus(m, d))
}, error = function(e) message("all ols: ", e$message))
tryCatch({
  m <- run_ols("ncosp", dR)
  put("female_sponsor_ncosponsors_rep_ols", coef(m)["female"])
}, error = function(e) message("rep ols: ", e$message))
tryCatch({
  m <- run_ols("pctopp", dD)
  put("female_sponsor_pct_opposite_dem_ols", coef(m)["female"])
  put("n_bills_pct_opposite_dem_ols", nobs(m))
}, error = function(e) message("dem pct ols: ", e$message))
tryCatch({
  m <- run_ols("pctopp", dR)
  put("female_sponsor_pct_opposite_rep_ols", coef(m)["female"])
  put("n_bills_pct_opposite_rep_ols", nobs(m))
}, error = function(e) message("rep pct ols: ", e$message))

# ---------- propensity scores (sponsor-Congress level) ----------
mvw <- findcol(c("^MV1$", "^MV$", "margin", "winmargin"), exclude = c("MV1_female", "MV1_democrat"))
if (is.null(mvw)) { d$mv_win <- abs(as.numeric(d$MV1_democrat)) } else d$mv_win <- abs(as.numeric(d[[mvw]]))
dD <- d[d$party_grp == "D", ]; dR <- d[d$party_grp == "R", ]

ps_weights <- function(sub, covs) {
  sp <- sub[!duplicated(sub$clus), c("clus", "female", setdiff(c(covs, if (!is.null(reg)) "region_f"), character(0))), drop = FALSE]
  sp <- sp[complete.cases(sp), ]
  rhs <- c(covs, if (!is.null(reg) && length(unique(sp$region_f)) > 1) "factor(region_f)")
  g <- glm(as.formula(paste("female ~", paste(rhs, collapse = " + "))), data = sp, family = binomial())
  sp$ps <- predict(g, type = "response")
  sp$w <- ifelse(sp$female == 1, 1 / sp$ps, 1 / (1 - sp$ps))
  sub$w <- sp$w[match(sub$clus, sp$clus)]
  sub[!is.na(sub$w), ]
}
run_ipw <- function(y, sub) {
  feols(ff(y, c("female", comm), c("v2", "minor_f")), data = sub, weights = ~w, cluster = ~clus)
}
tryCatch({
  s <- ps_weights(dR, c(distr, "mv_win", spons))
  m <- run_ipw("ncosp", s)
  put("female_sponsor_ncosponsors_rep_ipw_sponsor", coef(m)["female"])
}, error = function(e) message("rep ipw sponsor: ", e$message))
tryCatch({
  s <- ps_weights(dD, c(distr, "mv_win", spons))
  m <- run_ipw("pctopp", s)
  put("female_sponsor_pct_opposite_dem_ipw_sponsor", coef(m)["female"])
}, error = function(e) message("dem ipw sponsor: ", e$message))
tryCatch({
  s <- ps_weights(dR, c(distr, "mv_win"))
  m <- run_ipw("pctopp", s)
  put("female_sponsor_pct_opposite_rep_ipw_district", coef(m)["female"])
}, error = function(e) message("rep ipw district: ", e$message))

# ---------- RD ----------
d$MV <- as.numeric(d$MV1_female)
mvmax <- max(abs(d$MV), na.rm = TRUE)
sc <- if (mvmax <= 1.5) 0.01 else 1
rdbase <- d[!is.na(d$MV) & (if ("mixed_gender_election" %in% nm) d$mixed_gender_election == 1 else TRUE), ]
rdbase <- rdbase[!is.na(rdbase$mixed_gender_election) | !("mixed_gender_election" %in% nm), ]
tryCatch({
  h <- 24 * sc
  s <- rdbase[rdbase$party_grp == "D" & abs(rdbase$MV) <= h, ]
  m <- feols(pctopp ~ female + MV + female:MV | v2, data = s, cluster = ~clus)
  put("female_sponsor_pct_opposite_dem_rd", coef(m)["female"])
}, error = function(e) message("dem rd: ", e$message))
tryCatch({
  h <- 13 * sc
  s <- rdbase[rdbase$party_grp == "R" & abs(rdbase$MV) <= h, ]
  s <- ps_weights(s, distr)
  m <- feols(ff("ncosp", c("female", "MV", "female:MV", comm), c("v2", "minor_f")),
             data = s, weights = ~w, cluster = ~clus)
  put("female_sponsor_ncosponsors_rep_rd_ipw", coef(m)["female"])
}, error = function(e) message("rep rd ipw: ", e$message))

for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))