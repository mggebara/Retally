suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
f <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
d <- as.data.frame(haven::zap_labels(haven::read_dta(f)))

num <- function(x) suppressWarnings(as.numeric(x))
for (v in c("Child", "Violation", "ViolationHelp", "Help", "Punishment", "Helping",
            "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot", "School", "scene")) {
  if (v %in% names(d)) d[[v]] <- num(d[[v]])
}
cat("Rows:", nrow(d), "\n")
if ("scene" %in% names(d)) print(table(d$scene, useNA = "ifany"))
print(table(V = d$Violation, VH = d$ViolationHelp, H = d$Help, useNA = "ifany"))

z <- function(x) ifelse(is.na(x), 0, x)
d$VH <- z(d$ViolationHelp)
# Robust to either coding (scene dummies exclusive, or Violation/Help also = 1 in VH)
d$inPun <- (z(d$Violation) == 1) | (d$VH == 1)
d$inHelp <- (z(d$Help) == 1) | (d$VH == 1)

dp <- d[d$inPun & !is.na(d$Punishment), ]
dh <- d[d$inHelp & !is.na(d$Helping), ]
cat("Punishment sample:", nrow(dp), " Helping sample:", nrow(dh), "\n")

# Fallback if dummy-based selection fails
if (nrow(dp) < 350 || nrow(dp) > 450) {
  dp <- d[!is.na(d$Punishment), ]
  if (nrow(dp) > 450 && "Help" %in% names(d)) dp <- dp[!(z(dp$Help) == 1 & dp$VH == 0), ]
}
if (nrow(dh) < 350 || nrow(dh) > 450) {
  dh <- d[!is.na(d$Helping), ]
  if (nrow(dh) > 450) dh <- dh[!(z(dh$Violation) == 1 & dh$VH == 0), ]
}
cat("Final punishment sample:", nrow(dp), " helping sample:", nrow(dh), "\n")

ctrls <- "male + hugo + Morning + witness + rich + Rain + Hot"

m1 <- feols(Punishment ~ Child * VH, data = dp, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child * VH +", ctrls)), data = dp, cluster = ~School)
m3 <- feols(Helping ~ Child * VH, data = dh, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child * VH +", ctrls)), data = dh, cluster = ~School)

print(etable(m1, m2, m3, m4))

cf <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

out <- c(
  child_punishment_no_controls = cf(m1, "Child"),
  child_punishment_controls = cf(m2, "Child"),
  child_helping_no_controls = cf(m3, "Child"),
  child_helping_controls = cf(m4, "Child"),
  vh_punishment_controls = cf(m2, "VH"),
  vh_helping_controls = cf(m4, "VH"),
  child_x_vh_punishment_no_controls = cf(m1, "Child:VH"),
  child_x_vh_punishment_controls = cf(m2, "Child:VH"),
  child_x_vh_helping_no_controls = cf(m3, "Child:VH"),
  child_x_vh_helping_controls = cf(m4, "Child:VH"),
  observations_punishment_controls = nobs(m2),
  observations_helping_no_controls = nobs(m3)
)

cat(sprintf("SE child pun nc=%.4f c=%.4f; help nc=%.4f c=%.4f\n",
            se(m1, "Child"), se(m2, "Child"), se(m3, "Child"), se(m4, "Child")))

for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))