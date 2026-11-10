suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- file.path("<repo>/.cache/datasets/balan_2022_local_elites_state_capacity.script-free",
                  "Replication Materials - Updated October 2025", "Data", "01_base")
rd <- function(p) as.data.frame(haven::read_dta(file.path(root, p)))

results <- list()
emit <- function(name, val) { results[[name]] <<- val }

key <- function(x) {
  x <- haven::zap_labels(x)
  if (is.numeric(x)) {
    if (all(is.na(x) | x == round(x))) out <- ifelse(is.na(x), NA, sprintf("%.0f", x)) else out <- as.character(x)
  } else {
    out <- trimws(as.character(x)); out[out == ""] <- NA
  }
  out
}
pickcol <- function(df, cands, regex = NULL, exclude = NULL) {
  if (is.null(df)) return(NULL)
  nm <- names(df)
  for (c in cands) { i <- which(tolower(nm) == tolower(c)); if (length(i)) return(nm[i[1]]) }
  if (!is.null(regex)) {
    i <- grep(regex, nm, ignore.case = TRUE, value = TRUE)
    if (!is.null(exclude)) i <- i[!grepl(exclude, i, ignore.case = TRUE)]
    if (length(i)) return(i[1])
  }
  NULL
}
num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))
to_binary <- function(x) {
  if (haven::is.labelled(x)) {
    labs <- attr(x, "labels")
    v <- num(x)
    yes <- labs[grepl("^(yes|oui)", names(labs), ignore.case = TRUE)]
    no  <- labs[grepl("^(no|non)$|^no\\b|^non\\b", names(labs), ignore.case = TRUE)]
    if (length(yes) && length(no)) {
      out <- ifelse(v %in% yes, 1, ifelse(v %in% no, 0, NA)); return(out)
    }
  }
  v <- num(x)
  v[!is.na(v) & v < 0] <- NA
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(is.na(v), NA, as.numeric(v == 1)))
  ifelse(is.na(v), NA, as.numeric(v > 0))
}
to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.character(x)) {
    d <- suppressWarnings(as.Date(x))
    if (all(is.na(d))) d <- suppressWarnings(as.Date(x, "%d/%m/%Y"))
    return(d)
  }
  x <- num(x); m <- suppressWarnings(median(x, na.rm = TRUE))
  if (is.na(m)) return(as.Date(rep(NA, length(x))))
  if (m > 1e9) return(as.Date(x / 86400000, origin = "1960-01-01"))
  if (m > 15000) return(as.Date(x, origin = "1960-01-01"))
  if (m > 600) return(as.Date(ifelse(is.na(x), NA, paste0(1960 + x %/% 12, "-", sprintf("%02d", x %% 12 + 1), "-01"))))
  as.Date("2018-01-01") + round((x - 1) * 30.44)
}
map_arm <- function(v) {
  if (haven::is.labelled(v)) { cat("arm labels:\n"); print(attr(v, "labels")) }
  lab <- if (haven::is.labelled(v)) as.character(haven::as_factor(v, levels = "labels")) else as.character(v)
  l <- tolower(lab)
  out <- rep(NA_character_, length(l))
  if (any(grepl("[a-z]", l))) {
    out[grepl("control|pure", l)] <- "Control"
    out[is.na(out) & grepl("\\bcli\\b|info|consult", l)] <- "CLI"
    out[is.na(out) & grepl("cxl|central ?x ?local|central.*local|both|joint", l)] <- "CXL"
    out[is.na(out) & grepl("local|chief|chef", l)] <- "Local"
    out[is.na(out) & grepl("central|state", l)] <- "Central"
  }
  if (all(is.na(out))) {
    codes <- num(v)
    tab <- sort(table(codes))
    if (length(tab) == 5) {
      cs <- as.numeric(names(tab))
      out[codes == cs[1]] <- "Control"; out[codes == cs[2]] <- "CXL"; out[codes == cs[3]] <- "CLI"
      big <- sort(cs[4:5])
      out[codes == big[1]] <- "Central"; out[codes == big[2]] <- "Local"
    } else {
      out[codes == 1] <- "Central"; out[codes == 2] <- "Local"; out[codes == 3] <- "CLI"; out[codes == 4] <- "CXL"
      out[is.na(out) & !is.na(codes)] <- "Control"
    }
  }
  out
}
n_arms <- function(a) sum(c("Central", "Local", "CLI", "CXL", "Control") %in% unique(a[!is.na(a)]))
mode_chr <- function(x) { x <- x[!is.na(x)]; if (!length(x)) return(NA_character_); names(sort(table(x), decreasing = TRUE))[1] }

