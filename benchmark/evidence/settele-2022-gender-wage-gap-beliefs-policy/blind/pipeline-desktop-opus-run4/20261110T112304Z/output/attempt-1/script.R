suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy.script-free/data"
rd <- function(f) as.data.frame(read_dta(file.path(root, f)))
A  <- rd("SurveyStageI_WaveA_raw.dta")
B  <- rd("SurveyStageI_WaveB_raw.dta")
FA <- rd("SurveyStageII_WaveA_raw.dta")
FB <- rd("SurveyStageII_WaveB_raw.dta")

message("Stage I wave A columns: ", paste(names(A), collapse = " "))
message("Stage I wave B columns: ", paste(names(B), collapse = " "))

res <- list()
put <- function(nm, expr) {
  v <- tryCatch(expr, error = function(e) { message("ERROR in ", nm, ": ", conditionMessage(e)); NA_real_ })
  if (length(v) == 0 || is.null(v)) v <- NA_real_
  res[[nm]] <<- as.numeric(v[1])
}

# ---------------- helpers ----------------
nonTime <- function(nm) nm[!grepl("Time$", nm)]
fexact <- function(d, cands) {
  nm <- names(d)
  for (cc in cands) {
    h <- nm[tolower(nm) == tolower(cc)]
    if (length(h)) return(h[1])
  }
  NA_character_
}
fregex <- function(d, pats, excl = NULL) {
  nm <- nonTime(names(d))
  if (!is.null(excl)) nm <- nm[!grepl(excl, nm, ignore.case = TRUE)]
  for (p in pats) {
    h <- nm[grepl(p, nm, ignore.case = TRUE)]
    if (length(h)) return(h[1])
  }
  NA_character_
}
tonum <- function(x) {
  x <- zap_labels(x)
  if (is.numeric(x)) return(as.numeric(x))
  x <- trimws(as.character(x)); x[x == ""] <- NA
  y <- suppressWarnings(as.numeric(x))
  if (sum(!is.na(x)) > 0 && mean(is.na(y[!is.na(x)])) > 0.5)
    y <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", x)))
  y
}
scale_item <- function(raw) {
  labs <- attr(raw, "labels")
  x <- tonum(raw)
  if (!is.null(labs) && length(labs) >= 2) {
    lv <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", as.character(labs))))
    ln <- tolower(names(labs))
    dk <- grepl("know|refuse|prefer not|no answer|not sure", ln)
    x[x %in% lv[dk & !is.na(lv)]] <- NA
    keep <- !dk & !is.na(lv)
    lv2 <- lv[keep]; ln2 <- ln[keep]
    if (length(lv2) >= 2) {
      lo <- ln2[which.min(lv2)]; hi <- ln2[which.max(lv2)]
      neg <- "disagree|oppose|small|not |not$|^no|none|less|decrease|weak|never"
      if (grepl(neg, hi) && !grepl(neg, lo)) x <- max(lv2) + min(lv2) - x
    }
  }
  x
}
zc <- function(x, ref) {
  m <- mean(x[ref], na.rm = TRUE); s <- sd(x[ref], na.rm = TRUE)
  (x - m) / s
}
coalesce_num <- function(lst) {
  if (length(lst) == 0) return(NULL)
  out <- lst[[1]]
  if (length(lst) > 1) for (k in 2:length(lst)) out <- ifelse(is.na(out), lst[[k]], out)
  out
}
anderson <- function(Z, ref) {
  Z <- as.matrix(Z)
  Z[!is.finite(Z)] <- NA
  keep <- colSums(!is.na(Z)) > 0
  Z <- Z[, keep, drop = FALSE]
  S <- cov(Z, use = "pairwise.complete.obs")
  w <- tryCatch(rowSums(solve(S)), error = function(e) rep(1, ncol(Z)))
  W <- matrix(w, nrow(Z), ncol(Z), byrow = TRUE); W[is.na(Z)] <- 0
  Z0 <- Z; Z0[is.na(Z0)] <- 0
  idx <- rowSums(W * Z0) / rowSums(W)
  idx[rowSums(!is.na(Z)) == 0] <- NA
  zc(idx, ref)
}

