suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms"
f_dta <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
f_csv <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")

df <- tryCatch(as.data.frame(haven::read_dta(f_dta)), error = function(e) NULL)
if (is.null(df)) df <- as.data.frame(readr::read_csv(f_csv, show_col_types = FALSE))
df <- as.data.frame(haven::zap_labels(df))

num <- function(x) suppressWarnings(as.numeric(as.character(x)))
vars <- c("School", "Child", "Violation", "Help", "ViolationHelp", "Punishment", "Helping",
          "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot")
for (v in vars) df[[v]] <- num(df[[v]])

# As in the do-file
df$Helping[!is.na(df$Violation) & df$Violation == 1] <- NA
df$Punishment[!is.na(df$Help) & df$Help == 1] <- NA

df$ChildVH <- df$Child * df$ViolationHelp

dp <- df[!is.na(df$Help) & df$Help == 0, ]
dh <- df[!is.na(df$Violation) & df$Violation == 0, ]

ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

fit <- function(y, d, controls = FALSE) {
  rhs <- "Child + ViolationHelp + ChildVH"
  if (controls) rhs <- paste(rhs, "+", ctrl)
  fml <- as.formula(paste(y, "~", rhs))
  feols(fml, data = d, cluster = ~School)
}

m1 <- fit("Punishment", dp, FALSE)
m2 <- fit("Punishment", dp, TRUE)
m3 <- fit("Helping", dh, FALSE)
m4 <- fit("Helping", dh, TRUE)

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

out("child_punishment_no_controls", coef(m1)["Child"])
out("child_punishment_controls", coef(m2)["Child"])
out("child_helping_no_controls", coef(m3)["Child"])
out("child_helping_controls", coef(m4)["Child"])
out("vh_punishment_controls", coef(m2)["ViolationHelp"])
out("vh_helping_controls", coef(m4)["ViolationHelp"])
out("child_x_vh_punishment_no_controls", coef(m1)["ChildVH"])
out("child_x_vh_punishment_controls", coef(m2)["ChildVH"])
out("child_x_vh_helping_no_controls", coef(m3)["ChildVH"])
out("child_x_vh_helping_controls", coef(m4)["ChildVH"])
out("observations_punishment_controls", nobs(m2))
out("observations_helping_no_controls", nobs(m3))
