suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance.script-free"
path <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta")
d <- as.data.frame(haven::zap_labels(haven::read_dta(path)))
d[] <- lapply(d, function(x) { if (inherits(x, "haven_labelled")) as.vector(x) else x })
nm <- names(d)

findv <- function(cands) {
  for (c in cands) {
    hit <- nm[nm == c]
    if (length(hit)) return(hit[1])
  }
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit)) return(hit[1])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# ---------- identify follow-up rows ----------
id_v <- findv(c("nstudent", "id", "student_id", "studentid"))
round_v <- findv(c("round", "Round", "wave", "survey_round", "followup", "fu", "time", "post"))
fu <- NULL
if (!is.na(round_v)) {
  rr <- num(d[[round_v]])
  ur <- sort(unique(rr[!is.na(rr)]))
  if (length(ur) >= 2) fu <- d[!is.na(rr) & rr == max(ur), , drop = FALSE]
}
if (is.null(fu) && !is.na(id_v) && any(duplicated(d[[id_v]]))) {
  o <- order(d[[id_v]])
  dd <- d[o, , drop = FALSE]
  # keep last occurrence per student (follow-up)
  fu <- dd[!duplicated(dd[[id_v]], fromLast = TRUE), , drop = FALSE]
}
if (is.null(fu)) fu <- d
cat("Rows in follow-up data:", nrow(fu), "\n")

# ---------- key variables ----------
treat_v <- findv(c("mixracebas", "mixroom", "MixRoom", "mixrace"))
race_fu <- findv(c("DscoreraceIAT"))
race_bl <- findv(c("DscoreraceIATbas"))
aca_fu <- findv(c("DscoreacaIAT"))
aca_bl <- findv(c("DscoreacaIATbas"))
res_v <- findv(c("Res_base", "residence", "Res"))
white_v <- findv(c("white"))
black_v <- findv(c("black"))
col_v <- findv(c("coloured"))
exams_v <- findv(c("examspassed"))
cont_v <- findv(c("continue"))
pca_v <- findv(c("PCAperf"))

gpa_cands <- nm[grepl("^z?gpa", tolower(nm)) & !grepl("2013|yr2|_fu|ro", tolower(nm))]
gpa_v <- findv(c("GPA", "GPA2012", "gpa", "gpa2012", "GPA_std", "zGPA", gpa_cands))

prog_cands <- nm[grepl("prog", tolower(nm)) & !grepl("^ro", nm)]
prog_v <- findv(c("program", "Program", "programme", "Programme", "acadprogram", "prog", prog_cands, "Faculty", "faculty"))

# working sample: non-missing race and academic IAT (follow-up and baseline)
w <- fu
keepvars <- c(race_fu, aca_fu, race_bl, aca_bl)
keepvars <- keepvars[!is.na(keepvars)]
ok <- rep(TRUE, nrow(w))
for (v in keepvars) ok <- ok & !is.na(num(w[[v]]))
if (sum(ok) < 300) {
  ok <- rep(TRUE, nrow(w))
  for (v in c(race_fu, aca_fu)[!is.na(c(race_fu, aca_fu))]) ok <- ok & !is.na(num(w[[v]]))
}
w <- w[ok, , drop = FALSE]
cat("Working sample:", nrow(w), "\n")

# ---------- build analysis frame ----------
A <- data.frame(row = seq_len(nrow(w)))
A$mix <- num(w[[treat_v]])
A$race_fu <- if (!is.na(race_fu)) num(w[[race_fu]]) else NA
A$race_bl <- if (!is.na(race_bl)) num(w[[race_bl]]) else NA
A$res <- if (!is.na(res_v)) as.character(w[[res_v]]) else "1"
A$white <- if (!is.na(white_v)) num(w[[white_v]]) else NA
A$black <- if (!is.na(black_v)) num(w[[black_v]]) else NA
A$white[is.na(A$white)] <- 0
A$black[is.na(A$black)] <- 0
A$coloured <- if (!is.na(col_v)) num(w[[col_v]]) else 0
A$coloured[is.na(A$coloured)] <- 0
A$other <- as.numeric(A$white == 0 & A$black == 0 & A$coloured == 0)
A$rg <- ifelse(A$black == 1, "B", ifelse(A$white == 1, "W", "O"))
A$rg_res <- paste(A$rg, A$res, sep = "_")
A$exams <- if (!is.na(exams_v)) num(w[[exams_v]]) else NA
A$cont <- if (!is.na(cont_v)) num(w[[cont_v]]) else NA
A$pca <- if (!is.na(pca_v)) num(w[[pca_v]]) else NA
g <- if (!is.na(gpa_v)) num(w[[gpa_v]]) else rep(NA_real_, nrow(w))
if (sum(!is.na(g)) > 10) {
  m <- mean(g, na.rm = TRUE); s <- sd(g, na.rm = TRUE)
  if (!(abs(m) < 0.15 && abs(s - 1) < 0.15)) g <- (g - m) / s
}
A$gpa <- g
if (!is.na(prog_v)) {
  p <- as.character(w[[prog_v]])
  p[is.na(p) | p == ""] <- "missing"
  A$prog <- p
} else A$prog <- "1"
cat("Treatment:", treat_v, " GPA:", gpa_v, " Program:", prog_v, "\n")

# controls
own_base <- c(findv(c("Female", "female")),
              findv(c("Falseuct2012", "falseuct2012")),
              findv(c("durpcabas_nomiss")),
              findv(c("consbas_nomiss")),
              findv(c("Foreign", "foreign")),
              findv(c("privateschool_nomiss")))
