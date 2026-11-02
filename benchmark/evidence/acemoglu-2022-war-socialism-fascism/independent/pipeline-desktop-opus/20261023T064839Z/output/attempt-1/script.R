suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free/fascism_db.dta"
df <- haven::read_dta(path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)
names(df) <- tolower(names(df))
nm <- names(df)
cat("N rows:", nrow(df), " N cols:", ncol(df), "\n")

is_num <- function(v) is.numeric(df[[v]])

find_var <- function(cands = character(0), regex = NULL, exclude = NULL, numeric = TRUE) {
  for (c in cands) if (c %in% nm && (!numeric || is_num(c))) return(c)
  if (!is.null(regex)) {
    hits <- nm[grepl(regex, nm)]
    if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits)]
    if (numeric) hits <- hits[vapply(hits, is_num, logical(1))]
    if (length(hits) > 0) {
      hits <- hits[order(nchar(hits))]
      return(hits[1])
    }
  }
  NA_character_
}

# ---------------- core variables ----------------
y_viol   <- find_var(c("fascist_violence"))
y_branch <- find_var(c("fascist_branch"))
y_v21    <- find_var(c("fascist1921_vv"))
y_v24    <- find_var(c("fascist1924_vv"))
endo     <- find_var(c("psu1919_vv"))
inst     <- find_var(c("foots_pop6m"))
clus     <- find_var(c("circondario1921", "circondario"), numeric = FALSE)

prov <- find_var(c("province1921", "provincia1921", "prov1921", "province", "provincia",
                   "prov", "prov_id", "province_id", "cod_prov", "codprov", "id_prov"),
                 regex = "^prov|provinc", exclude = "_d_|share|sh_", numeric = FALSE)
cat("Province var:", prov, "\n")

# population (log 1911)
lpopv <- find_var(c("lpop1911", "ln_pop1911", "log_pop1911", "lnpop1911", "logpop1911", "lpop_1911", "lpop"),
                  regex = "^(l|ln|log)_?pop", exclude = "pop6m|be6|sh_|_[2-4]$|sq|cub|2$|3$|4$")
if (!is.na(lpopv)) {
  lp <- df[[lpopv]]
} else {
  popv <- find_var(c("pop1911", "pop_1911", "population1911", "totpop1911", "pop"),
                   regex = "pop.*1911|1911.*pop|^pop", exclude = "sh_|be6|pop6m|jewish|_pop$|ratio|share")
  cat("Population var:", popv, "\n")
  lp <- log(df[[popv]])
}
cat("Log pop var:", lpopv, "\n")
df$lp1 <- lp; df$lp2 <- lp^2; df$lp3 <- lp^3; df$lp4 <- lp^4
shbe6 <- find_var(c("sh_pop_1911_be6"), regex = "be6")

# geographic
larea <- find_var(c("larea", "lnarea", "log_area"), regex = "area")
maxalt <- find_var(c("max_alt"), regex = "max_?alt")
alt <- find_var(c("alt", "altitude", "alt_center", "alt_centro", "altitudine", "elevation", "elev",
                  "alt_cen", "center_alt", "alt_main", "altitude_center"),
                regex = "alt|elev", exclude = "max|min|_d_|army|alter|salt")
# socialist 1913
psu13 <- find_var(c("psu1913_vv"), regex = "psu1913")
# military
vet1 <- find_var(c("veterans74_95"), regex = "veter.*74")
vet2 <- find_var(c("veterans96_00", "veterans96_900", "veterans96_1900", "veterans1896_1900"),
                 regex = "veter.*9[6-9]|veter.*00", exclude = "74")
assault <- find_var(c("arditi_pop6m", "assault_pop6m", "arditi_vol_pop6m", "assvol_pop6m",
                      "arditivol_pop6m", "special_pop6m"),
                    regex = "ardit|assault|assalt|special")
volunt  <- find_var(c("volunteers_pop6m", "volontari_pop6m", "vol_pop6m", "volunt_pop6m"),
                    regex = "volunt|volont|^vol_")
armyd <- find_var(c("army_suppliers_d"))
battle <- find_var(c("battle_d", "big_battles_d", "bigbattle_d", "highmort_d", "battles_d", "deadly_d",
                     "big_battle", "battle1000_d", "battles1000_d"),
                   regex = "battl|highmort|high_mort|deadl|1000")
