suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free"
f_main <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_mig  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

get_names <- function(f) {
  nm <- tryCatch(names(haven::read_dta(f, n_max = 0)), error = function(e) NULL)
  if (is.null(nm) || length(nm) == 0) nm <- names(haven::read_dta(f, n_max = 1))
  nm
}

pick_weight <- function(nm) {
  exact <- c("weight", "wgt", "stuwgt", "studwgt", "cntwgt", "cntrywgt", "senwgt",
             "senate_wgt", "w_senate", "weight_c", "wgt_c", "w_c", "cweight", "countryweight",
             "w_country", "wt", "w")
  hit <- exact[exact %in% nm]
  if (length(hit)) return(list(var = hit[1], raw = FALSE))
  rx <- nm[grepl("(wgt|weight|wt)", nm, ignore.case = TRUE) &
             !grepl("^w_fstr", nm) & nm != "w_fstuwt"]
  if (length(rx)) return(list(var = rx[1], raw = FALSE))
  if ("w_fstuwt" %in% nm) return(list(var = "w_fstuwt", raw = TRUE))
  list(var = NA_character_, raw = TRUE)
}

num <- function(x) as.numeric(haven::zap_labels(x))

rescale_math <- function(x) {
  x <- num(x)
  if (isTRUE(median(x, na.rm = TRUE) > 20)) x <- x / 100
  x
}

safe_coef <- function(m, v) {
  out <- tryCatch(unname(coef(m)[v]), error = function(e) NA_real_)
  if (length(out) == 0) NA_real_ else out
}
safe_se <- function(m, v) {
  out <- tryCatch(unname(sqrt(diag(vcov(m)))[v]), error = function(e) NA_real_)
  if (length(out) == 0) NA_real_ else out
}

res <- list()

## ---------------- Cross-country analysis (Table 1) ----------------
nm <- get_names(f_main)
cat("Main file columns:", length(nm), "\n")
wsel <- pick_weight(nm)
cat("Weight variable (main):", wsel$var, " raw:", wsel$raw, "\n")
cat("Weight-like vars:", paste(nm[grepl("(wgt|weight|wt)", nm, ignore.case = TRUE) & !grepl("^w_fstr", nm)], collapse = ","), "\n")

mig_dum <- nm[grepl("^(migra[0-9]|mig[0-9]|firstgen|secondgen|native|migrant)$", nm)]
imp_vars <- nm[grepl("^im(female|age|mig.*|migra.*)$", nm)]
cat("Migration vars:", paste(mig_dum, collapse = ","), "\n")
cat("Imputation vars:", paste(imp_vars, collapse = ","), "\n")

need <- unique(c("country", "wave", "pv1math", "patience", "risktaking",
                 "female", "age", mig_dum, imp_vars, wsel$var))
need <- need[!is.na(need) & need %in% nm]
dt <- as.data.table(haven::read_dta(f_main, col_select = dplyr::all_of(need)))
for (v in names(dt)) {
  if (v == "country") next
  dt[[v]] <- num(dt[[v]])
}
dt[, country := as.character(haven::as_factor(country))]
dt[, math := rescale_math(pv1math)]
cat("Rows main:", nrow(dt), "\n")

if (is.na(wsel$var)) {
  dt[, w0 := 1]
} else {
  dt[, w0 := get(wsel$var)]
}
## equal total weight per country, within-country proportional to sampling weights
dt[, w := w0 / sum(w0, na.rm = TRUE), by = country]
dt[, w := w * 1e4]

ctrl <- c("female", "age", mig_dum, imp_vars)
ctrl <- ctrl[ctrl %in% names(dt)]
ctrl <- ctrl[sapply(ctrl, function(v) isTRUE(sd(dt[[v]], na.rm = TRUE) > 0))]
ctrl_str <- paste(ctrl, collapse = " + ")

mk <- function(prefs, ctrls) {
  as.formula(paste("math ~", paste(c(prefs, ctrls), collapse = " + "), "| wave"))
}

m1 <- feols(mk("patience", ctrl), data = dt, weights = ~w, cluster = ~country, lean = TRUE)
m2 <- feols(mk("risktaking", ctrl), data = dt, weights = ~w, cluster = ~country, lean = TRUE)
m3 <- feols(mk(c("patience", "risktaking"), ctrl), data = dt, weights = ~w, cluster = ~country, lean = TRUE)
print(summary(m3))

res$table1_col3_patience <- safe_coef(m3, "patience")
res$table1_col3_risk_taking <- safe_coef(m3, "risktaking")
res$table1_col3_patience_se <- safe_se(m3, "patience")
res$table1_col3_risk_taking_se <- safe_se(m3, "risktaking")
res$table1_col1_patience <- safe_coef(m1, "patience")
res$table1_col2_risk_taking <- safe_coef(m2, "risktaking")
res$table1_col3_observations <- nobs(m3)
res$table1_col3_r2 <- tryCatch(unname(r2(m3, "r2")), error = function(e) NA_real_)

