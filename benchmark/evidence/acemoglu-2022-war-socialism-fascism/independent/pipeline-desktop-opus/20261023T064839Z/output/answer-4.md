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

# ---------------- diagnostics: column-name patterns ----------------
pat <- gsub("[0-9]+", "#", nm)
pattab <- sort(table(pat), decreasing = TRUE)
big <- pattab[pattab >= 10]
cat("Patterns(>=10):", paste0(names(big), "(", as.integer(big), ")", collapse = " "), "\n")
regpats <- pattab[grepl("^d_reg", names(pattab))]
cat("All d_reg patterns:", paste0(names(regpats), "(", as.integer(regpats), ")", collapse = " "), "\n")

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

lpopv <- find_var(c("lpop1911", "ln_pop1911", "log_pop1911", "lnpop1911", "logpop1911", "lpop_1911", "lpop"),
                  regex = "^(l|ln|log)_?pop", exclude = "pop6m|be6|sh_|_[2-4]$|sq|cub|2$|3$|4$")
if (!is.na(lpopv)) {
  lp <- df[[lpopv]]
} else {
  popv <- find_var(c("pop1911", "pop_1911", "population1911", "totpop1911", "pop"),
                   regex = "pop.*1911|1911.*pop|^pop", exclude = "sh_|be6|pop6m|jewish|_pop$|ratio|share")
  lp <- log(df[[popv]])
}
df$lp1 <- lp; df$lp2 <- lp^2; df$lp3 <- lp^3; df$lp4 <- lp^4
shbe6 <- find_var(c("sh_pop_1911_be6"), regex = "be6")

larea <- find_var(c("larea", "lnarea", "log_area"), regex = "area")
maxalt <- find_var(c("max_alt"), regex = "max_?alt")
alt <- find_var(c("centre_alt", "alt", "altitude", "alt_center", "elevation"),
                regex = "alt|elev", exclude = "max|min|_d_|army|alter|salt")
psu13 <- find_var(c("psu1913_vv"), regex = "psu1913")
vet1 <- find_var(c("veterans74_95"), regex = "veter.*74")
vet2 <- find_var(c("veterans96_00", "veterans96_900", "veterans96_1900", "veterans1896_1900"),
                 regex = "veter.*9[6-9]|veter.*00", exclude = "74")
# Paper: "assault-troop and volunteer casualties as a share of males above 6" -> one combined variable
ardvol <- find_var(c("ard_vol_pop6m"))
if (!is.na(ardvol)) {
  assault <- ardvol; volunt <- NA_character_
} else {
  assault <- find_var(c("arditi_pop6m", "assault_pop6m"), regex = "ardit|assault|assalt")
  volunt  <- find_var(c("volunt_pop6m", "volunteers_pop6m", "volontari_pop6m", "vol_pop6m"),
                      regex = "volunt|volont|^vol_")
}
armyd <- find_var(c("army_suppliers_d"), regex = "army_?suppl|suppl")
# Dummy for any casualties in the bloodiest battles (days with > 1,000 deaths)
battle <- find_var(c("cruent_d", "battle_d", "big_battles_d", "highmort_d"), regex = "cruent")
dlab <- find_var(c("dlab"), regex = "dlab|day_?lab|braccian")
shcrop <- find_var(c("shcrop", "sharecroppers", "sharecrop", "mezzadri"),
                   regex = "crop|mezz|sharec|shcr")
landown <- find_var(c("landlord_ass", "landowners_d", "landowner_d", "agrarian_d"),
                    regex = "landown|landlord")
indw <- find_var(c("ind_workers"), regex = "ind_?work")
indf <- find_var(c("ind_firms"), regex = "ind_?firm")
lit  <- find_var(c("literacy"), regex = "litera")
eli  <- find_var(c("elites"), regex = "elite")
bou  <- find_var(c("bourgeoisie"), regex = "bourg")

found <- list(prov = prov, alt = alt, vet1 = vet1, vet2 = vet2, assault = assault, volunt = volunt,
              armyd = armyd, battle = battle, dlab = dlab, shcrop = shcrop, landown = landown,
              indw = indw, indf = indf, lit = lit, eli = eli, bou = bou, clus = clus)
for (k in names(found)) cat("Matched", k, "->", found[[k]], "\n")

# ---------------- regiment dummies ----------------
numcol <- vapply(nm, is_num, logical(1))
nonneg <- vapply(nm, function(v) {
  if (!numcol[v]) return(FALSE)
  x <- df[[v]]; x <- x[!is.na(x)]
  length(x) > 0 && all(x >= 0)
}, logical(1))
cand_pats <- names(pattab)[pattab >= 15 & grepl("#", names(pattab))]
pat_ok <- vapply(cand_pats, function(p) {
  cols <- nm[pat == p]
  mean(nonneg[cols]) > 0.9
}, logical(1))
cand_pats <- cand_pats[pat_ok]
reg_pref <- cand_pats[grepl("reg|rgt|rgm|regg|brig", cand_pats) & !grepl("region", cand_pats)]
chosen <- NA_character_
if (length(reg_pref) > 0) {
  chosen <- reg_pref[which.max(pattab[reg_pref])]
} else {
  other <- cand_pats[!grepl("army|prov|circ|elec|year|distr|veter|psu|vv|pop|^lp|sh_|share|pct|rain|temp|vote", cand_pats)]
  other <- other[pattab[other] >= 30]
  if (length(other) > 0) chosen <- other[which.max(pattab[other])]
}

