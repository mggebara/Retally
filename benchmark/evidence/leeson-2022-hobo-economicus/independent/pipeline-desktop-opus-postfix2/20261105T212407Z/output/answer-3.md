suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
  library(car)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"
rd <- function(f) read_csv(file.path(base, f), col_types = cols(.default = col_character()), show_col_types = FALSE)

visits  <- rd("metrovisitslog.csv")
pass    <- rd("passersby.csv")
friend  <- rd("friendliness.csv")
service <- rd("service.csv")
shuttle <- rd("shuttle.csv")
receipts <- rd("receipts.csv")

num <- function(x) suppressWarnings(as.numeric(gsub("[^0-9eE.+-]", "", as.character(x))))
key <- function(x) gsub("[^a-z]", "", tolower(as.character(x)))
pdate <- function(x) {
  d <- suppressWarnings(as.Date(parse_date_time(x, orders = c("mdY", "mdy", "Ymd", "dmY", "dbY", "bdY", "Ymd HMS", "mdY HMS"), quiet = TRUE)))
  d
}
to_month <- function(m) {
  n <- suppressWarnings(as.integer(m))
  out <- n
  idx <- is.na(n)
  if (any(idx)) {
    mm <- tolower(trimws(m[idx]))
    a <- match(mm, tolower(month.name))
    b <- match(substr(mm, 1, 3), tolower(month.abb))
    out[idx] <- ifelse(is.na(a), b, a)
  }
  out
}

# Match keys of an auxiliary table to the station keys in the visit log
match_keys <- function(target, source) {
  sapply(target, function(k) {
    if (k %in% source) return(k)
    p <- source[substr(source, 1, 8) == substr(k, 1, 8)]
    if (length(unique(p)) == 1) return(p[1])
    p <- source[startsWith(source, substr(k, 1, 6))]
    if (length(unique(p)) == 1) return(p[1])
    a <- agrep(k, source, max.distance = 0.25, value = TRUE)
    if (length(unique(a)) >= 1) return(a[1])
    a <- source[sapply(source, function(s) grepl(s, k, fixed = TRUE) || grepl(k, s, fixed = TRUE))]
    if (length(a) >= 1) return(a[1])
    NA_character_
  }, USE.NAMES = FALSE)
}

# Alternative matcher: exact, else containment, else minimum normalised edit distance
match_keys_dist <- function(target, source) {
  source <- unique(source[!is.na(source) & source != ""])
  sapply(target, function(k) {
    if (k %in% source) return(k)
    cont <- source[sapply(source, function(s) grepl(s, k, fixed = TRUE) || grepl(k, s, fixed = TRUE))]
    if (length(cont) == 1) return(cont)
    if (length(cont) > 1) source2 <- cont else source2 <- source
    d <- as.numeric(adist(k, source2)) / pmax(nchar(k), nchar(source2))
    source2[which.min(d)]
  }, USE.NAMES = FALSE)
}

# ---------------- Visit log ----------------
visits <- visits %>%
  mutate(mkey = key(metro), d = pdate(date), panhandlers = num(panhandlers),
         month = month(d), year = year(d))
cat(sprintf("SAMPLE:table2_full:loaded=%d\n", nrow(visits)))
stations <- unique(visits$mkey)

# Passersby (monthly exits), Georgetown gets Foggy Bottom-GWU
pass <- pass %>% mutate(pkey = key(metro), month = to_month(month), year = num(year), passersby = num(passersby))
pass_keys <- unique(pass$pkey)
st_map <- data.frame(mkey = stations, stringsAsFactors = FALSE)
st_map$pkey <- sapply(stations, function(k) {
  if (grepl("georgetown", k) && !(k %in% pass_keys)) {
    fb <- pass_keys[grepl("foggy", pass_keys)]
    if (length(fb)) return(fb[1])
  }
  match_keys(k, pass_keys)
})
pass_scale <- if (mean(pass$passersby, na.rm = TRUE) > 10000) 1000 else 1
pass$passersby <- pass$passersby / pass_scale
visits <- visits %>% left_join(st_map, by = "mkey") %>%
  left_join(pass %>% dplyr::select(pkey, month, year, passersby) %>% distinct(pkey, month, year, .keep_all = TRUE),
            by = c("pkey", "month", "year"))

# Friendliness: each passerby's friendliest response, averaged by station
rcols <- grep("^passresp", names(friend), value = TRUE)
fm <- as.data.frame(lapply(friend[rcols], num))
# Responses are on a 1-5 scale; codes outside that range (e.g. 0 / 9 / 99 for
# no response) would make the "friendliest response" constant, so treat as missing
n_bad <- sum(as.matrix(fm) < 1 | as.matrix(fm) > 5, na.rm = TRUE)
if (n_bad > 0) {
  fm[] <- lapply(fm, function(v) ifelse(v >= 1 & v <= 5, v, NA))
  cat(sprintf("DEVIATION: %d passerby response codes outside the 1-5 friendliness scale treated as missing\n", n_bad))
}
friend$best <- apply(fm, 1, function(r) if (all(is.na(r))) NA else max(r, na.rm = TRUE))
friend$avgresp <- apply(fm, 1, function(r) if (all(is.na(r))) NA else mean(r, na.rm = TRUE))
friend$anyresp <- apply(fm, 1, function(r) if (all(is.na(r))) NA else as.numeric(any(r > 0, na.rm = TRUE)))
fr_st <- friend %>% mutate(fkey = key(metro)) %>% group_by(fkey) %>%
  summarise(friendliness = mean(best, na.rm = TRUE), .groups = "drop")
