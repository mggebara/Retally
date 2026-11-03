suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"
rd <- function(f) as.data.frame(read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 10000))

visits <- rd("metrovisitslog.csv")
pass   <- rd("passersby.csv")
friend <- rd("friendliness.csv")
shut   <- rd("shuttle.csv")
serv   <- rd("service.csv")
rec    <- rd("receipts.csv")

num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(readr::parse_number(as.character(x)))
}
normkey <- function(x) {
  x <- tolower(as.character(x))
  x <- gsub("&", "and", x)
  x <- gsub("station", "", x)
  gsub("[^a-z0-9]", "", x)
}
pdate <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.numeric(x)) {
    if (all(x[!is.na(x)] > 15000 & x[!is.na(x)] < 30000)) return(as.Date(x, origin = "1960-01-01"))
    if (all(x[!is.na(x)] > 19000000)) return(as.Date(as.character(x), format = "%Y%m%d"))
  }
  d <- suppressWarnings(as.Date(parse_date_time(as.character(x),
         orders = c("mdy", "ymd", "dmy", "mdY", "dbY", "dmY", "Ymd HMS", "mdy HMS"), quiet = TRUE)))
  d
}
# map each key in 'from' to a key in 'to'
matchkeys <- function(from, to) {
  to <- unique(to)
  sapply(from, function(k) {
    if (is.na(k)) return(NA_character_)
    if (k %in% to) return(k)
    p <- to[startsWith(to, k) | startsWith(k, to)]
    if (length(p) == 1) return(p)
    if (length(p) > 1) return(p[which.min(abs(nchar(p) - nchar(k)))])
    d <- adist(k, to)[1, ]
    if (min(d) <= max(3, 0.35 * nchar(k))) return(to[which.min(d)])
    NA_character_
  }, USE.NAMES = FALSE)
}

# ---------------- Visits ----------------
visits$panhandlers <- num(visits$panhandlers)
visits$vdate <- pdate(visits$date)
visits$mkey <- normkey(visits$metro)
visits$month <- month(visits$vdate)
visits$year <- year(visits$vdate)
vkeys <- unique(visits$mkey)
is_gt <- grepl("georgetown|wisconsin", vkeys)

# ---------------- Passersby ----------------
pass$pkey <- normkey(pass$metro)
pm <- pass$month
if (!is.numeric(pm)) {
  pmn <- suppressWarnings(as.numeric(as.character(pm)))
  if (all(is.na(pmn))) pmn <- match(tolower(substr(trimws(as.character(pm)), 1, 3)), tolower(month.abb))
  pm <- pmn
}
pass$month <- as.integer(pm)
py <- num(pass$year); py <- ifelse(py < 100, py + 2000, py)
pass$year <- as.integer(py)
pass$passersby <- num(pass$passersby)
pkeys <- unique(pass$pkey)
foggy <- pkeys[grepl("foggy", pkeys)][1]
map_p <- matchkeys(vkeys, pkeys)
for (i in seq_along(vkeys)) {
  if (is_gt[i] && !(vkeys[i] %in% pkeys)) map_p[i] <- foggy
}
visits$pkey <- map_p[match(visits$mkey, vkeys)]
pass_agg <- pass %>% group_by(pkey, month, year) %>% summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop")
visits <- visits %>% left_join(pass_agg, by = c("pkey", "month", "year"))
mpass <- mean(visits$passersby, na.rm = TRUE)
if (is.finite(mpass) && mpass > 5000) visits$passersby <- visits$passersby / 1000

# ---------------- Friendliness ----------------
rcols <- grep("^passresp", names(friend), value = TRUE)
R <- sapply(rcols, function(cc) num(friend[[cc]]))
if (is.null(dim(R))) R <- matrix(R, nrow = 1)
friend$best <- apply(R, 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))
friend$fkey <- normkey(friend$metro)
fr_st <- friend %>% filter(!is.na(best)) %>% group_by(fkey) %>% summarise(friendliness = mean(best), .groups = "drop")
map_f <- matchkeys(vkeys, fr_st$fkey)
visits$friendliness <- fr_st$friendliness[match(map_f[match(visits$mkey, vkeys)], fr_st$fkey)]

# ---------------- Shuttle / service ----------------
shut$skey <- normkey(shut$metro)
shut$shuttle <- as.numeric(num(shut$shuttlemin) <= 10)
map_s <- matchkeys(vkeys, shut$skey)
visits$shuttle <- shut$shuttle[match(map_s[match(visits$mkey, vkeys)], shut$skey)]

serv$skey <- normkey(serv$metro)
serv$service <- as.numeric(num(serv$servicemin) <= 10)
map_v <- matchkeys(vkeys, serv$skey)
visits$service <- serv$service[match(map_v[match(visits$mkey, vkeys)], serv$skey)]

visits$date_f <- factor(as.character(visits$vdate))
visits$date_f[is.na(visits$vdate)] <- NA

five_pat <- "farragutnorth|farragutwest|gallery|mcpherson|metrocenter"
visits$five <- grepl(five_pat, visits$mkey)

fml <- panhandlers ~ passersby + friendliness + shuttle + service | date_f
m1 <- feols(fml, data = visits, cluster = ~metro)
m2 <- feols(fml, data = visits[visits$five, ], cluster = ~metro)

gc <- function(m, v) { b <- coef(m); if (v %in% names(b)) unname(b[v]) else NA_real_ }

# ---------------- Receipts ----------------
rec$donations <- num(rec$donations)
rec$minutes <- num(rec$minutes)
rec$cash <- num(rec$cash)
rec$inkind <- num(rec$inkind)
rec$st <- factor(normkey(rec$metro))
rec$don_hr <- rec$donations / rec$minutes * 60
rec$dollars <- ifelse(is.na(rec$cash) & is.na(rec$inkind), NA_real_,
                      ifelse(is.na(rec$cash), 0, rec$cash) + ifelse(is.na(rec$inkind), 0, rec$inkind))
rec$dol_hr <- rec$dollars / rec$minutes * 60

bf <- function(y, g) {
  ok <- is.finite(y) & !is.na(g); y <- y[ok]; g <- droplevels(factor(g[ok]))
  med <- ave(y, g, FUN = median)
  z <- abs(y - med)
  unname(summary(aov(z ~ g))[[1]][1, "F value"])
}
af <- function(y, g) {
  ok <- is.finite(y) & !is.na(g); y <- y[ok]; g <- droplevels(factor(g[ok]))
  unname(summary(aov(y ~ g))[[1]][1, "F value"])
}

bf_d <- bf(rec$don_hr, rec$st)
bf_c <- bf(rec$dol_hr, rec$st)
af_d <- af(rec$don_hr, rec$st)
af_c <- af(rec$dol_hr, rec$st)

out <- function(n, v) cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 10)))
out("passersby_full_sample", gc(m1, "passersby"))
out("passersby_five_station_subsample", gc(m2, "passersby"))
out("friendliness_full_sample", gc(m1, "friendliness"))
out("shuttle_stop_full_sample", gc(m1, "shuttle"))
out("shuttle_stop_five_station_subsample", gc(m2, "shuttle"))
out("brown_forsythe_donations_per_hour", bf_d)
out("brown_forsythe_dollars_per_hour", bf_c)
out("anova_f_donations_per_hour", af_d)
out("anova_f_dollars_per_hour", af_c)
out("station_visits_full_sample", nobs(m1))
out("station_visits_five_station_subsample", nobs(m2))
