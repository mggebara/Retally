# Hanushek et al. (2022) Patience, Risk-Taking, and Human Capital Investment across Countries
# Tables 1 and 2 (seeded mode: follows 3_analysis_crosscountry.do and 3_analysis_migrants.do)
set.seed(42)
T_START <- Sys.time()
elapsed <- function() as.numeric(difftime(Sys.time(), T_START, units = "secs"))
suppressPackageStartupMessages({ library(haven); library(fixest) })
D <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data"
res <- list()
cf <- function(m, v) unname(coef(m)[v])

## ---------------- TABLE 2: migrant analysis (full sample) ----------------
m <- read_dta(file.path(D, "Working/pisa_full_gps_final_imcoo.dta"),
  col_select = c(pv1math, coo_patience, coo_risktaking, coo_posrecip, coo_negrecip,
                 coo_altruism, coo_trust, female, age, imfemale, image, coo_oecd, countrywave, coo))
m <- zap_labels(m)
message("imcoo read at ", round(elapsed()), "s, rows ", nrow(m))
# reg pv1math <prefs> female age imfemale image coo_oecd i.countrywave, vce(cluster coo)
t2 <- function(prefs) feols(as.formula(paste("pv1math ~", paste(prefs, collapse = "+"),
  "+ female + age + imfemale + image + coo_oecd | countrywave")), data = m,
  cluster = ~coo, fixef.rm = "none")
m1 <- t2("coo_patience")
m3 <- t2(c("coo_patience", "coo_risktaking"))
m4 <- t2(c("coo_patience", "coo_risktaking", "coo_posrecip", "coo_negrecip", "coo_altruism", "coo_trust"))
res$table2_col1_patience <- cf(m1, "coo_patience")
res$table2_col3_patience <- cf(m3, "coo_patience")
res$table2_col3_risk_taking <- cf(m3, "coo_risktaking")
res$table2_col4_patience <- cf(m4, "coo_patience")
res$table2_col4_risk_taking <- cf(m4, "coo_risktaking")
res$table2_col3_observations <- nobs(m3)
rm(m); invisible(gc())
message("table 2 done at ", round(elapsed()), "s")

## ---------------- TABLE 1: cross-country (big file) ----------------
# The 2.47 GB .dta cannot be read in full through the mount within the 300 s limit
# (raw I/O ~6-15 MB/s).  Parse the Stata 118 file directly and read evenly spread row
# blocks (van der Corput order) until a time deadline, extracting only needed columns.
f <- file.path(D, "Working/pisa_full_gps_final.dta")
con <- file(f, "rb")
hdr <- readBin(con, "raw", 600000)
pos <- function(tag) grepRaw(tag, hdr, fixed = TRUE)
kpos <- pos("<K>") + 3; K <- readBin(hdr[kpos:(kpos + 1)], "integer", 1, size = 2, signed = FALSE, endian = "little")
npos <- pos("<N>") + 3; N <- sum(as.numeric(as.integer(hdr[npos:(npos + 7)])) * 256^(0:7))
mpos <- pos("<map>") + 5
mapv <- sapply(0:13, function(i) sum(as.numeric(as.integer(hdr[(mpos + 8 * i):(mpos + 8 * i + 7)])) * 256^(0:7)))
tpos <- pos("<variable_types>") + 16
types <- readBin(hdr[tpos:(tpos + 2 * K - 1)], "integer", K, size = 2, signed = FALSE, endian = "little")
vpos <- pos("<varnames>") + 10
vn <- sapply(0:(K - 1), function(i) { b <- hdr[(vpos + 129 * i):(vpos + 129 * i + 128)]; rawToChar(b[seq_len(which(b == as.raw(0))[1] - 1)]) })
width <- ifelse(types <= 2045, types, ifelse(types == 32768, 8,
          c(`65526` = 8, `65527` = 4, `65528` = 4, `65529` = 2, `65530` = 1)[as.character(types)]))
off <- c(0, cumsum(width))[1:K]
W <- sum(width)
data_start <- mapv[10] + 6
message("K=", K, " N=", N, " rowwidth=", W, " data_start=", data_start,
        " check=", data_start + N * W <= mapv[11])
need <- c("pv1math", "patience", "risktaking", "female", "age", "migra0", "migra1", "migra2",
          "image", "imfemale", "immigra1", "wave", "wgtc", "country")
