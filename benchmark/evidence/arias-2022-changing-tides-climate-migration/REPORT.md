# Evidence report: arias-2022-changing-tides-climate-migration

**Changing Tides: Public Attitudes on Climate Migration** — Sabrina B. Arias, Christopher W. Blair

- Paper: https://sabrinabarias.com/wp-content/uploads/2020/09/Climate_Migration_Main_Text__JOP_.pdf
- I4R report: https://www.socialsciencereproduction.org/reproductions/791/published/index
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/arias-2022-changing-tides-climate-migration.yaml`

> Headline finding: climate migrants occupy an intermediate position in public preferences — more supported than economic migrants, less than refugees.  In the US conjoint, migrants displaced by droughts, floods, and wildfires are respectively ~3.5, 3.7, and 4.0 percentage points more likely to be preferred than economic migrants (AMCE; nationally representative US and German samples, N~2,160).
> Promoted from the I4R First Meta Database (replication report team 12) via scripts/import_i4r_candidates.py.  On holdout: touched only to confirm that a dev-set prompt improvement generalises.
> Curation pass (2026-10-21).  Pinned 12 claims: the eight Table 2 AMCEs of the focal attribute (drought, flooding, wildfires, persecution vs economic opportunity, U.S. and German samples), each with its SE in standard_error (SEs are not separate claims, as in bisbee-2022 and alesina-2022; separate SE claims would push the entry past 12), and the four design-section counts (1,086 / 1,074 respondents; 18,966 / 18,862 choice tasks).  Every AMCE and SE is printed to three decimal places. The abstract's 2,160 respondents is the sum of the two respondent claims and is not pinned separately.
> What was read.  The author PDF (conditionally accepted, 2020-09-29; Table 1 design, Table 2 AMCEs, text); the Kleinman Center digest of December 2019 (for the first-public date); the Dataverse API metadata; the whole package, downloaded to a scratch directory (never committed); the R script's Study 1 sections; the meta-database's 8 rows.
> What could not be verified.  (1) The published JOP Table 2: the journal PDF is paywalled and the SSRN copy is blocked, so the pinned values are the conditionally-accepted author text's; the package was deposited two days later (2020-10-01), so the numbers are very likely final, but this is unconfirmed.  (2) The AMCEs against package output: the package ships no tables or logs, and the code was not run.  (3) The SSRP #791 report itself (host unreachable); the verdict comes from the meta-database's survey fields.
> Counts cross-check.  A raw count over the package's .tab exports (respondents with at least one answered forced-choice item; two profiles per answered task) gives 1,074 respondents / 18,862 profiles for Germany, exactly the paper's, and 1,086 respondents / 18,970 profiles for the U.S.  The script reshapes to one row per profile with cjoint::read.qualtrics and then keeps rows 5 onward for the U.S. (cjt_us_data[5:nrow(cjt_us_data), ], line ~172), dropping four profile rows (18,970 - 4 = 18,966, the paper's figure) without dropping a respondent; Germany drops rows with a missing choice (line ~784).  So the paper's "unique choice tasks" counts profile rows (two per pairing), and the U.S. 18,966 depends on an undocumented four-row drop a reproducer following the paper cannot know about: choice_tasks_us (and, marginally, the U.S. AMCEs) may come out on 18,970.
> Package structure (package-only facts; never in contexts).  One script, Migration_Analysis_Final.R, with a hard-coded Windows setwd() and a memory.limit() call, set.seed(8675309), and libraries tidyverse, xtable, ggplot2, ggpubr, corrplot, car, splines, readxl, stargazer, psych, lemon, boot, cjoint, cregg, margins, FindIt.  Table 2 comes from cjoint::amce(selected ~ Gender + Language.Fluency + Occupation + Origin + Reason.for.migration + Religion + Vulnerability, cluster = TRUE, respondent.id = 'Response.ID', design = <design file>, baselines = ...) printed through xtable(digits = 3): U.S. at lines ~243-261 (cjt_us_results, design conjoint_design.dat, baseline 'Economic opportunity'), Germany at lines ~897-920 (cjt_ger_results, design conjoint_design_german2.dat, German level labels, baseline 'Wirtschaftliche Perspektive', columns renamed by position).  The data are read with cjoint::read.qualtrics(new.format = TRUE, respondentID = "ResponseId", responses = force_choice, Q184 ... Q198) from the original Qualtrics .csv names ("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv", "... Germany_September 11, 2019_02.58.csv"), but Dataverse serves ingested .tab by default (the .csv originals need ?format=original); each export keeps Qualtrics' two metadata rows under the header.  The design files encode the randomization restrictions (the internal-migrant .dat variants constrain origin), which the paper does not describe; a reproducer that ignores them estimates unweighted AMCEs, which can differ slightly.  Other files: Study 2 factorial data (usclimate_exp1.tab, "Climate Migration 1_ Article- Germany ... .tab"), the 2020 follow-up survey ("Migration Follow-Up_August 1, 2020 ... .tab"), and germany_state_key.tab.  No .tex, .log or .RData outputs: the independent-mode script-free copy carries no answers.
> Left out.  The other Table 2 rows (language, gender, occupation, religion, origin, vulnerability), the marginal-means ranges in the text (0.45-0.48 / 0.48-0.53 / 0.53-0.60, from a figure, not tabulated), internal/international subset AMCEs (Figure 1 middle/right, appendix), and all of study 2 (null priming effects, appendix tables only).
> First run 2026-10-21 (Phase 3.2 evaluation pass; main 0492c17, after the content-aware strip rule and the printed-precision floor; Opus 4.7, 47-package image, LLM cache on, --mode all, one run per mode; eval-7papers-all-modes-2026-10-21.json).  Seeded 4 / 12 (first scored 4; 1 error + 1 claim refinement): only the four counts.  The model reshaped the Qualtrics exports and estimated the AMCEs with feols clustered by respondent rather than the package's cjoint::amce with the design's randomisation constraints; the AMCEs come out ~1.5-2x too large (0.069 vs 0.035) and one German attribute level failed a label regex (NA).  The 3,700-line package script with hard-coded Windows paths was in the prompt; the model rewrote rather than translated, so the seeded vs independent gap is undefined for this paper. Independent 0 / 12 (first scored 0; 3 error + 3 claim refinements): AMCEs near zero, respondents 1,033 / 1,029.  Blind 1 / 12 (first scored 1; 1 error repair): AMCEs again ~2x too large, amce_flooding_germany (0.091 vs 0.086) inside its SE band.  Most expensive paper of the pass ($2.44 for three modes).

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `amce_drought_us` | 0.035 | 0.012 | Table 2, U.S. Sample, Reason for Migration: Drought | 0.035 | matches |
| 1 | `amce_flooding_us` | 0.037 | 0.012 | Table 2, U.S. Sample, Reason for Migration: Flooding | 0.037 | matches |
| 2 | `amce_wildfires_us` | 0.04 | 0.011 | Table 2, U.S. Sample, Reason for Migration: Wildfires | 0.04 | matches |
| 3 | `amce_persecution_us` | 0.076 | 0.012 | Table 2, U.S. Sample, Reason for Migration: Political/religious/ethnic persecution | 0.076 | matches |
| 4 | `amce_drought_germany` | 0.081 | 0.012 | Table 2, German Sample, Reason for Migration: Drought | 0.081 | matches |
| 5 | `amce_flooding_germany` | 0.086 | 0.012 | Table 2, German Sample, Reason for Migration: Flooding | 0.086 | matches |
| 6 | `amce_wildfires_germany` | 0.06 | 0.012 | Table 2, German Sample, Reason for Migration: Wildfires | 0.06 | matches |
| 7 | `amce_persecution_germany` | 0.162 | 0.013 | Table 2, German Sample, Reason for Migration: Political/religious/ethnic persecution | 0.162 | matches |
| 8 | `respondents_us` | 1086 | — | Study 1: Empirical Design (text) | 1086 | matches |
| 9 | `respondents_germany` | 1074 | — | Study 1: Empirical Design (text) | 1074 | matches |
| 10 | `choice_tasks_us` | 18966 | — | Study 1: Empirical Design (text) | 18966 | matches |
| 11 | `choice_tasks_germany` | 18862 | — | Study 1: Empirical Design (text) | 18862 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [12/12](seeded/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b) | [12/12](independent/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[12/12](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [12/12](blind/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[12/12](blind/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[12/12](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-claude-opus-4-7` | [4/12](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [0/12](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [1/12](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) |
| `pipeline-desktop-opus` | [12/12](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) (20261023T063725Z) | [12/12](independent/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) | [12/12](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) |
| `pipeline-desktop-opus-run2` | [12/12](seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) (20261023T152513Z) | [12/12](independent/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) | [12/12](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-claude-opus-4-7/20261021T142909Z](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `amce_flooding_germany` | 0.091215 | 0.086 | ±0.012 (se_band) | 0.435 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261023T152513Z](seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) | `amce_drought_germany` | 0.080475 | 0.081 | ±0.00162 (relative) | 0.324 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261023T152513Z](seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) | `amce_flooding_germany` | 0.086466 | 0.086 | ±0.00172 (relative) | 0.271 | PASS |
| [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) | `amce_flooding_germany` | 0.086457 | 0.086 | ±0.00172 (relative) | 0.266 | PASS |
| [seeded/pipeline-desktop-opus/20261023T063725Z](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `amce_flooding_germany` | 0.086457 | 0.086 | ±0.00172 (relative) | 0.266 | PASS |
| [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) | `amce_persecution_us` | 0.07568 | 0.076 | ±0.00152 (relative) | 0.211 | PASS |
| [seeded/pipeline-desktop-opus/20261023T063725Z](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `amce_persecution_us` | 0.07568 | 0.076 | ±0.00152 (relative) | 0.211 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261023T152513Z](seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) | `amce_persecution_us` | 0.07568 | 0.076 | ±0.00152 (relative) | 0.211 | PASS |
| [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) | `amce_drought_germany` | 0.080667 | 0.081 | ±0.00162 (relative) | 0.206 | PASS |
| [seeded/pipeline-desktop-opus/20261023T063725Z](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `amce_drought_germany` | 0.080667 | 0.081 | ±0.00162 (relative) | 0.206 | PASS |

### Declared deviations

- [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) (12/12)
  - cjoint is not installed in the sandbox: cjoint::read.qualtrics(new.format=TRUE) was re-implemented in base R (respondent x task x profile long format, attributes matched by name from F-k-a / F-k-j-a columns, selected = 1 if the forced-choice answer equals the profile number, NA if unanswered), and cjoint::amce() was estimated as an OLS of selected on the seven attribute factors with fixest::feols and respondent-clustered SEs. Baselines follow the authors' baselines list.
  - Germany: attribute columns were renamed by German attribute name (Beruf->Occupation, Geschlecht->Gender, Gruende fuer die Migration->Reason.for.migration, Herkunft->Origin, Sprachkompetenz->Language.Fluency, Zusaetzliche Belastung->Vulnerability) rather than by the script's column positions 23-36, which depend on cjoint's internal column order.
  - Germany: the reported AMCEs come from the main-effects model. The design file declares a Language Fluency x Origin restriction (no 'Keine' language with same-country origin, which the data confirm), and cjoint would add that interaction for dependent attributes. The interacted model is also printed: its reason-for-migration coefficients (drought/flooding/wildfires/persecution) are 0.0805/0.0865/0.0598/0.1617, versus 0.0807/0.0865/0.0598/0.1623 in the main-effects model. The main-effects model was chosen as the scored specification when the script was written, before any results were seen; the script was not changed afterward.
- [independent/claude-code/2026-10-21-b](independent/claude-code/2026-10-21-b/CELL.md) (12/12)
  - Profile count reported as all profiles in choice tasks the respondent answered (18970 US); the paper reports 18966, a difference of 4 profiles (2 tasks) whose source I did not identify. The German count matches exactly (18862).
- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (12/12)
  - US profile count is 18970 (9485 answered pairs from 1086 respondents, keeping every answered task including the one Qualtrics preview response); the paper reports 18966. The 2-pair difference could not be traced to any filter; no filter was applied to chase it.
  - Language x Origin interaction included to mirror the design-file restriction (cjoint-style); the additive model gives Reason coefficients within 0.0006 (printed in stdout). In the US data the restriction was evidently not enforced (1274 None-fluency/Another-region profiles).
- [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (0/12; failed: `amce_drought_us`, `amce_flooding_us`, `amce_wildfires_us`, `amce_persecution_us`, `amce_drought_germany`, `amce_flooding_germany`, `amce_wildfires_germany`, `amce_persecution_germany`, `respondents_us`, `respondents_germany`, `choice_tasks_us`, `choice_tasks_germany`)
  - The AMCE estimates do not match the paper despite correct attribute coding. The core issue appears to be that the choice variable detection is picking up wrong columns, inverting or scrambling the chosen indicator. Switching to more careful choice detection: for conjoint tasks, the choice should be the question asked after each pair, and we need to look at the specific pattern.
- [blind/claude-code/2026-10-21-b](blind/claude-code/2026-10-21-b/CELL.md) (12/12)
  - Language x Origin interaction included in the AMCE regression to respect the design-file restriction (Language None never paired with Origin 'Another region'); the restriction is enforced in the German data but not in the US data. An additive specification gives reason-for-migration AMCEs within 0.001 of the main-specification ones (printed in stdout as a check).
  - Sample: Qualtrics preview responses (DistributionChannel = 'preview') dropped; profiles whose forced-choice question was unanswered dropped; respondents are respondents with at least one answered choice task. Duplicate psid values (2 US, 8 DE) were kept as separate respondents (clustered on ResponseId).
- [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) (12/12)
  - AMCEs are estimated by additive OLS (all seven attributes as dummies, Table 1 baselines) with respondent-clustered SEs via fixest, rather than with the cjoint package. The design file restricts Language=None with Origin=Another region; this restriction was enforced in the German randomization (0 such profiles) but not in the U.S. data (1274 such profiles). No Language x Origin interaction was added; reason for migration is randomized independently of both, so its AMCEs are unaffected in expectation.
  - No respondent filters (Status/preview, Finished, duplicate panel IDs) were applied: every profile whose forced-choice answer is non-missing is used, including those from respondents who did not finish all nine tasks. Respondents = distinct ResponseIds with at least one answered choice task; choice tasks = profile-level observations entering the AMCE regression (2 per answered pair).
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (12/12)
  - Language x Origin interaction included in the full model (cjoint convention for the design's restriction Language=None x Origin=Another region, as specified in conjoint_design.dat); reason-for-migration AMCEs are its main-effect coefficients.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

## Cells

### seeded · claude-code · 2026-10-21-b

[`seeded/claude-code/2026-10-21-b/CELL.md`](seeded/claude-code/2026-10-21-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-10-22T02:06:00Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-claude-opus-4-7 · 20261021T142909Z

[`seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 4/12, re-scored 4/12; first scored 4/12; executions 3; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261023T063725Z

[`seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md`](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T06:37:25Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T152513Z

[`seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) — final 12/12, re-scored 12/12; first scored 4/12; executions 2; 2026-10-23T15:25:13Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-21-b

[`independent/claude-code/2026-10-21-b/CELL.md`](independent/claude-code/2026-10-21-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-10-22T02:09:00Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-11-02T04:40:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-claude-opus-4-7 · 20261021T142909Z

[`independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 0/12, re-scored 0/12; first scored 0/12; executions 7; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261023T062931Z

[`independent/pipeline-desktop-opus/20261023T062931Z/CELL.md`](independent/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T150832Z

[`independent/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-21-b

[`blind/claude-code/2026-10-21-b/CELL.md`](blind/claude-code/2026-10-21-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-10-22T02:13:30Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### blind · claude-code · 2026-10-22-a

[`blind/claude-code/2026-10-22-a/CELL.md`](blind/claude-code/2026-10-22-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-10-22T02:45:13Z; from `claude-code-blind-rerun-2026-10-22.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-11-02T04:21:16Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-claude-opus-4-7 · 20261021T142909Z

[`blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 1/12, re-scored 1/12; first scored 1/12; executions 2; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261023T062931Z

[`blind/pipeline-desktop-opus/20261023T062931Z/CELL.md`](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

