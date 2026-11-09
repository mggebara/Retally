suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
f <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
d <- haven::read_dta(f)
d <- haven::zap_labels(d)
d <- as.data.frame(d)

to_num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}

for (v in c("Child", "Violation", "ViolationHelp", "Help", "Punishment", "Helping",
            "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot", "School")) {
  if (v %in% names(d)) d[[v]] <- to_num(d[[v]])
}

# Child dummy: ensure 0/1
if (!all(d$Child %in% c(0, 1, NA))) {
  d$Child <- as.numeric(d$Child == max(d$Child, na.rm = TRUE))
}

# Scene indicators
vh  <- !is.na(d$ViolationHelp) & d$ViolationHelp == 1
vio <- !is.na(d$Violation) & d$Violation == 1
hlp <- !is.na(d$Help) & d$Help == 1
# If Violation / Help dummies also flag the VH scene, strip VH out
v_only <- vio & !vh
h_only <- hlp & !vh

d$VH <- as.numeric(vh)
d$ChildxVH <- d$Child * d$VH

pun <- d[(v_only | vh) & !is.na(d$Punishment), ]
hel <- d[(h_only | vh) & !is.na(d$Helping), ]

controls <- c("male", "hugo", "Morning", "witness", "rich", "Rain", "Hot")
ctrl_str <- paste(controls, collapse = " + ")

m1 <- feols(Punishment ~ Child + VH + ChildxVH, data = pun, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child + VH + ChildxVH +", ctrl_str)),
            data = pun, cluster = ~School)
m3 <- feols(Helping ~ Child + VH + ChildxVH, data = hel, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child + VH + ChildxVH +", ctrl_str)),
            data = hel, cluster = ~School)

print(summary(m1)); print(summary(m2)); print(summary(m3)); print(summary(m4))

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

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
cat(sprintf("RESULT:observations_punishment_controls=%d\n", as.integer(nobs(m2))))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", as.integer(nobs(m3))))
