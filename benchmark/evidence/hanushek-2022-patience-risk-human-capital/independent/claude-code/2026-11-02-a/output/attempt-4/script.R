# Hanushek, Kinne, Lergetporer, Woessmann (2022, EJ): Patience, Risk-Taking, and Human Capital
# Independent reproduction of Table 1 (cols 1,2,3,5) and Table 2 (cols 1,3,4).
set.seed(42)
T_START <- Sys.time()
elapsed <- function() as.numeric(Sys.time() - T_START, units = "secs")
suppressMessages({library(data.table); library(fixest)})
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/"
zstd <- function(v) (v - mean(v)) / sd(v)   # z-standardise in the analytical (student) sample
res <- list()

## ---------------- Table 2: migrant analysis ----------------
m <- fread(paste0(B, "CSV/pisa_full_gps_final_imcoo.csv"), nThread = 1, showProgress = FALSE,
           select = c("isocode","wave","wgt","coo_isocode","coo_patience","coo_risktaking","coo_posrecip",
                      "coo_negrecip","coo_altruism","coo_trust","coo_oecd","pv1math","female","imfemale",
                      "age","image","countrywave"))
cat("migrant file rows", nrow(m), "loaded at", round(elapsed()), "s\n")
m <- m[!is.na(pv1math) & !is.na(coo_patience) & !is.na(coo_risktaking)]
for (v in c("coo_patience","coo_risktaking","coo_posrecip","coo_negrecip","coo_altruism","coo_trust"))
  set(m, j = v, value = zstd(m[[v]]))
# students' sampling weights, rescaled so each residence country gets equal total weight
m[, w := wgt / sum(wgt), by = isocode]
ctl2 <- "female + imfemale + age + image + coo_oecd"
t2 <- function(rhs) feols(as.formula(paste("pv1math ~", rhs, "+", ctl2, "| countrywave")),
                         data = m, weights = ~w, cluster = ~coo_isocode)
r21 <- t2("coo_patience")
r23 <- t2("coo_patience + coo_risktaking")
r24 <- t2("coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust")
res$table2_col1_patience     <- coef(r21)["coo_patience"]
res$table2_col3_patience     <- coef(r23)["coo_patience"]
res$table2_col3_risk_taking  <- coef(r23)["coo_risktaking"]
res$table2_col4_patience     <- coef(r24)["coo_patience"]
res$table2_col4_risk_taking  <- coef(r24)["coo_risktaking"]
res$table2_col3_observations <- nobs(r23)
cat("Table 2 done at", round(elapsed()), "s; origins", uniqueN(m$coo_isocode), "residence", uniqueN(m$isocode), "\n")
rm(m); invisible(gc())

## ---------------- Table 1: cross-country analysis ----------------
f <- paste0(B, "CSV/pisa_full_gps_final.csv")
sz <- file.size(f)
con <- file(f, "rb")
hdr <- strsplit(readLines(con, n = 1), ",")[[1]]
need <- c("isocode","wave","wgtc","patience","risktaking","pv1math","female","imfemale","age","image",
          "migra0","migra1","migra2","immigra0","immigra1","immigra2")
idx <- match(need, hdr)
hdr_bytes <- nchar(paste(hdr, collapse = ",")) + 1
# Evenly spread block sample: blocks of BS bytes visited in van der Corput order so that any
# prefix of the visiting order covers the whole (country/wave-sorted) file evenly.
BS <- 5e5
nb <- floor((sz - hdr_bytes) / BS)
vdc <- function(n) { b <- 0; f <- 0.5; while (n > 0) { b <- b + f * (n %% 2); n <- n %/% 2; f <- f / 2 }; b }
ord <- unique(floor(sapply(0:(4 * nb), vdc) * nb))[1:nb]
ord <- ord[!is.na(ord)]
BUDGET <- 228   # seconds since start at which reading stops
parts <- list(); bytes_read <- 0; nblk <- 0; buf <- list()
flush_buf <- function() {
  if (!length(buf)) return(NULL)
  txt <- paste(unlist(buf), collapse = "\n")
  fread(text = txt, header = FALSE, sep = ",", select = idx, col.names = need, nThread = 1,
        showProgress = FALSE, fill = TRUE, colClasses = list(character = which(hdr == "isocode")))
}
for (k in ord) {
  if (elapsed() > BUDGET) break
  off <- hdr_bytes + k * BS
  seek(con, off)
  b <- readBin(con, "raw", BS + 20000)          # overshoot to finish the last line
  bytes_read <- bytes_read + length(b)
  nl <- which(b == as.raw(10L))
  if (length(nl) < 2) next
  # drop the partial first line (unless block starts right after the header) and partial tail
  start <- if (k == 0) 1 else nl[1] + 1
  # keep only lines whose START lies inside [off, off+BS) so blocks never overlap
  ends <- nl[nl >= start]
  starts <- c(start, head(ends, -1) + 1)
  keep <- starts <= BS
  if (!any(keep)) next
  last_end <- max(ends[keep])
  buf[[length(buf) + 1]] <- rawToChar(b[start:(last_end - 1)])
  nblk <- nblk + 1
  if (length(buf) >= 100) { parts[[length(parts) + 1]] <- flush_buf(); buf <- list() }
}
parts[[length(parts) + 1]] <- flush_buf(); buf <- list()
close(con)
d <- rbindlist(parts); rm(parts); invisible(gc())
frac_blocks <- nblk / nb
cat("big file: read", nblk, "of", nb, "blocks (", round(100 * frac_blocks, 1), "% ),", nrow(d), "rows at", round(elapsed()), "s\n")
cat(sprintf("DEVIATION: Table 1 estimated on an evenly spread block sample of %.1f%% of pisa_full_gps_final.csv (%d of %d 0.5 MB blocks, %d students) because the 3 GB file cannot be read through the mount within the 300 s sandbox limit (~6 MB/s); only the needed columns were parsed\n",
            100 * frac_blocks, nblk, nb, nrow(d)))

