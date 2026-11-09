suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setFixest_nthreads(0)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_ur   <- file.path(base, "v2unemp_smy.csv")
f_cpi  <- file.path(base, "wage_deflation_1994_2016.csv")
f_ind  <- file.path(base, "ind_xwalk2002.csv")
f_occ  <- file.path(base, "occ_xwalk2002.csv")

hdr <- names(fread(f_main, nrows = 0))
has <- function(x) x %in% hdr
cat("Columns in yh_data:", paste(hdr, collapse = ","), "\n")

want <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pemlr",
          "pwsswgt","v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1",
          "v2peio1cow","v2peio1icd","v2peio1ocd","v2pwsswgt","v2peage","v2pesex",
          "hrmis","v2hrmis","v2unemp_smy","gestfips","v2peeduca")
# earnings and allocation flags (names searched)
earn_cands <- hdr[grepl("ernwa|pternwa|prernwa|earnweek|weekly", hdr, ignore.case = TRUE)]
alloc_cands <- hdr[grepl("ernal|prwernal|allocat|ptwk|alloc", hdr, ignore.case = TRUE)]
cat("Earnings candidates:", paste(earn_cands, collapse=","), "\n")
cat("Allocation candidates:", paste(alloc_cands, collapse=","), "\n")
sel <- unique(c(want[sapply(want, has)], earn_cands, alloc_cands))

dt <- fread(f_main, select = sel, showProgress = FALSE)
cat("Rows read:", nrow(dt), "\n")

# ---------- sample restrictions ----------
dt <- dt[!is.na(peage) & !is.na(peeduca) & peeduca > 0]
dt <- dt[peage >= 16]
dt <- dt[pemlr >= 1 & pemlr <= 7 & v2pemlr >= 1 & v2pemlr <= 7]
dt <- dt[!(v2hryear == 1995 & v2hrmonth %in% 5:8)]
dt <- dt[!(hryear == 1995 & hrmonth %in% 5:8)]
if (has("hrmis") && has("v2hrmis")) dt <- dt[!(hrmis == 4 & v2hrmis == 5)]
dt <- dt[(v2hryear > 1994 | (v2hryear == 1994 & v2hrmonth >= 1)) &
         (v2hryear < 2016 | (v2hryear == 2016 & v2hrmonth <= 9))]

# ---------- labor market status ----------
dt[, emp_prev := pemlr %in% 1:2]
dt[, unemp_prev := pemlr %in% 3:4]
dt[, nilf_prev := pemlr %in% 5:7]
dt[, emp_now := v2pemlr %in% 1:2]
if (has("v2peio1cow")) {
  dt[, selfemp_now := v2peio1cow %in% c(6, 7)]
} else dt[, selfemp_now := FALSE]
dt[, changed_emp := !is.na(v2puiodp1) & v2puiodp1 == 2]
dt[, hired := 100 * as.numeric(emp_now & !selfemp_now & ((!emp_prev) | (emp_prev & changed_emp)))]

# ---------- potential experience ----------
edyrs <- c(`31`=0, `32`=3, `33`=6, `34`=8, `35`=9, `36`=10, `37`=11, `38`=12,
           `39`=12, `40`=13, `41`=14, `42`=14, `43`=16, `44`=18, `45`=19, `46`=21)
dt[, yrs_ed := edyrs[as.character(peeduca)]]
dt <- dt[!is.na(yrs_ed)]
dt[, pe := peage - yrs_ed - 6]
dt[, young := as.numeric(pe <= 10)]

dt[, educ7 := fcase(peeduca <= 38, 1L, peeduca == 39, 2L, peeduca %in% 40:42, 3L,
                    peeduca == 43, 4L, peeduca == 44, 5L, peeduca == 45, 6L,
                    peeduca == 46, 7L)]
dt[, white := as.integer(race == 1)]
dt[, hisp := as.integer(prhspnon == 1)]
dt[, demo := paste(pesex, white, hisp, educ7, sep = "_")]

# ---------- weights ----------
if (has("v2pwsswgt")) {
  dt[, w := (pwsswgt + v2pwsswgt) / 2]
} else dt[, w := pwsswgt]
dt <- dt[!is.na(w) & w > 0]

# ---------- unemployment rate ----------
if (!has("v2unemp_smy")) {
  ur <- fread(f_ur)
  dt <- merge(dt, ur, by = c("v2gestfips","v2hryear","v2hrmonth"), all.x = FALSE)
}
dt <- dt[!is.na(v2unemp_smy)]
if (max(dt$v2unemp_smy, na.rm = TRUE) < 1) dt[, v2unemp_smy := 100 * v2unemp_smy]
dt[, ur := v2unemp_smy]
dt[, ur_y := ur * young]
dt[, ur_o := ur * (1 - young)]
dt[, state := v2gestfips]
dt[, ym := v2hryear * 100 + v2hrmonth]

N <- nrow(dt)
cat("N full sample:", N, "\n")

# ---------- Table 1 ----------
pA1 <- feols(hired ~ ur, data = dt, weights = ~w, cluster = ~state)
pA4 <- feols(hired ~ ur | state + demo + ym, data = dt, weights = ~w, cluster = ~state)
pB1 <- feols(hired ~ young + ur_y + ur_o, data = dt, weights = ~w, cluster = ~state)
pB4 <- feols(hired ~ young + ur_y + ur_o | state + demo + ym, data = dt, weights = ~w, cluster = ~state)
print(etable(pA1, pA4, pB1, pB4))

