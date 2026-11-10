suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/balan_2022_local_elites_state_capacity.script-free/Replication Materials - Updated October 2025/Data/01_base"

rd <- function(p) {
  d <- haven::read_dta(file.path(root, p))
  names(d) <- tolower(names(d))
  d
}
pick <- function(d, cands, regex = NULL) {
  for (c in cands) if (c %in% names(d)) return(c)
  if (!is.null(regex)) {
    m <- grep(regex, names(d), value = TRUE, ignore.case = TRUE)
    if (length(m)) return(m[1])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))
yes01 <- function(x) {
  labs <- attr(x, "labels")
  v <- num(x)
  if (is.character(x) && all(is.na(v[!is.na(x) & x != ""]))) {
    s <- tolower(trimws(as.character(x)))
    return(ifelse(s %in% c("yes", "oui", "1", "true"), 1,
                  ifelse(s %in% c("no", "non", "0", "false"), 0, NA)))
  }
  v[v < 0] <- NA
  if (!is.null(labs) && length(labs)) {
    ln <- tolower(names(labs))
    ycodes <- as.numeric(labs[grepl("^(yes|oui)", ln)])
    ncodes <- as.numeric(labs[grepl("^(no|non)\\b", ln)])
    if (length(ycodes) && length(ncodes)) {
      out <- ifelse(v %in% ycodes, 1, ifelse(v %in% ncodes, 0, NA))
      out[is.na(v)] <- NA
      return(out)
    }
  }
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  out <- ifelse(v == 1, 1, ifelse(v %in% c(0, 2), 0, NA))
  out[is.na(v)] <- NA
  out
}
info <- function(name, d) {
  cat("----", name, ":", nrow(d), "rows\n")
  cat(paste(head(names(d), 120), collapse = " "), "\n")
}

## ---------- Arm coding ----------
arm_from_labels <- function(x) {
  labs <- attr(x, "labels")
  s <- NULL
  if (!is.null(labs) && length(labs)) {
    s <- tolower(as.character(haven::as_factor(x, levels = "labels")))
  } else if (is.character(x)) {
    s <- tolower(x)
  }
  if (is.null(s)) return(NULL)
  a <- rep(NA_character_, length(s))
  a[grepl("cxl|both|x local|\\+|and local|central.*local", s)] <- "CXL"
  a[is.na(a) & grepl("cli|consult|info", s)] <- "CLI"
  a[is.na(a) & grepl("control|pure", s)] <- "Control"
  a[is.na(a) & grepl("local|chief|chef", s)] <- "Local"
  a[is.na(a) & grepl("central|state|dgrkoc", s)] <- "Central"
  if (sum(!is.na(a)) == 0) return(NULL)
  a
}
arm_from_counts <- function(code, nbid) {
  tab <- tapply(nbid, code, function(z) length(unique(z)))
  tab <- tab[!is.na(names(tab))]
  cat("Neighborhood counts by treatment code:\n"); print(tab)
  codes <- as.numeric(names(tab)); cnt <- as.numeric(tab)
  map <- setNames(rep(NA_character_, length(codes)), names(tab))
  # control: smallest (<= 10)
  if (any(cnt <= 10)) map[which.min(cnt)] <- "Control"
  rem <- which(is.na(map))
  big <- rem[order(-cnt[rem])][1:2]
  big <- big[order(codes[big])]
  map[big[1]] <- "Central"; map[big[2]] <- "Local"
  rem <- which(is.na(map))
  if (length(rem)) {
    cli <- rem[which.min(abs(cnt[rem] - 80))]; map[cli] <- "CLI"
    rem <- which(is.na(map))
    if (length(rem)) { cxl <- rem[which.min(abs(cnt[rem] - 50))]; map[cxl] <- "CXL" }
  }
  print(map)
  unname(map[as.character(code)])
}

## ---------- Register ----------
reg <- rd("admin_data/registration_noPII.dta")
info("registration", reg)
nb_v <- pick(reg, c("a7", "polygon", "grid_nm", "neighborhood", "poly"))
cp_v <- pick(reg, c("compound1", "compound", "compound_code", "code", "tax_id", "taxid"), "compound")
cat("nb id:", nb_v, " compound id:", cp_v, "\n")
reg$nbid <- as.character(num(reg[[nb_v]]))
if (all(is.na(reg$nbid))) reg$nbid <- as.character(reg[[nb_v]])
reg$cid <- as.character(reg[[cp_v]])

