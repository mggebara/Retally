suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/balan_2022_local_elites_state_capacity.script-free/Replication Materials - Updated October 2025/Data/01_base"
adm <- file.path(root, "admin_data")
srv <- file.path(root, "survey_data")

res <- list()
put <- function(n, v) res[[n]] <<- v

rd <- function(p) {
  d <- haven::read_dta(p)
  names(d) <- make.unique(tolower(names(d)))
  d
}
fc <- function(d, cands) {
  x <- intersect(cands, names(d))
  if (length(x)) x[1] else NA_character_
}
num <- function(x) as.numeric(haven::zap_labels(x))
bin01 <- function(x) {
  if (is.character(x)) {
    l <- tolower(trimws(x))
    return(ifelse(l %in% c("yes", "oui", "1", "true"), 1, ifelse(l %in% c("no", "non", "0", "false"), 0, NA)))
  }
  x <- num(x)
  x[!is.na(x) & (x < 0 | x > 90)] <- NA
  v <- unique(x[!is.na(x)])
  if (length(v) && all(v %in% c(1, 2))) x <- ifelse(x == 1, 1, 0)
  x[!is.na(x) & !(x %in% c(0, 1))] <- NA
  x
}
show_names <- function(lbl, d) message(lbl, ": ", paste(names(d), collapse = " "))

# ---- treatment arm mapping ----
arm_from <- function(d) {
  n <- nrow(d)
  arm <- rep(NA_character_, n)
  if (all(c("t_l", "t_c") %in% names(d))) {
    g <- function(v) if (v %in% names(d)) { z <- num(d[[v]]); !is.na(z) & z == 1 } else rep(FALSE, n)
    arm[g("t_c")] <- "Central"; arm[g("t_l")] <- "Local"
    arm[g("t_cli")] <- "CLI"; arm[g("t_cxl")] <- "CXL"
    if ("t_ctrl" %in% names(d)) arm[g("t_ctrl")] <- "Control"
    if ("t_control" %in% names(d)) arm[g("t_control")] <- "Control"
    if (any(!is.na(arm))) return(arm)
  }
  tv <- fc(d, c("tmt", "treatment", "treat", "arm", "treatment_arm"))
  if (is.na(tv)) return(arm)
  x <- d[[tv]]
  lab <- NULL
  if (haven::is.labelled(x)) {
    lab <- tolower(as.character(haven::as_factor(x, levels = "labels")))
  } else if (is.character(x) || is.factor(x)) {
    lab <- tolower(as.character(x))
  }
  if (!is.null(lab) && any(grepl("[a-z]", lab))) {
    cli <- grepl("cli|info|consult", lab)
    cxl <- (grepl("cxl|cross|together|joint|collab", lab) | (grepl("central", lab) & grepl("local", lab))) & !cli
    ctl <- grepl("control|pure", lab) & !cli & !cxl
    loc <- grepl("local|chief|chef", lab) & !cli & !cxl & !ctl
    cen <- grepl("central|state", lab) & !cli & !cxl & !ctl & !loc
    arm[cen] <- "Central"; arm[loc] <- "Local"; arm[cli] <- "CLI"; arm[cxl] <- "CXL"; arm[ctl] <- "Control"
    if (any(!is.na(arm))) return(arm)
  }
  z <- num(x)
  arm[z == 1] <- "Central"; arm[z == 2] <- "Local"; arm[z == 3] <- "CLI"; arm[z == 4] <- "CXL"
  arm[z %in% c(0, 5)] <- "Control"
  arm
}

