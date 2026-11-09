suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
f_us <- file.path(base_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
f_de <- file.path(base_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")

read_qualtrics <- function(path) {
  raw <- suppressWarnings(readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()),
                                          name_repair = "minimal", progress = FALSE))
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)
  nm <- names(raw)
  # make names unique but preserve originals where possible
  nm[nm == ""] <- paste0("unnamed_", seq_len(sum(nm == "")))
  nm <- make.unique(nm)
  names(raw) <- nm
  qtext <- as.character(unlist(raw[1, ]))
  drop <- 1
  if (nrow(raw) >= 2 && any(grepl("ImportId", unlist(raw[2, ]), fixed = TRUE))) drop <- c(1, 2)
  dat <- raw[-drop, , drop = FALSE]
  rownames(dat) <- NULL
  list(dat = dat, qtext = setNames(qtext, nm))
}

std_choice <- function(x) {
  x <- trimws(as.character(x))
  out <- rep(NA_integer_, length(x))
  out[grepl("(^|[^0-9])1([^0-9]|$)", x)] <- 1L
  out[grepl("(^|[^0-9])2([^0-9]|$)", x)] <- 2L
  idxA <- is.na(out) & grepl("(^|\\s)A(\\s|$)", x)
  idxB <- is.na(out) & grepl("(^|\\s)B(\\s|$)", x)
  out[idxA] <- 1L
  out[idxB] <- 2L
  # fallback: two distinct non-empty values, order them
  rem <- is.na(out) & !is.na(x) & x != ""
  if (any(rem)) {
    u <- sort(unique(x[!is.na(x) & x != ""]))
    if (length(u) == 2) out[rem] <- match(x[rem], u)
  }
  out[is.na(x) | x == ""] <- NA_integer_
  out
}

find_choice_cols <- function(dat, qtext, ntask) {
  nm <- names(dat)
  fcols <- grepl("^F-[0-9]+-", nm)
  cand <- c()
  for (j in which(!fcols)) {
    v <- dat[[j]]
    v <- v[!is.na(v) & trimws(v) != ""]
    if (length(v) < 0.3 * nrow(dat)) next
    u <- unique(trimws(v))
    if (length(u) != 2) next
    cand <- c(cand, j)
  }
  if (length(cand) == 0) return(integer(0))
  kw <- "(prefer|admit|settle|choose|choice|which of|which migrant|bevorzug|aufnehm|ansiedel|wählen|welche[nr]?|lieber|migrant)"
  qt <- qtext[nm[cand]]
  withkw <- cand[grepl(kw, qt, ignore.case = TRUE)]
  # exclude demographic-ish yes/no and gender columns
  looks_profile <- function(j) {
    u <- unique(trimws(dat[[j]][!is.na(dat[[j]]) & trimws(dat[[j]]) != ""]))
    all(grepl("1|2|\\bA\\b|\\bB\\b", u))
  }
  sel <- withkw[vapply(withkw, looks_profile, logical(1))]
  if (length(sel) < ntask) sel <- withkw
  if (length(sel) < ntask) {
    alt <- cand[vapply(cand, looks_profile, logical(1))]
    if (length(alt) >= ntask) sel <- alt
  }
  if (length(sel) > ntask) {
    # prefer a contiguous-ish block: take last ntask before the F- columns or first ntask
    sel <- sel[seq_len(ntask)]
  }
  sel
}

build_long <- function(path) {
  q <- read_qualtrics(path)
  dat <- q$dat
  nm <- names(dat)
  lvl_cols <- grep("^F-[0-9]+-[0-9]+-[0-9]+$", nm, value = TRUE)
  att_cols <- grep("^F-[0-9]+-[0-9]+$", nm, value = TRUE)
  parts <- do.call(rbind, strsplit(sub("^F-", "", lvl_cols), "-"))
  tasks <- sort(unique(as.integer(parts[, 1])))
  profs <- sort(unique(as.integer(parts[, 2])))
  attrs <- sort(unique(as.integer(parts[, 3])))
  ntask <- length(tasks)
  ch_cols <- find_choice_cols(dat, q$qtext, ntask)
  if (length(ch_cols) < ntask) stop("Could not identify choice columns in ", basename(path))
  dat$resp_id <- if ("ResponseId" %in% nm) dat$ResponseId else as.character(seq_len(nrow(dat)))
  out <- list()
  for (k in seq_along(tasks)) {
    t <- tasks[k]
    ch <- std_choice(dat[[ch_cols[k]]])
    for (p in profs) {
      d <- data.frame(resp = dat$resp_id, task = t, profile = p,
                      chosen = as.integer(ch == p), stringsAsFactors = FALSE)
      for (a in attrs) {
        an_col <- paste0("F-", t, "-", a)
        lv_col <- paste0("F-", t, "-", p, "-", a)
        anames <- if (an_col %in% nm) dat[[an_col]] else rep(paste0("attr", a), nrow(dat))
        lv <- if (lv_col %in% nm) dat[[lv_col]] else rep(NA_character_, nrow(dat))
        # store by attribute name (order may be randomized across respondents)
        tmp <- data.frame(row = seq_len(nrow(dat)), aname = trimws(anames), lv = trimws(lv),
                          stringsAsFactors = FALSE)
        d[[paste0("..a", a, "_name")]] <- tmp$aname
        d[[paste0("..a", a, "_lv")]] <- tmp$lv
      }
      out[[length(out) + 1]] <- d
    }
  }
  long <- bind_rows(out)
  long <- long[!is.na(long$chosen), , drop = FALSE]
  # reshape attributes to named columns
  all_names <- unique(unlist(lapply(attrs, function(a) long[[paste0("..a", a, "_name")]])))
  all_names <- all_names[!is.na(all_names) & all_names != ""]
  for (an in all_names) {
    v <- rep(NA_character_, nrow(long))
    for (a in attrs) {
      hit <- !is.na(long[[paste0("..a", a, "_name")]]) & long[[paste0("..a", a, "_name")]] == an
      v[hit] <- long[[paste0("..a", a, "_lv")]][hit]
    }
    long[[paste0("att_", make.names(an))]] <- v
  }
  long <- long[, !grepl("^\\.\\.a", names(long)), drop = FALSE]
  long
}