if ("pilot" %in% names(reg)) { pv <- num(reg$pilot); reg <- reg[is.na(pv) | pv != 1, ] }
reg <- reg[!is.na(reg$cid) & reg$cid != "", ]
reg <- reg[!duplicated(reg$cid), ]

# Treatment assignment
ra <- tryCatch(rd("admin_data/randomization_assignment.dta"), error = function(e) NULL)
if (!is.null(ra)) info("randomization_assignment", ra)
tr_v <- pick(reg, c("tmt", "treatment", "treat", "arm", "tmt_2018"))
arm_reg <- NULL
if (!is.na(tr_v)) {
  cat("Treatment variable in register:", tr_v, "\n"); print(table(reg[[tr_v]], useNA = "ifany"))
  arm_reg <- arm_from_labels(reg[[tr_v]])
  if (is.null(arm_reg)) arm_reg <- arm_from_counts(num(reg[[tr_v]]), reg$nbid)
} else if (!is.null(ra)) {
  rnb <- pick(ra, c(nb_v, "a7", "polygon"))
  rtv <- pick(ra, c("tmt", "treatment", "treat", "arm"), "tmt|treat")
  ra$nbid <- as.character(num(ra[[rnb]]))
  a <- arm_from_labels(ra[[rtv]])
  if (is.null(a)) a <- arm_from_counts(num(ra[[rtv]]), ra$nbid)
  ra$arm <- a
  arm_reg <- ra$arm[match(reg$nbid, ra$nbid)]
}
reg$arm <- arm_reg
# one arm per neighborhood (mode)
nbarm <- reg %>% filter(!is.na(arm)) %>% count(nbid, arm) %>% group_by(nbid) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>% ungroup() %>% dplyr::select(nbid, arm)
reg$arm <- nbarm$arm[match(reg$nbid, nbarm$nbid)]
cat("Neighborhoods by arm:\n"); print(table(nbarm$arm))

# Stratum
st_v <- pick(reg, c("stratum", "strata"))
if (!is.na(st_v)) {
  reg$stratum_fe <- as.character(num(reg[[st_v]]))
} else {
  st <- rd("admin_data/stratum.dta"); info("stratum", st)
  snb <- pick(st, c(nb_v, "a7", "polygon")); ssv <- pick(st, c("stratum", "strata"), "strat")
  reg$stratum_fe <- as.character(num(st[[ssv]]))[match(reg$nbid, as.character(num(st[[snb]])))]
}
if (all(is.na(reg$stratum_fe))) {
  st <- rd("admin_data/stratum.dta")
  snb <- pick(st, c(nb_v, "a7", "polygon")); ssv <- pick(st, c("stratum", "strata"), "strat")
  reg$stratum_fe <- as.character(num(st[[ssv]]))[match(reg$nbid, as.character(num(st[[snb]])))]
}

# House type
h_v <- pick(reg, c("house", "house_type", "rate_assigned"))
reg$house_fe <- as.character(num(reg[[h_v]]))
if (!is.null(attr(reg[[h_v]], "labels"))) {
  hl <- tolower(as.character(haven::as_factor(reg[[h_v]], levels = "labels")))
  cat("House labels:\n"); print(table(hl, useNA = "ifany"))
  reg <- reg[is.na(hl) | !grepl("villa", hl), ]
} else {
  print(table(reg$house_fe, useNA = "ifany"))
}

# Exempt
ex_v <- pick(reg, c("exempt", "exempt_status", "designate"))
reg$exempt01 <- if (!is.na(ex_v)) yes01(reg[[ex_v]]) else 0
reg$exempt01[is.na(reg$exempt01)] <- 0

## ---------- Payments ----------
tp <- rd("admin_data/tax_payments_noPII.dta"); info("tax_payments", tp)
tcp <- pick(tp, c(cp_v, "compound1", "compound", "compound_code", "code", "tax_id"), "compound")
amt_v <- pick(tp, c("amount", "amt_paid", "amount_paid", "amt", "paid_amount", "taxes_paid_amt"), "amount|amt")
tp$cid <- as.character(tp[[tcp]])
tp$amt <- if (!is.na(amt_v)) num(tp[[amt_v]]) else NA_real_
pay_v <- pick(tp, c("paid", "taxes_paid", "paid_tax"))
if (!is.na(pay_v)) {
  tp$pd <- yes01(tp[[pay_v]])
} else tp$pd <- 1
if (all(is.na(tp$amt))) tp$amt <- 0
tp$amt[is.na(tp$amt)] <- 0
tpa <- tp %>% filter(!is.na(cid)) %>% group_by(cid) %>%
  summarise(paid_any = as.numeric(any(pd == 1 | amt > 0, na.rm = TRUE)),
            amt_sum = sum(amt[pd == 1 | is.na(pd) | amt > 0], na.rm = TRUE), .groups = "drop")
