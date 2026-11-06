suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(readr)
  library(fixest)
  library(sandwich)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation.script-free"

to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  suppressWarnings(as.numeric(as.character(x)))
}
to_lab <- function(x) {
  if (inherits(x, "haven_labelled")) {
    as.character(haven::as_factor(x, levels = "default"))
  } else as.character(x)
}

make_type_factor <- function(x) {
  lab <- trimws(to_lab(x))
  lab[lab == ""] <- NA
  f <- factor(lab)
  lv <- levels(f)
  up <- toupper(lv)
  ref <- which(up == "M" | grepl("MAYOR|ALCALD|MUNIC", up))
  if (length(ref) >= 1) f <- relevel(f, ref = lv[ref[1]])
  f
}

out <- list()

# ---------------- Table 2: weighted OLS of PGG contributions ----------------
pgg <- haven::read_dta(file.path(base_dir, "publicgoodgame_dataAug27.dta"))

ptype_src <- NULL
for (cand in c("player_type", "p_type")) {
  if (cand %in% names(pgg)) {
    lab <- to_lab(pgg[[cand]])
    if (any(!is.na(lab)) && length(unique(na.omit(lab))) >= 3 &&
        any(grepl("[A-Za-z]", lab))) { ptype_src <- cand; break }
  }
}
if (is.null(ptype_src)) ptype_src <- if ("player_type" %in% names(pgg)) "player_type" else "p_type"

d2 <- data.frame(
  contribution = to_num(pgg$contribution),
  decentralized = to_num(pgg$decentralized),
  communication = to_num(pgg$communication),
  round = to_num(pgg$round),
  lag_gc = to_num(pgg$lag_groupcontribution),
  num_players = to_num(pgg$num_players),
  knownpeople = to_num(pgg$knownpeople),
  female = to_num(pgg$Q2_female),
  age = to_num(pgg$Q1_Edad),
  educ = to_num(pgg$Q2_Educacion),
  yrs_health = to_num(pgg$Q3_YrsSalud),
  trust = to_num(pgg$Q5_Trust1Base),
  w = to_num(pgg$weights_games_full_scaled),
  publicid = to_lab(pgg$publicid),
  muni = to_lab(pgg$publicid_muni),
  stringsAsFactors = FALSE
)
d2$ptype <- make_type_factor(pgg[[ptype_src]])

d2c <- d2[complete.cases(d2[, c("contribution", "decentralized", "communication", "round",
                                "lag_gc", "num_players", "knownpeople", "female", "age",
                                "educ", "yrs_health", "trust", "w", "ptype")]), ]
d2c <- d2c[d2c$w > 0, ]

f1 <- contribution ~ decentralized + communication + ptype + round + lag_gc +
  num_players + knownpeople + female + age + educ + yrs_health + trust
f2 <- contribution ~ decentralized * communication + ptype + round + lag_gc +
  num_players + knownpeople + female + age + educ + yrs_health + trust

m1 <- feols(f1, data = d2c, weights = ~w, cluster = ~publicid)
m2 <- feols(f2, data = d2c, weights = ~w, cluster = ~publicid)

cf1 <- coef(m1); cf2 <- coef(m2)
ix <- grep("decentralized:communication|communication:decentralized", names(cf2), value = TRUE)[1]
out$decentralized_table2_col1 <- cf1["decentralized"]
out$communication_table2_col1 <- cf1["communication"]
out$decentralized_table2_col2 <- cf2["decentralized"]
out$communication_table2_col2 <- cf2["communication"]
out$decentralized_x_communication_table2_col2 <- cf2[ix]
out$n_obs_table2 <- nobs(m1)

