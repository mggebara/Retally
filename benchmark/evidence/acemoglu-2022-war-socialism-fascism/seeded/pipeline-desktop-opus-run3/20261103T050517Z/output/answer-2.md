suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})

set.seed(42)

data_dir <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism"
raw <- haven::read_dta(file.path(data_dir, "fascism_db.dta"))
raw <- haven::zap_labels(raw)
df <- as.data.frame(raw)

# Standardize (Stata egen std: (x - mean)/sd over non-missing, sd with n-1)
zstd <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
}

base_vars <- c("psu1919_vv", "foots_pop6m", "fascist_violence", "fascist_branch",
               "fascist1921_vv", "fascist1924_vv",
               "lpop1911", "lpop2", "lpop3", "lpop4", "sh_pop_1911_be6",
               "larea", "centre_alt", "max_alt", "psu1913_vv",
               "veterans74_95", "veterans96_00", "ard_vol_pop6m", "cruent_d", "army_suppliers_d",
               "dlab", "shcrop", "landlord_ass",
               "ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")
for (v in base_vars) {
  if (v %in% names(df)) {
    df[[paste0("z_", v)]] <- zstd(df[[v]])
  } else {
    warning(paste("Missing variable:", v))
  }
}

# Dummy sets: d_reg* (regiment dummies) and province* (province dummies), as in Stata wildcards
is_num <- vapply(df, is.numeric, logical(1))
dreg_vars <- names(df)[startsWith(names(df), "d_reg") & is_num]
prov_vars <- names(df)[startsWith(names(df), "province") & is_num]
# Drop constant dummies (would be collinear with intercept anyway)
nonconst <- function(v) { x <- df[[v]]; length(unique(x[!is.na(x)])) > 1 }
dreg_vars <- dreg_vars[vapply(dreg_vars, nonconst, logical(1))]
prov_vars <- prov_vars[vapply(prov_vars, nonconst, logical(1))]

# Cluster variable: circondario1921 is a string identifier in the data; coercing it
# to numeric turned every value into NA. Keep it as a character/group id instead,
# treating empty strings as missing (as Stata does for string cluster variables).
cl <- df$circondario1921
if (is.numeric(cl)) {
  cl <- as.character(cl)
} else {
  cl <- trimws(as.character(cl))
  cl[cl == ""] <- NA
}
df$circondario1921 <- cl

spec1 <- c("z_lpop1911", "z_lpop2", "z_lpop3", "z_lpop4", "z_sh_pop_1911_be6")
spec2 <- c(spec1, "z_larea", "z_centre_alt", "z_max_alt")
spec3 <- c(spec2, "z_psu1913_vv")
spec4 <- c(spec3, "z_veterans74_95", "z_veterans96_00", "z_ard_vol_pop6m", "z_cruent_d", "z_army_suppliers_d")
spec5 <- c(spec4, "z_dlab", "z_shcrop", "z_landlord_ass")
spec6 <- c(spec5, "z_ind_workers", "z_ind_firms", "z_literacy", "z_elites", "z_bourgeoisie")
specs <- list(spec1, spec2, spec3, spec4, spec5, spec6)

bt <- function(x) paste0("`", x, "`")
ctrl_str <- function(i) paste(bt(c(specs[[i]], dreg_vars, prov_vars)), collapse = " + ")

vc <- ~circondario1921
ss <- ssc(adj = TRUE, cluster.adj = TRUE)

results <- list()
emit <- function(name, value) {
  if (!is.null(value) && length(value) == 1 && is.finite(value)) {
    results[[name]] <<- value
  }
}

n_clusters <- function(m, data) {
  idx <- obs(m)
  length(unique(data$circondario1921[idx]))
}

# --- Table I: first stage ---
fs_model <- function(i) {
  f <- as.formula(paste("z_psu1919_vv ~ z_foots_pop6m +", ctrl_str(i)))
  feols(f, data = df, vcov = vc, ssc = ss, notes = FALSE, warn = FALSE)
}

fs1 <- tryCatch(fs_model(1), error = function(e) { message("fs1: ", e$message); NULL })
if (!is.null(fs1)) {
  emit("first_stage_casualties_table1_col1", unname(coef(fs1)["z_foots_pop6m"]))
  emit("first_stage_casualties_table1_col1_se", unname(se(fs1)["z_foots_pop6m"]))
  emit("n_obs_main_sample", nobs(fs1))
  emit("n_clusters_main_sample", n_clusters(fs1, df))
}

fs6 <- tryCatch(fs_model(6), error = function(e) { message("fs6: ", e$message); NULL })
if (!is.null(fs6)) {
  b <- unname(coef(fs6)["z_foots_pop6m"])
  s <- unname(se(fs6)["z_foots_pop6m"])
  emit("first_stage_casualties_table1_col6", b)
  emit("first_stage_casualties_table1_col6_se", s)
  emit("first_stage_fstat_table1_col6", (b / s)^2)
}

# --- 2SLS ---
iv_model <- function(dep, i) {
  f <- as.formula(paste(dep, "~", ctrl_str(i), "| z_psu1919_vv ~ z_foots_pop6m"))
  feols(f, data = df, vcov = vc, ssc = ss, notes = FALSE, warn = FALSE)
}
get_iv <- function(m) {
  cn <- names(coef(m))
  k <- if ("fit_z_psu1919_vv" %in% cn) "fit_z_psu1919_vv" else "z_psu1919_vv"
  list(b = unname(coef(m)[k]), s = unname(se(m)[k]))
}

m <- tryCatch(iv_model("z_fascist_violence", 6), error = function(e) { message("viol: ", e$message); NULL })
if (!is.null(m)) {
  r <- get_iv(m)
  emit("iv_violence_table2_panelA_col6", r$b)
  emit("iv_violence_table2_panelA_col6_se", r$s)
}

m <- tryCatch(iv_model("z_fascist_branch", 6), error = function(e) { message("branch: ", e$message); NULL })
if (!is.null(m)) {
  r <- get_iv(m)
  emit("iv_branches_table2_panelC_col6", r$b)
  emit("iv_branches_table2_panelC_col6_se", r$s)
}

m <- tryCatch(iv_model("z_fascist1921_vv", 6), error = function(e) { message("v1921: ", e$message); NULL })
if (!is.null(m)) {
  r <- get_iv(m)
  emit("iv_fascist_vote1921_table3_panelA_col6", r$b)
  emit("iv_fascist_vote1921_table3_panelA_col6_se", r$s)
  emit("n_obs_fascist_vote1921", nobs(m))
  emit("n_clusters_fascist_vote1921", n_clusters(m, df))
}

m <- tryCatch(iv_model("z_fascist1924_vv", 1), error = function(e) { message("v1924c1: ", e$message); NULL })
if (!is.null(m)) {
  r <- get_iv(m)
  emit("iv_fascist_vote1924_table3_panelC_col1", r$b)
  emit("iv_fascist_vote1924_table3_panelC_col1_se", r$s)
}

m <- tryCatch(iv_model("z_fascist1924_vv", 6), error = function(e) { message("v1924c6: ", e$message); NULL })
if (!is.null(m)) {
  r <- get_iv(m)
  emit("iv_fascist_vote1924_table3_panelC_col6", r$b)
  emit("iv_fascist_vote1924_table3_panelC_col6_se", r$s)
}

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}
