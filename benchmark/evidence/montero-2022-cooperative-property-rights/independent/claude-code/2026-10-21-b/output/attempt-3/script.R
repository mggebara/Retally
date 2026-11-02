suppressPackageStartupMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-10-21-b/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
d$rv <- d$own_amt - 500
s <- d %>% filter(abs(rv) <= 300)
cat("rv near +-300:\n"); print(s %>% filter(abs(rv) > 290) %>% count(match_id, Expropretario_ISTA, rv, year))
cat("strict <300 N", sum(abs(d$rv) < 300), "\n")
cat("float own_amt near 800/200:\n"); print(sort(unique(d$own_amt[d$own_amt > 190 & d$own_amt < 210 | d$own_amt > 790 & d$own_amt < 810])), digits=12)
print(sort(unique(s$own_amt)), digits=10)
for (bw in c(300,150)) {
  s <- d %>% filter(abs(rv) <= bw)
  for (mm in c(0,5)) {
    g <- s %>% filter(num_members >= mm) %>% group_by(match_id, year) %>% summarise(n=n(),
      iqr7=quantile(hh_income_pc,.75)-quantile(hh_income_pc,.25),
      iqr2=quantile(hh_income_pc,.75,type=2)-quantile(hh_income_pc,.25,type=2),
      iqr6=quantile(hh_income_pc,.75,type=6)-quantile(hh_income_pc,.25,type=6), cl=n_distinct(Expropretario_ISTA), .groups="drop")
    cat(sprintf("bw %d nm>=%d: obs %d mean iqr7 %.3f iqr2 %.3f iqr6 %.3f\n", bw, mm, nrow(g), mean(g$iqr7), mean(g$iqr2), mean(g$iqr6)))
  }
}
