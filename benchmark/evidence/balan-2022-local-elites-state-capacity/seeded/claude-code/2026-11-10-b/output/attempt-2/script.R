# Reproduction of Balan et al. (2022), "Local Elites as State Capacity"
# Seeded mode: translates 2_Data_Construction.do (construction of analysis_data.dta)
# and the regressions of Table4.do, Table5.do, Table6.do, Table7.do, Table8.do
# that produce the listed claims.
suppressPackageStartupMessages({
  library(haven); library(readxl); library(data.table); library(fixest)
})
set.seed(42)

ROOT <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/seeded/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
A <- file.path(ROOT, "admin_data"); S <- file.path(ROOT, "survey_data")

rd <- function(f, cols = NULL) {
  d <- read_dta(f, col_select = if (is.null(cols)) tidyselect::everything() else tidyselect::any_of(cols))
  d <- zap_labels(zap_missing(d))
  as.data.table(d)
}
# Stata %td day number (days since 1960-01-01)
td <- function(s) as.numeric(as.Date(s) - as.Date("1960-01-01"))
dnum <- function(x) as.numeric(as.Date(x) - as.Date("1960-01-01"))

# Stata "merge" without update: full join; for overlapping (non-key) variables the
# master value is kept for observations present in the master, the using value otherwise.
stata_merge <- function(m, u, by) {
  m <- copy(m); u <- copy(u)
  m[, .in_m := TRUE]; u[, .in_u := TRUE]
  common <- setdiff(intersect(names(m), names(u)), c(by, ".in_m", ".in_u"))
  if (length(common)) setnames(u, common, paste0(common, ".__u"))
  r <- merge(m, u, by = by, all = TRUE, sort = TRUE)
  r[is.na(.in_m), .in_m := FALSE]; r[is.na(.in_u), .in_u := FALSE]
  for (v in common) {
    uv <- paste0(v, ".__u")
    if (class(r[[v]])[1] == class(r[[uv]])[1]) {
      r[!(.in_m), (v) := get(uv)]
    }
    r[, (uv) := NULL]
  }
  r[, `_merge` := ifelse(.in_m & .in_u, 3L, ifelse(.in_m, 1L, 2L))]
  r[, c(".in_m", ".in_u") := NULL]
  r
}

pilot_a7 <- c(200, 201, 202, 203, 207, 208, 210)

## ---------------------------------------------------------------- assignment
asg <- rd(file.path(A, "randomization_schedule.dta"), c("a7", "treatment", "month"))
asg <- rbind(asg, data.table(a7 = c(201, 202, 203, 210, 200, 207, 208),
                             treatment = c(2, 1, 1, 2, 1, 2, 4), month = 0))
asg[a7 == 654, treatment := 2]
setnames(asg, "treatment", "tmt")

## ---------------------------------------------------------------- fliers
fl <- rd(file.path(A, "fliers_campaign.dta"), c("a7", "code", "treatment_fr", "rate"))
fl <- fl[!(a7 %in% pilot_a7), .(code, treatment_fr, rate)]
p1 <- as.data.table(read_excel(file.path(A, "fliers_pilot_set1.xlsx")))[, .(code, treatment_fr, rate = rate_rand)]
p2 <- as.data.table(read_excel(file.path(A, "fliers_pilot_set2.xlsx")))[, .(code, treatment_fr, rate)]
p3 <- as.data.table(read_excel(file.path(A, "fliers_pilot_set3.xlsx")))[, .(code, treatment_fr, rate)]
for (p in list(p1, p2, p3)) { p[, code := as.numeric(code)]; p[, rate := suppressWarnings(as.numeric(rate))] }
fl <- rbind(fl, p1, p2, p3)
setnames(fl, c("code", "rate"), c("compound1", "assign_flier_rate"))
s <- ifelse(is.na(fl$compound1), ".", format(fl$compound1, scientific = FALSE, trim = TRUE))
fl[, a7 := suppressWarnings(as.numeric(ifelse(nchar(s) == 6, substr(s, 1, 3),
                                         ifelse(nchar(s) == 7, substr(s, 1, 4), NA))))]
fl <- fl[, .(a7, compound1, assign_flier_rate)]

## ---------------------------------------------------------------- registration (carto)
reg <- rd(file.path(A, "registration_noPII.dta"),
          c("compound1", "a7", "today", "tot_complete", "house", "mm_rate", "exempt", "exempt_other", "pilot"))
reg <- reg[tot_complete == 1]
reg[, today_carto := dnum(today)][, c("today", "tot_complete") := NULL]

## ---------------------------------------------------------------- taxroll
tr <- rd(file.path(A, "taxroll_noPII.dta"), c("compound1", "a7"))

