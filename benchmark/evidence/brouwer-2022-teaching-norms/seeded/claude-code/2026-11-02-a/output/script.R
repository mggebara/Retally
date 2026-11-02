suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/seeded/2026-11-02-a/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data"
d <- as.data.frame(zap_labels(read_dta(file.path(base, "master.dta"))))
# As in the do-file before Table 2
d$Helping[d$Violation == 1] <- NA
d$Punishment[d$Help == 1] <- NA
ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"
fp <- d[d$Help == 0, ]; fh <- d[d$Violation == 0, ]
m1 <- feols(Punishment ~ Child * ViolationHelp, data = fp, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child * ViolationHelp +", ctrl)), data = fp, cluster = ~School)
m3 <- feols(Helping ~ Child * ViolationHelp, data = fh, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child * ViolationHelp +", ctrl)), data = fh, cluster = ~School)
for (m in list(m1, m2, m3, m4)) print(summary(m))
b <- function(m, v) unname(coef(m)[v])
ix <- "Child:ViolationHelp"
out <- c(
  child_punishment_no_controls = b(m1, "Child"),
  child_punishment_controls = b(m2, "Child"),
  child_helping_no_controls = b(m3, "Child"),
  child_helping_controls = b(m4, "Child"),
  vh_punishment_controls = b(m2, "ViolationHelp"),
  vh_helping_controls = b(m4, "ViolationHelp"),
  child_x_vh_punishment_no_controls = b(m1, ix),
  child_x_vh_punishment_controls = b(m2, ix),
  child_x_vh_helping_no_controls = b(m3, ix),
  child_x_vh_helping_controls = b(m4, ix),
  observations_punishment_controls = nobs(m2),
  observations_helping_no_controls = nobs(m3))
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
