suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance.script-free"
fpath <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta")
d0 <- haven::read_dta(fpath)
d0 <- as.data.frame(haven::zap_labels(d0))
message("Columns: ", paste(names(d0), collapse = " "))
message("Rows: ", nrow(d0))

findcol <- function(cands, data = d0) {
  n <- names(data)
  for (cc in cands) if (cc %in% n) return(cc)
  for (cc in cands) {
    i <- which(tolower(n) == tolower(cc))
    if (length(i)) return(n[i[1]])
  }
  NA_character_
}

results <- list()
setres <- function(name, val) {
  if (is.null(val) || length(val) == 0) val <- NA
  results[[name]] <<- as.numeric(val)[1]
}

# ---------------- Identify key variables ----------------
idv   <- findcol(c("nstudent", "id", "student_id", "studentid"))
rv    <- findcol(c("round", "Round", "wave", "survey_round", "period", "time"))
treat <- findcol(c("mixracebas", "MixRoom", "mixroom", "mixrace", "mixed_room"))
resv  <- findcol(c("Res_base", "residence", "res_base", "Res"))
raceIAT   <- findcol(c("DscoreraceIAT"))
acaIAT    <- findcol(c("DscoreacaIAT"))
raceIATb  <- findcol(c("DscoreraceIATbas"))
acaIATb   <- findcol(c("DscoreacaIATbas"))
message("id=", idv, " round=", rv, " treat=", treat, " res=", resv)

d <- d0
# Keep follow-up observations if the data are in long format
if (!is.na(rv)) {
  vals <- sort(unique(d[[rv]][!is.na(d[[rv]])]))
  message("Round values: ", paste(vals, collapse = ","))
  if (length(vals) > 1) {
    # construct baseline IATs if not already present
    if (is.na(raceIATb) && !is.na(idv)) {
      b <- d[!is.na(d[[rv]]) & d[[rv]] == min(vals), c(idv, raceIAT, acaIAT)]
      names(b) <- c(idv, "DscoreraceIATbas", "DscoreacaIATbas")
      b <- b[!duplicated(b[[idv]]), ]
      d <- merge(d, b, by = idv, all.x = TRUE)
      raceIATb <- "DscoreraceIATbas"; acaIATb <- "DscoreacaIATbas"
    }
    d <- d[!is.na(d[[rv]]) & d[[rv]] == max(vals), ]
  }
}
if (!is.na(idv) && any(duplicated(d[[idv]]))) {
  message("Duplicates on id remain; keeping last occurrence")
  d <- d[!duplicated(d[[idv]], fromLast = TRUE), ]
}

# Working sample: non-missing follow-up Race and Academic IAT
d <- d[!is.na(d[[raceIAT]]) & !is.na(d[[acaIAT]]), ]
message("Working sample size: ", nrow(d))

# ---------------- Race groups ----------------
wv <- findcol(c("white")); bv <- findcol(c("black")); cv <- findcol(c("coloured", "colored"))
ev <- findcol(c("Else", "other", "indian"))
d$is_white <- if (!is.na(wv)) as.numeric(d[[wv]] == 1) else NA
d$is_black <- if (!is.na(bv)) as.numeric(d[[bv]] == 1) else NA
d$is_white[is.na(d$is_white)] <- 0
d$is_black[is.na(d$is_black)] <- 0
d$is_col  <- if (!is.na(cv)) as.numeric(d[[cv]] == 1) else 0
d$is_col[is.na(d$is_col)] <- 0
d$is_else <- as.numeric(d$is_white == 0 & d$is_black == 0 & d$is_col == 0)
d$racegrp <- ifelse(d$is_white == 1, "W", ifelse(d$is_black == 1, "B", "O"))
d$res_fe  <- as.character(d[[resv]])
d$racegrp_res <- paste(d$racegrp, d$res_fe, sep = "_")

# ---------------- Controls ----------------
n <- names(d)
own_c <- c("Female", "Falseuct2012", "durpcabas_nomiss", "consbas_nomiss",
           "Foreign", "foreign_missing", "privateschool_nomiss")
