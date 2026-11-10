suppressMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)
options(width = 250)
d <- suppressWarnings(read_csv(file.path(base, "bu_qm222_survey_data.csv"), show_col_types = FALSE, guess_max = 5000))
d <- d[is.na(d$attention_check), ]
pos <- function(code) sapply(d$Condition, function(s) regexpr(code, s, fixed = TRUE)[1])
n <- nrow(d)
y <- c(d$AnomPts, d$RecogPts, d$EarnPts)
o <- c(pos("A"), pos("R"), pos("E"))
X <- cbind(1, rep(c(0,1,0), each = n), rep(c(0,0,1), each = n), o == 2, o == 3)
pid <- rep(seq_len(n), 3)
pr <- matrix(NA, 0, 6)
for (i in 1:(n-1)) for (j in (i+1):n) {
  keep <- !(pid %in% c(i, j))
  b <- lm.fit(X[keep, ], y[keep])$coefficients
  pr <- rbind(pr, c(i, j, mean(d$AnomPts[-c(i, j)]), b[2], b[3], 0))
}
pr[,6] <- abs(pr[,3] - 815.9) + abs(pr[,4] - 103.61) + abs(pr[,5] - 118.33)
pr <- pr[order(pr[,6]), ]
P <- as.matrix(d[paste0("preference_", lv)])
R1 <- as.matrix(d[paste0("pref_rec_", lv, "_1")]); A1 <- as.matrix(d[paste0("pref_anom_", lv, "_1")])
W <- ifelse(P == 1, R1, -A1)
for (r in 1:6) {
  cat(sprintf("excl %d,%d mean=%.2f pr=%.2f fi=%.2f dist=%.3f\n", pr[r,1], pr[r,2], pr[r,3], pr[r,4], pr[r,5], pr[r,6]))
  for (i in pr[r,1:2]) cat(sprintf("   idx=%d P=%s W=%s | anon=%d rec=%d earn=%d grp=%s\n", i, paste(P[i,], collapse=""), paste(W[i,], collapse=" "), d$AnomPts[i], d$RecogPts[i], d$EarnPts[i], d$recog_group_assign[i]))
}
