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

emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v)) cat(sprintf("RESULT:%s=NA\n", name))
  else cat(sprintf("RESULT:%s=%.6f\n", name, v))
}

## ------------------------------------------------------------------
## Table 2: weighted pooled OLS of PGG contributions
## ------------------------------------------------------------------
pgg <- haven::read_dta(file.path(base_dir, "publicgoodgame_dataAug27.dta"))
pgg <- haven::zap_labels(pgg)
pgg <- as.data.frame(pgg)

# player type: identify mayor's office (M) as reference
pt_raw <- pgg$player_type
pt_lab <- NULL
if (is.character(pt_raw)) {
  pt_chr <- toupper(trimws(pt_raw))
} else {
  # try to recover labels from the original labelled variable
  orig <- haven::read_dta(file.path(base_dir, "publicgoodgame_dataAug27.dta"))
  labs <- attr(orig$player_type, "labels")
  if (!is.null(labs)) {
    pt_chr <- toupper(names(labs)[match(pt_raw, labs)])
  } else {
    labs2 <- attr(orig$p_type, "labels")
    if (!is.null(labs2)) {
      pt_chr <- toupper(names(labs2)[match(pgg$p_type, labs2)])
    } else {
      pt_chr <- as.character(pt_raw)
    }
  }
}
classify_type <- function(x) {
  x <- toupper(trimws(as.character(x)))
  out <- rep(NA_character_, length(x))
  out[grepl("^HC$|HEALTH|CENTRO|^CS|US$|^UPS", x)] <- "HC"
  out[is.na(out) & grepl("^AI$|INTERM|GESTOR|ADMIN", x)] <- "AI"
  out[is.na(out) & grepl("^R$|REGION", x)] <- "R"
  out[is.na(out) & grepl("^M$|MAYOR|ALCALD|MUNI", x)] <- "M"
  out
}
ptype <- classify_type(pt_chr)
if (all(is.na(ptype))) {
  # fall back: use raw codes, reference = level that looks like M, else last level
  ptype <- as.character(pt_chr)
}
pgg$ptype <- ptype
lv <- unique(na.omit(pgg$ptype))
ref <- if ("M" %in% lv) "M" else sort(lv)[length(lv)]
pgg$ptype <- relevel(factor(pgg$ptype), ref = ref)

pgg$decentralized <- as.numeric(pgg$decentralized)
pgg$communication <- as.numeric(pgg$communication)
pgg$dec_comm <- pgg$decentralized * pgg$communication

ctrl <- c("ptype", "round", "lag_groupcontribution", "num_players", "knownpeople",
          "Q2_female", "Q1_Edad", "Q2_Educacion", "Q3_YrsSalud", "Q5_Trust1Base")
vars_needed <- c("contribution", "decentralized", "communication", ctrl,
                 "weights_games_full_scaled", "publicid_muni")
d2 <- pgg[complete.cases(pgg[, vars_needed]), ]

f1 <- as.formula(paste("contribution ~ decentralized + communication +", paste(ctrl, collapse = " + ")))
f2 <- as.formula(paste("contribution ~ decentralized + communication + dec_comm +", paste(ctrl, collapse = " + ")))

m1 <- feols(f1, data = d2, weights = ~weights_games_full_scaled, cluster = ~publicid_muni)
m2 <- feols(f2, data = d2, weights = ~weights_games_full_scaled, cluster = ~publicid_muni)

emit("decentralized_table2_col1", coef(m1)["decentralized"])
emit("communication_table2_col1", coef(m1)["communication"])
emit("decentralized_table2_col2", coef(m2)["decentralized"])
emit("communication_table2_col2", coef(m2)["communication"])
emit("decentralized_x_communication_table2_col2", coef(m2)["dec_comm"])
emit("n_obs_table2", nobs(m2))

## ------------------------------------------------------------------
## Table 3: weighted Poisson of cross-level ties with offset
## ------------------------------------------------------------------
cl <- tryCatch(as.data.frame(readr::read_csv(file.path(base_dir, "clanalysis_anondata_vNov16.csv"),
                                           show_col_types = FALSE)),
               error = function(e) NULL)

t3 <- list(ab = NA, af = NA, sb = NA, sf = NA, nb = NA, nf = NA)

find_col <- function(df, must, avoid = NULL) {
  nm <- names(df)
  ok <- rep(TRUE, length(nm))
  for (p in must) ok <- ok & grepl(p, nm, ignore.case = TRUE)
  if (!is.null(avoid)) for (p in avoid) ok <- ok & !grepl(p, nm, ignore.case = TRUE)
  nm[ok]
}

