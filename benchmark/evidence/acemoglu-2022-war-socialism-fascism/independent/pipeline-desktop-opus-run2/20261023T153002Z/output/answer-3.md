suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free"
d <- haven::read_dta(file.path(base, "fascism_db.dta"))
d <- haven::zap_labels(d)
d <- as.data.frame(d)
n <- nrow(d)
nm <- names(d)
lnm <- tolower(nm)

msg <- function(...) message(paste0(...))

is_num <- function(v) is.numeric(v) || is.logical(v)
is_binary <- function(v) {
  if (!is_num(v)) return(FALSE)
  u <- unique(v[!is.na(v)])
  length(u) >= 1 && all(u %in% c(0, 1))
}
good_cov <- function(v) is_num(v) && sum(!is.na(v)) >= 0.98 * n && length(unique(v[!is.na(v)])) > 1
cov90_bin <- function(v) is_num(v) && sum(!is.na(v)) >= 0.90 * n && is_binary(v) &&
  length(unique(v[!is.na(v)])) > 1

pick_exact <- function(cands, filt = NULL) {
  for (x in cands) {
    i <- match(tolower(x), lnm)
    if (!is.na(i)) {
      if (is.null(filt) || filt(d[[nm[i]]])) return(nm[i])
    }
  }
  NULL
}
pick_pat <- function(pats, exclude = character(0), filt = NULL) {
  for (p in pats) {
    hits <- nm[grepl(p, lnm, perl = TRUE)]
    hits <- setdiff(hits, exclude)
    if (!is.null(filt)) hits <- hits[vapply(hits, function(h) filt(d[[h]]), logical(1))]
    if (length(hits) > 0) return(hits[1])
  }
  NULL
}
pick <- function(exact, pats = character(0), exclude = character(0), filt = NULL) {
  r <- pick_exact(exact, filt)
  if (is.null(r) && length(pats) > 0) r <- pick_pat(pats, exclude, filt)
  r
}

# ---- core variables ----
y_viol   <- pick(c("fascist_violence"))
y_branch <- pick(c("fascist_branch"))
y_v21    <- pick(c("fascist1921_vv"))
y_v24    <- pick(c("fascist1924_vv"))
x_soc    <- pick(c("psu1919_vv"))
z_inst   <- pick(c("foots_pop6m"))
clus     <- pick(c("circondario1921", "circondario", "district1921", "district", "circ1921", "circ"))
msg("cluster var: ", clus, " levels=", length(unique(d[[clus]][!is.na(d[[clus]])])),
    " NA=", sum(is.na(d[[clus]])))

# ---- province ----
prov <- pick_exact(c("province", "provincia", "prov", "province1921", "provincia1921",
                     "prov1921", "cod_prov", "codprov", "prov_code", "id_prov", "province_id",
                     "provincia_1921", "province_1921", "cod_prov1921", "prov_id"))
if (is.null(prov)) {
  cands <- nm[grepl("prov", lnm)]
  if (length(cands) > 0) {
    nu <- vapply(cands, function(h) length(unique(d[[h]][!is.na(d[[h]])])), numeric(1))
    nna <- vapply(cands, function(h) sum(!is.na(d[[h]])), numeric(1))
    ok <- nu >= 40 & nu <= 100 & nna >= 0.98 * n
    if (any(ok)) {
      cc <- cands[ok]; nuu <- nu[ok]
      prov <- cc[which.min(abs(nuu - 64))]
    }
  }
}
msg("province var: ", ifelse(is.null(prov), "NONE", prov))

# ---- population (quartic in log population) ----
lpop_name <- pick_exact(c("lpop1911", "lnpop1911", "log_pop1911", "lpop_1911", "ln_pop1911",
                          "lpop", "lnpop", "logpop", "ln_pop", "log_pop", "lpop1921", "lnpop1921"),
                        filt = good_cov)
if (!is.null(lpop_name)) {
  lp <- as.numeric(d[[lpop_name]])
} else {
  pop_name <- pick_exact(c("pop1911", "pop_1911", "population1911", "totpop1911", "pop1921",
                           "pop_1921", "pop", "population", "popres1911", "pop_tot1911"),
                         filt = good_cov)
  if (is.null(pop_name)) pop_name <- pick_pat(c("^pop_?19(11|21)$", "^pop.*1911$", "^pop"),
                                               filt = function(v) good_cov(v) && median(v, na.rm = TRUE) > 50)
  if (!is.null(pop_name)) {
    lp <- log(pmax(as.numeric(d[[pop_name]]), 1))
  } else {
    lp <- NULL
  }
  lpop_name <- pop_name
}
msg("population var: ", ifelse(is.null(lpop_name), "NONE", lpop_name))
if (!is.null(lp)) {
  d$lp1_ <- lp; d$lp2_ <- lp^2; d$lp3_ <- lp^3; d$lp4_ <- lp^4
  demo <- c("lp1_", "lp2_", "lp3_", "lp4_")
} else demo <- character(0)
demo <- c(demo, pick(c("sh_pop_1911_be6")))

