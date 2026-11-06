suppressPackageStartupMessages({
  library(haven)
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation.script-free"

emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v)) cat(sprintf("RESULT:%s=NA\n", name))
  else cat(sprintf("RESULT:%s=%.6f\n", name, v))
}

to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  suppressWarnings(as.numeric(x))
}
to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- as.character(as_factor(x))
  as.character(x)
}

# Classify player type into M / R / AI / HC
classify_type <- function(x) {
  s <- trimws(tolower(to_chr(x)))
  out <- rep(NA_character_, length(s))
  out[grepl("mayor|alcald|municipal|^m$|^mo$", s)] <- "M"
  out[is.na(out) & grepl("regional|region|^r$|^rs$|^rha$", s)] <- "R"
  out[is.na(out) & grepl("interm|admin|gestor|^ai$|^ia$|^a$", s)] <- "AI"
  out[is.na(out) & grepl("health|centro|salud|doctor|nurse|medic|enferm|^hc$|^cs$|^h$", s)] <- "HC"
  out
}

type_dummies <- function(df, candidates) {
  best <- NULL; best_ok <- -1
  for (cc in candidates) {
    if (!cc %in% names(df)) next
    cls <- classify_type(df[[cc]])
    ok <- sum(!is.na(cls) & !is.na(df[[cc]])) / max(1, sum(!is.na(df[[cc]])))
    nlev <- length(unique(na.omit(cls)))
    if (nlev >= 3 && ok > best_ok) { best <- cls; best_ok <- ok }
  }
  if (is.null(best)) {
    # Fallback: factor dummies, first level as reference
    cc <- candidates[candidates %in% names(df)][1]
    f <- factor(to_chr(df[[cc]]))
    levs <- levels(f)
    cat("Player type levels (fallback):", paste(levs, collapse = ", "), "\n")
    best <- rep(NA_character_, nrow(df))
    map <- c("M", "HC", "AI", "R")
    for (i in seq_along(levs)) best[f == levs[i]] <- map[min(i, 4)]
  }
  data.frame(HC = as.numeric(best == "HC"), AI = as.numeric(best == "AI"),
             R = as.numeric(best == "R"), ptype = best)
}

# ------------------------------------------------------------------
# Table 2: weighted pooled OLS on person-rounds
# ------------------------------------------------------------------
pgg <- read_dta(file.path(base, "publicgoodgame_dataAug27.dta"))
pgg <- as.data.frame(pgg)

d2 <- data.frame(
  contribution = to_num(pgg$contribution),
  decentralized = to_num(pgg$decentralized),
  communication = to_num(pgg$communication),
  round = to_num(pgg$round),
  lag_group = to_num(pgg$lag_groupcontribution),
  num_players = to_num(pgg$num_players),
  knownpeople = to_num(pgg$knownpeople),
  female = to_num(pgg$Q2_female),
  age = to_num(pgg$Q1_Edad),
  educ = to_num(pgg$Q2_Educacion),
  yrs_health = to_num(pgg$Q3_YrsSalud),
  trust = to_num(pgg$Q5_Trust1Base),
  w = to_num(pgg$weights_games_full_scaled),
  muni = to_chr(pgg$publicid_muni),
  pid = to_chr(pgg$publicid)
)
td <- type_dummies(pgg, c("player_type", "p_type"))
d2$HC <- td$HC; d2$AI <- td$AI; d2$R <- td$R
cat("Player-type distribution (PGG):\n"); print(table(td$ptype, useNA = "ifany"))

# If communication missing, derive from round
if (all(is.na(d2$communication))) d2$communication <- as.numeric(d2$round >= 6)

vars2 <- c("contribution", "decentralized", "communication", "HC", "AI", "R", "round",
           "lag_group", "num_players", "knownpeople", "female", "age", "educ",
           "yrs_health", "trust", "w", "muni")
s2 <- d2[complete.cases(d2[, vars2]), ]
s2 <- s2[s2$w > 0, ]
s2$dec_comm <- s2$decentralized * s2$communication

f1 <- contribution ~ decentralized + communication + HC + AI + R + round + lag_group +
  num_players + knownpeople + female + age + educ + yrs_health + trust
f2 <- contribution ~ decentralized + communication + dec_comm + HC + AI + R + round + lag_group +
  num_players + knownpeople + female + age + educ + yrs_health + trust