get_female <- function(d) {
  c1 <- fexact(d, c("female", "woman", "fem"))
  if (!is.na(c1)) return(tonum(d[[c1]]))
  c1 <- fexact(d, c("gender", "sex", "genderII"))
  if (is.na(c1)) return(rep(NA_real_, nrow(d)))
  raw <- d[[c1]]; labs <- attr(raw, "labels"); x0 <- zap_labels(raw)
  if (!is.null(labs)) {
    fl <- grepl("^f|female|wom", tolower(names(labs)))
    if (sum(fl) == 1) {
      s <- as.character(x0)
      return(ifelse(is.na(x0) | s == "", NA, as.numeric(s == as.character(labs[fl]))))
    }
  }
  if (is.character(x0)) {
    s <- tolower(trimws(x0))
    return(ifelse(s == "", NA, as.numeric(s %in% c("f", "female", "woman", "w", "a2", "2"))))
  }
  x <- as.numeric(x0); u <- sort(unique(na.omit(x)))
  if (all(u %in% c(0, 1))) return(x)
  if (all(u %in% c(1, 2))) return(as.numeric(x == 2))
  as.numeric(x == max(u))
}

get_post <- function(d) {
  pcs <- nonTime(names(d))
  pcs <- pcs[grepl("^posterior", pcs, ignore.case = TRUE) &
               !grepl("rand|order|version|anchor|II$|incent|note|text|comment|conf|certain|sure", pcs, ignore.case = TRUE)]
  message("posterior columns: ", paste(pcs, collapse = " "))
  if (!length(pcs)) return(rep(NA_real_, nrow(d)))
  coalesce_num(lapply(pcs, function(p) tonum(d[[p]])))
}

assign_groups <- function(raw, post) {
  labs <- attr(raw, "labels")
  x0 <- zap_labels(raw)
  if (is.character(x0)) { x <- trimws(x0); x[x == ""] <- NA } else x <- as.numeric(x0)
  u <- sort(unique(x[!is.na(x)]))
  if (length(u) < 2 || length(u) > 3) return(NULL)
  key <- as.character(u)
  lab <- key
  if (!is.null(labs)) {
    for (i in seq_along(u)) {
      j <- which(as.character(labs) == key[i])
      if (length(j)) lab[i] <- names(labs)[j[1]]
    }
  }
  g <- rep(NA_character_, length(u))
  g[grepl("74", lab)] <- "T74"
  g[grepl("94", lab)] <- "T94"
  g[grepl("control|no info|none|pure", lab, ignore.case = TRUE)] <- "C"
  n74 <- sum(g == "T74", na.rm = TRUE); n94 <- sum(g == "T94", na.rm = TRUE)
  if (n74 == 1 && n94 == 1) {
    if (length(u) == 3) g[is.na(g)] <- "C"
  } else {
    if (is.null(post) || length(u) != 3) return(NULL)
    m <- sapply(u, function(v) mean(post[!is.na(x) & x == v], na.rm = TRUE))
    g <- rep(NA_character_, 3)
    if (sum(!is.finite(m)) == 1) {
      g[!is.finite(m)] <- "C"
      fi <- which(is.finite(m))
      g[fi[which.min(m[fi])]] <- "T74"; g[fi[which.max(m[fi])]] <- "T94"
    } else if (all(is.finite(m))) {
      o <- order(m); g[o[1]] <- "T74"; g[o[3]] <- "T94"; g[o[2]] <- "C"
    } else return(NULL)
  }
  out <- ifelse(is.na(x), NA_character_, g[match(as.character(x), key)])
  if (length(u) == 2) {
    if (mean(is.na(x)) < 0.15) return(NULL)
    out[is.na(x)] <- "C"
  }
  out
}

