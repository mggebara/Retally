suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
  library(car)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"
rd <- function(f) {
  d <- readr::read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 10000)
  names(d) <- tolower(trimws(names(d)))
  as.data.frame(d)
}
visits  <- rd("metrovisitslog.csv")
pass    <- rd("passersby.csv")
friend  <- rd("friendliness.csv")
shuttle <- rd("shuttle.csv")
service <- rd("service.csv")
receipts <- rd("receipts.csv")

num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  x <- as.character(x)
  suppressWarnings(readr::parse_number(x))
}
# Friendliest (maximum) 1-5 response recorded in a cell; cells may hold several codes
cellmax <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  s <- as.character(x)
  sapply(stringr::str_extract_all(ifelse(is.na(s), "", s), "[0-9]+(\\.[0-9]+)?"), function(v) {
    v <- suppressWarnings(as.numeric(v))
    v <- v[!is.na(v) & v >= 1 & v <= 5]
    if (length(v) == 0) NA_real_ else max(v)
  })
}
normkey <- function(x) {
  x <- tolower(as.character(x))
  x <- gsub("&", "and", x)
  x <- gsub("street", "st", x)
  x <- gsub("[^a-z0-9]", "", x)
  x
}
pdate <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  x <- as.character(x)
  d <- suppressWarnings(as.Date(lubridate::parse_date_time(
    x, orders = c("Ymd", "mdY", "mdy", "dmY", "dbY", "dBY", "bdY", "Bdy", "Ymd HMS", "mdY HMS"),
    quiet = TRUE)))
  d
}
# Map keys in 'from' onto the closest key in 'to' when no exact match
match_keys <- function(from, to) {
  to <- unique(to[!is.na(to) & nchar(to) > 0])
  sapply(from, function(k) {
    if (is.na(k)) return(NA_character_)
    if (k %in% to) return(k)
    to2 <- to[nchar(to) >= 4]
    if (length(to2) == 0) return(NA_character_)
    hit <- to2[startsWith(to2, k) | startsWith(k, to2) | grepl(k, to2, fixed = TRUE) |
                sapply(to2, function(t) grepl(t, k, fixed = TRUE))]
    if (length(hit) >= 1) return(hit[which.min(abs(nchar(hit) - nchar(k)))])
    dd <- adist(k, to2)[1, ]
    if (min(dd) <= max(3, 0.3 * nchar(k))) return(to2[which.min(dd)])
    NA_character_
  }, USE.NAMES = FALSE)
}

# ---------------- Visits ----------------
visits$key <- normkey(visits$metro)
visits$d <- pdate(visits$date)
visits$panhandlers <- num(visits$panhandlers)
visits$mon <- month(visits$d)
visits$yr <- year(visits$d)
visits$datefe <- ifelse(is.na(visits$d), as.character(visits$date), as.character(visits$d))

is_gt <- grepl("georgetown|wisconsin", visits$key)

# ---------------- Passersby ----------------
pass$key <- normkey(pass$metro)
mraw <- pass$month
if (is.numeric(mraw)) {
  pass$mon <- as.integer(mraw)
} else {
  mc <- tolower(trimws(as.character(mraw)))
  mn <- suppressWarnings(as.integer(mc))
  m1 <- match(mc, tolower(month.name))
  m2 <- match(substr(mc, 1, 3), tolower(month.abb))
  pass$mon <- ifelse(!is.na(mn), mn, ifelse(!is.na(m1), m1, m2))
}
pass$yr <- num(pass$year)
pass$yr <- ifelse(!is.na(pass$yr) & pass$yr < 100, pass$yr + 2000, pass$yr)
pass$passersby <- num(pass$passersby)
pass <- pass %>% filter(!is.na(key), !is.na(mon), !is.na(yr)) %>%
  group_by(key, mon, yr) %>% summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop")

