suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
path <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")

df <- haven::read_dta(path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)

num <- function(x) suppressWarnings(as.numeric(x))
for (v in c("School", "Child", "Violation", "Help", "ViolationHelp", "Punishment", "Helping",
            "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot")) {
  if (v %in% names(df)) df[[v]] <- num(df[[v]])
}

# Scene indicators (mutually exclusive): Violation-only, Help-only, Violation+Help
df$VH <- ifelse(!is.na(df$ViolationHelp) & df$ViolationHelp == 1, 1, 0)
df$isViol <- ifelse(!is.na(df$Violation) & df$Violation == 1 & df$VH == 0, 1, 0)
df$isHelp <- ifelse(!is.na(df$Help) & df$Help == 1 & df$VH == 0, 1, 0)

# Fallback using the scene variable if the dummies do not partition the sample
if (sum(df$isViol) + sum(df$isHelp) + sum(df$VH) != nrow(df) && "scene" %in% names(df)) {
  sc <- num(df$scene)
  if (all(!is.na(sc)) && length(unique(sc)) == 3) {
    cat("DEVIATION: scene dummies do not partition the sample; using scene codes\n")
  }
}

df$Child_VH <- df$Child * df$VH
controls <- c("male", "hugo", "Morning", "witness", "rich", "Rain", "Hot")

cat(sprintf("SAMPLE:all:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:all:violation_scene=%d\n", sum(df$isViol)))
cat(sprintf("SAMPLE:all:help_scene=%d\n", sum(df$isHelp)))
cat(sprintf("SAMPLE:all:vh_scene=%d\n", sum(df$VH)))

# ---------------- Punishment sample: Violation + VH scenes ----------------
pun <- df[df$isViol == 1 | df$VH == 1, ]
pun <- pun[!is.na(pun$Punishment), ]
pun_c <- pun[complete.cases(pun[, c("Punishment", "Child", "VH", controls)]), ]

m1 <- feols(Punishment ~ Child + VH + Child_VH, data = pun, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child + VH + Child_VH +", paste(controls, collapse = " + "))),
            data = pun, cluster = ~School)

cat(sprintf("SAMPLE:punishment_no_controls:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:punishment_no_controls:violation_and_vh_scenes=%d\n", sum(df$isViol == 1 | df$VH == 1)))
cat(sprintf("SAMPLE:punishment_no_controls:estimation=%d\n", nobs(m1)))
cat(sprintf("SAMPLE:punishment_controls:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:punishment_controls:violation_and_vh_scenes=%d\n", sum(df$isViol == 1 | df$VH == 1)))
cat(sprintf("SAMPLE:punishment_controls:nonmissing_controls=%d\n", nrow(pun_c)))
cat(sprintf("SAMPLE:punishment_controls:estimation=%d\n", nobs(m2)))
if (nobs(m1) != 400) cat(sprintf("DEVIATION: punishment sample has %d obs, paper states 400\n", nobs(m1)))

# ---------------- Helping sample: Help + VH scenes ----------------
hel <- df[df$isHelp == 1 | df$VH == 1, ]
hel <- hel[!is.na(hel$Helping), ]
hel_c <- hel[complete.cases(hel[, c("Helping", "Child", "VH", controls)]), ]

m3 <- feols(Helping ~ Child + VH + Child_VH, data = hel, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child + VH + Child_VH +", paste(controls, collapse = " + "))),
            data = hel, cluster = ~School)

cat(sprintf("SAMPLE:helping_no_controls:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:helping_no_controls:help_and_vh_scenes=%d\n", sum(df$isHelp == 1 | df$VH == 1)))
cat(sprintf("SAMPLE:helping_no_controls:estimation=%d\n", nobs(m3)))
cat(sprintf("SAMPLE:helping_controls:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:helping_controls:help_and_vh_scenes=%d\n", sum(df$isHelp == 1 | df$VH == 1)))
cat(sprintf("SAMPLE:helping_controls:nonmissing_controls=%d\n", nrow(hel_c)))
cat(sprintf("SAMPLE:helping_controls:estimation=%d\n", nobs(m4)))
if (nobs(m3) != 401) cat(sprintf("DEVIATION: helping sample has %d obs, paper states 401\n", nobs(m3)))

se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])
cf <- function(m, v) unname(coef(m)[v])

cat(sprintf("RESULT:child_punishment_no_controls=%.6f\n", cf(m1, "Child")))
cat(sprintf("RESULT:child_punishment_no_controls_se=%.6f\n", se(m1, "Child")))
cat(sprintf("RESULT:child_punishment_controls=%.6f\n", cf(m2, "Child")))
cat(sprintf("RESULT:child_punishment_controls_se=%.6f\n", se(m2, "Child")))
cat(sprintf("RESULT:child_helping_no_controls=%.6f\n", cf(m3, "Child")))
cat(sprintf("RESULT:child_helping_no_controls_se=%.6f\n", se(m3, "Child")))
cat(sprintf("RESULT:child_helping_controls=%.6f\n", cf(m4, "Child")))
cat(sprintf("RESULT:child_helping_controls_se=%.6f\n", se(m4, "Child")))
cat(sprintf("RESULT:vh_punishment_controls=%.6f\n", cf(m2, "VH")))
cat(sprintf("RESULT:vh_helping_controls=%.6f\n", cf(m4, "VH")))
cat(sprintf("RESULT:child_x_vh_punishment_no_controls=%.6f\n", cf(m1, "Child_VH")))
cat(sprintf("RESULT:child_x_vh_punishment_controls=%.6f\n", cf(m2, "Child_VH")))
cat(sprintf("RESULT:child_x_vh_helping_no_controls=%.6f\n", cf(m3, "Child_VH")))
cat(sprintf("RESULT:child_x_vh_helping_controls=%.6f\n", cf(m4, "Child_VH")))
cat(sprintf("RESULT:observations_punishment_controls=%d\n", nobs(m2)))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", nobs(m3)))