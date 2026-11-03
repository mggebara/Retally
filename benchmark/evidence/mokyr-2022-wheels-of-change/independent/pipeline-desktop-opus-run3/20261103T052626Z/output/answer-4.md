suppressPackageStartupMessages({
  library(haven)
  library(readr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/mokyr_2022_wheels_of_change.script-free/3 replication package/Replication files/Data"
dta_path <- file.path(base, "replication_data.dta")
csv_path <- file.path(base, "replication_data.csv")

df <- tryCatch({
  d <- haven::read_dta(dta_path)
  d <- haven::zap_labels(d)
  as.data.frame(d)
}, error = function(e) {
  as.data.frame(readr::read_csv(csv_path, show_col_types = FALSE))
})
cat("Loaded rows:", nrow(df), " cols:", ncol(df), "\n")

nm <- names(df)
pick <- function(cands, regex = NULL, required = TRUE) {
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit) > 0) return(hit[1])
  }
  if (!is.null(regex)) {
    hit <- nm[grepl(regex, nm, ignore.case = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  if (required) stop(paste("Column not found:", paste(cands, collapse = "/")))
  NA_character_
}

v_wr   <- pick(c("wrights"))
v_mill <- pick(c("mills", "watermills"))
v_pop  <- pick(c("pcmean", "pop_mean", "popmean"), regex = "^pc.*mean$")
v_lat  <- pick(c("latitude", "lat"))
v_lon  <- pick(c("longitude", "lon"))
v_rug  <- pick(c("dist_rug_mean", "rug_mean"))
v_elev <- pick(c("dist_elevation_mean", "elevation_mean"))
v_suit <- pick(c("suitmean", "agri_suit"))
v_wheat_raw <- pick(c("wheat_tmean", "wheat_mean"))
v_grass <- pick(c("dist_grass_mean", "grass_mean", "pasture_mean"))
v_prec <- pick(c("precip_mean_dist", "precip_mean"))
v_temp <- pick(c("temp_mean_dist", "temp_mean"))
v_harb <- pick(c("min_harbor", "min_harbour"))
v_lond <- pick(c("DIST_London", "dist_london"))
v_roman <- pick(c("min_dist_to_roman_rds"), regex = "roman")
v_nav  <- pick(c("min_dist_2nav_rivers"), regex = "nav")
v_area <- pick(c("area"))
v_cl   <- pick(c("GAZ_CNTY", "county"))
# River suitability: the paper uses the LENGTH of rivers through moderate ruggedness (TRI 2-6).
riv_cands <- nm[grepl("^riv_rug26", nm, ignore.case = TRUE)]
cat("River suitability candidates:", paste(riv_cands, collapse = ", "), "\n")
riv_len <- riv_cands[!grepl("count", riv_cands, ignore.case = TRUE)]
v_riv <- if (length(riv_len) > 0) riv_len[1] else pick(c("riv_rug26count"), regex = "^riv_rug26")
cat("Using river suitability column:", v_riv, "\n")

num <- function(x) suppressWarnings(as.numeric(x))

pop <- num(df[[v_pop]])
wr_raw <- num(df[[v_wr]])
mi_raw <- num(df[[v_mill]])
is_count <- function(x) { x <- x[!is.na(x)]; length(x) > 0 && all(abs(x - round(x)) < 1e-8) }
cat("Summary pop:\n"); print(summary(pop))
cat("Summary wrights raw:\n"); print(summary(wr_raw))

# Wrights are raw apprentice counts; population (pcmean) is stored in units of 10,000 people,
# so counts / pcmean is already wright apprentices per 10,000 people.
df$w_pc <- wr_raw / pop
cat("DEVIATION: wrights counts divided by mean population 1710-50 (pcmean, which is in units of 10,000 people) without an extra x10,000 factor, giving wright apprentices per 10,000 people\n")
if (is_count(mi_raw)) {
  df$m_pc <- mi_raw / pop
} else {
  df$m_pc <- mi_raw
}
cat("Summary w_pc:\n"); print(summary(df$w_pc))
cat("Summary m_pc:\n"); print(summary(df$m_pc))

df$lat <- num(df[[v_lat]]); df$lon <- num(df[[v_lon]])
df$rug <- num(df[[v_rug]]); df$elev <- num(df[[v_elev]])
df$suit <- num(df[[v_suit]])
df$wheat_cont <- num(df[[v_wheat_raw]])
df$wheat <- as.numeric(df$wheat_cont <= 5)
df$grass <- num(df[[v_grass]])
df$prec <- num(df[[v_prec]]); df$temp <- num(df[[v_temp]])
df$popm <- pop
df$harb <- num(df[[v_harb]]); df$lond <- num(df[[v_lond]])
df$roman <- num(df[[v_roman]]); df$nav <- num(df[[v_nav]])
df$areav <- num(df[[v_area]])
df$cl <- df[[v_cl]]
df$riv <- num(df[[v_riv]])
df$riv_wheat <- df$riv * df$wheat

geo <- c("lat", "lon", "rug", "elev")
# Table 2: wheat suitability enters as the mean GAEZ wheat suitability (continuous)
agr_t2 <- c("suit", "wheat_cont", "grass")
# Table 3: agricultural controls with wheat main effect entering separately (dummy)
agr <- c("suit", "grass")
clim <- c("prec", "temp")
oth <- c("popm", "harb", "lond", "roman", "nav", "areav")

allv <- c("w_pc", "m_pc", geo, "suit", "wheat_cont", "grass", clim, oth, "riv", "riv_wheat", "cl")
samp <- df[complete.cases(df[, allv]) & is.finite(df$w_pc) & is.finite(df$m_pc), ]
cat("Sample N:", nrow(samp), "\n")

ols <- function(ctrl) {
  rhs <- paste(c("m_pc", ctrl), collapse = " + ")
  feols(as.formula(paste("w_pc ~", rhs)), data = samp, cluster = ~cl)
}

m1 <- ols(character(0))
m2 <- ols(geo)
m3 <- ols(c(geo, agr_t2))
m4 <- ols(c(geo, agr_t2, clim))
m5 <- ols(c(geo, agr_t2, clim, oth))
m5r <- ols(c("riv", "wheat", geo, agr, clim, oth))

ivfit <- function(ctrl) {
  ctrl <- unique(c("riv", "wheat", ctrl))
  rhs <- paste(ctrl, collapse = " + ")
  f <- as.formula(paste("w_pc ~", rhs, "| m_pc ~ riv_wheat"))
  iv <- feols(f, data = samp, cluster = ~cl)
  fs <- feols(as.formula(paste("m_pc ~ riv_wheat +", rhs)), data = samp, cluster = ~cl)
  tt <- coef(fs)["riv_wheat"] / sqrt(diag(vcov(fs)))["riv_wheat"]
  list(iv = iv, F = unname(tt^2))
}

iv2 <- ivfit(character(0))
iv4 <- ivfit(c(geo, agr, clim))
iv6 <- ivfit(c(geo, agr, clim, oth))

print(etable(m1, m2, m3, m4, m5, m5r))
print(summary(iv6$iv))

b <- function(m) unname(coef(m)["m_pc"])
b_iv <- function(m) unname(coef(m)["fit_m_pc"])

cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", b(m1)))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", b(m2)))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", b(m3)))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", b(m4)))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", b(m5)))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", b(m5r)))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", b_iv(iv2$iv)))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", b_iv(iv4$iv)))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", b_iv(iv6$iv)))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.4f\n", iv2$F))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.4f\n", iv4$F))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.4f\n", iv6$F))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(m1)))
