suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(readr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation.script-free"
results <- list()

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    results[[name]] <<- as.numeric(val)
  }
}

to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- as.numeric(zap_labels(x))
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) x <- suppressWarnings(as.numeric(x))
  as.numeric(x)
}

## ---------------------------------------------------------------
## Table 2: weighted OLS of per-round contributions
## ---------------------------------------------------------------
pgg <- read_dta(file.path(base_dir, "publicgoodgame_dataAug27.dta"))
cat("PGG dims:", dim(pgg), "\n")

ptype_raw <- pgg$player_type
if (inherits(ptype_raw, "haven_labelled")) {
  ptype <- as.character(as_factor(ptype_raw))
} else {
  ptype <- as.character(ptype_raw)
}
if (all(is.na(ptype)) && "p_type" %in% names(pgg)) {
  ptype <- as.character(if (inherits(pgg$p_type, "haven_labelled")) as_factor(pgg$p_type) else pgg$p_type)
}
cat("Player types:\n"); print(table(ptype, useNA = "ifany"))

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
  muni = to_num(pgg$publicid_muni),
  pid = to_num(pgg$publicid),
  ptype = ptype,
  stringsAsFactors = FALSE
)

# reference category: mayor's office
lv <- sort(unique(na.omit(d2$ptype)))
mref <- lv[grepl("^m$|^m[^a-z]|mayor|alcald|munic", tolower(lv))]
d2$ptype_f <- factor(d2$ptype)
if (length(mref) >= 1) d2$ptype_f <- relevel(d2$ptype_f, ref = mref[1])

d2c <- d2 %>%
  filter(!is.na(contribution), !is.na(decentralized), !is.na(communication),
         !is.na(round), !is.na(lag_gc), !is.na(num_players), !is.na(knownpeople),
         !is.na(female), !is.na(age), !is.na(educ), !is.na(yrs_health),
         !is.na(trust), !is.na(w), !is.na(ptype_f))
cat("Table 2 sample N:", nrow(d2c), "\n")

m1 <- feols(contribution ~ decentralized + communication + ptype_f + round + lag_gc +
              num_players + knownpeople + female + age + educ + yrs_health + trust,
            data = d2c, weights = ~w, cluster = ~pid)
m2 <- feols(contribution ~ decentralized * communication + ptype_f + round + lag_gc +
              num_players + knownpeople + female + age + educ + yrs_health + trust,
            data = d2c, weights = ~w, cluster = ~pid)
print(summary(m1)); print(summary(m2))

emit("decentralized_table2_col1", coef(m1)["decentralized"])
emit("communication_table2_col1", coef(m1)["communication"])
emit("decentralized_table2_col2", coef(m2)["decentralized"])
emit("communication_table2_col2", coef(m2)["communication"])
emit("decentralized_x_communication_table2_col2", coef(m2)["decentralized:communication"])
emit("n_obs_table2", nobs(m1))

## municipal weights for Table 3
muni_w <- d2 %>% filter(!is.na(w), !is.na(muni)) %>%
  group_by(muni) %>% summarise(w_muni = mean(w), .groups = "drop")
pid_w <- d2 %>% filter(!is.na(w), !is.na(pid)) %>%
  group_by(pid) %>% summarise(w_pid = mean(w), .groups = "drop")

