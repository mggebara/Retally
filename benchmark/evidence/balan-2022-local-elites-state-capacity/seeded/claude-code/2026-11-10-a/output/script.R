# Balan et al. (2022) "Local Elites as State Capacity" -- seeded reproduction in R.
# Rebuilds analysis_data.dta following 2_Data_Construction.do (only the variables the
# targeted tables use), then estimates Table 4 (cols 1,2,4,5; panels A,B), Table 5 panel B
# "Paid bribe (endline)", Table 6 col 1, Table 7 cols 1-2 and Table 8 panel A col 2.
suppressPackageStartupMessages({library(haven); library(data.table); library(fixest)})
set.seed(42)
ROOT <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/seeded/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(p, cols = NULL) {
  d <- read_dta(file.path(ROOT, p), col_select = if (is.null(cols)) everything() else any_of(cols))
  d <- as.data.table(zap_labels(zap_missing(d)))
  d
}
num <- function(x) if (inherits(x, "Date")) as.numeric(x) + 3653 else suppressWarnings(as.numeric(x))  # Stata %td days
pilot_a7 <- c(200, 201, 202, 203, 207, 208, 210)

# Stata-style merge: master values win on overlapping vars; using-only rows take using values.
smerge <- function(m, u, by = "compound1", keep_using = TRUE) {
  ov <- setdiff(intersect(names(m), names(u)), by)
  if (length(ov)) setnames(u, ov, paste0(ov, ".__u"))
  m[, .__m := TRUE]; u[, .__u := TRUE]
  r <- merge(m, u, by = by, all.x = TRUE, all.y = keep_using, sort = FALSE)
  for (v in ov) { uv <- paste0(v, ".__u"); r[is.na(.__m), (v) := get(uv)]; r[, (uv) := NULL] }
  r[, mrg := fifelse(!is.na(.__m) & !is.na(.__u), 3L, fifelse(!is.na(.__m), 1L, 2L))]
  r[, c(".__m", ".__u") := NULL]
  r[]
}

## ---- flier mail merge (master) ----
fl <- rd("admin_data/fliers_campaign.dta", c("a7", "code", "rate"))
fl <- fl[!(a7 %in% pilot_a7)]
fl <- data.table(compound1 = num(fl$code), assign_flier_rate = num(fl$rate))
s <- format(fl$compound1, scientific = FALSE, trim = TRUE)
fl[, a7 := num(ifelse(nchar(s) == 6, substr(s, 1, 3), ifelse(nchar(s) == 7, substr(s, 1, 4), NA)))]
# pilot set xlsx files only concern pilot polygons, which are dropped from the analysis data
st <- rd("admin_data/stratum.dta", c("a7", "stratum")); st[, a7 := num(a7)]; st[, stratum := num(stratum)]
fl <- merge(fl, st, by = "a7", all.x = TRUE, sort = FALSE)
asg <- rd("admin_data/randomization_schedule.dta", c("a7", "treatment"))
asg <- data.table(a7 = num(asg$a7), tmt = num(asg$treatment))
asg[a7 == 654, tmt := 2]  # field-team assignment mistake
fl <- merge(fl, asg, by = "a7", all.x = TRUE, sort = FALSE)

## ---- registration (cartography) ----
rg <- rd("admin_data/registration_noPII.dta", c("compound1", "a7", "tot_complete", "today", "house", "mm_rate", "exempt", "pilot"))
rg <- rg[tot_complete %in% 1]
rg <- data.table(compound1 = num(rg$compound1), a7 = num(rg$a7), today_carto = num(rg$today), house = num(rg$house),
                 mm_rate = num(rg$mm_rate), exempt = num(rg$exempt), pilot = num(rg$pilot))
d <- smerge(fl, rg); setnames(d, "mrg", "m_fc")

## ---- tax roll ----
tr <- rd("admin_data/taxroll_noPII.dta", c("compound1", "a7"))
tr <- data.table(compound1 = num(tr$compound1), a7 = num(tr$a7))
tr <- tr[!is.na(compound1)]
d <- smerge(d, tr); setnames(d, "mrg", "m_fcr")

