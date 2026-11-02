D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-10-22-a/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D, "dyadic_data_1-4-22.Rdata"))
g <- readRDS(file.path(D, "gender_disagregated_8-8-21.rds"))
d <- as.data.frame(updated_data)
print(names(d)); print(names(g))
vars <- c("party_like","party_dislike","to_pfeml","rile_distance","rile_distance_s","prior_coalition","prior_opposition","govern_together","opposition_together","to_prior_seats","from_prior_seats","cntryyr","year")
for (v in intersect(vars, names(d))) { cat("==", v, "\n"); print(summary(d[[v]])) }
cat("rows", nrow(d), " countries", length(unique(d$country)), " cntryyr", length(unique(paste(d$country,d$year))), "\n")
print(table(d$prior_coalition, d$govern_together, useNA="ifany"))
print(table(d$prior_opposition, d$opposition_together, useNA="ifany"))
s <- subset(d, to_prior_seats >= 4 & from_prior_seats >= 4)
cat("seats>=4 rows", nrow(s), " cy", length(unique(paste(s$country,s$year))), " countries", length(unique(s$country)), "\n")
print(sapply(s[, intersect(vars, names(s))], function(x) sum(is.na(x))))
print(table(g$gender, useNA="ifany"))
for (v in intersect(c(vars,"dislike"), names(g))) { cat("== g", v, "\n"); print(summary(g[[v]])) }
print(unique(d$country))
print(table(d$year))
