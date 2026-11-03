suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
f_dta <- file.path(base, "3 replication package/Replication files/Data/replication_data.dta")
f_csv <- file.path(base, "3 replication package/Replication files/Data/replication_data.csv")

d <- tryCatch(as.data.frame(haven::zap_labels(haven::read_dta(f_dta))),
              error = function(e) NULL)
if (is.null(d)) d <- as.data.frame(readr::read_csv(f_csv, show_col_types = FALSE))

message("Columns: ", paste(names(d), collapse = ", "))

num <- function(x) suppressWarnings(as.numeric(x))
is_intlike <- function(x) { x <- x[!is.na(x)]; length(x) > 0 && all(abs(x - round(x)) < 1e-9) }

pop <- num(d$pcmean)

# Dependent variable: wright apprentices per capita
w <- num(d$wrights)
if (is_intlike(w) && max(w, na.rm = TRUE) > 1) w <- w / pop
d$y_wr <- w

# Domesday watermills per capita
m <- num(d$mills)
if (is_intlike(m) && max(m, na.rm = TRUE) > 1) m <- m / pop
d$x_mills <- m
message("mills summary: "); print(summary(num(d$mills)), file = stderr())

# High wheat suitability indicator
wt <- num(d$wheat_tmean)
uw <- unique(wt[!is.na(wt)])
if (all(uw %in% c(0, 1))) {
  d$wheat_suit <- wt
} else {
  d$wheat_suit <- as.numeric(wt <= 5)
}

# River suitability: length of rivers with ruggedness between 2 and 6
nm <- names(d)
cand <- nm[grepl("^riv_?rug_?0?2_?0?6", nm, ignore.case = TRUE)]
if (length(cand) == 0) cand <- nm[grepl("rug.*2.?6", nm, ignore.case = TRUE) & grepl("riv", nm, ignore.case = TRUE)]
if (length(cand) == 0) cand <- nm[grepl("riv.*suit|suit.*riv", nm, ignore.case = TRUE)]
if (length(cand) == 0) {
  # try to build from finer bins riv_rugABcount covering 2-6
  bins <- c("riv_rug23count", "riv_rug34count", "riv_rug45count", "riv_rug56count")
  if (all(bins %in% nm)) {
    d$riv_suit <- rowSums(sapply(bins, function(b) num(d[[b]])))
  } else {
    stop("No river-suitability (ruggedness 2-6) variable found")
  }
} else {
  # prefer one containing 'count' or length
  pick <- cand[grepl("count|len", cand, ignore.case = TRUE)]
  if (length(pick) == 0) pick <- cand
  message("River suitability variable: ", pick[1])
  d$riv_suit <- num(d[[pick[1]]])
}
d$iv_inst <- d$riv_suit * d$wheat_suit

for (v in c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean", "suitmean",
            "dist_grass_mean", "precip_mean_dist", "temp_mean_dist", "pcmean", "min_harbor",
            "DIST_London", "min_dist_to_roman_rds", "min_dist_2nav_rivers", "area")) {
  d[[v]] <- num(d[[v]])
}
d$cnty <- as.character(d$GAZ_CNTY)

geo  <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
agr  <- c("suitmean", "wheat_suit", "dist_grass_mean")
clim <- c("precip_mean_dist", "temp_mean_dist")
oth  <- c("pcmean", "min_harbor", "DIST_London", "min_dist_to_roman_rds", "min_dist_2nav_rivers", "area")

allv <- unique(c("y_wr", "x_mills", geo, agr, clim, oth, "riv_suit", "iv_inst", "cnty"))
s <- d[complete.cases(d[, allv]) & is.finite(d$x_mills) & is.finite(d$y_wr), ]
message("Sample size: ", nrow(s))

cl <- ~cnty
rhs <- function(v) if (length(v) == 0) "1" else paste(v, collapse = " + ")

ols <- function(ctrl) {
  feols(as.formula(paste("y_wr ~ x_mills +", rhs(ctrl))), data = s, cluster = cl)
}
m1 <- feols(y_wr ~ x_mills, data = s, cluster = cl)
m2 <- ols(geo)
m3 <- ols(c(geo, agr))
m4 <- ols(c(geo, agr, clim))
m5 <- ols(c(geo, agr, clim, oth))

m3_5 <- ols(unique(c(geo, agr, clim, oth, "riv_suit")))

ivm <- function(ctrl) {
  ctrl <- unique(c("riv_suit", "wheat_suit", ctrl))
  feols(as.formula(paste("y_wr ~", rhs(ctrl), "| x_mills ~ iv_inst")), data = s, cluster = cl)
}
iv2 <- ivm(character(0))
iv4 <- ivm(c(geo, agr, clim))
iv6 <- ivm(c(geo, agr, clim, oth))

fs_f <- function(mod) {
  v <- tryCatch(fitstat(mod, "ivwald1")[[1]]$stat, error = function(e) NA)
  if (is.null(v) || is.na(v)) v <- tryCatch(fitstat(mod, "ivf1")[[1]]$stat, error = function(e) NA)
  as.numeric(v)
}

b <- function(mod, nmv = "x_mills") {
  cf <- coef(mod)
  k <- if (nmv %in% names(cf)) nmv else paste0("fit_", nmv)
  as.numeric(cf[k])
}

cat(sprintf("RESULT:watermills_table2_col1=%.10g\n", b(m1)))
cat(sprintf("RESULT:watermills_table2_col2=%.10g\n", b(m2)))
cat(sprintf("RESULT:watermills_table2_col3=%.10g\n", b(m3)))
cat(sprintf("RESULT:watermills_table2_col4=%.10g\n", b(m4)))
cat(sprintf("RESULT:watermills_table2_col5=%.10g\n", b(m5)))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.10g\n", b(m3_5)))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.10g\n", b(iv2)))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.10g\n", b(iv4)))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.10g\n", b(iv6)))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.10g\n", fs_f(iv2)))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.10g\n", fs_f(iv4)))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.10g\n", fs_f(iv6)))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", as.integer(nobs(m5))))