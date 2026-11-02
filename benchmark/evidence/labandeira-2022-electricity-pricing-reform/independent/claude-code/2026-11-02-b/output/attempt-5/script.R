# Exploratory: how are the deflated price variables built, and how strong are candidate instruments?
suppressMessages({library(haven); library(data.table); library(fixest)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- as.data.table(read_dta(f))
s <- d[!is.na(T2) & !is.na(SITUACTHOG_j) & !is.na(lny) & !is.na(NHABIT) & !is.na(SUPERF) & !is.na(edif25) & !is.na(urban)]
cat("N", nrow(s), "\n")
s[, `:=`(a1 = lnPRE - lnp_kwh, a2 = lnPRE_papas - lnp_papas, a3 = lnPRE_aguav - lnp_aguav, a4 = lnPRE_gascar - lnp_gascar,
         chk = lng_ele - lnc_ele - lnp_kwh, ly = lny - log(y), lyad = lny_ad - log(y_ad))]
print(summary(s[, .(IP, a1, a2, a3, a4, chk, ly, lyad, LnPRE_M, lnaPRE_papas, lnPRE_papas_ - lnPRE_papas)]))
cat("cor(a1, IP)", cor(s$a1, s$IP), " sd a1", sd(s$a1), " sd IP", sd(s$IP), "\n")
cat("cor(-a1, IP) max abs diff", max(abs(s$a1 + s$IP)), "\n")
cat("ly vs IP max abs diff", max(abs(s$ly + s$IP), na.rm=TRUE), "\n")
cat("share of instrument fills: papas", mean(is.na(s$lnPRE_papas)), " aguav", mean(is.na(s$lnPRE_aguav)), " gascar", mean(is.na(s$lnPRE_gascar)), "\n")
cat("lnPRE_papas_ == lnaPRE_papas where NA:", all.equal(s[is.na(lnPRE_papas), lnPRE_papas_], s[is.na(lnPRE_papas), lnaPRE_papas]), "\n")
# IP within-household change by T
s[, dIP := IP - mean(IP), by = id]
print(s[, .(meanIP = mean(IP), sdIP = sd(IP)), by = .(year, T2)][order(year, T2)])
ctrl <- "lny + lny2 + dist + NMIEMB + NHABIT + SUPERF + mayores + i(ESTUDREDSP) + i(SITUACTHOG_j) + alqui + edif25 + i(TAMAMU) + urban + CAPROV + i(CCAA) + i(trim) + i(year)"
fs <- function(p, zs, fe) {
  f1 <- as.formula(paste(p, "~ T2 +", ctrl, "+", paste(zs, collapse = "+"), if (fe) "| id" else ""))
  m <- feols(f1, s, cluster = ~id)
  w <- wald(m, keep = paste0("^(", paste(zs, collapse="|"), ")$"), print = FALSE)
  cat(sprintf("%-8s fe=%d  z={%s}  N=%d  clusterF=%.2f\n", p, fe, paste(zs, collapse=","), nobs(m), w$stat))
}
for (fe in c(FALSE, TRUE)) {
  fs("lnPRE", c("lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_"), fe)
  fs("lnPRE", c("lnaPRE_papas","lnaPRE_aguav","lnaPRE_gascar"), fe)
  fs("lnPRE", c("lnPRE_papas","lnPRE_aguav","lnPRE_gascar"), fe)
  fs("lnp_kwh", c("lnp_papas","lnp_aguav","lnp_gascar"), fe)
  fs("LnPRE_M", c("lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_"), fe)
}
