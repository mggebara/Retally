D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-10-21-b/mount/adams_2023_women_mps_affective_polarization"
options(width=200)
for (f in c("Codebook for Dyadic Party Dataset.docx","Codebook for Gender Disaggregated Dyadic Party Dataset.docx")) {
  td <- tempfile(); dir.create(td); utils::unzip(file.path(D,f), exdir=td)
  x <- paste(readLines(file.path(td,"word/document.xml"), warn=FALSE), collapse="")
  x <- gsub("</w:p>", "\n", x); x <- gsub("<[^>]+>", "", x); cat("=====",f,"\n", x, "\n")
}
load(file.path(D,"dyadic_data_1-4-22.Rdata")); d <- as.data.frame(updated_data)
g <- readRDS(file.path(D,"gender_disagregated_8-8-21.rds"))
cat("nrow d", nrow(d), "cntryyr", length(unique(d$cntryyr)), "\n")
print(summary(d[,c("party_like","party_dislike","to_pfeml","rile_distance","rile_distance_s","to_prior_seats","from_prior_seats","govern_together","opposition_together")]))
for (k in c(1,4,5)) { s <- subset(d, to_prior_seats>=k & from_prior_seats>=k); cat("k",k,nrow(s), length(unique(s$cntryyr)), "complete", sum(complete.cases(s[,c("party_like","to_pfeml","rile_distance","govern_together","opposition_together")])), "\n") }
cat("cc all", sum(complete.cases(d[,c("party_like","to_pfeml","rile_distance","govern_together","opposition_together")])), "\n")
print(table(d$from_complete)); print(table(d$to_complete))
cat("sd party_like", sd(d$party_like,na.rm=T), "\n")
print(summary(g[,c("dislike","party_like","party_dislike","to_prior_seats")]))
print(head(g[,c("country","year","party_from","party_to","gender","dislike","party_like","party_dislike")],10))
print(table(d$country, d$year)[1:5,])
