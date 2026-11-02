suppressMessages({library(haven); library(dplyr); library(data.table)})
M <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-10-22-b/mount/holman_2022_theresa_may_rally"
g <- as.data.table(read_dta(file.path(M,"global_approval.dta")))
setorder(g, country_code, qtr)
cat("== first/last row lag_approval NA by panel ==\n")
print(g[, .(n=.N, firstNA=is.na(lag_approval[1]), lastNA=is.na(lag_approval[.N]), nNA=sum(is.na(lag_approval)), minq=min(qtr), maxq=max(qtr), gaps=any(diff(qtr)!=1), country=country[1]), by=country_code])
cat("UK rows around 2017:\n"); print(g[country=="United Kingdom" & qtr>=224, .(qtr,lag_approval,kill_16,manchester,female_pres,execrlc,election_qtr,growth,log_inflation)])
print(g[kill_16==1, .(country,qtr,female_pres,lag_approval)])
print(table(g$country_code==g$ccode))
print(attr(read_dta(file.path(M,"global_approval.dta"))$execrlc, "labels"))
d <- as.data.table(read_dta(file.path(M,"did_data.dta")))
d[, likeMayW := as.numeric(zap_labels(likeMayW))]
cat("rows", nrow(d), "ids", uniqueN(d$id), "\n")
print(d[, .(n=.N, like=sum(!is.na(likeMayW)), like9999=sum(likeMayW==9999,na.rm=TRUE), bestPM=sum(!is.na(bestPMW)), mbpm=sum(!is.na(may_bestpm)), t1=sum(treatment1==1,na.rm=T), t1na=sum(is.na(treatment1)), time=mean(time,na.rm=T), t2=sum(treatment2==1,na.rm=T), pa=sum(!is.na(post_attack)), pa1=sum(post_attack==1,na.rm=T)), by=wave][order(wave)])
cat("treatment1 constant within id? "); print(d[, uniqueN(treatment1), by=id][, table(V1)])
cat("treatment2 constant within id? "); print(d[, uniqueN(treatment2), by=id][, table(V1)])
cat("post_attack constant within id? "); print(d[, uniqueN(post_attack), by=id][, table(V1)])
w12 <- d[wave==12]
print(w12[, table(treatment1, post_attack, useNA="a")])
print(w12[, table(treatment2, post_attack, useNA="a")])
print(d[, table(bestPMW, wave, useNA="a")])
print(d[wave==12, table(bestPMW, may_bestpm, useNA="a")])
for (v in c("white","gender","labour","party_other","income","ideology","ideology2","ideo3","conservative","may_bestpm")) { cat(v,"\n"); print(table(d[[v]], useNA="a")) }
cat("controls constant within id?\n"); for (v in c("white","gender","labour","party_other","income","ideology","ideology2")) { cat(v); print(d[, uniqueN(get(v)), by=id][, table(V1)]) }
print(d[wave==12, .(mean(likeMayW12a,na.rm=T), mean(likeMayW12b,na.rm=T), sum(!is.na(likeMayW12a)), sum(!is.na(likeMayW12b)))])
print(d[, table(time, wave)])
print(d[wave==12, table(treatment1, is.na(likeMayW))])
