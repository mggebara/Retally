suppressMessages(library(haven))
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-c/mount/goni_2022_assortative_matching_london_season/data/"
d <- read_dta(paste0(D,"final-data.dta"))
cat(dim(d),"\n")
nm <- names(d)
for (v in nm) { lab <- attr(d[[v]],"label"); cat(v, ":", if(is.null(lab)) "" else lab, "| class", class(d[[v]])[1], "| nuniq", length(unique(d[[v]])), "\n") }
for (v in c("base_sample","marital_rates_sample","cOut","mheir","fdown","nthismarriage")) if (v %in% nm) print(table(d[[v]], useNA="ifany"))
