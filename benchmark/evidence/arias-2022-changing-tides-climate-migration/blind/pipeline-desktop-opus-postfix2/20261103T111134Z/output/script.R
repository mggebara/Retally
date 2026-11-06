suppressPackageStartupMessages({
  library(readr)
  library(data.table)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
files <- list(
  us      = file.path(base_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv"),
  germany = file.path(base_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")
)

pat_drought  <- "drought|d.{1,3}rre|trocken"
pat_flood    <- "flood|berschwemm|hochwasser|flut"
pat_wildfire <- "wildfire|waldbr|buschbr|fire|feuer"
pat_persec   <- "persecut|verfolg"
reason_any   <- paste(pat_drought, pat_flood, pat_wildfire, pat_persec, sep = "|")

map_choice <- function(x) {
  x <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(x))
  is1 <- grepl("(^|[^0-9])1([^0-9]|$)|\\ba\\b|first|erst", x)
  is2 <- grepl("(^|[^0-9])2([^0-9]|$)|\\bb\\b|second|zweit", x)
  out[is1 & !is2] <- 1L
  out[is2 & !is1] <- 2L
  out[is.na(x) | x == ""] <- NA_integer_
  out
}

find_choice_cols <- function(df) {
  nms <- names(df)
  excl <- grepl("^F-|Click|Submit|_resp$|^force_choice$|^Status$|^Finished$|^Progress$|^UserLanguage$|^Distribution|^Recipient|^External|^Location|^IPAddress$|^ResponseId$|Date$|Duration|PARTISANSHIP|NATIVE_BORN|TREATMENT|IDEOLOGY|state_region|EMPLOYMENT|^Age$|SURVEY_HISTORY|TRUST_GOVT|POL_INTEREST",
               nms, ignore.case = FALSE)
  cand <- c()
  nn <- c()
  for (k in which(!excl)) {
    v <- df[[k]]
    v <- v[!is.na(v) & trimws(v) != ""]
    if (length(v) < 50) next
    u <- unique(trimws(v))
    if (length(u) != 2) next
    m <- map_choice(u)
    if (any(is.na(m)) || length(unique(m)) != 2) next
    cand <- c(cand, nms[k]); nn <- c(nn, length(v))
  }
  if (length(cand) == 0) return(character(0))
  named <- cand[grepl("choice|choose|pref|admit|select|conjoint|cj|wahl|task", cand, ignore.case = TRUE)]
  pick_group <- function(cs) {
    if (length(cs) == 9) return(cs)
    stems <- gsub("[0-9]+", "#", cs)
    tab <- table(stems)
    if (any(tab == 9)) return(cs[stems == names(tab)[tab == 9][1]])
    if (any(tab > 9)) {
      g <- names(tab)[which.max(tab)]
      cs2 <- cs[stems == g]
      cnt <- nn[match(cs2, cand)]
      best <- 1; bestsd <- Inf
      for (s in 1:(length(cs2) - 8)) {
        sdv <- sd(cnt[s:(s + 8)]) - mean(cnt[s:(s + 8)]) / 1000
        if (sdv < bestsd) { bestsd <- sdv; best <- s }
      }
      return(cs2[best:(best + 8)])
    }
    if (length(cs) > 9) return(cs[1:9])
    cs
  }
  if (length(named) >= 9) return(pick_group(named))
  pick_group(cand)
}

build_long <- function(df, smp) {
  df$rid <- seq_len(nrow(df))
  nms <- names(df)
  f2 <- grep("^F-[0-9]+-[0-9]+$", nms, value = TRUE)
  f3 <- grep("^F-[0-9]+-[0-9]+-[0-9]+$", nms, value = TRUE)
  chcols <- find_choice_cols(df)
  if (length(chcols) == 0) stop("no choice columns found")
  chcols <- chcols[order(match(chcols, nms))]

  if (length(f2) > 0 && length(f3) > 0) {
    parts3 <- do.call(rbind, lapply(strsplit(sub("^F-", "", f3), "-"), as.integer))
    # determine whether third index is profile (max 2) or attribute
    prof_pos <- if (max(parts3[, 2]) == 2 && max(parts3[, 3]) > 2) 2 else if (max(parts3[, 3]) == 2 && max(parts3[, 2]) > 2) 3 else 2
    tasks <- sort(unique(parts3[, 1]))
    out <- list()
    for (r in seq_len(nrow(parts3))) {
      t <- parts3[r, 1]
      p <- parts3[r, prof_pos]
      j <- parts3[r, ifelse(prof_pos == 2, 3, 2)]
      nm2 <- sprintf("F-%d-%d", t, j)
      if (!nm2 %in% nms) next
      out[[length(out) + 1]] <- data.table(rid = df$rid, task = t, prof = p,
                                           attr = df[[nm2]], level = df[[f3[r]]])
    }
    long <- rbindlist(out)
    long <- long[!is.na(attr) & attr != "" & !is.na(level) & level != ""]
    long[, attr := trimws(attr)]
    wide <- dcast(long, rid + task + prof ~ attr, value.var = "level",
                  fun.aggregate = function(x) x[1], fill = NA)
    attr_names <- setdiff(names(wide), c("rid", "task", "prof"))
  } else {
    # fallback: locate reason columns by content, assume order task1-prof1, task1-prof2, ...
    rc <- nms[sapply(nms, function(n) {
      v <- tolower(df[[n]]); mean(grepl(reason_any, v[!is.na(v) & v != ""])) > 0.5 && sum(!is.na(v) & v != "") > 50
    })]
    tasks <- seq_len(floor(length(rc) / 2))
    out <- list()
    for (t in tasks) for (p in 1:2) {
      out[[length(out) + 1]] <- data.table(rid = df$rid, task = t, prof = p, reason = df[[rc[(t - 1) * 2 + p]]])
    }
    wide <- rbindlist(out)
    wide <- wide[!is.na(reason) & reason != ""]
    attr_names <- "reason"
  }
  cat(sprintf("SAMPLE:%s:with_conjoint_respondents=%d\n", smp, uniqueN(wide$rid)))
  cat(sprintf("SAMPLE:%s:profiles=%d\n", smp, nrow(wide)))

  # choice
  tasks_sorted <- sort(unique(wide$task))
  ch <- rbindlist(lapply(seq_along(tasks_sorted), function(i) {
    if (i > length(chcols)) return(NULL)
    data.table(rid = df$rid, task = tasks_sorted[i], choice = map_choice(df[[chcols[i]]]))
  }))
  wide <- merge(wide, ch, by = c("rid", "task"), all.x = TRUE)
  wide <- wide[!is.na(choice)]
  cat(sprintf("SAMPLE:%s:nonmissing_choice=%d\n", smp, nrow(wide)))
  wide[, chosen := as.integer(choice == prof)]

  # identify reason attribute
  rs <- sapply(attr_names, function(a) mean(grepl(pat_drought, tolower(wide[[a]]))))
  ra <- attr_names[which.max(rs)]
  rv <- tolower(wide[[ra]])
  wide[, d_drought := as.integer(grepl(pat_drought, rv))]
  wide[, d_flood := as.integer(!grepl(pat_drought, rv) & grepl(pat_flood, rv))]
  wide[, d_persec := as.integer(grepl(pat_persec, rv))]
  wide[, d_wildfire := as.integer(!grepl(pat_drought, rv) & !grepl(pat_flood, rv) & !grepl(pat_persec, rv) & grepl(pat_wildfire, rv))]
  others <- setdiff(attr_names, ra)
  newn <- character(0)
  for (k in seq_along(others)) {
    nn <- paste0("attr", k)
    wide[[nn]] <- factor(wide[[others[k]]])
    if (nlevels(wide[[nn]]) > 1) newn <- c(newn, nn)
  }
  list(data = wide, others = newn)
}

results <- list()
for (smp in names(files)) {
  res <- tryCatch({
    df <- readr::read_csv(files[[smp]], col_types = cols(.default = col_character()),
                          name_repair = "minimal", progress = FALSE)
    df <- as.data.frame(df, stringsAsFactors = FALSE)
    cat(sprintf("SAMPLE:%s:loaded=%d\n", smp, nrow(df)))
    if ("StartDate" %in% names(df)) {
      df <- df[grepl("^[0-9]", df$StartDate), , drop = FALSE]
      cat(sprintf("SAMPLE:%s:drop_qualtrics_header_rows=%d\n", smp, nrow(df)))
    }
    if ("Status" %in% names(df)) {
      df <- df[!(df$Status %in% c("1", "Survey Preview", "8", "Spam")), , drop = FALSE]
      cat(sprintf("SAMPLE:%s:drop_previews=%d\n", smp, nrow(df)))
    }
    bl <- build_long(df, smp)
    d <- bl$data
    rhs <- c("d_drought", "d_flood", "d_wildfire", "d_persec", bl$others)
    fml <- as.formula(paste("chosen ~", paste(rhs, collapse = " + ")))
    m <- feols(fml, data = d, cluster = ~rid)
    cat(sprintf("SAMPLE:%s:estimation=%d\n", smp, nobs(m)))
    est_rows <- setdiff(seq_len(nrow(d)), unlist(m$obs_selection))
    used <- if (length(m$obs_selection) > 0) d[unlist(m$obs_selection)] else d
    if (length(m$obs_selection) > 0 && all(unlist(m$obs_selection) < 0)) used <- d[unlist(m$obs_selection)]
    cf <- coef(m); se <- sqrt(diag(vcov(m)))
    list(drought = cf["d_drought"], flooding = cf["d_flood"], wildfires = cf["d_wildfire"],
         persecution = cf["d_persec"],
         se_drought = se["d_drought"], se_flooding = se["d_flood"], se_wildfires = se["d_wildfire"],
         se_persecution = se["d_persec"],
         n = nobs(m), resp = uniqueN(used$rid))
  }, error = function(e) {
    message("Error in ", smp, ": ", conditionMessage(e))
    list(drought = NA, flooding = NA, wildfires = NA, persecution = NA, n = NA, resp = NA)
  })
  results[[smp]] <- res
}

fmt <- function(x) ifelse(is.na(x), "NA", format(unname(x), digits = 8, scientific = FALSE))
for (smp in names(results)) {
  r <- results[[smp]]
  cat(sprintf("RESULT:amce_drought_%s=%s\n", smp, fmt(r$drought)))
  cat(sprintf("RESULT:amce_flooding_%s=%s\n", smp, fmt(r$flooding)))
  cat(sprintf("RESULT:amce_wildfires_%s=%s\n", smp, fmt(r$wildfires)))
  cat(sprintf("RESULT:amce_persecution_%s=%s\n", smp, fmt(r$persecution)))
}
for (smp in names(results)) {
  r <- results[[smp]]
  if (!is.null(r$se_drought)) {
    cat(sprintf("RESULT:se_amce_drought_%s=%s\n", smp, fmt(r$se_drought)))
    cat(sprintf("RESULT:se_amce_flooding_%s=%s\n", smp, fmt(r$se_flooding)))
    cat(sprintf("RESULT:se_amce_wildfires_%s=%s\n", smp, fmt(r$se_wildfires)))
    cat(sprintf("RESULT:se_amce_persecution_%s=%s\n", smp, fmt(r$se_persecution)))
  }
}
cat(sprintf("RESULT:respondents_us=%s\n", fmt(results$us$resp)))
cat(sprintf("RESULT:respondents_germany=%s\n", fmt(results$germany$resp)))
cat(sprintf("RESULT:choice_tasks_us=%s\n", fmt(results$us$n)))
cat(sprintf("RESULT:choice_tasks_germany=%s\n", fmt(results$germany$n)))