m1 <- feols(f1, data = s2, weights = ~w, cluster = ~muni)
m2 <- feols(f2, data = s2, weights = ~w, cluster = ~muni)
print(summary(m1)); print(summary(m2))

# ------------------------------------------------------------------
# Table 3: weighted Poisson with offset, individual level
# ------------------------------------------------------------------
cl <- read_csv(file.path(base, "clanalysis_anondata_vNov16.csv"), show_col_types = FALSE,
               guess_max = 10000)
cl <- as.data.frame(cl)
nm <- names(cl)
cat("clanalysis columns:\n"); print(nm)

find_col <- function(must, exclude = NULL) {
  cand <- nm
  for (p in must) cand <- cand[grepl(p, cand, ignore.case = TRUE)]
  if (!is.null(exclude)) for (p in exclude) cand <- cand[!grepl(p, cand, ignore.case = TRUE)]
  if (length(cand) == 0) NA_character_ else cand[1]
}

cl$type <- type_dummies(cl, c("ParticipantType"))$ptype
cl$muni <- as.character(cl$publicid_muni)
cl$code <- as.character(cl$ParticipantCode)

# Try precomputed counts first
known_c <- find_col(c("cross"), c("poss|total|tot|prop|friend|amig|strong|hour"))
friend_c <- find_col(c("cross", "friend|amig|strong"), c("poss|total|tot|prop"))
poss_known_c <- find_col(c("cross", "poss|total|tot"), c("friend|amig|strong|hour"))
poss_friend_c <- find_col(c("cross", "poss|total|tot", "friend|amig|strong"))

constructed <- FALSE
if (!is.na(known_c) && !is.na(friend_c) && !is.na(poss_known_c)) {
  cl$y_known <- to_num(cl[[known_c]])
  cl$y_friend <- to_num(cl[[friend_c]])
  cl$poss_known <- to_num(cl[[poss_known_c]])
  cl$poss_friend <- if (!is.na(poss_friend_c)) to_num(cl[[poss_friend_c]]) else cl$poss_known
  cat("Using precomputed tie columns:", known_c, friend_c, poss_known_c, poss_friend_c, "\n")
} else {
  constructed <- TRUE
  # Build from per-alter columns Participant_<code>
  pcols <- grep("^Participant_[A-Za-z0-9]+$", nm, value = TRUE)
  fcols <- grep("^(Friend|Amig[a-z]*|Strong)_?[A-Za-z0-9]+$", nm, value = TRUE, ignore.case = TRUE)
  sub_k <- grep("^Participant_[A-Za-z0-9]+_(know|known|conoc|colleg|col)", nm, value = TRUE, ignore.case = TRUE)
  sub_f <- grep("^Participant_[A-Za-z0-9]+_(friend|amig|strong)", nm, value = TRUE, ignore.case = TRUE)
  get_code <- function(cols, re) sub(re, "\\1", cols, ignore.case = TRUE)

  known_mat <- NULL; friend_mat <- NULL
  if (length(sub_k) > 0) {
    known_mat <- setNames(lapply(sub_k, function(c) cl[[c]]), get_code(sub_k, "^Participant_([A-Za-z0-9]+)_.*$"))
  } else if (length(pcols) > 0) {
    known_mat <- setNames(lapply(pcols, function(c) cl[[c]]), get_code(pcols, "^Participant_([A-Za-z0-9]+)$"))
  }
  if (length(sub_f) > 0) {
    friend_mat <- setNames(lapply(sub_f, function(c) cl[[c]]), get_code(sub_f, "^Participant_([A-Za-z0-9]+)_.*$"))
  } else if (length(fcols) > 0) {
    friend_mat <- setNames(lapply(fcols, function(c) cl[[c]]),
                           get_code(fcols, "^(?:Friend|Amig[a-z]*|Strong)_?([A-Za-z0-9]+)$"))
  }

  is_tie <- function(v) {
    if (is.numeric(v) || is.logical(v)) return(!is.na(v) & v > 0)
    s <- trimws(tolower(as.character(v)))
    !is.na(s) & s != "" & !s %in% c("0", "no", "none", "na", "nan", "ninguno", "no conoce", "desconocido", "false")
  }
  is_friend_val <- function(v) {
    if (is.numeric(v) || is.logical(v)) {
      mx <- suppressWarnings(max(v, na.rm = TRUE))
      if (is.finite(mx) && mx > 1) return(!is.na(v) & v >= 2)
      return(!is.na(v) & v > 0)
    }
    s <- tolower(as.character(v))
    !is.na(s) & grepl("friend|amig", s)
  }

  n <- nrow(cl)
  cl$y_known <- 0; cl$y_friend <- 0; cl$poss_known <- 0
  for (i in seq_len(n)) {
    same <- which(cl$muni == cl$muni[i] & seq_len(n) != i)
    cross <- same[!is.na(cl$type[same]) & cl$type[same] != cl$type[i]]
    cl$poss_known[i] <- length(cross)
    cross_codes <- cl$code[cross]
    yk <- 0; yf <- 0
    if (!is.null(known_mat)) {
      for (cc in intersect(names(known_mat), cross_codes)) {
        v <- known_mat[[cc]]
        if (is_tie(v)[i]) yk <- yk + 1
        if (is.null(friend_mat) && is_friend_val(v)[i]) yf <- yf + 1
      }
    }
    if (!is.null(friend_mat)) {
      for (cc in intersect(names(friend_mat), cross_codes)) {
        if (is_tie(friend_mat[[cc]])[i]) yf <- yf + 1
      }
    }
    cl$y_known[i] <- yk; cl$y_friend[i] <- yf
  }
  cl$poss_friend <- cl$poss_known
  cat("Constructed tie counts from per-alter columns.\n")
}

