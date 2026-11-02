library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/blind/2026-11-02-a/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
d <- as.data.frame(d)
cat(dim(d), "\n"); print(names(d))
v <- c("wrights","mills","pcmean","pc0","pop_86","wheat_tmean","suitmean","dist_grass_mean","riv_rug26count","dist_rug_mean","dist_elevation_mean","latitude","longitude","temp_mean_dist","precip_mean_dist","area","DIST_London","min_harbor","min_dist_to_roman_rds","min_dist_2nav_rivers","GAZ_CNTY")
for (x in v) { y <- d[[x]]; if (is.numeric(y)) cat(sprintf("%-22s NA=%3d mean=%.4g sd=%.4g min=%.4g max=%.4g\n", x, sum(is.na(y)), mean(y,na.rm=T), sd(y,na.rm=T), min(y,na.rm=T), max(y,na.rm=T))) else cat(x, class(y), length(unique(y)), "\n") }
cat("labels:\n"); for (x in names(d)) { l <- attr(d[[x]],"label"); if(!is.null(l)) cat(x, ":", l, "\n") }
cat("mills NA & mills==0:", sum(is.na(d$mills)), sum(d$mills==0,na.rm=T), "\n")
print(table(d$GAZ_CNTY[!is.na(d$mills)]))
print(head(d[,c("local_government_area","wrights","mills","pcmean","pc0")],10))
print(table(d$wheat_tmean<=5, useNA="a"))
