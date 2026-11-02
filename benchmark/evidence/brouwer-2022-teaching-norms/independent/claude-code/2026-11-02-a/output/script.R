## Brouwer et al. (2022), Table 2: pooled OLS LPMs, school-clustered SEs
set.seed(42)
suppressPackageStartupMessages(library(fixest))
d <- read.csv("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/independent/2026-11-02-a/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")
d$VH <- d$ViolationHelp
# Male Target = male; Male Actor = hugo (male actor); Witness = witness; Rich area = rich
ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

dp <- subset(d, scene %in% c("Violation", "Violation+Help"))
dh <- subset(d, scene %in% c("Help", "Violation+Help"))

f0p <- as.formula("Punishment ~ Child * VH")
f1p <- as.formula(paste("Punishment ~ Child * VH +", ctrl))
f0h <- as.formula("Helping ~ Child * VH")
f1h <- as.formula(paste("Helping ~ Child * VH +", ctrl))

m1 <- feols(f0p, data = dp, cluster = ~School)
m2 <- feols(f1p, data = dp, cluster = ~School)
m3 <- feols(f0h, data = dh, cluster = ~School)
m4 <- feols(f1h, data = dh, cluster = ~School)
etable(m1, m2, m3, m4)

r <- function(nm, v) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
r("child_punishment_no_controls", coef(m1)["Child"])
r("child_punishment_controls", coef(m2)["Child"])
r("child_helping_no_controls", coef(m3)["Child"])
r("child_helping_controls", coef(m4)["Child"])
r("vh_punishment_controls", coef(m2)["VH"])
r("vh_helping_controls", coef(m4)["VH"])
r("child_x_vh_punishment_no_controls", coef(m1)["Child:VH"])
r("child_x_vh_punishment_controls", coef(m2)["Child:VH"])
r("child_x_vh_helping_no_controls", coef(m3)["Child:VH"])
r("child_x_vh_helping_controls", coef(m4)["Child:VH"])
r("observations_punishment_controls", nobs(m2))
r("observations_helping_no_controls", nobs(m3))
