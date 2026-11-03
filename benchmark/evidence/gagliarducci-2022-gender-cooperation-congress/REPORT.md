# Evidence report: gagliarducci-2022-gender-cooperation-congress

**Gender Differences in Cooperative Environments? Evidence from the U.S. Congress** — Stefano Gagliarducci, M. Daniele Paserman

- Paper: https://www.nber.org/system/files/working_papers/w22488/w22488.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/278109/1/I4R-DP075.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/gagliarducci-2022-gender-cooperation-congress.yaml`
- Data access: public

> Headline finding: bill-level evidence from the 101st-111th U.S. House that, after addressing the selection of women into districts (close- election RD and inverse-propensity-score weighting), Democratic women recruit no more cosponsors than Democratic men but fewer from the opposite party, while Republican women recruit more cosponsors and more bipartisan support (Table 5).  DP75 reproduces the table exactly and finds it largely robust to amended controls and member-level clustering; extending to 2011-2020 removes the Republican bipartisanship gap and strengthens the overall gender gap in number of cosponsors.
> Original analysis in Stata 16.1 (README: reghdfe 5.7.3, rdrobust 8.1.0, rddensity 2.3, DCdensity 2009, all vendored in Adofiles/); language: r is the reproduction target.
> Curation pass (2026-10-21).  Pinned 13 claims, all from Table 5 (the exhibit every I4R row refers to): nine female-sponsor coefficients with their SEs — Panel A (number of cosponsors): all sponsors OLS, Republicans OLS / RD+IPW / full-sample IPW with sponsor characteristics; Panel B (percent cosponsors of opposite party): Democrats OLS / RD / full-sample IPW with sponsor characteristics, Republicans OLS / full-sample IPW without sponsor characteristics — and four column-1 counts: bills in Panel A All (60,670), sponsor- Congress clusters in Panel A All (4,746), bills in Panel B Democrats (32,846) and Republicans (27,669).  The mix covers all three estimators (OLS, RD at a data-driven bandwidth, inverse-propensity weighting inside and outside the bandwidth).  Every pinned value is identical in the meta-database (o_coeff / o_std_err), DP75 Table A1, and the package's Output/Table5_TopPanel_Cosponsors.xls and Table5_BottomPanel_PctCosponsorsOpposite.xls.  Optimal bandwidths (25/30/13 in Panel A, 16/24/11 in Panel B, All/Dem/Rep) are printed in the table and given in the RD contexts; they are not pinned.
> PDF version vs published.  The PDF is NBER WP 22488 (August 2016). Its Table 5 has the same number, title ("RD and PS Matching Estimates"), panels, rows and columns as the published Table 5 (DP75 Table A1 reprints the published one).  Differences: (a) column 3 Republicans in both panels — WP 6.857* (3.912), 1,227 bills, 100 sponsors and 5.038 (3.850), 1,043, 88; published 6.734* (3.946), 1,200, 98 and 4.428 (3.737), 1,016, 86 (the package reproduces the published values; the WP's column-3 Republican sample is 27 bills / 2 sponsors larger in each panel, consistent with the propensity-score step dropping observations in the published version); (b) column labels — the WP calls columns 3-5 "RD - optimal bandwidth with PS matching" and "PS matching - full sample", the published table "inverse PS-weighting"; the WP text (section 7.1) describes the same inverse-propensity-score weighting.  All other 28 coefficients, SEs and counts are identical.  No pinned value other than claim 2 is in a differing cell.  Table numbering of the other exhibits was not checked against the EJ article (paywalled), and none is pinned.
> What was read.  The NBER WP (all of sections 6-7, Tables 2-5 and the Table 5 notes); DP75 (all 28 pp., EconStor); the meta-database's 123 rows for the paper (team 32); the Zenodo API metadata; the package README.pdf; Dofiles/Table5.do and master.do; the shipped Table 5 .xls output; the column list of the analysis file.
> How the printed numbers are produced (package-only; never in contexts).  Dofiles/Table5.do on Data/AnalysisData/bills_analysis_101-111_replication.dta (63,895 bills; keep if private==0 leaves 62,349; the regression samples are smaller through missing controls).  Outcomes: numb_cosponsors and pct_cosponsors_opposite, which the do-file RECOMPUTES as 100*numb_cosponsors_opposite/(numb_cosponsors+1) (set to missing above 100), overwriting the column of the same name in the data.  Regressor sponsor_female; Congress FE i.v2; party samples sponsor_party==100 (Democrats) / 200 (Republicans); tag_bill==1 (one row per v2 x HRnumber).  Bill characteristics i.minor house_*; sponsor characteristics sponsor_democrat, sponsor_rookie (tenure==1), sponsor_tenure_run, sponsor_age (set missing if >100), leader (comc|comr), ivycoll, black, occ0-occ4, borninstate, tot_bills (bills per sponsor-Congress); district characteristics NE MW WE, pct_black, pct_urban, pct_for_born, pct_age_over65, lninc, lnpden = lnpop - lnarea.  Clusters group_sponsor = group(v2 sponsor_state_abbrev sponsor_district sponsor_term_served); reg ..., robust cluster(group_sponsor).  Bandwidth: rdbwselect_2014 depvar MV1_female, c(0) kernel(uniform), e(h_CCT) (the vendored 2014 CCT selector, on bill-level rows).  Column 2: reg on sponsor_female MV1_female femaleXMV1_female i.v2 within abs(MV1_female)<=h, on the e(sample) of a preliminary mixed_gender_election==1 regression with all controls. Column 3: probit sponsor_female on i.v2 + district characteristics (one row per sponsor, within h), weights 1/p or 1/(1-p), weighted regression adds i.minor house_*.  Columns 4-5: probit on i.v2 + district characteristics + absMV (= abs(MV1_democrat)) (+ sponsor characteristics in col 5) on the full sample, [aw=wt] regression of the outcome on sponsor_female i.v2 i.minor house_*.  "n. sponsors" is e(N_clust).
> Benchmark implications.  The RD columns depend on reproducing Stata's rdbwselect_2014 bandwidth (CCT 2014, uniform kernel) in R; current rdrobust::rdbwselect implements the later selectors, so the bandwidth (and hence claims 2 and 5) may not be reproducible exactly without porting the 2014 routine.  The OLS and full-sample IPW claims need only fixest with weights.  Script-free copy (blind render, 2026-10-21): 128 files withheld — 20 .do, 22 .log, 41 Adofiles (.ado/.mata/.mo/.sthlp by suffix, smcl or Stata content) and 61 __MACOSX ._* stubs — but NONE of Output/: the legacy-Excel Output/Table5_TopPanel_Cosponsors.xls, Table5_BottomPanel_PctCosponsorsOpposite.xls and Table5_Cosponsors.xls (every pinned value, to six decimals) stay in the independent / blind mount, as do the other tables' .xls/.xlsx and the Appendix C .tex. The blind prompt forbids reading result files, but nothing enforces it; review independent and blind passes on this entry for reads of Output/ until the strip rule handles .xls.  The paper text the model sees is the WP, whose column-3 Republican numbers differ from the pinned published ones.
> Left out.  Table 5 cells not pinned (the remaining 21 coefficients and counts, kept to 13 claims), Tables 1-4 and 6-10, Appendix D and the Appendix C simulations; DP75's extended-sample estimates (new data, not in the package).

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `female_sponsor_ncosponsors_all_ols` | 1.395 | 0.628 | Table 5, Panel A (Number of Cosponsors), row All, column 1 (OLS - full sample) | 1.395 | matches |
| 1 | `female_sponsor_ncosponsors_rep_ols` | 3.149 | 1.017 | Table 5, Panel A (Number of Cosponsors), row Republicans, column 1 (OLS - full sample) | 3.149 | matches |
| 2 | `female_sponsor_ncosponsors_rep_rd_ipw` | 6.734 | 3.946 | Table 5, Panel A (Number of Cosponsors), row Republicans, column 3 (RD - optimal bandwidth with inverse propensity score weighting) | 6.734 | matches |
| 3 | `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.124 | 1.04 | Table 5, Panel A (Number of Cosponsors), row Republicans, column 5 (PS weighting - full sample, district + margin of victory + sponsor characteristics) | 3.124 | matches |
| 4 | `female_sponsor_pct_opposite_dem_ols` | -1.505 | 0.419 | Table 5, Panel B (Percent Cosponsors of Opposite Party), row Democrats, column 1 (OLS - full sample) | -1.506 | matches |
| 5 | `female_sponsor_pct_opposite_dem_rd` | -3.351 | 1.91 | Table 5, Panel B (Percent Cosponsors of Opposite Party), row Democrats, column 2 (RD - optimal bandwidth) | -3.351 | matches |
| 6 | `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.208 | 0.525 | Table 5, Panel B (Percent Cosponsors of Opposite Party), row Democrats, column 5 (PS weighting - full sample, district + margin of victory + sponsor characteristics) | -1.208 | matches |
| 7 | `female_sponsor_pct_opposite_rep_ols` | 3.666 | 0.916 | Table 5, Panel B (Percent Cosponsors of Opposite Party), row Republicans, column 1 (OLS - full sample) | 3.666 | matches |
| 8 | `female_sponsor_pct_opposite_rep_ipw_district` | 2.905 | 0.82 | Table 5, Panel B (Percent Cosponsors of Opposite Party), row Republicans, column 4 (PS weighting - full sample, district + margin of victory) | 2.905 | matches |
| 9 | `n_bills_ncosponsors_all_ols` | 60670 | — | Table 5, Panel A, row All, n. bills, column 1 | — | — |
| 10 | `n_sponsor_terms_ncosponsors_all_ols` | 4746 | — | Table 5, Panel A, row All, n. sponsors, column 1 | — | — |
| 11 | `n_bills_pct_opposite_dem_ols` | 32846 | — | Table 5, Panel B, row Democrats, n. bills, column 1 | — | — |
| 12 | `n_bills_pct_opposite_rep_ols` | 27669 | — | Table 5, Panel B, row Republicans, n. bills, column 1 | — | — |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[13/13](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [13/13](independent/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[13/13](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a)<br>[13/13](independent/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) | [7/13](blind/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[9/13](blind/claude-code/2026-10-22-b/CELL.md) (2026-10-22-b)<br>[9/13](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a)<br>[9/13](blind/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) |
| `pipeline-desktop-opus` | [8/13](seeded/pipeline-desktop-opus/20261023T064839Z/CELL.md) (20261023T064839Z) | [13/13](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) (20261023T064839Z) | [12/13](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) |
| `pipeline-desktop-opus-postfix` | — | [13/13](independent/pipeline-desktop-opus-postfix/20261103T070149Z/CELL.md) (20261103T070149Z) | [7/13](blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md) (20261103T062809Z) |
| `pipeline-desktop-opus-run2` | [12/13](seeded/pipeline-desktop-opus-run2/20261023T153400Z/CELL.md) (20261023T153400Z) | [13/13](independent/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) (20261023T152513Z) | [7/13](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |
| `pipeline-desktop-opus-run3` | [11/13](seeded/pipeline-desktop-opus-run3/20261103T054754Z/CELL.md) (20261103T054754Z) | [12/13](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) (20261103T052626Z) | [7/13](blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/claude-code/2026-10-22-b](blind/claude-code/2026-10-22-b/CELL.md) | `female_sponsor_pct_opposite_dem_ipw_sponsor` | -1.75153 | -1.208 | ±0.525 (se_band) | 1.035 | FAIL |
| [seeded/pipeline-desktop-opus/20261023T064839Z](seeded/pipeline-desktop-opus/20261023T064839Z/CELL.md) | `female_sponsor_ncosponsors_rep_ipw_sponsor` | 3.06373 | 3.124 | ±0.06248 (relative) | 0.965 | PASS |
| [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) | `female_sponsor_pct_opposite_dem_rd` | -5.13248 | -3.351 | ±1.91 (se_band) | 0.933 | PASS |
| [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) | `female_sponsor_pct_opposite_dem_rd` | -5.13248 | -3.351 | ±1.91 (se_band) | 0.933 | PASS |
| [blind/claude-code/2026-10-22-b](blind/claude-code/2026-10-22-b/CELL.md) | `female_sponsor_pct_opposite_dem_rd` | -5.13248 | -3.351 | ±1.91 (se_band) | 0.933 | PASS |
| [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) | `female_sponsor_pct_opposite_dem_rd` | -5.13248 | -3.351 | ±1.91 (se_band) | 0.933 | PASS |
| [independent/pipeline-desktop-opus/20261023T064839Z](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) | `female_sponsor_pct_opposite_dem_ols` | -1.89122 | -1.505 | ±0.419 (se_band) | 0.922 | PASS |
| [seeded/claude-code/2026-10-22-a](seeded/claude-code/2026-10-22-a/CELL.md) | `female_sponsor_ncosponsors_rep_rd_ipw` | 6.85691 | 6.734 | ±0.13468 (relative) | 0.913 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261103T054754Z](seeded/pipeline-desktop-opus-run3/20261103T054754Z/CELL.md) | `female_sponsor_ncosponsors_rep_rd_ipw` | 6.85691 | 6.734 | ±0.13468 (relative) | 0.913 | PASS |
| [independent/pipeline-desktop-opus-postfix/20261103T070149Z](independent/pipeline-desktop-opus-postfix/20261103T070149Z/CELL.md) | `female_sponsor_pct_opposite_dem_ols` | -1.88656 | -1.505 | ±0.419 (se_band) | 0.911 | PASS |

### Declared deviations

- [seeded/claude-code/2026-10-22-a](seeded/claude-code/2026-10-22-a/CELL.md) (13/13)
  - rdbwselect_2014 (CCT 2014 bandwidth selector) is not available in the installed rdrobust 4.1.1; it was re-implemented in R from the shipped rdbwselect_2014.ado (p=1, q=2, uniform kernel, nearest-neighbour variance with 3 matches, regularisation on). Stata's compiled helper routines (.mo) could not be read, so the kernel weights and NN variance follow the CCT 2014 formulas, with ties in the matching handled as Stata's minindex() does (all observations at the 4 smallest distinct distances). The bandwidths obtained (e.g. 13.05 for Republicans/cosponsors, 24.53 for Democrats/percent opposite) agree with the paper's rounded values for most rows, and the RD samples match the paper's bill and sponsor counts (1,227/100 and 1,978/167).
  - Stata probit perfect-prediction handling was mimicked: a regressor x for which 'x != 0' perfectly predicts the outcome is dropped along with those observations, and their propensity scores are set to missing (Stata predict default), so those observations drop out of the weighted regressions. The base level of i.v2 is never checked. For Republicans in column 5 this drops black and occ3, which reproduces the paper's 23,818 bills and 1,953 sponsors.
  - Congress (v2) and minor-topic dummies are absorbed as fixed effects in fixest (fixef.rm='none'). The female-sponsor coefficient is identical to Stata reg with i.v2 i.minor; clustered SEs may differ slightly through small-sample corrections.
- [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) (13/13)
  - rdbwselect_2014 (CCT 2014 bandwidth, uniform kernel, p=1, q=2, nn variance with 3 matches) is not in the installed R rdrobust (4.1.1), so it was re-implemented in R from the shipped rdbwselect_2014.ado and kconst.ado; the compiled rdvce .mo could not be read, so the nearest-neighbour variance follows the documented CCT rule (all observations within the 4th-smallest distance including self, Stata minindex tie handling). Bandwidths came out 13.06 (Rep, cosponsors) and 24.74 (Dem, pct opposite), matching the paper's 13 and 24.
  - Stata probit perfect-prediction behaviour emulated by hand: a regressor whose nonzero values predict the outcome perfectly is dropped together with those observations, and (as Stata's predict without 'rules') those observations get a missing propensity score and so drop out of the weighted regression.
- [seeded/pipeline-desktop-opus-run2/20261023T153400Z](seeded/pipeline-desktop-opus-run2/20261023T153400Z/CELL.md) (12/13; failed: `female_sponsor_ncosponsors_rep_rd_ipw`)
  - Propensity scores are set to missing (as Stata's default predict after probit does) for observations excluded by perfect-prediction rules (dropped Congress levels or dropped covariates' nonzero values), so they get no IPW weight
  - RD-IPW propensity probit is estimated on one row per sponsor-Congress drawn from the RD estimation sample (mixed-gender races with complete data, within the bandwidth), rather than on the first row of each sponsor-Congress in the party subsample
  - Propensity-score probit now mimics Stata's perfect-prediction handling for covariates (a regressor whose nonzero values perfectly predict sponsor gender is dropped along with those observations before fitting), not only for Congress dummies
- [seeded/pipeline-desktop-opus-run3/20261103T054754Z](seeded/pipeline-desktop-opus-run3/20261103T054754Z/CELL.md) (11/13; failed: `female_sponsor_ncosponsors_rep_ipw_sponsor`, `female_sponsor_pct_opposite_dem_ipw_sponsor`)
  - plain RD (col 2) uses a CCT/MSE bandwidth selected on all bills of the party subsample; RD+IPW keeps the bandwidth selected on the mixed-gender complete-case sample; the paper does not state this choice
  - IPW (district + indiv + absMV) propensity score estimated once by probit on the pooled sponsor-level sample (both parties, incl. sponsor_democrat) and applied to each party subsample; the paper does not state the pscore estimation sample
  - RD bandwidth (CCT/MSE) selected on the mixed-gender complete-case RD sample rather than on all bills of the party subsample; the paper does not state the bandwidth selection sample
- [independent/claude-code/2026-10-22-a](independent/claude-code/2026-10-22-a/CELL.md) (13/13)
  - RD columns (2)-(3) use the optimal bandwidths reported in the paper (25/30/13 for number of cosponsors, 16/24/11 for percent opposite) rather than the bandwidths from rdrobust::rdbwselect (mserd, bill level), which the script also computes and prints (e.g. 17.8 for Republicans/number of cosponsors, 25.0 for Democrats/percent opposite).
  - Macro-area dummies were built from ICPSR state codes (Northeast 1-14, Midwest 21-37, South 40-56, West 61-82), since no region variable is in the data. Log population density = lnpop - lnarea.
  - Rookie = tenure_run == 1; committee leader = chair (comc) or ranking member (comr); occupation dummies occ1-occ5 (unknown and miscellaneous form the base); total bills sponsored = count of bills per sponsor-Congress in the analysis file.
  - Percent of cosponsors from the opposite party = 100 * pct_cosponsors_opposite, set to 0 for bills with no cosponsors.
  - Propensity scores come from logits estimated at the bill level within each party subsample. The full-sample IPW columns use district characteristics + \|MV1_democrat\| (+ sponsor characteristics in column 5). The RD+IPW score uses district characteristics only, within the bandwidth. Weights are 1/p for female sponsors and 1/(1-p) for male sponsors.
  - fixest drops one fixed-effect singleton (minor topic), so N is 1 lower than the paper's for some cells (60669 vs 60670).
- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (13/13)
  - RD bandwidths fixed at the paper-reported CCT optimal bandwidths (13 for Republican cosponsors, 24 for Democratic percent-opposite); rdbwselect (mserd, triangular, p=1, bill level) recomputed 17.8 and 25.0 and is printed for reference.
  - Percent of opposite-party cosponsors set to 0 for bills with zero cosponsors (the CSV has it missing there; Table 5 Panel B Ns imply it was 0) and scaled to percentage points; one bill with a fraction above 1 set to missing.
  - Constructed controls not in the CSV: rookie = tenure 1; committee leader = chair or ranking member (comc\|comr); total bills sponsored = count of bills per sponsor-Congress in the file; 4 macro regions (Northeast, Midwest, South, West) from ICPSR state codes; log population density = lnpop - lnarea; occupational dummies occ1-occ5 (occ0 and occ6 omitted); independent-party dummy alongside the Republican dummy.
  - Propensity scores: logit with Congress fixed effects estimated at bill level; ATE inverse-probability weights 1/p for women and 1/(1-p) for men. The margin of victory of the elected candidate = 100*\|MV1_democrat\|. For RD+IPW the score uses district characteristics within the bandwidth.
  - Sponsor-Congress clusters = Congress x sponsor name x state x district (4741 in the all-sponsor OLS against 4746 in the paper).
  - RD bandwidths fixed at the paper-reported CCT optimal bandwidths (CCT bandwidths recomputed and printed for reference)
- [independent/claude-code/2026-11-02-c](independent/claude-code/2026-11-02-c/CELL.md) (13/13)
  - Percent of opposite-party cosponsors constructed as 100*numb_cosponsors_opposite/(numb_cosponsors+1) per the paper's footnote 11, not the dataset's pct_cosponsors_opposite (which divides by numb_cosponsors).
  - RD bandwidths fixed at the values reported in the paper (13 for Republican cosponsors, 24 for Democratic percent opposite) rather than recomputed; current rdrobust MSE bandwidths (19.7 and 9.5) are printed for reference. Uniform kernel, linear in the margin with slopes differing by side.
  - Propensity scores: bill-level logit of the female dummy (no Congress FE), ATE inverse-probability weights 1/p and 1/(1-p); observations perfectly predicted by a binary covariate dropped as Stata's logit would. Column 3 PS on district characteristics within the bandwidth; columns 4/5 on district characteristics + \|MV1_democrat\| (+ sponsor characteristics in column 5).
  - Macro areas = Census regions (Northeast, Midwest, South; West omitted); log population density = lnpop - lnarea; rookie = tenure_run==1; committee leader = chair or ranking member; occupational dummies occ1-occ5; total bills sponsored counted per sponsor-Congress in the data.
  - fixest dropped one singleton fixed-effect observation, so the all-sponsor OLS uses 60,669 bills (paper 60,670; the complete-case sample is exactly 60,670 bills, 4,746 sponsor-terms).
- [independent/pipeline-desktop-opus/20261023T064839Z](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) (13/13)
  - Democratic sponsor-characteristics propensity score uses ATT weights (treated 1, controls p/(1-p)) as in matching on the treated; the paper text does not specify the weighting scheme
- [independent/pipeline-desktop-opus-postfix/20261103T070149Z](independent/pipeline-desktop-opus-postfix/20261103T070149Z/CELL.md) (13/13)
  - dem IPW pct outcome capped at 100 (1 rows above 100)
- [independent/pipeline-desktop-opus-run2/20261023T152513Z](independent/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) (13/13)
  - Dem pct-opposite matching estimate uses ATT propensity-score reweighting (treated weight 1, controls p/(1-p)) with full OLS controls in the outcome equation; exact matching estimator not specified in the provided text
- [independent/pipeline-desktop-opus-run3/20261103T052626Z](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) (12/13; failed: `female_sponsor_pct_opposite_dem_ipw_sponsor`)
  - Dem sponsor-PS IPW uses ATT weights (controls ps/(1-ps)) and only the sponsor controls listed in the paper (drops black, borninstate); paper does not specify weighting scheme
- [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) (7/13; failed: `female_sponsor_pct_opposite_dem_ols`, `female_sponsor_pct_opposite_dem_ipw_sponsor`, `female_sponsor_pct_opposite_rep_ols`, `female_sponsor_pct_opposite_rep_ipw_district`, `n_bills_pct_opposite_dem_ols`, `n_bills_pct_opposite_rep_ols`)
  - Data: AnalysisData/bills_analysis_101-111_replication.csv, restricted to public bills (private==0) with non-missing sponsor info; listwise deletion on all regressors.
  - Percent opposite-party cosponsors uses the dataset's pct_cosponsors_opposite (verified = opposite/number of cosponsors, missing when a bill has zero cosponsors) times 100, not opposite/(cosponsors+1) as described in the working-paper text.
  - Constructed variables not in the file: rookie = tenure_run==1; committee leader = chair or ranking member (comc\|comr); total bills sponsored = count of public bills per sponsor-Congress in the file; census macro areas (Northeast base; Delaware coded South) from ICPSR state codes; log population density = lnpop - lnarea; sponsor-Congress cluster = Congress x state x district x term_served.
  - Occupation entered as 6 dummies (occ1-occ6, occ0 base) since the file has 7 categories, not the 5 dummies stated in the notes.
  - Bill characteristics: 33 committee-of-referral dummies as regressors plus minor-topic fixed effects; Congress fixed effects; fixest drops FE singletons (as reghdfe does).
  - RD bandwidths taken from the task context (13 pp for Rep #cosponsors RD-IPW, 24 pp for Dem percent-opposite RD) rather than recomputed with CCT 2014 (rdbwselect_2014 not available in R); uniform kernel, linear with separate slopes in MV1_female.
  - Propensity scores: probit of sponsor_female on district characteristics (macro areas, % black, % urban, % foreign born, % over 65, log median income, log density) plus Congress dummies, estimated at bill level separately by party; col 4 adds \|MV1_democrat\|*100 (margin of victory of the winner); col 5 further adds sponsor characteristics (age, tenure, rookie, leader, black, Ivy, born in state, bills sponsored, occupation dummies). ATE weights 1/p for women and 1/(1-p) for men; no trimming. Lagged Democratic share and campaign spending ratio not used (lagged share entirely missing in Congresses 101, 103, 108).
- [blind/claude-code/2026-10-22-b](blind/claude-code/2026-10-22-b/CELL.md) (9/13; failed: `female_sponsor_pct_opposite_dem_ols`, `female_sponsor_pct_opposite_dem_ipw_sponsor`, `n_bills_pct_opposite_dem_ols`, `n_bills_pct_opposite_rep_ols`)
  - Percent of opposite-party cosponsors: used the dataset's pct_cosponsors_opposite, which equals opposite-party cosponsors / cosponsors (sponsor not in the denominator, missing for bills with zero cosponsors), multiplied by 100. The paper's text describes the denominator as cosponsors plus sponsor; the shipped variable was used as the authors' constructed outcome.
  - Propensity scores estimated by probit at the bill level (the paper's text does not say probit vs logit); ATE inverse-probability weights (1/p for women, 1/(1-p) for men). PS estimated separately within each party sample.
  - RD columns use the bandwidths stated in the task for these rows (13 for Republicans Panel A col 3; 24 for Democrats Panel B col 2), uniform kernel, linear in the margin with slope differing at the threshold. CCT mserd bandwidths recomputed on bills (17.79 and 16.45) are printed as diagnostics only.
  - Column 3 PS: district characteristics only (3 region dummies, % black, % over 65, % foreign born, % urban, log median income, log population density), estimated within the bandwidth; outcome regression adds Congress FE and bill characteristics.
  - Columns 4/5 PS: district characteristics + margin of victory of the elected candidate (\|MV1_democrat\|) (+ sponsor characteristics in col 5); bills with missing MV1_democrat dropped.
  - Macro regions built from ICPSR state codes (Northeast <20, Midwest 20-39, South 40-59, West 60+). Log population density = lnpop - ln(area in sq. miles); lnarea is stored in square meters for Congresses 108-111 (and a few earlier districts) and was converted to square miles.
  - Occupational dummies: occ1-occ5 (education, lawyer, professional, business, agriculture), with unknown and miscellaneous as base. Party dummy entered as factor of sponsor_party (Dem/Rep/independent) in the pooled sample. Total bills sponsored = count of bills per sponsor-Congress in the sample with a matched sponsor.
  - Minor topic and Congress absorbed as fixed effects (fixest); fixest drops fixed-effect singletons (1 bill in the all-sponsor OLS), as reghdfe would. Clusters: sponsor-Congress (Congress x state x district x seat order).
  - percent of opposite-party cosponsors uses the dataset's pct_cosponsors_opposite (opposite/cosponsors, sponsor not in denominator) x100; propensity scores are probit at bill level with ATE inverse-probability weights; RD bandwidths are the ones stated for these rows (13, 24) with a uniform kernel.
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (9/13; failed: `female_sponsor_pct_opposite_dem_ols`, `female_sponsor_pct_opposite_dem_ipw_sponsor`, `n_bills_pct_opposite_dem_ols`, `n_bills_pct_opposite_rep_ols`)
  - RD bandwidths: used the bandwidths stated in the task context for these rows (13 pp for Republican number of cosponsors, 24 pp for Democratic percent opposite-party) rather than my own rdbwselect (mserd, nn vce) output, which gave 17.8 and 16.5; uniform kernel (linear regression within the bandwidth, separate slopes each side).
  - Propensity scores estimated by logit at the race (sponsor-Congress) level, ATE inverse-probability weights (1/p treated, 1/(1-p) controls), no trimming. Full-sample PS logits include Congress dummies; the within-bandwidth RD PS logit (district characteristics only) does not, because the sample is small (107 races).
  - Margin of victory of the elected candidate = \|MV1_democrat\|. Log population density = lnpop - lnarea. Macro areas = 4 regions from ICPSR state codes (3 dummies). Occupation dummies occ1-occ5 (occ0 unknown and occ6 misc as base). Committee leader = chair or ranking member (comc\|comr). Rookie = tenure 1. Total bills sponsored counted per sponsor-Congress in the bill file. Party dummy (Democrat) only in pooled regressions.
  - Percent opposite-party cosponsors: the dataset's pct_cosponsors_opposite x 100 (missing for bills with zero cosponsors, which therefore drop). Minor topic and Congress absorbed as fixed effects with singleton removal (mimicking reghdfe); 33 committee-of-referral dummies as regressors; listwise deletion on covariates. SEs clustered by sponsor-Congress.
- [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) (9/13; failed: `female_sponsor_pct_opposite_dem_ols`, `female_sponsor_pct_opposite_dem_ipw_sponsor`, `n_bills_pct_opposite_dem_ols`, `n_bills_pct_opposite_rep_ols`)
  - Data: bills_analysis_101-111_replication.dta; sample = public bills (private==0 or missing) with sponsor information; pct opposite is the file's pct_cosponsors_opposite (opposite/cosponsors, missing with zero cosponsors) x100.
  - Macro-area dummies (3) built from Census regions of the sponsor's state; log population density = lnpop - lnarea; rookie = tenure_run==1; committee leader = comc or comr; occupation dummies occ1-occ5; total bills sponsored counted per sponsor-Congress in the data.
  - Bill characteristics: 33 house_* committee-of-referral dummies plus minor-topic fixed effects; Congress fixed effects; fixest with singleton removal (reghdfe-style); SEs clustered by sponsor-Congress (v2 x state x district x term_served).
  - RD: mixed-gender races, linear in MV1_female with separate slopes, uniform kernel, bandwidth fixed at the paper-stated optimal values (13 pp Rep number of cosponsors, 24 pp Dem pct opposite); rdrobust mserd bandwidths printed for information only (17.79, 16.45).
  - Propensity scores: bill-level logits within the party sample; RD-IPW on district characteristics within bandwidth; full-sample IPW on district characteristics + winner margin \|MV1_democrat\| (+ sponsor characteristics in column 5); ATE weights 1/p, 1/(1-p).
  - macro-area dummies built from Census regions of the sponsor state; log population density = lnpop - lnarea; rookie = tenure 1; committee leader = chair or ranking member; total bills sponsored counted per sponsor-Congress in the data; singletons dropped (reghdfe-style).
  - RD bandwidths fixed at the paper-stated optimal values (13 pp Rep ncosp, 24 pp Dem pct opposite) with uniform kernel; IPW uses ATE weights 1/p and 1/(1-p) from a bill-level logit.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- seeded: `female_sponsor_ncosponsors_rep_rd_ipw` — pipeline 1/3, agent 2/2
- seeded: `female_sponsor_pct_opposite_dem_ipw_sponsor` — pipeline 1/3, agent 2/2
- blind: `female_sponsor_pct_opposite_dem_rd` — pipeline 1/4, agent 4/4
- blind: `female_sponsor_pct_opposite_rep_ols` — pipeline 1/4, agent 3/4

## Cells

### seeded · claude-code · 2026-10-22-a

[`seeded/claude-code/2026-10-22-a/CELL.md`](seeded/claude-code/2026-10-22-a/CELL.md) — final 13/13, re-scored 13/13; first scored 11/13; executions 5; 2026-10-22T03:08:00Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 5; 2026-11-02T19:41:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261023T064839Z

[`seeded/pipeline-desktop-opus/20261023T064839Z/CELL.md`](seeded/pipeline-desktop-opus/20261023T064839Z/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 2; 2026-10-23T06:48:39Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T153400Z

[`seeded/pipeline-desktop-opus-run2/20261023T153400Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T153400Z/CELL.md) — final 12/13, re-scored 12/13; first scored 11/13; executions 4; 2026-10-23T15:34:00Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261103T054754Z

[`seeded/pipeline-desktop-opus-run3/20261103T054754Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261103T054754Z/CELL.md) — final 11/13, re-scored 11/13; first scored 11/13; executions 4; 2026-11-03T05:47:54Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### independent · claude-code · 2026-10-22-a

[`independent/claude-code/2026-10-22-a/CELL.md`](independent/claude-code/2026-10-22-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-10-22T03:10:46Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T04:30:29Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · claude-code · 2026-11-02-c

[`independent/claude-code/2026-11-02-c/CELL.md`](independent/claude-code/2026-11-02-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-02T20:05:00Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261023T064839Z

[`independent/pipeline-desktop-opus/20261023T064839Z/CELL.md`](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) — final 13/13, re-scored 13/13; first scored 7/13; executions 4; 2026-10-23T06:48:39Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix · 20261103T070149Z

[`independent/pipeline-desktop-opus-postfix/20261103T070149Z/CELL.md`](independent/pipeline-desktop-opus-postfix/20261103T070149Z/CELL.md) — final 13/13, re-scored 13/13; first scored 10/13; executions 3; 2026-11-03T07:01:49Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T152513Z

[`independent/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T152513Z/CELL.md) — final 13/13, re-scored 13/13; first scored 7/13; executions 3; 2026-10-23T15:25:13Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261103T052626Z

[`independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) — final 12/13, re-scored 12/13; first scored 7/13; executions 4; 2026-11-03T05:26:26Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### blind · claude-code · 2026-10-22-a

[`blind/claude-code/2026-10-22-a/CELL.md`](blind/claude-code/2026-10-22-a/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 3; 2026-10-22T03:21:43Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### blind · claude-code · 2026-10-22-b

[`blind/claude-code/2026-10-22-b/CELL.md`](blind/claude-code/2026-10-22-b/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 3; 2026-10-22T03:29:30Z; from `claude-code-blind-rerun-2026-10-22-b.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-11-02T04:24:44Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · claude-code · 2026-11-02-c

[`blind/claude-code/2026-11-02-c/CELL.md`](blind/claude-code/2026-11-02-c/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 3; 2026-11-02T20:17:30Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261023T062931Z

[`blind/pipeline-desktop-opus/20261023T062931Z/CELL.md`](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix · 20261103T062809Z

[`blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md`](blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 1; 2026-11-03T06:28:09Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261103T010557Z

[`blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 2; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

