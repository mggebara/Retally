suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

path <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free/fascism_db.dta"
raw <- haven::read_dta(path)
df <- as.data.frame(lapply(raw, function(x) { if (inherits(x, "haven_labelled")) as.vector(zap_labels(x)) else as.vector(x) }), stringsAsFactors = FALSE)
names(df) <- names(raw)
cn <- names(df)

labs <- vapply(raw, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else as.character(l)[1] }, character(1))

is_num <- function(v) is.numeric(df[[v]])
lfilter <- function(x, f) { if (length(x) == 0) return(character(0)); x[vapply(x, f, logical(1))] }
find_col <- function(name_patterns = character(0), label_patterns = character(0), exclude = character(0), numeric_only = TRUE) {
  exclude <- exclude[!is.na(exclude)]
  for (p in name_patterns) {
    hits <- cn[grepl(p, cn, ignore.case = TRUE)]
    hits <- setdiff(hits, exclude)
    if (numeric_only) hits <- lfilter(hits, is_num)
    if (length(hits) > 0) return(hits[1])
  }
  for (p in label_patterns) {
    hits <- cn[grepl(p, labs, ignore.case = TRUE)]
    hits <- setdiff(hits, exclude)
    if (numeric_only) hits <- lfilter(hits, is_num)
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}
report <- function(tag, v) cat(sprintf("VARMAP:%s=%s\n", tag, ifelse(is.na(v), "NOT_FOUND", v)))

# ---------------- Variables ----------------
y_soc <- "psu1919_vv"
z_inst <- if ("foots_pop6m" %in% cn) "foots_pop6m" else find_col(c("foot"), c("Foot-soldier casualties"))
v_viol <- "fascist_violence"
v_branch <- "fascist_branch"
v_f21 <- if ("fascist1921_vv" %in% cn) "fascist1921_vv" else find_col(c("fascist1921"))
v_f24 <- "fascist1924_vv"
cluster_var <- if ("circondario1921" %in% cn) "circondario1921" else find_col(c("circondario"))

prov_var <- find_col(c("^provincia1921$", "^province1921$", "^prov1921$", "^provincia$", "^province$", "^prov$", "^prov_id$", "^cod_prov", "^provincia", "^province", "^prov"),
                     c("^Province", "^Provincia"), exclude = character(0))

# log population
lpop_var <- find_col(c("^lpop1921$", "^lpop$", "^ln_pop1921$", "^log_pop1921$", "^lpop", "^ln_pop", "^log_pop", "^logpop"),
                     c("\\(log\\) .*population", "log.*population", "Log.*population"))
if (is.na(lpop_var)) {
  popv <- find_col(c("^pop1921$", "^pop_1921$", "^pop1911$", "^pop_1911$", "^pop$"), c("^Population"))
  if (!is.na(popv)) { df$lpop_constructed <- log(df[[popv]]); lpop_var <- "lpop_constructed"; cn <- names(df); cat(sprintf("DEVIATION: log population constructed as log(%s)\n", popv)) }
}
pop6_var <- if ("sh_pop_1911_be6" %in% cn) "sh_pop_1911_be6" else find_col(c("below.*6|be6"))

# geographic
larea_var <- "larea"
maxalt_var <- "max_alt"
alt_var <- find_col(c("^alt$", "^altitude$", "^alt_centro", "^alt_center", "^altitudine", "^elev", "^alt_main", "^min_alt", "^alt"),
                    c("Elevation of the main", "Elevation", "Altitude"), exclude = c("max_alt"))

# 1913 socialist
psu13_var <- "psu1913_vv"

# military
vet1_var <- if ("veterans74_95" %in% cn) "veterans74_95" else find_col(c("veterans74"))
vet2_var <- if ("veterans96_00" %in% cn) "veterans96_00" else find_col(c("veterans96"))
assault_var <- find_col(c("arditi.*vol", "vol.*ardit", "assault.*vol", "special.*vol", "^ardvol", "ardit", "assault", "volunt"),
                        c("assault.*volunt", "volunt.*assault", "special assault", "Arditi", "volunteer"),
                        exclude = c(z_inst, "casualties_pop6m"))
army_var <- "army_suppliers_d"
battle_var <- find_col(c("bloody", "battle", "high_mort", "deadl", "worst", "1000"),
                       c("highest.mortality", "battles", "1000 deaths", "1,000"))

# agricultural
dlab_var <- "dlab"
mezz_var <- find_col(c("^mezz", "sharecrop", "^shcrop", "^colon", "^sharecr"), c("sharecropper", "Sharecropper", "mezzadri"))
agr_var <- find_col(c("agrar", "landown", "^asso", "assagr", "agr_ass"), c("landowner", "Landowner", "agrarian association", "Agrarian"))

# urban
indw_var <- "ind_workers"; indf_var <- "ind_firms"; lit_var <- "literacy"; elite_var <- "elites"; bourg_var <- "bourgeoisie"

# regiment dummies
reg_cands <- cn[grepl("^(reg|regg|regiment|reggimento|rgt|rgm)[_]?[0-9]+$|^regiment_|^reggimento_|^reg_d_?[0-9]+|^d_reg_?[0-9]+|^regd[0-9]+|^rgm_", cn, ignore.case = TRUE)]
if (length(reg_cands) == 0) {
  reg_cands <- cn[grepl("regiment|reggim", labs, ignore.case = TRUE)]
}
reg_cands <- lfilter(reg_cands, function(v) is.numeric(df[[v]]))
reg_cands <- lfilter(reg_cands, function(v) {
  u <- unique(df[[v]][!is.na(df[[v]])]); length(u) == 2 && all(u %in% c(0, 1))
})
cat(sprintf("VARMAP:regiment_dummies=%d\n", length(reg_cands)))
if (length(reg_cands) == 0) cat("DEVIATION: regiment fixed effects (dummies) not found in data; omitted\n")

for (nm in c("y_soc", "z_inst", "v_viol", "v_branch", "v_f21", "v_f24", "cluster_var", "prov_var", "lpop_var", "pop6_var",
             "alt_var", "assault_var", "battle_var", "mezz_var", "agr_var")) report(nm, get(nm))

# quartic in log population
if (!is.na(lpop_var)) {
  df$lpop_q1 <- df[[lpop_var]]; df$lpop_q2 <- df[[lpop_var]]^2; df$lpop_q3 <- df[[lpop_var]]^3; df$lpop_q4 <- df[[lpop_var]]^4
  demo <- c("lpop_q1", "lpop_q2", "lpop_q3", "lpop_q4")
} else { demo <- character(0); cat("DEVIATION: log population not found; quartic omitted\n") }
cn <- names(df)
demo <- c(demo, pop6_var)
geo <- c(larea_var, alt_var, maxalt_var)
s13 <- c(psu13_var)
mil <- c(vet1_var, vet2_var, assault_var, army_var, battle_var)
agri <- c(dlab_var, mezz_var, agr_var)
urb <- c(indw_var, indf_var, lit_var, elite_var, bourg_var)
clean <- function(v) { v <- v[!is.na(v)]; v[v %in% cn] }
for (grp in list(list("geo", geo), list("mil", mil), list("agri", agri))) {
  miss <- sum(is.na(grp[[2]])); if (miss > 0) cat(sprintf("DEVIATION: %d control(s) in group %s not found; omitted\n", miss, grp[[1]]))
}
ctrl_sets <- list(
  c1 = clean(c(demo, reg_cands)),
  c2 = clean(c(demo, reg_cands, geo)),
  c3 = clean(c(demo, reg_cands, geo, s13)),
  c4 = clean(c(demo, reg_cands, geo, s13, mil)),
  c5 = clean(c(demo, reg_cands, geo, s13, mil, agri)),
  c6 = clean(c(demo, reg_cands, geo, s13, mil, agri, urb))
)

bt <- function(x) paste0("`", x, "`")
zs <- function(x) { s <- sd(x, na.rm = TRUE); if (is.na(s) || s == 0) x else (x - mean(x, na.rm = TRUE)) / s }

fe_part <- if (!is.na(prov_var)) paste0(" | ", bt(prov_var)) else ""
if (is.na(prov_var)) cat("DEVIATION: province identifier not found; province FE omitted\n")

prep_sample <- function(vars) {
  d <- df[, unique(clean(c(vars, prov_var, cluster_var))), drop = FALSE]
  d <- d[complete.cases(d), , drop = FALSE]
  # standardize continuous LHS/RHS (non-dummy) in estimation sample
  for (v in setdiff(names(d), c(prov_var, cluster_var))) {
    u <- unique(d[[v]])
    if (!(length(u) <= 2 && all(u %in% c(0, 1)))) d[[v]] <- zs(d[[v]])
  }
  d
}
# Ensure standardization of key variables even if binary
prep_std_keys <- function(d, keys) { for (k in keys) d[[k]] <- zs(d[[k]]); d }

run_fs <- function(ctrls) {
  d <- prep_sample(c(y_soc, z_inst, ctrls))
  d <- prep_std_keys(d, c(y_soc, z_inst))
  ctrls <- lfilter(ctrls, function(v) length(unique(d[[v]])) > 1)
  f <- as.formula(paste0(bt(y_soc), " ~ ", paste(bt(c(z_inst, ctrls)), collapse = " + "), fe_part))
  feols(f, data = d, cluster = as.formula(paste0("~", bt(cluster_var))))
}
run_iv <- function(yv, ctrls) {
  d <- prep_sample(c(yv, y_soc, z_inst, ctrls))
  d <- prep_std_keys(d, c(yv, y_soc, z_inst))
  ctrls <- lfilter(ctrls, function(v) length(unique(d[[v]])) > 1)
  rhs <- if (length(ctrls)) paste(bt(ctrls), collapse = " + ") else "1"
  f <- as.formula(paste0(bt(yv), " ~ ", rhs, fe_part, " | ", bt(y_soc), " ~ ", bt(z_inst)))
  m <- feols(f, data = d, cluster = as.formula(paste0("~", bt(cluster_var))))
  list(m = m, d = d)
}

safe <- function(expr) tryCatch(expr, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL })

