suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free/fascism_db.dta"
raw <- haven::read_dta(path)
df <- as.data.frame(lapply(raw, function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  x
}), stringsAsFactors = FALSE)
names(df) <- names(raw)
nm <- names(df)
msg <- function(...) message(paste0(...))

is_num <- function(v) is.numeric(df[[v]])
is_binary <- function(v) {
  x <- df[[v]]
  if (!is.numeric(x)) return(FALSE)
  u <- unique(x[!is.na(x)])
  length(u) >= 1 && all(u %in% c(0, 1))
}

pick <- function(exact, regex = NULL, exclude = character(0), prefer_binary = FALSE, numeric_only = TRUE) {
  for (e in exact) if (e %in% nm && (!numeric_only || is_num(e))) return(e)
  if (!is.null(regex)) {
    m <- grep(regex, nm, value = TRUE, ignore.case = TRUE)
    m <- setdiff(m, exclude)
    if (numeric_only) m <- m[vapply(m, is_num, logical(1))]
    if (length(m) > 0) {
      if (prefer_binary) {
        b <- m[vapply(m, is_binary, logical(1))]
        if (length(b) > 0) return(b[1])
      }
      return(m[1])
    }
  }
  NA_character_
}

# ---- core variables ----
y_soc <- "psu1919_vv"
z_inst <- "foots_pop6m"
clus <- "circondario1921"

# ---- province ----
prov_cands <- c("province", "provincia", "prov", "province1921", "provincia1921", "prov1921",
                "provincia_1921", "province_1921", "prov_1921", "cod_prov", "codprov", "prov_id", "province_id", "id_prov")
prov <- NA_character_
for (e in c(prov_cands, grep("^prov|provinc|^cod_?prov", nm, value = TRUE, ignore.case = TRUE))) {
  if (e %in% nm) {
    k <- length(unique(df[[e]][!is.na(df[[e]])]))
    if (k >= 30 && k <= 150) { prov <- e; break }
  }
}
msg("province var: ", prov)

# ---- population (quartic in log population) ----
lpop_exact <- c("lpop1911", "lpop", "ln_pop1911", "logpop1911", "log_pop1911", "lpop_1911", "lpop1921", "ln_pop", "logpop")
pop_exact <- c("pop1911", "pop_1911", "population1911", "pop1921", "pop_1921", "population1921",
               "pop", "population", "totpop1911", "pop_tot1911", "pop_tot", "popres1911")
lp <- NULL
for (e in lpop_exact) if (e %in% nm && is_num(e)) { lp <- df[[e]]; msg("log pop var: ", e); break }
if (is.null(lp)) {
  pv <- pick(pop_exact, "^pop[_]?(19(11|21))?$|^population|^pop_?tot|^totpop")
  if (!is.na(pv)) {
    x <- df[[pv]]
    if (max(x, na.rm = TRUE) < 25) lp <- x else lp <- log(ifelse(x > 0, x, NA))
    msg("pop var: ", pv)
  }
}
demo <- c("sh_pop_1911_be6")
if (!is.null(lp)) {
  df$lp_1 <- lp; df$lp_2 <- lp^2; df$lp_3 <- lp^3; df$lp_4 <- lp^4
  demo <- c("lp_1", "lp_2", "lp_3", "lp_4", demo)
} else msg("WARNING: population variable not found")

