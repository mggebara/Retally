suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free/fascism_db.dta"
raw <- haven::read_dta(path)

# collect variable labels for searching
labs <- vapply(raw, function(x) {
  l <- attr(x, "label")
  if (is.null(l)) "" else as.character(l)[1]
}, character(1))
df <- as.data.frame(haven::zap_labels(raw))
nm <- names(df)
names(labs) <- nm
msg <- function(...) message(paste0(...))

is_num <- function(v) is.numeric(df[[v]])
nuniq <- function(v) length(unique(df[[v]][!is.na(df[[v]])]))
is_bin <- function(v) is_num(v) && all(df[[v]][!is.na(df[[v]])] %in% c(0, 1))

find_cols <- function(name_pat = NULL, label_pat = NULL, exclude = NULL, numeric_only = TRUE) {
  hits <- character(0)
  if (!is.null(name_pat)) hits <- c(hits, nm[grepl(name_pat, nm, ignore.case = TRUE)])
  if (!is.null(label_pat)) hits <- c(hits, nm[grepl(label_pat, labs, ignore.case = TRUE)])
  hits <- unique(hits)
  if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
  if (numeric_only) hits <- hits[vapply(hits, is_num, logical(1))]
  hits
}
first_or_null <- function(x) if (length(x)) x[1] else NULL

# ---------------- core variables ----------------
y_viol <- "fascist_violence"
y_branch <- "fascist_branch"
y_f21 <- "fascist1921_vv"
y_f24 <- "fascist1924_vv"
endo <- "psu1919_vv"
inst <- "foots_pop6m"

# ---------------- cluster (administrative district, 181 in paper) ----------------
base_ok <- !is.na(df[[endo]]) & !is.na(df[[inst]])
clus_c <- unique(c(nm[grepl("circond|distr|circ", nm, ignore.case = TRUE)],
                   nm[grepl("circondario|district", labs, ignore.case = TRUE)]))
clus_c <- clus_c[!grepl("elect|coll", clus_c, ignore.case = TRUE)]
clus <- "circondario1921"
best_gap <- Inf
for (v in clus_c) {
  x <- df[[v]][base_ok]
  k <- length(unique(x[!is.na(x)]))
  gap <- abs(k - 181) + sum(is.na(x)) / 1e4
  msg("Cluster candidate: ", v, " k=", k, " nmiss=", sum(is.na(x)))
  if (k >= 100 && k <= 300 && gap < best_gap) { best_gap <- gap; clus <- v }
}
msg("Cluster var: ", clus)
# fill missing cluster ids with own unique id so observations are not dropped
if (any(is.na(df[[clus]]))) {
  cc <- as.character(df[[clus]])
  miss <- is.na(cc)
  cc[miss] <- paste0("solo__", which(miss))
  df$clus__ <- cc
  clus <- "clus__"
  cat('DEVIATION: Municipalities with missing district id treated as singleton clusters to keep full sample\n')
}

# ---------------- province ----------------
prov_c <- unique(c(nm[grepl("^prov|province|provincia", nm, ignore.case = TRUE)],
                   nm[grepl("^province|^provincia", labs, ignore.case = TRUE)]))
prov_c <- prov_c[!grepl("_d_|_d$|dummy", prov_c)]
prov <- NULL
for (v in prov_c) {
  k <- nuniq(v)
  if (k >= 40 && k <= 80) { prov <- v; break }
}
if (is.null(prov)) {
  for (v in prov_c) { k <- nuniq(v); if (k >= 20 && k <= 120) { prov <- v; break } }
}
msg("Province var: ", ifelse(is.null(prov), "NONE", prov))

# ---------------- regiment dummies ----------------
suffixed <- nm[grepl("[0-9]+$", nm)]
pref <- sub("_?[0-9]+$", "", suffixed)
groups <- split(suffixed, pref)
groups <- groups[vapply(groups, length, integer(1)) >= 15]
groups <- groups[!grepl("army_suppliers|prov|circ|distr|year|elect|psu|ppi|vv|pop|census|veteran|fascist",
                        names(groups), ignore.case = TRUE)]
