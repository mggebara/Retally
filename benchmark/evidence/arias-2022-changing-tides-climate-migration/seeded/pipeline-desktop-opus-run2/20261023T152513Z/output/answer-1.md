suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration"
f_us <- file.path(base_dir, "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv")
f_de <- file.path(base_dir, "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")
resp_cols <- c("force_choice", "Q184", "Q186", "Q188", "Q190", "Q192", "Q194", "Q196", "Q198")

gl <- function(pat, x) grepl(pat, x, ignore.case = TRUE, useBytes = TRUE)

# ---------------------------------------------------------------------------
# Re-implementation of cjoint::read.qualtrics(new.format = TRUE)
# ---------------------------------------------------------------------------
read_raw <- function(path, enc = "UTF-8") {
  raw <- readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()),
                         na = character(), progress = FALSE, name_repair = "minimal",
                         locale = readr::locale(encoding = enc))
  raw <- as.data.frame(raw, stringsAsFactors = FALSE, optional = TRUE)
  nm <- sub("^﻿", "", names(raw))
  nm <- gsub("^\"|\"$", "", nm)
  names(raw) <- nm
  raw
}

code_choice <- function(mat) {
  v <- trimws(as.vector(mat)); v[is.na(v)] <- ""
  nonempty <- v[v != ""]
  num <- suppressWarnings(as.numeric(gsub("[^0-9]", "", nonempty)))
  if (length(nonempty) > 0 && all(!is.na(num)) && all(num %in% c(1, 2))) {
    n2 <- suppressWarnings(as.numeric(gsub("[^0-9]", "", v)))
    out <- ifelse(v == "", NA, n2)
  } else {
    tab <- sort(table(nonempty), decreasing = TRUE)
    top <- names(tab)[1:min(2, length(tab))]
    tn <- suppressWarnings(as.numeric(gsub("[^0-9]", "", top)))
    top <- if (all(!is.na(tn))) top[order(tn)] else sort(top)
    out <- match(v, top)
  }
  matrix(out, nrow = nrow(mat))
}

classify_attr <- function(levs, aname) {
  has <- function(p) any(gl(p, levs))
  if (has("^(female|male|weiblich|m.{1,3}nnlich)$")) return("Gender")
  if (has("econom|wirtschaft")) return("Reason")
  if (has("unemploy|arbeitslos")) return("Occupation")
  if (has("ukrain")) return("Origin")
  if (has("muslim")) return("Religion")
  if (has("broken|gebrochen|fluent|flie")) return("Language")
  if (has("ptsd|ptbs|trauma|food|handicap|famil|behind")) return("Vulnerability")
  if (gl("gender|geschlecht", aname)) return("Gender")
  if (gl("reason|grund", aname)) return("Reason")
  if (gl("occupation|beruf", aname)) return("Occupation")
  if (gl("origin|herkunft", aname)) return("Origin")
  if (gl("religion", aname)) return("Religion")
  if (gl("language|sprach", aname)) return("Language")
  if (gl("vulner|verletz|schutz", aname)) return("Vulnerability")
  NA_character_
}