own_miss <- c(findv(c("missfalse", "Falseuct2012_miss", "falseuct_miss")),
              findv(c("durpcabas_miss")),
              findv(c("consbas_miss")),
              findv(c("foreign_missing", "Foreign_miss")),
              findv(c("privateschool_miss")))
ro_base <- c(findv(c("roFalseuct2012", "rofalseuct2012")),
             findv(c("rodurpcabas_nomiss")),
             findv(c("roconsbas_nomiss")),
             findv(c("roForeign_bas", "roForeign", "roforeign")),
             findv(c("roprivschool_nomiss", "roprivateschool_nomiss")))
ro_miss <- c(findv(c("romissfalse", "roFalseuct2012_miss")),
             findv(c("rodurpcabas_miss")),
             findv(c("roconsbas_miss")),
             findv(c("roforeign_missing", "roForeign_missing", "roForeign_miss")),
             findv(c("roprivschool_miss", "roprivateschool_miss")))
ctrl_src <- unique(c(own_base, own_miss, ro_base, ro_miss))
ctrl_src <- ctrl_src[!is.na(ctrl_src)]
ctrl_names <- character(0)
k <- 0
for (v in ctrl_src) {
  x <- num(w[[v]])
  if (all(is.na(x))) next
  k <- k + 1
  cn <- paste0("c", k)
  if (any(is.na(x))) {
    dn <- paste0(cn, "_md")
    A[[dn]] <- as.numeric(is.na(x))
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    ctrl_names <- c(ctrl_names, dn)
  }
  if (length(unique(x)) > 1) {
    A[[cn]] <- x
    ctrl_names <- c(ctrl_names, cn)
  }
}
ctrl_names <- ctrl_names[sapply(ctrl_names, function(v) length(unique(A[[v]])) > 1)]
cat("Controls used:", paste(ctrl_src, collapse = ", "), "\n")

# cluster: room
room_v <- findv(c("roomnum_base", "room_base", "roomid", "room_id", "roomnum", "room", "idroom", "roomno"))
if (is.na(room_v)) {
  rc <- nm[grepl("^room", tolower(nm)) & !grepl("mate", tolower(nm))]
  if (length(rc)) room_v <- rc[1]
}
if (!is.na(room_v)) {
  A$cl <- paste(A$res, as.character(w[[room_v]]), sep = "_")
  A$cl[is.na(w[[room_v]])] <- paste0("na_", which(is.na(w[[room_v]])))
} else {
  rid <- findv(c("ronstudent", "roommate_id", "roid", "roommateid"))
  if (!is.na(rid) && !is.na(id_v)) {
    a <- num(w[[id_v]]); b <- num(w[[rid]])
    A$cl <- ifelse(is.na(b), paste0("s", a), paste(pmin(a, b), pmax(a, b), sep = "_"))
  } else {
    A$cl <- as.character(seq_len(nrow(A)))
  }
}
cat("Cluster var:", room_v, " clusters:", length(unique(A$cl)), "\n")

ctrl_str <- if (length(ctrl_names)) paste("+", paste(ctrl_names, collapse = " + ")) else ""

run <- function(fml, data) {
  tryCatch({
    feols(as.formula(fml), data = data, cluster = ~cl)
  }, error = function(e) { cat("Error:", conditionMessage(e), "\n"); NULL })
}
getb <- function(m) {
  if (is.null(m)) return(NA_real_)
  b <- coef(m)["mix"]
  if (is.na(b)) NA_real_ else unname(b)
}
getn <- function(m) if (is.null(m)) NA_real_ else nobs(m)

W <- A[A$white == 1, ]
B <- A[A$black == 1, ]

# Table 3
f_iat <- paste("race_fu ~ mix + race_bl", ctrl_str, "| res")
m_iw <- run(f_iat, W)
m_ib <- run(f_iat, B)

# Table 4 (subsamples)
f_sub <- function(y) paste(y, "~ mix", ctrl_str, "| res + prog")
m_gb <- run(f_sub("gpa"), B)
m_eb <- run(f_sub("exams"), B)
m_cb <- run(f_sub("cont"), B)
m_pb <- run(f_sub("pca"), B)
m_gw <- run(f_sub("gpa"), W)

# Table 4 full sample
f_full <- function(y) paste(y, "~ mix + white + coloured + other", ctrl_str, "| rg_res + prog")
m_gf <- run(f_full("gpa"), A)
m_ef <- run(f_full("exams"), A)
m_pf <- run(f_full("pca"), A)

n_w <- if (!is.null(m_iw)) getn(m_iw) else nrow(W)
n_b <- if (!is.null(m_ib)) getn(m_ib) else nrow(B)
n_full <- if (!is.null(m_gf)) getn(m_gf) else nrow(A)

out <- function(name, val) cat(sprintf("RESULT:%s=%s\n", name, format(val, digits = 8)))
out("race_iat_mixed_room_whites_table3_col1", getb(m_iw))
out("race_iat_mixed_room_blacks_table3_col2", getb(m_ib))
out("n_obs_table3_whites", n_w)
out("n_obs_table3_blacks", n_b)
out("gpa_mixed_room_blacks_table4_panelB_col1", getb(m_gb))
out("exams_passed_mixed_room_blacks_table4_panelB_col2", getb(m_eb))
out("eligible_mixed_room_blacks_table4_panelB_col3", getb(m_cb))
out("performance_index_mixed_room_blacks_table4_panelB_col4", getb(m_pb))
out("gpa_mixed_room_whites_table4_panelA_col1", getb(m_gw))
out("gpa_mixed_room_full_table4_panelC_col1", getb(m_gf))
out("exams_passed_mixed_room_full_table4_panelC_col2", getb(m_ef))
out("performance_index_mixed_room_full_table4_panelC_col4", getb(m_pf))
out("n_obs_table4_panelC_cols1_2", n_full)