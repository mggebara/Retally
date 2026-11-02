# Brouwer et al. (2022) Teaching Norms -- Table 2 reproduction (independent, blind)
# Pooled OLS LPMs, school-clustered SEs.
suppressPackageStartupMessages(library(fixest))
set.seed(42)

d <- read.csv("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/blind/2026-11-02-c/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")

d$VH <- d$ViolationHelp
d$ChildVH <- d$Child * d$VH
d$MaleTarget <- d$male      # father targeted (NA for 2 observations)
d$MaleActor <- d$hugo       # male actor played the scene

pun <- subset(d, scene %in% c("Violation", "Violation+Help"))
hel <- subset(d, scene %in% c("Help", "Violation+Help"))

ctrl <- "+ MaleTarget + MaleActor + Morning + witness + rich + Rain + Hot"
f_pun0 <- Punishment ~ Child + VH + ChildVH
f_pun1 <- as.formula(paste("Punishment ~ Child + VH + ChildVH", ctrl))
f_hel0 <- Helping ~ Child + VH + ChildVH
f_hel1 <- as.formula(paste("Helping ~ Child + VH + ChildVH", ctrl))

m1 <- feols(f_pun0, data = pun, cluster = ~School)
m2 <- feols(f_pun1, data = pun, cluster = ~School)
m3 <- feols(f_hel0, data = hel, cluster = ~School)
m4 <- feols(f_hel1, data = hel, cluster = ~School)

for (m in list(m1, m2, m3, m4)) print(summary(m))

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
out("child_punishment_no_controls", coef(m1)[["Child"]])
out("child_punishment_controls", coef(m2)[["Child"]])
out("child_helping_no_controls", coef(m3)[["Child"]])
out("child_helping_controls", coef(m4)[["Child"]])
out("vh_punishment_controls", coef(m2)[["VH"]])
out("vh_helping_controls", coef(m4)[["VH"]])
out("child_x_vh_punishment_no_controls", coef(m1)[["ChildVH"]])
out("child_x_vh_punishment_controls", coef(m2)[["ChildVH"]])
out("child_x_vh_helping_no_controls", coef(m3)[["ChildVH"]])
out("child_x_vh_helping_controls", coef(m4)[["ChildVH"]])
cat(sprintf("RESULT:observations_punishment_controls=%d\n", nobs(m2)))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", nobs(m3)))
