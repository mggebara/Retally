suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital.script-free"
f_full <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_mig  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

# ---------------------------------------------------------------
# helpers
# ---------------------------------------------------------------
get_labels <- function(df0) {
  sapply(names(df0), function(v) {
    l <- attr(df0[[v]], "label")
    if (is.null(l)) "" else as.character(l)
  })
}

pick_weight <- function(nms, labs) {
  # prefer an already rescaled/senate weight, otherwise the raw final student weight
  pref <- c("senwgt", "senate_wgt", "senatewgt", "sweight", "weight", "wgt", "stuweight",
            "stweight", "w_senate", "w_fstuwt_s", "w_fstuwt_senate", "cntwgt", "wt")
  hit <- pref[pref %in% nms]
  if (length(hit) > 0) return(list(var = hit[1], raw = FALSE))
  lab_hit <- nms[grepl("senate|rescal|equal", labs, ignore.case = TRUE) &
                   grepl("weight|wgt", labs, ignore.case = TRUE)]
  if (length(lab_hit) > 0) return(list(var = lab_hit[1], raw = FALSE))
  if ("w_fstuwt" %in% nms) return(list(var = "w_fstuwt", raw = TRUE))
  wn <- nms[grepl("wgt|weight|wt$", nms, ignore.case = TRUE) & !grepl("^w_fstr", nms)]
  if (length(wn) > 0) return(list(var = wn[1], raw = TRUE))
  list(var = NA_character_, raw = TRUE)
}

rescale_equal_country <- function(w, country, wave) {
  # within each country-wave weights sum to 1, then each country sums to 1 overall
  d <- data.frame(w = as.numeric(w), c = country, t = wave)
  d$w[is.na(d$w)] <- 0
  s_ct <- ave(d$w, d$c, d$t, FUN = sum)
  w1 <- ifelse(s_ct > 0, d$w / s_ct, 0)
  nw <- ave(as.numeric(as.factor(paste(d$c, d$t))), d$c,
            FUN = function(x) length(unique(x)))
  w1 / nw
}

first_present <- function(cands, nms) {
  h <- cands[cands %in% nms]
  if (length(h) == 0) NA_character_ else h[1]
}

num <- function(x) as.numeric(zap_labels(x))

coefval <- function(m, v) unname(coef(m)[v])

# ---------------------------------------------------------------
# Cross-country sample (Table 1)
# ---------------------------------------------------------------
hdr <- read_dta(f_full, n_max = 1)
nms <- names(hdr)
labs <- get_labels(hdr)

wsel <- pick_weight(nms, labs)
if (is.na(wsel$var)) cat("DEVIATION: no sampling weight variable found; running unweighted\n")

female_v <- first_present(c("female", "girl", "sex"), nms)
age_v    <- first_present(c("age", "agestud", "st_age"), nms)
imf_v    <- first_present(c("imfemale", "imgirl"), nms)
ima_v    <- first_present(c("image", "image_"), nms)
mig_dummies <- intersect(c("migra1", "migra2"), nms)
immig_v  <- first_present(c("immigra", "immig", "immigrant_im", "immigration_im", "immigra0"), nms)
mig0_v   <- first_present(c("migra0"), nms)

need <- unique(na.omit(c("country", "wave", "pv1math", "patience", "risktaking",
                         female_v, age_v, imf_v, ima_v, mig_dummies, mig0_v, immig_v,
                         wsel$var, "isocode")))
need <- need[need %in% nms]

df <- read_dta(f_full, col_select = all_of(need))
df <- as.data.frame(lapply(df, function(x) if (is.labelled(x)) zap_labels(x) else x))
cat(sprintf("SAMPLE:table1_full:loaded=%d\n", nrow(df)))

df$country <- as.character(df$country)
df$wave <- num(df$wave)
df$pv1math <- num(df$pv1math)
# outcome should be PISA score / 100
if (mean(df$pv1math, na.rm = TRUE) > 50) df$pv1math <- df$pv1math / 100

df <- df[!is.na(df$patience) & !is.na(df$risktaking), ]
cat(sprintf("SAMPLE:table1_full:countries_with_gps=%d\n", nrow(df)))
df <- df[!is.na(df$pv1math), ]
cat(sprintf("SAMPLE:table1_full:nonmissing_math=%d\n", nrow(df)))
cat(sprintf("SAMPLE:table1_full:n_countries=%d\n", length(unique(df$country))))
cat(sprintf("SAMPLE:table1_full:n_country_waves=%d\n", nrow(unique(df[, c("country", "wave")]))))

if (!is.na(wsel$var)) {
  if (wsel$raw) {
    df$w <- rescale_equal_country(df[[wsel$var]], df$country, df$wave)
  } else {
    df$w <- num(df[[wsel$var]])
    df$w[is.na(df$w)] <- 0
  }
} else {
  df$w <- 1
}

