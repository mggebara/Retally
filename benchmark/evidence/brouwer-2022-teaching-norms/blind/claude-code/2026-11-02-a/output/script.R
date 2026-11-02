## Brouwer et al. (2022) "Teaching Norms" -- Table 2 reproduction (independent, blind)
## Pooled OLS LPMs, school-clustered SEs.
suppressMessages({library(haven); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/blind/2026-11-02-a/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
d <- zap_labels(d)
d$VH <- as.numeric(d$scene == 3)
d$School <- as.character(d$School)

pun <- subset(d, scene %in% c(2, 3))   # Violation and Violation + Help
hel <- subset(d, scene %in% c(1, 3))   # Help and Violation + Help
ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

m1 <- feols(Punishment ~ Child * VH, data = pun, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child * VH +", ctrl)), data = pun, cluster = ~School)
m3 <- feols(Helping ~ Child * VH, data = hel, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child * VH +", ctrl)), data = hel, cluster = ~School)
etable(m1, m2, m3, m4)

ix <- "Child:VH"
out <- c(
  child_punishment_no_controls      = coef(m1)[["Child"]],
  child_punishment_controls         = coef(m2)[["Child"]],
  child_helping_no_controls         = coef(m3)[["Child"]],
  child_helping_controls            = coef(m4)[["Child"]],
  vh_punishment_controls            = coef(m2)[["VH"]],
  vh_helping_controls               = coef(m4)[["VH"]],
  child_x_vh_punishment_no_controls = coef(m1)[[ix]],
  child_x_vh_punishment_controls    = coef(m2)[[ix]],
  child_x_vh_helping_no_controls    = coef(m3)[[ix]],
  child_x_vh_helping_controls       = coef(m4)[[ix]],
  observations_punishment_controls  = nobs(m2),
  observations_helping_no_controls  = nobs(m3)
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
