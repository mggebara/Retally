# Balan, Bergeron, Tourek & Weigel (2022, AER) "Local Elites as State Capacity"
# Independent reproduction of Tables 4-8 claims from the paper's description.
# Equation (1): y_ijkt = b0 + b*Local_jkt + X_ijk G + alpha_k + theta_t + e, OLS, SEs clustered by neighborhood (a7).
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})

B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"

## ---------------- Treatment assignment and strata ----------------
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
# treatment: 0 Control, 1 Central, 2 Local, 3 CLI (Central + Local Information), 4 CXL.
# Paper fn 40: one neighborhood randomly assigned to CXL received Local; de facto assignment used.
# Neighborhood 654 is the CXL-assigned neighborhood where only the chief collected (registration 'who' = chief)
# and endline records it as Local; recoding it gives the paper's Table 2 counts (111 Local / 50 CXL neighborhoods).
ra$trt <- ra$treatment
ra$trt[ra$a7 == 654] <- 2
# randomization stratum: group(geo_stratum jontax chef_collect_stratum) -- geography, 2016 campaign status, chief tax experience
ra <- ra[, c("a7", "trt", "stratum")]

## ---------------- Property universe (registered properties) ----------------
# hh_distances holds one row per registered property in the 356 study neighborhoods (45,162 incl. Control);
# property characteristics (house band, exemption, registration date) come from the registration survey.
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
hd <- hd[!is.na(hd$compound1), c("compound1", "a7")]
hd <- merge(hd, ra, by = "a7")
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"),
                          col_select = c(a7, compound1, start, tot_complete, house, exempt)))
rg <- rg[rg$compound1 %in% hd$compound1, ] %>% arrange(compound1, desc(tot_complete), start) %>%
  filter(!duplicated(compound1))
u <- merge(hd, rg[, c("compound1", "start", "house", "exempt")], by = "compound1")
u$d <- as.Date(u$start)                     # registration date of the property
u$house <- factor(u$house)                  # 1 low-value band, 2 high-value band

