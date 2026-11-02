suppressMessages({library(readr);library(dplyr);library(fixest);library(car)})
set.seed(42)
B <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/blind/2026-11-02-c/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"
rd <- function(x) read_csv(file.path(B, x), show_col_types = FALSE)
v  <- rd("metrovisitslog.csv"); p <- rd("passersby.csv"); f <- rd("friendliness.csv")
r  <- rd("receipts.csv"); sv <- rd("service.csv"); sh <- rd("shuttle.csv")

# Friendliness: each passerby's friendliest (highest) response category; station average
fm <- as.matrix(f[, paste0("passresp", 1:5)])
f$friendliest <- apply(fm, 1, function(z) if (any(z == 1)) max(which(z == 1)) else NA)
fr <- f %>% group_by(metro) %>% summarise(friendliness = mean(friendliest, na.rm = TRUE))

# Station indicators: within a ten-minute walk
stn <- sh %>% transmute(metro, shuttle = as.integer(shuttlemin <= 10)) %>%
  inner_join(sv %>% transmute(metro, service = as.integer(servicemin <= 10)), by = "metro")

# Visits: passersby in month of visit (Georgetown already carries Foggy Bottom's counts in file)
v <- v %>% mutate(d = as.Date(date, "%m/%d/%Y"), month = as.integer(format(d, "%m")),
                  year = as.integer(format(d, "%Y")))
dat <- v %>% left_join(p, by = c("metro", "month", "year")) %>%
  left_join(fr, by = "metro") %>% left_join(stn, by = "metro")
cat("visits:", nrow(dat), " missing passersby:", sum(is.na(dat$passersby)),
    " missing friendliness:", sum(is.na(dat$friendliness)), "\n")

five <- c("Farragut North", "Farragut West", "Gallery Place", "McPherson Square", "Metro Center")
# OLS with date dummies (singleton dates retained, as in a plain dummy-variable regression)
m1 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | date, data = dat,
            cluster = ~metro, fixef.rm = "none")
m2 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | date,
            data = filter(dat, metro %in% five), cluster = ~metro, fixef.rm = "none")
l1 <- lm(panhandlers ~ passersby + friendliness + shuttle + service + factor(date), data = dat)
l2 <- lm(panhandlers ~ passersby + friendliness + shuttle + service + factor(date), data = filter(dat, metro %in% five))
print(rbind(coef(l1)[2:5], coef(m1))); print(rbind(coef(l2)[2:5], coef(m2)))
print(summary(m1)); print(summary(m2))
cat("adj R2:", r2(m1, "ar2"), r2(m2, "ar2"), "\n")

# Receipts
r <- r %>% mutate(don_hr = donations / minutes * 60,
                  dol_hr = (cash + inkind) / minutes * 60, metro = factor(metro))
rd2 <- filter(r, !is.na(dol_hr))
cat("donations obs:", nrow(r), " dollars obs:", nrow(rd2), "\n")
print(r %>% group_by(metro) %>% summarise(n = n(), m = mean(don_hr), s = sd(don_hr)))
print(rd2 %>% group_by(metro) %>% summarise(n = n(), m = mean(dol_hr), s = sd(dol_hr)))
bf1 <- leveneTest(don_hr ~ metro, data = r, center = median)
bf2 <- leveneTest(dol_hr ~ metro, data = rd2, center = median)
a1 <- summary(aov(don_hr ~ metro, data = r))[[1]]
a2 <- summary(aov(dol_hr ~ metro, data = rd2))[[1]]
print(bf1); print(bf2); print(a1); print(a2)

out <- c(passersby_full_sample = coef(m1)[["passersby"]],
         passersby_five_station_subsample = coef(m2)[["passersby"]],
         friendliness_full_sample = coef(m1)[["friendliness"]],
         shuttle_stop_full_sample = coef(m1)[["shuttle"]],
         shuttle_stop_five_station_subsample = if ("shuttle" %in% names(coef(m2))) coef(m2)[["shuttle"]] else NA,
         brown_forsythe_donations_per_hour = bf1[1, "F value"],
         brown_forsythe_dollars_per_hour = bf2[1, "F value"],
         anova_f_donations_per_hour = a1[1, "F value"],
         anova_f_dollars_per_hour = a2[1, "F value"],
         station_visits_full_sample = nobs(l1),
         station_visits_five_station_subsample = nobs(l2))
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