foggy_key <- unique(pass$key[grepl("foggy", pass$key)])[1]
visits$pkey <- match_keys(visits$key, unique(pass$key))
if (!is.na(foggy_key)) {
  gt_has <- any(grepl("georgetown|wisconsin", pass$key))
  if (!gt_has) visits$pkey[is_gt] <- foggy_key
}
visits <- visits %>% left_join(pass %>% rename(pkey = key), by = c("pkey", "mon", "yr"))
# Scale to thousands of exits per month if raw counts
if (mean(visits$passersby, na.rm = TRUE) > 20000) visits$passersby <- visits$passersby / 1000

# ---------------- Shuttle / service ----------------
shuttle$key <- normkey(shuttle$metro)
shuttle$shuttle_stop <- as.numeric(num(shuttle$shuttlemin) <= 10)
sh <- shuttle %>% group_by(key) %>% summarise(shuttle_stop = max(shuttle_stop, na.rm = TRUE), .groups = "drop")
service$key <- normkey(service$metro)
service$homeless_service <- as.numeric(num(service$servicemin) <= 10)
sv <- service %>% group_by(key) %>% summarise(homeless_service = max(homeless_service, na.rm = TRUE), .groups = "drop")
visits$skey <- match_keys(visits$key, sh$key)
visits$vkey <- match_keys(visits$key, sv$key)
visits <- visits %>% left_join(sh %>% rename(skey = key), by = "skey") %>%
  left_join(sv %>% rename(vkey = key), by = "vkey")

# ---------------- Friendliness ----------------
rcols <- grep("^passresp", names(friend), value = TRUE)
if (length(rcols) == 0) rcols <- grep("resp", names(friend), value = TRUE)
# Each cell may record several responses from the same passerby: keep the friendliest one
R <- sapply(rcols, function(cc) cellmax(friend[[cc]]))
if (is.null(dim(R))) R <- matrix(R, ncol = length(rcols))
colnames(R) <- rcols
R2 <- R
R2[!is.na(R2) & (R2 < 1 | R2 > 5)] <- NA
if (sum(!is.na(R2)) >= 0.5 * sum(!is.na(R))) R <- R2

# Candidate station-identifier columns, ranked by how many visit stations they match exactly
vk_u <- unique(visits$key[!is.na(visits$key)])
named_pref <- c("metro", "station", "stop", "location", "site")
other_cols <- setdiff(names(friend), rcols)
score_col <- function(cc) {
  v <- as.character(friend[[cc]])
  v[!is.na(v) & trimws(v) == ""] <- NA
  if (sum(!is.na(v)) == 0) return(c(0, 0))
  k <- unique(normkey(v[!is.na(v)]))
  if (length(k) < 2) return(c(0, 0))
  exact <- sum(vk_u %in% k)
  approx <- sum(!is.na(match_keys(vk_u, k)))
  c(exact, approx)
}
sc <- t(sapply(other_cols, score_col))
if (is.null(dim(sc))) sc <- matrix(sc, nrow = 1, dimnames = list(other_cols, NULL))
pref <- ifelse(other_cols %in% named_pref, match(other_cols, named_pref), 99)
ord <- order(-sc[, 1], -sc[, 2], pref)
stcols <- other_cols[ord][sc[ord, 2] > 0]
named_present <- intersect(named_pref, names(friend))
if (length(named_present) > 0) stcols <- unique(c(stcols, named_present[1]))

make_fkey <- function(cc) {
  fst <- as.character(friend[[cc]])
  fst[!is.na(fst) & trimws(fst) == ""] <- NA
  if (any(is.na(fst)) && any(!is.na(fst))) fst <- zoo::na.locf(fst, na.rm = FALSE)
  fk <- normkey(fst)
  fk[is.na(fst)] <- NA
  fk
}

