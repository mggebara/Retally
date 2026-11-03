suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})

set.seed(42)

base <- "<repo>/.cache/datasets/hanushek_2022_patience_risk_human_capital"
f_full <- file.path(base, "Replication/Data/Working/pisa_full_gps_final.dta")
f_mig  <- file.path(base, "Replication/Data/Working/pisa_full_gps_final_imcoo.dta")

emit <- function(name, value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) return(invisible(NULL))
  cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(value)))
}

clean_df <- function(d) {
  d <- haven::zap_labels(d)
  d <- haven::zap_formats(d)
  as.data.frame(d)
}

# ------------------------------------------------------------------
# TABLE 1: cross-country analysis
# ------------------------------------------------------------------
full_vars <- c("pv1math", "patience", "risktaking", "posrecip", "negrecip",
               "altruism", "trust", "female", "age", "migra0", "migra1",
               "migra2", "image", "imfemale", "immigra1", "wave", "wgtc",
               "country")

full <- tryCatch(
  haven::read_dta(f_full, col_select = dplyr::any_of(full_vars)),
  error = function(e) {
    message("Column-select read failed: ", conditionMessage(e))
    haven::read_dta(f_full)[, intersect(full_vars, names(haven::read_dta(f_full, n_max = 1)))]
  }
)
full <- clean_df(full)

# PISA scores should be in units of 100 points (scores / 100)
if (mean(full$pv1math, na.rm = TRUE) > 50) full$pv1math <- full$pv1math / 100

full$wave <- as.integer(full$wave)
full$country_cl <- as.character(full$country)

ctrl_full <- "female + age + migra1 + migra2 + image + imfemale + immigra1"

run_t1 <- function(rhs, data) {
  fml <- as.formula(paste0("pv1math ~ ", rhs, " | wave"))
  feols(fml, data = data, weights = ~wgtc, cluster = ~country_cl,
        fixef.rm = "none", warn = FALSE, notes = FALSE)
}

m1 <- run_t1(paste("patience +", ctrl_full), full)
m2 <- run_t1(paste("risktaking +", ctrl_full), full)
m3 <- run_t1(paste("patience + risktaking +", ctrl_full), full)

natives <- full[!is.na(full$migra0) & full$migra0 == 1, ]
m5 <- run_t1("patience + risktaking + female + age + image + imfemale", natives)

emit("table1_col3_patience", coef(m3)["patience"])
emit("table1_col3_patience_se", sqrt(diag(vcov(m3)))["patience"])
emit("table1_col3_risk_taking", coef(m3)["risktaking"])
emit("table1_col3_risk_taking_se", sqrt(diag(vcov(m3)))["risktaking"])
emit("table1_col3_r2", fitstat(m3, "r2")[[1]])
emit("table1_col1_patience", coef(m1)["patience"])
emit("table1_col2_risk_taking", coef(m2)["risktaking"])
emit("table1_col5_natives_patience", coef(m5)["patience"])
emit("table1_col5_natives_risk_taking", coef(m5)["risktaking"])
emit("table1_col5_natives_observations", nobs(m5))
emit("table1_col3_observations", nobs(m3))

rm(full, natives, m1, m2, m3, m5)
invisible(gc())

# ------------------------------------------------------------------
# TABLE 2: migrant analysis
# ------------------------------------------------------------------
mig <- clean_df(haven::read_dta(f_mig))

if (mean(mig$pv1math, na.rm = TRUE) > 50) mig$pv1math <- mig$pv1math / 100

mig$countrywave <- as.character(mig$countrywave)
mig$coo_cl <- as.character(mig$coo)

ctrl_mig <- "female + age + imfemale + image + coo_oecd"

run_t2 <- function(rhs, data) {
  fml <- as.formula(paste0("pv1math ~ ", rhs, " | countrywave"))
  feols(fml, data = data, cluster = ~coo_cl,
        fixef.rm = "none", warn = FALSE, notes = FALSE)
}

t2_1 <- run_t2(paste("coo_patience +", ctrl_mig), mig)
t2_3 <- run_t2(paste("coo_patience + coo_risktaking +", ctrl_mig), mig)
t2_4 <- run_t2(paste("coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust +",
                     ctrl_mig), mig)

emit("table2_col3_patience", coef(t2_3)["coo_patience"])
emit("table2_col3_patience_se", sqrt(diag(vcov(t2_3)))["coo_patience"])
emit("table2_col3_risk_taking", coef(t2_3)["coo_risktaking"])
emit("table2_col3_risk_taking_se", sqrt(diag(vcov(t2_3)))["coo_risktaking"])
emit("table2_col3_r2", fitstat(t2_3, "r2")[[1]])
emit("table2_col1_patience", coef(t2_1)["coo_patience"])
emit("table2_col4_patience", coef(t2_4)["coo_patience"])
emit("table2_col4_risk_taking", coef(t2_4)["coo_risktaking"])
emit("table2_col3_observations", nobs(t2_3))