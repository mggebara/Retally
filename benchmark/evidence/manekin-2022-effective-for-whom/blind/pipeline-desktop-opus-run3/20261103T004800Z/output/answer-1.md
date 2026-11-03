suppressPackageStartupMessages({
  library(haven)
})
set.seed(42)

base <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data"
load(file.path(base, "us_survey_wave1.rdata"))
load(file.path(base, "isr_survey_wave1.rdata"))
load(file.path(base, "us_survey_wave2.rdata"))
load(file.path(base, "isr_survey_wave2.rdata"))

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x)
  tolower(trimws(as.character(x)))
}
to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

# Generic dummy maker: pattern for "treated" level; fallback on 0/1 numeric or non-first level
make_dummy <- function(x, pos_pattern, neg_pattern = NULL) {
  raw <- x
  if (is.logical(raw)) return(as.numeric(raw))
  if (is.numeric(raw) && !inherits(raw, "haven_labelled")) {
    u <- sort(unique(raw[!is.na(raw)]))
    if (all(u %in% c(0, 1))) return(as.numeric(raw))
  }
  ch <- to_chr(raw)
  out <- rep(NA_real_, length(ch))
  pos <- grepl(pos_pattern, ch)
  if (!is.null(neg_pattern)) {
    neg <- grepl(neg_pattern, ch) & !pos
    if (any(pos) && any(neg)) {
      out[pos] <- 1; out[neg] <- 0
      out[is.na(ch) | ch == "na"] <- NA
      # anything else not matched -> 0 only if pattern ambiguous; keep NA
      return(out)
    }
  }
  if (any(pos)) {
    out <- ifelse(is.na(ch) | ch == "na", NA, as.numeric(pos))
    return(out)
  }
  # fallback: numeric 0/1 after zap
  nn <- to_num(raw)
  u <- sort(unique(nn[!is.na(nn)]))
  if (length(u) == 2) return(as.numeric(nn == u[2]))
  if (is.factor(raw)) return(as.numeric(as.integer(raw) != 1))
  stop("cannot build dummy")
}

get_w <- function(d) {
  if ("weight" %in% names(d)) {
    w <- to_num(d$weight)
    if (sum(!is.na(w)) > 0) {
      w[is.na(w)] <- 1
      return(w)
    }
  }
  rep(1, nrow(d))
}

# Classify identity (3-way or 2-way) and tactic
classify_identity <- function(x) {
  ch <- to_chr(x)
  out <- rep(NA_character_, length(ch))
  out[grepl("black|tyrone|african", ch)] <- "black"
  out[grepl("ethiop", ch)] <- "ethiopian"
  out[grepl("arab", ch)] <- "arab"
  out[is.na(out) & grepl("white|charlie|jew|ashk", ch)] <- "white"
  if (all(is.na(out))) {
    # numeric coding fallback: ordered as white, (ethiopian/black), arab
    nn <- to_num(x)
    u <- sort(unique(nn[!is.na(nn)]))
    if (length(u) == 2) out <- ifelse(nn == u[1], "white", "black")
    if (length(u) == 3) out <- c("white", "ethiopian", "arab")[match(nn, u)]
  }
  out
}
classify_tactic <- function(x) {
  ch <- to_chr(x)
  out <- rep(NA_character_, length(ch))
  out[grepl("traffic|shut|block", ch)] <- "traffic"
  out[grepl("destroy|car|garbage|property|damage|violent", ch) & is.na(out)] <- "destroy"
  out[grepl("march|street|peace", ch) & is.na(out)] <- "march"
  if (all(is.na(out)) || any(is.na(out) & !is.na(x))) {
    if (is.factor(x)) {
      lv <- as.integer(x)
      out2 <- c("march", "traffic", "destroy")[lv]
      out[is.na(out)] <- out2[is.na(out)]
    } else {
      nn <- to_num(x)
      u <- sort(unique(nn[!is.na(nn)]))
      if (length(u) == 3) {
        out2 <- c("march", "traffic", "destroy")[match(nn, u)]
        out[is.na(out)] <- out2[is.na(out)]
      }
    }
  }
  out
}

