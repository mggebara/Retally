# Brouwer et al. (2022) "Teaching Norms" -- Table 2, independent blind reproduction.
# Pooled OLS LPMs, school-clustered SEs.
#   Punishment: sample = Violation + Violation+Help scenes
#   Helping:    sample = Help + Violation+Help scenes
#   RHS: Child, VH (Violation+Help scene), Child x VH [+ controls]
#   Controls: Male Target (male), Male Actor (hugo), Morning, Witness (witness),
#             Rich area (rich), Rain, Hot
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest) })

d <- read_dta("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/blind/2026-11-02-b/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
d <- zap_labels(d)
d <- as.data.frame(d)
d$VH <- as.numeric(d$scene == 3)   # Violation+Help scene
stopifnot(all(d$VH == d$ViolationHelp))

pun <- subset(d, scene %in% c(2, 3))
hel <- subset(d, scene %in% c(1, 3))

ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"
f_pun0 <- Punishment ~ Child * VH
f_pun1 <- as.formula(paste("Punishment ~ Child * VH +", ctrl))
f_hel0 <- Helping ~ Child * VH
f_hel1 <- as.formula(paste("Helping ~ Child * VH +", ctrl))

m1 <- feols(f_pun0, data = pun, cluster = ~School)
m2 <- feols(f_pun1, data = pun, cluster = ~School)
m3 <- feols(f_hel0, data = hel, cluster = ~School)
m4 <- feols(f_hel1, data = hel, cluster = ~School)

etable(m1, m2, m3, m4, se.below = TRUE)
cat("clusters: pun", length(unique(pun$School)), " hel", length(unique(hel$School)), "\n")

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