# ---------------- Neighborhood master ----------------
nb <- rd("admin_data/tax_payments_neighborhoods.dta")
cat("nb names:", paste(names(nb), collapse = ", "), "\n")
nb$a7k <- key(nb[[pickcol(nb, c("a7"), "^a7")]])
progc <- pickcol(nb, c("tmt", "treatment", "program"))
nb$arm <- if (!is.null(progc)) map_arm(nb[[progc]]) else NA_character_
cat("arm from nb (", ifelse(is.null(progc), "none", progc), "):\n"); print(table(nb$arm, useNA = "ifany"))

# The neighborhood file's 'program' is not the 5-arm treatment; fall back to the randomization assignment
if (n_arms(nb$arm) < 4) {
  ra_arm <- tryCatch({
    ra <- rd("admin_data/randomization_assignment.dta")
    cat("ra names:", paste(names(ra), collapse = ", "), "\n")
    ra$a7k <- key(ra[[pickcol(ra, c("a7"), "^a7")]])
    tc <- pickcol(ra, c("tmt", "treatment", "treat", "arm", "program"), "tmt|treat")
    ra$arm <- map_arm(ra[[tc]])
    ra %>% filter(!is.na(a7k)) %>% group_by(a7k) %>% summarise(arm_new = mode_chr(arm), .groups = "drop")
  }, error = function(e) { message("ERR ra: ", conditionMessage(e)); NULL })
  if (!is.null(ra_arm) && n_arms(ra_arm$arm_new) >= 4) {
    nb$arm <- NULL
    nb <- left_join(nb, ra_arm, by = "a7k"); nb$arm <- nb$arm_new; nb$arm_new <- NULL
  }
}
if (n_arms(nb$arm) < 4) {
  rg_arm <- tryCatch({
    rg <- rd("admin_data/registration_noPII.dta")
    rg$a7k <- key(rg[[pickcol(rg, c("a7"), "^a7")]])
    tc <- pickcol(rg, c("tmt", "treatment"), "tmt")
    rg$arm <- map_arm(rg[[tc]])
    rg %>% filter(!is.na(a7k)) %>% group_by(a7k) %>% summarise(arm_new = mode_chr(arm), .groups = "drop")
  }, error = function(e) { message("ERR reg tmt: ", conditionMessage(e)); NULL })
  if (!is.null(rg_arm) && n_arms(rg_arm$arm_new) >= 4) {
    nb$arm <- NULL
    nb <- left_join(nb, rg_arm, by = "a7k"); nb$arm <- nb$arm_new; nb$arm_new <- NULL
  }
}
cat("final neighborhood arms:\n"); print(table(nb$arm, useNA = "ifany"))

stc <- pickcol(nb, c("stratum"))
if (!is.null(stc)) nb$strat <- key(nb[[stc]]) else {
  st <- rd("admin_data/stratum.dta"); st$a7k <- key(st[[pickcol(st, c("a7"), "^a7")]])
  st$strat <- key(st[[pickcol(st, c("stratum"), "strat")]])
  nb <- left_join(nb, st[!duplicated(st$a7k), c("a7k", "strat")], by = "a7k")
}
sdc <- pickcol(nb, c("program_start", "start_date", "start"), "start")
nb$sdate <- if (!is.null(sdc)) to_date(nb[[sdc]]) else as.Date(NA)
if (all(is.na(nb$sdate))) {
  rs <- rd("admin_data/randomization_schedule.dta")
  cat("schedule names:", paste(names(rs), collapse = ", "), "\n")
  rs$a7k <- key(rs[[pickcol(rs, c("a7"), "^a7")]])
  dc <- pickcol(rs, c("program_start", "start_date", "date", "start", "month"), "start|date|month")
  rs$sdate2 <- to_date(rs[[dc]])
  rs <- rs %>% group_by(a7k) %>% summarise(sdate2 = suppressWarnings(min(sdate2, na.rm = TRUE)), .groups = "drop")
  nb <- left_join(nb, rs, by = "a7k"); nb$sdate <- nb$sdate2
}
cat("start date range:", format(range(nb$sdate, na.rm = TRUE)), "\n")
nbm <- nb[!duplicated(nb$a7k), c("a7k", "arm", "strat", "sdate")]
print(table(nbm$arm, is.na(nbm$sdate), useNA = "ifany"))

