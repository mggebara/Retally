# Exploratory run 7: universe flags and time-period definition search (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
options(width = 220, warn = -1)
f <- function(t, lab) { tt <- table(factor(t, levels = 0:4)); cat(sprintf("%-50s N=%6d | %s\n", lab, sum(tt), paste(names(tt), tt, sep="=", collapse=" "))) }
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>% zap_labels()
ra$tf <- ra$treatment; ra$tf[ra$a7 == 654] <- 2
reg <- read_dta(file.path(B, "admin_data/registration_noPII.dta")) %>% zap_labels()
hh <- read_dta(file.path(B, "admin_data/hh_distances.dta")) %>% zap_labels()
pay <- read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")) %>% zap_labels()
r <- reg %>% filter(compound1 %in% hh$compound1)
r$dup <- duplicated(r$compound1) | duplicated(r$compound1, fromLast = TRUE)
r1 <- r %>% arrange(compound1, start) %>% distinct(compound1, .keep_all = TRUE)
u <- hh %>% filter(!is.na(compound1)) %>% select(compound1, a7h = a7) %>% left_join(r1, by = "compound1")
u$t <- ra$tf[match(u$a7h, ra$a7)]
cat("TARGET extra: 1=12 3=3 (approx)\n")
flags <- list(
  tot_incomplete = u$tot_complete == 0, c1ne_c2 = u$compound1 != u$compound2, dup = u$dup, a7_ne_code = u$compound1 %/% 1000 != u$a7h,
  a7h_ne_a7 = u$a7h != u$a7, a7b_ne = !is.na(u$a7b) & u$a7b != u$a7, a7comp_ne = u$a7_compound != u$a7, double_sensi = u$double_sensi == 1,
  correct0 = u$correct %in% 0, chalk0 = u$chalk_check %in% 0, end_na = is.na(u$end), first1 = u$first %in% 1, col_change1 = u$col_change %in% 1,
  who_na = is.na(u$who), commune_na = is.na(u$commune), house_corr = !is.na(u$house_correct), tmt_ne = !is.na(u$tmt) & u$tmt != u$t,
  oldcode_big = u$old_code > 0, carto_na = is.na(u$carto_pay))
for (n in names(flags)) f(u$t[which(flags[[n]])], n)
cat("a7=561 rows:", sum(u$a7h == 561, na.rm=T), "\n")
cat("high band (house==2) by arm:\n"); print(table(u$house, u$t))

# Time-period search
u$d <- as.numeric(as.Date(u$start))
nbstat <- u %>% filter(!is.na(t)) %>% group_by(a7h, t) %>% summarise(nmin = min(d, na.rm=T), nmax = max(d, na.rm=T), nmed = median(d, na.rm=T), nmean = mean(d, na.rm=T), .groups = "drop")
u <- u %>% left_join(nbstat %>% select(-t), by = "a7h")
search <- function(arms, target) {
  cat("\n--- arms", arms, "target", target, "\n")
  s <- u %>% filter(t %in% arms)
  for (dv in c("d", "nmin", "nmax", "nmed", "nmean")) for (fl in c("prop", "nbmin", "nbmax")) {
    # arm first/last
    if (fl == "prop") { fa <- tapply(s$d, s$t, min, na.rm=T); la <- tapply(s$d, s$t, max, na.rm=T) }
    if (fl == "nbmin") { fa <- tapply(s$nmin, s$t, min, na.rm=T); la <- tapply(s$nmin, s$t, max, na.rm=T) }
    if (fl == "nbmax") { fa <- tapply(s$nmin, s$t, min, na.rm=T); la <- tapply(s$nmax, s$t, max, na.rm=T) }
    st <- mean(fa); en <- mean(la)
    x <- s[[dv]]
    for (inc in c("ge", "gt")) {
      keep <- if (inc == "ge") x >= st & x <= en else x > st & x < en
      keep[is.na(keep)] <- FALSE
      cat(sprintf("date=%-5s first/last=%-5s %s start=%s end=%s N=%d clusters=%d\n", dv, fl, inc, as.Date(st, origin="1970-01-01"), as.Date(en, origin="1970-01-01"), sum(keep), length(unique(s$a7h[keep]))))
    }
  }
}
search(1:2, "27764 / 213 (of 28872/221)")
search(c(1,3), "20636 / 165 (of 23911/190)")
# payments outliers
cat("\nbig amounts:\n"); print(as.data.frame(pay %>% filter(amountCF > 13200 | amountCF < 1500) %>% select(compound1, a7, amountCF, rateUSD, error_code, error_rate, date, house)))
cat("pay rows with error_code==1 by rateUSD:\n"); print(table(pay$rateUSD, pay$error_code))
cat("error_rate x error_code\n"); print(table(pay$error_rate, pay$error_code, useNA="ifany"))
cat("pay date < 2018-06 in universe:", sum(as.Date(pay$date) < as.Date("2018-06-01") & pay$compound1 %in% u$compound1, na.rm=T), "\n")
print(table(pay$error_code, as.Date(pay$date) < as.Date("2018-06-01"), useNA="ifany"))
