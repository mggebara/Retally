suppressPackageStartupMessages({
  library(haven)
  library(readr)
  library(dplyr)
  library(fixest)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation.script-free"

emit <- function(name, value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) return(invisible(NULL))
  cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(value)))
}

to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

# Build player-type dummies HC, AI, R with M (mayor's office) as reference
make_type_dummies <- function(x) {
  lab <- NULL
  if (inherits(x, "haven_labelled")) {
    lab <- as.character(as_factor(x, levels = "labels"))
  } else {
    lab <- as.character(x)
  }
  u <- toupper(trimws(lab))
  out <- data.frame(
    HC = as.integer(grepl("^HC$|HEALTH|CENTRO|^CS$|MEDIC|ENFER|DOCTOR|NURSE", u)),
    AI = as.integer(grepl("^AI$|INTERMED|ADMIN|GESTOR", u)),
    R  = as.integer(grepl("^R$|REGION", u))
  )
  # If nothing matched, try numeric codes via factor with the most M-like level as reference
  if (sum(out$HC) == 0 && sum(out$AI) == 0 && sum(out$R) == 0) {
    f <- factor(u)
    lv <- levels(f)
    ref <- lv[grepl("^M$|MAYOR|ALCAL|MUNI", lv)]
    if (length(ref) == 0) ref <- lv[1]
    f <- relevel(f, ref = ref[1])
    mm <- model.matrix(~ f)[, -1, drop = FALSE]
    colnames(mm) <- paste0("ptype_", make.names(levels(f)[-1]))
    out <- as.data.frame(mm)
  }
  out[is.na(u), ] <- NA
  out
}

# =================== Table 2: public goods game ===================
pgg <- read_dta(file.path(base_dir, "publicgoodgame_dataAug27.dta"))

ptype_src <- if ("player_type" %in% names(pgg)) pgg$player_type else pgg$p_type
pt <- make_type_dummies(ptype_src)
# if player_type is uninformative, try p_type
if (ncol(pt) == 3 && sum(colSums(pt, na.rm = TRUE)) == 0 && "p_type" %in% names(pgg)) {
  pt <- make_type_dummies(pgg$p_type)
}
type_vars <- names(pt)

d2 <- data.frame(
  contribution = to_num(pgg$contribution),
  decentralized = to_num(pgg$decentralized),
  communication = to_num(pgg$communication),
  round = to_num(pgg$round),
  lag_groupcontribution = to_num(pgg$lag_groupcontribution),
  num_players = to_num(pgg$num_players),
  knownpeople = to_num(pgg$knownpeople),
  female = to_num(pgg$Q2_female),
  age = to_num(pgg$Q1_Edad),
  educ = to_num(pgg$Q2_Educacion),
  yrs_health = to_num(pgg$Q3_YrsSalud),
  trust = to_num(pgg$Q5_Trust1Base),
  w = to_num(pgg$weights_games_full_scaled),
  muni = pgg$publicid_muni,
  pid = pgg$publicid
)
d2 <- cbind(d2, pt)
# communication dummy fallback from round
if (all(is.na(d2$communication))) d2$communication <- as.integer(d2$round >= 6)
d2$dec_comm <- d2$decentralized * d2$communication

rhs_ctrl <- c("communication", type_vars, "round", "lag_groupcontribution",
              "num_players", "knownpeople", "female", "age", "educ",
              "yrs_health", "trust")
needed <- c("contribution", "decentralized", rhs_ctrl, "w", "dec_comm")
d2c <- d2[complete.cases(d2[, needed]), ]

f1 <- as.formula(paste("contribution ~ decentralized +", paste(rhs_ctrl, collapse = " + ")))
f2 <- as.formula(paste("contribution ~ decentralized + dec_comm +", paste(rhs_ctrl, collapse = " + ")))

m1 <- tryCatch(feols(f1, data = d2c, weights = ~w, cluster = ~muni), error = function(e) NULL)
m2 <- tryCatch(feols(f2, data = d2c, weights = ~w, cluster = ~muni), error = function(e) NULL)
if (is.null(m1)) m1 <- lm(f1, data = d2c, weights = w)
if (is.null(m2)) m2 <- lm(f2, data = d2c, weights = w)