## ---------------- Outcomes: compliance and revenue ----------------
tp <- zap_labels(read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")))
tp <- tp[!is.na(tp$compound1) & tp$error_code %in% 0, ]   # receipt records flagged as errors dropped
tp$amountCF[tp$amountCF > 13200 & !is.na(tp$amountCF)] <- 13200  # two impossible amounts (>100x max liability) capped
pay <- tp %>% group_by(compound1) %>% summarise(rev = sum(amountCF, na.rm = TRUE), .groups = "drop")
u$compliance <- as.numeric(u$compound1 %in% pay$compound1)
u$revenue <- pay$rev[match(u$compound1, pay$compound1)]
u$revenue[is.na(u$revenue)] <- 0

## ---------------- Time periods (online Appendix A2.5) ----------------
# Two-month periods starting at the midpoint between the arms' first registration days and ending at the
# midpoint between their last registration days; properties outside drop out.
make_periods <- function(df, arms) {
  s <- df[df$trt %in% arms, ]
  fd <- tapply(as.numeric(s$d), s$trt, min); ld <- tapply(as.numeric(s$d), s$trt, max)
  st <- as.Date(floor(mean(fd)), origin = "1970-01-01")
  en <- as.Date(ceiling(mean(ld)), origin = "1970-01-01")
  br <- seq(st, by = "2 months", length.out = 8)
  s$period <- ifelse(s$d >= st & s$d <= en, findInterval(as.numeric(s$d), as.numeric(br)), NA)
  cat(sprintf("Arms %s: window %s to %s; N before %d, after %d; clusters %d -> %d\n",
              paste(arms, collapse = ","), st, en, nrow(s), sum(!is.na(s$period)),
              length(unique(s$a7)), length(unique(s$a7[!is.na(s$period)]))))
  s
}

cl <- u[u$trt %in% c(1, 2), ]
cl$local <- as.numeric(cl$trt == 2)
clp <- make_periods(u, c(1, 2)); clp$local <- as.numeric(clp$trt == 2)
clp <- clp[!is.na(clp$period), ]

co <- function(m, v) unname(coef(m)[v])
rep_m <- function(name, m, v) cat(sprintf("  %-50s b=%.4f se=%.4f N=%d\n", name, co(m, v), se(m)[v], nobs(m)))

cat("\nTable 4\n")
m1  <- feols(compliance ~ local | stratum, data = cl, cluster = ~a7)
m2  <- feols(compliance ~ local | stratum + period, data = clp, cluster = ~a7)
m4  <- feols(compliance ~ local | stratum + period + house, data = clp, cluster = ~a7)
m5  <- feols(compliance ~ local | stratum + period + house, data = clp[!(clp$exempt %in% 1), ], cluster = ~a7)
r1  <- feols(revenue ~ local | stratum, data = cl, cluster = ~a7)
r2  <- feols(revenue ~ local | stratum + period, data = clp, cluster = ~a7)
r4  <- feols(revenue ~ local | stratum + period + house, data = clp, cluster = ~a7)
for (x in list(list("compliance col1", m1), list("compliance col2", m2), list("compliance col4", m4), list("compliance col5", m5),
               list("revenue col1", r1), list("revenue col2", r2), list("revenue col4", r4))) rep_m(x[[1]], x[[2]], "local")
cat(sprintf("  Central means: col1 compliance %.3f revenue %.1f; col2 compliance %.3f revenue %.1f\n",
            mean(cl$compliance[cl$local == 0]), mean(cl$revenue[cl$local == 0]),
            mean(clp$compliance[clp$local == 0]), mean(clp$revenue[clp$local == 0])))

## ---------------- Table 5 Panel B: paid bribe (endline) ----------------
e1 <- zap_labels(read_dta(file.path(B, "survey_data/endline_round1_noPII.dta"),
                          col_select = c(a7, code, visited, bribe)))
e1 <- merge(e1, ra, by = "a7")
e1 <- e1[e1$trt %in% c(1, 2), ]
# 'bribe': did you (or a family member) pay the transport of the collector? -- asked of households visited
# with someone present (visited == 1); households not visited (0) or visited with nobody home (2) paid none.
e1$paid_bribe <- ifelse(e1$visited %in% c(0, 2), 0, e1$bribe)
e1 <- e1[!is.na(e1$paid_bribe), ]
e1 <- e1[!duplicated(e1$code) | is.na(e1$code), ]
e1$local <- as.numeric(e1$trt == 2)
b5 <- feols(paid_bribe ~ local | stratum, data = e1, cluster = ~a7)
cat("\nTable 5\n"); rep_m("paid bribe endline", b5, "local")
cat(sprintf("  Central mean %.3f\n", mean(e1$paid_bribe[e1$local == 0])))

## ---------------- Table 6 col 1: visited by collector after registration (midline) ----------------
md <- zap_labels(read_dta(file.path(B, "survey_data/midline_noPII.dta"),
                          col_select = c(a7, compound, visited, visits, tot_complete, start)))
md$compound1 <- ifelse(md$compound < 1e5, md$a7 * 1000 + md$compound, md$compound)
md <- md[!is.na(md$compound1) & md$compound1 %in% clp$compound1, ] %>%
  arrange(compound1, desc(tot_complete), is.na(visited), start) %>% filter(!duplicated(compound1))
md$visits[md$visits >= 90] <- NA            # don't-know codes
# 'visits' counts all collector visits including the registration visit: a post-registration visit is visits >= 2
md$visited_post <- ifelse(md$visited %in% c(0), 0, ifelse(is.na(md$visits), NA, as.numeric(md$visits >= 2)))
mv <- merge(md[, c("compound1", "visited_post")], clp[, c("compound1", "a7", "local", "stratum", "period", "house")], by = "compound1")
v6 <- feols(visited_post ~ local | house + stratum + period, data = mv, cluster = ~a7)
cat("\nTable 6\n"); rep_m("visited by collector", v6, "local")
cat(sprintf("  Central mean %.3f\n", mean(mv$visited_post[mv$local == 0], na.rm = TRUE)))

## ---------------- Table 7: CLI vs Central ----------------
ccp <- make_periods(u, c(1, 3)); ccp <- ccp[!is.na(ccp$period), ]
ccp$cli <- as.numeric(ccp$trt == 3)
t7c <- feols(compliance ~ cli | house + stratum + period, data = ccp, cluster = ~a7)
t7r <- feols(revenue ~ cli | house + stratum + period, data = ccp, cluster = ~a7)
cat("\nTable 7\n"); rep_m("CLI compliance", t7c, "cli"); rep_m("CLI revenue", t7r, "cli")

## ---------------- Table 8 Panel A col 2: chief's ease-of-payment rating (CLI only) ----------------
cc <- zap_labels(read_dta(file.path(B, "survey_data/chief_consultations.dta"), col_select = c(compound1, pay_ease)))
cc$pay_ease[cc$pay_ease == 8888] <- NA      # "don't know"
cli <- merge(u[u$trt == 3, ], cc, by = "compound1")
cli <- cli[!is.na(cli$pay_ease), ]
t8 <- feols(compliance ~ pay_ease | house + stratum, data = cli, cluster = ~a7)
cat("\nTable 8\n"); rep_m("ease of payment (CLI)", t8, "pay_ease")
cat(sprintf("  clusters %d\n", length(unique(cli$a7))))

cat("\nDEVIATION: time periods use each property's registration date; the paper's exact period construction (online Appendix A2.5) is not available, so the trimmed samples differ from the paper's (Local/Central col 2 has the paper's 213 clusters but fewer properties; CLI/Central keeps 157 rather than 165 clusters). The universe has 12 more Central properties than the paper's Table 2 (14,501 vs 14,489).\n")
cat("DEVIATION: Table 6 midline outcome = household reports 2+ collector visits including registration (0 if no visit); midline records linked to the register by compound code, so fewer observations than the paper.\n")
cat("DEVIATION: payment records flagged error_code==1 are not counted; two payment amounts above 13,200 CF (1.42m and 1.66m CF) are capped at 13,200 CF.\n")
cat("DEVIATION: endline bribe outcome set to 0 for households reporting no collector visit (question asked only of visited households).\n")

cat(sprintf("RESULT:compliance_local_table4_panelA_col1=%.6f\n", co(m1, "local")))
cat(sprintf("RESULT:compliance_local_table4_panelA_col2=%.6f\n", co(m2, "local")))
cat(sprintf("RESULT:compliance_local_house_fe_table4_panelA_col4=%.6f\n", co(m4, "local")))
cat(sprintf("RESULT:compliance_local_exempt_excluded_table4_panelA_col5=%.6f\n", co(m5, "local")))
cat(sprintf("RESULT:revenue_local_table4_panelB_col2=%.6f\n", co(r2, "local")))
cat(sprintf("RESULT:revenue_local_house_fe_table4_panelB_col4=%.6f\n", co(r4, "local")))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table4_col2=%d\n", nobs(m2)))
cat(sprintf("RESULT:paid_bribe_endline_local_table5_panelB=%.6f\n", co(b5, "local")))
cat(sprintf("RESULT:visited_by_collector_local_table6_col1=%.6f\n", co(v6, "local")))
cat(sprintf("RESULT:compliance_cli_table7_col1=%.6f\n", co(t7c, "cli")))
cat(sprintf("RESULT:revenue_cli_table7_col2=%.6f\n", co(t7r, "cli")))
cat(sprintf("RESULT:compliance_ease_of_payment_cli_table8_panelA_col2=%.6f\n", co(t8, "pay_ease")))
