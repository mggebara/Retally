suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- file.path("<repo>/.cache/datasets/balan_2022_local_elites_state_capacity.script-free",
                  "Replication Materials - Updated October 2025", "Data", "01_base")

rd <- function(rel) {
  p <- file.path(root, rel)
  x <- tryCatch(haven::read_dta(p), error = function(e) {
    message("read fail ", rel, ": ", conditionMessage(e)); NULL })
  if (!is.null(x)) {
    names(x) <- tolower(names(x))
    x <- as.data.frame(x)
    message("Loaded ", rel, ": ", nrow(x), " rows; cols: ",
            paste(head(names(x), 80), collapse = ","))
  }
  x
}

first_col <- function(df, cands) {
  if (is.null(df)) return(NA_character_)
  h <- intersect(cands, names(df))
  if (length(h)) h[1] else NA_character_
}

num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))

to01 <- function(x) {
  v <- num(x)
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) && all(u %in% c(1, 2)) && !all(u %in% c(0, 1))) v <- ifelse(v == 1, 1, ifelse(v == 2, 0, NA))
  v[!(v %in% c(0, 1))] <- NA
  v
}

to_days <- function(x) {
  if (inherits(x, "POSIXt")) return(as.numeric(as.Date(x)))
  if (inherits(x, "Date")) return(as.numeric(x))
  if (is.character(x)) {
    d <- suppressWarnings(as.Date(x))
    if (all(is.na(d))) d <- suppressWarnings(lubridate::dmy(x))
    if (all(is.na(d))) d <- suppressWarnings(lubridate::mdy(x))
    return(as.numeric(d))
  }
  v <- num(x)
  if (isTRUE(median(abs(v), na.rm = TRUE) > 1e8)) v <- v / 86400000
  v
}

arm_from <- function(x) {
  lab <- tryCatch(tolower(as.character(haven::as_factor(x, levels = "labels"))),
                  error = function(e) tolower(as.character(x)))
  out <- rep(NA_character_, length(lab))
  out[grepl("central", lab)] <- "Central"
  out[grepl("local", lab)] <- "Local"
  out[grepl("cxl|central.*local|local.*central|both|collab", lab)] <- "CXL"
  out[grepl("cli|info|consult", lab)] <- "CLI"
  out[grepl("control|pure", lab)] <- "Control"
  if (all(is.na(out))) {
    v <- num(x)
    out <- c("Control", "Central", "Local", "CLI", "CXL")[match(v, 0:4)]
  }
  out
}

pick_arm <- function(df) {
  if (is.null(df)) return(NULL)
  nm <- names(df)
  cands <- unique(c(nm[grepl("fact|actual|imple", nm) & grepl("tmt|treat|arm|program", nm)],
                    intersect(c("tmt", "treatment", "treat", "arm", "program", "assignment", "tmt_2018"), nm),
                    nm[grepl("^tmt|treat", nm)]))
  for (cc in cands) {
    a <- tryCatch(arm_from(df[[cc]]), error = function(e) NULL)
    if (is.null(a)) next
    if (sum(a == "Local", na.rm = TRUE) >= 20 && sum(a == "Central", na.rm = TRUE) >= 20) {
      message("Arm variable: ", cc); print(table(a, useNA = "ifany"))
      return(a)
    }
  }
  NULL
}

idc <- c("compound1", "compound", "compound_id", "compound_code", "code", "taxid", "tax_id", "id")
nbc <- c("a7", "polygon", "neighborhood", "grid_nm", "poly")

# ---------------- Neighborhood-level info ----------------
nb  <- rd("admin_data/tax_payments_neighborhoods.dta")
ra  <- rd("admin_data/randomization_assignment.dta")
st  <- rd("admin_data/stratum.dta")
sch <- rd("admin_data/randomization_schedule.dta")

nbid <- first_col(nb, nbc)
nbx <- data.frame(a7 = nb[[nbid]], stringsAsFactors = FALSE)
arm <- pick_arm(nb)
if (is.null(arm) && !is.null(ra)) {
  raid <- first_col(ra, nbc)
  a2 <- pick_arm(ra)
  if (!is.null(a2)) arm <- a2[match(nbx$a7, ra[[raid]])]
}
nbx$arm <- arm

