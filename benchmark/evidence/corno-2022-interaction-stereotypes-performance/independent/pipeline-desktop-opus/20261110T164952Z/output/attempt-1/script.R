suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance.script-free"
f_bal <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta")
f_cln <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_clean.dta")

strip <- function(d) {
  d <- as.data.frame(zap_labels(zap_formats(d)))
  d
}

raw <- strip(read_dta(f_bal))
cln <- tryCatch(strip(read_dta(f_cln)), error = function(e) NULL)

nm <- names(raw)
pick <- function(cands, data = raw) {
  for (c in cands) if (c %in% names(data)) return(c)
  low <- tolower(names(data))
  for (c in cands) {
    w <- which(low == tolower(c))
    if (length(w) > 0) return(names(data)[w[1]])
  }
  NA_character_
}

## ---- Keep follow-up observation (one row per student) ----
id_var <- pick(c("nstudent", "id", "studentid"))
round_var <- pick(c("round", "Round", "wave", "survey"))
dat <- raw
if (!is.na(round_var)) {
  rv <- dat[[round_var]]
  if (length(unique(na.omit(rv))) > 1) {
    dat <- dat[!is.na(rv) & rv == max(rv, na.rm = TRUE), ]
  }
}
if (!is.na(id_var) && any(duplicated(dat[[id_var]]))) {
  # keep row with non-missing follow-up IAT if possible, else last row
  dat$.__ok <- !is.na(dat$DscoreraceIAT)
  dat <- dat %>% group_by(.data[[id_var]]) %>%
    arrange(desc(.__ok), .by_group = TRUE) %>% slice(1) %>% ungroup() %>% as.data.frame()
  dat$.__ok <- NULL
}

## Bring in variables only available in the clean file (e.g., program, GPA, room)
if (!is.null(cln) && !is.na(id_var) && id_var %in% names(cln)) {
  extra <- setdiff(names(cln), names(dat))
  if (length(extra) > 0) {
    cl <- cln
    cr <- pick(c("round", "Round", "wave"), cl)
    if (!is.na(cr) && length(unique(na.omit(cl[[cr]]))) > 1) {
      cl <- cl[!is.na(cl[[cr]]) & cl[[cr]] == max(cl[[cr]], na.rm = TRUE), ]
    }
    cl <- cl[!duplicated(cl[[id_var]]), c(id_var, extra), drop = FALSE]
    dat <- left_join(dat, cl, by = id_var)
  }
}

## ---- Working sample ----
bal_var <- pick(c("balanced"), dat)
if (!is.na(bal_var) && length(unique(na.omit(dat[[bal_var]]))) > 1) {
  dat <- dat[!is.na(dat[[bal_var]]) & dat[[bal_var]] == 1, ]
}
iat_r <- pick(c("DscoreraceIAT"), dat); iat_rb <- pick(c("DscoreraceIATbas"), dat)
iat_a <- pick(c("DscoreacaIAT"), dat);  iat_ab <- pick(c("DscoreacaIATbas"), dat)
keep <- !is.na(dat[[iat_r]]) & !is.na(dat[[iat_a]])
if (!is.na(iat_rb)) keep <- keep & !is.na(dat[[iat_rb]])
if (!is.na(iat_ab)) keep <- keep & !is.na(dat[[iat_ab]])
dat <- dat[keep, ]

treat <- pick(c("mixracebas", "MixRoom", "mixroom", "mixrace"), dat)
dat$MixRoom <- as.numeric(dat[[treat]])
dat <- dat[!is.na(dat$MixRoom), ]

## ---- Race ----
if ("white" %in% names(dat) && "black" %in% names(dat)) {
  dat$is_white <- as.numeric(dat$white == 1)
  dat$is_black <- as.numeric(dat$black == 1)
} else {
  dat$is_white <- as.numeric(dat$Race == 2)
  dat$is_black <- as.numeric(dat$Race == 1)
}
dat$is_white[is.na(dat$is_white)] <- 0
dat$is_black[is.na(dat$is_black)] <- 0
col_v <- pick(c("coloured"), dat)
dat$is_col <- if (!is.na(col_v)) { x <- as.numeric(dat[[col_v]] == 1); x[is.na(x)] <- 0; x } else 0
dat$is_else <- as.numeric(dat$is_white == 0 & dat$is_black == 0 & dat$is_col == 0)
dat$racegrp <- ifelse(dat$is_black == 1, "B", ifelse(dat$is_white == 1, "W", "O"))

