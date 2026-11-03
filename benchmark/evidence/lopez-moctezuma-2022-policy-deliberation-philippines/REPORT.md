# Evidence report: lopez-moctezuma-2022-policy-deliberation-philippines

**Policy Deliberation and Voter Persuasion: Experimental Evidence from an Election in the Philippines** — Gabriel López-Moctezuma, Leonard Wantchekon, Daniel Rubenson, Thomas Fujiwara, Cecilia Pe Lero

- Paper: https://authors.library.caltech.edu/api/records/qce9v-wvk72/files/American_J_Political_Sci_-_2020_-_L_pez_u2010Moctezuma_-_Policy_Deliberation_and_Voter_Persuasion_Experimental_Evidence_from_an.pdf/content
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/lopez-moctezuma-2022-policy-deliberation-philippines.yaml`
- Data access: public

> Headline finding: in a cluster-randomised experiment in the May 2013 Philippine party-list election (13 municipalities, one treated and two control barangays each, 39 barangays), assignment of town-hall (deliberative) campaigns raised the treating party list's official vote share by 1.096 percentage points over a control mean of 2.397 (Table 1 col 2, permutation p = .048), with no turnout effect (-4.544, p = .404); in the post-election survey the effect is driven by women (Akbayan) and low-income / less-educated voters (Umalab Ka), and town halls moved attitudes on gender (index +0.45 s.d.) and, less, poverty.
> Original analysis in R 3.6.2 (base lm, AER::ivreg, ri for randomization inference, stargazer / xtable output); language: r is the reproduction target and matches the original.
> outcome_label.  The I4R verdict is "minor discrepancies" (computational_reproduction = 1, perfect_reproduction = No) and the only reason recorded is having to install archived CRAN versions; the replicator answered that the code produces the paper's output.  The schema has no "minor discrepancies" label, so the entry is labelled reproducible (stratification only).  The robustness rows (dropping the attendance weights kills the Akbayan gender-index effect, 0.450 -> -0.001, and the Akbayan poverty-index effect, 0.496 -> 0.138, p = 0.39) would argue for not_robust on the attitude claims; the omitted-cities rows leave Table F.1 unchanged.
> Curation pass (2026-10-21).  Pinned 13 claims: Table 1's four ITT coefficients and its three observation counts (39 / 39 / 18 / 21; the first two columns share one count), the summary-index ITTs of SI Tables C.3 and C.4 for both party lists (0.496, 0.126, 0.450, 0.095), and the pooled and Akbayan ITTs of SI Table F.1 (23.242, 31.729). Why this mix: Table 1 is the paper's only main-text table and is what the package's aggregate data produce, but it has no I4R row; every I4R row is from SI Tables C.3, C.4 and F.1, so their estimates are pinned so that six claims carry findings.  F.1 columns 1 and 4 (turnout 1.965, Umalab Ka 14.057) also have rows but were left out to stay within 13 claims; C.3 / C.4 component columns have no rows. Values exactly as printed (published AJPS PDF for Table 1; the SI PDF, compiled 2020-05-23, for C.3 / C.4 / F.1), and equal to the database's o_coeff except the F.2 slip noted on claim 11.  The tables print p-values ("p = .048"), never SEs, so no standard_error is pinned; the CACE rows, control means and R2 are not pinned.  Observation counts of the SI columns are not pinned (C.3 Akbayan index 640, Umalab Ka 568; C.4 644 / 542; F.1 869 / 476).
> What was read.  The published AJPS PDF (all 16 pp.); the SI PDF (all 30 pp.: Tables A.1-A.2, B.1-B.2, C.1-C.4, D.1-D.3, E.1, F.1, Figure G.1, survey questions H); the March 2017 working paper (front matter and table list, for dates and numbering only: its Table 4 is the barangay-level ITT, Tables 7-9 the individual ITT and attitudes); the package readme, main_*.R, functions_*.R, tables_figures_agg.R, tables_fig_ind.R, tables_fig_ind_unweighted.R and survey_clean.R; the database's 10 rows (team 66); the Dataverse and CaltechAUTHORS API metadata.  No R run of the package was made in this pass.
> How the printed numbers are produced (package-only; never in contexts).  Table 1: tables_figures_agg.R (run via main_agg.R) loads data_agg.RData (object data.all; outcomes turnout.party, share.treated, share.akbayan, share.umalabka; assignment, treatment, city, barangay, partytreat in {"akbayan","umalabka"}); the ITT is ri::estate(outcome, assignment, X = city dummies (dummies::dummy), prob = ri::genprobexact(assignment, blockvar = city, clustvar = barangay)) — an IPW regression with city dummies — and the p-value is from ri::genperms (maxiter 50000, set.seed(1983)) / gendist; the CACE is ri::estlate; the Control row is the intercept of a weighted lm without city dummies.  Output table_agg.txt (stargazer).  Columns 3-4 subset partytreat; rows with missing outcome dropped.  SI Tables C.3 / C.4: tables_fig_ind.R (run via main_ind.R, after main_survey.R -> survey_clean.R builds survey_ind.RData / survey_agg.RData from survey_raw.RData): lm(index ~ assignment + city, weights = weight.att) per partytreat in {"Akbayan","Umalab Ka"}, clustered vcov by barangay (varcov.cluster in functions_ind.R).  weight.att = att.prop (official attendance share from data_agg) / attendance.agg (survey share of self-reported attendees) in treatment barangays, 1 in controls. Indices: poverty.all (Table C.3) and sexism (Table C.4) from survey_clean.R — items standardized by standard(), which centres on the full-sample mean and scales by the s.d. among treatment == 0 (implemented, not assigned, status), then combined with wmean() (inverse-covariance weights).  Outputs table_pov.txt / table_sex.txt (the readme says .pdf).  SI Table F.1: tables_fig_ind_unweighted.R — outcomes turnout_pl, vote, vote.akbayan, vote.umalabka multiplied by 100, lm(y ~ assignment + city, weights = weight.assign) where weight.assign is the inverse assignment probability from ri::genprobexact (so "unweighted" means no attendance weights, not no weights); permutation p-values; output table_itt_unweighted.txt.
> Package quirks for a run.  (1) The scripts depend on ri and dummies, both archived off CRAN (the I4R discrepancy), plus AER, stargazer, xtable, mvtnorm, MatchIt, Amelia, doParallel, fastLink, data.table. (2) main.dir is "" and the scripts setwd() to /data/aggregate/ and /data/survey/ and load "../aggregate/data_agg.RData"; the downloader flattens Dataverse's folders, so paths must be rewritten.  (3) survey_ind.RData / survey_agg.RData are generated, not shipped.
> Left out.  Table 1 CACE row (estlate) and control means; Figures 2-5 (figures; their point estimates are in SI Tables C.2-C.4, D.3); SI Table C.2 (weighted individual ITT, no I4R row); C.3 / C.4 component columns; D / E tables (covariates, multiple imputation); maps (Figure A.1).
> Render check (render_task, run id curation-check, 2026-10-21).  Before the parser fix paper.txt was the raw PDF byte stream decoded as text (483 KB of "%PDF-1.6 ... endobj"); after it, 67 KB of the published article.  Blind: 16 files stripped (all 16 R scripts; readme.txt, codebooks, data and shapefiles kept), 20 paper redactions.  None of the 13 pinned literals appears in the blind task.md or paper.txt, but the article text still says "0.13 s.d. units" twice (the rounded Umalab Ka poverty-index ITT, claim 8 — outside its tolerance band), and the dataset listing shows data.all with 39 rows (the Table 1 columns 1-2 N follows from the data).  The SI is not part of paper.txt in any mode, so the six SI claims rest on their location / context.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `itt_turnout_barangay_table1_col1` | -4.544 | — | Table 1, column 1 (Turnout), ITT row | — | — |
| 1 | `itt_vote_overall_barangay_table1_col2` | 1.096 | — | Table 1, column 2 (Vote (overall)), ITT row | — | — |
| 2 | `itt_vote_akbayan_barangay_table1_col3` | 1.955 | — | Table 1, column 3 (Vote (Akbayan)), ITT row | — | — |
| 3 | `itt_vote_umalabka_barangay_table1_col4` | 0.36 | — | Table 1, column 4 (Vote (Umalab Ka)), ITT row | — | — |
| 4 | `n_obs_barangay_table1_cols1_2` | 39 | — | Table 1, Observations, columns 1 and 2 | — | — |
| 5 | `n_obs_barangay_akbayan_table1_col3` | 18 | — | Table 1, Observations, column 3 | — | — |
| 6 | `n_obs_barangay_umalabka_table1_col4` | 21 | — | Table 1, Observations, column 4 | — | — |
| 7 | `itt_poverty_index_akbayan_tableC3` | 0.496 | — | SI Table C.3, Akbayan Treatment panel, column 1 (Index), ITT row | 0.496 | matches |
| 8 | `itt_poverty_index_umalabka_tableC3` | 0.126 | — | SI Table C.3, Umalab Ka Treatment panel, column 1 (Index), ITT row | 0.126 | matches |
| 9 | `itt_gender_index_akbayan_tableC4` | 0.45 | — | SI Table C.4, Akbayan Treatment panel, column 1 (Index), ITT row | 0.45 | matches |
| 10 | `itt_gender_index_umalabka_tableC4` | 0.095 | — | SI Table C.4, Umalab Ka Treatment panel, column 1 (Index), ITT row | 0.095 | matches |
| 11 | `itt_vote_overall_unweighted_tableF1_col2` | 23.242 | — | SI Table F.1, column 2 (Vote (Overall)), ITT row | 23.242 | matches |
| 12 | `itt_vote_akbayan_unweighted_tableF1_col3` | 31.729 | — | SI Table F.1, column 3 (Vote (Akbyan)), ITT row | 31.729 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[13/13](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [9/13](independent/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[9/13](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a)<br>[9/13](independent/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) | [9/13](blind/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[9/13](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a)<br>[9/13](blind/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) (20261023T063725Z) | [9/13](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) (20261023T064839Z) | [9/13](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [9/13](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [9/13](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) | [9/13](independent/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) | [9/13](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) (20261103T004800Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/claude-code/2026-10-22-a](independent/claude-code/2026-10-22-a/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |
| [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |
| [independent/claude-code/2026-11-02-c](independent/claude-code/2026-11-02-c/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |
| [independent/pipeline-desktop-opus/20261023T064839Z](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |
| [independent/pipeline-desktop-opus-run2/20261023T151837Z](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |
| [independent/pipeline-desktop-opus-run3/20261103T010557Z](independent/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |
| [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |
| [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |
| [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |
| [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `itt_vote_overall_unweighted_tableF1_col2` | 23.5099 | 23.242 | ±0.46484 (relative) | 0.576 | PASS |

### Declared deviations

- [seeded/claude-code/2026-10-22-a](seeded/claude-code/2026-10-22-a/CELL.md) (13/13)
  - ri::genprobexact / ri::estate are not installed; assignment probabilities computed as the within-city share of treated barangays (exact for this complete block-cluster randomization), and the ITT computed as the IPW-weighted OLS of the outcome on assignment plus city dummies, which is what ri::estate does when given X and prob. Randomization-inference p-values were not computed (not claimed).
  - survey_ind.RData and survey_agg.RData are not shipped; they were rebuilt from survey_raw.RData following survey_clean.R (control-group-standardized items, inverse-covariance weighted indices). The fastLink name match of survey to official barangays was replaced by an exact barangay-name merge on the 10 treated surveyed barangays (all 10 linked; only treated barangays enter the attendance weights).
  - Clustered SEs by barangay computed with sandwich::vcovCL (HC1) rather than the authors' varcov.cluster; only point estimates are scored.
- [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) (13/13)
  - survey_clean.R links survey barangays to official barangays with fastLink (not installed); replaced by an exact barangay-name match, which matches all 10 treated survey barangays (control weights are 1 regardless).
  - ri::estate / ri::genprobexact replaced by direct computation: assignment probability = share of assigned barangays within each city; ITT = lm(y ~ assignment + city dummies) with weights Z/p + (1-Z)/(1-p). Randomization-inference p-values and clustered SEs were not computed (only coefficients and N are claimed).
  - fastLink record linkage of survey to official barangays replaced by exact barangay-name match (treated barangays share names in both files); ri::estate/genprobexact computed directly.
- [independent/claude-code/2026-10-22-a](independent/claude-code/2026-10-22-a/CELL.md) (9/13; failed: `itt_poverty_index_akbayan_tableC3`, `itt_poverty_index_umalabka_tableC3`, `itt_gender_index_akbayan_tableC4`, `itt_gender_index_umalabka_tableC4`)
  - Attendance-oversampling weights reconstructed from the paper's one-sentence description: in barangays with town-hall attendees (att.prop > 0 in data_agg), self-reported attendees get weight att.prop / (survey attendee share in that barangay), all other respondents weight 1. The exact weighting formula of the authors is not given in the paper text available; a two-sided IPW (non-attendees weighted (1-pa)/(1-ps)) was tried in attempts 2-3.
  - Anderson (2008) indices: items oriented so higher = more agreement with the problem statement for poverty/gap/corruption (6 - code), cct as coded; gender items oriented toward gender-egalitarian awareness (femhouse, fempol as coded; equality and harassment as coded, i.e. disagreement with sexist statements; discrimination reversed). Items standardized on the control group of each party's municipalities; inverse-covariance weights from the full-sample covariance of the standardized items; respondents with missing items use the available items; index re-standardized on the control group. Only five gender items exist in the data (the paper mentions six).
  - Survey sample: respondents with a valid party-list turnout answer (paper footnote 11; 1,081 with non-missing city/assignment vs 1,082 reported). Vote outcomes in F.1 are among respondents who turned out (turnout_pl == 1).
  - Permutation p-values for Table 1 computed by within-municipality reshuffling of assignment (2,000 draws, two-sided); they are printed for information only and do not match the paper's (e.g. 0.14 vs .048 for column 2).
- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (9/13; failed: `itt_poverty_index_akbayan_tableC3`, `itt_poverty_index_umalabka_tableC3`, `itt_gender_index_akbayan_tableC4`, `itt_gender_index_umalabka_tableC4`)
  - Attendance weights (survey analyses): weights are built in actually treated barangays as pt/ps for self-reported attendees and (1-pt)/(1-ps) for non-attendees, where pt = att.prop (attendees / registered voters, data_agg) and ps = the share of attendees among that barangay's respondents in the analysis sample; all other respondents get weight 1. The paper only describes the adjustment verbally; this exact form is my reconstruction.
  - Anderson (2008) indices: items oriented as higher = more agreement with the party's concern (poverty, gap, corruption reversed 6-x; cct as is; femhouse, fempol, equality, harassment as is; discrimination reversed 6-x), each standardized by the control-group (assignment==0) mean and s.d. within the party's municipalities, weighted by row sums of the inverse (pairwise) covariance matrix over the items a respondent has, then the index is re-standardized on the control group. Effective sample = respondents with non-missing turnout_pl (1,081 here; paper says 1,082). Regressions use city FE, attendance weights, SEs clustered by barangay.
  - Permutation p-values, CACE and SEs were not computed (only the listed point estimates and Ns).
- [independent/claude-code/2026-11-02-c](independent/claude-code/2026-11-02-c/CELL.md) (9/13; failed: `itt_poverty_index_akbayan_tableC3`, `itt_poverty_index_umalabka_tableC3`, `itt_gender_index_akbayan_tableC4`, `itt_gender_index_umalabka_tableC4`)
  - Attendance-oversampling weights reconstructed from the paper's one-sentence description: in barangays with treatment == 1, self-reported attendees are weighted att.prop / p_s and non-attendees (1 - att.prop) / (1 - p_s), where p_s is the survey share of attendees in the barangay and att.prop is attendees / registered voters from data_agg; weight 1 elsewhere and for missing attendance.
  - Survey sample restricted to respondents with non-missing party-list turnout and non-missing city/barangay (effective sample, fn. 11).
  - Index item orientation is my interpretation: poverty, gap, corruption reversed (higher = agrees the issue is a main problem), cct kept; gender items oriented toward awareness (femhouse, fempol, equality, harassment kept; discrimination reversed). Anderson index: items standardized on the within-panel control group (assignment == 0), inverse-covariance (pairwise) weights, available-item averaging, re-standardized on control s.d.
- [independent/pipeline-desktop-opus/20261023T064839Z](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) (9/13; failed: `itt_poverty_index_akbayan_tableC3`, `itt_poverty_index_umalabka_tableC3`, `itt_gender_index_akbayan_tableC4`, `itt_gender_index_umalabka_tableC4`)
  - Index items located by name pattern (gender index has 6 items per paper); attitude items oriented via their value labels (higher = more agreement, DK/refused set to missing). Summary indices are constructed once on the pooled analysis sample (respondents with a valid turnout response in municipalities with both treatment and control samples; control-group mean/s.d. and inverse-covariance weights from the pooled control group) and then the ITT is estimated separately by party
- [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) (9/13; failed: `itt_poverty_index_akbayan_tableC3`, `itt_poverty_index_umalabka_tableC3`, `itt_gender_index_akbayan_tableC4`, `itt_gender_index_umalabka_tableC4`)
  - Attendance-oversampling weights reconstructed from the paper's description: in barangays with town-hall attendance, self-reported attendees get weight att.prop/s_j and non-attendees (1-att.prop)/(1-s_j), where s_j is the survey attendee share in the barangay and att.prop the attendance-sheet share of registered voters (data_agg); all other respondents weight 1. Respondents with missing attendance treated as non-attendees for the weights.
  - Anderson (2008) indices built on all survey respondents with a non-missing city/barangay (control group = assignment 0), item weights from the inverse of the pairwise covariance matrix of the control-standardized items, averaged over available items, then re-standardized on the control group. Item orientation: poverty, gap, corruption reversed (6 - x) so higher = more agreement the issue is a main problem; cct as coded. Gender: equality and harassment as coded (5 = strongly disagree with a sexist statement), discrimination reversed (higher = agrees women miss out due to discrimination), femhouse and fempol as coded.
  - Individual regressions restricted to respondents with a valid party-list turnout answer (1,081 here vs 1,082 in the paper; one respondent lacks city/barangay). Vote outcomes (F.1) among party-list voters, unweighted, x100.
  - Barangay-level regressions use data_agg (39 barangays; Luisiana's San Diego/San Antonio is a single row) with the assignment variable as coded there.
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (9/13; failed: `itt_poverty_index_akbayan_tableC3`, `itt_poverty_index_umalabka_tableC3`, `itt_gender_index_akbayan_tableC4`, `itt_gender_index_umalabka_tableC4`)
  - Attendance weights (paper describes them only verbally): in barangays where town halls were held (treatment==1), self-reported attendees get att.prop/s_j and non-attendees (1-att.prop)/(1-s_j), where att.prop is attendees/registered voters from data_agg and s_j the share of self-reported attendees among all survey respondents in the barangay; weight 1 elsewhere; treated-barangay respondents with missing attendance dropped from weighted regressions.
  - Anderson indices: items oriented so that higher = more concern about poverty (poverty, gap, corruption reversed 6-x; cct as is) or more pro-gender-equality / less sexist (femhouse, fempol, equality, harassment as is; discrimination reversed 6-x); standardized on the unweighted control-group (assignment==0) mean and s.d. within each party's municipalities; weights = row sums of the inverse pairwise-complete covariance matrix; index averaged over available items and re-standardized on the control group.
  - Survey effective sample = respondents with non-missing turnout_pl (1,081 after dropping one row with missing city/barangay/assignment; paper reports 1,082). Vote outcomes (F.1) use respondents with turnout_pl==1.
  - Barangay-level ITT uses the assignment variable as coded in data_agg.RData; permutation p-values were not computed (only coefficients and N are requested).
- [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) (9/13; failed: `itt_poverty_index_akbayan_tableC3`, `itt_poverty_index_umalabka_tableC3`, `itt_gender_index_akbayan_tableC4`, `itt_gender_index_umalabka_tableC4`)
  - Attendance-oversampling weights reconstructed: in barangays with town-hall meetings (att.prop > 0 in data_agg), attendees weighted by att.prop / survey attendance share and non-attendees by (1 - att.prop) / (1 - survey share); weight 1 elsewhere and for respondents with missing attendance. The authors' exact weight formula is not given in the paper.
  - Anderson (2008) indices: all five-point items (poverty, gap, corruption, equality, discrimination, harassment) reversed (6 - x) so that higher = more agreement, following the paper's literal statement; binary items (cct, femhouse, fempol) kept as coded. Items standardized on the assignment==0 group of each party's municipalities, inverse-covariance weights from the pairwise covariance matrix of standardized items, index averaged over available items and re-standardized on the control group; built separately within each party sample.
  - Survey sample: respondents with non-missing party-list turnout response (and non-missing city), N = 1081 (paper reports 1,082; one respondent has missing city).
  - Only point estimates computed; permutation inference not reproduced (not among the requested quantities).
  - attendance IPW weights constructed from data_agg att.prop (attendance sheets / registered voters) vs. barangay survey attendance share; exact authors' weight formula not documented
  - all five-point attitude items reversed (6-x) so higher = more agreement; binary items kept as coded

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

## Cells

### seeded · claude-code · 2026-10-22-a

[`seeded/claude-code/2026-10-22-a/CELL.md`](seeded/claude-code/2026-10-22-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-10-22T03:03:14Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T19:38:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261023T063725Z

[`seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md`](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-23T06:37:25Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261103T010557Z

[`seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### independent · claude-code · 2026-10-22-a

[`independent/claude-code/2026-10-22-a/CELL.md`](independent/claude-code/2026-10-22-a/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 5; 2026-10-22T03:15:00Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 6; 2026-11-02T04:33:57Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · claude-code · 2026-11-02-c

[`independent/claude-code/2026-11-02-c/CELL.md`](independent/claude-code/2026-11-02-c/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 4; 2026-11-02T20:07:30Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261023T064839Z

[`independent/pipeline-desktop-opus/20261023T064839Z/CELL.md`](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 4; 2026-10-23T06:48:39Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T151837Z

[`independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261103T010557Z

[`independent/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### blind · claude-code · 2026-10-22-a

[`blind/claude-code/2026-10-22-a/CELL.md`](blind/claude-code/2026-10-22-a/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-10-22T03:20:33Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-11-02T04:24:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · claude-code · 2026-11-02-c

[`blind/claude-code/2026-11-02-c/CELL.md`](blind/claude-code/2026-11-02-c/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-11-02T20:40:00Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261023T062931Z

[`blind/pipeline-desktop-opus/20261023T062931Z/CELL.md`](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261103T004800Z

[`blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 1; 2026-11-03T00:48:00Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

