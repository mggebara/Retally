suppressMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)
nswitch <- function(x) sum(diff(x) != 0)
options(width = 250)
coefs <- function(d) {
  pos <- function(code) sapply(d$Condition, function(s) regexpr(code, s, fixed = TRUE)[1])
  y <- c(d$AnomPts, d$RecogPts, d$EarnPts)
  pr <- rep(c(0,1,0), each = nrow(d)); fi <- rep(c(0,0,1), each = nrow(d))
  o <- c(pos("A"), pos("R"), pos("E"))
  X <- cbind(1, pr, fi, o == 2, o == 3)
  b <- lm.fit(X, y)$coefficients
  c(mean = mean(d$AnomPts), pr = b[2], fi = b[3])
}
for (f in c("bu_qm222_survey_data.csv","berkeley_survey_data.csv")) {
  d <- suppressWarnings(read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 5000))
  d <- d[is.na(d$attention_check), ]
  P <- as.matrix(d[paste0("preference_", lv)])
  inc <- apply(P, 1, function(x) all(diff(x) >= 0)); ns <- apply(P, 1, nswitch)
  cand <- which(!inc & ns <= 2); sure <- which(!inc & ns > 2)
  k <- if (grepl("bu", f)) 2 - length(sure) else 11 - length(sure)
  cat("\n=====", f, " candidates:", length(cand), " sure:", length(sure), " choose:", k, "\n")
  for (i in cand) cat(sprintf("idx=%3d sw=%d anon=%4d rec=%4d earn=%4d P=%s\n", i, ns[i], d$AnomPts[i], d$RecogPts[i], d$EarnPts[i], paste(P[i,], collapse="")))
  cb <- combn(cand, k)
  res <- t(apply(cb, 2, function(ex) coefs(d[-c(sure, ex), ])))
  target <- if (grepl("bu", f)) c(815.9, 103.61, 118.33) else c(989.8, 134.41, 177.76)
  dist <- abs(res[,1] - target[1]) / 1 + abs(res[,2] - target[2]) + abs(res[,3] - target[3])
  o <- order(dist)[1:min(8, length(dist))]
  for (j in o) cat(sprintf("excl=%s  mean=%.2f pr=%.2f fi=%.2f dist=%.3f\n", paste(cb[, j], collapse=","), res[j,1], res[j,2], res[j,3], dist[j]))
}
