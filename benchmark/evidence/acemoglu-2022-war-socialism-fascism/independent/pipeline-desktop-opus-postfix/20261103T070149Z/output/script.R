suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

data_path <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free/fascism_db.dta"
raw <- haven::read_dta(data_path)
labs <- vapply(raw, function(v) { l <- attr(v, "label"); if (is.null(l)) "" else as.character(l)[1] }, character(1))
df <- as.data.frame(haven::zap_labels(raw))
for (v in names(df)) attr(df[[v]], "label") <- NULL
nm <- names(df)
names(labs) <- nm

is_num <- function(v) is.numeric(df[[v]])
is_bin <- function(v) { x <- df[[v]]; if (!is.numeric(x)) return(FALSE); u <- unique(na.omit(x)); length(u) == 2 && all(u %in% c(0, 1)) }
is_bin_loose <- function(v) { x <- df[[v]]; if (!is.numeric(x)) return(FALSE); u <- unique(na.omit(x)); length(u) >= 1 && length(u) <= 2 && all(u %in% c(0, 1)) }

pick <- function(cands) { h <- cands[cands %in% nm]; if (length(h)) h[1] else NA_character_ }
find_re <- function(name_re = NULL, label_re = NULL, exclude = character(0), binary = NA, prefer = NULL) {
  hit <- rep(FALSE, length(nm))
  if (!is.null(name_re)) hit <- hit | grepl(name_re, nm, ignore.case = TRUE, perl = TRUE)
  if (!is.null(label_re)) hit <- hit | grepl(label_re, labs, ignore.case = TRUE, perl = TRUE)
  c0 <- setdiff(nm[hit], exclude)
  c0 <- c0[vapply(c0, is_num, logical(1))]
  if (!is.na(binary)) c0 <- c0[vapply(c0, is_bin, logical(1)) == binary]
  if (!length(c0)) return(NA_character_)
  if (!is.null(prefer)) { p <- c0[grepl(prefer, c0, ignore.case = TRUE)]; if (length(p)) return(p[1]) }
  c0[1]
}
need <- function(v, what) { if (is.na(v)) cat(sprintf("DEVIATION: could not locate variable for %s; omitted\n", what)); v }

# ---------------- core variables ----------------
y1919 <- "psu1919_vv"
inst  <- "foots_pop6m"
clus  <- "circondario1921"

# province identifier
prov <- NA_character_
for (cand in c("province", "provincia", "province1921", "provincia1921", "prov1921", "prov", "cod_prov", "codprov", "prov_id", "province_id", "id_prov")) {
  if (cand %in% nm) { k <- length(unique(na.omit(df[[cand]]))); if (k >= 40 && k <= 90) { prov <- cand; break } }
}
if (is.na(prov)) {
  cc <- nm[grepl("prov", nm, ignore.case = TRUE) | grepl("province|provincia", labs, ignore.case = TRUE)]
  for (cand in cc) { k <- length(unique(na.omit(df[[cand]]))); if (k >= 40 && k <= 90) { prov <- cand; break } }
}
if (is.na(prov)) cat("DEVIATION: province identifier not found; province FE omitted\n")

# regiment dummies (broadened search; province / region dummy families are excluded)
bad_prefix_re <- "prov|region|circond|distr|year|anno|pop|psu|vote|alt|elev|class|veteran|cens"
reg_vars <- nm[(grepl("(^|_)(reg|regg|regt|regim|regiment|reggimento|rgt|rgm|rég)[a-z]*_?d?_?[0-9]+(_d)?$", nm, ignore.case = TRUE) |
                grepl("regiment|reggiment|regim|brigat|brigade", labs, ignore.case = TRUE)) &
               !grepl("region|prov", nm, ignore.case = TRUE)]
