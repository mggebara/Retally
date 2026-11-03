suppressPackageStartupMessages({
  library(readr)
  library(data.table)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
f_us <- file.path(base, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
f_de <- file.path(base, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

clean_val <- function(v) {
  v <- trimws(as.character(v))
  v[is.na(v)] <- ""
  v[v %in% c("-99", "-98", "NA")] <- ""
  v
}

read_qualtrics <- function(path) {
  raw <- readr::read_csv(path, col_names = FALSE,
                         col_types = readr::cols(.default = readr::col_character()),
                         na = character(), trim_ws = TRUE, progress = FALSE,
                         show_col_types = FALSE)
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)
  nm <- unlist(raw[1, ], use.names = FALSE)
  nm <- trimws(gsub("\ufeff", "", nm, fixed = TRUE))
  nm[is.na(nm) | nm == ""] <- paste0("V", which(is.na(nm) | nm == ""))
  nm <- make.unique(nm)
  r2 <- unlist(raw[2, ], use.names = FALSE)
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}|^[0-9]{1,2}/[0-9]{1,2}/", r2[1])) {
    qtext <- rep("", length(nm))
    dat <- raw[-1, , drop = FALSE]
  } else {
    qtext <- r2
    drop <- 1:2
    if (nrow(raw) >= 3) {
      r3 <- unlist(raw[3, ], use.names = FALSE)
      if (any(grepl("ImportId", r3[seq_len(min(10, length(r3)))], fixed = TRUE))) drop <- 1:3
    }
    dat <- raw[-drop, , drop = FALSE]
  }
  names(dat) <- nm
  qtext[is.na(qtext)] <- ""
  names(qtext) <- nm
  if ("Status" %in% nm) {
    st <- trimws(dat$Status)
    dat <- dat[!(st %in% c("Survey Preview", "Survey Test", "Spam", "1", "2", "8")), , drop = FALSE]
  }
  list(dat = dat, qtext = qtext)
}

drought_rx <- "drought|d.{1,2}rre|trockenheit"
flood_rx   <- "flood|berschwemm|hochwasser|flut"
wild_rx    <- "wildfire|fire|waldbr|buschbr|chenbr|feuer|br.{1,2}nde"
pers_rx    <- "persecut|verfolg"

gl <- function(rx, x) grepl(rx, x, ignore.case = TRUE, useBytes = TRUE)

std_reason <- function(x) {
  out <- rep("economic", length(x))
  out[gl(wild_rx, x)] <- "wildfires"
  out[gl(flood_rx, x)] <- "flooding"
  out[gl(drought_rx, x)] <- "drought"
  out[gl(pers_rx, x)] <- "persecution"
  out
}

norm_txt <- function(x) {
  x <- tolower(x)
  x <- gsub("<[^>]+>", " ", x, useBytes = TRUE)
  x <- gsub("\\$\\{[^}]*\\}", " ", x, useBytes = TRUE)
  x <- gsub("[0-9]+", " ", x, useBytes = TRUE)
  x <- gsub("[[:punct:][:space:]]+", "", x, useBytes = TRUE)
  x
}

analyze_country <- function(path, label) {
  q <- read_qualtrics(path)
  dat <- q$dat; qtext <- q$qtext; nm <- names(dat)
  N <- nrow(dat)
  rid <- if ("ResponseId" %in% nm) trimws(dat$ResponseId) else as.character(seq_len(N))
  rid[is.na(rid) | rid == ""] <- paste0("row", which(is.na(rid) | rid == ""))
  rid <- make.unique(rid)

  lev_rx <- "^([A-Za-z]+)-([0-9]+)-([0-9]+)-([0-9]+)$"
  lev_cols <- grep(lev_rx, nm, value = TRUE)
  if (!length(lev_cols)) {
    lev_rx <- "^([A-Za-z]*)[-_.]([0-9]+)[-_.]([0-9]+)[-_.]([0-9]+)$"
    lev_cols <- grep(lev_rx, nm, value = TRUE)
  }
  if (!length(lev_cols)) stop("no conjoint attribute columns found")
  m <- regmatches(lev_cols, regexec(lev_rx, lev_cols))
  info <- data.table(col = lev_cols,
                     pre = sapply(m, `[`, 2),
                     t = as.integer(sapply(m, `[`, 3)),
                     p = as.integer(sapply(m, `[`, 4)),
                     a = as.integer(sapply(m, `[`, 5)))
  info[, acol := sub("^(.*[-_.][0-9]+)([-_.])[0-9]+([-_.])([0-9]+)$", "\\1\\2\\4", col)]
  info <- info[p %in% 1:2]
  pre_order <- unique(info$pre)
  info[, key := paste(pre, t, sep = "-")]
  tk <- unique(info[, .(pre, t, key)])
  tk <- tk[order(match(pre, pre_order), t)]
  task_keys <- tk$key
  n_tasks <- length(task_keys)
  message(label, ": N rows=", N, " tasks=", n_tasks, " attr cols=", nrow(info))

  # long attribute data
  L <- rbindlist(lapply(seq_len(nrow(info)), function(i) {
    lv <- clean_val(dat[[info$col[i]]])
    lv <- trimws(gsub("<[^>]+>", "", lv, useBytes = TRUE))
    ac <- info$acol[i]
    an <- if (ac %in% nm) trimws(gsub("<[^>]+>", "", clean_val(dat[[ac]]), useBytes = TRUE)) else rep(paste0("attr", info$a[i]), N)
    data.table(rid = rid, key = info$key[i], p = info$p[i], an = an, lv = lv)
  }))
  L <- L[an != "" & lv != ""]

  # choice columns
  meta <- c("StartDate", "EndDate", "Status", "IPAddress", "Progress", "Duration (in seconds)",
            "Finished", "RecordedDate", "ResponseId", "RecipientLastName", "RecipientFirstName",
            "RecipientEmail", "ExternalReference", "LocationLatitude", "LocationLongitude",
            "DistributionChannel", "UserLanguage")
  excl <- union(meta, c(lev_cols, unique(info$acol)))
  cand <- setdiff(nm, excl)
  cand <- cand[!grepl("^[A-Za-z]+-[0-9]+(-[0-9]+)*$", cand)]
  cand <- cand[vapply(cand, function(cn) {
    v <- clean_val(dat[[cn]]); v <- v[v != ""]
    length(v) >= 0.2 * N && length(unique(v)) == 2
  }, logical(1))]
  if (!length(cand)) stop("no candidate choice columns")

  # mapping via piped text
  pipe_rx <- "e://Field/([A-Za-z]+)[-_.]([0-9]+)[-_.]"
  cmap <- character(0)
  for (cn in cand) {
    mm <- regmatches(qtext[cn], gregexpr(pipe_rx, qtext[cn], useBytes = TRUE))[[1]]
    if (!length(mm)) next
    ks <- unique(sub("^e://Field/([A-Za-z]+)[-_.]([0-9]+)[-_.]$", "\\1-\\2", mm))
    if (length(ks) == 1 && ks %in% task_keys && !(ks %in% names(cmap))) cmap[ks] <- cn
  }
  if (length(cmap) < ceiling(n_tasks / 2)) {
    choice_rx <- "prefer|admit|settle|which|choose|migrant|bevorz|welche|aufnehm|ansiedel|w.{1,2}hl"
    nt <- norm_txt(qtext[cand])
    g <- split(cand, nt)
    sizes <- vapply(g, length, integer(1))
    has_rx <- vapply(names(g), function(s) any(gl(choice_rx, qtext[g[[s]]])), logical(1))
    sel <- NULL
    if (any(sizes == n_tasks)) {
      ok <- which(sizes == n_tasks)
      if (any(has_rx[ok])) ok <- ok[has_rx[ok]]
      sel <- g[[ok[1]]]
    } else if (any(sizes > n_tasks)) {
      ok <- which(sizes > n_tasks)
      if (any(has_rx[ok])) ok <- ok[has_rx[ok]]
      ok <- ok[which.min(sizes[ok])]
      sel <- g[[ok]][seq_len(n_tasks)]
    } else {
      cr <- cand[gl(choice_rx, qtext[cand])]
      if (length(cr) >= n_tasks) sel <- cr[seq_len(n_tasks)] else sel <- cand[seq_len(min(n_tasks, length(cand)))]
    }
    sel <- sel[order(match(sel, nm))]
    k <- min(length(sel), n_tasks)
    cmap <- setNames(sel[seq_len(k)], task_keys[seq_len(k)])
  }
  message(label, ": choice columns: ", paste(names(cmap), "=", cmap, collapse = "; "))

  pooled <- unique(unlist(lapply(cmap, function(cn) clean_val(dat[[cn]]))))
  pooled <- pooled[pooled != ""]
  order_levs <- function(levs) {
    num <- suppressWarnings(as.numeric(levs))
    if (!anyNA(num)) levs[order(num)] else sort(levs)
  }
  C <- rbindlist(lapply(names(cmap), function(k) {
    v <- clean_val(dat[[cmap[[k]]]])
    levs <- if (length(pooled) == 2) pooled else unique(v[v != ""])
    levs <- order_levs(levs)
    ch <- match(v, levs)
    ch[!(ch %in% 1:2)] <- NA
    data.table(rid = rid, key = k, ch = ch)
  }))
  C <- C[!is.na(ch)]

  W <- dcast(L, rid + key + p ~ an, value.var = "lv", fun.aggregate = function(x) x[1], fill = NA)
  acols_raw <- setdiff(names(W), c("rid", "key", "p"))
  cover <- vapply(acols_raw, function(a) mean(!is.na(W[[a]]) & W[[a]] != ""), numeric(1))
  acols_raw <- acols_raw[cover >= 0.5]
  newn <- paste0("A", seq_along(acols_raw))
  setnames(W, acols_raw, newn)
  W <- W[, c("rid", "key", "p", newn), with = FALSE]
  W <- W[complete.cases(W)]
  for (a in newn) W <- W[get(a) != ""]
  W <- merge(W, C, by = c("rid", "key"))
  W[, nprof := .N, by = .(rid, key)]
  W <- W[nprof == 2]
  W[, chosen := as.integer(ch == p)]

  dshare <- vapply(newn, function(a) mean(gl(drought_rx, W[[a]])), numeric(1))
  rcol <- newn[which.max(dshare)]
  message(label, ": attributes: ", paste(newn, "=", acols_raw, collapse = "; "), " | reason col: ", rcol)
  message(label, ": raw reason levels: ", paste(unique(W[[rcol]]), collapse = " | "))
  W[, reason := relevel(factor(std_reason(get(rcol))), ref = "economic")]
  others <- setdiff(newn, rcol)
  for (o in others) set(W, j = o, value = factor(W[[o]]))
  fml <- as.formula(paste("chosen ~ reason", if (length(others)) paste("+", paste(others, collapse = " + ")) else ""))
  mod <- feols(fml, data = W, cluster = ~rid)
  print(summary(mod))
  list(coef = coef(mod), se = sqrt(diag(vcov(mod))),
       nresp = uniqueN(W$rid), nobs = nobs(mod))
}

emit <- function(name, val) {
  if (length(val) == 1 && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
}

for (cc in list(list(path = f_us, lab = "us"), list(path = f_de, lab = "germany"))) {
  res <- tryCatch(analyze_country(cc$path, cc$lab), error = function(e) {
    message("Error for ", cc$lab, ": ", conditionMessage(e)); NULL })
  if (is.null(res)) next
  cat(sprintf("SE %s: drought=%.4f flooding=%.4f wildfires=%.4f persecution=%.4f\n", cc$lab,
              res$se["reasondrought"], res$se["reasonflooding"], res$se["reasonwildfires"], res$se["reasonpersecution"]))
  emit(paste0("amce_drought_", cc$lab), res$coef["reasondrought"])
  emit(paste0("amce_flooding_", cc$lab), res$coef["reasonflooding"])
  emit(paste0("amce_wildfires_", cc$lab), res$coef["reasonwildfires"])
  emit(paste0("amce_persecution_", cc$lab), res$coef["reasonpersecution"])
  emit(paste0("respondents_", cc$lab), res$nresp)
  emit(paste0("choice_tasks_", cc$lab), res$nobs)
}