# Controls: gender, age, migration status, imputation dummies
ctrl <- c()
for (v in c(female_v, age_v, imf_v, ima_v)) {
  if (!is.na(v)) { df[[v]] <- num(df[[v]]); df[[v]][is.na(df[[v]])] <- 0; ctrl <- c(ctrl, v) }
}
# migration status: first/second-generation dummies plus missing indicator
if (length(mig_dummies) > 0) {
  mis_mig <- rep(FALSE, nrow(df))
  for (v in mig_dummies) { df[[v]] <- num(df[[v]]); mis_mig <- mis_mig | is.na(df[[v]]) }
  if (!is.na(mig0_v)) { df[[mig0_v]] <- num(df[[mig0_v]]); mis_mig <- mis_mig & is.na(df[[mig0_v]]) | mis_mig }
  for (v in mig_dummies) { df[[v]][is.na(df[[v]])] <- 0; ctrl <- c(ctrl, v) }
  if (!is.na(immig_v)) {
    df[[immig_v]] <- num(df[[immig_v]]); df[[immig_v]][is.na(df[[immig_v]])] <- 0
    ctrl <- c(ctrl, immig_v)
  } else {
    df$immig_missing <- as.numeric(mis_mig)
    if (sum(df$immig_missing) > 0) ctrl <- c(ctrl, "immig_missing")
  }
}
ctrl <- unique(ctrl)
ctrl_str <- if (length(ctrl) > 0) paste(ctrl, collapse = " + ") else "1"

f1 <- as.formula(paste("pv1math ~ patience +", ctrl_str, "| wave"))
f2 <- as.formula(paste("pv1math ~ risktaking +", ctrl_str, "| wave"))
f3 <- as.formula(paste("pv1math ~ patience + risktaking +", ctrl_str, "| wave"))

m1 <- feols(f1, data = df, weights = ~w, cluster = ~country)
m2 <- feols(f2, data = df, weights = ~w, cluster = ~country)
m3 <- feols(f3, data = df, weights = ~w, cluster = ~country)
cat(sprintf("SAMPLE:table1_full:estimation=%d\n", nobs(m3)))
if (nobs(m3) != 1992276) cat(sprintf("DEVIATION: Table 1 full-sample N is %d, paper reports 1,992,276\n", nobs(m3)))

# Natives (column 5): students not classified as migrants (both parents born abroad)
cat(sprintf("SAMPLE:table1_natives:loaded=%d\n", nrow(df)))
if (!is.na(mig0_v)) {
  nat <- df[!is.na(df[[mig0_v]]) & df[[mig0_v]] == 1, ]
} else if (length(mig_dummies) > 0) {
  nat <- df[rowSums(df[, mig_dummies, drop = FALSE]) == 0 &
              (if ("immig_missing" %in% names(df)) df$immig_missing == 0 else TRUE), ]
} else {
  nat <- df
  cat("DEVIATION: no migration status variable found; natives sample equals full sample\n")
}
if (!is.na(immig_v) && immig_v %in% names(nat)) nat <- nat[nat[[immig_v]] == 0, ]
cat(sprintf("SAMPLE:table1_natives:natives_only=%d\n", nrow(nat)))
ctrl_nat <- setdiff(ctrl, c(mig_dummies, immig_v, "immig_missing"))
ctrl_nat_str <- if (length(ctrl_nat) > 0) paste(ctrl_nat, collapse = " + ") else "1"
f5 <- as.formula(paste("pv1math ~ patience + risktaking +", ctrl_nat_str, "| wave"))
m5 <- feols(f5, data = nat, weights = ~w, cluster = ~country)
cat(sprintf("SAMPLE:table1_natives:estimation=%d\n", nobs(m5)))
if (abs(nobs(m5) - 1751822) > 0) cat(sprintf("DEVIATION: natives N is %d, paper reports 1,751,822\n", nobs(m5)))

n_t1 <- nobs(m3)
rm(df, nat); invisible(gc())

# ---------------------------------------------------------------
# Migrant sample (Table 2)
# ---------------------------------------------------------------
mg <- read_dta(f_mig)
mg <- as.data.frame(lapply(mg, function(x) if (is.labelled(x)) zap_labels(x) else x))
mn <- names(mg)
mlabs <- get_labels(read_dta(f_mig, n_max = 1))
cat(sprintf("SAMPLE:table2_migrants:loaded=%d\n", nrow(mg)))

mg$pv1math <- num(mg$pv1math)
if (mean(mg$pv1math, na.rm = TRUE) > 50) mg$pv1math <- mg$pv1math / 100
mg$wave <- num(mg$wave)
mg$country <- as.character(mg$country)
mg$coo <- as.character(mg$coo)

