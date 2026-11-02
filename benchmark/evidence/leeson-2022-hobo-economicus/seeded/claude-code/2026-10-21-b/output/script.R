suppressPackageStartupMessages({library(readr); library(dplyr); library(fixest); library(car)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/seeded/2026-10-21-b/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"
rd <- function(f) read_csv(file.path(D, f), show_col_types = FALSE)
# encode metro -> metroid (alphabetical within each file, as Stata's encode)
enc <- function(d) { d$metroid <- as.integer(factor(d$metro, levels = sort(unique(d$metro)))); d }
visits <- enc(rd("metrovisitslog.csv")) %>%
  mutate(day = as.Date(date, format = "%m/%d/%Y"),
         month = as.integer(format(day, "%m")), year = as.integer(format(day, "%Y")))
pass <- enc(rd("passersby.csv")) %>% select(metroid, month, year, passersby)
serv <- rd("service.csv") %>% filter(!is.na(metro) & metro != "") %>% enc() %>%
  transmute(metroid, service = as.integer(servicemin <= 10))
shut <- rd("shuttle.csv") %>% filter(!is.na(metro) & metro != "") %>% enc() %>%
  transmute(metroid, shuttle = as.integer(shuttlemin <= 10))
fr <- enc(rd("friendliness.csv")) %>%
  mutate(friendly = case_when(passresp5 == 1 ~ 5, passresp4 == 1 ~ 4, passresp3 == 1 ~ 3,
                              passresp2 == 1 ~ 2, passresp1 == 1 ~ 1, TRUE ~ NA_real_)) %>%
  group_by(metroid) %>% summarise(friendly = mean(friendly, na.rm = TRUE), .groups = "drop")
sv <- visits %>% left_join(pass, by = c("metroid", "month", "year")) %>%
  left_join(serv, by = "metroid") %>% left_join(shut, by = "metroid") %>%
  left_join(fr, by = "metroid") %>%
  mutate(subsample = as.integer(metroid %in% c(9, 10, 14, 17, 18)), dayf = factor(day))
cat("rows:", nrow(sv), " missing passersby:", sum(is.na(sv$passersby)), "\n")
cat("subsample stations:", paste(sort(unique(sv$metro[sv$subsample == 1])), collapse = "; "), "\n")
m1 <- feols(panhandlers ~ passersby + friendly + shuttle + service | dayf, data = sv,
            cluster = ~metroid, fixef.rm = "none")
m2 <- feols(panhandlers ~ passersby + friendly + shuttle + service | dayf, data = sv[sv$subsample == 1, ],
            cluster = ~metroid, fixef.rm = "none")
print(summary(m1)); print(summary(m2))
rc <- rd("receipts.csv") %>% mutate(hourlydonations = 60 * donations / minutes,
                                    hourlydollars = 60 * (cash + inkind) / minutes,
                                    metro = factor(metro))
bf <- function(y) { d <- rc[!is.na(rc[[y]]), ]; r <- leveneTest(d[[y]] ~ d$metro, center = median); print(r); list(W = r$`F value`[1], n = nrow(d)) }
bfd <- bf("hourlydonations"); bfl <- bf("hourlydollars")
ow <- function(y) { d <- rc[!is.na(rc[[y]]), ]; a <- summary(aov(d[[y]] ~ d$metro)); print(a); a[[1]]$`F value`[1] }
fd <- ow("hourlydonations"); fl <- ow("hourlydollars")
cat(sprintf("N donations=%d, N dollars=%d\n", bfd$n, bfl$n))
cat(sprintf("RESULT:passersby_full_sample=%.6f\n", coef(m1)["passersby"]))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", coef(m2)["passersby"]))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", coef(m1)["friendly"]))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", coef(m1)["shuttle"]))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", coef(m2)["shuttle"]))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bfd$W))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bfl$W))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", fd))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", fl))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