# ---------- Table 2 by origin ----------
fE <- feols(hired ~ young + ur_y + ur_o | state + demo + ym, data = dt[emp_prev == TRUE], weights = ~w, cluster = ~state)
fU <- feols(hired ~ young + ur_y + ur_o | state + demo + ym, data = dt[unemp_prev == TRUE], weights = ~w, cluster = ~state)
fN <- feols(hired ~ young + ur_y + ur_o | state + demo + ym, data = dt[nilf_prev == TRUE], weights = ~w, cluster = ~state)
print(etable(fE, fU, fN))

# ---------- Table 10: wages of new hires ----------
wy <- NA_real_; wo <- NA_real_
earn_var <- NULL
for (cand in c("v2prernwa","v2pternwa","v2earnweek","prernwa","pternwa")) if (cand %in% names(dt)) { earn_var <- cand; break }
if (is.null(earn_var) && length(earn_cands) > 0) {
  v2c <- earn_cands[grepl("^v2", earn_cands)]
  earn_var <- if (length(v2c)) v2c[1] else earn_cands[1]
}
try({
  if (!is.null(earn_var)) {
    h <- dt[hired == 100]
    h[, earn := as.numeric(get(earn_var))]
    h <- h[!is.na(earn) & earn > 0]
    # implied decimals in CPS PRERNWA (2 decimals)
    if (median(h$earn) > 20000) h[, earn := earn / 100]
    # non-allocated
    al <- alloc_cands[grepl("^v2", alloc_cands) & grepl("ernwa|ernal|wernal", alloc_cands)]
    if (length(al)) {
      a <- al[1]
      h <- h[is.na(get(a)) | get(a) %in% c(-1, 0)]
    }
    cpi <- fread(f_cpi)
    base_cpi <- cpi[year == 1994 & month == 1, cpi][1]
    h <- merge(h, cpi, by.x = c("v2hryear","v2hrmonth"), by.y = c("year","month"), all.x = TRUE)
    h[, lw := log(earn * base_cpi / cpi)]

    # code-year period mapping
    start_of <- function(v) {
      s <- c(`1990`=1994, `2000`=2003, `2002`=2003, `2007`=2009, `2010`=2011, `2012`=2014, `2013`=2014)
      out <- s[as.character(v)]; out[is.na(out)] <- v[is.na(out)] + 1; as.numeric(out)
    }
    assign_cy <- function(years, cys) {
      cys <- sort(unique(cys)); st <- start_of(cys)
      sapply(years, function(y) { ok <- which(st <= y); if (length(ok)) cys[max(ok)] else cys[1] })
    }
    ix <- fread(f_ind); ox <- fread(f_occ)
    yrs <- sort(unique(h$v2hryear))
    imap <- data.table(v2hryear = yrs, v2ind_codeyear = assign_cy(yrs, ix$v2ind_codeyear))
    omap <- data.table(v2hryear = yrs, v2occ_codeyear = assign_cy(yrs, ox$v2occ_codeyear))
    h <- merge(h, imap, by = "v2hryear", all.x = TRUE)
    h <- merge(h, omap, by = "v2hryear", all.x = TRUE)
    ix <- unique(ix, by = c("v2peio1icd","v2ind_codeyear"))
    ox <- unique(ox, by = c("v2peio1ocd","v2occ_codeyear"))
    h <- merge(h, ix, by = c("v2peio1icd","v2ind_codeyear"), all.x = TRUE)
    h <- merge(h, ox, by = c("v2peio1ocd","v2occ_codeyear"), all.x = TRUE)
    h[, ind := ifelse(is.na(v2censusind_2002recode), paste0("r", v2ind_codeyear, "_", v2peio1icd), as.character(v2censusind_2002recode))]
    h[, occ := ifelse(is.na(v2censusocc_2002recode), paste0("r", v2occ_codeyear, "_", v2peio1ocd), as.character(v2censusocc_2002recode))]
    h <- h[is.finite(lw)]
    fw <- feols(lw ~ young + ur_y + ur_o | state + demo + ym + ind + occ, data = h, weights = ~w, cluster = ~state)
    print(summary(fw))
    wy <- unname(coef(fw)["ur_y"]); wo <- unname(coef(fw)["ur_o"])
  }
}, silent = FALSE)

fmt <- function(x) format(x, digits = 6, scientific = FALSE)
cat(paste0("RESULT:young_x_unemp_rate_no_controls=", fmt(coef(pB1)["ur_y"]), "\n"))
cat(paste0("RESULT:experienced_x_unemp_rate_no_controls=", fmt(coef(pB1)["ur_o"]), "\n"))
cat(paste0("RESULT:young_x_unemp_rate_preferred=", fmt(coef(pB4)["ur_y"]), "\n"))
cat(paste0("RESULT:experienced_x_unemp_rate_preferred=", fmt(coef(pB4)["ur_o"]), "\n"))
cat(paste0("RESULT:aggregate_unemp_rate_no_controls=", fmt(coef(pA1)["ur"]), "\n"))
cat(paste0("RESULT:aggregate_unemp_rate_month_year_fe=", fmt(coef(pA4)["ur"]), "\n"))
cat(paste0("RESULT:young_x_unemp_rate_employed=", fmt(coef(fE)["ur_y"]), "\n"))
cat(paste0("RESULT:experienced_x_unemp_rate_employed=", fmt(coef(fE)["ur_o"]), "\n"))
cat(paste0("RESULT:young_x_unemp_rate_unemployed=", fmt(coef(fU)["ur_y"]), "\n"))
cat(paste0("RESULT:young_x_unemp_rate_nilf=", fmt(coef(fN)["ur_y"]), "\n"))
cat(paste0("RESULT:wage_young_x_unemp_rate_all_hires=", fmt(wy), "\n"))
cat(paste0("RESULT:wage_experienced_x_unemp_rate_all_hires=", fmt(wo), "\n"))
cat(paste0("RESULT:n_obs_full_sample=", N, "\n"))