suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
df <- as.data.frame(haven::zap_labels(haven::read_dta(path)))
nms <- names(df)
message("Columns: ", paste(nms, collapse = ", "))

num <- function(v) suppressWarnings(as.numeric(v))

# ---------- treatment ----------
df$Above500 <- num(df$Above500)

# ---------- running variable (former owner's holdings centred at 500) ----------
agree <- function(x) {
  ok <- !is.na(x) & !is.na(df$Above500)
  if (sum(ok) < 50) return(0)
  mean((x[ok] >= 0) == (df$Above500[ok] == 1))
}
run_cands <- unique(c("norm_dist_Above", "own_amt",
                      grep("landhold|holding|dist_above|own_amt|owner_size|tot_land",
                           nms, ignore.case = TRUE, value = TRUE)))
run_cands <- run_cands[run_cands %in% nms]
best <- NULL; best_score <- -1
for (cn in run_cands) {
  v <- num(df[[cn]])
  if (all(is.na(v))) next
  for (shift in c(0, 500)) {
    x <- v - shift
    a <- agree(x)
    sc <- stats::quantile(abs(x), 0.9, na.rm = TRUE)
    if (is.na(sc) || sc < 20) next
    score <- a + ifelse(cn == "norm_dist_Above", 0.001, 0)
    message(sprintf("run cand %s shift %d: agreement %.3f, q90|x| %.1f", cn, shift, a, sc))
    if (score > best_score) { best_score <- score; best <- list(cn = cn, shift = shift) }
  }
}
if (is.null(best)) stop("No running variable found")
df$x <- num(df[[best$cn]]) - best$shift
message("Running variable: ", best$cn, " - ", best$shift)

# ---------- cluster (former owner) ----------
cl_cands <- c("Expropretario_ISTA", grep("owner|propiet|expropr", nms, ignore.case = TRUE, value = TRUE))
cl_cands <- unique(cl_cands[cl_cands %in% nms])
clvar <- NULL
for (cn in cl_cands) {
  v <- df[[cn]]
  if (is.character(v)) v[trimws(v) == ""] <- NA
  if (sum(!is.na(v)) > 0.8 * nrow(df) && length(unique(v[!is.na(v)])) > 20) { clvar <- cn; break }
}
if (is.null(clvar)) {
  df$owner_cl <- as.character(round(num(df$own_amt), 4))
} else {
  v <- df[[clvar]]; if (is.character(v)) v[trimws(v) == ""] <- NA
  df$owner_cl <- as.character(v)
  # fill missing owner ids with holdings value
  miss <- is.na(df$owner_cl)
  if (any(miss) && "own_amt" %in% nms) df$owner_cl[miss] <- paste0("amt_", round(num(df$own_amt[miss]), 4))
}
message("Cluster var: ", ifelse(is.null(clvar), "own_amt", clvar))

# ---------- outcome: household earnings per capita ----------
pick_outcome <- function() {
  pri <- c("ingpe", "Income_pc", "income_pc", "HH_Income_pc", "Earnings_pc", "earnings_pc",
           "hh_income_pc", "Household_Income_pc", "Income_per_capita", "income_per_capita",
           "HH_Earnings_pc", "Earnings_per_capita", "ingpe_hh")
  for (p in pri) if (p %in% nms) return(p)
  pc <- grep("(per.?cap|percap|_pc$|_pc_|^pc_|ingpe)", nms, ignore.case = TRUE, value = TRUE)
  pc <- pc[!grepl("land", pc, ignore.case = TRUE)]
  pc2 <- pc[grepl("inc|earn|ing|wage|money", pc, ignore.case = TRUE)]
  if (length(pc2)) return(pc2[1])
  if (length(pc)) return(pc[1])
  NULL
}
yname <- pick_outcome()
if (is.null(yname)) {
  inc <- grep("income|earn|ingreso|ingfa", nms, ignore.case = TRUE, value = TRUE)
  inc <- inc[!grepl("land|other", inc, ignore.case = TRUE)]
  hs <- grep("hh_?size|household_?size|members|tot_?pers|miembros", nms, ignore.case = TRUE, value = TRUE)
  if (length(inc) && length(hs)) {
    df$y <- num(df[[inc[1]]]) / num(df[[hs[1]]])
    message("Outcome constructed: ", inc[1], " / ", hs[1])
  } else if (length(inc)) {
    df$y <- num(df[[inc[1]]]); message("Outcome fallback: ", inc[1])
  } else stop("No outcome found")
} else {
  df$y <- num(df[[yname]]); message("Outcome: ", yname)
}
df$y[is.infinite(df$y)] <- NA

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

df$survey_year <- num(df$survey_year)

res <- list()
est_level <- function(bw) {
  d <- df %>% filter(!is.na(y), !is.na(x), !is.na(Above500), abs(x) <= bw, !is.na(survey_year))
  m <- feols(y ~ Above500 + x + Above500:x | survey_year, data = d, cluster = ~owner_cl)
  list(b = unname(coef(m)["Above500"]), se = unname(sqrt(diag(vcov(m)))["Above500"]),
       n = nobs(m), ncl = length(unique(d$owner_cl[!is.na(d$y)])))
}
est_iqr <- function(bw) {
  d <- df %>% filter(!is.na(y), !is.na(x), !is.na(Above500), abs(x) <= bw)
  p <- d %>% group_by(prop) %>%
    summarise(n = n(),
              iqr = unname(quantile(y, 0.75, na.rm = TRUE) - quantile(y, 0.25, na.rm = TRUE)),
              Above500 = first(Above500), x = first(x), owner_cl = first(owner_cl),
              .groups = "drop") %>%
    filter(n >= 5)
  m <- feols(iqr ~ Above500 + x + Above500:x, data = p, cluster = ~owner_cl)
  list(b = unname(coef(m)["Above500"]), se = unname(sqrt(diag(vcov(m)))["Above500"]),
       n = nobs(m), ncl = length(unique(p$owner_cl)))
}

safe <- function(f, ...) tryCatch(f(...), error = function(e) { message("Error: ", conditionMessage(e)); NULL })
l300 <- safe(est_level, 300); l150 <- safe(est_level, 150)
i300 <- safe(est_iqr, 300);   i150 <- safe(est_iqr, 150)

out <- function(name, val) if (!is.null(val) && length(val) && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
if (!is.null(l300)) { out("earnings_level_above500_bw300", l300$b); out("n_obs_earnings_level_bw300", l300$n); out("n_clusters_bw300", l300$ncl) }
if (!is.null(l150)) { out("earnings_level_above500_bw150", l150$b); out("n_obs_earnings_level_bw150", l150$n); out("n_clusters_bw150", l150$ncl) }
if (!is.null(i300)) { out("earnings_iqr_above500_bw300", i300$b); out("n_obs_earnings_iqr_bw300", i300$n) }
if (!is.null(i150)) { out("earnings_iqr_above500_bw150", i150$b); out("n_obs_earnings_iqr_bw150", i150$n) }
