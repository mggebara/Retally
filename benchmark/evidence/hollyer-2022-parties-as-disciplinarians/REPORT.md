# Evidence report: hollyer-2022-parties-as-disciplinarians

**Parties as Disciplinarians: Charisma and Commitment Problems in Programmatic Campaigning** — James R. Hollyer, Marko Klašnja, Rocío Titiunik

- Paper: https://titiunik.github.io/files/publications/HollyerKlasnjaTitiunik2022-AJPS.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/274553/1/I4R-DP054.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/hollyer-2022-parties-as-disciplinarians.yaml`

> Headline findings (as published): across DALP parties, higher electoral volatility goes with more Personalism and less Programmaticness (Hypothesis 1, Table 1 upper panel), but only for nonethnic and ideologically moderate parties; ethnic and extremist parties' strategies do not vary with volatility (Hypothesis 2), and in stable systems ethnic/extremist parties are more personalist while in volatile systems they are more programmatic (Hypothesis 3, three of four comparisons significant).  In Brazil, a party that barely wins a mayoral election is about 8-9 percentage points less likely to field a young (or young outsider) candidate next time (Table 2, local linear RD).  DP54 reproduces all of this except the extremist-party rows of Table 1.
> Original analysis: Stata 16 (Table 1) and R 4.0.3 with rdrobust (Table 2); language: r is the reproduction target.
> Curation pass (2026-11-02).  Pinned 13 claims: ten Table 1 differences with their SEs (the volatility differences for all, nonethnic and moderate parties; the four Hypothesis 3 comparisons ethnic/extremist minus nonethnic/moderate at the relevant volatility level), the Table 1 N, and the two Table 2 RD point estimates.  Values exactly as printed in the published AJPS PDF, two decimals in Table 1 (trailing zeros kept: 0.30, 0.20, -0.30) and three in Table 2; the printed-precision floor is therefore 0.005 on every Table 1 claim.  Every pinned value equals the meta-database's o_coeff_dbl / o_std_err_dbl where a row exists (the DB stores 0.30 as 0.3 and -0.30 as -0.3; Table 2 rows carry no SE in the DB and the paper prints none).  Not pinned: the Table 1 levels (the differences are what the hypotheses rest on), the ethnic- and extremist-party volatility differences (0.04, 0.03, 0.05, 0.08: the "invariance" rows), the two remaining Hypothesis 3 cells (both near zero), and Table 2's p-values, confidence intervals, bandwidths and N+/N- (rdrobust outputs that move with the bandwidth selector version).  Table 1 N is 431 parties in 75 countries per the note; appendix Table D1 shows the ideology models use 430.
> What was read.  The published AJPS PDF (all 18 pp.: model, empirical implications, the cross-national section, Table 1, the Brazil section, Table 2 and footnotes 17-21); the supplementary appendix (Sections C and D: Tables C1-C3, D1); DP54 (27 pp., EconStor: text, Tables 2-6); the Dataverse API metadata for versions 1.0 and 1.1; the package (00-README.txt, codebook.pdf, brazil-RD-analysis.R, cross-national-designate-controls.do, the Table 1 section and margins programs of cross-national-analysis.do; estimation-sample counts of cross-national-data.dta); the 176 team-62 meta-database rows.
> Package-only facts (never in contexts).  Table 1: setup loads cross-national-data.dta and runs cross-national-designate-controls.do, which divides gini by 100 (DP54's "Gini coefficient of 0" comes from skipping this) and sets p_controls = partysize unions business religious and controls = pluralty i.pr b3.cl mdmh b1.system demsys polity gdppc gini ethfrac.  Models: reg personal|programmatic ev_total $p_controls $controls, cluster(ccode); then i.ethnic##c.ev_total and c.extremist2##c.ev_total versions.  Predicted values are Stata margins (average predictions over the estimation sample) at ev_total = its p25 and p75 in e(sample) (sum, d), and differences via lincom.  In the group-attachment models the high-attachment party is set at the p90 of the attachment variable in e(sample): 1 for ethnic, but for extremist2 about 3.55 (numpy linear p90 on the 430-party sample; p75 is about 2.58), NOT the "3, approximately the 75th percentile" the paper states.  That is why DP54, which used 3, could not match the extremist rows; a run that follows the paper text is expected to miss claims 8 and 9 (and the extremist levels) while hitting the moderate rows.  Estimation sample: 431 complete cases over 75 ccode clusters (430 with extremist2); ev_total p25/p75 about 0.146/0.420.  Table 2: brazil-RD-data.dta; outcomes youngF_inc_for1 and outyg1F_inc_for1, running variable mv_incparty, sample dlameduck_runs == 0; rdrobust(y, x) with defaults (local linear, triangular kernel, mserd bandwidth, separate b), Estimate[1] is the conventional estimate; the h = b column reruns with rho = 1.
> Leak surface.  The independent/blind script-free copy drops all six scripts by suffix (Figure1.R, Figure2.R, brazil-RD-analysis.R, cross-national-analysis.do, cross-national-designate-controls.do, Table-E2.do) and keeps the four .dta files, 00-README.txt (a file list) and codebook.pdf (variable definitions); none carries a result.
> Blind-mode render check (2026-11-02, LLM oracle, zero API calls). Both blind and independent cells reached llm_answer_pending.  The blind generation prompt (reached by answering the methodology and hyperparameter calls with result-free placeholders) contains none of the 13 values or 10 SEs as printed or rounded to 1-3 significant figures, and no script text; its dataset listing shows only the four .dta files, 00-README.txt and codebook.pdf.  As for every entry, the methodology summariser itself receives the full paper text (Tables 1 and 2 included) with an instruction to leave results out, so the blind summary is only as clean as the summariser.  The paper's prose also restates rounded results that a value-matching redactor (the claude-code reproducer's) may not catch: "about 0.3 on a 1-4 scale" (Table 1 overall Personalism difference), "approximately 8 percentage points" and "about 9 percentage points" (Table 2), plus the Table 2 confidence intervals in the text.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `personalism_volatility_difference_overall` | 0.3 | 0.06 | Table 1, Overall row, Personalism, Difference column | 0.29 | matches |
| 1 | `programmaticness_volatility_difference_overall` | -0.11 | 0.05 | Table 1, Overall row, Programmaticness, Difference column | -0.11 | matches |
| 2 | `personalism_volatility_difference_nonethnic` | 0.35 | 0.06 | Table 1, Ethnicity panel, Nonethnic party row, Personalism, Difference column | 0.35 | matches |
| 3 | `programmaticness_volatility_difference_nonethnic` | -0.15 | 0.06 | Table 1, Ethnicity panel, Nonethnic party row, Programmaticness, Difference column | -0.15 | matches |
| 4 | `personalism_ethnic_minus_nonethnic_low_volatility` | 0.31 | 0.13 | Table 1, Ethnicity panel, Difference row, Personalism, Low volatility column | 0.3 | matches |
| 5 | `programmaticness_ethnic_minus_nonethnic_high_volatility` | 0.2 | 0.06 | Table 1, Ethnicity panel, Difference row, Programmaticness, High volatility column | 0.2 | matches |
| 6 | `personalism_volatility_difference_moderate` | 0.53 | 0.13 | Table 1, Ideology panel, Moderate party row, Personalism, Difference column | 0.52 | matches |
| 7 | `programmaticness_volatility_difference_moderate` | -0.3 | 0.08 | Table 1, Ideology panel, Moderate party row, Programmaticness, Difference column | -0.29 | matches |
| 8 | `personalism_extremist_minus_moderate_low_volatility` | 0.15 | 0.17 | Table 1, Ideology panel, Difference row, Personalism, Low volatility column | 0.12 | does_not_match |
| 9 | `programmaticness_extremist_minus_moderate_high_volatility` | 0.44 | 0.09 | Table 1, Ideology panel, Difference row, Programmaticness, High volatility column | 0.37 | does_not_match |
| 10 | `n_obs_table1` | 431 | — | Table 1, note | 431 | matches |
| 11 | `rd_effect_young` | -0.084 | — | Table 2, row Young, tau_RD | -0.084 | matches |
| 12 | `rd_effect_young_outsider` | -0.092 | — | Table 2, row Young and outsider, tau_RD | -0.092 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [13/13](independent/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](independent/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [13/13](blind/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](blind/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261102T141403Z/CELL.md) (20261102T141403Z) | [13/13](independent/pipeline-desktop-opus/20261102T141403Z/CELL.md) (20261102T141403Z) | [10/13](blind/pipeline-desktop-opus/20261102T095147Z/CELL.md) (20261102T095147Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) (20261102T152052Z) | [13/13](independent/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) (20261102T152052Z) | [12/13](blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md) (20261102T151132Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-desktop-opus-run2/20261102T151132Z](blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md) | `programmaticness_extremist_minus_moderate_high_volatility` | 0.35364 | 0.44 | ±0.09 (se_band) | 0.960 | PASS |
| [blind/pipeline-desktop-opus-run2/20261102T151132Z](blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md) | `personalism_volatility_difference_nonethnic` | 0.41266 | 0.35 | ±0.06 (se_band) | 1.044 | FAIL |
| [blind/pipeline-desktop-opus/20261102T095147Z](blind/pipeline-desktop-opus/20261102T095147Z/CELL.md) | `programmaticness_volatility_difference_overall` | -0.163086 | -0.11 | ±0.05 (se_band) | 1.062 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261102T151132Z](blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md) | `personalism_ethnic_minus_nonethnic_low_volatility` | 0.428185 | 0.31 | ±0.13 (se_band) | 0.909 | PASS |
| [blind/pipeline-desktop-opus/20261102T095147Z](blind/pipeline-desktop-opus/20261102T095147Z/CELL.md) | `programmaticness_volatility_difference_nonethnic` | -0.218785 | -0.15 | ±0.06 (se_band) | 1.146 | FAIL |
| [independent/pipeline-desktop-opus/20261102T141403Z](independent/pipeline-desktop-opus/20261102T141403Z/CELL.md) | `programmaticness_extremist_minus_moderate_high_volatility` | 0.364781 | 0.44 | ±0.09 (se_band) | 0.836 | PASS |
| [blind/pipeline-desktop-opus-run2/20261102T151132Z](blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md) | `personalism_volatility_difference_overall` | 0.348361 | 0.3 | ±0.06 (se_band) | 0.806 | PASS |
| [independent/pipeline-desktop-opus-run2/20261102T152052Z](independent/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) | `programmaticness_extremist_minus_moderate_high_volatility` | 0.370113 | 0.44 | ±0.09 (se_band) | 0.777 | PASS |
| [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) | `programmaticness_extremist_minus_moderate_high_volatility` | 0.3713 | 0.44 | ±0.09 (se_band) | 0.763 | PASS |
| [independent/claude-code/2026-11-02-b](independent/claude-code/2026-11-02-b/CELL.md) | `programmaticness_extremist_minus_moderate_high_volatility` | 0.3713 | 0.44 | ±0.09 (se_band) | 0.763 | PASS |

