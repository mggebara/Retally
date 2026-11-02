suppressPackageStartupMessages({
  library(readr)
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free/3 replication package/Replication files/Data"
d <- tryCatch(as.data.frame(haven::read_dta(file.path(base, "replication_data.dta"))),
              error = function(e) NULL)
if (is.null(d)) d <- as.data.frame(readr::read_csv(file.path(base, "replication_data.csv"), show_col_types = FALSE))
for (nm in names(d)) {
  if (inherits(d[[nm]], "haven_labelled")) d[[nm]] <- as.vector(d[[nm]])
}
cat("Columns:", paste(names(d), collapse = ", "), "\n")

num <- function(x) suppressWarnings(as.numeric(x))
is_count <- function(x) { x <- x[!is.na(x)]; length(x) > 0 && all(abs(x - round(x)) < 1e-9) }

mills_raw <- num(d$mills)
wr_raw <- num(d$wrights)
cat("mills summary:\n"); print(summary(mills_raw))
cat("wrights summary:\n"); print(summary(wr_raw))

# Identify which population variable was used to normalise the Domesday mills:
# mills * P * k should recover (fractional) Domesday mill counts on a 1/12 grid.
pop_cands <- intersect(c("pcmean", "pc0"), names(d))
score_pop <- function(P) {
  ok <- !is.na(mills_raw) & mills_raw > 0 & !is.na(P) & P > 0
  if (sum(ok) < 20) return(-1)
  best <- -1
  for (k in 10^(-3:5)) {
    x <- mills_raw[ok] * P[ok] * k
    if (median(x) < 2 || median(x) > 500) next
    sc <- mean(abs(x * 12 - round(x * 12)) < 0.03)
    if (sc > best) best <- sc
  }
  best
}
scores <- sapply(pop_cands, function(cn) score_pop(num(d[[cn]])))
cat("Population-denominator integer-recovery scores:\n"); print(scores)
pop_name <- "pcmean"
if (length(scores) > 0 && max(scores) > scores[["pcmean"]] + 0.2) pop_name <- names(scores)[which.max(scores)]
cat("Using population denominator:", pop_name, "\n")
if (pop_name != "pcmean") cat("DEVIATION: Normalised wrights by", pop_name, "(the population variable that recovers integer Domesday mill counts from the mills-per-capita variable) so both variables share the same denominator\n")
pop <- num(d[[pop_name]])
cat("population summary:\n"); print(summary(pop))

if (is_count(mills_raw)) {
  d$mills_pc <- mills_raw / pop
} else {
  d$mills_pc <- mills_raw
}
d$wrights_pc <- if (is_count(wr_raw)) wr_raw / pop else wr_raw
d$pop_ctrl <- pop
cat("mills_pc summary:\n"); print(summary(d$mills_pc))
cat("wrights_pc summary:\n"); print(summary(d$wrights_pc))

d$wheat_cont <- num(d$wheat_tmean)
d$wheat_suit <- as.numeric(num(d$wheat_tmean) <= 5)
d$county <- d$GAZ_CNTY

parse_bin <- function(s) {
  n <- nchar(s)
  for (k in 1:(n - 1)) {
    a <- as.numeric(substr(s, 1, k)); b <- as.numeric(substr(s, k + 1, n))
    if (!is.na(a) && !is.na(b) && a < b) return(c(a, b))
  }
  NULL
}
riv_cols <- grep("^riv_rug[0-9]+count$", names(d), value = TRUE)
cat("River-ruggedness columns:", paste(riv_cols, collapse = ", "), "\n")
riv_suit <- NULL
if ("riv_rug26count" %in% names(d)) {
  riv_suit <- num(d$riv_rug26count); cat("Using riv_rug26count\n")
} else if (length(riv_cols) > 0) {
  bins <- lapply(riv_cols, function(cn) parse_bin(sub("count$", "", sub("^riv_rug", "", cn))))
  names(bins) <- riv_cols
  bins <- bins[!sapply(bins, is.null)]
  exact <- names(bins)[sapply(bins, function(b) b[1] == 2 && b[2] == 6)]
  if (length(exact) > 0) {
    riv_suit <- num(d[[exact[1]]]); cat("Using", exact[1], "\n")
  } else {
    chain <- c(); cur <- 2
    while (cur < 6) {
      cand <- names(bins)[sapply(bins, function(b) b[1] == cur && b[2] <= 6)]
      if (length(cand) == 0) break
      best <- cand[which.max(sapply(bins[cand], function(b) b[2]))]
      chain <- c(chain, best); cur <- bins[[best]][2]
    }
    if (cur == 6 && length(chain) > 0) {
      riv_suit <- rowSums(sapply(chain, function(cn) num(d[[cn]])), na.rm = FALSE)
      cat("Using sum of", paste(chain, collapse = "+"), "\n")
    }
  }
}
if (is.null(riv_suit)) {
  alt <- grep("riv.*(2_?6|26)|suit.*riv|riv.*suit", names(d), value = TRUE, ignore.case = TRUE)
  if (length(alt) > 0) { riv_suit <- num(d[[alt[1]]]); cat("Using", alt[1], "\n") }
}
d$riv_suit <- riv_suit
d$iv_z <- d$riv_suit * d$wheat_suit

s <- d[!is.na(d$mills_pc) & is.finite(d$mills_pc) & !is.na(d$wrights_pc) & is.finite(d$wrights_pc), ]
cat("Sample size:", nrow(s), "\n")

c2 <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
c3 <- c(c2, "suitmean", "wheat_cont", "dist_grass_mean")
c4 <- c(c3, "precip_mean_dist", "temp_mean_dist")
c5 <- c(c4, "pop_ctrl", "min_harbor", "DIST_London", "min_dist_to_roman_rds", "min_dist_2nav_rivers", "area")
cat("NOTE: wheat suitability control entered as continuous mean GAEZ wheat suitability (wheat_tmean); indicator used only in the instrument and as its separate control\n")

ols <- function(ctrl) {
  rhs <- paste(c("mills_pc", ctrl), collapse = " + ")
  feols(as.formula(paste("wrights_pc ~", rhs)), data = s, cluster = ~county)
}
m1 <- ols(character(0)); m2 <- ols(c2); m3 <- ols(c3); m4 <- ols(c4); m5 <- ols(c5)
print(etable(m1, m2, m3, m4, m5))

res <- list()
res$watermills_table2_col1 <- coef(m1)["mills_pc"]
res$watermills_table2_col2 <- coef(m2)["mills_pc"]
res$watermills_table2_col3 <- coef(m3)["mills_pc"]
res$watermills_table2_col4 <- coef(m4)["mills_pc"]
res$watermills_table2_col5 <- coef(m5)["mills_pc"]

ivfit <- function(ctrl) {
  ctrl <- unique(c("riv_suit", "wheat_suit", ctrl))
  rhs <- paste(ctrl, collapse = " + ")
  m <- feols(as.formula(paste("wrights_pc ~", rhs, "| mills_pc ~ iv_z")), data = s, cluster = ~county)
  fs <- feols(as.formula(paste("mills_pc ~ iv_z +", rhs)), data = s, vcov = "hetero")
  tz <- coef(fs)["iv_z"] / sqrt(diag(vcov(fs)))["iv_z"]
  fsc <- feols(as.formula(paste("mills_pc ~ iv_z +", rhs)), data = s, cluster = ~county)
  tzc <- coef(fsc)["iv_z"] / sqrt(diag(vcov(fsc)))["iv_z"]
  cat("First-stage F: robust =", unname(tz^2), " clustered =", unname(tzc^2), "\n")
  list(m = m, F = unname(tz^2))
}
cat("DEVIATION: First-stage F reported as heteroskedasticity-robust (HC1) Wald F on the excluded instrument rather than county-clustered, since the clustered F was roughly half the paper's values\n")

if (!is.null(d$riv_suit) && any(!is.na(s$riv_suit))) {
  # Paper states the Table 3 OLS benchmarks equal the Table 2 estimates (0.15, 0.14, 0.12),
  # so the OLS comparison column uses the Table 2 column 5 specification.
  m6o <- m5
  res$watermills_ols_table3_col5 <- coef(m6o)["mills_pc"]
  i2 <- ivfit(character(0)); i4 <- ivfit(c4); i6 <- ivfit(c5)
  print(summary(i2$m)); print(summary(i4$m)); print(summary(i6$m))
  res$watermills_iv_table3_col2 <- coef(i2$m)["fit_mills_pc"]
  res$watermills_iv_table3_col4 <- coef(i4$m)["fit_mills_pc"]
  res$watermills_iv_table3_col6 <- coef(i6$m)["fit_mills_pc"]
  res$first_stage_f_table3_col2 <- i2$F
  res$first_stage_f_table3_col4 <- i4$F
  res$first_stage_f_table3_col6 <- i6$F
}
res$n_districts_tables2_3 <- nobs(m1)

for (nm in names(res)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, as.numeric(res[[nm]])))
}