# Exploratory: first-stage strength of the price instruments under alternative exogenous sets
# (paper reports first-stage F 379.6 / Cragg-Donald 1936 pooled, 6.957 / 7.58 with household FE).
suppressMessages({library(haven); library(data.table); library(fixest)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- as.data.table(read_dta(f))
s <- d[!is.na(T2) & !is.na(SITUACTHOG_j) & !is.na(lny) & !is.na(NHABIT) & !is.na(SUPERF) & !is.na(edif25) & !is.na(urban)]
setFixest_notes(FALSE)
X0 <- "NMIEMB + NHABIT + SUPERF + mayores + i(ESTUDREDSP) + i(SITUACTHOG_j) + alqui + edif25 + i(TAMAMU) + urban + CAPROV + i(CCAA)"
fs <- function(lab, p = "lnPRE", zs = c("lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_"), time = "dist + i(trim) + i(year)", X = X0, fe = FALSE) {
  fml <- as.formula(paste(p, "~ TT202 + lny + lny2 +", time, if (X != "") paste("+", X) else "", "+", paste(zs, collapse = "+"), if (fe) "| id" else ""))
  m1 <- feols(fml, s, cluster = ~id); m0 <- feols(fml, s, vcov = "iid")
  k <- paste0("^(", paste(zs, collapse="|"), ")$")
  cat(sprintf("%-30s fe=%d robustF=%8.2f iidF=%8.2f\n", lab, fe, wald(m1, keep = k, print = FALSE)$stat, wald(m0, keep = k, print = FALSE)$stat))
}
fs("baseline"); fs("baseline", fe = TRUE)
fs("no year FE", time = "dist + i(trim)"); fs("no year FE", time = "dist + i(trim)", fe = TRUE)
fs("no months", time = "i(trim) + i(year)")
fs("no quarter", time = "dist + i(year)")
fs("no time controls", time = "1")
fs("no controls X", X = "")
fs("lnaPRE instruments", zs = c("lnaPRE_papas","lnaPRE_aguav","lnaPRE_gascar"))
fs("nominal p, deflated z", p = "lnp_kwh")
fs("LnPRE_M as price", p = "LnPRE_M")
