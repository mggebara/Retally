suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

base_dir <- '<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free'

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) {
    cat(sprintf('RESULT:%s=NA\n', name))
  } else {
    cat(sprintf('RESULT:%s=%.6f\n', name, as.numeric(val)))
  }
}

safe_coef <- function(m, v) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

# lag a variable within id, requiring consecutive years
make_lag <- function(dt, var, id, t, newname) {
  setorderv(dt, c(id, t))
  dt[, (newname) := {
    x <- get(var); yy <- get(t)
    lx <- shift(x, 1L); ly <- shift(yy, 1L)
    lx[is.na(ly) | (yy - ly) != 1] <- NA
    lx
  }, by = id]
  invisible(dt)
}

to_num <- function(x) {
  if (inherits(x, 'haven_labelled')) x <- zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

# =====================================================================
# COUNTRY-LEVEL
# =====================================================================
cl <- as.data.table(read_dta(file.path(base_dir, 'morning_after_dataset_countrylevel.dta')))
cl[] <- lapply(cl, function(x) if (inherits(x, 'haven_labelled')) zap_labels(x) else x)
nm <- names(cl)
n_loaded_cl <- nrow(cl)

idv <- if ('COUNTRY_ID' %in% nm) 'COUNTRY_ID' else 'COUNTRY_DATA'
tv  <- 'YEAR_DATA'
cl[, cid := get(idv)]
cl[, yr := to_num(get(tv))]
# drop exact duplicate country-years if any
cl <- cl[!is.na(cid) & !is.na(yr)]

# --- coup variable ---
coup_cands <- nm[grepl('^coupattem', nm, ignore.case = TRUE) &
                 !grepl('month|_br|type|lag|last', nm, ignore.case = TRUE)]
pref <- c('coupattempt_whogov', 'coupattempt_presentyear', 'coupattempt')
coupv <- intersect(pref, coup_cands)
coupv <- if (length(coupv)) coupv[1] else if (length(coup_cands)) coup_cands[1] else NA
if (is.na(coupv)) {
  # fall back: build from month variable if available
  if ('coupattempt_month_whogov' %in% nm) {
    cl[, coup_fca := as.numeric(!is.na(coupattempt_month_whogov) & coupattempt_month_whogov > 0)]
    cat('DEVIATION: no coup indicator found; built from coupattempt_month_whogov\n')
  }
} else {
  cl[, coup_fca := to_num(get(coupv))]
}
cl[is.na(coup_fca), coup_fca := NA]

# --- lagged BMR democracy ---
ldem_cands <- intersect(c('ldemocracy1', 'democracy1_lag', 'l_democracy1', 'democracy_lag', 'ldemocracy'), nm)
if (length(ldem_cands)) {
  cl[, ldem := to_num(get(ldem_cands[1]))]
} else {
  cl[, dem_tmp := to_num(democracy1)]
  make_lag(cl, 'dem_tmp', 'cid', 'yr', 'ldem')
}

# --- GDP and population (lagged, logged) ---
find_var <- function(patterns, exclude = 'growth') {
  c1 <- nm
  for (p in patterns) c1 <- c1[grepl(p, c1, ignore.case = TRUE)]
  if (!is.null(exclude)) c1 <- c1[!grepl(exclude, c1, ignore.case = TRUE)]
  c1
}
gdp_all <- find_var(c('gdp'))
pop_all <- find_var(c('pop'), exclude = 'oil|valuepop')
pick_lagged <- function(cands) {
  lagged <- cands[grepl('lag|^l', cands, ignore.case = TRUE) & grepl('ln|log', cands, ignore.case = TRUE)]
  if (length(lagged)) return(list(v = lagged[1], lagged = TRUE))
  logged <- cands[grepl('ln|log', cands, ignore.case = TRUE)]
  if (length(logged)) return(list(v = logged[1], lagged = FALSE))
  if (length(cands)) return(list(v = cands[1], lagged = FALSE, raw = TRUE))
  NULL
}
g <- pick_lagged(gdp_all); p <- pick_lagged(pop_all)
prep_ctrl <- function(info, newname) {
  if (is.null(info)) { cl[, (newname) := NA_real_]; return(invisible()) }
  cl[, tmpv := to_num(get(info$v))]
  if (isTRUE(info$raw)) cl[, tmpv := log(tmpv)]
  if (info$lagged) cl[, (newname) := tmpv] else make_lag(cl, 'tmpv', 'cid', 'yr', newname)
  cl[, tmpv := NULL]
}
prep_ctrl(g, 'l_gdp'); prep_ctrl(p, 'l_pop')

# --- regime dummies lagged ---
for (rv in c('military_c', 'monarchy_c', 'party_c')) {
  lname <- paste0('l_', rv)
  lc <- intersect(c(paste0('l', rv), paste0(rv, '_lag'), paste0('lag_', rv)), nm)
  if (length(lc)) {
    cl[, (lname) := to_num(get(lc[1]))]
  } else if (rv %in% nm) {
    cl[, tmpv := to_num(get(rv))]
    make_lag(cl, 'tmpv', 'cid', 'yr', lname)
    cl[, tmpv := NULL]
  } else cl[, (lname) := NA_real_]
}

cl[, dv := to_num(replacement_rateadj_minister)]
cl[, leader_fe := leader_cab_id]

cat(sprintf('SAMPLE:country_level:loaded=%d\n', n_loaded_cl))
cs <- cl[!is.na(ldem) & ldem == 0]
cat(sprintf('SAMPLE:country_level:lagged_bmr_democracy_eq_0=%d\n', nrow(cs)))
cs <- cs[yr >= 1967 & yr <= 2016]
cat(sprintf('SAMPLE:country_level:years_1967_2016=%d\n', nrow(cs)))
cs <- cs[!is.na(dv) & !is.na(coup_fca)]
cat(sprintf('SAMPLE:country_level:nonmissing_dv_coup=%d\n', nrow(cs)))

run_cl <- function(rhs, fe, label) {
  f <- as.formula(paste0('dv ~ ', rhs, ' | ', fe, ' + yr'))
  m <- tryCatch(feols(f, data = cs, cluster = ~cid), error = function(e) { cat('# error ', label, ': ', conditionMessage(e), '\n'); NULL })
  if (!is.null(m)) cat(sprintf('SAMPLE:%s:estimation=%d\n', label, nobs(m)))
  m
}
base_rhs <- 'coup_fca + l_gdp + l_pop'
main_rhs <- 'coup_fca + l_gdp + l_pop + l_military_c + l_monarchy_c + l_party_c'
m_bc <- run_cl(base_rhs, 'cid', 'base_country_fe')
m_mc <- run_cl(main_rhs, 'cid', 'main_country_fe')
m_bl <- run_cl(base_rhs, 'leader_fe', 'base_leader_fe')
m_ml <- run_cl(main_rhs, 'leader_fe', 'main_leader_fe')

# =====================================================================
# INDIVIDUAL-LEVEL
# =====================================================================
il <- as.data.table(readRDS(file.path(base_dir, 'morning_after_dataset_individuallevel.rds')))
inm <- names(il)
n_loaded_il <- nrow(il)

il[, purged := to_num(purged_y1)]
il[, fca := to_num(coupattempt_presentyear)]
il[, yr := to_num(year)]
il[, cid := as.character(country_isocode)]
il[, exper := to_num(experience)]
il[, gdpl := to_num(gdp_cap_pwt_ln_lag)]
il[, popl := to_num(pop_pwt_ln_lag)]
il[, ldem := to_num(democracy_lag)]
il[, exp2 := exper^2]
il[, exp3 := exper^3]

chr <- function(x) as.character(x)

# identify leader rows
is_leader <- rep(FALSE, nrow(il))
for (cc in intersect(c('classification', 'minister_classification', 'importance_factor', 'minister_type'), inm)) {
  v <- chr(il[[cc]])
  hit <- !is.na(v) & grepl('^\\s*leader\\s*$|^the leader$|^leader \\(', v, ignore.case = TRUE)
  if (any(hit)) is_leader <- is_leader | hit
}
if (!any(is_leader) && all(c('name', 'leader') %in% inm) && is.character(il$leader)) {
  is_leader <- !is.na(il$name) & !is.na(il$leader) & chr(il$name) == chr(il$leader)
}
il[, is_leader := is_leader]

# junior / low-ranking identification from importance factor
impcol <- if ('importance_factor' %in% inm) 'importance_factor' else NA
il[, imp := if (!is.na(impcol)) chr(get(impcol)) else NA_character_]
il[, junior_low := !is.na(imp) & grepl('junior|low', imp, ignore.case = TRUE)]
if (!any(il$is_leader) && !is.na(impcol)) {
  il[, is_leader := !is.na(imp) & grepl('^leader', imp, ignore.case = TRUE)]
}

cat(sprintf('SAMPLE:individual:loaded=%d\n', n_loaded_il))
is0 <- il[!is.na(ldem) & ldem == 0]
cat(sprintf('SAMPLE:individual:lagged_bmr_democracy_eq_0=%d\n', nrow(is0)))
is0 <- is0[yr >= 1967 & yr <= 2016]
cat(sprintf('SAMPLE:individual:years_1967_2016=%d\n', nrow(is0)))
is0 <- is0[is_leader == FALSE]
cat(sprintf('SAMPLE:individual:exclude_leader=%d\n', nrow(is0)))
is0 <- is0[!is.na(purged) & !is.na(fca)]
cat(sprintf('SAMPLE:individual:nonmissing_purge_coup=%d\n', nrow(is0)))

add_dummies <- function(dt, fac, ref, prefix) {
  lv <- sort(unique(fac[!is.na(fac)]))
  lv <- setdiff(lv, ref)
  nms <- character(0)
  for (i in seq_along(lv)) {
    dn <- paste0(prefix, '_', i)
    ix <- paste0('fcax_', prefix, '_', i)
    dt[, (dn) := as.numeric(fac == lv[i])]
    dt[, (ix) := fca * get(dn)]
    nms <- c(nms, dn)
  }
  list(levels = lv, dummies = nms, inter = paste0('fcax_', nms))
}

run_il <- function(dt, rhs_terms, label) {
  f <- as.formula(paste0('purged ~ ', paste(rhs_terms, collapse = ' + '), ' | cid + yr'))
  m <- tryCatch(feols(f, data = dt, cluster = ~cid), error = function(e) { cat('# error ', label, ': ', conditionMessage(e), '\n'); NULL })
  if (!is.null(m)) cat(sprintf('SAMPLE:%s:estimation=%d\n', label, nobs(m)))
  m
}

# ---- H2a: Experience ----
dE <- copy(is0[junior_low == FALSE])
cat(sprintf('SAMPLE:h2a_experience:loaded=%d\n', n_loaded_il))
cat(sprintf('SAMPLE:h2a_experience:exclude_leader_junior_lowranking=%d\n', nrow(dE)))
dE[, egrp := fifelse(is.na(exper), NA_character_,
              fifelse(exper < 2, 'a_lt2',
              fifelse(exper <= 3, 'b_2to3',
              fifelse(exper <= 6, 'c_4to6', 'd_gt6'))))]
dE <- dE[!is.na(egrp)]
eD <- add_dummies(dE, dE$egrp, 'a_lt2', 'eg')
m_exp <- run_il(dE, c('fca', eD$dummies, eD$inter, 'gdpl', 'popl'), 'h2a_experience')
gt6_ix <- eD$inter[which(eD$levels == 'd_gt6')]

# ---- H2b: Affiliation ----
dA <- copy(is0)
pg <- chr(dA$party_group)
ref_other <- unique(pg[!is.na(pg) & grepl('other', pg, ignore.case = TRUE)])
lead_lv <- unique(pg[!is.na(pg) & grepl('leader', pg, ignore.case = TRUE) & !grepl('other|not', pg, ignore.case = TRUE)])
m_aff <- NULL; lead_ix <- NA
if (length(ref_other)) {
  dA[, pgrp := pg]
  dA <- dA[!is.na(pgrp)]
  aD <- add_dummies(dA, dA$pgrp, ref_other[1], 'pg')
  cat(sprintf('SAMPLE:h2b_affiliation:loaded=%d\n', n_loaded_il))
  cat(sprintf('SAMPLE:h2b_affiliation:exclude_leader_nonmissing_party=%d\n', nrow(dA)))
  m_aff <- run_il(dA, c('fca', aD$dummies, aD$inter, 'exper', 'exp2', 'exp3', 'gdpl', 'popl'), 'h2b_affiliation')
  if (length(lead_lv)) lead_ix <- aD$inter[which(aD$levels == lead_lv[1])]
} else cat('DEVIATION: could not identify "other party" reference level in party_group\n')

# ---- H3a: Responsibility (portfolio) ----
port_col <- NA
for (cc in intersect(c('minister_type', 'portfolio_1', 'minister_classification', 'Group', 'classification'), inm)) {
  v <- chr(il[[cc]])
  if (any(grepl('defen', v, ignore.case = TRUE)) && any(grepl('natural', v, ignore.case = TRUE)) &&
      length(unique(v)) <= 15) { port_col <- cc; break }
}
m_resp <- NULL; nr_ix <- NA
if (!is.na(port_col)) {
  dR <- copy(is0)
  dR[, ptype := chr(get(port_col))]
  dR <- dR[!is.na(ptype)]
  ref_def <- unique(dR$ptype[grepl('defen', dR$ptype, ignore.case = TRUE)])[1]
  rD <- add_dummies(dR, dR$ptype, ref_def, 'pt')
  cat(sprintf('SAMPLE:h3a_responsibility:loaded=%d\n', n_loaded_il))
  cat(sprintf('SAMPLE:h3a_responsibility:exclude_leader_nonmissing_portfolio=%d\n', nrow(dR)))
  m_resp <- run_il(dR, c('fca', rD$dummies, rD$inter, 'exper', 'exp2', 'exp3', 'gdpl', 'popl'), 'h3a_responsibility')
  nr_lv <- rD$levels[grepl('natural', rD$levels, ignore.case = TRUE)]
  if (length(nr_lv)) nr_ix <- rD$inter[which(rD$levels == nr_lv[1])]
} else cat('DEVIATION: could not identify portfolio-type column with Defense / Natural Resources levels\n')

# ---- H3b: Importance ----
m_imp <- NULL
if (!is.na(impcol)) {
  dI <- copy(is0[!is.na(imp)])
  dI <- dI[!grepl('^leader', imp, ignore.case = TRUE)]
  lv <- unique(dI$imp)
  ref_pm <- lv[grepl('prime|president|pm', lv, ignore.case = TRUE) & !grepl('vice|deputy|vp', lv, ignore.case = TRUE)]
  if (!length(ref_pm)) ref_pm <- sort(lv)[1]
  iD <- add_dummies(dI, dI$imp, ref_pm[1], 'im')
  cat(sprintf('SAMPLE:h3b_importance:loaded=%d\n', n_loaded_il))
  cat(sprintf('SAMPLE:h3b_importance:exclude_leader=%d\n', nrow(dI)))
  m_imp <- run_il(dI, c('fca', iD$dummies, iD$inter, 'exper', 'exp2', 'exp3', 'gdpl', 'popl'), 'h3b_importance')
} else cat('DEVIATION: importance_factor not available\n')

# =====================================================================
# RESULTS
# =====================================================================
emit('failed_coup_base_country_fe', safe_coef(m_bc, 'coup_fca'))
emit('failed_coup_main_country_fe', safe_coef(m_mc, 'coup_fca'))
emit('failed_coup_base_leader_fe', safe_coef(m_bl, 'coup_fca'))
emit('failed_coup_main_leader_fe', safe_coef(m_ml, 'coup_fca'))
emit('failed_coup_experience_model', safe_coef(m_exp, 'fca'))
emit('failed_coup_x_over_6_years_experience', if (length(gt6_ix)) safe_coef(m_exp, gt6_ix) else NA)
emit('failed_coup_affiliation_model', safe_coef(m_aff, 'fca'))
emit('failed_coup_x_leaders_party', if (!is.na(lead_ix)) safe_coef(m_aff, lead_ix) else NA)
emit('failed_coup_responsibility_model', safe_coef(m_resp, 'fca'))
emit('failed_coup_x_natural_resources', if (!is.na(nr_ix)) safe_coef(m_resp, nr_ix) else NA)
emit('failed_coup_importance_model', safe_coef(m_imp, 'fca'))
