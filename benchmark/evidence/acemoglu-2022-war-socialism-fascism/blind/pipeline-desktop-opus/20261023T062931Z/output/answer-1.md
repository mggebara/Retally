suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free/fascism_db.dta"
df <- haven::read_dta(path)
df <- as.data.frame(haven::zap_labels(df))
nm <- names(df)
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")

lnm <- tolower(nm)
find_var <- function(exact = character(0), regex = character(0), exclude = NULL, label = "") {
  for (e in exact) {
    i <- which(lnm == tolower(e))
    if (length(i) > 0) { cat("Using", nm[i[1]], "for", label, "\n"); return(nm[i[1]]) }
  }
  for (r in regex) {
    i <- grep(r, lnm, perl = TRUE)
    if (!is.null(exclude) && length(i) > 0) i <- i[!grepl(exclude, lnm[i], perl = TRUE)]
    if (length(i) > 0) {
      cat("Candidates for", label, ":", paste(head(nm[i], 10), collapse = ", "), "\n")
      cat("Using", nm[i[1]], "for", label, "\n")
      return(nm[i[1]])
    }
  }
  cat("DEVIATION: variable for", label, "not found; omitted\n")
  NULL
}

numify <- function(v) { if (is.numeric(v)) v else suppressWarnings(as.numeric(as.character(v))) }

# ---------------- core variables ----------------
y_soc   <- find_var(c("psu1919_vv"), c("psu1919"), label = "socialist share 1919")
z_cas   <- find_var(c("foots_pop6m"), c("foot"), label = "foot soldier casualties")
y_viol  <- find_var(c("fascist_violence"), c("fascist_viol"), label = "fascist violence")
y_bran  <- find_var(c("fascist_branch"), c("fascist_bran"), label = "fascist branches")
y_f21   <- find_var(c("fascist1921_vv"), c("fascist1921"), exclude = "restr", label = "fascist share 1921")
y_f24   <- find_var(c("fascist1924_vv"), c("fascist1924"), label = "fascist share 1924")
clus    <- find_var(c("circondario1921", "circondario"), c("circond", "district"), label = "district cluster")
prov    <- find_var(c("province1921", "provincia1921", "prov1921", "province", "provincia", "prov",
                      "cod_prov", "codprov", "id_prov", "prov_code", "province_code"),
                    c("^prov", "provinc"), exclude = "pop|share|_vv", label = "province")

# ---------------- demographic controls ----------------
popv <- find_var(c("lpop1911", "ln_pop1911", "logpop1911", "log_pop1911", "lnpop1911", "lpop_1911", "ln_pop_1911"),
                 c("^l(n|og)?_?pop_?1911$"), label = "log population 1911")
if (is.null(popv)) {
  praw <- find_var(c("pop1911", "pop_1911", "population1911", "pop_tot1911", "poptot1911"),
                   c("^pop.*1911", "1911.*pop", "^pop"),
                   exclude = "sh_|pop6|jew|be6|_m$|male|_f$", label = "population 1911")
  if (!is.null(praw)) df$.lpop <- log(numify(df[[praw]])) else df$.lpop <- NA_real_
} else df$.lpop <- numify(df[[popv]])
df$.lpop1 <- df$.lpop; df$.lpop2 <- df$.lpop^2; df$.lpop3 <- df$.lpop^3; df$.lpop4 <- df$.lpop^4
sh6 <- find_var(c("sh_pop_1911_be6"), c("be6"), label = "share below six")
demo <- c(".lpop1", ".lpop2", ".lpop3", ".lpop4", sh6)

# ---------------- geographic ----------------
larea <- find_var(c("larea"), c("^l(n|og)?_?area"), label = "log area")
alt   <- find_var(c("alt", "altitude", "altitudine", "elevation", "alt_center", "alt_centro", "alt_main"),
                  c("^alt", "elev", "altit"), exclude = "max|min|range", label = "elevation main center")
malt  <- find_var(c("max_alt"), c("max_?alt", "max_?elev"), label = "max elevation")
geo <- c(larea, alt, malt)

# ---------------- 1913 socialist ----------------
s13 <- find_var(c("psu1913_vv"), c("psu1913"), label = "socialist share 1913")

# ---------------- military ----------------
v74 <- find_var(c("veterans74_95"), c("veterans74"), label = "veterans 1874-95")
v96 <- find_var(c("veterans96_00"), c("veterans96"), label = "veterans 1896-1900")
avp <- find_var(c("ard_vol_pop6m"), c("ard_vol"), label = "assault+volunteer casualties")
arm <- find_var(c("army_suppliers_d"), c("army_suppl"), label = "army suppliers dummy")
bat <- find_var(c("battles_d", "battle_d", "big_battles", "big_battles_d", "highmort_d", "bloody_battles", "deadliest_d"),
                c("battle", "bloody", "highmort", "high_mort", "deadl", "1000"), label = "high-mortality battle dummy")
mil <- c(v74, v96, avp, arm, bat)

