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

# patterns for reason-for-migration levels (English + German)
pat_econ <- "(?i)econom|wirtschaft|ökonom|oekonom|arbeitsm|job|employment"
pat_drought <- "(?i)drought|dürre|duerre|trockenheit"
pat_flood <- "(?i)flood|überschwemm|ueberschwemm|hochwasser|flut"
pat_fire <- "(?i)wildfire|fire|waldbr|brand|feuer"
pat_pers <- "(?i)persecut|verfolg"

choice_text_pat <- "(?i)which|welche|welchen|prefer|bevorzug|admit|aufnehm|aufgenommen|choose|wähl|waehl|entscheid|settle|ansiedl|niederlass|lieber|eher"

read_qualtrics <- function(path) {
  raw <- suppressWarnings(readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()),
                                          progress = FALSE, name_repair = "minimal"))
  nm <- names(raw)
  nm <- sub("^﻿", "", nm)
  names(raw) <- nm
  qtext <- rep(NA_character_, length(nm))
  drop <- integer(0)
  for (r in 1:min(3, nrow(raw))) {
    v <- raw[[ifelse("StartDate" %in% nm, "StartDate", nm[1])]][r]
    v2 <- paste(unlist(raw[r, ]), collapse = " ")
    if (!is.na(v) && (grepl("Start", v) || grepl("ImportId", v) || grepl("ImportId", v2))) {
      if (!grepl("ImportId", v2) && all(is.na(qtext))) qtext <- as.character(unlist(raw[r, ]))
      drop <- c(drop, r)
    }
  }
  if (length(drop) > 0) raw <- raw[-drop, , drop = FALSE]
  if (all(is.na(qtext))) qtext <- nm
  list(data = raw, qtext = qtext)
}

