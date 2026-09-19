# FRIDA v3.1 overview paper: figures

This repository holds the R scripts behind the figures of the FRIDA v3.1 overview paper.
They set up and submit the scenario ensembles the paper discusses, and draw Figures 1 to 6
from the results.

## Paper

**An overview of FRIDA v3.1: An update to a feedback-based, fully coupled, global
integrated assessment model of climate and humans**

William Schoenberg, Benjamin Blanz, Jefferson K. Rajah, Beniamino Callegari, Christopher
Wells, Theresia B. Putranti, Francisco Mahu, Maria Molina, Alexandre Köberle, Catherine Li,
Wanderson Costa, David Collste, Karel Zwetsloot, Jannes Breier, Lennart Ramme, Chris Smith
and Cecilie Mauritzen

A link to the preprint will be added once it is submitted.

## Figures

Each paper figure has one script, `plotFRIDAv3-1PaperFigN.R`, which writes
`figures/multipanel/FigureN.png`.

| Figure | Script | Shows |
|---|---|---|
| 1 | `plotFRIDAv3-1PaperFig1.R` | Global overburned area as a function of the surface temperature anomaly: quadratic fits to the p10, p50 and p90 overburning of Burton et al. (2024), fig. 3, against the ISIMIP2a GSWP3 temperature anomaly, 1901 to 2019. Uses only the files in `data/`, no model runs. |
| 2 | `plotFRIDAv3-1PaperFig2.R` | The FRIDA v3.1 default run against the data it was calibrated to, 1980 to 2030: fertilizer demand, transportation energy demand and life expectancy at birth. A listed variable without calibration data is dropped from the figure with a warning. |
| 3 | `plotFRIDAv3-1PaperFig3.R` | FRIDA v2.1 and v3.1 ensembles, 2025 to 2150: surface temperature anomaly, GDP per person, population, cropland, forest land, grassland, energy demand and fertilizer use. Median with 67 % and 95 % ranges. |
| 4 | `plotFRIDAv3-1PaperFig4.R` | FRIDA v2.1 and v3.1 ensembles, 2025 to 2150: burned area due to climate change, transportation energy demand, wind energy full load hours and life expectancy. Median with 67 % and 95 % ranges. |
| 5 | `plotFRIDAv3-1PaperFig5.R` | EMB against the 100 $/tCO2e carbon tax runs with and without CCS, 2025 to 2150: surface temperature anomaly, GDP per person, years spent in recession, inflation index, share of energy CO2 captured and stored CO2. Median with 67 % range. |
| 6 | `plotFRIDAv3-1PaperFig6.R` | EMB against the government investment and insurance scenarios, 2025 to 2150: GDP, inflation rate, productivity growth, private consumption, safe and risky interest rates, unemployment rate, private investment, loan failure rate, transfers as share of government expenditure, government expenditure and debt to GDP ratio. Median with 67 % range. |

The scripts `plotFRIDAv3-1PaperFigNotUsed7.R` to `FigNotUsed9.R` draw figures that did not
make it into the paper: the carbon tax sweeps sliced at 2050, 2100 and 2150, fertilizer
demand and feedstock price against calibration data, and a single panel calibration figure.
They write `figures/multipanel/FigureNotUsedN.png` and are not built by
`runFRIDAv3-1PaperAll.R`.

## Scenarios

- **EMB**: the FRIDA v3.1 baseline. It is the v3.1 ensemble in Figures 2 to 4 and the
  reference run in Figures 5 and 6.
- **v2.1**: the FRIDA v2.1 reference ensemble (run `UA_EMBv6Try2_nS100000`), for Figures 3
  and 4.
- **Government investment** (`ScenarioFiles/v31Doc_gov_investment_scenario.csv`): from 2030
  a government run public investment programme with a growth target of 3 % per year,
  financed in equal shares from wage, profit, rent and wealth taxes.
- **Insurance** (`ScenarioFiles/v31Doc_insurance_scenario.csv`): from 2030 loan defaults
  are covered by private, central bank and government insurance, at a coverage level of 70
  phased in over 10 years.
- **Carbon tax sweeps** (`ScenarioFiles/v31Doc_CCS_cX.csv`, `v31Doc_NoCCS_cX.csv`): a tax on
  CO2e emissions that starts in 2030, reaches X <span>$</span>/tCO2e in 2035 and stays there,
  for X = 25 to 500 in steps of 25. In the CCS family the model chooses carbon storage
  endogenously; in the NoCCS family that choice is switched off. Figure 5 uses the two
  100 <span>$</span>/tCO2e runs.
- **CCS** (`ScenarioFiles/v31Doc_ccs_scenario.csv`): prescribed, rising shares of stored
  emissions from coal, oil, gas and biofuel processes. It is run along with the others but
  is not shown in Figures 1 to 6.

## Requirements

