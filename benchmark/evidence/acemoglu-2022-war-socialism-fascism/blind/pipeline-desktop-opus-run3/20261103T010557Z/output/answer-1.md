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
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")

is_binary <- function(x) {
  if (!is.numeric(x)) return(FALSE)
  u <- unique(x[!is.na(x)])
  length(u) >= 1 && all(u %in% c(0, 1))
}

pick <- function(patterns, exclude = NULL, prefer_binary = FALSE, prefer_nonbinary = FALSE) {
  for (p in patterns) {
    c0 <- grep(p, nm, ignore.case = TRUE, value = TRUE)
    if (!is.null(exclude)) c0 <- c0[!grepl(exclude, c0, ignore.case = TRUE)]
    c0 <- c0[sapply(c0, function(v) is.numeric(df[[v]]))]
    if (length(c0) == 0) next
    if (prefer_binary) {
      b <- c0[sapply(c0, function(v) is_binary(df[[v]]))]
      if (length(b) > 0) c0 <- b
    }
    if (prefer_nonbinary) {
      b <- c0[!sapply(c0, function(v) is_binary(df[[v]]))]
      if (length(b) > 0) c0 <- b
    }
    # prefer shortest / fewest NA
    nas <- sapply(c0, function(v) sum(is.na(df[[v]])))
    c0 <- c0[order(nas, nchar(c0))]
    return(c0[1])
  }
  NA_character_
}

## ---- Core variables ----
y_soc19 <- "psu1919_vv"
inst    <- "foots_pop6m"
clus    <- "circondario1921"

## ---- Province identifier ----
prov_c <- grep("prov", nm, ignore.case = TRUE, value = TRUE)
prov_c <- prov_c[!grepl("_d$|dummy", prov_c)]
prov_ok <- prov_c[sapply(prov_c, function(v) {
  k <- length(unique(df[[v]][!is.na(df[[v]])])); k >= 40 && k <= 90
})]
if (length(prov_ok) == 0) prov_ok <- prov_c
prov_ok <- prov_ok[order(!grepl("1921", prov_ok), sapply(prov_ok, function(v) sum(is.na(df[[v]]))), nchar(prov_ok))]
prov <- prov_ok[1]
cat("Province var:", prov, " (#", length(unique(df[[prov]])), ")\n")
df$prov_fe <- as.factor(df[[prov]])

## ---- Population quartic ----
lpop_c <- grep("^(l|ln|log)_?pop.*1911|^(l|ln|log)_?pop", nm, ignore.case = TRUE, value = TRUE)
lpop_c <- lpop_c[!grepl("be6|6m|_d$|sh_|share|[_]?[234]$|sq|cub", lpop_c)]
lpop_c <- lpop_c[sapply(lpop_c, function(v) {
  x <- df[[v]]; is.numeric(x) && median(x, na.rm = TRUE) > 2 && median(x, na.rm = TRUE) < 15
})]
if (length(lpop_c) > 0) {
  lpop_c <- lpop_c[order(!grepl("1911", lpop_c), nchar(lpop_c))]
  df$lp1 <- df[[lpop_c[1]]]
  cat("Log pop var:", lpop_c[1], "\n")
} else {
  pop_c <- grep("pop", nm, ignore.case = TRUE, value = TRUE)
  pop_c <- pop_c[grepl("1911", pop_c) & !grepl("be6|6m|_d$|sh_|share|jew|pop6", pop_c)]
  pop_c <- pop_c[sapply(pop_c, function(v) {
    x <- df[[v]]; is.numeric(x) && median(x, na.rm = TRUE) > 100
  })]
  if (length(pop_c) == 0) {
    pop_c <- grep("^pop", nm, ignore.case = TRUE, value = TRUE)
    pop_c <- pop_c[sapply(pop_c, function(v) {
      x <- df[[v]]; is.numeric(x) && median(x, na.rm = TRUE) > 100
    })]
  }
  pop_c <- pop_c[order(nchar(pop_c))]
  cat("Pop var:", pop_c[1], "\n")
  df$lp1 <- log(df[[pop_c[1]]])
}
df$lp2 <- df$lp1^2; df$lp3 <- df$lp1^3; df$lp4 <- df$lp1^4
demo <- c("lp1", "lp2", "lp3", "lp4", "sh_pop_1911_be6")

## ---- Regiment dummies ----
find_groups <- function(cands, minsize) {
  cands <- cands[grepl("[0-9]+$", cands)]
  if (length(cands) == 0) return(character(0))
  pref <- sub("_?[0-9]+$", "", cands)
  bin <- sapply(cands, function(v) is_binary(df[[v]]))
  cands <- cands[bin]; pref <- pref[bin]
  if (length(cands) == 0) return(character(0))
  tab <- sort(table(pref), decreasing = TRUE)
  tab <- tab[!grepl("army_suppl|prov|year|elect|circ|region", names(tab))]
  if (length(tab) == 0 || tab[1] < minsize) return(character(0))
  cands[pref == names(tab)[1]]
}
reg_c <- grep("reg", nm, ignore.case = TRUE, value = TRUE)
reg_c <- reg_c[!grepl("region", reg_c, ignore.case = TRUE)]
regs <- find_groups(reg_c, 10)
if (length(regs) == 0) regs <- find_groups(nm, 50)
# drop constant dummies
regs <- regs[sapply(regs, function(v) length(unique(df[[v]][!is.na(df[[v]])])) > 1)]
cat("Regiment dummies:", length(regs), " e.g.", head(regs, 3), "\n")

