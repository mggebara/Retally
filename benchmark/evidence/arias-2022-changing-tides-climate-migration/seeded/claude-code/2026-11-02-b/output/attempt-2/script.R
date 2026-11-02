D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/mount/arias_2022_changing_tides_climate_migration"
resp_cols <- c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")
build_long <- function(f) {
  x <- read.csv(file.path(D,f), stringsAsFactors=FALSE, check.names=FALSE, encoding="UTF-8")
  x <- x[-(1:2), ]
  out <- list()
  for (k in 1:9) for (j in 1:2) {
    d <- data.frame(Response.ID = x$ResponseId, row = seq_len(nrow(x)), task = k, profile = j,
                    resp = x[[resp_cols[k]]], stringsAsFactors = FALSE)
    for (a in 1:7) {
      an <- x[[sprintf("F-%d-%d", k, a)]]; lv <- x[[sprintf("F-%d-%d-%d", k, j, a)]]
      d[[paste0("attr", a)]] <- an; d[[paste0("lev", a)]] <- lv
    }
    out[[length(out)+1]] <- d
  }
  L <- do.call(rbind, out)
  # wide by attribute name
  anames <- sort(unique(unlist(L[, paste0("attr",1:7)])))
  anames <- anames[anames != ""]
  for (an in anames) {
    v <- rep(NA_character_, nrow(L))
    for (a in 1:7) { m <- L[[paste0("attr",a)]] == an; v[m] <- L[[paste0("lev",a)]][m] }
    L[[an]] <- v
  }
  L$selected <- ifelse(L$resp == "", NA, as.integer(L$resp == as.character(L$profile)))
  L
}
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  L <- build_long(f)
  cat("====", f, "\n")
  A <- L[!is.na(L$selected), ]
  cat("profiles answered:", nrow(A), " respondents:", length(unique(A$Response.ID)), "\n")
  an <- setdiff(names(A), c("Response.ID","row","task","profile","resp","selected", paste0("attr",1:7), paste0("lev",1:7)))
  for (v in an) { cat("--", v, "\n"); print(table(A[[v]], useNA="ifany")) }
  # order check: first 4 rows in respondent order
  A <- A[order(A$row, A$task, A$profile), ]
  print(head(A[, c("Response.ID","row","task","profile","selected")], 6))
  print(table(table(A$Response.ID)))
  cat("selected mean:", mean(A$selected), " per task sums:", paste(names(table(tapply(A$selected, paste(A$row,A$task), sum))), collapse=","), "\n")
}
