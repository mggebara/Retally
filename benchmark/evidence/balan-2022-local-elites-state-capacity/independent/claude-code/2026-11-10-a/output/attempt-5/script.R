# Exploratory 5: sample counts and time-window variants (no estimates)
suppressMessages({library(haven); library(dplyr)})
options(width = 220)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rs <- zap_labels(read_dta(file.path(B, "admin_data/randomization_schedule.dta")))
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta")))
tr <- zap_labels(read_dta(file.path(B, "admin_data/taxroll_noPII.dta")))
tp <- zap_labels(read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")))
tr$trstat <- ifelse(grepl("FC", tr$MontantIF) & !grepl("^\\.", tr$MontantIF), "amount", ifelse(tr$MontantIF == "", "blank", tr$MontantIF))
rg <- rg %>% filter(pilot == 0) %>% left_join(rs[, c("a7", "treatment")], by = "a7") %>%
  left_join(tr[, c("compound1", "trstat")], by = "compound1")
rg$trstat[is.na(rg$trstat)] <- "notinroll"
cat("639/654 by trstat\n"); print(table(rg$a7[rg$a7 %in% c(639, 654, 374)], rg$trstat[rg$a7 %in% c(639, 654, 374)]))
# payments collector codes in candidate nbhds vs arms
tpa <- tp %>% left_join(rs[, c("a7", "treatment")], by = "a7")
cat("colcode ranges by treatment\n"); print(tapply(tpa$colcode, tpa$treatment, function(x) paste(range(x, na.rm = TRUE), collapse = "-")))
print(table(tpa$colcode[tpa$a7 %in% c(639, 654, 374)], tpa$a7[tpa$a7 %in% c(639, 654, 374)]))
cat("rs rows for 639/654/374\n"); print(as.data.frame(rs[rs$a7 %in% c(639, 654, 374), ]))
cat("chef_code/agent codes CXL nbhds\n"); print(as.data.frame(rs[rs$treatment == 4, ]))

s <- rg %>% filter(trstat == "amount") %>% distinct(compound1, .keep_all = TRUE)
s$d <- as.Date(s$start)
s$trt <- s$treatment
for (cand in c(639, 654)) {
  s$trt <- s$treatment; s$trt[s$a7 == cand] <- 2
  cat("cand", cand, ":"); print(table(s$trt))
}
s$trt <- s$treatment; s$trt[s$a7 == 639] <- 2
nbd <- s %>% group_by(a7) %>% summarise(nmin = min(d), nmed = as.Date(median(as.numeric(d)), origin = "1970-01-01"))
s <- s %>% left_join(nbd, by = "a7")
variant <- function(a, b, dvar, arm_first, label) {
  x <- s %>% filter(trt %in% c(a, b))
  dd <- x[[dvar]]
  if (arm_first == "prop") { f <- tapply(x$d, x$trt, min); l <- tapply(x$d, x$trt, max) }
  else { f <- tapply(x$nmin, x$trt, min); l <- tapply(x$nmin, x$trt, max) }
  ms <- mean(as.numeric(f)); me <- mean(as.numeric(l))
  keep <- as.numeric(dd) >= ms & as.numeric(dd) <= me
  cat(sprintf("%-10s %-5s %-5s first=%s last=%s mid=[%s,%s] N=%d (of %d) clusters=%d (of %d)\n", label, dvar, arm_first,
              paste(as.Date(f, origin = "1970-01-01"), collapse = "/"), paste(as.Date(l, origin = "1970-01-01"), collapse = "/"),
              as.Date(ms, origin = "1970-01-01"), as.Date(me, origin = "1970-01-01"),
              sum(keep), nrow(x), length(unique(x$a7[keep])), length(unique(x$a7))))
}
for (dv in c("d", "nmin", "nmed")) for (af in c("prop", "nb")) {
  variant(1, 2, dv, af, "LocCen"); variant(1, 3, dv, af, "CLICen")
}
cat("targets: LocCen 27764/213 of 28872/221 ; CLICen 20636/165\n")
