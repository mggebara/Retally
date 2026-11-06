suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bokobza_2022_morning_after_coup_purges.script-free"

# ---------------- helpers ----------------
pick <- function(nms, cands) {
  for (c in cands) if (c %in% nms) return(c)
  NA_character_
}
find_re <- function(nms, pattern, exclude = NULL) {
  m <- nms[grepl(pattern, nms, ignore.case = TRUE)]
  if (!is.null(exclude)) m <- m[!grepl(exclude, m, ignore.case = TRUE)]
  if (length(m) == 0) NA_character_ else m[1]
}
lag_by <- function(df, var, id, time) {
  o <- order(df[[id]], df[[time]])
  v <- df[[var]][o]; g <- df[[id]][o]; t <- df[[time]][o]
  n <- length(v)
  lv <- rep(NA_real_, n)
  if (n > 1) {
    ok <- c(FALSE, g[-1] == g[-n] & t[-1] == t[-n] + 1)
    lv[ok] <- as.numeric(v[which(ok) - 1])
  }
  out <- rep(NA_real_, n)
  out[o] <- lv
  out
}
safe_coef <- function(m, nm) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (nm %in% names(cf)) unname(cf[nm]) else NA_real_
}
coef_grep <- function(m, pattern) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  hit <- names(cf)[grepl(pattern, names(cf), ignore.case = TRUE)]
  if (length(hit) == 0) return(NA_real_)
  unname(cf[hit[1]])
}
fmt <- function(x) if (is.na(x)) "NA" else formatC(x, digits = 8, format = "f")

# ================= COUNTRY LEVEL =================
cl <- haven::read_dta(file.path(base_dir, "morning_after_dataset_countrylevel.dta"))
cl <- as.data.frame(haven::zap_labels(cl))
nms <- names(cl)

idv <- pick(nms, c("COUNTRY_ID", "COUNTRY_DATA"))
tv  <- pick(nms, c("YEAR_DATA", "year"))
cl[[tv]] <- as.numeric(cl[[tv]])

dv <- pick(nms, c("replacement_rateadj_minister"))
if (is.na(dv)) dv <- find_re(nms, "^replacement_rate", "_[0-9]+$")

coupv <- pick(nms, c("coupattempt_whogov", "coupattempt_presentyear", "coupattempt"))
if (is.na(coupv)) coupv <- find_re(nms, "^coupattempt", "month|type|_br|lag|^l")
cl$fca <- as.numeric(as.numeric(cl[[coupv]]) > 0)

# lagged democracy (BMR)
ldem <- pick(nms, c("ldemocracy1", "democracy1_lag", "lag_democracy1", "ldemocracy", "democracy_lag"))
if (is.na(ldem)) {
  cl$ldem_bmr <- lag_by(cl, "democracy1", idv, tv)
} else {
  cl$ldem_bmr <- as.numeric(cl[[ldem]])
}

# GDP and population (lagged)
get_lagged <- function(df, lagcands, lagre, basecands, basere, baseexcl) {
  nm <- names(df)
  lv <- pick(nm, lagcands)
  if (is.na(lv)) lv <- find_re(nm, lagre, "growth")
  if (!is.na(lv)) return(as.numeric(df[[lv]]))
  bv <- pick(nm, basecands)
  if (is.na(bv)) bv <- find_re(nm, basere, baseexcl)
  if (is.na(bv)) stop("Cannot find variable for ", basere)
  lag_by(df, bv, idv, tv)
}
cl$lgdp <- get_lagged(cl,
  c("gdp_cap_pwt_ln_lag", "lgdp_cap_pwt_ln", "l_gdp_cap_pwt_ln", "gdp_pwt_ln_lag", "lgdp_pwt_ln"),
  "(gdp.*ln.*lag)|(^l_?gdp.*ln)",
  c("gdp_cap_pwt_ln", "gdp_pwt_ln", "rgdpe_pc_ln"), "gdp.*ln", "growth|lag")
cl$lpop <- get_lagged(cl,
  c("pop_pwt_ln_lag", "lpop_pwt_ln", "l_pop_pwt_ln"),
  "(pop.*ln.*lag)|(^l_?pop.*ln)",
  c("pop_pwt_ln"), "pop.*ln", "lag")

