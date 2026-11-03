suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
files <- list(
  us = file.path(base_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv"),
  germany = file.path(base_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")
)
stated_resp <- c(us = 1086, germany = 1074)
stated_obs <- c(us = 18966, germany = 18862)

U <- "(.{1,2})"  # umlaut-tolerant wildcard

attr_patterns <- list(
  reason = paste0("drought|d", U, "rre|trockenheit|flood|", U, "berschwemm|hochwasser|flut|wildfire|waldbr|feuer|persecution|verfolgung|economic|wirtschaft"),
  language = paste0("fluent|flie", U, "end|broken|gebrochen|gebrochenes|kaum"),
  gender = paste0("^female$|^male$|weiblich|m", U, "nnlich|^frau$|^mann$"),
  occupation = paste0("unemployed|arbeitslos|cleaner|reinigung|putz|teacher|lehrer|doctor|arzt|", U, "rztin"),
  religion = "atheist|agnost|christ|muslim|islam",
  origin = paste0("afghanistan|ethiopia|", U, "thiopien|myanmar|ukrain|region"),
  vulnerability = "ptsd|ptbs|posttraum|trauma|food|nahrung|lebensmittel|hunger|family|familie|handicap|behinder|disab"
)
baseline_patterns <- list(
  language = "^none$|^keine?$|kein|nicht|^no ",
  gender = "female|weiblich|frau",
  occupation = "unemploy|arbeitslos",
  religion = "atheis|agnost",
  origin = "region|another|andere",
  vulnerability = "^none$|^keine?$|^kein"
)

recode_reason <- function(x) {
  out <- rep(NA_character_, length(x))
  lx <- tolower(x)
  out[str_detect(lx, "econom|wirtschaft|konom")] <- "economic"
  out[str_detect(lx, paste0("drought|d", U, "rre|trocken"))] <- "drought"
  out[str_detect(lx, paste0("flood|", U, "berschwemm|hochwasser|flut"))] <- "flooding"
  out[str_detect(lx, "wildfire|fire|waldbr|brand|feuer")] <- "wildfires"
  out[str_detect(lx, "persecut|verfolg")] <- "persecution"
  out
}

is_meta <- function(nm) {
  nm %in% c("StartDate","EndDate","Status","IPAddress","Progress","Duration (in seconds)","Finished",
            "RecordedDate","ResponseId","RecipientLastName","RecipientFirstName","RecipientEmail",
            "ExternalReference","LocationLatitude","LocationLongitude","DistributionChannel","UserLanguage")
}
timer_re <- "_(First ?Click|Last ?Click|Page ?Submit|Click ?Count)$"

two_valued <- function(x) {
  v <- unique(x[!is.na(x) & x != ""])
  length(v) == 2 && sum(!is.na(x) & x != "") >= 200
}

find_choice_cols <- function(d) {
  nms <- names(d)
  tcols <- which(str_detect(nms, timer_re))
  prefixes <- unique(str_remove(nms[tcols], timer_re))
  found <- character(0)
  for (i in seq_along(prefixes)) {
    idx <- which(str_remove(nms, timer_re) == prefixes[i] & str_detect(nms, timer_re))
    start <- max(idx) + 1
    if (i < length(prefixes)) {
      nidx <- which(str_remove(nms, timer_re) == prefixes[i + 1] & str_detect(nms, timer_re))
      end <- min(nidx) - 1
    } else end <- length(nms)
    if (start > end) next
    cand <- start:end
    cand <- cand[!is_meta(nms[cand]) & !str_detect(nms[cand], "^F-") &
                   !str_detect(nms[cand], timer_re) & !str_detect(nms[cand], "_DO|_TEXT")]
    hit <- NA_character_
    for (j in cand) if (two_valued(d[[j]])) { hit <- nms[j]; break }
    if (!is.na(hit)) found <- c(found, hit)
  }
  if (length(found) >= 9) return(tail(found, 9))
  # fallback: two-valued Q-columns after the first timer
  first_t <- if (length(tcols)) min(tcols) else 1
  cand <- which(str_detect(nms, "^Q\\d+$") & seq_along(nms) > first_t)
  cand <- cand[sapply(cand, function(j) two_valued(d[[j]]))]
  cat("DEVIATION: timer-block detection found", length(found), "choice columns; using fallback\n")
  tail(nms[cand], 9)
}

parse_choice <- function(x) {
  x[x == ""] <- NA
  v <- unique(x[!is.na(x)])
  num <- suppressWarnings(as.numeric(v))
  if (all(!is.na(num))) {
    ord <- v[order(num)]
  } else {
    dig <- suppressWarnings(as.numeric(str_extract(v, "\\d+(?!.*\\d)")))
    ord <- if (all(!is.na(dig)) && length(unique(dig)) == length(v)) v[order(dig)] else sort(v)
  }
  match(x, ord)
}

run_sample <- function(key) {
  path <- files[[key]]
  d <- read_csv(path, col_types = cols(.default = col_character()), na = c("", "NA"),
                show_col_types = FALSE, progress = FALSE)
  names(d) <- str_remove(names(d), "^﻿")
  cat(sprintf("SAMPLE:%s:loaded=%d\n", key, nrow(d)))
  d <- d[str_detect(coalesce(d$StartDate, ""), "^\\d{4}-|^\\d{1,2}/"), ]
  cat(sprintf("SAMPLE:%s:drop_qualtrics_header_rows=%d\n", key, nrow(d)))
  if ("Status" %in% names(d)) {
    d <- d[!(d$Status %in% c("Survey Preview", "1", "Spam", "8")), ]
    cat(sprintf("SAMPLE:%s:drop_preview_responses=%d\n", key, nrow(d)))
  }
  d$resp_id <- if ("ResponseId" %in% names(d)) d$ResponseId else as.character(seq_len(nrow(d)))

  choice_cols <- find_choice_cols(d)
  ch <- sapply(choice_cols, function(cc) parse_choice(d[[cc]]))
  if (is.null(dim(ch))) ch <- matrix(ch, ncol = length(choice_cols))
  n_ans <- rowSums(!is.na(ch))

  # candidate respondent restrictions; choose the one matching the stated N
  fin <- if ("Finished" %in% names(d)) d$Finished %in% c("1", "True", "TRUE", "true") else rep(TRUE, nrow(d))
  cands <- list(any_conjoint_answer = n_ans > 0,
                finished_and_answered = fin & n_ans > 0,
                all_tasks_answered = n_ans == ncol(ch))
  keep_name <- names(cands)[1]
  for (nm in names(cands)) if (sum(cands[[nm]]) == stated_resp[[key]]) { keep_name <- nm; break }
  if (sum(cands[[keep_name]]) != stated_resp[[key]])
    cat(sprintf("DEVIATION: %s respondents with conjoint answers = %d (paper: %d)\n",
                key, sum(cands[[keep_name]]), stated_resp[[key]]))
  keep <- cands[[keep_name]]
  d <- d[keep, ]; ch <- ch[keep, , drop = FALSE]
  cat(sprintf("SAMPLE:%s:%s=%d\n", key, keep_name, nrow(d)))

  # reshape to profile level
  nms <- names(d)
  fk <- str_match(nms, "^F-(\\d+)-(\\d+)$")
  K <- max(as.integer(fk[, 3]), na.rm = TRUE)
  rows <- list()
  for (t in seq_len(ncol(ch))) {
    for (p in 1:2) {
      for (k in seq_len(K)) {
        ncol_name <- sprintf("F-%d-%d", t, k)
        lcol_name <- sprintf("F-%d-%d-%d", t, p, k)
        if (!(ncol_name %in% nms) || !(lcol_name %in% nms)) next
        rows[[length(rows) + 1]] <- data.frame(
          resp_id = d$resp_id, task = t, profile = p,
          chosen = as.integer(ch[, t] == p),
          attr_name = d[[ncol_name]], level = d[[lcol_name]],
          stringsAsFactors = FALSE)
      }
    }
  }
  long <- bind_rows(rows)
  long$level <- str_trim(long$level)
  long$attr_name <- str_trim(long$attr_name)

  # map attribute names to canonical attributes via their levels
  an <- unique(long$attr_name[!is.na(long$attr_name)])
  amap <- sapply(an, function(a) {
    lv <- tolower(unique(long$level[long$attr_name == a & !is.na(long$level)]))
    sc <- sapply(attr_patterns, function(pt) sum(str_detect(lv, regex(pt, ignore_case = TRUE))))
    if (max(sc) == 0) NA_character_ else names(sc)[which.max(sc)]
  })
  long$attr <- unname(amap[long$attr_name])
  long <- long[!is.na(long$attr), ]

  wide <- long %>%
    select(resp_id, task, profile, chosen, attr, level) %>%
    distinct(resp_id, task, profile, attr, .keep_all = TRUE) %>%
    pivot_wider(names_from = attr, values_from = level)
  cat(sprintf("SAMPLE:%s:profiles_all_tasks=%d\n", key, nrow(wide)))
  wide <- wide[!is.na(wide$chosen), ]
  cat(sprintf("SAMPLE:%s:drop_unanswered_tasks=%d\n", key, nrow(wide)))

  wide$reason <- recode_reason(wide$reason)
  wide$reason <- relevel(factor(wide$reason), ref = "economic")
  others <- intersect(c("language","gender","occupation","religion","origin","vulnerability"), names(wide))
  for (a in others) {
    f <- factor(wide[[a]])
    lv <- levels(f)
    b <- lv[str_detect(tolower(lv), regex(baseline_patterns[[a]], ignore_case = TRUE))]
    if (length(b) >= 1) f <- relevel(f, ref = b[1])
    wide[[a]] <- f
  }
  fml <- as.formula(paste("chosen ~", paste(c("reason", others), collapse = " + ")))
  m <- feols(fml, data = wide, cluster = ~resp_id)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", key, nobs(m)))
  if (nobs(m) != stated_obs[[key]])
    cat(sprintf("DEVIATION: %s estimation N = %d (paper: %d)\n", key, nobs(m), stated_obs[[key]]))
  used <- wide[obs(m), ]
  list(model = m, n_resp = length(unique(used$resp_id)), n_obs = nobs(m))
}

res <- lapply(names(files), run_sample)
names(res) <- names(files)

for (key in names(res)) {
  m <- res[[key]]$model
  cf <- coef(m); se <- sqrt(diag(vcov(m)))
  for (lv in c("drought", "flooding", "wildfires", "persecution")) {
    nm <- paste0("reason", lv)
    cat(sprintf("RESULT:amce_%s_%s=%.6f\n", lv, key, cf[nm]))
    cat(sprintf("RESULT:amce_%s_%s_se=%.6f\n", lv, key, se[nm]))
  }
}
for (key in names(res)) {
  cat(sprintf("RESULT:respondents_%s=%d\n", key, res[[key]]$n_resp))
  cat(sprintf("RESULT:choice_tasks_%s=%d\n", key, res[[key]]$n_obs))
}