read_conjoint <- function(path, responses) {
  raw <- read_raw(path, "UTF-8")
  nm <- names(raw)
  lv_cols <- grep("^[A-Za-z]+-[0-9]+-[0-9]+-[0-9]+$", nm, value = TRUE)
  if (length(lv_cols) == 0) stop("No conjoint level columns found in ", path)
  # encoding check
  chk <- unlist(raw[, lv_cols[seq_len(min(length(lv_cols), 200))], drop = FALSE])
  if (any(!validUTF8(chk))) {
    raw <- read_raw(path, "latin1")
    nm <- names(raw)
  }
  idcol <- if ("ResponseId" %in% nm) "ResponseId" else nm[gl("responsei", nm)][1]
  ids <- raw[[idcol]]
  hdr <- ids %in% c("Response ID", "ResponseID") | grepl("ImportId", ids, fixed = TRUE)
  raw <- raw[!hdr, , drop = FALSE]
  nr <- nrow(raw)

  letter <- names(sort(table(sub("-.*$", "", lv_cols)), decreasing = TRUE))[1]
  a_cols <- grep(paste0("^", letter, "-1-[0-9]+$"), nm, value = TRUE)
  nattr <- max(as.integer(sub(".*-", "", a_cols)))

  ch <- code_choice(sapply(responses, function(cn) if (cn %in% names(raw)) raw[[cn]] else rep("", nr)))

  long <- list()
  for (k in seq_along(responses)) for (p in 1:2) for (j in seq_len(nattr)) {
    an <- raw[[sprintf("%s-%d-%d", letter, k, j)]]
    lv <- raw[[sprintf("%s-%d-%d-%d", letter, k, p, j)]]
    if (is.null(an) || is.null(lv)) next
    long[[length(long) + 1]] <- data.frame(r = seq_len(nr), task = k, profile = p,
                                           aname = trimws(an), lvl = trimws(lv),
                                           stringsAsFactors = FALSE)
  }
  long <- bind_rows(long)
  long <- long[!is.na(long$aname) & long$aname != "" & !is.na(long$lvl) & long$lvl != "", ]
  anames <- unique(long$aname)
  canon <- vapply(anames, function(a) classify_attr(unique(long$lvl[long$aname == a]), a), character(1))
  long$attr <- unname(canon[long$aname])
  long <- long[!is.na(long$attr), ]

  wide <- long %>%
    dplyr::select(r, task, profile, attr, lvl) %>%
    tidyr::pivot_wider(id_cols = c(r, task, profile), names_from = attr, values_from = lvl,
                       values_fn = function(x) x[1]) %>%
    as.data.frame(stringsAsFactors = FALSE)
  wide$selected <- ch[cbind(wide$r, wide$task)]
  wide$resp_id <- raw[[idcol]][wide$r]
  wide <- wide[order(wide$r, wide$task, wide$profile), ]
  rownames(wide) <- NULL
  wide
}

attrs <- c("Gender", "Language", "Occupation", "Origin", "Reason", "Religion", "Vulnerability")

pick_base <- function(levs, pat) {
  m <- levs[gl(pat, levs)]
  if (length(m)) m[1] else sort(levs)[1]
}

get_bases <- function(d) {
  pats <- list(Gender = "^(female|weiblich)$", Language = "^(none|keine)$",
               Occupation = "^(unemployed|arbeitslos)$", Origin = "another region|anderen teil",
               Reason = "econom|wirtschaft", Religion = "agnost|athe",
               Vulnerability = "^(none|keine)$")
  b <- list()
  for (a in attrs) b[[a]] <- pick_base(sort(unique(d[[a]])), pats[[a]])
  b
}

reason_key <- function(l) {
  if (gl("drought|d.{0,4}rre", l)) return("drought")
  if (gl("wildfire|waldbr|wald", l)) return("wildfires")
  if (gl("persecut|verfolg", l)) return("persecution")
  if (gl("flood|berschw|hochwasser|flut", l)) return("flooding")
  NA_character_
}