groups <- lapply(groups, function(g) g[vapply(g, is_num, logical(1))])
groups <- groups[vapply(groups, length, integer(1)) >= 15]
reg_vars <- character(0)
if (length(groups)) {
  score <- vapply(names(groups), function(g) {
    s <- 0
    if (grepl("reg|rgt|rgm|reggim|fant|brig|inf|unit|corp", g, ignore.case = TRUE)) s <- s + 2
    if (mean(grepl("regiment|reggim|brigad|infantry|fanteria", labs[groups[[g]]], ignore.case = TRUE)) > 0.3) s <- s + 3
    vals <- unlist(df[groups[[g]]], use.names = FALSE)
    vals <- vals[!is.na(vals)]
    if (length(vals) && all(vals >= 0) && mean(vals == 0) > 0.5) s <- s + 1
    s
  }, numeric(1))
  msg("Suffix groups: ", paste(paste0(names(groups), "(", vapply(groups, length, integer(1)), ":", score, ")"), collapse = ","))
  if (max(score) > 0) {
    best <- names(groups)[which.max(score + vapply(groups, length, integer(1)) / 1e5)]
    reg_vars <- groups[[best]]
    msg("Regiment group: ", best, " (", length(reg_vars), " vars)")
  }
}
if (!length(reg_vars)) {
  reg_vars <- find_cols("regiment|^reg_|^rgt|^regg|^fant|^brig", "regiment|reggimento|brigad|fanteria",
                        exclude = "region")
  msg("Regiment vars by keyword: ", length(reg_vars))
}
reg_vars <- reg_vars[vapply(reg_vars, is_num, logical(1))]
reg_safe <- character(0)
if (length(reg_vars)) {
  R <- as.data.frame(lapply(df[reg_vars], function(x) as.numeric(!is.na(x) & x > 0)))
  keep <- vapply(R, function(x) { s <- sum(x); s > 0 && s < nrow(R) }, logical(1))
  R <- R[, keep, drop = FALSE]
  reg_safe <- paste0("regd__", seq_len(ncol(R)))
  names(R) <- reg_safe
  df <- cbind(df, R)
}
msg("Regiment dummies used: ", length(reg_safe))

# ---------------- demographic ----------------
lpop <- first_or_null(nm[grepl("^(l|ln|log)_?pop(_?19(21|11))?$", nm, ignore.case = TRUE)])
if (is.null(lpop)) {
  popv <- first_or_null(nm[grepl("^pop_?(19(21|11))?$|^population|^pop_?tot", nm, ignore.case = TRUE)])
  if (is.null(popv)) popv <- first_or_null(find_cols(NULL, "^(total )?population|^municipal(ity)? population",
                                                      exclude = "^sh_|pop6|share"))
  if (!is.null(popv)) {
    df$lpop__ <- log(pmax(df[[popv]], 1)); lpop <- "lpop__"
  }
}
demo <- character(0)
if (!is.null(lpop)) {
  df$lpop1__ <- df[[lpop]]; df$lpop2__ <- df[[lpop]]^2
  df$lpop3__ <- df[[lpop]]^3; df$lpop4__ <- df[[lpop]]^4
  demo <- c("lpop1__", "lpop2__", "lpop3__", "lpop4__")
}
msg("Log pop var: ", ifelse(is.null(lpop), "NONE", lpop))
demo <- c(demo, "sh_pop_1911_be6")

# ---------------- geographic ----------------
alt_main <- first_or_null(setdiff(find_cols("^alt|altitud|elev", "altitude|elevation",
                                            exclude = "max|min|range"), "max_alt"))
geo <- c("larea", alt_main, "max_alt")

# ---------------- military ----------------
assault <- find_cols("ardit|assault|volunt|volont", "assault|volunteer|arditi",
                     exclude = "_d$|dummy")
assault <- assault[!vapply(assault, is_bin, logical(1))]
pref_a <- assault[grepl("pop6m", assault)]
if (length(pref_a)) assault <- pref_a
assault <- head(assault, 2)
# paper: special-assault-troop PLUS volunteer casualties share (single combined control)
if (length(assault) == 2) {
  df$arditi_volunt__ <- rowSums(cbind(df[[assault[1]]], df[[assault[2]]]), na.rm = FALSE)
  assault <- "arditi_volunt__"
}
battle <- find_cols("battle|bloody|deadl|highmort|high_mort|bigbattle|cruent", "battle|highest.?mortality|1,?000 deaths")
battle_b <- battle[vapply(battle, is_bin, logical(1))]
battle <- first_or_null(if (length(battle_b)) battle_b else battle)
mil <- c("veterans74_95", "veterans96_00", assault, "army_suppliers_d", battle)

# ---------------- agricultural ----------------
sharecrop <- first_or_null(find_cols("mezzadr|sharecrop|share_crop|sharecr|mezz|^shcrop|^scrop", "sharecrop|mezzadr"))
landown <- find_cols("agrar|landown|landlord|ass_agr|proprietar", "landowner|agrarian|agrari")
landown_b <- landown[vapply(landown, is_bin, logical(1))]
landown <- first_or_null(if (length(landown_b)) landown_b else landown)
agri <- c("dlab", sharecrop, landown)

# ---------------- urban ----------------
urb <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")

msg("Geo: ", paste(geo, collapse = ","))
msg("Mil: ", paste(mil, collapse = ","))
msg("Agri: ", paste(agri, collapse = ","))

clean <- function(v) unique(v[!is.null(v) & v %in% names(df)])
demo <- clean(demo); geo <- clean(geo); mil <- clean(mil); agri <- clean(agri); urb <- clean(urb)
s13 <- clean("psu1913_vv")

