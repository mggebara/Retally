suppressPackageStartupMessages({
  library(readr)
  library(data.table)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
files <- list(
  us = "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv",
  germany = "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv"
)

fix_enc <- function(x) {
  x <- as.character(x)
  bad <- !is.na(x) & !validUTF8(x)
  if (any(bad)) x[bad] <- iconv(x[bad], "latin1", "UTF-8")
  x
}

safe_lower <- function(x) {
  x <- fix_enc(x)
  out <- tryCatch(tolower(x), error = function(e) x)
  out[is.na(out)] <- ""
  out
}

read_qualtrics <- function(path) {
  raw <- readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()),
                         na = character(), progress = FALSE, name_repair = "minimal")
  names(raw) <- make.unique(names(raw))
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)
  nm <- names(raw)
  qtext <- nm
  rid_col <- which(nm == "ResponseId")[1]
  if (is.na(rid_col)) rid_col <- grep("ResponseI[dD]", nm)[1]
  first_is_hdr <- TRUE
  if (!is.na(rid_col) && any(grepl("^R_", raw[[rid_col]]))) {
    first_is_hdr <- !grepl("^R_", raw[[rid_col]][1])
  }
  drop <- integer(0)
  if (first_is_hdr && nrow(raw) >= 1) {
    r1 <- fix_enc(as.character(unlist(raw[1, ])))
    qtext <- r1
    drop <- 1L
    if (nrow(raw) >= 2) {
      r2 <- as.character(unlist(raw[2, ]))
      if (any(grepl("ImportId", r2, fixed = TRUE)) ||
          (!is.na(rid_col) && any(grepl("^R_", raw[[rid_col]])) && !grepl("^R_", raw[[rid_col]][2]))) {
        drop <- c(1L, 2L)
      }
    }
  }
  qtext[is.na(qtext) | qtext == ""] <- nm[is.na(qtext) | qtext == ""]
  dat <- raw[setdiff(seq_len(nrow(raw)), drop), , drop = FALSE]
  rownames(dat) <- NULL
  list(dat = dat, qtext = qtext)
}

is_pair <- function(u) {
  if (length(u) != 2) return(FALSE)
  nu <- suppressWarnings(as.numeric(u))
  if (all(!is.na(nu))) return(TRUE)
  s <- sort(u)
  (sub("1", "#", s[1], fixed = TRUE) == sub("2", "#", s[2], fixed = TRUE)) ||
    (sub("A", "#", s[1], fixed = TRUE) == sub("B", "#", s[2], fixed = TRUE))
}

map_choice <- function(v) {
  u <- unique(v[!is.na(v) & v != ""])
  if (length(u) != 2) return(NULL)
  nu <- suppressWarnings(as.numeric(u))
  if (all(!is.na(nu))) s <- u[order(nu)] else s <- sort(u)
  out <- rep(NA_integer_, length(v))
  out[!is.na(v) & v == s[1]] <- 1L
  out[!is.na(v) & v == s[2]] <- 2L
  out
}

code_reason <- function(x) {
  lx <- safe_lower(x)
  out <- rep("econ", length(x))
  out[grepl("drought|d.{1,2}rre|trockenheit", lx)] <- "drought"
  out[grepl("flood|berschwemm|hochwasser|flut", lx)] <- "flooding"
  out[grepl("wildfire|wild fire|waldbr|buschbr|brand|feuer|fire", lx)] <- "wildfires"
  out[grepl("persecution|verfolg", lx)] <- "persecution"
  out[is.na(x) | x == ""] <- NA
  out
}

