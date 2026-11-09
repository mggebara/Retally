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

num <- function(x) suppressWarnings(as.numeric(x))
for (v in c("Child", "Violation", "Help", "ViolationHelp", "Punishment", "Helping",
            "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot", "School")) {
  if (v %in% names(d)) d[[v]] <- num(d[[v]])
}

d$VH <- ifelse(is.na(d$ViolationHelp), 0, d$ViolationHelp)
d$Viol_only <- ifelse(is.na(d$Violation), 0, d$Violation)
d$Help_only <- ifelse(is.na(d$Help), 0, d$Help)
d$ChildVH <- d$Child * d$VH
d$MaleTarget <- d$male
d$MaleActor <- d$hugo

pun <- d %>% filter((Viol_only == 1 | VH == 1) & !is.na(Punishment) & !is.na(Child))
hel <- d %>% filter((Help_only == 1 | VH == 1) & !is.na(Helping) & !is.na(Child))

ctrl <- "MaleTarget + MaleActor + Morning + witness + rich + Rain + Hot"

m1 <- feols(Punishment ~ Child + VH + ChildVH, data = pun, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child + VH + ChildVH +", ctrl)), data = pun, cluster = ~School)
m3 <- feols(Helping ~ Child + VH + ChildVH, data = hel, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child + VH + ChildVH +", ctrl)), data = hel, cluster = ~School)

se <- function(m, v) sqrt(diag(vcov(m)))[v]
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
out("observations_punishment_controls", nobs(m2))
out("observations_helping_no_controls", nobs(m3))