suppressPackageStartupMessages({
  library(haven)
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation.script-free"
pgg_path <- file.path(base_dir, "publicgoodgame_dataAug27.dta")
net_path <- file.path(base_dir, "clanalysis_anondata_vNov16.csv")

results <- list()
setres <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0) v <- NA_real_
  results[[name]] <<- v[1]
}

to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  suppressWarnings(as.numeric(x))
}
lab_chr <- function(x) {
  if (inherits(x, "haven_labelled")) return(as.character(as_factor(x)))
  as.character(x)
}
# Build a player-type factor with the mayor's office (M) as reference
make_ptype <- function(x) {
  s <- trimws(lab_chr(x))
  f <- factor(s)
  lv <- levels(f)
  ref <- lv[grepl("^m$|mayor|alcald|munic", lv, ignore.case = TRUE)]
  if (length(ref) == 0) ref <- lv[grepl("^m", lv, ignore.case = TRUE)]
  if (length(ref) > 0) f <- relevel(f, ref = ref[1])
  f
}

# =========================== Table 2: PGG ===========================
pgg <- read_dta(pgg_path)
cat("PGG columns:", paste(names(pgg), collapse = ", "), "\n")
cat("player_type table:\n"); print(table(lab_chr(pgg$player_type), useNA = "ifany"))

d2 <- data.frame(
  contribution  = to_num(pgg$contribution),
  decentralized = to_num(pgg$decentralized),
  communication = to_num(pgg$communication),
  round         = to_num(pgg$round),
  lag_gc        = to_num(pgg$lag_groupcontribution),
  num_players   = to_num(pgg$num_players),
  knownpeople   = to_num(pgg$knownpeople),
  female        = to_num(pgg$Q2_female),
  age           = to_num(pgg$Q1_Edad),
  educ          = to_num(pgg$Q2_Educacion),
  yrs_health    = to_num(pgg$Q3_YrsSalud),
  trust         = to_num(pgg$Q5_Trust1Base),
  w             = to_num(pgg$weights_games_full_scaled),
  muni          = lab_chr(pgg$publicid_muni),
  stringsAsFactors = FALSE
)
d2$ptype <- make_ptype(pgg$player_type)
d2$dec_comm <- d2$decentralized * d2$communication

vars2 <- c("contribution", "decentralized", "communication", "round", "lag_gc",
           "num_players", "knownpeople", "female", "age", "educ", "yrs_health",
           "trust", "w", "muni", "ptype")
d2c <- d2[complete.cases(d2[, vars2]), ]
cat("Table 2 complete-case N:", nrow(d2c), "\n")

f1 <- contribution ~ decentralized + communication + ptype + round + lag_gc +
  num_players + knownpeople + female + age + educ + yrs_health + trust
f2 <- contribution ~ decentralized + communication + dec_comm + ptype + round + lag_gc +
  num_players + knownpeople + female + age + educ + yrs_health + trust

m1 <- tryCatch(feols(f1, data = d2c, weights = ~w, cluster = ~muni), error = function(e) { print(e); NULL })
m2 <- tryCatch(feols(f2, data = d2c, weights = ~w, cluster = ~muni), error = function(e) { print(e); NULL })
if (!is.null(m1)) print(summary(m1))
if (!is.null(m2)) print(summary(m2))

setres("decentralized_table2_col1", if (!is.null(m1)) coef(m1)["decentralized"] else NA)
setres("communication_table2_col1", if (!is.null(m1)) coef(m1)["communication"] else NA)
setres("decentralized_table2_col2", if (!is.null(m2)) coef(m2)["decentralized"] else NA)
setres("communication_table2_col2", if (!is.null(m2)) coef(m2)["communication"] else NA)
setres("decentralized_x_communication_table2_col2", if (!is.null(m2)) coef(m2)["dec_comm"] else NA)
setres("n_obs_table2", if (!is.null(m2)) nobs(m2) else if (!is.null(m1)) nobs(m1) else NA)

# =========================== Table 3: networks ===========================
net <- tryCatch(as.data.frame(read_csv(net_path, show_col_types = FALSE)), error = function(e) { print(e); NULL })

t3 <- list(ab = NA, af = NA, sb = NA, sf = NA, nb = NA, nf = NA)

