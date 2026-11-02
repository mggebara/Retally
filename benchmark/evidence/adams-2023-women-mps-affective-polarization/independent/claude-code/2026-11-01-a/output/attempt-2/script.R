P <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-01-a/mount/adams_2023_women_mps_affective_polarization"
load(file.path(P, "dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
cat("seats==999 to/from:", sum(d$to_prior_seats==999, na.rm=TRUE), sum(d$from_prior_seats==999, na.rm=TRUE), "\n")
print(d[d$to_prior_seats==999 | d$from_prior_seats==999, c("country","year","from_partyname","to_partyname","from_prior_seats","to_prior_seats")][1:10,])
cat("NA: like", sum(is.na(d$party_like)), " pfeml", sum(is.na(d$to_pfeml)), " rile", sum(is.na(d$rile_distance)), " pc", sum(is.na(d$prior_coalition)), " gt", sum(is.na(d$govern_together)), "\n")
cc <- !is.na(d$party_like) & !is.na(d$to_pfeml)
f4 <- d$to_prior_seats >= 4 & d$from_prior_seats >= 4
f4b <- f4 & d$to_prior_seats != 999 & d$from_prior_seats != 999
for (nm in c("cc","cc&f4","cc&f4b")) { s <- eval(parse(text=nm)); cat(nm, sum(s, na.rm=TRUE), " cy:", length(unique(d$cntryyr[which(s)])), " w/ rile:", sum(s & !is.na(d$rile_distance), na.rm=TRUE), "\n") }
cat("table pc vs gt\n"); print(table(d$prior_coalition, d$govern_together)); print(table(d$prior_opposition, d$opposition_together))
g <- readRDS(file.path(P, "gender_disagregated_8-8-21.rds"))
for (k in 1:2) { gg <- g[g$gender==k,]; s <- !is.na(gg$dislike) & !is.na(gg$to_pfeml) & gg$to_prior_seats>=4 & gg$from_prior_seats>=4; cat("gender", k, sum(s, na.rm=TRUE), " w/ rile", sum(s & !is.na(gg$rile_distance), na.rm=TRUE), "\n") }
s <- cc & f4
cat("rile mean/sd in sample:", mean(d$rile_distance[which(s)], na.rm=TRUE), sd(d$rile_distance[which(s)], na.rm=TRUE), "\n")
cat("pfeml mean/sd in sample:", mean(d$to_pfeml[which(s)]), sd(d$to_pfeml[which(s)]), " like sd", sd(d$party_like[which(s)]), "\n")
