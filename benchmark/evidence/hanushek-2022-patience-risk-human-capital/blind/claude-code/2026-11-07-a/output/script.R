# ---- Chunked Stata 117/118/119 reader (readBin on large blocks) ----
dta_header <- function(path) {
  con <- file(path, "rb"); on.exit(close(con))
  hdr <- readBin(con, "raw", 2000000)
  rp <- grepRaw("<release>", hdr) + 9
  rel <- as.integer(rawToChar(hdr[rp:(rp + 2)]))
  le <- length(grepRaw("<byteorder>LSF", hdr)) > 0
  endian <- if (le) "little" else "big"
  kpos <- grepRaw("<K>", hdr) + 3
  ksize <- if (rel == 119) 4 else 2
  K <- readBin(hdr[kpos:(kpos + ksize - 1)], "integer", n = 1, size = ksize, signed = FALSE, endian = endian)
  if (ksize == 4) K <- readBin(hdr[kpos:(kpos + 3)], "integer", n = 1, size = 4, endian = endian)
  npos <- kpos + ksize + 7  # skip "</K><N>"
  N <- readBin(hdr[npos:(npos + 7)], "double", n = 1, size = 8, endian = endian) # placeholder
  lo <- readBin(hdr[npos:(npos + 3)], "integer", n = 1, size = 4, endian = endian)
  hi <- readBin(hdr[(npos + 4):(npos + 7)], "integer", n = 1, size = 4, endian = endian)
  if (lo < 0) lo <- lo + 2^32
  N <- lo + hi * 2^32
  # map
  mpos <- grepRaw("<map>", hdr) + 5
  map <- sapply(0:13, function(j) {
    b <- hdr[(mpos + 8 * j):(mpos + 8 * j + 7)]
    lo <- readBin(b[1:4], "integer", size = 4, endian = endian); if (lo < 0) lo <- lo + 2^32
    hi <- readBin(b[5:8], "integer", size = 4, endian = endian)
    lo + hi * 2^32
  })
  # variable types
  tpos <- map[3] + 1 + nchar("<variable_types>")
  types <- readBin(hdr[tpos:(tpos + 2 * K - 1)], "integer", n = K, size = 2, signed = FALSE, endian = endian)
  vpos <- map[4] + 1 + nchar("<varnames>")
  nmlen <- if (rel == 117) 33 else 129
  nm <- sapply(0:(K - 1), function(j) {
    b <- hdr[(vpos + nmlen * j):(vpos + nmlen * j + nmlen - 1)]
    b <- b[seq_len(which(b == as.raw(0))[1] - 1)]
    rawToChar(b)
  })
  lpos <- map[8] + 1 + nchar("<variable_labels>")
  lablen <- if (rel == 117) 81 else 321
  labs <- sapply(0:(K - 1), function(j) {
    b <- hdr[(lpos + lablen * j):(lpos + lablen * j + lablen - 1)]
    z <- which(b == as.raw(0))[1]
    if (is.na(z) || z == 1) "" else rawToChar(b[seq_len(z - 1)])
  })
  w <- ifelse(types <= 2045, types, ifelse(types == 32768, 8,
       ifelse(types == 65526, 8, ifelse(types == 65527, 4, ifelse(types == 65528, 4,
       ifelse(types == 65529, 2, ifelse(types == 65530, 1, NA)))))))
  off <- c(0, cumsum(w))[1:K]
  list(release = rel, endian = endian, K = K, N = N, map = map, types = types,
       names = nm, labels = labs, width = w, offset = off, rowwidth = sum(w),
       dataStart = map[10] + nchar("<data>"))
}