# ---- regiment dummies ----
bin_ok <- vapply(nm, function(h) is_binary(d[[h]]), logical(1))
tmpl <- gsub("[0-9]+", "#", lnm)
has_digit <- grepl("[0-9]", lnm)
fam_ok <- bin_ok & has_digit & !grepl("prov", lnm) & !grepl("^(province|provincia|prov)", tmpl)
fams <- table(tmpl[fam_ok])
fams <- fams[fams >= 20]
reg <- character(0)
if (length(fams) > 0) {
  fn <- names(fams)
  pref_fams <- fn[grepl("reg|rgt|rgm|regg|brig|regiment|reggim|^r#|^r_#|^rg", fn)]
  msg("binary digit families: ", paste(paste0(fn, "(", as.integer(fams), ")"), collapse = " "))
  chosen <- if (length(pref_fams) > 0) {
    pref_fams[which.max(as.integer(fams[pref_fams]))]
  } else fn[which.max(as.integer(fams))]
  reg <- nm[fam_ok & tmpl == chosen]
  msg("regiment family chosen: ", chosen)
}
if (length(reg) == 0) {
  reg <- nm[grepl("regiment|reggim|^reg_|^d_reg|^rgt", lnm) & bin_ok & !grepl("prov", lnm)]
}
reg <- reg[vapply(reg, function(h) { v <- d[[h]]; sum(v == 1, na.rm = TRUE) > 0 && sum(!is.na(v)) >= 0.5 * n }, logical(1))]
msg("regiment dummies: ", length(reg), if (length(reg)) paste0(" (e.g. ", paste(head(reg, 3), collapse = ","), ")") else "")
for (h in reg) d[[h]][is.na(d[[h]])] <- 0

# exclusion set for broad searches: dummy families (regiments, front-month dummies)
fam_excl <- nm[grepl("^d_reg|^d_fr", lnm) | (fam_ok & tmpl %in% names(fams))]

# ---- control blocks ----
geo <- c(pick(c("larea", "lnarea", "log_area")),
         pick(c("alt", "altitude", "elevation", "alt_centro", "altitudine", "alt_center", "alt_main", "elev",
                "min_alt", "alt_mun", "altitude_center"),
              c("^alt", "elev", "altit", "_alt$", "alt_"), exclude = c("max_alt", "MAX_ALT"),
              filt = function(v) good_cov(v) && !is_binary(v)),
         pick(c("max_alt")))
soc13 <- pick(c("psu1913_vv"))

battle <- pick(c("battle_d", "big_battle", "bigbattle_d", "battles_d", "high_mort_battle", "battle1000_d",
                 "bigbattles_d", "big_battles_d", "battle1000", "deadly_battle_d"),
               c("battle", "bigbat", "batt", "high_?mort", "1000", "deadl", "big_?day", "maxday",
                 "max_?death", "highdeath", "heavy", "mass_?death", "bloody", "offens", "isonzo",
                 "caporet", "piave", "strafe", "mort.*_d$", "death.*_d$", "dead.*_d$", "casual.*_d$"),
               exclude = fam_excl, filt = cov90_bin)
landown <- pick(c("landowners_d", "agrarian_d", "agr_assoc", "agr_assoc_d", "landowner_assoc", "agrarian_assoc",
                  "landowner_d", "landown_d", "agrarian", "landowners"),
                c("landown", "landl", "agrar", "agr_?ass", "ass_?agr", "assoc", "owner", "padron",
                  "proprie", "feder", "asso", "lord", "agri"),
                exclude = c(fam_excl, nm[grepl("vv$|pop6m", lnm)]), filt = cov90_bin)
msg("battle var: ", ifelse(is.null(battle), "NONE", battle),
    " | landowner var: ", ifelse(is.null(landown), "NONE", landown))
for (h in c(battle, landown)) {
  if (any(is.na(d[[h]]))) {
    cat(sprintf("DEVIATION: Filled %d missing values of dummy %s with 0 to keep the full sample\n",
                sum(is.na(d[[h]])), h))
    d[[h]][is.na(d[[h]])] <- 0
  }
}