# ---------------- Table 3: weighted Poisson of cross-level ties ----------------
t3 <- tryCatch({
  cl <- readr::read_csv(file.path(base_dir, "clanalysis_anondata_vNov16.csv"),
                        show_col_types = FALSE, guess_max = 10000)
  cl <- as.data.frame(cl)

  # municipal weights
  wcol <- grep("weight", names(cl), ignore.case = TRUE, value = TRUE)
  wcol <- wcol[!grepl("reduced", wcol, ignore.case = TRUE)]
  if (length(wcol) >= 1) {
    cl$w <- to_num(cl[[wcol[1]]])
  } else {
    wm <- d2 %>% filter(!is.na(w)) %>% group_by(muni) %>% summarise(w = first(w), .groups = "drop")
    cl$muni_chr <- as.character(cl$publicid_muni)
    cl <- left_join(cl, wm, by = c("muni_chr" = "muni"))
  }

  tie_cols <- grep("^Participant_[A-Za-z0-9]+$", names(cl), value = TRUE)
  suffix <- sub("^Participant_", "", tie_cols)
  code <- as.character(cl$ParticipantCode)
  code_s <- sub(".*[_ -]", "", code)
  if (!any(code_s %in% suffix)) {
    code_s <- sapply(code, function(cc) {
      hit <- suffix[sapply(suffix, function(s) grepl(paste0(s, "$"), cc))]
      if (length(hit)) hit[which.max(nchar(hit))] else NA_character_
    })
  }
  cl$code_s <- code_s
  level <- trimws(to_lab(cl$ParticipantType))

  # determine coding of tie responses
  vals <- unlist(lapply(tie_cols, function(cc) cl[[cc]]))
  is_chr <- is.character(vals)
  known_fn <- NULL; friend_fn <- NULL
  if (is_chr) {
    known_fn <- function(v) {
      v <- tolower(trimws(as.character(v)))
      !is.na(v) & v != "" & !grepl("^no|not|desconoc|^0$|ninguno|none", v)
    }
    friend_fn <- function(v) {
      v <- tolower(trimws(as.character(v)))
      !is.na(v) & grepl("amig|friend", v)
    }
  } else {
    nv <- sort(unique(na.omit(as.numeric(vals))))
    mn <- min(nv); mx <- max(nv)
    if (mn == 0) {
      known_fn <- function(v) !is.na(v) & as.numeric(v) > 0
    } else if (length(nv) >= 3) {
      known_fn <- function(v) !is.na(v) & as.numeric(v) > mn
    } else {
      known_fn <- function(v) !is.na(v) & as.numeric(v) >= 1
    }
    friend_fn <- function(v) !is.na(v) & as.numeric(v) == mx
  }

  muni_id <- as.character(cl$publicid_muni)
  n <- nrow(cl)
  realized_all <- rep(NA_real_, n); realized_str <- rep(NA_real_, n); possible <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    others <- which(muni_id == muni_id[i] & seq_len(n) != i & !is.na(cl$code_s))
    others <- others[!is.na(level[others]) & !is.na(level[i]) & level[others] != level[i]]
    possible[i] <- length(others)
    ra <- 0; rs <- 0
    for (j in others) {
      colj <- paste0("Participant_", cl$code_s[j])
      if (colj %in% names(cl)) {
        v <- cl[[colj]][i]
        ra <- ra + as.numeric(known_fn(v))
        rs <- rs + as.numeric(friend_fn(v))
      }
    }
    realized_all[i] <- ra; realized_str[i] <- rs
  }
  cl$ties_all <- realized_all
  cl$ties_strong <- realized_str
  cl$possible <- possible

  cl$decentralized <- to_num(cl$decentralized)
  cl$female <- to_num(cl$Mujer)
  cl$educ <- to_num(cl$Q2_Educacion)
  cl$age <- to_num(cl$Q1_Edad)
  cl$yrs_health <- to_num(cl$Q3_YrsSalud)
  cl$trust <- to_num(cl$gen_trust)
  cl$ptype <- make_type_factor(cl$ParticipantType)
  cl$cluster_muni <- muni_id

  base_d <- cl[!is.na(cl$possible) & cl$possible > 0 & !is.na(cl$decentralized) &
                 !is.na(cl$w) & cl$w > 0, ]
  full_d <- base_d[complete.cases(base_d[, c("female", "educ", "age", "yrs_health", "trust", "ptype")]), ]

  fitp <- function(y, dat, full) {
    rhs <- if (full) "decentralized + female + educ + age + yrs_health + trust + ptype" else "decentralized"
    fm <- as.formula(paste(y, "~", rhs))
    m <- suppressWarnings(glm(fm, data = dat, family = poisson(link = "log"),
                              weights = w, offset = log(possible)))
    list(coef = unname(coef(m)["decentralized"]), n = nobs(m))
  }
  ab <- fitp("ties_all", base_d, FALSE)
  af <- fitp("ties_all", full_d, TRUE)
  sb <- fitp("ties_strong", base_d, FALSE)
  sf <- fitp("ties_strong", full_d, TRUE)
  list(ab = ab, af = af, sb = sb, sf = sf)
}, error = function(e) { message("Table 3 error: ", conditionMessage(e)); NULL })

if (!is.null(t3)) {
  out$decentralized_table3_allties_base <- t3$ab$coef
  out$decentralized_table3_allties_full <- t3$af$coef
  out$decentralized_table3_strongties_base <- t3$sb$coef
  out$decentralized_table3_strongties_full <- t3$sf$coef
  out$n_obs_table3_base <- t3$ab$n
  out$n_obs_table3_full <- t3$af$n
}

for (nm in names(out)) {
  val <- as.numeric(out[[nm]])
  if (length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", nm, val))
}