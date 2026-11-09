suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/acemoglu_2022_war_socialism_fascism.script-free/fascism_db.dta"
df <- as.data.frame(haven::zap_labels(haven::read_dta(path)))
nms <- names(df)
cat("Loaded", nrow(df), "rows,", ncol(df), "cols\n")

# ---------- diagnostics: show column names so missing controls can be located ----------
nonz <- nms[!grepl("^z_", nms)]
cat("Non-z column names (first 400):\n", paste(head(nonz, 400), collapse = " "), "\n")
diag_pat <- c("vet", "alt", "elev", "quota", "battl", "1000", "mort", "deadl", "sharec", "mezz", "colon",
              "agr", "landown", "assoc", "ass_", "reg", "rgt", "brig", "fant", "inf")
for (p in diag_pat) {
  h <- grep(p, nonz, value = TRUE, ignore.case = TRUE)
  cat("[diag]", p, "(", length(h), "):", paste(head(h, 25), collapse = ","), "\n")
}

# ---------- helpers ----------
find_var <- function(exact = character(0), patterns = character(0), exclude = NULL, required = FALSE, label = "") {
  for (e in exact) if (e %in% nms) { cat("[var]", label, "->", e, "\n"); return(e) }
  for (p in patterns) {
    hits <- grep(p, nms, value = TRUE, ignore.case = TRUE)
    hits <- hits[!grepl("^z_", hits)]
    if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
    hits <- hits[vapply(hits, function(v) is.numeric(df[[v]]), logical(1))]
    if (length(hits) > 0) {
      hits <- hits[order(nchar(hits))]
      cat("[var]", label, "->", hits[1], " (candidates:", paste(head(hits, 6), collapse = ","), ")\n")
      return(hits[1])
    }
  }
  cat("[var]", label, "-> NOT FOUND\n")
  if (required) stop(paste("Required variable not found:", label))
  NULL
}
is_num <- function(v) is.numeric(df[[v]])

# ---------- core variables ----------
y_endog <- find_var(c("psu1919_vv"), label = "socialist 1919", required = TRUE)
instr   <- find_var(c("foots_pop6m"), label = "foot soldier casualties", required = TRUE)
clus    <- find_var(c("circondario1921"), c("^circond"), label = "district", required = TRUE)
prov    <- find_var(c("provincia1921", "province1921", "prov1921", "province", "provincia", "prov", "id_prov", "prov_id", "cod_prov"),
                    c("^prov", "provinc"), exclude = "share|_vv|pop", label = "province")
y_viol  <- find_var(c("fascist_violence"), label = "fascist violence")
y_branch<- find_var(c("fascist_branch"), label = "fascist branch")
y_f21   <- find_var(c("fascist1921_vv"), label = "fascist 1921")
y_f24   <- find_var(c("fascist1924_vv"), label = "fascist 1924")

if (is.null(prov)) {
  cat("Province not found; using district clusters as FE fallback\n")
  prov <- clus
}

# ---------- demographic controls ----------
popv <- find_var(c("lpop1911", "log_pop1911", "lnpop1911", "lpop_1911", "ln_pop1911", "pop1911", "pop_1911", "population1911", "pop11"),
                 c("^l?n?_?pop_?1911$", "pop.*1911", "1911.*pop"), exclude = "sh_|share|be6|_6|6m|jew|male", label = "population 1911")
if (!is.null(popv)) {
  lp <- df[[popv]]
  if (!grepl("^l", popv) || max(lp, na.rm = TRUE) > 50) lp <- log(pmax(lp, 1))
  df$lp1 <- lp; df$lp2 <- lp^2; df$lp3 <- lp^3; df$lp4 <- lp^4
  demo <- c("lp1", "lp2", "lp3", "lp4")
} else demo <- character(0)
under6 <- find_var(c("sh_pop_1911_be6"), label = "share under 6")
demo <- c(demo, under6)

# ---------- geographic ----------
geo <- c(find_var(c("larea", "log_area"), label = "log area"),
         find_var(c("alt", "altitude", "elevation", "alt_center", "altitudine", "min_alt", "alt_cent", "alt_centro", "quota"),
                  c("alt", "elev", "quota", "height"), exclude = "max|vol|alter", label = "elevation center"),
         find_var(c("max_alt"), label = "max elevation"))

# ---------- socialist 1913 ----------
soc13 <- find_var(c("psu1913_vv"), label = "socialist 1913")

