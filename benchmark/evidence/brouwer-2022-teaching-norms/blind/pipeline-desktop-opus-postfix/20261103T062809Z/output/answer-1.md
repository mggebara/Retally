suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
f <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")
df <- readr::read_csv(f, show_col_types = FALSE)

num <- function(x) suppressWarnings(as.numeric(x))
df <- df %>% mutate(
  Child = num(Child), Violation = num(Violation), Help = num(Help),
  ViolationHelp = num(ViolationHelp), Punishment = num(Punishment),
  Helping = num(Helping), male = num(male), hugo = num(hugo),
  Morning = num(Morning), witness = num(witness), rich = num(rich),
  Rain = num(Rain), Hot = num(Hot)
)

# Scene indicators: VH scene, pure Violation scene, pure Help scene
df <- df %>% mutate(
  VH = as.numeric(!is.na(ViolationHelp) & ViolationHelp == 1),
  is_V = as.numeric(!is.na(Violation) & Violation == 1 & VH == 0),
  is_H = as.numeric(!is.na(Help) & Help == 1 & VH == 0)
)
# Fallback using scene variable if dummies look inconsistent
if (sum(df$VH) < 50 || sum(df$is_V) < 50 || sum(df$is_H) < 50) {
  sc <- tolower(as.character(df$scene))
  sv <- sort(unique(sc))
  is_vh <- grepl("viol", sc) & grepl("help", sc) | sc %in% c("3", "vh")
  df$VH <- as.numeric(is_vh)
  df$is_V <- as.numeric((grepl("viol", sc) | sc %in% c("1", "v")) & !is_vh)
  df$is_H <- as.numeric((grepl("help", sc) | sc %in% c("2", "h")) & !is_vh)
}
df$ChildxVH <- df$Child * df$VH

cat(sprintf("SAMPLE:punishment:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:helping:loaded=%d\n", nrow(df)))

# Punishment sample: Violation and Violation+Help scenes (drop Help scene)
dp <- df %>% filter(is_V == 1 | VH == 1)
cat(sprintf("SAMPLE:punishment:drop_help_scene=%d\n", nrow(dp)))
dp <- dp %>% filter(!is.na(Punishment), !is.na(Child))

# Helping sample: Help and Violation+Help scenes (drop Violation scene)
dh <- df %>% filter(is_H == 1 | VH == 1)
cat(sprintf("SAMPLE:helping:drop_violation_scene=%d\n", nrow(dh)))
dh <- dh %>% filter(!is.na(Helping), !is.na(Child))

ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

m1 <- feols(Punishment ~ Child + VH + ChildxVH, data = dp, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child + VH + ChildxVH +", ctrl)), data = dp, cluster = ~School)
m3 <- feols(Helping ~ Child + VH + ChildxVH, data = dh, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child + VH + ChildxVH +", ctrl)), data = dh, cluster = ~School)

cat(sprintf("SAMPLE:punishment:estimation=%d\n", nobs(m2)))
cat(sprintf("SAMPLE:punishment_nocontrols:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:punishment_nocontrols:drop_help_scene=%d\n", nrow(dp)))
cat(sprintf("SAMPLE:punishment_nocontrols:estimation=%d\n", nobs(m1)))
cat(sprintf("SAMPLE:helping:estimation=%d\n", nobs(m4)))
cat(sprintf("SAMPLE:helping_nocontrols:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:helping_nocontrols:drop_violation_scene=%d\n", nrow(dh)))
cat(sprintf("SAMPLE:helping_nocontrols:estimation=%d\n", nobs(m3)))

for (m in list(m1, m2, m3, m4)) print(summary(m))

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
out("child_punishment_no_controls", coef(m1)["Child"])
out("child_punishment_controls", coef(m2)["Child"])
out("child_helping_no_controls", coef(m3)["Child"])
out("child_helping_controls", coef(m4)["Child"])
out("vh_punishment_controls", coef(m2)["VH"])
out("vh_helping_controls", coef(m4)["VH"])
out("child_x_vh_punishment_no_controls", coef(m1)["ChildxVH"])
out("child_x_vh_punishment_controls", coef(m2)["ChildxVH"])
out("child_x_vh_helping_no_controls", coef(m3)["ChildxVH"])
out("child_x_vh_helping_controls", coef(m4)["ChildxVH"])
cat(sprintf("RESULT:observations_punishment_controls=%d\n", nobs(m2)))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", nobs(m3)))