# ---------------- agricultural ----------------
dlab <- find_var(c("dlab"), c("day_?lab", "bracc"), label = "day laborers")
shc  <- find_var(c("shcrop", "sharecroppers", "sharecrop", "mezzadri", "mezz", "sharec"),
                 c("sharecrop", "mezzad", "shcrop", "share_?crop", "^mezz"), label = "sharecroppers")
agas <- find_var(c("agr_assoc", "landowner_assoc", "agrarian_assoc", "agrarian_d", "agr_assoc_d", "landowners_d"),
                 c("agrar", "landown", "agr_?ass", "assoc"), label = "landowner association")
agr <- c(dlab, shc, agas)

# ---------------- urban ----------------
iw  <- find_var(c("ind_workers"), c("ind_work"), label = "industrial workers")
ifm <- find_var(c("ind_firms"), c("ind_firm"), label = "industrial firms")
lit <- find_var(c("literacy"), c("literac"), label = "literacy")
eli <- find_var(c("elites"), c("^elite"), label = "elites")
bou <- find_var(c("bourgeoisie"), c("bourg"), label = "bourgeoisie")
urb <- c(iw, ifm, lit, eli, bou)

# ---------------- regiment dummies ----------------
reg_idx <- grep("^(d_?)?(reg|rgt|regg|regt|regiment|reggimento)[a-z_]*_?[0-9]+$", lnm, perl = TRUE)
if (length(reg_idx) == 0) reg_idx <- grep("regiment|reggim|^rgt", lnm, perl = TRUE)
reg_vars <- nm[reg_idx]
# keep binary non-constant columns
reg_vars <- reg_vars[sapply(reg_vars, function(v) {
  x <- numify(df[[v]]); ux <- unique(x[!is.na(x)])
  length(ux) == 2 && all(ux %in% c(0, 1))
})]
cat("Regiment dummies found:", length(reg_vars), "\n")
if (length(reg_vars) > 0) cat("  e.g.", paste(head(reg_vars, 5), collapse = ", "), "\n")
if (length(reg_vars) == 0) cat("DEVIATION: regiment dummies not found; omitted\n")

# numeric conversion
allv <- unique(c(y_soc, z_cas, y_viol, y_bran, y_f21, y_f24, demo, geo, s13, mil, agr, urb, reg_vars))
for (v in allv) df[[v]] <- numify(df[[v]])
# drop control variables that are entirely missing
keep_ok <- function(vs) vs[sapply(vs, function(v) !is.null(v) && sum(!is.na(df[[v]])) > 0.5 * nrow(df))]
demo <- keep_ok(demo); geo <- keep_ok(geo); mil <- keep_ok(mil); agr <- keep_ok(agr); urb <- keep_ok(urb)
if (!is.null(s13)) s13 <- keep_ok(s13)

# standardize LHS and RHS variables
stdz <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
std_vars <- unique(c(y_soc, z_cas, y_viol, y_bran, y_f21, y_f24, demo, geo, s13, mil, agr, urb))
for (v in std_vars) {
  x <- df[[v]]
  if (sd(x, na.rm = TRUE) > 0) df[[v]] <- stdz(x)
}

df$.prov <- factor(df[[prov]])
df$.clus <- df[[clus]]

ctrl_sets <- list(
  c1 = c(demo, reg_vars),
  c6 = c(demo, reg_vars, geo, s13, mil, agr, urb)
)
bt <- function(v) paste0("`", v, "`")
rhs <- function(vs) if (length(vs) == 0) "1" else paste(bt(vs), collapse = " + ")

fs <- function(cs) {
  f <- as.formula(paste0(bt(y_soc), " ~ ", bt(z_cas), " + ", rhs(cs), " | .prov"))
  feols(f, data = df, cluster = ~.clus)
}
iv <- function(y, cs) {
  f <- as.formula(paste0(bt(y), " ~ ", rhs(cs), " | .prov | ", bt(y_soc), " ~ ", bt(z_cas)))
  feols(f, data = df, cluster = ~.clus)
}
getc <- function(m, v) unname(coef(m)[v])

m1 <- fs(ctrl_sets$c1)
m6 <- fs(ctrl_sets$c6)
b1 <- getc(m1, z_cas); b6 <- getc(m6, z_cas)
se6 <- unname(sqrt(diag(vcov(m6)))[z_cas])
F6 <- (b6 / se6)^2

fitv <- paste0("fit_", y_soc)
mv6  <- iv(y_viol, ctrl_sets$c6)
mb6  <- iv(y_bran, ctrl_sets$c6)
m21  <- iv(y_f21, ctrl_sets$c6)
m24a <- iv(y_f24, ctrl_sets$c1)
m24f <- iv(y_f24, ctrl_sets$c6)

nclus <- function(m) {
  obs <- obs(m)
  length(unique(df$.clus[obs]))
}

print(summary(m6, keep = z_cas))
print(etable(mv6, mb6, m21, m24a, m24f, keep = y_soc))

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", b1))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", b6))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", F6))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", getc(mv6, fitv)))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", getc(mb6, fitv)))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", getc(m21, fitv)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", getc(m24a, fitv)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", getc(m24f, fitv)))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", nobs(m6)))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", nclus(m6)))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", nobs(m21)))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", nclus(m21)))