if (!is.null(cl)) {
  # weights: prefer a propensity weight column in the file, otherwise merge from PGG data
  wcol <- find_col(cl, "weight", avoid = "reduc")
  if (length(wcol) == 0) {
    wmap <- pgg %>% group_by(publicid_muni) %>%
      summarise(w_muni = first(na.omit(weights_games_full_scaled)), .groups = "drop")
    cl <- left_join(cl, wmap, by = "publicid_muni")
    wcol <- "w_muni"
  } else {
    wcol <- if ("weights_games_full_scaled" %in% wcol) "weights_games_full_scaled" else wcol[1]
  }
  cl$w <- as.numeric(cl[[wcol]])

  # type classification
  cl$ctype <- classify_type(cl$ParticipantType)
  if (all(is.na(cl$ctype))) cl$ctype <- as.character(cl$ParticipantType)

  # look for precomputed tie counts
  known_cnt <- find_col(cl, c("cross"), avoid = c("friend", "amig", "poss", "total", "prop", "hour"))
  known_cnt <- known_cnt[grepl("know|conoc|col|tie|all", known_cnt, ignore.case = TRUE)]
  friend_cnt <- find_col(cl, c("cross"), avoid = c("poss", "total", "prop"))
  friend_cnt <- friend_cnt[grepl("friend|amig|strong", friend_cnt, ignore.case = TRUE)]
  poss_cnt <- find_col(cl, c("cross"))
  poss_cnt <- poss_cnt[grepl("poss|total|max|pot", poss_cnt, ignore.case = TRUE)]

  if (length(known_cnt) >= 1 && length(friend_cnt) >= 1 && length(poss_cnt) >= 1) {
    cl$y_known <- as.numeric(cl[[known_cnt[1]]])
    cl$y_friend <- as.numeric(cl[[friend_cnt[1]]])
    pk <- poss_cnt[!grepl("friend|amig", poss_cnt, ignore.case = TRUE)]
    pf <- poss_cnt[grepl("friend|amig", poss_cnt, ignore.case = TRUE)]
    cl$poss_known <- as.numeric(cl[[if (length(pk)) pk[1] else poss_cnt[1]]])
    cl$poss_friend <- as.numeric(cl[[if (length(pf)) pf[1] else poss_cnt[1]]])
  } else {
    # construct from Participant_<code> columns: responses about each other participant
    pcols <- grep("^Participant_", names(cl), value = TRUE)
    codes <- sub("^Participant_", "", pcols)
    pcode <- as.character(cl$ParticipantCode)
    pcode_key <- ifelse(pcode %in% codes, pcode, substr(pcode, nchar(pcode), nchar(pcode)))
    is_known <- function(v) {
      if (is.numeric(v)) return(!is.na(v) & v > 0)
      s <- tolower(trimws(as.character(v)))
      !is.na(s) & s != "" & !grepl("^(0|no|ninguno|none|na|no conoce|don't know)$", s)
    }
    is_friend <- function(v) {
      if (is.numeric(v)) {
        mx <- suppressWarnings(max(v, na.rm = TRUE))
        return(!is.na(v) & v == mx & mx >= 2)
      }
      s <- tolower(as.character(v))
      !is.na(s) & grepl("amig|friend", s)
    }
    n <- nrow(cl)
    yk <- yf <- poss <- rep(NA_real_, n)
    for (i in seq_len(n)) {
      same <- which(cl$publicid_muni == cl$publicid_muni[i] & seq_len(n) != i)
      others <- same[!is.na(cl$ctype[same]) & cl$ctype[same] != cl$ctype[i]]
      poss[i] <- length(others)
      ck <- 0; cf <- 0
      for (j in others) {
        col <- paste0("Participant_", pcode_key[j])
        if (col %in% names(cl)) {
          v <- cl[[col]]
          if (is_known(v)[i]) ck <- ck + 1
          if (is_friend(v)[i]) cf <- cf + 1
        }
      }
      yk[i] <- ck; yf[i] <- cf
    }
    cl$y_known <- yk; cl$y_friend <- yf
    cl$poss_known <- poss; cl$poss_friend <- poss
  }

  # controls
  fem <- if ("Mujer" %in% names(cl)) "Mujer" else find_col(cl, "female")[1]
  cl$female <- as.numeric(cl[[fem]])
  cl$educ <- suppressWarnings(as.numeric(cl$Q2_Educacion))
  cl$age <- suppressWarnings(as.numeric(cl$Q1_Edad))
  cl$yrs <- suppressWarnings(as.numeric(cl$Q3_YrsSalud))
  cl$trust <- suppressWarnings(as.numeric(cl$gen_trust))
  lv3 <- unique(na.omit(cl$ctype))
  ref3 <- if ("M" %in% lv3) "M" else sort(lv3)[length(lv3)]
  cl$ctype_f <- relevel(factor(cl$ctype), ref = ref3)
  cl$decentralized <- as.numeric(cl$decentralized)

  run_pois <- function(y, poss, full) {
    dd <- cl
    dd$y <- dd[[y]]; dd$lp <- log(dd[[poss]])
    keep <- !is.na(dd$y) & is.finite(dd$lp) & !is.na(dd$w) & !is.na(dd$decentralized)
    if (full) keep <- keep & complete.cases(dd[, c("female", "educ", "age", "yrs", "trust", "ctype_f")])
    dd <- dd[keep, ]
    fml <- if (full) y ~ decentralized + female + educ + age + yrs + trust + ctype_f + offset(lp)
           else y ~ decentralized + offset(lp)
    m <- suppressWarnings(glm(fml, family = poisson(link = "log"), data = dd, weights = w))
    list(b = unname(coef(m)["decentralized"]), n = nobs(m))
  }
  r <- tryCatch(run_pois("y_known", "poss_known", FALSE), error = function(e) list(b = NA, n = NA))
  t3$ab <- r$b; t3$nb <- r$n
  r <- tryCatch(run_pois("y_known", "poss_known", TRUE), error = function(e) list(b = NA, n = NA))
  t3$af <- r$b; t3$nf <- r$n
  r <- tryCatch(run_pois("y_friend", "poss_friend", FALSE), error = function(e) list(b = NA, n = NA))
  t3$sb <- r$b
  r <- tryCatch(run_pois("y_friend", "poss_friend", TRUE), error = function(e) list(b = NA, n = NA))
  t3$sf <- r$b
}

emit("decentralized_table3_allties_base", t3$ab)
emit("decentralized_table3_allties_full", t3$af)
emit("decentralized_table3_strongties_base", t3$sb)
emit("decentralized_table3_strongties_full", t3$sf)
emit("n_obs_table3_base", t3$nb)
emit("n_obs_table3_full", t3$nf)