# regime dummies lagged
get_reg <- function(base) {
  nm <- names(cl)
  lv <- pick(nm, c(paste0(base, "_lag"), paste0("l", base), paste0("l_", base), paste0("lag_", base)))
  if (!is.na(lv)) return(as.numeric(cl[[lv]]))
  lag_by(cl, base, idv, tv)
}
cl$lmil <- get_reg("military_c")
cl$lmon <- get_reg("monarchy_c")
cl$lpar <- get_reg("party_c")

cl$cluster_id <- cl[[idv]]
cl$country_fe <- cl[[idv]]
cl$year_fe <- cl[[tv]]
cl$leader_fe <- if ("leader_cab_id" %in% nms) cl$leader_cab_id else NA

cat(sprintf("SAMPLE:country:loaded=%d\n", nrow(cl)))
cs <- cl[!is.na(cl$ldem_bmr) & cl$ldem_bmr == 0, ]
cat(sprintf("SAMPLE:country:autocracy_lagged_bmr=%d\n", nrow(cs)))
cs <- cs[cs[[tv]] >= 1967 & cs[[tv]] <= 2016, ]
cat(sprintf("SAMPLE:country:years_1967_2016=%d\n", nrow(cs)))
cs$dv <- as.numeric(cs[[dv]])

run_feols <- function(fml, data) {
  tryCatch(feols(fml, data = data, cluster = ~cluster_id, warn = FALSE, notes = FALSE),
           error = function(e) { message("feols error: ", conditionMessage(e)); NULL })
}

m_base_c <- run_feols(dv ~ fca + lgdp + lpop | country_fe + year_fe, cs)
m_main_c <- run_feols(dv ~ fca + lgdp + lpop + lmil + lpar + lmon | country_fe + year_fe, cs)
m_base_l <- run_feols(dv ~ fca + lgdp + lpop | leader_fe + year_fe, cs)
m_main_l <- run_feols(dv ~ fca + lgdp + lpop + lmil + lpar + lmon | leader_fe + year_fe, cs)

pn <- function(m) if (is.null(m)) 0L else as.integer(nobs(m))
cat(sprintf("SAMPLE:country_base_cfe:estimation=%d\n", pn(m_base_c)))
cat(sprintf("SAMPLE:country_main_cfe:estimation=%d\n", pn(m_main_c)))
cat(sprintf("SAMPLE:country_base_lfe:estimation=%d\n", pn(m_base_l)))
cat(sprintf("SAMPLE:country_main_lfe:estimation=%d\n", pn(m_main_l)))

# ================= INDIVIDUAL LEVEL =================
il_raw <- as.data.frame(readRDS(file.path(base_dir, "morning_after_dataset_individuallevel.rds")))
il <- il_raw
for (v in names(il)) if (inherits(il[[v]], "haven_labelled")) il[[v]] <- haven::as_factor(il[[v]])
inms <- names(il)

