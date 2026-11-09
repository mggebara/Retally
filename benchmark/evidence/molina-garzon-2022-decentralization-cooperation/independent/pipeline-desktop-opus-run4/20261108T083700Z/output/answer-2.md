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

# Player type: build factor with mayor's office (M) as reference
pt_raw <- pg$player_type
if (inherits(pt_raw, "haven_labelled")) {
  pt <- as.character(as_factor(pt_raw, levels = "labels"))
} else {
  pt <- as.character(pt_raw)
}
if (all(is.na(pt)) && "p_type" %in% names(pg)) {
  pt <- as.character(as_factor(pg$p_type))
}
cat("player_type table:\n"); print(table(pt, useNA = "ifany"))
if ("p_type" %in% names(pg)) { cat("p_type table:\n"); print(table(as.character(as_factor(pg$p_type)), useNA = "ifany")) }

# player_type holds individual codes (C1, A1, G1, R1, ...); p_type holds the
# organisational level: C = health centre, A = administrative intermediary,
# R = region, G = municipal government (mayor's office, reference category)
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
  cat("CL columns:", paste(nm, collapse = ", "), "\n")

  pick <- function(include, exclude = NULL) {
    cand <- nm
    for (p in include) cand <- cand[grepl(p, cand, ignore.case = TRUE)]
    if (!is.null(exclude)) for (p in exclude) cand <- cand[!grepl(p, cand, ignore.case = TRUE)]
    if (length(cand) == 0) NA_character_ else cand[1]
  }

  # Outcomes and exposures
  y_all <- pick(c("cross", "know|known|conoc|tie"), c("friend|amig|strong|poss|total|prop|max"))
  if (is.na(y_all)) y_all <- pick(c("cross"), c("friend|amig|strong|poss|total|prop|max"))
  y_str <- pick(c("cross", "friend|amig|strong"), c("poss|total|prop|max"))
  if (is.na(y_str)) y_str <- pick(c("friend|amig|strong"), c("poss|total|prop|max"))
  e_all <- pick(c("cross", "poss|total|max"), c("friend|amig|strong"))
  if (is.na(e_all)) e_all <- pick(c("poss|total_tie|max"), c("friend|amig|strong"))
  e_str <- pick(c("cross", "poss|total|max", "friend|amig|strong"))
  if (is.na(e_str)) e_str <- e_all
  wcol <- pick(c("weight"), c("reduced"))
  cat("Chosen: y_all=", y_all, " y_str=", y_str, " e_all=", e_all, " e_str=", e_str, " w=", wcol, "\n")

  # Player type in CL data
  ptc <- as.character(cl$ParticipantType)
  cat("ParticipantType table:\n"); print(table(ptc, useNA = "ifany"))
  lvc <- unique(na.omit(ptc))
  fl <- function(patterns) {
    for (p in patterns) { h <- lvc[grepl(p, lvc, ignore.case = TRUE)]; if (length(h)) return(h[1]) }
    NA_character_
  }
  if (all(grepl("^[A-Za-z][0-9]*$", lvc))) {
    ptc <- toupper(substr(trimws(ptc), 1, 1))
    lvc <- unique(na.omit(ptc))
  }
  cHC <- fl(c("^C$", "^HC$", "health ?cent", "centro", "^HC", "^C"))
  cAI <- fl(c("^A$", "^AI$", "admin", "intermed", "^AI", "^A"))
  cR  <- fl(c("^R$", "region", "^R"))
  cat("CL levels: HC=", cHC, " AI=", cAI, " R=", cR, "\n")

  # If outcome columns not found, build from Participant_* tie columns
  if (is.na(y_all) || is.na(e_all)) {
    cat("Constructing cross-level ties from Participant_* columns\n")
    pcols <- grep("^Participant_", nm, value = TRUE)
    # level for each participant
    lvl <- ifelse(ptc == cHC, "HC", ifelse(ptc == cAI, "AI", ifelse(ptc == cR, "R", "M")))
    code <- as.character(cl$ParticipantCode)
    yA <- yS <- ex <- rep(NA_real_, nrow(cl))
    for (i in seq_len(nrow(cl))) {
      same <- which(cl$publicid_muni == cl$publicid_muni[i] & seq_len(nrow(cl)) != i)
      others <- same[lvl[same] != lvl[i]]
      ex[i] <- length(others)
      kA <- 0; kS <- 0
      for (j in others) {
        col <- paste0("Participant_", gsub("^.*_|^.*([A-Za-z])$", "\\1", code[j]))
        col2 <- pcols[pcols == col | grepl(paste0("_", code[j], "$"), pcols)]
        if (length(col2)) {
          val <- cl[[col2[1]]][i]
          vs <- tolower(as.character(val))
          if (!is.na(vs) && vs != "" && !grepl("^0$|no|not|desconoc", vs)) kA <- kA + 1
          if (!is.na(vs) && grepl("friend|amig|^2$", vs)) kS <- kS + 1
        }
      }
      yA[i] <- kA; yS[i] <- kS
    }
    cl$y_all_c <- yA; cl$y_str_c <- yS; cl$exp_c <- ex
    y_all <- "y_all_c"; y_str <- "y_str_c"; e_all <- "exp_c"; e_str <- "exp_c"
  }

  t3 <- data.frame(
    yA = num(cl[[y_all]]), yS = num(cl[[y_str]]),
    eA = num(cl[[e_all]]), eS = num(cl[[e_str]]),
    decentralized = num(cl$decentralized),
    female = num(cl$Mujer), educ = num(cl$Q2_Educacion), age = num(cl$Q1_Edad),
    yrs_health = num(cl$Q3_YrsSalud), trust = num(cl$gen_trust),
    muni = num(cl$publicid_muni)
  )
  t3$HC <- as.numeric(!is.na(cHC) & ptc %in% cHC)
  t3$AI <- as.numeric(!is.na(cAI) & ptc %in% cAI)
  t3$R  <- as.numeric(!is.na(cR) & ptc %in% cR)
  t3$HC[is.na(ptc)] <- NA; t3$AI[is.na(ptc)] <- NA; t3$R[is.na(ptc)] <- NA

  if (!is.na(wcol)) {
    t3$w <- num(cl[[wcol]])
  } else {
    mw <- d %>% group_by(muni) %>% summarise(w = mean(w, na.rm = TRUE), .groups = "drop")
    t3 <- left_join(t3, mw, by = "muni")
  }

  fitp <- function(y, e, full) {
    dat <- t3
    dat$y <- dat[[y]]; dat$e <- dat[[e]]
    rhs <- if (full) "decentralized + female + educ + age + yrs_health + trust + HC + AI + R" else "decentralized"
    vv <- c("y", "e", "w", "decentralized")
    if (full) vv <- c(vv, "female", "educ", "age", "yrs_health", "trust", "HC", "AI", "R")
    dat <- dat[complete.cases(dat[, vv]) & dat$e > 0, ]
    m <- glm(as.formula(paste("y ~", rhs)), family = quasipoisson(), data = dat,
             weights = w, offset = log(e))
    print(coeftest(m, vcov. = vcovCL(m, cluster = ~muni)))
    list(b = coef(m)["decentralized"], n = nrow(dat))
  }
  ab <- fitp("yA", "eA", FALSE); af <- fitp("yA", "eA", TRUE)
  sb <- fitp("yS", "eS", FALSE); sf <- fitp("yS", "eS", TRUE)
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
