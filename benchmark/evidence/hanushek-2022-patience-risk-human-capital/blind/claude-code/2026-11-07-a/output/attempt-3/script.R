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
D <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-07-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/Working/"
suppressMessages({library(haven); library(data.table)})
options(width = 200)
t0 <- proc.time()
cols <- c("isocode", "country", "wave", "oecd", "wgt", "wgtc", "patience", "risktaking", "posrecip", "negrecip", "altruism", "trust",
          "age", "image", "female", "imfemale", "migra0", "migra1", "migra2", "immigra0", "immigra1", "immigra2",
          "pv1math", "pv1mathorig", "stubrncnt", "fatbrncnt", "motbrncnt", "nonresp", "mmnonresp")
d <- setDT(read_dta_chunked(paste0(D, "pisa_full_gps_final.dta"), cols, block_rows = 40000))
print(proc.time() - t0)
cat("N", nrow(d), "countries", uniqueN(d$country), "isocodes", uniqueN(d$isocode), "\n")
print(d[, .N, by = wave][order(wave)])
print(summary(d[, .(pv1math, pv1mathorig, age, female, migra0, migra1, migra2, wgt, wgtc, patience, risktaking)]))
for (v in c("migra0", "migra1", "migra2", "immigra0", "immigra1", "immigra2", "imfemale", "image", "female", "oecd")) { cat(v, "\n"); print(table(d[[v]], useNA = "ifany")) }
print(head(table(round(d$migra0, 3), round(d$migra1, 3), useNA = "ifany"), 20))
print(table(paste(d$migra0, d$migra1, d$migra2, d$immigra0)))
cat("pv1math vs orig/100: "); print(summary(d$pv1math - d$pv1mathorig / 100))
cw <- d[, .(N = .N, sw = sum(wgtc), sw2 = sum(wgt), pat = mean(patience), sdp = sd(patience), risk = mean(risktaking)), by = country]
print(cw[order(country)])
cat("country-level mean/sd patience", mean(cw$pat), sd(cw$pat), "risk", mean(cw$risk), sd(cw$risk), "\n")
cat("student-level weighted mean/sd patience (wgtc)", weighted.mean(d$patience, d$wgtc), sqrt(weighted.mean((d$patience - weighted.mean(d$patience, d$wgtc))^2, d$wgtc)), "\n")
cat("student-level unweighted mean/sd patience", mean(d$patience), sd(d$patience), "risk", mean(d$risktaking), sd(d$risktaking), "\n")
cat("cor country patience risk", cor(cw$pat, cw$risk), "\n")
print(d[, .(sw = sum(wgt)), by = .(country, wave)][, summary(sw)])
cat("NA counts\n"); print(sapply(d, function(x) sum(is.na(x))))
m <- setDT(read_dta(paste0(D, "pisa_full_gps_final_imcoo.dta"),
    col_select = c("country", "isocode", "wave", "wgt", "coo", "coo_isocode", "coo_patience", "coo_risktaking", "coo_posrecip", "coo_negrecip",
                   "coo_altruism", "coo_trust", "coo_oecd", "image", "age", "imfemale", "female", "countrywave", "pv1math", "migra0", "migra1", "migra2",
                   "stubrncnt", "fatbrncnt", "motbrncnt", "coo_patience_orig")))
m <- m[, lapply(.SD, function(x) if (is.labelled(x)) as.vector(zap_labels(x)) else x)]
cat("imcoo N", nrow(m), "res countries", uniqueN(m$country), "coo", uniqueN(m$coo), "countrywave", uniqueN(m$countrywave), "\n")
print(m[, .N, by = wave][order(wave)])
print(summary(m))
for (v in c("migra0", "migra1", "migra2", "coo_oecd", "imfemale", "image", "stubrncnt", "fatbrncnt", "motbrncnt")) { cat(v, "\n"); print(table(m[[v]], useNA = "ifany")) }
cc <- m[, .(pat = coo_patience[1], risk = coo_risktaking[1], n = .N), by = coo]
cat("coo-level mean/sd patience", mean(cc$pat), sd(cc$pat), "risk", mean(cc$risk), sd(cc$risk), "\n")
cat("student-level mean/sd coo patience", mean(m$coo_patience, na.rm = TRUE), sd(m$coo_patience, na.rm = TRUE), "\n")
cat("wgt sum by country-wave\n"); print(m[, .(sw = sum(wgt)), by = countrywave][, summary(sw)])
print(proc.time() - t0)