# ---- tax roll ----
tr <- rd(file.path(adm, "taxroll_noPII.dta"))
show_names("taxroll", tr)
nb <- fc(tr, c("a7", "polygon", "neighborhood", "grid_nm"))
idv <- fc(tr, c("compound1", "compound_code", "code", "compound", "id", "prop_id"))
tr$arm <- arm_from(tr)
if (all(is.na(tr$arm))) {
  ra <- rd(file.path(adm, "randomization_assignment.dta"))
  show_names("randassign", ra)
  ra$arm <- arm_from(ra)
  rnb <- fc(ra, c(nb, "a7", "polygon"))
  ra2 <- ra %>% transmute(.nb = .data[[rnb]], arm2 = arm) %>% distinct(.nb, .keep_all = TRUE)
  tr <- tr %>% mutate(.nb = .data[[nb]]) %>% left_join(ra2, by = ".nb") %>% mutate(arm = arm2) %>% select(-arm2, -.nb)
}
message("arm table: "); print(table(tr$arm, useNA = "ifany"))

# stratum
if (!("stratum" %in% names(tr))) {
  st <- rd(file.path(adm, "stratum.dta"))
  snb <- fc(st, c(nb, "a7", "polygon"))
  st2 <- st %>% transmute(.nb = .data[[snb]], stratum = .data[["stratum"]]) %>% distinct(.nb, .keep_all = TRUE)
  tr <- tr %>% mutate(.nb = .data[[nb]]) %>% left_join(st2, by = ".nb") %>% select(-.nb)
}
tr$stratum <- num(tr$stratum)
tr$nbid <- tr[[nb]]
if (is.labelled(tr$nbid)) tr$nbid <- num(tr$nbid)

# pilot / villa exclusions
if ("pilot" %in% names(tr)) {
  pz <- num(tr$pilot)
  tr <- tr[is.na(pz) | pz != 1, ]
}
if ("house" %in% names(tr)) {
  if (haven::is.labelled(tr$house)) {
    hl <- tolower(as.character(haven::as_factor(tr$house, levels = "labels")))
    tr <- tr[!grepl("villa", hl), ]
  }
  tr$house_fe <- num(tr$house)
} else tr$house_fe <- 1

# payments
pv <- fc(tr, c("taxes_paid", "paid", "tax_paid", "paid_tax", "compliance", "paid_2018"))
av <- fc(tr, c("taxes_paid_amt", "amount", "amt_paid", "tax_amount", "revenue", "amount_paid", "paid_amt"))
if (is.na(pv) && is.na(av)) {
  tp <- rd(file.path(adm, "tax_payments_noPII.dta"))
  show_names("tax_payments", tp)
  key <- intersect(c(idv, "compound1", "code", "compound_code"), names(tp))[1]
  tpa <- fc(tp, c("amount", "taxes_paid_amt", "amt_paid", "amount_paid"))
  tp2 <- tp %>% mutate(.k = .data[[key]], .a = if (!is.na(tpa)) num(.data[[tpa]]) else 1) %>%
    group_by(.k) %>% summarise(pay_amt = sum(.a, na.rm = TRUE), .groups = "drop")
  tr <- tr %>% mutate(.k = .data[[key]]) %>% left_join(tp2, by = ".k") %>% select(-.k)
  tr$rev <- ifelse(is.na(tr$pay_amt), 0, tr$pay_amt)
  tr$paid01 <- as.numeric(tr$rev > 0)
} else {
  if (!is.na(pv)) tr$paid01 <- bin01(tr[[pv]])
  if (!is.na(av)) {
    a <- num(tr[[av]]); a[is.na(a) | a < 0] <- 0; tr$rev <- a
  }
  if (is.na(pv)) tr$paid01 <- as.numeric(tr$rev > 0)
  if (is.na(av)) tr$rev <- NA_real_
  tr$paid01[is.na(tr$paid01)] <- 0
  if (!is.na(av)) tr$rev[tr$paid01 == 0] <- 0
}

