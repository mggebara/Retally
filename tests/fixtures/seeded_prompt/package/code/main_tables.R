library(fixest)
feols(lum ~ warfare | state, data = d, cluster = ~district)
