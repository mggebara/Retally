suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns.script-free"
raw <- read_dta(file.path(base_dir, "ICPSR_183165-V1.1", "konda_data_for_analysis.dta"))
raw <- as.data.frame(raw)

num <- function(v) suppressWarnings(as.numeric(zap_labels(v)))

# ---- running variable ----
yr <- num(raw$year)
if (all(yr[!is.na(yr)] < 100)) yr <- yr + 1900
mo <- num(raw$month)
mob <- yr * 12 + mo                        # month-year of birth index
cut_mid <- 1955 * 12 + 12.5                # between Dec 1955 and Jan 1956
r <- cut_mid - mob                         # months older than threshold (+ = older)
treat <- as.numeric(r > 0)                 # born in or before Dec 1955

d <- data.frame(
  mob = mob, r = r, treat = treat,
  bmonth = mo,
  surveyor = if ("survey_taker_id" %in% names(raw)) num(raw$survey_taker_id) else NA,
  edu = if ("education" %in% names(raw)) num(raw$education) else NA,
  female = num(raw$female),
  stringsAsFactors = FALSE
)
if ("non_turk" %in% names(raw)) {
  d$non_turk <- num(raw$non_turk)
} else if ("ethnicity" %in% names(raw)) {
  e <- num(raw$ethnicity)
  tab <- sort(table(e), decreasing = TRUE)
  d$non_turk <- ifelse(is.na(e), NA, as.numeric(e != as.numeric(names(tab)[1])))
} else {
  d$non_turk <- 0
}

# ---- province variable ----
nms <- names(raw)
prov_cands <- nms[grepl("province|^il$|^il_|_il$|city|sehir|şehir|region|bolge", tolower(nms))]
prov_cands <- prov_cands[!grepl("survey|taker", tolower(prov_cands))]
pref <- prov_cands[grepl("province", tolower(prov_cands))]
if (length(pref) > 0) prov_cands <- c(pref, setdiff(prov_cands, pref))
if (length(prov_cands) > 0) {
  d$province <- num(raw[[prov_cands[1]]])
  if (all(is.na(d$province))) d$province <- as.numeric(factor(as.character(raw[[prov_cands[1]]])))
  has_prov <- TRUE
} else {
  has_prov <- FALSE
}
has_surv <- !all(is.na(d$surveyor))

# ---- outcomes: mobility ----
d$outside_week <- num(raw$outside_week)
d$under_curfew <- num(raw$under_curfew)
d$never_out <- num(raw$never_out)

# ---- SRQ-20 items ----
yesno <- function(v) {
  labs <- attr(v, "labels")
  x <- suppressWarnings(as.numeric(zap_labels(v)))
  if (!is.null(labs) && length(labs) > 0) {
  ln <- tolower(names(labs))
    yc <- labs[grepl("^(yes|evet)", ln)]
    nc <- labs[grepl("^(no|hay)", ln) & !grepl("^(no answer|no idea|not)", ln)]
    if (length(yc) == 1 && length(nc) == 1) {
      return(ifelse(x == as.numeric(yc), 1, ifelse(x == as.numeric(nc), 0, NA)))
    }
  }
  u <- unique(x[!is.na(x)])
  if (all(u %in% c(0, 1))) return(x)
  if (all(c(1, 2) %in% u) || all(u %in% c(1, 2))) return(ifelse(x == 1, 1, ifelse(x == 2, 0, NA)))
  if (0 %in% u && 1 %in% u) return(ifelse(x %in% c(0, 1), x, NA))
  x
}

blacklist <- "index|sum|total|count|_std|srq|_z$|overall|health"
item_pats <- list(
  headache    = "headache|head_ache|^head",
  shaking     = "shak|tremb",
  indigestion = "indigest|digest",
  stomach     = "stomach",
  appetite    = "appetite",
  sleep       = "sleep|insomn",
  frighten    = "fright|scare|afraid|fear",
  nervous     = "nervous|worri|tense",
  thinking    = "think",
  unhappy     = "unhappy|^sad",
  cry         = "cry",
  enjoy       = "enjoy|pleasure",
  decision    = "decis",
  work        = "suffer|daily_work|dailywork|work_suf",
  useful      = "useful|useless|play_|role",
  uninterest  = "uninterest|interest",
  worthless   = "worthless",
  suicide     = "suicid|end_life|kill",
  tired_easy  = "tired_eas|easily_tired|eas.*tired|tired.*eas|tired_quick",
  tired_all   = "tired|fatigu|exhaust"
)
cand <- nms[!grepl(blacklist, tolower(nms))]
assigned <- character(0)
item_map <- list()
for (it in names(item_pats)) {
  m <- cand[grepl(item_pats[[it]], tolower(cand)) & !(cand %in% assigned)]
  if (length(m) > 0) {
    # prefer variables that look binary
    ok <- sapply(m, function(v) length(unique(na.omit(yesno(raw[[v]])))) <= 3)
    m <- m[ok]
  }
  if (length(m) > 0) {
    item_map[[it]] <- m[1]
    assigned <- c(assigned, m[1])
  }
}
somatic_names <- c("headache", "shaking", "indigestion", "stomach")
items_all <- names(item_map)
items_som <- intersect(items_all, somatic_names)
items_non <- setdiff(items_all, somatic_names)

