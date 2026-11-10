suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance.script-free"
f_bal   <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta")
f_clean <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_clean.dta")

strip_labels <- function(d) {
  d <- as.data.frame(zap_labels(zap_formats(d)))
  d
}

bal <- strip_labels(read_dta(f_bal))
message("Balanced file: ", nrow(bal), " rows, ", ncol(bal), " cols")
message("Columns: ", paste(names(bal), collapse = ", "))

clean <- tryCatch(strip_labels(read_dta(f_clean)), error = function(e) NULL)

pick <- function(d, cands, pattern = NULL, exclude = NULL) {
  for (cc in cands) if (cc %in% names(d)) return(cc)
  lc <- tolower(names(d))
  for (cc in cands) {
    w <- which(lc == tolower(cc))
    if (length(w) > 0) return(names(d)[w[1]])
  }
  if (!is.null(pattern)) {
    hits <- grep(pattern, names(d), value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude) && length(hits) > 0)
      hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

# ---------------------------------------------------------------
# Bring in variables possibly missing from balanced file (from clean)
# ---------------------------------------------------------------
id_var <- pick(bal, c("nstudent", "id", "student_id"))
need_from_clean <- c("regprog", "Faculty", "roomnum_base", "room", "roomid", "GPA", "GPA2012")
if (!is.null(clean) && !is.na(id_var) && id_var %in% names(clean)) {
  add <- setdiff(intersect(need_from_clean, names(clean)), names(bal))
  # also any GPA-like or room-like vars in clean not in balanced
  add <- union(add, setdiff(grep("^z?GPA|room|prog", names(clean), value = TRUE, ignore.case = TRUE), names(bal)))
  add <- add[!grepl("roommate", add, ignore.case = TRUE)]
  if (length(add) > 0) {
    cl <- clean[, c(id_var, add), drop = FALSE]
    cl <- cl[!duplicated(cl[[id_var]]), , drop = FALSE]
    bal <- left_join(bal, cl, by = id_var)
    message("Merged from clean file: ", paste(add, collapse = ", "))
  }
}

# ---------------------------------------------------------------
# Keep one (follow-up) row per student if file is in long format
# ---------------------------------------------------------------
d <- bal
round_var <- pick(d, c("round", "Round", "wave", "survey_round", "followup", "fu", "post"))
if (!is.na(id_var) && any(duplicated(d[[id_var]]))) {
  if (!is.na(round_var)) {
    mx <- max(d[[round_var]], na.rm = TRUE)
    d <- d[!is.na(d[[round_var]]) & d[[round_var]] == mx, , drop = FALSE]
    message("Kept round ", mx, " of ", round_var)
  } else {
    found <- FALSE
    for (v in names(d)) {
      x <- d[[v]]
      if (!is.numeric(x)) next
      u <- unique(x[!is.na(x)])
      if (length(u) == 2 && all(table(x) == nrow(d) / 2)) {
        mx <- max(u)
        sub <- d[d[[v]] == mx, , drop = FALSE]
        if (!any(duplicated(sub[[id_var]]))) {
          d <- sub; found <- TRUE
          message("Kept ", v, " == ", mx)
          break
        }
      }
    }
    if (!found) d <- d[!duplicated(d[[id_var]], fromLast = TRUE), , drop = FALSE]
  }
}

# ---------------------------------------------------------------
# Variable names
# ---------------------------------------------------------------
v_race_fu  <- pick(d, c("DscoreraceIAT"))
v_aca_fu   <- pick(d, c("DscoreacaIAT"))
v_race_bas <- pick(d, c("DscoreraceIATbas"))
v_aca_bas  <- pick(d, c("DscoreacaIATbas"))
v_mix      <- pick(d, c("mixracebas", "MixRoom", "mixroom", "mixrace"))
v_res      <- pick(d, c("Res_base", "res_base", "residence"))
v_room     <- pick(d, c("roomnum_base", "room_base", "roomid", "room_id", "roomnum", "room", "Room"),
                   pattern = "room", exclude = "roommate|same|^ro[A-Z]")
v_prog     <- pick(d, c("regprog", "program", "Program", "programme", "prog", "acadprog", "Faculty"))
v_gpa      <- pick(d, c("GPA", "GPA2012", "zGPA", "GPA_std", "gpa", "GPA2012_fu", "gpa2012"),
                   pattern = "^z?GPA", exclude = "2013|ro")
v_exams    <- pick(d, c("examspassed", "examspassed2012"))
v_cont     <- pick(d, c("continue", "continue2012"))
v_perf     <- pick(d, c("PCAperf", "PCAperf2012"))

message("Vars: race_fu=", v_race_fu, " aca_fu=", v_aca_fu, " race_bas=", v_race_bas,
        " mix=", v_mix, " res=", v_res, " room=", v_room, " prog=", v_prog,
        " gpa=", v_gpa, " exams=", v_exams, " cont=", v_cont, " perf=", v_perf)

own_ctrl_c <- list(
  c("Female", "female"),
  c("Falseuct2012", "falseuct2012"),
  c("durpcabas_nomiss"),
  c("consbas_nomiss"),
  c("Foreign", "foreign"),
  c("privschool_nomiss", "privateschool_nomiss", "privschool", "privateschool")
)
ro_ctrl_c <- list(
  c("roFalseuct2012", "rofalseuct2012"),
  c("rodurpcabas_nomiss"),
  c("roconsbas_nomiss"),
  c("roForeign", "roforeign"),
  c("roprivschool_nomiss", "roprivateschool_nomiss")
)
own_ctrl <- unique(na.omit(sapply(own_ctrl_c, function(x) pick(d, x))))
ro_ctrl  <- unique(na.omit(sapply(ro_ctrl_c, function(x) pick(d, x))))

own_miss_c <- c("foreign_missing", "missfalse", "consbas_miss", "durpcabas_miss",
                "privateschool_miss", "privschool_miss", "uct_miss", "falseuct_miss")
ro_miss_c  <- c("roforeign_missing", "romissfalse", "roconsbas_miss", "rodurpcabas_miss",
                "roprivateschool_miss", "roprivschool_miss", "rouct_miss", "rofalseuct_miss")
own_miss <- intersect(own_miss_c, names(d))
ro_miss  <- intersect(ro_miss_c, names(d))

message("Own controls: ", paste(c(own_ctrl, own_miss), collapse = ", "))
message("Roommate controls: ", paste(c(ro_ctrl, ro_miss), collapse = ", "))

# Mean imputation (with missing dummies) for any residual missing controls
ctrl_all <- c(own_ctrl, ro_ctrl)
extra_miss <- c()
for (v in ctrl_all) {
  x <- as.numeric(d[[v]])
  if (any(is.na(x))) {
    mname <- paste0("mi_", v)
    d[[mname]] <- as.numeric(is.na(x))
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    extra_miss <- c(extra_miss, mname)
  }
  d[[v]] <- x
}
for (v in c(own_miss, ro_miss)) {
  x <- as.numeric(d[[v]]); x[is.na(x)] <- 0; d[[v]] <- x
}

# ---------------------------------------------------------------
# Working sample: non-missing follow-up Race and Academic IAT
# ---------------------------------------------------------------
ws <- d[!is.na(d[[v_race_fu]]) & !is.na(d[[v_aca_fu]]), , drop = FALSE]
if (!is.na(v_race_bas) && !is.na(v_aca_bas)) {
  ws2 <- ws[!is.na(ws[[v_race_bas]]) & !is.na(ws[[v_aca_bas]]), , drop = FALSE]
  if (abs(nrow(ws2) - 499) <= abs(nrow(ws) - 499)) ws <- ws2
}
message("Working sample N = ", nrow(ws))

# Race variables
if (!"white" %in% names(ws) || !"black" %in% names(ws)) {
  r <- ws[["Race"]]
  ws$black <- as.numeric(r == 1)
  ws$white <- as.numeric(r == 4)
}
ws$white <- as.numeric(ws$white == 1 & !is.na(ws$white))
ws$black <- as.numeric(ws$black == 1 & !is.na(ws$black))
if (!"coloured" %in% names(ws)) ws$coloured <- 0
ws$coloured <- as.numeric(ws$coloured == 1 & !is.na(ws$coloured))
ws$else_d <- as.numeric(ws$white == 0 & ws$black == 0 & ws$coloured == 0)
ws$racegrp <- ifelse(ws$black == 1, "B", ifelse(ws$white == 1, "W", "O"))

# GPA standardization (if not already standardized)
if (!is.na(v_gpa)) {
  g <- as.numeric(ws[[v_gpa]])
  if (abs(mean(g, na.rm = TRUE)) > 0.15 || abs(sd(g, na.rm = TRUE) - 1) > 0.15) {
    g <- (g - mean(g, na.rm = TRUE)) / sd(g, na.rm = TRUE)
  }
  ws$gpa_std <- g
}

# Cluster variable
if (!is.na(v_room)) {
  ws$cl_room <- as.character(ws[[v_room]])
  if (!is.na(v_res)) ws$cl_room <- paste(ws[[v_res]], ws$cl_room, sep = "_")
} else {
  ws$cl_room <- as.character(seq_len(nrow(ws)))
}
ws$res <- if (!is.na(v_res)) as.character(ws[[v_res]]) else "1"
ws$prog <- if (!is.na(v_prog)) {
  p <- as.character(ws[[v_prog]]); p[is.na(p) | p == ""] <- "missing"; p
} else "1"
ws$mix <- as.numeric(ws[[v_mix]])

rhs_ctrl <- c(own_ctrl, own_miss, ro_ctrl, ro_miss, extra_miss)
# drop roommate female if present
rhs_ctrl <- rhs_ctrl[!rhs_ctrl %in% c("roFemale", "rofemale")]
rhs_ctrl <- unique(rhs_ctrl)

run <- function(y, data, extra = character(0), fe = "res") {
  out <- tryCatch({
    rhs <- c("mix", extra, rhs_ctrl)
    rhs <- rhs[sapply(rhs, function(v) length(unique(na.omit(data[[v]]))) > 1)]
    fml <- as.formula(paste0("`", y, "` ~ ", paste(paste0("`", rhs, "`"), collapse = " + "),
                             " | ", paste(fe, collapse = " + ")))
    m <- feols(fml, data = data, cluster = ~cl_room, warn = FALSE, notes = FALSE)
    list(b = unname(coef(m)["mix"]), se = unname(sqrt(diag(vcov(m)))["mix"]), n = nobs(m))
  }, error = function(e) { message("Error for ", y, ": ", conditionMessage(e)); list(b = NA, se = NA, n = NA) })
  out
}

wh <- ws[ws$white == 1, , drop = FALSE]
bl <- ws[ws$black == 1, , drop = FALSE]

# Table 3: Race IAT
r_w_iat <- run(v_race_fu, wh, extra = v_race_bas, fe = "res")
r_b_iat <- run(v_race_fu, bl, extra = v_race_bas, fe = "res")

# Table 4
r_b_gpa   <- run("gpa_std", bl, fe = c("res", "prog"))
r_b_exams <- run(v_exams, bl, fe = c("res", "prog"))
r_b_cont  <- run(v_cont, bl, fe = c("res", "prog"))
r_b_perf  <- run(v_perf, bl, fe = c("res", "prog"))
r_w_gpa   <- run("gpa_std", wh, fe = c("res", "prog"))

ws$racegrp_res <- paste(ws$racegrp, ws$res, sep = "_")
race_d <- c("white", "coloured", "else_d")
r_f_gpa   <- run("gpa_std", ws, extra = race_d, fe = c("racegrp_res", "prog"))
r_f_exams <- run(v_exams, ws, extra = race_d, fe = c("racegrp_res", "prog"))
r_f_perf  <- run(v_perf, ws, extra = race_d, fe = c("racegrp_res", "prog"))

for (nm in c("r_w_iat", "r_b_iat", "r_b_gpa", "r_b_exams", "r_b_cont", "r_b_perf",
             "r_w_gpa", "r_f_gpa", "r_f_exams", "r_f_perf")) {
  x <- get(nm)
  message(nm, ": b=", round(x$b, 4), " se=", round(x$se, 4), " n=", x$n)
}

fmt <- function(x) ifelse(is.na(x), "NA", format(x, digits = 6))

cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%s\n", fmt(r_w_iat$b)))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%s\n", fmt(r_b_iat$b)))
cat(sprintf("RESULT:n_obs_table3_whites=%s\n", fmt(nrow(wh))))
cat(sprintf("RESULT:n_obs_table3_blacks=%s\n", fmt(nrow(bl))))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%s\n", fmt(r_b_gpa$b)))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%s\n", fmt(r_b_exams$b)))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%s\n", fmt(r_b_cont$b)))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%s\n", fmt(r_b_perf$b)))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%s\n", fmt(r_w_gpa$b)))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%s\n", fmt(r_f_gpa$b)))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%s\n", fmt(r_f_exams$b)))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%s\n", fmt(r_f_perf$b)))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%s\n", fmt(nrow(ws))))