## ---- Residence, room, program ----
res_v <- pick(c("Res_base", "res_base", "residence"), dat)
dat$res <- as.character(dat[[res_v]])
dat$race_res <- paste(dat$racegrp, dat$res, sep = "_")

room_v <- pick(c("roomnum_base", "room_base", "roomid", "room", "roomnum", "room_id", "idroom"), dat)
if (is.na(room_v)) {
  # try to build room id from student id and roommate id
  rid <- pick(c("ronstudent", "roid", "roommate_id"), dat)
  if (!is.na(rid) && !is.na(id_var)) {
    a <- dat[[id_var]]; b <- dat[[rid]]
    dat$room <- ifelse(is.na(b), paste0("s", a), paste(pmin(a, b), pmax(a, b), sep = "_"))
  } else if (!is.na(id_var)) {
    dat$room <- dat[[id_var]]
  } else dat$room <- seq_len(nrow(dat))
} else {
  dat$room <- paste(dat$res, dat[[room_v]], sep = "_")
  dat$room[is.na(dat[[room_v]])] <- paste0("m", which(is.na(dat[[room_v]])))
}

prog_v <- pick(c("regprog", "program", "Program", "acadprog", "prog", "Faculty"), dat)
dat$prog <- if (!is.na(prog_v)) { x <- as.character(dat[[prog_v]]); x[is.na(x) | x == ""] <- "missing"; x } else "all"

## ---- Controls with mean imputation + missing dummies ----
own_c <- list(
  uct = c("Falseuct2012", "falseuct2012", "uct2012"),
  wealth = c("durpcabas_nomiss", "durpcabas"),
  cons = c("consbas_nomiss", "consbas"),
  foreign = c("Foreign", "foreign"),
  priv = c("privschool_nomiss", "privateschool_nomiss", "privschool", "privateschool")
)
ro_c <- list(
  ro_uct = c("roFalseuct2012", "rofalseuct2012"),
  ro_wealth = c("rodurpcabas_nomiss", "rodurpcabas"),
  ro_cons = c("roconsbas_nomiss", "roconsbas"),
  ro_foreign = c("roForeign", "roforeign"),
  ro_priv = c("roprivschool_nomiss", "roprivateschool_nomiss", "roprivschool")
)
ctrl <- c()
add_ctrl <- function(newname, cands) {
  v <- pick(cands, dat)
  if (is.na(v)) return(invisible(NULL))
  x <- as.numeric(dat[[v]])
  if (grepl("uct", newname) && mean(x, na.rm = TRUE) > 10) x <- x / 1000
  if (any(is.na(x))) {
    dat[[paste0(newname, "_mi")]] <<- as.numeric(is.na(x))
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    ctrl <<- c(ctrl, paste0(newname, "_mi"))
  }
  dat[[newname]] <<- x
  ctrl <<- c(ctrl, newname)
}
fem <- pick(c("Female", "female"), dat)
dat$female_c <- as.numeric(dat[[fem]]); dat$female_c[is.na(dat$female_c)] <- mean(dat$female_c, na.rm = TRUE)
for (n in names(own_c)) add_ctrl(n, own_c[[n]])
for (n in names(ro_c)) add_ctrl(n, ro_c[[n]])
# existing missing-value indicators in data (e.g., foreign_missing, *_miss)
miss_existing <- grep("(^(ro)?foreign_missing$)|(^(ro)?missfalse$)|([^o]_miss$)", names(dat), value = TRUE)
miss_existing <- setdiff(miss_existing, ctrl)
for (m in miss_existing) {
  x <- as.numeric(dat[[m]]); x[is.na(x)] <- 0
  if (length(unique(x)) > 1) { dat[[m]] <- x; ctrl <- c(ctrl, m) }
}
ctrl_all <- c("female_c", ctrl)

## ---- Regression helpers ----
run <- function(y, sub, fe, extra = NULL, ctrls = ctrl_all) {
  d <- dat[sub, ]
  d <- d[!is.na(d[[y]]), ]
  rhs <- c("MixRoom", extra, ctrls)
  rhs <- rhs[sapply(rhs, function(v) length(unique(d[[v]])) > 1)]
  rhs <- unique(c("MixRoom", rhs))
  fml <- as.formula(paste(y, "~", paste(rhs, collapse = " + "), "|", paste(fe, collapse = " + ")))
  m <- tryCatch(feols(fml, data = d, cluster = ~room), error = function(e) NULL)
  m
}
getb <- function(m) if (is.null(m)) NA else unname(coef(m)["MixRoom"])
getse <- function(m) if (is.null(m)) NA else unname(sqrt(diag(vcov(m)))["MixRoom"])

