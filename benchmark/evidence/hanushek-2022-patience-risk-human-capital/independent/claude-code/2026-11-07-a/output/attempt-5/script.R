# Chunked reader for Stata .dta format 118 (little-endian): reads the data section in large
# blocks with readBin (few big reads instead of one small read per row) and decodes only the
# requested columns. Stata missing values become NA; strings are trimmed of padding.
read_dta118_cols <- function(path, cols, chunk_rows = 100000L) {
  con <- file(path, "rb"); on.exit(close(con))
  hdr <- readBin(con, "raw", 4096L)
  at <- function(tag) grepRaw(charToRaw(tag), hdr, fixed = TRUE)[1]
  stopifnot(rawToChar(hdr[at("<release>") + 9:11]) == "118",
            rawToChar(hdr[at("<byteorder>") + 11:13]) == "LSF")
  u64 <- function(b) { v <- readBin(b, "integer", 2L, size = 4L, endian = "little"); (v[1] %% 2^32) + (v[2] %% 2^32) * 2^32 }
  K <- readBin(hdr[at("<K>") + 3:4], "integer", 1L, size = 2L, signed = FALSE, endian = "little")
  N <- u64(hdr[at("<N>") + 3:10])
  mp <- at("<map>") + 5L
  map <- vapply(0:13, function(i) u64(hdr[mp + i * 8L + 0:7]), 0)
  seek(con, map[3] + 16); types <- readBin(con, "integer", K, size = 2L, signed = FALSE, endian = "little")
  seek(con, map[4] + 10); nmraw <- readBin(con, "raw", K * 129L)
  nms <- vapply(seq_len(K), function(j) { b <- nmraw[(j - 1L) * 129L + 1:129]; rawToChar(b[seq_len(which(b == as.raw(0))[1] - 1L)]) }, "")
  width <- ifelse(types <= 2045L, types, ifelse(types == 32768L, 8L,
           c(`65526` = 8L, `65527` = 4L, `65528` = 4L, `65529` = 2L, `65530` = 1L)[as.character(types)]))
  stopifnot(!anyNA(width), all(cols %in% nms))
  off <- cumsum(c(0L, width))[seq_len(K)]
  L <- sum(width)
  sel <- match(cols, nms)
  seek(con, map[10] + 6)
  out <- setNames(replicate(length(cols), list(), simplify = FALSE), cols)
  done <- 0
  while (done < N) {
    n <- as.integer(min(chunk_rows, N - done))
    m <- matrix(readBin(con, "raw", n * L), nrow = L)
    stopifnot(ncol(m) == n)
    for (k in seq_along(sel)) {
      j <- sel[k]; t <- types[j]; w <- width[j]
      b <- as.vector(m[off[j] + seq_len(w), , drop = FALSE])
      v <- if (t == 65526L) { x <- readBin(b, "double", n, size = 8L, endian = "little"); x[x > 8.988465674311579e307] <- NA; x
      } else if (t == 65527L) { x <- readBin(b, "double", n, size = 4L, endian = "little"); x[x > 1.701411733e38] <- NA; x
      } else if (t == 65528L) { x <- readBin(b, "integer", n, size = 4L, endian = "little"); x[x > 2147483620L] <- NA; x
      } else if (t == 65529L) { x <- readBin(b, "integer", n, size = 2L, signed = TRUE, endian = "little"); x[x > 32740L] <- NA; x
      } else if (t == 65530L) { x <- readBin(b, "integer", n, size = 1L, signed = TRUE); x[x > 100L] <- NA; x
      } else if (t <= 2045L) { sm <- matrix(b, nrow = w); z <- as.raw(0)
        vapply(seq_len(n), function(i) { r <- sm[, i]; rawToChar(r[seq_len(match(z, r, nomatch = w + 1L) - 1L)]) }, "")
      } else stop("strL column not supported: ", cols[k])
      out[[k]][[length(out[[k]]) + 1L]] <- v
    }
    done <- done + n
  }
  data.table::as.data.table(lapply(out, function(p) do.call(c, p)))
}

# ---- Exploratory checks (no estimates) ----
suppressMessages({library(data.table); library(haven)})
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-07-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/Working/"
c1 <- c("country","wave","pv1math","wgtc","patience","risktaking","female","age","imfemale","image",
        "migra1","migra2","immigra0","immigra1","immigra2")
c2 <- c("country","wave","coo","pv1math","wgt","coo_patience","coo_risktaking","coo_posrecip","coo_negrecip",
        "coo_altruism","coo_trust","coo_oecd","female","age","imfemale","image","countrywave")
strip <- function(d) { d <- as.data.table(d); d[] <- lapply(d, function(v) { attributes(v) <- NULL; v }); d }
# 1) correctness vs haven on the first 30,000 rows of the big file, then a timed full read
h <- strip(read_dta(paste0(B, "pisa_full_gps_final.dta"), col_select = all_of(c1), n_max = 30000))
t0 <- proc.time()
x <- read_dta118_cols(paste0(B, "pisa_full_gps_final.dta"), c1, chunk_rows = 100000L)
cat("full big-file read:\n"); print(proc.time() - t0)
cat("rows:", nrow(x), " countries:", uniqueN(x$country), " country-waves:", uniqueN(x[, .(country, wave)]), "\n")
cat("first 30k identical to haven:\n"); print(all.equal(h, x[1:30000], check.attributes = FALSE))
print(sapply(x, function(v) sum(is.na(v))))
# 2) migrant file vs haven
t0 <- proc.time()
m <- read_dta118_cols(paste0(B, "pisa_full_gps_final_imcoo.dta"), c2)
print(proc.time() - t0)
hm <- strip(read_dta(paste0(B, "pisa_full_gps_final_imcoo.dta"), col_select = all_of(c2)))
cat("imcoo identical to haven:\n"); print(all.equal(hm, m, check.attributes = FALSE))
cat("imcoo rows:", nrow(m), " coo:", uniqueN(m$coo), " cw:", uniqueN(m$countrywave), " waves:", paste(sort(unique(m$wave)), collapse = ","), "\n")