own_c <- unique(na.omit(sapply(own_c, function(x) findcol(x, d))))
own_miss <- n[grepl("(_miss$)|(^miss)|(_missing$)", n) & !grepl("^ro", n) &
                !grepl("fwer|IAT|sim|2013|_fu|^PCA", n)]
own_c <- unique(c(own_c, own_miss))

ro_c <- c("roFalseuct2012", "rodurpcabas_nomiss", "roconsbas_nomiss")
ro_c <- unique(na.omit(sapply(ro_c, function(x) findcol(x, d))))
ro_for <- findcol(c("roForeign_bas", "roForeign"), d)
ro_ps  <- findcol(c("roprivschool_nomiss", "roprivateschool_nomiss"), d)
ro_c <- unique(c(ro_c, na.omit(c(ro_for, ro_ps))))
ro_miss <- n[grepl("^ro", n) & grepl("(_miss$)|(^romiss)|(_missing$)", n) &
               !grepl("fwer|IAT|sim|2013|_fu|Female|female", n)]
ro_c <- unique(c(ro_c, ro_miss))
controls <- unique(c(own_c, ro_c))
message("Controls: ", paste(controls, collapse = " "))

# Mean-impute any remaining missing control values with indicator dummies
extra <- c()
for (v in controls) {
  x <- suppressWarnings(as.numeric(d[[v]]))
  if (any(is.na(x))) {
    dn <- paste0("mi_", v)
    d[[dn]] <- as.numeric(is.na(x))
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    if (length(unique(d[[dn]])) > 1) extra <- c(extra, dn)
  }
  d[[v]] <- x
}
controls <- c(controls, extra)

# ---------------- Program FE ----------------
progv <- findcol(c("program", "Program", "programme", "Programme", "acadprogram",
                   "program_code", "prog", "degree", "Plan"), d)
if (is.na(progv)) {
  g <- n[grepl("prog", n, ignore.case = TRUE) & !grepl("^ro", n)]
  if (length(g)) progv <- g[1]
}
if (is.na(progv)) progv <- findcol(c("Faculty", "faculty"), d)
message("Program FE variable: ", progv)
if (!is.na(progv)) {
  d$prog_fe <- as.character(d[[progv]])
  d$prog_fe[is.na(d$prog_fe)] <- "missing"
}

# ---------------- Room cluster ----------------
roomv <- findcol(c("roomnum_base", "room_base", "roomid", "room_id", "roomnum", "room"), d)
if (is.na(roomv)) {
  g <- n[grepl("^room", n, ignore.case = TRUE)]
  g2 <- g[grepl("num|id|base", g, ignore.case = TRUE)]
  if (length(g2)) roomv <- g2[1] else if (length(g)) roomv <- g[1]
}
ronv <- findcol(c("ronstudent", "roid", "roommate_id"), d)
if (!is.na(roomv)) {
  d$cl_room <- paste(d$res_fe, d[[roomv]], sep = "_")
} else if (!is.na(ronv) && !is.na(idv)) {
  a <- as.character(d[[idv]]); b <- as.character(d[[ronv]])
  d$cl_room <- ifelse(is.na(b), a, paste(pmin(a, b), pmax(a, b), sep = "_"))
} else {
  d$cl_room <- if (!is.na(idv)) as.character(d[[idv]]) else as.character(seq_len(nrow(d)))
}
message("Room variable: ", roomv, "; clusters: ", length(unique(d$cl_room)))

# ---------------- Outcomes ----------------
gpav <- findcol(c("zGPA", "GPA_std", "stdGPA", "GPAstd", "GPA2012", "GPA", "gpa", "GPA_fu"), d)
if (is.na(gpav)) {
  g <- n[grepl("gpa", n, ignore.case = TRUE) & !grepl("^ro|2013|fwer", n)]
  if (length(g)) gpav <- g[1]
}
message("GPA variable: ", gpav)
if (!is.na(gpav)) {
  gx <- as.numeric(d[[gpav]])
  m <- mean(gx, na.rm = TRUE); s <- sd(gx, na.rm = TRUE)
  if (abs(m) > 0.05 || abs(s - 1) > 0.05) gx <- (gx - m) / s
  d$gpa_std <- gx
}
examv <- findcol(c("examspassed", "exams_passed"), d)
contv <- findcol(c("continue", "eligible"), d)
perfv <- findcol(c("PCAperf", "pcaperf"), d)

