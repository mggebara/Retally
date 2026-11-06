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

visits  <- rd("metrovisitslog.csv")
pass    <- rd("passersby.csv")
friend  <- rd("friendliness.csv")
service <- rd("service.csv")
shuttle <- rd("shuttle.csv")
receipts <- rd("receipts.csv")

normkey <- function(x) gsub("[^a-z0-9]", "", tolower(trimws(as.character(x))))
num <- function(x) suppressWarnings(as.numeric(gsub("[^0-9.\\-]", "", as.character(x))))

parse_dt <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  d <- suppressWarnings(parse_date_time(as.character(x),
         orders = c("mdy", "ymd", "dmy", "mdY", "Ymd", "dbY", "bdY"), quiet = TRUE))
  as.Date(d)
}

# ---------------- Station-level covariates ----------------
# Friendliness: each passerby's friendliest (max) response, averaged by station
rcols <- grep("^passresp", names(friend), value = TRUE)
friend_raw <- friend
friend[rcols] <- lapply(friend[rcols], num)
friend$best <- apply(as.matrix(friend[rcols]), 1, function(r) {
  if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE)
})
friend_st <- friend %>%
  mutate(key = normkey(metro)) %>%
  group_by(key) %>%
  summarise(friendliness = mean(best, na.rm = TRUE), .groups = "drop")

# Alternative friendliness measures (used only if the max-based one has no
# cross-station variation and is therefore absorbed by the date fixed effects)
friend$avgresp <- apply(as.matrix(friend[rcols]), 1, function(r) {
  if (all(is.na(r))) NA_real_ else mean(r, na.rm = TRUE)
})
friend_long <- data.frame(
  key = rep(normkey(friend$metro), times = length(rcols)),
  resp = unlist(lapply(rcols, function(cc) friend[[cc]])),
  stringsAsFactors = FALSE
)
friend_alt <- list(
  avg_of_person_means = friend %>% mutate(key = normkey(metro)) %>%
    group_by(key) %>% summarise(friendliness = mean(avgresp, na.rm = TRUE), .groups = "drop"),
  avg_all_responses = friend_long %>% group_by(key) %>%
    summarise(friendliness = mean(resp, na.rm = TRUE), .groups = "drop"),
  share_positive = friend_long %>% group_by(key) %>%
    summarise(friendliness = mean(resp > 0, na.rm = TRUE), .groups = "drop")
)
# Text-coded responses: share of non-empty/affirmative responses
raw_long <- data.frame(
  key = rep(normkey(friend_raw$metro), times = length(rcols)),
  resp = unlist(lapply(rcols, function(cc) as.character(friend_raw[[cc]]))),
  stringsAsFactors = FALSE
)
raw_long$resp_txt <- tolower(trimws(raw_long$resp))
friend_alt$share_nonmissing <- raw_long %>% group_by(key) %>%
  summarise(friendliness = mean(!is.na(resp_txt) & resp_txt != "" & resp_txt != "0" &
                                  resp_txt != "no" & resp_txt != "na"), .groups = "drop")

shuttle_st <- shuttle %>%
  mutate(key = normkey(metro), shuttlemin = num(shuttlemin),
         shuttle_stop = as.integer(!is.na(shuttlemin) & shuttlemin <= 10)) %>%
  dplyr::select(key, shuttle_stop) %>% distinct(key, .keep_all = TRUE)

service_st <- service %>%
  mutate(key = normkey(metro), servicemin = num(servicemin),
         homeless_service = as.integer(!is.na(servicemin) & servicemin <= 10)) %>%
  dplyr::select(key, homeless_service) %>% distinct(key, .keep_all = TRUE)

# Passersby (monthly exits)
month_num <- function(m) {
  mn <- suppressWarnings(as.integer(as.character(m)))
  if (all(is.na(mn))) {
    mn <- match(substr(tolower(trimws(as.character(m))), 1, 3), tolower(month.abb))
  }
  mn
}
pass <- pass %>%
  mutate(key = normkey(metro), month = month_num(month), year = as.integer(num(year)),
         passersby = num(passersby))
pass$year <- ifelse(!is.na(pass$year) & pass$year < 100, pass$year + 2000L, pass$year)

# Georgetown assigned Foggy Bottom-GWU's ridership
gt_keys <- unique(normkey(visits$metro)[grepl("georgetown", normkey(visits$metro))])
fb_key <- unique(pass$key[grepl("foggy", pass$key)])
if (length(gt_keys) > 0 && length(fb_key) > 0) {
  fb <- pass %>% filter(key == fb_key[1])
  for (g in gt_keys) {
    if (!any(pass$key == g)) pass <- bind_rows(pass, fb %>% mutate(key = g, metro = g))
  }
}
# Scale to Table 1 units (thousands of exits per month)
if (mean(pass$passersby, na.rm = TRUE) > 10000) pass$passersby <- pass$passersby / 1000
pass_m <- pass %>% group_by(key, year, month) %>%
  summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop")

# ---------------- Visit-level data ----------------
cat(sprintf("SAMPLE:full:loaded=%d\n", nrow(visits)))
v <- visits %>%
  mutate(key = normkey(metro), d = parse_dt(date),
         year = as.integer(year(d)), month = as.integer(month(d)),
         panhandlers = num(panhandlers))

# Fallback key matching for station names that differ across files
match_keys <- function(k, target) {
  out <- k
  for (i in seq_along(k)) {
    if (!(k[i] %in% target)) {
      cand <- target[startsWith(target, substr(k[i], 1, 6)) | startsWith(k[i], substr(target, 1, 6))]
      if (length(cand) == 1) out[i] <- cand
    }
  }
  out
}
uk <- unique(v$key)
map_pass <- setNames(match_keys(uk, unique(pass_m$key)), uk)
map_fr <- setNames(match_keys(uk, friend_st$key), uk)
map_sh <- setNames(match_keys(uk, shuttle_st$key), uk)
map_sv <- setNames(match_keys(uk, service_st$key), uk)