reg$taxes_paid <- ifelse(reg$cid %in% tpa$cid[tpa$paid_any == 1], 1, 0)
reg$revenue <- tpa$amt_sum[match(reg$cid, tpa$cid)]
reg$revenue[is.na(reg$revenue) | reg$taxes_paid == 0] <- 0
cat("Matched payers:", sum(reg$taxes_paid), "of", nrow(tpa), "payment ids\n")

## ---------- Campaign timing (neighborhood month) ----------
to_month <- function(x) {
  if (inherits(x, "Date")) return(as.numeric(format(x, "%Y")) * 12 + as.numeric(format(x, "%m")))
  if (inherits(x, "POSIXt")) return(as.numeric(format(x, "%Y")) * 12 + as.numeric(format(x, "%m")))
  labs <- attr(x, "labels")
  if (!is.null(labs) && length(labs) && !is.character(x)) {
    s <- tolower(as.character(haven::as_factor(x, levels = "labels")))
    mm <- to_month(s)
    if (sum(!is.na(mm)) > 0) return(mm)
  }
  if (is.character(x)) {
    s <- tolower(trimws(x))
    en <- tolower(month.name); fr <- c("janvier", "fevrier", "mars", "avril", "mai", "juin", "juillet", "aout", "septembre", "octobre", "novembre", "decembre")
    s <- iconv(s, to = "ASCII//TRANSLIT")
    out <- rep(NA_real_, length(s))
    for (i in 1:12) {
      hit <- grepl(paste0("^(", substr(en[i], 1, 3), "|", substr(fr[i], 1, 4), ")"), s) | grepl(en[i], s) | grepl(fr[i], s)
      out[is.na(out) & hit] <- i
    }
    nn <- suppressWarnings(as.numeric(s)); out[is.na(out)] <- nn[is.na(out)]
    yr <- suppressWarnings(as.numeric(sub(".*(20[0-9]{2}).*", "\\1", s)))
    yr[is.na(yr) | !grepl("20[0-9]{2}", s)] <- 2018
    out <- ifelse(!is.na(out) & out <= 12, yr * 12 + out, out)
    return(out)
  }
  v <- num(x)
  if (all(is.na(v))) return(v)
  mx <- max(v, na.rm = TRUE)
  if (mx > 1e9) { d <- as.Date(as.POSIXct(v / 1000, origin = "1960-01-01", tz = "UTC")); return(as.numeric(format(d, "%Y")) * 12 + as.numeric(format(d, "%m"))) }
  if (mx > 5000) { d <- as.Date(v, origin = "1960-01-01"); return(as.numeric(format(d, "%Y")) * 12 + as.numeric(format(d, "%m"))) }
  if (mx > 400) { return((1960 * 12 + 1) + v) }  # %tm
  if (mx <= 12) return(2018 * 12 + v)
  v
}
nbm <- NULL
cci <- tryCatch(rd("admin_data/campaign_collector_info.dta"), error = function(e) NULL)
if (!is.null(cci)) {
  info("campaign_collector_info", cci)
  cnb <- pick(cci, c(nb_v, "a7", "polygon", "grid_nm"))
  cmv <- pick(cci, c("month", "campaign_month", "month_collect"), "^month")
  if (!is.na(cnb) && !is.na(cmv)) {
    cat("Month var raw:\n"); print(head(table(cci[[cmv]], useNA = "ifany"), 20))
    nbm <- data.frame(nbid = as.character(num(cci[[cnb]])), m = to_month(cci[[cmv]])) %>%
      filter(!is.na(nbid), !is.na(m)) %>% group_by(nbid) %>% summarise(m = min(m), .groups = "drop")
  }
}
if (is.null(nbm) || nrow(nbm) < 100) {
  rmv <- pick(reg, c("month", "campaign_month"))
  if (!is.na(rmv)) {
    reg$m_tmp <- to_month(reg[[rmv]])
    nbm <- reg %>% filter(!is.na(m_tmp)) %>% group_by(nbid) %>% summarise(m = median(m_tmp), .groups = "drop")
  }
}
if (is.null(nbm) || nrow(nbm) < 100) {
  ml0 <- rd("survey_data/midline_noPII.dta")
  mnb <- pick(ml0, c(nb_v, "a7", "polygon"))
  ml0$m_tmp <- to_month(ml0$month)
  nbm <- data.frame(nbid = as.character(num(ml0[[mnb]])), m = ml0$m_tmp) %>%
    filter(!is.na(m)) %>% group_by(nbid) %>% summarise(m = median(m), .groups = "drop")
}
reg$nbmonth <- nbm$m[match(reg$nbid, nbm$nbid)]
cat("Neighborhood campaign month by arm:\n")
print(table(nbarm$arm, nbm$m[match(nbarm$nbid, nbm$nbid)], useNA = "ifany"))

