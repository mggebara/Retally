suppressPackageStartupMessages({
  library(haven)
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation.script-free"

res <- list(
  decentralized_table2_col1 = NA_real_,
  communication_table2_col1 = NA_real_,
  decentralized_table2_col2 = NA_real_,
  communication_table2_col2 = NA_real_,
  decentralized_x_communication_table2_col2 = NA_real_,
  n_obs_table2 = NA_real_,
  decentralized_table3_allties_base = NA_real_,
  decentralized_table3_allties_full = NA_real_,
  decentralized_table3_strongties_base = NA_real_,
  decentralized_table3_strongties_full = NA_real_,
  n_obs_table3_base = NA_real_,
  n_obs_table3_full = NA_real_
)

to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) x <- suppressWarnings(as.numeric(x))
  as.numeric(x)
}

# Build a player-type factor with the mayor's office (M) as reference
make_type_factor <- function(x) {
  if (inherits(x, "haven_labelled")) x <- as_factor(x, levels = "labels")
  x <- as.character(x)
  x <- trimws(x)
  x[x == ""] <- NA
  f <- factor(x)
  lv <- levels(f)
  ref <- lv[grepl("^m$|alcald|mayor|munic|^mo$|^m[ _]", tolower(lv))]
  if (length(ref) >= 1) f <- relevel(f, ref = ref[1])
  f
}

# ---------------------------------------------------------------------------
# Table 2: weighted pooled OLS on person-round panel
# ---------------------------------------------------------------------------
pgg <- read_dta(file.path(base_dir, "publicgoodgame_dataAug27.dta"))
cat("PGG columns:", paste(names(pgg), collapse = ", "), "\n")

