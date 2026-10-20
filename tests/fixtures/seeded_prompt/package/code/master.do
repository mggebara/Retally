use "data/analysis.dta", clear
reghdfe lum warfare, absorb(state) cluster(district)
