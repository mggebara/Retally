suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
f <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
df <- haven::read_dta(f)
df <- haven::zap_labels(df)
df <- as.data.frame(df)

num <- function(x) as.numeric(x)
vars <- c("Child", "Violation", "Help", "ViolationHelp", "Punishment", "Helping",
          "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot", "School")
for (v in vars) df[[v]] <- num(df[[v]])

# Scene indicators: VH scene identified by ViolationHelp dummy
df$VH <- ifelse(!is.na(df$ViolationHelp) & df$ViolationHelp == 1, 1, 0)
df$is_violation_scene <- ifelse(df$VH == 0 & !is.na(df$Violation) & df$Violation == 1, 1, 0)
df$is_help_scene <- ifelse(df$VH == 0 & !is.na(df$Help) & df$Help == 1, 1, 0)

controls <- c("male", "hugo", "Morning", "witness", "rich", "Rain", "Hot")

# ---------- Punishment samples ----------
pun <- df
cat(sprintf("SAMPLE:punishment_nocontrols:loaded=%d\n", nrow(pun)))
pun <- pun[pun$is_violation_scene == 1 | pun$VH == 1, ]
cat(sprintf("SAMPLE:punishment_nocontrols:violation_and_vh_scenes=%d\n", nrow(pun)))
m1 <- feols(Punishment ~ Child + VH + Child:VH, data = pun, cluster = ~School)
cat(sprintf("SAMPLE:punishment_nocontrols:estimation=%d\n", nobs(m1)))

cat(sprintf("SAMPLE:punishment_controls:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:punishment_controls:violation_and_vh_scenes=%d\n", nrow(pun)))
pun_c <- pun[complete.cases(pun[, c("Punishment", "Child", "VH", controls)]), ]
cat(sprintf("SAMPLE:punishment_controls:nonmissing_controls=%d\n", nrow(pun_c)))
m2 <- feols(Punishment ~ Child + VH + Child:VH + male + hugo + Morning + witness + rich + Rain + Hot,
            data = pun_c, cluster = ~School)
cat(sprintf("SAMPLE:punishment_controls:estimation=%d\n", nobs(m2)))

# ---------- Helping samples ----------
hel <- df
cat(sprintf("SAMPLE:helping_nocontrols:loaded=%d\n", nrow(hel)))
hel <- hel[hel$is_help_scene == 1 | hel$VH == 1, ]
cat(sprintf("SAMPLE:helping_nocontrols:help_and_vh_scenes=%d\n", nrow(hel)))
m3 <- feols(Helping ~ Child + VH + Child:VH, data = hel, cluster = ~School)
cat(sprintf("SAMPLE:helping_nocontrols:estimation=%d\n", nobs(m3)))

cat(sprintf("SAMPLE:helping_controls:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:helping_controls:help_and_vh_scenes=%d\n", nrow(hel)))
hel_c <- hel[complete.cases(hel[, c("Helping", "Child", "VH", controls)]), ]
cat(sprintf("SAMPLE:helping_controls:nonmissing_controls=%d\n", nrow(hel_c)))
m4 <- feols(Helping ~ Child + VH + Child:VH + male + hugo + Morning + witness + rich + Rain + Hot,
            data = hel_c, cluster = ~School)
cat(sprintf("SAMPLE:helping_controls:estimation=%d\n", nobs(m4)))

getc <- function(m, nm) {
  cf <- coef(m)
  if (nm %in% names(cf)) return(unname(cf[nm]))
  alt <- if (nm == "Child:VH") "VH:Child" else nm
  if (alt %in% names(cf)) return(unname(cf[alt]))
  NA_real_
}

cat(sprintf("RESULT:child_punishment_no_controls=%.6f\n", getc(m1, "Child")))
cat(sprintf("RESULT:child_punishment_controls=%.6f\n", getc(m2, "Child")))
cat(sprintf("RESULT:child_helping_no_controls=%.6f\n", getc(m3, "Child")))
cat(sprintf("RESULT:child_helping_controls=%.6f\n", getc(m4, "Child")))
cat(sprintf("RESULT:vh_punishment_controls=%.6f\n", getc(m2, "VH")))
cat(sprintf("RESULT:vh_helping_controls=%.6f\n", getc(m4, "VH")))
cat(sprintf("RESULT:child_x_vh_punishment_no_controls=%.6f\n", getc(m1, "Child:VH")))
cat(sprintf("RESULT:child_x_vh_punishment_controls=%.6f\n", getc(m2, "Child:VH")))
cat(sprintf("RESULT:child_x_vh_helping_no_controls=%.6f\n", getc(m3, "Child:VH")))
cat(sprintf("RESULT:child_x_vh_helping_controls=%.6f\n", getc(m4, "Child:VH")))
cat(sprintf("RESULT:observations_punishment_controls=%d\n", as.integer(nobs(m2))))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", as.integer(nobs(m3))))