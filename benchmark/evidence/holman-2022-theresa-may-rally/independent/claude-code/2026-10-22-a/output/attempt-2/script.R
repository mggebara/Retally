suppressMessages({library(haven); library(dplyr)})
M <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-10-22-a/mount/holman_2022_theresa_may_rally"
# ---- global approval: sample-size checks only
g <- as.data.frame(zap_labels(read_dta(file.path(M, "global_approval.dta"))))
g <- g[order(g$country_code, g$qtr), ]
g$lag_k16 <- ave(g$kill_16, g$country_code, FUN = function(x) c(NA, head(x, -1)))
base <- c("lag_approval", "female_pres", "growth", "log_inflation", "execrlc", "election_qtr")
cat("complete, base+kill_16:", sum(complete.cases(g[, c(base, "kill_16")])), "\n")
cat("complete, base+lag kill_16:", sum(complete.cases(g[, c(base, "lag_k16")])), "\n")
cat("complete, base minus execrlc:", sum(complete.cases(g[, setdiff(c(base, "kill_16"), "execrlc")])), "\n")
cat("countries in complete:", length(unique(g$country_code[complete.cases(g[, c(base, "kill_16")])])), "\n")
cat("N countries total:", length(unique(g$country_code)), " countries by name:", length(unique(g$country)), "\n")
cat("kill_16==1 quarters:", sum(g$kill_16 == 1), " with female:", sum(g$kill_16 == 1 & g$female_pres == 1, na.rm = TRUE), "\n")
cat("kill_14==1 quarters:", sum(g$kill_14 == 1), " with female:", sum(g$kill_14 == 1 & g$female_pres == 1, na.rm = TRUE), "\n")
cat("qtr gaps within country:", sum(ave(g$qtr, g$country_code, FUN = function(x) c(1, diff(x))) != 1), "\n")
print(head(g[g$kill_16 == 1 & g$female_pres %in% 1, c("country", "qtr", "kill_16", "kill_14", "manchester", "rally_kill", "lag_approval")], 20))
# ---- DiD panel: sample-size checks only
d <- as.data.frame(zap_labels(read_dta(file.path(M, "did_data.dta"))))
nn <- function(v) tapply(!is.na(d[[v]]), d$wave, sum)
print(rbind(likeMay = nn("likeMayW"), bestPM = nn("bestPMW"), income = nn("income"), ideology = nn("ideology"),
            ideology2 = nn("ideology2"), wt = nn("wt_new_W12"), start = nn("starttimeW"), gender = nn("gender")))
# within-id variation of controls
for (v in c("white", "gender", "labour", "party_other", "income", "ideology", "ideology2", "treatment1", "conservative")) {
  s <- tapply(d[[v]], d$id, function(x) length(unique(na.omit(x))) > 1)
  cat(v, "varies within id for", sum(s, na.rm = TRUE), "ids\n")
}
ctrl_sets <- list(
  c1 = c("white", "gender", "labour", "party_other", "income", "ideology"),
  c2 = c("white", "gender", "labour", "party_other", "income", "ideology2"),
  c3 = c("white", "gender", "labour", "party_other", "ideology2"),
  c4 = c("white", "gender", "labour", "party_other"))
wsets <- list(w9_16 = 9:16, w9_14 = 9:14, w10_14 = 10:14, w10_16 = 10:16, w9_13 = 9:13, w11_13 = 11:13, w10_13=10:13, w11_16=11:16, w11_14=11:14)
for (y in c("likeMayW", "bestPMW")) for (cs in names(ctrl_sets)) {
  ok <- complete.cases(d[, c(y, ctrl_sets[[cs]], "treatment1", "time")])
  cat(y, cs, ":", paste(names(wsets), sapply(wsets, function(w) sum(ok & d$wave %in% w)), collapse = "  "), " all:", sum(ok), "\n")
}
