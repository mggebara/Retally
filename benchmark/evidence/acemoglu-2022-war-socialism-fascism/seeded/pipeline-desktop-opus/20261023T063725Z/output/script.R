suppressPackageStartupMessages({
  library(haven)
})
set.seed(42)

data_dir <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism"
df <- as.data.frame(zap_labels(read_dta(file.path(data_dir, "fascism_db.dta"))))

# ---------------------------------------------------------------------------
# Standardize (Stata egen std: mean 0, sd 1 over all non-missing obs)
# ---------------------------------------------------------------------------
zstd <- function(x) {
  x <- as.numeric(x)
  (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
}

outcomes <- c("fascist_violence", "fascist_branch", "fascist1921_vv", "fascist1924_vv")
base_vars <- c("psu1919_vv", "foots_pop6m",
               "lpop1911", "lpop2", "lpop3", "lpop4", "sh_pop_1911_be6",
               "larea", "centre_alt", "max_alt",
               "psu1913_vv",
               "veterans74_95", "veterans96_00", "ard_vol_pop6m", "cruent_d", "army_suppliers_d",
               "dlab", "shcrop", "landlord_ass",
               "ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")
for (v in c(outcomes, base_vars)) {
  if (!v %in% names(df)) stop(paste("Missing variable:", v))
  df[[paste0("z_", v)]] <- zstd(df[[v]])
}

df$cluster_id <- as.character(df$circondario1921)
df$cluster_id[df$cluster_id == "" ] <- NA

# Regiment dummies (d_reg*) and province dummies (province*)
is_num <- sapply(df, is.numeric)
reg_d  <- names(df)[grepl("^d_reg", names(df)) & is_num]
prov_d <- names(df)[grepl("^province", names(df)) & is_num]
fe_dummies <- c(reg_d, prov_d)

spec1 <- c("z_lpop1911", "z_lpop2", "z_lpop3", "z_lpop4", "z_sh_pop_1911_be6")
spec2 <- c(spec1, "z_larea", "z_centre_alt", "z_max_alt")
spec3 <- c(spec2, "z_psu1913_vv")
spec4 <- c(spec3, "z_veterans74_95", "z_veterans96_00", "z_ard_vol_pop6m", "z_cruent_d", "z_army_suppliers_d")
spec5 <- c(spec4, "z_dlab", "z_shcrop", "z_landlord_ass")
spec6 <- c(spec5, "z_ind_workers", "z_ind_firms", "z_literacy", "z_elites", "z_bourgeoisie")
specs <- list(spec1, spec2, spec3, spec4, spec5, spec6)

# ---------------------------------------------------------------------------
# Estimation via Frisch-Waugh-Lovell: partial out constant + controls + dummies
# ---------------------------------------------------------------------------
estimate <- function(yvar, zvar, ctrl, dvar = NULL) {
  vars <- unique(c(yvar, dvar, zvar, ctrl, fe_dummies, "cluster_id"))
  keep <- complete.cases(df[, vars])
  d <- df[keep, , drop = FALSE]
  N <- nrow(d)
  W <- cbind(1, as.matrix(d[, c(ctrl, fe_dummies), drop = FALSE]))
  storage.mode(W) <- "double"
  q <- qr(W)
  kW <- q$rank
  M <- cbind(y = d[[yvar]], z = d[[zvar]])
  if (!is.null(dvar)) M <- cbind(M, dd = d[[dvar]])
  R <- qr.resid(q, M)
  yt <- R[, "y"]; zt <- R[, "z"]
  cl <- d$cluster_id
  G <- length(unique(cl))
  K <- kW + 1
  if (is.null(dvar)) {
    b <- sum(zt * yt) / sum(zt^2)
    e <- yt - b * zt
    s <- rowsum(zt * e, cl)
    V <- sum(s^2) / sum(zt^2)^2 * ((N - 1) / (N - K)) * (G / (G - 1))
  } else {
    dt <- R[, "dd"]
    b <- sum(zt * yt) / sum(zt * dt)
    e <- yt - b * dt
    s <- rowsum(zt * e, cl)
    # ivreg2 cluster-robust (no small-sample adjustment)
    V <- sum(s^2) / sum(zt * dt)^2
  }
  se <- sqrt(V)
  list(b = b, se = se, F = (b / se)^2, N = N, G = G)
}

# Table I: first stages
fs <- lapply(specs, function(ct) estimate("z_psu1919_vv", "z_foots_pop6m", ct))
for (i in 1:6) {
  cat(sprintf("Table I col %d: b=%.4f se=%.4f F=%.2f N=%d G=%d\n",
              i, fs[[i]]$b, fs[[i]]$se, fs[[i]]$F, fs[[i]]$N, fs[[i]]$G))
}

# Table II / III: 2SLS
iv_viol6   <- estimate("z_fascist_violence", "z_foots_pop6m", spec6, dvar = "z_psu1919_vv")
iv_branch6 <- estimate("z_fascist_branch",   "z_foots_pop6m", spec6, dvar = "z_psu1919_vv")
iv_f21_6   <- estimate("z_fascist1921_vv",   "z_foots_pop6m", spec6, dvar = "z_psu1919_vv")
iv_f24_1   <- estimate("z_fascist1924_vv",   "z_foots_pop6m", spec1, dvar = "z_psu1919_vv")
iv_f24_6   <- estimate("z_fascist1924_vv",   "z_foots_pop6m", spec6, dvar = "z_psu1919_vv")

for (nm in c("iv_viol6", "iv_branch6", "iv_f21_6", "iv_f24_1", "iv_f24_6")) {
  r <- get(nm)
  cat(sprintf("%s: b=%.4f se=%.4f N=%d G=%d\n", nm, r$b, r$se, r$N, r$G))
}

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", fs[[1]]$b))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", fs[[6]]$b))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", fs[[6]]$F))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", iv_viol6$b))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", iv_branch6$b))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", iv_f21_6$b))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", iv_f24_1$b))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", iv_f24_6$b))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", fs[[6]]$N))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", fs[[6]]$G))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", iv_f21_6$N))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", iv_f21_6$G))