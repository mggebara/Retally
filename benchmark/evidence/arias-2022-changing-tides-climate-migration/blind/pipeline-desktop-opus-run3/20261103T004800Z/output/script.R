suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
f_us <- file.path(base_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
f_de <- file.path(base_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

clean_str <- function(x) {
  x <- as.character(x)
  x <- iconv(x, "UTF-8", "UTF-8", sub = "?")
  x <- gsub("<[^>]+>", " ", x)
  x <- gsub("&nbsp;", " ", x, fixed = TRUE)
  x <- gsub("\\s+", " ", x)
  x <- trimws(x)
  x[x == ""] <- NA
  x
}

read_qualtrics <- function(path) {
  d <- suppressWarnings(read_csv(path, col_types = cols(.default = col_character()),
                                 show_col_types = FALSE, progress = FALSE))
  # check encoding
  smp <- unlist(lapply(d, function(z) z[!is.na(z)]), use.names = FALSE)
  if (length(smp) > 0 && mean(!validUTF8(smp)) > 0) {
    d <- suppressWarnings(read_csv(path, col_types = cols(.default = col_character()),
                                   locale = locale(encoding = "latin1"),
                                   show_col_types = FALSE, progress = FALSE))
  }
  d <- as.data.frame(d, stringsAsFactors = FALSE, check.names = FALSE)
  qtext <- NULL
  if (nrow(d) >= 2) {
    r2 <- paste(unlist(d[2, ]), collapse = " ")
    r1 <- paste(unlist(d[1, ]), collapse = " ")
    if (grepl("ImportId", r2, fixed = TRUE)) {
      qtext <- as.character(unlist(d[1, ]))
      d <- d[-(1:2), , drop = FALSE]
    } else if (grepl("ImportId", r1, fixed = TRUE)) {
      d <- d[-1, , drop = FALSE]
    } else if ("StartDate" %in% names(d) && grepl("Start Date", d$StartDate[1], fixed = TRUE)) {
      qtext <- as.character(unlist(d[1, ]))
      d <- d[-1, , drop = FALSE]
    }
  }
  if (!is.null(qtext)) names(qtext) <- names(d)
  if ("Status" %in% names(d)) {
    d <- d[is.na(d$Status) | !grepl("preview", d$Status, ignore.case = TRUE), , drop = FALSE]
  }
  list(d = d, qtext = qtext)
}

choice_regex <- "which|prefer|admit|choose|chose|settle|welche|bevorzug|aufnehm|ansiedel|entscheid|w.hlen|lieber|aufnahme"
label_regex <- "migrant|person|profil|einwander|zuwander|option|kandidat"

find_choice_cols <- function(d, qtext, ntask) {
  nm <- names(d)
  is_f <- grepl("^F-[0-9]+-[0-9]+(-[0-9]+)?$", nm)
  meta <- c("StartDate","EndDate","Status","IPAddress","Progress","Duration (in seconds)","Finished",
            "RecordedDate","ResponseId","RecipientLastName","RecipientFirstName","RecipientEmail",
            "ExternalReference","LocationLatitude","LocationLongitude","DistributionChannel","UserLanguage")
  cand <- which(!is_f & !(nm %in% meta))
  info <- lapply(cand, function(ci) {
    v <- clean_str(d[[ci]])
    u <- unique(v[!is.na(v)])
    list(ci = ci, nu = length(u), share = mean(!is.na(v)), u = u)
  })
  bin <- Filter(function(z) z$nu == 2 && z$share > 0.3, info)
  if (length(bin) == 0) return(integer(0))
  lab_score <- sapply(bin, function(z) {
    u <- tolower(z$u)
    s <- 0
    if (all(grepl(label_regex, u))) s <- s + 2
    if (all(grepl("(1|2|a|b)\\s*\\)?\\.?$", u)) && !all(u %in% c("1","2"))) s <- s + 1
    if (any(grepl("^(male|female|m.nnlich|weiblich|yes|no|ja|nein|true|false)$", u))) s <- s - 5
    s
  })
  q_score <- sapply(bin, function(z) {
    if (is.null(qtext)) return(0)
    q <- tolower(clean_str(qtext[z$ci]))
    if (!is.na(q) && grepl(choice_regex, q)) 2 else 0
  })
  tot <- lab_score + q_score
  cols <- sapply(bin, function(z) z$ci)
  best <- max(tot)
  sel <- cols[tot == best]
  if (length(sel) < ntask) {
    # widen to anything with positive score
    sel <- cols[tot > 0]
  }
  if (length(sel) < ntask) sel <- cols[tot >= max(0, best - 1)]
  sel <- sort(sel)
  if (length(sel) > ntask) {
    # prefer a contiguous-ish block: take the last ntask before F columns? take first ntask
    sel <- sel[seq_len(ntask)]
  }
  sel
}

map_choice <- function(v) {
  v <- clean_str(v)
  u <- sort(unique(v[!is.na(v)]))
  out <- rep(NA_integer_, length(v))
  lv <- tolower(v)
  dig <- suppressWarnings(as.integer(sub(".*?([12])\\D*$", "\\1", lv, perl = TRUE)))
  dig[!grepl("[12]\\D*$", lv)] <- NA
  if (all(!is.na(dig[!is.na(v)])) && length(unique(dig[!is.na(dig)])) == 2) {
    out <- dig
  } else if (all(grepl("(a|b)\\W*$", tolower(u)))) {
    out[grepl("a\\W*$", lv)] <- 1L
    out[grepl("b\\W*$", lv)] <- 2L
  } else {
    out[v == u[1]] <- 1L
    out[v == u[2]] <- 2L
  }
  out
}

build_long <- function(path) {
  rq <- read_qualtrics(path)
  d <- rq$d
  qtext <- rq$qtext
  nm <- names(d)
  lev_cols <- grep("^F-[0-9]+-[0-9]+-[0-9]+$", nm, value = TRUE)
  parts <- do.call(rbind, strsplit(sub("^F-", "", lev_cols), "-"))
  K <- max(as.integer(parts[, 1])); J <- max(as.integer(parts[, 2])); A <- max(as.integer(parts[, 3]))
  ch_cols <- find_choice_cols(d, qtext, K)
  K <- min(K, length(ch_cols))
  id <- if ("ResponseId" %in% nm) d$ResponseId else as.character(seq_len(nrow(d)))
  id[is.na(id)] <- paste0("row", which(is.na(id)))
  rows <- list()
  for (k in seq_len(K)) {
    ch <- map_choice(d[[ch_cols[k]]])
    for (j in seq_len(J)) {
      df <- data.frame(id = id, task = k, profile = j,
                       y = as.integer(ch == j), stringsAsFactors = FALSE)
      for (a in seq_len(A)) {
        an <- clean_str(d[[sprintf("F-%d-%d", k, a)]])
        lv <- clean_str(d[[sprintf("F-%d-%d-%d", k, j, a)]])
        df[[paste0("n", a)]] <- an
        df[[paste0("l", a)]] <- lv
      }
      rows[[length(rows) + 1]] <- df
    }
  }
  long <- do.call(rbind, rows)
  # reshape attribute by name
  anames <- unique(unlist(long[, paste0("n", seq_len(A))]))
  anames <- anames[!is.na(anames)]
  out <- long[, c("id", "task", "profile", "y")]
  for (an in anames) {
    val <- rep(NA_character_, nrow(long))
    for (a in seq_len(A)) {
      hit <- !is.na(long[[paste0("n", a)]]) & long[[paste0("n", a)]] == an
      val[hit] <- long[[paste0("l", a)]][hit]
    }
    out[[paste0("att", match(an, anames))]] <- val
  }
  attr(out, "anames") <- anames
  out
}

reg_pat <- list(
  drought = "drought|d.{0,2}rre|trocken",
  flooding = "flood|berschwemm|hochwasser|flut",
  wildfires = "wildfire|fire|brand",
  persecution = "persecut|verfolg"
)
econ_pat <- "econom|wirtschaft|arbeit|job|opportunit|chancen|m.glichkeit"

estimate <- function(path) {
  long <- build_long(path)
  attcols <- grep("^att[0-9]+$", names(long), value = TRUE)
  # keep attributes present for most rows (drop spurious names)
  keep <- attcols[sapply(attcols, function(a) mean(!is.na(long[[a]])) > 0.5)]
  est <- long[!is.na(long$y), ]
  est <- est[complete.cases(est[, keep, drop = FALSE]), ]
  reason_var <- NULL
  for (a in keep) {
    u <- tolower(unique(est[[a]]))
    if (any(grepl(reg_pat$persecution, u)) || (any(grepl(reg_pat$drought, u)) && any(grepl(reg_pat$flooding, u)))) {
      reason_var <- a; break
    }
  }
  for (a in keep) {
    lv <- sort(unique(est[[a]]))
    base <- lv[1]
    if (!is.null(reason_var) && a == reason_var) {
      b <- lv[grepl(econ_pat, tolower(lv))]
      if (length(b) > 0) base <- b[1]
    }
    est[[a]] <- relevel(factor(est[[a]], levels = lv), ref = base)
  }
  fml <- as.formula(paste("y ~", paste(keep, collapse = " + ")))
  m <- feols(fml, data = est, cluster = ~id)
  cf <- coef(m)
  res <- list()
  for (nmr in names(reg_pat)) {
    val <- NA_real_
    if (!is.null(reason_var)) {
      cn <- names(cf)[startsWith(names(cf), reason_var)]
      lvl <- substring(cn, nchar(reason_var) + 1)
      hit <- grepl(reg_pat[[nmr]], tolower(lvl))
      if (nmr == "wildfires") hit <- hit & !grepl(reg_pat$persecution, tolower(lvl))
      if (any(hit)) val <- unname(cf[cn[which(hit)[1]]])
    }
    res[[nmr]] <- val
  }
  res$n_resp <- length(unique(est$id))
  res$n_obs <- nobs(m)
  res
}

safe_est <- function(path) {
  tryCatch(estimate(path), error = function(e) {
    message("Error: ", conditionMessage(e))
    list(drought = NA, flooding = NA, wildfires = NA, persecution = NA, n_resp = NA, n_obs = NA)
  })
}

us <- safe_est(f_us)
de <- safe_est(f_de)

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