wh <- dat$is_white == 1
bl <- dat$is_black == 1
al <- rep(TRUE, nrow(dat))

## ---- Table 3 ----
m_w_r <- run(iat_r, wh, "res", extra = iat_rb)
m_b_r <- run(iat_r, bl, "res", extra = iat_rb)

## ---- Table 4 outcomes ----
gpa_v <- pick(c("GPA", "gpa", "zGPA", "GPA2012", "GPA_std", "stdGPA", "GPA2012_std", "zgpa"), dat)
if (is.na(gpa_v)) {
  g <- grep("gpa", names(dat), ignore.case = TRUE, value = TRUE)
  g <- g[!grepl("2013|2014|fu|fwer|yr2|ro", g, ignore.case = TRUE)]
  gpa_v <- if (length(g)) g[1] else NA
}
if (!is.na(gpa_v)) {
  x <- as.numeric(dat[[gpa_v]])
  if (abs(sd(x, na.rm = TRUE) - 1) > 0.05 || abs(mean(x, na.rm = TRUE)) > 0.05) x <- (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
  dat$gpa_z <- x
}
ex_v <- pick(c("examspassed", "examspassed2012"), dat)
ct_v <- pick(c("continue", "continue2012"), dat)
pc_v <- pick(c("PCAperf", "pcaperf"), dat)
if (is.na(pc_v) && !is.na(gpa_v) && !is.na(ex_v) && !is.na(ct_v)) {
  cc <- complete.cases(dat[, c("gpa_z", ex_v, ct_v)])
  pc <- prcomp(dat[cc, c("gpa_z", ex_v, ct_v)], scale. = TRUE)
  s <- pc$x[, 1]; if (cor(s, dat$gpa_z[cc]) < 0) s <- -s
  dat$PCAperf_c <- NA; dat$PCAperf_c[cc] <- s; pc_v <- "PCAperf_c"
}
if (!is.na(ct_v)) { x <- as.numeric(dat[[ct_v]]); if (max(x, na.rm = TRUE) > 1) x <- as.numeric(x > 0); dat[[ct_v]] <- x }

fe_sub <- c("res", "prog")
fe_full <- c("race_res", "prog")
race_d <- c("is_white", "is_col", "is_else")

m_b_gpa <- if (!is.na(gpa_v)) run("gpa_z", bl, fe_sub) else NULL
m_b_ex <- if (!is.na(ex_v)) run(ex_v, bl, fe_sub) else NULL
m_b_ct <- if (!is.na(ct_v)) run(ct_v, bl, fe_sub) else NULL
m_b_pc <- if (!is.na(pc_v)) run(pc_v, bl, fe_sub) else NULL
m_w_gpa <- if (!is.na(gpa_v)) run("gpa_z", wh, fe_sub) else NULL
m_f_gpa <- if (!is.na(gpa_v)) run("gpa_z", al, fe_full, extra = race_d) else NULL
m_f_ex <- if (!is.na(ex_v)) run(ex_v, al, fe_full, extra = race_d) else NULL
m_f_pc <- if (!is.na(pc_v)) run(pc_v, al, fe_full, extra = race_d) else NULL

fmt <- function(x) if (is.na(x)) "NA" else formatC(x, digits = 6, format = "f")
out <- function(n, v) cat(sprintf("RESULT:%s=%s\n", n, fmt(v)))

out("race_iat_mixed_room_whites_table3_col1", getb(m_w_r))
out("race_iat_mixed_room_blacks_table3_col2", getb(m_b_r))
out("n_obs_table3_whites", if (is.null(m_w_r)) sum(wh) else nobs(m_w_r))
out("n_obs_table3_blacks", if (is.null(m_b_r)) sum(bl) else nobs(m_b_r))
out("gpa_mixed_room_blacks_table4_panelB_col1", getb(m_b_gpa))
out("exams_passed_mixed_room_blacks_table4_panelB_col2", getb(m_b_ex))
out("eligible_mixed_room_blacks_table4_panelB_col3", getb(m_b_ct))
out("performance_index_mixed_room_blacks_table4_panelB_col4", getb(m_b_pc))
out("gpa_mixed_room_whites_table4_panelA_col1", getb(m_w_gpa))
out("gpa_mixed_room_full_table4_panelC_col1", getb(m_f_gpa))
out("exams_passed_mixed_room_full_table4_panelC_col2", getb(m_f_ex))
out("performance_index_mixed_room_full_table4_panelC_col4", getb(m_f_pc))
out("n_obs_table4_panelC_cols1_2", if (is.null(m_f_gpa)) nrow(dat) else nobs(m_f_gpa))