# ---- regiment dummies ----
bin_flag <- vapply(nm, is_binary, logical(1))
reg_rx <- "(^|_)(reg|regg|rgt|regim|regiment|reggimento)[_0-9a-z]*"
reg_cols <- nm[grepl(reg_rx, nm, ignore.case = TRUE) & !grepl("region", nm, ignore.case = TRUE) & bin_flag]
if (length(reg_cols) < 10) {
  bn <- nm[bin_flag]
  pref <- sub("_?[0-9]+$", "", bn)
  has_digit <- grepl("[0-9]+$", bn)
  tb <- table(pref[has_digit])
  tb <- tb[!grepl("army_suppliers|prov|year|elec|circ|region", names(tb), ignore.case = TRUE)]
  tb <- tb[tb >= 30]
  if (length(tb) > 0) {
    best <- names(tb)[which.max(tb)]
    reg_cols <- bn[has_digit & pref == best]
  } else reg_cols <- character(0)
}
msg("regiment dummies: ", length(reg_cols), " e.g. ", paste(head(reg_cols, 5), collapse = ","))
for (v in reg_cols) { x <- df[[v]]; x[is.na(x)] <- 0; df[[v]] <- x }
reg_cols <- reg_cols[vapply(reg_cols, function(v) var(df[[v]]) > 0, logical(1))]

# ---- geographic ----
alt_main <- pick(c("alt", "altitude", "elevation", "alt_center", "alt_centro", "altitudine", "alt_cen", "alt_mc", "min_alt"),
                 "^alt|elev", exclude = c("max_alt"))
geo <- c("larea", alt_main, "max_alt")
# ---- 1913 socialist ----
pol <- c("psu1913_vv")
# ---- military ----
assault <- grep("ardit|assault|volunt|^vol_|_vol_|spec", nm, value = TRUE, ignore.case = TRUE)
assault <- assault[vapply(assault, is_num, logical(1))]
a6 <- assault[grepl("pop6m", assault)]
if (length(a6) > 0) assault <- a6 else assault <- head(assault, 2)
battle <- pick(c("battle1000_d", "bigbattle_d", "battles_d", "high_mort_d", "d_battle", "battle_d"),
               "battle|bigb|high_?mort|deadl|1000", prefer_binary = TRUE)
mil <- c("veterans74_95", "veterans96_00", assault, "army_suppliers_d", battle)
# ---- agricultural ----
shcrop <- pick(c("shcrop", "sharecroppers", "sharecrop", "mezzadri", "scrop", "shcr"), "share_?crop|mezzad|^scrop|shcrop")
landown <- pick(c("agrarian_ass", "agr_ass", "landowner_ass", "ass_agr", "agrarian_d", "landowners_d"),
                "agrar|landown|ass_agr|agr_ass|proprietar", prefer_binary = TRUE)
agr <- c("dlab", shcrop, landown)
# ---- urban ----
urb <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")

clean <- function(v) unique(v[!is.na(v) & v %in% nm])
geo <- clean(geo); pol <- clean(pol); mil <- clean(mil); agr <- clean(agr); urb <- clean(urb); demo <- clean(demo)
msg("geo: ", paste(geo, collapse = ","))
msg("mil: ", paste(mil, collapse = ","))
msg("agr: ", paste(agr, collapse = ","))
msg("urb: ", paste(urb, collapse = ","))

ctrl_sets <- list(
  c1 = c(demo),
  c6 = c(demo, geo, pol, mil, agr, urb)
)

bt <- function(v) paste0("`", v, "`")
fe_part <- if (!is.na(prov)) paste0(" | ", bt(prov)) else ""

zs <- function(x) (x - mean(x)) / sd(x)

prep <- function(vars_std, controls) {
  need <- unique(c(vars_std, controls, reg_cols, clus, if (!is.na(prov)) prov))
  d <- df[, need, drop = FALSE]
  d <- d[complete.cases(d), , drop = FALSE]
  for (v in vars_std) d[[v]] <- zs(d[[v]])
  d
}

rhs_ctrl <- function(controls) {
  terms <- c(controls, reg_cols)
  if (length(terms) == 0) "1" else paste(bt(terms), collapse = " + ")
}

first_stage <- function(controls) {
  d <- prep(c(y_soc, z_inst), controls)
  f <- as.formula(paste0(bt(y_soc), " ~ ", bt(z_inst), " + ", rhs_ctrl(controls), fe_part))
  m <- feols(f, data = d, cluster = as.formula(paste0("~", bt(clus))), warn = FALSE, notes = FALSE)
  list(m = m, d = d)
}