period_fun <- function(month, arm, A, B) {
  mA <- month[arm == A]; mB <- month[arm == B]
  first <- (min(mA, na.rm = TRUE) + min(mB, na.rm = TRUE)) / 2
  last <- (max(mA, na.rm = TRUE) + max(mB, na.rm = TRUE)) / 2
  cat("Periods", A, "vs", B, ": first", first, "last", last, "\n")
  ifelse(!is.na(month) & month >= first & month <= last,
         as.character(floor((month - first) / 2)), NA_character_)
}

## ---------- Regression helper ----------
getb <- function(fml, data, var, clus = ~nbid) {
  r <- tryCatch({
    m <- feols(fml, data = data, cluster = clus)
    cat(deparse(fml), " N =", nobs(m), " b =", coef(m)[var], " se =", sqrt(diag(vcov(m)))[var], "\n")
    list(b = unname(coef(m)[var]), n = nobs(m))
  }, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); list(b = NA, n = NA) })
  r
}

res <- list()

## ---------- Table 4: Local vs Central ----------
lc <- reg %>% filter(arm %in% c("Local", "Central"), !is.na(stratum_fe))
lc$local <- as.numeric(lc$arm == "Local")
lc$period <- period_fun(lc$nbmonth, lc$arm, "Local", "Central")

r1 <- getb(taxes_paid ~ local | stratum_fe, lc, "local")
res$compliance_local_table4_panelA_col1 <- r1$b
res$n_obs_table4_col1 <- nrow(lc)
lc2 <- lc %>% filter(!is.na(period))
r2 <- getb(taxes_paid ~ local | stratum_fe + period, lc2, "local")
res$compliance_local_table4_panelA_col2 <- r2$b
res$n_obs_table4_col2 <- nrow(lc2)
r4 <- getb(taxes_paid ~ local | stratum_fe + period + house_fe, lc2, "local")
res$compliance_local_house_fe_table4_panelA_col4 <- r4$b
r5 <- getb(taxes_paid ~ local | stratum_fe + period + house_fe, lc2 %>% filter(exempt01 == 0), "local")
res$compliance_local_exempt_excluded_table4_panelA_col5 <- r5$b
rb2 <- getb(revenue ~ local | stratum_fe + period, lc2, "local")
res$revenue_local_table4_panelB_col2 <- rb2$b
rb4 <- getb(revenue ~ local | stratum_fe + period + house_fe, lc2, "local")
res$revenue_local_house_fe_table4_panelB_col4 <- rb4$b

## ---------- Table 5: bribe at endline ----------
res$paid_bribe_endline_local_table5_panelB <- tryCatch({
  en <- rd("survey_data/endline_round1_noPII.dta"); info("endline_round1", en)
  enb <- pick(en, c(nb_v, "a7", "polygon"))
  bv <- pick(en, c("paid_bribe", "bribe", "transport", "bribe_paid"), "bribe")
  cat("Bribe var:", bv, "\n"); print(table(en[[bv]], useNA = "ifany"))
  en$nbid <- as.character(num(en[[enb]]))
  en$y <- yes01(en[[bv]])
  en$arm <- nbarm$arm[match(en$nbid, nbarm$nbid)]
  en$stratum_fe <- reg$stratum_fe[match(en$nbid, reg$nbid)]
  e2 <- en %>% filter(arm %in% c("Local", "Central"), !is.na(y), !is.na(stratum_fe))
  e2$local <- as.numeric(e2$arm == "Local")
  getb(y ~ local | stratum_fe, e2, "local")$b
}, error = function(e) { cat("T5 error:", conditionMessage(e), "\n"); NA })