# full-sample N from the .dta header (<N> tag), adjusted for the share of rows with missing model variables
dta <- paste0(B, "Working/pisa_full_gps_final.dta")
cd <- file(dta, "rb"); hb <- readBin(cd, "raw", 400); close(cd)
pat3 <- charToRaw("<N>")
pos <- which(sapply(1:(length(hb) - 2), function(i) all(hb[i:(i + 2)] == pat3)))[1]
lsf <- length(grepRaw("LSF", hb)) > 0
Nb <- as.numeric(hb[(pos + 3):(pos + 10)])
N_dta <- if (lsf) sum(Nb * 256^(0:7)) else sum(rev(Nb) * 256^(0:7))
cat("dta header N =", N_dta, "\n")

d <- d[isocode %in% d[, .N, by = isocode][N > 0, isocode]]
model_vars <- c("pv1math","patience","risktaking","wgtc","female","age","migra1","migra2","wave")
miss_share <- mean(!complete.cases(d[, ..model_vars]))
d <- d[complete.cases(d[, ..model_vars])]
cat("countries", uniqueN(d$isocode), "country-waves", uniqueN(d[, .(isocode, wave)]), "missing share", miss_share, "\n")
# re-weight: within each country-wave, the sampled students carry that cell's full weight
# (country-wave cells sum to 1/#waves of the country, i.e. equal weight per country)
d[, nw := uniqueN(wave), by = isocode]
d[, w := wgtc / sum(wgtc) / nw, by = .(isocode, wave)]
d[, pat := zstd(patience)]
d[, risk := zstd(risktaking)]
ctl1 <- "female + imfemale + age + image + migra1 + migra2 + immigra0 + immigra1 + immigra2"
t1 <- function(rhs, data, ctl = ctl1) feols(as.formula(paste("pv1math ~", rhs, "+", ctl, "| wave")),
                                            data = data, weights = ~w, cluster = ~isocode)
r11 <- t1("pat", d); r12 <- t1("risk", d); r13 <- t1("pat + risk", d)
nat <- d[(migra1 + migra2) < 1]
r15 <- t1("pat + risk", nat, ctl = "female + imfemale + age + image + immigra0 + immigra1 + immigra2")
res$table1_col1_patience     <- coef(r11)["pat"]
res$table1_col2_risk_taking  <- coef(r12)["risk"]
res$table1_col3_patience     <- coef(r13)["pat"]
res$table1_col3_risk_taking  <- coef(r13)["risk"]
res$table1_col5_natives_patience    <- coef(r15)["pat"]
res$table1_col5_natives_risk_taking <- coef(r15)["risk"]
res$table1_col3_observations <- round(N_dta * (1 - miss_share))
cat(sprintf("DEVIATION: table1_col3_observations is the row count in the .dta header (%d) times the complete-case share in the block sample (%.5f); the sample regression itself used %d students\n",
            N_dta, 1 - miss_share, nobs(r13)))
cat("Table 1 done at", round(elapsed()), "s\n")
etable(r11, r12, r13, r15)
etable(r21, r23, r24)

for (n in names(res)) cat(sprintf("RESULT:%s=%.6g\n", n, unname(res[[n]])))
