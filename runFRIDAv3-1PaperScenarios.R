source('config.R')

# run scenarios ####
# if they don't already exist

## EMB ####
scenarioName <- 'EMB'
setwd(uncertaintyWD)
statusFile <- file.path(dataLocation, scenarios[[scenarioName]]$dir, 'status')
if (file.exists(statusFile)) {
	status <- readChar(statusFile, file.info(statusFile)$size - 1)
} else {
	status <- 'not started'
}
cat(sprintf('EMB status: %s\n', status))
if (status == 'not started') {
	system(scenarios[[scenarioName]]$call)
	setwd(homeWD)
	stop(sprintf('Scenario %s run has been submitted to SLURM, please restart this script once the baseline run has completed\n', scenarioName))
}
setwd(homeWD)
if (status == 'failed') {
	stop('Baseline run has failed, please check the LOG and then delete the status file\n')
} else if (status != 'completed') {
	stop('Baseline run has not completed yet. Run this script again once it has completed.\n')
} else {
	cat('Baseline completed, continuing\n')
}

## others ####
statuses <- c()
setwd(uncertaintyWD)
for (scenarioName in names(scenarios)) {
	statusFile <- file.path(dataLocation, scenarios[[scenarioName]]$dir, 'status')
	if (file.exists(statusFile)) {
		statuses[scenarioName] <- readChar(statusFile, file.info(statusFile)$size - 1)
	} else {
		statuses[scenarioName] <- 'not started'
	}
}
print(statuses)
for (scenarioName in names(scenarios)) {
	if (statuses[scenarioName] == 'not started') {
		system(scenarios[[scenarioName]]$call)
		statuses[scenarioName] <- 'submitted'
		writeLines(statuses[scenarioName], file.path(dataLocation, scenarios[[scenarioName]]$dir, 'status'))
		cat(sprintf('Scenario %s run has been submitted to SLURM, please restart this script once the run has completed\n', scenarioName))
	}
}
for (scenarioName in names(scenarios)) {
	if (is.na(statuses[scenarioName])) {
		statuses[scenarioName] <- 'not started'
	}
	if (statuses[scenarioName] == 'failed') {
		cat(sprintf('Scenario %s run has failed, please check the LOG and then delete the status file\n', scenarioName))
	} else {
		cat(sprintf('Scenario %s run is %s.\n', scenarioName, statuses[scenarioName]))
	}
}
setwd(homeWD)
if (sum(statuses == 'completed') == length(statuses)) {
	cat('All runs completed, continuing.\n')
} else {
	stop('Not all runs complete, please restart this script when all runs are completed.\n')
}
