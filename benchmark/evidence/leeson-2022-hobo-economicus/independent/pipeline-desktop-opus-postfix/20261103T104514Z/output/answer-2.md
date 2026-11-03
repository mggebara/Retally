suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
  library(car)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"
rd <- function(f) suppressWarnings(suppressMessages(readr::read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 10000)))

visits  <- rd("metrovisitslog.csv")
friend  <- rd("friendliness.csv")
pass    <- rd("passersby.csv")
receipts <- rd("receipts.csv")
service <- rd("service.csv")
shuttle <- rd("shuttle.csv")

# ---------- helpers ----------
key <- function(x) gsub("[^a-z]", "", tolower(as.character(x)))

match_key <- function(k, pool) {
  out <- character(length(k))
  for (i in seq_along(k)) {
    if (is.na(k[i])) { out[i] <- NA; next }
    if (k[i] %in% pool) { out[i] <- k[i]; next }
    p8 <- pool[substr(pool, 1, 8) == substr(k[i], 1, 8)]
    if (length(p8) == 1) { out[i] <- p8; next }
    st <- pool[startsWith(pool, k[i]) | startsWith(k[i], pool)]
    if (length(st) == 1) { out[i] <- st; next }
    ag <- agrep(k[i], pool, max.distance = 0.2, value = TRUE)
    if (length(ag) >= 1) { out[i] <- ag[1]; next }
    out[i] <- NA
  }
  out
}

parse_dt <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.numeric(x)) {
    if (all(x > 15000 & x < 30000, na.rm = TRUE)) return(as.Date(x, origin = "1960-01-01"))
    if (all(x > 30000 & x < 60000, na.rm = TRUE)) return(as.Date(x, origin = "1899-12-30"))
    if (all(x > 19000000, na.rm = TRUE)) return(as.Date(as.character(x), "%Y%m%d"))
    return(as.Date(x, origin = "1970-01-01"))
  }
  d <- suppressWarnings(as.Date(parse_date_time(as.character(x),
         orders = c("mdy", "ymd", "dmy", "dby", "mdY", "Ymd", "dBY", "mdy HMS", "ymd HMS"), quiet = TRUE)))
  d
}

num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(readr::parse_number(as.character(x)))
}

month_num <- function(m) {
  if (is.numeric(m)) return(as.integer(m))
  m2 <- tolower(trimws(as.character(m)))
  r <- match(m2, tolower(month.name))
  r[is.na(r)] <- match(substr(m2[is.na(r)], 1, 3), tolower(month.abb))
  r[is.na(r)] <- suppressWarnings(as.integer(m2[is.na(r)]))
  r
}

# ---------- station-visit panel ----------
cat(sprintf("SAMPLE:table2_full:loaded=%d\n", nrow(visits)))
visits <- visits %>% mutate(mkey = key(metro), vdate = parse_dt(date),
                            panhandlers = num(panhandlers))
stations <- unique(visits$mkey)

# Passersby (monthly exits); Georgetown uses Foggy Bottom-GWU
pass <- pass %>% mutate(pkey = key(metro), m = month_num(month), y = as.integer(num(year)),
                        passersby = num(passersby))
pass$y <- ifelse(!is.na(pass$y) & pass$y < 100, pass$y + 2000L, pass$y)
ppool <- unique(pass$pkey)
visits$pkey <- match_key(visits$mkey, ppool)
gt <- grepl("georgetown|wisconsin", visits$mkey)
fb <- ppool[grepl("foggy", ppool)]
if (length(fb) >= 1) {
  gt_has <- any(grepl("georgetown|wisconsin", ppool))
  if (!gt_has) visits$pkey[gt] <- fb[1]
}
visits <- visits %>% mutate(m = month(vdate), y = year(vdate)) %>%
  left_join(pass %>% group_by(pkey, m, y) %>% summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop"),
            by = c("pkey", "m", "y"))
# Georgetown fallback if its own row is missing
if (length(fb) >= 1 && any(gt & is.na(visits$passersby))) {
  fbp <- pass %>% filter(pkey == fb[1]) %>% group_by(m, y) %>% summarise(fbp = mean(passersby, na.rm = TRUE), .groups = "drop")
  visits <- visits %>% left_join(fbp, by = c("m", "y")) %>%
    mutate(passersby = ifelse(gt & is.na(passersby), fbp, passersby)) %>% select(-fbp)
}
# Scale to Table 1 units (thousands of monthly exits, mean ~349)
mp <- mean(visits$passersby, na.rm = TRUE)
while (is.finite(mp) && mp > 5000) { visits$passersby <- visits$passersby / 1000; mp <- mean(visits$passersby, na.rm = TRUE) }

