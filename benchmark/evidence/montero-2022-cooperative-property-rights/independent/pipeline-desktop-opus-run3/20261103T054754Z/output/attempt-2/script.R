suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
raw <- haven::read_dta(path)
df <- as.data.frame(haven::zap_labels(haven::zap_formats(raw)))
nms <- names(df)
cat("Columns:\n"); print(nms)

num <- function(x) suppressWarnings(as.numeric(x))
is_num_col <- function(cols) {
  if (length(cols) == 0) return(logical(0))
  vapply(cols, function(h) is.numeric(df[[h]]), logical(1), USE.NAMES = FALSE)
}
find_col <- function(patterns, exclude = NULL, numeric_only = TRUE) {
  for (p in patterns) {
    hits <- nms[grepl(p, nms, ignore.case = TRUE)]
    if (!is.null(exclude) && length(hits) > 0) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
    if (numeric_only && length(hits) > 0) hits <- hits[is_num_col(hits)]
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

# ---------- treatment ----------
df$Above500 <- num(df$Above500)

# ---------- running variable (former owner's cumulative holdings, centred at 500) ----------
cands <- unique(c(
  nms[grepl("own_amt", nms, ignore.case = TRUE)],
  nms[grepl("norm_dist|dist_above|dist500|distance", nms, ignore.case = TRUE)],
  nms[grepl("cum|total_hold|landhold|holding|own_size|owner_size|tot_ha", nms, ignore.case = TRUE)]
))
cands <- cands[is_num_col(cands)]
best <- NULL; best_score <- -Inf
for (cc in cands) {
  x <- num(df[[cc]])
  ok <- !is.na(x) & !is.na(df$Above500)
  if (sum(ok) < 50) next
  # try centred at 500 or already centred at 0
  for (shift in c(500, 0)) {
    r <- x - shift
    agree <- mean((r[ok] >= 0) == (df$Above500[ok] == 1))
    plaus <- mean(abs(r[ok]) < 3000)
    score <- agree + 0.2 * plaus + 0.001 * (cc == "own_amt")
    if (score > best_score) { best_score <- score; best <- list(col = cc, shift = shift) }
  }
}
if (is.null(best)) stop("No running variable found")
cat("Running variable:", best$col, "shift", best$shift, "score", best_score, "\n")
df$run <- num(df[[best$col]]) - best$shift
# if variable is a normalised distance (small scale), rescale check
if (best$col != "own_amt" && "own_amt" %in% nms) {
  # prefer own_amt in hectares if it is consistent
  x <- num(df$own_amt) - 500
  ok <- !is.na(x) & !is.na(df$Above500)
  if (sum(ok) > 50 && mean((x[ok] >= 0) == (df$Above500[ok] == 1)) > 0.9) df$run <- x
}
df$Above500 <- ifelse(is.na(df$Above500), as.numeric(df$run >= 0), df$Above500)

# ---------- outcome: household earnings per capita ----------
y_col <- find_col(c("^hh_?earn.*pc", "earn.*per.?cap", "earn.*_pc$", "inc.*per.?cap",
                    "income_pc", "ingpe", "ing_pc", "percap", "per_cap", "_pc$", "pc_inc", "pc_earn",
                    "ingper"), exclude = "pct|pctile")
if (is.na(y_col)) {
  hh_inc <- find_col(c("hh_?inc", "household_inc", "hh_?earn", "ingfa", "ing_hog", "total_inc", "tot_inc", "ingre"))
  hh_sz  <- find_col(c("hh_?size", "household_size", "hhsize", "miembros", "num_mem", "members", "tam_hog", "nmiem"))
  if (!is.na(hh_inc) && !is.na(hh_sz)) {
    df$y <- num(df[[hh_inc]]) / num(df[[hh_sz]])
    cat("Outcome constructed:", hh_inc, "/", hh_sz, "\n")
  } else if (!is.na(hh_inc)) {
    df$y <- num(df[[hh_inc]]); cat("Outcome:", hh_inc, "\n")
  } else {
    df$y <- num(df$Work_Income); cat("Outcome fallback: Work_Income\n")
  }
} else {
  df$y <- num(df[[y_col]]); cat("Outcome:", y_col, "\n")
}

# ---------- cluster: former owner ----------
cl_col <- NA_character_
for (p in c("Expropretario_ISTA", "owner_id", "own_id", "^owner", "propiet", "expropiet", "exprop", "landlord", "owner")) {
  hits <- nms[grepl(p, nms, ignore.case = TRUE)]
  hits <- hits[!grepl("Land_Owner", hits)]
  if (length(hits) > 0) { cl_col <- hits[1]; break }
}
if (!is.na(cl_col)) {
  df$cl <- as.character(df[[cl_col]])
  df$cl[df$cl == "" | df$cl == "NA"] <- NA
} else df$cl <- NA
# fallback: owners identified by their holdings size
miss_cl <- is.na(df$cl)
df$cl[miss_cl] <- paste0("amt_", round(df$run[miss_cl], 3))
cat("Cluster var:", cl_col, "\n")

# ---------- property id ----------
pid <- rep(NA_character_, nrow(df))
if ("match_id" %in% nms) { v <- as.character(df$match_id); v[v == ""] <- NA; pid <- v }
if ("Reform_Coop_id" %in% nms) {
  v <- as.character(df$Reform_Coop_id); v[v == "" | v == "0"] <- NA
  pid <- ifelse(is.na(pid) & !is.na(v), paste0("C", v), pid)
}
if ("Hacienda_id" %in% nms) {
  v <- as.character(df$Hacienda_id); v[v == "" | v == "0"] <- NA
  pid <- ifelse(is.na(pid) & !is.na(v), paste0("H", v), pid)
}
pid[is.na(pid)] <- paste0("O", df$cl[is.na(pid)])
df$pid <- pid

df$survey_year <- num(df$survey_year)

base <- df %>% filter(!is.na(y), !is.na(run), !is.na(Above500), !is.na(survey_year))
cat("Base N:", nrow(base), "\n")

run_level <- function(bw) {
  d <- base %>% filter(abs(run) <= bw)
  m <- feols(y ~ Above500 + run + run:Above500 | survey_year, data = d, cluster = ~cl)
  print(summary(m))
  list(b = unname(coef(m)["Above500"]), n = nobs(m), ncl = length(unique(d$cl[obs(m)])))
}

run_iqr <- function(bw) {
  d <- base %>% filter(abs(run) <= bw) %>%
    group_by(pid) %>%
    summarise(n = n(),
              iqr = as.numeric(quantile(y, 0.75, type = 2) - quantile(y, 0.25, type = 2)),
              Above500 = first(Above500), run = first(run), cl = first(cl),
              yr = as.numeric(names(sort(table(survey_year), decreasing = TRUE))[1]),
              .groups = "drop") %>%
    filter(n >= 5)
  m <- tryCatch(feols(iqr ~ Above500 + run + run:Above500 | yr, data = d, cluster = ~cl),
                error = function(e) feols(iqr ~ Above500 + run + run:Above500, data = d, cluster = ~cl))
  print(summary(m))
  list(b = unname(coef(m)["Above500"]), n = nobs(m), ncl = length(unique(d$cl)))
}

safe <- function(f, ...) tryCatch(f(...), error = function(e) { message(e$message); list(b = NA, n = NA, ncl = NA) })

l300 <- safe(run_level, 300)
l150 <- safe(run_level, 150)
i300 <- safe(run_iqr, 300)
i150 <- safe(run_iqr, 150)

cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", l300$b))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", l150$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", i300$b))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", i150$b))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%s\n", l300$n))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%s\n", l150$n))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%s\n", i300$n))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%s\n", i150$n))
cat(sprintf("RESULT:n_clusters_bw300=%s\n", l300$ncl))
cat(sprintf("RESULT:n_clusters_bw150=%s\n", l150$ncl))