# exempt
ev <- fc(tr, c("exempt", "exempt_status", "designate_exempt"))
if (!is.na(ev)) tr$exempt01 <- bin01(tr[[ev]]) else {
  tr$exempt01 <- NA_real_
  try({
    rg <- rd(file.path(adm, "registration_noPII.dta"))
    key <- intersect(c(idv, "compound1", "code", "compound_code"), names(rg))[1]
    rg2 <- rg %>% transmute(.k = .data[[key]], ex = bin01(.data[["exempt"]])) %>% group_by(.k) %>%
      summarise(ex = suppressWarnings(max(ex, na.rm = TRUE)), .groups = "drop")
    rg2$ex[!is.finite(rg2$ex)] <- NA
    tr <- tr %>% mutate(.k = .data[[idv]]) %>% left_join(rg2, by = ".k") %>% mutate(exempt01 = ex) %>% select(-ex, -.k)
  }, silent = TRUE)
}
tr$exempt01[is.na(tr$exempt01)] <- 0

# ---- neighborhood-level table and time FE ----
nbt <- tr %>% filter(!is.na(nbid)) %>% group_by(nbid) %>%
  summarise(arm = first(na.omit(arm)), stratum = first(na.omit(stratum)), .groups = "drop")

tfe_cols <- names(tr)[grepl("time_fe|timefe|tdm", names(tr))]
message("time fe cand: ", paste(tfe_cols, collapse = " "))
pick_tfe <- function(pat) {
  x <- tfe_cols[grepl(pat, tfe_cols)]
  x2 <- x[grepl("2mo", x)]
  if (length(x2)) x2[1] else if (length(x)) x[1] else NA_character_
}
tfe_l <- pick_tfe("cvl$|_cvl|lvc|cl$")
tfe_cli <- pick_tfe("cvcli|cliv|ccli|cli")
if (!is.na(tfe_l) && identical(tfe_l, tfe_cli)) tfe_cli <- NA_character_

# neighborhood campaign date for fallback construction
nb_date <- NULL
try({
  sc <- rd(file.path(adm, "randomization_schedule.dta"))
  show_names("schedule", sc)
  snb <- fc(sc, c(nb, "a7", "polygon"))
  isd <- sapply(sc, function(z) inherits(z, "Date") || inherits(z, "POSIXt"))
  cand <- names(sc)[isd]
  dc <- c(cand[grepl("start|first|begin", cand)], cand)[1]
  unit <- "day"
  if (is.na(dc)) {
    mc <- names(sc)[grepl("month|start|time|period|wave", names(sc)) & sapply(sc, is.numeric)]
    mc <- setdiff(mc, snb)
    dc <- mc[1]; unit <- "month"
  }
  if (!is.na(dc)) {
    dd <- sc[[dc]]
    dn <- if (inherits(dd, "Date")) as.numeric(dd) else if (inherits(dd, "POSIXt")) as.numeric(as.Date(dd)) else num(dd)
    if (unit == "month" && max(dn, na.rm = TRUE) > 1000) unit <- "day"
    nb_date <- data.frame(nbid = sc[[snb]], d = dn) %>% mutate(nbid = if (is.labelled(nbid)) num(nbid) else nbid) %>%
      group_by(nbid) %>% summarise(d = suppressWarnings(min(d, na.rm = TRUE)), .groups = "drop")
    nb_date$d[!is.finite(nb_date$d)] <- NA
    attr(nb_date, "unit") <- unit
  }
}, silent = TRUE)
if (is.null(nb_date)) {
  try({
    mc <- fc(tr, c("month", "campaign_month", "month_campaign"))
    if (!is.na(mc)) {
      nb_date <- tr %>% mutate(d = num(.data[[mc]])) %>% group_by(nbid) %>%
        summarise(d = suppressWarnings(median(d, na.rm = TRUE)), .groups = "drop")
      attr(nb_date, "unit") <- "month"
    }
  }, silent = TRUE)
}

build_tfe <- function(armA, armB) {
  if (is.null(nb_date)) return(NULL)
  unit <- attr(nb_date, "unit"); w <- if (unit == "month") 2 else 61
  x <- nbt %>% inner_join(nb_date, by = "nbid") %>% filter(arm %in% c(armA, armB), !is.na(d))
  fA <- min(x$d[x$arm == armA]); fB <- min(x$d[x$arm == armB])
  lA <- max(x$d[x$arm == armA]); lB <- max(x$d[x$arm == armB])
  s <- (fA + fB) / 2; e <- (lA + lB) / 2
  x$tfe <- ifelse(x$d >= s & x$d <= e, floor((x$d - s) / w), NA)
  x %>% select(nbid, tfe)
}