# ---------------------------------------------------------------------------
# AMCE estimation (LPM, respondent-clustered SEs). Attribute pairs with
# structural zeros (design restrictions) are modelled with full interaction
# cells and AMCEs averaged over supported levels, as in cjoint::amce.
# ---------------------------------------------------------------------------
estimate_amce <- function(d) {
  bases <- get_bases(d)
  grp <- setNames(seq_along(attrs), attrs)
  for (i in 1:(length(attrs) - 1)) for (j in (i + 1):length(attrs)) {
    tb <- table(d[[attrs[i]]], d[[attrs[j]]])
    ex <- outer(rowSums(tb), colSums(tb)) / sum(tb)
    if (any(tb == 0 & ex > 30)) {
      gi <- grp[attrs[i]]; gj <- grp[attrs[j]]
      grp[grp == gj] <- gi
      cat("Dependency detected:", attrs[i], "x", attrs[j], "\n")
    }
  }
  X <- list(); info <- list(); groups <- list()
  for (g in unique(grp)) {
    members <- names(grp)[grp == g]
    if (length(members) == 1) {
      a <- members
      for (l in setdiff(sort(unique(d[[a]])), bases[[a]])) {
        nm <- paste0("x", length(X) + 1)
        X[[nm]] <- as.numeric(d[[a]] == l)
        info[[nm]] <- list(type = "main", attr = a, level = l)
      }
    } else {
      cell <- do.call(paste, c(lapply(members, function(m) d[[m]]), sep = "||"))
      cells <- sort(unique(cell))
      refcell <- paste(unlist(bases[members]), collapse = "||")
      if (!refcell %in% cells) refcell <- cells[1]
      cellnm <- setNames(rep(NA_character_, length(cells)), cells)
      for (cc in setdiff(cells, refcell)) {
        nm <- paste0("x", length(X) + 1)
        X[[nm]] <- as.numeric(cell == cc)
        cellnm[cc] <- nm
      }
      groups[[length(groups) + 1]] <- list(members = members, cells = cells, cellnm = cellnm)
    }
  }
  dd <- as.data.frame(X)
  dd$selected <- d$selected
  dd$resp_id <- d$resp_id
  fml <- as.formula(paste("selected ~", paste(names(X), collapse = " + ")))
  fit <- fixest::feols(fml, data = dd, cluster = ~resp_id)
  b <- coef(fit); V <- vcov(fit)

  amce <- function(a, l) {
    w <- setNames(rep(0, length(b)), names(b))
    gidx <- which(vapply(groups, function(g) a %in% g$members, logical(1)))
    if (length(gidx) == 0) {
      nm <- names(info)[vapply(info, function(z) z$attr == a && z$level == l, logical(1))]
      if (length(nm) == 0 || !(nm %in% names(b))) return(c(NA, NA))
      w[nm] <- 1
    } else {
      g <- groups[[gidx]]
      parts <- do.call(rbind, strsplit(g$cells, "||", fixed = TRUE))
      colnames(parts) <- g$members
      others <- setdiff(g$members, a)
      okey <- apply(parts[, others, drop = FALSE], 1, paste, collapse = "||")
      combos <- unique(okey)
      sup <- 0
      for (cmb in combos) {
        cl <- g$cells[parts[, a] == l & okey == cmb]
        cb <- g$cells[parts[, a] == bases[[a]] & okey == cmb]
        if (length(cl) == 1 && length(cb) == 1) {
          sup <- sup + 1
          for (pair in list(list(cl, 1), list(cb, -1))) {
            nm <- g$cellnm[pair[[1]]]
            if (!is.na(nm) && nm %in% names(b)) w[nm] <- w[nm] + pair[[2]]
          }
        }
      }
      if (sup == 0) return(c(NA, NA))
      w <- w / sup
    }
    est <- sum(w * b)
    se <- sqrt(as.numeric(t(w) %*% V %*% w))
    c(est, se)
  }

  rl <- setdiff(sort(unique(d$Reason)), bases$Reason)
  keys <- vapply(rl, reason_key, character(1))
  if (sum(is.na(keys)) == 1 && !("flooding" %in% keys)) keys[is.na(keys)] <- "flooding"
  res <- list()
  for (i in seq_along(rl)) {
    if (is.na(keys[i])) next
    res[[keys[i]]] <- amce("Reason", rl[i])
  }
  cat("Baselines:\n"); print(unlist(bases))
  cat("Reason levels:\n"); print(setNames(keys, rl))
  res
}

emit <- function(name, val) {
  if (length(val) == 1 && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}

out <- list()

# ------------------------------- US ---------------------------------------
tryCatch({
  us <- read_conjoint(f_us, resp_cols)
  us <- us[!is.na(us$selected), ]
  us <- us[is.na(us$Occupation) | us$Occupation != "Unemployer", ]
  us <- us[5:nrow(us), ]
  us <- us[complete.cases(us[, c(attrs, "selected")]), ]
  cat("US profiles:", nrow(us), " respondents:", length(unique(us$resp_id)), "\n")
  r_us <- estimate_amce(us)
  for (k in names(r_us)) {
    out[[paste0("amce_", k, "_us")]] <- r_us[[k]][1]
    out[[paste0("se_amce_", k, "_us")]] <- r_us[[k]][2]
  }
  out[["respondents_us"]] <- length(unique(us$resp_id))
  out[["choice_tasks_us"]] <- nrow(us)
}, error = function(e) cat("US error:", conditionMessage(e), "\n"))

# ----------------------------- Germany ------------------------------------
tryCatch({
  de <- read_conjoint(f_de, resp_cols)
  de <- de[!is.na(de$selected), ]
  de <- de[complete.cases(de[, c(attrs, "selected")]), ]
  cat("Germany profiles:", nrow(de), " respondents:", length(unique(de$resp_id)), "\n")
  r_de <- estimate_amce(de)
  for (k in names(r_de)) {
    out[[paste0("amce_", k, "_germany")]] <- r_de[[k]][1]
    out[[paste0("se_amce_", k, "_germany")]] <- r_de[[k]][2]
  }
  out[["respondents_germany"]] <- length(unique(de$resp_id))
  out[["choice_tasks_germany"]] <- nrow(de)
}, error = function(e) cat("Germany error:", conditionMessage(e), "\n"))

for (nm in names(out)) emit(nm, out[[nm]])