- R 4.0 or later. The scripts use base R only.
- **Run data.** The figures (except Figure 1) read the summary data of the ensembles, which
  every run keeps in `figures/CI-plots/completeEquallyWeighted/plotData/` of its run folder.
  The EMB and scenario ensembles will be available for download on Zenodo. The link will be
  added here.
- **Making the runs yourself.** The ensembles are made with the FRIDA uncertainty analysis,
  [WorldTransFrida-Uncertainty](https://github.com/BenjaminBlanz/WorldTransFrida-Uncertainty),
  which runs the model, [WorldTransFRIDA](https://github.com/metno/WorldTransFRIDA), through
  the Stella Simulator. Its README explains the setup. The runs are submitted through SLURM
  (the scripts were written for DKRZ Levante), but a cluster is not required. That
  repository has stand-ins for `sbatch`, `squeue` and `scancel` in `localSlurm/` that run
  the same jobs on a single machine, see
  [Running the same job without SLURM](https://github.com/BenjaminBlanz/WorldTransFrida-Uncertainty#running-the-same-job-without-slurm).
  Put `localSlurm/` in front of your `PATH` before starting R.

## Reproducing the figures

All scripts are run from the repository root.

1. **Tell `config.R` where the run data is.** Whether you downloaded the ensembles or ran
   them yourself, the locations in the settings section of `config.R` have to be adjusted:
   - `uncertaintyWD`: the uncertainty analysis working directory. The run folders are
     expected in its `workOutput/`, e.g.
     `workOutput/UA-v3-1-2026-09-14-S100000-policy_EMB-ClimateFeedback_On-ClimateSTAOverride_Off/`.
     The folder names are built from `expIDprePreString`, `numSample`, the policy file and
     `commonDirStringBit`.
   - `legacyDataLocation` and `legacyRunDir`: where the v2.1 reference ensemble is.
   - `localMountPoint`: where a remote file system with the runs is mounted. A path that
     does not exist on this machine is looked for below it. When you work on the machine
     the ensembles were run on, the paths are simply used as they are.
   - For new runs, also `expIDprePreString`, `runHours` and `embRunHOURS`.
2. **Run everything:**

   ```sh
   Rscript runFRIDAv3-1PaperAll.R
   ```

   If `uncertaintyWD` is reachable, this first runs `runFRIDAv3-1PaperScenarios.R`. That
   script copies the scenario files into the `FRIDA-configs` folder of `uncertaintyWD`,
   submits EMB, and after EMB has finished submits all other scenarios, which reuse EMB's
   calibration. It stops while runs are still missing or in progress. Re-run it until all
   runs are complete. The runner then checks that the EMB, v2.1, government investment
   and insurance results exist, builds Figures 1 to 6 into `figures/multipanel/` and
   reports ok or FAILED for each script.
3. If `uncertaintyWD` is not reachable, the runner skips the runs and plots from the
   results that are available.
4. To produce individual figures run e.g.

   ```sh
   Rscript plotFRIDAv3-1PaperFig3.R
   ```

The time axis and the colour of each ensemble are set once in `config.R` (`figYearStart`,
`figYearEnd`, `figYearTicks`, `paperCols`), so all figures share them.

## Repository layout

| Path | Contents |
|---|---|
| `config.R` | Settings (paths, run configuration, time axis, colours) and the scenario list and result paths derived from them. Every script sources it. |
| `runFRIDAv3-1PaperAll.R` | Runs the scenarios, then builds all paper figures. |
| `runFRIDAv3-1PaperScenarios.R` | Deploys the scenario files and submits the runs that do not exist yet. |
| `plotFRIDAv3-1PaperFigN.R` | One script per paper figure, see [Figures](#figures). |
| `plotOverlayedRunsFun.R` | Draws one time series panel with several ensembles overlaid. |
| `plotScenarioSliceFun.R` | Draws a scenario family at a fixed year against the swept value. |
| `ScenarioFiles/` | Policy files of the scenarios. |
| `data/` | Calibration and observational data, see [Input data](#input-data). |

Two further scripts are not needed for the paper figures. `plotFRIDAv3-1PaperScenarios.R`
draws an overview of all scenarios; it also writes `figures/multipanel/Figure1.png`, so run
it before, not after, the paper figures. `runPlotOverlayedRuns.R` is an older overlay
script that needs `initialise.R` from the uncertainty analysis repository.

## Input data

- `data/Calibration Data.csv`: the data FRIDA v3.1 was calibrated to, used by Figure 2.
- `data/gswp3_tas_anom_rel_preindus.csv`: the ISIMIP2a GSWP3 global surface temperature
  anomaly relative to preindustrial, used by Figure 1.
- `data/burton_global_fig3_full.csv`: global overburning percentiles (p10, p50, p90) from
  Burton et al. (2024), fig. 3, used by Figure 1.

## Code

Benjamin Blanz

## License

This repository is licensed under the
[Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/),
see [`LICENSE`](LICENSE). If you use it, please cite the paper above.