## ---- midline (monitoring) ----
md <- rd("survey_data/midline_noPII.dta", c("compound", "possible_compound", "tot_complete", "start", "end", "a7", "code_same", "visited", "visits"))
md[, compound1 := num(compound)]; md[, possible_compound := num(possible_compound)]
md[possible_compound %in% c(0, 999999, 9999999), possible_compound := NA]
md[compound1 %in% 999999 & !is.na(possible_compound), compound1 := possible_compound]
md <- md[!(compound1 %in% 999999) & !is.na(compound1)]
md[, tot_complete := num(tot_complete)]
md[, mx := suppressWarnings(max(tot_complete, na.rm = TRUE)), by = compound1]; md[!is.finite(mx), mx := NA]
md <- md[!( (is.na(tot_complete) & !is.na(mx)) | (!is.na(tot_complete) & is.na(mx)) | (!is.na(tot_complete) & !is.na(mx) & tot_complete != mx) )]
md[, `:=`(st_ = as.numeric(start), en_ = as.numeric(end))]
setorderv(md, c("compound1", "st_", "en_"), na.last = TRUE)  # stable sort
md <- md[md[, .I[.N], by = compound1]$V1]
md <- md[, .(compound1, a7 = num(a7), code_same = num(code_same), visited = num(visited), visits = num(visits))]
d <- smerge(d, md, keep_using = FALSE); setnames(d, "mrg", "m_fcrm")

## ---- tax payments (TDM) ----
tp <- rd("admin_data/tax_payments_noPII.dta", c("compound1", "a7", "house", "date", "amountCF", "unmatched_compound"))
tp <- tp[!(unmatched_compound %in% 1) & !is.na(compound1)]
tp <- data.table(compound1 = num(tp$compound1), a7 = num(tp$a7), house = num(tp$house), date_TDM = num(tp$date), amountCF = num(tp$amountCF))
d <- smerge(d, tp); setnames(d, "mrg", "m_tdm")
d <- d[!(m_fc %in% 1 & m_fcr %in% 1 & m_fcrm %in% 1)]

## ---- outcomes ----
d[, taxes_paid := as.numeric(m_tdm == 3)]
d[taxes_paid == 0 & code_same %in% 1, taxes_paid := 1]
d[house %in% 1 & m_tdm == 3 & !is.na(amountCF) & !is.na(assign_flier_rate) & assign_flier_rate > amountCF, taxes_paid := 0]
d[house %in% 2 & m_tdm == 3 & !is.na(amountCF) & !is.na(mm_rate) & mm_rate > amountCF, taxes_paid := 0]
d[, rate := fifelse(house %in% 1, assign_flier_rate, fifelse(house %in% 2, mm_rate, NA_real_))]

## ---- analysis data ----
d <- d[!(house %in% 3)]
d <- d[!(pilot %in% 1)]
d <- d[!(a7 %in% pilot_a7)]
d[, `:=`(t_l = as.numeric(tmt %in% 2), t_c = as.numeric(tmt %in% 1), t_cli = as.numeric(tmt %in% 3))]
d[, taxes_paid_amt := taxes_paid * rate]
td <- function(s) { mo <- match(substr(s, 3, 5), c("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"))
  as.numeric(as.Date(sprintf("%s-%02d-%s", substr(s, 6, 9), mo, substr(s, 1, 2)))) + 3653 }
stopifnot(td("15jun2018") == 21350)
d[!is.na(date_TDM) & date_TDM < td("15jun2018"), date_TDM := NA]
d[tmt %in% 3 & !is.na(date_TDM) & date_TDM < td("16jul2018"), date_TDM := NA]
wp <- list(`112`="28nov2018",`219`="28nov2018",`224`="29nov2018",`238`="03dec2018",`327`="06dec2018",`343`="30nov2018",
           `356`="30nov2018",`510`="03dec2018",`512`="03dec2018",`514`="26nov2018",`533`="28nov2018",`538`="29nov2018",
           `544`="29nov2018",`588`="27nov2018",`596`="29nov2018",`658`="27nov2018",`664`="28nov2018",`669`="01dec2018",`678`="29nov2018")