# ---------- military ----------
vet <- grep("vet", nms, value = TRUE, ignore.case = TRUE)
vet <- vet[!grepl("^z_", vet)]
vet <- vet[vapply(vet, is_num, logical(1))]
cat("[var] veterans candidates ->", paste(vet, collapse = ","), "\n")
# prefer variables expressed per male pop above 6, two cohorts
vet_pref <- vet[grepl("pop6m|pop|sh", vet, ignore.case = TRUE)]
if (length(vet_pref) >= 1) vet <- vet_pref
vet <- head(vet[order(nchar(vet))], 2)
cat("[var] veterans used ->", paste(vet, collapse = ","), "\n")
arditi <- find_var(c("arditi_pop6m", "assault_pop6m", "ardvol_pop6m", "arditi_vol_pop6m"),
                   c("ardit", "assault"), label = "assault troops")
volunt <- find_var(c("volunt_pop6m", "volunteers_pop6m", "volontari_pop6m", "vol_pop6m"),
                   c("volunt.*pop6m", "volont"), exclude = "1866", label = "volunteers")
armys  <- find_var(c("army_suppliers_d"), label = "army suppliers")
battle <- find_var(c("battles_d", "big_battles_d", "bigbattle_d", "battle_d", "high_mort_d", "deadly_battles_d"),
                   c("battl", "batt", "deadl", "1000", "bigday", "big_d"), label = "high-mortality battles")
mil <- unique(c(vet, arditi, volunt, armys, battle))

# ---------- agricultural ----------
agr <- c(find_var(c("dlab", "day_laborers"), label = "day laborers"),
         find_var(c("sharecroppers", "sharecr", "mezzadri", "sharecrop", "scrop", "colons"),
                  c("sharec", "mezzad", "share_crop", "scrop", "colon"), label = "sharecroppers"),
         find_var(c("agr_ass", "agrarian_ass", "landowner_ass", "agrarian_d", "agr_assoc_d", "assagr_d", "landowners_d", "agrarian"),
                  c("agrar", "landown", "agr_ass", "assagr", "agr_assoc", "ass_agr", "landlord"), label = "landowner association"))

# ---------- urban ----------
urb <- c(find_var(c("ind_workers"), label = "industrial workers"),
         find_var(c("ind_firms"), label = "industrial firms"),
         find_var(c("literacy"), label = "literacy"),
         find_var(c("elites"), label = "elites"),
         find_var(c("bourgeoisie"), label = "bourgeoisie"))

# ---------- regiment dummies (generic detection of numbered binary groups) ----------
used <- unique(c(y_endog, instr, clus, prov, demo, geo, soc13, mil, agr, urb))
isbin <- function(v) { x <- df[[v]]; if (!is.numeric(x)) return(FALSE); u <- unique(x[!is.na(x)]); length(u) <= 2 && all(u %in% c(0, 1)) }
cand <- nms[grepl("[0-9]", nms) & !grepl("^z_", nms)]
key <- gsub("[0-9]+", "#", cand)
tab <- sort(table(key), decreasing = TRUE)
tab <- tab[tab >= 20]
cat("[diag] numbered column groups (>=20):\n")
for (k in names(tab)) cat("   ", k, ":", tab[[k]], "\n")
regs <- character(0)
grp_ok <- names(tab)[!grepl("prov|circ|year|elect|army_suppl|_vv|pop|vote|psu|fasc|1911|1921|1919|1924|1913", names(tab), ignore.case = TRUE)]
# prefer groups whose name suggests regiments/brigades
pri <- grp_ok[grepl("reg|rgt|rgm|brig|fant|inf|unit", grp_ok, ignore.case = TRUE) & !grepl("region", grp_ok, ignore.case = TRUE)]
order_try <- c(pri, setdiff(grp_ok, pri))
for (k in order_try) {
  cols <- cand[key == k]
  b <- cols[vapply(cols, isbin, logical(1))]
  if (length(b) >= 20 && length(b) >= 0.8 * length(cols)) {
    regs <- b
    cat("[var] regiment dummies group:", k, "n =", length(regs), "\n")
    break
  }
}
if (length(regs) == 0) cat("[var] regiment dummies NOT FOUND\n")
regs <- setdiff(regs, used)
regs <- regs[vapply(regs, function(v) { x <- df[[v]]; s <- sd(x, na.rm = TRUE); !is.na(s) && s > 0 }, logical(1))]

