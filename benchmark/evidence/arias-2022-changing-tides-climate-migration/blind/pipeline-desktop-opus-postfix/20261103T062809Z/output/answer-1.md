suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free"
files <- list(
  us = "Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv",
  germany = "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv"
)

# ---- level regexes (English + German) ----
rx_drought <- "drought|d(ü|u|ue)rre|trockenheit"
rx_flood <- "flood|(ü|u|ue)berschwemm|hochwasser|flut"
rx_fire <- "wildfire|fire|waldbr|feuer|br(ä|a|ae)nde|brand"
rx_persec <- "persecut|verfolg"
rx_econ <- "econom|wirtschaft|(ö|o|oe)konom|opportun|chance|perspektiv"

baseline_rx <- c(
  "^\\s*(none|keine?|kein)\\b",
  "female|weiblich|^frau",
  "unemploy|arbeitslos",
  "agnost|athe",
  "region|another|anderen|anderes|bundesland|your country|ihrem land",
  "^\\s*(none|keine?|kein)\\b"
)

kw_choice <- "(which|welche|welchen|choose|w(ä|a|ae)hlen|prefer|bevorzug|admit|aufnehm|aufnahme|settle|ansiedel|niederlass)"
kw_migrant <- "(migrant|immigrant|person|profil|einwander|zuwander)"

map_two <- function(u) {
  u <- sort(u)
  d <- str_extract(u, "[12]")
  if (all(!is.na(d)) && length(unique(d)) == 2) {
    return(setNames(as.integer(d), u))
  }
  ab <- str_match(u, "\\b([ABab])\\b")[, 2]
  if (all(!is.na(ab)) && length(unique(toupper(ab))) == 2) {
    return(setNames(ifelse(toupper(ab) == "A", 1L, 2L), u))
  }
  one <- grepl("first|erst|left|links|\\beins\\b|\\bone\\b", u, ignore.case = TRUE)
  two <- grepl("second|zweit|right|rechts|\\bzwei\\b|\\btwo\\b", u, ignore.case = TRUE)
  if (sum(one & !two) == 1 && sum(two & !one) == 1) {
    return(setNames(ifelse(one & !two, 1L, 2L), u))
  }
  NULL
}

