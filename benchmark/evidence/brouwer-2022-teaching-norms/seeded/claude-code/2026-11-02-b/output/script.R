suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-b/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data"
d <- as.data.frame(zap_labels(read_dta(file.path(base, "master.dta"))))
# As in the do-file before Table 2
d$Helping[d$Violation == 1] <- NA
d$Punishment[d$Help == 1] <- NA
dp <- d[d$Help == 0, ]
dh <- d[d$Violation == 0, ]
ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"
f0p <- Punishment ~ Child * ViolationHelp
f0h <- Helping ~ Child * ViolationHelp
f1p <- as.formula(paste("Punishment ~ Child * ViolationHelp +", ctrl))
f1h <- as.formula(paste("Helping ~ Child * ViolationHelp +", ctrl))
m1 <- feols(f0p, dp, cluster = ~School)
m2 <- feols(f1p, dp, cluster = ~School)
m3 <- feols(f0h, dh, cluster = ~School)
m4 <- feols(f1h, dh, cluster = ~School)
for (m in list(m1, m2, m3, m4)) print(summary(m))
r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
ix <- "Child:ViolationHelp"
r("child_punishment_no_controls", coef(m1)["Child"])
r("child_punishment_controls", coef(m2)["Child"])
r("child_helping_no_controls", coef(m3)["Child"])
r("child_helping_controls", coef(m4)["Child"])
r("vh_punishment_controls", coef(m2)["ViolationHelp"])
r("vh_helping_controls", coef(m4)["ViolationHelp"])
r("child_x_vh_punishment_no_controls", coef(m1)[ix])
r("child_x_vh_punishment_controls", coef(m2)[ix])
r("child_x_vh_helping_no_controls", coef(m3)[ix])
r("child_x_vh_helping_controls", coef(m4)[ix])
r("observations_punishment_controls", nobs(m2))
r("observations_helping_no_controls", nobs(m3))
