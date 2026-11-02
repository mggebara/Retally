suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
f_csv <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")
f_dta <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")

df <- tryCatch(as.data.frame(haven::zap_labels(haven::read_dta(f_dta))),
               error = function(e) as.data.frame(read_csv(f_csv, show_col_types = FALSE)))

num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}
for (v in c("Child","Violation","Help","ViolationHelp","Punishment","Helping","male",
            "hugo","Morning","witness","rich","Rain","Hot","School")) {
  if (v %in% names(df)) df[[v]] <- num(df[[v]])
}

# Scene identification
vh  <- !is.na(df$ViolationHelp) & df$ViolationHelp == 1
vio <- !is.na(df$Violation) & df$Violation == 1 & !vh
hel <- !is.na(df$Help) & df$Help == 1 & !vh
if (sum(vh) + sum(vio) + sum(hel) != nrow(df) && "scene" %in% names(df)) {
  sc <- tolower(as.character(df$scene))
  if (all(grepl("^[0-9.]+$", sc[!is.na(sc)]))) {
    # numeric coding fallback: rely on dummies as computed
  } else {
    vh  <- grepl("vh|violation ?\\+ ?help|violationhelp|both", sc)
    vio <- grepl("viol", sc) & !vh
    hel <- grepl("help", sc) & !vh
  }
}
df$VH <- as.numeric(vh)
df$ChildVH <- df$Child * df$VH

pun <- df[(vio | vh) & !is.na(df$Punishment), ]
hlp <- df[(hel | vh) & !is.na(df$Helping), ]

ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"
f_p1 <- as.formula("Punishment ~ Child + VH + ChildVH")
f_p2 <- as.formula(paste("Punishment ~ Child + VH + ChildVH +", ctrl))
f_h1 <- as.formula("Helping ~ Child + VH + ChildVH")
f_h2 <- as.formula(paste("Helping ~ Child + VH + ChildVH +", ctrl))

m1 <- feols(f_p1, data = pun, cluster = ~School)
m2 <- feols(f_p2, data = pun, cluster = ~School)
m3 <- feols(f_h1, data = hlp, cluster = ~School)
m4 <- feols(f_h2, data = hlp, cluster = ~School)

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

out("child_punishment_no_controls", coef(m1)["Child"])
out("child_punishment_controls", coef(m2)["Child"])
out("child_helping_no_controls", coef(m3)["Child"])
out("child_helping_controls", coef(m4)["Child"])
out("vh_punishment_controls", coef(m2)["VH"])
out("vh_helping_controls", coef(m4)["VH"])
out("child_x_vh_punishment_no_controls", coef(m1)["ChildVH"])
out("child_x_vh_punishment_controls", coef(m2)["ChildVH"])
out("child_x_vh_helping_no_controls", coef(m3)["ChildVH"])
out("child_x_vh_helping_controls", coef(m4)["ChildVH"])
cat(sprintf("RESULT:observations_punishment_controls=%d\n", as.integer(nobs(m2))))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", as.integer(nobs(m3))))