period_map <- function(A, B) {
  d <- nbm[nbm$arm %in% c(A, B) & !is.na(nbm$sdate), ]
  fA <- min(d$sdate[d$arm == A]); fB <- min(d$sdate[d$arm == B])
  lA <- max(d$sdate[d$arm == A]); lB <- max(d$sdate[d$arm == B])
  s <- fA + as.numeric(fB - fA) / 2; e <- lA + as.numeric(lB - lA) / 2
  len <- 365.25 / 6
  tot <- as.numeric(e - s)
  nbin <- max(1, ceiling(tot / len))
  dd <- as.numeric(d$sdate - s)
  keep <- dd >= 0 & dd <= tot
  per <- pmin(floor(dd / len), nbin - 1)
  data.frame(a7k = d$a7k[keep], period = per[keep], stringsAsFactors = FALSE)
}

# ---------------- Property register + payments ----------------
reg <- rd("admin_data/registration_noPII.dta")
cat("reg names:", paste(names(reg), collapse = ", "), "\n")
tp <- rd("admin_data/tax_payments_noPII.dta")
cat("tp names:", paste(names(tp), collapse = ", "), "\n")

idcands <- c("compound1", "compound_code", "compound", "code", "tax_id", "taxid", "id_compound", "property_id", "id")
idc <- NULL
for (c in idcands) if (c %in% names(reg) && c %in% names(tp)) { idc <- c; break }
if (is.null(idc)) {
  common <- setdiff(intersect(names(reg), names(tp)), c("a7", "commune", "stratum", "house", "rate", "status", "exempt", "time"))
  for (c in common) { k <- key(reg[[c]]); if (mean(!duplicated(k[!is.na(k)])) > 0.9) { idc <- c; break } }
}
cat("id column:", ifelse(is.null(idc), "NONE", idc), "\n")

reg$a7k <- key(reg[[pickcol(reg, c("a7"), "^a7")]])
if (!is.null(pickcol(reg, c("pilot")))) reg <- reg[is.na(num(reg$pilot)) | num(reg$pilot) != 1, ]
reg <- reg[reg$a7k %in% nbm$a7k, ]
if (!is.null(idc)) { reg$idk <- key(reg[[idc]]); reg <- reg[!is.na(reg$idk) & !duplicated(reg$idk), ] } else reg$idk <- as.character(seq_len(nrow(reg)))

hc <- pickcol(reg, c("house"), "^house")
reg$house_t <- if (!is.null(hc)) key(reg[[hc]]) else "1"
if (!is.null(hc) && haven::is.labelled(reg[[hc]])) {
  hl <- tolower(as.character(haven::as_factor(reg[[hc]], levels = "labels")))
  reg <- reg[!grepl("villa", hl), ]
}
exc <- pickcol(reg, c("exempt"))
reg$exempt_f <- if (!is.null(exc)) { v <- num(reg[[exc]]); !is.na(v) & v == 1 } else FALSE

