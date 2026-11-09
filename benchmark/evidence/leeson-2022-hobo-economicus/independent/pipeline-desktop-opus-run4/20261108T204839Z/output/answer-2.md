suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
  library(car)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"
rd <- function(f) suppressMessages(readr::read_csv(file.path(base, f), show_col_types = FALSE))

visits <- rd("metrovisitslog.csv")
pass   <- rd("passersby.csv")
fr     <- rd("friendliness.csv")
rec    <- rd("receipts.csv")
serv   <- rd("service.csv")
shut   <- rd("shuttle.csv")

# Normalise station names; keep "metro" when it is part of "Metro Center"
norm <- function(x) {
  x <- tolower(as.character(x))
  x <- gsub("station|metrorail", "", x)
  x <- gsub("metro(?![^a-z]*cent)", "", x, perl = TRUE)
  gsub("[^a-z0-9]", "", x)
}

canon <- unique(norm(visits$metro))
canon <- canon[!is.na(canon) & canon != ""]

map_names <- function(x) {
  nx <- norm(x)
  out <- nx
  for (i in seq_along(nx)) {
    if (is.na(nx[i]) || nx[i] %in% canon) next
    hit <- canon[startsWith(canon, nx[i]) | startsWith(nx[i], canon)]
    if (length(hit) == 1) { out[i] <- hit; next }
    d <- adist(nx[i], canon)[1, ]
    j <- which.min(d)
    if (length(j) == 1 && d[j] <= max(3, 0.35 * nchar(nx[i]))) out[i] <- canon[j]
  }
  out
}

parse_dt <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  x <- as.character(x)
  suppressWarnings(as.Date(parse_date_time(x, orders = c("mdy", "ymd", "dmy", "mdY", "Ymd", "dbY", "bdY"))))
}

to_num <- function(x) suppressWarnings(as.numeric(as.character(x)))

# ---------------- Visits ----------------
visits <- visits %>%
  mutate(key = map_names(metro),
         d = parse_dt(date),
         panhandlers = to_num(panhandlers),
         mon = month(d), yr = year(d))

# ---------------- Passersby ----------------
mon_num <- function(m) {
  mn <- to_num(m)
  if (all(!is.na(mn[!is.na(m)]))) return(as.integer(mn))
  as.integer(match(substr(tolower(trimws(as.character(m))), 1, 3), tolower(month.abb)))
}
pass <- pass %>%
  mutate(key = map_names(metro),
         mon = mon_num(month),
         yr = as.integer(to_num(year)),
         yr = ifelse(!is.na(yr) & yr < 100, yr + 2000L, yr),
         passersby = to_num(gsub(",", "", as.character(passersby))))
pass <- pass %>% group_by(key, mon, yr) %>% summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop")

gt_key <- canon[grepl("georgetown|wisconsin", canon)]
fb_key <- unique(pass$key[grepl("foggy", pass$key)])
if (length(gt_key) >= 1 && length(fb_key) >= 1 && !any(pass$key %in% gt_key)) {
  for (g in gt_key) {
    add <- pass %>% filter(key == fb_key[1]) %>% mutate(key = g)
    pass <- bind_rows(pass, add)
  }
}
if (mean(pass$passersby, na.rm = TRUE) > 20000) pass$passersby <- pass$passersby / 1000

# ---------------- Friendliness ----------------
rcols <- grep("^passresp", names(fr), value = TRUE)
fr[rcols] <- lapply(fr[rcols], to_num)
fr$key <- map_names(fr$metro)
fr$best <- apply(as.matrix(fr[rcols]), 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))
frs <- fr %>% filter(!is.na(best)) %>% group_by(key) %>% summarise(friendliness = mean(best), .groups = "drop")

# If row-max is (near) constant across stations, rows are visits and columns are
# separate passersby: take each passerby's friendliest response, then average.
if (length(unique(round(frs$friendliness, 8))) <= 2 && length(rcols) > 1) {
  idx <- regmatches(rcols, gregexpr("[0-9]+", rcols))
  pid <- vapply(idx, function(z) if (length(z) >= 2) z[1] else paste0("c", paste(z, collapse = "_")), character(1))
  if (any(lengths(idx) >= 2)) {
    # multiple responses per passerby: max within passerby
    pb <- lapply(unique(pid), function(p) {
      cols <- rcols[pid == p]
      apply(as.matrix(fr[cols]), 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))
    })
    pbm <- do.call(cbind, pb)
  } else {
    pbm <- as.matrix(fr[rcols])
  }
  long <- data.frame(key = rep(fr$key, ncol(pbm)), v = as.vector(pbm))
  frs <- long %>% filter(!is.na(v)) %>% group_by(key) %>% summarise(friendliness = mean(v), .groups = "drop")
  cat("DEVIATION: Friendliness row-max was constant across stations; treated response columns as separate passersby and averaged each passerby's friendliest response by station\n")
}

