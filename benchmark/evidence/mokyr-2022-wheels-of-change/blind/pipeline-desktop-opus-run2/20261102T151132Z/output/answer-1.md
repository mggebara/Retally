suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
d <- as.data.frame(haven::read_dta(file.path(base, "3 replication package/Replication files/Data/replication_data.dta")))
d[] <- lapply(d, function(x) { if (inherits(x, "haven_labelled")) as.numeric(x) else x })
nm <- names(d)
cat("Columns:", paste(nm, collapse = ", "), "\n")

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  cat(sprintf("RESULT:%s=%s\n", name, format(as.numeric(val), digits = 10)))
}

# ---- per-capita construction ----
pop <- d$pcmean
is_count <- function(x) { x <- x[!is.na(x)]; length(x) > 0 && all(abs(x - round(x)) < 1e-8) }
if (is_count(d$wrights)) {
  d$wrights_pc <- d$wrights / pop * 10000
} else {
  d$wrights_pc <- d$wrights
  cat("DEVIATION: wrights appears already per capita; used as is\n")
}
if (is_count(d$mills)) {
  d$mills_pc <- d$mills / pop * 10000
} else {
  d$mills_pc <- d$mills
  cat("DEVIATION: mills appears already per capita; used as is\n")
}

d$wheat_suit <- as.numeric(d$wheat_tmean <= 5)

# ---- river suitability (rivers through ruggedness 2-6) ----
riv <- NULL
cands <- c("riv_rug26count", "riv_rug2_6count", "riv_rug206count", "riv_rug2060count", "riv_rug26")
hit <- cands[cands %in% nm]
if (length(hit) > 0) {
  riv <- d[[hit[1]]]; cat("River suitability variable:", hit[1], "\n")
} else {
  g <- grep("^riv_rug0?2.*0?6", nm, value = TRUE)
  if (length(g) > 0) {
    riv <- d[[g[1]]]; cat("River suitability variable (pattern):", g[1], "\n")
  } else if (all(c("riv_rug06count", "riv_rug02count") %in% nm)) {
    riv <- d$riv_rug06count - d$riv_rug02count
    cat("DEVIATION: river suitability built as riv_rug06count - riv_rug02count\n")
  } else {
    g2 <- grep("^riv_rug", nm, value = TRUE)
    cat("DEVIATION: no 2-6 river ruggedness variable found; available:", paste(g2, collapse = ", "), "\n")
    if (length(g2) > 0) riv <- d[[g2[1]]]
  }
}
d$riv_suit <- if (is.null(riv)) NA_real_ else as.numeric(riv)
d$iv_inst <- d$riv_suit * d$wheat_suit

# ---- controls ----
c_geo  <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
c_agr  <- c("suitmean", "wheat_suit", "dist_grass_mean")
c_clim <- c("precip_mean_dist", "temp_mean_dist")
c_oth  <- c("pcmean", "min_harbor", "DIST_London", "min_dist_to_roman_rds", "min_dist_2nav_rivers", "area")
allc <- c(c_geo, c_agr, c_clim, c_oth)

# ---- sample: districts with Domesday mills data ----
s <- d[!is.na(d$mills_pc) & is.finite(d$mills_pc) & !is.na(d$wrights_pc) & is.finite(d$wrights_pc), ]
cc <- complete.cases(s[, intersect(allc, names(s))])
if (sum(cc) < nrow(s)) cat("Note: dropping", nrow(s) - sum(cc), "rows with missing controls\n")
s <- s[cc, ]
cat("N sample:", nrow(s), "\n")

fml <- function(lhs, rhs) as.formula(paste(lhs, "~", paste(rhs, collapse = " + ")))
ols <- function(ctrl) {
  feols(fml("wrights_pc", c("mills_pc", ctrl)), data = s, cluster = ~GAZ_CNTY)
}

specs <- list(
  character(0),
  c_geo,
  c(c_geo, c_agr),
  c(c_geo, c_agr, c_clim),
  c(c_geo, c_agr, c_clim, c_oth)
)
t2 <- lapply(specs, ols)
for (i in 1:5) {
  emit(sprintf("watermills_table2_col%d", i), coef(t2[[i]])["mills_pc"])
}

# ---- Table 3 ----
ivc2 <- c("riv_suit", "wheat_suit")
ivc4 <- unique(c("riv_suit", c_geo, c_agr, c_clim))
ivc6 <- unique(c(ivc4, c_oth))
s3 <- s[!is.na(s$riv_suit), ]

ols3_5 <- tryCatch(feols(fml("wrights_pc", c("mills_pc", ivc6)), data = s3, cluster = ~GAZ_CNTY),
                   error = function(e) NULL)
emit("watermills_ols_table3_col5", if (is.null(ols3_5)) NA else coef(ols3_5)["mills_pc"])

ivfit <- function(ctrl) {
  f <- as.formula(paste("wrights_pc ~", paste(ctrl, collapse = " + "), "| mills_pc ~ iv_inst"))
  m <- tryCatch(feols(f, data = s3, cluster = ~GAZ_CNTY), error = function(e) NULL)
  fs <- tryCatch(feols(fml("mills_pc", c("iv_inst", ctrl)), data = s3, cluster = ~GAZ_CNTY),
                 error = function(e) NULL)
  b <- if (is.null(m)) NA else coef(m)["fit_mills_pc"]
  F <- NA
  if (!is.null(fs)) {
    tt <- coef(fs)["iv_inst"] / sqrt(diag(vcov(fs)))["iv_inst"]
    F <- as.numeric(tt^2)
  }
  list(b = b, F = F)
}
r2 <- ivfit(ivc2); r4 <- ivfit(ivc4); r6 <- ivfit(ivc6)
emit("watermills_iv_table3_col2", r2$b)
emit("watermills_iv_table3_col4", r4$b)
emit("watermills_iv_table3_col6", r6$b)
emit("first_stage_f_table3_col2", r2$F)
emit("first_stage_f_table3_col4", r4$F)
emit("first_stage_f_table3_col6", r6$F)
emit("n_districts_tables2_3", nobs(t2[[5]]))
