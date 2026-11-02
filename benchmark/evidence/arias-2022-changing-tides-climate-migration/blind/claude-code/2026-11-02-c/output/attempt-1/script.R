suppressMessages(library(tidyverse))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-11-02-c/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  d <- read_csv(file.path(D,f), col_types=cols(.default="c"))
  cat("====",f,nrow(d),"\n")
  print(as.data.frame(d[1:2, c("Status","Finished","Progress","RATE_MIG1","force_choice","Q184","F-1-1","F-1-1-1")]))
  d <- d[-(1:2),]
  cat("rows after header:",nrow(d),"\n")
  print(table(d$Status, useNA="a")); print(table(d$Finished,useNA="a"))
  print(head(table(d$Progress),10))
  print(table(d$force_choice,useNA="a")); print(table(d$Q184,useNA="a")); print(table(d$Q198,useNA="a"))
  print(table(d$`F-1-1`,useNA="a")); print(table(d$`F-1-1-1`,useNA="a"))
  print(table(is.na(d$`F-9-2-7`)))
  ch <- c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")
  nans <- rowSums(!is.na(d[,ch]))
  print(table(nans))
  print(table(nans>0 & !is.na(d$`F-1-1-1`)))
  cat("unique ResponseId", length(unique(d$ResponseId)), " psid uniq", length(unique(d$psid)), "\n")
  print(head(table(d$Q89,useNA="a"),5)); print(table(d$TREATMENT,useNA="a"))
  print(table(d$DistributionChannel))
  print(table(d$RATE_MIG1,useNA="a"))
}
d <- read_csv(file.path(D,"usclimate_exp1.csv"), col_types=cols(.default="c")); cat("usclimate_exp1", nrow(d), "\n"); print(names(d)[1:30]); print(tail(names(d),40))
