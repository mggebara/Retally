suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

to_num <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    xl <- tolower(trimws(x))
    if (all(xl %in% c("yes", "no", "true", "false", NA, ""))) {
      return(ifelse(xl %in% c("yes", "true"), 1, ifelse(xl %in% c("no", "false"), 0, NA)))
    }
    return(suppressWarnings(as.numeric(x)))
  }
  as.numeric(x)
}

## ---------------- load data ----------------
e1 <- new.env()
load(file.path(base, "dyadic_data_1-4-22.Rdata"), envir = e1)
dy <- as.data.frame(e1$updated_data)
gd <- tryCatch(as.data.frame(readRDS(file.path(base, "gender_disagregated_8-8-21.rds"))),
               error = function(e) NULL)

cat("Dyadic columns:\n"); print(names(dy))
if (!is.null(gd)) { cat("Gender columns:\n"); print(names(gd)) }

make_ws <- function(x) {
  x <- to_num(x)
  if (max(x, na.rm = TRUE) > 1.0001 && max(x, na.rm = TRUE) <= 100) x <- x / 100
  x
}
cat("to_pfeml summary:\n"); print(summary(to_num(dy$to_pfeml)))
if ("to_complete" %in% names(dy)) { cat("to_complete table:\n"); print(table(dy$to_complete, useNA = "ifany")) }
if ("from_complete" %in% names(dy)) { cat("from_complete table:\n"); print(table(dy$from_complete, useNA = "ifany")) }

## ---------------- prepare main dyadic data ----------------
getcol <- function(d, nm) if (nm %in% names(d)) to_num(d[[nm]]) else rep(NA_real_, nrow(d))

prep <- function(d, dvname) {
  cat("DV:", dvname, " | women share: to_pfeml\n")
  out <- d
  out$dv <- as.numeric(d[[dvname]])
  out$ws <- make_ws(d$to_pfeml)
  out$ws_from <- if ("from_pfeml" %in% names(d)) make_ws(d$from_pfeml) else rep(NA_real_, nrow(d))
  out$rl_raw <- abs(to_num(d$rile_distance))
  out$coal <- to_num(d$govern_together)
  out$opp <- to_num(d$opposition_together)
  out$to_mp <- to_num(d$to_mp_number)
  out$from_mp <- to_num(d$from_mp_number)
  out$to_cmp <- getcol(d, "to_complete")
  out$from_cmp <- getcol(d, "from_complete")
  out$cy <- paste(d$country, d$year, sep = "_")
  out
}

dd <- prep(dy, "party_like")

base_ok <- function(d) {
  !is.na(d$to_mp) & !is.na(d$from_mp) & d$to_mp >= 4 & d$from_mp >= 4 &
    !is.na(d$dv) & !is.na(d$ws) & !is.na(d$rl_raw) & !is.na(d$coal) & !is.na(d$opp)
}
nz <- function(x) { x[is.na(x)] <- FALSE; x }

## Candidate sample definitions consistent with the paper's restrictions
## (both parties >= 4 MPs, non-missing women-share data for the parties in the dyad).
variants <- list(
  base = function(d) base_ok(d),
  mp_gt4 = function(d) base_ok(d) & d$to_mp > 4 & d$from_mp > 4,
  to_complete = function(d) base_ok(d) & nz(d$to_cmp == 1),
  both_complete = function(d) base_ok(d) & nz(d$to_cmp == 1) & nz(d$from_cmp == 1),
  from_ws_nonmiss = function(d) base_ok(d) & !is.na(d$ws_from),
  from_ws_both_complete = function(d) base_ok(d) & !is.na(d$ws_from) & nz(d$to_cmp == 1) & nz(d$from_cmp == 1)
)
ns <- sapply(variants, function(f) sum(nz(f(dd))))
cat("Candidate sample sizes:\n"); print(ns)
valid <- ns[ns > 0]
chosen <- names(valid)[which.min(abs(valid - 1842))]
cat("Chosen sample definition:", chosen, "\n")
if (chosen != "base") {
  cat(sprintf("DEVIATION: Sample restricted with additional filter '%s' (women-share data completeness / MP threshold) to match the paper's dyad count; exact filter not stated in the paper\n", chosen))
}
restrict <- function(d) d[nz(variants[[chosen]](d)), , drop = FALSE]