for (k in names(wp)) d[a7 %in% as.numeric(k), today_carto := td(wp[[k]])]
setorderv(d, c("a7", "compound1"), na.last = TRUE)
d[, a7_rank := seq_len(.N), by = a7]; d[, a7_max_rank := max(a7_rank), by = a7]
n <- nrow(d); a7v <- d$a7; tc <- d$today_carto
same_next <- c(a7v[-1] == a7v[-n], FALSE); same_next[is.na(same_next)] <- FALSE
same_prev <- c(FALSE, a7v[-1] == a7v[-n]); same_prev[is.na(same_prev)] <- FALSE
plus1 <- ifelse(same_next, c(tc[-1], NA), NA); minus1 <- ifelse(same_prev, c(NA, tc[-n]), NA)
rk <- d$a7_rank; mr <- d$a7_max_rank
nb <- function(i) list(p = if (i > 1) tc[i - 1] else NA, q = if (i < n) tc[i + 1] else NA)
for (i in seq_len(n)) if (is.na(tc[i])) { z <- nb(i); if (!is.na(z$p) && !is.na(z$q) && z$p == z$q) tc[i] <- minus1[i] }
for (i in seq_len(n)) if (is.na(tc[i])) { z <- nb(i); if (!is.na(z$p) && !is.na(z$q) && z$p != z$q && rk[i] == mr[i]) tc[i] <- minus1[i] }
for (i in seq_len(n)) if (is.na(tc[i])) { z <- nb(i); if (!is.na(z$p) && !is.na(z$q) && z$p != z$q && rk[i] != mr[i]) tc[i] <- plus1[i] }
d[, today_carto := tc]
d[is.na(today_carto) & a7 %in% 694 & compound1 %in% c(694001, 694002, 694003, 694004), today_carto := td("05nov2018")]
oth <- rbind(c(204,"09aug2018"),c(624,"21jun2018"),c(694,"06nov2018"),c(6104,"08aug2018"),c(231,"18jun2018"),c(300,"16jun2018"),
             c(312,"17sep2018"),c(313,"15jun2018"),c(502,"18jul2018"),c(507,"08aug2018"),c(557,"08aug2018"),c(563,"25jun2018"),
             c(571,"18aug2018"),c(577,"08aug2018"),c(595,"11dec2018"),c(597,"19jul2018"),c(619,"08aug2018"),c(635,"08aug2018"),
             c(647,"07nov2018"),c(701,"07sep2018"),c(6103,"06nov2018"))
for (j in seq_len(nrow(oth))) d[is.na(today_carto) & a7 %in% as.numeric(oth[j, 1]), today_carto := td(oth[j, 2])]
mn <- function(x) if (all(is.na(x))) NA_real_ else min(x, na.rm = TRUE)
mxf <- function(x) if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)
d[, a7_min_today_TDM := mn(date_TDM), by = a7]
d[, a7_max_today_carto := mxf(today_carto), by = a7]
d[, today_alt := fifelse(!is.na(a7_min_today_TDM), a7_min_today_TDM, a7_max_today_carto)]
an <- d[!is.na(rate)]
cat(sprintf("analysis rows: %d; tmt table:\n", nrow(an))); print(table(an$tmt, useNA = "a"))

## ---- helpers ----
cutfe <- function(x, br) { r <- findInterval(x, br); r[is.na(x) | x < br[1] | x >= br[length(br)]] <- NA; r }
fit <- function(fml, data, coef) {
  m <- feols(fml, data = data, cluster = ~a7, fixef.rm = "none")
  cat(sprintf("  %-40s b=%.4f se=%.4f N=%d G=%d\n", deparse(fml)[1], coef(m)[coef], se(m)[coef], nobs(m),
              length(unique(data$a7[obs(m)]))))
  m
}
a <- an[tmt %in% c(1, 2, 3)]
a[, fe_CvL := cutfe(today_alt, c(21355, 21415, 21475, 21532))]
a[, fe_CvL6 := cutfe(today_alt, c(21355, 21415, 21475, 21529))]
a[, fe_CvCLI := cutfe(today_alt, c(21365.5, 21425.5, 21485.5, 21519))]
cl <- a[tmt %in% c(1, 2)]

## ---- Table 4 ----
cat("Table 4\n")
t4a1 <- fit(taxes_paid ~ t_l | stratum, cl, "t_l")
t4a2 <- fit(taxes_paid ~ t_l | stratum + fe_CvL, cl, "t_l")
t4a4 <- fit(taxes_paid ~ t_l | stratum + house + fe_CvL, cl, "t_l")
t4a5 <- fit(taxes_paid ~ t_l | stratum + house + fe_CvL, cl[!(exempt %in% 1)], "t_l")
t4b2 <- fit(taxes_paid_amt ~ t_l | stratum + fe_CvL, cl, "t_l")
t4b4 <- fit(taxes_paid_amt ~ t_l | stratum + house + fe_CvL, cl, "t_l")
cat(sprintf("  central mean col1 %.4f col2 %.4f\n", mean(cl[t_c == 1]$taxes_paid), mean(cl[t_c == 1 & !is.na(fe_CvL)]$taxes_paid)))

