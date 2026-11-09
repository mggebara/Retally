suppressPackageStartupMessages({
  library(haven)
  library(readr)
  library(dplyr)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation.script-free"

emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v)) v <- NA
  cat(sprintf("RESULT:%s=%s\n", name, ifelse(is.na(v), "NA", format(v, digits = 8))))
}

num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  suppressWarnings(as.numeric(as.character(x)))
}

# ---------------------------------------------------------------
# Table 2: public goods game
# ---------------------------------------------------------------
pg <- read_dta(file.path(base, "publicgoodgame_dataAug27.dta"))
cat("PGG columns:", paste(names(pg), collapse = ", "), "\n")

pt_raw <- pg$player_type
if (inherits(pt_raw, "haven_labelled")) {
  pt <- as.character(as_factor(pt_raw, levels = "labels"))
} else {
  pt <- as.character(pt_raw)
}
if (all(is.na(pt)) && "p_type" %in% names(pg)) {
  pt <- as.character(as_factor(pg$p_type))
}

# p_type holds the organisational level: C = health centre, A = administrative
# intermediary, R = region, G = municipal government (mayor's office, reference)
if ("p_type" %in% names(pg)) {
  ptl <- toupper(trimws(as.character(as_factor(pg$p_type))))
} else {
  ptl <- toupper(substr(trimws(pt), 1, 1))
}
ptl[ptl == ""] <- NA
pt <- ptl
lv <- unique(na.omit(pt))
find_level <- function(patterns) {
  for (p in patterns) {
    hit <- lv[grepl(p, lv, ignore.case = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}
lev_HC <- find_level(c("^C$", "^HC$", "health ?cent", "centro", "^HC"))
lev_AI <- find_level(c("^A$", "^AI$", "admin", "intermed", "^AI"))
lev_R  <- find_level(c("^R$", "region", "^R"))
lev_M  <- find_level(c("^G$", "^M$", "mayor", "alcal", "munic", "^M"))
cat("Levels: HC=", lev_HC, " AI=", lev_AI, " R=", lev_R, " M=", lev_M, "\n")

d <- data.frame(
  contribution = num(pg$contribution),
  decentralized = num(pg$decentralized),
  communication = num(pg$communication),
  round = num(pg$round),
  lag_gc = num(pg$lag_groupcontribution),
  num_players = num(pg$num_players),
  knownpeople = num(pg$knownpeople),
  female = num(pg$Q2_female),
  age = num(pg$Q1_Edad),
  educ = num(pg$Q2_Educacion),
  yrs_health = num(pg$Q3_YrsSalud),
  trust = num(pg$Q5_Trust1Base),
  w = num(pg$weights_games_full_scaled),
  muni = num(pg$publicid_muni),
  pid = num(pg$publicid)
)
d$HC <- as.numeric(!is.na(pt) & !is.na(lev_HC) & pt == lev_HC)
d$AI <- as.numeric(!is.na(pt) & !is.na(lev_AI) & pt == lev_AI)
d$R  <- as.numeric(!is.na(pt) & !is.na(lev_R) & pt == lev_R)
d$HC[is.na(pt)] <- NA; d$AI[is.na(pt)] <- NA; d$R[is.na(pt)] <- NA

vars2 <- c("contribution", "decentralized", "communication", "HC", "AI", "R", "round",
           "lag_gc", "num_players", "knownpeople", "female", "age", "educ",
           "yrs_health", "trust", "w")
dd <- d[complete.cases(d[, vars2]), ]
cat("Table 2 N:", nrow(dd), "\n")

f1 <- contribution ~ decentralized + communication + HC + AI + R + round + lag_gc +
  num_players + knownpeople + female + age + educ + yrs_health + trust
f2 <- contribution ~ decentralized * communication + HC + AI + R + round + lag_gc +
  num_players + knownpeople + female + age + educ + yrs_health + trust

m1 <- lm(f1, data = dd, weights = w)
m2 <- lm(f2, data = dd, weights = w)
v1 <- vcovCL(m1, cluster = ~muni)
v2 <- vcovCL(m2, cluster = ~muni)
print(coeftest(m1, vcov. = v1))
print(coeftest(m2, vcov. = v2))
cat("R2:", summary(m1)$r.squared, summary(m2)$r.squared, " AIC:", AIC(m1), AIC(m2), "\n")

ix <- grep("decentralized:communication|communication:decentralized", names(coef(m2)), value = TRUE)[1]

# ---------------------------------------------------------------
# Table 3: cross-level ties (weighted Poisson with offset)
# ---------------------------------------------------------------
res3 <- list(ab = NA, af = NA, sb = NA, sf = NA, nb = NA, nf = NA)
try({
  cl <- read_csv(file.path(base, "clanalysis_anondata_vNov16.csv"), show_col_types = FALSE)
  nm <- names(cl)
  cat("CL columns:\n"); print(nm)

  cn <- nm[grepl("cross", nm, ignore.case = TRUE)]
  cat("Cross-level columns:\n"); print(cn)
  for (cc in cn) {
    x <- num(cl[[cc]])
    cat(sprintf("  %s: mean=%.4f min=%s max=%s nNA=%d\n", cc, mean(x, na.rm = TRUE),
                min(x, na.rm = TRUE), max(x, na.rm = TRUE), sum(is.na(x))))
  }

  # Realized cross-level tie counts (not proportions, not collapsed versions)
  pick_count <- function(key) {
    c1 <- cn[grepl(key, cn, ignore.case = TRUE) &
             !grepl("prop|_col$|poss|total|max", cn, ignore.case = TRUE)]
    if (length(c1) == 0) return(NA_character_)
    pref <- c1[grepl("num", c1, ignore.case = TRUE)]
    if (length(pref)) return(pref[1])
    pref <- c1[!grepl("hours", c1, ignore.case = TRUE)]
    if (length(pref)) return(pref[1])
    c1[1]
  }
  pick_prop <- function(key) {
    c1 <- cn[grepl(key, cn, ignore.case = TRUE) & grepl("prop", cn, ignore.case = TRUE) &
             !grepl("_col$", cn, ignore.case = TRUE)]
    if (length(c1) == 0) NA_character_ else c1[1]
  }
  y_all <- pick_count("known|know|colleag")
  y_str <- pick_count("friend|strong|amig")
  p_all <- pick_prop("known|know|colleag")
  p_str <- pick_prop("friend|strong|amig")
  e_col <- cn[grepl("poss|total|max", cn, ignore.case = TRUE) &
              !grepl("prop|_col$", cn, ignore.case = TRUE)]
  e_col <- if (length(e_col)) e_col[1] else NA_character_
  wcol <- if ("weights_games_full_scaled" %in% nm) "weights_games_full_scaled" else {
    ww <- nm[grepl("weight", nm, ignore.case = TRUE) & !grepl("reduced", nm, ignore.case = TRUE)]
    if (length(ww)) ww[1] else NA_character_
  }
  cat("Chosen: y_all=", y_all, " y_str=", y_str, " p_all=", p_all, " p_str=", p_str,
      " e_col=", e_col, " w=", wcol, "\n")

  # Player type in CL data
  ptc <- toupper(substr(trimws(as.character(cl$ParticipantType)), 1, 1))
  ptc[ptc == ""] <- NA
  cat("ParticipantType table:\n"); print(table(ptc, useNA = "ifany"))

  # Possible cross-level ties: other workshop participants at a different level
  muni_cl <- num(cl$publicid_muni)
  ex <- sapply(seq_len(nrow(cl)), function(i) {
    same <- which(muni_cl == muni_cl[i] & seq_len(nrow(cl)) != i)
    sum(ptc[same] != ptc[i], na.rm = TRUE)
  })

  yA <- num(cl[[y_all]]); yS <- num(cl[[y_str]])
  # Exposure: explicit column if present; else count / proportion; else roster-based
  expo <- rep(NA_real_, nrow(cl))
  if (!is.na(e_col)) expo <- num(cl[[e_col]])
  if (!is.na(p_all)) {
    pa <- num(cl[[p_all]])
    r <- ifelse(!is.na(pa) & pa > 0, yA / pa, NA)
    expo <- ifelse(is.na(expo), r, expo)
  }
  if (!is.na(p_str)) {
    ps <- num(cl[[p_str]])
    r <- ifelse(!is.na(ps) & ps > 0, yS / ps, NA)
    expo <- ifelse(is.na(expo), r, expo)
  }
  cat("Exposure from data vs roster (non-missing):", sum(!is.na(expo)), "\n")
  if (sum(!is.na(expo)) > 2) cat("cor(data exposure, roster exposure):",
                                  cor(expo, ex, use = "complete.obs"), "\n")
  expo <- ifelse(is.na(expo), ex, expo)

  t3 <- data.frame(
    yA = yA, yS = yS, e = expo,
    decentralized = num(cl$decentralized),
    female = num(cl$Mujer), educ = num(cl$Q2_Educacion), age = num(cl$Q1_Edad),
    yrs_health = num(cl$Q3_YrsSalud), trust = num(cl$gen_trust),
    muni = muni_cl
  )
  t3$HC <- as.numeric(ptc %in% "C")
  t3$AI <- as.numeric(ptc %in% "A")
  t3$R  <- as.numeric(ptc %in% "R")
  t3$HC[is.na(ptc)] <- NA; t3$AI[is.na(ptc)] <- NA; t3$R[is.na(ptc)] <- NA

  if (!is.na(wcol)) {
    t3$w <- num(cl[[wcol]])
  } else {
    mw <- d %>% group_by(muni) %>% summarise(w = mean(w, na.rm = TRUE), .groups = "drop")
    t3 <- left_join(t3, mw, by = "muni")
  }

  fitp <- function(y, full) {
    dat <- t3
    dat$y <- dat[[y]]
    rhs <- if (full) "decentralized + female + educ + age + yrs_health + trust + HC + AI + R" else "decentralized"
    vv <- c("y", "e", "w", "decentralized")
    if (full) vv <- c(vv, "female", "educ", "age", "yrs_health", "trust", "HC", "AI", "R")
    dat <- dat[complete.cases(dat[, vv]) & dat$e > 0, ]
    m <- glm(as.formula(paste("y ~", rhs)), family = quasipoisson(), data = dat,
             weights = w, offset = log(e))
    print(coeftest(m, vcov. = vcovCL(m, cluster = ~muni)))
    list(b = coef(m)["decentralized"], n = nrow(dat))
  }
  ab <- fitp("yA", FALSE); af <- fitp("yA", TRUE)
  sb <- fitp("yS", FALSE); sf <- fitp("yS", TRUE)
  res3 <- list(ab = ab$b, af = af$b, sb = sb$b, sf = sf$b, nb = ab$n, nf = af$n)
})

emit("decentralized_table2_col1", coef(m1)["decentralized"])
emit("communication_table2_col1", coef(m1)["communication"])
emit("decentralized_table2_col2", coef(m2)["decentralized"])
emit("communication_table2_col2", coef(m2)["communication"])
emit("decentralized_x_communication_table2_col2", coef(m2)[ix])
emit("n_obs_table2", nobs(m1))
emit("decentralized_table3_allties_base", res3$ab)
emit("decentralized_table3_allties_full", res3$af)
emit("decentralized_table3_strongties_base", res3$sb)
emit("decentralized_table3_strongties_full", res3$sf)
emit("n_obs_table3_base", res3$nb)
emit("n_obs_table3_full", res3$nf)