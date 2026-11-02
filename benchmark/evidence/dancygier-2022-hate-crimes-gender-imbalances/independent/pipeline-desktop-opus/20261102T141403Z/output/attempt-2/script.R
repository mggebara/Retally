suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}

findvar <- function(nms, patterns, exclude = character(0)) {
  for (p in patterns) {
    hit <- grep(p, nms, value = TRUE, ignore.case = TRUE)
    if (length(exclude)) hit <- hit[!hit %in% exclude]
    if (length(hit)) return(hit[1])
  }
  NA_character_
}

num <- function(x) as.numeric(zap_labels(x))

# ===================== Survey: Table 1 =====================
res_survey <- tryCatch({
  sv <- read_dta(file.path(base, "survey.dta"))
  nms <- names(sv)
  message("Survey columns: ", paste(nms, collapse = ", "))
  sv <- sv[num(sv$wave) == max(num(sv$wave), na.rm = TRUE), ]
  if ("wave" %in% nms && any(num(sv$wave) == 4)) sv <- sv[num(sv$wave) == 4, ]

  d <- data.frame(y = num(sv$hate_violence_means),
                  mate = num(sv[["MateComp.cont"]]),
                  job = num(sv[["JobComp.cont"]]),
                  life = num(sv[["LifeSatis.cont"]]))

  # Sociodemographics
  cat_vars <- c(); num_vars <- c()
  addnum <- function(v) if (!is.na(v) && v %in% nms) { d[[v]] <<- num(sv[[v]]); num_vars <<- c(num_vars, v) }
  addcat <- function(v) if (!is.na(v) && v %in% nms) { x <- as_factor(sv[[v]]); x <- droplevels(factor(x)); d[[v]] <<- x; cat_vars <<- c(cat_vars, v) }

  addnum(findvar(nms, c("^age$")))
  addcat(findvar(nms, c("^gender$")))
  edu <- findvar(nms, c("^eduyrs$", "^educ", "^edu"))
  addnum(edu)
  addnum(findvar(nms, c("^income$")))
  addcat(findvar(nms, c("^occup", "^oc", "econ_act", "activity")))
  addcat(findvar(nms, c("^employ", "^emp_stat", "^empl")))
  addcat(findvar(nms, c("^citizenship$")))
  addnum(findvar(nms, c("^household_size$")))
  addnum(findvar(nms, c("^self_econ$", "status")))
  addcat(findvar(nms, c("^religion$")))
  addcat(findvar(nms, c("^state$")))
  socio <- c(num_vars, cat_vars)

  # National attitudes toward refugees: ref_* but not ref_loc_*
  nat <- grep("^ref_", nms, value = TRUE)
  nat <- nat[!grepl("^ref_loc", nat)]
  loc <- grep("^ref_loc", nms, value = TRUE)
  for (v in c(nat, loc)) d[[v]] <- num(sv[[v]])

  # Additional controls
  add <- unique(c(grep("contact", nms, value = TRUE),
                  grep("close|shelter|dist", nms, value = TRUE, ignore.case = TRUE),
                  grep("refugee_ind|num_ref|ref_num|estim", nms, value = TRUE, ignore.case = TRUE),
                  grep("afd", nms, value = TRUE, ignore.case = TRUE),
                  grep("lrscale", nms, value = TRUE),
                  grep("muslim", nms, value = TRUE)))
  add <- setdiff(add, c(socio, nat, loc, "y", "pop_15_44_muni_gendergap_2015"))
  for (v in add) d[[v]] <- num(sv[[v]])

  bt <- function(v) paste0("`", v, "`")
  f <- function(rhs) as.formula(paste("y ~", paste(bt(rhs), collapse = " + ")))

  d12 <- d[complete.cases(d[, c("y", "mate", "job", "life")]), ]
  m1 <- lm(y ~ mate, data = d12)
  m2 <- lm(y ~ mate + job + life, data = d12)

  d3 <- d[complete.cases(d[, c("y", "mate", "job", "life", socio)]), ]
  m3 <- lm(f(c("mate", "job", "life", socio)), data = d3)
  # Columns 4-6: keep sample of col 3; mean-impute missing attitude items with missing indicators
  imp <- function(dd, vars) {
    for (v in vars) {
      if (any(is.na(dd[[v]]))) {
        dd[[paste0(v, "_miss")]] <- as.numeric(is.na(dd[[v]]))
        dd[[v]][is.na(dd[[v]])] <- mean(dd[[v]], na.rm = TRUE)
      }
    }
    dd
  }
  d4 <- imp(d3, c(nat, loc, add))
  missv <- grep("_miss$", names(d4), value = TRUE)
  mv <- function(vars) intersect(paste0(vars, "_miss"), missv)
  m4 <- lm(f(c("mate", "job", "life", socio, nat, mv(nat))), data = d4)
  m5 <- lm(f(c("mate", "job", "life", socio, nat, loc, mv(c(nat, loc)))), data = d4)
  m6 <- lm(f(c("mate", "job", "life", socio, nat, loc, add, mv(c(nat, loc, add)))), data = d4)

  list(c1 = coef(m1)["mate"], c2 = coef(m2)["mate"], c3 = coef(m3)["mate"],
       c4 = coef(m4)["mate"], c5 = coef(m5)["mate"], c6 = coef(m6)["mate"],
       j2 = coef(m2)["job"], n1 = nobs(m1), n3 = nobs(m3))
}, error = function(e) { message("Survey error: ", conditionMessage(e)); NULL })

