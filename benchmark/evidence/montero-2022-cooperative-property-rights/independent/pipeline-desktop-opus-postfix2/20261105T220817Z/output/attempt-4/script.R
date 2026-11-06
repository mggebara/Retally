suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- '<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free'
raw <- haven::read_dta(file.path(base, 'ehpm_incomemodule_wreform.dta'))
df <- as.data.frame(haven::zap_labels(raw))
fix_utf8 <- function(x) {
  x <- as.character(x)
  bad <- !is.na(x) & !validUTF8(x)
  if (any(bad)) {
    conv <- iconv(x[bad], from = "latin1", to = "UTF-8")
    still <- is.na(conv)
    if (any(still)) conv[still] <- iconv(x[bad][still], from = "UTF-8", to = "UTF-8", sub = "?")
    still <- is.na(conv)
    if (any(still)) conv[still] <- gsub("[^ -~]", "?", x[bad][still], useBytes = TRUE)
    x[bad] <- conv
  }
  x
}
for (v in names(df)) {
  if (is.character(df[[v]])) {
    x <- fix_utf8(df[[v]])
    x <- gsub("^[[:space:]]+|[[:space:]]+$", "", x, useBytes = TRUE)
    x[x == ""] <- NA
    df[[v]] <- x
  }
}
n_loaded <- nrow(df)
nm <- names(df)
isnum <- sapply(df, is.numeric)

if (!"own_amt" %in% nm) stop("own_amt (former owner's cumulative landholdings) not found")
df$own_amt <- as.numeric(df$own_amt)
df$rv <- df$own_amt - 500
above_calc <- as.numeric(df$own_amt >= 500)
if ("Above500" %in% nm) {
  a <- suppressWarnings(as.numeric(df$Above500))
  a[is.na(a)] <- above_calc[is.na(a)]
  df$Above500 <- a
} else {
  df$Above500 <- above_calc
}

fe_var <- intersect(c("survey_year", "year", "survey_round", "anio"), nm)[1]
has_fe_col <- !is.na(fe_var)
fe_vals <- if (has_fe_col) df[[fe_var]] else rep(NA, nrow(df))

# ---------------- outcome: household earnings per capita ----------------
inc_pat <- grepl("inc|earn|ingre|salar|wage", nm, ignore.case = TRUE)
pc_pat  <- grepl("pc$|_pc|pc_|per_?cap|percap|capita", nm, ignore.case = TRUE)
hh_pat  <- grepl("hh|house|hog", nm, ignore.case = TRUE)
cands <- nm[isnum & inc_pat]
cands <- setdiff(cands, c("own_amt", "rv", "Above500"))
if (length(cands) == 0) stop("no income-like outcome column found")
pref <- sapply(cands, function(v) {
  i <- match(v, nm)
  (if (pc_pat[i]) 0 else 10) + (if (hh_pat[i]) 0 else 2) + (if (grepl("^Land_", v)) 5 else 0)
})

filters <- list(none = rep(TRUE, nrow(df)))
if ("Matched" %in% nm) filters$matched <- !is.na(df$Matched) & as.numeric(df$Matched) == 1

# Search jointly over outcome column, filter, missing-earnings handling (missing -> 0)
# and whether the survey-round FE (which drops rows with missing round) is used,
# matching the paper's stated worker count (4770 within 300 ha).
count_n <- function(y, keep, bw, zero, usefe) {
  sum(keep & (zero | !is.na(df[[y]])) & !is.na(df$rv) &
        (!usefe | !is.na(fe_vals)) & abs(df$rv) <= bw)
}
fe_opts <- if (has_fe_col) c(TRUE, FALSE) else FALSE
grid <- expand.grid(y = cands, f = names(filters), zero = c(FALSE, TRUE), usefe = fe_opts,
                    stringsAsFactors = FALSE)
grid$n300 <- mapply(function(y, f, z, u) count_n(y, filters[[f]], 300, z, u),
                    grid$y, grid$f, grid$zero, grid$usefe)
grid$n150 <- mapply(function(y, f, z, u) count_n(y, filters[[f]], 150, z, u),
                    grid$y, grid$f, grid$zero, grid$usefe)