### Declared deviations

- [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Ethnic party coded as ethnic > 0.5 (majority of expert coders report ethnic/linguistic linkages); extremism uses extremist2 (vote-share-weighted absolute distance from country mean, per codebook) with the extremist party at distance 3 as the paper states.
  - Covariate mapping inferred from paper text and codebook: partysize, unions, business, religious, pluralty, pr (mixed omitted), cl dummies (closed, open; non-list omitted), mdmh, polity, demsys, system dummies (presidential omitted), gdppc, gini, ethfrac. Volatility percentiles taken over the 431-party estimation sample. Extremism models use 430 parties (one missing extremist2).
- [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Volatility 25th/75th percentiles taken over the party-level estimation sample (N=430) using Stata-style percentiles (R quantile type 2); the paper says only 'in the sample'.
  - Ethnic party coded as ethnic > 0.5 (strict majority of expert coders report ethnic/linguistic linkages).
  - Ideological extremism uses the supplied extremist2 variable (per the codebook, vote-share-weighted absolute distance from the country mean left-right placement); extremist party at distance 3, moderate at 0.
  - Country covariates coded as: pluralty and pr dummies (mixed omitted); closed-list (cl==1) and open-list (cl==2) dummies (non-list omitted); mdmh; polity; demsys; system as a 3-level factor (presidential omitted); gdppc; gini; ethfrac. Party covariates: partysize, unions, business, religious.
  - Table 1 sample is complete cases on both outcomes, volatility, all covariates, ethnic and extremist2 (430 parties, 75 countries), so every panel uses the same sample.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- blind: `personalism_volatility_difference_nonethnic` — pipeline 1/2, agent 2/2
- blind: `programmaticness_ethnic_minus_nonethnic_high_volatility` — pipeline 1/2, agent 2/2
- blind: `programmaticness_volatility_difference_nonethnic` — pipeline 1/2, agent 2/2
- blind: `programmaticness_volatility_difference_overall` — pipeline 1/2, agent 2/2

## Cells

### seeded · claude-code · 2026-11-02-a

[`seeded/claude-code/2026-11-02-a/CELL.md`](seeded/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T09:47:00Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T19:42:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261102T141403Z

[`seeded/pipeline-desktop-opus/20261102T141403Z/CELL.md`](seeded/pipeline-desktop-opus/20261102T141403Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T14:14:03Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261102T152052Z

[`seeded/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T15:20:52Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-a

[`independent/claude-code/2026-11-02-a/CELL.md`](independent/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T01:50:00Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-b

[`independent/claude-code/2026-11-02-b/CELL.md`](independent/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T14:58:00Z; from `claude-code-run2-6papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261102T141403Z

[`independent/pipeline-desktop-opus/20261102T141403Z/CELL.md`](independent/pipeline-desktop-opus/20261102T141403Z/CELL.md) — final 13/13, re-scored 13/13; first scored 11/13; executions 2; 2026-11-02T14:14:03Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261102T152052Z

[`independent/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) — final 13/13, re-scored 13/13; first scored 10/13; executions 2; 2026-11-02T15:20:52Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-a

[`blind/claude-code/2026-11-02-a/CELL.md`](blind/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-02T01:50:00Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-b

[`blind/claude-code/2026-11-02-b/CELL.md`](blind/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T14:59:50Z; from `claude-code-run2-6papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261102T095147Z

[`blind/pipeline-desktop-opus/20261102T095147Z/CELL.md`](blind/pipeline-desktop-opus/20261102T095147Z/CELL.md) — final 10/13, re-scored 10/13; first scored 10/13; executions 1; 2026-11-02T09:51:47Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261102T151132Z

[`blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261102T151132Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 1; 2026-11-02T15:11:32Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

