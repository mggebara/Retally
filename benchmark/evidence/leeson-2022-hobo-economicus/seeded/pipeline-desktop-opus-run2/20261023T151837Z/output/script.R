suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(sandwich)
  library(lmtest)
  library(car)
})

set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"

# Stata's encode: codes assigned in sorted (byte-order) order of the distinct strings
encode <- function(x) {
  lev <- sort(unique(x[!is.na(x) & x != ""]), method = "radix")
  match(x, lev)
}
to_num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(readr::parse_number(as.character(x)))
}
parse_mdy <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  d <- suppressWarnings(as.Date(parse_date_time(as.character(x), orders = c("mdy", "mdY", "mdy HMS", "mdy HM"))))
  d
}

## ---------------- Metro visits log ----------------
visits <- read_csv(file.path(base, "metrovisitslog.csv"), show_col_types = FALSE)
visits <- visits %>% filter(!is.na(metro))
visits$metroid <- encode(visits$metro)
visits$day <- parse_mdy(visits$date)
visits$month <- as.integer(month(visits$day))
visits$year <- as.integer(year(visits$day))
visits$panhandlers <- to_num(visits$panhandlers)

## ---------------- Passersby ----------------
pass <- read_csv(file.path(base, "passersby.csv"), show_col_types = FALSE)
pass <- pass %>% filter(!is.na(metro))
pass$metroid <- encode(pass$metro)
pass$month <- as.integer(to_num(pass$month))
pass$year <- as.integer(to_num(pass$year))
pass$passersby <- to_num(pass$passersby)
pass <- pass %>% select(metroid, month, year, passersby) %>%
  distinct(metroid, month, year, .keep_all = TRUE)

## ---------------- Service ----------------
serv <- read_csv(file.path(base, "service.csv"), show_col_types = FALSE)
serv <- serv[, 1:3]
serv <- serv %>% filter(!is.na(metro) & metro != "")
serv$metroid <- encode(serv$metro)
serv$servicemin <- to_num(serv$servicemin)
serv$service <- as.numeric(!is.na(serv$servicemin) & serv$servicemin <= 10)
serv <- serv %>% select(metroid, service) %>% distinct(metroid, .keep_all = TRUE)

## ---------------- Shuttle ----------------
shut <- read_csv(file.path(base, "shuttle.csv"), show_col_types = FALSE)
shut <- shut[, 1:3]
shut <- shut %>% filter(!is.na(metro) & metro != "")
shut$metroid <- encode(shut$metro)
shut$shuttlemin <- to_num(shut$shuttlemin)
shut$shuttle <- as.numeric(!is.na(shut$shuttlemin) & shut$shuttlemin <= 10)
shut <- shut %>% select(metroid, shuttle) %>% distinct(metroid, .keep_all = TRUE)

## ---------------- Friendliness ----------------
fr <- read_csv(file.path(base, "friendliness.csv"), show_col_types = FALSE)
fr <- fr %>% filter(!is.na(metro))
fr$metroid <- encode(fr$metro)
for (k in 1:5) fr[[paste0("passresp", k)]] <- to_num(fr[[paste0("passresp", k)]])
fr$friendly <- NA_real_
fr$friendly[!is.na(fr$passresp5) & fr$passresp5 == 1] <- 5
for (k in 4:1) {
  v <- fr[[paste0("passresp", k)]]
  idx <- is.na(fr$friendly) & !is.na(v) & v == 1
  fr$friendly[idx] <- k
}
stfr <- fr %>% group_by(metroid) %>%
  summarise(friendly = if (all(is.na(friendly))) NA_real_ else mean(friendly, na.rm = TRUE),
            .groups = "drop")

## ---------------- Combine (merges on encoded metroid, as in Stata) ----------------
sv <- visits %>%
  left_join(pass, by = c("metroid", "month", "year")) %>%
  left_join(serv, by = "metroid") %>%
  left_join(shut, by = "metroid") %>%
  left_join(stfr, by = "metroid")
sv$subsample <- as.numeric(sv$metroid %in% c(9, 10, 14, 17, 18))
sv$dayf <- factor(sv$day)

cat("Subsample stations:", paste(sort(unique(sv$metro[sv$subsample == 1])), collapse = "; "), "\n")

