suppressMessages({library(haven); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/blind/2026-11-07-a/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
d <- zap_labels(d)
d$VH <- d$ViolationHelp
ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

pun <- subset(d, scene %in% c(2, 3))   # Violation, Violation + Help
hel <- subset(d, scene %in% c(1, 3))   # Help, Violation + Help

m1 <- feols(Punishment ~ Child * VH, data = pun, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child * VH +", ctrl)), data = pun, cluster = ~School)
m3 <- feols(Helping ~ Child * VH, data = hel, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child * VH +", ctrl)), data = hel, cluster = ~School)
etable(m1, m2, m3, m4)

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
out("child_punishment_no_controls", coef(m1)["Child"])
out("child_punishment_controls", coef(m2)["Child"])
out("child_helping_no_controls", coef(m3)["Child"])
out("child_helping_controls", coef(m4)["Child"])
out("vh_punishment_controls", coef(m2)["VH"])
out("vh_helping_controls", coef(m4)["VH"])
out("child_x_vh_punishment_no_controls", coef(m1)["Child:VH"])
out("child_x_vh_punishment_controls", coef(m2)["Child:VH"])
out("child_x_vh_helping_no_controls", coef(m3)["Child:VH"])
out("child_x_vh_helping_controls", coef(m4)["Child:VH"])
cat(sprintf("RESULT:observations_punishment_controls=%d\n", nobs(m2)))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", nobs(m3)))