scan74 <- function(d) {
  nm <- nonTime(names(d))
  ord <- c(nm[!grepl("anchor", nm, ignore.case = TRUE)], nm[grepl("anchor", nm, ignore.case = TRUE)])
  for (cn in ord) {
    x0 <- zap_labels(d[[cn]])
    if (is.numeric(x0)) {
      u <- sort(unique(x0[!is.na(x0)]))
      if (length(u) == 2 && all(u == c(74, 94))) {
        message("treatment from values of ", cn)
        return(ifelse(is.na(x0), "C", ifelse(x0 == 74, "T74", "T94")))
      }
    } else if (is.character(x0)) {
      s <- trimws(x0); s[s == ""] <- NA
      u <- unique(s[!is.na(s)])
      if (length(u) >= 2 && length(u) <= 3) {
        h74 <- grepl("74", u) & !grepl("94", u); h94 <- grepl("94", u) & !grepl("74", u)
        if (sum(h74) == 1 && sum(h94) == 1) {
          message("treatment from text of ", cn)
          return(ifelse(is.na(s), "C", ifelse(s == u[h74], "T74", ifelse(s == u[h94], "T94", "C"))))
        }
      }
    }
  }
  NULL
}

get_tgroup <- function(d, post) {
  c74 <- fexact(d, c("T74", "treat74", "treatment74", "T_74", "info74"))
  if (!is.na(c74)) {
    t74 <- tonum(d[[c74]])
    c94 <- fexact(d, c("T94", "treat94", "treatment94", "T_94", "info94"))
    cc <- fexact(d, c("control", "controlgroup", "purecontrol", "pc"))
    if (!is.na(c94)) {
      t94 <- tonum(d[[c94]])
      message("treatment from dummies ", c74, " / ", c94)
      return(ifelse(t74 %in% 1, "T74", ifelse(t94 %in% 1, "T94", "C")))
    }
    if (!is.na(cc)) {
      ctl <- tonum(d[[cc]])
      message("treatment from dummies ", c74, " / ", cc)
      return(ifelse(ctl %in% 1, "C", ifelse(t74 %in% 1, "T74", "T94")))
    }
  }
  for (cn in c("treatment", "treat", "group", "treatmentgroup", "condition", "arm", "info",
               "infotreatment", "rand", "randtreat", "randomization", "treatmentrand",
               "randgroup", "tgroup", "randinfo", "treatgroup")) {
    c1 <- fexact(d, cn); if (is.na(c1)) next
    r <- assign_groups(d[[c1]], post)
    if (!is.null(r)) { message("treatment from group column ", c1); return(r) }
  }
  r <- scan74(d)
  if (!is.null(r)) return(r)
  nm <- names(d)
  t74 <- nm[grepl("74", nm) & grepl("Time$", nm)]; t94 <- nm[grepl("94", nm) & grepl("Time$", nm)]
  if (length(t74) == 1 && length(t94) == 1) {
    a <- tonum(d[[t74]]); b <- tonum(d[[t94]])
    message("treatment from timing columns ", t74, " / ", t94)
    return(ifelse(!is.na(a) & a > 0, "T74", ifelse(!is.na(b) & b > 0, "T94", "C")))
  }
  message("WARNING: treatment assignment not found")
  rep(NA_character_, nrow(d))
}

getitem <- function(d, exact, pats, excl = NULL, label = "") {
  c1 <- fexact(d, exact)
  if (is.na(c1)) c1 <- fregex(d, pats, excl)
  message("item ", label, " -> ", c1)
  if (is.na(c1)) return(rep(NA_real_, nrow(d)))
  scale_item(d[[c1]])
}

dum <- c("midwest", "south", "west", "age1", "age2", "age3", "age4", "anychildren", "loghhinc",
         "associatemore", "fulltime", "parttime", "selfemp", "unemployed", "student",
         "democrat", "indep", "otherpol")