## ---- Table 6 col 1 ----
cat("Table 6\n")
a[, visit_post_carto := NA_real_]
a[visited %in% 0 | (!is.na(visits) & visits != 0), visit_post_carto := 0]
a[!is.na(visits) & visits > 1, visit_post_carto := 1]
cl <- a[tmt %in% c(1, 2)]
t6 <- fit(visit_post_carto ~ t_l | house + stratum + fe_CvL6, cl, "t_l")

## ---- Table 7 ----
cat("Table 7\n")
cc7 <- a[tmt %in% c(1, 3)]
t7a <- fit(taxes_paid ~ t_cli | house + stratum + fe_CvCLI, cc7, "t_cli")
t7b <- fit(taxes_paid_amt ~ t_cli | house + stratum + fe_CvCLI, cc7, "t_cli")

## ---- Table 8 panel A col 2 ----
cat("Table 8\n")
el <- rd("survey_data/endline_round1_noPII.dta", c("code", "tot_complete", "compound_code", "compound_code_prev", "move"))
el <- el[tot_complete %in% 1]
el[, `:=`(compound_code = num(compound_code), compound_code_prev = num(compound_code_prev), move = num(move))]
el[move %in% c(1, 2), compound_code := compound_code_prev]
el[compound_code %in% c(99999, 9999999), compound_code := 999999]
el <- el[!(compound_code %in% 999999) & !is.na(compound_code)]
el <- el[, .(compound1 = compound_code, el_code = code)]
cat(sprintf("  endline rows %d, duplicated compound codes %d\n", nrow(el), sum(duplicated(el$compound1))))
a8 <- merge(a, el, by = "compound1", all.x = TRUE, allow.cartesian = TRUE, sort = FALSE)
cons <- rd("survey_data/chief_consultations.dta", c("compound1", "pay_ease"))
cons <- data.table(compound1 = num(cons$compound1), pay_ease = num(cons$pay_ease))
a8 <- merge(a8, cons, by = "compound1", all.x = TRUE, sort = FALSE)
t8 <- fit(taxes_paid ~ pay_ease | house + stratum, a8[t_cli == 1], "pay_ease")

## ---- Table 5 panel B: paid bribe (endline) ----
cat("Table 5\n")
e5 <- rd("survey_data/endline_round1_noPII.dta", c("code", "a7", "tot_complete", "bribe", "bribe2a", "bribe2b", "bribe3"))
e5 <- e5[tot_complete %in% 1]
for (v in c("a7", "bribe", "bribe2a", "bribe2b", "bribe3")) e5[, (v) := num(get(v))]
e5[is.na(bribe), bribe := bribe2a]; e5[is.na(bribe), bribe := bribe2b]; e5[is.na(bribe), bribe := bribe3]
pt <- an[, .(treatment = mxf(tmt), stratum = mxf(stratum)), by = a7]
e5 <- merge(e5, pt, by = "a7", sort = FALSE)
e5[, t_l := as.numeric(treatment %in% 2)]
t5 <- fit(bribe ~ t_l | stratum, e5[treatment %in% c(1, 2)], "t_l")

res <- c(compliance_local_table4_panelA_col1 = coef(t4a1)[["t_l"]],
         compliance_local_table4_panelA_col2 = coef(t4a2)[["t_l"]],
         compliance_local_house_fe_table4_panelA_col4 = coef(t4a4)[["t_l"]],
         compliance_local_exempt_excluded_table4_panelA_col5 = coef(t4a5)[["t_l"]],
         revenue_local_table4_panelB_col2 = coef(t4b2)[["t_l"]],
         revenue_local_house_fe_table4_panelB_col4 = coef(t4b4)[["t_l"]],
         n_obs_table4_col1 = nobs(t4a1),
         n_obs_table4_col2 = nobs(t4a2),
         paid_bribe_endline_local_table5_panelB = coef(t5)[["t_l"]],
         visited_by_collector_local_table6_col1 = coef(t6)[["t_l"]],
         compliance_cli_table7_col1 = coef(t7a)[["t_cli"]],
         revenue_cli_table7_col2 = coef(t7b)[["t_cli"]],
         compliance_ease_of_payment_cli_table8_panelA_col2 = coef(t8)[["pay_ease"]])
for (k in names(res)) cat(sprintf("RESULT:%s=%.6f\n", k, res[[k]]))
