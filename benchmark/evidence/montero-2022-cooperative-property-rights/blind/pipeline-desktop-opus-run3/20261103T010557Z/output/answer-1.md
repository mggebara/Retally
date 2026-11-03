suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
d <- as.data.frame(haven::zap_labels(haven::read_dta(path)))
cn <- names(d)
cat("Columns:", paste(cn, collapse = ", "), "\n")

find_col <- function(patterns, exclude = NULL) {
  for (p in patterns) {
    hits <- cn[grepl(p, cn, ignore.case = TRUE, perl = TRUE)]
    if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE, perl = TRUE)]
    hits <- hits[sapply(hits, function(h) is.numeric(d[[h]]) && sum(!is.na(d[[h]])) > 0)]
    if (length(hits) > 0) return(hits[1])
  }
  NULL
}

# ---------------- running variable (former owner's landholdings, centered at 500) -------------
xvar <- NULL
if ("norm_dist_Above" %in% cn && is.numeric(d$norm_dist_Above)) {
  xvar <- "norm_dist_Above"
  x <- d$norm_dist_Above
} else {
  hc <- find_col(c("^dist", "dist_500", "Total_Land", "landholding", "cum.*hold", "holding"))
  if (!is.null(hc)) {
    xvar <- hc
    x <- d[[hc]]
    if (median(x, na.rm = TRUE) > 150) x <- x - 500
  } else {
    stop("No running variable found")
  }
}
mx <- max(abs(x), na.rm = TRUE)
cat("Running variable:", xvar, " range:", range(x, na.rm = TRUE), "\n")
if (mx < 5) {
  cat("DEVIATION: running variable appears normalized; rescaling by 500 to hectares\n")
  x <- x * 500
}
d$x <- x

# ---------------- treatment -------------
if ("Above500" %in% cn) {
  d$above <- as.numeric(d$Above500)
  d$above[is.na(d$above) & !is.na(d$x)] <- as.numeric(d$x[is.na(d$above) & !is.na(d$x)] >= 0)
} else {
  d$above <- as.numeric(d$x >= 0)
}

# ---------------- outcome: household earnings per capita -------------
ycol <- find_col(c("^ingpe$", "earn.*(pc|per_?cap|capita)", "(pc|per_?cap|capita).*earn",
                   "inc.*(pc|per_?cap|capita)", "(pc|per_?cap|capita).*inc",
                   "ingre.*(pc|per_?cap|capita)", "hh.*earn", "earn", "^ingfa$"))
if (is.null(ycol)) {
  ycol <- "Work_Income"
  cat("DEVIATION: no per-capita household earnings column found; using Work_Income\n")
}
cat("Outcome column:", ycol, "\n")
d$y <- as.numeric(d[[ycol]])

# ---------------- cluster: former owner -------------
ccol <- NULL
for (cc in c("Expropretario_ISTA", "owner_id", "Owner_id", "propietario", "match_id")) {
  if (cc %in% cn && sum(!is.na(d[[cc]]) & as.character(d[[cc]]) != "") > 0) { ccol <- cc; break }
}
if (is.null(ccol)) ccol <- "match_id"
d$cl <- as.character(d[[ccol]])
d$cl[d$cl == ""] <- NA
cat("Cluster column:", ccol, "\n")

# ---------------- property id -------------
pid <- rep(NA_character_, nrow(d))
if ("Reform_Coop_id" %in% cn) {
  v <- as.character(d$Reform_Coop_id); ok <- !is.na(v) & v != "" & v != "0"
  pid[ok] <- paste0("C", v[ok])
}
if ("Hacienda_id" %in% cn) {
  v <- as.character(d$Hacienda_id); ok <- is.na(pid) & !is.na(v) & v != "" & v != "0"
  pid[ok] <- paste0("H", v[ok])
}
if ("match_id" %in% cn) {
  v <- as.character(d$match_id); ok <- is.na(pid) & !is.na(v) & v != ""
  pid[ok] <- paste0("M", v[ok])
}
ok <- is.na(pid) & !is.na(d$cl)
pid[ok] <- paste0("O", d$cl[ok])
d$pid <- pid

# survey round
d$round <- if ("survey_year" %in% cn) d$survey_year else 1

base <- d %>% filter(!is.na(x), !is.na(above), !is.na(cl))
if ("Matched" %in% cn) {
  mm <- base$Matched
  if (sum(mm == 1, na.rm = TRUE) > 0) base <- base[!is.na(mm) & mm == 1, ]
}

safe <- function(expr) tryCatch(expr, error = function(e) { cat("Error:", conditionMessage(e), "\n"); NA })

run_level <- function(bw) {
  s <- base %>% filter(abs(x) <= bw, !is.na(y))
  m <- feols(y ~ above + x + above:x | round, data = s, cluster = ~cl)
  print(summary(m))
  list(b = unname(coef(m)["above"]), n = nobs(m),
       ncl = length(unique(s$cl[obs(m)])))
}

run_iqr <- function(bw) {
  s <- base %>% filter(abs(x) <= bw, !is.na(y), !is.na(pid))
  p <- s %>% group_by(pid) %>%
    summarise(n = n(),
              iqr = as.numeric(quantile(y, 0.75, type = 2) - quantile(y, 0.25, type = 2)),
              x = first(x), above = first(above), cl = first(cl),
              round = as.numeric(names(which.max(table(round)))), .groups = "drop") %>%
    filter(n >= 5)
  m <- feols(iqr ~ above + x + above:x, data = p, cluster = ~cl)
  print(summary(m))
  list(b = unname(coef(m)["above"]), n = nobs(m), ncl = length(unique(p$cl)))
}

l300 <- safe(run_level(300))
l150 <- safe(run_level(150))
i300 <- safe(run_iqr(300))
i150 <- safe(run_iqr(150))

g <- function(o, k) if (is.list(o)) o[[k]] else NA

cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", g(l300, "b")))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", g(l150, "b")))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", g(i300, "b")))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", g(i150, "b")))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%s\n", g(l300, "n")))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%s\n", g(l150, "n")))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%s\n", g(i300, "n")))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%s\n", g(i150, "n")))
cat(sprintf("RESULT:n_clusters_bw300=%s\n", g(l300, "ncl")))
cat(sprintf("RESULT:n_clusters_bw150=%s\n", g(l150, "ncl")))