if ("stratum" %in% names(nb)) {
  nbx$stratum <- num(nb$stratum)
} else if (!is.null(st)) {
  sid <- first_col(st, nbc)
  nbx$stratum <- num(st$stratum)[match(nbx$a7, st[[sid]])]
}

dcol <- first_col(nb, c("program_start", "start_date", "date_start", "start"))
if (!is.na(dcol)) {
  nbx$nbdate <- to_days(nb[[dcol]])
} else if (!is.null(sch)) {
  sid <- first_col(sch, nbc)
  sc <- names(sch)[grepl("start|date|day|first", names(sch))][1]
  nbx$nbdate <- to_days(sch[[sc]])[match(nbx$a7, sch[[sid]])]
} else nbx$nbdate <- NA_real_
if (all(is.na(nbx$nbdate)) && !is.null(sch)) {
  sid <- first_col(sch, nbc)
  sc <- names(sch)[grepl("start|date|day|first", names(sch))][1]
  if (!is.na(sc)) nbx$nbdate <- to_days(sch[[sc]])[match(nbx$a7, sch[[sid]])]
}
if ("nganza" %in% names(nb)) nbx <- nbx[is.na(num(nb$nganza)) | num(nb$nganza) != 1, ]
message("Neighborhoods: ", nrow(nbx)); print(table(nbx$arm, useNA = "ifany"))

# Two-month campaign periods for a pair of arms (Appendix A2.5)
add_period <- function(nbtab, a, b) {
  d <- nbtab$nbdate
  fa <- min(d[nbtab$arm == a], na.rm = TRUE); fb <- min(d[nbtab$arm == b], na.rm = TRUE)
  la <- max(d[nbtab$arm == a], na.rm = TRUE); lb <- max(d[nbtab$arm == b], na.rm = TRUE)
  s <- (fa + fb) / 2; e <- (la + lb) / 2
  per <- ifelse(!is.na(d) & d >= s & d <= e, floor((d - s) / (365.25 / 6)), NA)
  data.frame(a7 = nbtab$a7, period = per)
}

# ---------------- Property-level data ----------------
tr  <- rd("admin_data/taxroll_noPII.dta")
reg <- rd("admin_data/registration_noPII.dta")
pay <- rd("admin_data/tax_payments_noPII.dta")

ok_base <- function(df) !is.null(df) && !is.na(first_col(df, idc)) && !is.na(first_col(df, nbc))
prop <- if (ok_base(tr)) tr else reg
pid <- first_col(prop, idc)
prop$pid <- as.character(num(prop[[pid]]))
if (all(is.na(prop$pid))) prop$pid <- as.character(prop[[pid]])
prop <- prop[!is.na(prop$pid) & !duplicated(prop$pid), ]
prop$a7 <- prop[[first_col(prop, nbc)]]

reg_lookup <- function(var) {
  if (is.null(reg) || !(var %in% names(reg))) return(rep(NA, nrow(prop)))
  rid <- first_col(reg, idc)
  k <- as.character(num(reg[[rid]]))
  reg[[var]][match(prop$pid, k)]
}
hv <- first_col(prop, c("house", "house_type", "rate_type"))
prop$house_fe <- if (!is.na(hv)) num(prop[[hv]]) else num(reg_lookup("house"))
ev <- first_col(prop, c("exempt", "exempt_final"))
prop$exempt01 <- if (!is.na(ev)) to01(prop[[ev]]) else to01(reg_lookup("exempt"))
prop$exempt01[is.na(prop$exempt01)] <- 0