for (it in items_all) d[[paste0("srq_", it)]] <- yesno(raw[[item_map[[it]]]])
cols_all <- paste0("srq_", items_all)
cols_som <- paste0("srq_", items_som)
cols_non <- paste0("srq_", items_non)

# diagnostics on item mapping
for (it in items_all) {
  cat(sprintf("DIAG: item %s -> %s (missing=%d)\n", it, item_map[[it]],
              sum(is.na(d[[paste0("srq_", it)]]))))
}

complete_srq <- complete.cases(d[, cols_all, drop = FALSE])
ctrl <- d$treat == 0 & !is.na(d$treat)

# Anderson (2008) index: item z-scores standardized on the control group,
# averaged over the items each respondent answered, then re-standardized.
anderson <- function(cols, keep) {
  zs <- sapply(cols, function(cc) {
    x <- d[[cc]]
    mu <- mean(x[ctrl & keep], na.rm = TRUE)
    s <- sd(x[ctrl & keep], na.rm = TRUE)
    if (is.na(s) || s == 0) s <- 1
    (x - mu) / s
  })
  zs <- as.matrix(zs)
  idx <- rowMeans(zs, na.rm = TRUE)
  idx[rowSums(!is.na(zs)) == 0 | !keep] <- NA
  mu <- mean(idx[ctrl], na.rm = TRUE)
  s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - mu) / s
}

# ---- sample for the mental-health indices ----
# Prefer the sample of the authors' own constructed mental distress index if
# it is present in the analysis file; otherwise require that a respondent
# answered a majority (>= 75%) of the SRQ items.
idx_cands <- nms[grepl("distress|mdi|mental", tolower(nms)) &
                 !grepl("somatic|nonsom|support|psych_sup", tolower(nms))]
idx_cands <- idx_cands[sapply(idx_cands, function(v) {
  x <- num(raw[[v]]); length(unique(na.omit(x))) > 5
})]
n_answered <- rowSums(!is.na(d[, cols_all, drop = FALSE]))
if (length(idx_cands) > 0) {
  keep_mh <- !is.na(num(raw[[idx_cands[1]]]))
  cat(sprintf("DEVIATION: Mental-health index sample defined by non-missingness of the dataset's own index variable '%s'\n", idx_cands[1]))
} else {
  keep_mh <- n_answered >= ceiling(0.75 * length(cols_all))
  cat('DEVIATION: Anderson indices average z-scores over answered SRQ items, restricted to respondents answering at least 75% of the items (paper does not state its missing-item rule)\n')
}

d$mdi <- anderson(cols_all, keep_mh)
d$som_idx <- if (length(cols_som) > 0) anderson(cols_som, keep_mh) else NA
d$non_idx <- if (length(cols_non) > 0) anderson(cols_non, keep_mh) else NA
d$srq_sum <- rowSums(d[, cols_all, drop = FALSE])
d$srq_sum[!complete_srq] <- NA

# ---- estimation ----
h <- 45
sub <- d[!is.na(d$r) & abs(d$r) < h, ]

fe_terms <- c("bmonth", if (has_prov) "province", if (has_surv) "surveyor", "edu")
fe_str <- paste(fe_terms, collapse = " + ")

run_rd <- function(y) {
  f <- as.formula(paste0(y, " ~ treat + r + treat:r + female + non_turk | ", fe_str))
  m <- tryCatch(feols(f, data = sub, cluster = ~mob),
                error = function(e) feols(as.formula(paste0(y, " ~ treat + r + treat:r + female + non_turk | bmonth + edu")),
                                          data = sub, cluster = ~mob))
  m
}

m_out <- run_rd("outside_week")
m_cur <- run_rd("under_curfew")
m_nev <- run_rd("never_out")
m_mdi <- run_rd("mdi")
m_som <- run_rd("som_idx")
m_non <- run_rd("non_idx")
m_sum <- run_rd("srq_sum")

cf <- function(m) unname(coef(m)["treat"])

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", cf(m_out)))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", cf(m_cur)))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", cf(m_nev)))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", as.integer(nobs(m_out))))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", as.integer(nobs(m_cur))))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", cf(m_mdi)))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", cf(m_som)))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", cf(m_non)))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", cf(m_sum)))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", as.integer(nobs(m_mdi))))