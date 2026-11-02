# Brouwer et al. (2022), Teaching Norms -- Table 2 (independent reproduction)
set.seed(42)
suppressPackageStartupMessages(library(fixest))
d <- readr::read_csv("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/independent/2026-11-02-b/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.csv", show_col_types = FALSE)
d$VH <- d$ViolationHelp
d$ChildxVH <- d$Child * d$VH

pun <- subset(d, scene %in% c("Violation", "Violation+Help"))
hel <- subset(d, scene %in% c("Help", "Violation+Help"))

ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"
f0p <- Punishment ~ Child + VH + ChildxVH
f1p <- as.formula(paste("Punishment ~ Child + VH + ChildxVH +", ctrl))
f0h <- Helping ~ Child + VH + ChildxVH
f1h <- as.formula(paste("Helping ~ Child + VH + ChildxVH +", ctrl))

m1 <- feols(f0p, data = pun, cluster = ~School)
m2 <- feols(f1p, data = pun, cluster = ~School)
m3 <- feols(f0h, data = hel, cluster = ~School)
m4 <- feols(f1h, data = hel, cluster = ~School)
etable(m1, m2, m3, m4)

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("child_punishment_no_controls", coef(m1)["Child"])
r("child_punishment_controls", coef(m2)["Child"])
r("child_helping_no_controls", coef(m3)["Child"])
r("child_helping_controls", coef(m4)["Child"])
r("vh_punishment_controls", coef(m2)["VH"])
r("vh_helping_controls", coef(m4)["VH"])
r("child_x_vh_punishment_no_controls", coef(m1)["ChildxVH"])
r("child_x_vh_punishment_controls", coef(m2)["ChildxVH"])
r("child_x_vh_helping_no_controls", coef(m3)["ChildxVH"])
r("child_x_vh_helping_controls", coef(m4)["ChildxVH"])
r("observations_punishment_controls", nobs(m2))
r("observations_helping_no_controls", nobs(m3))
