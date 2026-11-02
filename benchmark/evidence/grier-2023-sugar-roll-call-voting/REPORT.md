# Evidence report: grier-2023-sugar-roll-call-voting

**Campaign Contributions and Roll-Call Voting in the U.S. House of Representatives: The Case of the Sugar Industry** — Kevin Grier, Robin Grier, Gor Mkrtchian

- Paper: https://www.cambridge.org/core/services/aop-cambridge-core/content/view/DBB341572A3FC0A1D06705B5DDE5C497/S0003055422000466a.pdf/div-class-title-campaign-contributions-and-roll-call-voting-in-the-u-s-house-of-representatives-the-case-of-the-sugar-industry-div.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/275682/1/I4R-DP057.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/grier-2023-sugar-roll-call-voting.yaml`

> Headline finding: rising sugar-industry contributions between the 2013 and 2018 House votes on near-identical sugar-program reform amendments significantly lowered the probability that a district's representative voted for reform, in district fixed-effects logits (93 vote-switching districts) and incumbent fixed-effects logits (53 vote-switching members), and across alternative contribution windows.
> Curation pass (2026-10-21).  Pinned 11 claims: the sugar-contributions coefficient in all six reported models (Table 1 cols 1-2, Table 3's four cells), the Table 1 col 1 ACU and tenure coefficients and the col 2 tenure coefficient, and the two observation counts.  The paper prints coefficient (p-value) with robust-SE p-values, never SEs, so standard_error is empty throughout; the p-values are mostly printed as 0.001 (a floor, not an exact value) and are not pinned.  The contributions coefficients are printed to ONE significant digit (-0.0006, -0.0004, ...), so a relative-tolerance comparison against them is coarse: e.g. -0.00063 and -0.00055 both "round" near -0.0006. Left out: the poverty, education, income, age and agriculture-committee rows (the agriculture-committee coefficients, -36.3 / -39.3, and the constants, -20.9 / -63.1, are artefacts of near-separation and of the dummy base category, not estimable targets), the pseudo R2s (0.745 / 0.721), Table 2 (vote-changer contribution changes), the Figure 1-3 marginal effects, and the appendix tables.
> What was read.  The published APSR PDF (Table 1, Table 2, Table 3, text); the Dataverse API metadata; the whole package (downloaded to a scratch directory, never committed): the do-file, the .docx readme and the three .dta originals; I4R DP 57 (EconStor PDF); the meta-database's 8 rows.
> Independent cross-check (not the package code: a statsmodels logit with id dummies on the .dta originals, dropping ids whose outcome does not vary, as Stata's logit does).  Reproduces Table 1 exactly at the printed precision: contributions -0.000631 (robust SE 0.000087) / -0.000392 (0.000110); ACU 0.2023 / 0.0599 (p 0.52, paper 0.53); tenure -0.2969 / -1.4327; N 186 / 106.  Table 3: calendar-year window -0.000575 (SE 0.000116) / -0.000565 (0.000159); 12-month window -0.000597 (0.000105) / -0.000318 (0.000106, p 0.0026, paper 0.003).  One printed value does not round from the estimate: the calendar-year incumbent cell (claim 6) is printed -0.0005 while the estimate is -0.000565 (rounds to -0.0006); either the paper truncated or Stata's fit differs in the fourth decimal. A reproducer that gets -0.0006 there is right.  SEs above are HC0; Stata's logit robust SEs differ only by the n/(n-1) factor.
> Package structure (package-only facts; never in contexts).  Files: "APSR Replication Codes.do" (one script, Stata 15, ~70 lines), "Replication Read Me.docx", SugarReplicate.dta (main, Table 1 / Figures 1-3), SugarReplicate_iter1.dta (calendar-year window, Table 3 row 1), SugarReplicate_iter2.dta (12-month window, Table 3 row 2); each 862 rows (434 rows for the 113th Congress, 428 for the 115th) and 27 columns (cong, id, vote, totalcont, ncu, tenure, poverty, bach, medincome, over65, agcom, both, party, dwn, ...).  The script builds yesvote = (vote == "Aye") — so "Not Voting" / "No Vote" rows count as 0 — deflates totalcont by 1.103 for the 115th Congress (the paper says only "inflation-adjusted"), and runs `logit yesvote rsugcont ncu tenure poverty bach medincome over65 agcom i.id, robust`, then `keep if both == 1` and the same logit for the incumbent column; Stata drops the ids whose outcome does not vary, giving 186 / 106.  The deflator, the coding of non-votes, and the "both" filter are not in the paper's text. It calls `ssc install marhis` (network access) for the figures and has no cd/setwd (expects the .dta files in the working directory).
> What could not be verified.  The package ships no logs or table output, and the do-file was not run; the cross-check above is an independent re-estimate in Python.  No working paper was found, so publication_date is the APSR online-first date.
> Original analysis in Stata (one do-file, Stata 15); language is r, the reproduction target (the pipeline translates Stata originals to R, as for alesina-2022).
> First run 2026-10-21 (Phase 3.2 evaluation pass; main 0492c17, after the content-aware strip rule and the printed-precision floor; Opus 4.7, 47-package image, LLM cache on, --mode all, one run per mode; eval-7papers-all-modes-2026-10-21.json).  0 / 11 in every mode, even seeded (first scored 0 in all three; seeded 1 claim refinement, independent 3 error repairs and no printed value, blind 2 error repairs).  The model estimated a conditional logit (survival::clogit with strata(id)) instead of the paper's logit with district / incumbent fixed-effect dummies, so every coefficient is ~1/7 of the printed value (-0.00009 vs -0.0006) and N is 860 / 612 instead of 186 / 106 (it reported all rows rather than the estimation sample).  The do-file was in the seeded prompt and still got mistranslated, so the seeded vs independent gap is undefined.  Grier prints coefficients to one significant digit and no SEs, so the printed-precision floor (PR #62) was the binding tolerance on most claims (tolerance_source: printed_precision); it rescued nothing because the estimates are an order of magnitude off.
> Window-file ambiguity (2026-10-22, from the Claude Code blind runs). The package never says which of SugarReplicate_iter1.dta and SugarReplicate_iter2.dta holds the calendar-year window and which the 12-months-before-the-vote window; the three files differ only in totalcont and the Read Me says just "three different time windows". The do-file (seeded mode only) runs them in the order SugarReplicate, _iter1, _iter2, which matches the paper's Table 3 row order (calendar year, then 12 months).  Of three blind agent runs, two took _iter1 = calendar year and scored 10 / 11; one took the reverse, by reasoning about when election-season giving falls, and scored 9 / 11 (the two incumbent-window coefficients swap).  The deflator base year is also unstated (the do-file divides 115th-Congress amounts by 1.103); agents chose 2013 or 2018 dollars, which rescales every contribution coefficient by about 8%.  Both are paper-versus-package gaps an independent reader cannot resolve from the text.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `sugar_contributions_district_fe` | -0.0006 | — | Table 1, District fixed effects, Inflation-adjusted sugar contributions | -0.0006 | matches |
| 1 | `sugar_contributions_incumbent_fe` | -0.0004 | — | Table 1, Incumbent fixed effects, Inflation-adjusted sugar contributions | -0.0004 | matches |
| 2 | `acu_ideology_district_fe` | 0.2 | — | Table 1, District fixed effects, ACU | 0.202 | matches |
| 3 | `tenure_district_fe` | -0.3 | — | Table 1, District fixed effects, Tenure | -0.297 | matches |
| 4 | `tenure_incumbent_fe` | -1.43 | — | Table 1, Incumbent fixed effects, Tenure | -1.433 | matches |
| 5 | `sugar_contributions_calendar_year_district_fe` | -0.0006 | — | Table 3, 1/1/13-12/31/13 and 1/1/18-12/31/18, District fixed effects | — | not_attempted |
| 6 | `sugar_contributions_calendar_year_incumbent_fe` | -0.0005 | — | Table 3, 1/1/13-12/31/13 and 1/1/18-12/31/18, Incumbent fixed effects | — | not_attempted |
| 7 | `sugar_contributions_12_months_district_fe` | -0.0006 | — | Table 3, 6/20/12-6/20/13 and 5/17/17-5/17/18, District fixed effects | — | not_attempted |
| 8 | `sugar_contributions_12_months_incumbent_fe` | -0.0003 | — | Table 3, 6/20/12-6/20/13 and 5/17/17-5/17/18, Incumbent fixed effects | — | not_attempted |
| 9 | `observations_district_fe` | 186 | — | Table 1, District fixed effects, Observations | 186 | matches |
| 10 | `observations_incumbent_fe` | 106 | — | Table 1, Incumbent fixed effects, Observations | 106 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [10/11](seeded/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b) | [10/11](independent/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[9/11](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [10/11](blind/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[9/11](blind/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[10/11](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-claude-opus-4-7` | [0/11](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [0/11](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [0/11](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) |
| `pipeline-claude-opus-5-5` | [11/11](seeded/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md) (20261022T043524Z) | [0/11](independent/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md) (20261022T043524Z) | [0/11](blind/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md) (20261022T043524Z) |
| `pipeline-desktop-opus-run2` | [10/11](seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) (20261023T152513Z) | [2/11](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) (20261023T153002Z) | [0/11](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [seeded/pipeline-claude-opus-5-5/20261022T043524Z](seeded/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md) | `sugar_contributions_calendar_year_district_fe` | -0.00055017 | -0.0006 | ±5e-05 (printed_precision) | 0.997 | PASS |
| [blind/claude-code/2026-10-21-b](blind/claude-code/2026-10-21-b/CELL.md) | `sugar_contributions_12_months_district_fe` | -0.000552102 | -0.0006 | ±5e-05 (printed_precision) | 0.958 | PASS |
| [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) | `sugar_contributions_12_months_district_fe` | -0.000552102 | -0.0006 | ±5e-05 (printed_precision) | 0.958 | PASS |
| [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) | `sugar_contributions_calendar_year_incumbent_fe` | -0.000554504 | -0.0005 | ±5e-05 (printed_precision) | 1.090 | FAIL |
| [seeded/pipeline-claude-opus-5-5/20261022T043524Z](seeded/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md) | `sugar_contributions_calendar_year_incumbent_fe` | -0.000540619 | -0.0005 | ±5e-05 (printed_precision) | 0.812 | PASS |
| [independent/claude-code/2026-10-21-b](independent/claude-code/2026-10-21-b/CELL.md) | `sugar_contributions_calendar_year_incumbent_fe` | -0.00056128 | -0.0005 | ±5e-05 (printed_precision) | 1.226 | FAIL |
| [blind/claude-code/2026-10-21-b](blind/claude-code/2026-10-21-b/CELL.md) | `sugar_contributions_incumbent_fe` | -0.000362363 | -0.0004 | ±5e-05 (printed_precision) | 0.753 | PASS |
| [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) | `sugar_contributions_incumbent_fe` | -0.000362363 | -0.0004 | ±5e-05 (printed_precision) | 0.753 | PASS |
| [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) | `sugar_contributions_calendar_year_incumbent_fe` | -0.000564732 | -0.0005 | ±5e-05 (printed_precision) | 1.295 | FAIL |
| [seeded/pipeline-desktop-opus-run2/20261023T152513Z](seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) | `sugar_contributions_calendar_year_incumbent_fe` | -0.000564732 | -0.0005 | ±5e-05 (printed_precision) | 1.295 | FAIL |

### Declared deviations

- [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) (10/11; failed: `sugar_contributions_calendar_year_incumbent_fe`)
  - Stata `logit ... i.id, robust` translated to fixest::feglm(binomial logit) with id fixed effects and vcov='hetero'. feglm drops FE groups with no outcome variation, matching Stata's perfect-prediction drops (186 and 106 obs). The agcom coefficient is quasi-separated (about -38.7 vs the paper's -36.3); its value depends on where the optimizer stops and it is not a scored claim.
- [seeded/pipeline-claude-opus-5-5/20261022T043524Z](seeded/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md) (11/11)
  - Calendar-year window (2013 vs 2018) contributions deflated with CPI-U annual ratio 2018/2013 = 1.0779 and expressed in dollars at the geometric midpoint of the 2013 and 2018 price levels (2013 values x 1.0382, 2018 values / 1.0382); paper does not state the base year for this window
- [independent/claude-code/2026-10-21-b](independent/claude-code/2026-10-21-b/CELL.md) (10/11; failed: `sugar_contributions_calendar_year_incumbent_fe`)
  - Inflation adjustment done in-script: 115th-Congress (2018) contributions multiplied by CPI-U 2013/2018 annual-average ratio (232.957/251.107), i.e. expressed in 2013 dollars. The paper does not state the deflator or base year; the base year only rescales the contribution coefficient.
  - Robust (HC0) standard errors are printed as diagnostics only; HC0 is near-singular for two observations because the agriculture-committee coefficient diverges (quasi-separation), as in the paper's -36.3/-39.3.
- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (9/11; failed: `tenure_incumbent_fe`, `sugar_contributions_calendar_year_incumbent_fe`)
  - Inflation adjustment: data contributions are nominal integers; 2018 contributions deflated to 2013 dollars with CPI-U annual averages (232.957/251.107). The paper does not state the deflator or base year.
  - Window mapping assumed from the paper's order of description: SugarReplicate.dta = baseline window (1 year before vote to end of vote's calendar year), SugarReplicate_iter1.dta = calendar year of vote, SugarReplicate_iter2.dta = 12 months before vote. The contribution variable used is totalcont (the only column that differs across files); sugcont (identical across files) is not used.
  - Outcome coded 1 for Aye, 0 otherwise (No, No Vote, Not Voting), following the table note; this yields 94 switching districts, 93 after listwise deletion on missing covariates (186 obs), and 53 switching incumbents (same cid in both Congresses; 106 obs).
  - FE logit estimated as unconditional logit with FE dummies (glm, binomial) on units whose outcome varies, mirroring Stata logit with i.FE; robust HC0 p-values printed for information. The agriculture-committee coefficient is not identified (quasi-separation), as in the paper's -36/-39.
  - inflation adjustment uses CPI-U annual averages, 2018 contributions in 2013 dollars (paper does not state deflator/base year)
  - mapping of data files to windows assumed: SugarReplicate.dta = baseline, _iter1 = calendar year, _iter2 = 12 months before vote
- [independent/pipeline-desktop-opus-run2/20261023T153002Z](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) (2/11; failed: `sugar_contributions_district_fe`, `sugar_contributions_incumbent_fe`, `acu_ideology_district_fe`, `tenure_district_fe`, `tenure_incumbent_fe`, `sugar_contributions_calendar_year_district_fe`, `sugar_contributions_calendar_year_incumbent_fe`, `sugar_contributions_12_months_district_fe`, `sugar_contributions_12_months_incumbent_fe`)
  - dataset holds nominal contributions; converted to real 2013 dollars with BLS CPI-U annual averages (2018 values x 232.957/251.107) since the paper's deflator/base year is not stated
  - alternative-window contributions taken from window-named variables if present, else from SugarReplicate_iter1.dta (calendar year) and SugarReplicate_iter2.dta (12 months)
- [blind/claude-code/2026-10-21-b](blind/claude-code/2026-10-21-b/CELL.md) (10/11; failed: `sugar_contributions_calendar_year_district_fe`)
  - Inflation adjustment: totalcont is nominal; 2013 contributions converted to 2018 dollars with CPI-U annual averages (232.957 for 2013, 251.107 for 2018). The paper does not state the deflator or base year; a 2013-dollar base would scale the contribution coefficients by about 1.078.
  - Fixed-effects logit estimated as an unconditional logit with district (or incumbent) dummies plus a constant, as the paper's table reports a constant, restricted to vote-switching groups (the only groups that identify the FE logit). Robust (HC1) SEs printed but not scored.
  - Window files identified from the data, not from documentation: SugarReplicate.dta = baseline (largest totals), _iter1 = calendar year, _iter2 = 12 months before the vote up to the vote date.
  - Agriculture committee dummy is perfectly separated among switchers (agcom=1 always with a No vote), so its coefficient diverges; other coefficients are at the converged limit.
  - inflation adjustment uses CPI-U annual averages to express 2013 contributions in 2018 dollars; the paper does not state the deflator or base year.
  - district/incumbent fixed effects estimated as an unconditional logit with group dummies (the paper's table reports a constant), restricted to vote-switching groups.
- [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) (9/11; failed: `sugar_contributions_calendar_year_incumbent_fe`, `sugar_contributions_12_months_incumbent_fe`)
  - Inflation adjustment: the paper does not state the deflator or base year; contributions are deflated with CPI-U annual averages (2013 = 232.957, 2018 = 251.107) to constant 2013 dollars. A different base year rescales the sugar coefficients (e.g. 2018 dollars would divide them by about 1.078).
  - Window-to-file mapping: the readme says the three .dta files hold contributions over the three windows but does not say which is which. SugarReplicate.dta is treated as the baseline (its totalcont is >= the other two for >99% of rows, consistent with the superset window). SugarReplicate_iter2.dta is treated as the calendar-year window and SugarReplicate_iter1.dta as the 12-months-before-vote window, inferred from seasonality: iter1 is larger for 2013 (its window would contain fall 2012 election-season giving) and iter2 is larger for 2018 (calendar 2018 contains the fall 2018 election season). If the mapping is reversed, the calendar_year and 12_months results swap.
  - The regressor is totalcont (varies across the three files); sugcont is identical in all three files and is taken to be the original cycle-aggregated CRP measure, not used.
  - inflation adjustment uses CPI-U annual averages to express contributions in constant 2013 dollars (base year not stated in the paper)
  - iter1/iter2 file-to-window mapping inferred (iter2 = calendar year, iter1 = 12 months before vote); not stated in the readme
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (10/11; failed: `sugar_contributions_calendar_year_district_fe`)
  - Contributions in the data are nominal; inflation-adjusted to 2018 dollars with CPI-U annual averages (2013: 232.957, 2018: 251.107). The paper does not state the base year or deflator.
  - Window-to-file mapping: SugarReplicate.dta = baseline window (verified as the superset window); SugarReplicate_iter1.dta assumed = calendar-year window and SugarReplicate_iter2.dta = 12-months-before window, following the order the windows are described in the text/Table 3. The data alone gave mixed evidence on this assignment.
  - Fixed-effects logit estimated as an unconditional logit with district (or incumbent) dummies on the vote-switching sample (the paper's table reports a constant and pseudo R2, as Stata logit with i.dummies does); robust (sandwich, n/(n-1)) SEs. A conditional logit gives roughly half-size coefficients (printed as a side check only).
  - The contribution regressor is the window-specific author-aggregated variable totalcont (differs across the three files); sugcont is identical across files and is taken to be the election-cycle aggregate, not used.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- independent: `acu_ideology_district_fe` — pipeline 0/3, agent 2/2
- independent: `sugar_contributions_12_months_district_fe` — pipeline 0/3, agent 2/2
- independent: `sugar_contributions_12_months_incumbent_fe` — pipeline 0/3, agent 2/2
- independent: `sugar_contributions_calendar_year_district_fe` — pipeline 0/3, agent 2/2
- independent: `sugar_contributions_district_fe` — pipeline 0/3, agent 2/2
- independent: `sugar_contributions_incumbent_fe` — pipeline 0/3, agent 2/2
- independent: `tenure_district_fe` — pipeline 0/3, agent 2/2
- blind: `acu_ideology_district_fe` — pipeline 0/3, agent 3/3
- blind: `observations_district_fe` — pipeline 0/3, agent 3/3
- blind: `observations_incumbent_fe` — pipeline 0/3, agent 3/3
- blind: `sugar_contributions_12_months_district_fe` — pipeline 0/3, agent 3/3
- blind: `sugar_contributions_district_fe` — pipeline 0/3, agent 3/3
- blind: `sugar_contributions_incumbent_fe` — pipeline 0/3, agent 3/3
- blind: `tenure_district_fe` — pipeline 0/3, agent 3/3
- blind: `tenure_incumbent_fe` — pipeline 0/3, agent 3/3

Pass rates at least 50 points apart (not unanimous):

- independent: `observations_district_fe` — pipeline 1/3, agent 2/2
- independent: `observations_incumbent_fe` — pipeline 1/3, agent 2/2
- independent: `tenure_incumbent_fe` — pipeline 0/3, agent 1/2
- blind: `sugar_contributions_12_months_incumbent_fe` — pipeline 0/3, agent 2/3
- blind: `sugar_contributions_calendar_year_incumbent_fe` — pipeline 0/3, agent 2/3

## Cells

### seeded · claude-code · 2026-10-21-b

[`seeded/claude-code/2026-10-21-b/CELL.md`](seeded/claude-code/2026-10-21-b/CELL.md) — final 10/11, re-scored 10/11; first scored 10/11; executions 1; 2026-10-22T02:02:53Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-claude-opus-4-7 · 20261021T142909Z

[`seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 2; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-claude-opus-5-5 · 20261022T043524Z

[`seeded/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md`](seeded/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md) — final 11/11, re-scored 11/11; first scored 10/11; executions 4; 2026-10-22T04:35:24Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T152513Z

[`seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) — final 10/11, re-scored 10/11; first scored 10/11; executions 1; 2026-10-23T15:25:13Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-21-b

[`independent/claude-code/2026-10-21-b/CELL.md`](independent/claude-code/2026-10-21-b/CELL.md) — final 10/11, re-scored 10/11; first scored 10/11; executions 3; 2026-10-22T02:09:30Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 9/11, re-scored 9/11; first scored 9/11; executions 4; 2026-11-02T04:26:29Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-claude-opus-4-7 · 20261021T142909Z

[`independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 4; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### independent · pipeline-claude-opus-5-5 · 20261022T043524Z

[`independent/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md`](independent/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 3; 2026-10-22T04:35:24Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T153002Z

[`independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) — final 2/11, re-scored 2/11; first scored 1/11; executions 4; 2026-10-23T15:30:02Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-21-b

[`blind/claude-code/2026-10-21-b/CELL.md`](blind/claude-code/2026-10-21-b/CELL.md) — final 10/11, re-scored 10/11; first scored 10/11; executions 3; 2026-10-22T02:13:13Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### blind · claude-code · 2026-10-22-a

[`blind/claude-code/2026-10-22-a/CELL.md`](blind/claude-code/2026-10-22-a/CELL.md) — final 9/11, re-scored 9/11; first scored 9/11; executions 4; 2026-10-22T02:45:54Z; from `claude-code-blind-rerun-2026-10-22.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 10/11, re-scored 10/11; first scored 10/11; executions 4; 2026-11-02T04:23:30Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-claude-opus-4-7 · 20261021T142909Z

[`blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 3; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### blind · pipeline-claude-opus-5-5 · 20261022T043524Z

[`blind/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md`](blind/pipeline-claude-opus-5-5/20261022T043524Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 1; 2026-10-22T04:35:24Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

