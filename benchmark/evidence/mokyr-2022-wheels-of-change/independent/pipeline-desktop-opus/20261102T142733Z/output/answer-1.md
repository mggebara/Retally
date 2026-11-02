suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
f_dta <- file.path(base, "3 replication package/Replication files/Data/replication_data.dta")
f_csv <- file.path(base, "3 replication package/Replication files/Data/replication_data.csv")
d <- tryCatch(as.data.frame(haven::read_dta(f_dta)), error = function(e) NULL)
if (is.null(d)) d <- as.data.frame(readr::read_csv(f_csv, show_col_types = FALSE))
d <- as.data.frame(lapply(d, function(x) { if (inherits(x, "haven_labelled")) as.numeric(zap_labels(x)) else x }))
nm <- names(d)
cat("Columns:", paste(nm, collapse = ", "), "\n")

pick <- function(cands, required = TRUE) {
  for (c in cands) if (c %in% nm) return(c)
  low <- tolower(nm)
  for (c in cands) { i <- which(low == tolower(c)); if (length(i)) return(nm[i[1]]) }
  if (required) message("Missing column among: ", paste(cands, collapse = ","))
  NA_character_
}

# ---- Core variables ----
v_wr <- pick(c("wrights"))
v_ml <- pick(c("mills", "db_mills", "watermills"))
v_pop <- pick(c("pcmean", "pop_mean", "popmean"))
v_cl <- pick(c("GAZ_CNTY", "county", "gaz_cnty"))

isint <- function(x) { x <- x[!is.na(x)]; length(x) > 0 && all(abs(x - round(x)) < 1e-8) }
pop <- as.numeric(d[[v_pop]])
wr <- as.numeric(d[[v_wr]])
ml <- as.numeric(d[[v_ml]])
# Convert counts to per 10,000 people if the variables look like raw counts
if (isint(wr) && max(wr, na.rm = TRUE) > 5) wr <- wr / pop * 10000
if (isint(ml) && max(ml, na.rm = TRUE) > 5) ml <- ml / pop * 10000
d$y_wr <- wr
d$x_ml <- ml
cat("Summary wrights pc:", summary(d$y_wr), "\n")
cat("Summary mills pc:", summary(d$x_ml), "\n")

# ---- Controls ----
c_geo <- na.omit(c(pick(c("latitude")), pick(c("longitude")),
                   pick(c("dist_rug_mean", "rug_mean", "ruggedness")),
                   pick(c("dist_elevation_mean", "elevation_mean"))))

# wheat suitability: high wheat indicator (mean GAEZ category <= 5)
wd <- NA_character_
for (c in c("wheat_suit", "high_wheat", "wheat_high", "wheat_dummy", "wheat5", "wheat_d", "hwheat")) {
  if (c %in% nm) { wd <- c; break }
}
if (is.na(wd)) {
  wcol <- pick(c("wheat_tmean", "wheat_mean"))
  d$wheat_hi <- as.numeric(d[[wcol]] <= 5)
} else {
  x <- d[[wd]]
  if (all(x[!is.na(x)] %in% c(0, 1))) d$wheat_hi <- x else d$wheat_hi <- as.numeric(x <= 5)
}
cat("Wheat high share:", mean(d$wheat_hi, na.rm = TRUE), "\n")

c_agr <- na.omit(c(pick(c("suitmean", "agri_suit")), "wheat_hi", pick(c("dist_grass_mean", "grass_mean", "pasture_mean"))))
c_clim <- na.omit(c(pick(c("precip_mean_dist", "precip_mean")), pick(c("temp_mean_dist", "temp_mean"))))
c_oth <- na.omit(c(v_pop, pick(c("min_harbor", "min_harbour")), pick(c("DIST_London", "dist_london")),
                   pick(c("min_dist_to_roman_rds", "min_dist_roman")), pick(c("min_dist_2nav_rivers", "min_dist_nav_rivers")),
                   pick(c("area", "AREA"))))

