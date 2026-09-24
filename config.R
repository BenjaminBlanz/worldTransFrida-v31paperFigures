# config.R — shared configuration for run and plot scripts
#
# Everything that may have to be edited lives in the settings section below.
# The derived section after it builds the scenario list and the result paths out
# of those settings and should not normally have to be touched.

##############################################################################
######## settings                                                   ##########
##############################################################################

# where things live ####
# the folder holding the runs, or their digests, see runDir() below. Set it to
# the workOutput of a WorldTransFrida-Uncertainty checkout to plot the runs
# themselves
dataLocation       <- 'data'
# the v2.1 reference ensemble, made in another checkout than the v3.1 runs
legacyDataLocation <- dataLocation
legacyRunDir       <- 'UA_EMBv6Try2_nS100000'
# where a run keeps the data the CI plots are made from, within its run directory
plotDataSubDir     <- file.path('figures', 'CI-plots', 'completeEquallyWeighted', 'plotData')

# run configuration ####
numSample          <- "100000"
expIDprePreString  <- 'UA-v3-1-2026-09-14'
likeCutoffRatio    <- 1000
varNameExtra       <- '-fit uncertainty-completeEqually-weighted.RDS'
# the part of a run directory name that all scenarios share. Mirrors the climate
# feedback and STA override files set below
commonDirStringBit <- '-ClimateFeedback_On-ClimateSTAOverride_Off'

# submit settings ####
# these files have to be present in the FRIDA-configs folder of the uncertainty
# checkout, runFRIDAv3-1PaperScenarios.R puts the scenario policy files there
runHours               <- 2
embPolicyFile          <- 'policy_EMB.csv'
climateFeedbackFile    <- 'ClimateFeedback_On.csv'
climateSTAOverrideFile <- 'ClimateSTAOverride_Off.csv'
# optional: supply a completed EMB run directory name to use as the calibrated
# initial draw (--cid). When set, cpps and cpsp are also enabled for the EMB run
embCID                 <- NULL   # e.g. 'UA-v3-1-2026-08-01-S100000-policy_EMB-ClimateFeedback_On-ClimateSTAOverride_Off'
# running EMB for the first time, i.e. if embCID is false,
# also has to do parm scaling and ranging which takes long
# other scenarios will reuse the sampling points from emb so will run shorter.
embRunHOURS <- 7
# Format(s) of the *final* one file per variable results.
# The per chunk intermediates the workers write are always plain uncompressed
# csv, mergePerVarFiles derives every requested final format from those.
# Outputting csv files only massively reduces the amount of memory needed in the 
# merging step. If enabling RDS files make sure to reduce the number of workers
# used in the merge step.
# Allowed options: 'csv','RDS', or 'both'
perVarOutputTypes <- 'csv'

# data ####
# the input data the figure scripts read, all of it below this folder
dataDir <- 'data'

# the data FRIDA was fitted to, transposed: one row per variable, one column per
# year, followed by metadata columns that are not years
calibrationDataFile <- file.path(dataDir, 'Calibration Data.csv')

# burned area figure: the ISIMIP2a GSWP3 surface temperature anomaly relative to
# preindustrial, and the overburning percentiles of Burton et al. (2024) fig. 3
gswp3TasFile       <- file.path(dataDir, 'gswp3_tas_anom_rel_preindus.csv')
overburnedAreaFile <- file.path(dataDir, 'burton_global_fig3_full.csv')

# time axis of the paper figures ####
# the years the scenario time series are drawn over, and the years labelled on
# their x axis. The first label is aligned left and the last right, so that
# neither sticks out past the axis. The labels therefore have to be spaced wide
# enough that those two still clear their neighbours. The carbon tax figure
# takes its last slice at figYearEnd. The calibration figures show the historical
# period and keep their own range.
figYearStart <- 2025
figYearEnd   <- 2150
figYearTicks <- seq(figYearStart, figYearEnd, by=25)

# paper figure palette ####
# one colour per ensemble, shared by all paper figures so that the same run keeps
# the same colour wherever it appears. The v3.1 EMB baseline is the reference run
# shown in every figure and is always black. Okabe-Ito colours, colourblind safe
# and separated in lightness so the figures survive greyscale print too.
paperCols <- c(
	'v3.1'      = '#000000',
	'EMB'       = '#000000',
	'v2.1'      = '#009E73',
	'Gov. Inv.' = '#0072B2',
	'Insurance' = '#E69F00',
	'CCS'       = '#000000',
	'NoCCS'     = '#CC79A7',
	# single runs out of the two carbon tax sweeps, shown next to EMB. A warm and a
	# cool colour, so the two stay apart where their ranges overlap, and neither
	# taken by another run in the paper figures
	'100$ tax w CCS'   = '#D55E00',
	'100$ tax w/o CCS' = '#56B4E9'
)

# colours for several variables overlaid in one panel, e.g. the three fossil
# fuels. Line type cannot carry this once the variables have CI ranges to shade,
# so in such a panel the variables take the colours and the scenario family takes
# the line type instead. Black, brown, ochre.
varOverlayCols <- c('#000000', '#8B4513', '#CC7722')

##############################################################################
######## derived                                                    ##########
##############################################################################

homeWD <- getwd()