mg <- mg[mg$wave >= 2003, ]
cat(sprintf("SAMPLE:table2_migrants:waves_2003_2018=%d\n", nrow(mg)))
mg <- mg[!is.na(mg$coo_patience) & !is.na(mg$coo_risktaking), ]
cat(sprintf("SAMPLE:table2_migrants:origin_with_gps=%d\n", nrow(mg)))
mg <- mg[!is.na(mg$pv1math), ]
cat(sprintf("SAMPLE:table2_migrants:nonmissing_math=%d\n", nrow(mg)))

mw <- pick_weight(mn, mlabs)
if (!is.na(mw$var)) {
  if (mw$raw) mg$w <- rescale_equal_country(mg[[mw$var]], mg$country, mg$wave)
  else { mg$w <- num(mg[[mw$var]]); mg$w[is.na(mg$w)] <- 0 }
} else {
  mg$w <- 1
  cat("DEVIATION: no weight variable found in migrant file; unweighted\n")
}

mctrl <- c()
for (v in c(first_present(c("female", "girl"), mn), first_present(c("age"), mn),
            "coo_oecd", first_present(c("imfemale"), mn), first_present(c("image"), mn))) {
  if (!is.na(v) && v %in% mn) { mg[[v]] <- num(mg[[v]]); mg[[v]][is.na(mg[[v]])] <- 0; mctrl <- c(mctrl, v) }
}
mctrl_str <- paste(unique(mctrl), collapse = " + ")

other_cands <- list(
  posrecip = c("coo_posrecip", "coo_posrecip_orig"),
  negrecip = c("coo_negrecip", "coo_negrecip_orig"),
  altruism = c("coo_altruism", "coo_altruism_orig"),
  trust    = c("coo_trust", "coo_trust_orig")
)
others <- sapply(other_cands, function(cc) first_present(cc, mn))
others <- others[!is.na(others)]
if (length(others) < 4) cat("DEVIATION: not all four other origin GPS preferences found\n")

if (!("countrywave" %in% mn)) mg$countrywave <- paste(mg$country, mg$wave)

g1 <- as.formula(paste("pv1math ~ coo_patience +", mctrl_str, "| countrywave"))
g3 <- as.formula(paste("pv1math ~ coo_patience + coo_risktaking +", mctrl_str, "| countrywave"))
g4 <- as.formula(paste("pv1math ~ coo_patience + coo_risktaking +", paste(others, collapse = " + "),
                       "+", mctrl_str, "| countrywave"))

t1 <- feols(g1, data = mg, weights = ~w, cluster = ~coo)
t3 <- feols(g3, data = mg, weights = ~w, cluster = ~coo)
t4 <- feols(g4, data = mg, weights = ~w, cluster = ~coo)
cat(sprintf("SAMPLE:table2_migrants:estimation=%d\n", nobs(t3)))
if (nobs(t3) != 80398) cat(sprintf("DEVIATION: Table 2 N is %d, paper reports 80,398\n", nobs(t3)))

# ---------------------------------------------------------------
# Results
# ---------------------------------------------------------------
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])
cat(sprintf("RESULT:table1_col3_patience=%.6f\n", coefval(m3, "patience")))
cat(sprintf("RESULT:table1_col3_patience_se=%.6f\n", se(m3, "patience")))
cat(sprintf("RESULT:table1_col3_risk_taking=%.6f\n", coefval(m3, "risktaking")))
cat(sprintf("RESULT:table1_col3_risk_taking_se=%.6f\n", se(m3, "risktaking")))
cat(sprintf("RESULT:table1_col3_r2=%.6f\n", r2(m3, "r2")))
cat(sprintf("RESULT:table1_col1_patience=%.6f\n", coefval(m1, "patience")))
cat(sprintf("RESULT:table1_col2_risk_taking=%.6f\n", coefval(m2, "risktaking")))
cat(sprintf("RESULT:table1_col5_natives_patience=%.6f\n", coefval(m5, "patience")))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.6f\n", coefval(m5, "risktaking")))
cat(sprintf("RESULT:table1_col3_observations=%d\n", n_t1))
cat(sprintf("RESULT:table2_col3_patience=%.6f\n", coefval(t3, "coo_patience")))
cat(sprintf("RESULT:table2_col3_patience_se=%.6f\n", se(t3, "coo_patience")))
cat(sprintf("RESULT:table2_col3_risk_taking=%.6f\n", coefval(t3, "coo_risktaking")))
cat(sprintf("RESULT:table2_col3_risk_taking_se=%.6f\n", se(t3, "coo_risktaking")))
cat(sprintf("RESULT:table2_col1_patience=%.6f\n", coefval(t1, "coo_patience")))
cat(sprintf("RESULT:table2_col4_patience=%.6f\n", coefval(t4, "coo_patience")))
cat(sprintf("RESULT:table2_col4_risk_taking=%.6f\n", coefval(t4, "coo_risktaking")))
cat(sprintf("RESULT:table2_col3_observations=%d\n", nobs(t3)))