# ---------------- Sample accounting ----------------
nclus <- function(m, d) {
  obs <- tryCatch(obs(m), error = function(e) NULL)
  if (!is.null(obs)) length(unique(d[[cluster_var]][obs])) else length(unique(d[[cluster_var]]))
}

cat(sprintf("SAMPLE:table1:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:table1:nonmissing_socialist1919=%d\n", sum(!is.na(df[[y_soc]]))))
fs1 <- safe(run_fs(ctrl_sets$c1))
fs6 <- safe(run_fs(ctrl_sets$c6))
if (!is.null(fs6)) cat(sprintf("SAMPLE:table1:estimation=%d\n", nobs(fs6)))

cat(sprintf("SAMPLE:table2_violence:loaded=%d\n", nrow(df)))
iv_viol6 <- safe(run_iv(v_viol, ctrl_sets$c6))
if (!is.null(iv_viol6)) cat(sprintf("SAMPLE:table2_violence:estimation=%d\n", nobs(iv_viol6$m)))

cat(sprintf("SAMPLE:table2_branches:loaded=%d\n", nrow(df)))
iv_br6 <- safe(run_iv(v_branch, ctrl_sets$c6))
if (!is.null(iv_br6)) cat(sprintf("SAMPLE:table2_branches:estimation=%d\n", nobs(iv_br6$m)))

