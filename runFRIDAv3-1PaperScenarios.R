homeWD <- getwd()
numSample <- "100000"
expIDprePreString <- 'UA-v3_1-paper'
likeCutoffRatio <- 1000

varNameExtra <- '-fit uncertainty-completeEqually-weighted.RDS'
commonDirStringBit <- '-ClimateFeedback_On-ClimateSTAOverride_Off'
uncertaintyWD <- '/home/benjamin/mnt/levante/work/uc1275/u244021/WorldTransFrida-Uncertainty-main/'
dataLocation <- file.path(uncertaintyWD,'workOutput')

scenario_files <- list.files("ScenarioFiles", pattern = "\\.csv$", full.names = TRUE)

# define Scenarios ####
scenarios <- list(
	'EMB'= list(
		dir=paste0(expIDprePreString,
							 '-S',numSample,'-policy_EMB',commonDirStringBit),
		beauty_name = 'EMB',
		col='black',
		areaCol='gray',
		lty=1,
		call=paste('./submit_UncertaintyAnalysisLevante.sh',
							 '-n',numSample,
							 '-h',7,
							 '--pol','policy_EMB.csv',
							 '--cfb','ClimateFeedback_On.csv',
							 '--sta','ClimateSTAOverride_Off.csv',
							 '-s',expIDprePreString,
							 '--outputType','RDS',
							 '--sym','Min',
							 '--cpps','false',
							 '--cpsp','false')
	)
)

for (scenario_file in scenario_files) {
  file_path <- scenario_file
  file_name <- basename(scenario_file)
  scenario_name <- tools::file_path_sans_ext(file_name)
  scenarios[[scenario_name]] <- list(
  	beauty_name =  scenario_name,
  	dir=paste0(expIDprePreString,
  						 '-S',numSample,'-',scenario_name,
  						 commonDirStringBit),
  	call=paste('./submit_UncertaintyAnalysisLevante.sh',
  						 '-n',numSample,
  						 '-h',7,
  						 '--pol',paste0(policy,'.csv'),
  						 '--cfb','ClimateFeedback_On.csv',
  						 '--sta','ClimateSTAOverride_Off.csv',
  						 '-s',expIDprePreString,
  						 '--outputType','RDS',
  						 '--sym','Min',
  						 '--cpps','true',
  						 '--cpsp','true',
  						 '--cid',scenarios[['EMB']]$dir)
  )
}

# run scenarios ####
# if they don't already exist

## EMB ####
scenarioName <- 'EMB'
setwd(uncertaintyWD)
statusFile <- file.path(dataLocation,scenarios[[scenarioName]]$dir,'status')
if(file.exists(statusFile)){
	status <- readChar(statusFile,file.info(statusFile)$size-1)
} else {
	status <- 'not started'
}
cat(sprintf('EMB status: %s\n',status))
if(status=='not started'){
	system(scenarios[[scenarioName]]$call)
	setwd(homeWD)
	stop(sprintf('Scenario %s run has been submitted to SLURM, please restart this script once the baseline run has completed\n',scenarioName))
}
setwd(homeWD)
if(status=='failed'){
	stop('Baseline run has failed, please check the LOG and then delete the status file\n')
} else if(status!='completed'){
	stop('Baseline run has not completed yet. Run this script again once it has completed.\n')
} else {
	cat('Baseline completed continuing\n')
}

## others ####
statuses <- c()
setwd(uncertaintyWD)
for(scenarioName in names(scenarios)){
	statusFile <- file.path(dataLocation,scenarios[[scenarioName]]$dir,'status')
	if(file.exists(statusFile)){
		statuses[scenarioName] <- readChar(statusFile,file.info(statusFile)$size-1)
	} else {
		statuses[scenarioName] <- 'not started'
	}
}
print(statuses)
for(scenarioName in names(scenarios)){
	if(statuses[scenarioName]=='not started'){
		system(scenarios[[scenarioName]]$call)
		statuses[scenarioName] <- 'submitted'
		writeLines(statuses[scenarioName],file.path(dataLocation,scenarios[[scenarioName]]$dir,'status'))
		cat(sprintf('Scenario %s run has been submitted to SLURM, please restart this script once the run has completed\n',scenarioName))
	}
}
for(scenarioName in names(scenarios)){
	if(is.na(statuses[scenarioName])){
		statuses[scenarioName] <- 'not started'
	}
	if(statuses[scenarioName]=='failed'){
		cat(sprintf('Scenario %s run has failed, please check the LOG and then delete the status file\n',scenarioName))
	} else {
		cat(sprintf('Scenario %s run is %s.\n',scenarioName,statuses[scenarioName]))
	}
}
setwd(homeWD)
if(sum(statuses=='completed')==length(statuses)){
	cat('All runs completed continuing.\n')
} else {
	stop('Not all runs complete, please restart this script when all runs are completed.\n')
}
