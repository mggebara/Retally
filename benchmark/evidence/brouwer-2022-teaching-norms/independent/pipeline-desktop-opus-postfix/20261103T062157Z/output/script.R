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
for (v in c("Child", "Violation", "Help", "ViolationHelp", "Punishment", "Helping",
            "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot", "School")) {
  if (v %in% names(df)) df[[v]] <- num(df[[v]])
}

z <- function(x) ifelse(is.na(x), 0, x)
df$is_vh <- z(df$ViolationHelp) == 1
df$is_v  <- z(df$Violation) == 1 & !df$is_vh
df$is_h  <- z(df$Help) == 1 & !df$is_vh
df$VH <- as.numeric(df$is_vh)
df$ChildVH <- df$Child * df$VH
df$male_actor <- df$hugo

controls <- c("male", "male_actor", "Morning", "witness", "rich", "Rain", "Hot")

# ---------------- Punishment sample ----------------
cat(sprintf("SAMPLE:punishment:loaded=%d\n", nrow(df)))
pun <- df[df$is_v | df$is_vh, ]
if (nrow(pun) != 400) {
  cat(sprintf("DEVIATION: scene dummies gave %d punishment rows; using non-missing Punishment instead\n", nrow(pun)))
  pun <- df[!is.na(df$Punishment) & !(df$is_h), ]
}
cat(sprintf("SAMPLE:punishment:violation_and_vh_scenes=%d\n", nrow(pun)))
pun <- pun[!is.na(pun$Punishment) & !is.na(pun$Child), ]
cat(sprintf("SAMPLE:punishment:nonmissing_outcome=%d\n", nrow(pun)))

pun_c <- pun[complete.cases(pun[, controls]), ]
cat(sprintf("SAMPLE:punishment_controls:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:punishment_controls:violation_and_vh_scenes=%d\n", nrow(pun)))
cat(sprintf("SAMPLE:punishment_controls:nonmissing_controls=%d\n", nrow(pun_c)))

# ---------------- Helping sample ----------------
cat(sprintf("SAMPLE:helping:loaded=%d\n", nrow(df)))
hel <- df[df$is_h | df$is_vh, ]
if (nrow(hel) != 401) {
  cat(sprintf("DEVIATION: scene dummies gave %d helping rows; using non-missing Helping instead\n", nrow(hel)))
  hel <- df[!is.na(df$Helping) & !(df$is_v), ]
}
cat(sprintf("SAMPLE:helping:help_and_vh_scenes=%d\n", nrow(hel)))
hel <- hel[!is.na(hel$Helping) & !is.na(hel$Child), ]
cat(sprintf("SAMPLE:helping:nonmissing_outcome=%d\n", nrow(hel)))

hel_c <- hel[complete.cases(hel[, controls]), ]
cat(sprintf("SAMPLE:helping_controls:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:helping_controls:help_and_vh_scenes=%d\n", nrow(hel)))
cat(sprintf("SAMPLE:helping_controls:nonmissing_controls=%d\n", nrow(hel_c)))

# ---------------- Models ----------------
ctrl_str <- paste(controls, collapse = " + ")
f1 <- as.formula("Punishment ~ Child + VH + ChildVH")
f2 <- as.formula(paste("Punishment ~ Child + VH + ChildVH +", ctrl_str))
f3 <- as.formula("Helping ~ Child + VH + ChildVH")
f4 <- as.formula(paste("Helping ~ Child + VH + ChildVH +", ctrl_str))

m1 <- feols(f1, data = pun,   cluster = ~School)
m2 <- feols(f2, data = pun_c, cluster = ~School)
m3 <- feols(f3, data = hel,   cluster = ~School)
m4 <- feols(f4, data = hel_c, cluster = ~School)

cat(sprintf("SAMPLE:punishment:estimation=%d\n", nobs(m1)))
cat(sprintf("SAMPLE:punishment_controls:estimation=%d\n", nobs(m2)))
cat(sprintf("SAMPLE:helping:estimation=%d\n", nobs(m3)))
cat(sprintf("SAMPLE:helping_controls:estimation=%d\n", nobs(m4)))

se <- function(m, v) sqrt(diag(vcov(m)))[v]

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

out("child_punishment_no_controls", coef(m1)["Child"])
out("child_punishment_no_controls_se", se(m1, "Child"))
out("child_punishment_controls", coef(m2)["Child"])
out("child_punishment_controls_se", se(m2, "Child"))
out("child_helping_no_controls", coef(m3)["Child"])
out("child_helping_no_controls_se", se(m3, "Child"))
out("child_helping_controls", coef(m4)["Child"])
out("child_helping_controls_se", se(m4, "Child"))
out("vh_punishment_controls", coef(m2)["VH"])
out("vh_helping_controls", coef(m4)["VH"])
out("child_x_vh_punishment_no_controls", coef(m1)["ChildVH"])
out("child_x_vh_punishment_controls", coef(m2)["ChildVH"])
out("child_x_vh_helping_no_controls", coef(m3)["ChildVH"])
out("child_x_vh_helping_controls", coef(m4)["ChildVH"])
cat(sprintf("RESULT:observations_punishment_controls=%d\n", nobs(m2)))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", nobs(m3)))