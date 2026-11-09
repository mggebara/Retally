suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"

results <- list()
emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  results[[name]] <<- val
}

pick <- function(nms, patterns, exclude = NULL) {
  for (p in patterns) {
    hit <- grep(p, nms, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) hit <- hit[!grepl(exclude, hit, ignore.case = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}

strip_df <- function(d) {
  d <- as.data.frame(d)
  for (v in names(d)) {
    if (inherits(d[[v]], "haven_labelled")) d[[v]] <- as.numeric(zap_labels(d[[v]]))
  }
  d
}

# ---------------- Country level ----------------
cl <- strip_df(read_dta(file.path(base, "morning_after_dataset_countrylevel.dta")))
cn <- names(cl)
cat("Country-level columns:\n"); print(cn)

dv <- "replacement_rateadj_minister"
fca <- pick(cn, c("^failed", "fail.*coup", "coup.*fail", "^coupattempt_whogov$", "^coupattempt_whogov", "^coupattempt$", "^coupattempt"),
            exclude = "month|_br|type|lag|^l")
cat("Failed coup var:", fca, "\n")
gdp <- pick(cn, c("^l.*gdp.*ln", "^l.*ln.*gdp", "gdp.*ln.*lag", "^lgdp", "ln.*gdp", "gdp.*ln", "gdp"), exclude = "growth")
pop <- pick(cn, c("^l.*pop.*ln", "^l.*ln.*pop", "pop.*ln.*lag", "^lpop", "ln.*pop", "pop.*ln", "pop"), exclude = "oil")
cat("GDP var:", gdp, " Pop var:", pop, "\n")

cl$cid <- if ("COUNTRY_ID" %in% cn) cl$COUNTRY_ID else cl$COUNTRY_DATA
cl$yr <- cl$YEAR_DATA
cl <- cl %>% arrange(cid, yr)

# lag helper (panel lag by country, consecutive years)
plag <- function(d, v) {
  d %>% group_by(cid) %>% arrange(yr, .by_group = TRUE) %>%
    mutate(.l = ifelse(dplyr::lag(yr) == yr - 1, dplyr::lag(.data[[v]]), NA)) %>%
    ungroup() %>% pull(.l)
}
cl <- cl %>% arrange(cid, yr)
# if gdp/pop look unlagged (no leading 'l' prefix), lag them
mk_lag <- function(v) {
  if (is.na(v)) return(NULL)
  if (grepl("^l", v) || grepl("lag", v, ignore.case = TRUE)) return(cl[[v]])
  vals <- cl[[v]]
  if (!grepl("ln|log", v, ignore.case = TRUE) && all(vals[!is.na(vals)] > 0)) vals <- log(vals)
  tmp <- cl; tmp$.v <- vals
  plag(tmp, ".v")
}
cl$lgdp_c <- mk_lag(gdp)
cl$lpop_c <- mk_lag(pop)
for (v in c("military_c", "monarchy_c", "party_c")) {
  cl[[paste0("l_", v)]] <- plag(cl, v)
}
cl$fca <- cl[[fca]]
cl$fca[is.na(cl$fca)] <- NA

# autocracy sample: lagged BMR democracy == 0
autoc <- if ("ldemocracy_br" %in% cn) cl$ldemocracy_br else plag(cl, "democracy_br")
cs <- cl[!is.na(autoc) & autoc == 0, ]
cs <- cs[!is.na(cs[[dv]]), ]
cat("Country sample N:", nrow(cs), " failed coups:", sum(cs$fca == 1, na.rm = TRUE), "\n")

run_cl <- function(rhs, fe) {
  f <- as.formula(paste(dv, "~", rhs, "|", fe))
  m <- feols(f, data = cs, cluster = ~cid)
  print(summary(m))
  coef(m)["fca"]
}
tryCatch(emit("failed_coup_base_country_fe", run_cl("fca + lgdp_c + lpop_c", "cid + yr")), error = function(e) message(e))
tryCatch(emit("failed_coup_main_country_fe", run_cl("fca + lgdp_c + lpop_c + l_military_c + l_monarchy_c + l_party_c", "cid + yr")), error = function(e) message(e))
tryCatch(emit("failed_coup_base_leader_fe", run_cl("fca + lgdp_c + lpop_c", "leader_cab_id + yr")), error = function(e) message(e))
tryCatch(emit("failed_coup_main_leader_fe", run_cl("fca + lgdp_c + lpop_c + l_military_c + l_monarchy_c + l_party_c", "leader_cab_id + yr")), error = function(e) message(e))

# ---------------- Individual level ----------------
il <- readRDS(file.path(base, "morning_after_dataset_individuallevel.rds"))
il <- strip_df(il)
inm <- names(il)
cat("Individual-level columns:\n"); print(inm)
for (v in c("experience_group", "party_group", "portfolio_1", "prestige_1", "importance_numeric", "Group", "classification", "leader"))
  if (v %in% inm) { cat("Table of", v, ":\n"); print(head(sort(table(il[[v]], useNA = "ifany"), decreasing = TRUE), 50)) }

igdp <- pick(inm, c("gdp.*ln", "ln.*gdp", "gdp"), exclude = "growth")
ipop <- pick(inm, c("pop.*ln", "ln.*pop", "pop"), exclude = "oil")
cat("Ind GDP var:", igdp, " Pop var:", ipop, "\n")

# failed coup indicator
if ("coupattempt_presentyear" %in% inm) {
  il$fca <- as.numeric(il$coupattempt_presentyear)
} else {
  il$fca <- NA
}
il$fca[is.na(il$fca)] <- 0
il$cid <- il$country_isocode
il$yr <- il$year
il$lgdp_i <- il[[igdp]]
il$lpop_i <- il[[ipop]]
if (!grepl("ln|log", igdp, ignore.case = TRUE)) il$lgdp_i <- log(il$lgdp_i)
if (!grepl("ln|log", ipop, ignore.case = TRUE)) il$lpop_i <- log(il$lpop_i)
il$exp <- as.numeric(il$experience)
il$exp2 <- il$exp^2; il$exp3 <- il$exp^3

is <- il
if ("democracy_lag_br" %in% inm) is <- is[!is.na(is$democracy_lag_br) & is$democracy_lag_br == 0, ]
if ("leader" %in% inm) is <- is[is.na(is$leader) | as.numeric(is$leader) != 1, ]
is <- is[!is.na(is$purged_y1), ]
cat("Individual sample N:", nrow(is), "\n")

ctrl <- "lgdp_i + lpop_i"
run_il <- function(d, catvar, ref, poly = TRUE) {
  d$M <- relevel(factor(d[[catvar]]), ref = ref)
  rhs <- paste("fca * M +", ctrl, if (poly) "+ exp + exp2 + exp3" else "")
  m <- feols(as.formula(paste("purged_y1 ~", rhs, "| cid + yr")), data = d, cluster = ~cid)
  print(summary(m))
  m
}
getc <- function(m, pattern) {
  cc <- coef(m)
  nm <- grep(pattern, names(cc), value = TRUE, ignore.case = TRUE)
  nm <- nm[grepl("^fca:", nm)]
  if (length(nm) == 0) return(NA)
  cc[nm[1]]
}

# H2a experience
tryCatch({
  d <- is
  # exclude junior ministers / low-ranking posts
  if ("importance_numeric" %in% inm) {
    imp <- as.numeric(d$importance_numeric)
    d <- d[is.na(imp) | imp < max(imp, na.rm = TRUE) - 1 | TRUE, ]
  }
  if ("prestige_1" %in% inm) {
    d <- d[!grepl("junior|low", as.character(d$prestige_1), ignore.case = TRUE), ]
  }
  if ("experience_group" %in% inm) {
    lv <- levels(factor(d$experience_group))
    ref <- lv[grepl("<|less|under|0|1", lv)][1]; if (is.na(ref)) ref <- lv[1]
    d$experience_group <- factor(d$experience_group)
  } else {
    d$experience_group <- cut(d$exp, c(-Inf, 1.999, 3.999, 6.001, Inf), labels = c("lt2", "2-3", "4-6", "gt6"))
    ref <- "lt2"
  }
  m <- run_il(d, "experience_group", ref, poly = FALSE)
  emit("failed_coup_experience_model", coef(m)["fca"])
  cc <- names(coef(m)); cand <- cc[grepl("^fca:M", cc)]
  over <- cand[grepl(">|over|more|6\\+|7|gt", cand, ignore.case = TRUE) & !grepl("4", cand)]
  if (length(over) == 0) over <- tail(cand, 1)
  emit("failed_coup_x_over_6_years_experience", coef(m)[over[1]])
}, error = function(e) message(e))

# H2b affiliation
tryCatch({
  d <- is
  lv <- levels(factor(d$party_group))
  ref <- lv[grepl("other|another", lv, ignore.case = TRUE)][1]; if (is.na(ref)) ref <- lv[1]
  m <- run_il(d, "party_group", ref)
  emit("failed_coup_affiliation_model", coef(m)["fca"])
  emit("failed_coup_x_leaders_party", getc(m, "leader"))
}, error = function(e) message(e))

# H3a responsibility
tryCatch({
  d <- is
  pf <- tolower(as.character(d$portfolio_1))
  d$resp <- ifelse(grepl("defen|defense|security", pf), "Defense",
             ifelse(grepl("foreign", pf), "Foreign",
             ifelse(grepl("financ|econom|treasur", pf), "Finance",
             ifelse(grepl("natural|oil|petrol|mining|mine|energy", pf), "NaturalResources", "Other"))))
  d$resp[is.na(pf)] <- NA
  m <- run_il(d, "resp", "Defense")
  emit("failed_coup_responsibility_model", coef(m)["fca"])
  emit("failed_coup_x_natural_resources", getc(m, "Natural"))
}, error = function(e) message(e))

# H3b importance
tryCatch({
  d <- is
  if ("prestige_1" %in% inm) {
    d$imp <- factor(d$prestige_1)
    lv <- levels(d$imp)
    ref <- lv[grepl("prime minister|president|^pm", lv, ignore.case = TRUE) & !grepl("vice|deputy", lv, ignore.case = TRUE)][1]
    if (is.na(ref)) ref <- lv[1]
  } else {
    d$imp <- factor(d$importance_numeric)
    ref <- levels(d$imp)[1]
  }
  m <- run_il(d, "imp", ref)
  emit("failed_coup_importance_model", coef(m)["fca"])
}, error = function(e) message(e))

names_req <- c("failed_coup_base_country_fe", "failed_coup_main_country_fe", "failed_coup_base_leader_fe",
               "failed_coup_main_leader_fe", "failed_coup_experience_model", "failed_coup_x_over_6_years_experience",
               "failed_coup_affiliation_model", "failed_coup_x_leaders_party", "failed_coup_responsibility_model",
               "failed_coup_x_natural_resources", "failed_coup_importance_model")
for (n in names_req) {
  v <- results[[n]]
  if (is.null(v)) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(unname(as.numeric(v)), digits = 8)))
}