## ---- Control blocks ----
geo <- c("larea", pick(c("^centre_alt$", "centre_alt|center_alt|alt_cent")), pick(c("^max_alt$", "max_alt")))
s13 <- "psu1913_vv"
vet <- grep("^veteran", nm, ignore.case = TRUE, value = TRUE)
if (length(vet) > 2) {
  v1 <- vet[grepl("74|95", vet)][1]; v2 <- vet[grepl("96|00", vet)][1]
  vet <- na.omit(c(v1, v2))
}
battle <- pick(c("battle", "batt", "mlarge", "high_?mort", "maxmort", "large_?d"), prefer_binary = TRUE)
mil <- c(vet, "ard_vol_pop6m", "army_suppliers_d", battle)
sharecr <- pick(c("sharecr", "mezzadr", "share_?crop", "scrop", "^sc_?1911$", "^sc$"), exclude = "_d$")
landown <- pick(c("landown", "agrar", "agr_?ass", "assoc"), prefer_binary = TRUE)
agr <- c("dlab", sharecr, landown)
urb <- c(pick(c("^ind_workers$", "ind_work")), pick(c("^ind_firms$", "ind_firm")),
         pick(c("^literacy$", "litera")), pick(c("^elites$", "elite")), pick(c("^bourgeoisie$", "bourg")))

clean <- function(v) { v <- v[!is.na(v)]; v[v %in% nm | v %in% names(df)] }
geo <- clean(geo); mil <- clean(mil); agr <- clean(agr); urb <- clean(urb)
cat("Geo:", geo, "\nMil:", mil, "\nAgr:", agr, "\nUrb:", urb, "\n")

## ---- Standardize ----
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
df$z_soc19 <- z(df[[y_soc19]])
df$z_inst  <- z(df[[inst]])
df$z_viol  <- z(df$fascist_violence)
df$z_branch <- z(df$fascist_branch)
df$z_f21   <- z(df$fascist1921_vv)
df$z_f24   <- z(df$fascist1924_vv)

bt <- function(v) paste0("`", v, "`")
ctrl1 <- c(demo, regs)
ctrl6 <- c(demo, regs, geo, s13, mil, agr, urb)

fs_formula <- function(ctrl) as.formula(paste("z_soc19 ~ z_inst +", paste(bt(ctrl), collapse = " + "), "| prov_fe"))
iv_formula <- function(y, ctrl) as.formula(paste(y, "~", paste(bt(ctrl), collapse = " + "), "| prov_fe | z_soc19 ~ z_inst"))

fs1 <- feols(fs_formula(ctrl1), data = df, cluster = as.formula(paste0("~", clus)))
fs6 <- feols(fs_formula(ctrl6), data = df, cluster = as.formula(paste0("~", clus)))

b1 <- coef(fs1)["z_inst"]
b6 <- coef(fs6)["z_inst"]
se6 <- sqrt(diag(vcov(fs6)))["z_inst"]
F6 <- (b6 / se6)^2
cat("FS col1:", b1, " N=", nobs(fs1), "\n")
cat("FS col6:", b6, " se=", se6, " N=", nobs(fs6), "\n")

ivv <- feols(iv_formula("z_viol", ctrl6), data = df, cluster = as.formula(paste0("~", clus)))
ivb <- feols(iv_formula("z_branch", ctrl6), data = df, cluster = as.formula(paste0("~", clus)))
iv21 <- feols(iv_formula("z_f21", ctrl6), data = df, cluster = as.formula(paste0("~", clus)))
iv24a <- feols(iv_formula("z_f24", ctrl1), data = df, cluster = as.formula(paste0("~", clus)))
iv24f <- feols(iv_formula("z_f24", ctrl6), data = df, cluster = as.formula(paste0("~", clus)))

gc <- function(m) unname(coef(m)["fit_z_soc19"])
ncl <- function(m) {
  obs <- obs(m)
  length(unique(df[[clus]][obs]))
}

n_main <- nobs(fs1)
ncl_main <- ncl(fs1)
n21 <- nobs(iv21)
ncl21 <- ncl(iv21)

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", unname(b1)))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", unname(b6)))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", unname(F6)))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", gc(ivv)))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", gc(ivb)))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", gc(iv21)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", gc(iv24a)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", gc(iv24f)))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", as.integer(n_main)))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", as.integer(ncl_main)))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", as.integer(n21)))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", as.integer(ncl21)))
