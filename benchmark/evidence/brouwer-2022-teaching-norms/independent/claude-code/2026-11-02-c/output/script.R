## Brouwer et al. (2022) Teaching Norms -- Table 2 independent reproduction
suppressPackageStartupMessages({ library(haven); library(fixest) })
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/independent/2026-11-02-c/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
d <- zap_labels(d)
d$VH <- as.numeric(d$scene == 3)          # Violation + Help scene
d$ChildVH <- d$Child * d$VH
# Male Actor: 'hugo' dummy (the male actor); Male Target: 'male'
ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

pun <- subset(d, scene %in% c(2, 3))      # Violation, Violation+Help
hel <- subset(d, scene %in% c(1, 3))      # Help, Violation+Help

f1 <- Punishment ~ Child + VH + ChildVH
f2 <- as.formula(paste("Punishment ~ Child + VH + ChildVH +", ctrl))
f3 <- Helping ~ Child + VH + ChildVH
f4 <- as.formula(paste("Helping ~ Child + VH + ChildVH +", ctrl))

m1 <- feols(f1, data = pun, cluster = ~School)
m2 <- feols(f2, data = pun, cluster = ~School)
m3 <- feols(f3, data = hel, cluster = ~School)
m4 <- feols(f4, data = hel, cluster = ~School)
etable(m1, m2, m3, m4)

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("child_punishment_no_controls", coef(m1)["Child"])
r("child_punishment_controls", coef(m2)["Child"])
r("child_helping_no_controls", coef(m3)["Child"])
r("child_helping_controls", coef(m4)["Child"])
r("vh_punishment_controls", coef(m2)["VH"])
r("vh_helping_controls", coef(m4)["VH"])
r("child_x_vh_punishment_no_controls", coef(m1)["ChildVH"])
r("child_x_vh_punishment_controls", coef(m2)["ChildVH"])
r("child_x_vh_helping_no_controls", coef(m3)["ChildVH"])
r("child_x_vh_helping_controls", coef(m4)["ChildVH"])
r("observations_punishment_controls", nobs(m2))
r("observations_helping_no_controls", nobs(m3))
