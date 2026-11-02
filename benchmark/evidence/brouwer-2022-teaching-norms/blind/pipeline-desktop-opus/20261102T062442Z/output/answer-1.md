suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
f <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")
d <- readr::read_csv(f, show_col_types = FALSE)
d <- as.data.frame(d)

to01 <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x))
  xs <- tolower(trimws(as.character(x)))
  out <- suppressWarnings(as.numeric(xs))
  out[xs %in% c("yes", "true", "child")] <- 1
  out[xs %in% c("no", "false", "alone")] <- 0
  out
}

for (v in c("Child", "Violation", "ViolationHelp", "Help", "Punishment", "Helping",
            "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot")) {
  if (v %in% names(d)) d[[v]] <- to01(d[[v]])
}

# Fallback for Child from Condition if needed
if (all(is.na(d$Child)) && "Condition" %in% names(d)) {
  cs <- tolower(as.character(d$Condition))
  d$Child <- ifelse(grepl("child", cs), 1, ifelse(grepl("alone", cs), 0, NA))
}

# Scene indicators (robust to Violation possibly being 1 in VH scene too)
vh <- !is.na(d$ViolationHelp) & d$ViolationHelp == 1
viol_only <- !is.na(d$Violation) & d$Violation == 1 & !vh
help_only <- !is.na(d$Help) & d$Help == 1 & !vh

# If dummies don't partition the sample, fall back to the scene variable
if (sum(vh) + sum(viol_only) + sum(help_only) < 0.9 * nrow(d) && "scene" %in% names(d)) {
  sc <- tolower(trimws(as.character(d$scene)))
  vh <- grepl("vh|violation.*help|v\\+h|^3$", sc)
  viol_only <- (grepl("viol", sc) | sc == "1") & !vh
  help_only <- (grepl("help", sc) | sc == "2") & !vh
}

d$VH <- as.numeric(vh)

pun <- d[viol_only | vh, ]
hel <- d[help_only | vh, ]
pun <- pun[!is.na(pun$Punishment) & !is.na(pun$Child), ]
hel <- hel[!is.na(hel$Helping) & !is.na(hel$Child), ]

ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

m1 <- feols(Punishment ~ Child * VH, data = pun, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child * VH +", ctrl)), data = pun, cluster = ~School)
m3 <- feols(Helping ~ Child * VH, data = hel, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child * VH +", ctrl)), data = hel, cluster = ~School)

g <- function(m, nm) unname(coef(m)[nm])
ix <- "Child:VH"

cat(sprintf("RESULT:child_punishment_no_controls=%.6f\n", g(m1, "Child")))
cat(sprintf("RESULT:child_punishment_controls=%.6f\n", g(m2, "Child")))
cat(sprintf("RESULT:child_helping_no_controls=%.6f\n", g(m3, "Child")))
cat(sprintf("RESULT:child_helping_controls=%.6f\n", g(m4, "Child")))
cat(sprintf("RESULT:vh_punishment_controls=%.6f\n", g(m2, "VH")))
cat(sprintf("RESULT:vh_helping_controls=%.6f\n", g(m4, "VH")))
cat(sprintf("RESULT:child_x_vh_punishment_no_controls=%.6f\n", g(m1, ix)))
cat(sprintf("RESULT:child_x_vh_punishment_controls=%.6f\n", g(m2, ix)))
cat(sprintf("RESULT:child_x_vh_helping_no_controls=%.6f\n", g(m3, ix)))
cat(sprintf("RESULT:child_x_vh_helping_controls=%.6f\n", g(m4, ix)))
cat(sprintf("RESULT:observations_punishment_controls=%d\n", as.integer(nobs(m2))))
cat(sprintf("RESULT:observations_helping_no_controls=%d\n", as.integer(nobs(m3))))
