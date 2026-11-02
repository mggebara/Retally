suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
f_us <- file.path(base, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
f_de <- file.path(base, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

clean_txt <- function(x) {
  x <- gsub("<[^>]+>", "", x)
  x <- gsub("&nbsp;", " ", x, fixed = TRUE)
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("\\s+", " ", x)
  x <- trimws(x)
  x[x == ""] <- NA
  x
}

meta_cols <- c("StartDate", "EndDate", "Status", "IPAddress", "Progress",
               "Duration (in seconds)", "Finished", "RecordedDate", "ResponseId",
               "RecipientLastName", "RecipientFirstName", "RecipientEmail",
               "ExternalReference", "LocationLatitude", "LocationLongitude",
               "DistributionChannel", "UserLanguage")

map_choice <- function(v) {
  u <- sort(unique(v[!is.na(v)]))
  d <- suppressWarnings(as.integer(sub("^.*?(\\d+)\\D*$", "\\1", u, perl = TRUE)))
  if (length(u) == 2 && all(!is.na(d)) && setequal(d, c(1L, 2L))) {
    key <- setNames(d, u)
  } else {
    nu <- suppressWarnings(as.numeric(u))
    if (all(!is.na(nu))) u <- u[order(nu)]
    key <- setNames(seq_along(u), u)
  }
  unname(key[v])
}

analyze <- function(path, label) {
  raw <- read_csv(path, col_types = cols(.default = col_character()),
                  na = c(""), name_repair = "minimal", progress = FALSE)
  nm <- names(raw)
  nm <- sub("^\ufeff", "", nm)
  nm <- make.unique(nm)
  names(raw) <- nm
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)

  sc <- nm[grepl("StartDate", nm)][1]
  is_data <- grepl("\\d{4}-\\d{1,2}-\\d{1,2}|\\d{1,2}/\\d{1,2}/\\d{2,4}", raw[[sc]])
  qtext <- if (any(!is_data)) as.character(unlist(raw[which(!is_data)[1], ])) else nm
  qtext[is.na(qtext)] <- ""
  names(qtext) <- nm
  dat <- raw[is_data, , drop = FALSE]

  # drop previews / tests / spam
  if ("Status" %in% nm) {
    st <- dat$Status
    drop <- grepl("(?i)preview|test|spam", st, perl = TRUE) | st %in% c("1", "2", "8", "9")
    dat <- dat[!drop | is.na(drop), , drop = FALSE]
  }
  dat$.id <- if ("ResponseId" %in% nm) dat$ResponseId else as.character(seq_len(nrow(dat)))

  # conjoint embedded data
  re_name <- "^F[-._](\\d+)[-._](\\d+)$"
  re_lev  <- "^F[-._](\\d+)[-._](\\d+)[-._](\\d+)$"
  name_cols <- nm[grepl(re_name, nm)]
  lev_cols  <- nm[grepl(re_lev, nm)]
  if (length(lev_cols) == 0) stop("No conjoint level columns found in ", label)
  sep_of <- function(x) substr(x, 2, 2)

  long <- lapply(lev_cols, function(cn) {
    p <- as.integer(regmatches(cn, regexec(re_lev, cn))[[1]][2:4])
    s <- sep_of(cn)
    ncol_name <- paste0("F", s, p[1], s, p[3])
    if (!ncol_name %in% nm) return(NULL)
    data.frame(.id = dat$.id, task = p[1], profile = p[2],
               attr = clean_txt(dat[[ncol_name]]), level = clean_txt(dat[[cn]]),
               stringsAsFactors = FALSE)
  })
  long <- bind_rows(long)
  long <- long[!is.na(long$attr) & !is.na(long$level), ]
  K <- max(long$task)
  wide <- long %>%
    pivot_wider(id_cols = c(.id, task, profile), names_from = attr,
                values_from = level, values_fn = function(z) z[1])
  attrs <- setdiff(names(wide), c(".id", "task", "profile"))
  cat(label, ": tasks =", K, "; attributes:", paste(attrs, collapse = " | "), "\n")

  # ---- choice columns
  have_f <- dat$.id %in% unique(long$.id)
  nf <- sum(have_f)
  excl <- nm %in% c(meta_cols, ".id") | grepl(re_name, nm) | grepl(re_lev, nm) |
    grepl("(?i)_DO|DO-|^FL_|_Click|_Submit|_Page|Timing|Count", nm, perl = TRUE)
  cand <- character(0); cnt <- numeric(0); sig <- character(0)
  for (cn in nm[!excl]) {
    v <- clean_txt(dat[[cn]][have_f])
    nn <- sum(!is.na(v))
    if (nn < 0.5 * nf) next
    u <- sort(unique(v[!is.na(v)]))
    if (length(u) != 2) next
    cand <- c(cand, cn); cnt <- c(cnt, nn); sig <- c(sig, paste(u, collapse = "||"))
  }
  if (length(cand) < K) stop("Could not find choice columns in ", label)
  qt <- qtext[cand]
  task_ref <- suppressWarnings(as.integer(sub("^.*?e://Field/F[-._](\\d+)[-._].*$", "\\1", qt, perl = TRUE)))
  task_ref[!grepl("e://Field/F", qt)] <- NA
  choice_re <- "(?i)prefer|admit|choose|which of|which migrant|welche|bevorz|lieber|aufnehm|aufgenommen|entscheid|w.{1,2}hlen"
  pref <- grepl(choice_re, qt, perl = TRUE) | !is.na(task_ref)

  pick_run <- function(idx) {
    best <- NULL; best_score <- Inf
    for (g in unique(sig[idx])) {
      ii <- idx[sig[idx] == g]
      if (length(ii) < K) next
      bonus <- if (grepl("1", g) && grepl("2", g)) 0 else 1
      for (s in 1:(length(ii) - K + 1)) {
        w <- ii[s:(s + K - 1)]
        sc_ <- sd(cnt[w]) / mean(cnt[w]) + bonus * 0.5
        if (sc_ < best_score) { best_score <- sc_; best <- w }
      }
    }
    best
  }
  chosen_idx <- NULL
  tasks_for <- NULL
  if (sum(!is.na(task_ref)) >= K && all(1:K %in% task_ref) &&
      !any(duplicated(task_ref[!is.na(task_ref) & task_ref <= K]))) {
    chosen_idx <- match(1:K, task_ref)
  }
  if (is.null(chosen_idx) && sum(pref) >= K) chosen_idx <- pick_run(which(pref))
  if (is.null(chosen_idx)) chosen_idx <- pick_run(seq_along(cand))
  if (is.null(chosen_idx)) stop("Choice column selection failed in ", label)
  ch_cols <- cand[chosen_idx]
  cat(label, ": choice columns =", paste(ch_cols, collapse = ", "), "\n")

  ch <- bind_rows(lapply(seq_len(K), function(k) {
    v <- clean_txt(dat[[ch_cols[k]]])
    data.frame(.id = dat$.id, task = k, chosen_profile = map_choice(v),
               stringsAsFactors = FALSE)
  }))
  ch <- ch[!is.na(ch$chosen_profile), ]

  d <- inner_join(wide, ch, by = c(".id", "task"))
  d$chosen <- as.integer(d$profile == d$chosen_profile)

  # ---- identify reason attribute and levels
  p_dr <- "(?i)drought|d.{1,2}rre|trocken"
  p_fl <- "(?i)flood|berschwemm|hochwasser|flut"
  p_wf <- "(?i)wildfire|fire|waldbr|feuer|br.{1,2}nde"
  p_pe <- "(?i)persecut|verfolg"
  score <- sapply(attrs, function(a) {
    u <- unique(na.omit(d[[a]]))
    sum(grepl(p_dr, u, perl = TRUE)) + sum(grepl(p_fl, u, perl = TRUE)) +
      sum(grepl(p_wf, u, perl = TRUE)) + sum(grepl(p_pe, u, perl = TRUE))
  })
  ra <- attrs[which.max(score)]
  rl <- unique(na.omit(d[[ra]]))
  lev_pe <- rl[grepl(p_pe, rl, perl = TRUE)][1]
  lev_dr <- rl[grepl(p_dr, rl, perl = TRUE) & rl != lev_pe][1]
  lev_fl <- rl[grepl(p_fl, rl, perl = TRUE) & !rl %in% c(lev_pe, lev_dr)][1]
  lev_wf <- rl[grepl(p_wf, rl, perl = TRUE) & !rl %in% c(lev_pe, lev_dr, lev_fl)][1]
  lev_ec <- setdiff(rl, c(lev_pe, lev_dr, lev_fl, lev_wf))
  econ_hit <- lev_ec[grepl("(?i)econom|opportun|wirtschaft|konom|chance|arbeit", lev_ec, perl = TRUE)]
  lev_ec <- if (length(econ_hit) > 0) econ_hit[1] else lev_ec[1]
  cat(label, ": reason attribute =", ra, "; levels:", paste(rl, collapse = " | "),
      "; baseline =", lev_ec, "\n")

  # baselines for other attributes (do not affect reason AMCEs)
  base_pat <- c("(?i)^none$|^kein|^no |^nicht", "(?i)female|weiblich|frau",
                "(?i)unemploy|arbeitslos", "(?i)atheis|agnost|konfessionslos",
                "(?i)region|another|anderen")
  safe <- data.frame(chosen = d$chosen, id = d$.id, stringsAsFactors = FALSE)
  safe$reason <- relevel(factor(d[[ra]]), ref = lev_ec)
  others <- setdiff(attrs, ra)
  for (i in seq_along(others)) {
    f <- factor(d[[others[i]]])
    for (bp in base_pat) {
      hit <- levels(f)[grepl(bp, levels(f), perl = TRUE)]
      if (length(hit) == 1 && nlevels(f) > 2 || (length(hit) == 1 && grepl("female|weiblich|frau", hit, ignore.case = TRUE))) {
        f <- relevel(f, ref = hit); break
      }
    }
    safe[[paste0("a", i)]] <- f
  }
  safe <- safe[complete.cases(safe), ]
  fml <- as.formula(paste("chosen ~ reason +", paste(paste0("a", seq_along(others)), collapse = " + ")))
  m <- feols(fml, data = safe, cluster = ~id)
  print(summary(m))
  cf <- coef(m)
  getc <- function(l) if (is.na(l)) NA_real_ else unname(cf[paste0("reason", l)])
  list(drought = getc(lev_dr), flooding = getc(lev_fl), wildfires = getc(lev_wf),
       persecution = getc(lev_pe), n_resp = length(unique(safe$id)), n_obs = nobs(m))
}

safe_run <- function(path, label) {
  tryCatch(analyze(path, label), error = function(e) {
    message("ERROR in ", label, ": ", conditionMessage(e))
    list(drought = NA, flooding = NA, wildfires = NA, persecution = NA, n_resp = NA, n_obs = NA)
  })
}

us <- safe_run(f_us, "US")
de <- safe_run(f_de, "Germany")

fmt <- function(x) if (is.na(x)) "NA" else format(x, digits = 10)
cat(sprintf("RESULT:amce_drought_us=%s\n", fmt(us$drought)))
cat(sprintf("RESULT:amce_flooding_us=%s\n", fmt(us$flooding)))
cat(sprintf("RESULT:amce_wildfires_us=%s\n", fmt(us$wildfires)))
cat(sprintf("RESULT:amce_persecution_us=%s\n", fmt(us$persecution)))
cat(sprintf("RESULT:amce_drought_germany=%s\n", fmt(de$drought)))
cat(sprintf("RESULT:amce_flooding_germany=%s\n", fmt(de$flooding)))
cat(sprintf("RESULT:amce_wildfires_germany=%s\n", fmt(de$wildfires)))
cat(sprintf("RESULT:amce_persecution_germany=%s\n", fmt(de$persecution)))
cat(sprintf("RESULT:respondents_us=%s\n", fmt(us$n_resp)))
cat(sprintf("RESULT:respondents_germany=%s\n", fmt(de$n_resp)))
cat(sprintf("RESULT:choice_tasks_us=%s\n", fmt(us$n_obs)))
cat(sprintf("RESULT:choice_tasks_germany=%s\n", fmt(de$n_obs)))