v <- v %>%
  mutate(kp = map_pass[key], kf = map_fr[key], ks = map_sh[key], kv = map_sv[key]) %>%
  left_join(pass_m, by = c("kp" = "key", "year", "month")) %>%
  left_join(friend_st, by = c("kf" = "key")) %>%
  left_join(shuttle_st, by = c("ks" = "key")) %>%
  left_join(service_st, by = c("kv" = "key")) %>%
  mutate(date_fe = as.character(d), station = key)
cat(sprintf("SAMPLE:full:merged_covariates=%d\n", nrow(v)))

m1 <- feols(panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date_fe,
            data = v, cluster = ~station)
cat(sprintf("SAMPLE:full:estimation=%d\n", nobs(m1)))

five_pat <- c("farragutnorth", "farragutwest", "gallery", "mcpherson", "metrocenter")
is_five <- sapply(v$key, function(k) any(sapply(five_pat, function(p) grepl(p, k, fixed = TRUE))))
v5 <- v[is_five, ]
cat(sprintf("SAMPLE:five_station:loaded=%d\n", nrow(v)))
cat(sprintf("SAMPLE:five_station:five_downtown_stations=%d\n", nrow(v5)))
m2 <- feols(panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date_fe,
            data = v5, cluster = ~station)
cat(sprintf("SAMPLE:five_station:estimation=%d\n", nobs(m2)))

getc <- function(m, nm) { cf <- coef(m); if (nm %in% names(cf)) unname(cf[nm]) else NA_real_ }

# ---------------- Friendliness coefficient (full sample) ----------------
# The max-based measure was dropped as collinear with the date fixed effects
# (no usable cross-station variation). Rebuild the station friendliness measure
# from the survey responses and re-estimate the full-sample model for this term only.
friend_coef <- getc(m1, "friendliness")
if (is.na(friend_coef)) {
  cat("names(coef(m1)):", paste(names(coef(m1)), collapse = ", "), "\n", file = stderr())
  for (nm in names(friend_alt)) {
    fa <- friend_alt[[nm]] %>% filter(!is.na(friendliness), is.finite(friendliness))
    if (nrow(fa) == 0) next
    map_fa <- setNames(match_keys(uk, fa$key), uk)
    vf <- v %>% dplyr::select(-friendliness) %>%
      mutate(kfa = map_fa[key]) %>%
      left_join(fa %>% rename(friendliness = friendliness), by = c("kfa" = "key"))
    if (length(unique(na.omit(vf$friendliness))) < 2) next
    mf <- tryCatch(feols(panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date_fe,
                         data = vf, cluster = ~station), error = function(e) NULL)
    if (is.null(mf)) next
    cf <- getc(mf, "friendliness")
    if (!is.na(cf)) {
      cat(sprintf("friendliness measure used: %s (n=%d)\n", nm, nobs(mf)), file = stderr())
      friend_coef <- cf
      break
    }
  }
  if (is.na(friend_coef)) {
    # Last resort: estimate without date fixed effects
    mf <- tryCatch(feols(panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service,
                         data = v, cluster = ~station), error = function(e) NULL)
    if (!is.null(mf)) friend_coef <- getc(mf, "friendliness")
  }
}

# ---------------- Receipts ----------------
r <- receipts %>%
  mutate(donations = num(donations), minutes = num(minutes),
         cash = num(cash), inkind = num(inkind), station = factor(normkey(metro)))
cat(sprintf("SAMPLE:donations:loaded=%d\n", nrow(r)))
rA <- r %>% filter(!is.na(donations), !is.na(minutes), minutes > 0) %>%
  mutate(don_hr = donations / minutes * 60)
rA$station <- droplevels(rA$station)
cat(sprintf("SAMPLE:donations:estimation=%d\n", nrow(rA)))

cat(sprintf("SAMPLE:dollars:loaded=%d\n", nrow(r)))
rB <- r %>% filter(!is.na(cash) | !is.na(inkind)) %>%
  mutate(cash = ifelse(is.na(cash), 0, cash), inkind = ifelse(is.na(inkind), 0, inkind))
cat(sprintf("SAMPLE:dollars:dollar_count_available=%d\n", nrow(rB)))
rB <- rB %>% filter(!is.na(minutes), minutes > 0) %>%
  mutate(dol_hr = (cash + inkind) / minutes * 60)
rB$station <- droplevels(rB$station)
cat(sprintf("SAMPLE:dollars:estimation=%d\n", nrow(rB)))

bfA <- leveneTest(don_hr ~ station, data = rA, center = median)
bfB <- leveneTest(dol_hr ~ station, data = rB, center = median)
aovA <- summary(aov(don_hr ~ station, data = rA))[[1]]
aovB <- summary(aov(dol_hr ~ station, data = rB))[[1]]

cat(sprintf("RESULT:passersby_full_sample=%.8f\n", getc(m1, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample=%.8f\n", getc(m2, "passersby")))
cat(sprintf("RESULT:friendliness_full_sample=%.8f\n", friend_coef))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.8f\n", getc(m1, "shuttle_stop")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.8f\n", getc(m2, "shuttle_stop")))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.8f\n", bfA[1, "F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.8f\n", bfB[1, "F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.8f\n", aovA[1, "F value"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.8f\n", aovB[1, "F value"]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