if (!is.null(net)) {
  nm <- names(net)
  cat("Network CSV columns:", paste(nm, collapse = ", "), "\n")
  cat("Network CSV rows:", nrow(net), "\n")

  find_col <- function(patterns, exclude = NULL) {
    for (p in patterns) {
      h <- grep(p, nm, ignore.case = TRUE, value = TRUE, perl = TRUE)
      if (!is.null(exclude)) h <- h[!grepl(exclude, h, ignore.case = TRUE)]
      if (length(h) > 0) return(h[1])
    }
    NULL
  }

  muni <- as.character(net$publicid_muni)
  ptype_raw <- as.character(net$ParticipantType)
  cat("ParticipantType table:\n"); print(table(ptype_raw, useNA = "ifany"))

  # --- Try pre-computed counts / denominators first ---
  known_cnt  <- find_col(c("cross.*kn[o]?w", "kn[o]?w.*cross", "cl_?known", "known_?cl", "n_?known", "known_?ties", "ties_?known"),
                         exclude = "prop|poss|total|people")
  friend_cnt <- find_col(c("cross.*(friend|amig)", "(friend|amig).*cross", "cl_?friend", "friend_?cl", "n_?friend", "friend_?ties", "ties_?friend"),
                         exclude = "prop|poss|total")
  poss_col   <- find_col(c("poss", "total.*cross", "cross.*total", "max.*tie", "denom"))
  poss_fr_col <- find_col(c("poss.*(friend|amig)", "(friend|amig).*poss"))
  cat("Detected columns -> known:", known_cnt, " friend:", friend_cnt, " possible:", poss_col, " possible_friend:", poss_fr_col, "\n")

  known <- friend <- possible <- possible_fr <- rep(NA_real_, nrow(net))
  if (!is.null(known_cnt) && !is.null(friend_cnt) && !is.null(poss_col)) {
    known <- to_num(net[[known_cnt]])
    friend <- to_num(net[[friend_cnt]])
    possible <- to_num(net[[poss_col]])
    possible_fr <- if (!is.null(poss_fr_col)) to_num(net[[poss_fr_col]]) else possible
    # if detected "counts" are actually proportions, convert
    if (all(known <= 1, na.rm = TRUE) && any(possible > 1, na.rm = TRUE)) known <- round(known * possible)
    if (all(friend <= 1, na.rm = TRUE) && any(possible_fr > 1, na.rm = TRUE)) friend <- round(friend * possible_fr)
  } else {
    # --- Construct from dyadic columns (one column per other participant, suffix = code letter) ---
    letter_cols <- grep("_[A-Za-z]$", nm, value = TRUE)
    prefixes <- unique(sub("_[A-Za-z]$", "", letter_cols))
    cat("Letter-suffixed prefixes:", paste(prefixes, collapse = ", "), "\n")
    kn_pref <- prefixes[grepl("know|conoc|coleg|colleag", prefixes, ignore.case = TRUE)]
    fr_pref <- prefixes[grepl("friend|amig", prefixes, ignore.case = TRUE)]
    part_pref <- prefixes[grepl("^particip", prefixes, ignore.case = TRUE)]
    cat("known prefixes:", kn_pref, " friend prefixes:", fr_pref, " participant prefix:", part_pref, "\n")

    code_letter <- toupper(sub(".*([A-Za-z])[^A-Za-z]*$", "\\1", as.character(net$ParticipantCode)))

    truthy <- function(v) {
      if (is.na(v)) return(FALSE)
      s <- tolower(trimws(as.character(v)))
      if (s %in% c("", "0", "no", "false", "none", "ninguno", "na", "nan")) return(FALSE)
      nv <- suppressWarnings(as.numeric(s))
      if (!is.na(nv)) return(nv > 0)
      !grepl("^no|ning|desconoc|not", s)
    }
    is_friend_val <- function(v) {
      if (is.na(v)) return(FALSE)
      s <- tolower(trimws(as.character(v)))
      if (grepl("friend|amig", s)) return(TRUE)
      FALSE
    }

    if (length(part_pref) > 0) {
      pp <- part_pref[1]
      vals <- unlist(lapply(grep(paste0("^", pp, "_[A-Za-z]$"), nm, value = TRUE), function(cc) as.character(net[[cc]])))
      cat("Values in", pp, "columns:\n"); print(head(sort(table(vals, useNA = "ifany"), decreasing = TRUE), 20))
    }

    for (i in seq_len(nrow(net))) {
      same <- which(muni == muni[i] & seq_len(nrow(net)) != i)
      k <- 0; f <- 0; p <- 0
      for (j in same) {
        if (is.na(ptype_raw[j]) || is.na(ptype_raw[i]) || ptype_raw[j] == ptype_raw[i]) next
        L <- code_letter[j]
        p <- p + 1
        kv <- FALSE; fv <- FALSE
        if (length(kn_pref) > 0) for (pf in kn_pref) { cc <- paste0(pf, "_", L); if (cc %in% nm) kv <- kv || truthy(net[[cc]][i]) }
        if (length(fr_pref) > 0) for (pf in fr_pref) { cc <- paste0(pf, "_", L); if (cc %in% nm) fv <- fv || truthy(net[[cc]][i]) }
        if (length(kn_pref) == 0 && length(fr_pref) == 0 && length(part_pref) > 0) {
          cc <- paste0(part_pref[1], "_", L)
          if (cc %in% nm) { v <- net[[cc]][i]; kv <- truthy(v); fv <- is_friend_val(v) }
        }
        if (fv) kv <- TRUE
        k <- k + kv; f <- f + fv
      }
      known[i] <- k; friend[i] <- f; possible[i] <- p
    }
    possible_fr <- possible
  }

  cat("Summary known:\n"); print(summary(known))
  cat("Summary friend:\n"); print(summary(friend))
  cat("Summary possible:\n"); print(summary(possible))

  # weights: from CSV if present, else municipal weights from the PGG data
  wcol <- find_col(c("weights_games_full", "^weight", "weight"))
  if (!is.null(wcol)) {
    w3 <- to_num(net[[wcol]])
  } else {
    wm <- d2 %>% filter(!is.na(w)) %>% group_by(muni) %>% summarise(w = first(w), .groups = "drop")
    w3 <- wm$w[match(muni, wm$muni)]
  }

  d3 <- data.frame(
    known = known, friend = friend,
    lposs = ifelse(!is.na(possible) & possible > 0, log(possible), NA),
    lposs_fr = ifelse(!is.na(possible_fr) & possible_fr > 0, log(possible_fr), NA),
    decentralized = to_num(net$decentralized),
    female = to_num(net$Mujer),
    educ = to_num(net$Q2_Educacion),
    age = to_num(net$Q1_Edad),
    yrs_health = to_num(net$Q3_YrsSalud),
    trust = to_num(net$gen_trust),
    w = w3, muni = muni, stringsAsFactors = FALSE
  )
  d3$ptype <- make_ptype(ptype_raw)

  fit_pois <- function(y, off, full) {
    rhs <- if (full) "decentralized + female + educ + age + yrs_health + trust + ptype" else "decentralized"
    need <- c(y, off, "decentralized", "w", "muni")
    if (full) need <- c(need, "female", "educ", "age", "yrs_health", "trust", "ptype")
    dd <- d3[complete.cases(d3[, need]), ]
    fml <- as.formula(paste(y, "~", rhs))
    m <- tryCatch(fepois(fml, data = dd, weights = ~w, offset = as.formula(paste("~", off)), cluster = ~muni),
                  error = function(e) { print(e); NULL })
    if (!is.null(m)) print(summary(m))
    m
  }

  ab <- fit_pois("known", "lposs", FALSE)
  af <- fit_pois("known", "lposs", TRUE)
  sb <- fit_pois("friend", "lposs_fr", FALSE)
  sf <- fit_pois("friend", "lposs_fr", TRUE)

  gc <- function(m) if (!is.null(m)) unname(coef(m)["decentralized"]) else NA
  t3$ab <- gc(ab); t3$af <- gc(af); t3$sb <- gc(sb); t3$sf <- gc(sf)
  t3$nb <- if (!is.null(ab)) nobs(ab) else if (!is.null(sb)) nobs(sb) else NA
  t3$nf <- if (!is.null(af)) nobs(af) else if (!is.null(sf)) nobs(sf) else NA
}

setres("decentralized_table3_allties_base", t3$ab)
setres("decentralized_table3_allties_full", t3$af)
setres("decentralized_table3_strongties_base", t3$sb)
setres("decentralized_table3_strongties_full", t3$sf)
setres("n_obs_table3_base", t3$nb)
setres("n_obs_table3_full", t3$nf)

for (nmr in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", nmr, format(results[[nmr]], digits = 10)))
}
