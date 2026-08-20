source('config.R')

# scenario file deployment ####
# the runs read their policy file from the FRIDA-configs folder of the uncertainty
# working directory, so the file named by the --pol argument of a call has to be
# put there before the run is submitted
fridaConfigsDir  <- file.path(uncertaintyWD, 'FRIDA-configs')
scenarioFilesDir <- file.path(homeWD, 'ScenarioFiles')

polFileOfCall <- function(call) {
	callParts <- strsplit(call, ' ', fixed=TRUE)[[1]]
	polIdx <- which(callParts == '--pol')
	if (length(polIdx) != 1 || polIdx == length(callParts)) {
		stop(sprintf('Could not determine the --pol argument of the call\n%s\n', call))
	}
	callParts[polIdx + 1]
}

deployScenarioFile <- function(scenarioName) {
	polFile <- polFileOfCall(scenarios[[scenarioName]]$call)
	src <- file.path(scenarioFilesDir, polFile)
	dst <- file.path(fridaConfigsDir, polFile)
	if (!dir.exists(fridaConfigsDir)) {
		stop(sprintf('FRIDA config folder %s does not exist\n', fridaConfigsDir))
	}
	if (!file.exists(src)) {
		# policy files that are not among this paper's scenario files, such as the
		# EMB baseline, are expected to already be in place
		if (file.exists(dst)) {
			cat(sprintf('Scenario file %s already in %s\n', polFile, fridaConfigsDir))
			return(invisible(dst))
		}
		stop(sprintf('Scenario file %s found neither in %s nor in %s\n',
									 polFile, scenarioFilesDir, fridaConfigsDir))
	}
	if (!file.copy(src, dst, overwrite=TRUE)) {
		stop(sprintf('Could not copy %s to %s\n', src, dst))
	}
	cat(sprintf('Scenario file %s copied to %s\n', polFile, fridaConfigsDir))
	invisible(dst)
}

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
	deployScenarioFile(scenarioName)
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
		deployScenarioFile(scenarioName)
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
