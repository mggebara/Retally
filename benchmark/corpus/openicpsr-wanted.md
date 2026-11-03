# openICPSR packages wanted (manual download)

These 33 AEA papers have I4R ground truth (at least 8 paired rows) and an original
replication package that exists only on openICPSR, which needs a login and a terms
click-through, so the harness cannot fetch them (ROADMAP 3.7 item (b); candidates
file of 2026-11-02).

## How to download

1. Create or use a free account at https://www.openicpsr.org (top right, Log In /
   Create Account; any email works, no institution needed).
2. Find each package: open the article's DOI page at aeaweb.org and follow its
   'Replication Package' link, or search https://www.openicpsr.org/openicpsr/search/aea/studies
   by title. The project page is https://www.openicpsr.org/openicpsr/project/<id>/version/V1/view.
3. Click Download (whole project as zip), accept the terms, and save the zip unchanged.
4. Put each zip under `benchmark/manual-packages/<tag>/` in this repo (one folder per
   paper, folder name = the I4R tag below, e.g. `benchmark/manual-packages/T73/`), and
   note the openICPSR project id and version in a `SOURCE.txt` next to it. The folder is
   git-ignored; curation then records `data_access: manual` and the id in the catalog entry.

Priority order is the candidates file's (I4R report available first: T3, T13, T37, T54,
T67, T72, T73, T82, T106), then the rest.

| Tag | Title | Journal | Year | I4R report |
|---|---|---|---|---|
| T3 | Assortative Matching at the Top of the Distribution: Evidence from the World's Most Exclusive Marriage Market | American Economic Journal: Applied Economics | 2022 | https://www.econstor.eu/bitstream/10419/273432/1/I4R-DP047.pdf |
| T8 | Can Information Reduce Ethnic Discrimination? Evidence from Airbnb | American Economic Journal: Applied Economics | 2022 | — |
| T9 | Can Technology Solve the Principal-Agent Problem? Evidence from China's War on Air Pollution | American Economic Review | 2022 | — |
| T13 | Checking and Sharing Alt-Facts | American Economic Journal: Economic Policy | 2022 | https://www.econstor.eu/bitstream/10419/271674/1/I4R-DP034.pdf |
| T14 | Child Marriage Bans and Female Schooling and Labor Market Outcomes: Evidence from Natural Experiments in 17 Low- and Middle-Income Countries | American Economic Journal: Economic Policy | 2022 | — |
| T20 | Do Thank-You Calls Increase Charitable Giving? Expert Forecasts and Field Experimental Evidence | American Economic Journal: Applied Economics | 2023 | — |
| T23 | Does Patient Demand Contribute to the Overuse of Prescription Drugs? | American Economic Journal: Applied Economics | 2022 | — |
| T26 | Enabling or Limiting Cognitive Flexibility? Evidence of Demand for Moral Commitment | American Economic Review | 2023 | — |
| T28 | Evaluating Deliberative Competence: A Simple Method with an Application to Financial Choice | American Economic Review | 2022 | — |
| T37 | How Do Beliefs about the Gender Wage Gap Affect the Demand for Public Policy? | American Economic Journal: Economic Policy | 2022 | https://econpapers.repec.org/paper/zbwi4rdps/12.htm |
| T44 | Interaction, Stereotypes, and Performance: Evidence from South Africa | American Economic Review | 2022 | — |
| T48 | Local Elites as State Capacity: How City Chiefs Use Local Information to Increase Tax Compliance in the Democratic Republic of the Congo | American Economic Review | 2022 | — |
| T50 | Market Access and Quality Upgrading: Evidence from Four Field Experiments | American Economic Review | 2022 | — |
| T53 | Measuring the Welfare Effects of Pride and Shame | American Economic Review | 2022 | — |
| T54 | Mental Health Costs of Lockdowns: Evidence from Age-Specific Curfews in Turkey | American Economic Journal: Applied Economics | 2022 | https://www.econstor.eu/bitstream/10419/268496/1/I4R-DP016.pdf |
| T55 | Mortality, Temperature, and Public Health Provision: Evidence from Mexico | American Economic Journal: Economic Policy | 2022 | — |
| T56 | Motivated Beliefs and Anticipation of Uncertainty Resolution | American Economic Review: Insights | 2022 | — |
| T67 | Political Turnover, Bureaucratic Turnover, and the Quality of Public Services | American Economic Review | 2022 | https://www.econstor.eu/bitstream/10419/272772/1/I4R-DP039.pdf |
| T71 | Rebel on the Canal: Disrupted Trade Access and Social Conflict in China, 1650–1911 | American Economic Review | 2022 | — |
| T72 | Recessions, Mortality, and Migration Bias: Evidence from the Lancashire Cotton Famine | American Economic Journal: Applied Economics | 2022 | https://ideas.repec.org/p/zbw/i4rdps/25.html |
| T73 | Reshaping Adolescents' Gender Attitudes: Evidence from a School-Based Experiment in India | American Economic Review | 2022 | — |
| T75 | School Spending and Student Outcomes: Evidence from Revenue Limit Elections in Wisconsin | American Economic Journal: Economic Policy | 2022 | — |
| T80 | Student Performance, Peer Effects, and Friend Networks: Evidence from a Randomized Peer Intervention | American Economic Journal: Economic Policy | 2023 | — |
| T82 | Targeting High Ability Entrepreneurs Using Community Information: Mechanism Design in the Field | American Economic Review | 2022 | https://www.econstor.eu/bitstream/10419/274139/1/I4R-DP049.pdf |
| T84 | Technological Change and the Consequences of Job Loss | American Economic Review | 2023 | — |
| T85 | The Common-Probability Auction Puzzle | American Economic Review | 2023 | — |
| T91 | The Labor Market Impacts of Universal and Permanent Cash Transfers: Evidence from the Alaska Permanent Fund | American Economic Journal: Economic Policy | 2022 | — |
| T93 | The Long-Term Effects of Measles Vaccination on Earnings and Employment | American Economic Journal: Economic Policy | 2022 | — |
| T98 | The Relative Efficiency of Skilled Labor across Countries: Measurement and Interpretation | American Economic Review | 2022 | — |
| T99 | The Side Effects of Immunity: Malaria and African Slavery in the United States | American Economic Journal: Applied Economics | 2022 | — |
| T102 | Vulnerability and Clientelism | American Economic Review | 2022 | — |
| T103 | Wage Cyclicality and Labor Market Sorting | American Economic Review: Insights | 2022 | — |
| T106 | When a Doctor Falls from the Sky: The Impact of Easing Doctor Supply Constraints on Mortality | American Economic Review | 2023 | https://www.econstor.eu/bitstream/10419/274552/1/I4R-DP053.pdf |
