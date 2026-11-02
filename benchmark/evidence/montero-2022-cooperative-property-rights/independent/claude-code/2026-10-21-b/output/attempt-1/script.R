suppressPackageStartupMessages({library(haven); library(dplyr)})
d <- read_dta("/Users/matthew/dev/Retally/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-10-21-b/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
cat(dim(d), "\n")
for (v in names(d)) { x <- d[[v]]; lab <- attr(x, "label"); cat(sprintf("%-28s %-10s nNA=%5d nuniq=%5d  %s | %s\n", v, class(x)[1], sum(is.na(x)), length(unique(x)), ifelse(is.null(lab), "", lab), paste(head(unique(as.character(x)), 5), collapse=", "))) }