# ---------------- Shuttle / service ----------------
shut <- shut %>% mutate(key = map_names(metro), shuttlemin = to_num(shuttlemin)) %>%
  group_by(key) %>% summarise(shuttle = as.integer(min(shuttlemin, na.rm = TRUE) <= 10), .groups = "drop")
serv <- serv %>% mutate(key = map_names(metro), servicemin = to_num(servicemin)) %>%
  group_by(key) %>% summarise(service = as.integer(min(servicemin, na.rm = TRUE) <= 10), .groups = "drop")

# ---------------- Merge ----------------
df <- visits %>%
  left_join(pass, by = c("key", "mon", "yr")) %>%
  left_join(frs, by = "key") %>%
  left_join(shut, by = "key") %>%
  left_join(serv, by = "key") %>%
  mutate(datef = factor(as.character(d)))

five_pat <- c("farragutnorth", "farragutwest", "galleryp", "chinatown", "mcpherson", "metrocent")
df$five <- sapply(df$key, function(k) !is.na(k) && grepl(paste(five_pat, collapse = "|"), k))

dfa <- df %>% filter(!is.na(panhandlers), !is.na(passersby), !is.na(friendliness), !is.na(shuttle), !is.na(service), !is.na(datef))
# Keep singleton date groups (as Stata's reg with i.date does) so N matches paper
m1 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | datef, data = dfa, cluster = ~key, fixef.rm = "none")
dfs <- dfa %>% filter(five)
m2 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | datef, data = dfs, cluster = ~key, fixef.rm = "none")

gc1 <- function(m, v) { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA_real_ }
gs1 <- function(m, v) { s <- sqrt(diag(vcov(m))); if (v %in% names(s)) unname(s[v]) else NA_real_ }

# ---------------- Receipts ----------------
rec <- rec %>%
  mutate(key = map_names(metro),
         donations = to_num(donations), minutes = to_num(minutes),
         cash = to_num(cash), inkind = to_num(inkind),
         donph = donations / minutes * 60)
dec <- tolower(trimws(as.character(rec$declinedoffer)))
declined <- !is.na(dec) & (dec %in% c("1", "yes", "y", "true", "t") | grepl("^decl", dec))
# dollars counted only for panhandlers who accepted the offer and had cash counted
dollars <- ifelse(is.na(rec$cash), NA_real_,
                  rec$cash + ifelse(is.na(rec$inkind), 0, rec$inkind))
dollars[declined] <- NA_real_
rec$dolph <- dollars / rec$minutes * 60
rec$station <- factor(rec$key)

ra <- rec %>% filter(is.finite(donph))
rb <- rec %>% filter(is.finite(dolph))

bf_a <- leveneTest(donph ~ station, data = ra, center = median)
bf_b <- leveneTest(dolph ~ station, data = rb, center = median)
av_a <- oneway.test(donph ~ station, data = ra, var.equal = TRUE)
av_b <- oneway.test(dolph ~ station, data = rb, var.equal = TRUE)
kw_a <- kruskal.test(donph ~ station, data = ra)
kw_b <- kruskal.test(dolph ~ station, data = rb)

out <- function(n, v) cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 8)))
out("passersby_full_sample", gc1(m1, "passersby"))
out("passersby_full_sample_se", gs1(m1, "passersby"))
out("passersby_five_station_subsample", gc1(m2, "passersby"))
out("passersby_five_station_subsample_se", gs1(m2, "passersby"))
out("friendliness_full_sample", gc1(m1, "friendliness"))
out("shuttle_stop_full_sample", gc1(m1, "shuttle"))
out("shuttle_stop_five_station_subsample", gc1(m2, "shuttle"))
out("brown_forsythe_donations_per_hour", bf_a[1, "F value"])
out("brown_forsythe_dollars_per_hour", bf_b[1, "F value"])
out("anova_f_donations_per_hour", unname(av_a$statistic))
out("anova_f_dollars_per_hour", unname(av_b$statistic))
out("kruskal_wallis_donations_per_hour", unname(kw_a$statistic))
out("kruskal_wallis_dollars_per_hour", unname(kw_b$statistic))
out("station_visits_full_sample", nobs(m1))
out("station_visits_five_station_subsample", nobs(m2))
out("receipts_n_donations", nrow(ra))
out("receipts_n_dollars", nrow(rb))
