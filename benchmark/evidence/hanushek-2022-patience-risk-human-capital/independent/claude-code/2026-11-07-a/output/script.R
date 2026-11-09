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

# Independent reproduction: Hanushek et al. (2022, EJ) "Patience, Risk-Taking, and Human Capital
# Investment across Countries", Table 1 (cols 1,2,3,5) and Table 2 (cols 1,3,4), math scores.
# Data are read with the chunked .dta reader above (identical values to haven::read_dta, but a few
# large reads instead of one read per row, which is what made haven/fread exceed the time limit).
suppressMessages({library(data.table); library(fixest); library(haven)})
set.seed(42)
setFixest_nthreads(1)
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-07-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/Working/"
t0 <- proc.time()

## ---------- Table 2: migrant analysis, eq. (2) ----------
# Sample: migrants (both parents foreign-born) with GPS data for the origin country, waves 2003-2018
# (first generation: country of birth; second generation: father's country of origin; as coded in
# the working file). Outcome pv1math (PISA math / 100). Regressors: origin-country GPS measures
# (z-standardised at the individual level and collapsed to country means, as provided).
# Residence-country x wave FE; controls: gender, age, OECD-origin dummy, imputation dummies;
# weighted by sampling weights; SEs clustered by country of origin.
m <- read_dta118_cols(paste0(B, "pisa_full_gps_final_imcoo.dta"),
  c("country","wave","coo","pv1math","wgt","coo_patience","coo_risktaking","coo_posrecip",
    "coo_negrecip","coo_altruism","coo_trust","coo_oecd","female","age","imfemale","image","countrywave"))
m <- m[wave >= 2003]
cat("Table 2 rows:", nrow(m), " FE cells:", uniqueN(m$countrywave), " origins:", uniqueN(m$coo), "\n")
ctl2 <- "female + age + coo_oecd + imfemale + image"
t2 <- function(rhs) feols(as.formula(paste("pv1math ~", rhs, "+", ctl2, "| countrywave")),
                          data = m, weights = ~wgt, cluster = ~coo)
r21 <- t2("coo_patience")
r23 <- t2("coo_patience + coo_risktaking")
r24 <- t2("coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust")
print(etable(r21, r23, r24))
cat(sprintf("RESULT:table2_col3_patience=%.4f\n", coef(r23)["coo_patience"]))
cat(sprintf("RESULT:table2_col3_risk_taking=%.4f\n", coef(r23)["coo_risktaking"]))
cat(sprintf("RESULT:table2_col1_patience=%.4f\n", coef(r21)["coo_patience"]))
cat(sprintf("RESULT:table2_col4_patience=%.4f\n", coef(r24)["coo_patience"]))
cat(sprintf("RESULT:table2_col4_risk_taking=%.4f\n", coef(r24)["coo_risktaking"]))
cat(sprintf("RESULT:table2_col3_observations=%d\n", nobs(r23)))
flush(stdout()); print(proc.time() - t0)

## ---------- Table 1: cross-country baseline, eq. (1) ----------
# All PISA waves 2000-2018, 49 GPS countries. Controls: gender, age, migration status
# (first/second generation), imputation dummies, wave FE. Weights wgtc = sampling weights
# rescaled to give each country equal weight. SEs clustered by country.
c1 <- c("country","wave","pv1math","wgtc","patience","risktaking","female","age","imfemale","image",
        "migra1","migra2","immigra0","immigra1","immigra2")
x <- read_dta118_cols(paste0(B, "pisa_full_gps_final.dta"), c1)
print(proc.time() - t0)
# reader sanity check against haven on the first 2,000 rows (same column order)
h <- as.data.table(read_dta(paste0(B, "pisa_full_gps_final.dta"), col_select = all_of(c1), n_max = 2000))
h[] <- lapply(h, function(v) { attributes(v) <- NULL; v }); setcolorder(h, c1)
cat("reader check, max abs diff on numeric cols:",
    max(sapply(setdiff(c1, "country"), function(v) max(abs(as.numeric(h[[v]]) - as.numeric(x[[v]][1:2000]))))),
    " country equal:", identical(h$country, x$country[1:2000]), "\n")
cat("rows:", nrow(x), " countries:", uniqueN(x$country), " country-waves:", uniqueN(x[, .(country, wave)]), "\n")
# migra1/migra2 are mean-imputed where missing; immigra* flag imputations (collinear ones dropped)
ctl1 <- "female + age + migra1 + migra2 + imfemale + image + immigra0 + immigra1 + immigra2"
t1 <- function(rhs, d = x) feols(as.formula(paste("pv1math ~", rhs, "+", ctl1, "| wave")),
                                 data = d, weights = ~wgtc, cluster = ~country)
r11 <- t1("patience")
r12 <- t1("risktaking")
r13 <- t1("patience + risktaking")
# Natives: everyone except migrants (both parents born abroad = first or second generation)
nat <- x[!(migra1 %in% 1 | migra2 %in% 1)]
cat("natives:", nrow(nat), "\n")
r15 <- t1("patience + risktaking", nat)
print(etable(r11, r12, r13, r15))
cat(sprintf("RESULT:table1_col3_patience=%.4f\n", coef(r13)["patience"]))
cat(sprintf("RESULT:table1_col3_risk_taking=%.4f\n", coef(r13)["risktaking"]))
cat(sprintf("RESULT:table1_col1_patience=%.4f\n", coef(r11)["patience"]))
cat(sprintf("RESULT:table1_col2_risk_taking=%.4f\n", coef(r12)["risktaking"]))
cat(sprintf("RESULT:table1_col5_natives_patience=%.4f\n", coef(r15)["patience"]))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.4f\n", coef(r15)["risktaking"]))
cat(sprintf("RESULT:table1_col3_observations=%d\n", nobs(r13)))
print(proc.time() - t0)