# impute missing controls with mean + missing indicator to keep the full sample
all_ctrl <- unique(c(demo, geo, s13, mil, agri, urb))
add_miss <- list()
for (v in all_ctrl) {
  x <- df[[v]]
  if (any(is.na(x))) {
    mi <- paste0("miss__", v)
    df[[mi]] <- as.numeric(is.na(x))
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    df[[v]] <- x
    add_miss[[v]] <- mi
  }
}
withmiss <- function(vs) unique(c(vs, unlist(add_miss[intersect(vs, names(add_miss))])))

# standardize LHS, endogenous and instrument (and continuous controls)
zs <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
for (v in c(y_viol, y_branch, y_f21, y_f24, endo, inst)) {
  if (v %in% names(df)) df[[paste0("z_", v)]] <- zs(as.numeric(df[[v]]))
}
for (v in all_ctrl) df[[v]] <- zs(df[[v]])
for (v in all_ctrl) if (all(is.na(df[[v]]))) df[[v]] <- 0

ctrl_sets <- list(
  c1 = c(reg_safe, withmiss(demo)),
  c6 = c(reg_safe, withmiss(c(demo, geo, s13, mil, agri, urb)))
)

fe_part <- if (!is.null(prov)) paste0(" | ", prov) else ""
mk_rhs <- function(ctrl) if (length(ctrl)) paste(ctrl, collapse = " + ") else "1"
cl <- as.formula(paste0("~", clus))

fs <- function(ctrl) {
  f <- as.formula(paste0("z_", endo, " ~ z_", inst, " + ", mk_rhs(ctrl), fe_part))
  feols(f, data = df, cluster = cl, notes = FALSE, warn = FALSE)
}
iv <- function(y, ctrl) {
  f <- as.formula(paste0("z_", y, " ~ ", mk_rhs(ctrl), fe_part,
                         " | z_", endo, " ~ z_", inst))
  feols(f, data = df, cluster = cl, notes = FALSE, warn = FALSE)
}
getb <- function(m, v) unname(coef(m)[v])
gets <- function(m, v) unname(sqrt(diag(vcov(m)))[v])
ncl <- function(m) {
  idx <- obs(m)
  length(unique(df[[clus]][idx]))
}

out <- list()
safe <- function(expr) tryCatch(expr, error = function(e) { msg("ERROR: ", conditionMessage(e)); NULL })

m1 <- safe(fs(ctrl_sets$c1))
if (!is.null(m1)) {
  out$first_stage_casualties_table1_col1 <- getb(m1, paste0("z_", inst))
  out$first_stage_casualties_table1_col1_se <- gets(m1, paste0("z_", inst))
  out$n_obs_main_sample <- nobs(m1)
  out$n_clusters_main_sample <- ncl(m1)
}
m6 <- safe(fs(ctrl_sets$c6))
if (!is.null(m6)) {
  b <- getb(m6, paste0("z_", inst)); s <- gets(m6, paste0("z_", inst))
  out$first_stage_casualties_table1_col6 <- b
  out$first_stage_casualties_table1_col6_se <- s
  out$first_stage_fstat_table1_col6 <- (b / s)^2
}

v6 <- safe(iv(y_viol, ctrl_sets$c6))
if (!is.null(v6)) {
  out$iv_violence_table2_panelA_col6 <- getb(v6, paste0("fit_z_", endo))
  out$iv_violence_table2_panelA_col6_se <- gets(v6, paste0("fit_z_", endo))
}
b6 <- safe(iv(y_branch, ctrl_sets$c6))
if (!is.null(b6)) {
  out$iv_branches_table2_panelC_col6 <- getb(b6, paste0("fit_z_", endo))
  out$iv_branches_table2_panelC_col6_se <- gets(b6, paste0("fit_z_", endo))
}
f21 <- safe(iv(y_f21, ctrl_sets$c6))
if (!is.null(f21)) {
  out$iv_fascist_vote1921_table3_panelA_col6 <- getb(f21, paste0("fit_z_", endo))
  out$iv_fascist_vote1921_table3_panelA_col6_se <- gets(f21, paste0("fit_z_", endo))
  out$n_obs_fascist_vote1921 <- nobs(f21)
  out$n_clusters_fascist_vote1921 <- ncl(f21)
}
f24a <- safe(iv(y_f24, ctrl_sets$c1))
if (!is.null(f24a)) {
  out$iv_fascist_vote1924_table3_panelC_col1 <- getb(f24a, paste0("fit_z_", endo))
  out$iv_fascist_vote1924_table3_panelC_col1_se <- gets(f24a, paste0("fit_z_", endo))
}
f24 <- safe(iv(y_f24, ctrl_sets$c6))
if (!is.null(f24)) {
  out$iv_fascist_vote1924_table3_panelC_col6 <- getb(f24, paste0("fit_z_", endo))
  out$iv_fascist_vote1924_table3_panelC_col6_se <- gets(f24, paste0("fit_z_", endo))
}

for (k in names(out)) {
  val <- out[[k]]
  if (length(val) == 1 && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", k, val))
}
