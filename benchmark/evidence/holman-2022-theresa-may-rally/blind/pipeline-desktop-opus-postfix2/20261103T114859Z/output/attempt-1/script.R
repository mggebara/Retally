suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free"

clean_num <- function(x) {
  x <- as.numeric(haven::zap_labels(x))
  x[x %in% c(9999, 999, -999, -99, -9, -8, -7)] <- NA
  x
}

midpoint_fill <- function(x) {
  if (all(is.na(x))) return(x)
  mp <- (min(x, na.rm = TRUE) + max(x, na.rm = TRUE)) / 2
  x[is.na(x)] <- mp
  x
}

## =====================================================================
## Table 4: cross-national TSCS of executive approval
## =====================================================================
g <- haven::read_dta(file.path(base, "global_approval.dta"))
g <- as.data.frame(haven::zap_labels(g))
cat(sprintf("SAMPLE:table4:loaded=%d\n", nrow(g)))
nm <- names(g)

# attack indicator: international attack with more than 15 deaths (16+)
att_var <- if ("kill_16" %in% nm) "kill_16" else if ("kill_15" %in% nm) "kill_15" else "pres_15death"
g$attack <- clean_num(g[[att_var]])
g$attack <- as.numeric(g$attack > 0)

g$woman <- clean_num(g$female_pres)
g$growth_c <- clean_num(g$growth)
g$loginf <- clean_num(g$log_inflation)
g$exec_lrc <- as.numeric(haven::zap_labels(g$execrlc))
g$exec_lrc[g$exec_lrc < 0] <- NA
g$elect <- clean_num(g$election_qtr)
g$qtr_n <- as.numeric(g$qtr)
cty <- if ("country" %in% nm) "country" else "ccode"
g$cty <- as.character(g[[cty]])

# dependent variable: approval in the quarter following the attack
appr <- setdiff(grep("approv", nm, value = TRUE, ignore.case = TRUE), "lag_approval")
lead_c <- grep("lead|^f_|^f\\.|next|fwd|_f$|^F", appr, value = TRUE, ignore.case = TRUE)
if (length(lead_c) > 0) {
  g$dv <- clean_num(g[[lead_c[1]]])
} else {
  avar <- if ("approval" %in% appr) "approval" else appr[1]
  g$appr_now <- clean_num(g[[avar]])
  # lead within country (and office type) unit by consecutive quarter
  unit <- if ("country_code" %in% nm) as.character(g$country_code) else g$cty
  g$unit <- unit
  nxt <- g[, c("unit", "qtr_n", "appr_now")]
  nxt$qtr_n <- nxt$qtr_n - 1
  names(nxt)[3] <- "dv"
  nxt <- nxt[!duplicated(nxt[, c("unit", "qtr_n")]), ]
  g <- left_join(g, nxt, by = c("unit", "qtr_n"))
}

g4 <- g[complete.cases(g[, c("dv", "attack", "woman", "growth_c", "loginf",
                             "exec_lrc", "elect", "cty")]), ]
cat(sprintf("SAMPLE:table4:nonmissing_model_vars=%d\n", nrow(g4)))
m4 <- feols(dv ~ attack * woman + growth_c + loginf + exec_lrc + elect | cty,
            data = g4, vcov = "hetero")
cat(sprintf("SAMPLE:table4:estimation=%d\n", nobs(m4)))

## =====================================================================
## Table 2: panel difference-in-differences
## =====================================================================
d <- haven::read_dta(file.path(base, "did_data.dta"),
                     col_select = c("wave", "treatment1", "time", "likeMayW",
                                    "may_bestpm", "white", "gender", "labour",
                                    "party_other", "income", "ideology", "id"))
d <- as.data.frame(haven::zap_labels(d))
n_loaded <- nrow(d)

d$treat <- clean_num(d$treatment1)
d$time <- clean_num(d$time)
d$wave <- clean_num(d$wave)
d$likeMay <- clean_num(d$likeMayW)
d$likeMay[!is.na(d$likeMay) & (d$likeMay < 0 | d$likeMay > 10)] <- NA
d$bestpm <- clean_num(d$may_bestpm)
d$bestpm[!is.na(d$bestpm) & !(d$bestpm %in% c(0, 1))] <- NA
d$white <- clean_num(d$white)
d$gender <- clean_num(d$gender)
d$labour <- clean_num(d$labour)
d$party_other <- clean_num(d$party_other)
inc <- clean_num(d$income)
ideo <- clean_num(d$ideology)
ideo[!is.na(ideo) & (ideo < 0 | ideo > 10)] <- NA
d$income_r <- midpoint_fill(inc)
d$ideology_r <- midpoint_fill(ideo)
d$wave_f <- factor(d$wave)
d$treat_time <- d$treat * d$time

rhs <- "treat + time + treat_time + white + gender + labour + party_other + income_r + ideology_r + wave_f"
xvars <- c("treat", "time", "white", "gender", "labour", "party_other",
           "income_r", "ideology_r", "wave")

# May likeability (OLS)
cat(sprintf("SAMPLE:table2_like:loaded=%d\n", n_loaded))
dl <- d[complete.cases(d[, c("likeMay", xvars)]), ]
cat(sprintf("SAMPLE:table2_like:nonmissing_model_vars=%d\n", nrow(dl)))
dl$wave_f <- droplevels(dl$wave_f)
m_like <- lm(as.formula(paste("likeMay ~", rhs)), data = dl)
cat(sprintf("SAMPLE:table2_like:estimation=%d\n", nobs(m_like)))
cl <- coef(m_like)
rm(dl); invisible(gc())

# May best PM (logit)
cat(sprintf("SAMPLE:table2_bestpm:loaded=%d\n", n_loaded))
db <- d[complete.cases(d[, c("bestpm", xvars)]), ]
cat(sprintf("SAMPLE:table2_bestpm:nonmissing_model_vars=%d\n", nrow(db)))
db$wave_f <- droplevels(db$wave_f)
m_pm <- glm(as.formula(paste("bestpm ~", rhs)), data = db,
            family = binomial(link = "logit"))
cat(sprintf("SAMPLE:table2_bestpm:estimation=%d\n", nobs(m_pm)))
cb <- coef(m_pm)

## =====================================================================
## Results
## =====================================================================
c4 <- coef(m4)
cat(sprintf("RESULT:intl_attack_table4=%.6f\n", c4["attack"]))
cat(sprintf("RESULT:intl_attack_x_woman_exec_table4=%.6f\n", c4["attack:woman"]))
cat(sprintf("RESULT:n_obs_table4=%d\n", nobs(m4)))
cat(sprintf("RESULT:did_attack_x_time_like_may_table2=%.6f\n", cl["treat_time"]))
cat(sprintf("RESULT:did_attack_like_may_table2=%.6f\n", cl["treat"]))
cat(sprintf("RESULT:did_time_like_may_table2=%.6f\n", cl["time"]))
cat(sprintf("RESULT:did_attack_x_time_may_best_pm_table2=%.6f\n", cb["treat_time"]))
cat(sprintf("RESULT:did_attack_may_best_pm_table2=%.6f\n", cb["treat"]))
cat(sprintf("RESULT:did_time_may_best_pm_table2=%.6f\n", cb["time"]))
cat(sprintf("RESULT:n_obs_did_like_may_table2=%d\n", nobs(m_like)))
cat(sprintf("RESULT:n_obs_did_may_best_pm_table2=%d\n", nobs(m_pm)))