# Weights: from clanalysis if present, else municipal weight from PGG data
wcol <- find_col(c("weight"), c("reduced"))
if (!is.na(wcol)) {
  cl$w <- to_num(cl[[wcol]])
} else {
  mw <- d2 %>% filter(!is.na(w)) %>% group_by(muni) %>% summarise(w = first(w), .groups = "drop")
  cl <- left_join(cl, mw, by = "muni")
}

cl$decentralized <- to_num(cl$decentralized)
tdc <- type_dummies(cl, c("ParticipantType"))
cl$HC <- tdc$HC; cl$AI <- tdc$AI; cl$R <- tdc$R
cl$female <- to_num(cl$Mujer)
cl$educ <- to_num(cl$Q2_Educacion)
cl$age <- to_num(cl$Q1_Edad)
cl$yrs_health <- to_num(cl$Q3_YrsSalud)
cl$trust <- to_num(cl$gen_trust)
cl$lpk <- log(cl$poss_known)
cl$lpf <- log(cl$poss_friend)

run_pois <- function(y, lp, full) {
  vars <- c(y, lp, "decentralized", "w", "muni")
  ctrl <- c("female", "educ", "age", "yrs_health", "trust", "HC", "AI", "R")
  if (full) vars <- c(vars, ctrl)
  d <- cl[complete.cases(cl[, vars]) & is.finite(cl[[lp]]) & cl$w > 0, ]
  rhs <- if (full) paste(c("decentralized", ctrl), collapse = " + ") else "decentralized"
  fml <- as.formula(paste(y, "~", rhs))
  m <- fepois(fml, data = d, offset = as.formula(paste("~", lp)), weights = ~w, cluster = ~muni)
  print(summary(m))
  list(b = coef(m)["decentralized"], n = nobs(m))
}

r_kb <- tryCatch(run_pois("y_known", "lpk", FALSE), error = function(e) { print(e); list(b = NA, n = NA) })
r_kf <- tryCatch(run_pois("y_known", "lpk", TRUE), error = function(e) { print(e); list(b = NA, n = NA) })
r_fb <- tryCatch(run_pois("y_friend", "lpf", FALSE), error = function(e) { print(e); list(b = NA, n = NA) })
r_ff <- tryCatch(run_pois("y_friend", "lpf", TRUE), error = function(e) { print(e); list(b = NA, n = NA) })

emit("decentralized_table2_col1", coef(m1)["decentralized"])
emit("communication_table2_col1", coef(m1)["communication"])
emit("decentralized_table2_col2", coef(m2)["decentralized"])
emit("communication_table2_col2", coef(m2)["communication"])
emit("decentralized_x_communication_table2_col2", coef(m2)["dec_comm"])
emit("n_obs_table2", nobs(m2))
emit("decentralized_table3_allties_base", r_kb$b)
emit("decentralized_table3_allties_full", r_kf$b)
emit("decentralized_table3_strongties_base", r_fb$b)
emit("decentralized_table3_strongties_full", r_ff$b)
emit("n_obs_table3_base", r_kb$n)
emit("n_obs_table3_full", r_kf$n)
