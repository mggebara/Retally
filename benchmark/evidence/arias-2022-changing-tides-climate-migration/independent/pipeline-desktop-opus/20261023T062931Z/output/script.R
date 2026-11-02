suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
files <- list(
  us = file.path(base, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv"),
  germany = file.path(base, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")
)

gl <- function(p, x) {
  x <- as.character(x); x[is.na(x)] <- ""
  grepl(p, x, ignore.case = TRUE, useBytes = TRUE)
}
fix_enc <- function(x) {
  x <- as.character(x)
  bad <- !is.na(x) & !validUTF8(x)
  if (any(bad)) x[bad] <- iconv(x[bad], "latin1", "UTF-8", sub = "?")
  x
}
clean_txt <- function(x) {
  x <- fix_enc(x)
  x <- gsub("<[^>]+>", " ", x, useBytes = TRUE)
  x <- gsub("&nbsp;", " ", x, fixed = TRUE)
  x <- gsub("\\s+", " ", x, useBytes = TRUE)
  trimws(x)
}

read_q <- function(path) {
  raw <- read_csv(path, col_types = cols(.default = col_character()),
                  na = c("", "NA"), name_repair = "minimal", progress = FALSE)
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)
  nm <- names(raw)
  nm <- gsub("^﻿", "", nm)
  nm <- gsub("^\xef\xbb\xbf", "", nm, useBytes = TRUE)
  nm[nm == ""] <- paste0("V", which(nm == ""))
  nm <- make.unique(nm)
  names(raw) <- nm
  sd_col <- grep("StartDate", nm, value = TRUE)[1]
  is_data <- gl("^\\s*[0-9]{4}-[0-9]{2}-[0-9]{2}|^\\s*[0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4}", raw[[sd_col]])
  meta <- raw[!is_data, , drop = FALSE]
  df <- raw[is_data, , drop = FALSE]
  qt <- if (nrow(meta) >= 1) fix_enc(unlist(meta[1, ], use.names = FALSE)) else nm
  qt[is.na(qt)] <- ""
  names(qt) <- nm
  list(df = df, qt = qt)
}

map_choice <- function(v) {
  v <- clean_txt(v)
  v[v %in% c("", "-99")] <- NA
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) == 0) return(rep(NA_integer_, length(v)))
  num <- suppressWarnings(as.numeric(u))
  m <- NULL
  if (all(!is.na(num))) {
    if (all(num %in% c(1, 2))) m <- setNames(as.integer(num), u)
    else m <- setNames(as.integer(rank(num)), u)
  } else {
    dg <- regmatches(u, regexpr("[0-9]+", u))
    if (length(dg) == length(u) && length(unique(dg)) == length(u)) {
      m <- setNames(as.integer(rank(as.numeric(dg))), u)
    } else {
      lt <- sub(".*\\b([A-Za-z])\\s*[.:)]?$", "\\1", u)
      if (all(nchar(lt) == 1) && length(unique(toupper(lt))) == length(u)) {
        m <- setNames(as.integer(rank(toupper(lt))), u)
      } else {
        m <- setNames(seq_along(u), u)
      }
    }
  }
  out <- unname(m[v])
  out[!out %in% c(1L, 2L)] <- NA_integer_
  as.integer(out)
}