emit("decentralized_table2_col1", coef(m1)["decentralized"])
emit("communication_table2_col1", coef(m1)["communication"])
emit("decentralized_table2_col2", coef(m2)["decentralized"])
emit("communication_table2_col2", coef(m2)["communication"])
emit("decentralized_x_communication_table2_col2", coef(m2)["dec_comm"])
emit("n_obs_table2", nobs(m1))

# =================== Table 3: cross-level ties ===================
tab3 <- tryCatch({
  cl <- read_csv(file.path(base_dir, "clanalysis_anondata_vNov16.csv"), show_col_types = FALSE)
  nm <- names(cl)
  message("clanalysis columns: ", paste(nm, collapse = ", "))

  cl$w <- to_num(cl$weights_games_full_scaled)

  # Precomputed cross-level tie counts (numerators) and possible cross-level ties (denominators)
  pick <- function(a, b) {
    va <- if (a %in% nm) to_num(cl[[a]]) else NULL
    if (!is.null(va) && length(unique(na.omit(va))) > 1) return(va)
    if (b %in% nm) return(to_num(cl[[b]]))
    va
  }
  cl$y_all   <- pick("net_crosslevel_propnumknown",     "net_crosslevel_propnumknown_col")
  cl$tot_all <- pick("net_crosslevel_propdenomknown",   "net_crosslevel_propdenomknown_col")
  cl$y_str   <- pick("net_crosslevel_propnumfriends",   "net_crosslevel_propnumfriends_col")
  cl$tot_str <- pick("net_crosslevel_propdenomfriends", "net_crosslevel_propdenomfriends_col")
  for (v in c("y_all", "tot_all", "y_str", "tot_str")) {
    message(v, ": n_nonmiss=", sum(!is.na(cl[[v]])), " mean=", round(mean(cl[[v]], na.rm = TRUE), 3))
  }

  cl$decentralized <- to_num(cl$decentralized)
  cl$female <- to_num(cl$Mujer)
  cl$educ <- to_num(cl$Q2_Educacion)
  cl$age <- to_num(cl$Q1_Edad)
  cl$yrs_health <- to_num(cl$Q3_YrsSalud)
  cl$trust <- to_num(cl$gen_trust)
  ptc <- make_type_dummies(cl$ParticipantType)
  tv3 <- names(ptc)
  cl <- cbind(as.data.frame(cl), ptc)
  cl$muni <- cl$publicid_muni

  run_pois <- function(y, tot, ctrls) {
    dd <- cl
    dd$yy <- dd[[y]]; dd$off <- suppressWarnings(log(dd[[tot]]))
    vars <- c("yy", "off", "decentralized", "w", ctrls)
    dd <- dd[complete.cases(dd[, vars]) & is.finite(dd$off), ]
    fm <- as.formula(paste("yy ~", paste(c("decentralized", ctrls), collapse = " + ")))
    m <- fepois(fm, data = dd, offset = ~off, weights = ~w, cluster = ~muni)
    list(b = coef(m)["decentralized"], n = nobs(m))
  }
  full_ctrl <- c("female", "educ", "age", "yrs_health", "trust", tv3)
  safe <- function(...) tryCatch(run_pois(...), error = function(e) {
    message("Table 3 model error: ", conditionMessage(e)); list(b = NA, n = NA) })
  list(
    ab = safe("y_all", "tot_all", character(0)),
    af = safe("y_all", "tot_all", full_ctrl),
    sb = safe("y_str", "tot_str", character(0)),
    sf = safe("y_str", "tot_str", full_ctrl)
  )
}, error = function(e) { message("Table 3 error: ", conditionMessage(e)); NULL })

if (!is.null(tab3)) {
  emit("decentralized_table3_allties_base", tab3$ab$b)
  emit("decentralized_table3_allties_full", tab3$af$b)
  emit("decentralized_table3_strongties_base", tab3$sb$b)
  emit("decentralized_table3_strongties_full", tab3$sf$b)
  emit("n_obs_table3_base", tab3$ab$n)
  emit("n_obs_table3_full", tab3$af$n)
}