amc <- pickcol(tp, c("amount", "amt", "amount_paid", "amt_paid", "paid_amount", "taxes_paid_amt"), "amount|amt")
if (!is.null(idc)) {
  tp$idk <- key(tp[[idc]])
  tp$amt_ <- if (!is.null(amc)) num(tp[[amc]]) else 1
  tpp <- tp[!is.na(tp$idk), ]
  if (!is.null(amc)) tpp <- tpp[!is.na(tpp$amt_) & tpp$amt_ > 0, ]
  pay <- tpp %>% group_by(idk) %>% summarise(rev = sum(amt_, na.rm = TRUE), .groups = "drop")
  reg <- left_join(reg, pay, by = "idk")
  reg$paid <- as.numeric(!is.na(reg$rev))
  reg$rev[is.na(reg$rev)] <- 0
  if (is.null(amc)) reg$rev <- NA
} else {
  pc <- pickcol(reg, c("taxes_paid", "paid"), "paid")
  ac <- pickcol(reg, c("taxes_paid_amt", "amt_paid"), "amt")
  reg$paid <- to_binary(reg[[pc]]); reg$paid[is.na(reg$paid)] <- 0
  reg$rev <- num(reg[[ac]]); reg$rev[is.na(reg$rev)] <- 0
}
reg <- left_join(reg, nbm[, c("a7k", "arm", "strat")], by = "a7k")
cat("properties by arm:\n"); print(table(reg$arm))
cat("payment rate:", mean(reg$paid), " mean rev:", mean(reg$rev), "\n")

coefof <- function(m, v) unname(coef(m)[v])
safe <- function(expr) tryCatch(expr, error = function(e) { message("ERR: ", conditionMessage(e)); NA })

pair_data <- function(dat, A, B, with_period = TRUE) {
  d <- dat[dat$arm %in% c(A, B), ]
  d$treat <- as.integer(d$arm == A)
  if (with_period) { pm <- period_map(A, B); d <- inner_join(d, pm, by = "a7k") }
  d
}

# ---------------- Table 4 ----------------
d1 <- pair_data(reg, "Local", "Central", FALSE)
d2 <- pair_data(reg, "Local", "Central", TRUE)
m1 <- safe(feols(paid ~ treat | strat, data = d1, cluster = ~a7k))
emit("compliance_local_table4_panelA_col1", safe(coefof(m1, "treat")))
emit("n_obs_table4_col1", safe(nobs(m1)))
m2 <- safe(feols(paid ~ treat | strat + period, data = d2, cluster = ~a7k))
emit("compliance_local_table4_panelA_col2", safe(coefof(m2, "treat")))
emit("n_obs_table4_col2", safe(nobs(m2)))
m4 <- safe(feols(paid ~ treat | strat + period + house_t, data = d2, cluster = ~a7k))
emit("compliance_local_house_fe_table4_panelA_col4", safe(coefof(m4, "treat")))
m5 <- safe(feols(paid ~ treat | strat + period + house_t, data = d2[!d2$exempt_f, ], cluster = ~a7k))
emit("compliance_local_exempt_excluded_table4_panelA_col5", safe(coefof(m5, "treat")))
r2 <- safe(feols(rev ~ treat | strat + period, data = d2, cluster = ~a7k))
emit("revenue_local_table4_panelB_col2", safe(coefof(r2, "treat")))
r4 <- safe(feols(rev ~ treat | strat + period + house_t, data = d2, cluster = ~a7k))
emit("revenue_local_house_fe_table4_panelB_col4", safe(coefof(r4, "treat")))

# ---------------- Table 7 ----------------
d7 <- pair_data(reg, "CLI", "Central", TRUE)
c7 <- safe(feols(paid ~ treat | strat + period + house_t, data = d7, cluster = ~a7k))
emit("compliance_cli_table7_col1", safe(coefof(c7, "treat")))
c72 <- safe(feols(rev ~ treat | strat + period + house_t, data = d7, cluster = ~a7k))
emit("revenue_cli_table7_col2", safe(coefof(c72, "treat")))