# scenarios ####
scenarios <- list(
	'EMB' = list(
		dir=paste0(expIDprePreString,
							 '-S', numSample, '-policy_EMB', commonDirStringBit),
		beauty_name='EMB',
		col='black',
		areaCol='gray',
		lty=1,
		call=paste(
			'./submit_UncertaintyAnalysisLevante.sh',
			'-n', numSample,
			'-h', embRunHOURS,
			'--pol', embPolicyFile,
			'--cfb', climateFeedbackFile,
			'--sta', climateSTAOverrideFile,
			'-s', expIDprePreString,
			'--outputType', perVarOutputTypes,
			'--sym', 'Min',
			'--cpps', if (!is.null(embCID)) 'true' else 'false',
			'--cpsp', if (!is.null(embCID)) 'true' else 'false',
			if (!is.null(embCID)) paste('--cid', embCID) else '')
	)
)

palette('set2')
scenario_files <- list.files("ScenarioFiles", pattern = "\\.csv$", full.names = TRUE)
for (p.i in seq_along(scenario_files)) {
	scenario_name <- tools::file_path_sans_ext(basename(scenario_files[p.i]))
	scenarios[[scenario_name]] <- list(
		beauty_name=scenario_name,
		col=p.i,
		areaCol=p.i,
		lty=1,
		dir=paste0(expIDprePreString,
							 '-S', numSample, '-', scenario_name,
							 commonDirStringBit),
		call=paste('./submit_UncertaintyAnalysisLevante.sh',
							 '-n', numSample,
							 '-h', runHours,
							 '--pol', paste0(scenario_name, '.csv'),
							 '--cfb', climateFeedbackFile,
							 '--sta', climateSTAOverrideFile,
							 '-s', expIDprePreString,
							 '--outputType', perVarOutputTypes,
							 '--sym', 'Min',
							 '--cpps', 'true',
							 '--cpsp', 'true',
							 '--cid', scenarios[['EMB']]$dir)
	)
}

# derived convenience vectors ####
scenarioCols       <- sapply(scenarios, `[[`, 'col')
scenarioAreaCols   <- sapply(scenarios, `[[`, 'areaCol')
scenarioBeautyNames <- sapply(scenarios, `[[`, 'beauty_name')

# result locations ####
# a run and its digest hold the plot data at the same paths, only the folder
# name differs. Takes the run where it exists and the digest otherwise, e.g.
# runDir('UA_EMBv6Try2_nS100000') gives 'data/UA_EMBv6Try2_nS100000-digest'
runDir <- function(dir, location=dataLocation) {
	d <- file.path(location, dir)
	if (dir.exists(d)) d else paste0(d, '-digest')
}
plotDataFolder <- function(dir, location=dataLocation) {
	file.path(runDir(dir, location), plotDataSubDir)
}

# stops a figure script whose runs are neither in dataLocation nor digested
# there, e.g. requireResults(dataFolders)
requireResults <- function(folders) {
	missing <- folders[!dir.exists(folders)]
	if (length(missing) > 0) {
		stop(sprintf('missing runs, neither the run nor its digest found:\n%s\n',
								 paste(missing, collapse='\n')), call.=FALSE)
	}
}

# the plotData folders the paper figures read, keyed by the overlay names the
# figure scripts use, so a figure gets its folders the same way it gets its
# colours. v3.1 and EMB are the same run and therefore the same folder.
embResultFolder <- plotDataFolder(scenarios[['EMB']]$dir)
resultFolders <- c(
	'v2.1'      = plotDataFolder(legacyRunDir, legacyDataLocation),
	'v3.1'      = embResultFolder,
	'EMB'       = embResultFolder,
	'Gov. Inv.' = plotDataFolder(scenarios[['v31Doc_gov_investment_scenario']]$dir),
	'Insurance' = plotDataFolder(scenarios[['v31Doc_insurance_scenario']]$dir)
)

# calibration data ####
# read once, keeping only the columns whose header is a year. The row names carry
# an index suffix such as [1] while the plotData names carry [*], so the suffix is
# dropped on both sides and the lookup goes by the plain FRIDA variable name.
calibrationTable <- local({
	f <- file.path(homeWD, calibrationDataFile)
	if (!file.exists(f)) {
		# the paper figures need it, the scenario runs do not, so a missing file is
		# only a problem for whoever asks for a series
		return(NULL)
	}
	raw <- read.csv(f, check.names=FALSE, row.names=1, stringsAsFactors=FALSE)
	isYear <- !is.na(suppressWarnings(as.numeric(colnames(raw))))
	tbl <- raw[, isYear, drop=FALSE]
	rownames(tbl) <- sub('\\[[^]]*\\]$', '', rownames(tbl))
	tbl
})

# the calibration series of a variable, given the original FRIDA name that the
# plotData RDS carries in varName.orig. NULL when that variable has no data
calibrationSeries <- function(varName.orig) {
	if (is.null(calibrationTable)) {
		warning(sprintf('%s not found, no calibration data available', calibrationDataFile))
		return(NULL)
	}
	key <- sub('\\[[^]]*\\]$', '', varName.orig)
	if (!key %in% rownames(calibrationTable)) return(NULL)
	value <- suppressWarnings(as.numeric(calibrationTable[key, ]))
	year  <- as.numeric(colnames(calibrationTable))
	ok    <- !is.na(value)
	if (!any(ok)) return(NULL)
	data.frame(year=year[ok], value=value[ok])
}