## ---------------------------------------------------------------- midline (monitoring)
mid <- rd(file.path(S, "midline_noPII.dta"),
          c("compound", "a7", "start", "end", "tot_complete", "possible_compound", "visited", "visits",
            "code_same", "visits_other1a", "visits_other2a", "visits_other1b", "visits_other2b"))
setnames(mid, "compound", "compound1")
mid[possible_compound %in% c(0, 999999, 9999999), possible_compound := NA]
mid[compound1 == 999999 & !is.na(possible_compound), compound1 := possible_compound]
mid <- mid[!(compound1 %in% 999999) & !is.na(compound1)]
mid[, max_tc := suppressWarnings(max(tot_complete, na.rm = TRUE)), by = compound1]
mid[is.infinite(max_tc), max_tc := NA]
# Stata: drop if tot_complete != max_tot_complete (missing treated as +inf)
neq <- with(mid, ifelse(is.na(tot_complete) & is.na(max_tc), FALSE,
                 ifelse(is.na(tot_complete) | is.na(max_tc), TRUE, tot_complete != max_tc)))
mid <- mid[!neq]
mid[, st := as.numeric(start)][, en := as.numeric(end)]
setorder(mid, compound1, st, en, na.last = TRUE)
mid <- mid[, .SD[.N], by = compound1]
mid[, c("st", "en", "start", "end", "max_tc", "possible_compound", "tot_complete") := NULL]

## ---------------------------------------------------------------- TDM tax payments
tp <- rd(file.path(A, "tax_payments_noPII.dta"), c("compound1", "a7", "house", "amountCF", "date", "unmatched_compound"))
tp <- tp[!(unmatched_compound %in% 1) & !is.na(compound1)]
tp[, date_TDM := dnum(date)][, c("date", "unmatched_compound") := NULL]

## ---------------------------------------------------------------- stratum
st <- rd(file.path(A, "stratum.dta"), c("a7", "stratum"))

## ---------------------------------------------------------------- merge
d <- merge(fl, st, by = "a7", all.x = TRUE, sort = FALSE)
d <- merge(d, asg[, .(a7, tmt)], by = "a7", all.x = TRUE, sort = FALSE)
d <- stata_merge(d, reg, "compound1"); setnames(d, "_merge", "m_carto")
d <- stata_merge(d, tr, "compound1"); setnames(d, "_merge", "m_rep")
d <- stata_merge(d, mid, "compound1"); d <- d[`_merge` != 2]; setnames(d, "_merge", "m_monit")
d <- stata_merge(d, tp, "compound1")
d <- d[!(m_carto %in% 1 & m_rep %in% 1 & m_monit %in% 1)]

## ---------------------------------------------------------------- outcomes
d[, taxes_paid := as.numeric(`_merge` == 3)]
d[taxes_paid == 0 & code_same %in% 1, taxes_paid := 1]
d[house %in% 1 & `_merge` == 3 & !is.na(amountCF) & !is.na(assign_flier_rate) & assign_flier_rate > amountCF, taxes_paid := 0]
d[house %in% 2 & `_merge` == 3 & !is.na(amountCF) & !is.na(mm_rate) & mm_rate > amountCF, taxes_paid := 0]
d[, rate := NA_real_]
d[house %in% 1, rate := assign_flier_rate]
d[house %in% 2, rate := mm_rate]

## ---------------------------------------------------------------- analysis data
d <- d[!(house %in% 3)]
d <- d[!(pilot %in% 1)]
d <- d[!(a7 %in% pilot_a7)]
d[, t_l := as.numeric(tmt %in% 2)][, t_c := as.numeric(tmt %in% 1)][, t_cli := as.numeric(tmt %in% 3)]
d[, taxes_paid_amt := taxes_paid * rate]

d[!is.na(date_TDM) & date_TDM < td("2018-06-15"), date_TDM := NA]
d[tmt %in% 3 & !is.na(date_TDM) & date_TDM < td("2018-07-16"), date_TDM := NA]

fix <- list(`112` = "2018-11-28", `219` = "2018-11-28", `224` = "2018-11-29", `238` = "2018-12-03",
            `327` = "2018-12-06", `343` = "2018-11-30", `356` = "2018-11-30", `510` = "2018-12-03",
            `512` = "2018-12-03", `514` = "2018-11-26", `533` = "2018-11-28", `538` = "2018-11-29",
            `544` = "2018-11-29", `588` = "2018-11-27", `596` = "2018-11-29", `658` = "2018-11-27",
            `664` = "2018-11-28", `669` = "2018-12-01", `678` = "2018-11-29")
for (k in names(fix)) d[a7 == as.numeric(k), today_carto := td(fix[[k]])]

