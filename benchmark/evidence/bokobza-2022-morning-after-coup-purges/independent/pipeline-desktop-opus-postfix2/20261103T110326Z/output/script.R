suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"
results <- list()

pick_col <- function(df, cands) {
  for (c in cands) if (c %in% names(df)) return(c)
  NA_character_
}
grep_col <- function(df, include, exclude = NULL, prefer = NULL) {
  nm <- names(df)
  hit <- nm[Reduce(`&`, lapply(include, function(p) grepl(p, nm, ignore.case = TRUE)))]
  if (!is.null(exclude) && length(hit)) hit <- hit[!grepl(exclude, hit, ignore.case = TRUE)]
  if (!is.null(prefer) && length(hit)) {
    p <- hit[grepl(prefer, hit, ignore.case = TRUE)]
    if (length(p)) hit <- p
  }
  if (length(hit)) hit[1] else NA_character_
}
lag_by <- function(df, var, id, yr) {
  key <- paste(df[[id]], df[[yr]])
  lkey <- paste(df[[id]], df[[yr]] - 1)
  df[[var]][match(lkey, key)]
}
num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))

# ------------------------------------------------------------------
# Country-level analysis (Tables A1, A2)
# ------------------------------------------------------------------
cl <- tryCatch(as.data.frame(read_dta(file.path(base_dir, "morning_after_dataset_countrylevel.dta"))),
               error = function(e) NULL)

if (!is.null(cl)) {
  id_c <- pick_col(cl, c("COUNTRY_ID", "COUNTRY_DATA"))
  yr_c <- pick_col(cl, c("YEAR_DATA", "year"))
  cl[[yr_c]] <- num(cl[[yr_c]])
  dv <- pick_col(cl, c("replacement_rateadj_minister"))
  coup <- pick_col(cl, c("coupattempt_whogov", "coupattempt_presentyear", "coupattempt"))
  if (is.na(coup)) coup <- grep_col(cl, "^coupattem", exclude = "month|_br|type|lag")
  if (is.na(coup)) coup <- grep_col(cl, "coup", exclude = "month|_br|type|lag")
  cl$fca <- num(cl[[coup]])
  cl$dv <- num(cl[[dv]])

  # lagged controls
  gdp_lag <- grep_col(cl, c("gdp", "ln"), exclude = "growth", prefer = "lag|^l")
  pop_lag <- grep_col(cl, c("pop", "ln"), exclude = "oil", prefer = "lag|^l")
  if (!is.na(gdp_lag) && grepl("lag|^l", gdp_lag)) cl$lgdp <- num(cl[[gdp_lag]]) else if (!is.na(gdp_lag)) {
    cl$tmp <- num(cl[[gdp_lag]]); cl$lgdp <- lag_by(cl, "tmp", id_c, yr_c)
  }
  if (!is.na(pop_lag) && grepl("lag|^l", pop_lag)) cl$lpop <- num(cl[[pop_lag]]) else if (!is.na(pop_lag)) {
    cl$tmp <- num(cl[[pop_lag]]); cl$lpop <- lag_by(cl, "tmp", id_c, yr_c)
  }
  for (v in c("military_c", "monarchy_c", "party_c")) {
    lv <- pick_col(cl, c(paste0("l", v), paste0(v, "_lag"), paste0("lag_", v)))
    if (!is.na(lv)) cl[[paste0("L_", v)]] <- num(cl[[lv]]) else if (v %in% names(cl)) {
      cl$tmp <- num(cl[[v]]); cl[[paste0("L_", v)]] <- lag_by(cl, "tmp", id_c, yr_c)
    } else cl[[paste0("L_", v)]] <- NA_real_
  }
  # lagged BMR democracy
  ld <- pick_col(cl, c("ldemocracy1", "democracy1_lag", "lag_democracy1", "ldemocracy"))
  if (!is.na(ld)) cl$ldem <- num(cl[[ld]]) else {
    cl$tmp <- num(cl$democracy1); cl$ldem <- lag_by(cl, "tmp", id_c, yr_c)
  }
  leader_id <- pick_col(cl, c("leader_id", "leaderid", "leader_cab_id"))
  if (is.na(leader_id)) leader_id <- grep_col(cl, c("leader", "id"))
  cl$country <- cl[[id_c]]
  cl$leaderfe <- cl[[leader_id]]

  cat(sprintf("SAMPLE:country_level:loaded=%d\n", nrow(cl)))
  s <- cl[!is.na(cl$ldem) & cl$ldem == 0, ]
  cat(sprintf("SAMPLE:country_level:lagged_bmr_autocracy=%d\n", nrow(s)))
  s <- s[s[[yr_c]] >= 1967 & s[[yr_c]] <= 2016, ]
  cat(sprintf("SAMPLE:country_level:years_1967_2016=%d\n", nrow(s)))
  s <- s[!is.na(s$dv) & !is.na(s$fca), ]
  cat(sprintf("SAMPLE:country_level:nonmissing_dv_coup=%d\n", nrow(s)))
  s$yearfe <- s[[yr_c]]

  run <- function(fml, nm) {
    m <- tryCatch(feols(as.formula(fml), data = s, cluster = ~country), error = function(e) { message(e$message); NULL })
    if (!is.null(m)) {
      cat(sprintf("SAMPLE:%s:estimation=%d\n", nm, nobs(m)))
      results[[nm]] <<- coef(m)["fca"]
      results[[paste0(nm, "_se")]] <<- sqrt(diag(vcov(m)))["fca"]
    }
  }
  run("dv ~ fca + lgdp + lpop | country + yearfe", "failed_coup_base_country_fe")
  run("dv ~ fca + lgdp + lpop + L_military_c + L_monarchy_c + L_party_c | country + yearfe", "failed_coup_main_country_fe")
  run("dv ~ fca + lgdp + lpop | leaderfe + yearfe", "failed_coup_base_leader_fe")
  run("dv ~ fca + lgdp + lpop + L_military_c + L_monarchy_c + L_party_c | leaderfe + yearfe", "failed_coup_main_leader_fe")
}