decode_col <- function(m, h, j) {
  t <- h$types[j]; o <- h$offset[j]; w <- h$width[j]; n <- ncol(m)
  b <- as.vector(m[(o + 1):(o + w), , drop = FALSE])
  e <- h$endian
  if (t == 65526) { x <- readBin(b, "double", n = n, size = 8, endian = e); x[!is.na(x) & x > 8.988e307] <- NA }
  else if (t == 65527) { x <- readBin(b, "double", n = n, size = 4, endian = e); x[!is.na(x) & x > 1.701e38] <- NA }
  else if (t == 65528) { x <- readBin(b, "integer", n = n, size = 4, endian = e); x[!is.na(x) & x > 2147483620] <- NA }
  else if (t == 65529) { x <- readBin(b, "integer", n = n, size = 2, signed = TRUE, endian = e); x[x > 32740] <- NA }
  else if (t == 65530) { x <- readBin(b, "integer", n = n, size = 1, signed = TRUE); x[x > 100] <- NA }
  else if (t <= 2045) {
    mm <- matrix(b, nrow = w)
    x <- apply(mm, 2, function(r) { z <- which(r == as.raw(0)); if (length(z)) r <- r[seq_len(z[1] - 1)]; rawToChar(r) })
  } else stop("strL not supported: ", h$names[j])
  x
}

read_dta_chunked <- function(path, cols, h = dta_header(path), block_rows = 40000, max_rows = Inf) {
  js <- match(cols, h$names)
  if (anyNA(js)) stop("missing cols: ", paste(cols[is.na(js)], collapse = ","))
  N <- min(h$N, max_rows)
  con <- file(path, "rb"); on.exit(close(con))
  seek(con, h$dataStart)
  out <- lapply(js, function(j) vector("list", ceiling(N / block_rows)))
  done <- 0; k <- 0
  while (done < N) {
    nr <- min(block_rows, N - done)
    raw <- readBin(con, "raw", nr * h$rowwidth)
    m <- matrix(raw, nrow = h$rowwidth, ncol = nr)
    k <- k + 1
    for (i in seq_along(js)) out[[i]][[k]] <- decode_col(m, h, js[i])
    done <- done + nr
  }
  res <- lapply(out, function(l) unlist(l[seq_len(k)], use.names = FALSE))
  names(res) <- cols
  as.data.frame(res, stringsAsFactors = FALSE)
}
# ---- Hanushek, Kinne, Lergetporer & Woessmann (2022), Tables 1 and 2 ----
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-07-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/Working/"
suppressMessages({library(haven); library(data.table); library(fixest)})
setFixest_nthreads(1)
t0 <- proc.time()

## ---------------- Table 1: cross-country analysis ----------------
# Data: pisa_full_gps_final.dta (all PISA waves 2000-2018, 49 GPS countries).
# Read with a chunked readBin reader (verified against haven on the first 3000 rows, all 208 columns).
cols <- c("country", "wave", "wgtc", "patience", "risktaking", "age", "image", "female", "imfemale",
          "migra0", "migra1", "migra2", "immigra0", "immigra1", "immigra2", "pv1math")
d <- setDT(read_dta_chunked(paste0(D, "pisa_full_gps_final.dta"), cols, block_rows = 60000))
cat("read main file:", (proc.time() - t0)[["elapsed"]], "s\n")
# pv1math = PISA math score / 100 (checked: pv1math == pv1mathorig/100).
# patience / risktaking: GPS measures z-standardised at the individual level, collapsed to country means
#   (country-level correlation 0.358 as reported in the paper).
# Weights: wgtc = student sampling weight rescaled to sum to 1 within each country (equal country weights).
# Controls: female, age, migration status (migra1, migra2; migra0 = native reference), imputation dummies,
#   wave fixed effects. SEs clustered by country.
d <- d[complete.cases(d)]
ctrl <- "female + age + migra1 + migra2 + imfemale + image + immigra0 + immigra1 + immigra2"
f1 <- as.formula(paste("pv1math ~ patience +", ctrl, "| wave"))
f2 <- as.formula(paste("pv1math ~ risktaking +", ctrl, "| wave"))
f3 <- as.formula(paste("pv1math ~ patience + risktaking +", ctrl, "| wave"))
m1 <- feols(f1, d, weights = ~wgtc, cluster = ~country)
m2 <- feols(f2, d, weights = ~wgtc, cluster = ~country)
m3 <- feols(f3, d, weights = ~wgtc, cluster = ~country)
# Natives: students not classified as migrants (migrant = both parents born abroad, i.e. migra0 == 0)
nat <- d[migra0 != 0]
m5 <- feols(f3, nat, weights = ~wgtc, cluster = ~country)
print(etable(m1, m2, m3, m5, digits = 4, fitstat = ~ n + r2))
cat("countries col3:", uniqueN(d$country), " natives N:", nobs(m5), "\n")
rm(d, nat); invisible(gc())