process_country <- function(fname, label) {
  raw <- read_csv(file.path(base_dir, fname),
                  col_types = cols(.default = col_character()),
                  na = c("", "NA"), show_col_types = FALSE, progress = FALSE)
  cat(sprintf("SAMPLE:%s:loaded=%d\n", label, nrow(raw)))
  nm <- names(raw)

  idcol <- if ("ResponseId" %in% nm) "ResponseId" else nm[grep("Response ?I[dD]", nm)[1]]
  is_resp <- grepl("^R_", raw[[idcol]])
  if (!is_resp[1]) {
    qtext <- as.character(unlist(raw[1, ]))
  } else {
    qtext <- nm
  }
  qtext[is.na(qtext)] <- ""
  names(qtext) <- nm

  df <- raw[is_resp, , drop = FALSE]
  cat(sprintf("SAMPLE:%s:respondent_rows=%d\n", label, nrow(df)))

  if ("Status" %in% nm) {
    st <- str_trim(df$Status)
    drop <- grepl("preview|spam|test", st, ignore.case = TRUE) | st %in% c("1", "2", "8", "9", "12")
    df <- df[!drop, , drop = FALSE]
  }
  cat(sprintf("SAMPLE:%s:exclude_previews=%d\n", label, nrow(df)))

  # ---- conjoint attribute columns (Qualtrics conjoint SDK: F-task-attr, F-task-profile-attr) ----
  lev_cols <- nm[grepl("^F[-_]\\d+[-_]\\d+[-_]\\d+$", nm)]
  att_cols <- nm[grepl("^F[-_]\\d+[-_]\\d+$", nm)]
  if (length(lev_cols) == 0) stop("No conjoint level columns found")
  lm_ <- str_match(lev_cols, "^F[-_](\\d+)[-_](\\d+)[-_](\\d+)$")
  lev_t <- as.integer(lm_[, 2]); lev_p <- as.integer(lm_[, 3]); lev_a <- as.integer(lm_[, 4])
  am_ <- str_match(att_cols, "^F[-_](\\d+)[-_](\\d+)$")
  att_t <- as.integer(am_[, 2]); att_a <- as.integer(am_[, 3])
  tasks <- sort(unique(lev_t))

  # ---- detect forced-choice outcome columns ----
  meta_rx <- "^(StartDate|EndDate|Status|IPAddress|Progress|Duration|Finished|RecordedDate|ResponseId|Recipient|ExternalReference|Location|DistributionChannel|UserLanguage|force_choice|SURVEY_HISTORY)"
  cand <- setdiff(nm, c(lev_cols, att_cols))
  cand <- cand[!grepl(meta_rx, cand) &
               !grepl("First Click|Last Click|Page Submit|Click Count|FirstClick|LastClick|PageSubmit|ClickCount|_TIME", cand, ignore.case = TRUE)]
  info <- list()
  for (cn in cand) {
    v <- str_trim(df[[cn]])
    v <- v[!is.na(v) & v != ""]
    if (length(v) < 0.3 * nrow(df)) next
    u <- unique(v)
    if (length(u) != 2) next
    mp <- map_two(u)
    if (is.null(mp)) next
    share <- mean(mp[v] == 1L)
    if (share < 0.25 || share > 0.75) next
    sc <- 2 * grepl(kw_choice, qtext[cn], ignore.case = TRUE, perl = TRUE) +
      grepl(kw_migrant, qtext[cn], ignore.case = TRUE, perl = TRUE)
    info[[cn]] <- list(col = cn, map = mp, idx = match(cn, nm), score = sc)
  }
  if (length(info) == 0) stop("No choice columns detected")
  scores <- sapply(info, `[[`, "score")
  idxs <- sapply(info, `[[`, "idx")
  ntask <- length(tasks)
  sel <- NULL
  for (thr in c(3, 2, 1, 0)) {
    keep <- names(info)[scores >= thr]
    if (length(keep) >= ntask) { sel <- keep; break }
  }
  if (is.null(sel)) sel <- names(info)
  sel <- sel[order(idxs[sel])]
  if (length(sel) > ntask) {
    ii <- idxs[sel]
    spans <- sapply(1:(length(sel) - ntask + 1), function(s) ii[s + ntask - 1] - ii[s])
    s0 <- which.min(spans)
    sel <- sel[s0:(s0 + ntask - 1)]
  }

  ch_list <- list()
  for (k in seq_along(sel)) {
    cn <- sel[k]
    tk <- if (length(sel) == ntask) tasks[k] else k
    v <- str_trim(df[[cn]])
    code <- unname(info[[cn]]$map[v])
    ch_list[[k]] <- data.frame(resp = df[[idcol]], task = tk, choice = code, stringsAsFactors = FALSE)
  }
  choices <- bind_rows(ch_list) %>% filter(!is.na(choice))

  df <- df[df[[idcol]] %in% choices$resp, , drop = FALSE]
  cat(sprintf("SAMPLE:%s:completed_conjoint=%d\n", label, nrow(df)))

  # ---- long profile data ----
  lst <- vector("list", length(lev_cols))
  for (i in seq_along(lev_cols)) {
    j <- which(att_t == lev_t[i] & att_a == lev_a[i])
    attname <- if (length(j) >= 1) str_trim(df[[att_cols[j[1]]]]) else rep(paste0("attr", lev_a[i]), nrow(df))
    lst[[i]] <- data.frame(resp = df[[idcol]], task = lev_t[i], profile = lev_p[i],
                           attr = attname, level = str_trim(df[[lev_cols[i]]]),
                           stringsAsFactors = FALSE)
  }
  long <- bind_rows(lst) %>% filter(!is.na(attr), attr != "", !is.na(level), level != "")
  wide <- pivot_wider(long, id_cols = c(resp, task, profile), names_from = attr,
                      values_from = level, values_fn = function(x) x[1])
  attrs <- setdiff(names(wide), c("resp", "task", "profile"))

  reason_score <- sapply(attrs, function(a) {
    mean(grepl(paste(rx_drought, rx_flood, rx_persec, sep = "|"), wide[[a]],
               ignore.case = TRUE, perl = TRUE), na.rm = TRUE)
  })
  reason_attr <- attrs[which.max(reason_score)]
  other_attrs <- setdiff(attrs, reason_attr)

  dat <- inner_join(wide, choices, by = c("resp", "task"))
  dat$chosen <- as.integer(dat$profile == dat$choice)
  cat(sprintf("SAMPLE:%s:profiles=%d\n", label, nrow(dat)))

  rl <- dat[[reason_attr]]
  dat$reason_drought <- as.integer(grepl(rx_drought, rl, ignore.case = TRUE, perl = TRUE))
  dat$reason_flooding <- as.integer(grepl(rx_flood, rl, ignore.case = TRUE, perl = TRUE) & dat$reason_drought == 0)
  dat$reason_persecution <- as.integer(grepl(rx_persec, rl, ignore.case = TRUE, perl = TRUE))
  dat$reason_wildfires <- as.integer(grepl(rx_fire, rl, ignore.case = TRUE, perl = TRUE) &
                                       dat$reason_drought == 0 & dat$reason_flooding == 0 &
                                       dat$reason_persecution == 0)
  dat$reason_wildfires[is.na(rl)] <- NA
  dat$reason_drought[is.na(rl)] <- NA

  fac_names <- character(0)
  for (k in seq_along(other_attrs)) {
    a <- other_attrs[k]
    v <- dat[[a]]
    lv <- sort(unique(v[!is.na(v)]))
    base_lv <- NA_character_
    for (r in baseline_rx) {
      hit <- lv[grepl(r, lv, ignore.case = TRUE, perl = TRUE)]
      if (length(hit) == 1) { base_lv <- hit; break }
    }
    if (is.na(base_lv)) base_lv <- lv[1]
    fn <- paste0("a", k)
    dat[[fn]] <- factor(v, levels = c(base_lv, setdiff(lv, base_lv)))
    fac_names <- c(fac_names, fn)
  }

  rhs <- c("reason_drought", "reason_flooding", "reason_wildfires", "reason_persecution", fac_names)
  dat <- dat[complete.cases(dat[, c("chosen", rhs)]), , drop = FALSE]
  fml <- as.formula(paste("chosen ~", paste(rhs, collapse = " + ")))
  mod <- feols(fml, data = dat, cluster = ~resp)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", label, nobs(mod)))

  used <- dat[obs(mod), , drop = FALSE]
  list(model = mod, n_resp = n_distinct(used$resp), n_obs = nobs(mod))
}

