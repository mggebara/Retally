suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance.script-free"
f_bal <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta")

d <- haven::read_dta(f_bal)
d <- as.data.frame(haven::zap_labels(d))
nm <- names(d)
message("Columns: ", paste(nm, collapse = ", "))
message("Rows read: ", nrow(d))

pick <- function(cands, names_vec = names(d)) {
  x <- cands[cands %in% names_vec]
  if (length(x)) x[1] else NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# ------------------------------------------------------------------
# 1. Keep one (follow-up) row per student
# ------------------------------------------------------------------
if ("balanced" %in% nm) {
  b <- num(d$balanced)
  if (any(b == 1, na.rm = TRUE) && any(b != 1 | is.na(b))) {
    d <- d[!is.na(b) & b == 1, , drop = FALSE]
  }
}

rv <- pick(c("round", "Round", "wave", "survey", "followup", "fu", "post", "period", "time"))
if (!is.na(rv)) {
  vals <- sort(unique(na.omit(num(d[[rv]]))))
  if (length(vals) >= 2 && length(vals) <= 4) {
    message("Using follow-up round: ", rv, " == ", max(vals))
    d <- d[!is.na(num(d[[rv]])) & num(d[[rv]]) == max(vals), , drop = FALSE]
  }
}

idv <- pick(c("nstudent", "id", "studentid", "student_id", "ID"))
if (!is.na(idv) && anyDuplicated(d[[idv]])) {
  message("Duplicated ids remain; keeping last occurrence per student")
  d <- d[!duplicated(d[[idv]], fromLast = TRUE), , drop = FALSE]
}
message("Rows after de-duplication: ", nrow(d))

# ------------------------------------------------------------------
# 2. Key variables
# ------------------------------------------------------------------
v_mix   <- pick(c("mixracebas", "MixRoom", "mixroom", "mixrace"))
v_race  <- pick(c("DscoreraceIAT", "DscoreraceIAT_fu"))
v_raceb <- pick(c("DscoreraceIATbas", "DscoreraceIAT_bas"))
v_aca   <- pick(c("DscoreacaIAT", "DscoreacaIAT_fu"))
v_acab  <- pick(c("DscoreacaIATbas", "DscoreacaIAT_bas"))
v_res   <- pick(c("Res_base", "res_base", "Residence"))

d$mix <- num(d[[v_mix]])
d$race_fu <- num(d[[v_race]])
d$race_bas <- if (!is.na(v_raceb)) num(d[[v_raceb]]) else NA_real_
d$aca_fu <- if (!is.na(v_aca)) num(d[[v_aca]]) else NA_real_
d$aca_bas <- if (!is.na(v_acab)) num(d[[v_acab]]) else NA_real_
d$res <- as.character(d[[v_res]])

# working sample: baseline and follow-up IATs non-missing
sA <- !is.na(d$race_fu) & !is.na(d$aca_fu) & !is.na(d$mix)
sB <- sA & !is.na(d$race_bas) & !is.na(d$aca_bas)
if (sum(sB) >= 300) d <- d[sB, , drop = FALSE] else d <- d[sA, , drop = FALSE]
message("Working sample size: ", nrow(d))

# race
if ("black" %in% nm) d$is_black <- num(d$black) else d$is_black <- as.numeric(num(d$Race) == 1)
if ("white" %in% nm) d$is_white <- num(d$white) else d$is_white <- as.numeric(num(d$Race) == 2)
d$is_black[is.na(d$is_black)] <- 0
d$is_white[is.na(d$is_white)] <- 0
d$is_coloured <- if ("coloured" %in% nm) num(d$coloured) else 0
d$is_else <- if ("Else" %in% nm) num(d$Else) else as.numeric(d$is_black == 0 & d$is_white == 0 & d$is_coloured == 0)
d$is_coloured[is.na(d$is_coloured)] <- 0
d$is_else[is.na(d$is_else)] <- 0
d$racegrp <- ifelse(d$is_black == 1, "B", ifelse(d$is_white == 1, "W", "O"))

# room cluster
room_c <- nm[grepl("room", nm, ignore.case = TRUE) &
             !grepl("sameroom|mixroom|roommate|Same_ro", nm, ignore.case = TRUE)]
v_room <- pick(c("roomnum_base", "room_base", "roomid", "room_id", "idroom", "room", "roomnum", "Room", room_c))
v_roid <- pick(c("ronstudent", "roid", "id_ro", "roommate_id", "ro_nstudent"))
if (!is.na(v_room)) {
  d$room <- paste(d$res, d[[v_room]], sep = "_")
  message("Clustering on ", v_room, " (within residence)")
} else if (!is.na(idv) && !is.na(v_roid)) {
  a <- as.character(d[[idv]]); b <- as.character(d[[v_roid]])
  d$room <- ifelse(is.na(b), a, paste(pmin(a, b), pmax(a, b), sep = "_"))
  message("Clustering on constructed room pair")
} else {
  d$room <- if (!is.na(idv)) as.character(d[[idv]]) else as.character(seq_len(nrow(d)))
  message("No room id found; clustering at individual level")
}

# academic program FE
prog_c <- nm[grepl("prog", nm, ignore.case = TRUE) & !grepl("^ro", nm)]
v_prog <- pick(c("regprog", "program", "Program", "prog", prog_c, "Faculty", "faculty"))
if (!is.na(v_prog)) {
  d$prog <- as.character(d[[v_prog]])
  d$prog[is.na(d$prog) | d$prog == ""] <- "missing"
  message("Program FE: ", v_prog)
} else {
  d$prog <- "all"
}

# ------------------------------------------------------------------
# 3. Controls (own + roommate) with mean imputation / missing dummies
# ------------------------------------------------------------------
own_cands <- c(pick(c("Female", "female")),
               pick(c("Falseuct2012", "falseuct2012", "Falseuct2012_nomiss")),
               pick(c("durpcabas_nomiss", "durpcabas")),
               pick(c("consbas_nomiss", "consbas")),
               pick(c("Foreign", "foreign")),
               pick(c("privschool_nomiss", "privateschool_nomiss", "privschool", "privateschool")))
own_cands <- own_cands[!is.na(own_cands)]
ro_cands <- c(pick(c("roFalseuct2012", "rofalseuct2012")),
              pick(c("rodurpcabas_nomiss", "rodurpcabas")),
              pick(c("roconsbas_nomiss", "roconsbas")),
              pick(c("roForeign", "roforeign")),
              pick(c("roprivschool_nomiss", "roprivateschool_nomiss", "roprivschool", "roprivateschool")))
ro_cands <- ro_cands[!is.na(ro_cands)]

is_missdum <- grepl("miss", nm, ignore.case = TRUE) & !grepl("nomiss", nm, ignore.case = TRUE) &
  grepl("foreign|false|uct|durpca|cons|priv", nm, ignore.case = TRUE) &
  !grepl("IAT|PCA|fwer|sim", nm)
own_miss <- nm[is_missdum & !grepl("^ro", nm)]
ro_miss  <- nm[is_missdum & grepl("^ro", nm)]

controls <- unique(c(own_cands, own_miss, ro_cands, ro_miss))
message("Controls: ", paste(controls, collapse = ", "))

ctrl_names <- character(0)
for (v in controls) {
  x <- num(d[[v]])
  if (grepl("uct2012", v, ignore.case = TRUE) && mean(x, na.rm = TRUE) > 5) x <- x / 1000
  nv <- paste0("c_", make.names(v))
  if (any(is.na(x))) {
    md <- paste0(nv, "_md")
    d[[md]] <- as.numeric(is.na(x))
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    ctrl_names <- c(ctrl_names, md)
  }
  d[[nv]] <- x
  ctrl_names <- c(ctrl_names, nv)
}
# drop constant controls
ctrl_names <- ctrl_names[sapply(ctrl_names, function(v) length(unique(d[[v]])) > 1)]
ctrl_str <- if (length(ctrl_names)) paste(ctrl_names, collapse = " + ") else "1"

# ------------------------------------------------------------------
# 4. Outcomes
# ------------------------------------------------------------------
gpa_c <- nm[grepl("^z?GPA", nm, ignore.case = TRUE) & !grepl("2013|2014|yr2|fwer|^ro", nm)]
v_gpa <- pick(c("GPA", "GPA2012", "gpa", "zGPA", "GPA_std", gpa_c))
v_ex  <- pick(c("examspassed", "examspassed2012"))
v_con <- pick(c("continue", "continue2012"))
v_pca <- pick(c("PCAperf", "PCAperf2012"))
message("Outcomes: GPA=", v_gpa, " exams=", v_ex, " continue=", v_con, " index=", v_pca)

if (!is.na(v_gpa)) {
  g <- num(d[[v_gpa]])
  if (abs(mean(g, na.rm = TRUE)) > 0.2 || abs(sd(g, na.rm = TRUE) - 1) > 0.2) {
    g <- (g - mean(g, na.rm = TRUE)) / sd(g, na.rm = TRUE)
  }
  d$gpa <- g
} else d$gpa <- NA_real_
d$exams <- if (!is.na(v_ex)) num(d[[v_ex]]) else NA_real_
d$elig <- if (!is.na(v_con)) num(d[[v_con]]) else NA_real_
if (max(d$elig, na.rm = TRUE) > 1) d$elig <- d$elig / 100
d$perf <- if (!is.na(v_pca)) num(d[[v_pca]]) else NA_real_

# ------------------------------------------------------------------
# 5. Estimation
# ------------------------------------------------------------------
run <- function(y, data, lag = NULL, fe = "res", full = FALSE) {
  rhs <- paste("mix", if (!is.null(lag)) paste("+", lag) else "", "+", ctrl_str)
  if (full) rhs <- paste(rhs, "+ is_white + is_coloured + is_else")
  fml <- as.formula(paste(y, "~", rhs, "|", fe))
  tryCatch(feols(fml, data = data, cluster = ~room, warn = FALSE, notes = FALSE),
           error = function(e) { message("Error: ", conditionMessage(e)); NULL })
}
getb <- function(m) if (is.null(m)) NA_real_ else unname(coef(m)["mix"])
getse <- function(m) if (is.null(m)) NA_real_ else unname(sqrt(diag(vcov(m)))["mix"])

dw <- d[d$is_white == 1, ]
db <- d[d$is_black == 1, ]

m_rw <- run("race_fu", dw, lag = "race_bas", fe = "res")
m_rb <- run("race_fu", db, lag = "race_bas", fe = "res")

m_gb <- run("gpa", db, fe = "res + prog")
m_eb <- run("exams", db, fe = "res + prog")
m_cb <- run("elig", db, fe = "res + prog")
m_pb <- run("perf", db, fe = "res + prog")

m_gw <- run("gpa", dw, fe = "res + prog")

m_gf <- run("gpa", d, fe = "racegrp^res + prog", full = TRUE)
m_ef <- run("exams", d, fe = "racegrp^res + prog", full = TRUE)
m_pf <- run("perf", d, fe = "racegrp^res + prog", full = TRUE)

for (m in list(m_rw, m_rb, m_gb, m_gf)) if (!is.null(m)) message("b=", round(getb(m), 4), " se=", round(getse(m), 4), " n=", nobs(m))

nob <- function(m) if (is.null(m)) NA_real_ else nobs(m)

cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%.6f\n", getb(m_rw)))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%.6f\n", getb(m_rb)))
cat(sprintf("RESULT:n_obs_table3_whites=%s\n", nob(m_rw)))
cat(sprintf("RESULT:n_obs_table3_blacks=%s\n", nob(m_rb)))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%.6f\n", getb(m_gb)))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%.6f\n", getb(m_eb)))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%.6f\n", getb(m_cb)))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%.6f\n", getb(m_pb)))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%.6f\n", getb(m_gw)))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%.6f\n", getb(m_gf)))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%.6f\n", getb(m_ef)))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%.6f\n", getb(m_pf)))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%s\n", nob(m_gf)))