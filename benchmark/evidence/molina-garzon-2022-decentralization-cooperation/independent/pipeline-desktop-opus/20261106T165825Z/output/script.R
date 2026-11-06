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
## Uses the dataset's precomputed cross-level tie counts (numerator)
## and possible cross-level ties (denominator -> log offset).
## ---------------------------------------------------------------
tryCatch({
  cl <- read_csv(file.path(base_dir, "clanalysis_anondata_vNov16.csv"), show_col_types = FALSE)
  cat("CL dims:", dim(cl), "\n")
  for (cc in c("net_crosslevel_propnumknown", "net_crosslevel_propdenomknown",
               "net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends",
               "net_crosslevel_propnumknown_col", "net_crosslevel_propdenomknown_col",
               "net_crosslevel_propnumfriends_col", "net_crosslevel_propdenomfriends_col",
               "weights_games_full_scaled")) {
    cat(cc, ":\n"); print(summary(to_num(cl[[cc]])))
  }

  ctype <- as.character(cl$ParticipantType)
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
    known = to_num(cl$net_crosslevel_propnumknown),
    den_known = to_num(cl$net_crosslevel_propdenomknown),
    friend = to_num(cl$net_crosslevel_propnumfriends),
    den_friend = to_num(cl$net_crosslevel_propdenomfriends),
    w = to_num(cl$weights_games_full_scaled)
  )
  cat("Participant types:\n"); print(table(t3$ptype, useNA = "ifany"))
  lvc <- levels(t3$ptype)
  mref3 <- lvc[grepl("^m$|^m[^a-z]|mayor|alcald|munic", tolower(lvc))]
  if (length(mref3) >= 1) t3$ptype <- relevel(t3$ptype, ref = mref3[1])

  # fall back to municipal PGG weights if the CL file weight is missing
  t3 <- t3 %>% left_join(muni_w, by = "muni")
  t3$w <- ifelse(!is.na(t3$w), t3$w, t3$w_muni)
  cat("Missing weights:", sum(is.na(t3$w)), "\n")

  covs_ok <- function(d) d %>% filter(!is.na(female), !is.na(educ), !is.na(age),
                                       !is.na(yrs_health), !is.na(trust), !is.na(ptype))

  fit_pois <- function(fml, dat, den) {
    dat <- dat[!is.na(dat[[den]]) & dat[[den]] > 0, , drop = FALSE]
    dat$lden <- log(dat[[den]])
    fepois(fml, data = dat, offset = ~lden, weights = ~w, cluster = ~muni)
  }

  tb_k <- t3 %>% filter(!is.na(known), !is.na(decentralized), !is.na(w))
  a_b <- fit_pois(known ~ decentralized, tb_k, "den_known")
  a_f <- fit_pois(known ~ decentralized + female + educ + age + yrs_health + trust + ptype,
                  covs_ok(tb_k), "den_known")
  print(summary(a_b)); print(summary(a_f))
  emit("decentralized_table3_allties_base", coef(a_b)["decentralized"])
  emit("decentralized_table3_allties_full", coef(a_f)["decentralized"])
  emit("n_obs_table3_base", nobs(a_b))
  emit("n_obs_table3_full", nobs(a_f))

  tb_s <- t3 %>% filter(!is.na(friend), !is.na(decentralized), !is.na(w))
  s_b <- fit_pois(friend ~ decentralized, tb_s, "den_friend")
  s_f <- fit_pois(friend ~ decentralized + female + educ + age + yrs_health + trust + ptype,
                  covs_ok(tb_s), "den_friend")
  print(summary(s_b)); print(summary(s_f))
  emit("decentralized_table3_strongties_base", coef(s_b)["decentralized"])
  emit("decentralized_table3_strongties_full", coef(s_f)["decentralized"])
}, error = function(e) {
  cat("Table 3 error:", conditionMessage(e), "\n")
})

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}