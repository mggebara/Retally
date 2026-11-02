suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

data_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration"
us_file  <- file.path(data_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
ger_file <- file.path(data_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

responses <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192", "Q194", "Q196", "Q198")

sanitize <- function(x) {
  x <- as.character(x)
  y <- iconv(x, from = "UTF-8", to = "UTF-8", sub = "?")
  y[is.na(y) & !is.na(x)] <- iconv(x[is.na(y) & !is.na(x)], from = "latin1", to = "UTF-8", sub = "?")
  trimws(y)
}

read_q <- function(path) {
  d <- readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()),
                       name_repair = "minimal", progress = FALSE)
  d <- as.data.frame(d, stringsAsFactors = FALSE, check.names = FALSE)
  d <- d[, !duplicated(names(d)), drop = FALSE]
  rid <- d$ResponseId
  keep <- !is.na(rid) & !(rid %in% c("Response ID", "ResponseId")) & !grepl("ImportId", rid, fixed = TRUE)
  d <- d[keep, , drop = FALSE]
  rownames(d) <- NULL
  d
}

parse_choice <- function(v) {
  v <- sanitize(v)
  v[!is.na(v) & v == ""] <- NA
  if (all(is.na(v))) return(rep(NA_real_, length(v)))
  num <- suppressWarnings(as.numeric(v))
  if (all(is.na(v) | !is.na(num))) {
    u <- sort(unique(num[!is.na(num)]))
    if (all(u %in% c(1, 2))) return(num)
    if (length(u) == 2) return(ifelse(is.na(num), NA, ifelse(num == u[1], 1, 2)))
    return(num)
  }
  has <- !is.na(v) & grepl("[0-9]", v)
  if (all(is.na(v) | has)) {
    dig <- suppressWarnings(as.numeric(sub("^.*([0-9])[^0-9]*$", "\\1", v)))
    return(ifelse(has, dig, NA))
  }
  u <- sort(unique(v[!is.na(v)]))
  out <- match(v, u)
  as.numeric(out)
}

stack_conjoint <- function(d) {
  nm <- names(d)
  lv <- grep("^F-[0-9]+-[0-9]+-[0-9]+$", nm, value = TRUE)
  parts <- do.call(rbind, strsplit(lv, "-"))
  i2 <- as.integer(parts[, 2]); i3 <- as.integer(parts[, 3]); i4 <- as.integer(parts[, 4])
  prof_pos <- 3
  if (max(i4) <= 2 && max(i3) > 2) prof_pos <- 4
  tasks <- sort(unique(i2))
  profiles <- sort(unique(if (prof_pos == 3) i3 else i4))
  attrs <- sort(unique(if (prof_pos == 3) i4 else i3))
  n <- nrow(d)
  long_list <- list()
  sel_list <- list()
  idx <- 0
  for (ti in seq_along(tasks)) {
    t <- tasks[ti]
    if (ti > length(responses)) next
    resp_col <- responses[ti]
    choice <- if (resp_col %in% nm) parse_choice(d[[resp_col]]) else rep(NA_real_, n)
    for (p in profiles) {
      sel_list[[length(sel_list) + 1]] <- data.frame(
        resp_index = seq_len(n), ResponseId = d$ResponseId, task = t, profile = p,
        selected = ifelse(is.na(choice), NA, as.integer(choice == p)),
        stringsAsFactors = FALSE)
      for (k in attrs) {
        name_col <- paste0("F-", t, "-", k)
        lev_col <- if (prof_pos == 3) paste0("F-", t, "-", p, "-", k) else paste0("F-", t, "-", k, "-", p)
        if (!(name_col %in% nm) || !(lev_col %in% nm)) next
        idx <- idx + 1
        long_list[[idx]] <- data.frame(
          resp_index = seq_len(n), task = t, profile = p,
          attr_name = sanitize(d[[name_col]]), level = sanitize(d[[lev_col]]),
          stringsAsFactors = FALSE)
      }
    }
  }
  long <- bind_rows(long_list)
  long <- long[!is.na(long$attr_name) & long$attr_name != "", ]
  wide <- long %>%
    tidyr::pivot_wider(id_cols = c(resp_index, task, profile), names_from = attr_name,
                       values_from = level, values_fn = function(x) x[1])
  sel <- bind_rows(sel_list)
  out <- left_join(sel, wide, by = c("resp_index", "task", "profile"))
  out <- out[order(out$resp_index, out$task, out$profile), ]
  attr_cols <- setdiff(names(wide), c("resp_index", "task", "profile"))
  list(data = as.data.frame(out, stringsAsFactors = FALSE), attr_cols = attr_cols)
}

