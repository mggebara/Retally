suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free"
f_dta <- file.path(base, "3 replication package/Replication files/Data/replication_data.dta")
f_csv <- file.path(base, "3 replication package/Replication files/Data/replication_data.csv")

if (file.exists(f_dta)) {
  d <- as.data.frame(haven::zap_labels(haven::read_dta(f_dta)))
} else {
  d <- as.data.frame(readr::read_csv(f_csv, show_col_types = FALSE))
}
cat("Columns:\n"); print(names(d))
cat("Rows:", nrow(d), "\n")

nm <- names(d)
pick <- function(cands, required = TRUE) {
  for (c in cands) if (c %in% nm) return(c)
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit)) return(hit[1])
  }
  if (required) stop("Missing column among: ", paste(cands, collapse = ", "))
  NA_character_
}

is_intlike <- function(x) {
  x <- x[!is.na(x)]
  length(x) > 0 && all(abs(x - round(x)) < 1e-8)
}

# ---- population (mean population 1710-50, HYDE) ----
pop_var <- pick(c("pc0", "pcmean"))
cat("Population variable used:", pop_var, "\n")
d$pop <- d[[pop_var]]

# ---- dependent variable and regressor in per-capita terms ----
w_var <- pick(c("wrights"))
m_var <- pick(c("mills"))
w_raw <- d[[w_var]]; m_raw <- d[[m_var]]
cat("wrights summary:\n"); print(summary(w_raw))
cat("mills summary:\n"); print(summary(m_raw))
cat("pop summary:\n"); print(summary(d$pop))

# counts -> per capita (per 10,000 people); the scale factor cancels in the slope
if (is_intlike(w_raw)) d$w_pc <- w_raw / d$pop * 10000 else d$w_pc <- w_raw
if (is_intlike(m_raw)) d$m_pc <- m_raw / d$pop * 10000 else d$m_pc <- m_raw

# ---- controls ----
lat   <- pick(c("latitude"))
lon   <- pick(c("longitude"))
rug   <- pick(c("dist_rug_mean"))
elev  <- pick(c("dist_elevation_mean"))
agri  <- pick(c("suitmean"))
wheat <- pick(c("wheat_tmean"))
past  <- pick(c("dist_grass_mean"))
prec  <- pick(c("precip_mean_dist"))
temp  <- pick(c("temp_mean_dist"))
harb  <- pick(c("min_harbor"))
lond  <- pick(c("DIST_London"))
roman <- pick(c("min_dist_to_roman_rds"))
navr  <- pick(c("min_dist_2nav_rivers"))
area  <- pick(c("area"))
clus  <- pick(c("GAZ_CNTY"))

# high wheat suitability indicator: mean category <= 5 (lower = more suitable)
d$wheat_hi <- as.numeric(d[[wheat]] <= 5)

# ---- river suitability: length of rivers with ruggedness between 2 and 6 ----
riv_cands <- nm[grepl("riv", nm, ignore.case = TRUE)]
cat("River-related columns:\n"); print(riv_cands)
riv_var <- NA_character_
pref <- riv_cands[grepl("rug26|rug2_6|rug_2_6|26", riv_cands)]
if (length(pref)) {
  lenp <- pref[grepl("len|length", pref, ignore.case = TRUE)]
  riv_var <- if (length(lenp)) lenp[1] else pref[1]
  d$riv_suit <- d[[riv_var]]
} else {
  # build from contiguous unit bins 2-3, 3-4, 4-5, 5-6 if available
  bins <- c("riv_rug23count", "riv_rug34count", "riv_rug45count", "riv_rug56count")
  if (all(bins %in% nm)) {
    riv_var <- paste(bins, collapse = "+")
    d$riv_suit <- rowSums(d[, bins], na.rm = FALSE)
  } else {
    alt <- riv_cands[grepl("rug2", riv_cands)]
    if (!length(alt)) stop("Cannot identify river suitability variable")
    riv_var <- alt[1]
    d$riv_suit <- d[[riv_var]]
  }
}
cat("River suitability variable used:", riv_var, "\n")
d$instr <- d$riv_suit * d$wheat_hi

# ---- sample: districts with Domesday mill data ----
d$cl <- d[[clus]]
ds <- d[!is.na(d$m_pc) & is.finite(d$m_pc) & !is.na(d$w_pc) & is.finite(d$w_pc), ]
cat("Sample size:", nrow(ds), "\n")

main_geo <- c(lat, lon, rug, elev)
agr      <- c(agri, "wheat_hi", past)
clim     <- c(prec, temp)
other    <- c("pop", harb, lond, roman, navr, area)

fm <- function(lhs, rhs) as.formula(paste(lhs, "~", if (length(rhs)) paste(rhs, collapse = " + ") else "1"))

# keep sample fixed across columns: complete cases on all variables used
allv <- unique(c("w_pc", "m_pc", main_geo, agr, clim, other, "riv_suit", "instr", "cl"))
cc <- complete.cases(ds[, allv])
if (sum(cc) < nrow(ds)) cat("Note: dropping", nrow(ds) - sum(cc), "rows with missing covariates\n")
ds <- ds[cc, ]
n_obs <- nrow(ds)

# ---- Table 2 ----
specs <- list(
  c(),
  main_geo,
  c(main_geo, agr),
  c(main_geo, agr, clim),
  c(main_geo, agr, clim, other)
)
t2 <- sapply(seq_along(specs), function(k) {
  m <- feols(fm("w_pc", c("m_pc", specs[[k]])), data = ds, cluster = ~cl)
  print(summary(m))
  coef(m)["m_pc"]
})

# ---- Table 3 OLS col 5 ----
m35 <- feols(fm("w_pc", c("m_pc", main_geo, agr, clim, other, "riv_suit")), data = ds, cluster = ~cl)
print(summary(m35))
b_ols35 <- coef(m35)["m_pc"]

# ---- Table 3 IV ----
iv_spec <- list(
  c("riv_suit", "wheat_hi"),
  unique(c("riv_suit", main_geo, agr, clim)),
  unique(c("riv_suit", main_geo, agr, clim, other))
)
iv_b <- c(); iv_f <- c()
for (k in seq_along(iv_spec)) {
  ctrl <- iv_spec[[k]]
  f_iv <- as.formula(paste("w_pc ~", paste(ctrl, collapse = " + "), "| m_pc ~ instr"))
  miv <- feols(f_iv, data = ds, cluster = ~cl)
  print(summary(miv))
  iv_b[k] <- coef(miv)["fit_m_pc"]
  fs <- feols(fm("m_pc", c("instr", ctrl)), data = ds, cluster = ~cl)
  tt <- coef(fs)["instr"] / sqrt(diag(vcov(fs)))["instr"]
  iv_f[k] <- as.numeric(tt^2)
}

cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", t2[1]))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", t2[2]))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", t2[3]))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", t2[4]))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", t2[5]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", b_ols35))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", iv_b[1]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", iv_b[2]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", iv_b[3]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.6f\n", iv_f[1]))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.6f\n", iv_f[2]))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.6f\n", iv_f[3]))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", n_obs))
