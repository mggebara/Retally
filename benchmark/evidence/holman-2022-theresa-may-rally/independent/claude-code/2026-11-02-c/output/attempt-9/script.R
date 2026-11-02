suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-02-c/mount/holman_2022_theresa_may_rally"
d <- read_dta(file.path(D, "did_data.dta"),
  col_select = c("id","wave","likeMayW","bestPMW","treatment1","treatment2","post_attack","time","white","gender","labour","party_other","income","ideology","ideology2","ideo3","conservative")) %>% zap_labels()
cat("treatment2 x time x treatment1\n"); print(with(d[d$wave %in% c(11,12), ], table(treatment2, treatment1, wave)))
cat("post_attack vs treatment1\n"); print(with(d[d$wave == 12, ], table(post_attack, treatment1)))
fit <- function(y, att, ideo, drop_w = NULL, extra = NULL) {
  ctrl <- c("white","gender","labour","party_other","income", ideo, extra)
  dd <- as.data.frame(d[complete.cases(d[, c(y, att, "time", "wave", ctrl)]), ])
  dd$A <- dd[[att]]; dd$AxT <- dd$A * dd$time
  ws <- sort(unique(dd$wave)); for (w in ws[-1]) dd[[paste0("w", w)]] <- as.numeric(dd$wave == w)
  wn <- paste0("w", ws[-1])
  if (!is.null(drop_w)) wn <- setdiff(wn, paste0("w", drop_w))
  cterm <- if (ideo == "ideo3f") { dd$ideo3f <- factor(dd$ideo3); c(setdiff(ctrl, "ideo3f"), "ideo3f") } else ctrl
  f <- as.formula(paste(y, "~ AxT + A + time +", paste(wn, collapse = "+"), "+", paste(cterm, collapse = "+")))
  b <- coef(lm(f, dd))
  sprintf("%-9s %-11s %-9s drop=%-3s N=%d AxT=%.4f A=%.4f time=%.4f const=%.4f", y, att, ideo, ifelse(is.null(drop_w), "last", drop_w), nrow(dd), b["AxT"], b["A"], b["time"], b["(Intercept)"])
}
for (y in c("likeMayW", "bestPMW")) for (att in c("treatment1","post_attack","treatment2")) for (ideo in c("ideology2","ideo3","ideo3f")) cat(fit(y, att, ideo), "\n")
for (dw in 12:16) cat(fit("likeMayW", "treatment1", "ideology2", drop_w = dw), "\n")
cat(fit("likeMayW", "treatment1", "ideology2", extra = "conservative"), "\n")
cat(fit("bestPMW", "treatment1", "ideology2", extra = "conservative"), "\n")