build_long <- function(path) {
  q <- read_qualtrics(path)
  d <- q$data
  qtext <- q$qtext
  nm <- names(d)
  id_col <- if ("ResponseId" %in% nm) "ResponseId" else nm[grepl("(?i)responseid", nm)][1]
  d$.rid <- d[[id_col]]
  if (any(is.na(d$.rid) | d$.rid == "")) d$.rid[is.na(d$.rid) | d$.rid == ""] <- paste0("row", which(is.na(d$.rid) | d$.rid == ""))

  re_name <- "^F[-_.](\\d+)[-_.](\\d+)$"
  re_lev <- "^F[-_.](\\d+)[-_.](\\d+)[-_.](\\d+)$"
  name_cols <- nm[grepl(re_name, nm)]
  lev_cols <- nm[grepl(re_lev, nm)]
  if (length(lev_cols) == 0) stop("No conjoint attribute columns (F-t-k-j) found in ", path)
  nm_m <- str_match(name_cols, re_name)
  lv_m <- str_match(lev_cols, re_lev)
  tasks <- sort(unique(as.integer(lv_m[, 2])))
  n_tasks <- length(tasks)
  profiles <- sort(unique(as.integer(lv_m[, 3])))

  # ---- identify choice columns ----
  meta <- c("StartDate","EndDate","Status","IPAddress","Progress","Duration (in seconds)","Finished",
            "RecordedDate","ResponseId","RecipientLastName","RecipientFirstName","RecipientEmail",
            "ExternalReference","LocationLatitude","LocationLongitude","DistributionChannel","UserLanguage", ".rid")
  cand <- setdiff(nm, c(meta, name_cols, lev_cols))
  # exclude screener items (e.g. NATIVE_BORN) that share the two-level answer format of the choice items
  cand <- cand[!grepl("(?i)native|born", cand)]
  info <- lapply(cand, function(cn) {
    v <- d[[cn]]
    v <- str_trim(v)
    u <- sort(unique(v[!is.na(v) & v != ""]))
    list(col = cn, u = u, nn = sum(!is.na(v) & v != ""), pos = match(cn, nm))
  })
  two <- Filter(function(x) length(x$u) == 2 && x$nn >= 0.3 * nrow(d), info)
  choice_cols <- NULL
  if (length(two) > 0) {
    keys <- sapply(two, function(x) paste(x$u, collapse = "||"))
    txt <- sapply(two, function(x) qtext[x$pos])
    txtmatch <- grepl(choice_text_pat, txt) | grepl("(?i)migrant|profil|person", keys)
    grp <- split(seq_along(two), keys)
    best <- NULL; best_score <- -Inf
    for (g in names(grp)) {
      idx <- grp[[g]]
      cnt <- length(idx)
      score <- -abs(cnt - n_tasks) * 10 + sum(txtmatch[idx]) +
        5 * grepl("1|2|A|B", g) + 3 * grepl("(?i)migrant|profil|person", g) -
        20 * grepl("(?i)^(female\\|\\|male|männlich|weiblich|yes\\|\\|no|ja\\|\\|nein|no\\|\\|yes|nein\\|\\|ja)", g)
      if (cnt >= n_tasks) score <- score + 2
      if (score > best_score) { best_score <- score; best <- idx }
    }
    sel <- two[best]
    sel <- sel[order(sapply(sel, `[[`, "pos"))]
    if (length(sel) > n_tasks) {
      tm <- grepl(choice_text_pat, sapply(sel, function(x) qtext[x$pos]))
      if (sum(tm) >= n_tasks) sel <- sel[tm]
      sel <- sel[seq_len(n_tasks)]
    }
    choice_cols <- sapply(sel, `[[`, "col")
  }
  if (is.null(choice_cols) || length(choice_cols) < n_tasks) stop("Could not identify choice columns in ", path)
  message("Choice columns (", basename(path), "): ", paste(choice_cols, collapse = ", "))

  # map choice values to profile number
  map_choice <- function(v) {
    v <- str_trim(v)
    out <- rep(NA_integer_, length(v))
    u <- sort(unique(v[!is.na(v) & v != ""]))
    dig <- suppressWarnings(as.integer(str_extract(u, "\\d+")))
    if (length(u) == 2 && all(!is.na(dig)) && length(unique(dig)) == 2) {
      lab <- rank(dig)
    } else {
      lab <- seq_along(u)
    }
    for (i in seq_along(u)) out[!is.na(v) & v == u[i]] <- as.integer(lab[i])
    out
  }

  long_list <- list()
  for (ti in seq_along(tasks)) {
    t <- tasks[ti]
    ch <- map_choice(d[[choice_cols[ti]]])
    for (k in profiles) {
      jj <- sort(unique(as.integer(lv_m[lv_m[, 2] == t & lv_m[, 3] == k, 4])))
      for (j in jj) {
        ncol_ <- name_cols[nm_m[, 2] == t & nm_m[, 3] == j]
        lcol_ <- lev_cols[lv_m[, 2] == t & lv_m[, 3] == k & lv_m[, 4] == j]
        if (length(ncol_) == 0 || length(lcol_) == 0) next
        long_list[[length(long_list) + 1]] <- tibble(
          rid = d$.rid, task = t, profile = k, choice = ch,
          attr = str_trim(d[[ncol_[1]]]), level = str_trim(d[[lcol_[1]]])
        )
      }
    }
  }
  ll <- bind_rows(long_list) %>% filter(!is.na(attr), attr != "", !is.na(level), level != "")
  wide <- ll %>%
    distinct(rid, task, profile, attr, .keep_all = TRUE) %>%
    pivot_wider(id_cols = c(rid, task, profile, choice), names_from = attr, values_from = level)
  wide <- wide %>% filter(!is.na(choice))
  attrs <- setdiff(names(wide), c("rid", "task", "profile", "choice"))
  wide <- wide[complete.cases(wide[, attrs]), ]
  wide$chosen <- as.integer(wide$choice == wide$profile)
  list(df = wide, attrs = attrs)
}

