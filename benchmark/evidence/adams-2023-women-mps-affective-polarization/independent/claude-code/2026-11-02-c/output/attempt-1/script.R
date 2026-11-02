D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-02-c/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D,"dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
print(names(d))
print(dim(d))
for (v in c("year","party_like","party_dislike","to_pfeml","rile_distance","rile_distance_s","govern_together","opposition_together","to_prior_seats","from_prior_seats","cntryyr")) if (v %in% names(d)) {cat(v,"\n"); print(summary(d[[v]]))}
print(length(unique(paste(d$country,d$year))))
print(table(d$govern_together, d$opposition_together, useNA="a"))
g <- readRDS(file.path(D,"gender_disagregated_8-8-21.rds"))
print(names(g)); print(dim(g)); print(table(g$gender, useNA="a"))
print(length(unique(paste(g$country,g$year))))
for (v in c("dislike","to_prior_seats","from_prior_seats")) print(summary(g[[v]]))
