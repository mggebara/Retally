suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/blind/2026-11-07-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
cat(dim(d), "\n")
for (v in names(d)) { x <- d[[v]]; lab <- attr(x, "label"); cat(sprintf("%-28s %-10s nNA=%5d nuniq=%5d  %s | %s\n", v, class(x)[1], sum(is.na(x)), length(unique(x)), ifelse(is.null(lab), "", lab), paste(head(unique(as.character(x)), 6), collapse=", "))) }