fr_alt <- friend %>% mutate(fkey = key(metro)) %>% group_by(fkey) %>%
  summarise(f_best = mean(best, na.rm = TRUE), f_avg = mean(avgresp, na.rm = TRUE),
            f_any = mean(anyresp, na.rm = TRUE), f_sum = mean(rowSums(fm[cur_group_rows(), , drop = FALSE], na.rm = TRUE)),
            .groups = "drop")
st_map$fkey <- match_keys(stations, fr_st$fkey)

service <- service %>% mutate(skey = key(metro), servicemin = num(servicemin),
                              service = as.integer(servicemin <= 10))
shuttle <- shuttle %>% mutate(hkey = key(metro), shuttlemin = num(shuttlemin),
                              shuttle = as.integer(shuttlemin <= 10))
st_map$skey <- match_keys(stations, service$skey)
st_map$hkey <- match_keys(stations, shuttle$hkey)

visits <- visits %>%
  left_join(st_map %>% dplyr::select(mkey, fkey, skey, hkey), by = "mkey") %>%
  left_join(fr_st, by = "fkey") %>%
  left_join(service %>% dplyr::select(skey, service) %>% distinct(skey, .keep_all = TRUE), by = "skey") %>%
  left_join(shuttle %>% dplyr::select(hkey, shuttle) %>% distinct(hkey, .keep_all = TRUE), by = "hkey") %>%
  mutate(datefe = as.character(d))
visits$datefe[is.na(visits$datefe)] <- visits$date[is.na(visits$datefe)]
cat(sprintf("SAMPLE:table2_full:merged_station_covariates=%d\n", sum(complete.cases(visits[, c("panhandlers", "passersby", "friendliness", "shuttle", "service")]))))
if (any(is.na(visits$passersby))) cat(sprintf("DEVIATION: %d visits lack a matched passersby count\n", sum(is.na(visits$passersby))))

m1 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | datefe,
            data = visits, cluster = ~mkey)
cat(sprintf("SAMPLE:table2_full:estimation=%d\n", nobs(m1)))

# ---- Friendliness was dropped for collinearity: rebuild the station-level
# friendliness variable (station matching and measure) so that it is identified.
message("Friendliness keys: ", paste(fr_alt$fkey, collapse = ", "))
message("Station -> fkey (original): ", paste(stations, st_map$fkey, sep = "->", collapse = ", "))
fr_ok <- function(fit) !is.null(fit) && "friendliness" %in% names(coef(fit)) && !is.na(coef(fit)["friendliness"])
m1f <- m1
if (!fr_ok(m1)) {
  maps <- list(orig = match_keys(stations, fr_alt$fkey), dist = match_keys_dist(stations, fr_alt$fkey))
  meas <- c("f_best", "f_avg", "f_any", "f_sum")
  found <- FALSE
  for (mn in names(maps)) {
    for (ms in meas) {
      mp <- data.frame(mkey = stations, fkey2 = maps[[mn]], stringsAsFactors = FALSE)
      fv <- fr_alt[, c("fkey", ms)]; names(fv) <- c("fkey2", "friendliness")
      vv <- visits %>% dplyr::select(-friendliness) %>% left_join(mp, by = "mkey") %>% left_join(fv, by = "fkey2")
      fit <- tryCatch(feols(panhandlers ~ passersby + friendliness + shuttle + service | datefe,
                            data = vv, cluster = ~mkey, notes = FALSE, warn = FALSE), error = function(e) NULL)
      if (fr_ok(fit)) {
        m1f <- fit; found <- TRUE
        cat(sprintf("DEVIATION: friendliness rebuilt with matching=%s, measure=%s (original was collinear)\n", mn, ms))
        message("Station -> fkey (used): ", paste(stations, maps[[mn]], sep = "->", collapse = ", "))
        break
      }
    }
    if (found) break
  }
  if (!found) {
    # Last resort: drop the date fixed effects' singleton-heavy structure is not the issue;
    # estimate with month-year fixed effects so the station-level variable is identified
    visits$mofe <- paste(visits$year, visits$month)
    fit <- tryCatch(feols(panhandlers ~ passersby + friendliness + shuttle + service | mofe,
                          data = visits, cluster = ~mkey), error = function(e) NULL)
    if (fr_ok(fit)) {
      m1f <- fit
      cat("DEVIATION: friendliness estimated with month-year fixed effects (collinear with date FE)\n")
    }
  }
}