# ---- River suitability: river length in terrain with ruggedness between 2 and 6 ----
rv <- NA_character_
cand <- nm[grepl("riv", nm, ignore.case = TRUE)]
cat("River columns:", paste(cand, collapse = ", "), "\n")
for (c in c("riv_rug26count", "riv_rug26", "riv_rug2_6count", "riv_rug26len", "riv_rug26length", "river_suit", "riv_suit")) {
  if (c %in% nm) { rv <- c; break }
}
if (is.na(rv)) {
  g <- cand[grepl("rug26", cand, ignore.case = TRUE)]
  if (length(g)) rv <- g[1]
}
if (is.na(rv)) {
  # try differences of cumulative bins, e.g. riv_rug06 - riv_rug02
  if (all(c("riv_rug06count", "riv_rug02count") %in% nm)) {
    d$riv_suit_c <- d$riv_rug06count - d$riv_rug02count; rv <- "riv_suit_c"
  } else if (all(c("riv_rug16count", "riv_rug12count") %in% nm)) {
    d$riv_suit_c <- d$riv_rug16count - d$riv_rug12count; rv <- "riv_suit_c"
  } else if (all(c("riv_rug23count", "riv_rug34count", "riv_rug45count", "riv_rug56count") %in% nm)) {
    d$riv_suit_c <- d$riv_rug23count + d$riv_rug34count + d$riv_rug45count + d$riv_rug56count; rv <- "riv_suit_c"
  } else {
    g <- cand[grepl("^riv_rug2", cand)]
    if (length(g)) rv <- g[1]
  }
}
cat("River suitability column used:", rv, "\n")
d$riv_suit <- as.numeric(d[[rv]])
d$riv_suit[is.na(d$riv_suit) & !is.na(d$x_ml)] <- 0
d$iv_z <- d$riv_suit * d$wheat_hi
d$cl <- d[[v_cl]]

# ---- Sample: districts with Domesday mills data ----
s <- d[!is.na(d$x_ml) & !is.na(d$y_wr) & !is.na(d[[v_pop]]), ]
cat("N sample:", nrow(s), "\n")

fml <- function(lhs, rhs) as.formula(paste(lhs, "~", paste(rhs, collapse = " + ")))
est_ols <- function(ctrl) {
  m <- feols(fml("y_wr", c("x_ml", ctrl)), data = s, cluster = ~cl)
  m
}

ctrl2 <- c_geo
ctrl3 <- c(c_geo, c_agr)
ctrl4 <- c(c_geo, c_agr, c_clim)
ctrl5 <- c(c_geo, c_agr, c_clim, c_oth)

m1 <- est_ols(character(0))
m2 <- est_ols(ctrl2)
m3 <- est_ols(ctrl3)
m4 <- est_ols(ctrl4)
m5 <- est_ols(ctrl5)
m5b <- est_ols(c(ctrl5, "riv_suit"))
for (m in list(m1, m2, m3, m4, m5, m5b)) print(coeftable(m)["x_ml", ])

est_iv <- function(ctrl) {
  ctrl <- unique(c("riv_suit", "wheat_hi", ctrl))
  f <- as.formula(paste("y_wr ~", paste(ctrl, collapse = " + "), "| x_ml ~ iv_z"))
  m <- feols(f, data = s, cluster = ~cl)
  # first stage clustered Wald F for the excluded instrument
  fs <- feols(fml("x_ml", c("iv_z", ctrl)), data = s, cluster = ~cl)
  tz <- coeftable(fs)["iv_z", "t value"]
  list(m = m, F = as.numeric(tz^2))
}
iv2 <- est_iv(character(0))
iv4 <- est_iv(ctrl4)
iv6 <- est_iv(ctrl5)
for (r in list(iv2, iv4, iv6)) { print(coeftable(r$m)["fit_x_ml", ]); cat("F:", r$F, "\n") }

b <- function(m, v = "x_ml") unname(coef(m)[v])
cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", b(m1)))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", b(m2)))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", b(m3)))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", b(m4)))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", b(m5)))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", b(m5b)))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", b(iv2$m, "fit_x_ml")))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", b(iv4$m, "fit_x_ml")))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", b(iv6$m, "fit_x_ml")))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.4f\n", iv2$F))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.4f\n", iv4$F))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.4f\n", iv6$F))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", as.integer(nobs(m5))))
