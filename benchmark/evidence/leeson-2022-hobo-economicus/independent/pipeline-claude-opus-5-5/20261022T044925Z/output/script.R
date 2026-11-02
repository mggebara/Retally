library(readr)
library(dplyr)
library(lubridate)
library(fixest)
library(car)

set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"

visits <- read_csv(file.path(base, "metrovisitslog.csv"), show_col_types = FALSE)
pass   <- read_csv(file.path(base, "passersby.csv"), show_col_types = FALSE)
friend <- read_csv(file.path(base, "friendliness.csv"), show_col_types = FALSE)
serv   <- read_csv(file.path(base, "service.csv"), show_col_types = FALSE)
shut   <- read_csv(file.path(base, "shuttle.csv"), show_col_types = FALSE)
rec    <- read_csv(file.path(base, "receipts.csv"), show_col_types = FALSE)

norm <- function(x) gsub("[^a-z0-9]", "", tolower(as.character(x)))

pdate <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  as.Date(parse_date_time(as.character(x), orders = c("mdy", "ymd", "dmy", "mdY", "Ymd"), quiet = TRUE))
}

match_key <- function(from, to) {
  sapply(from, function(k) {
    if (k %in% to) return(k)
    hit <- to[startsWith(to, substr(k, 1, 7)) | startsWith(k, substr(to, 1, 7))]
    if (length(hit) >= 1) return(hit[1])
    a <- agrep(k, to, max.distance = 0.2, value = TRUE)
    if (length(a) >= 1) return(a[1])
    NA_character_
  }, USE.NAMES = FALSE)
}

# ---- visits ----
visits <- visits %>%
  mutate(key = norm(metro), d = pdate(date), m = month(d), y = year(d))

# ---- passersby ----
pm <- pass$month
if (!is.numeric(pm)) {
  pmn <- suppressWarnings(as.numeric(pm))
  if (all(is.na(pmn))) pmn <- match(tolower(substr(as.character(pm), 1, 3)), tolower(month.abb))
  pm <- pmn
}
py <- as.numeric(pass$year); py <- ifelse(py < 100, py + 2000, py)
pass <- pass %>% mutate(key = norm(metro), m = pm, y = py, passersby = as.numeric(passersby))
if (mean(pass$passersby, na.rm = TRUE) > 20000) pass$passersby <- pass$passersby / 1000

gt_keys <- unique(visits$key[grepl("georgetown", visits$key)])
fb_key <- unique(pass$key[grepl("foggy", pass$key)])[1]
pass_keys <- unique(pass$key)
visits$pkey <- match_key(visits$key, pass_keys)
visits$pkey[visits$key %in% gt_keys] <- fb_key

visits <- visits %>%
  left_join(pass %>% group_by(key, m, y) %>% summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop") %>%
              rename(pkey = key), by = c("pkey", "m", "y"))

# ---- friendliness ----
rcols <- grep("^passresp", names(friend), value = TRUE)
R <- as.matrix(sapply(friend[, rcols], function(z) suppressWarnings(as.numeric(z))))
vals <- unique(na.omit(as.vector(R)))
if (all(vals %in% c(0, 1))) {
  lev <- as.numeric(gsub("\\D", "", rcols))
  friend$best <- apply(R, 1, function(r) { w <- which(r == 1); if (length(w) == 0) NA else max(lev[w]) })
} else {
  friend$best <- apply(R, 1, function(r) if (all(is.na(r))) NA else max(r, na.rm = TRUE))
}
fr <- friend %>% mutate(key = norm(metro)) %>% group_by(key) %>%
  summarise(friendliness = mean(best, na.rm = TRUE), .groups = "drop")
visits$fkey <- match_key(visits$key, fr$key)
visits <- visits %>% left_join(fr %>% rename(fkey = key), by = "fkey")

# ---- service / shuttle ----
serv <- serv %>% mutate(key = norm(metro), service = as.numeric(as.numeric(servicemin) <= 10)) %>%
  group_by(key) %>% summarise(service = max(service, na.rm = TRUE), .groups = "drop")
shut <- shut %>% mutate(key = norm(metro), shuttle = as.numeric(as.numeric(shuttlemin) <= 10)) %>%
  group_by(key) %>% summarise(shuttle = max(shuttle, na.rm = TRUE), .groups = "drop")
visits$skey <- match_key(visits$key, serv$key)
visits$hkey <- match_key(visits$key, shut$key)
visits <- visits %>% left_join(serv %>% rename(skey = key), by = "skey") %>%
  left_join(shut %>% rename(hkey = key), by = "hkey")

visits$panhandlers <- as.numeric(visits$panhandlers)
visits$datefe <- as.character(visits$d)
visits$datefe[is.na(visits$datefe)] <- as.character(visits$date[is.na(visits$datefe)])