reg_vars <- reg_vars[vapply(reg_vars, is_num, logical(1))]
if (!length(reg_vars)) {
  # fallback: largest family of numeric variables sharing a common prefix followed by a (non-year) number,
  # excluding province / region dummy families
  nums <- nm[vapply(nm, is_num, logical(1))]
  m <- regmatches(nums, regexec("^([A-Za-z_]+?)_?([0-9]{1,4})(_d)?$", nums))
  ok <- vapply(m, length, integer(1)) > 0
  if (any(ok)) {
    pref <- vapply(m[ok], function(z) tolower(z[2]), character(1))
    numpart <- vapply(m[ok], function(z) as.numeric(z[3]), numeric(1))
    keep <- !grepl(bad_prefix_re, pref, ignore.case = TRUE) & !(numpart >= 1800 & numpart <= 2030)
    cand_v <- nums[ok][keep]; pref <- pref[keep]
    if (length(cand_v)) {
      tab <- sort(table(pref), decreasing = TRUE)
      tab <- tab[tab >= 20]
      if (length(tab)) {
        pri <- names(tab)[grepl("^r|brig|reg|rgt", names(tab), ignore.case = TRUE)]
        best <- if (length(pri)) pri[1] else names(tab)[1]
        reg_vars <- cand_v[pref == best]
        cat(sprintf("DEVIATION: regiment dummies identified heuristically as %d variables with prefix '%s' (province dummy family excluded)\n", length(reg_vars), best))
      }
    }
  }
}
if (length(reg_vars)) {
  # convert to 'any deaths in regiment' dummies if stored as counts/shares
  newv <- character(0)
  for (v in reg_vars) {
    x <- df[[v]]
    nv <- paste0("regd__", v)
    df[[nv]] <- ifelse(is.na(x), 0, as.numeric(x > 0))
    newv <- c(newv, nv)
  }
  reg_vars <- newv
  reg_vars <- reg_vars[vapply(reg_vars, function(v) length(unique(na.omit(df[[v]]))) == 2, logical(1))]
}
if (!length(reg_vars)) cat("DEVIATION: regiment dummies not found; regiment FE omitted\n")
nm <- names(df)

# demographic: quartic in log population + share below 6
lpop <- pick(c("lpop1921", "lpop", "lnpop1921", "log_pop1921", "lpop_1921", "lnpop", "logpop", "lpop1911"))
if (is.na(lpop)) lpop <- find_re(name_re = "^(l|ln|log)_?pop", label_re = "\\(log\\).*population|log.*population", binary = FALSE)
if (!is.na(lpop)) {
  df$lp1 <- df[[lpop]]
} else {
  pp <- pick(c("pop1921", "pop_1921", "pop1911", "pop_1911", "pop"))
  if (!is.na(pp)) { df$lp1 <- log(df[[pp]]) } else { cat("DEVIATION: population not found\n"); df$lp1 <- NA }
}
df$lp2 <- df$lp1^2; df$lp3 <- df$lp1^3; df$lp4 <- df$lp1^4
demo <- c("lp1", "lp2", "lp3", "lp4", "sh_pop_1911_be6")

# geographic
alt_c <- pick(c("alt", "altitude", "alt_center", "alt_centro", "altitudine", "elevation", "elev", "alt_mun", "min_alt"))
if (is.na(alt_c)) alt_c <- find_re(name_re = "alt|elev", label_re = "elevation|altitude", exclude = c("max_alt"), binary = FALSE)
geo <- c("larea", need(alt_c, "elevation of main center"), "max_alt")

pol13 <- "psu1913_vv"

# military
assault <- pick(c("arditi_vol_pop6m", "assault_vol_pop6m", "vol_arditi_pop6m", "arditivol_pop6m", "special_pop6m"))
if (is.na(assault)) assault <- find_re(name_re = "ardit|assault|volunt", label_re = "assault|ardit|volunteer",
                                       exclude = c(inst, "casualties_pop6m"), binary = FALSE, prefer = "pop6m")
battle <- find_re(name_re = "battle|bloody|deadl|maxdeath|highmort", label_re = "battle|mortality|1000|1,000|bloodiest",
                  binary = TRUE)
mil <- c("veterans74_95", "veterans96_00", need(assault, "assault/volunteer casualties"), "army_suppliers_d",
         need(battle, "highest-mortality battle dummy"))

# agricultural
shcrop <- find_re(name_re = "sharecrop|share_crop|mezzadr|shcrop|scrop", label_re = "sharecrop|mezzadr", binary = FALSE)
landown <- find_re(name_re = "landown|agrar", label_re = "landowner|agrarian|agrari", binary = TRUE)
agr <- c("dlab", need(shcrop, "share of sharecroppers"), need(landown, "landowner association dummy"))

urb <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")

clean <- function(v) { v <- v[!is.na(v)]; v <- v[v %in% names(df)]; unique(v) }
spec <- list()
spec[[1]] <- clean(c(reg_vars, demo))
spec[[2]] <- clean(c(spec[[1]], geo))
spec[[3]] <- clean(c(spec[[2]], pol13))
spec[[4]] <- clean(c(spec[[3]], mil))
spec[[5]] <- clean(c(spec[[4]], agr))
spec[[6]] <- clean(c(spec[[5]], urb))

