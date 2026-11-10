suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance.script-free"
d <- read_dta(file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta"))
d <- as.data.frame(haven::zap_labels(d))
nm <- names(d)
message("Columns: ", paste(nm, collapse = " "))
message("Rows: ", nrow(d))

pick <- function(cands) {
  x <- intersect(cands, nm)
  if (length(x)) x[1] else NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# ---------------- Identify follow-up rows ----------------
idv <- pick(c("nstudent", "id", "student_id", "studentid"))
rv <- pick(c("round", "Round", "wave", "survey_round", "followup", "fu", "post", "time"))
fu <- NULL
if (!is.na(rv)) {
  r <- num(d[[rv]])
  if (length(unique(na.omit(r))) >= 2) {
    fu <- d[!is.na(r) & r == max(r, na.rm = TRUE), , drop = FALSE]
    message("Using round variable ", rv, "; follow-up rows: ", nrow(fu))
  }
}
if (is.null(fu)) {
  if (!is.na(idv) && any(duplicated(d[[idv]]))) {
    dd <- abs(num(d$DscoreraceIAT) - num(d$DscoreraceIATbas)) +
      abs(num(d$DscoreacaIAT) - num(d$DscoreacaIATbas))
    dd[is.na(dd)] <- -1
    d$.dd <- dd
    d$.rowid <- seq_len(nrow(d))
    fu <- d %>% group_by(.data[[idv]]) %>%
      arrange(desc(.dd), desc(.rowid), .by_group = TRUE) %>%
      slice(1) %>% ungroup() %>% as.data.frame()
    message("No round variable; heuristic follow-up rows: ", nrow(fu))
  } else {
    fu <- d
    message("Single-row-per-student data assumed: ", nrow(fu))
  }
}

# ---------------- Working sample ----------------
need <- intersect(c("DscoreraceIAT", "DscoreacaIAT", "DscoreraceIATbas", "DscoreacaIATbas"), nm)
ok <- complete.cases(fu[, need, drop = FALSE])
if (sum(ok) >= 0.5 * nrow(fu)) fu <- fu[ok, , drop = FALSE]
message("Working sample: ", nrow(fu))

# ---------------- Variables ----------------
treat <- pick(c("mixracebas", "MixRoom", "mixroom", "mixrace", "mixracebase"))
fu$MixRoom <- num(fu[[treat]])

black_v <- pick(c("black", "Black"))
white_v <- pick(c("white", "White"))
col_v <- pick(c("coloured", "Coloured", "colored"))
oth_v <- pick(c("Else", "else", "other", "indian", "Indian", "asian"))
fu$isblack <- as.integer(num(fu[[black_v]]) == 1)
fu$iswhite <- as.integer(num(fu[[white_v]]) == 1)
fu$isblack[is.na(fu$isblack)] <- 0L
fu$iswhite[is.na(fu$iswhite)] <- 0L
fu$dcol <- if (!is.na(col_v)) num(fu[[col_v]]) else 0
fu$doth <- if (!is.na(oth_v)) num(fu[[oth_v]]) else 0
fu$dcol[is.na(fu$dcol)] <- 0
fu$doth[is.na(fu$doth)] <- 0
fu$dwhite <- fu$iswhite
fu$racegrp <- ifelse(fu$isblack == 1, "B", ifelse(fu$iswhite == 1, "W", "O"))

resv <- pick(c("Res_base", "res_base", "residence", "Residence"))
fu$res <- as.character(fu[[resv]])
fu$res[is.na(fu$res)] <- "NA"
fu$rg_res <- paste(fu$racegrp, fu$res, sep = "_")

# Own controls
own <- na.omit(c(
  pick(c("Female", "female")),
  pick(c("Falseuct2012", "falseuct2012", "Falseuct2012_nomiss")),
  pick(c("durpcabas_nomiss", "durpcabas")),
  pick(c("consbas_nomiss", "consbas")),
  pick(c("Foreign", "foreign", "Foreign_bas")),
  pick(c("privateschool_nomiss", "privateschool"))
))
own_miss <- intersect(c("foreign_missing", "privateschool_miss", "missfalse",
                        "consbas_miss", "durpcabas_miss",
                        "Falseuct2012_miss", "falseuct2012_miss"), nm)
# Roommate controls (no female: rooms are single-sex)
ro <- na.omit(c(
  pick(c("roFalseuct2012", "rofalseuct2012")),
  pick(c("rodurpcabas_nomiss", "rodurpcabas")),
  pick(c("roconsbas_nomiss", "roconsbas")),
  pick(c("roForeign_bas", "roForeign", "roforeign")),
  pick(c("roprivschool_nomiss", "roprivateschool_nomiss", "roprivateschool"))
))
ro_miss <- intersect(c("roforeign_missing", "roForeign_missing", "roprivateschool_miss",
                       "roprivschool_miss", "romissfalse", "roconsbas_miss",
                       "rodurpcabas_miss"), nm)
ctrl <- unique(c(own, own_miss, ro, ro_miss))
message("Controls: ", paste(ctrl, collapse = " "))

# Mean imputation + missing dummies for any remaining NAs in controls
extra <- character(0)
for (v in ctrl) {
  x <- num(fu[[v]])
  if (any(is.na(x))) {
    dn <- paste0(v, "_nadum")
    fu[[dn]] <- as.integer(is.na(x))
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    extra <- c(extra, dn)
  }
  fu[[v]] <- x
}
ctrl <- c(ctrl, extra)

# Cluster: room
cl_built <- FALSE
rov <- pick(c("ronstudent", "roommate_id", "roommateid", "roommate", "ro_nstudent", "nstudent_ro", "roomm_id", "roommate_nstudent"))
if (!is.na(idv) && !is.na(rov)) {
  a <- num(fu[[idv]]); b <- num(fu[[rov]])
  if (sum(!is.na(b)) > 0.8 * nrow(fu) && length(unique(na.omit(b))) > nrow(fu) / 4) {
    fu$room_cl <- ifelse(is.na(b), paste0("s", a), paste(pmin(a, b), pmax(a, b), sep = "_"))
    cl_built <- TRUE
    message("Cluster built from ids ", idv, " & ", rov)
  }
}
if (!cl_built) {
  roomv <- pick(c("roomnum_base", "room_id", "roomid", "roomnum", "room", "room_base", "roomno"))
  if (is.na(roomv)) {
    g <- grep("^room", nm, value = TRUE, ignore.case = TRUE)
    if (length(g)) roomv <- g[1]
  }
  if (!is.na(roomv)) {
    fu$room_cl <- paste(fu$res, as.character(fu[[roomv]]), sep = "_")
    message("Cluster from room var ", roomv)
  } else {
    fu$room_cl <- if (!is.na(idv)) as.character(fu[[idv]]) else as.character(seq_len(nrow(fu)))
    message("No room variable found; clustering by student")
  }
}

# Academic program FE
progv <- pick(c("program", "Program", "programme", "Programme", "prog", "acad_program",
                "academic_program", "degree", "Degree", "Faculty", "faculty",
                "Faculty_base", "faculty_base"))
if (is.na(progv)) {
  g <- grep("prog|degree|facult", nm, value = TRUE, ignore.case = TRUE)
  g <- g[!grepl("^ro", g)]
  if (length(g)) progv <- g[1]
}
if (!is.na(progv)) {
  fu$prog <- as.character(fu[[progv]])
  fu$prog[is.na(fu$prog) | fu$prog == ""] <- "NA"
  message("Program FE: ", progv)
} else {
  fu$prog <- "all"
  message("No program variable found")
}

# Outcomes
gpav <- pick(c("GPA", "gpa", "GPA2012", "gpa2012", "GPA_2012", "zGPA", "GPAstd", "GPA_std"))
if (is.na(gpav)) {
  g <- grep("gpa", nm, value = TRUE, ignore.case = TRUE)
  g <- g[!grepl("^ro|2013|yr2", g)]
  if (length(g)) gpav <- g[1]
}
message("GPA var: ", gpav)
g <- num(fu[[gpav]])
fu$GPAz <- (g - mean(g, na.rm = TRUE)) / sd(g, na.rm = TRUE)
fu$exams <- num(fu[[pick(c("examspassed", "exams_passed"))]])
fu$elig <- num(fu[[pick(c("continue", "eligible"))]])
fu$perfidx <- num(fu[[pick(c("PCAperf", "pcaperf"))]])
fu$raceIAT <- num(fu$DscoreraceIAT)
fu$raceIATbas <- num(fu$DscoreraceIATbas)

# ---------------- Estimation ----------------
run <- function(y, rhs, fe, data) {
  f <- as.formula(paste(y, "~", paste(rhs, collapse = " + "), "|", fe))
  tryCatch(feols(f, data = data, cluster = ~room_cl, warn = FALSE, notes = FALSE),
           error = function(e) { message("Error: ", conditionMessage(e)); NULL })
}
cf <- function(m) if (is.null(m)) NA_real_ else unname(coef(m)["MixRoom"])
nob <- function(m) if (is.null(m)) NA_real_ else nobs(m)

W <- fu[fu$iswhite == 1, ]
B <- fu[fu$isblack == 1, ]

# Table 3
m3w <- run("raceIAT", c("MixRoom", "raceIATbas", ctrl), "res", W)
m3b <- run("raceIAT", c("MixRoom", "raceIATbas", ctrl), "res", B)
mAw <- run("DscoreacaIAT", c("MixRoom", "DscoreacaIATbas", ctrl), "res", W)
mAb <- run("DscoreacaIAT", c("MixRoom", "DscoreacaIATbas", ctrl), "res", B)

# Table 4
fe_sub <- "res + prog"
m4b1 <- run("GPAz", c("MixRoom", ctrl), fe_sub, B)
m4b2 <- run("exams", c("MixRoom", ctrl), fe_sub, B)
m4b3 <- run("elig", c("MixRoom", ctrl), fe_sub, B)
m4b4 <- run("perfidx", c("MixRoom", ctrl), fe_sub, B)
m4w1 <- run("GPAz", c("MixRoom", ctrl), fe_sub, W)

fe_full <- "rg_res + prog"
race_d <- c("dwhite", "dcol", "doth")
m4c1 <- run("GPAz", c("MixRoom", race_d, ctrl), fe_full, fu)
m4c2 <- run("exams", c("MixRoom", race_d, ctrl), fe_full, fu)
m4c4 <- run("perfidx", c("MixRoom", race_d, ctrl), fe_full, fu)

n_w <- if (!is.null(m3w)) nob(m3w) else sum(fu$iswhite == 1)
n_b <- if (!is.null(m3b)) nob(m3b) else sum(fu$isblack == 1)
n_c <- if (!is.null(m4c1)) nob(m4c1) else nrow(fu)

out <- function(name, v) cat(sprintf("RESULT:%s=%s\n", name, format(v, digits = 10)))
out("race_iat_mixed_room_whites_table3_col1", cf(m3w))
out("race_iat_mixed_room_blacks_table3_col2", cf(m3b))
out("n_obs_table3_whites", n_w)
out("n_obs_table3_blacks", n_b)
out("gpa_mixed_room_blacks_table4_panelB_col1", cf(m4b1))
out("exams_passed_mixed_room_blacks_table4_panelB_col2", cf(m4b2))
out("eligible_mixed_room_blacks_table4_panelB_col3", cf(m4b3))
out("performance_index_mixed_room_blacks_table4_panelB_col4", cf(m4b4))
out("gpa_mixed_room_whites_table4_panelA_col1", cf(m4w1))
out("gpa_mixed_room_full_table4_panelC_col1", cf(m4c1))
out("exams_passed_mixed_room_full_table4_panelC_col2", cf(m4c2))
out("performance_index_mixed_room_full_table4_panelC_col4", cf(m4c4))
out("n_obs_table4_panelC_cols1_2", n_c)