analyze <- function(file) {
  rq <- read_qualtrics(file.path(base_dir, file))
  dat <- rq$dat
  qtext <- rq$qtext
  nm <- names(dat)
  n <- nrow(dat)

  lev_re <- "^F[-_]([0-9]+)[-_]([0-9]+)[-_]([0-9]+)$"
  nam_re <- "^F[-_]([0-9]+)[-_]([0-9]+)$"
  lc <- grep(lev_re, nm, value = TRUE)
  if (length(lc) == 0) stop("No conjoint F- columns found")
  lt <- as.integer(sub(lev_re, "\\1", lc))
  lp <- as.integer(sub(lev_re, "\\2", lc))
  lk <- as.integer(sub(lev_re, "\\3", lc))
  ncs <- grep(nam_re, nm, value = TRUE)
  nt <- as.integer(sub(nam_re, "\\1", ncs))
  nk <- as.integer(sub(nam_re, "\\2", ncs))
  keep <- lp %in% c(1L, 2L)
  lc <- lc[keep]; lt <- lt[keep]; lp <- lp[keep]; lk <- lk[keep]
  ntask <- max(lt)

  pieces <- vector("list", length(lc))
  for (i in seq_along(lc)) {
    nmcol <- ncs[nt == lt[i] & nk == lk[i]]
    an <- if (length(nmcol)) dat[[nmcol[1]]] else rep(paste0("Attr", lk[i]), n)
    pieces[[i]] <- data.table(id = seq_len(n), task = lt[i], prof = lp[i],
                              attr = trimws(fix_enc(an)), lev = trimws(fix_enc(dat[[lc[i]]])))
  }
  L <- rbindlist(pieces)
  L <- L[!is.na(attr) & attr != "" & !is.na(lev) & lev != ""]
  W <- dcast(L, id + task + prof ~ attr, value.var = "lev",
             fun.aggregate = function(z) z[1], fill = NA)
  acols <- setdiff(names(W), c("id", "task", "prof"))
  cover <- sapply(acols, function(a) mean(!is.na(W[[a]])))
  acols <- acols[cover > 0.5]
  W <- W[complete.cases(W[, c("id", "task", "prof", acols), with = FALSE])]

  # identify reason attribute
  score <- sapply(acols, function(a) {
    lv <- safe_lower(unique(W[[a]]))
    sum(grepl("drought|d.{1,2}rre|trockenheit|flood|berschwemm|hochwasser|wildfire|waldbr|persecution|verfolg", lv))
  })
  if (max(score) > 0) {
    reason_attr <- acols[which.max(score)]
  } else {
    reason_attr <- acols[grepl("reason|grund|migration", safe_lower(acols))][1]
  }
  W[, reason := factor(code_reason(get(reason_attr)),
                       levels = c("econ", "drought", "flooding", "wildfires", "persecution"))]
  cat("Reason attribute:", reason_attr, "\n")
  print(table(W[[reason_attr]], W$reason))
  others <- setdiff(acols, reason_attr)
  onames <- paste0("att", seq_along(others))
  for (j in seq_along(others)) W[, (onames[j]) := factor(get(others[j]))]
  cat("Other attributes:", paste(others, collapse = " | "), "\n")

  # design matrix once
  fml_rhs <- paste(c("reason", onames), collapse = " + ")
  X <- model.matrix(as.formula(paste("~", fml_rhs)), data = W)

  # candidate choice columns
  meta_re <- "^(StartDate|EndDate|Status|IPAddress|Progress|Duration|Finished|RecordedDate|ResponseId|Recipient|ExternalReference|Location|DistributionChannel|UserLanguage)"
  fset <- grep("^F[-_][0-9]+[-_][0-9]+([-_][0-9]+)?$", nm)
  cand <- c()
  for (j in seq_along(nm)) {
    if (j %in% fset) next
    if (grepl(meta_re, nm[j])) next
    v <- dat[[j]]
    v <- v[!is.na(v) & v != ""]
    if (length(v) < 0.2 * n) next
    if (is_pair(unique(v))) cand <- c(cand, j)
  }
  sets <- list()
  if (length(cand) >= ntask) {
    normt <- safe_lower(gsub("[0-9]+", "", qtext[cand]))
    normt <- gsub("\\s+", " ", trimws(normt))
    for (g in unique(normt)) {
      cols <- cand[normt == g]
      if (length(cols) >= ntask) {
        nchunk <- floor(length(cols) / ntask)
        for (h in seq_len(nchunk)) sets[[length(sets) + 1]] <- cols[((h - 1) * ntask + 1):(h * ntask)]
      }
    }
    for (s in 1:(length(cand) - ntask + 1)) sets[[length(sets) + 1]] <- cand[s:(s + ntask - 1)]
    kw <- grepl("migrant|prefer|bevorz|choose|w.{1,2}hlen|ansied|settle|aufnehm|profil|person",
                safe_lower(qtext[cand]))
    if (sum(kw) >= ntask) sets[[length(sets) + 1]] <- cand[kw][1:ntask]
  }
  sets <- unique(sets)
  if (length(sets) == 0) stop("No candidate choice columns found")

  best <- NULL; best_r2 <- -Inf
  for (S in sets) {
    M <- sapply(S, function(c) dat[[c]])
    if (is.null(dim(M))) next
    pooled <- as.vector(M)
    mv <- map_choice(pooled)
    if (is.null(mv)) next
    Mm <- matrix(mv, nrow = n)
    cv <- Mm[cbind(W$id, W$task)]
    ok <- !is.na(cv)
    if (sum(ok) < 100) next
    y <- as.numeric(cv[ok] == W$prof[ok])
    fit <- lm.fit(X[ok, , drop = FALSE], y)
    r2 <- 1 - sum(fit$residuals^2) / sum((y - mean(y))^2)
    if (is.finite(r2) && r2 > best_r2) { best_r2 <- r2; best <- S }
  }
  if (is.null(best)) stop("Could not identify choice columns")
  cat("Choice columns:", paste(nm[best], collapse = ", "), " R2 =", best_r2, "\n")

  M <- sapply(best, function(c) dat[[c]])
  Mm <- matrix(map_choice(as.vector(M)), nrow = n)
  W[, cv := Mm[cbind(id, task)]]
  D <- W[!is.na(cv)]
  D[, chosen := as.numeric(cv == prof)]

  fml <- as.formula(paste("chosen ~", fml_rhs))
  m <- feols(fml, data = D, cluster = ~id)
  print(summary(m))
  list(model = m, nobs = nobs(m), nresp = length(unique(D$id)))
}

res <- list()
for (cn in names(files)) {
  res[[cn]] <- tryCatch(analyze(files[[cn]]), error = function(e) {
    cat("Error for", cn, ":", conditionMessage(e), "\n"); NULL
  })
}

out <- character(0)
for (cn in names(res)) {
  r <- res[[cn]]
  if (is.null(r)) next
  cf <- coef(r$model)
  se <- sqrt(diag(vcov(r$model)))
  for (lv in c("drought", "flooding", "wildfires", "persecution")) {
    v <- paste0("reason", lv)
    if (v %in% names(cf)) {
      out <- c(out, sprintf("RESULT:amce_%s_%s=%.6f", lv, cn, cf[v]))
      out <- c(out, sprintf("RESULT:amce_%s_%s_se=%.6f", lv, cn, se[v]))
    }
  }
  out <- c(out, sprintf("RESULT:respondents_%s=%d", cn, as.integer(r$nresp)))
  out <- c(out, sprintf("RESULT:choice_tasks_%s=%d", cn, as.integer(r$nobs)))
}
cat(paste0(out, "\n"), sep = "")