# ---------- control sets ----------
c1 <- c(regs, demo)
c2 <- c(c1, geo)
c3 <- c(c2, soc13)
c4 <- c(c3, mil)
c5 <- c(c4, agr)
c6 <- c(c5, urb)
ctrl_sets <- list(c1, c2, c3, c4, c5, c6)
ctrl_sets <- lapply(ctrl_sets, function(x) unique(x[!is.null(x) & !is.na(x)]))
c1 <- ctrl_sets[[1]]; c6 <- ctrl_sets[[6]]

bt <- function(v) paste0("`", v, "`")
rhs_str <- function(ctrls) if (length(ctrls) == 0) "1" else paste(bt(ctrls), collapse = " + ")

df$.prov <- df[[prov]]
df$.clus <- df[[clus]]

fit_fs <- function(ctrls) {
  f <- as.formula(paste(bt(y_endog), "~", bt(instr), "+", rhs_str(ctrls), "| .prov"))
  m <- feols(f, data = df, cluster = ~.clus, warn = FALSE, notes = FALSE)
  idx <- obs(m)
  b <- coef(m)[instr]; se <- se(m)[instr]
  sx <- sd(df[[instr]][idx]); sy <- sd(df[[y_endog]][idx])
  list(m = m, b_std = unname(b * sx / sy), se_std = unname(se * sx / sy), F = unname((b / se)^2),
       n = length(idx), ncl = length(unique(df$.clus[idx])), r2 = unname(r2(m, "r2")))
}

fit_iv <- function(y, ctrls) {
  f <- as.formula(paste(bt(y), "~", rhs_str(ctrls), "| .prov |", bt(y_endog), "~", bt(instr)))
  m <- feols(f, data = df, cluster = ~.clus, warn = FALSE, notes = FALSE)
  idx <- obs(m)
  nm <- paste0("fit_", y_endog)
  b <- coef(m)[nm]; se <- se(m)[nm]
  sx <- sd(df[[y_endog]][idx]); sy <- sd(df[[y]][idx])
  list(m = m, b_std = unname(b * sx / sy), se_std = unname(se * sx / sy),
       n = length(idx), ncl = length(unique(df$.clus[idx])))
}

safe <- function(expr) tryCatch(expr, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL })

fs <- lapply(1:6, function(k) safe(fit_fs(ctrl_sets[[k]])))
for (k in 1:6) if (!is.null(fs[[k]]))
  cat(sprintf("First stage col %d: b_std=%.4f se=%.4f F=%.2f R2=%.3f N=%d clusters=%d nctrl=%d\n",
              k, fs[[k]]$b_std, fs[[k]]$se_std, fs[[k]]$F, fs[[k]]$r2, fs[[k]]$n, fs[[k]]$ncl, length(ctrl_sets[[k]])))

iv_viol6   <- if (!is.null(y_viol))   safe(fit_iv(y_viol, c6)) else NULL
iv_branch6 <- if (!is.null(y_branch)) safe(fit_iv(y_branch, c6)) else NULL
iv_f21_6   <- if (!is.null(y_f21))    safe(fit_iv(y_f21, c6)) else NULL
iv_f24_1   <- if (!is.null(y_f24))    safe(fit_iv(y_f24, c1)) else NULL
iv_f24_6   <- if (!is.null(y_f24))    safe(fit_iv(y_f24, c6)) else NULL

pr <- function(lbl, r) if (!is.null(r)) cat(sprintf("%s: b_std=%.4f se=%.4f N=%d clusters=%d\n", lbl, r$b_std, r$se_std, r$n, r$ncl))
pr("IV violence col6", iv_viol6)
pr("IV branch col6", iv_branch6)
pr("IV fascist 1921 col6", iv_f21_6)
pr("IV fascist 1924 col1", iv_f24_1)
pr("IV fascist 1924 col6", iv_f24_6)

out <- function(name, val) if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
out("first_stage_casualties_table1_col1", fs[[1]]$b_std)
out("first_stage_casualties_table1_col6", fs[[6]]$b_std)
out("first_stage_fstat_table1_col6", fs[[6]]$F)
out("iv_violence_table2_panelA_col6", iv_viol6$b_std)
out("iv_branches_table2_panelC_col6", iv_branch6$b_std)
out("iv_fascist_vote1921_table3_panelA_col6", iv_f21_6$b_std)
out("iv_fascist_vote1924_table3_panelC_col1", iv_f24_1$b_std)
out("iv_fascist_vote1924_table3_panelC_col6", iv_f24_6$b_std)
out("n_obs_main_sample", fs[[1]]$n)
out("n_clusters_main_sample", fs[[1]]$ncl)
out("n_obs_fascist_vote1921", iv_f21_6$n)
out("n_clusters_fascist_vote1921", iv_f21_6$ncl)