tryCatch({
  # choose player type variable with 4 categories if possible
  ptype_var <- "player_type"
  cand <- intersect(c("player_type", "p_type"), names(pgg))
  nlev <- sapply(cand, function(v) length(unique(na.omit(as.character(as_factor(pgg[[v]]))))))
  cat("Player type candidates (n levels):", paste(cand, nlev, collapse = "; "), "\n")
  if (any(nlev == 4)) ptype_var <- cand[which(nlev == 4)[1]] else ptype_var <- cand[1]

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
    muni = to_num(pgg$publicid_muni),
    ptype = make_type_factor(pgg[[ptype_var]])
  )
  cat("Player type levels (ref first):", paste(levels(d2$ptype), collapse = ", "), "\n")
  d2$dec_comm <- d2$decentralized * d2$communication

  ctrl <- "ptype + round + lag_groupcontribution + num_players + knownpeople + female + age + educ + yrs_health + trust"
  f1 <- as.formula(paste("contribution ~ decentralized + communication +", ctrl))
  f2 <- as.formula(paste("contribution ~ decentralized + communication + dec_comm +", ctrl))

  m1 <- feols(f1, data = d2, weights = ~w, cluster = ~muni)
  m2 <- feols(f2, data = d2, weights = ~w, cluster = ~muni)
  print(summary(m1)); print(summary(m2))

  res$decentralized_table2_col1 <- unname(coef(m1)["decentralized"])
  res$communication_table2_col1 <- unname(coef(m1)["communication"])
  res$decentralized_table2_col2 <- unname(coef(m2)["decentralized"])
  res$communication_table2_col2 <- unname(coef(m2)["communication"])
  res$decentralized_x_communication_table2_col2 <- unname(coef(m2)["dec_comm"])
  res$n_obs_table2 <- nobs(m2)
}, error = function(e) cat("Table 2 error:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------------------
# Table 3: weighted Poisson of cross-level ties with log(possible ties) offset
# ---------------------------------------------------------------------------
cl <- read_csv(file.path(base_dir, "clanalysis_anondata_vNov16.csv"), show_col_types = FALSE)
cl <- as.data.frame(cl)
cat("CL columns:", paste(names(cl), collapse = ", "), "\n")
nm <- names(cl)
lnm <- tolower(nm)

tryCatch({
  muni <- to_num(cl$publicid_muni)
  type_f <- make_type_factor(cl$ParticipantType)
  cat("ParticipantType levels (ref first):", paste(levels(type_f), collapse = ", "), "\n")

  # --- Try precomputed cross-level tie variables first
  cross_cols <- nm[grepl("cross|crosslevel|cl_|_cl$|between", lnm) &
                     !grepl("^participant_", lnm)]
  denom_cols <- cross_cols[grepl("poss|total|tot|max|denom|n_", tolower(cross_cols))]
  num_cols <- setdiff(cross_cols, denom_cols)
  known_num <- num_cols[grepl("know|conoc|coleg|colleg|all", tolower(num_cols)) &
                          !grepl("prop|hour|hora", tolower(num_cols))]
  friend_num <- num_cols[grepl("friend|amig|strong", tolower(num_cols)) &
                           !grepl("prop|hour|hora", tolower(num_cols))]
  known_den <- denom_cols[grepl("know|conoc|coleg|colleg|all", tolower(denom_cols))]
  friend_den <- denom_cols[grepl("friend|amig|strong", tolower(denom_cols))]
  cat("Precomputed candidates: known=", paste(known_num, collapse = ","),
      " friend=", paste(friend_num, collapse = ","),
      " denoms=", paste(denom_cols, collapse = ","), "\n")

  # --- Construct from dyadic Participant_<letter> columns
  code_letter <- toupper(sub(".*([A-Za-z])[^A-Za-z]*$", "\\1", as.character(cl$ParticipantCode)))
  letters_present <- sort(unique(na.omit(code_letter)))
  # group columns by prefix with single-letter suffix
  m <- regmatches(nm, regexec("^(.*?)_?([A-Za-z])$", nm))
  pref <- sapply(m, function(z) if (length(z) == 3) z[2] else NA_character_)
  suff <- sapply(m, function(z) if (length(z) == 3) toupper(z[3]) else NA_character_)
  ok <- !is.na(pref) & suff %in% letters_present & nchar(pref) > 0
  pref_tab <- table(pref[ok])
  dyad_prefixes <- names(pref_tab)[pref_tab >= 3]
  cat("Dyadic prefixes:", paste(dyad_prefixes, collapse = ", "), "\n")

  get_mat <- function(p) {
    cols <- sapply(letters_present, function(L) {
      hit <- nm[ok & pref == p & suff == L]
      if (length(hit)) hit[1] else NA_character_
    })
    cols
  }

  # Classify each dyadic value into known / friend
  classify <- function(v) {
    if (is.numeric(v)) {
      list(known = !is.na(v) & v > 0, friend = NULL, raw = v)
    } else {
      s <- tolower(trimws(as.character(v)))
      neg <- is.na(s) | s == "" | grepl("^no$|^0$|no lo conoc|no conoc|ningun|don.?t|not know|nunca|^na$", s)
      fr <- !neg & grepl("amig|friend|^2$|^3$", s)
      list(known = !neg, friend = fr, raw = s)
    }
  }

  n <- nrow(cl)
  possible <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    same <- which(muni == muni[i] & seq_len(n) != i)
    possible[i] <- sum(as.character(type_f[same]) != as.character(type_f[i]), na.rm = TRUE)
    if (is.na(type_f[i])) possible[i] <- NA
  }

  build_counts <- function(p, mode) {
    cols <- get_mat(p)
    out <- rep(NA_real_, n)
    allvals <- unlist(lapply(na.omit(cols), function(cc) cl[[cc]]))
    numeric_all <- is.numeric(allvals)
    uv <- if (numeric_all) sort(unique(na.omit(allvals))) else NULL
    for (i in seq_len(n)) {
      same <- which(muni == muni[i] & seq_len(n) != i)
      same <- same[!is.na(type_f[same]) & as.character(type_f[same]) != as.character(type_f[i])]
      cnt <- 0; anyobs <- FALSE
      for (j in same) {
        cc <- cols[code_letter[j]]
        if (is.na(cc)) next
        v <- cl[[cc]][i]
        if (numeric_all) {
          if (is.na(v)) next
          anyobs <- TRUE
          if (mode == "known") cnt <- cnt + (v > 0)
          else {
            # friend: highest code when coded ordinal (e.g., 0 none, 1 colleague, 2 friend)
            if (length(uv) <= 4) cnt <- cnt + (v == max(uv)) else cnt <- cnt + (v > 0)
          }
        } else {
          cv <- classify(v)
          anyobs <- TRUE
          if (mode == "known") cnt <- cnt + cv$known else cnt <- cnt + cv$friend
        }
      }
      out[i] <- if (anyobs || length(same) == 0) cnt else NA
    }
    out
  }

  y_known <- NULL; y_friend <- NULL; den_known <- NULL; den_friend <- NULL
  if (length(known_num) >= 1) y_known <- to_num(cl[[known_num[1]]])
  if (length(friend_num) >= 1) y_friend <- to_num(cl[[friend_num[1]]])
  if (length(known_den) >= 1) den_known <- to_num(cl[[known_den[1]]])
  if (length(friend_den) >= 1) den_friend <- to_num(cl[[friend_den[1]]])
  if (is.null(den_known) && length(denom_cols) >= 1 && length(friend_den) == 0)
    den_known <- to_num(cl[[denom_cols[1]]])
  if (is.null(den_known)) den_known <- possible
  if (is.null(den_friend)) den_friend <- den_known

  if (is.null(y_known) || is.null(y_friend)) {
    kp <- dyad_prefixes[grepl("know|conoc|coleg|colleg", tolower(dyad_prefixes))]
    fp <- dyad_prefixes[grepl("friend|amig", tolower(dyad_prefixes))]
    gp <- dyad_prefixes[grepl("^participant$", tolower(dyad_prefixes))]
    if (is.null(y_known)) {
      if (length(kp)) y_known <- build_counts(kp[1], "known")
      else if (length(gp)) y_known <- build_counts(gp[1], "known")
      else if (length(dyad_prefixes)) y_known <- build_counts(dyad_prefixes[1], "known")
    }
    if (is.null(y_friend)) {
      if (length(fp)) y_friend <- build_counts(fp[1], "known")
      else if (length(gp)) y_friend <- build_counts(gp[1], "friend")
      else if (length(dyad_prefixes)) y_friend <- build_counts(dyad_prefixes[1], "friend")
    }
  }

  # Weights: in CSV if present, else municipal propensity weights from PGG data
  wcols <- nm[grepl("weight|peso", lnm)]
  wcols_full <- wcols[grepl("full", tolower(wcols))]
  if (length(wcols_full)) w3 <- to_num(cl[[wcols_full[1]]])
  else if (length(wcols)) w3 <- to_num(cl[[wcols[1]]])
  else {
    wm <- data.frame(muni = to_num(pgg$publicid_muni), w = to_num(pgg$weights_games_full_scaled)) %>%
      filter(!is.na(muni), !is.na(w)) %>% group_by(muni) %>% summarise(w = first(w), .groups = "drop")
    w3 <- wm$w[match(muni, wm$muni)]
  }

  find_col <- function(pats) {
    for (p in pats) { h <- nm[grepl(p, lnm)]; if (length(h)) return(h[1]) }
    NA_character_
  }
  fem_c <- find_col(c("^mujer$", "female"))
  edu_c <- find_col(c("^q2_educacion$", "educ"))
  age_c <- find_col(c("^q1_edad$", "edad", "age"))
  yrs_c <- find_col(c("^q3_yrssalud$", "yrssalud"))
  tru_c <- find_col(c("^gen_trust$", "trust"))

  d3 <- data.frame(
    y_known = y_known, y_friend = y_friend,
    den_known = den_known, den_friend = den_friend,
    decentralized = to_num(cl$decentralized),
    female = to_num(cl[[fem_c]]), educ = to_num(cl[[edu_c]]), age = to_num(cl[[age_c]]),
    yrs_health = to_num(cl[[yrs_c]]), trust = to_num(cl[[tru_c]]),
    ptype = type_f, w = w3, muni = muni
  )
  d3$off_known <- ifelse(d3$den_known > 0, log(d3$den_known), NA)
  d3$off_friend <- ifelse(d3$den_friend > 0, log(d3$den_friend), NA)
  cat("Summary of constructed Table 3 variables:\n"); print(summary(d3[, c("y_known", "y_friend", "den_known", "den_friend", "w")]))

  full_ctrl <- "female + educ + age + yrs_health + trust + ptype"
  fit_pois <- function(y, off, rhs) {
    dd <- d3[!is.na(d3[[y]]) & !is.na(d3[[off]]) & !is.na(d3$w) & !is.na(d3$decentralized), ]
    fepois(as.formula(paste(y, "~", rhs)), data = dd,
           offset = as.formula(paste("~", off)), weights = ~w, cluster = ~muni)
  }
  pk_b <- fit_pois("y_known", "off_known", "decentralized")
  pk_f <- fit_pois("y_known", "off_known", paste("decentralized +", full_ctrl))
  pf_b <- fit_pois("y_friend", "off_friend", "decentralized")
  pf_f <- fit_pois("y_friend", "off_friend", paste("decentralized +", full_ctrl))
  print(summary(pk_b)); print(summary(pk_f)); print(summary(pf_b)); print(summary(pf_f))

  res$decentralized_table3_allties_base <- unname(coef(pk_b)["decentralized"])
  res$decentralized_table3_allties_full <- unname(coef(pk_f)["decentralized"])
  res$decentralized_table3_strongties_base <- unname(coef(pf_b)["decentralized"])
  res$decentralized_table3_strongties_full <- unname(coef(pf_f)["decentralized"])
  res$n_obs_table3_base <- nobs(pk_b)
  res$n_obs_table3_full <- nobs(pk_f)
}, error = function(e) cat("Table 3 error:", conditionMessage(e), "\n"))

for (k in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", k, format(res[[k]], digits = 10)))
}