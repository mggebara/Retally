suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

msg <- function(...) message(paste0(...))
pick <- function(nms, patterns, exclude = character(0)) {
  for (p in patterns) {
    hits <- grep(p, nms, value = TRUE, ignore.case = TRUE)
    if (length(exclude)) hits <- setdiff(hits, exclude)
    if (length(hits)) return(hits[1])
  }
  NA_character_
}
num <- function(x) as.numeric(haven::zap_labels(x))
out <- list()

########################## Survey: Table 1 ##########################
sv <- tryCatch(read_dta(file.path(base, "survey.dta")), error = function(e) NULL)
if (!is.null(sv)) {
  snm <- names(sv)
  msg("Survey columns: ", paste(snm, collapse = ", "))
  sv$wave_n <- num(sv$wave)
  s4 <- sv[!is.na(sv$wave_n) & sv$wave_n == max(4, 0), ]
  if (nrow(s4) == 0) s4 <- sv[!is.na(sv$MateComp.cont), ]
  msg("Wave 4 rows: ", nrow(s4))

  y   <- pick(snm, c("^hate_violence_means$", "violence_means", "only_means"))
  mc  <- pick(snm, c("^MateComp.cont$", "matecomp"))
  jc  <- pick(snm, c("^JobComp.cont$", "jobcomp"))
  ls  <- pick(snm, c("^LifeSatis.cont$", "lifesat"))

  d <- data.frame(y = num(s4[[y]]), mate = num(s4[[mc]]), job = num(s4[[jc]]), life = num(s4[[ls]]))

  # sociodemographics
  socio_num_pats <- list(
    age = c("^age$", "^age_group$"),
    gender = c("^gender$", "^sex$"),
    educ = c("^eduyrs$", "educ"),
    income = c("^income$"),
    citizen = c("^citizenship$"),
    hh = c("^household_size$", "hhsize"),
    status = c("social_status", "soc_status", "^status", "self_status", "^self_econ$")
  )
  socio_fac_pats <- list(
    activity = c("^occ", "activ", "^oc"),
    employ = c("employ", "^empl", "work"),
    religion = c("^religion$", "relig"),
    state = c("^state$", "bundesland")
  )
  used <- c(y, mc, jc, ls)
  socio_terms <- c()
  for (k in names(socio_num_pats)) {
    v <- pick(snm, socio_num_pats[[k]], exclude = used)
    if (!is.na(v)) { d[[k]] <- num(s4[[v]]); socio_terms <- c(socio_terms, k); used <- c(used, v); msg("socio ", k, " -> ", v) }
  }
  for (k in names(socio_fac_pats)) {
    v <- pick(snm, socio_fac_pats[[k]], exclude = used)
    if (!is.na(v)) { d[[k]] <- factor(num(s4[[v]])); socio_terms <- c(socio_terms, k); used <- c(used, v); msg("socio(factor) ", k, " -> ", v) }
  }

  # national refugee attitudes (ref_* not local, not ref_ind) and local (ref_loc_*)
  nat_v <- grep("^ref_", snm, value = TRUE)
  nat_v <- nat_v[!grepl("loc", nat_v, ignore.case = TRUE)]
  loc_v <- grep("^ref_loc|^loc_", snm, value = TRUE)
  nat_v <- setdiff(nat_v, used); used <- c(used, nat_v)
  loc_v <- setdiff(loc_v, used); used <- c(used, loc_v)
  msg("national: ", paste(nat_v, collapse = ", "))
  msg("local: ", paste(loc_v, collapse = ", "))
  nat_t <- c(); for (v in nat_v) { nm <- paste0("n_", make.names(v)); d[[nm]] <- num(s4[[v]]); nat_t <- c(nat_t, nm) }
  loc_t <- c(); for (v in loc_v) { nm <- paste0("l_", make.names(v)); d[[nm]] <- num(s4[[v]]); loc_t <- c(loc_t, nm) }

  # additional controls col 6
  add_v <- c()
  for (p in c("^contact", "shelter|dist_|close", "^refugee_ind$|num_ref|refugees_town", "afd", "^lrscale$|leftright", "^muslim")) {
    hits <- setdiff(grep(p, snm, value = TRUE, ignore.case = TRUE), c(used, add_v))
    hits <- hits[!grepl("gendergap|^hate|list", hits)]
    add_v <- c(add_v, hits)
  }
  used <- c(used, add_v)
  msg("additional: ", paste(add_v, collapse = ", "))
  add_t <- c(); for (v in add_v) { nm <- paste0("a_", make.names(v)); d[[nm]] <- num(s4[[v]]); add_t <- c(add_t, nm) }

  f <- function(terms) as.formula(paste("y ~", paste(terms, collapse = " + ")))
  base_ok <- complete.cases(d[, c("y", "mate", "job", "life")])
  d12 <- d[base_ok, ]
  m1 <- lm(y ~ mate, data = d12)
  m2 <- lm(y ~ mate + job + life, data = d12)
  t3 <- c("mate", "job", "life", socio_terms)
  ok3 <- complete.cases(d[, c("y", t3), drop = FALSE])
  d3 <- d[ok3, ]
  m3 <- lm(f(t3), data = d3)
  t4 <- c(t3, nat_t); m4 <- lm(f(t4), data = d3)
  t5 <- c(t4, loc_t); m5 <- lm(f(t5), data = d3)
  t6 <- c(t5, add_t); m6 <- lm(f(t6), data = d3)
  msg("N col4-6: ", nobs(m4), " ", nobs(m5), " ", nobs(m6))

  out$mate_competition_table1_col1 <- coef(m1)["mate"]
  out$mate_competition_table1_col2 <- coef(m2)["mate"]
  out$mate_competition_table1_col3 <- coef(m3)["mate"]
  out$mate_competition_table1_col4 <- coef(m4)["mate"]
  out$mate_competition_table1_col5 <- coef(m5)["mate"]
  out$mate_competition_table1_col6 <- coef(m6)["mate"]
  out$job_competition_table1_col2 <- coef(m2)["job"]
  out$n_obs_table1_col1 <- nobs(m1)
  out$n_obs_table1_col3 <- nobs(m3)
}