# agricultural
dlab <- find_var(c("dlab"), regex = "dlab|day_?lab")
shcrop <- find_var(c("shcrop", "sharecroppers", "sharecrop", "mezzadri", "sharecr", "shcr"),
                   regex = "crop|mezz|sharec|shcr")
landown <- find_var(c("landowners_d", "landowner_d", "agrarian_d", "agr_assoc", "landowners", "agrarian_ass",
                      "agrarian", "landown_d"),
                    regex = "landown|agrar|agr_as|ass_agr|land_as")
# urban
indw <- find_var(c("ind_workers"))
indf <- find_var(c("ind_firms"))
lit  <- find_var(c("literacy"))
eli  <- find_var(c("elites"))
bou  <- find_var(c("bourgeoisie"))

found <- list(prov = prov, alt = alt, vet2 = vet2, assault = assault, volunt = volunt,
              battle = battle, shcrop = shcrop, landown = landown)
for (k in names(found)) cat("Matched", k, "->", found[[k]], "\n")

# ---------------- regiment dummies ----------------
dig <- grepl("[0-9]+$", nm)
fam <- ifelse(dig, sub("_?[0-9]+$", "", nm), NA)
famtab <- table(fam[!is.na(fam)])
fams <- names(famtab)[famtab >= 15]
fams <- fams[!grepl("army|prov|circ|elec|year|distr|veter|psu|vv|pop|lp", fams)]
isbin <- function(v) {
  x <- df[[v]]
  if (!is.numeric(x)) return(FALSE)
  u <- unique(x[!is.na(x)])
  length(u) <= 2 && all(u %in% c(0, 1))
}
reg_dummies <- character(0)
if (length(fams) > 0) {
  fam_bin <- sapply(fams, function(f) {
    cols <- nm[!is.na(fam) & fam == f]
    mean(vapply(cols[seq_len(min(30, length(cols)))], isbin, logical(1)))
  })
  fams_ok <- fams[fam_bin > 0.9]
  if (length(fams_ok) > 0) {
    pref <- fams_ok[grepl("reg|rgt|regg", fams_ok)]
    chosen <- if (length(pref) > 0) pref[which.max(famtab[pref])] else fams_ok[which.max(famtab[fams_ok])]
    reg_dummies <- nm[!is.na(fam) & fam == chosen]
    reg_dummies <- reg_dummies[vapply(reg_dummies, isbin, logical(1))]
    # drop constant dummies
    reg_dummies <- reg_dummies[vapply(reg_dummies, function(v) {
      x <- df[[v]]; length(unique(x[!is.na(x)])) > 1
    }, logical(1))]
    cat("Regiment dummy family:", chosen, " count:", length(reg_dummies), "\n")
  }
}
if (length(reg_dummies) == 0) cat("WARNING: no regiment dummies identified\n")

# ---------------- control sets ----------------
clean <- function(x) x[!is.na(x)]
demo <- clean(c("lp1", "lp2", "lp3", "lp4", shbe6))
geo  <- clean(c(larea, alt, maxalt))
pol  <- clean(c(psu13))
mil  <- clean(unique(c(vet1, vet2, assault, volunt, armyd, battle)))
agr  <- clean(c(dlab, shcrop, landown))
urb  <- clean(c(indw, indf, lit, eli, bou))

ctrl_col1 <- c(demo, reg_dummies)
ctrl_col6 <- c(demo, geo, pol, mil, agr, urb, reg_dummies)

# standardization (on full available data) of outcomes, endogenous regressor and instrument
sdv <- function(v) sd(df[[v]], na.rm = TRUE)

bq <- function(v) paste0("`", v, "`")
fe_part <- if (!is.na(prov)) paste0(" | ", bq(prov)) else ""