res_us <- process_country(files$us, "us")
res_de <- process_country(files$germany, "germany")

getc <- function(m, v) {
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

cat(sprintf("RESULT:amce_drought_us=%.6f\n", getc(res_us$model, "reason_drought")))
cat(sprintf("RESULT:amce_flooding_us=%.6f\n", getc(res_us$model, "reason_flooding")))
cat(sprintf("RESULT:amce_wildfires_us=%.6f\n", getc(res_us$model, "reason_wildfires")))
cat(sprintf("RESULT:amce_persecution_us=%.6f\n", getc(res_us$model, "reason_persecution")))
cat(sprintf("RESULT:amce_drought_germany=%.6f\n", getc(res_de$model, "reason_drought")))
cat(sprintf("RESULT:amce_flooding_germany=%.6f\n", getc(res_de$model, "reason_flooding")))
cat(sprintf("RESULT:amce_wildfires_germany=%.6f\n", getc(res_de$model, "reason_wildfires")))
cat(sprintf("RESULT:amce_persecution_germany=%.6f\n", getc(res_de$model, "reason_persecution")))
cat(sprintf("RESULT:respondents_us=%d\n", as.integer(res_us$n_resp)))
cat(sprintf("RESULT:respondents_germany=%d\n", as.integer(res_de$n_resp)))
cat(sprintf("RESULT:choice_tasks_us=%d\n", as.integer(res_us$n_obs)))
cat(sprintf("RESULT:choice_tasks_germany=%d\n", as.integer(res_de$n_obs)))
