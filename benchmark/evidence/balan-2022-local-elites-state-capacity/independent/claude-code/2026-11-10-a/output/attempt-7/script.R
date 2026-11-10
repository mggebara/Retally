# Exploratory 7: grid of time-window definitions vs observation/cluster counts (no estimates)
suppressMessages({library(haven); library(dplyr)})
options(width = 250)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rs <- zap_labels(read_dta(file.path(B, "admin_data/randomization_schedule.dta")))
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta")))
tr <- zap_labels(read_dta(file.path(B, "admin_data/taxroll_noPII.dta")))
tr$amt <- suppressWarnings(as.numeric(gsub("[^0-9]", "", tr$MontantIF)))
tr$amt[!grepl("FC", tr$MontantIF)] <- NA
s <- rg %>% filter(pilot == 0) %>% left_join(rs[, c("a7", "treatment", "month")], by = "a7") %>%
  inner_join(tr[!is.na(tr$amt), c("compound1", "amt")], by = "compound1") %>% distinct(compound1, .keep_all = TRUE)
s$trt <- s$treatment; s$trt[s$a7 == 654] <- 2
s$dstart <- as.numeric(as.Date(s$start)); s$dtoday <- as.numeric(s$today)
s$dtoday2 <- ifelse(is.na(s$dtoday), s$dstart, s$dtoday)
res <- list()
for (dv in c("dstart", "dtoday", "dtoday2")) {
  s$tp <- s[[dv]]
  nbt <- s %>% group_by(a7) %>% summarise(tmin = suppressWarnings(min(tp, na.rm = TRUE)), tmed = median(tp, na.rm = TRUE), tmax = suppressWarnings(max(tp, na.rm = TRUE)), .groups = "drop")
  s2 <- s %>% left_join(nbt, by = "a7")
  for (lev in c("tp", "tmin", "tmed", "tmax")) for (bnd in c("own", "nbmin")) for (cut in c("both", "end", "start")) for (rnd in c("exact", "floor")) {
    out <- c()
    for (b in c(2, 3)) {
      x <- s2 %>% filter(trt %in% c(1, b))
      t <- x[[lev]]; t[!is.finite(t)] <- NA
      bt <- if (bnd == "own") t else x$tmin
      bt[!is.finite(bt)] <- NA
      f <- tapply(bt, x$trt, min, na.rm = TRUE); l <- tapply(bt, x$trt, max, na.rm = TRUE)
      ms <- mean(f); me <- mean(l)
      if (rnd == "floor") { ms <- floor(ms); me <- floor(me) }
      keep <- !is.na(t)
      if (cut %in% c("both", "start")) keep <- keep & t >= ms
      if (cut %in% c("both", "end")) keep <- keep & t <= me
      out <- c(out, sum(keep), length(unique(x$a7[keep])))
    }
    res[[length(res) + 1]] <- data.frame(dv = dv, lev = lev, bnd = bnd, cut = cut, rnd = rnd, LC_N = out[1], LC_J = out[2], CC_N = out[3], CC_J = out[4])
  }
}
r <- bind_rows(res)
r$score <- abs(r$LC_J - 213) + abs(r$CC_J - 165) + abs(r$LC_N - 27764) / 200 + abs(r$CC_N - 20636) / 200
r <- r %>% arrange(score)
print(head(r, 40), row.names = FALSE)
cat("base sizes: LC", sum(s$trt %in% c(1, 2)), " CC", sum(s$trt %in% c(1, 3)), "\n")
