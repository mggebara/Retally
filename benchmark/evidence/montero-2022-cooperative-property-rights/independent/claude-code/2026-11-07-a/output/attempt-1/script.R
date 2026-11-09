library(haven); library(dplyr)
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-07-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
print(dim(d))
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label"); cat(v, "|", class(x)[1], "|", if(!is.null(lab)) lab else "", "| nNA", sum(is.na(x)), "| uniq", length(unique(x)), "| ", paste(head(unique(x),6), collapse=","), "\n") }
