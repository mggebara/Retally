P <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-01-a/mount/adams_2023_women_mps_affective_polarization"
load(file.path(P, "dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
print(names(d))
str(d, list.len = 200, vec.len = 2)
for (v in c("to_prior_seats","from_prior_seats","party_like","party_dislike","to_pfeml","govern_together","opposition_together","prior_coalition","prior_opposition")) if (v %in% names(d)) {cat(v,"\n"); print(summary(d[[v]]))}
cat("rows", nrow(d), " cntryyr", length(unique(paste(d$country,d$year))), "\n")
g <- readRDS(file.path(P, "gender_disagregated_8-8-21.rds"))
print(names(g)); print(table(g$gender, useNA="a"))
