# Exploratory: endline bribe sources, de facto Local nbhd (no estimates)
suppressMessages({library(haven); library(dplyr)})
options(width = 220)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
tb <- function(...) print(table(..., useNA = "ifany"))
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>% select(a7, treatment, stratum) %>% mutate(treatment = as.vector(treatment))
e1 <- read_dta(file.path(B, "survey_data/endline_round1_noPII.dta"))
e1j <- e1 %>% inner_join(ra %>% rename(atr = treatment, str = stratum), by = "a7")
cat("CXL nbhds with endline treatment==2:\n"); print(e1j %>% filter(atr == 4) %>% group_by(a7) %>% summarise(n = n(), t2 = sum(as.vector(treatment) == 2, na.rm=TRUE), t4 = sum(as.vector(treatment) == 4, na.rm=TRUE)) %>% filter(t2 > 0) %>% as.data.frame())
# bribe-like variables in endline round1
nm <- names(e1); labs <- sapply(e1, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
idx <- grep("bribe|transport|pot|informal|pay_gov|fee", paste(nm, labs), ignore.case = TRUE)
for (i in idx) { v <- as.vector(e1j[[nm[i]]]); if (is.numeric(v)) cat(sprintf("%-30s nonmiss C/L=%d  mean=%.3f | %s\n", nm[i], sum(!is.na(v) & e1j$atr %in% 1:2 & v < 8000), mean(v[e1j$atr %in% 1:2 & v < 8000], na.rm=TRUE), substr(labs[i], 1, 90))) }
e3 <- read_dta(file.path(B, "survey_data/endline_2016campaign_noPII.dta"))
cat("\nendline_2016campaign rows", nrow(e3), "\n")
nm3 <- names(e3); labs3 <- sapply(e3, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
for (i in grep("a7|treat|tmt|stratum|bribe|transport|visited|today|code|round", nm3, ignore.case = TRUE)[1:60]) if (!is.na(i)) cat(sprintf("%s | %s\n", nm3[i], substr(labs3[i], 1, 90)))
if ("a7" %in% nm3) { x <- e3 %>% inner_join(ra %>% rename(atr = treatment, str = stratum), by = "a7"); tb(x$atr); if ("bribe" %in% nm3) tb(x$atr, as.vector(x$bribe)); if ("today" %in% nm3) print(summary(x$today)) }
