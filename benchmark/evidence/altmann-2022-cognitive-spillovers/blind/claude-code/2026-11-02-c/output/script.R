# Altmann, Grunewald & Radbruch (2022), "Interventions and Cognitive Spillovers"
# Independent, blind reproduction of Tables 2-4 (lab) and Table 3 cols 5-6 (online).
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(dplyr); library(fixest) })

D <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-11-02-c/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"

# ---------------- Lab experiment ----------------
d <- read_dta(paste0(D, "formatted_data_replication.dta"))
env <- as.character(as_factor(d$Treatment_Environment))
inc <- as.character(as_factor(d$Treatment_Incentives))

lab <- d %>%
  mutate(env = env, inc = inc) %>%
  filter(inc != "Ample") %>%                       # scarce cognitive resources only
  mutate(
    intervention   = as.numeric(zap_labels(Treatment_intervention)),
    directed       = as.numeric(grepl("Directed", env)),
    forced         = as.numeric(grepl("Forced", env)),
    choice_correct = as.numeric(zap_labels(summation_correct)),
    default_adh    = as.numeric(zap_labels(default_followed)),
    bg_correct     = as.numeric(zap_labels(load_correct)),
    payoff_share   = as.numeric(payoff_share),
    female         = as.numeric(zap_labels(q_gender)),
    field          = factor(as.numeric(zap_labels(subject_cat))),
    gpa_cat        = factor(q_abitur_grade_cat),       # GPA quartiles, 5 = missing / no A-level
    math_cat       = factor(q_math_grade_cat),
    scheme         = factor(inc),
    wave           = factor(as.numeric(zap_labels(original_lab)))
  )

stopifnot(all(lab$intervention == (lab$directed | lab$forced)))
ctrl <- "q_age + female + field + gpa_cat + math_cat + ability_load + ability_task + perc_multitasking_1 + scheme + wave"

est <- function(y, x, controls = FALSE, data = lab) {
  f <- as.formula(paste(y, "~", x, if (controls) paste("+", ctrl) else ""))
  feols(f, data = data, cluster = ~subject_id)
}

m1 <- est("choice_correct", "intervention")
m2 <- est("choice_correct", "intervention", TRUE)
m5 <- est("default_adh", "intervention")
m6 <- est("default_adh", "intervention", TRUE)
m7 <- est("default_adh", "directed + forced")
b1 <- est("bg_correct", "intervention")
b2 <- est("bg_correct", "intervention", TRUE)
p1 <- est("payoff_share", "intervention")

for (m in list(m1, m2, m5, m6, m7, b1, b2, p1)) {
  ct <- summary(m)$coeftable
  print(ct[rownames(ct) %in% c("intervention", "directed", "forced"), , drop = FALSE])
}
cat("nobs per model:", sapply(list(m1, m2, m5, m6, m7, b1, b2, p1), nobs), "\n")

# ---------------- Online experiment ----------------
o <- read_dta(paste0(D, "formatted_data_long_mturk.dta")) %>%
  mutate(
    intervention = as.numeric(zap_labels(Treatment_intervention)),
    gender_f     = factor(as.numeric(zap_labels(gender))),
    memory       = as.numeric(memory)
  )
o5 <- feols(memory ~ intervention, data = o, cluster = ~subject_id)
o6 <- feols(memory ~ intervention + age + gender_f + window_height1 + window_width1, data = o, cluster = ~subject_id)
print(summary(o5)$coeftable); print(summary(o6)$coeftable[1:2, ])
cat("online nobs:", nobs(o5), nobs(o6), " subjects:", length(unique(o$subject_id)), "\n")

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("choice_quality_intervention_t2_col1", coef(m1)[["intervention"]])
r("choice_quality_intervention_t2_col2", coef(m2)[["intervention"]])
r("default_adherence_intervention_t2_col5", coef(m5)[["intervention"]])
r("default_adherence_intervention_t2_col6", coef(m6)[["intervention"]])
r("default_adherence_directed_attention_t2_col7", coef(m7)[["directed"]])
r("default_adherence_forced_choice_t2_col7", coef(m7)[["forced"]])
r("background_quality_intervention_lab_t3_col1", coef(b1)[["intervention"]])
r("background_quality_intervention_lab_t3_col2", coef(b2)[["intervention"]])
r("memory_intervention_online_t3_col5", coef(o5)[["intervention"]])
r("payoff_share_intervention_t4_col1", coef(p1)[["intervention"]])
cat(sprintf("RESULT:n_obs_lab_tables_2_to_4=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_subjects_lab_tables_2_to_4=%d\n", length(unique(lab$subject_id))))
r("memory_intervention_online_t3_col6", coef(o6)[["intervention"]])