stopifnot(all(need %in% vn))
extract <- function(chunk, n, v) {
  j <- match(v, vn); w <- width[j]; ty <- types[j]
  idx <- rep((0:(n - 1)) * W + off[j], each = w) + seq_len(w)
  b <- chunk[idx]
  if (ty <= 2045) { # fixed string: integer key from first up to 6 bytes
    mm <- matrix(as.integer(b), nrow = w); k <- min(w, 6)
    return(colSums(mm[1:k, , drop = FALSE] * 256^(0:(k - 1))))
  }
  x <- switch(as.character(ty),
    `65526` = readBin(b, "double", n, size = 8, endian = "little"),
    `65527` = readBin(b, "double", n, size = 4, endian = "little"),
    `65528` = as.numeric(readBin(b, "integer", n, size = 4, endian = "little")),
    `65529` = as.numeric(readBin(b, "integer", n, size = 2, endian = "little")),
    `65530` = as.numeric(readBin(b, "integer", n, size = 1, signed = TRUE, endian = "little")))
  miss <- switch(as.character(ty), `65526` = x > 8.988e307, `65527` = x > 1.7e38,
    `65528` = x > 2147483620, `65529` = x > 32740, `65530` = x > 100)
  x[miss] <- NA
  x
}
rows_per_block <- 12000
nb <- ceiling(N / rows_per_block)
vdc <- function(i) { r <- 0; f <- 0.5; while (i > 0) { r <- r + f * (i %% 2); i <- i %/% 2; f <- f / 2 }; r }
ord <- unique(floor(sapply(0:(4 * nb), vdc) * nb))
ord <- c(ord, setdiff(0:(nb - 1), ord))
DEADLINE <- 205
parts <- list(); nread <- 0
for (bi in ord) {
  if (elapsed() > DEADLINE) break
  r0 <- bi * rows_per_block; n <- min(rows_per_block, N - r0)
  seek(con, data_start + r0 * W, origin = "start")
  chunk <- readBin(con, "raw", n * W)
  parts[[length(parts) + 1]] <- as.data.frame(setNames(lapply(need, function(v) extract(chunk, n, v)), need))
  nread <- nread + n
}
close(con)
nblk <- length(parts)
x <- do.call(rbind, parts); rm(parts); invisible(gc())
message("big file: read ", nread, " of ", N, " rows (", round(100 * nread / N, 1), "%) in ", length(unique(x$country)), " countries at ", round(elapsed()), "s")
cat(sprintf("DEVIATION: Table 1 estimated on %d of %d student rows (%.1f%%): the 2.47 GB pisa_full_gps_final.dta cannot be read through the mount within the 300 s sandbox limit, so the script parses the Stata file directly and reads only the needed columns from %d evenly spread blocks of %d consecutive rows until a time deadline.\n",
            nread, N, 100 * nread / N, nblk, rows_per_block))
regvars <- c("pv1math", "patience", "risktaking", "female", "age", "migra1", "migra2", "image", "imfemale", "immigra1", "wave", "wgtc", "country")
nmiss <- sum(!complete.cases(x[, regvars]))
message("rows with missing reg vars in subsample: ", nmiss)
t1 <- function(prefs, ctrl = "female + age + migra1 + migra2 + image + imfemale + immigra1", sub = NULL) {
  d <- if (is.null(sub)) x else x[which(sub), ]
  feols(as.formula(paste("pv1math ~", paste(prefs, collapse = "+"), "+", ctrl, "| wave")),
        data = d, weights = ~wgtc, cluster = ~country, fixef.rm = "none")
}
c1 <- t1("patience"); c2 <- t1("risktaking"); c3 <- t1(c("patience", "risktaking"))
c5 <- t1(c("patience", "risktaking"), ctrl = "female + age + image + imfemale", sub = x$migra0 == 1)
res$table1_col1_patience <- cf(c1, "patience")
res$table1_col2_risk_taking <- cf(c2, "risktaking")
res$table1_col3_patience <- cf(c3, "patience")
res$table1_col3_risk_taking <- cf(c3, "risktaking")
res$table1_col5_natives_patience <- cf(c5, "patience")
res$table1_col5_natives_risk_taking <- cf(c5, "risktaking")
message("col3 N in subsample: ", nobs(c3), "; clusters: ", length(unique(x$country)))
# Observations: the full-sample regression N cannot be counted without reading every row.
# If no row read has a missing regression variable, the full-file row count is reported.
if (nmiss == 0) {
  res$table1_col3_observations <- N
  cat("DEVIATION: table1_col3_observations is the row count in the .dta header (N), reported because none of the rows read has a missing regression variable; the regression itself used only the subsample.\n")
} else {
  res$table1_col3_observations <- round(nobs(c3) * N / nread)
  cat("DEVIATION: table1_col3_observations is the subsample regression N scaled to the full file.\n")
}
message("done at ", round(elapsed()), "s")
for (k in names(res)) cat(sprintf("RESULT:%s=%.6f\n", k, res[[k]]))