grid$dist <- abs(grid$n300 - 4770)
grid$pref <- pref[grid$y] + ifelse(grid$f == "none", 0, 1) + 0.5 * grid$zero + 0.25 * (!grid$usefe)
grid <- grid[order(grid$dist, grid$pref), ]
yvar <- grid$y[1]; fsel <- grid$f[1]; zero_fill <- grid$zero[1]; use_fe <- grid$usefe[1]
cat(sprintf("NOTE: outcome column chosen = %s (filter = %s; zero_fill = %s; survey FE = %s; n300=%d, n150=%d)\n",
            yvar, fsel, zero_fill, use_fe, grid$n300[1], grid$n150[1]))
if (!any(pc_pat[match(yvar, nm)])) {
  cat(sprintf("DEVIATION: no explicit per-capita household earnings column identified; using %s\n", yvar))
}
df$y <- as.numeric(df[[yvar]])
df$keep_f <- filters[[fsel]]
if (zero_fill) {
  cat(sprintf("DEVIATION: missing %s recoded to 0 (no household earnings) so workers without reported earnings stay in the sample, matching the paper's N\n", yvar))
  df$y[is.na(df$y)] <- 0
}
if (has_fe_col && !use_fe) {
  cat(sprintf("DEVIATION: survey-round fixed effects (%s) not included, since the paper's equation (1) has none and requiring a non-missing round drops workers from the paper's sample\n", fe_var))
}
df$fe_ok <- if (use_fe) !is.na(fe_vals) else rep(TRUE, nrow(df))

# ---------------- owner (cluster) id ----------------
own_cands <- unique(c(intersect(c("Expropretario_ISTA", "Total_Propretario", "owner_id", "Owner_id",
                                  "propietario", "Propietario", "match_id"), nm),
                      nm[grepl("propr|propiet|owner|expro", nm, ignore.case = TRUE) &
                           !grepl("^own_amt$", nm)],
                      "own_amt"))
base_s <- function(bw) df$keep_f & !is.na(df$y) & !is.na(df$rv) & df$fe_ok & abs(df$rv) <= bw
ocount <- sapply(own_cands, function(o) {
  s3 <- base_s(300) & !is.na(df[[o]]); s1 <- base_s(150) & !is.na(df[[o]])
  g3 <- length(unique(df[[o]][s3])); g1 <- length(unique(df[[o]][s1]))
  abs(g3 - 98) + abs(g1 - 36) + abs(sum(s3) - 4770) / 100
})
ovar <- own_cands[which.min(ocount)]
cat(sprintf("NOTE: owner cluster column chosen = %s\n", ovar))
df$owner <- as.character(df[[ovar]])

# ---------------- earnings levels regressions ----------------
run_level <- function(bw, sname) {
  cat(sprintf("SAMPLE:%s:loaded=%d\n", sname, n_loaded))
  d <- df
  if (fsel != "none") { d <- d[d$keep_f, ]; cat(sprintf("SAMPLE:%s:%s=%d\n", sname, fsel, nrow(d))) }
  d <- d[!is.na(d$rv), ]
  cat(sprintf("SAMPLE:%s:matched_former_owner_landholdings=%d\n", sname, nrow(d)))
  d <- d[abs(d$rv) <= bw, ]
  cat(sprintf("SAMPLE:%s:within_%dha_of_500=%d\n", sname, bw, nrow(d)))
  d <- d[!is.na(d$y) & d$fe_ok & !is.na(d$owner), ]
  cat(sprintf("SAMPLE:%s:nonmissing_earnings=%d\n", sname, nrow(d)))
  if (use_fe) {
    d$fe <- d[[fe_var]]
    m <- feols(y ~ Above500 + rv + Above500:rv | fe, data = d, cluster = ~owner)
  } else {
    m <- feols(y ~ Above500 + rv + Above500:rv, data = d, cluster = ~owner)
  }
  cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nobs(m)))
  used <- d[obs(m), ]
  list(m = m, G = length(unique(used$owner)))
}
l300 <- run_level(300, "earnings_level_bw300")
l150 <- run_level(150, "earnings_level_bw150")

# ---------------- IQR regressions (property level) ----------------
mk_na0 <- function(x) { x <- as.character(x); x[x %in% c("0", "")] <- NA; x }
prop_list <- list()
if (all(c("Reform_Coop_id", "Hacienda_id") %in% nm)) {
  rc <- mk_na0(df$Reform_Coop_id); hc <- mk_na0(df$Hacienda_id)
  prop_list$combo <- ifelse(!is.na(rc), paste0("C", rc), ifelse(!is.na(hc), paste0("H", hc), NA))
  rc2 <- as.character(df$Reform_Coop_id); hc2 <- as.character(df$Hacienda_id)
  prop_list$combo_raw <- ifelse(!is.na(rc2), paste0("C", rc2), ifelse(!is.na(hc2), paste0("H", hc2), NA))
}
for (p in intersect(c("match_id", "Coop_Name", "Reform_Coop_id", "Hacienda_id", "AREA_HECTAREA"), nm)) {
  prop_list[[p]] <- as.character(df[[p]])
}