# ===================== Ecological: SI Table C1 =====================
res_eco <- tryCatch({
  cx <- read_dta(file.path(base, "context.dta"))
  nms <- names(cx)
  message("Context columns: ", paste(nms, collapse = ", "))
  cx <- as.data.frame(lapply(cx, function(x) if (is.character(x)) x else num(x)), stringsAsFactors = FALSE)

  idv <- findvar(nms, c("^ags_muni$", "^ags$", "ags_gem", "^muni", "gemeinde", "^id"))
  em <- findvar(nms, c("pop_15_44_muni_gendergap_2015", "15_44.*gendergap", "gendergap.*15_44", "excess"))
  hate <- findvar(nms, c("^Hate_all_muni$", "^hate_all", "^hate"))
  message("id=", idv, " em=", em, " hate=", hate)

  ctrl_pats <- list(
    pop = c("^log_pop.*muni", "population_muni_2015", "^population"),
    dens = c("dens"),
    popch = c("pop.*ch", "d_pop", "ch.*pop", "popgrowth", "pop_change"),
    unemp = c("unemp_all_muni", "log_unemp_all", "unemp_all"),
    gap = c("^unemp_gendergap_2015$", "unemp_gendergap"),
    refstock = c("log_ref_stock", "ref_stock", "log_ref_20", "^log_ref(?!_inflow)", "refugees"),
    refflow = c("log_ref_inflow", "inflow", "ref_flow"),
    educ = c("high_degree", "educ", "high_edu"),
    manuf = c("^pc_manufacturing_2015$", "pc_manuf"),
    dmanuf = c("^d_manuf", "ch.*manuf"),
    afd = c("vote_afd_2013_muni", "afd"),
    viol = c("violence_percap", "viol", "crime")
  )
  ctrls <- c()
  for (k in names(ctrl_pats)) {
    v <- NA_character_
    for (p in ctrl_pats[[k]]) {
      hit <- grep(p, nms, value = TRUE, ignore.case = TRUE, perl = TRUE)
      hit <- setdiff(hit, c(ctrls, em, hate, idv, "year", "east", "ags_county", "ags_state"))
      if (length(hit)) { v <- hit[1]; break }
    }
    if (!is.na(v)) ctrls <- c(ctrls, v)
  }
  ctrls <- unique(ctrls)
  message("Controls: ", paste(ctrls, collapse = ", "))

  cx$em <- cx[[em]]
  cx$hate_ind <- as.numeric(cx[[hate]] > 0)
  if (is.na(idv)) stop("no muni id")
  cx$id <- cx[[idv]]

  # Trim extreme Excess Males (2.5/97.5 percentiles), at municipality level
  mu <- cx %>% group_by(id) %>% summarise(em = first(em[!is.na(em)]), .groups = "drop")
  q <- quantile(mu$em, c(0.025, 0.975), na.rm = TRUE)
  keep <- mu$id[!is.na(mu$em) & mu$em >= q[1] & mu$em <= q[2]]
  cx <- cx[cx$id %in% keep, ]
  cx <- cx[cx$year %in% 2015:2017, ]

  rhs <- paste(c("em", paste0("`", ctrls, "`")), collapse = " + ")

  # Annual
  ann <- cx[complete.cases(cx[, c("hate_ind", "em", ctrls, "ags_state", "ags_county", "year")]), ]
  ma <- feglm(as.formula(paste("hate_ind ~", rhs, "| ags_county + year")),
              data = ann, family = binomial(), cluster = ~ags_county)

  # Sum: municipality-level, any hate crime 2015-2017; time-invariant controls from 2015 row
  anyh <- cx %>% group_by(id) %>% summarise(hate_sum = as.numeric(any(hate_ind == 1, na.rm = TRUE)), .groups = "drop")
  s15 <- cx[cx$year == 2015, ]
  s15 <- merge(s15[, setdiff(names(s15), "hate_sum")], anyh, by = "id")
  s15 <- s15[complete.cases(s15[, c("hate_sum", "em", ctrls, "ags_state", "ags_county")]), ]
  ms <- feglm(as.formula(paste("hate_sum ~", rhs, "| ags_county")),
              data = s15, family = binomial(), cluster = ~ags_county)

  list(bs = coef(ms)["em"], ba = coef(ma)["em"], ns = nobs(ms), na = nobs(ma))
}, error = function(e) { message("Eco error: ", conditionMessage(e)); NULL })

if (!is.null(res_survey)) {
  emit("mate_competition_table1_col1", res_survey$c1)
  emit("mate_competition_table1_col2", res_survey$c2)
  emit("mate_competition_table1_col3", res_survey$c3)
  emit("mate_competition_table1_col4", res_survey$c4)
  emit("mate_competition_table1_col5", res_survey$c5)
  emit("mate_competition_table1_col6", res_survey$c6)
  emit("job_competition_table1_col2", res_survey$j2)
  emit("n_obs_table1_col1", res_survey$n1)
  emit("n_obs_table1_col3", res_survey$n3)
}
if (!is.null(res_eco)) {
  emit("excess_males_sum_tableC1_col5", res_eco$bs)
  emit("excess_males_annual_tableC1_col6", res_eco$ba)
  emit("n_obs_sum_tableC1_col5", res_eco$ns)
  emit("n_obs_annual_tableC1_col6", res_eco$na)
}