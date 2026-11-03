suppressPackageStartupMessages({
  library(readr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration"
us_file  <- file.path(base_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
ger_file <- file.path(base_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

response_names <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192",
                    "Q194", "Q196", "Q198")

gl <- function(pat, x) grepl(pat, x, ignore.case = TRUE, useBytes = TRUE)

# ------------------------------------------------------------------
# Re-implementation of cjoint::read.qualtrics(new.format = TRUE)
# Output: one row per respondent x task x profile (ordered that way)
# ------------------------------------------------------------------
read_conjoint <- function(path, responses, letter = "F") {
  raw <- readr::read_csv(path, col_names = FALSE,
                         col_types = readr::cols(.default = readr::col_character()),
                         na = character(), progress = FALSE)
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)
  qn <- trimws(as.character(unlist(raw[1, ])))
  qn <- sub("^﻿", "", qn)
  dat <- raw[4:nrow(raw), , drop = FALSE]
  n <- nrow(dat)

  rid_col <- which(qn == "ResponseId")[1]
  rid <- dat[[rid_col]]

  resp_idx <- which(qn %in% responses)   # column order, as in cjoint

  nm_cols <- grep(paste0("^", letter, "-[0-9]+-[0-9]+$"), qn)
  lv_cols <- grep(paste0("^", letter, "-[0-9]+-[0-9]+-[0-9]+$"), qn)
  nm_parts <- do.call(rbind, strsplit(qn[nm_cols], "-"))
  lv_parts <- do.call(rbind, strsplit(qn[lv_cols], "-"))
  tasks    <- sort(unique(as.integer(nm_parts[, 2])))
  profiles <- sort(unique(as.integer(lv_parts[, 3])))
  K <- min(length(tasks), length(resp_idx))
  tasks <- tasks[seq_len(K)]

  # Response matrix -> chosen profile number
  resp_mat <- sapply(resp_idx[seq_len(K)], function(ci) trimws(dat[[ci]]))
  if (is.null(dim(resp_mat))) resp_mat <- matrix(resp_mat, nrow = n)
  resp_mat[is.na(resp_mat)] <- ""
  dig <- suppressWarnings(matrix(as.integer(gsub("[^0-9]", "", resp_mat)),
                                 nrow = n))
  dig[resp_mat == ""] <- NA
  nonempty <- resp_mat != ""
  if (any(nonempty) && all(is.na(dig[nonempty]) | !(dig[nonempty] %in% profiles))) {
    # fallback: map sorted unique choice texts to profile numbers
    u <- sort(unique(resp_mat[nonempty]))
    dig <- matrix(match(resp_mat, u), nrow = n)
    dig[!nonempty] <- NA
  }
  dig[!is.na(dig) & !(dig %in% profiles)] <- NA

  # All attribute names
  all_names <- unique(trimws(unlist(lapply(nm_cols, function(ci) dat[[ci]]))))
  all_names <- all_names[!is.na(all_names) & all_names != ""]

  blocks <- list()
  for (kk in seq_len(K)) {
    k <- tasks[kk]
    attr_pos <- sort(unique(as.integer(nm_parts[as.integer(nm_parts[, 2]) == k, 3])))
    for (j in profiles) {
      M <- matrix(NA_character_, n, length(all_names))
      colnames(M) <- all_names
      for (i in attr_pos) {
        nc <- which(qn == paste(letter, k, i, sep = "-"))[1]
        lc <- which(qn == paste(letter, k, j, i, sep = "-"))[1]
        if (is.na(nc) || is.na(lc)) next
        nmv <- trimws(dat[[nc]]); lvv <- trimws(dat[[lc]])
        ok <- !is.na(nmv) & nmv != ""
        if (any(ok)) {
          lvv[!is.na(lvv) & lvv == ""] <- NA
          M[cbind(which(ok), match(nmv[ok], all_names))] <- lvv[ok]
        }
      }
      sel <- ifelse(is.na(dig[, kk]), NA_integer_, as.integer(dig[, kk] == j))
      b <- data.frame(row = seq_len(n), rid = rid, task = k, profile = j,
                      selected = sel, stringsAsFactors = FALSE)
      b <- cbind(b, as.data.frame(M, stringsAsFactors = FALSE))
      blocks[[length(blocks) + 1]] <- b
    }
  }
  out <- do.call(rbind, blocks)
  out <- out[order(out$row, out$task, out$profile), ]
  rownames(out) <- NULL
  list(data = out, attrs = all_names)
}

# ------------------------------------------------------------------
# Identify attribute roles from their levels (works for EN and DE)
# ------------------------------------------------------------------
assign_roles <- function(df, attrs) {
  roles <- setNames(rep(NA_character_, length(attrs)), attrs)
  for (a in attrs) {
    lv <- unique(na.omit(df[[a]]))
    if (any(gl("Economic|Wirtschaft", lv)))                    roles[a] <- "reason"
    else if (any(gl("^Unemploy|^Arbeitslos", lv)))             roles[a] <- "occupation"
    else if (any(gl("^Female$|^Weiblich$", lv)))               roles[a] <- "gender"
    else if (any(gl("Another region|anderen Teil|Ukraine", lv))) roles[a] <- "origin"
    else if (any(gl("Broken|Gebrochen|Fluent", lv)))           roles[a] <- "language"
    else if (any(gl("PTSD|Posttraum|Post.Traum|handicap|insecurity", lv)) ||
             length(lv) >= 5)                                  roles[a] <- "vulnerability"
    else                                                       roles[a] <- "religion"
  }
  roles
}

map_reason <- function(x) {
  lv <- unique(na.omit(x))
  lab <- setNames(rep(NA_character_, length(lv)), lv)
  lab[gl("Economic|Wirtschaft", lv)] <- "econ"
  lab[is.na(lab) & gl("persecution|Verfolgung", lv)] <- "persecution"
  lab[is.na(lab) & gl("Wildfire|Waldbr|fire|brand", lv)] <- "wildfires"
  lab[is.na(lab) & gl("Drought|^D.{1,4}rre", lv)] <- "drought"
  lab[is.na(lab) & gl("Flood|berschwemm|Hochwasser|Flut", lv)] <- "flooding"
  rem <- which(is.na(lab))
  if (length(rem) == 1 && !("flooding" %in% lab)) lab[rem] <- "flooding"
  if (length(rem) == 1 && !("drought" %in% lab) && is.na(lab[rem])) lab[rem] <- "drought"
  lab[is.na(lab)] <- make.names(names(lab)[is.na(lab)])
  unname(lab[x])
}

make_factor <- function(x, base_pat) {
  lv <- sort(unique(na.omit(x)))
  base <- lv[gl(base_pat, lv)][1]
  if (is.na(base)) base <- lv[1]
  relevel(factor(x, levels = lv), ref = base)
}

build_analysis <- function(parsed) {
  df <- parsed$data
  roles <- assign_roles(df, parsed$attrs)
  get <- function(r) { a <- names(roles)[roles == r][1]; if (is.na(a)) rep(NA_character_, nrow(df)) else df[[a]] }
  data.frame(
    rid = df$rid, selected = df$selected,
    reason = get("reason"), occupation = get("occupation"), gender = get("gender"),
    origin = get("origin"), language = get("language"),
    vulnerability = get("vulnerability"), religion = get("religion"),
    stringsAsFactors = FALSE
  )
}

estimate <- function(d) {
  d$reason_f <- factor(map_reason(d$reason))
  d$reason_f <- relevel(d$reason_f, ref = "econ")
  d$occupation_f    <- make_factor(d$occupation, "^Unemployed$|^Arbeitslos$")
  d$gender_f        <- make_factor(d$gender, "^Female$|^Weiblich$")
  d$origin_f        <- make_factor(d$origin, "Another region|anderen Teil")
  d$language_f      <- make_factor(d$language, "^None$|^Keine$")
  d$vulnerability_f <- make_factor(d$vulnerability, "^None$|^Keine$")
  d$religion_f      <- make_factor(d$religion, "^$")   # alphabetical first (cjoint default)
  feols(selected ~ gender_f + language_f + occupation_f + origin_f + reason_f +
          religion_f + vulnerability_f,
        data = d, cluster = ~rid)
}

emit <- function(name, val) {
  if (length(val) == 1 && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}

report <- function(m, d, suffix) {
  cf <- coef(m); se <- sqrt(diag(vcov(m)))
  for (lv in c("drought", "flooding", "wildfires", "persecution")) {
    nm <- paste0("reason_f", lv)
    emit(paste0("amce_", lv, "_", suffix), unname(cf[nm]))
    emit(paste0("amce_", lv, "_", suffix, "_se"), unname(se[nm]))
  }
  emit(paste0("respondents_", suffix), length(unique(d$rid)))
  emit(paste0("choice_tasks_", suffix), nrow(d))
}

# ---------------------------- US ----------------------------------
tryCatch({
  us_parsed <- read_conjoint(us_file, response_names)
  us <- build_analysis(us_parsed)
  us <- us[!is.na(us$selected), ]
  us <- us[is.na(us$occupation) | us$occupation != "Unemployer", ]
  us <- us[5:nrow(us), ]
  rownames(us) <- NULL
  m_us <- estimate(us)
  report(m_us, us, "us")
}, error = function(e) message("US error: ", conditionMessage(e)))

# -------------------------- Germany -------------------------------
tryCatch({
  ger_parsed <- read_conjoint(ger_file, response_names)
  ger <- build_analysis(ger_parsed)
  ger <- ger[!is.na(ger$selected), ]
  rownames(ger) <- NULL
  m_ger <- estimate(ger)
  report(m_ger, ger, "germany")
}, error = function(e) message("Germany error: ", conditionMessage(e)))