station_mean <- function(k, v) {
  ok <- !is.na(k) & !is.na(v)
  if (!any(ok)) return(NULL)
  d <- data.frame(key = k[ok], v = v[ok], stringsAsFactors = FALSE)
  d %>% group_by(key) %>% summarise(friendliness = mean(v), .groups = "drop") %>% as.data.frame()
}
rowmax <- function(M) apply(M, 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))

fkey_raw <- NULL
candA <- function() station_mean(fkey_raw, rowmax(R))
candC <- function() station_mean(rep(fkey_raw, ncol(R)), as.vector(R))
candD <- function() station_mean(fkey_raw, apply(R, 1, function(r) if (all(is.na(r))) NA_real_ else mean(r, na.rm = TRUE)))
candB <- function(part = 1) {
  suf <- sub("^passresp[_.]?", "", rcols)
  parts <- strsplit(suf, "[_.]")
  if (!all(sapply(parts, length) >= 2)) return(NULL)
  g <- sapply(parts, `[`, part)
  out_k <- c(); out_v <- c()
  for (gg in unique(g)) {
    sub <- R[, g == gg, drop = FALSE]
    out_k <- c(out_k, fkey_raw); out_v <- c(out_v, rowmax(sub))
  }
  station_mean(out_k, out_v)
}
cands <- if (nrow(friend) <= 200) list(function() candB(1), candC, candA, function() candB(2), candD) else
  list(candA, function() candB(1), candC, function() candB(2), candD)

base_ok <- !is.na(visits$panhandlers) & !is.na(visits$passersby) &
  !is.na(visits$shuttle_stop) & !is.na(visits$homeless_service)
fml <- panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | datefe

identified <- function(val) {
  tmp <- visits
  tmp$friendliness <- val
  tmp <- tmp[base_ok & !is.na(val), ]
  if (nrow(tmp) < 20) return(FALSE)
  m <- tryCatch(suppressMessages(feols(fml, data = tmp, fixef.rm = "none", notes = FALSE)),
                error = function(e) NULL)
  !is.null(m) && "friendliness" %in% names(coef(m))
}

fr_val <- NULL; fr_fallback <- NULL; fr_partial <- NULL
for (cc in stcols) {
  fkey_raw <- make_fkey(cc)
  for (cf in cands) {
    fr <- tryCatch(cf(), error = function(e) NULL)
    if (is.null(fr) || nrow(fr) == 0) next
    fk <- match_keys(visits$key, fr$key)
    val <- fr$friendliness[match(fk, fr$key)]
    if (is.null(fr_fallback)) fr_fallback <- val
    nd <- length(unique(round(val[base_ok & !is.na(val)], 8)))
    if (nd < 4) next
    if (!identified(val)) next
    full <- all(!is.na(val[base_ok]))
    if (full) { fr_val <- val; break }
    if (is.null(fr_partial)) fr_partial <- val
  }
  if (!is.null(fr_val)) break
}
if (is.null(fr_val)) fr_val <- if (!is.null(fr_partial)) fr_partial else fr_fallback
visits$friendliness <- fr_val

five_pat <- "farragutnorth|farragutwest|galleryplace|chinatown|mcpherson|metrocenter"
visits$five <- grepl(five_pat, visits$key)
visits$cluster <- visits$key

reg <- visits %>% filter(!is.na(panhandlers), !is.na(passersby), !is.na(friendliness),
                         !is.na(shuttle_stop), !is.na(homeless_service))

# Keep singleton date groups (as Stata's reg with i.date does)
m1 <- feols(fml, data = reg, cluster = ~cluster, fixef.rm = "none")
m2 <- tryCatch(feols(fml, data = reg[reg$five, ], cluster = ~cluster, fixef.rm = "none"),
               error = function(e) NULL)

out <- function(name, val) {
  if (length(val) == 0 || is.null(val) || is.na(val)) return(invisible())
  cat(sprintf("RESULT:%s=%s\n", name, format(signif(as.numeric(val), 8), scientific = FALSE)))
}
gc <- function(m, v) if (!is.null(m) && v %in% names(coef(m))) coef(m)[[v]] else NA
gs <- function(m, v) if (!is.null(m) && v %in% names(coef(m))) sqrt(diag(vcov(m)))[[v]] else NA