run_fs <- function(ctrls) {
  f <- as.formula(paste0(bq(endo), " ~ ", paste(c(bq(inst), bq(ctrls)), collapse = " + "), fe_part))
  feols(f, data = df, cluster = as.formula(paste0("~", bq(clus))))
}
run_iv <- function(y, ctrls) {
  rhs <- if (length(ctrls) > 0) paste(bq(ctrls), collapse = " + ") else "1"
  f <- as.formula(paste0(bq(y), " ~ ", rhs, fe_part, " | ", bq(endo), " ~ ", bq(inst)))
  feols(f, data = df, cluster = as.formula(paste0("~", bq(clus))))
}

res <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}

nclus <- function(m) {
  idx <- obs(m)
  length(unique(df[[clus]][idx]))
}

# Table I col 1
fs1 <- tryCatch(run_fs(ctrl_col1), error = function(e) { cat("fs1 error:", conditionMessage(e), "\n"); NULL })
if (!is.null(fs1)) {
  b <- coef(fs1)[inst]
  res$first_stage_casualties_table1_col1 <- b * sdv(inst) / sdv(endo)
  res$n_obs_main_sample <- nobs(fs1)
  res$n_clusters_main_sample <- nclus(fs1)
}
# Table I col 6
fs6 <- tryCatch(run_fs(ctrl_col6), error = function(e) { cat("fs6 error:", conditionMessage(e), "\n"); NULL })
if (!is.null(fs6)) {
  b <- coef(fs6)[inst]
  se <- sqrt(diag(vcov(fs6)))[inst]
  res$first_stage_casualties_table1_col6 <- b * sdv(inst) / sdv(endo)
  res$first_stage_fstat_table1_col6 <- (b / se)^2
  if (is.null(res$n_obs_main_sample)) {
    res$n_obs_main_sample <- nobs(fs6)
    res$n_clusters_main_sample <- nclus(fs6)
  }
}

std_iv <- function(m, y) {
  b <- coef(m)[paste0("fit_", endo)]
  if (is.na(b)) b <- coef(m)[grep("^fit_", names(coef(m)))[1]]
  b * sdv(endo) / sdv(y)
}

iv_v6 <- tryCatch(run_iv(y_viol, ctrl_col6), error = function(e) { cat("iv viol error:", conditionMessage(e), "\n"); NULL })
if (!is.null(iv_v6)) res$iv_violence_table2_panelA_col6 <- std_iv(iv_v6, y_viol)

iv_b6 <- tryCatch(run_iv(y_branch, ctrl_col6), error = function(e) { cat("iv branch error:", conditionMessage(e), "\n"); NULL })
if (!is.null(iv_b6)) res$iv_branches_table2_panelC_col6 <- std_iv(iv_b6, y_branch)

iv_21 <- tryCatch(run_iv(y_v21, ctrl_col6), error = function(e) { cat("iv 1921 error:", conditionMessage(e), "\n"); NULL })
if (!is.null(iv_21)) {
  res$iv_fascist_vote1921_table3_panelA_col6 <- std_iv(iv_21, y_v21)
  res$n_obs_fascist_vote1921 <- nobs(iv_21)
  res$n_clusters_fascist_vote1921 <- nclus(iv_21)
}

iv_24a <- tryCatch(run_iv(y_v24, ctrl_col1), error = function(e) { cat("iv 1924 c1 error:", conditionMessage(e), "\n"); NULL })
if (!is.null(iv_24a)) res$iv_fascist_vote1924_table3_panelC_col1 <- std_iv(iv_24a, y_v24)

iv_24f <- tryCatch(run_iv(y_v24, ctrl_col6), error = function(e) { cat("iv 1924 c6 error:", conditionMessage(e), "\n"); NULL })
if (!is.null(iv_24f)) res$iv_fascist_vote1924_table3_panelC_col6 <- std_iv(iv_24f, y_v24)

order_names <- c("first_stage_casualties_table1_col1", "first_stage_casualties_table1_col6",
                 "first_stage_fstat_table1_col6", "iv_violence_table2_panelA_col6",
                 "iv_branches_table2_panelC_col6", "iv_fascist_vote1921_table3_panelA_col6",
                 "iv_fascist_vote1924_table3_panelC_col1", "iv_fascist_vote1924_table3_panelC_col6",
                 "n_obs_main_sample", "n_clusters_main_sample",
                 "n_obs_fascist_vote1921", "n_clusters_fascist_vote1921")
for (n in order_names) emit(n, as.numeric(res[[n]]))