setorder(d, a7, compound1, na.last = TRUE)
d[, a7_rank := seq_len(.N), by = a7][, a7_max_rank := max(a7_rank), by = a7]
n <- nrow(d); a <- d$a7; tc <- d$today_carto
same_next <- c(!is.na(a[-n]) & !is.na(a[-1]) & a[-n] == a[-1], FALSE)
same_prev <- c(FALSE, same_next[-n])
plus1 <- ifelse(same_next, c(tc[-1], NA), NA)
minus1 <- ifelse(same_prev, c(NA, tc[-n]), NA)
rk <- d$a7_rank; mx <- d$a7_max_rank
for (i in seq_len(n)) {   # sequential, as Stata's replace with explicit subscripts
  p <- if (i > 1) tc[i - 1] else NA; q <- if (i < n) tc[i + 1] else NA
  if (is.na(tc[i]) && !is.na(p) && !is.na(q) && p == q) tc[i] <- minus1[i]
}
for (i in seq_len(n)) {
  p <- if (i > 1) tc[i - 1] else NA; q <- if (i < n) tc[i + 1] else NA
  if (is.na(tc[i]) && !is.na(p) && !is.na(q) && p != q && rk[i] == mx[i]) tc[i] <- minus1[i]
}
for (i in seq_len(n)) {
  p <- if (i > 1) tc[i - 1] else NA; q <- if (i < n) tc[i + 1] else NA
  if (is.na(tc[i]) && !is.na(p) && !is.na(q) && p != q && rk[i] != mx[i]) tc[i] <- plus1[i]
}
d[, today_carto := tc]
fill <- list(c(204, "2018-08-09"), c(624, "2018-06-21"))
for (f in fill) d[is.na(today_carto) & a7 == as.numeric(f[1]), today_carto := td(f[2])]
d[is.na(today_carto) & a7 == 694 & compound1 %in% c(694001, 694002, 694003, 694004), today_carto := td("2018-11-05")]
fill2 <- list(c(694, "2018-11-06"), c(6104, "2018-08-08"), c(231, "2018-06-18"), c(300, "2018-06-16"),
              c(312, "2018-09-17"), c(313, "2018-06-15"), c(502, "2018-07-18"), c(507, "2018-08-08"),
              c(557, "2018-08-08"), c(563, "2018-06-25"), c(571, "2018-08-18"), c(577, "2018-08-08"),
              c(595, "2018-12-11"), c(597, "2018-07-19"), c(619, "2018-08-08"), c(635, "2018-08-08"),
              c(647, "2018-11-07"), c(701, "2018-09-07"), c(6103, "2018-11-06"))
for (f in fill2) d[is.na(today_carto) & a7 == as.numeric(f[1]), today_carto := td(f[2])]

mn <- function(x) if (all(is.na(x))) NA_real_ else min(x, na.rm = TRUE)
mxf <- function(x) if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)
d[, a7_min_today_TDM := mn(date_TDM), by = a7]
d[, a7_max_today_carto := mxf(today_carto), by = a7]
d[, today_alt := a7_min_today_TDM]
d[is.na(today_alt) & !is.na(a7_max_today_carto), today_alt := a7_max_today_carto]
ad <- d[!is.na(rate)]
cat("analysis_data rows:", nrow(ad), "\n"); print(table(ad$tmt, useNA = "a"))

## time fixed effects: egen cut(), at() icodes
cutfe <- function(x, br) { k <- findInterval(x, br); ifelse(is.na(x) | x < br[1] | x >= br[length(br)], NA, k - 1) }

## ---------------------------------------------------------------- Table 4
t4 <- ad[tmt %in% c(1, 2, 3)]
t4[, tfe := cutfe(today_alt, c(21355, 21415, 21475, 21532))]
s4 <- t4[tmt %in% c(1, 2)]
f <- function(fml, data) feols(fml, data = data, cluster = ~a7, fixef.rm = "none")
m1 <- f(taxes_paid ~ t_l | stratum, s4)
m2 <- f(taxes_paid ~ t_l | stratum + tfe, s4)
m4 <- f(taxes_paid ~ t_l | stratum + house + tfe, s4)
m5 <- f(taxes_paid ~ t_l | stratum + house + tfe, s4[is.na(exempt) | exempt != 1])
r2 <- f(taxes_paid_amt ~ t_l | stratum + tfe, s4)
r4 <- f(taxes_paid_amt ~ t_l | stratum + house + tfe, s4)
cat("T4 N:", nobs(m1), nobs(m2), nobs(m4), nobs(m5), "\n")
cat("T4 SE col1/col2:", se(m1)["t_l"], se(m2)["t_l"], "\n")