# Payments
got_pay <- FALSE
if (!is.null(pay)) {
  ppid <- first_col(pay, idc)
  pac <- first_col(pay, c("amount", "amt_paid", "amount_paid", "paid_amount", "taxes_paid_amt", "amt"))
  ppc <- first_col(pay, c("paid", "taxes_paid", "paid_self", "payment"))
  if (!is.na(ppid) && (!is.na(pac) || !is.na(ppc))) {
    pk <- as.character(num(pay[[ppid]]))
    amt <- if (!is.na(pac)) num(pay[[pac]]) else rep(NA_real_, nrow(pay))
    pd <- if (!is.na(ppc)) to01(pay[[ppc]]) else as.numeric(amt > 0)
    if (all(is.na(pd))) pd <- as.numeric(amt > 0)
    pa <- data.frame(pid = pk, pd = pd, amt = amt) %>% filter(!is.na(pid)) %>%
      group_by(pid) %>%
      summarise(paid_p = as.numeric(any(pd == 1 | (!is.na(amt) & amt > 0), na.rm = TRUE)),
                amt_p = sum(ifelse(is.na(amt), 0, amt)), .groups = "drop")
    m <- match(prop$pid, pa$pid)
    if (sum(!is.na(m)) > 100) {
      prop$paid <- ifelse(is.na(m), 0, pa$paid_p[m])
      prop$revenue <- ifelse(is.na(m), 0, pa$amt_p[m])
      if (is.na(pac)) prop$revenue <- NA_real_
      got_pay <- TRUE
      message("Payment matches: ", sum(!is.na(m)))
    }
  }
}
if (!got_pay || all(is.na(prop$revenue))) {
  oc <- first_col(prop, c("taxes_paid", "paid", "paid_self"))
  ac <- first_col(prop, c("taxes_paid_amt", "amount", "amt_paid", "amount_paid"))
  if (!got_pay && !is.na(oc)) { prop$paid <- to01(prop[[oc]]); prop$paid[is.na(prop$paid)] <- 0 }
  if (!is.na(ac)) { r <- num(prop[[ac]]); r[is.na(r)] <- 0; prop$revenue <- r }
  if (!got_pay && is.na(oc) && !is.na(ac)) prop$paid <- as.numeric(prop$revenue > 0)
}

drop_overlap <- function(df) df[, setdiff(names(df), c("arm", "stratum", "nbdate", "period")), drop = FALSE]
dat <- inner_join(drop_overlap(prop), nbx, by = "a7")
message("Property sample: ", nrow(dat))

per_LC <- add_period(nbx, "Local", "Central")
per_CC <- add_period(nbx, "CLI", "Central")

res <- list()
cf <- function(m, v) tryCatch(unname(coef(m)[v]), error = function(e) NA_real_)
safe <- function(expr) tryCatch(expr, error = function(e) { message("ERR: ", conditionMessage(e)); NULL })

lc <- dat %>% filter(arm %in% c("Local", "Central")) %>% mutate(local = as.integer(arm == "Local")) %>%
  left_join(per_LC, by = "a7")

m1 <- safe(feols(paid ~ local | stratum, lc, cluster = ~a7))
m2 <- safe(feols(paid ~ local | stratum + period, lc, cluster = ~a7))
m4 <- safe(feols(paid ~ local | stratum + period + house_fe, lc, cluster = ~a7))
m5 <- safe(feols(paid ~ local | stratum + period + house_fe, filter(lc, exempt01 != 1), cluster = ~a7))
r2 <- safe(feols(revenue ~ local | stratum + period, lc, cluster = ~a7))
r4 <- safe(feols(revenue ~ local | stratum + period + house_fe, lc, cluster = ~a7))

res$compliance_local_table4_panelA_col1 <- cf(m1, "local")
res$compliance_local_table4_panelA_col2 <- cf(m2, "local")
res$compliance_local_house_fe_table4_panelA_col4 <- cf(m4, "local")
res$compliance_local_exempt_excluded_table4_panelA_col5 <- cf(m5, "local")
res$revenue_local_table4_panelB_col2 <- cf(r2, "local")
res$revenue_local_house_fe_table4_panelB_col4 <- cf(r4, "local")
res$n_obs_table4_col1 <- if (!is.null(m1)) nobs(m1) else NA
res$n_obs_table4_col2 <- if (!is.null(m2)) nobs(m2) else NA

# ---------------- Endline: paid bribe ----------------
res$paid_bribe_endline_local_table5_panelB <- NA_real_
safe({
  el <- rd("survey_data/endline_round1_noPII.dta")
  bv <- NA_character_
  for (cand in c("bribe", "paid_bribe", "bribe_self", "transport")) {
    if (cand %in% names(el)) { v <- to01(el[[cand]]); if (sum(!is.na(v)) > 100 && var(v, na.rm = TRUE) > 0) { bv <- cand; break } }
  }
  message("Bribe variable: ", bv)
  e <- data.frame(y = to01(el[[bv]]))
  eid <- first_col(el, nbc)
  if (!is.na(eid)) {
    e$a7 <- el[[eid]]
  } else {
    k <- as.character(num(el[[first_col(el, idc)]]))
    e$a7 <- prop$a7[match(k, prop$pid)]
  }
  e <- inner_join(e, nbx, by = "a7") %>% filter(arm %in% c("Local", "Central")) %>%
    mutate(local = as.integer(arm == "Local"))
  mb <- feols(y ~ local | stratum, e, cluster = ~a7)
  res$paid_bribe_endline_local_table5_panelB <- cf(mb, "local")
})

