suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
f_dta <- file.path(base, "3 replication package/Replication files/Data/replication_data.dta")
f_csv <- file.path(base, "3 replication package/Replication files/Data/replication_data.csv")

d <- tryCatch(as.data.frame(zap_labels(read_dta(f_dta))), error = function(e) NULL)
if (is.null(d)) d <- as.data.frame(readr::read_csv(f_csv, show_col_types = FALSE))
nm <- names(d)
cat("Columns:\n"); print(nm)

pick <- function(cands) {
  for (c in cands) {
    if (c %in% nm) return(c)
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit)) return(hit[1])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# ---- Population (mean 1710-50) ----
popvar <- pick(c("pcmean", "pc0", "pop_mean", "population"))
cat("Population var:", popvar, "\n")
d$pop <- num(d[[popvar]])

is_count <- function(x) {
  x <- x[!is.na(x)]
  length(x) > 0 && all(abs(x - round(x)) < 1e-9) && max(x) > 1
}

# ---- Wrights per capita ----
wv <- pick(c("wrights_pc", "wright_pc", "wrights"))
d$w_raw <- num(d[[wv]])
if (is_count(d$w_raw)) {
  d$w_pc <- d$w_raw / d$pop * 10000
  cat("wrights treated as counts -> per 10,000\n")
} else {
  d$w_pc <- d$w_raw
  cat("wrights treated as already per capita\n")
}

# ---- Mills per capita ----
mv <- pick(c("mills_pc", "mill_pc", "mills"))
d$m_raw <- num(d[[mv]])
if (is_count(d$m_raw)) {
  d$m_pc <- d$m_raw / d$pop * 10000
  cat("mills treated as counts -> per 10,000\n")
} else {
  d$m_pc <- d$m_raw
  cat("mills treated as already per capita\n")
}
# If wrights were counts but mills were already per capita (or vice versa), rescale
# is irrelevant for significance but matters for coefficient units; keep both per 10,000
# only when both were raw counts. Report scales for diagnostics:
cat("Summary w_pc:\n"); print(summary(d$w_pc))
cat("Summary m_pc:\n"); print(summary(d$m_pc))

# ---- Controls ----
lat <- pick(c("latitude", "lat"))
lon <- pick(c("longitude", "lon"))
rug <- pick(c("dist_rug_mean", "rug_mean"))
elev <- pick(c("dist_elevation_mean", "elevation_mean"))
agri <- pick(c("suitmean", "agri_suit"))
past <- pick(c("dist_grass_mean", "grass_mean"))
wheatcont <- pick(c("wheat_tmean", "wheat_mean"))
prec <- pick(c("precip_mean_dist", "precip_mean"))
temp <- pick(c("temp_mean_dist", "temp_mean"))
harb <- pick(c("min_harbor", "min_harbour"))
lond <- pick(c("DIST_London", "dist_london"))
roman <- pick(c("min_dist_to_roman_rds", "min_dist_roman"))
navr <- pick(c("min_dist_2nav_rivers", "min_dist_nav_rivers"))
areav <- pick(c("area", "AREA"))
clus <- pick(c("GAZ_CNTY", "county", "gaz_cnty"))

# High wheat suitability indicator
wd_exist <- nm[grepl("wheat", nm, ignore.case = TRUE) & nm != wheatcont]
cat("Other wheat vars:", paste(wd_exist, collapse = ", "), "\n")
wd_cand <- NA_character_
for (v in wd_exist) {
  x <- num(d[[v]]); x <- x[!is.na(x)]
  if (length(x) && all(x %in% c(0, 1))) { wd_cand <- v; break }
}
if (!is.na(wd_cand)) {
  d$wheat_d <- num(d[[wd_cand]])
  cat("Using existing wheat dummy:", wd_cand, "\n")
} else {
  d$wheat_d <- as.numeric(num(d[[wheatcont]]) <= 5)
  cat("Constructed wheat dummy from", wheatcont, "<= 5\n")
}

# River suitability: rivers through ruggedness 2-6
rivs <- nm[grepl("^riv", nm, ignore.case = TRUE)]
cat("River vars:", paste(rivs, collapse = ", "), "\n")
rv <- NA_character_
for (p in c("^riv_rug26count$", "^riv_rug26", "riv_rug_?2_?6", "rug.*2.*6")) {
  h <- rivs[grepl(p, rivs, ignore.case = TRUE)]
  if (length(h)) { rv <- h[1]; break }
}
if (is.na(rv)) {
  # try to build from finer bins (e.g. riv_rug23count, riv_rug34count, ...)
  parts <- c("riv_rug23count", "riv_rug34count", "riv_rug45count", "riv_rug56count")
  if (all(parts %in% nm)) {
    d$riv_suit <- rowSums(sapply(parts, function(p) num(d[[p]])), na.rm = FALSE)
    rv <- "riv_suit"
  } else {
    h <- rivs[grepl("^riv_rug2", rivs)]
    rv <- if (length(h)) h[1] else rivs[1]
  }
}
cat("River suitability var:", rv, "\n")
d$riv_suit <- num(d[[rv]])
d$inst <- d$riv_suit * d$wheat_d

