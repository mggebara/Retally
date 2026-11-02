D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-02-c/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D,"dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
d$el <- paste(d$country, d$year)
k <- !is.na(d$to_pfeml) & !is.na(d$party_like)
x <- d[k, ]
cat("base", nrow(x), "\n")
for (thr in 1:6) cat(thr, " to only:", sum(x$to_prior_seats >= thr), " from only:", sum(x$from_prior_seats >= thr),
  " both:", sum(x$to_prior_seats >= thr & x$from_prior_seats >= thr), "\n")
cat("from_pfeml NA in base:", sum(is.na(x$from_pfeml)), "\n")
cat("both pfeml nonNA:", sum(!is.na(x$from_pfeml)), "\n")
cat("both pfeml nonNA & seats>=4 both:", sum(!is.na(x$from_pfeml) & x$to_prior_seats>=4 & x$from_prior_seats>=4), "\n")
# party-level: implied number of MPs from pfeml denominators? check pfeml*seats integer-ness
pf <- x$to_pfeml * x$to_prior_seats
cat("frac of to_pfeml*seats near integer:", mean(abs(pf - round(pf)) < 1e-6, na.rm=TRUE), "\n")
# rows by number of unique parties per election
y <- x[x$from_prior_seats >= 4 & x$to_prior_seats >= 4,]
print(head(x[x$to_prior_seats < 4, c("el","to_partyname","to_prior_seats","to_pfeml","from_partyname","from_prior_seats")], 30))
cat("party_like==NA:", sum(is.na(d$party_like)), "\n")
print(table(x$to_pfeml == 0, x$to_prior_seats < 4))
cat("prior_seats > 0 & pfeml>0 & seats>=4 both, or pfeml defined:\n")
cat(sum(x$to_prior_seats >= 4 | x$to_prior_seats==999), "\n")
cat("drop dyads where either has seats<4 but count 0-seat as >=4?", sum((x$to_prior_seats>=4 | x$to_prior_seats==0) & (x$from_prior_seats>=4 | x$from_prior_seats==0)), "\n")