iv_est <- function(yv, controls) {
  d <- prep(c(yv, y_soc, z_inst), controls)
  f <- as.formula(paste0(bt(yv), " ~ ", rhs_ctrl(controls), fe_part, " | ", bt(y_soc), " ~ ", bt(z_inst)))
  m <- feols(f, data = d, cluster = as.formula(paste0("~", bt(clus))), warn = FALSE, notes = FALSE)
  list(m = m, d = d)
}

res <- list()
safe <- function(expr) tryCatch(expr, error = function(e) { msg("ERROR: ", conditionMessage(e)); NA })

fs1 <- safe(first_stage(ctrl_sets$c1))
if (is.list(fs1)) {
  res$first_stage_casualties_table1_col1 <- unname(coef(fs1$m)[z_inst])
  res$n_obs_main_sample <- nobs(fs1$m)
  res$n_clusters_main_sample <- length(unique(fs1$d[[clus]]))
} else {
  res$first_stage_casualties_table1_col1 <- NA
  res$n_obs_main_sample <- NA
  res$n_clusters_main_sample <- NA
}

fs6 <- safe(first_stage(ctrl_sets$c6))
if (is.list(fs6)) {
  b <- coef(fs6$m)[z_inst]
  se <- sqrt(diag(vcov(fs6$m)))[z_inst]
  res$first_stage_casualties_table1_col6 <- unname(b)
  res$first_stage_fstat_table1_col6 <- unname((b / se)^2)
} else {
  res$first_stage_casualties_table1_col6 <- NA
  res$first_stage_fstat_table1_col6 <- NA
}

get_iv <- function(yv, cs) {
  r <- safe(iv_est(yv, cs))
  if (is.list(r)) {
    cn <- names(coef(r$m))
    k <- cn[grepl(y_soc, cn, fixed = TRUE)][1]
    list(b = unname(coef(r$m)[k]), n = nobs(r$m), g = length(unique(r$d[[clus]])))
  } else list(b = NA, n = NA, g = NA)
}

v6 <- get_iv("fascist_violence", ctrl_sets$c6)
res$iv_violence_table2_panelA_col6 <- v6$b
b6 <- get_iv("fascist_branch", ctrl_sets$c6)
res$iv_branches_table2_panelC_col6 <- b6$b
f21 <- get_iv("fascist1921_vv", ctrl_sets$c6)
res$iv_fascist_vote1921_table3_panelA_col6 <- f21$b
f24a <- get_iv("fascist1924_vv", ctrl_sets$c1)
res$iv_fascist_vote1924_table3_panelC_col1 <- f24a$b
f24b <- get_iv("fascist1924_vv", ctrl_sets$c6)
res$iv_fascist_vote1924_table3_panelC_col6 <- f24b$b

# 1921 sample size: based on the parsimonious specification sample (same across columns)
f21c1 <- get_iv("fascist1921_vv", ctrl_sets$c1)
res$n_obs_fascist_vote1921 <- if (!is.na(f21c1$n)) f21c1$n else f21$n
res$n_clusters_fascist_vote1921 <- if (!is.na(f21c1$g)) f21c1$g else f21$g

out_order <- c("first_stage_casualties_table1_col1", "first_stage_casualties_table1_col6",
               "first_stage_fstat_table1_col6", "iv_violence_table2_panelA_col6",
               "iv_branches_table2_panelC_col6", "iv_fascist_vote1921_table3_panelA_col6",
               "iv_fascist_vote1924_table3_panelC_col1", "iv_fascist_vote1924_table3_panelC_col6",
               "n_obs_main_sample", "n_clusters_main_sample",
               "n_obs_fascist_vote1921", "n_clusters_fascist_vote1921")
for (k in out_order) {
  v <- res[[k]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", k, format(v, digits = 8)))
}