## exploratory: component-level ITTs (raw coding, control-standardized) under weight/sample variants; no RESULT lines
suppressPackageStartupMessages(library(fixest))
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-11-02-c/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData")); load(file.path(D, "survey_raw.RData"))
s0 <- as.data.frame(survey_raw)
s0$city <- as.character(s0$city); s0$barangay <- as.character(s0$barangay)
s0 <- subset(s0, !is.na(city) & !is.na(barangay))
s0 <- merge(s0, data.all[, c("barangay", "att.prop", "att.prop.turn")], by = "barangay", all.x = TRUE)
s0$att.prop[is.na(s0$att.prop)] <- 0; s0$att.prop.turn[is.na(s0$att.prop.turn)] <- 0
mkw <- function(s, pt, type) {
  ps <- tapply(s$attendance, s$barangay, function(x) mean(x, na.rm = TRUE)); p_s <- ps[s$barangay]
  w <- rep(1, nrow(s)); tr <- s$treatment == 1 & !is.na(s$attendance) & p_s > 0
  a <- tr & s$attendance == 1; n <- tr & s$attendance == 0
  w[a] <- (pt / p_s)[a]
  if (type == "post") w[n] <- ((1 - pt) / (1 - p_s))[n]
  w
}
items <- c("poverty", "gap", "cct", "corruption", "femhouse", "fempol", "equality", "discrimination", "harassment")
for (samp in c("turnout_nonmissing", "all")) for (wt in c("none", "post_att.prop", "post_att.prop.turn", "attonly_att.prop")) {
  s <- if (samp == "all") s0 else subset(s0, !is.na(turnout_pl))
  s$w <- switch(wt, none = 1, post_att.prop = mkw(s, s$att.prop, "post"),
                post_att.prop.turn = mkw(s, s$att.prop.turn, "post"), attonly_att.prop = mkw(s, s$att.prop, "att"))
  for (p in c("Akbayan", "Umalab Ka")) {
    d <- subset(s, partytreat == p); ctrl <- d$assignment == 0
    out <- sapply(items, function(k) {
      d$z <- (d[[k]] - mean(d[[k]][ctrl], na.rm = TRUE)) / sd(d[[k]][ctrl], na.rm = TRUE)
      coef(feols(z ~ assignment | city, data = d, weights = ~w, notes = FALSE))["assignment"]
    })
    cat(sprintf("%-18s %-20s %-9s %s\n", samp, wt, p, paste(sprintf("%s=%.3f", items, out), collapse = " ")))
  }
}