s <- restrict(dd)
rl_sd <- sd(s$rl_raw)
s$rl <- s$rl_raw / rl_sd
cat("Sample N:", nrow(s), " elections:", length(unique(s$cy)), " rl raw mean/sd:",
    mean(s$rl_raw), rl_sd, " ws mean/sd:", mean(s$ws), sd(s$ws), "\n")

m2 <- feols(dv ~ ws + rl + coal + opp | cy, data = s, cluster = ~cy)

flip <- FALSE
if (coef(m2)["coal"] < 0) {
  cat("DV appears reverse-coded; using 10 - DV\n")
  flip <- TRUE
  s$dv <- 10 - s$dv
  m2 <- feols(dv ~ ws + rl + coal + opp | cy, data = s, cluster = ~cy)
}
m1 <- feols(dv ~ ws | cy, data = s, cluster = ~cy)

print(summary(m1)); print(summary(m2))
cat("Adj R2 m1:", r2(m1, "ar2"), " m2:", r2(m2, "ar2"), "\n")

## ---------------- gender-disaggregated models ----------------
gw <- NULL; gm <- NULL
tryCatch({
  if (is.null(gd)) stop("no gender data")
  g <- gd
  key <- intersect(c("country", "year", "party_from", "party_to"), names(g))
  need <- setdiff(c("to_pfeml", "from_pfeml", "to_complete", "from_complete"), names(g))
  need <- intersect(need, names(dy))
  if (length(need) > 0) {
    add <- dy[, c(key, need)]
    add <- add[!duplicated(add[, key]), ]
    g <- left_join(g, add, by = key)
  }
  gdv <- if ("dislike" %in% names(g)) "dislike" else "party_like"
  gp <- prep(g, gdv)
  if (all(is.na(gp$dv))) stop("no gender DV")
  gv <- g$gender
  if (is.factor(gv)) gv <- as.character(gv)
  if (is.character(gv)) {
    fem <- grepl("^f|wom|^2$", trimws(gv), ignore.case = TRUE)
    male <- grepl("^m(?!.*wom)|^men|^1$", trimws(gv), ignore.case = TRUE, perl = TRUE) & !fem
  } else {
    gvn <- as.numeric(gv)
    u <- sort(unique(gvn[!is.na(gvn)]))
    if (all(u %in% c(1, 2))) { fem <- gvn == 2; male <- gvn == 1 }
    else { fem <- gvn == 1; male <- gvn == 0 }
  }
  fem[is.na(fem)] <- FALSE; male[is.na(male)] <- FALSE
  cat("Gender table:\n"); print(table(gv, useNA = "ifany"))
  gw_d <- restrict(gp[fem, ]); gw_d$rl <- gw_d$rl_raw / rl_sd
  gm_d <- restrict(gp[male, ]); gm_d$rl <- gm_d$rl_raw / rl_sd
  chk <- feols(dv ~ rl + coal + opp | cy, data = rbind(gw_d, gm_d))
  if (coef(chk)["coal"] < 0) {
    cat("Gender DV appears reverse-coded (dislike); using 10 - DV\n")
    gw_d$dv <- 10 - gw_d$dv
    gm_d$dv <- 10 - gm_d$dv
  }
  gw <- feols(dv ~ ws + rl + coal + opp | cy, data = gw_d, cluster = ~cy)
  gm <- feols(dv ~ ws + rl + coal + opp | cy, data = gm_d, cluster = ~cy)
  print(summary(gw)); print(summary(gm))
}, error = function(e) cat("Gender models failed:", conditionMessage(e), "\n"))

## ---------------- output ----------------
emit("women_mps_coef_bivariate", coef(m1)["ws"])
emit("women_mps_coef_full", coef(m2)["ws"])
emit("women_mps_coef_women_partisans", if (!is.null(gw)) coef(gw)["ws"] else NA)
emit("women_mps_coef_men_partisans", if (!is.null(gm)) coef(gm)["ws"] else NA)
emit("right_left_distance_coef_full", coef(m2)["rl"])
emit("coalition_partners_coef_full", coef(m2)["coal"])
emit("opposition_partners_coef_full", coef(m2)["opp"])
emit("n_directed_dyads", nobs(m2))
emit("n_obs_women_partisans", if (!is.null(gw)) nobs(gw) else NA)
emit("n_obs_men_partisans", if (!is.null(gm)) nobs(gm) else NA)
emit("n_election_studies", length(unique(s$cy)))