mil <- c(pick(c("veterans74_95")),
         pick(c("veterans96_00", "veterans96_900", "veterans1896_1900", "veterans96_1900"),
              c("^veterans9", "^veterans.*96", "^veterans1896"), exclude = c("veterans74_95"), filt = good_cov),
         pick(c("arditi_pop6m")),
         pick(c("volunteers_pop6m", "volunt_pop6m", "vol_pop6m", "volontari_pop6m"),
              c("volunt.*pop6m", "volont.*pop6m", "^vol.*pop6m"), filt = good_cov),
         pick(c("army_suppliers_d")),
         battle)
agr <- c(pick(c("dlab", "daylab", "day_lab")),
         pick(c("sharecroppers", "sharecr", "mezzadri", "shcrop"),
              c("sharecr", "mezzad", "^shcr", "share_?crop"), filt = good_cov),
         landown)
urb <- c(pick(c("ind_workers")), pick(c("ind_firms")), pick(c("literacy")),
         pick(c("elites")), pick(c("bourgeoisie")))

clean <- function(v) { v <- unique(v[!is.null(v)]); v[vapply(v, function(h) good_cov(d[[h]]), logical(1))] }
demo <- clean(demo); geo <- clean(geo); soc13 <- clean(soc13); mil <- clean(mil); agr <- clean(agr); urb <- clean(urb)
msg("demo: ", paste(demo, collapse = ","))
msg("geo: ", paste(geo, collapse = ","))
msg("soc13: ", paste(soc13, collapse = ","))
msg("mil: ", paste(mil, collapse = ","))
msg("agr: ", paste(agr, collapse = ","))
msg("urb: ", paste(urb, collapse = ","))

ctrl1 <- c(reg, demo)
ctrl6 <- c(reg, demo, geo, soc13, mil, agr, urb)

# ---- standardize LHS and RHS (dataset-wide, as with egen std) ----
zs <- function(v) { v <- as.numeric(v); (v - mean(v, na.rm = TRUE)) / sd(v, na.rm = TRUE) }
d$z_x  <- zs(d[[x_soc]])
d$z_z  <- zs(d[[z_inst]])
d$z_vi <- zs(d[[y_viol]])
d$z_br <- zs(d[[y_branch]])
d$z_21 <- zs(d[[y_v21]])
d$z_24 <- zs(d[[y_v24]])
d$clus_ <- d[[clus]]
fe_part <- if (!is.null(prov)) { d$prov_ <- d[[prov]]; "prov_" } else "0"

bt <- function(v) paste0("`", v, "`")
rhs <- function(ctrl) if (length(ctrl)) paste(bt(ctrl), collapse = " + ") else "1"

fs_fit <- function(ctrl) {
  f <- as.formula(paste0("z_x ~ z_z + ", rhs(ctrl), " | ", fe_part))
  feols(f, data = d, cluster = ~clus_, fixef.rm = "none")
}
iv_fit <- function(y, ctrl) {
  f <- as.formula(paste0(y, " ~ ", rhs(ctrl), " | ", fe_part, " | z_x ~ z_z"))
  feols(f, data = d, cluster = ~clus_, fixef.rm = "none")
}
nclus <- function(m) {
  o <- obs(m)
  length(unique(d$clus_[o]))
}

fs1 <- fs_fit(ctrl1)
fs6 <- fs_fit(ctrl6)
b_fs1 <- coef(fs1)["z_z"]
b_fs6 <- coef(fs6)["z_z"]
se_fs6 <- sqrt(diag(vcov(fs6)))["z_z"]
F6 <- (b_fs6 / se_fs6)^2

iv_vi6 <- iv_fit("z_vi", ctrl6)
iv_br6 <- iv_fit("z_br", ctrl6)
iv_216 <- iv_fit("z_21", ctrl6)
iv_241 <- iv_fit("z_24", ctrl1)
iv_246 <- iv_fit("z_24", ctrl6)

gx <- function(m) unname(coef(m)["fit_z_x"])
gse <- function(m) unname(sqrt(diag(vcov(m)))["fit_z_x"])

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", b_fs1))
cat(sprintf("RESULT:first_stage_casualties_table1_col1_se=%.6f\n", sqrt(diag(vcov(fs1)))["z_z"]))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", b_fs6))
cat(sprintf("RESULT:first_stage_casualties_table1_col6_se=%.6f\n", se_fs6))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", F6))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", gx(iv_vi6)))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6_se=%.6f\n", gse(iv_vi6)))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", gx(iv_br6)))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6_se=%.6f\n", gse(iv_br6)))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", gx(iv_216)))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6_se=%.6f\n", gse(iv_216)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", gx(iv_241)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1_se=%.6f\n", gse(iv_241)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", gx(iv_246)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6_se=%.6f\n", gse(iv_246)))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", as.integer(nobs(fs1))))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", as.integer(nclus(fs1))))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", as.integer(nobs(iv_216))))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", as.integer(nclus(iv_216))))