identify_attrs <- function(df, attr_cols) {
  levs <- lapply(attr_cols, function(a) unique(df[[a]][!is.na(df[[a]]) & df[[a]] != ""]))
  names(levs) <- attr_cols
  has <- function(a, pat) any(grepl(pat, levs[[a]], ignore.case = TRUE))
  remaining <- attr_cols
  pick <- function(cands) { if (length(cands) == 0) return(NA_character_); cands[which.max(sapply(cands, function(a) sum(!is.na(df[[a]]))))] }
  res <- list()
  res$Reason <- pick(remaining[sapply(remaining, has, pat = "conomic|Wirtschaft")]); remaining <- setdiff(remaining, res$Reason)
  res$Origin <- pick(remaining[sapply(remaining, has, pat = "Ukrain")]); remaining <- setdiff(remaining, res$Origin)
  res$Occupation <- pick(remaining[sapply(remaining, has, pat = "Unemploy|Arbeitslos")]); remaining <- setdiff(remaining, res$Occupation)
  res$Gender <- pick(remaining[sapply(remaining, has, pat = "^Female$|^Weiblich$|^Male$|^M.nnlich$")]); remaining <- setdiff(remaining, res$Gender)
  none_c <- remaining[sapply(remaining, has, pat = "^None$|^Keine$|^Kein$")]
  if (length(none_c) >= 2) {
    nl <- sapply(none_c, function(a) length(levs[[a]]))
    res$Vulnerability <- none_c[which.max(nl)]
    res$Language <- none_c[which.min(nl)]
  } else if (length(none_c) == 1) {
    res$Vulnerability <- none_c
  }
  remaining <- setdiff(remaining, unlist(res))
  if (length(remaining) > 0) res$Religion <- pick(remaining)
  res
}

classify_reason <- function(x) {
  out <- rep(NA_character_, length(x))
  out[grepl("conomic|Wirtschaft", x, ignore.case = TRUE)] <- "economic"
  out[is.na(out) & grepl("ersecution|Verfolgung", x, ignore.case = TRUE)] <- "persecution"
  out[is.na(out) & grepl("ildfire|Waldbr|Feuer|Brand", x, ignore.case = TRUE)] <- "wildfires"
  out[is.na(out) & grepl("rought|D.{0,6}rre|Trocken", x, ignore.case = TRUE)] <- "drought"
  out[is.na(out) & grepl("lood|berschwemm|Hochwasser|Flut", x, ignore.case = TRUE)] <- "flooding"
  unm <- unique(x[is.na(out) & !is.na(x) & x != ""])
  if (length(unm) == 1 && !("flooding" %in% out)) out[!is.na(x) & x == unm] <- "flooding"
  out
}

run_country <- function(path, us = TRUE) {
  d <- read_q(path)
  st <- stack_conjoint(d)
  df <- st$data
  ids <- identify_attrs(df, st$attr_cols)
  df <- df[!is.na(df$selected), ]
  if (us && !is.na(ids$Occupation)) {
    df <- df[is.na(df[[ids$Occupation]]) | df[[ids$Occupation]] != "Unemployer", ]
  }
  df <- df[order(df$resp_index, df$task, df$profile), ]
  if (us) df <- df[5:nrow(df), ]
  n_obs <- nrow(df)
  n_resp <- length(unique(df$ResponseId))

  est <- data.frame(selected = df$selected, ResponseId = df$ResponseId, stringsAsFactors = FALSE)
  est$Reason_cat <- factor(classify_reason(df[[ids$Reason]]),
                           levels = c("economic", "drought", "flooding", "wildfires", "persecution"))
  fnames <- c()
  base_pat <- list(Gender = "^Female$|^Weiblich$", Language = "^None$|^Keine$|^Kein$",
                   Occupation = "^Unemployed$|^Arbeitslos$", Origin = "region in your country|anderen Teil",
                   Vulnerability = "^None$|^Keine$|^Kein$", Religion = "gnostic|theist|Atheist")
  for (a in c("Gender", "Language", "Occupation", "Origin", "Religion", "Vulnerability")) {
    col <- ids[[a]]
    if (is.null(col) || is.na(col)) next
    v <- df[[col]]
    v[!is.na(v) & v == ""] <- NA
    f <- factor(v)
    bl <- levels(f)[grepl(base_pat[[a]], levels(f), ignore.case = TRUE)]
    if (length(bl) >= 1) f <- relevel(f, ref = bl[1])
    vn <- paste0("A_", a)
    est[[vn]] <- f
    fnames <- c(fnames, vn)
  }
  fml <- as.formula(paste("selected ~ Reason_cat", if (length(fnames)) paste("+", paste(fnames, collapse = " + ")) else ""))
  m <- feols(fml, data = est, cluster = ~ResponseId)
  cf <- coef(m)
  list(coef = cf, se = sqrt(diag(vcov(m))), n_obs = n_obs, n_resp = n_resp)
}

us <- run_country(us_file, us = TRUE)
ger <- run_country(ger_file, us = FALSE)

g <- function(x, nm) { v <- x[paste0("Reason_cat", nm)]; if (is.null(v) || is.na(v)) NA else unname(v) }

cat(sprintf("RESULT:amce_drought_us=%.6f\n", g(us$coef, "drought")))
cat(sprintf("RESULT:amce_flooding_us=%.6f\n", g(us$coef, "flooding")))
cat(sprintf("RESULT:amce_wildfires_us=%.6f\n", g(us$coef, "wildfires")))
cat(sprintf("RESULT:amce_persecution_us=%.6f\n", g(us$coef, "persecution")))
cat(sprintf("RESULT:amce_drought_germany=%.6f\n", g(ger$coef, "drought")))
cat(sprintf("RESULT:amce_flooding_germany=%.6f\n", g(ger$coef, "flooding")))
cat(sprintf("RESULT:amce_wildfires_germany=%.6f\n", g(ger$coef, "wildfires")))
cat(sprintf("RESULT:amce_persecution_germany=%.6f\n", g(ger$coef, "persecution")))
cat(sprintf("RESULT:respondents_us=%d\n", us$n_resp))
cat(sprintf("RESULT:respondents_germany=%d\n", ger$n_resp))
cat(sprintf("RESULT:choice_tasks_us=%d\n", us$n_obs))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", ger$n_obs))