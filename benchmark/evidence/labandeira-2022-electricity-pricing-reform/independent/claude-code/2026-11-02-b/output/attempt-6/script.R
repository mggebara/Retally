# Specification grid around the baseline (attempt-4 spec), plus baseline RESULT lines.
set.seed(42)
suppressMessages({library(haven); library(data.table); library(fixest)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- as.data.table(read_dta(f))
s <- d[!is.na(T2) & !is.na(SITUACTHOG_j) & !is.na(lny) & !is.na(NHABIT) & !is.na(SUPERF) & !is.na(edif25) & !is.na(urban)]
s[, `:=`(lnyn = log(y), lnyn2 = log(y)^2, ym = factor(year*100 + month))]
setFixest_notes(FALSE)
X0 <- "NMIEMB + NHABIT + SUPERF + mayores + i(ESTUDREDSP) + i(SITUACTHOG_j) + alqui + edif25 + i(TAMAMU) + urban + CAPROV + i(CCAA)"
run <- function(lab, Tv = "T2", p = "lnPRE", inc = "lny + lny2", time = "dist + i(trim) + i(year)", X = X0, extra = "", w = NULL) {
  out <- c()
  for (dep in c("lnc_ele", "lng_ele")) for (fe in c(FALSE, TRUE)) {
    fml <- as.formula(paste(dep, "~", Tv, "+", p, "+", inc, "+", time, if (X != "") paste("+", X) else "", extra, if (fe) "| id" else ""))
    m <- feols(fml, s, cluster = ~id, weights = w)
    out <- c(out, sprintf("%.3f/%.3f", coef(m)[Tv], coef(m)[p]))
  }
  cat(sprintf("%-28s cons OLS %s | cons FE %s | exp OLS %s | exp FE %s\n", lab, out[1], out[2], out[3], out[4]))
}
cat("target                       cons OLS -0.178/-1.044 | cons FE -0.154/-1.026 | exp OLS -0.156/-0.049 | exp FE -0.098/-0.027\n")
run("A baseline")
run("B no months", time = "i(trim) + i(year)")
run("C no year FE", time = "dist + i(trim)")
run("D no quarter", time = "dist + i(year)")
run("E T=TT202", Tv = "TT202")
run("F +D(Tm)", extra = "+ Tm")
run("G nominal p", p = "lnp_kwh")
run("H nominal p & y", p = "lnp_kwh", inc = "lnyn + lnyn2")
run("I no controls", X = "")
run("J weights FACTOR", w = ~FACTOR)
run("K months as Tm*dist", time = "i(trim) + i(year)", extra = "+ Tm:dist")
run("L lny_ad income", inc = "lny_ad + I(lny_ad^2)")
run("M year x quarter", time = "dist + i(trim):i(year)")
run("N no months no year", time = "i(trim)")

# baseline RESULT lines (spec A = attempt-4 spec; OLS/FE columns only, IV columns not recomputed in this grid run)
fa <- function(dep, fe) feols(as.formula(paste(dep, "~ T2 + lnPRE + lny + lny2 + dist + i(trim) + i(year) +", X0, if (fe) "| id" else "")), s, cluster = ~id)
m1 <- fa("lnc_ele", FALSE); m3 <- fa("lnc_ele", TRUE); m5 <- fa("lng_ele", FALSE); m7 <- fa("lng_ele", TRUE)
cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(m1)["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(m3)["T2"]))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(m5)["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(m7)["T2"]))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(m1)["lnPRE"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(m3)["lnPRE"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(s)))
cat(sprintf("RESULT:n_households_table2=%d\n", uniqueN(s$id)))
