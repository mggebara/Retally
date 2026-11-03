suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base_dir <- '<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free'
df <- haven::read_dta(file.path(base_dir, 'fascism_db.dta'))
df <- as.data.frame(df)
n_loaded <- nrow(df)

nms <- names(df)
labs <- vapply(nms, function(v) {
  l <- attr(df[[v]], "label")
  if (is.null(l)) "" else as.character(l)
}, character(1))

# Strip haven classes to plain numeric where possible
for (v in nms) {
  x <- df[[v]]
  if (inherits(x, "haven_labelled") || inherits(x, "labelled")) x <- as.vector(zap_labels(x))
  df[[v]] <- x
}

is_num <- function(v) is.numeric(df[[v]])

find_var <- function(cands = character(0), label_re = NULL, name_re = NULL, exclude_re = NULL) {
  for (c in cands) if (c %in% nms) return(c)
  pool <- nms
  if (!is.null(exclude_re)) pool <- pool[!grepl(exclude_re, pool, ignore.case = TRUE)]
  if (!is.null(name_re)) {
    hit <- pool[grepl(name_re, pool, ignore.case = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  if (!is.null(label_re)) {
    hit <- pool[grepl(label_re, labs[pool], ignore.case = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}

# ---------------- Core variables ----------------
v_endog   <- find_var(c("psu1919_vv"), label_re = "socialist.*1919")
v_inst    <- find_var(c("foots_pop6m"), label_re = "foot.soldier casualties")
v_viol    <- find_var(c("fascist_violence"))
v_branch  <- find_var(c("fascist_branch"))
v_f1921   <- find_var(c("fascist1921_vv"), label_re = "fascist vote share in 1921$")
v_f1924   <- find_var(c("fascist1924_vv"))
v_clu     <- find_var(c("circondario1921", "circondario"), name_re = "^circondario")
v_prov    <- find_var(c("province1921", "provincia1921", "prov1921", "province", "provincia", "prov", "id_prov", "cod_prov", "prov_id"),
                      name_re = "^prov", label_re = "^province", exclude_re = "provider")

# Population (log 1911)
v_lpop <- find_var(c("lpop1911", "lnpop1911", "log_pop1911", "logpop1911", "lpop_1911", "ln_pop1911", "lpop"),
                   name_re = "^l(n)?_?pop_?1911$", label_re = "log.*population.*1911")
v_pop  <- find_var(c("pop1911", "pop_1911", "population1911", "pop11", "popres1911"),
                   name_re = "^pop_?1911$", label_re = "^population.*1911")
if (!is.na(v_lpop)) {
  df$.lpop <- as.numeric(df[[v_lpop]])
} else if (!is.na(v_pop)) {
  df$.lpop <- log(as.numeric(df[[v_pop]]))
} else {
  df$.lpop <- NA_real_
}
df$.lpop[!is.finite(df$.lpop)] <- NA
df$.lpop1 <- df$.lpop
df$.lpop2 <- df$.lpop^2
df$.lpop3 <- df$.lpop^3
df$.lpop4 <- df$.lpop^4
v_be6 <- find_var(c("sh_pop_1911_be6"), label_re = "below the age of 6")

demog <- c(".lpop1", ".lpop2", ".lpop3", ".lpop4", v_be6)

# Regiment dummies
reg_cands <- nms[grepl("^(regiment|regg?|rgt|reggimento)_?d?_?[0-9]+(_d)?$", nms, ignore.case = TRUE) |
                 (grepl("regiment|reggimento", labs, ignore.case = TRUE) & !grepl("region", nms, ignore.case = TRUE))]
reg_cands <- unique(reg_cands)
reg_cands <- reg_cands[vapply(reg_cands, function(v) {
  x <- df[[v]]
  if (!is.numeric(x)) return(FALSE)
  u <- unique(x[!is.na(x)])
  length(u) <= 2 && all(u %in% c(0, 1)) && length(u) == 2
}, logical(1))]
regiment_dummies <- reg_cands

# Geographic
geo <- c(find_var(c("larea"), label_re = "log.*area"),
         find_var(c("centre_alt"), label_re = "elevation.*cent"),
         find_var(c("max_alt"), label_re = "maximum elevation"))

# Socialist 1913
soc13 <- find_var(c("psu1913_vv"), label_re = "socialist.*1913")

# Military
vet_vars <- nms[grepl("^veterans", nms, ignore.case = TRUE)]
vet_vars <- vet_vars[vapply(vet_vars, is_num, logical(1))]
if (length(vet_vars) > 2) {
  v74 <- vet_vars[grepl("74|1874", vet_vars)][1]
  v96 <- vet_vars[grepl("96|1896", vet_vars)][1]
  vet_vars <- unique(na.omit(c(v74, v96)))
}
v_ardvol <- find_var(c("ard_vol_pop6m"), label_re = "assault troops and volunteer")
v_army   <- find_var(c("army_suppliers_d"), label_re = "army supplying")
v_battle <- find_var(c("large_battles_d", "battle_d", "mlarge_d", "highmort_d"),
                     label_re = "battle|highest.mortality|more than 1,?000")
if (is.na(v_battle)) {
  ml <- nms[grepl("^mlarge", nms)]
  if (length(ml) > 0) v_battle <- ml[1]
}
military <- c(vet_vars, v_ardvol, v_army, v_battle)

# Agricultural
v_dlab  <- find_var(c("dlab"), label_re = "day.?labo")
v_shcr  <- find_var(c("sharecroppers", "sharecrop", "shcrop", "scrop", "mezzadri", "sh_sharecrop"),
                    name_re = "crop", label_re = "sharecrop")
v_landw <- find_var(c("landowners_assoc", "agrarian_assoc", "agr_assoc", "landowner_d", "agrarian_d"),
                    label_re = "landowner|agrarian assoc|agrarian assoc|association of (land|agr)")
agri <- c(v_dlab, v_shcr, v_landw)

# Urban
urban <- c(find_var(c("ind_workers"), label_re = "industrial workers"),
           find_var(c("ind_firms"), label_re = "industry firms"),
           find_var(c("literacy"), label_re = "literacy in 1911"),
           find_var(c("elites"), label_re = "share of elites"),
           find_var(c("bourgeoisie"), label_re = "share of bourgeoisie"))

clean <- function(x) unique(x[!is.na(x)])
demog <- clean(demog); geo <- clean(geo); soc13 <- clean(soc13)
military <- clean(military); agri <- clean(agri); urban <- clean(urban)

ctrl_sets <- list(
  c1 = c(demog, regiment_dummies),
  c6 = c(demog, regiment_dummies, geo, soc13, military, agri, urban)
)

# ---------------- Standardise ----------------
zs <- function(x) {
  x <- as.numeric(x)
  (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
}
df$z_endog  <- zs(df[[v_endog]])
df$z_inst   <- zs(df[[v_inst]])
df$z_viol   <- if (!is.na(v_viol)) zs(df[[v_viol]]) else NA_real_
df$z_branch <- if (!is.na(v_branch)) zs(df[[v_branch]]) else NA_real_
df$z_f1921  <- if (!is.na(v_f1921)) zs(df[[v_f1921]]) else NA_real_
df$z_f1924  <- if (!is.na(v_f1924)) zs(df[[v_f1924]]) else NA_real_
df$.clu <- df[[v_clu]]
fe_part <- if (!is.na(v_prov)) paste0("`", v_prov, "`") else "0"

bt <- function(v) paste0("`", v, "`")
rhs_str <- function(ctrls) if (length(ctrls) == 0) "1" else paste(bt(ctrls), collapse = " + ")

run_fs <- function(ctrls, data) {
  f <- as.formula(paste0("z_endog ~ z_inst + ", rhs_str(ctrls), " | ", fe_part))
  feols(f, data = data, cluster = ~.clu, warn = FALSE, notes = FALSE)
}
run_iv <- function(y, ctrls, data) {
  f <- as.formula(paste0(y, " ~ ", rhs_str(ctrls), " | ", fe_part, " | z_endog ~ z_inst"))
  feols(f, data = data, cluster = ~.clu, warn = FALSE, notes = FALSE)
}

safe <- function(expr) tryCatch(expr, error = function(e) { message("ERROR: ", conditionMessage(e)); NULL })

# ---------------- Main sample ----------------
cat(sprintf('SAMPLE:main:loaded=%d\n', n_loaded))
main <- df[!is.na(df[[v_endog]]) & !is.na(df[[v_f1924]]), ]
cat(sprintf('SAMPLE:main:nonmissing_1919_1924_elections=%d\n', nrow(main)))

fs1 <- safe(run_fs(ctrl_sets$c1, main))
fs6 <- safe(run_fs(ctrl_sets$c6, main))
cat(sprintf('SAMPLE:main:estimation=%d\n', if (!is.null(fs6)) nobs(fs6) else NA_integer_))

iv_viol6   <- safe(run_iv("z_viol", ctrl_sets$c6, main))
iv_branch6 <- safe(run_iv("z_branch", ctrl_sets$c6, main))
iv_f24_1   <- safe(run_iv("z_f1924", ctrl_sets$c1, main))
iv_f24_6   <- safe(run_iv("z_f1924", ctrl_sets$c6, main))

cat(sprintf('SAMPLE:table2_violence:loaded=%d\n', n_loaded))
cat(sprintf('SAMPLE:table2_violence:estimation=%d\n', if (!is.null(iv_viol6)) nobs(iv_viol6) else NA_integer_))
cat(sprintf('SAMPLE:table2_branches:loaded=%d\n', n_loaded))
cat(sprintf('SAMPLE:table2_branches:estimation=%d\n', if (!is.null(iv_branch6)) nobs(iv_branch6) else NA_integer_))
cat(sprintf('SAMPLE:table3_fascist1924:loaded=%d\n', n_loaded))
cat(sprintf('SAMPLE:table3_fascist1924:estimation=%d\n', if (!is.null(iv_f24_6)) nobs(iv_f24_6) else NA_integer_))

# ---------------- 1921 sample ----------------
cat(sprintf('SAMPLE:fascist1921:loaded=%d\n', n_loaded))
s21 <- df[!is.na(df[[v_f1921]]), ]
cat(sprintf('SAMPLE:fascist1921:nonmissing_1921_fascist_vote=%d\n', nrow(s21)))
iv_f21_6 <- safe(run_iv("z_f1921", ctrl_sets$c6, s21))
cat(sprintf('SAMPLE:fascist1921:estimation=%d\n', if (!is.null(iv_f21_6)) nobs(iv_f21_6) else NA_integer_))

# ---------------- Extract ----------------
gcoef <- function(m, v) if (is.null(m)) NA_real_ else unname(coef(m)[v])
gse <- function(m, v) if (is.null(m)) NA_real_ else unname(sqrt(diag(vcov(m)))[v])
ivname <- "fit_z_endog"
nclu <- function(m, data) {
  if (is.null(m)) return(NA_integer_)
  obs <- obs(m)
  length(unique(data$.clu[obs]))
}

fstat6 <- if (!is.null(fs6)) (gcoef(fs6, "z_inst") / gse(fs6, "z_inst"))^2 else NA_real_

fmt <- function(x) if (is.na(x)) "NA" else format(x, digits = 10)
cat(sprintf('RESULT:first_stage_casualties_table1_col1=%s\n', fmt(gcoef(fs1, "z_inst"))))
cat(sprintf('RESULT:first_stage_casualties_table1_col6=%s\n', fmt(gcoef(fs6, "z_inst"))))
cat(sprintf('RESULT:first_stage_fstat_table1_col6=%s\n', fmt(fstat6)))
cat(sprintf('RESULT:iv_violence_table2_panelA_col6=%s\n', fmt(gcoef(iv_viol6, ivname))))
cat(sprintf('RESULT:iv_branches_table2_panelC_col6=%s\n', fmt(gcoef(iv_branch6, ivname))))
cat(sprintf('RESULT:iv_fascist_vote1921_table3_panelA_col6=%s\n', fmt(gcoef(iv_f21_6, ivname))))
cat(sprintf('RESULT:iv_fascist_vote1924_table3_panelC_col1=%s\n', fmt(gcoef(iv_f24_1, ivname))))
cat(sprintf('RESULT:iv_fascist_vote1924_table3_panelC_col6=%s\n', fmt(gcoef(iv_f24_6, ivname))))
cat(sprintf('RESULT:n_obs_main_sample=%s\n', fmt(if (!is.null(fs6)) nobs(fs6) else NA)))
cat(sprintf('RESULT:n_clusters_main_sample=%s\n', fmt(nclu(fs6, main))))
cat(sprintf('RESULT:n_obs_fascist_vote1921=%s\n', fmt(if (!is.null(iv_f21_6)) nobs(iv_f21_6) else NA)))
cat(sprintf('RESULT:n_clusters_fascist_vote1921=%s\n', fmt(nclu(iv_f21_6, s21))))