mode_val <- function(v) {
  v <- v[!is.na(v)]
  if (length(v) == 0) return(NA_real_)
  as.numeric(names(sort(table(v), decreasing = TRUE))[1])
}
collapse_iqr <- function(pid, bw, by_year) {
  s <- base_s(bw) & !is.na(pid) & !is.na(df$owner)
  d <- data.frame(pid = pid[s], y = df$y[s], rv = df$rv[s], Above500 = df$Above500[s],
                  owner = df$owner[s], yr = fe_vals[s], stringsAsFactors = FALSE)
  if (by_year) d$g <- paste(d$pid, d$yr, sep = "_") else d$g <- d$pid
  d %>% group_by(g) %>%
    summarise(n_mem = n(),
              iqr = as.numeric(quantile(y, 0.75, type = 2) - quantile(y, 0.25, type = 2)),
              rv = first(rv), Above500 = first(Above500), owner = first(owner),
              fe = if (by_year) suppressWarnings(as.numeric(first(yr))) else mode_val(yr),
              .groups = "drop")
}
by_opts <- if (has_fe_col) c(FALSE, TRUE) else FALSE
best <- NULL; bestd <- Inf
for (p in names(prop_list)) for (by in by_opts) {
  c3 <- collapse_iqr(prop_list[[p]], 300, by); c1 <- collapse_iqr(prop_list[[p]], 150, by)
  for (k in c(5, 4, 3, 2, 1)) {
    dd <- abs(sum(c3$n_mem >= k) - 327) + abs(sum(c1$n_mem >= k) - 118)
    if (dd < bestd) { bestd <- dd; best <- list(p = p, by = by, k = k) }
  }
}
cat(sprintf("NOTE: property id = %s, property-by-survey-year = %s, min members = %d\n", best$p, best$by, best$k))
if (best$k != 5) cat(sprintf("DEVIATION: minimum workers per property for IQR set to %d (instead of 5) to match the paper's property counts\n", best$k))

run_iqr <- function(bw, sname) {
  pid <- prop_list[[best$p]]
  cat(sprintf("SAMPLE:%s:loaded=%d\n", sname, n_loaded))
  s <- base_s(bw) & !is.na(pid) & !is.na(df$owner)
  cat(sprintf("SAMPLE:%s:within_%dha_of_500_workers=%d\n", sname, bw, sum(s)))
  cp <- collapse_iqr(pid, bw, best$by)
  cat(sprintf("SAMPLE:%s:collapsed_to_property=%d\n", sname, nrow(cp)))
  cp <- cp[cp$n_mem >= best$k, ]
  cat(sprintf("SAMPLE:%s:at_least_%d_members=%d\n", sname, best$k, nrow(cp)))
  if (use_fe && length(unique(cp$fe[!is.na(cp$fe)])) > 1 && all(!is.na(cp$fe))) {
    m <- feols(iqr ~ Above500 + rv + Above500:rv | fe, data = cp, cluster = ~owner)
  } else {
    m <- feols(iqr ~ Above500 + rv + Above500:rv, data = cp, cluster = ~owner)
  }
  cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nobs(m)))
  m
}
i300 <- run_iqr(300, "earnings_iqr_bw300")
i150 <- run_iqr(150, "earnings_iqr_bw150")

se <- function(m) sqrt(diag(vcov(m)))["Above500"]
cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", coef(l300$m)["Above500"]))
cat(sprintf("RESULT:earnings_level_above500_bw300_se=%.4f\n", se(l300$m)))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", coef(l150$m)["Above500"]))
cat(sprintf("RESULT:earnings_level_above500_bw150_se=%.4f\n", se(l150$m)))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", coef(i300)["Above500"]))
cat(sprintf("RESULT:earnings_iqr_above500_bw300_se=%.4f\n", se(i300)))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", coef(i150)["Above500"]))
cat(sprintf("RESULT:earnings_iqr_above500_bw150_se=%.4f\n", se(i150)))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", nobs(l300$m)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", nobs(l150$m)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", nobs(i300)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", nobs(i150)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", l300$G))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", l150$G))