analyse <- function(path) {
  r <- read_q(path)
  df <- r$df; qt <- r$qt
  nm <- names(df)
  rid_col <- grep("^ResponseId$", nm, value = TRUE)[1]
  if (is.na(rid_col)) rid_col <- grep("ResponseI", nm, value = TRUE)[1]
  st_col <- grep("^Status$", nm, value = TRUE)[1]
  if (!is.na(st_col)) {
    st <- trimws(df[[st_col]])
    df <- df[!(st %in% c("1", "Survey Preview")), , drop = FALSE]
  }
  df$rid__ <- df[[rid_col]]
  nm <- names(df)

  sep <- "[-_.]"
  lev_idx <- grep(paste0("^F", sep, "[0-9]+", sep, "[0-9]+", sep, "[0-9]+$"), nm)
  name_idx <- grep(paste0("^F", sep, "[0-9]+", sep, "[0-9]+$"), nm)
  if (length(lev_idx) == 0) stop("no conjoint F- columns found")
  getnums <- function(s) as.integer(regmatches(s, gregexpr("[0-9]+", s))[[1]])
  name_map <- list()
  for (ci in name_idx) {
    z <- getnums(nm[ci]); name_map[[paste(z[1], z[2])]] <- nm[ci]
  }
  L <- list()
  for (ci in lev_idx) {
    z <- getnums(nm[ci])
    k <- z[1]; p <- z[2]; j <- z[3]
    ncn <- name_map[[paste(k, j)]]
    if (is.null(ncn)) next
    L[[length(L) + 1]] <- data.frame(rid = df$rid__, task = k, prof = p, pos = j,
                                     attr = df[[ncn]], level = df[[nm[ci]]],
                                     stringsAsFactors = FALSE)
  }
  long <- bind_rows(L)
  long <- long[!is.na(long$attr) & !is.na(long$level), ]
  long$attr <- clean_txt(long$attr)
  long$level <- clean_txt(long$level)
  long <- long[long$attr != "" & long$level != "", ]
  K <- max(long$task)
  resp_with_F <- unique(long$rid)
  nF <- length(resp_with_F)

  # ---- locate choice questions ----
  excl <- c("StartDate","EndDate","Status","IPAddress","Progress","Finished","RecordedDate",
            "ResponseId","RecipientLastName","RecipientFirstName","RecipientEmail",
            "ExternalReference","LocationLatitude","LocationLongitude","DistributionChannel",
            "UserLanguage","rid__")
  cand <- c()
  for (ci in seq_along(nm)) {
    cn <- nm[ci]
    if (ci %in% c(lev_idx, name_idx)) next
    if (cn %in% excl || gl("Duration|First Click|Last Click|Page Submit|Click Count|_DO|_TEXT|^F[-_.][0-9]", cn)) next
    v <- clean_txt(df[[cn]])
    v[v %in% c("", "-99")] <- NA
    nn <- sum(!is.na(v) & df$rid__ %in% resp_with_F)
    u <- unique(v[!is.na(v)])
    if (length(u) == 2 && nn >= 0.3 * nF) cand <- c(cand, ci)
  }
  task_of <- rep(NA_integer_, length(cand))
  for (i in seq_along(cand)) {
    t <- qt[nm[cand[i]]]
    mm <- regmatches(t, regexpr("Field/F[-_.][0-9]+[-_.]", t, useBytes = TRUE))
    if (length(mm) == 1) task_of[i] <- as.integer(regmatches(mm, regexpr("[0-9]+", mm)))
  }
  choice_cols <- NULL
  if (all(seq_len(K) %in% task_of)) {
    choice_cols <- sapply(seq_len(K), function(k) nm[cand[which(task_of == k)[1]]])
  } else {
    kw <- "migrant|admit|prefer|settle|choose|which of|zuwander|aufnehm|aufzunehm|bevorzug|ansied|einwander|lieber|w.{1,3}hlen|entscheiden|profil"
    kwc <- cand[gl(kw, qt[nm[cand]])]
    pool <- if (length(kwc) >= K) kwc else cand
    pool <- sort(pool)
    if (length(pool) < K) stop("could not find choice questions")
    best <- 1; bspan <- Inf
    for (s in 1:(length(pool) - K + 1)) {
      sp <- pool[s + K - 1] - pool[s]
      if (sp < bspan) { bspan <- sp; best <- s }
    }
    choice_cols <- nm[pool[best:(best + K - 1)]]
  }
  CH <- list()
  for (k in seq_len(K)) {
    CH[[k]] <- data.frame(rid = df$rid__, task = k, choice = map_choice(df[[choice_cols[k]]]),
                          stringsAsFactors = FALSE)
  }
  CH <- bind_rows(CH)
  CH <- CH[!is.na(CH$choice), ]

  wide <- long %>%
    distinct(rid, task, prof, attr, .keep_all = TRUE) %>%
    select(rid, task, prof, attr, level) %>%
    pivot_wider(names_from = attr, values_from = level)
  wide <- as.data.frame(wide, stringsAsFactors = FALSE)
  attrs <- setdiff(names(wide), c("rid", "task", "prof"))
  # drop sparse spurious attribute columns
  attrs <- attrs[sapply(attrs, function(a) mean(!is.na(wide[[a]])) > 0.5)]
  d <- merge(wide, CH, by = c("rid", "task"))
  d <- d[d$prof %in% c(1, 2), ]
  d$chosen <- as.integer(d$prof == d$choice)
  d <- d[complete.cases(d[, attrs, drop = FALSE]), ]

  pat <- list(
    drought = "drought|d\\S{1,3}rre|trocken",
    flooding = "flood|berschwemm|hochwasser|flut",
    wildfires = "wild ?fire|forest fire|bush ?fire|waldbr|buschbr|buschfeuer|feuer|brand|fire",
    persecution = "persecut|verfolg"
  )
  econ <- "econom|wirtschaft|opportun|chance|arbeit|job"
  reason <- NA
  for (a in attrs) {
    lv <- unique(d[[a]])
    if (any(gl(pat$drought, lv)) && any(gl(pat$persecution, lv))) { reason <- a; break }
  }
  if (is.na(reason)) stop("reason attribute not found")
  newn <- paste0("A", seq_along(attrs))
  for (i in seq_along(attrs)) d[[newn[i]]] <- factor(d[[attrs[i]]])
  rv <- newn[attrs == reason]
  lv <- levels(d[[rv]])
  other <- !(gl(pat$drought, lv) | gl(pat$flooding, lv) | gl(pat$wildfires, lv) | gl(pat$persecution, lv))
  basel <- lv[gl(econ, lv) & other]
  if (length(basel) == 0) basel <- lv[other]
  if (length(basel) >= 1) d[[rv]] <- relevel(d[[rv]], ref = basel[1])
  fml <- as.formula(paste("chosen ~", paste(newn, collapse = " + ")))
  m <- feols(fml, data = d, cluster = ~rid)
  cf <- coef(m)
  get <- function(p) {
    l <- levels(d[[rv]])[-1]
    hit <- l[gl(p, l)]
    if (length(hit) == 0) return(NA_real_)
    unname(cf[paste0(rv, hit[1])])
  }
  # ensure persecution not matched by wildfire pattern etc.
  out <- c(
    drought = get(pat$drought),
    flooding = get(pat$flooding),
    wildfires = {
      l <- levels(d[[rv]])[-1]
      hit <- l[gl(pat$wildfires, l) & !gl(pat$persecution, l) & !gl(pat$drought, l) & !gl(pat$flooding, l)]
      if (length(hit) == 0) NA_real_ else unname(cf[paste0(rv, hit[1])])
    },
    persecution = get(pat$persecution)
  )
  list(coefs = out, n_resp = length(unique(d$rid)), n_obs = nrow(d))
}

res <- list()
for (cc in names(files)) {
  res[[cc]] <- tryCatch(analyse(files[[cc]]), error = function(e) {
    message("Error for ", cc, ": ", conditionMessage(e)); NULL
  })
}

for (cc in names(files)) {
  r <- res[[cc]]
  if (is.null(r)) next
  for (nmk in names(r$coefs)) {
    cat(sprintf("RESULT:amce_%s_%s=%.6f\n", nmk, cc, r$coefs[[nmk]]))
  }
  cat(sprintf("RESULT:respondents_%s=%d\n", cc, r$n_resp))
  cat(sprintf("RESULT:choice_tasks_%s=%d\n", cc, r$n_obs))
}