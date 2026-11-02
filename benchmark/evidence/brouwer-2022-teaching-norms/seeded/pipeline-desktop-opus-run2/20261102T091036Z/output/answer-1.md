suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data"
d <- tryCatch(haven::read_dta(file.path(base, "master.dta")),
              error = function(e) readr::read_csv(file.path(base, "master.csv"), show_col_types = FALSE))
d <- as.data.frame(haven::zap_labels(d))

vars <- c("School", "Child", "ViolationHelp", "Violation", "Help", "Punishment", "Helping",
          "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot")
for (v in vars) d[[v]] <- suppressWarnings(as.numeric(d[[v]]))

# As in the do-file
d$Helping[!is.na(d$Violation) & d$Violation == 1] <- NA
d$Punishment[!is.na(d$Help) & d$Help == 1] <- NA

dp <- d[!is.na(d$Help) & d$Help == 0, ]
dh <- d[!is.na(d$Violation) & d$Violation == 0, ]

f0p <- Punishment ~ Child * ViolationHelp
f1p <- Punishment ~ Child * ViolationHelp + male + hugo + Morning + witness + rich + Rain + Hot
f0h <- Helping ~ Child * ViolationHelp
f1h <- Helping ~ Child * ViolationHelp + male + hugo + Morning + witness + rich + Rain + Hot

m1 <- feols(f0p, data = dp, cluster = ~School)
m2 <- feols(f1p, data = dp, cluster = ~School)
m3 <- feols(f0h, data = dh, cluster = ~School)
m4 <- feols(f1h, data = dh, cluster = ~School)

ix <- "Child:ViolationHelp"
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

out("child_punishment_no_controls", coef(m1)["Child"])
out("child_punishment_controls", coef(m2)["Child"])
out("child_helping_no_controls", coef(m3)["Child"])
out("child_helping_controls", coef(m4)["Child"])
out("vh_punishment_controls", coef(m2)["ViolationHelp"])
out("vh_helping_controls", coef(m4)["ViolationHelp"])
out("child_x_vh_punishment_no_controls", coef(m1)[ix])
out("child_x_vh_punishment_controls", coef(m2)[ix])
out("child_x_vh_helping_no_controls", coef(m3)[ix])
out("child_x_vh_helping_controls", coef(m4)[ix])
out("observations_punishment_controls", nobs(m2))
out("observations_helping_no_controls", nobs(m3))
