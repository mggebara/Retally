suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
f_dta <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
f_csv <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")

if (file.exists(f_dta)) {
  d <- haven::read_dta(f_dta)
  d <- haven::zap_labels(d)
} else {
  d <- readr::read_csv(f_csv, show_col_types = FALSE)
}
d <- as.data.frame(d)
cat("Rows:", nrow(d), "\n")

to01 <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  u <- sort(unique(x[!is.na(x)]))
  if (length(u) == 2 && !all(u %in% c(0, 1))) x <- as.numeric(x == max(u))
  x
}

for (v in c("Child", "Violation", "Help", "ViolationHelp", "Punishment", "Helping",
            "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot")) {
  if (v %in% names(d)) d[[v]] <- to01(d[[v]])
}

cat("Scene table:\n"); print(table(d$scene, useNA = "ifany"))
cat("Violation x Help x VH:\n"); print(table(d$Violation, d$Help, d$ViolationHelp, useNA = "ifany"))
cat("Child table:\n"); print(table(d$Child, useNA = "ifany"))

# Scene indicators (robust to whether Violation/Help dummies include the VH scene)
VH <- d$ViolationHelp == 1
VH[is.na(VH)] <- FALSE
Vonly <- (d$Violation == 1) & !VH
Vonly[is.na(Vonly)] <- FALSE
Honly <- (d$Help == 1) & !VH
Honly[is.na(Honly)] <- FALSE
d$VH <- as.numeric(VH)

dp <- d[Vonly | VH, ]
dh <- d[Honly | VH, ]
cat("Punishment sample:", nrow(dp), " Helping sample:", nrow(dh), "\n")

ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

m1 <- feols(Punishment ~ Child * VH, data = dp, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child * VH +", ctrl)), data = dp, cluster = ~School)
m3 <- feols(Helping ~ Child * VH, data = dh, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child * VH +", ctrl)), data = dh, cluster = ~School)

print(etable(m1, m2, m3, m4))

gc <- function(m, v) unname(coef(m)[v])
ix <- "Child:VH"

cat(sprintf("RESULT:child_punishment_no_controls=%.6f\n", gc(m1, "Child")))
cat(sprintf("RESULT:child_punishment_controls=%.6f\n", gc(m2, "Child")))
cat(sprintf("RESULT:child_helping_no_controls=%.6f\n", gc(m3, "Child")))
cat(sprintf("RESULT:child_helping_controls=%.6f\n", gc(m4, "Child")))
cat(sprintf("RESULT:vh_punishment_controls=%.6f\n", gc(m2, "VH")))
cat(sprintf("RESULT:vh_helping_controls=%.6f\n", gc(m4, "VH")))
cat(sprintf("RESULT:child_x_vh_punishment_no_controls=%.6f\n", gc(m1, ix)))
cat(sprintf("RESULT:child_x_vh_punishment_controls=%.6f\n", gc(m2, ix)))
cat(sprintf("RESULT:child_x_vh_helping_no_controls=%.6f\n", gc(m3, ix)))
cat(sprintf("RESULT:child_x_vh_helping_controls=%.6f\n", gc(m4, ix)))
cat(sprintf("RESULT:observations_punishment_controls=%d\n", nobs(m2)))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", nobs(m3)))