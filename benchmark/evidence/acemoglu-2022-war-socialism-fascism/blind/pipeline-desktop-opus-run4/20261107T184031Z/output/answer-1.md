suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free/fascism_db.dta"
df <- haven::read_dta(path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)
nm <- names(df)
cat("Loaded:", nrow(df), "rows,", ncol(df), "cols\n")

# ---------- helpers ----------
find_col <- function(exact = character(0), regex = character(0), exclude = NULL, label = "") {
  for (e in exact) if (e %in% nm) { cat("[col]", label, "->", e, "\n"); return(e) }
  for (r in regex) {
    hits <- grep(r, nm, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
    if (length(hits) > 0) {
      cat("[col]", label, "->", hits[1], " (candidates:", paste(head(hits, 10), collapse = ","), ")\n")
      return(hits[1])
    }
  }
  cat("[col]", label, "-> NOT FOUND\n")
  NA_character_
}
to_num <- function(x) suppressWarnings(as.numeric(x))
zstd <- function(x) { x <- to_num(x); (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE) }

# ---------- core variables ----------
v_soc19   <- find_col(c("psu1919_vv"), c("psu1919", "soc.*1919"), label = "socialist1919")
v_inst    <- find_col(c("foots_pop6m"), c("^foot"), label = "instrument")
v_viol    <- find_col(c("fascist_violence"), c("fasc.*viol"), label = "violence")
v_branch  <- find_col(c("fascist_branch"), c("fasc.*branch"), label = "branch")
v_f21     <- find_col(c("fascist1921_vv"), c("fascist1921"), exclude = "restr", label = "fascist1921")
v_f24     <- find_col(c("fascist1924_vv"), c("fascist1924"), label = "fascist1924")
v_clus    <- find_col(c("circondario1921", "circondario"), c("circond", "district"), label = "cluster")
v_prov    <- find_col(c("province1921", "provincia1921", "prov1921", "province", "provincia", "prov", "codprov", "cod_prov", "prov_code", "id_prov"),
                      c("^prov[a-z_]*1921$", "^cod.*prov", "^prov"), exclude = "_[0-9]+$|vol|provis", label = "province")

# ---------- demographic controls ----------
v_shbe6 <- find_col(c("sh_pop_1911_be6"), c("be6", "under6"), label = "share_under6")
v_lpop  <- find_col(c("lpop1911", "lnpop1911", "ln_pop1911", "log_pop1911", "lpop_1911", "lpop"),
                    c("^l(n|og)?_?pop.*1911$", "^l(n|og)?_?pop"), exclude = "sh_|jew|_[234]$|sq|cub", label = "log_pop1911")
if (is.na(v_lpop)) {
  v_pop <- find_col(c("pop1911", "pop_1911", "population1911", "pop1911_tot", "totpop1911"),
                    c("^pop.*1911", "pop.*1911"), exclude = "sh_|jew|6m|be6|male|_m$|share", label = "pop1911")
  if (!is.na(v_pop)) {
    df$lpop_constr <- log(to_num(df[[v_pop]]))
    v_lpop <- "lpop_constr"
  }
}
demo_terms <- character(0)
if (!is.na(v_lpop)) {
  lp <- to_num(df[[v_lpop]])
  df$lp1 <- lp; df$lp2 <- lp^2; df$lp3 <- lp^3; df$lp4 <- lp^4
  demo_terms <- c("lp1", "lp2", "lp3", "lp4")
}
if (!is.na(v_shbe6)) demo_terms <- c(demo_terms, v_shbe6)

# ---------- regiment dummies ----------
mm <- regmatches(nm, regexec("^(.*?)_?([0-9]+)$", nm))
pref <- vapply(mm, function(z) if (length(z) == 3) z[2] else NA_character_, "")
tab <- sort(table(pref[!is.na(pref)]), decreasing = TRUE)
tab <- tab[tab >= 15]
cat("Numeric-suffix prefix groups (>=15):\n"); print(head(tab, 30))
is_binary <- function(v) { x <- to_num(df[[v]]); u <- unique(x[!is.na(x)]); length(u) <= 2 && all(u %in% c(0, 1)) }
reg_cols <- character(0)
reg_pref_cands <- names(tab)[grepl("reg|rgt|brig", names(tab), ignore.case = TRUE)]
if (length(reg_pref_cands) > 0) {
  rp <- reg_pref_cands[which.max(tab[reg_pref_cands])]
  reg_cols <- nm[!is.na(pref) & pref == rp]
} else {
  bad <- "army|prov|circ|year|elec|vet|psu|fasc|pop|cas|vote|alt|area"
  cands <- names(tab)[!grepl(bad, names(tab), ignore.case = TRUE)]
  best <- NA; bestn <- 0
  for (p in cands) {
    cols <- nm[!is.na(pref) & pref == p]
    if (length(cols) >= 30 && all(vapply(head(cols, 20), is_binary, TRUE)) && length(cols) > bestn) { best <- p; bestn <- length(cols) }
  }
  if (!is.na(best)) { rp <- best; reg_cols <- nm[!is.na(pref) & pref == best] }
}
if (length(reg_cols) > 0) {
  reg_cols <- reg_cols[vapply(reg_cols, function(v) { x <- to_num(df[[v]]); sd(x, na.rm = TRUE) > 0 }, TRUE)]
}
cat("Regiment dummies:", length(reg_cols), if (length(reg_cols)) paste0("(e.g. ", paste(head(reg_cols, 5), collapse = ","), ")") else "", "\n")
for (v in reg_cols) df[[v]] <- to_num(df[[v]])

# ---------- other control blocks ----------
geo <- c(
  find_col(c("larea", "log_area", "lnarea"), c("^l.*area"), label = "log_area"),
  find_col(c("alt", "altitude", "alt_center", "alt_centro", "elevation", "alt_cen", "altcentro", "alt_main"),
           c("^alt", "elev", "altit"), exclude = "max|min|_[0-9]+$", label = "elev_center"),
  find_col(c("max_alt", "alt_max", "maxalt"), c("max.*alt"), label = "max_elev")
)
soc13 <- find_col(c("psu1913_vv"), c("psu1913", "soc.*1913"), label = "soc1913")
mil <- c(
  find_col(c("veterans74_95"), c("veterans74"), label = "vet74_95"),
  find_col(c("veterans96_00"), c("veterans96"), label = "vet96_00"),
  find_col(c("ard_vol_pop6m"), c("ard.*vol"), label = "ard_vol"),
  find_col(c("army_suppliers_d"), c("^army_suppl"), exclude = "_[0-9]+$", label = "army_suppliers"),
  find_col(c("battle_d", "battles_d", "max_battles_d", "bigbattles_d", "big_battles_d", "battle1000_d"),
           c("battle", "bigbat", "1000"), exclude = "_[0-9]+$", label = "battle_dummy")
)
agr <- c(
  find_col(c("dlab", "day_lab", "daylab"), c("dlab", "day.?lab"), exclude = "_[0-9]+$", label = "day_laborers"),
  find_col(c("shcrop", "sharecrop", "sharecroppers", "mezzadri", "scrop"), c("crop", "mezzad", "shcr"), exclude = "_[0-9]+$", label = "sharecroppers"),
  find_col(c("agr_ass_d", "agrarian_d", "landowner_d", "agr_assoc_d", "ass_agr_d", "landowners_d"),
           c("agrar", "landown", "agr_ass", "ass_agr", "assoc"), exclude = "_[0-9]+$", label = "landowner_assoc")
)
urb <- c(
  find_col(c("ind_workers"), c("ind_work"), exclude = "_[0-9]+$", label = "ind_workers"),
  find_col(c("ind_firms"), c("ind_firm"), exclude = "_[0-9]+$", label = "ind_firms"),
  find_col(c("literacy"), c("litera"), exclude = "_[0-9]+$", label = "literacy"),
  find_col(c("elites"), c("elite"), exclude = "_[0-9]+$", label = "elites"),
  find_col(c("bourgeoisie"), c("bourg"), exclude = "_[0-9]+$", label = "bourgeoisie")
)
geo <- geo[!is.na(geo)]; mil <- mil[!is.na(mil)]; agr <- agr[!is.na(agr)]; urb <- urb[!is.na(urb)]
soc13 <- soc13[!is.na(soc13)]
for (v in unique(c(demo_terms, geo, soc13, mil, agr, urb))) df[[v]] <- to_num(df[[v]])

# ---------- standardized variables ----------
df$z_soc19  <- zstd(df[[v_soc19]])
df$z_inst   <- zstd(df[[v_inst]])
df$z_viol   <- zstd(df[[v_viol]])
df$z_branch <- zstd(df[[v_branch]])
df$z_f21    <- zstd(df[[v_f21]])
df$z_f24    <- zstd(df[[v_f24]])
df$clus     <- df[[v_clus]]
df$prov     <- if (!is.na(v_prov)) df[[v_prov]] else 1

ctrl1 <- c(reg_cols, demo_terms)
ctrl6 <- c(ctrl1, geo, soc13, mil, agr, urb)
bq <- function(v) paste0("`", v, "`")
rhs <- function(ctrl) if (length(ctrl)) paste(bq(ctrl), collapse = " + ") else "1"
fe_part <- if (!is.na(v_prov)) " | prov" else ""

fs_formula <- function(ctrl) as.formula(paste0("z_soc19 ~ z_inst + ", rhs(ctrl), fe_part))
iv_formula <- function(y, ctrl) as.formula(paste0(y, " ~ ", rhs(ctrl), fe_part, " | z_soc19 ~ z_inst"))

fs1 <- feols(fs_formula(ctrl1), data = df, cluster = ~clus)
fs6 <- feols(fs_formula(ctrl6), data = df, cluster = ~clus)
b_fs1 <- unname(coef(fs1)["z_inst"])
b_fs6 <- unname(coef(fs6)["z_inst"])
t_fs6 <- unname(coef(fs6)["z_inst"] / se(fs6)["z_inst"])
F_fs6 <- t_fs6^2

iv_viol6   <- feols(iv_formula("z_viol", ctrl6), data = df, cluster = ~clus)
iv_branch6 <- feols(iv_formula("z_branch", ctrl6), data = df, cluster = ~clus)
iv_f21_6   <- feols(iv_formula("z_f21", ctrl6), data = df, cluster = ~clus)
iv_f24_1   <- feols(iv_formula("z_f24", ctrl1), data = df, cluster = ~clus)
iv_f24_6   <- feols(iv_formula("z_f24", ctrl6), data = df, cluster = ~clus)

getb <- function(m) unname(coef(m)["fit_z_soc19"])
ncl <- function(m) {
  obs <- obs(m)
  length(unique(df$clus[obs]))
}

cat("FS col1:", b_fs1, " n=", nobs(fs1), "\n")
cat("FS col6:", b_fs6, " t=", t_fs6, " n=", nobs(fs6), "\n")
cat("IV first-stage Wald (viol):\n"); print(tryCatch(fitstat(iv_viol6, "ivwald"), error = function(e) NA))

n_main <- nobs(fs6)
cl_main <- ncl(fs6)
n_21 <- nobs(iv_f21_6)
cl_21 <- ncl(iv_f21_6)

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", b_fs1))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", b_fs6))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", F_fs6))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", getb(iv_viol6)))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", getb(iv_branch6)))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", getb(iv_f21_6)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", getb(iv_f24_1)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", getb(iv_f24_6)))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", as.integer(n_main)))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", as.integer(cl_main)))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", as.integer(n_21)))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", as.integer(cl_21)))
