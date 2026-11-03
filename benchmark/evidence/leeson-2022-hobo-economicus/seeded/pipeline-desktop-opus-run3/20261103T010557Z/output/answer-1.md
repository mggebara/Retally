suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
  library(car)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"

num <- function(x) suppressWarnings(readr::parse_number(as.character(x)))
encode_id <- function(x) {
  x <- as.character(x)
  lv <- sort(unique(x[!is.na(x) & x != ""]), method = "radix")
  match(x, lv)
}

## ---- metro visits log ----
mv <- read_csv(file.path(base, "metrovisitslog.csv"), col_types = cols(.default = col_character()))
mv <- mv %>% filter(!is.na(metro), metro != "")
mv$metroid <- encode_id(mv$metro)
mv$day <- suppressWarnings(mdy(mv$date))
mv$month <- month(mv$day)
mv$year <- year(mv$day)
mv$panhandlers <- num(mv$panhandlers)

## ---- passersby ----
pb <- read_csv(file.path(base, "passersby.csv"), col_types = cols(.default = col_character()))
pb <- pb %>% filter(!is.na(metro), metro != "")
pb$metroid <- encode_id(pb$metro)
m_num <- suppressWarnings(as.numeric(pb$month))
if (all(is.na(m_num))) {
  m_num <- match(tolower(substr(trimws(pb$month), 1, 3)), tolower(month.abb))
}
pb$month <- m_num
pb$year <- num(pb$year)
pb$passersby <- num(pb$passersby)
pb <- pb %>% select(metroid, month, year, passersby) %>%
  distinct(metroid, month, year, .keep_all = TRUE)

## ---- service ----
sv <- read_csv(file.path(base, "service.csv"), col_types = cols(.default = col_character()))
sv <- sv %>% filter(!is.na(metro), metro != "")
sv$metroid <- encode_id(sv$metro)
sm <- num(sv$servicemin)
sv$service <- as.numeric(!is.na(sm) & sm <= 10)
sv <- sv %>% select(metroid, service) %>% distinct(metroid, .keep_all = TRUE)

## ---- shuttle ----
sh <- read_csv(file.path(base, "shuttle.csv"), col_types = cols(.default = col_character()))
sh <- sh %>% filter(!is.na(metro), metro != "")
sh$metroid <- encode_id(sh$metro)
shm <- num(sh$shuttlemin)
sh$shuttle <- as.numeric(!is.na(shm) & shm <= 10)
sh <- sh %>% select(metroid, shuttle) %>% distinct(metroid, .keep_all = TRUE)

## ---- friendliness ----
fr <- read_csv(file.path(base, "friendliness.csv"), col_types = cols(.default = col_character()))
fr <- fr %>% filter(!is.na(metro), metro != "")
fr$metroid <- encode_id(fr$metro)
for (k in 1:5) fr[[paste0("passresp", k)]] <- num(fr[[paste0("passresp", k)]])
fr$friendly <- NA_real_
for (k in 5:1) {
  v <- fr[[paste0("passresp", k)]]
  fr$friendly[is.na(fr$friendly) & !is.na(v) & v == 1] <- k
}
sf <- fr %>% group_by(metroid) %>% summarise(friendly = mean(friendly, na.rm = TRUE), .groups = "drop")
sf$friendly[is.nan(sf$friendly)] <- NA

## ---- station-visit data ----
st <- mv %>%
  left_join(pb, by = c("metroid", "month", "year")) %>%
  left_join(sv, by = "metroid") %>%
  left_join(sh, by = "metroid") %>%
  left_join(sf, by = "metroid")
st$subsample <- as.numeric(st$metroid %in% c(9, 10, 14, 17, 18))
st$dayf <- factor(as.character(st$day))

m1 <- feols(panhandlers ~ passersby + friendly + shuttle + service | dayf,
            data = st, cluster = ~metroid, fixef.rm = "none",
            ssc = ssc(adj = TRUE, fixef.K = "full", cluster.adj = TRUE))
m2 <- feols(panhandlers ~ passersby + friendly + shuttle + service | dayf,
            data = st[st$subsample == 1, ], cluster = ~metroid, fixef.rm = "none",
            ssc = ssc(adj = TRUE, fixef.K = "full", cluster.adj = TRUE))

## ---- receipts ----
rc <- read_csv(file.path(base, "receipts.csv"), col_types = cols(.default = col_character()))
rc <- rc %>% filter(!is.na(metro), metro != "")
rc$metro <- trimws(rc$metro)
rc$donations <- num(rc$donations)
rc$minutes <- num(rc$minutes)
rc$cash <- num(rc$cash)
rc$inkind <- num(rc$inkind)
rc$hourlydonations <- 60 * rc$donations / rc$minutes
rc$hourlydollars <- 60 * (rc$cash + rc$inkind) / rc$minutes
rc$metrof <- factor(rc$metro)

dA <- rc[!is.na(rc$hourlydonations) & is.finite(rc$hourlydonations), ]
dB <- rc[!is.na(rc$hourlydollars) & is.finite(rc$hourlydollars), ]
dA$metrof <- droplevels(dA$metrof)
dB$metrof <- droplevels(dB$metrof)

bfA <- leveneTest(hourlydonations ~ metrof, data = dA, center = median)
bfB <- leveneTest(hourlydollars ~ metrof, data = dB, center = median)

aA <- anova(lm(hourlydonations ~ metrof, data = dA))
aB <- anova(lm(hourlydollars ~ metrof, data = dB))

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

out("passersby_full_sample", coef(m1)["passersby"])
out("passersby_five_station_subsample", coef(m2)["passersby"])
out("friendliness_full_sample", coef(m1)["friendly"])
out("shuttle_stop_full_sample", coef(m1)["shuttle"])
out("shuttle_stop_five_station_subsample", coef(m2)["shuttle"])
out("brown_forsythe_donations_per_hour", bfA[1, "F value"])
out("brown_forsythe_dollars_per_hour", bfB[1, "F value"])
out("anova_f_donations_per_hour", aA[1, "F value"])
out("anova_f_dollars_per_hour", aB[1, "F value"])
out("station_visits_full_sample", nobs(m1))
out("station_visits_five_station_subsample", nobs(m2))
