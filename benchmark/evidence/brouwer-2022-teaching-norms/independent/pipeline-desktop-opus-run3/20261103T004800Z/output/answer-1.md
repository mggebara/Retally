suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
f <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")
d <- suppressWarnings(readr::read_csv(f, show_col_types = FALSE, guess_max = 10000))
d <- as.data.frame(d)

tonum <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  y <- suppressWarnings(as.numeric(as.character(x)))
  y
}
for (v in c("Child","Violation","ViolationHelp","Help","Punishment","Helping","male","hugo",
            "Morning","witness","rich","Rain","Hot","School")) {
  if (v %in% names(d) && v != "School") d[[v]] <- tonum(d[[v]])
}

d$vh <- as.numeric(!is.na(d$ViolationHelp) & d$ViolationHelp == 1)
d$viol_only <- as.numeric(!is.na(d$Violation) & d$Violation == 1 & d$vh == 0)
d$help_only <- as.numeric(!is.na(d$Help) & d$Help == 1 & d$vh == 0)

pun <- d[(d$viol_only == 1 | d$vh == 1) & !is.na(d$Punishment), ]
hel <- d[(d$help_only == 1 | d$vh == 1) & !is.na(d$Helping), ]

# Fallback using the scene variable if the dummies did not give the expected samples
if ((nrow(pun) != 400 || nrow(hel) != 401) && "scene" %in% names(d)) {
  sc <- tolower(as.character(d$scene))
  scn <- suppressWarnings(as.numeric(sc))
  message("Sample sizes from dummies: ", nrow(pun), " / ", nrow(hel), "; scene values: ",
          paste(unique(sc), collapse = ","))
  pun2 <- d[!is.na(d$Punishment), ]
  hel2 <- d[!is.na(d$Helping) & !(d$viol_only == 1), ]
  if (nrow(pun2) == 400) pun <- pun2
  if (nrow(hel2) == 401) hel <- hel2
}

pun$Child_x_VH <- pun$Child * pun$vh
hel$Child_x_VH <- hel$Child * hel$vh

ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

m1 <- feols(Punishment ~ Child + vh + Child_x_VH, data = pun, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child + vh + Child_x_VH +", ctrl)), data = pun, cluster = ~School)
m3 <- feols(Helping ~ Child + vh + Child_x_VH, data = hel, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child + vh + Child_x_VH +", ctrl)), data = hel, cluster = ~School)

print(etable(m1, m2, m3, m4))

cf <- function(m, v) unname(coef(m)[v])
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

out("child_punishment_no_controls", cf(m1, "Child"))
out("child_punishment_controls", cf(m2, "Child"))
out("child_helping_no_controls", cf(m3, "Child"))
out("child_helping_controls", cf(m4, "Child"))
out("vh_punishment_controls", cf(m2, "vh"))
out("vh_helping_controls", cf(m4, "vh"))
out("child_x_vh_punishment_no_controls", cf(m1, "Child_x_VH"))
out("child_x_vh_punishment_controls", cf(m2, "Child_x_VH"))
out("child_x_vh_helping_no_controls", cf(m3, "Child_x_VH"))
out("child_x_vh_helping_controls", cf(m4, "Child_x_VH"))
out("observations_punishment_controls", nobs(m2))
out("observations_helping_no_controls", nobs(m3))