bt <- function(x) paste0("`", x, "`")
run <- function(y, data, extra_x = c(), fe = c(), use_controls = TRUE) {
  if (is.na(y) || !(y %in% names(data))) return(NULL)
  rhs <- c(bt(treat), bt(extra_x), if (use_controls) bt(controls))
  fml <- paste(bt(y), "~", paste(rhs, collapse = " + "))
  if (length(fe)) fml <- paste(fml, "|", paste(fe, collapse = " + "))
  tryCatch(feols(as.formula(fml), data = data, cluster = ~cl_room),
           error = function(e) { message("Error in ", y, ": ", conditionMessage(e)); NULL })
}
getb <- function(m) if (is.null(m)) NA else unname(coef(m)[treat])
getn <- function(m) if (is.null(m)) NA else nobs(m)

wh <- d[d$is_white == 1, ]
bl <- d[d$is_black == 1, ]

# ---------------- Table 3 ----------------
m_w_race <- run(raceIAT, wh, extra_x = raceIATb, fe = "res_fe")
m_b_race <- run(raceIAT, bl, extra_x = raceIATb, fe = "res_fe")
setres("race_iat_mixed_room_whites_table3_col1", getb(m_w_race))
setres("race_iat_mixed_room_blacks_table3_col2", getb(m_b_race))
setres("n_obs_table3_whites", if (!is.null(m_w_race)) getn(m_w_race) else nrow(wh))
setres("n_obs_table3_blacks", if (!is.null(m_b_race)) getn(m_b_race) else nrow(bl))

# ---------------- Table 4 ----------------
fe_sub  <- c("res_fe", if (!is.na(progv)) "prog_fe")
fe_full <- c("racegrp_res", if (!is.na(progv)) "prog_fe")
race_d  <- c("is_white", "is_col", "is_else")

m_b_gpa  <- run("gpa_std", bl, fe = fe_sub)
m_b_ex   <- run(examv, bl, fe = fe_sub)
m_b_cont <- run(contv, bl, fe = fe_sub)
m_b_perf <- run(perfv, bl, fe = fe_sub)
m_w_gpa  <- run("gpa_std", wh, fe = fe_sub)
m_f_gpa  <- run("gpa_std", d, extra_x = race_d, fe = fe_full)
m_f_ex   <- run(examv, d, extra_x = race_d, fe = fe_full)
m_f_perf <- run(perfv, d, extra_x = race_d, fe = fe_full)

setres("gpa_mixed_room_blacks_table4_panelB_col1", getb(m_b_gpa))
setres("exams_passed_mixed_room_blacks_table4_panelB_col2", getb(m_b_ex))
setres("eligible_mixed_room_blacks_table4_panelB_col3", getb(m_b_cont))
setres("performance_index_mixed_room_blacks_table4_panelB_col4", getb(m_b_perf))
setres("gpa_mixed_room_whites_table4_panelA_col1", getb(m_w_gpa))
setres("gpa_mixed_room_full_table4_panelC_col1", getb(m_f_gpa))
setres("exams_passed_mixed_room_full_table4_panelC_col2", getb(m_f_ex))
setres("performance_index_mixed_room_full_table4_panelC_col4", getb(m_f_perf))
setres("n_obs_table4_panelC_cols1_2", if (!is.null(m_f_gpa)) getn(m_f_gpa) else nrow(d))

for (m in list(m_w_race, m_b_race, m_b_gpa, m_f_gpa)) {
  if (!is.null(m)) message(sprintf("coef=%.4f se=%.4f n=%d", coef(m)[treat], se(m)[treat], nobs(m)))
}

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(results[[nm]], digits = 10)))
}
