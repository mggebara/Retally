D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-10-21-b/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D, "dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
print(names(d))
for (v in grep("rile|prior|seats|together|pfeml|like", names(d), value=TRUE)) { cat(v, ": NA=", sum(is.na(d[[v]])), "\n"); print(summary(d[[v]])) }
cat("n countries", length(unique(d$country)), " n cy", length(unique(paste(d$country,d$year))), "\n")
print(table(d$from_prior_seats >= 4 & d$to_prior_seats >= 4, useNA="ifany"))
s <- subset(d, from_prior_seats >= 4 & to_prior_seats >= 4)
cat("sub n", nrow(s), " cy", length(unique(paste(s$country,s$year))), " countries", length(unique(s$country)), "\n")
if ("cntryyr" %in% names(s)) cat("cntryyr n", length(unique(s$cntryyr)), "\n")
print(colSums(is.na(s[, grep("rile|prior_co|prior_op|together|pfeml|like", names(s))])))
print(with(s, table(prior_coalition, govern_together, useNA="ifany")))
print(with(s, table(prior_opposition, opposition_together, useNA="ifany")))
g <- readRDS(file.path(D, "gender_disagregated_8-8-21.rds"))
print(names(g)); print(table(g$gender, useNA="ifany"))
for (v in grep("rile|prior|seats|dislike", names(g), value=TRUE)) { cat(v, ": NA=", sum(is.na(g[[v]])), "\n"); print(summary(g[[v]])) }
gs <- subset(g, from_prior_seats >= 4 & to_prior_seats >= 4)
print(table(gs$gender, !is.na(gs$dislike)))