cat(sprintf("SAMPLE:table3_fascist1921:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:table3_fascist1921:nonmissing_fascist1921=%d\n", sum(!is.na(df[[v_f21]]))))
iv_f21_6 <- safe(run_iv(v_f21, ctrl_sets$c6))
if (!is.null(iv_f21_6)) cat(sprintf("SAMPLE:table3_fascist1921:estimation=%d\n", nobs(iv_f21_6$m)))

cat(sprintf("SAMPLE:table3_fascist1924:loaded=%d\n", nrow(df)))
iv_f24_1 <- safe(run_iv(v_f24, ctrl_sets$c1))
iv_f24_6 <- safe(run_iv(v_f24, ctrl_sets$c6))
if (!is.null(iv_f24_6)) cat(sprintf("SAMPLE:table3_fascist1924:estimation=%d\n", nobs(iv_f24_6$m)))

# ---------------- Results ----------------
out <- function(name, val) if (!is.null(val) && length(val) == 1 && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
getc <- function(m, v) if (is.null(m)) NA else unname(coef(m)[v])
gets <- function(m, v) if (is.null(m)) NA else unname(sqrt(diag(vcov(m)))[v])
fitv <- paste0("fit_", y_soc)

out("first_stage_casualties_table1_col1", getc(fs1, z_inst))
out("first_stage_casualties_table1_col1_se", gets(fs1, z_inst))
out("first_stage_casualties_table1_col6", getc(fs6, z_inst))
out("first_stage_casualties_table1_col6_se", gets(fs6, z_inst))
if (!is.null(fs6)) out("first_stage_fstat_table1_col6", (getc(fs6, z_inst) / gets(fs6, z_inst))^2)
if (!is.null(iv_viol6)) { out("iv_violence_table2_panelA_col6", getc(iv_viol6$m, fitv)); out("iv_violence_table2_panelA_col6_se", gets(iv_viol6$m, fitv)) }
if (!is.null(iv_br6)) { out("iv_branches_table2_panelC_col6", getc(iv_br6$m, fitv)); out("iv_branches_table2_panelC_col6_se", gets(iv_br6$m, fitv)) }
if (!is.null(iv_f21_6)) { out("iv_fascist_vote1921_table3_panelA_col6", getc(iv_f21_6$m, fitv)); out("iv_fascist_vote1921_table3_panelA_col6_se", gets(iv_f21_6$m, fitv)) }
if (!is.null(iv_f24_1)) { out("iv_fascist_vote1924_table3_panelC_col1", getc(iv_f24_1$m, fitv)); out("iv_fascist_vote1924_table3_panelC_col1_se", gets(iv_f24_1$m, fitv)) }
if (!is.null(iv_f24_6)) { out("iv_fascist_vote1924_table3_panelC_col6", getc(iv_f24_6$m, fitv)); out("iv_fascist_vote1924_table3_panelC_col6_se", gets(iv_f24_6$m, fitv)) }
if (!is.null(fs6)) {
  out("n_obs_main_sample", nobs(fs6))
  d6 <- prep_sample(c(y_soc, z_inst, ctrl_sets$c6))
  out("n_clusters_main_sample", nclus(fs6, d6))
}
if (!is.null(iv_f21_6)) {
  out("n_obs_fascist_vote1921", nobs(iv_f21_6$m))
  out("n_clusters_fascist_vote1921", nclus(iv_f21_6$m, iv_f21_6$d))
}