D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-02-c/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D,"dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
d$el <- paste(d$country, d$year)
cc <- function(x, vars) { k <- complete.cases(x[, vars]); c(n = sum(k), el = length(unique(x$el[k]))) }
v1 <- c("party_like","to_pfeml"); v2 <- c(v1,"rile_distance_s","govern_together","opposition_together")
cat("all:", cc(d,v1), cc(d,v2), "\n")
for (thr in c(1,2,3,4,5)) {
  s <- d[d$from_prior_seats >= thr & d$to_prior_seats >= thr, ]
  cat("seats>=",thr,":", cc(s,v1), cc(s,v2), "\n")
}
cat("seat distribution low:\n"); print(table(pmin(d$to_prior_seats, 10)))
cat("to_pfeml NA by seats==0:\n"); print(table(is.na(d$to_pfeml), d$to_prior_seats==0))
cat("elections with NA to_pfeml everywhere:\n")
print(tapply(is.na(d$to_pfeml), d$el, mean)[tapply(is.na(d$to_pfeml), d$el, mean) > 0.5])
print(table(d$to_complete, useNA="a")); print(table(d$from_complete, useNA="a"))
g <- readRDS(file.path(D,"gender_disagregated_8-8-21.rds")); g$el <- paste(g$country,g$year)
g$like <- 10 - g$dislike
for (gg in 1:2) cat("gender",gg,":", cc(g[g$gender==gg,], c("like","to_pfeml","rile_distance_s","govern_together","opposition_together")), "\n")