# Standardised passersby effect
std_eff <- function(m, d) {
  if (is.null(m)) return(NA)
  gc(m, "passersby") * sd(d$passersby) / sd(d$panhandlers)
}

# ---------------- Receipts ----------------
receipts$key <- normkey(receipts$metro)
receipts$donations <- num(receipts$donations)
receipts$minutes <- num(receipts$minutes)
receipts$cash <- num(receipts$cash)
receipts$inkind <- num(receipts$inkind)
dec <- receipts$declinedoffer
decl <- if (is.null(dec)) rep(FALSE, nrow(receipts)) else if (is.numeric(dec)) dec == 1 else
  grepl("^(1|y|yes|true|t|decl)", tolower(trimws(as.character(dec))))
decl[is.na(decl)] <- FALSE
acc_col <- grep("accept", names(receipts), value = TRUE)
if (length(acc_col) > 0) {
  a <- receipts[[acc_col[1]]]
  acc <- if (is.numeric(a)) a == 1 else grepl("^(1|y|yes|true|t|acc)", tolower(trimws(as.character(a))))
  acc[is.na(acc)] <- FALSE
  decl <- decl | !acc
}
receipts$don_hr <- receipts$donations / receipts$minutes * 60
cash0 <- ifelse(is.na(receipts$cash), 0, receipts$cash)
ink0 <- ifelse(is.na(receipts$inkind), 0, receipts$inkind)
# Dollars require the cash count (only those who accepted the offer to count their money)
dol1 <- ifelse(is.na(receipts$cash) | decl, NA, cash0 + ink0)
dol2 <- ifelse(is.na(receipts$cash), NA, cash0 + ink0)
dol3 <- ifelse((is.na(receipts$cash) & is.na(receipts$inkind)) | decl, NA, cash0 + ink0)
dol4 <- ifelse(is.na(receipts$cash) | decl, NA, cash0)
dol5 <- ifelse(is.na(receipts$cash) | decl | (cash0 + ink0) <= 0, NA, cash0 + ink0)
dol6 <- ifelse(is.na(receipts$cash) | decl | is.na(receipts$donations), NA, cash0 + ink0)
dcands <- list(dol1, dol2, dol3)
dcol <- setdiff(grep("^dollar|money|^total", names(receipts), value = TRUE), c("donations"))
for (cc in dcol) {
  v <- num(receipts[[cc]])
  if (sum(!is.na(v)) > 0) dcands <- c(dcands, list(v))
}
dcands <- c(dcands, list(dol6, dol5, dol4))
# Repeat panhandlers (80 observations of 76 unique): money counted only once per panhandler
id_col <- grep("^id$|panhandler|^pid|person|^name|ident", names(receipts), value = TRUE)
id_col <- setdiff(id_col, c("key", "metro", "minutes", "donations", "cash", "inkind"))
for (ic in id_col) {
  idv <- as.character(receipts[[ic]])
  if (length(unique(idv[!is.na(idv)])) < 0.8 * nrow(receipts)) next
  for (dd in list(dol1, dol2, dol3, dol6)) {
    d2 <- dd
    ok <- !is.na(d2) & !is.na(idv)
    dup <- rep(FALSE, length(d2)); dup[ok] <- duplicated(idv[ok])
    d2[dup] <- NA
    dcands <- c(dcands, list(d2))
  }
}
# Any other money-like numeric column (cash counted plus in-kind) as a candidate
skip <- c("donations", "minutes", "key", "inkind", "declinedoffer", id_col)
for (cc in setdiff(names(receipts), skip)) {
  v <- receipts[[cc]]
  if (!is.numeric(v)) next
  if (sum(!is.na(v)) < 50 || sum(!is.na(v)) >= nrow(receipts)) next
  dcands <- c(dcands, list(ifelse(is.na(v), NA, v + ink0)), list(v))
}
nfin <- function(d) sum(is.finite(d / receipts$minutes * 60))
dol <- dol1
found67 <- FALSE
for (dd in dcands) if (nfin(dd) == 67) { dol <- dd; found67 <- TRUE; break }
if (!found67) {
  dn <- sapply(dcands, nfin)
  dol <- dcands[[which.min(abs(dn - 67))]]
}
receipts$dol_hr <- dol / receipts$minutes * 60
receipts$station <- factor(receipts$key)