## ---------------------------------------------------------------
## Table 3: weighted Poisson of cross-level ties
## ---------------------------------------------------------------
tryCatch({
  cl <- read_csv(file.path(base_dir, "clanalysis_anondata_vNov16.csv"), show_col_types = FALSE)
  cat("CL dims:", dim(cl), "\n")
  cat("CL columns:\n"); print(names(cl))

  pcols <- grep("^Participant_[A-Za-z0-9]+$", names(cl), value = TRUE)
  pletters <- sub("^Participant_", "", pcols)
  cat("Participant columns:", pcols, "\n")

  # respondent's own letter
  pc <- as.character(cl$ParticipantCode)
  own <- sub("^.*?([A-Za-z]+)$", "\\1", pc)
  if (!any(own %in% pletters)) {
    num <- suppressWarnings(as.integer(pc))
    if (any(!is.na(num))) own <- LETTERS[num]
  }
  if (!any(own %in% pletters)) {
    own <- toupper(substr(gsub("[^A-Za-z]", "", pc), nchar(gsub("[^A-Za-z]", "", pc)), nchar(gsub("[^A-Za-z]", "", pc))))
  }
  cat("Own letters:\n"); print(table(own, useNA = "ifany"))

  # decode tie values
  allvals <- unlist(lapply(pcols, function(cc) as.character(cl[[cc]])))
  cat("Tie value table:\n"); print(table(allvals, useNA = "ifany"))
  numvals <- suppressWarnings(as.numeric(allvals))
  is_numeric_coding <- all(is.na(allvals) | allvals == "" | !is.na(numvals))

  decode <- function(x) {
    x <- as.character(x)
    if (is_numeric_coding) {
      v <- suppressWarnings(as.numeric(x))
      vv <- numvals[!is.na(numvals)]
      mn <- min(vv); mx <- max(vv)
      if (mn == 0) {
        known <- !is.na(v) & v > 0
        friend <- if (mx >= 2) (!is.na(v) & v == mx) else rep(NA, length(v))
      } else if (mn == 1 && mx >= 3) {
        known <- !is.na(v) & v > 1
        friend <- !is.na(v) & v == mx
      } else {
        known <- !is.na(v) & v == mx
        friend <- rep(NA, length(v))
      }
    } else {
      lx <- tolower(trimws(x))
      nonresp <- is.na(lx) | lx == "" | lx == "na"
      neg <- grepl("^no|no conoc|no lo|desconoc|ningun|nada|never|don.?t|not", lx)
      known <- !nonresp & !neg
      friend <- !nonresp & grepl("amig|friend", lx)
    }
    list(known = known, friend = friend)
  }

  ctype <- as.character(cl$ParticipantType)
  muni <- cl$publicid_muni
  n <- nrow(cl)
  possible <- known_ct <- friend_ct <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    others <- which(muni == muni[i] & seq_len(n) != i)
    others <- others[!is.na(ctype[others]) & !is.na(ctype[i]) & ctype[others] != ctype[i]]
    others <- others[own[others] %in% pletters]
    possible[i] <- length(others)
    if (length(others) == 0) { known_ct[i] <- 0; friend_ct[i] <- 0; next }
    vals <- sapply(own[others], function(L) as.character(cl[[paste0("Participant_", L)]][i]))
    dd <- decode(vals)
    known_ct[i] <- sum(dd$known, na.rm = TRUE)
    friend_ct[i] <- if (all(is.na(dd$friend))) NA else sum(dd$friend, na.rm = TRUE)
  }

  t3 <- data.frame(
    muni = to_num(cl$publicid_muni),
    pid = to_num(cl$publicid),
    decentralized = to_num(cl$decentralized),
    female = to_num(cl$Mujer),
    educ = to_num(cl$Q2_Educacion),
    age = to_num(cl$Q1_Edad),
    yrs_health = to_num(cl$Q3_YrsSalud),
    trust = to_num(cl$gen_trust),
    ptype = factor(ctype),
    possible = possible, known = known_ct, friend = friend_ct
  )
  lvc <- levels(t3$ptype)
  mref3 <- lvc[grepl("^m$|^m[^a-z]|mayor|alcald|munic", tolower(lvc))]
  if (length(mref3) >= 1) t3$ptype <- relevel(t3$ptype, ref = mref3[1])

  t3 <- t3 %>% left_join(muni_w, by = "muni") %>% left_join(pid_w, by = "pid")
  t3$w <- ifelse(!is.na(t3$w_muni), t3$w_muni, t3$w_pid)
  cat("Possible ties summary:\n"); print(summary(t3$possible))
  cat("Known ties summary:\n"); print(summary(t3$known))
  cat("Friend ties summary:\n"); print(summary(t3$friend))
  cat("Missing weights:", sum(is.na(t3$w)), "\n")

  t3b <- t3 %>% filter(possible > 0, !is.na(decentralized), !is.na(w))
  t3f <- t3b %>% filter(!is.na(female), !is.na(educ), !is.na(age), !is.na(yrs_health),
                        !is.na(trust), !is.na(ptype))

  fit_pois <- function(fml, dat) {
    fepois(fml, data = dat, offset = ~log(possible), weights = ~w, cluster = ~muni)
  }

  a_b <- fit_pois(known ~ decentralized, t3b)
  a_f <- fit_pois(known ~ decentralized + female + educ + age + yrs_health + trust + ptype, t3f)
  print(summary(a_b)); print(summary(a_f))
  emit("decentralized_table3_allties_base", coef(a_b)["decentralized"])
  emit("decentralized_table3_allties_full", coef(a_f)["decentralized"])
  emit("n_obs_table3_base", nobs(a_b))
  emit("n_obs_table3_full", nobs(a_f))

  if (!all(is.na(t3b$friend))) {
    s_b <- fit_pois(friend ~ decentralized, t3b %>% filter(!is.na(friend)))
    s_f <- fit_pois(friend ~ decentralized + female + educ + age + yrs_health + trust + ptype,
                    t3f %>% filter(!is.na(friend)))
    print(summary(s_b)); print(summary(s_f))
    emit("decentralized_table3_strongties_base", coef(s_b)["decentralized"])
    emit("decentralized_table3_strongties_full", coef(s_f)["decentralized"])
  }
}, error = function(e) {
  cat("Table 3 error:", conditionMessage(e), "\n")
})

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}