base_vars <- function(d, wb) {
  n <- nrow(d)
  o <- data.frame(row = seq_len(n))
  o$waveB <- wb
  idc <- fexact(d, c("panelID", "panelid", "panel_id", "pid", "respondentid"))
  o$id <- if (!is.na(idc)) as.character(zap_labels(d[[idc]])) else NA_character_
  pc <- fexact(d, c("pweight", "weight", "weights", "pw"))
  o$pweight <- if (!is.na(pc)) tonum(d[[pc]]) else 1
  prc <- fexact(d, c("prior", "priorbelief", "prior1"))
  if (is.na(prc)) prc <- fregex(d, c("^prior"), "II$|incent|conf|rand|order")
  message("prior -> ", prc)
  o$prior <- if (!is.na(prc)) tonum(d[[prc]]) else NA_real_
  o$female <- get_female(d)
  for (v in dum) {
    c1 <- fexact(d, v)
    o[[v]] <- if (!is.na(c1)) tonum(d[[c1]]) else NA_real_
  }
  for (fb in c("region", "employment", "education", "hhincome")) {
    c1 <- fexact(d, fb)
    o[[paste0("fb_", fb)]] <- if (!is.na(c1)) as.character(zap_labels(d[[c1]])) else NA_character_
  }
  ac <- fexact(d, c("age"))
  ag <- if (!is.na(ac)) tonum(d[[ac]]) else rep(NA_real_, n)
  o$agecat <- as.character(cut(ag, c(-Inf, 24, 34, 44, 54, Inf)))
  o
}

mk <- function(d, wb) {
  o <- base_vars(d, wb)
  o$post <- get_post(d)
  o$tg <- get_tgroup(d, o$post)
  o$large   <- getitem(d, c("large", "wagegaplarge", "gaplarge", "biggap", "sizegap", "gapsize"),
                       c("large"), "company|firm|size$", "large")
  o$problem <- getitem(d, c("problem", "wageproblem", "gapproblem"), c("problem"), NULL, "problem")
  o$gov     <- getitem(d, c("gov", "government", "govmore", "govdo", "govaction", "govwomen"),
                       c("^gov"), "effective|trust", "gov")
  o$quota   <- getitem(d, c("quota", "quotas", "genderquota"), c("quota"), "calculation", "quota")
  o$aa      <- getitem(d, c("affirmativeaction", "affirmative", "aa"), c("affirm"), NULL, "aa")
  o$legis   <- getitem(d, c("legislation", "equalpay", "equalpaylegislation"),
                       c("^legislation", "equalpay", "legislation"), "anchor", "legislation")
  o$transp  <- getitem(d, c("transparency"), c("^transparen", "transparen"), "anchor", "transparency")
  o$website <- getitem(d, c("website", "reportingwebsite", "reporting"), c("website", "webpage", "portal"),
                       NULL, "website")
  o$child   <- getitem(d, c("childcare", "daycare", "childcaresubsidies", "childcaresubsidy"),
                       c("childcare", "daycare", "child.?care"), "anychild|nchild", "childcare")
  o
}

oA <- mk(A, 0)
oB <- mk(B, 1)
D <- rbind(oA, oB)
message("Treatment groups: "); print(table(D$tg, D$waveB, useNA = "ifany"))

C <- D$tg %in% "C"
iA <- D$waveB == 0; iB <- D$waveB == 1

# z-score outcomes on pure control group
D$z_large <- zc(D$large, C)
D$z_problem <- zc(D$problem, C)
D$z_gov <- zc(D$gov, C)
D$z_quota <- zc(D$quota, C)
D$z_aa <- zc(D$aa, C)
D$z_legis <- zc(D$legis, C)
D$z_child <- zc(D$child, C)
D$z_pol4 <- NA_real_
D$z_pol4[iA] <- zc(D$transp, C & iA)[iA]
D$z_pol4[iB] <- zc(D$website, C & iB)[iB]
D$z_pol4[!is.finite(D$z_pol4)] <- NA