## ---------------- Table 2: migrant analysis ----------------
# Data: pisa_full_gps_final_imcoo.dta (first/second-generation migrants, both parents born abroad,
# origin country with GPS data, waves 2003-2018). coo_* = country-of-origin GPS measures.
m <- setDT(read_dta(paste0(D, "pisa_full_gps_final_imcoo.dta"),
    col_select = c("country", "wave", "wgt", "coo", "coo_patience", "coo_risktaking", "coo_posrecip", "coo_negrecip",
                   "coo_altruism", "coo_trust", "coo_oecd", "image", "age", "imfemale", "female", "countrywave", "pv1math")))
m <- m[, lapply(.SD, function(x) if (is.labelled(x)) as.vector(zap_labels(x)) else x)]
m <- m[complete.cases(m)]
# Controls: gender, age, OECD-origin dummy, imputation dummies; residence-country-by-wave FE (180 cells);
# weighted by student sampling weight; SEs clustered by country of origin.
c2 <- "female + age + coo_oecd + imfemale + image"
g1 <- as.formula(paste("pv1math ~ coo_patience +", c2, "| countrywave"))
g3 <- as.formula(paste("pv1math ~ coo_patience + coo_risktaking +", c2, "| countrywave"))
g4 <- as.formula(paste("pv1math ~ coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust +", c2, "| countrywave"))
n1 <- feols(g1, m, weights = ~wgt, cluster = ~coo)
n3 <- feols(g3, m, weights = ~wgt, cluster = ~coo)
n4 <- feols(g4, m, weights = ~wgt, cluster = ~coo)
print(etable(n1, n3, n4, digits = 4, fitstat = ~ n + r2))
cat("origin countries:", uniqueN(m$coo), " residence countries:", uniqueN(m$country), " FE cells:", uniqueN(m$countrywave), "\n")
cat("total time:", (proc.time() - t0)[["elapsed"]], "s\n")

co <- function(mod, v) unname(coef(mod)[v])
cat(sprintf("RESULT:table1_col3_patience=%.6f\n", co(m3, "patience")))
cat(sprintf("RESULT:table1_col3_risk_taking=%.6f\n", co(m3, "risktaking")))
cat(sprintf("RESULT:table1_col1_patience=%.6f\n", co(m1, "patience")))
cat(sprintf("RESULT:table1_col2_risk_taking=%.6f\n", co(m2, "risktaking")))
cat(sprintf("RESULT:table1_col5_natives_patience=%.6f\n", co(m5, "patience")))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.6f\n", co(m5, "risktaking")))
cat(sprintf("RESULT:table1_col3_observations=%d\n", nobs(m3)))
cat(sprintf("RESULT:table2_col3_patience=%.6f\n", co(n3, "coo_patience")))
cat(sprintf("RESULT:table2_col3_risk_taking=%.6f\n", co(n3, "coo_risktaking")))
cat(sprintf("RESULT:table2_col1_patience=%.6f\n", co(n1, "coo_patience")))
cat(sprintf("RESULT:table2_col4_patience=%.6f\n", co(n4, "coo_patience")))
cat(sprintf("RESULT:table2_col4_risk_taking=%.6f\n", co(n4, "coo_risktaking")))
cat(sprintf("RESULT:table2_col3_observations=%d\n", nobs(n3)))