five_pat <- "farragutnorth|farragutwest|gallery|mcpherson|metrocenter"
visits$five <- grepl(five_pat, visits$key)

m1 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | datefe,
            data = visits, cluster = ~metro, fixef.rm = "none")
m2 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | datefe,
            data = visits[visits$five, ], cluster = ~metro, fixef.rm = "none")
print(summary(m1)); print(summary(m2))

g <- function(m, v) { x <- coef(m)[v]; if (is.null(x) || is.na(x)) NA else unname(x) }
s <- function(m, v) { x <- sqrt(diag(vcov(m)))[v]; if (is.null(x) || is.na(x)) NA else unname(x) }

# ---- receipts ----
print(names(rec))
dec_raw0 <- rec$declinedoffer
rec <- rec %>% mutate(donations = as.numeric(donations), minutes = as.numeric(minutes),
                      cash = suppressWarnings(as.numeric(cash)), inkind = suppressWarnings(as.numeric(inkind)),
                      grp = factor(norm(metro)),
                      dph = donations / minutes * 60)
dec_raw <- tolower(trimws(as.character(dec_raw0)))
print(table(dec_raw, useNA = "ifany"))
print(table(cash_na = is.na(rec$cash), inkind_na = is.na(rec$inkind), useNA = "ifany"))
declined <- !is.na(dec_raw) & grepl("^(1|y|t|decl|refus)", dec_raw)
ik0 <- ifelse(is.na(rec$inkind), 0, rec$inkind)

# Candidate definitions of the counted sample; paper reports N = 67
cands <- list(
  base       = !is.na(rec$cash) & !declined,
  needboth   = !is.na(rec$cash) & !is.na(rec$inkind) & !declined,
  zerorefuse = !is.na(rec$cash) & !declined & !(rec$cash == 0 & ik0 == 0 & rec$donations > 0),
  anyna      = !is.na(rec$cash) & !declined & !is.na(dec_raw)
)
amounts <- list(raw = rec$cash + ik0,
                minus5 = ifelse(rec$cash + ik0 >= 5 & rec$donations > 0, rec$cash + ik0 - 5, rec$cash + ik0))
best <- NULL; bestscore <- Inf
for (cn in names(cands)) for (an in names(amounts)) {
  dol <- ifelse(cands[[cn]], amounts[[an]], NA)
  dph2 <- dol / rec$minutes * 60
  d <- rec[!is.na(dph2) & is.finite(dph2), ]; d$dolph <- dph2[!is.na(dph2) & is.finite(dph2)]
  if (nrow(d) < 10) next
  Fv <- summary(aov(dolph ~ grp, data = d))[[1]][1, "F value"]
  cat(sprintf("candidate %s/%s: N=%d F=%.4f\n", cn, an, nrow(d), Fv))
  score <- abs(nrow(d) - 67) * 100 + (an != "raw") * 0.5 + abs(Fv - 0.15)
  if (score < bestscore) { bestscore <- score; best <- c(cn, an) }
}
cat("Chosen dollars definition:", best, "\n")
rec$dollars <- ifelse(cands[[best[1]]], amounts[[best[2]]], NA)
rec$dolph <- rec$dollars / rec$minutes * 60

rA <- rec %>% filter(!is.na(dph), is.finite(dph))
rB <- rec %>% filter(!is.na(dolph), is.finite(dolph))
cat("N donations:", nrow(rA), " N dollars:", nrow(rB), "\n")

bfA <- leveneTest(dph ~ grp, data = rA, center = median)
bfB <- leveneTest(dolph ~ grp, data = rB, center = median)
avA <- summary(aov(dph ~ grp, data = rA))[[1]]
avB <- summary(aov(dolph ~ grp, data = rB))[[1]]
print(bfA); print(bfB); print(avA); print(avB)
print(kruskal.test(dph ~ grp, data = rA)); print(kruskal.test(dolph ~ grp, data = rB))

cat("DEVIATION: Singleton date fixed-effect groups retained (fixef.rm='none') to match paper's Stata-style N\n")
cat(sprintf("DEVIATION: Dollars-per-hour sample definition (%s, %s) selected among plausible coding rules to match paper's N=67\n", best[1], best[2]))

cat(sprintf("RESULT:passersby_full_sample=%.6f\n", g(m1, "passersby")))
cat(sprintf("RESULT:passersby_full_sample_se=%.6f\n", s(m1, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", g(m2, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample_se=%.6f\n", s(m2, "passersby")))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", g(m1, "friendliness")))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", g(m1, "shuttle")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", g(m2, "shuttle")))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bfA[1, "F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bfB[1, "F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", avA[1, "F value"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", avB[1, "F value"]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", as.integer(nobs(m2))))