## ---------- Table 6: visited by collector (midline) ----------
res$visited_by_collector_local_table6_col1 <- tryCatch({
  ml <- rd("survey_data/midline_noPII.dta"); info("midline", ml)
  mcp <- pick(ml, c(cp_v, "compound1", "compound", "code"), "compound")
  mnb <- pick(ml, c(nb_v, "a7", "polygon"))
  vv <- pick(ml, c("visited_post", "visit_post", "visited", "visits"), "visit")
  cat("Visited var:", vv, "\n"); print(head(table(ml[[vv]], useNA = "ifany"), 15))
  ml$cid <- if (!is.na(mcp)) as.character(ml[[mcp]]) else NA
  ml$nbid <- if (!is.na(mnb)) as.character(num(ml[[mnb]])) else reg$nbid[match(ml$cid, reg$cid)]
  ml$nbid[is.na(ml$nbid)] <- reg$nbid[match(ml$cid[is.na(ml$nbid)], reg$cid)]
  ml$y <- if (vv == "visits") as.numeric(num(ml[[vv]]) > 0) else yes01(ml[[vv]])
  ml$house_fe <- reg$house_fe[match(ml$cid, reg$cid)]
  if (sum(!is.na(ml$house_fe)) < 100 && "house" %in% names(ml)) ml$house_fe <- as.character(num(ml$house))
  ml$arm <- nbarm$arm[match(ml$nbid, nbarm$nbid)]
  ml$stratum_fe <- reg$stratum_fe[match(ml$nbid, reg$nbid)]
  ml$nbmonth <- nbm$m[match(ml$nbid, nbm$nbid)]
  if ("pilot" %in% names(ml)) { pv <- num(ml$pilot); ml <- ml[is.na(pv) | pv != 1, ] }
  m2 <- ml %>% filter(arm %in% c("Local", "Central"), !is.na(y), !is.na(stratum_fe))
  m2 <- m2[!(duplicated(m2$cid) & !is.na(m2$cid)), ]
  m2$local <- as.numeric(m2$arm == "Local")
  m2$period <- period_fun(m2$nbmonth, m2$arm, "Local", "Central")
  m2 <- m2 %>% filter(!is.na(period))
  getb(y ~ local | stratum_fe + period + house_fe, m2, "local")$b
}, error = function(e) { cat("T6 error:", conditionMessage(e), "\n"); NA })

## ---------- Table 7: CLI vs Central ----------
cc <- reg %>% filter(arm %in% c("CLI", "Central"), !is.na(stratum_fe))
cc$cli <- as.numeric(cc$arm == "CLI")
cc$period <- period_fun(cc$nbmonth, cc$arm, "CLI", "Central")
cc2 <- cc %>% filter(!is.na(period))
res$compliance_cli_table7_col1 <- getb(taxes_paid ~ cli | stratum_fe + period + house_fe, cc2, "cli")$b
res$revenue_cli_table7_col2 <- getb(revenue ~ cli | stratum_fe + period + house_fe, cc2, "cli")$b

## ---------- Table 8: value of chiefs' information (CLI only) ----------
res$compliance_ease_of_payment_cli_table8_panelA_col2 <- tryCatch({
  ch <- rd("survey_data/chief_consultations.dta"); info("chief_consultations", ch)
  ccp <- pick(ch, c(cp_v, "compound1", "compound", "code"), "compound")
  ev <- pick(ch, c("pay_ease", "ease_pay", "ease_of_payment", "ease", "ability_pay", "able_pay", "capacity_pay"),
             "ease|abil|able|capac")
  cat("Ease var:", ev, "\n"); print(table(ch[[ev]], useNA = "ifany"))
  ch$cid <- as.character(ch[[ccp]])
  e <- num(ch[[ev]]); e[e < 0 | e > 10] <- NA
  ch$ease <- e
  ch <- ch %>% filter(!is.na(cid), !is.na(ease)) %>% group_by(cid) %>% summarise(ease = mean(ease), .groups = "drop")
  cl <- reg %>% filter(arm == "CLI", !is.na(stratum_fe))
  cl$ease <- ch$ease[match(cl$cid, ch$cid)]
  cl <- cl %>% filter(!is.na(ease))
  getb(taxes_paid ~ ease | stratum_fe + house_fe, cl, "ease")$b
}, error = function(e) { cat("T8 error:", conditionMessage(e), "\n"); NA })

## ---------- Output ----------
for (nm in c("compliance_local_table4_panelA_col1", "compliance_local_table4_panelA_col2",
             "compliance_local_house_fe_table4_panelA_col4", "compliance_local_exempt_excluded_table4_panelA_col5",
             "revenue_local_table4_panelB_col2", "revenue_local_house_fe_table4_panelB_col4",
             "n_obs_table4_col1", "n_obs_table4_col2", "paid_bribe_endline_local_table5_panelB",
             "visited_by_collector_local_table6_col1", "compliance_cli_table7_col1", "revenue_cli_table7_col2",
             "compliance_ease_of_payment_cli_table8_panelA_col2")) {
  v <- res[[nm]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", nm, format(v, digits = 10)))
}