## ---------------------------------------------------------------- Table 6
t6 <- ad[tmt %in% c(1, 2, 3)]
t6[, visit_post_carto := NA_real_]
t6[visited %in% 0 | (!is.na(visits) & visits != 0), visit_post_carto := 0]
t6[!is.na(visits) & visits > 1, visit_post_carto := 1]
t6[, tfe6 := cutfe(today_alt, c(21355, 21415, 21475, 21529))]
m6 <- f(visit_post_carto ~ t_l | house + stratum + tfe6, t6[tmt %in% c(1, 2)])
cat("T6 N:", nobs(m6), "\n")

## ---------------------------------------------------------------- Table 7
t7 <- ad[tmt %in% c(1, 2, 3)]
t7[, tfe7 := cutfe(today_alt, c(21365.5, 21425.5, 21485.5, 21519))]
m7a <- f(taxes_paid ~ t_cli | house + stratum + tfe7, t7[tmt %in% c(1, 3)])
m7b <- f(taxes_paid_amt ~ t_cli | house + stratum + tfe7, t7[tmt %in% c(1, 3)])
cat("T7 N:", nobs(m7a), nobs(m7b), "\n")

## ---------------------------------------------------------------- Table 5 (endline bribe)
el <- rd(file.path(S, "endline_round1_noPII.dta"),
         c("code", "a7", "tot_complete", "bribe", "bribe2a", "bribe2b", "bribe3"))
el <- el[tot_complete == 1]
el[is.na(bribe), bribe := bribe2a][is.na(bribe), bribe := bribe2b][is.na(bribe), bribe := bribe3]
tm <- ad[, .(treatment = mxf(tmt), stratum = mxf(stratum)), by = a7]
el <- merge(el[, .(code, a7, bribe_endline = bribe)], tm, by = "a7")
el[, t_l := as.numeric(treatment %in% 2)]
m5b <- f(bribe_endline ~ t_l | stratum, el[treatment %in% c(1, 2)])
cat("T5 bribe N:", nobs(m5b), "\n")

## ---------------------------------------------------------------- Table 8
t8 <- ad[tmt %in% c(1, 2, 3)]
setnames(t8, "compound1", "compound_code")
e8 <- rd(file.path(S, "endline_round1_noPII.dta"), c("code", "tot_complete", "compound_code", "compound_code_prev", "move"))
e8 <- e8[tot_complete == 1]
b8 <- rd(file.path(S, "baseline_noPII.dta"), c("code", "tot_complete"))
b8 <- b8[tot_complete == 1, .(code)]
e8 <- merge(e8[, .(code, compound_code, compound_code_prev, move)], b8, by = "code", all = TRUE)
e8[move %in% c(1, 2), compound_code := compound_code_prev]
e8[compound_code %in% c(99999, 9999999), compound_code := 999999]
e8 <- e8[!(compound_code %in% 999999) & !is.na(compound_code), .(compound_code, el_code = code)]
t8 <- merge(t8, e8, by = "compound_code", all.x = TRUE, allow.cartesian = TRUE)  # 1:m, master rows duplicated
cs <- rd(file.path(S, "chief_consultations.dta"), c("compound1", "pay_ease", "willingness"))
setnames(cs, "compound1", "compound_code")
cat("consult dup:", sum(duplicated(cs$compound_code)), "\n")
t8 <- merge(t8, cs, by = "compound_code", all.x = TRUE)
m8 <- f(taxes_paid ~ pay_ease | house + stratum, t8[t_cli == 1])
cat("T8 N:", nobs(m8), "\n")

## ---------------------------------------------------------------- results
out <- c(
  compliance_local_table4_panelA_col1 = coef(m1)[["t_l"]],
  compliance_local_table4_panelA_col2 = coef(m2)[["t_l"]],
  compliance_local_house_fe_table4_panelA_col4 = coef(m4)[["t_l"]],
  compliance_local_exempt_excluded_table4_panelA_col5 = coef(m5)[["t_l"]],
  revenue_local_table4_panelB_col2 = coef(r2)[["t_l"]],
  revenue_local_house_fe_table4_panelB_col4 = coef(r4)[["t_l"]],
  n_obs_table4_col1 = nobs(m1),
  n_obs_table4_col2 = nobs(m2),
  paid_bribe_endline_local_table5_panelB = coef(m5b)[["t_l"]],
  visited_by_collector_local_table6_col1 = coef(m6)[["t_l"]],
  compliance_cli_table7_col1 = coef(m7a)[["t_cli"]],
  revenue_cli_table7_col2 = coef(m7b)[["t_cli"]],
  compliance_ease_of_payment_cli_table8_panelA_col2 = coef(m8)[["pay_ease"]]
)
for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