# numeric conversion from the RAW column (labelled -> underlying codes), so that
# value labels such as "Yes"/"No" do not become NA via as.character()
num_raw <- function(v) {
  if (is.na(v) || !(v %in% names(il_raw))) return(rep(NA_real_, nrow(il_raw)))
  x <- il_raw[[v]]
  if (inherits(x, "haven_labelled")) return(as.numeric(haven::zap_labels(x)))
  if (is.factor(x)) {
    y <- suppressWarnings(as.numeric(as.character(x)))
    if (sum(!is.na(y)) == 0) {
      lx <- tolower(as.character(x))
      y <- ifelse(lx %in% c("yes", "true", "coup attempt", "failed coup"), 1,
           ifelse(lx %in% c("no", "false", "none", "no coup"), 0, NA_real_))
    }
    return(y)
  }
  if (is.logical(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}

cat(sprintf("SAMPLE:individual:loaded=%d\n", nrow(il)))

il$year <- num_raw("year")
il$purged <- num_raw("purged_y1")
fca_v <- rep(NA_real_, nrow(il))
for (cand in c("coupattempt_presentyear", "coupattempt_whogov")) {
  if (cand %in% inms) {
    x <- num_raw(cand)
    if (sum(!is.na(x)) > 0) { fca_v <- as.numeric(x > 0); break }
  }
}
il$fca <- fca_v
il$lgdp <- num_raw("gdp_cap_pwt_ln_lag")
il$lpop <- num_raw("pop_pwt_ln_lag")
il$exper <- num_raw("experience")
il$exper2 <- il$exper^2
il$exper3 <- il$exper^3
il$cluster_id <- as.character(il$country_isocode)
il$country_fe <- as.character(il$country_isocode)
il$year_fe <- il$year

message("non-missing: fca=", sum(!is.na(il$fca)), " lgdp=", sum(!is.na(il$lgdp)),
        " lpop=", sum(!is.na(il$lpop)), " exper=", sum(!is.na(il$exper)),
        " purged=", sum(!is.na(il$purged)))

# leader indicator
is_leader <- rep(FALSE, nrow(il))
if ("leader" %in% inms) {
  lv <- il$leader
  lvn <- suppressWarnings(as.numeric(as.character(lv)))
  if (sum(!is.na(lvn)) > 0.9 * sum(!is.na(lv)) && all(lvn[!is.na(lvn)] %in% c(0, 1))) {
    is_leader <- !is.na(lvn) & lvn == 1
  } else if ("name" %in% inms) {
    is_leader <- !is.na(lv) & as.character(lv) == as.character(il$name)
  }
}
if ("importance_factor" %in% inms) {
  is_leader <- is_leader | grepl("^leader$", as.character(il$importance_factor), ignore.case = TRUE)
}
il$is_leader <- is_leader

# autocracy: lagged BMR democracy == 0
demv <- pick(inms, c("democracy_lag", "democracy_lag_bmr"))
ind <- il[!is.na(il[[demv]]) & as.numeric(as.character(il[[demv]])) == 0, ]
cat(sprintf("SAMPLE:individual:autocracy_lagged_bmr=%d\n", nrow(ind)))
ind <- ind[!is.na(ind$year) & ind$year >= 1967 & ind$year <= 2016, ]
cat(sprintf("SAMPLE:individual:years_1967_2016=%d\n", nrow(ind)))
ind <- ind[!ind$is_leader, ]
cat(sprintf("SAMPLE:individual:exclude_leader=%d\n", nrow(ind)))

# helper to build releveled factor with clean names
make_factor <- function(x, ref_re, ref_excl = NULL) {
  x <- as.character(x)
  x[x == "" ] <- NA
  levs <- sort(unique(x[!is.na(x)]))
  cand <- levs[grepl(ref_re, levs, ignore.case = TRUE)]
  if (!is.null(ref_excl)) cand <- cand[!grepl(ref_excl, cand, ignore.case = TRUE)]
  ref <- if (length(cand)) cand[1] else levs[1]
  factor(x, levels = c(ref, setdiff(levs, ref)))
}
interaction_coef <- function(m, varname, f, level_re, level_excl = NULL) {
  if (is.null(m)) return(NA_real_)
  levs <- levels(f)[-1]
  hit <- levs[grepl(level_re, levs, ignore.case = TRUE)]
  if (!is.null(level_excl)) hit <- hit[!grepl(level_excl, hit, ignore.case = TRUE)]
  if (length(hit) == 0) return(NA_real_)
  nm <- paste0("fca:", varname, hit[1])
  v <- safe_coef(m, nm)
  if (is.na(v)) v <- safe_coef(m, paste0(varname, hit[1], ":fca"))
  if (is.na(v)) {
    cf <- coef(m)
    cand <- names(cf)[grepl("fca", names(cf)) & grepl(varname, names(cf), fixed = TRUE) &
                      grepl(hit[1], names(cf), fixed = TRUE)]
    if (length(cand)) v <- unname(cf[cand[1]])
  }
  v
}

imp_chr <- if ("importance_factor" %in% inms) as.character(ind$importance_factor) else as.character(ind$classification)
low_junior <- grepl("junior|low", imp_chr, ignore.case = TRUE)

# --- H2a Experience ---
ie <- ind[!low_junior, ]
cat(sprintf("SAMPLE:ind_experience:loaded=%d\n", nrow(il)))
cat(sprintf("SAMPLE:ind_experience:autocracy_years_noleader=%d\n", nrow(ind)))
cat(sprintf("SAMPLE:ind_experience:exclude_junior_lowranking=%d\n", nrow(ie)))
ie$expg <- make_factor(ie$experience_group, "<\\s*2|less than 2|under 2|0-1|^1$|0_1")
m_exp <- tryCatch(feols(purged ~ fca * expg + lgdp + lpop | country_fe + year_fe, data = ie,
                        cluster = ~cluster_id, warn = FALSE, notes = FALSE),
                  error = function(e) { message(conditionMessage(e)); NULL })
cat(sprintf("SAMPLE:ind_experience:estimation=%d\n", pn(m_exp)))
if (!is.null(m_exp)) message("m_exp coefs: ", paste(names(coef(m_exp)), collapse = ", "))

# --- H2b Affiliation ---
cat(sprintf("SAMPLE:ind_affiliation:loaded=%d\n", nrow(il)))
cat(sprintf("SAMPLE:ind_affiliation:autocracy_years_noleader=%d\n", nrow(ind)))
ia <- ind
ia$pg <- make_factor(ia$party_group, "other|another")
m_aff <- tryCatch(feols(purged ~ fca * pg + exper + exper2 + exper3 + lgdp + lpop | country_fe + year_fe,
                        data = ia, cluster = ~cluster_id, warn = FALSE, notes = FALSE),
                  error = function(e) { message(conditionMessage(e)); NULL })
cat(sprintf("SAMPLE:ind_affiliation:estimation=%d\n", pn(m_aff)))
if (!is.null(m_aff)) message("m_aff coefs: ", paste(names(coef(m_aff)), collapse = ", "))

# --- H3a Responsibility ---
cat(sprintf("SAMPLE:ind_responsibility:loaded=%d\n", nrow(il)))
cat(sprintf("SAMPLE:ind_responsibility:autocracy_years_noleader=%d\n", nrow(ind)))
ir <- ind
ir$mt <- make_factor(ir$minister_type, "defen|defence|defense")
m_resp <- tryCatch(feols(purged ~ fca * mt + exper + exper2 + exper3 + lgdp + lpop | country_fe + year_fe,
                         data = ir, cluster = ~cluster_id, warn = FALSE, notes = FALSE),
                   error = function(e) { message(conditionMessage(e)); NULL })
cat(sprintf("SAMPLE:ind_responsibility:estimation=%d\n", pn(m_resp)))
if (!is.null(m_resp)) message("m_resp coefs: ", paste(names(coef(m_resp)), collapse = ", "))

# --- H3b Importance ---
cat(sprintf("SAMPLE:ind_importance:loaded=%d\n", nrow(il)))
cat(sprintf("SAMPLE:ind_importance:autocracy_years_noleader=%d\n", nrow(ind)))
ii <- ind
ii$impf <- make_factor(imp_chr, "prime|president|^pm", "vice|deputy|top|leader")
m_imp <- tryCatch(feols(purged ~ fca * impf + exper + exper2 + exper3 + lgdp + lpop | country_fe + year_fe,
                        data = ii, cluster = ~cluster_id, warn = FALSE, notes = FALSE),
                  error = function(e) { message(conditionMessage(e)); NULL })
cat(sprintf("SAMPLE:ind_importance:estimation=%d\n", pn(m_imp)))

# ================= RESULTS =================
res <- list(
  failed_coup_base_country_fe = safe_coef(m_base_c, "fca"),
  failed_coup_main_country_fe = safe_coef(m_main_c, "fca"),
  failed_coup_base_leader_fe = safe_coef(m_base_l, "fca"),
  failed_coup_main_leader_fe = safe_coef(m_main_l, "fca"),
  failed_coup_experience_model = safe_coef(m_exp, "fca"),
  failed_coup_x_over_6_years_experience = interaction_coef(m_exp, "expg", ie$expg, ">\\s*6|over 6|more than 6|6\\+|7"),
  failed_coup_affiliation_model = safe_coef(m_aff, "fca"),
  failed_coup_x_leaders_party = interaction_coef(m_aff, "pg", ia$pg, "leader"),
  failed_coup_responsibility_model = safe_coef(m_resp, "fca"),
  failed_coup_x_natural_resources = interaction_coef(m_resp, "mt", ir$mt, "natural|resource|oil|mining|energy"),
  failed_coup_importance_model = safe_coef(m_imp, "fca")
)
for (n in names(res)) cat(sprintf("RESULT:%s=%s\n", n, fmt(res[[n]])))