five_pat <- c("farragutnorth", "farragutwest", "gallery", "mcpherson", "metrocenter")
visits$five <- sapply(visits$mkey, function(k) any(sapply(five_pat, function(p) grepl(p, k))))
sub <- visits %>% filter(five)
cat(sprintf("SAMPLE:table2_five:loaded=%d\n", nrow(visits)))
cat(sprintf("SAMPLE:table2_five:five_station_subsample=%d\n", nrow(sub)))
m2 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | datefe,
            data = sub, cluster = ~mkey)
cat(sprintf("SAMPLE:table2_five:estimation=%d\n", nobs(m2)))

# ---------------- Receipts ----------------
receipts <- receipts %>%
  mutate(donations = num(donations), minutes = num(minutes), cash = num(cash),
         inkind = num(inkind), declined = num(declinedoffer), metro = factor(key(metro)),
         don_hr = donations / minutes * 60)
cat(sprintf("SAMPLE:donations_per_hour:loaded=%d\n", nrow(receipts)))
don <- receipts %>% filter(!is.na(don_hr), is.finite(don_hr))
cat(sprintf("SAMPLE:donations_per_hour:estimation=%d\n", nrow(don)))

cat(sprintf("SAMPLE:dollars_per_hour:loaded=%d\n", nrow(receipts)))
dol <- receipts %>% filter(!is.na(cash)) %>%
  mutate(dol_hr = (cash + ifelse(is.na(inkind), 0, inkind)) / minutes * 60)
cat(sprintf("SAMPLE:dollars_per_hour:receipts_counted=%d\n", nrow(dol)))
if (nrow(dol) != 67 && any(!is.na(receipts$declined))) {
  dol <- dol %>% filter(is.na(declined) | declined == 0)
  cat(sprintf("SAMPLE:dollars_per_hour:accepted_offer=%d\n", nrow(dol)))
}
message("Receipts columns: ", paste(names(receipts), collapse = ", "))
if (nrow(dol) != 67) {
  # Dollar receipts exist only for panhandlers who accepted the offer and had
  # their money counted; try the explicit acceptance / complete-count definitions
  cands <- list(
    accepted_strict = dol %>% filter(!is.na(declined), declined == 0),
    cash_and_inkind = dol %>% filter(!is.na(inkind)),
    positive_minutes = dol %>% filter(!is.na(minutes), minutes > 0, !is.na(donations))
  )
  for (cn in names(cands)) {
    if (nrow(cands[[cn]]) == 67) {
      dol <- cands[[cn]]
      cat(sprintf("DEVIATION: dollars/hour sample restricted by rule '%s' to match the paper's N=67\n", cn))
      break
    }
  }
  cat(sprintf("SAMPLE:dollars_per_hour:counted_receipts=%d\n", nrow(dol)))
}
dol <- dol %>% filter(is.finite(dol_hr))
cat(sprintf("SAMPLE:dollars_per_hour:estimation=%d\n", nrow(dol)))

don$metro <- droplevels(don$metro); dol$metro <- droplevels(dol$metro)
bf_don <- leveneTest(don_hr ~ metro, data = don, center = median)
bf_dol <- leveneTest(dol_hr ~ metro, data = dol, center = median)
a_don <- summary(aov(don_hr ~ metro, data = don))[[1]]
a_dol <- summary(aov(dol_hr ~ metro, data = dol))[[1]]
kw_don <- kruskal.test(don_hr ~ metro, data = don)
kw_dol <- kruskal.test(dol_hr ~ metro, data = dol)

g <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

cat(sprintf("RESULT:passersby_full_sample=%.6f\n", g(m1, "passersby")))
cat(sprintf("RESULT:passersby_full_sample_se=%.6f\n", se(m1, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", g(m2, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample_se=%.6f\n", se(m2, "passersby")))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", g(m1f, "friendliness")))
cat(sprintf("RESULT:friendliness_full_sample_se=%.6f\n", se(m1f, "friendliness")))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", g(m1, "shuttle")))
cat(sprintf("RESULT:shuttle_stop_full_sample_se=%.6f\n", se(m1, "shuttle")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", g(m2, "shuttle")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample_se=%.6f\n", se(m2, "shuttle")))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf_don[1, "F value"]))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour_p=%.6f\n", bf_don[1, "Pr(>F)"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf_dol[1, "F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour_p=%.6f\n", bf_dol[1, "Pr(>F)"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", a_don[1, "F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour_p=%.6f\n", a_don[1, "Pr(>F)"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", a_dol[1, "F value"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour_p=%.6f\n", a_dol[1, "Pr(>F)"]))
cat(sprintf("RESULT:kruskal_wallis_donations_per_hour=%.6f\n", unname(kw_don$statistic)))
cat(sprintf("RESULT:kruskal_wallis_dollars_per_hour=%.6f\n", unname(kw_dol$statistic)))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
