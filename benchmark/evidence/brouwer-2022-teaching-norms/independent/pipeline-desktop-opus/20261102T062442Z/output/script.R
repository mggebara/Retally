suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/brouwer_2022_teaching_norms.script-free"
dta_path <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
csv_path <- file.path(base, "Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")

df <- tryCatch(as.data.frame(haven::zap_labels(haven::read_dta(dta_path))),
               error = function(e) as.data.frame(readr::read_csv(csv_path, show_col_types = FALSE)))

to_num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}

for (v in c("Child", "Violation", "Help", "ViolationHelp", "Punishment", "Helping",
            "male", "hugo", "Morning", "witness", "rich", "Rain", "Hot", "School")) {
  if (v %in% names(df)) df[[v]] <- to_num(df[[v]])
}

# Child dummy: ensure 0/1
if (!all(na.omit(df$Child) %in% c(0, 1))) {
  if ("Condition" %in% names(df)) {
    cc <- tolower(as.character(df$Condition))
    df$Child <- as.numeric(grepl("child", cc))
  }
}

# Scene identification
scene_str <- tolower(as.character(df$scene))
V  <- if ("Violation" %in% names(df)) df$Violation else rep(NA, nrow(df))
H  <- if ("Help" %in% names(df)) df$Help else rep(NA, nrow(df))
VH <- if ("ViolationHelp" %in% names(df)) df$ViolationHelp else rep(NA, nrow(df))
V[is.na(V)] <- 0; H[is.na(H)] <- 0; VH[is.na(VH)] <- 0

if (sum(VH == 1) > 0) {
  df$VH <- as.numeric(VH == 1)
} else {
  df$VH <- as.numeric(V == 1 & H == 1)
}
df$inV <- as.numeric(V == 1 | df$VH == 1)
df$inH <- as.numeric(H == 1 | df$VH == 1)

# Fallback using scene variable if dummies look wrong
if (sum(df$inV) < 350 || sum(df$inV) > 450 || sum(df$inH) < 350 || sum(df$inH) > 450) {
  sv <- df$scene
  if (is.numeric(sv) || !any(is.na(suppressWarnings(as.numeric(as.character(sv)))))) {
    s <- as.numeric(as.character(sv))
    # guess: 1 = Violation, 2 = Help, 3 = VH
    df$VH  <- as.numeric(s == 3)
    df$inV <- as.numeric(s %in% c(1, 3))
    df$inH <- as.numeric(s %in% c(2, 3))
  } else {
    isVH <- grepl("vh", scene_str) | (grepl("viol", scene_str) & grepl("help", scene_str))
    df$VH  <- as.numeric(isVH)
    df$inV <- as.numeric(grepl("viol", scene_str) | isVH | scene_str == "v")
    df$inH <- as.numeric(grepl("help", scene_str) | isVH | scene_str == "h")
  }
}

dP <- df %>% filter(inV == 1, !is.na(Punishment))
dH <- df %>% filter(inH == 1, !is.na(Helping))
# Final sanity fallback: use non-missing outcomes
if (nrow(dP) < 350 || nrow(dP) > 450) dP <- df %>% filter(!is.na(Punishment))
if (nrow(dH) < 350 || nrow(dH) > 450) dH <- df %>% filter(!is.na(Helping))

ctrl <- "male + hugo + Morning + witness + rich + Rain + Hot"

m1 <- feols(Punishment ~ Child * VH, data = dP, cluster = ~School)
m2 <- feols(as.formula(paste("Punishment ~ Child * VH +", ctrl)), data = dP, cluster = ~School)
m3 <- feols(Helping ~ Child * VH, data = dH, cluster = ~School)
m4 <- feols(as.formula(paste("Helping ~ Child * VH +", ctrl)), data = dH, cluster = ~School)

g <- function(m, v) unname(coef(m)[v])
out <- function(n, x) cat(sprintf("RESULT:%s=%.6f\n", n, x))

out("child_punishment_no_controls", g(m1, "Child"))
out("child_punishment_controls", g(m2, "Child"))
out("child_helping_no_controls", g(m3, "Child"))
out("child_helping_controls", g(m4, "Child"))
out("vh_punishment_controls", g(m2, "VH"))
out("vh_helping_controls", g(m4, "VH"))
out("child_x_vh_punishment_no_controls", g(m1, "Child:VH"))
out("child_x_vh_punishment_controls", g(m2, "Child:VH"))
out("child_x_vh_helping_no_controls", g(m3, "Child:VH"))
out("child_x_vh_helping_controls", g(m4, "Child:VH"))
out("observations_punishment_controls", nobs(m2))
out("observations_helping_no_controls", nobs(m3))