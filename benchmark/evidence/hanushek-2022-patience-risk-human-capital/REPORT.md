# Evidence report: hanushek-2022-patience-risk-human-capital

**Patience, Risk-Taking, and Human Capital Investment across Countries** — Eric A. Hanushek, Lavinia Kinne, Philipp Lergetporer, Ludger Woessmann

- Paper: https://hanushek.stanford.edu/sites/default/files/Hanushek%2BKinne%2BLergetporer%2BWoessmann%202022%20EJ%20132%28646%29.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/273433/1/I4R-DP048.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/hanushek-2022-patience-risk-human-capital.yaml`
- Data access: public

> Pinned values (kept out of every context): Table 1 col 3 patience 1.226 (0.132) and risk-taking -1.241 (0.184); col 1 patience 0.917 (0.127); col 2 risk-taking -0.482 (0.261); col 5 natives 1.296 (0.133) and -1.320 (0.189), N 1,751,822; full-sample N 1,992,276.  Table 2 col 3 patience 0.931 (0.116) and risk-taking -0.294 (0.122); col 1 patience 0.779 (0.115); col 4 patience 1.032 (0.133) and risk-taking -0.449 (0.140); migrant N 80,398.  All are printed to three decimals.  Left out: Table 1 cols 4 and 6-8 and Table 2 cols 2 and 5-9 (other preferences, migrants-only and effort controls, language subsamples), the subsample-difference rows, R2s, Tables 3-4, the country-level R2 of Figure 1 (0.672, from a figure), and the appendix.
> Dropped claim: Table 1 col 6 (migrants) patience 0.702 (0.172).  The independent cross-check below gives 0.698 (0.169) and risk-taking -0.371 (0.221) against the printed -0.370 (0.225), with the same N (192,736).  That is within one SE but outside the 2 % band.  The cause was not traced (possibly weight precision in the CSV export, or collinearity handling of the migration flags).  DP 48 reports the Stata run reproduces it.
> What was read.  The published EJ PDF (all 18 pp.: Tables 1-4, text, footnotes); I4R DP 48 (EconStor, 20 pp., incl. Tables A1-A3); the meta-database's 95 rows; the Dataverse and DataCite API metadata for both package DOIs; the whole package listing (downloaded with the project downloader to .cache/datasets/, never committed); README.docx; 0_masterfile.do and the Table 1-2 sections of 3_analysis_crosscountry.do and 3_analysis_migrants.do; the CSV headers.
> Independent cross-check (not the package code: pyfixest on the .csv copies of the working data).  It reproduces every pinned value at the printed precision.  Table 1 (pisa_full_gps_final.csv, 1,992,276 rows, 49 countries): col 1 0.917 (0.127); col 2 -0.482 (0.261); col 3 1.226 (0.132) / -1.241 (0.184); col 5 1.296 (0.133) / -1.320 (0.189), N 1,751,822.  Table 2 (pisa_full_gps_final_imcoo.csv): col 1 0.779 (0.115); col 2 0.183 (0.210); col 3 0.931 (0.116) / -0.294 (0.122); col 4 1.032 (0.133) / -0.449 (0.140).  pyfixest drops one singleton observation (N 80,397); Stata's reg keeps it, hence the printed 80,398.
> Package structure (package-only facts; never in contexts).  Table 1 is `reg pv1math patience risktaking female age migra1 migra2 image imfemale immigra1 i.wave [pw=wgtc], vce(cluster country)` on Data/Working/pisa_full_gps_final.dta.  The dependent variable is pv1math, the FIRST plausible value divided by 100, and wgtc is the equal-country-weight sampling weight.  Natives are migra0==1 (migra1/migra2 dropped); migrants are migra0==0.  Table 2 is `reg pv1math coo_patience coo_risktaking female age imfemale image coo_oecd i.countrywave, vce(cluster coo)` on Data/Working/pisa_full_gps_final_imcoo.dta.  It is UNWEIGHTED (no pweight; the paper's Table 2 notes do not mention weights), and countrywave is the 180 residence-country-by-wave cells.  Column 4 adds coo_posrecip coo_negrecip coo_altruism coo_trust.  The 0_masterfile.do path is a hard-coded Windows G:\ drive; outputs go to Results\ via outreg2 (ssc).  The full cross-country file is 2.5 GB as .dta and 3.0 GB as .csv: a reproduction must read only the needed columns (haven col_select / data.table select) or memory will be the binding constraint.
> What could not be verified.  The do-files were not run (no Stata), and the cross-check is an independent re-estimate.  Whether the Dataverse 1.0 zip is byte-identical to the openICPSR E153101V2 deposit that DP 48 used was not checked: openICPSR needs a login. Both carry the same title, and DP 48's reproduction of every table is consistent with the Dataverse data reproducing the pinned values above.
> Curation check (2026-11-02, zero cost).  I ran `benchmark.runner --llm-oracle curation-check --only hanushek-2022-patience-risk-human-capital` once in --mode blind and once in --mode independent.  Both cells stopped as llm_answer_pending on the first call, the methodology summary, with 0 API calls.  That prompt embeds the paper text, Tables 1-2 included, by design.  It carried no package script text, file names or claim tokens.  The project downloader fetched Dataverse 1.0 and recorded the version in metadata.json.  The strip rule withholds the 21 .do files (script-suffix) and nothing else.  The kept README.docx and six .xlsx inputs contain no pinned value, and Results/ is empty.  The blind code-generation prompt is checked by tests/test_blind_prompt.py (passes).
> Original analysis in Stata 15 (21 do-files).  language is r, the reproduction target (the pipeline translates Stata originals to R).

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `table1_col3_patience` | 1.226 | 0.132 | Table 1, column (3) Full sample, Patience | 1.226 | matches |
| 1 | `table1_col3_risk_taking` | -1.241 | 0.184 | Table 1, column (3) Full sample, Risk-taking | -1.241 | matches |
| 2 | `table1_col1_patience` | 0.917 | 0.127 | Table 1, column (1) Full sample, Patience | 0.917 | matches |
| 3 | `table1_col2_risk_taking` | -0.482 | 0.261 | Table 1, column (2) Full sample, Risk-taking | -0.482 | matches |
| 4 | `table1_col5_natives_patience` | 1.296 | 0.133 | Table 1, column (5) Natives, Patience | 1.296 | matches |
| 5 | `table1_col5_natives_risk_taking` | -1.32 | 0.189 | Table 1, column (5) Natives, Risk-taking | -1.32 | matches |
| 6 | `table1_col3_observations` | 1.99228e+06 | — | Table 1, column (3), Observations | 1.99228e+06 | matches |
| 7 | `table2_col3_patience` | 0.931 | 0.116 | Table 2, column (3) Full sample, Patience (country-of-origin) | 0.931 | matches |
| 8 | `table2_col3_risk_taking` | -0.294 | 0.122 | Table 2, column (3) Full sample, Risk-taking (country-of-origin) | -0.294 | matches |
| 9 | `table2_col1_patience` | 0.779 | 0.115 | Table 2, column (1) Full sample, Patience (country-of-origin) | 0.779 | matches |
| 10 | `table2_col4_patience` | 1.032 | 0.133 | Table 2, column (4) Full sample, Patience (country-of-origin) | 1.032 | matches |
| 11 | `table2_col4_risk_taking` | -0.449 | 0.14 | Table 2, column (4) Full sample, Risk-taking (country-of-origin) | -0.449 | matches |
| 12 | `table2_col3_observations` | 80398 | — | Table 2, column (3), Observations | 80398 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [13/13](independent/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](independent/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[13/13](independent/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) | [13/13](blind/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](blind/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[13/13](blind/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261102T141403Z/CELL.md) (20261102T141403Z) | [9/13](independent/pipeline-desktop-opus/20261102T141403Z/CELL.md) (20261102T141403Z) | [12/13](blind/pipeline-desktop-opus/20261102T095147Z/CELL.md) (20261102T095147Z) |
| `pipeline-desktop-opus-postfix` | — | [9/13](independent/pipeline-desktop-opus-postfix/20261103T063758Z/CELL.md) (20261103T063758Z) | [9/13](blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md) (20261103T062809Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) (20261102T152052Z) | [9/13](independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md) (20261102T190406Z) | [9/13](blind/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) (20261102T152052Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) | [13/13](independent/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) (20261103T004800Z) | [9/13](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) (20261103T004800Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-desktop-opus/20261102T095147Z](blind/pipeline-desktop-opus/20261102T095147Z/CELL.md) | `table1_col3_risk_taking` | -1.08571 | -1.241 | ±0.184 (se_band) | 0.844 | PASS |
| [independent/claude-code/2026-11-02-b](independent/claude-code/2026-11-02-b/CELL.md) | `table2_col3_risk_taking` | -0.194 | -0.294 | ±0.122 (se_band) | 0.820 | PASS |
| [independent/claude-code/2026-11-02-c](independent/claude-code/2026-11-02-c/CELL.md) | `table2_col3_risk_taking` | -0.194 | -0.294 | ±0.122 (se_band) | 0.820 | PASS |
| [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) | `table2_col3_risk_taking` | -0.194001 | -0.294 | ±0.122 (se_band) | 0.820 | PASS |
| [independent/pipeline-desktop-opus-run3/20261103T004800Z](independent/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) | `table2_col3_risk_taking` | -0.194001 | -0.294 | ±0.122 (se_band) | 0.820 | PASS |
| [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) | `table2_col3_risk_taking` | -0.194001 | -0.294 | ±0.122 (se_band) | 0.820 | PASS |
| [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) | `table2_col3_risk_taking` | -0.194001 | -0.294 | ±0.122 (se_band) | 0.820 | PASS |
| [blind/pipeline-desktop-opus-run2/20261102T152052Z](blind/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) | `table2_col3_risk_taking` | -0.205689 | -0.294 | ±0.122 (se_band) | 0.724 | PASS |
| [blind/pipeline-desktop-opus/20261102T095147Z](blind/pipeline-desktop-opus/20261102T095147Z/CELL.md) | `table1_col5_natives_risk_taking` | -1.19398 | -1.32 | ±0.189 (se_band) | 0.667 | PASS |
| [independent/pipeline-desktop-opus/20261102T141403Z](independent/pipeline-desktop-opus/20261102T141403Z/CELL.md) | `table2_col3_risk_taking` | -0.231388 | -0.294 | ±0.122 (se_band) | 0.513 | PASS |

### Declared deviations

- [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Table 1 (pisa_full_gps_final.dta, 2.47 GB) cannot be read in full through the read-only mount within the 300 s sandbox limit (raw I/O roughly 5-15 MB/s; fread select= on the 2.8 GB CSV and haven col_select on the .dta both timed out). The final script parses the Stata 118 file directly, reading only the 14 needed columns from evenly spread blocks of 3000 consecutive rows (van der Corput order) until a 225 s deadline: 1,965,000 of 1,992,276 rows (98.6%), all 49 countries. Table 1 coefficients are therefore estimated on that subsample.
  - table1_col3_observations is the .dta header row count (1,992,276), reported because no row read has a missing regression variable; it is not the N of the subsample regression (1,965,000). — names `table1_col3_observations`
  - Table 1 standard errors are clustered on the country-level (patience, risk-taking) pair (49 distinct values) instead of the country string, which is a Stata strL that the direct parser does not decode. Coefficients are unaffected.
  - Table 2 uses the full migrant file (pisa_full_gps_final_imcoo.dta read with haven col_select) with no deviation: reg pv1math prefs female age imfemale image coo_oecd i.countrywave, cluster(coo) as feols(... \| countrywave, cluster=~coo, fixef.rm='none'); image is constant (0) in this sample and drops for collinearity, as in Stata.
  - Table 1 estimated on 1965000 of 1992276 student rows (98.6%): the 2.47 GB pisa_full_gps_final.dta cannot be read through the mount within the 300 s sandbox limit, so the script parses the Stata file directly and reads only the needed columns from 655 evenly spread blocks of 3000 consecutive rows until a time deadline.
  - Table 1 standard errors are clustered on the country-level (patience, risk-taking) pair (49 distinct values) because the country variable is a Stata strL that the direct parser does not decode; coefficients are unaffected.
  - table1_col3_observations is the row count in the .dta header (N), reported because none of the rows read has a missing regression variable; the regression itself used only the subsample. — names `table1_col3_observations`
- [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) (13/13)
  - Read only the 14 columns needed for Table 1 (and 14 for Table 2) via data.table::fread(select=) from the CSV forms of pisa_full_gps_final and pisa_full_gps_final_imcoo instead of the .dta files; all rows kept.
  - read only the 14 columns used by the Table 1 regressions from the CSV form of pisa_full_gps_final (column subsetting, all rows kept) to fit the sandbox time/memory limits
- [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Only the needed columns of the PISA files were read (data.table::fread select=); the replicate weights and other variables were skipped.
  - Table 1 (cols 1, 2, 3, 5) is estimated on an evenly spread block sample (about 20% of the rows, 0.5 MB blocks visited in van der Corput order until a 228 s time budget ran out) of Replication/Data/CSV/pisa_full_gps_final.csv. The full 3 GB file cannot be read through the read-only mount within the 300 s sandbox limit (measured raw throughput about 5-8 MB/s). All 49 countries and 253 of 263 country-waves are in the sample. Within each country-wave the sampled students' wgtc weights are rescaled to that cell's full weight (1/#waves of the country), keeping equal weight per country. The sample is timing-dependent, so a rerun can draw a slightly different subset.
  - table1_col3_observations is the observation count read from the <N> tag of the pisa_full_gps_final.dta header (1,992,276) times the complete-case share in the block sample (1.0); it is not the N of the sample regression. It is printed with %.6g as 1.99228e+06. — names `table1_col3_observations`
  - The preference measures are used as supplied in the data files (patience, risktaking, coo_* variables). These appear to be GPS measures z-standardised at the individual level in the analytical sample and then collapsed to the country level. They were not re-standardised across students.
  - Table 2 weights are the supplied student weight wgt (sampling weights normalised per residence country-wave), unchanged. Singletons are kept (fixef.rm='none'), so N = 80,398. Table 2 SEs are clustered by country of origin, Table 1 SEs by country.
  - Table 1 estimated on an evenly spread block sample of 19.9% of pisa_full_gps_final.csv (1180 of 5938 0.5 MB blocks, 395484 students) because the 3 GB file cannot be read through the mount within the 300 s sandbox limit (~6 MB/s); only the needed columns were parsed
  - table1_col3_observations is the row count in the .dta header (1992276) times the complete-case share in the block sample (1.00000); the sample regression itself used 395484 students — names `table1_col3_observations`
- [independent/claude-code/2026-11-02-b](independent/claude-code/2026-11-02-b/CELL.md) (13/13)
  - Read only the needed columns of Replication/Data/CSV/pisa_full_gps_final.csv with data.table::fread(select=) to fit the 300 s sandbox limit; no rows dropped (N = 1,992,276).
  - Natives (Table 1 col 5) defined as migra0 == 1 (1,751,822 students); students with imputed (fractional) migration status are excluded from the native subsample, so the migration controls drop out as described.
  - Table 2 standard errors clustered by country of origin (as in the text); coefficients unaffected.
  - read only the 16 needed columns of pisa_full_gps_final.csv (CSV form) for speed; no rows dropped
- [independent/claude-code/2026-11-02-c](independent/claude-code/2026-11-02-c/CELL.md) (13/13)
  - Read pisa_full_gps_final in its CSV form with data.table::fread(select=) on only the needed columns, because of the sandbox's time and memory limits; all 1,992,276 rows kept.
  - Used the first plausible value only (pv1math, already divided by 100). GPS preferences used as shipped in the data files (country-level values; not re-standardised by me).
  - Table 1: weights wgtc (sum to 1 per country, so each country gets equal weight); controls female, age, migra1, migra2, imfemale, image, immigra0-2; wave FE; clustered by country. Natives = migra0==1.
  - Table 2: weights wgt; controls female, age, coo_oecd, imfemale, image; country-by-wave FE (countrywave); clustered by country of origin. fixest dropped 1 singleton observation (N 80,397 vs 80,398).
  - read the CSV form of pisa_full_gps_final with data.table::fread(select=) on only the columns needed (sandbox time/memory limits); all rows kept
  - first plausible value (pv1math, already /100) only; GPS preference variables used as provided in the data files (country-level, standardised as shipped)
- [independent/pipeline-desktop-opus/20261102T141403Z](independent/pipeline-desktop-opus/20261102T141403Z/CELL.md) (9/13; failed: `table2_col3_patience`, `table2_col1_patience`, `table2_col4_patience`, `table2_col4_risk_taking`)
  - Migrant regressions weight students by sampling weights scaled to give each residence country equal total weight in the full PISA sample (not re-equalised within the migrant subsample)
- [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Full PISA file pisa_full_gps_final.dta (1,992,276 rows, 2.5 GB) cannot be read through the mount within the 300 s sandbox limit (~5-10 MB/s; a full CSV fread and a full chunked read both timed out in exploration). Table 1 is estimated on a systematic 50% subsample: 3000-row blocks every 6000 rows (all 333 blocks read; every country hit, 49 countries, 253 of the country-waves), read with haven::read_dta(col_select, skip, n_max) so only needed columns are kept. wgtc weights are renormalised within country-wave so every country keeps equal total weight and equal weight per wave.
  - table1_col3_observations = full-file row count (from the .dta header) times the complete-case share of loaded rows; exploratory reads of all 1,992,276 rows (attempts 5 and 6) found no missing values in any regression variable. — names `table1_col3_observations`
  - The data contain only raw country-level GPS means for residence countries. The paper's individual-level z-standardisation in the 49-country sample is reconstructed as SD = sqrt(mean within-country GPS variance + variance of country means), with within-country SDs from patience_sd/risktaking_sd in the migrant file (43 of 49 countries matched; others get the mean within variance). Validated on the 58 origin countries, where it reproduces the migrant file's own coo_patience/coo_risktaking standardisation slope to <1%.
  - Table 2 uses the migrant file's already-standardised coo_* preferences, residence country-by-wave fixed effects, weights wgt (the student sampling weight in that file), controls female, age, coo_oecd, imfemale, image, SEs clustered by country of origin. A singleton country-wave observation is kept (fixef.rm = none; coefficients unaffected).
  - Table 1 controls: female, age, migra1, migra2 (migration status, mean-imputed where missing), imputation dummies imfemale, image, immigra0, wave fixed effects; SEs clustered by country. Natives (col 5) = students with observed native status (migra0 == 1 and immigra0 == 0); students with imputed migration status are excluded from the natives subsample. image is dropped as collinear in the 50% subsample (no imputed ages loaded).
  - full PISA file (1992276 rows, 2.5 GB) cannot be read through the mount within the 300 s sandbox limit (~10 MB/s); Table 1 is estimated on a systematic subsample of 996276 rows (50.0%): 3000-row blocks every 6000 rows, 333 of 333 blocks read; only the needed columns are loaded (haven col_select); sampling weights wgtc are renormalised within country-wave so each country keeps equal total weight and equal weight per wave.
  - table1_col3_observations is the full-file row count times the complete-case share of the loaded rows (no missing values were found in any regression variable in exploratory reads of all rows). — names `table1_col3_observations`
  - the data hold only country-level GPS means; the individual-level z-standardisation in the 49-country sample is reconstructed with the within-country GPS SDs of the migrant file (validated on the 58 origin countries, where it reproduces the file's own standardisation slope to <1%).
- [blind/claude-code/2026-11-02-b](blind/claude-code/2026-11-02-b/CELL.md) (13/13)
  - Read only the needed columns of the 2.8 GB pisa_full_gps_final.csv with data.table::fread(select=) to fit the sandbox limits; all rows kept.
  - Math achievement uses the first plausible value only (pv1math, already divided by 100 in the data).
  - Preference measures are the dataset's prepared country-level GPS variables (patience, risktaking; coo_* for origin), used as provided; individual GPS data are not in the package, so the in-sample z-standardisation could not be redone.
  - Table 2 regressions unweighted (Table 2 notes describe plain least squares, unlike Table 1's weighted regressions); Table 1 weighted by wgtc (sampling weights rescaled to sum to one per country).
  - Table 1 migration-status controls: migra1, migra2 (first/second generation, mean-imputed) plus imputation dummies immigra1, immigra2; natives defined as migra0==1 with non-imputed status.
  - fixest dropped one singleton residence-country-by-wave observation in Table 2, so N is 80,397 of 80,398.
  - Read only the needed columns of the 2.8 GB pisa_full_gps_final.csv (fread select=) to fit the sandbox time/memory limits; all rows kept.
  - Achievement uses the first plausible value only (pv1math, already divided by 100 in the data), not all ten PVs.
  - Preference measures are the dataset's prepared country-level GPS variables (patience, risktaking; coo_* for origin), used as provided (already standardised); individual GPS data are not in the package so the standardisation could not be redone.
  - Table 2 regressions are unweighted (the Table 2 notes describe plain least squares, unlike Table 1's weighted regressions).
- [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) (13/13)
  - pisa_full_gps_final.csv (2.8 GB) read with only the 16 needed columns via data.table::fread(select=); all rows kept
  - GPS preference variables (patience, risktaking, coo_*) used as supplied: they are already z-standardised in the respective analytical sample and collapsed to country level (country-level mean ~0 in each sample); not re-standardised
  - Table 1 natives subsample defined as migra0 == 1, so students with imputed migration status are left out of it
  - Table 1 weights: wgtc (sampling weights rescaled so each country sums to 1); Table 2 weights: the supplied wgt (sampling weights normalised within country-wave over all students). The migrant file has no country-equalised weight
  - Table 2 SEs clustered by country of origin (text, Section 3.1); fixest drops one singleton country-wave observation, so N = 80,397 of the 80,398 rows
  - Table 1 controls: female, age, migra1, migra2, imputation dummies (imfemale, image, immigra0-2), wave FE. Table 2 controls: female, age, coo_oecd, imfemale, image (image is constant 0 there and drops out), residence-country-by-wave FE (countrywave, 180 cells)
  - the 2.8 GB pisa_full_gps_final.csv was read with only the 16 columns the Table 1 models need (fread select=); all rows kept
  - GPS preference variables used as supplied (already z-standardised in the analytical sample and collapsed to country level by the authors); not re-standardised
  - natives defined as migra0 == 1; students with imputed migration status are excluded from the natives subsample
  - Table 2 weights are the supplied sampling weights (wgt, normalised within country-wave over all students); SEs clustered by country of origin

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- independent: `table2_col1_patience` — pipeline 1/4, agent 3/3
- independent: `table2_col3_patience` — pipeline 1/4, agent 3/3
- independent: `table2_col4_patience` — pipeline 1/4, agent 3/3
- independent: `table2_col4_risk_taking` — pipeline 1/4, agent 3/3
- blind: `table2_col1_patience` — pipeline 1/4, agent 3/3
- blind: `table2_col3_patience` — pipeline 1/4, agent 3/3
- blind: `table2_col4_patience` — pipeline 1/4, agent 3/3
- blind: `table2_col4_risk_taking` — pipeline 1/4, agent 3/3

## Cells

### seeded · claude-code · 2026-11-02-a

[`seeded/claude-code/2026-11-02-a/CELL.md`](seeded/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 9/13; executions 6; 2026-11-02T14:22:06Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T19:46:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261102T141403Z

[`seeded/pipeline-desktop-opus/20261102T141403Z/CELL.md`](seeded/pipeline-desktop-opus/20261102T141403Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T14:14:03Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261102T152052Z

[`seeded/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T15:20:52Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261103T010557Z

[`seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### independent · claude-code · 2026-11-02-a

[`independent/claude-code/2026-11-02-a/CELL.md`](independent/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 2/13; executions 5; 2026-11-02T10:08:30Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-b

[`independent/claude-code/2026-11-02-b/CELL.md`](independent/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 2/13; executions 3; 2026-11-02T15:05:26Z; from `claude-code-run2-6papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-c

[`independent/claude-code/2026-11-02-c/CELL.md`](independent/claude-code/2026-11-02-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T20:14:30Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261102T141403Z

[`independent/pipeline-desktop-opus/20261102T141403Z/CELL.md`](independent/pipeline-desktop-opus/20261102T141403Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-11-02T14:14:03Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix · 20261103T063758Z

[`independent/pipeline-desktop-opus-postfix/20261103T063758Z/CELL.md`](independent/pipeline-desktop-opus-postfix/20261103T063758Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-11-03T06:37:58Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261102T190406Z

[`independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261102T190406Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 4; 2026-11-02T19:04:06Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261103T004800Z

[`independent/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-03T00:48:00Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### blind · claude-code · 2026-11-02-a

[`blind/claude-code/2026-11-02-a/CELL.md`](blind/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 10; 2026-11-02T14:17:44Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-b

[`blind/claude-code/2026-11-02-b/CELL.md`](blind/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-02T15:08:35Z; from `claude-code-run2-6papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-c

[`blind/claude-code/2026-11-02-c/CELL.md`](blind/claude-code/2026-11-02-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T20:33:00Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261102T095147Z

[`blind/pipeline-desktop-opus/20261102T095147Z/CELL.md`](blind/pipeline-desktop-opus/20261102T095147Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 1; 2026-11-02T09:51:47Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix · 20261103T062809Z

[`blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md`](blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 1; 2026-11-03T06:28:09Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261102T152052Z

[`blind/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-11-02T15:20:52Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261103T004800Z

[`blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 1; 2026-11-03T00:48:00Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