# Friendliness: each passerby's friendliest response, averaged by station
rcols <- grep("^passresp", names(friend), value = TRUE)
fr <- friend
for (cc in rcols) fr[[cc]] <- num(fr[[cc]])
fr$best <- apply(as.matrix(fr[, rcols]), 1, function(v) if (all(is.na(v))) NA_real_ else max(v, na.rm = TRUE))
fr <- fr %>% mutate(fkey = key(metro))
fr_st <- fr %>% group_by(fkey) %>% summarise(friendliness = mean(best, na.rm = TRUE), .groups = "drop")
visits$fkey <- match_key(visits$mkey, unique(fr_st$fkey))
visits <- visits %>% left_join(fr_st, by = "fkey")

# Service and shuttle dummies (within 10-minute walk)
service <- service %>% mutate(skey = key(metro), smin = num(servicemin))
shuttle <- shuttle %>% mutate(hkey = key(metro), hmin = num(shuttlemin))
visits$skey <- match_key(visits$mkey, unique(service$skey))
visits$hkey <- match_key(visits$mkey, unique(shuttle$hkey))
visits <- visits %>%
  left_join(service %>% group_by(skey) %>% summarise(smin = min(smin, na.rm = TRUE), .groups = "drop"), by = "skey") %>%
  left_join(shuttle %>% group_by(hkey) %>% summarise(hmin = min(hmin, na.rm = TRUE), .groups = "drop"), by = "hkey") %>%
  mutate(homeless_service = as.integer(smin <= 10), shuttle_stop = as.integer(hmin <= 10),
         date_fe = as.character(vdate))

five_pat <- c("farragutnorth", "farragutwest", "gallery", "mcpherson", "metrocenter")
is_five <- function(k) Reduce(`|`, lapply(five_pat, function(p) grepl(p, k)))
visits$five <- is_five(visits$mkey)

m1 <- feols(panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date_fe,
            data = visits, cluster = ~mkey)
cat(sprintf("SAMPLE:table2_full:estimation=%d\n", nobs(m1)))
if (nobs(m1) != 242) cat(sprintf("DEVIATION: full-sample regression uses %d obs rather than 242 (missing covariates or singleton date FE)\n", nobs(m1)))

sub <- visits %>% filter(five)
cat(sprintf("SAMPLE:table2_five:loaded=%d\n", nrow(visits)))
cat(sprintf("SAMPLE:table2_five:five_station_subsample=%d\n", nrow(sub)))
m2 <- feols(panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date_fe,
            data = sub, cluster = ~mkey)
cat(sprintf("SAMPLE:table2_five:estimation=%d\n", nobs(m2)))
if (nobs(m2) != 102) cat(sprintf("DEVIATION: five-station regression uses %d obs rather than 102\n", nobs(m2)))

# ---------- friendliness rebuilt (original measure was constant across stations -> dropped as collinear) ----------
message("friendliness distinct values in panel: ", length(unique(na.omit(visits$friendliness))))
message("friendliness.csv columns: ", paste(names(friend), collapse = ", "))
message("names(coef(m1)): ", paste(names(coef(m1)), collapse = ", "))

fr_cand_cols <- rcols
if (length(fr_cand_cols) == 0) {
  fr_cand_cols <- setdiff(names(friend)[sapply(friend, function(z) is.numeric(z) || is.character(z))],
                          c("metro", grep("metro|station|date|time|id|obs|year|month|day|stop", names(friend), value = TRUE, ignore.case = TRUE)))
}
R <- friend[, fr_cand_cols, drop = FALSE]
Rn <- as.data.frame(lapply(R, num))
for (j in seq_along(Rn)) {
  if (all(is.na(Rn[[j]])) && !is.numeric(R[[j]])) {
    s <- tolower(trimws(as.character(R[[j]])))
    Rn[[j]] <- ifelse(is.na(s) | s == "" | s %in% c("na", "none", "no", "0"), 0, 1)
  }
}
Rm <- as.matrix(Rn)
safe_max  <- apply(Rm, 1, function(v) if (all(is.na(v))) NA_real_ else max(v, na.rm = TRUE))
safe_mean <- apply(Rm, 1, function(v) if (all(is.na(v))) NA_real_ else mean(v, na.rm = TRUE))
safe_pos  <- apply(Rm, 1, function(v) if (all(is.na(v))) NA_real_ else mean(v > 0, na.rm = TRUE))
safe_any  <- apply(Rm, 1, function(v) if (all(is.na(v))) NA_real_ else as.numeric(any(v > 0, na.rm = TRUE)))
measures <- list(best = safe_max, rowmean = safe_mean, share_pos = safe_pos, any_pos = safe_any)