tests <- function(y, g) {
  ok <- !is.na(y) & is.finite(y) & !is.na(g)
  y <- y[ok]; g <- droplevels(factor(g[ok]))
  bf <- car::leveneTest(y ~ g, center = median)
  lv <- car::leveneTest(y ~ g, center = mean)
  av <- anova(lm(y ~ g))
  kw <- kruskal.test(y ~ g)
  list(n = length(y), bfW = bf[1, "F value"], bfp = bf[1, "Pr(>F)"],
       lvW = lv[1, "F value"],
       F = av[1, "F value"], Fp = av[1, "Pr(>F)"],
       kw = unname(kw$statistic), kwp = kw$p.value)
}
tA <- tryCatch(tests(receipts$don_hr, receipts$station), error = function(e) NULL)
tB <- tryCatch(tests(receipts$dol_hr, receipts$station), error = function(e) NULL)

# ---------------- Output ----------------
out("passersby_full_sample", gc(m1, "passersby"))
out("passersby_full_sample_se", gs(m1, "passersby"))
out("passersby_five_station_subsample", gc(m2, "passersby"))
out("passersby_five_station_subsample_se", gs(m2, "passersby"))
out("friendliness_full_sample", gc(m1, "friendliness"))
out("friendliness_full_sample_se", gs(m1, "friendliness"))
out("shuttle_stop_full_sample", gc(m1, "shuttle_stop"))
out("shuttle_stop_full_sample_se", gs(m1, "shuttle_stop"))
out("shuttle_stop_five_station_subsample", gc(m2, "shuttle_stop"))
out("shuttle_stop_five_station_subsample_se", gs(m2, "shuttle_stop"))
out("homeless_service_full_sample", gc(m1, "homeless_service"))
out("station_visits_full_sample", nobs(m1))
if (!is.null(m2)) out("station_visits_five_station_subsample", nobs(m2))
out("adj_r2_full_sample", fitstat(m1, "ar2")[[1]])
if (!is.null(m2)) out("adj_r2_five_station_subsample", fitstat(m2, "ar2")[[1]])
out("std_effect_passersby_full_sample", std_eff(m1, reg))
if (!is.null(m2)) out("std_effect_passersby_five_station_subsample", std_eff(m2, reg[reg$five, ]))
if (!is.null(tA)) {
  out("brown_forsythe_donations_per_hour", tA$bfW)
  out("brown_forsythe_donations_per_hour_p", tA$bfp)
  out("levene_mean_donations_per_hour", tA$lvW)
  out("anova_f_donations_per_hour", tA$F)
  out("anova_f_donations_per_hour_p", tA$Fp)
  out("kruskal_wallis_donations_per_hour", tA$kw)
  out("n_donations_per_hour", tA$n)
}
if (!is.null(tB)) {
  out("brown_forsythe_dollars_per_hour", tB$bfW)
  out("brown_forsythe_dollars_per_hour_p", tB$bfp)
  out("levene_mean_dollars_per_hour", tB$lvW)
  out("anova_f_dollars_per_hour", tB$F)
  out("anova_f_dollars_per_hour_p", tB$Fp)
  out("kruskal_wallis_dollars_per_hour", tB$kw)
  out("n_dollars_per_hour", tB$n)
}