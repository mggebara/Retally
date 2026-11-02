# Leeson (2022) "Hobo Economicus": reproduction of Table 2 regressions and Table 3-4 tests
#
# Translates the authors' Stata scripts (1_dataprep.do, 2_analysis.do) into R.
# Station IDs are built as Stata's `encode` would build them: each file is
# encoded separately in byte order, and the files are merged on that ID.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"

# Mimic Stata `encode`: number the distinct non-empty strings in sorted
# (byte-order) sequence. radix sorting gives C-locale order like Stata.
encode <- function(x) {
  lv <- sort(unique(x[!is.na(x) & x != ""]), method = "radix")
  match(x, lv)
}

# ---------------- Station-visit data ----------------
visits <- read_csv(file.path(base, "metrovisitslog.csv"), show_col_types = FALSE)
visits <- visits %>%
  mutate(metroid = encode(metro),
         day = mdy(date),
         month = month(day),
         year = year(day))

pass <- read_csv(file.path(base, "passersby.csv"), show_col_types = FALSE)
pass <- pass %>%
  mutate(metroid = encode(metro),
         month = as.numeric(month),
         year = as.numeric(year),
         passersby = as.numeric(passersby)) %>%
  select(metroid, month, year, passersby)

# Proximity dummies. A missing walking time counts as 0 here, because Stata
# evaluates missing <= 10 as false.
serv <- read_csv(file.path(base, "service.csv"), show_col_types = FALSE)
serv <- serv[, 1:3]
serv <- serv %>% filter(!is.na(metro) & metro != "")
serv <- serv %>%
  mutate(metroid = encode(metro),
         servicemin = suppressWarnings(as.numeric(servicemin)),
         service = as.numeric(!is.na(servicemin) & servicemin <= 10)) %>%
  select(metroid, service)

shut <- read_csv(file.path(base, "shuttle.csv"), show_col_types = FALSE)
shut <- shut[, 1:3]
shut <- shut %>% filter(!is.na(metro) & metro != "")
shut <- shut %>%
  mutate(metroid = encode(metro),
         shuttlemin = suppressWarnings(as.numeric(shuttlemin)),
         shuttle = as.numeric(!is.na(shuttlemin) & shuttlemin <= 10)) %>%
  select(metroid, shuttle)

# Friendliness: each passerby's friendliest response (highest category coded
# 1), averaged by station.
fr <- read_csv(file.path(base, "friendliness.csv"), show_col_types = FALSE)
fr <- fr %>% mutate(metroid = encode(metro))
f <- rep(NA_real_, nrow(fr))
for (k in 5:1) {
  v <- suppressWarnings(as.numeric(fr[[paste0("passresp", k)]]))
  f[is.na(f) & !is.na(v) & v == 1] <- k
}
fr$friendly <- f
stfr <- fr %>%
  group_by(metroid) %>%
  summarise(friendly = mean(friendly, na.rm = TRUE), .groups = "drop")

# Merge on encoded station ID, as the Stata code does. Left joins suffice:
# using-only rows that Stata's merge would add have missing panhandlers and
# drop out of the regression anyway.
sv <- visits %>%
  left_join(pass, by = c("metroid", "month", "year")) %>%
  left_join(serv, by = "metroid") %>%
  left_join(shut, by = "metroid") %>%
  left_join(stfr, by = "metroid")

# Five-station subsample, using the Stata metroid codes
sv$subsample <- as.numeric(sv$metroid %in% c(9, 10, 14, 17, 18))
sv$dayf <- factor(as.character(sv$day))

# ---------------- Table 2 ----------------
# OLS with date fixed effects, SEs clustered by station. fixef.rm = "none"
# keeps singleton dates, matching Stata's i.day dummies.
m1 <- feols(panhandlers ~ passersby + friendly + shuttle + service | dayf,
            data = sv, cluster = ~metroid, fixef.rm = "none")
m2 <- feols(panhandlers ~ passersby + friendly + shuttle + service | dayf,
            data = sv[sv$subsample == 1, ], cluster = ~metroid, fixef.rm = "none")

print(summary(m1))
print(summary(m2))

getc <- function(m, v) {
  cc <- coef(m)
  if (v %in% names(cc)) cc[[v]] else NA
}

# ---------------- Receipts ----------------
rc <- read_csv(file.path(base, "receipts.csv"), show_col_types = FALSE)
rc <- rc %>%
  mutate(donations = as.numeric(donations),
         minutes = as.numeric(minutes),
         cash = suppressWarnings(as.numeric(cash)),
         inkind = suppressWarnings(as.numeric(inkind)),
         hourlydonations = 60 * donations / minutes,
         hourlydollars = 60 * (cash + inkind) / minutes)

# Brown-Forsythe W50 (Table 3): one-way ANOVA F on absolute deviations from
# the group median.
bf_test <- function(y, g) {
  ok <- !is.na(y) & !is.na(g)
  y <- y[ok]
  g <- factor(g[ok])
  med <- ave(y, g, FUN = median)
  z <- abs(y - med)
  a <- anova(lm(z ~ g))
  c(F = a$`F value`[1], p = a$`Pr(>F)`[1], n = length(y))
}

# One-way ANOVA (Table 4)
anova_test <- function(y, g) {
  ok <- !is.na(y) & !is.na(g)
  y <- y[ok]
  g <- factor(g[ok])
  a <- anova(lm(y ~ g))
  c(F = a$`F value`[1], p = a$`Pr(>F)`[1], n = length(y))
}

bf_d <- bf_test(rc$hourlydonations, rc$metro)
bf_m <- bf_test(rc$hourlydollars, rc$metro)
an_d <- anova_test(rc$hourlydonations, rc$metro)
an_m <- anova_test(rc$hourlydollars, rc$metro)

print(rbind(bf_d, bf_m, an_d, an_m))

# ---------------- Results ----------------
cat(sprintf("RESULT:passersby_full_sample=%.6f\n", getc(m1, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", getc(m2, "passersby")))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", getc(m1, "friendly")))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", getc(m1, "shuttle")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", getc(m2, "shuttle")))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf_d[["F"]]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf_m[["F"]]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", an_d[["F"]]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", an_m[["F"]]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))