kw_reason <- "(drought|dürre|durre|trocken|flood|überschwemm|uberschwemm|hochwasser|flut|wildfire|waldbr|feuer|brand|persecut|verfolg|econom|wirtschaft|ökonom)"

estimate <- function(long) {
  att <- grep("^att_", names(long), value = TRUE)
  # identify reason attribute
  score <- sapply(att, function(a) {
    u <- unique(long[[a]])
    mean(grepl(kw_reason, u, ignore.case = TRUE))
  })
  reason_att <- att[which.max(score)]
  long <- long[complete.cases(long[, att, drop = FALSE]) & long[, att[1]] != "", , drop = FALSE]
  for (a in att) long[[a]] <- factor(long[[a]])
  lv <- levels(long[[reason_att]])
  econ <- lv[grepl("(econom|wirtschaft|ökonom|oekonom|opportunit|chancen|arbeit)", lv, ignore.case = TRUE)]
  if (length(econ) >= 1) long[[reason_att]] <- relevel(long[[reason_att]], ref = econ[1])
  names(long)[names(long) == reason_att] <- "reason"
  att2 <- c("reason", setdiff(att, reason_att))
  fml <- as.formula(paste("chosen ~", paste(att2, collapse = " + ")))
  m <- feols(fml, data = long, cluster = ~resp)
  cf <- coef(m)
  rn <- names(cf)[grepl("^reason", names(cf))]
  getc <- function(pat) {
    h <- rn[grepl(pat, rn, ignore.case = TRUE)]
    if (length(h) == 0) NA_real_ else unname(cf[h[1]])
  }
  list(
    drought = getc("(drought|dürre|durre|trocken)"),
    flooding = getc("(flood|überschwemm|uberschwemm|hochwasser|flut)"),
    wildfires = getc("(wildfire|waldbr|feuer|brand)"),
    persecution = getc("(persecut|verfolg)"),
    nresp = length(unique(long$resp)),
    nobs = nobs(m)
  )
}

res_us <- tryCatch(estimate(build_long(f_us)), error = function(e) { message("US error: ", conditionMessage(e)); NULL })
res_de <- tryCatch(estimate(build_long(f_de)), error = function(e) { message("DE error: ", conditionMessage(e)); NULL })

g <- function(r, k) if (is.null(r) || is.null(r[[k]])) NA else r[[k]]

cat(sprintf("RESULT:amce_drought_us=%s\n", format(g(res_us, "drought"), digits = 6)))
cat(sprintf("RESULT:amce_flooding_us=%s\n", format(g(res_us, "flooding"), digits = 6)))
cat(sprintf("RESULT:amce_wildfires_us=%s\n", format(g(res_us, "wildfires"), digits = 6)))
cat(sprintf("RESULT:amce_persecution_us=%s\n", format(g(res_us, "persecution"), digits = 6)))
cat(sprintf("RESULT:amce_drought_germany=%s\n", format(g(res_de, "drought"), digits = 6)))
cat(sprintf("RESULT:amce_flooding_germany=%s\n", format(g(res_de, "flooding"), digits = 6)))
cat(sprintf("RESULT:amce_wildfires_germany=%s\n", format(g(res_de, "wildfires"), digits = 6)))
cat(sprintf("RESULT:amce_persecution_germany=%s\n", format(g(res_de, "persecution"), digits = 6)))
cat(sprintf("RESULT:respondents_us=%s\n", g(res_us, "nresp")))
cat(sprintf("RESULT:respondents_germany=%s\n", g(res_de, "nresp")))
cat(sprintf("RESULT:choice_tasks_us=%s\n", g(res_us, "nobs")))
cat(sprintf("RESULT:choice_tasks_germany=%s\n", g(res_de, "nobs")))