D$perc_idx <- anderson(D[, c("z_large", "z_problem", "z_gov")], C)
D$pol_idx  <- anderson(D[, c("z_quota", "z_aa", "z_legis", "z_pol4", "z_child")], C)

D$prior_z <- zc(D$prior, C)
if (sum(!is.na(D$post[C])) >= 30) {
  D$post_z <- zc(D$post, C)
} else {
  D$post_z <- zc(D$post, D$tg %in% c("T74", "T94"))
}

# ---------------- Table 3 / 4: correlates in trimmed control group ----------------
q <- quantile(D$prior[C], c(0.05, 0.95), na.rm = TRUE, type = 2)
S3 <- D[C & !is.na(D$prior) & D$prior > q[1] & D$prior < q[2], ]
message("Table 3 sample size: ", nrow(S3))

put("perception_index_democrat_table3_panelA_col4", {
  m <- feols(perc_idx ~ democrat + female + indep + otherpol + waveB, data = S3,
             weights = ~pweight, vcov = "hetero")
  coef(m)["democrat"]
})
put("perception_index_female_table3_panelA_col4", {
  m <- feols(perc_idx ~ democrat + female + indep + otherpol + waveB, data = S3,
             weights = ~pweight, vcov = "hetero")
  coef(m)["female"]
})
put("perception_index_prior_table3_panelB_col4", {
  m <- feols(perc_idx ~ prior_z + waveB, data = S3, weights = ~pweight, vcov = "hetero")
  coef(m)["prior_z"]
})
put("n_obs_table3", {
  m <- feols(perc_idx ~ prior_z + waveB, data = S3, weights = ~pweight, vcov = "hetero")
  nobs(m)
})
put("policy_demand_index_democrat_table4_panelA_col7", {
  m <- feols(pol_idx ~ democrat + female + indep + otherpol + waveB, data = S3,
             weights = ~pweight, vcov = "hetero")
  coef(m)["democrat"]
})
put("policy_demand_index_prior_table4_panelB_col7", {
  m <- feols(pol_idx ~ prior_z + waveB, data = S3, weights = ~pweight, vcov = "hetero")
  coef(m)["prior_z"]
})

# ---------------- Table 5: treatment effects, treatment arms only ----------------
okvar <- function(df, z) z %in% names(df) && sum(!is.na(df[[z]])) > 0.5 * nrow(df) &&
  length(unique(na.omit(df[[z]]))) > 1
rhs_controls <- function(df) {
  v <- c("waveB", "female", "prior")
  v <- v[sapply(v, function(z) okvar(df, z))]
  dm <- dum[sapply(dum, function(z) okvar(df, z))]
  v <- c(v, dm)
  if (!any(c("midwest", "south", "west") %in% v) && okvar(df, "fb_region")) v <- c(v, "factor(fb_region)")
  if (!any(c("age1", "age2", "age3", "age4") %in% v) && okvar(df, "agecat")) v <- c(v, "factor(agecat)")
  if (!any(c("fulltime", "parttime", "selfemp", "unemployed", "student") %in% v) && okvar(df, "fb_employment"))
    v <- c(v, "factor(fb_employment)")
  if (!("associatemore" %in% v) && okvar(df, "fb_education")) v <- c(v, "factor(fb_education)")
  if (!("loghhinc" %in% v) && okvar(df, "fb_hhincome")) v <- c(v, "factor(fb_hhincome)")
  message("controls: ", paste(v, collapse = " "))
  v
}

TT <- D[D$tg %in% c("T74", "T94"), ]
TT$T74 <- as.numeric(TT$tg == "T74")
rhs <- rhs_controls(TT)
rhs_s <- paste(rhs, collapse = " + ")
ols <- function(y, df) feols(as.formula(paste(y, "~ T74 +", rhs_s)), data = df,
                             weights = ~pweight, vcov = "hetero")