attach_tfe <- function(d, colname, armA, armB) {
  if (!is.na(colname)) {
    d$tfe <- num(d[[colname]])
  } else {
    t2 <- build_tfe(armA, armB)
    if (is.null(t2)) { d$tfe <- NA_real_ } else {
      d <- d %>% select(-any_of("tfe")) %>% left_join(t2, by = "nbid")
    }
  }
  d
}

# nbhd-level tfe tables (for survey merges)
nb_tfe <- function(colname, armA, armB) {
  if (!is.na(colname)) {
    tr %>% mutate(tfe = num(.data[[colname]])) %>% group_by(nbid) %>%
      summarise(tfe = first(na.omit(tfe)), .groups = "drop")
  } else build_tfe(armA, armB)
}

safe <- function(expr) tryCatch(expr, error = function(e) { message("ERR: ", conditionMessage(e)); NA })
getb <- function(m, v) unname(coef(m)[v])

# ---- Table 4 ----
lc <- tr %>% filter(arm %in% c("Local", "Central")) %>% mutate(local = as.numeric(arm == "Local"))
lc <- attach_tfe(lc, tfe_l, "Local", "Central")
message("tfe L v C table:"); print(table(lc$tfe, useNA = "ifany"))

m1 <- safe(feols(paid01 ~ local | stratum, data = lc, cluster = ~nbid))
put("compliance_local_table4_panelA_col1", safe(getb(m1, "local")))
put("n_obs_table4_col1", safe(nobs(m1)))

lc2 <- lc %>% filter(!is.na(tfe))
m2 <- safe(feols(paid01 ~ local | stratum + tfe, data = lc2, cluster = ~nbid))
put("compliance_local_table4_panelA_col2", safe(getb(m2, "local")))
put("n_obs_table4_col2", safe(nobs(m2)))

m4 <- safe(feols(paid01 ~ local | stratum + tfe + house_fe, data = lc2, cluster = ~nbid))
put("compliance_local_house_fe_table4_panelA_col4", safe(getb(m4, "local")))

m5 <- safe(feols(paid01 ~ local | stratum + tfe + house_fe, data = lc2 %>% filter(exempt01 != 1), cluster = ~nbid))
put("compliance_local_exempt_excluded_table4_panelA_col5", safe(getb(m5, "local")))

r2 <- safe(feols(rev ~ local | stratum + tfe, data = lc2, cluster = ~nbid))
put("revenue_local_table4_panelB_col2", safe(getb(r2, "local")))
r4 <- safe(feols(rev ~ local | stratum + tfe + house_fe, data = lc2, cluster = ~nbid))
put("revenue_local_house_fe_table4_panelB_col4", safe(getb(r4, "local")))

# ---- Table 7: CLI vs Central ----
cc <- tr %>% filter(arm %in% c("CLI", "Central")) %>% mutate(cli = as.numeric(arm == "CLI"))
cc <- attach_tfe(cc, tfe_cli, "CLI", "Central")
cc2 <- cc %>% filter(!is.na(tfe))
t7a <- safe(feols(paid01 ~ cli | house_fe + stratum + tfe, data = cc2, cluster = ~nbid))
put("compliance_cli_table7_col1", safe(getb(t7a, "cli")))
t7b <- safe(feols(rev ~ cli | house_fe + stratum + tfe, data = cc2, cluster = ~nbid))
put("revenue_cli_table7_col2", safe(getb(t7b, "cli")))

