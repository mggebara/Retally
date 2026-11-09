# ---- Chunked Stata 117/118/119 reader (readBin on large blocks) ----
dta_header <- function(path) {
  con <- file(path, "rb"); on.exit(close(con))
  hdr <- readBin(con, "raw", 2000000)
  s <- rawToChar(hdr[1:200], multiple = TRUE)
  s <- paste(ifelse(s == "", " ", s), collapse = "")
  rel <- as.integer(sub(".*<release>([0-9]+)</release>.*", "\\1", s))
  le <- grepl("<byteorder>LSF</byteorder>", s)
  endian <- if (le) "little" else "big"
  kpos <- regexpr("<K>", s)[1] + 3   # 1-based position of first K byte
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
suppressMessages(library(haven))
options(width = 200)
for (f in c("pisa_full_gps_final.dta", "pisa_full_gps_final_imcoo.dta")) {
  h <- dta_header(paste0(D, f))
  cat("FILE", f, "release", h$release, "K", h$K, "N", h$N, "rowwidth", h$rowwidth, "\n")
  for (j in seq_len(h$K)) cat(sprintf("%3d %-28s %6d %s\n", j, h$names[j], h$types[j], h$labels[j]))
}
h <- dta_header(paste0(D, "pisa_full_gps_final.dta"))
t0 <- proc.time()
a <- read_dta_chunked(paste0(D, "pisa_full_gps_final.dta"), h$names[h$types >= 65526 | h$types <= 2045], h, block_rows = 3000, max_rows = 3000)
b <- read_dta(paste0(D, "pisa_full_gps_final.dta"), n_max = 3000)
bad <- 0
for (v in names(a)) { x <- a[[v]]; y <- as.vector(zap_labels(b[[v]])); if (is.character(x)) y <- as.character(y)
  ok <- isTRUE(all.equal(x, y, check.attributes = FALSE)); if (!ok) { bad <- bad + 1; cat("MISMATCH", v, head(x), "|", head(y), "\n") } }
cat("verify mismatches:", bad, "of", length(a), "\n"); print(proc.time() - t0)
for (v in c("country", "wave", "migra0", "migra1", "migra2", "oecd")) if (v %in% names(b)) { cat(v, "\n"); print(attr(b[[v]], "labels")) }