make_dummies <- function(cols, prefix) {
  out <- character(0)
  k <- 0
  for (v in cols) {
    x <- df[[v]]
    d <- as.numeric(!is.na(x) & x > 0)
    if (length(unique(d)) > 1) {
      k <- k + 1
      nmv <- paste0(prefix, k)
      df[[nmv]] <<- d
      out <- c(out, nmv)
    }
  }
  out
}

reg_dummies <- character(0)
if (!is.na(chosen)) {
  cols <- nm[pat == chosen & nonneg]
  reg_dummies <- make_dummies(cols, "regd_")
  cat("Regiment pattern:", chosen, " count:", length(reg_dummies), "\n")
}
if (length(reg_dummies) == 0) cat("WARNING: no regiment dummies identified\n")

# Foot-soldier regiments beyond line infantry: bersaglieri, alpini, machine-gunners
# (the instrument counts all foot-soldier casualties, so regiment FE cover all foot-soldier regiments)
extra_cols <- nm[grepl("^d_reg[0-9]+_?(bersaglieri|alpini|mitraglieri)", nm) & nonneg]
extra_dummies <- make_dummies(extra_cols, "regx_")
cat("Extra foot-soldier regiment dummies:", length(extra_dummies), "\n")
if (length(extra_dummies) > 0) {
  cat("DEVIATION: Regiment FE extended from infantry (fanteria) regiments to all foot-soldier regiments (bersaglieri/alpini) present in the data\n")
}
reg_all <- c(reg_dummies, extra_dummies)

# ---------------- control sets ----------------
clean <- function(x) x[!is.na(x)]
demo <- clean(c("lp1", "lp2", "lp3", "lp4", shbe6))
geo  <- clean(c(larea, alt, maxalt))
pol  <- clean(c(psu13))
mil  <- clean(unique(c(vet1, vet2, assault, volunt, armyd, battle)))
agr  <- clean(c(dlab, shcrop, landown))
urb  <- clean(c(indw, indf, lit, eli, bou))
cat("Military controls:", paste(mil, collapse = " "), "\n")

ctrl_col1 <- c(demo, reg_all)
ctrl_col6 <- unique(c(demo, geo, pol, mil, agr, urb, reg_all))

sdv <- function(v) sd(df[[v]], na.rm = TRUE)

bq <- function(v) paste0("`", v, "`")
fe_part <- if (!is.na(prov)) paste0(" | ", bq(prov)) else ""

run_fs <- function(ctrls) {
  f <- as.formula(paste0(bq(endo), " ~ ", paste(c(bq(inst), bq(ctrls)), collapse = " + "), fe_part))
  feols(f, data = df, cluster = as.formula(paste0("~", bq(clus))), fixef.rm = "none")
}
run_iv <- function(y, ctrls) {
  rhs <- if (length(ctrls) > 0) paste(bq(ctrls), collapse = " + ") else "1"
  f <- as.formula(paste0(bq(y), " ~ ", rhs, fe_part, " | ", bq(endo), " ~ ", bq(inst)))
  feols(f, data = df, cluster = as.formula(paste0("~", bq(clus))), fixef.rm = "none")
}

res <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}

nclus <- function(m) {
  idx <- obs(m)
  length(unique(df[[clus]][idx]))
}

fs1 <- tryCatch(run_fs(ctrl_col1), error = function(e) { cat("fs1 error:", conditionMessage(e), "\n"); NULL })
if (!is.null(fs1)) {
  b <- coef(fs1)[inst]
  se1 <- sqrt(diag(vcov(fs1)))[inst]
  res$first_stage_casualties_table1_col1 <- b * sdv(inst) / sdv(endo)
  res$n_obs_main_sample <- nobs(fs1)
  res$n_clusters_main_sample <- nclus(fs1)
  cat("Diag: col1 first-stage F =", (b / se1)^2, "\n")
}
fs6 <- tryCatch(run_fs(ctrl_col6), error = function(e) { cat("fs6 error:", conditionMessage(e), "\n"); NULL })
if (!is.null(fs6)) {
  b <- coef(fs6)[inst]
  se <- sqrt(diag(vcov(fs6)))[inst]
  res$first_stage_casualties_table1_col6 <- b * sdv(inst) / sdv(endo)
  res$first_stage_fstat_table1_col6 <- (b / se)^2
  se_noadj <- sqrt(diag(vcov(fs6, cluster = as.formula(paste0("~", bq(clus))),
                              ssc = ssc(adj = FALSE, cluster.adj = FALSE))))[inst]
  cat("Diag: col6 F without small-sample adj =", (b / se_noadj)^2, "\n")
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
