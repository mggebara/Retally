suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(berkeley="berkeley_survey_data.csv", bu222="bu_qm222_survey_data.csv", prolific="prolific_survey_data.csv")
iv <- seq(0, 1700, 100)
inc <- function(x) length(x) < 2 || all(diff(x) >= 0)
dec <- function(x) length(x) < 2 || all(diff(x) <= 0)
peak <- function(x) length(x) < 2 || any(sapply(which(x == max(x)), function(k) all(diff(x[1:k]) >= 0) && all(diff(x[k:length(x)]) <= 0)))
dip <- function(x) length(x) < 2 || any(sapply(which(x == min(x)), function(k) all(diff(x[1:k]) <= 0) && all(diff(x[k:length(x)]) >= 0)))
nzs <- function(x) { s <- sign(x); s[s != 0] }
dat <- list()
for (nm in names(files)) {
  d <- read_csv(file.path(base, files[nm]), show_col_types = FALSE, guess_max = 5000)
  d <- d[is.na(d$attention_check), ]
  P <- as.matrix(d[, paste0("preference_", iv)])
  R <- as.matrix(d[, paste0("pref_rec_", iv, "_1")]); A <- as.matrix(d[, paste0("pref_anom_", iv, "_1")])
  W <- ifelse(P == 1, R, -A)
  dat[[nm]] <- list(P = P, W = W)
}
reps <- list(bin = function(P, W, i, rr) P[i, rr], sign = function(P, W, i, rr) sign(W[i, rr]),
             nzsign = function(P, W, i, rr) nzs(W[i, rr]), lev = function(P, W, i, rr) W[i, rr])
shapes <- list(inc = inc, dec = dec, peak = peak, dip = dip)
res <- list()
for (k in c(18, 17)) for (mr in names(reps)) for (cr in names(reps)) for (ext in list("dec", "peak", c("dec", "peak"), c("dec","peak","dip"), "none")) {
  key <- sprintf("k=%d mono=%s coh=%s ext=%s", k, mr, cr, paste(ext, collapse = "+"))
  out <- c()
  for (nm in names(dat)) {
    P <- dat[[nm]]$P; W <- dat[[nm]]$W; rr <- 1:k
    mono <- sapply(seq_len(nrow(P)), function(i) inc(reps[[mr]](P, W, i, rr)))
    cohx <- sapply(seq_len(nrow(P)), function(i) { x <- reps[[cr]](P, W, i, rr)
      if (identical(ext, "none")) FALSE else any(sapply(ext, function(s) shapes[[s]](x))) })
    coh <- mono | cohx
    out <- c(out, sum(!coh), sum(coh & !mono))
  }
  res[[key]] <- out
}
tab <- do.call(rbind, res)
colnames(tab) <- c("brk_incoh", "brk_cohNM", "bu_incoh", "bu_cohNM", "pro_incoh", "pro_cohNM")
tab <- as.data.frame(tab)
tab$score <- abs(tab$brk_incoh - 11) + abs(tab$bu_incoh - 2) + abs(tab$pro_incoh - 40) + abs(tab$brk_cohNM - 7) + abs(tab$bu_cohNM - 2) + abs(tab$pro_cohNM - 10)
tab <- tab[order(tab$score), ]
options(width = 200)
print(head(tab, 40))
