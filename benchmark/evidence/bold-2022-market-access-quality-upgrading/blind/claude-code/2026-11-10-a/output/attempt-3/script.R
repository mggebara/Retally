suppressMessages({library(haven); library(dplyr)})
M <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(M, "data/raw/")
options(width=250)
g1 <- read_dta(paste0(D,"panel_g1.dta"))
num <- names(g1)[sapply(g1, is.numeric)]
tab <- sapply(num, function(v) tapply(!is.na(g1[[v]]), g1$survey_season, sum))
tab <- t(tab); tab <- tab[rowSums(tab)>30,]
print(tab)
chr <- names(g1)[sapply(g1, is.character)]
for (v in c("sold_crop","dry_how","sort","winnow","decob","bag","storage")) {cat(v,"\n"); print(table(g1[[v]], g1$survey_season)[1:min(12,length(unique(g1[[v]]))),])}
# returns: bag ids across sales
r <- read_dta(paste0(D,"anonym_returns_data.dta"))
W <- function(s) as.matrix(r[, paste0("add5_ind_weight",1:20,"_",s)])
A <- as.matrix(r[, paste0("add4_weight_",1:20)])
ov <- 0; for (s1 in 1:3) for (s2 in (s1+1):4) ov <- ov + sum(!is.na(W(s1)) & !is.na(W(s2)))
cat("bag-slot overlap across sales:", ov, "\n")
for (s in 1:4) { w <- W(s); m <- !is.na(w); cat("sale",s,"slots",sum(m)," slot has add4 weight:", sum(m & !is.na(A)), " mean abs diff:", mean(abs(w[m]-A[m]), na.rm=TRUE), " cor:", cor(w[m & !is.na(A)], A[m & !is.na(A)]), "\n") }
cat("bags measured but never sold:", sum(!is.na(A) & is.na(W(1)) & is.na(W(2)) & is.na(W(3)) & is.na(W(4))), "\n")
for (s in 1:4) {d <- r[[paste0("add5_sold_when_e_",s)]]; cat("sale",s,"dates nonmissing", sum(!is.na(d) & d!=""), "range", range(d[!is.na(d)&d!=""]), "\n")}
hh_sales <- rowSums(!is.na(as.matrix(r[,paste0("add5_ppk_",1:4)])))
cat("hh with >=1 sale:", sum(hh_sales>0), " total sales:", sum(hh_sales), "\n")
# defects NA pattern
ty <- c("dirty","cobs","stones","dust","broken","immature","damage","rot","insect","insect_live","mould")
for (t in ty) { x <- as.matrix(r[, paste0("add4_",t,"_",1:20)]); cat(t, "values:", paste(names(table(x, useNA="ifany")), table(x,useNA="ifany"), collapse=" "), " NA-on-existing-bag:", sum(is.na(x) & !is.na(A)), "\n") }
for (t in ty) cat(t, "NA on existing bag by treat:", tapply(rowSums(is.na(as.matrix(r[, paste0("add4_",t,"_",1:20)])) & !is.na(A)), r$treatment, sum), "\n")
cat("lab nonNA by treat:", tapply(!is.na(r$Total_weight_of_maize_g), r$treatment, sum), "\n")
cat("sold_kg seller vs panel\n")
sd <- read_dta(paste0(D,"seller_data.dta"))
print(table(sd$name, useNA="ifany")[1:15]); print(sum(sd$price==0)); print(sum(sd$sold_kg_p_==0))
print(table(sd$survey_season, is.na(sd$name)))
