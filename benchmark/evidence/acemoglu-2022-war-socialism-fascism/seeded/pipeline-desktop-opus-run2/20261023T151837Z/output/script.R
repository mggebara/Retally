suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism/fascism_db.dta"
raw <- read_dta(path)
raw <- zap_labels(raw)
df <- as.data.frame(raw)

std <- function(x) { x <- as.numeric(x); (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE) }

base_vars <- c("fascist_violence", "fascist_branch", "fascist1921_vv", "fascist1924_vv",
               "psu1919_vv", "foots_pop6m", "lpop1911", "lpop2", "lpop3", "lpop4",
               "sh_pop_1911_be6", "larea", "centre_alt", "max_alt", "psu1913_vv",
               "veterans74_95", "veterans96_00", "ard_vol_pop6m", "cruent_d", "army_suppliers_d",
               "dlab", "shcrop", "landlord_ass", "ind_workers", "ind_firms", "literacy",
               "elites", "bourgeoisie")
for (v in base_vars) {
  if (v %in% names(df)) df[[paste0("z_", v)]] <- std(df[[v]])
  else warning(paste("missing variable", v))
}

is_num <- function(v) is.numeric(df[[v]]) || is.logical(df[[v]])
dreg <- grep("^d_reg", names(df), value = TRUE)
dreg <- dreg[sapply(dreg, is_num)]
prov <- grep("^province", names(df), value = TRUE)
prov <- prov[sapply(prov, is_num)]
for (v in c(dreg, prov)) df[[v]] <- as.numeric(df[[v]])

bt <- function(x) paste0("`", x, "`")

spec1 <- c("z_lpop1911", "z_lpop2", "z_lpop3", "z_lpop4", "z_sh_pop_1911_be6", dreg, prov)
spec2 <- c(spec1, "z_larea", "z_centre_alt", "z_max_alt")
spec3 <- c(spec2, "z_psu1913_vv")
spec4 <- c(spec3, "z_veterans74_95", "z_veterans96_00", "z_ard_vol_pop6m", "z_cruent_d", "z_army_suppliers_d")
spec5 <- c(spec4, "z_dlab", "z_shcrop", "z_landlord_ass")
spec6 <- c(spec5, "z_ind_workers", "z_ind_firms", "z_literacy", "z_elites", "z_bourgeoisie")
specs <- list(spec1, spec2, spec3, spec4, spec5, spec6)

ctrl_str <- function(s) paste(bt(s), collapse = " + ")

used_rows <- function(vars) {
  vars <- unique(c(vars, "circondario1921"))
  complete.cases(df[, vars, drop = FALSE])
}

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}

# ---- Table I: first stage ----
fs <- function(i) {
  s <- specs[[i]]
  f <- as.formula(paste0("z_psu1919_vv ~ z_foots_pop6m + ", ctrl_str(s)))
  m <- feols(f, data = df, cluster = ~circondario1921, notes = FALSE, warn = FALSE)
  b <- coef(m)["z_foots_pop6m"]
  se <- sqrt(diag(vcov(m)))["z_foots_pop6m"]
  list(m = m, b = unname(b), se = unname(se), F = unname((b / se)^2),
       rows = used_rows(c("z_psu1919_vv", "z_foots_pop6m", s)))
}

r1 <- tryCatch(fs(1), error = function(e) { message("fs1 error: ", conditionMessage(e)); NULL })
if (!is.null(r1)) {
  emit("first_stage_casualties_table1_col1", r1$b)
  emit("first_stage_casualties_table1_col1_se", r1$se)
  emit("n_obs_main_sample", nobs(r1$m))
  emit("n_clusters_main_sample", length(unique(df$circondario1921[r1$rows])))
}
r6 <- tryCatch(fs(6), error = function(e) { message("fs6 error: ", conditionMessage(e)); NULL })
if (!is.null(r6)) {
  emit("first_stage_casualties_table1_col6", r6$b)
  emit("first_stage_casualties_table1_col6_se", r6$se)
  emit("first_stage_fstat_table1_col6", r6$F)
}

# ---- 2SLS ----
iv <- function(y, i) {
  s <- specs[[i]]
  f <- as.formula(paste0(y, " ~ ", ctrl_str(s), " | z_psu1919_vv ~ z_foots_pop6m"))
  m <- feols(f, data = df, cluster = ~circondario1921, notes = FALSE, warn = FALSE)
  cn <- "fit_z_psu1919_vv"
  list(m = m, b = unname(coef(m)[cn]), se = unname(sqrt(diag(vcov(m)))[cn]),
       rows = used_rows(c(y, "z_psu1919_vv", "z_foots_pop6m", s)))
}

safe_iv <- function(y, i) tryCatch(iv(y, i), error = function(e) { message("iv error ", y, " ", i, ": ", conditionMessage(e)); NULL })

a <- safe_iv("z_fascist_violence", 6)
if (!is.null(a)) { emit("iv_violence_table2_panelA_col6", a$b); emit("iv_violence_table2_panelA_col6_se", a$se) }

cc <- safe_iv("z_fascist_branch", 6)
if (!is.null(cc)) { emit("iv_branches_table2_panelC_col6", cc$b); emit("iv_branches_table2_panelC_col6_se", cc$se) }

f21 <- safe_iv("z_fascist1921_vv", 6)
if (!is.null(f21)) {
  emit("iv_fascist_vote1921_table3_panelA_col6", f21$b)
  emit("iv_fascist_vote1921_table3_panelA_col6_se", f21$se)
  emit("n_obs_fascist_vote1921", nobs(f21$m))
  emit("n_clusters_fascist_vote1921", length(unique(df$circondario1921[f21$rows])))
}

f24a <- safe_iv("z_fascist1924_vv", 1)
if (!is.null(f24a)) { emit("iv_fascist_vote1924_table3_panelC_col1", f24a$b); emit("iv_fascist_vote1924_table3_panelC_col1_se", f24a$se) }

f24f <- safe_iv("z_fascist1924_vv", 6)
if (!is.null(f24f)) { emit("iv_fascist_vote1924_table3_panelC_col6", f24f$b); emit("iv_fascist_vote1924_table3_panelC_col6_se", f24f$se) }

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}