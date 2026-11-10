# Exploratory run 5: universe, time-window variants, payment definitions (counts and arm means only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, house, today, start, exempt, tot_complete)))
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
hd <- merge(hd[, c("compound1","a7")], ra[, c("a7","trt","stratum")], by = "a7")
cat("hd by trt:\n"); print(table(hd$trt))
cat("hd compound prefix == a7:", sum(hd$compound1 %/% 1000 == hd$a7), "\n")
cat("hd in registration:\n"); print(table(hd$trt, hd$compound1 %in% rg$compound1))
rgd <- rg[rg$compound1 %in% hd$compound1, ]
cat("dup among matched registration:", sum(duplicated(rgd$compound1)), "\n")
dupc <- rgd$compound1[duplicated(rgd$compound1)]
print(as.data.frame(rgd[rgd$compound1 %in% dupc, ][1:min(20, sum(rgd$compound1 %in% dupc)), ]))
cat("house among matched:\n"); print(table(rgd$house))
rgd <- rgd %>% arrange(compound1, start) %>% filter(!duplicated(compound1))
u <- merge(hd, rgd[, c("compound1","house","today","exempt")], by = "compound1", all.x = TRUE)
cat("universe by trt, house:\n"); print(table(u$trt, u$house, useNA = "a"))
u$dt <- as.Date(u$today)
cat("missing date:", sum(is.na(u$dt)), "\n")
print(u %>% group_by(trt) %>% summarise(first = min(dt, na.rm=TRUE), last = max(dt, na.rm=TRUE), n = n()))

win <- function(u, arms) {
  s <- u[u$trt %in% arms, ]
  fd <- tapply(s$dt, s$trt, min, na.rm = TRUE); ld <- tapply(s$dt, s$trt, max, na.rm = TRUE)
  st <- as.Date(mean(as.numeric(fd)), origin = "1970-01-01"); en <- as.Date(mean(as.numeric(ld)), origin = "1970-01-01")
  cat("\narms", arms, " first:", format(as.Date(fd, origin="1970-01-01")), " last:", format(as.Date(ld, origin="1970-01-01")), " start mid:", mean(as.numeric(fd)), format(st), " end mid:", mean(as.numeric(ld)), format(en), "\n")
  sn <- mean(as.numeric(fd)); enn <- mean(as.numeric(ld))
  nbd <- s %>% group_by(a7) %>% mutate(nmin = min(as.numeric(dt), na.rm=TRUE), nmax = max(as.numeric(dt), na.rm=TRUE), nmed = median(as.numeric(dt), na.rm=TRUE), nmean = mean(as.numeric(dt), na.rm=TRUE)) %>% ungroup()
  cat("total N", nrow(s), " clusters", length(unique(s$a7)), "\n")
  for (v in c("prop", "nmin", "nmax", "nmed", "nmean")) {
    x <- if (v == "prop") as.numeric(nbd$dt) else nbd[[v]]
    for (rule in c("ge", "gt")) {
      keep <- if (rule == "ge") (x >= sn & x <= enn) else (x > sn & x < enn)
      keep[is.na(keep)] <- FALSE
      cat(sprintf("  %-6s %-3s N=%d clusters=%d\n", v, rule, sum(keep), length(unique(nbd$a7[keep]))))
    }
  }
}
win(u, c(1, 2))
win(u, c(1, 3))

tp <- zap_labels(read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")))
tp <- tp[!is.na(tp$compound1), ]
cat("\npayments in universe:", sum(tp$compound1 %in% u$compound1), " of", nrow(tp), "\n")
u$pay_all <- as.numeric(u$compound1 %in% tp$compound1)
u$pay_noerr <- as.numeric(u$compound1 %in% tp$compound1[tp$error_code %in% 0])
u$pay_nolate <- as.numeric(u$compound1 %in% tp$compound1[tp$lateCollection %in% 0])
u$pay_paid3 <- as.numeric(u$compound1 %in% tp$compound1[tp$paid %in% c(1,3)])
amt <- tp %>% group_by(compound1) %>% summarise(amt = sum(amountCF, na.rm=TRUE))
u <- merge(u, amt, by = "compound1", all.x = TRUE); u$rev <- ifelse(is.na(u$amt), 0, u$amt)
print(u %>% group_by(trt) %>% summarise(n = n(), all = mean(pay_all), noerr = mean(pay_noerr), nolate = mean(pay_nolate), paid3 = mean(pay_paid3), rev = mean(rev), rev_cap = mean(pmin(rev, 13200))))
cat("big amounts in universe:\n"); print(tp[tp$amountCF > 13200 & !is.na(tp$amountCF), c("compound1","amountCF","house","error_code")])
cat("rev table for payers (Central/Local):\n"); print(table(u$rev[u$rev > 0 & u$trt %in% c(1,2)]))
cat("exempt by trt:\n"); print(table(u$trt, u$exempt, useNA="a"))
cat("payers with exempt==1:", sum(u$pay_all == 1 & u$exempt %in% 1), "\n")
cat("C+L non-exempt (exempt!=1):", sum(u$trt %in% c(1,2) & !(u$exempt %in% 1)), " exempt==0:", sum(u$trt %in% c(1,2) & u$exempt %in% 0), "\n")