# ---- Table 8: ease of payment within CLI ----
put("compliance_ease_of_payment_cli_table8_panelA_col2", safe({
  cl <- tr %>% filter(arm == "CLI")
  ecol <- names(cl)[grepl("ease|pay_ease|ability", names(cl))]
  ecol <- ecol[!grepl("will", ecol)]
  if (length(ecol)) {
    cl$ease <- num(cl[[ecol[1]]])
  } else {
    ch <- rd(file.path(srv, "chief_consultations.dta"))
    show_names("chief_consult", ch)
    ec <- names(ch)[grepl("ease|ability|pay_ease|able", names(ch)) & !grepl("will", names(ch))]
    key <- intersect(c(idv, "compound1", "code", "compound_code"), names(ch))[1]
    ch2 <- ch %>% transmute(.k = .data[[key]], ease = num(.data[[ec[1]]])) %>% distinct(.k, .keep_all = TRUE)
    cl <- cl %>% mutate(.k = .data[[key]]) %>% left_join(ch2, by = ".k")
  }
  cl$ease[!is.na(cl$ease) & (cl$ease < 0 | cl$ease > 10)] <- NA
  m <- feols(paid01 ~ ease | house_fe + stratum, data = cl, cluster = ~nbid)
  getb(m, "ease")
}))

# ---- Table 6: visited (midline) ----
put("visited_by_collector_local_table6_col1", safe({
  ml <- rd(file.path(srv, "midline_noPII.dta"))
  show_names("midline", ml)
  mnb <- fc(ml, c(nb, "a7", "polygon"))
  ml$nbid <- if (is.labelled(ml[[mnb]])) num(ml[[mnb]]) else ml[[mnb]]
  ml$vis <- bin01(ml$visited)
  if ("house" %in% names(ml)) ml$house_fe <- num(ml$house) else {
    key <- intersect(c(idv, "compound1", "code", "compound_code"), names(ml))[1]
    hh <- tr %>% transmute(.k = .data[[key]], house_fe) %>% distinct(.k, .keep_all = TRUE)
    ml <- ml %>% mutate(.k = .data[[key]]) %>% left_join(hh, by = ".k")
  }
  t2 <- nb_tfe(tfe_l, "Local", "Central")
  d <- ml %>% select(nbid, vis, house_fe) %>% inner_join(nbt, by = "nbid") %>%
    filter(arm %in% c("Local", "Central")) %>% left_join(t2, by = "nbid") %>%
    mutate(local = as.numeric(arm == "Local")) %>% filter(!is.na(tfe))
  m <- feols(vis ~ local | house_fe + stratum + tfe, data = d, cluster = ~nbid)
  getb(m, "local")
}))

# ---- Table 5: bribe (endline) ----
put("paid_bribe_endline_local_table5_panelB", safe({
  en <- rd(file.path(srv, "endline_round1_noPII.dta"))
  show_names("endline1", en)
  enb <- fc(en, c(nb, "a7", "polygon"))
  en$nbid <- if (is.labelled(en[[enb]])) num(en[[enb]]) else en[[enb]]
  if ("replacement" %in% names(en)) {
    rp <- num(en$replacement); en <- en[is.na(rp) | rp != 1, ]
  }
  bv <- fc(en, c("bribe", "paid_bribe", "transport"))
  en$br <- bin01(en[[bv]])
  d <- en %>% select(nbid, br) %>% inner_join(nbt, by = "nbid") %>%
    filter(arm %in% c("Local", "Central")) %>% mutate(local = as.numeric(arm == "Local"))
  m <- feols(br ~ local | stratum, data = d, cluster = ~nbid)
  getb(m, "local")
}))

nm <- c("compliance_local_table4_panelA_col1", "compliance_local_table4_panelA_col2",
        "compliance_local_house_fe_table4_panelA_col4", "compliance_local_exempt_excluded_table4_panelA_col5",
        "revenue_local_table4_panelB_col2", "revenue_local_house_fe_table4_panelB_col4",
        "n_obs_table4_col1", "n_obs_table4_col2", "paid_bribe_endline_local_table5_panelB",
        "visited_by_collector_local_table6_col1", "compliance_cli_table7_col1", "revenue_cli_table7_col2",
        "compliance_ease_of_payment_cli_table8_panelA_col2")
for (n in nm) {
  v <- res[[n]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(as.numeric(v[1]), digits = 10)))
}