########################## Ecological: Table C1 ##########################
cx <- tryCatch(read_dta(file.path(base, "context.dta")), error = function(e) NULL)
if (!is.null(cx)) {
  cnm <- names(cx)
  msg("Context columns: ", paste(cnm, collapse = ", "))
  for (v in cnm) if (!is.character(cx[[v]])) cx[[v]] <- num(cx[[v]])

  id   <- pick(cnm, c("^ags_muni$", "^ags$", "ags_gem", "gemeinde", "^ags_mun", "muni_id", "^id$"))
  em   <- pick(cnm, c("^pop_15_44_muni_gendergap_2015$", "15_44.*gendergap", "gendergap.*15_44", "excess"))
  hate <- pick(cnm, c("^Hate_all_muni$", "^hate_all", "hate"))
  msg("id=", id, " em=", em, " hate=", hate)
  if (is.na(id)) {
    cx$muni_tmp_id <- as.integer(factor(paste(cx$ags_county, cx$population_muni_2015, cx$vote_afd_2013_muni)))
    id <- "muni_tmp_id"
  }
  cx$id <- cx[[id]]; cx$em <- cx[[em]]; cx$hate <- cx[[hate]]
  cx <- cx[cx$year %in% 2015:2017, ]

  ctrl <- list()
  popv <- pick(cnm, c("^log_pop", "^population_muni_2015$", "^population_muni", "^pop"))
  if (!is.na(popv)) {
    if (grepl("^log", popv)) cx$c_pop <- cx[[popv]] else cx$c_pop <- log(pmax(cx[[popv]], 1))
    ctrl$c_pop <- popv
  }
  addc <- function(name, pats, exclude = character(0)) {
    v <- pick(cnm, pats, exclude = c(exclude, unlist(ctrl), id, em, hate))
    if (!is.na(v)) { cx[[name]] <<- cx[[v]]; ctrl[[name]] <<- v }
  }
  addc("c_dens", c("dens"))
  addc("c_popch", c("pop.*(change|growth|ch_|_ch|diff)", "(change|growth|^d_|^ch_).*pop"))
  addc("c_unemp", c("^log_unemp_all_muni_2015$", "unemp_all"))
  addc("c_unempratio", c("^unemp_gendergap_2015$", "unemp_gendergap"))
  addc("c_refstock", c("ref_stock", "refugee", "^log_ref", "ref"),
       exclude = grep("inflow|pc_ref_male", cnm, value = TRUE))
  addc("c_refflow", c("ref_inflow", "inflow"))
  addc("c_educ", c("educ", "high_degree", "highly", "abitur"))
  addc("c_manuf", c("^pc_manufacturing_2015$", "^pc_manuf"))
  addc("c_dmanuf", c("^d_manuf"))
  addc("c_afd", c("afd"))
  addc("c_viol", c("violence", "crime"))
  msg("Controls: ", paste(names(ctrl), unlist(ctrl), sep = "=", collapse = "; "))
  left <- setdiff(cnm, c(unlist(ctrl), id, em, hate))
  msg("Unused context columns: ", paste(left, collapse = ", "))
  ctrl_t <- names(ctrl)

  # municipality cross-section
  muni <- cx %>% group_by(id) %>%
    summarise(hate_sum = if (all(is.na(hate))) NA_real_ else sum(hate, na.rm = TRUE),
              across(all_of(c("em", ctrl_t, "ags_county", "ags_state")), ~ first(na.omit(.x))[1]),
              .groups = "drop")
  muni$y_sum <- as.integer(muni$hate_sum > 0)
  q <- quantile(muni$em, c(0.025, 0.975), na.rm = TRUE)
  keep_ids <- muni$id[!is.na(muni$em) & muni$em >= q[1] & muni$em <= q[2]]
  ms <- muni[muni$id %in% keep_ids, ]
  msg("Munis total: ", nrow(muni), "; after trimming: ", nrow(ms))

  fs <- as.formula(paste("y_sum ~ em +", paste(ctrl_t, collapse = " + "), "| ags_state"))
  m_sum <- feglm(fs, data = ms, family = binomial("logit"), cluster = ~ags_county)
  print(summary(m_sum))

  pa <- cx[cx$id %in% keep_ids, ]
  pa$y_ann <- as.integer(pa$hate > 0)
  fa <- as.formula(paste("y_ann ~ em +", paste(ctrl_t, collapse = " + "), "| ags_state + year"))
  m_ann <- feglm(fa, data = pa, family = binomial("logit"), cluster = ~ags_county)
  print(summary(m_ann))

  # informational: county FE variants
  try({
    fsc <- as.formula(paste("y_sum ~ em +", paste(ctrl_t, collapse = " + "), "| ags_county"))
    mc_ <- feglm(fsc, data = ms, family = binomial("logit"), cluster = ~ags_county)
    msg("County-FE sum: coef=", coef(mc_)["em"], " N=", nobs(mc_))
  }, silent = TRUE)

  out$excess_males_sum_tableC1_col5 <- coef(m_sum)["em"]
  out$excess_males_annual_tableC1_col6 <- coef(m_ann)["em"]
  out$n_obs_sum_tableC1_col5 <- nobs(m_sum)
  out$n_obs_annual_tableC1_col6 <- nobs(m_ann)
}

nms <- c("mate_competition_table1_col1", "mate_competition_table1_col2", "mate_competition_table1_col3",
         "mate_competition_table1_col4", "mate_competition_table1_col5", "mate_competition_table1_col6",
         "job_competition_table1_col2", "n_obs_table1_col1", "n_obs_table1_col3",
         "excess_males_sum_tableC1_col5", "excess_males_annual_tableC1_col6",
         "n_obs_sum_tableC1_col5", "n_obs_annual_tableC1_col6")
for (n in nms) {
  v <- if (!is.null(out[[n]])) as.numeric(out[[n]]) else NA_real_
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 8)))
}