## ---------------- Table 2 ----------------
run_reg <- function(d) {
  d <- d %>% filter(!is.na(panhandlers), !is.na(passersby), !is.na(friendly),
                    !is.na(shuttle), !is.na(service), !is.na(dayf))
  d$dayf <- droplevels(d$dayf)
  m <- lm(panhandlers ~ passersby + friendly + shuttle + service + dayf, data = d)
  V <- vcovCL(m, cluster = ~metroid, type = "HC1")
  list(m = m, V = V, n = nobs(m), ar2 = summary(m)$adj.r.squared, d = d)
}

r1 <- run_reg(sv)
r2 <- run_reg(sv %>% filter(subsample == 1))
print(coeftest(r1$m, vcov = r1$V)[2:5, ])
print(coeftest(r2$m, vcov = r2$V)[2:5, ])

se <- function(r, v) { s <- sqrt(diag(r$V))[v]; if (is.na(s)) NA else s }
cf <- function(r, v) unname(coef(r$m)[v])

# standardised effect of passersby
std_eff <- function(r) cf(r, "passersby") * sd(r$d$passersby) / sd(r$d$panhandlers)

## ---------------- Receipts ----------------
rc <- read_csv(file.path(base, "receipts.csv"), show_col_types = FALSE)
rc <- rc %>% filter(!is.na(metro))
rc$donations <- to_num(rc$donations)
rc$minutes <- to_num(rc$minutes)
rc$cash <- to_num(rc$cash)
rc$inkind <- to_num(rc$inkind)
rc$hourlydonations <- 60 * rc$donations / rc$minutes
rc$hourlydollars <- 60 * (rc$cash + rc$inkind) / rc$minutes
rc$metrof <- factor(rc$metro)

tests <- function(y) {
  d <- rc[!is.na(rc[[y]]) & is.finite(rc[[y]]), ]
  d$metrof <- droplevels(d$metrof)
  f <- as.formula(paste(y, "~ metrof"))
  bf <- leveneTest(f, data = d, center = median)
  lv <- leveneTest(f, data = d, center = mean)
  a <- summary(aov(f, data = d))[[1]]
  kw <- kruskal.test(f, data = d)
  list(n = nrow(d),
       bf_w = bf[1, "F value"], bf_p = bf[1, "Pr(>F)"],
       lev_w = lv[1, "F value"], lev_p = lv[1, "Pr(>F)"],
       f = a[1, "F value"], f_p = a[1, "Pr(>F)"], df1 = a[1, "Df"], df2 = a[2, "Df"],
       kw = unname(kw$statistic), kw_p = kw$p.value)
}
tA <- tests("hourlydonations")
tB <- tests("hourlydollars")

## ---------------- Output ----------------
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

out("passersby_full_sample", cf(r1, "passersby"))
out("passersby_five_station_subsample", cf(r2, "passersby"))
out("friendliness_full_sample", cf(r1, "friendly"))
out("shuttle_stop_full_sample", cf(r1, "shuttle"))
out("shuttle_stop_five_station_subsample", cf(r2, "shuttle"))
out("brown_forsythe_donations_per_hour", tA$bf_w)
out("brown_forsythe_dollars_per_hour", tB$bf_w)
out("anova_f_donations_per_hour", tA$f)
out("anova_f_dollars_per_hour", tB$f)
out("station_visits_full_sample", r1$n)
out("station_visits_five_station_subsample", r2$n)

# supplementary
out("passersby_full_sample_se", se(r1, "passersby"))
out("passersby_five_station_subsample_se", se(r2, "passersby"))
out("friendliness_full_sample_se", se(r1, "friendly"))
out("shuttle_stop_full_sample_se", se(r1, "shuttle"))
out("shuttle_stop_five_station_subsample_se", se(r2, "shuttle"))
out("friendliness_five_station_subsample", cf(r2, "friendly"))
out("adj_r2_full_sample", r1$ar2)
out("adj_r2_five_station_subsample", r2$ar2)
out("std_effect_passersby_full_sample", std_eff(r1))
out("std_effect_passersby_five_station_subsample", std_eff(r2))
out("brown_forsythe_donations_per_hour_p", tA$bf_p)
out("brown_forsythe_dollars_per_hour_p", tB$bf_p)
out("anova_f_donations_per_hour_p", tA$f_p)
out("anova_f_dollars_per_hour_p", tB$f_p)
out("kruskal_wallis_donations_per_hour", tA$kw)
out("kruskal_wallis_dollars_per_hour", tB$kw)
out("n_donations_per_hour", tA$n)
out("n_dollars_per_hour", tB$n)