suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta"
df <- haven::read_dta(path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)

yr <- as.numeric(df$year)
inc <- as.numeric(df$hh_income_pc)
defl <- rep(0, length(yr))
defl[yr %in% 2000] <- 71.57
defl[yr %in% 2001] <- 74.25
defl[yr %in% 2004] <- 80.68
defl[yr %in% 2005] <- 84.47
defl[yr %in% 2006] <- 87.88
defl[yr %in% 2007] <- 91.90
defl[yr %in% 2008] <- 98.06
defl[yr %in% 2009] <- 99.10
defl[yr %in% 2011] <- 105.13
defl[yr %in% 2012] <- 106.95
defl[yr %in% 2013] <- 107.79
df$hh_inc_pc_real <- inc * defl / 100
df$hh_inc_pc_real[is.na(yr)] <- NA

iyear <- grep("^i_year", names(df), value = TRUE)
for (v in iyear) df[[v]] <- as.numeric(df[[v]])
df$norm_dist <- as.numeric(df$norm_dist)
df$Above500 <- as.numeric(df$Above500)
df$hh_income_pc <- inc
if ("age" %in% names(df)) df$age <- as.numeric(df$age)
if (!("age2" %in% names(df))) df$age2 <- df$age^2
df$age2 <- as.numeric(df$age2)
df$sex <- as.numeric(df$sex)

run_reg <- function(d, y, extra, bw) {
  vars <- c(y, "Above500", "norm_dist", iyear, extra, "Expropretario_ISTA")
  s <- d[complete.cases(d[, vars]), , drop = FALSE]
  s <- s[abs(s$norm_dist) < bw, , drop = FALSE]
  s <- s[!(is.character(s$Expropretario_ISTA) & s$Expropretario_ISTA == ""), , drop = FALSE]
  rhs <- paste(c("Above500", "norm_dist", "norm_dist:Above500",
                 paste0("`", iyear, "`"), extra), collapse = " + ")
  fml <- as.formula(paste(y, "~", rhs))
  m <- feols(fml, data = s, cluster = ~Expropretario_ISTA)
  list(coef = unname(coef(m)["Above500"]),
       se = unname(sqrt(diag(vcov(m)))["Above500"]),
       n = nobs(m),
       g = length(unique(s$Expropretario_ISTA)))
}

# Table 5 cols 1-2: worker-level income levels
r1 <- run_reg(df, "hh_inc_pc_real", c("sex", "age", "age2"), 300)
r2 <- run_reg(df, "hh_inc_pc_real", c("sex", "age", "age2"), 150)

# Table 5 cols 3-4: IQR collapsed by property x owner x survey year
q75q25 <- function(x) {
  as.numeric(quantile(x, 0.75, type = 2)) - as.numeric(quantile(x, 0.25, type = 2))
}
cvars <- c("hh_income_pc", "hh_inc_pc_real", "num_members", "norm_dist", "Above500")
df$num_members <- as.numeric(df$num_members)
dc <- df[complete.cases(df[, cvars]), , drop = FALSE]
byv <- c("match_id", "Expropretario_ISTA", iyear)
coll <- dc %>%
  group_by(across(all_of(byv))) %>%
  summarise(hh_income_pc = q75q25(hh_income_pc),
            hh_inc_pc_real = q75q25(hh_inc_pc_real),
            num_members = mean(num_members),
            norm_dist = mean(norm_dist),
            Above500 = mean(Above500),
            .groups = "drop") %>%
  as.data.frame()

r3 <- run_reg(coll, "hh_inc_pc_real", character(0), 300)
r4 <- run_reg(coll, "hh_inc_pc_real", character(0), 150)

cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", r1$coef))
cat(sprintf("RESULT:earnings_level_above500_bw300_se=%.6f\n", r1$se))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", r2$coef))
cat(sprintf("RESULT:earnings_level_above500_bw150_se=%.6f\n", r2$se))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", r3$coef))
cat(sprintf("RESULT:earnings_iqr_above500_bw300_se=%.6f\n", r3$se))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", r4$coef))
cat(sprintf("RESULT:earnings_iqr_above500_bw150_se=%.6f\n", r4$se))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", as.integer(r1$n)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", as.integer(r2$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", as.integer(r3$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", as.integer(r4$n)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", as.integer(r1$g)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", as.integer(r2$g)))
cat(sprintf("RESULT:n_clusters_iqr_bw300=%d\n", as.integer(r3$g)))
cat(sprintf("RESULT:n_clusters_iqr_bw150=%d\n", as.integer(r4$g)))