## Natives subsample: candidate definitions of migrant status, report diagnostics
nat_cands <- list()
impmig <- imp_vars[grepl("mig", imp_vars)]
notimp <- if (length(impmig)) rowSums(as.matrix(dt[, ..impmig]) != 0, na.rm = TRUE) == 0 else rep(TRUE, nrow(dt))
has <- function(v) v %in% names(dt)
if (has("migra1") && has("migra2")) {
  mm <- (dt$migra1 %in% 1) | (dt$migra2 %in% 1)
  nat_cands$a <- !mm & notimp & !is.na(dt$migra1) & !is.na(dt$migra2)
  if (has("migra0")) {
    nat_cands$b <- (dt$migra0 %in% 1) & notimp
    nat_cands$c <- !mm & !(dt$migra0 %in% 1) & notimp
  }
}
if (has("native")) nat_cands$d <- (dt$native %in% 1) & notimp
if (has("migrant")) nat_cands$e <- (dt$migrant %in% 0) & notimp
if (length(mig_dum) == 1) nat_cands$f <- (dt[[mig_dum]] %in% 0) & notimp
for (k in names(nat_cands)) cat("Natives candidate", k, ":", sum(nat_cands[[k]]), "\n")

if (length(nat_cands)) {
  ## choose the definition whose implied size is closest to the documented natives N
  sizes <- sapply(nat_cands, sum)
  pick <- names(sizes)[which.min(abs(sizes - 1751822))]
  cat("Natives definition chosen:", pick, "\n")
  dn <- dt[nat_cands[[pick]]]
  ctrl_n <- setdiff(ctrl, c(mig_dum, impmig))
  ctrl_n <- ctrl_n[sapply(ctrl_n, function(v) isTRUE(sd(dn[[v]], na.rm = TRUE) > 0))]
  m5 <- feols(mk(c("patience", "risktaking"), ctrl_n), data = dn, weights = ~w,
              cluster = ~country, lean = TRUE)
  res$table1_col5_natives_patience <- safe_coef(m5, "patience")
  res$table1_col5_natives_risk_taking <- safe_coef(m5, "risktaking")
  res$table1_col5_natives_observations <- nobs(m5)
  rm(dn, m5)
}
rm(dt, m1, m2, m3); invisible(gc())

## ---------------- Migrant analysis (Table 2) ----------------
mnm <- get_names(f_mig)
wm <- pick_weight(mnm)
cat("Weight variable (migrants):", wm$var, " raw:", wm$raw, "\n")
find1 <- function(cands) { h <- cands[cands %in% mnm]; if (length(h)) h[1] else NA_character_ }
v_pos <- find1(c("coo_posrecip", "coo_posrecip_orig"))
v_neg <- find1(c("coo_negrecip", "coo_negrecip_orig"))
v_alt <- find1(c("coo_altruism", "coo_altruism_orig"))
v_tru <- find1(c("coo_trust", "coo_trust_orig"))
mimp <- mnm[grepl("^im(female|age)$", mnm)]
mneed <- unique(c("country", "wave", "countrywave", "coo", "pv1math", "coo_patience", "coo_risktaking",
                  "coo_oecd", "female", "age", mimp, v_pos, v_neg, v_alt, v_tru, wm$var))
mneed <- mneed[!is.na(mneed) & mneed %in% mnm]
dm <- as.data.table(haven::read_dta(f_mig, col_select = dplyr::all_of(mneed)))
for (v in names(dm)) {
  if (v %in% c("country", "coo", "countrywave")) {
    dm[[v]] <- as.character(haven::as_factor(dm[[v]]))
  } else dm[[v]] <- num(dm[[v]])
}
if (!"countrywave" %in% names(dm)) dm[, countrywave := paste(country, wave)]
dm[, math := rescale_math(pv1math)]
if (is.na(wm$var)) dm[, wmig := 1] else dm[, wmig := get(wm$var)]
if (wm$raw) dm[, wmig := wmig / sum(wmig, na.rm = TRUE), by = country]
cat("Rows migrants:", nrow(dm), "\n")

mctrl <- c("female", "age", "coo_oecd", mimp)
mctrl <- mctrl[mctrl %in% names(dm)]
mctrl <- mctrl[sapply(mctrl, function(v) isTRUE(sd(dm[[v]], na.rm = TRUE) > 0))]
mkm <- function(prefs) as.formula(paste("math ~", paste(c(prefs, mctrl), collapse = " + "), "| countrywave"))

t1 <- feols(mkm("coo_patience"), data = dm, weights = ~wmig, cluster = ~coo)
t3 <- feols(mkm(c("coo_patience", "coo_risktaking")), data = dm, weights = ~wmig, cluster = ~coo)
print(summary(t3))
others <- c(v_pos, v_neg, v_alt, v_tru); others <- others[!is.na(others)]
t4 <- feols(mkm(c("coo_patience", "coo_risktaking", others)), data = dm, weights = ~wmig, cluster = ~coo)

res$table2_col3_patience <- safe_coef(t3, "coo_patience")
res$table2_col3_risk_taking <- safe_coef(t3, "coo_risktaking")
res$table2_col3_patience_se <- safe_se(t3, "coo_patience")
res$table2_col3_risk_taking_se <- safe_se(t3, "coo_risktaking")
res$table2_col1_patience <- safe_coef(t1, "coo_patience")
res$table2_col4_patience <- safe_coef(t4, "coo_patience")
res$table2_col4_risk_taking <- safe_coef(t4, "coo_risktaking")
res$table2_col3_observations <- nobs(t3)

for (k in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", k, format(res[[k]], digits = 10, scientific = FALSE)))
}
