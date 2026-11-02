suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "/Users/matthew/dev/Retally/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
df <- as.data.frame(haven::zap_labels(haven::read_dta(path)))
nms <- names(df)

num <- function(v) suppressWarnings(as.numeric(v))

# ---------- treatment ----------
df$Above500 <- num(df$Above500)

# ---------- cluster (former owner) ----------
v <- df$Expropretario_ISTA
if (is.character(v)) v[trimws(v) == ""] <- NA
df$owner_cl <- as.character(v)
miss <- is.na(df$owner_cl)
if (any(miss) && "own_amt" %in% nms) df$owner_cl[miss] <- paste0("amt_", round(num(df$own_amt[miss]), 4))

# ---------- year ----------
df$yr <- num(df$survey_year)
if ("year" %in% nms) { yy <- num(df$year); df$yr[is.na(df$yr)] <- yy[is.na(df$yr)] }

# ---------- property id ----------
if ("match_id" %in% nms && sum(!is.na(df$match_id) & df$match_id != "") > 0.8 * nrow(df)) {
  df$prop <- as.character(df$match_id)
} else {
  rc <- if ("Reform_Coop_id" %in% nms) as.character(df$Reform_Coop_id) else NA
  hc <- if ("Hacienda_id" %in% nms) as.character(df$Hacienda_id) else NA
  rc[!is.na(rc) & trimws(rc) == ""] <- NA; hc[!is.na(hc) & trimws(hc) == ""] <- NA
  df$prop <- ifelse(!is.na(rc), paste0("C", rc), ifelse(!is.na(hc), paste0("H", hc), NA))
  if (all(is.na(df$prop))) df$prop <- as.character(df$canton)
}
df$prop <- paste(df$owner_cl, df$prop, sep = "|")

# ---------- candidate running variables and outcomes ----------
run_list <- list()
if ("own_amt" %in% nms) run_list[["own_amt-500"]] <- num(df$own_amt) - 500
if ("norm_dist" %in% nms) {
  nd <- num(df$norm_dist)
  ok <- !is.na(nd) & !is.na(df$Above500)
  if (sum(ok) > 50) {
    agr <- mean((nd[ok] >= 0) == (df$Above500[ok] == 1))
    q90 <- stats::quantile(abs(nd), 0.9, na.rm = TRUE)
    message(sprintf("norm_dist agreement %.3f q90 %.1f", agr, q90))
    if (agr > 0.97 && q90 > 20) run_list[["norm_dist"]] <- nd
  }
}
y_list <- list()
for (cn in c("hh_income_pc", "hh_inc_pc_real")) if (cn %in% nms) y_list[[cn]] <- num(df[[cn]])

# choose the combination whose bw300 sample best matches the stated
# estimation sample (workers within 300 ha, former-owner clusters)
best <- NULL; best_score <- Inf
for (rn in names(run_list)) for (yn in names(y_list)) {
  x <- run_list[[rn]]; y <- y_list[[yn]]
  ok <- !is.na(x) & !is.na(y) & !is.infinite(y) & !is.na(df$Above500) & abs(x) <= 300 & !is.na(df$yr)
  n <- sum(ok); ncl <- length(unique(df$owner_cl[ok]))
  sc <- abs(n - 4770) / 4770 + abs(ncl - 98) / 98 + ifelse(yn == "hh_income_pc", 0, 1e-6) + ifelse(rn == "own_amt-500", 0, 2e-6)
  message(sprintf("combo %s / %s: n=%d ncl=%d", rn, yn, n, ncl))
  if (sc < best_score) { best_score <- sc; best <- c(rn, yn) }
}
df$x <- run_list[[best[1]]]
df$y <- y_list[[best[2]]]
df$y[is.infinite(df$y)] <- NA
message("Running variable: ", best[1], "; outcome: ", best[2])
if (best[2] != "hh_income_pc") cat("DEVIATION: Used real (deflated) household earnings per capita, which best matched the stated sample\n")

est_level <- function(bw) {
  d <- df %>% filter(!is.na(y), !is.na(x), !is.na(Above500), abs(x) <= bw, !is.na(yr))
  m <- feols(y ~ Above500 + x + Above500:x | yr, data = d, cluster = ~owner_cl)
  list(b = unname(coef(m)["Above500"]), n = nobs(m),
       ncl = length(unique(d$owner_cl)))
}
# IQR of earnings computed within property x survey year cells
est_iqr <- function(bw) {
  d <- df %>% filter(!is.na(y), !is.na(x), !is.na(Above500), abs(x) <= bw, !is.na(yr))
  p <- d %>% group_by(prop, yr) %>%
    summarise(n = n(),
              iqr = unname(quantile(y, 0.75, na.rm = TRUE) - quantile(y, 0.25, na.rm = TRUE)),
              Above500 = first(Above500), x = first(x), owner_cl = first(owner_cl),
              .groups = "drop") %>%
    filter(n >= 2)
  m <- feols(iqr ~ Above500 + x + Above500:x | yr, data = p, cluster = ~owner_cl)
  list(b = unname(coef(m)["Above500"]), n = nobs(m))
}

safe <- function(f, ...) tryCatch(f(...), error = function(e) { message("Error: ", conditionMessage(e)); NULL })
l300 <- safe(est_level, 300); l150 <- safe(est_level, 150)
i300 <- safe(est_iqr, 300);   i150 <- safe(est_iqr, 150)

out <- function(name, val) if (!is.null(val) && length(val) && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
if (!is.null(l300)) { out("earnings_level_above500_bw300", l300$b); out("n_obs_earnings_level_bw300", l300$n); out("n_clusters_bw300", l300$ncl) }
if (!is.null(l150)) { out("earnings_level_above500_bw150", l150$b); out("n_obs_earnings_level_bw150", l150$n); out("n_clusters_bw150", l150$ncl) }
if (!is.null(i300)) { out("earnings_iqr_above500_bw300", i300$b); out("n_obs_earnings_iqr_bw300", i300$n) }
if (!is.null(i150)) { out("earnings_iqr_above500_bw150", i150$b); out("n_obs_earnings_iqr_bw150", i150$n) }
cat("DEVIATION: IQR of earnings computed within property-by-survey-year cells (min 2 workers) with survey-year fixed effects\n")
