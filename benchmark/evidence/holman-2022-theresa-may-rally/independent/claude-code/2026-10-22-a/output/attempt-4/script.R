suppressMessages({library(haven)})
M <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-10-22-a/mount/holman_2022_theresa_may_rally"
# timing check of the approval series only (no estimation)
g <- as.data.frame(zap_labels(read_dta(file.path(M, "global_approval.dta"))))
v <- c("country", "country_code", "qtr", "lag_approval", "kill_16", "rally_kill", "female_pres", "execrlc", "election_qtr")
print(g[g$country == "United States" & g$qtr %in% 162:170, v])
print(g[g$country == "United Kingdom" & g$qtr %in% 224:231, v])
print(g[g$country == "Spain" & g$qtr %in% 174:180, v])
print(table(g$country, g$country_code)[rowSums(table(g$country, g$country_code) > 0) > 1, , drop = FALSE] |> (\(m) m[, colSums(m) > 0, drop = FALSE])())
