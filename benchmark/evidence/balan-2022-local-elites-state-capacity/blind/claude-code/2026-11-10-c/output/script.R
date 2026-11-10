# Balan, Bergeron, Tourek & Weigel (2022, AER) -- independent blind reproduction
# Local elites as state capacity: Tables 4-8 selected quantities.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
R <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base/"
B <- paste0(R, "admin_data/"); S <- paste0(R, "survey_data/")

## ---------------- neighborhoods: strata and de facto treatment ----------------
ra  <- read_dta(paste0(B, "randomization_assignment.dta"))
cci <- read_dta(paste0(B, "campaign_collector_info.dta"))
nb <- data.frame(a7 = as.numeric(ra$a7), stratum = as.numeric(ra$stratum),
                 rtrt = as.numeric(ra$treatment))
# de facto treatment (paper: one CXL neighborhood was implemented as Local)
nb$trt <- as.numeric(cci$Tmt[match(nb$a7, cci$a7)])
nb$trt[is.na(nb$trt)] <- nb$rtrt[is.na(nb$trt)]
cat("Randomized vs de facto treatment:\n"); print(table(rand = nb$rtrt, defacto = nb$trt))
# 0 Control, 1 Central, 2 Local, 3 CLI, 4 CXL

## ---------------- property register ----------------
reg <- read_dta(paste0(B, "registration_noPII.dta"))
pr <- reg %>%
  filter(a7 %in% nb$a7, pilot == 0, tot_complete == 1, house %in% c(1, 2)) %>%  # drop pilot, incomplete, villas
  transmute(compound1 = as.numeric(compound1), a7 = as.numeric(a7),
            house = as.numeric(house), exempt = as.numeric(exempt),
            rdate = as.Date(start))
pr <- pr[!duplicated(pr$compound1), ]
pr <- left_join(pr, nb[, c("a7", "stratum", "trt")], by = "a7")
cat("Registered properties (non-villa) by de facto arm:\n"); print(table(pr$trt))

## ---------------- tax payments (receipt data) ----------------
tp <- read_dta(paste0(B, "tax_payments_noPII.dta")) %>%
  filter(!is.na(compound1), !is.na(amountCF), amountCF > 0) %>%
  transmute(compound1 = as.numeric(compound1), amt = as.numeric(amountCF))
pay <- tp %>% group_by(compound1) %>% summarise(amt = sum(amt), .groups = "drop")
pr <- left_join(pr, pay, by = "compound1")
pr$paid <- as.numeric(!is.na(pr$amt))
pr$revenue <- ifelse(is.na(pr$amt), 0, pr$amt)
# two obvious keying errors (amounts > 100x the largest liability): set to the band liability
big <- pr$revenue > 13200
cat("Payments above the maximum liability recoded:", sum(big), "\n")
pr$revenue[big] <- ifelse(pr$house[big] == 2, 13200, 3000)

## ---------------- campaign-period time fixed effects ----------------
# Two-month periods starting at the midpoint between the first days of the two
# arms compared and ending at the midpoint between their last days (dates =
# registration dates). Observations outside the window drop out.
make_period <- function(d, armA, armB, datevar = "rdate", ref = pr) {
  fa <- min(ref$rdate[ref$trt == armA]); fb <- min(ref$rdate[ref$trt == armB])
  la <- max(ref$rdate[ref$trt == armA]); lb <- max(ref$rdate[ref$trt == armB])
  st <- (as.numeric(fa) + as.numeric(fb)) / 2
  en <- (as.numeric(la) + as.numeric(lb)) / 2
  x <- as.numeric(d[[datevar]])
  per <- floor((x - st) / 61)          # 61 days = two months
  per[is.na(x) | x < st | x > en] <- NA
  cat(sprintf("Window arms %d vs %d: %s to %s\n", armA, armB,
              format(as.Date(st, origin = "1970-01-01")), format(as.Date(en, origin = "1970-01-01"))))
  per
}

## ---------------- Table 4: Local vs Central ----------------
lc <- pr %>% filter(trt %in% c(1, 2)) %>% mutate(local = as.numeric(trt == 2))
lc$period <- make_period(lc, 1, 2)
lc2 <- lc %>% filter(!is.na(period))
cat("Table 4 col1 N =", nrow(lc), " clusters =", length(unique(lc$a7)), "\n")
cat("Table 4 col2 N =", nrow(lc2), " clusters =", length(unique(lc2$a7)), "\n")
print(table(lc2$period, lc2$local))

t4c1  <- feols(paid ~ local | stratum, data = lc, cluster = ~a7)
t4c2  <- feols(paid ~ local | stratum + period, data = lc2, cluster = ~a7)
t4c4  <- feols(paid ~ local | stratum + period + house, data = lc2, cluster = ~a7)
lc5   <- lc2 %>% filter(is.na(exempt) | exempt != 1)
t4c5  <- feols(paid ~ local | stratum + period + house, data = lc5, cluster = ~a7)
t4r2  <- feols(revenue ~ local | stratum + period, data = lc2, cluster = ~a7)
t4r4  <- feols(revenue ~ local | stratum + period + house, data = lc2, cluster = ~a7)
etable(t4c1, t4c2, t4c4, t4c5, t4r2, t4r4)
cat("Central means: col1", mean(lc$paid[lc$local == 0]), " col2", mean(lc2$paid[lc2$local == 0]),
    " col5", mean(lc5$paid[lc5$local == 0]), " col5 N", nrow(lc5), "\n")

