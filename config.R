# config.R — shared configuration for run and plot scripts
#
# Everything that may have to be edited lives in the settings section below.
# The derived section after it builds the scenario list and the result paths out
# of those settings and should not normally have to be touched.

##############################################################################
######## settings                                                   ##########
##############################################################################

# where things live ####
# the working directory on the machine that runs the scenarios. On any other
# machine that tree is reached through localMountPoint instead, see
# onThisMachine() below
uncertaintyWD      <- '/work/uc1275/u244021/WorldTransFrida-Uncertainty-FRIDA-development/'
localMountPoint    <- '/home/benjamin/mnt/levante'
# the v2.1 reference ensemble, which lives outside uncertaintyWD
legacyDataLocation <- '/work/mh0033/b383346/Legacy_WorldTransFrida-Uncertainty/workOutput'
legacyRunDir       <- 'UA_EMBv6Try2_nS100000'
# where a run keeps the data the CI plots are made from, within its run directory
plotDataSubDir     <- file.path('figures', 'CI-plots', 'completeEquallyWeighted', 'plotData')

# run configuration ####
numSample          <- "100000"
expIDprePreString  <- 'UA-v3-1-2026-08-21'
likeCutoffRatio    <- 1000
varNameExtra       <- '-fit uncertainty-completeEqually-weighted.RDS'
# the part of a run directory name that all scenarios share. Mirrors the climate
# feedback and STA override files set below
commonDirStringBit <- '-ClimateFeedback_On-ClimateSTAOverride_Off'

# submit settings ####
# these files have to be present in the FRIDA-configs folder of uncertaintyWD,
# runFRIDAv3-1PaperScenarios.R puts the scenario policy files there
runHours               <- 7
embPolicyFile          <- 'policy_EMB.csv'
climateFeedbackFile    <- 'ClimateFeedback_On.csv'
climateSTAOverrideFile <- 'ClimateSTAOverride_Off.csv'

# scenario sweeps ####
# families of scenarios that sweep a single number, here the carbon tax in
# $/tCO2e that the scenario file ramps to. The capture group picks that number
# out of the scenario name
carbonTaxSweepPatterns <- c(
	'CCS'   = '^v31Doc_CCS_c([0-9]+)$',
	'NoCCS' = '^v31Doc_NoCCS_c([0-9]+)$'
)

# calibration data ####
# the data FRIDA was fitted to, transposed: one row per variable, one column per
# year, followed by metadata columns that are not years
calibrationDataFile <- 'Calibration Data.csv'

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
	'NoCCS'     = '#CC79A7'
)

# colours for several variables overlaid in one panel, e.g. the three fossil
# fuels. Line type cannot carry this once the variables have CI ranges to shade,
# so in such a panel the variables take the colours and the scenario family takes
# the line type instead. Black, brown, ochre.
varOverlayCols <- c('#000000', '#8B4513', '#CC7722')

##############################################################################
######## derived                                                    ##########
##############################################################################

homeWD       <- getwd()
dataLocation <- file.path(uncertaintyWD, 'workOutput')

# scenarios ####
scenarios <- list(
	'EMB' = list(
		dir=paste0(expIDprePreString,
							 '-S', numSample, '-policy_EMB', commonDirStringBit),
		beauty_name='EMB',
		col='black',
		areaCol='gray',
		lty=1,
		call=paste('./submit_UncertaintyAnalysisLevante.sh',
							 '-n', numSample,
							 '-h', runHours,
							 '--pol', embPolicyFile,
							 '--cfb', climateFeedbackFile,
							 '--sta', climateSTAOverrideFile,
							 '-s', expIDprePreString,
							 '--outputType', 'RDS',
							 '--sym', 'Min',
							 '--cpps', 'false',
							 '--cpsp', 'false')
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
							 '--outputType', 'RDS',
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
# keeps a path as it is where it exists, and otherwise looks for it below the
# mount point, so the same config works on the run machine and on a local one
onThisMachine <- function(path) {
	if (dir.exists(path)) path else paste0(localMountPoint, path)
}
plotDataFolder <- function(runDir, location=dataLocation) {
	file.path(onThisMachine(location), runDir, plotDataSubDir)
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

# scenario sweeps ####
# one table per sweep family, sorted by the swept value. These are deliberately
# kept out of resultFolders, which runFRIDAv3-1PaperAll.R uses as a hard gate: a
# sweep that is only partly run should leave gaps in its figure and warn about
# them, not stop the whole pipeline.
scenarioSweep <- function(pattern) {
	sweepNames <- grep(pattern, names(scenarios), value=TRUE)
	sweepValue <- as.numeric(sub(pattern, '\\1', sweepNames))
	sweepNames <- sweepNames[order(sweepValue)]
	data.frame(
		value     = sort(sweepValue),
		scenario  = sweepNames,
		folder    = sapply(sweepNames, function(n) plotDataFolder(scenarios[[n]]$dir)),
		row.names = NULL, stringsAsFactors = FALSE
	)
}
carbonTaxSweeps <- lapply(carbonTaxSweepPatterns, scenarioSweep)

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