fit <- function(y, X, w) {
  df <- data.frame(y = y, X, w = w)
  m <- lm(y ~ ., data = df[, setdiff(names(df), "w"), drop = FALSE], weights = df$w)
  m
}

# ---------------- Study 1 US ----------------
d <- us_survey_wave1
idn <- classify_identity(d$identity_protesters)
tac <- classify_tactic(d$tactic)
X <- data.frame(black = as.numeric(idn == "black"),
                traffic = as.numeric(tac == "traffic"),
                destroy = as.numeric(tac == "destroy"))
w <- get_w(d)
m_us1_v <- fit(to_num(d$degree_violence), X, w)
m_us1_p <- fit(to_num(d$police_action_required), X, w)

# ---------------- Study 1 Israel ----------------
d <- isr_survey_wave1
idn <- classify_identity(d$identity_protesters)
tac <- classify_tactic(d$tactic)
X <- data.frame(ethiopian = as.numeric(idn == "ethiopian"),
                arab = as.numeric(idn == "arab"),
                traffic = as.numeric(tac == "traffic"),
                destroy = as.numeric(tac == "destroy"))
w <- get_w(d)
m_is1_v <- fit(to_num(d$degree_violence), X, w)
m_is1_p <- fit(to_num(d$police_action_required), X, w)

# ---------------- Study 2 US ----------------
d <- us_survey_wave2
if ("black" %in% names(d)) {
  blk <- make_dummy(d$black, "black|tyrone|^1$|yes")
} else {
  blk <- as.numeric(classify_identity(d$identity_protesters_fac) == "black")
}
gg <- make_dummy(d$group_goal, "minor|group|racis|brutal|police|^1$|yes", "general|layoff|^0$|no")
cm <- make_dummy(d$commitment, "^yes|^commit|^1$|^nonviol|^explicit", "^no |^no$|^no_|^0$|none|without|^not")
X <- data.frame(black = blk, group_goal = gg, commitment = cm)
w <- get_w(d)
m_us2_v <- fit(to_num(d$degree_violence), X, w)
m_us2_p <- fit(to_num(d$police_action_required), X, w)

# ---------------- Study 2 Israel ----------------
d <- isr_survey_wave2
idn <- classify_identity(d$identity_protesters)
gg <- make_dummy(d$group_goal, "minor|group|racis|discrim|^1$|yes", "general|layoff|^0$|no")
cm <- make_dummy(d$commitment, "^yes|^commit|^1$|^nonviol|^explicit", "^no |^no$|^no_|^0$|none|without|^not")
X <- data.frame(ethiopian = as.numeric(idn == "ethiopian"),
                arab = as.numeric(idn == "arab"),
                group_goal = gg, commitment = cm)
w <- get_w(d)
m_is2_v <- tryCatch(fit(to_num(d$degree_violence), X, w), error = function(e) NULL)
n_is2 <- if (!is.null(m_is2_v)) nobs(m_is2_v) else nrow(d)

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
outi <- function(name, val) cat(sprintf("RESULT:%s=%d\n", name, as.integer(val)))

out("study1_us_black_perceived_violence", coef(m_us1_v)["black"])
out("study1_us_black_police_action", coef(m_us1_p)["black"])
out("study1_israel_ethiopian_perceived_violence", coef(m_is1_v)["ethiopian"])
out("study1_israel_ethiopian_police_action", coef(m_is1_p)["ethiopian"])
out("study1_israel_arab_perceived_violence", coef(m_is1_v)["arab"])
out("study1_israel_arab_police_action", coef(m_is1_p)["arab"])
out("study2_us_black_perceived_violence", coef(m_us2_v)["black"])
out("study2_us_black_police_action", coef(m_us2_p)["black"])
outi("respondents_study1_us", nobs(m_us1_v))
outi("respondents_study1_israel", nobs(m_is1_v))
outi("respondents_study2_us", nobs(m_us2_v))
outi("respondents_study2_israel", n_is2)