## ---------------- Table 5: paid bribe (endline) ----------------
e1 <- read_dta(paste0(S, "endline_round1_noPII.dta"))
en <- e1 %>% filter(tot_complete == 1, is.na(pilot)) %>%
  transmute(a7 = as.numeric(a7), code = as.numeric(code), most_recent = as.numeric(most_recent),
            visited = as.numeric(visited), bribe = as.numeric(bribe))
en <- en %>% arrange(code, desc(most_recent))
en <- en[!(duplicated(en$code) & !is.na(en$code)), ]
# bribe ("transport" paid to collectors) is asked only of households reporting a
# collector visit with someone present; households reporting no visit (or nobody home) paid none.
en$bribe[!(en$bribe %in% c(0, 1))] <- NA
en$pb <- ifelse(en$visited %in% c(0, 2), 0, ifelse(en$visited == 1, en$bribe, NA))
en <- left_join(en, nb[, c("a7", "stratum", "trt")], by = "a7") %>%
  filter(trt %in% c(1, 2), !is.na(pb)) %>% mutate(local = as.numeric(trt == 2))
t5 <- feols(pb ~ local | stratum, data = en, cluster = ~a7)
print(summary(t5)); cat("Central mean", mean(en$pb[en$local == 0]), "\n")

## ---------------- Table 6: visited by collector after registration (midline) ----------------
mid <- read_dta(paste0(S, "midline_noPII.dta"))
md <- mid %>% filter(tot_complete == 1, pilot == 0, !is.na(compound)) %>%
  transmute(compound1 = as.numeric(compound), visited = as.numeric(visited), visits = as.numeric(visits))
md <- md[!duplicated(md$compound1), ]
# visits counts all collector visits since June *including* the registration visit
md$post_visit <- ifelse(md$visited == 0, 0,
                   ifelse(md$visited %in% c(1, 2) & !is.na(md$visits), as.numeric(md$visits >= 2), NA))
md <- inner_join(md, pr[, c("compound1", "a7", "house", "stratum", "trt", "rdate")], by = "compound1") %>%
  filter(trt %in% c(1, 2), !is.na(post_visit)) %>% mutate(local = as.numeric(trt == 2))
md$period <- make_period(md, 1, 2)
md <- md %>% filter(!is.na(period))
t6 <- feols(post_visit ~ local | house + stratum + period, data = md, cluster = ~a7)
print(summary(t6)); cat("Central mean", mean(md$post_visit[md$local == 0]), "\n")

## ---------------- Table 7: CLI vs Central ----------------
cc <- pr %>% filter(trt %in% c(1, 3)) %>% mutate(cli = as.numeric(trt == 3))
cc$period <- make_period(cc, 1, 3)
cc <- cc %>% filter(!is.na(period))
t7c <- feols(paid ~ cli | house + stratum + period, data = cc, cluster = ~a7)
t7r <- feols(revenue ~ cli | house + stratum + period, data = cc, cluster = ~a7)
etable(t7c, t7r); cat("Central mean", mean(cc$paid[cc$cli == 0]), "\n")

## ---------------- Table 8: chief's ease-of-payment rating within CLI ----------------
cons <- read_dta(paste0(S, "chief_consultations.dta")) %>%
  transmute(compound1 = as.numeric(compound1), pay_ease = as.numeric(pay_ease))
cons$pay_ease[!(cons$pay_ease %in% c(0, 1, 2))] <- NA   # 8888 = don't know
cons <- cons[!duplicated(cons$compound1), ]
t8d <- pr %>% filter(trt == 3) %>% inner_join(cons, by = "compound1") %>% filter(!is.na(pay_ease))
t8 <- feols(paid ~ pay_ease | house + stratum, data = t8d, cluster = ~a7)
print(summary(t8))

## ---------------- results ----------------
co <- function(m, v) unname(coef(m)[v])
cat(sprintf("RESULT:compliance_local_table4_panelA_col1=%.6f\n", co(t4c1, "local")))
cat(sprintf("RESULT:compliance_local_table4_panelA_col2=%.6f\n", co(t4c2, "local")))
cat(sprintf("RESULT:compliance_local_house_fe_table4_panelA_col4=%.6f\n", co(t4c4, "local")))
cat(sprintf("RESULT:compliance_local_exempt_excluded_table4_panelA_col5=%.6f\n", co(t4c5, "local")))
cat(sprintf("RESULT:revenue_local_table4_panelB_col2=%.4f\n", co(t4r2, "local")))
cat(sprintf("RESULT:revenue_local_house_fe_table4_panelB_col4=%.4f\n", co(t4r4, "local")))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(t4c1)))
cat(sprintf("RESULT:n_obs_table4_col2=%d\n", nobs(t4c2)))
cat(sprintf("RESULT:paid_bribe_endline_local_table5_panelB=%.6f\n", co(t5, "local")))
cat(sprintf("RESULT:visited_by_collector_local_table6_col1=%.6f\n", co(t6, "local")))
cat(sprintf("RESULT:compliance_cli_table7_col1=%.6f\n", co(t7c, "cli")))
cat(sprintf("RESULT:revenue_cli_table7_col2=%.4f\n", co(t7r, "cli")))
cat(sprintf("RESULT:compliance_ease_of_payment_cli_table8_panelA_col2=%.6f\n", co(t8, "pay_ease")))
