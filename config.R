# config.R — shared configuration for run and plot scripts

homeWD <- getwd()

# identifiers and paths ####
numSample          <- "100000"
expIDprePreString  <- 'UA-v3-1-2026-08-18'
likeCutoffRatio    <- 1000
varNameExtra       <- '-fit uncertainty-completeEqually-weighted.RDS'
commonDirStringBit <- '-ClimateFeedback_On-ClimateSTAOverride_Off'
uncertaintyWD      <- '/work/uc1275/u244021/WorldTransFrida-Uncertainty-FRIDA-development/'
dataLocation       <- file.path(uncertaintyWD, 'workOutput')

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
							 '-h', 7,
							 '--pol', 'policy_EMB.csv',
							 '--cfb', 'ClimateFeedback_On.csv',
							 '--sta', 'ClimateSTAOverride_Off.csv',
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
							 '-h', 7,
							 '--pol', paste0(scenario_name, '.csv'),
							 '--cfb', 'ClimateFeedback_On.csv',
							 '--sta', 'ClimateSTAOverride_Off.csv',
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
