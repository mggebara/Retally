suppressMessages({library(haven); library(dplyr)})
R <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base/"
B <- paste0(R, "admin_data/"); S <- paste0(R, "survey_data/")
desc <- function(d, nm) {
  cat("\n=====", nm, nrow(d), "x", ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nu <- length(unique(x))
    ex <- if (is.numeric(x)) paste(signif(head(sort(unique(x)), 5),5), collapse=",") else paste(substr(head(unique(as.character(x)),3),1,18), collapse="|")
    cat(sprintf("%-26s %-6s u=%-5d NA=%-5d [%s] %s\n", v, substr(class(x)[1],1,6), nu, sum(is.na(x)), substr(lab,1,55), ex))
  }
}
ra <- read_dta(paste0(B, "randomization_assignment.dta"))
reg <- read_dta(paste0(B, "registration_noPII.dta"))
r3 <- reg %>% filter(a7 %in% ra$a7, pilot==0, tot_complete==1) %>% mutate(trt = as.numeric(ra$treatment[match(a7, ra$a7)]))
w <- r3 %>% filter(trt %in% c(2,4)) %>% group_by(a7, trt) %>% summarise(n=n(), agent=mean(who==0,na.rm=TRUE), chef=mean(who==1,na.rm=TRUE), both=mean(who==2,na.rm=TRUE), tmt2=mean(tmt==2,na.rm=TRUE), tmt4=mean(tmt==4,na.rm=TRUE), .groups="drop")
print(as.data.frame(w %>% filter(trt==4) %>% arrange(desc(chef))), digits=2)
tr <- read_dta(paste0(B, "taxroll_noPII.dta"))
cat("reg r3 in taxroll:", sum(r3$compound1 %in% tr$compound1), "of", nrow(r3), "\n")
tr2 <- tr %>% filter(a7 %in% ra$a7); cat("taxroll in rand a7:", nrow(tr2), " in r3:", sum(tr2$compound1 %in% r3$compound1), "\n")
print(table(trt=ra$treatment[match(tr2$a7, ra$a7)]))
print(table(tr2$MontantIF)); print(table(tr2$Exempte))
mid <- read_dta(paste0(S, "midline_noPII.dta"))
desc(mid, "midline")
