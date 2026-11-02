suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-01-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d$dist <- d$own_amt - 500
print(table(round(d$own_amt[d$own_amt < 205],3)))
print(table(round(d$own_amt[d$own_amt > 795 & d$own_amt < 805],3)))
s <- d[abs(d$dist) < 300, ]
cat("strict N", nrow(s), "owners", n_distinct(s$Expropretario_ISTA), "propyr", nrow(distinct(s, match_id, year)), "\n")
s <- d[d$dist > -300 & d$dist <= 300, ]
cat("lefthalfopen N", nrow(s), "owners", n_distinct(s$Expropretario_ISTA), "propyr", nrow(distinct(s, match_id, year)), "\n")
for (bw in c(300,150)) {
  s <- d[abs(d$dist) <= bw, ]
  g <- s %>% group_by(match_id, year) %>% summarise(n=n(), nm=first(num_members), .groups="drop")
  cat("bw", bw, "cells", nrow(g), "n>=5", sum(g$n>=5), "nm>=5", sum(g$nm>=5), "\n")
  g2 <- s %>% group_by(match_id) %>% summarise(n=n(), .groups="drop"); cat(" props n>=5", sum(g2$n>=5), "\n")
}