iv <- function(y, df) feols(as.formula(paste(y, "~", rhs_s, "| post_z ~ T74")), data = df,
                            weights = ~pweight, vcov = "hetero")

put("first_stage_posterior_raw_t74_table5_panelA_col1", coef(ols("post", TT))["T74"])
put("first_stage_posterior_z_t74_table5_panelA_col2", coef(ols("post_z", TT))["T74"])
put("perception_index_t74_table5_panelA_col6", coef(ols("perc_idx", TT))["T74"])
put("iv_affirmative_action_posterior_table5_panelC_col2", coef(iv("z_aa", TT))["fit_post_z"])
put("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(iv("z_legis", TT))["fit_post_z"])
put("iv_policy_demand_index_posterior_table5_panelC_col7", coef(iv("pol_idx", TT))["fit_post_z"])

# ---------------- Table 6: follow-up survey ----------------
put("followup_perception_index_t74_table6_panelA_col7", {
  mkF <- function(d, wb) {
    o <- base_vars(d, wb)
    g <- function(cands) {
      for (c1 in cands) if (c1 %in% names(d)) return(scale_item(d[[c1]]))
      rep(NA_real_, nrow(d))
    }
    o$f_prob <- coalesce_num(list(g("wageproblemSQ001"), g("wageproblem2SQ001")))
    o$f_high <- coalesce_num(list(g("wageproblemSQ002"), g("wageproblem2SQ002")))
    o$f_low  <- coalesce_num(list(g("wageproblemSQ003"), g("wageproblem2SQ003")))
    o$f_gov  <- g("govwomen")
    o$rand <- if ("rand" %in% names(d)) tonum(d$rand) else NA_real_
    o$postII <- if ("posteriorII" %in% names(d)) tonum(d$posteriorII) else NA_real_
    o
  }
  F <- rbind(mkF(FA, 0), mkF(FB, 1))
  key <- D[!is.na(D$id), c("id", "waveB", "tg")]
  key <- key[!duplicated(key[, c("id", "waveB")]), ]
  Fm <- merge(F, key, by = c("id", "waveB"), all.x = TRUE)
  message("Follow-up rows: ", nrow(Fm), "; matched treatment: ", sum(!is.na(Fm$tg)))
  if (sum(Fm$tg %in% c("T74", "T94")) < 0.5 * nrow(Fm)) {
    u <- sort(unique(na.omit(Fm$rand)))
    if (length(u) == 2) {
      m <- sapply(u, function(v) mean(Fm$postII[Fm$rand %in% v], na.rm = TRUE))
      lowv <- u[which.min(m)]
      Fm$tg <- ifelse(is.na(Fm$rand), NA, ifelse(Fm$rand == lowv, "T74", "T94"))
      message("Follow-up treatment from rand column")
    }
  }
  Fm <- Fm[Fm$tg %in% c("T74", "T94"), ]
  Fm$T74 <- as.numeric(Fm$tg == "T74")
  allr <- rep(TRUE, nrow(Fm))
  Z <- data.frame(a = zc(Fm$f_prob, allr), b = zc(Fm$f_gov, allr),
                  c = zc(Fm$f_high, allr), d = zc(Fm$f_low, allr))
  Fm$f_idx <- anderson(Z, allr)
  rf <- rhs_controls(Fm)
  m <- feols(as.formula(paste("f_idx ~ T74 +", paste(rf, collapse = " + "))), data = Fm,
             weights = ~pweight, vcov = "hetero")
  coef(m)["T74"]
})

# ---------------- output ----------------
for (nm in names(res)) {
  v <- res[[nm]]
  cat(sprintf("RESULT:%s=%s\n", nm, ifelse(is.na(v), "NA", format(v, digits = 10))))
}