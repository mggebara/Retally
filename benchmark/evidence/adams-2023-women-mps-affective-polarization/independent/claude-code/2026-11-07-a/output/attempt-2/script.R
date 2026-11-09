D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-07-a/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D, "dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
cat("999 seats to:", sum(d$to_prior_seats == 999), " from:", sum(d$from_prior_seats == 999), "\n")
print(table(d$country[d$to_prior_seats == 999 | d$from_prior_seats == 999]))
cc <- complete.cases(d[, c("party_like", "to_pfeml", "rile_distance_s", "prior_coalition", "prior_opposition")])
cat("complete:", sum(cc), "\n")
f1 <- d$to_prior_seats >= 4 & d$from_prior_seats >= 4
f2 <- f1 & d$to_prior_seats != 999 & d$from_prior_seats != 999
cat("f1:", sum(f1 & cc), " f2:", sum(f2 & cc), "\n")
cat("f1 no-cc:", sum(f1), " pfeml nonNA f1:", sum(f1 & !is.na(d$to_pfeml)), "\n")
cat("elections f1:", length(unique(d$cntryyr[f1 & cc])), "\n")
cat("seats>4 :", sum(d$to_prior_seats > 4 & d$from_prior_seats > 4 & cc), "\n")
g <- readRDS(file.path(D, "gender_disagregated_8-8-21.rds"))
gc <- complete.cases(g[, c("dislike", "to_pfeml", "rile_distance_s", "prior_coalition", "prior_opposition")])
gf <- g$to_prior_seats >= 4 & g$from_prior_seats >= 4
print(table(g$gender[gf & gc]))
cat("rile_distance mean/sd on f1:", mean(d$rile_distance[f1 & cc]), sd(d$rile_distance[f1 & cc]), "\n")
cat("rile_distance_s check:", cor(d$rile_distance, d$rile_distance_s), "\n")