# ---------------- Table 5: endline bribe ----------------
safe({
  el <- rd("survey_data/endline_round1_noPII.dta")
  cat("endline names (first 80):", paste(head(names(el), 80), collapse = ", "), "\n")
  ac <- pickcol(el, c("a7"), "^a7")
  if (!is.null(ac)) el$a7k <- key(el[[ac]]) else {
    ic <- intersect(idcands, names(el))[1]
    el$idk <- key(el[[ic]]); el <- left_join(el, reg[, c("idk", "a7k")], by = "idk")
  }
  bc <- pickcol(el, c("bribe", "transport", "paid_bribe"), "bribe|transport")
  cat("bribe column:", bc, "\n")
  el$y <- to_binary(el[[bc]])
  el <- left_join(el, nbm[, c("a7k", "arm", "strat")], by = "a7k")
  de <- el[el$arm %in% c("Local", "Central") & !is.na(el$y), ]
  de$treat <- as.integer(de$arm == "Local")
  mb <- feols(y ~ treat | strat, data = de, cluster = ~a7k)
  emit("paid_bribe_endline_local_table5_panelB", coefof(mb, "treat"))
})

# ---------------- Table 6: midline visited ----------------
safe({
  ml <- rd("survey_data/midline_noPII.dta")
  ac <- pickcol(ml, c("a7"), "^a7")
  ic <- if (!is.null(idc) && idc %in% names(ml)) idc else intersect(idcands, names(ml))[1]
  if (!is.na(ic) && !is.null(ic)) ml$idk <- key(ml[[ic]]) else ml$idk <- NA
  if (!is.null(ac)) ml$a7k <- key(ml[[ac]]) else ml <- left_join(ml, reg[, c("idk", "a7k")], by = "idk")
  hm <- pickcol(ml, c("house"), "^house")
  if (!is.null(hm)) ml$house_t <- key(ml[[hm]]) else ml <- left_join(ml, reg[, c("idk", "house_t")], by = "idk")
  ml$y <- to_binary(ml[["visited"]])
  ml <- left_join(ml, nbm[, c("a7k", "arm", "strat")], by = "a7k")
  dm <- pair_data(ml[!is.na(ml$y), ], "Local", "Central", TRUE)
  mv <- feols(y ~ treat | strat + period + house_t, data = dm, cluster = ~a7k)
  emit("visited_by_collector_local_table6_col1", coefof(mv, "treat"))
})

# ---------------- Table 8: ease of payment within CLI ----------------
safe({
  rx <- "ease|facil|abil|capac|able_pay|abp"
  ex <- "willing|volont|wtp"
  ec <- pickcol(reg, character(0), rx, ex)
  dcli <- reg[!is.na(reg$arm) & reg$arm == "CLI", ]
  if (is.null(ec)) {
    cc <- rd("survey_data/chief_consultations.dta")
    cat("consult names:", paste(names(cc), collapse = ", "), "\n")
    ec <- pickcol(cc, character(0), rx, ex)
    ic <- if (!is.null(idc) && idc %in% names(cc)) idc else intersect(idcands, names(cc))[1]
    cc$idk <- key(cc[[ic]])
    cc$ease <- num(cc[[ec]]); cc$ease[!is.na(cc$ease) & cc$ease < 0] <- NA
    cc <- cc[!is.na(cc$idk) & !duplicated(cc$idk), c("idk", "ease")]
    dcli <- left_join(dcli, cc, by = "idk")
  } else {
    dcli$ease <- num(dcli[[ec]]); dcli$ease[!is.na(dcli$ease) & dcli$ease < 0] <- NA
  }
  cat("ease column:", ec, "\n"); print(table(dcli$ease, useNA = "ifany"))
  me <- feols(paid ~ ease | strat + house_t, data = dcli, cluster = ~a7k)
  emit("compliance_ease_of_payment_cli_table8_panelA_col2", coefof(me, "ease"))
})

nms <- c("compliance_local_table4_panelA_col1", "compliance_local_table4_panelA_col2",
         "compliance_local_house_fe_table4_panelA_col4", "compliance_local_exempt_excluded_table4_panelA_col5",
         "revenue_local_table4_panelB_col2", "revenue_local_house_fe_table4_panelB_col4",
         "n_obs_table4_col1", "n_obs_table4_col2", "paid_bribe_endline_local_table5_panelB",
         "visited_by_collector_local_table6_col1", "compliance_cli_table7_col1", "revenue_cli_table7_col2",
         "compliance_ease_of_payment_cli_table8_panelA_col2")
for (n in nms) {
  v <- results[[n]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(v[1], digits = 10)))
}