# ------------------------------------------------------------------
# Individual-level analysis (Tables K1, K2)
# ------------------------------------------------------------------
ind <- tryCatch(readRDS(file.path(base_dir, "morning_after_dataset_individuallevel.rds")), error = function(e) NULL)

if (!is.null(ind)) {
  ind <- as.data.frame(ind)
  cat(sprintf("SAMPLE:individual:loaded=%d\n", nrow(ind)))
  ind$year <- num(ind$year)
  ind$purged <- num(ind$purged_y1)
  ind$fca <- num(ind$coupattempt_presentyear)
  ind$lgdp <- num(ind$gdp_cap_pwt_ln_lag)
  ind$lpop <- num(ind$pop_pwt_ln_lag)
  ind$exper <- num(ind$experience)
  ind$exper2 <- ind$exper^2
  ind$exper3 <- ind$exper^3
  ind$country <- as.character(ind$country_isocode)

  if ("democracy_lag" %in% names(ind)) {
    ind <- ind[!is.na(num(ind$democracy_lag)) & num(ind$democracy_lag) == 0, ]
    cat(sprintf("SAMPLE:individual:lagged_bmr_autocracy=%d\n", nrow(ind)))
  } else cat("DEVIATION: democracy_lag not found; autocracy restriction not applied\n")
  ind <- ind[!is.na(ind$year) & ind$year >= 1967 & ind$year <= 2016, ]
  cat(sprintf("SAMPLE:individual:years_1967_2016=%d\n", nrow(ind)))

  # exclude the leader
  is_leader <- rep(FALSE, nrow(ind))
  if ("leader" %in% names(ind)) {
    lv <- num(ind$leader)
    if (all(lv %in% c(0, 1, NA)) && any(!is.na(lv))) is_leader <- is_leader | (!is.na(lv) & lv == 1)
  }
  for (v in c("classification", "minister_type", "minister_classification", "importance_factor")) {
    if (v %in% names(ind)) is_leader <- is_leader | grepl("^leader$|^the leader$|^head of state \\(leader\\)", trimws(as.character(ind[[v]])), ignore.case = TRUE)
  }
  ind <- ind[!is_leader, ]
  cat(sprintf("SAMPLE:individual:exclude_leader=%d\n", nrow(ind)))
  ind <- ind[!is.na(ind$purged) & !is.na(ind$fca), ]
  cat(sprintf("SAMPLE:individual:nonmissing_purge_coup=%d\n", nrow(ind)))

  make_dummies <- function(df, var, ref_regex, ref_exclude = NULL) {
    f <- as.factor(as.character(df[[var]]))
    lev <- levels(f)
    ref <- lev[grepl(ref_regex, lev, ignore.case = TRUE)]
    if (!is.null(ref_exclude) && length(ref)) ref <- ref[!grepl(ref_exclude, ref, ignore.case = TRUE)]
    ref <- if (length(ref)) ref[1] else lev[1]
    others <- setdiff(lev, ref)
    dn <- character(0)
    for (i in seq_along(others)) {
      d <- paste0("g_", var, "_", i)
      df[[d]] <- as.numeric(as.character(f) == others[i])
      df[[paste0("fcax_", d)]] <- df$fca * df[[d]]
      dn <- c(dn, d)
    }
    names(dn) <- others
    list(df = df, dn = dn, ref = ref)
  }
  run_ind <- function(df, var, ref_regex, nm, poly = TRUE, ref_exclude = NULL) {
    md <- make_dummies(df, var, ref_regex, ref_exclude)
    d <- md$df
    rhs <- c("fca", md$dn, paste0("fcax_", md$dn), "lgdp", "lpop")
    if (poly) rhs <- c(rhs, "exper", "exper2", "exper3")
    fml <- as.formula(paste("purged ~", paste(rhs, collapse = " + "), "| country + year"))
    m <- tryCatch(feols(fml, data = d, cluster = ~country), error = function(e) { message(e$message); NULL })
    if (!is.null(m)) cat(sprintf("SAMPLE:%s:estimation=%d\n", nm, nobs(m)))
    list(m = m, dn = md$dn, ref = md$ref)
  }
  getint <- function(r, lev_regex) {
    if (is.null(r$m)) return(NA)
    lv <- names(r$dn)[grepl(lev_regex, names(r$dn), ignore.case = TRUE)]
    if (!length(lv)) return(NA)
    coef(r$m)[paste0("fcax_", r$dn[lv[1]])]
  }

  # H2a: experience (exclude junior and low-ranking posts)
  dx <- ind
  if (!"experience_group" %in% names(dx) || all(is.na(dx$experience_group))) {
    dx$experience_group <- cut(dx$exper, c(-Inf, 1.999, 3.999, 6.0001, Inf), labels = c("<2", "2-3", "4-6", ">6"))
  }
  if ("importance_factor" %in% names(dx)) {
    dx <- dx[!grepl("junior|low", as.character(dx$importance_factor), ignore.case = TRUE), ]
    cat(sprintf("SAMPLE:h2a_experience:exclude_junior_lowranking=%d\n", nrow(dx)))
  }
  dx <- dx[!is.na(dx$experience_group), ]
  r1 <- run_ind(dx, "experience_group", "<\\s*2|less than 2|under 2|^0-1|^1$|0-2", "h2a_experience", poly = FALSE)
  if (!is.null(r1$m)) {
    results$failed_coup_experience_model <- coef(r1$m)["fca"]
    results$failed_coup_x_over_6_years_experience <- getint(r1, ">\\s*6|over 6|more than 6|6\\+|7")
  }

  # H2b: affiliation
  r2 <- run_ind(ind[!is.na(ind$party_group), ], "party_group", "other|another", "h2b_affiliation")
  if (!is.null(r2$m)) {
    results$failed_coup_affiliation_model <- coef(r2$m)["fca"]
    results$failed_coup_x_leaders_party <- getint(r2, "leader")
  }

  # H3a: responsibility (portfolio type)
  r3 <- run_ind(ind[!is.na(ind$minister_type), ], "minister_type", "defen[cs]e", "h3a_responsibility")
  if (!is.null(r3$m)) {
    results$failed_coup_responsibility_model <- coef(r3$m)["fca"]
    results$failed_coup_x_natural_resources <- getint(r3, "natural|resource")
  }

  # H3b: importance tiers
  r4 <- run_ind(ind[!is.na(ind$importance_factor), ], "importance_factor",
                "prime minister|president|^PM|not.*leader", "h3b_importance",
                ref_exclude = "vice|deputy|top")
  if (!is.null(r4$m)) results$failed_coup_importance_model <- coef(r4$m)["fca"]
}

for (nm in names(results)) {
  v <- as.numeric(results[[nm]])
  if (length(v) && !is.na(v)) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
}