zs <- function(x) (x - mean(x)) / sd(x)
bt <- function(v) paste0("`", v, "`")

build_sample <- function(sname, yvar, ctrls, endog = NULL) {
  cat(sprintf("SAMPLE:%s:loaded=%d\n", sname, nrow(df)))
  d <- df
  if (yvar != y1919) {
    d <- d[!is.na(d[[yvar]]), , drop = FALSE]
    cat(sprintf("SAMPLE:%s:nonmissing_%s=%d\n", sname, yvar, nrow(d)))
  }
  d <- d[!is.na(d[[y1919]]), , drop = FALSE]
  cat(sprintf("SAMPLE:%s:nonmissing_socialist1919=%d\n", sname, nrow(d)))
  need_v <- unique(c(yvar, endog, inst, ctrls, clus, if (!is.na(prov)) prov))
  cc <- stats::complete.cases(d[, need_v, drop = FALSE])
  d <- d[cc, , drop = FALSE]
  cat(sprintf("SAMPLE:%s:complete_controls=%d\n", sname, nrow(d)))
  d$y_z <- zs(d[[yvar]])
  d$x_z <- zs(d[[inst]])
  if (!is.null(endog)) d$en_z <- zs(d[[endog]])
  d
}

fe_part <- if (!is.na(prov)) bt(prov) else "0"

# keep fixed-effect singletons, as Stata areg/ivreg2 with province dummies would
run_fs <- function(sname, ctrls) {
  d <- build_sample(sname, y1919, ctrls)
  rhs <- paste(c("x_z", bt(ctrls)), collapse = " + ")
  f <- as.formula(paste0("y_z ~ ", rhs, " | ", fe_part))
  m <- feols(f, data = d, cluster = as.formula(paste0("~", bt(clus))), fixef.rm = "none")
  cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nobs(m)))
  b <- coef(m)["x_z"]; s <- sqrt(diag(vcov(m)))["x_z"]
  list(b = unname(b), se = unname(s), F = unname((b / s)^2), n = nobs(m), g = length(unique(d[[clus]])))
}

run_iv <- function(sname, yvar, ctrls) {
  d <- build_sample(sname, yvar, ctrls, endog = y1919)
  rhs <- if (length(ctrls)) paste(bt(ctrls), collapse = " + ") else "1"
  f <- as.formula(paste0("y_z ~ ", rhs, " | ", fe_part, " | en_z ~ x_z"))
  m <- feols(f, data = d, cluster = as.formula(paste0("~", bt(clus))), fixef.rm = "none")
  cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nobs(m)))
  b <- coef(m)["fit_en_z"]; s <- sqrt(diag(vcov(m)))["fit_en_z"]
  list(b = unname(b), se = unname(s), n = nobs(m), g = length(unique(d[[clus]])))
}

fs1 <- run_fs("table1_col1", spec[[1]])
fs6 <- run_fs("table1_col6", spec[[6]])
ivv6 <- run_iv("table2_panelA_col6_violence", "fascist_violence", spec[[6]])
ivb6 <- run_iv("table2_panelC_col6_branches", "fascist_branch", spec[[6]])
iv21 <- run_iv("table3_panelA_col6_vote1921", "fascist1921_vv", spec[[6]])
iv24a <- run_iv("table3_panelC_col1_vote1924", "fascist1924_vv", spec[[1]])
iv24f <- run_iv("table3_panelC_col6_vote1924", "fascist1924_vv", spec[[6]])

if (fs1$n != 5775) cat(sprintf("DEVIATION: main sample has %d obs vs 5775 in paper\n", fs1$n))
if (iv21$n != 5358) cat(sprintf("DEVIATION: 1921 sample has %d obs vs 5358 in paper\n", iv21$n))

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", fs1$b))
cat(sprintf("RESULT:first_stage_casualties_table1_col1_se=%.6f\n", fs1$se))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", fs6$b))
cat(sprintf("RESULT:first_stage_casualties_table1_col6_se=%.6f\n", fs6$se))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", fs6$F))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", ivv6$b))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6_se=%.6f\n", ivv6$se))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", ivb6$b))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6_se=%.6f\n", ivb6$se))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", iv21$b))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6_se=%.6f\n", iv21$se))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", iv24a$b))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1_se=%.6f\n", iv24a$se))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", iv24f$b))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6_se=%.6f\n", iv24f$se))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", fs1$n))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", fs1$g))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", iv21$n))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", iv21$g))