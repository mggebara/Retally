suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
f_us <- file.path(base_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
f_de <- file.path(base_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

read_qualtrics <- function(f) {
  d <- readr::read_csv(f, col_types = cols(.default = col_character()),
                       na = c("", "NA"), show_col_types = FALSE, progress = FALSE,
                       locale = locale(encoding = "UTF-8"))
  nm <- names(d)
  qtext <- nm
  drop <- 0
  first_sd <- if ("StartDate" %in% nm) d$StartDate[1] else as.character(unlist(d[1, 1]))
  if (!is.na(first_sd) && grepl("^\\s*\\d{4}-\\d{2}-\\d{2}", first_sd)) {
    drop <- 0
  } else {
    r1 <- as.character(unlist(d[1, ]))
    if (any(grepl("ImportId", r1, fixed = TRUE))) {
      drop <- 1
    } else {
      qtext <- ifelse(is.na(r1), nm, r1)
      drop <- 1
      if (nrow(d) >= 2) {
        r2 <- as.character(unlist(d[2, ]))
        if (any(grepl("ImportId", r2, fixed = TRUE))) drop <- 2
      }
    }
  }
  names(qtext) <- nm
  if (drop > 0) d <- d[-(1:drop), , drop = FALSE]
  list(d = d, qtext = qtext)
}

map_choice <- function(v) {
  v <- trimws(v)
  v[!is.na(v) & v == ""] <- NA
  u <- unique(v[!is.na(v)])
  if (length(u) != 2) return(NULL)
  pats <- list(
    c("(^|[^0-9])1([^0-9]|$)", "(^|[^0-9])2([^0-9]|$)"),
    c("(^|[^A-Za-z])A([^A-Za-z]|$)", "(^|[^A-Za-z])B([^A-Za-z]|$)"),
    c("(?i)(first|erste|left|links)", "(?i)(second|zweite|right|rechts)")
  )
  for (pp in pats) {
    m1 <- grepl(pp[1], u, perl = TRUE)
    m2 <- grepl(pp[2], u, perl = TRUE)
    if (sum(m1) == 1 && sum(m2) == 1 && which(m1) != which(m2)) {
      out <- rep(NA_integer_, length(v))
      out[!is.na(v) & v == u[m1]] <- 1L
      out[!is.na(v) & v == u[m2]] <- 2L
      return(out)
    }
  }
  NULL
}

classify_reason <- function(x) {
  x <- ifelse(is.na(x), "", x)
  out <- rep(NA_character_, length(x))
  out[grepl("(?i)(verfolg|persecut)", x, perl = TRUE)] <- "persecution"
  out[is.na(out) & grepl("(?i)(drought|d.{1,2}rre|trockenheit)", x, perl = TRUE)] <- "drought"
  out[is.na(out) & grepl("(?i)(flood|berschwemm|hochwasser|flut)", x, perl = TRUE)] <- "flooding"
  out[is.na(out) & grepl("(?i)(wildfire|fire|waldbr|feuer|br.{1,2}nde)", x, perl = TRUE)] <- "wildfires"
  out[is.na(out) & grepl("(?i)(econom|opportun|wirtsch|konom|arbeit|chance|m.{1,2}glichkeit)", x, perl = TRUE)] <- "economic"
  out
}

meta_cols <- c("StartDate", "EndDate", "Status", "IPAddress", "Progress", "Duration (in seconds)",
               "Finished", "RecordedDate", "ResponseId", "RecipientLastName", "RecipientFirstName",
               "RecipientEmail", "ExternalReference", "LocationLatitude", "LocationLongitude",
               "DistributionChannel", "UserLanguage")

kw_re <- "(?i)(migrant|prefer|bevorzug|settle|ansied|aufnehm|aufgenommen|admit|which of|welche[nrs]? der|choose|w.{1,2}hlen|priorit|vorrang|einwander|fl.{1,2}chtling)"

process_country <- function(f, label) {
  q <- read_qualtrics(f)
  d <- q$d
  qtext <- q$qtext
  nm <- names(d)

  if ("Status" %in% nm) {
    d <- d[!(d$Status %in% c("Survey Preview", "Survey Test", "Spam", "1", "2", "8")), , drop = FALSE]
  }
  d$..resp <- if ("ResponseId" %in% nm) d$ResponseId else as.character(seq_len(nrow(d)))

  lvl_cols <- grep("^F[-_]\\d+[-_]\\d+[-_]\\d+$", nm, value = TRUE)
  att_cols <- grep("^F[-_]\\d+[-_]\\d+$", nm, value = TRUE)
  if (length(lvl_cols) == 0) stop("no conjoint level columns found")
  lp <- do.call(rbind, lapply(strsplit(sub("^F[-_]", "", lvl_cols), "[-_]"), as.integer))
  lvl_key <- setNames(lvl_cols, paste(lp[, 1], lp[, 2], lp[, 3], sep = "_"))
  if (length(att_cols) > 0) {
    ap <- do.call(rbind, lapply(strsplit(sub("^F[-_]", "", att_cols), "[-_]"), as.integer))
    att_key <- setNames(att_cols, paste(ap[, 1], ap[, 2], sep = "_"))
  } else att_key <- character(0)
  ntask <- max(lp[, 1]); nprof <- max(lp[, 2]); natt <- max(lp[, 3])
  cat(sprintf("[%s] rows=%d tasks=%d profiles=%d attributes=%d\n", label, nrow(d), ntask, nprof, natt))

  first_lvl <- lvl_key[paste(1, 1, 1, sep = "_")]
  has_conj <- !is.na(d[[first_lvl]]) & trimws(d[[first_lvl]]) != ""

  # detect choice questions
  other <- setdiff(nm, c(meta_cols, lvl_cols, att_cols, "..resp"))
  cand <- list()
  for (cc in other) {
    m <- map_choice(d[[cc]])
    if (is.null(m)) next
    if (sum(!is.na(m[has_conj])) < 0.3 * sum(has_conj)) next
    cand[[cc]] <- m
  }
  if (length(cand) == 0) stop("no choice columns found")
  cn <- names(cand)
  qt <- qtext[cn]; qt[is.na(qt)] <- cn[is.na(qt)]
  ntxt <- gsub("\\s+", " ", gsub("[0-9]+", "#", qt))
  kw <- grepl(kw_re, qt, perl = TRUE)
  tab <- table(ntxt)
  grp <- names(tab)[tab == ntask]
  sel <- NULL
  if (length(grp) >= 1) {
    if (length(grp) > 1) {
      gk <- grp[sapply(grp, function(g) any(kw[ntxt == g]))]
      if (length(gk) >= 1) grp <- gk
    }
    sel <- cn[ntxt == grp[1]]
  } else if (sum(kw) == ntask) {
    sel <- cn[kw]
  } else if (sum(kw) > ntask) {
    sel <- tail(cn[kw], ntask)
  } else {
    sel <- tail(cn, ntask)
  }
  if (length(sel) != ntask) stop("could not identify choice columns")
  tnum <- seq_len(ntask)
  if (all(grepl("F[-_][0-9]+[-_]", qtext[sel]))) {
    tt <- as.integer(sub("^.*?F[-_]([0-9]+)[-_].*$", "\\1", qtext[sel], perl = TRUE))
    if (length(unique(tt)) == ntask && all(tt %in% seq_len(ntask))) tnum <- tt
  }
  cat(sprintf("[%s] choice columns: %s\n", label, paste(sel, collapse = ",")))

  # build long data
  dd <- d[has_conj, , drop = FALSE]
  chosen_by_task <- lapply(sel, function(cc) cand[[cc]][has_conj])
  names(chosen_by_task) <- as.character(tnum)
  pieces <- list()
  k <- 0
  for (t in seq_len(ntask)) {
    ch <- chosen_by_task[[as.character(t)]]
    for (p in seq_len(nprof)) {
      for (a in seq_len(natt)) {
        lc <- lvl_key[paste(t, p, a, sep = "_")]
        if (is.na(lc)) next
        ak <- paste(t, a, sep = "_")
        aname <- if (ak %in% names(att_key)) dd[[att_key[ak]]] else rep(paste0("att", a), nrow(dd))
        k <- k + 1
        pieces[[k]] <- data.frame(resp = dd$..resp, task = t, prof = p,
                                  attname = trimws(aname), level = trimws(dd[[lc]]),
                                  chosen = as.integer(ch == p), stringsAsFactors = FALSE)
      }
    }
  }
  long <- bind_rows(pieces)
  long <- long[!is.na(long$attname) & long$attname != "", ]
  wide <- long %>%
    pivot_wider(id_cols = c(resp, task, prof, chosen), names_from = attname,
                values_from = level, values_fn = function(x) x[1])
  attr_names <- setdiff(names(wide), c("resp", "task", "prof", "chosen"))
  wide <- wide[!is.na(wide$chosen), ]
  for (an in attr_names) wide <- wide[!is.na(wide[[an]]) & wide[[an]] != "", ]
  cat(sprintf("[%s] attributes: %s\n", label, paste(attr_names, collapse = " | ")))

  # identify reason-for-migration attribute
  score <- sapply(attr_names, function(an) {
    lv <- unique(wide[[an]])
    sum(c("drought", "flooding", "wildfires", "persecution") %in% classify_reason(lv))
  })
  reason_att <- attr_names[which.max(score)]
  rc <- classify_reason(wide[[reason_att]])
  lv_tab <- unique(data.frame(level = wide[[reason_att]], cls = rc))
  print(lv_tab)
  wide$r_drought <- as.integer(rc %in% "drought")
  wide$r_flooding <- as.integer(rc %in% "flooding")
  wide$r_wildfires <- as.integer(rc %in% "wildfires")
  wide$r_persecution <- as.integer(rc %in% "persecution")

  others <- setdiff(attr_names, reason_att)
  for (i in seq_along(others)) wide[[paste0("x", i)]] <- factor(wide[[others[i]]])
  fml <- as.formula(paste("chosen ~ r_drought + r_flooding + r_wildfires + r_persecution",
                          if (length(others) > 0) paste("+", paste(paste0("x", seq_along(others)), collapse = " + ")) else ""))
  m <- feols(fml, data = wide, cluster = ~resp)
  print(summary(m))
  cf <- coef(m)
  list(drought = unname(cf["r_drought"]), flooding = unname(cf["r_flooding"]),
       wildfires = unname(cf["r_wildfires"]), persecution = unname(cf["r_persecution"]),
       nresp = length(unique(wide$resp)), nobs = nobs(m))
}

empty <- list(drought = NA, flooding = NA, wildfires = NA, persecution = NA, nresp = NA, nobs = NA)
res_us <- tryCatch(process_country(f_us, "US"), error = function(e) { cat("US error:", conditionMessage(e), "\n"); empty })
res_de <- tryCatch(process_country(f_de, "Germany"), error = function(e) { cat("Germany error:", conditionMessage(e), "\n"); empty })

fmt <- function(x) if (is.na(x)) "NA" else format(x, digits = 10)
cat(sprintf("RESULT:amce_drought_us=%s\n", fmt(res_us$drought)))
cat(sprintf("RESULT:amce_flooding_us=%s\n", fmt(res_us$flooding)))
cat(sprintf("RESULT:amce_wildfires_us=%s\n", fmt(res_us$wildfires)))
cat(sprintf("RESULT:amce_persecution_us=%s\n", fmt(res_us$persecution)))
cat(sprintf("RESULT:amce_drought_germany=%s\n", fmt(res_de$drought)))
cat(sprintf("RESULT:amce_flooding_germany=%s\n", fmt(res_de$flooding)))
cat(sprintf("RESULT:amce_wildfires_germany=%s\n", fmt(res_de$wildfires)))
cat(sprintf("RESULT:amce_persecution_germany=%s\n", fmt(res_de$persecution)))
cat(sprintf("RESULT:respondents_us=%s\n", fmt(res_us$nresp)))
cat(sprintf("RESULT:respondents_germany=%s\n", fmt(res_de$nresp)))
cat(sprintf("RESULT:choice_tasks_us=%s\n", fmt(res_us$nobs)))
cat(sprintf("RESULT:choice_tasks_germany=%s\n", fmt(res_de$nobs)))
