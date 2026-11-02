## Exploratory: item-level attitude ITTs under alternative weighting / samples (no RESULT lines)
suppressPackageStartupMessages({ library(fixest) })
M <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-10-22-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(M, "data_agg.RData")); load(file.path(M, "survey_raw.RData"))
options(width = 200)
agg <- data.all
s0 <- as.data.frame(survey_raw)
s0$city <- as.character(s0$city); s0$barangay <- as.character(s0$barangay)
s0 <- s0[!is.na(s0$city) & !is.na(s0$assignment), ]
print(with(s0, table(barangay, paste(assignment, treatment))))
att <- agg[agg$att.prop > 0, c("barangay", "att.prop", "att.prop.turn")]
mkw <- function(s, scheme) {
  w <- rep(1, nrow(s))
  if (scheme == "none") return(w)
  for (i in seq_len(nrow(att))) {
    b <- as.character(att$barangay[i])
    idx <- which(s$barangay == b & !is.na(s$attendance)); if (!length(idx)) next
    ps <- mean(s$attendance[idx]); pa <- att$att.prop[i]
    a <- s$attendance[idx] == 1
    if (scheme == "ipw2") w[idx] <- ifelse(a, pa / ps, (1 - pa) / (1 - ps))
    if (scheme == "att_only") w[idx] <- ifelse(a, pa / ps, 1)
    if (scheme == "inv") w[idx] <- ifelse(a, ps / pa, 1)
  }
  w
}
items <- c("poverty", "gap", "cct", "corruption", "femhouse", "fempol", "equality", "discrimination", "harassment")
for (samp in c("turnoutvalid", "all")) {
  s <- if (samp == "all") s0 else s0[!is.na(s0$turnout_pl), ]
  for (scheme in c("ipw2", "att_only", "inv", "none")) {
    s$w <- mkw(s, scheme)
    for (party in c("Akbayan", "Umalab Ka")) {
      d <- s[s$partytreat == party, ]; ctrl <- d$assignment == 0
      out <- sapply(items, function(k) {
        x <- d[[k]]; d$z <- (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
        coef(feols(z ~ assignment | city, data = d, weights = ~w, notes = FALSE))[["assignment"]]
      })
      cat(sprintf("%-12s %-8s %-9s n=%4d | %s\n", samp, scheme, party, nrow(d),
                  paste(sprintf("%s=%.2f", items, out), collapse = " ")))
    }
  }
}