d$cl <- d[[clus]]
for (v in c(lat, lon, rug, elev, agri, past, prec, temp, harb, lond, roman, navr, areav)) {
  d[[v]] <- num(d[[v]])
}

geo <- c(lat, lon, rug, elev)
agr <- c(agri, "wheat_d", past)
cli <- c(prec, temp)
oth <- c("pop", harb, lond, roman, navr, areav)

# Sample: districts with Domesday mill data
s <- d[!is.na(d$m_pc) & !is.na(d$w_pc) & is.finite(d$m_pc) & is.finite(d$w_pc), ]
cat("N sample with mills:", nrow(s), "\n")

fml <- function(lhs, rhs) as.formula(paste(lhs, "~", paste(rhs, collapse = " + ")))

safe_coef <- function(expr, name = "m_pc") {
  tryCatch({ m <- expr; unname(coef(m)[name]) }, error = function(e) { cat("ERR:", conditionMessage(e), "\n"); NA })
}

ctl <- list(
  c1 = character(0),
  c2 = geo,
  c3 = c(geo, agr),
  c4 = c(geo, agr, cli),
  c5 = c(geo, agr, cli, oth)
)
res <- list()
for (k in names(ctl)) {
  rhs <- c("m_pc", ctl[[k]])
  m <- tryCatch(feols(fml("w_pc", rhs), data = s, cluster = ~cl), error = function(e) NULL)
  if (!is.null(m)) {
    cat("\n== Table 2", k, "==\n"); print(coeftable(m)["m_pc", ]); cat("nobs:", nobs(m), "\n")
    res[[k]] <- unname(coef(m)["m_pc"])
    if (k == "c1") nobs_t2 <- nobs(m)
  } else res[[k]] <- NA
}

# Table 3 col 5 OLS: full controls + river suitability
m35 <- tryCatch(feols(fml("w_pc", c("m_pc", "riv_suit", geo, agr, cli, oth)), data = s, cluster = ~cl),
                error = function(e) NULL)
ols35 <- if (!is.null(m35)) unname(coef(m35)["m_pc"]) else NA
if (!is.null(m35)) { cat("\n== Table 3 col5 OLS ==\n"); print(coeftable(m35)["m_pc", ]) }

# IV
run_iv <- function(ctrls) {
  ctrls <- unique(c("riv_suit", "wheat_d", ctrls))
  f <- as.formula(paste("w_pc ~", paste(ctrls, collapse = " + "), "| m_pc ~ inst"))
  m <- tryCatch(feols(f, data = s, cluster = ~cl), error = function(e) { cat("IV ERR:", conditionMessage(e), "\n"); NULL })
  if (is.null(m)) return(c(NA, NA))
  b <- unname(coef(m)["fit_m_pc"])
  Fs <- tryCatch({
    fs <- fitstat(m, "ivwald1")
    unname(fs[[1]]$stat)
  }, error = function(e) NA)
  if (is.na(Fs)) {
    Fs <- tryCatch({
      f1 <- m$iv_first_stage[[1]]
      t <- coeftable(f1)["inst", "t value"]; unname(t^2)
    }, error = function(e) NA)
  }
  cat("\nIV coef:", b, " first-stage F (clustered Wald):", Fs, "\n")
  c(b, Fs)
}
iv2 <- run_iv(character(0))
iv4 <- run_iv(c(geo, agr, cli))
iv6 <- run_iv(c(geo, agr, cli, oth))

if (!exists("nobs_t2")) nobs_t2 <- nrow(s)

out <- function(n, v) cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 10)))
out("watermills_table2_col1", res$c1)
out("watermills_table2_col2", res$c2)
out("watermills_table2_col3", res$c3)
out("watermills_table2_col4", res$c4)
out("watermills_table2_col5", res$c5)
out("watermills_ols_table3_col5", ols35)
out("watermills_iv_table3_col2", iv2[1])
out("watermills_iv_table3_col4", iv4[1])
out("watermills_iv_table3_col6", iv6[1])
out("first_stage_f_table3_col2", iv2[2])
out("first_stage_f_table3_col4", iv4[2])
out("first_stage_f_table3_col6", iv6[2])
out("n_districts_tables2_3", nobs_t2)
