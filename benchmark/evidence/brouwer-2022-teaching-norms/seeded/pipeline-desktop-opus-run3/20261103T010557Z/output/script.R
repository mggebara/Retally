suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms"
path <- file.path(base, "Data Replication Package EJ MS20210782", "3 replication package", "Data", "master.dta")
df <- haven::read_dta(path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)

num <- function(x) as.numeric(x)
for (v in c("Punishment", "Helping", "Child", "ViolationHelp", "Violation", "Help",
            "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot", "School")) {
  df[[v]] <- num(df[[v]])
}

# As in the do-file: Helping missing in Violation scene, Punishment missing in Help scene
df$Helping[df$Violation == 1] <- NA
df$Punishment[df$Help == 1] <- NA

dp <- df[!is.na(df$Help) & df$Help == 0, ]
dh <- df[!is.na(df$Violation) & df$Violation == 0, ]

f_p1 <- Punishment ~ Child * ViolationHelp
f_p2 <- Punishment ~ Child * ViolationHelp + male + hugo + Morning + witness + rich + Rain + Hot
f_h1 <- Helping ~ Child * ViolationHelp
f_h2 <- Helping ~ Child * ViolationHelp + male + hugo + Morning + witness + rich + Rain + Hot

m1 <- feols(f_p1, data = dp, cluster = ~School)
m2 <- feols(f_p2, data = dp, cluster = ~School)
m3 <- feols(f_h1, data = dh, cluster = ~School)
m4 <- feols(f_h2, data = dh, cluster = ~School)

ia <- "Child:ViolationHelp"
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

out("child_punishment_no_controls", coef(m1)["Child"])
out("child_punishment_controls", coef(m2)["Child"])
out("child_helping_no_controls", coef(m3)["Child"])
out("child_helping_controls", coef(m4)["Child"])
out("vh_punishment_controls", coef(m2)["ViolationHelp"])
out("vh_helping_controls", coef(m4)["ViolationHelp"])
out("child_x_vh_punishment_no_controls", coef(m1)[ia])
out("child_x_vh_punishment_controls", coef(m2)[ia])
out("child_x_vh_helping_no_controls", coef(m3)[ia])
out("child_x_vh_helping_controls", coef(m4)[ia])
cat(sprintf("RESULT:observations_punishment_controls=%d\n", nobs(m2)))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", nobs(m3)))

out("child_punishment_no_controls_se", se(m1, "Child"))
out("child_punishment_controls_se", se(m2, "Child"))
out("child_helping_no_controls_se", se(m3, "Child"))
out("child_helping_controls_se", se(m4, "Child"))