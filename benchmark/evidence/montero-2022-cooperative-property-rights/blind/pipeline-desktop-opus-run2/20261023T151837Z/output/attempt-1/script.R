suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "/Users/matthew/dev/Retally/.cache/datasets/montero_2022_cooperative_property_rights.script-free"
df <- haven::read_dta(file.path(base, "ehpm_incomemodule_wreform.dta"))
df <- haven::zap_labels(df)
df <- as.data.frame(df)
nm <- names(df)
message("Columns: ", paste(nm, collapse = ", "))

find_col <- function(patterns, exclude = character(0), numeric_only = FALSE) {
  for (p in patterns) {
    hits <- nm[grepl(p, nm, ignore.case = TRUE)]
    hits <- setdiff(hits, exclude)
    if (numeric_only) hits <- hits[sapply(df[hits], is.numeric)]
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

# ---------------- Running variable (former owner's cumulative holdings, centred at 500) ----
num_cols <- nm[sapply(df, is.numeric)]
above <- if ("Above500" %in% nm) df$Above500 else NULL

agree <- function(v, thr) {
  if (is.null(above)) return(NA)
  ok <- !is.na(v) & !is.na(above)
  if (sum(ok) < 50) return(0)
  mean((v[ok] >= thr) == (above[ok] == 1))
}

xrun <- NULL
dist_cands <- num_cols[grepl("dist", num_cols, ignore.case = TRUE)]
dist_cands <- c(intersect("norm_dist_Above", dist_cands), setdiff(dist_cands, "norm_dist_Above"))
for (cc in dist_cands) {
  v <- df[[cc]]
  if (sum(!is.na(v)) < 50) next
  a <- agree(v, 0)
  if (!is.na(a) && a >= 0.95 && max(abs(v), na.rm = TRUE) > 50) {
    xrun <- v; message("Running variable (distance): ", cc, " agreement=", round(a, 3)); break
  }
}
if (is.null(xrun)) {
  hold_cands <- num_cols[grepl("cum|holding|total_?area|tenencia|owner_?area|total_?ha|landhold", num_cols, ignore.case = TRUE)]
  hold_cands <- c(hold_cands, setdiff(num_cols, c(hold_cands, "Above500")))
  for (cc in hold_cands) {
    v <- df[[cc]]
    if (sum(!is.na(v)) < 50) next
    a <- agree(v, 500)
    if (!is.na(a) && a >= 0.97 && mean(v >= 500, na.rm = TRUE) > 0.05 && mean(v < 500, na.rm = TRUE) > 0.05) {
      xrun <- v - 500; message("Running variable (holdings): ", cc, " agreement=", round(a, 3)); break
    }
  }
}
if (is.null(xrun) && "norm_dist_Above" %in% nm) {
  v <- df$norm_dist_Above
  # assume normalized by 500 ha if on a small scale
  if (max(abs(v), na.rm = TRUE) <= 50) {
    xrun <- v * 500
    cat("DEVIATION: running variable taken as norm_dist_Above*500 (scale assumed)\n")
  } else xrun <- v
}
df$x <- xrun
df$treat <- as.integer(df$x >= 0)

# ---------------- Outcome: household earnings per capita ----------------
excl <- c(nm[grepl("^Land_|Other_Income", nm)])
ycol <- find_col(c("^ingpe$", "earn.*(pc|cap)", "(pc|cap).*earn", "inc.*(_pc|pc_|cap|percap)",
                   "(_pc|percap|capita).*inc", "ingpe", "ingreso.*(pc|cap)"),
                 exclude = excl, numeric_only = TRUE)
if (!is.na(ycol)) {
  df$y <- df[[ycol]]
  message("Outcome: ", ycol)
} else {
  tot <- find_col(c("^ingfa$", "hh_?earn", "hh_?inc", "household.*(inc|earn)", "earn", "^money", "ingreso"),
                  exclude = excl, numeric_only = TRUE)
  sz <- find_col(c("^miembros$", "hh_?size", "tot_?mem", "nmiem", "members", "hhsize"), numeric_only = TRUE)
  if (!is.na(tot) && !is.na(sz)) {
    df$y <- df[[tot]] / df[[sz]]
    cat("DEVIATION: earnings per capita constructed as", tot, "/", sz, "\n")
  } else if (!is.na(tot)) {
    df$y <- df[[tot]]
    cat("DEVIATION: per-capita earnings variable not found; using", tot, "\n")
  } else stop("No earnings variable found")
}

# ---------------- Cluster (former owner) and property id ----------------
ocol <- find_col(c("^Expropretario_ISTA$", "owner_?id", "former_?owner", "exprop", "propietario", "owner"),
                 exclude = c("Land_Owner"))
if (is.na(ocol)) ocol <- if ("match_id" %in% nm) "match_id" else NA
message("Owner cluster: ", ocol)
df$owner <- as.character(df[[ocol]])
df$owner[df$owner == "" ] <- NA

pcol <- find_col(c("^property_?id$", "^prop_?id$"))
if (!is.na(pcol)) {
  df$pid <- as.character(df[[pcol]])
} else if (all(c("Reform_Coop_id", "Hacienda_id") %in% nm)) {
  df$pid <- paste(df$Reform_Coop_id, df$Hacienda_id, sep = "_")
} else if ("match_id" %in% nm) {
  df$pid <- as.character(df$match_id)
} else df$pid <- df$owner

has_fe <- "survey_year" %in% nm
df$sy <- if (has_fe) df$survey_year else 1

base_s <- df %>% filter(!is.na(x), !is.na(y), !is.na(owner))

# ---------------- Levels regressions ----------------
run_level <- function(bw) {
  d <- base_s %>% filter(abs(x) <= bw)
  m <- feols(y ~ treat + x + x:treat | sy, data = d, cluster = ~owner)
  list(b = unname(coef(m)["treat"]), n = nobs(m), cl = length(unique(d$owner)))
}
l300 <- run_level(300)
l150 <- run_level(150)

# ---------------- IQR regressions (one obs per property, >=5 members) ----------------
prop <- base_s %>%
  group_by(pid) %>%
  summarise(n_w = n(),
            iqr = as.numeric(quantile(y, 0.75, type = 2) - quantile(y, 0.25, type = 2)),
            x = first(x), treat = first(treat), owner = first(owner), .groups = "drop") %>%
  filter(n_w >= 5)

run_iqr <- function(bw) {
  d <- prop %>% filter(abs(x) <= bw)
  m <- feols(iqr ~ treat + x + x:treat, data = d, cluster = ~owner)
  list(b = unname(coef(m)["treat"]), n = nobs(m), cl = length(unique(d$owner)))
}
i300 <- run_iqr(300)
i150 <- run_iqr(150)
cat("DEVIATION: IQR regressions use one observation per property; no survey-round FE (not identifiable with one obs per property)\n")

cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", l300$b))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", l150$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", i300$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", i150$b))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", as.integer(l300$n)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", as.integer(l150$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", as.integer(i300$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", as.integer(i150$n)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", as.integer(l300$cl)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", as.integer(l150$cl)))