# ---------------- Midline: visited ----------------
res$visited_by_collector_local_table6_col1 <- NA_real_
safe({
  mid <- rd("survey_data/midline_noPII.dta")
  if ("tot_complete" %in% names(mid)) {
    keep <- num(mid$tot_complete) == 1
    if (sum(keep, na.rm = TRUE) > 20000) mid <- mid[which(keep), ]
  }
  mv <- data.frame(y = to01(mid$visited))
  mpid <- first_col(mid, idc)
  k <- if (!is.na(mpid)) as.character(num(mid[[mpid]])) else rep(NA_character_, nrow(mid))
  mvid <- first_col(mid, nbc)
  mv$a7 <- if (!is.na(mvid)) mid[[mvid]] else prop$a7[match(k, prop$pid)]
  mv$house_fe <- if ("house" %in% names(mid)) num(mid$house) else prop$house_fe[match(k, prop$pid)]
  if (all(is.na(mv$house_fe))) mv$house_fe <- prop$house_fe[match(k, prop$pid)]
  mv <- inner_join(mv, nbx, by = "a7") %>% filter(arm %in% c("Local", "Central")) %>%
    mutate(local = as.integer(arm == "Local")) %>% left_join(per_LC, by = "a7")
  mm <- feols(y ~ local | stratum + period + house_fe, mv, cluster = ~a7)
  res$visited_by_collector_local_table6_col1 <- cf(mm, "local")
})

# ---------------- Table 7: CLI vs Central ----------------
cc <- dat %>% filter(arm %in% c("CLI", "Central")) %>% mutate(cli = as.integer(arm == "CLI")) %>%
  left_join(per_CC, by = "a7")
t7a <- safe(feols(paid ~ cli | stratum + period + house_fe, cc, cluster = ~a7))
t7b <- safe(feols(revenue ~ cli | stratum + period + house_fe, cc, cluster = ~a7))
res$compliance_cli_table7_col1 <- cf(t7a, "cli")
res$revenue_cli_table7_col2 <- cf(t7b, "cli")

# ---------------- Table 8: ease of payment within CLI ----------------
res$compliance_ease_of_payment_cli_table8_panelA_col2 <- NA_real_
safe({
  find_ease <- function(df) {
    nm <- names(df)
    c1 <- nm[grepl("ease", nm)]
    c2 <- nm[grepl("abil|able|afford|capac", nm) & !grepl("will", nm)]
    cs <- c(c1, c2)
    for (z in cs) { v <- num(df[[z]]); if (sum(v %in% 1:3) > 100) return(z) }
    NA_character_
  }
  cl <- dat %>% filter(arm == "CLI")
  ch <- rd("survey_data/chief_consultations.dta")
  ez <- NA_character_
  if (!is.null(ch)) ez <- find_ease(ch)
  if (!is.na(ez)) {
    chid <- first_col(ch, idc)
    kk <- as.character(num(ch[[chid]]))
    ev <- num(ch[[ez]]); ev[!(ev %in% 1:3)] <- NA
    tmp <- data.frame(pid = kk, ease = ev) %>% filter(!is.na(pid), !is.na(ease)) %>% distinct(pid, .keep_all = TRUE)
    cl$ease <- tmp$ease[match(cl$pid, tmp$pid)]
  } else {
    ez <- find_ease(cl)
    ev <- num(cl[[ez]]); ev[!(ev %in% 1:3)] <- NA
    cl$ease <- ev
  }
  message("Ease variable: ", ez, "; non-missing in CLI: ", sum(!is.na(cl$ease)))
  m8 <- feols(paid ~ ease | stratum + house_fe, cl, cluster = ~a7)
  res$compliance_ease_of_payment_cli_table8_panelA_col2 <- cf(m8, "ease")
})

for (n in names(res)) {
  v <- res[[n]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, ifelse(is.na(v), "NA", format(v, digits = 10, scientific = FALSE))))
}