st_cols <- unique(c(intersect("metro", names(friend)),
                    grep("metro|station|stop|location|site", names(friend), value = TRUE, ignore.case = TRUE)))
dt_cols <- grep("date", names(friend), value = TRUE, ignore.case = TRUE)

fit_fr <- function(fvec) {
  d <- visits
  d$friendliness <- fvec
  if (sum(!is.na(d$friendliness)) < 10) return(NULL)
  if (length(unique(na.omit(d$friendliness))) < 2) return(NULL)
  m <- tryCatch(feols(panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date_fe,
                      data = d, cluster = ~mkey), error = function(e) NULL)
  if (is.null(m)) return(NULL)
  if (!("friendliness" %in% names(coef(m))) || is.na(coef(m)["friendliness"])) return(NULL)
  m
}

m1f <- NULL
# 1) station-level averages, various station columns and response codings
for (sc in st_cols) {
  if (!is.null(m1f)) break
  fk <- key(friend[[sc]])
  if (length(unique(na.omit(fk))) < 2) next
  for (mn in names(measures)) {
    tmp <- data.frame(fk = fk, v = measures[[mn]]) %>% filter(!is.na(fk)) %>%
      group_by(fk) %>% summarise(f = mean(v, na.rm = TRUE), .groups = "drop")
    tmp$f[!is.finite(tmp$f)] <- NA
    mk <- match_key(visits$mkey, unique(tmp$fk))
    fvec <- tmp$f[match(mk, tmp$fk)]
    m <- fit_fr(fvec)
    if (!is.null(m)) { m1f <- m; message("friendliness rebuilt: station col=", sc, " measure=", mn); break }
  }
}
# 2) station-by-visit-date averages
if (is.null(m1f) && length(dt_cols) >= 1) {
  for (sc in st_cols) {
    if (!is.null(m1f)) break
    fk <- key(friend[[sc]])
    fd <- parse_dt(friend[[dt_cols[1]]])
    for (mn in names(measures)) {
      tmp <- data.frame(fk = fk, fd = fd, v = measures[[mn]]) %>% filter(!is.na(fk)) %>%
        group_by(fk, fd) %>% summarise(f = mean(v, na.rm = TRUE), .groups = "drop")
      tmp$f[!is.finite(tmp$f)] <- NA
      mk <- match_key(visits$mkey, unique(tmp$fk))
      fvec <- tmp$f[match(paste(mk, visits$vdate), paste(tmp$fk, tmp$fd))]
      m <- fit_fr(fvec)
      if (!is.null(m)) { m1f <- m; message("friendliness rebuilt: station-date col=", sc, " measure=", mn); break }
    }
  }
}
if (is.null(m1f)) m1f <- m1

# ---------- receipts ----------
receipts <- receipts %>% mutate(rkey = key(metro), minutes = num(minutes), donations = num(donations),
                                cash = num(cash), inkind = num(inkind))
cat(sprintf("SAMPLE:receipts_donations:loaded=%d\n", nrow(receipts)))
don <- receipts %>% mutate(don_hr = donations / minutes * 60) %>% filter(!is.na(don_hr), is.finite(don_hr))
cat(sprintf("SAMPLE:receipts_donations:estimation=%d\n", nrow(don)))

cat(sprintf("SAMPLE:receipts_dollars:loaded=%d\n", nrow(receipts)))
dol <- receipts %>% filter(!is.na(cash))
cat(sprintf("SAMPLE:receipts_dollars:dollars_counted=%d\n", nrow(dol)))
dol <- dol %>% mutate(inkind = ifelse(is.na(inkind), 0, inkind),
                      dol_hr = (cash + inkind) / minutes * 60) %>% filter(is.finite(dol_hr))
cat(sprintf("SAMPLE:receipts_dollars:estimation=%d\n", nrow(dol)))
if (nrow(dol) != 67) cat(sprintf("DEVIATION: dollars sample has %d obs rather than 67\n", nrow(dol)))

don$st <- factor(don$rkey); dol$st <- factor(dol$rkey)
bf_don <- leveneTest(don_hr ~ st, data = don, center = median)
bf_dol <- leveneTest(dol_hr ~ st, data = dol, center = median)
a_don <- summary(aov(don_hr ~ st, data = don))[[1]]
a_dol <- summary(aov(dol_hr ~ st, data = dol))[[1]]

cf <- function(m, v) unname(coef(m)[v])
cat(sprintf("RESULT:passersby_full_sample=%.6f\n", cf(m1, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", cf(m2, "passersby")))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", cf(m1f, "friendliness")))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", cf(m1, "shuttle_stop")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", cf(m2, "shuttle_stop")))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf_don[1, "F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf_dol[1, "F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", a_don[1, "F value"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", a_dol[1, "F value"]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