estimate <- function(path) {
  b <- build_long(path)
  df <- b$df
  attrs <- b$attrs
  # identify reason attribute
  reason_attr <- NULL
  for (a in attrs) {
    lv <- unique(df[[a]])
    if (any(grepl(pat_drought, lv)) && any(grepl(pat_pers, lv))) { reason_attr <- a; break }
  }
  if (is.null(reason_attr)) {
    for (a in attrs) if (any(grepl(pat_drought, unique(df[[a]])))) { reason_attr <- a; break }
  }
  if (is.null(reason_attr)) stop("Reason attribute not found")
  rhs <- c()
  reason_levels <- NULL
  for (ai in seq_along(attrs)) {
    a <- attrs[ai]
    lv <- sort(unique(df[[a]]))
    base <- lv[1]
    if (a == reason_attr) {
      eb <- lv[grepl(pat_econ, lv)]
      if (length(eb) > 0) base <- eb[1]
    } else {
      cand <- lv[grepl("(?i)^none$|^keine?$|unemployed|arbeitslos|^female$|weiblich|^frau$|atheist|agnostic|konfessionslos|another region|anderen region|andere region|region in", lv)]
      if (length(cand) > 0) base <- cand[1]
    }
    ord <- c(base, setdiff(lv, base))
    vname <- paste0("A", ai)
    df[[vname]] <- factor(match(df[[a]], ord), levels = seq_along(ord), labels = paste0("L", seq_along(ord)))
    rhs <- c(rhs, vname)
    if (a == reason_attr) { reason_levels <- ord; reason_var <- vname }
  }
  fml <- as.formula(paste("chosen ~", paste(rhs, collapse = " + ")))
  m <- feols(fml, data = df, cluster = ~rid)
  cf <- coef(m)
  se <- sqrt(diag(vcov(m)))
  get_lv <- function(pat) {
    i <- which(grepl(pat, reason_levels))
    i <- setdiff(i, 1)
    if (length(i) == 0) return(c(NA, NA))
    cn <- paste0(reason_var, "L", i[1])
    c(unname(cf[cn]), unname(se[cn]))
  }
  # wildfire pattern should not hit other levels; check order of matching
  out <- list(
    drought = get_lv(pat_drought),
    flooding = get_lv(pat_flood),
    wildfires = get_lv(pat_fire),
    persecution = get_lv(pat_pers),
    n_resp = length(unique(df$rid)),
    n_obs = nobs(m)
  )
  print(summary(m))
  message("Reason levels: ", paste(reason_levels, collapse = " | "))
  out
}

fmt <- function(x) ifelse(is.na(x), "NA", formatC(x, digits = 6, format = "f"))

res_us <- tryCatch(estimate(files$us), error = function(e) { message("US error: ", conditionMessage(e)); NULL })
res_de <- tryCatch(estimate(files$germany), error = function(e) { message("DE error: ", conditionMessage(e)); NULL })

emit <- function(name, val) cat(sprintf("RESULT:%s=%s\n", name, fmt(val)))

if (!is.null(res_us)) {
  emit("amce_drought_us", res_us$drought[1]); emit("amce_drought_us_se", res_us$drought[2])
  emit("amce_flooding_us", res_us$flooding[1]); emit("amce_flooding_us_se", res_us$flooding[2])
  emit("amce_wildfires_us", res_us$wildfires[1]); emit("amce_wildfires_us_se", res_us$wildfires[2])
  emit("amce_persecution_us", res_us$persecution[1]); emit("amce_persecution_us_se", res_us$persecution[2])
  cat(sprintf("RESULT:respondents_us=%d\n", as.integer(res_us$n_resp)))
  cat(sprintf("RESULT:choice_tasks_us=%d\n", as.integer(res_us$n_obs)))
}
if (!is.null(res_de)) {
  emit("amce_drought_germany", res_de$drought[1]); emit("amce_drought_germany_se", res_de$drought[2])
  emit("amce_flooding_germany", res_de$flooding[1]); emit("amce_flooding_germany_se", res_de$flooding[2])
  emit("amce_wildfires_germany", res_de$wildfires[1]); emit("amce_wildfires_germany_se", res_de$wildfires[2])
  emit("amce_persecution_germany", res_de$persecution[1]); emit("amce_persecution_germany_se", res_de$persecution[2])
  cat(sprintf("RESULT:respondents_germany=%d\n", as.integer(res_de$n_resp)))
  cat(sprintf("RESULT:choice_tasks_germany=%d\n", as.integer(res_de$n_obs)))
}
