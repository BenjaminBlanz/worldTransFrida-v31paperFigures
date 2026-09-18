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

# run status ####
statusFileOf <- function(scenarioName) {
	file.path(dataLocation, scenarios[[scenarioName]]$dir, 'status')
}

readStatusFile <- function(statusFile) {
	if (file.exists(statusFile)) {
		readChar(statusFile, file.info(statusFile)$size - 1)
	} else {
		'not started'
	}
}

# TRUE or FALSE, NA where squeue cannot be asked. The submit script names the job
# after the run folder.
slurmJobExists <- function(jobName) {
	out <- tryCatch(suppressWarnings(system2('squeue', c('-h', '-u', Sys.getenv('USER'),
																											 '-n', shQuote(jobName), '-o', '%i'),
																					 stdout=TRUE, stderr=TRUE)),
									error=function(e) NULL)
	exitCode <- attr(out, 'status')
	if (is.null(out) || (!is.null(exitCode) && exitCode != 0)) {
		return(NA)
	}
	length(out) > 0
}

# 'stale' for a run whose status file says submitted or started but that has no
# job in SLURM: it was cancelled or killed before it could write a final status.
# The file is read again after asking SLURM, a job that ended in between has
# written its final status by then.
scenarioStatus <- function(scenarioName) {
	statusFile <- statusFileOf(scenarioName)
	status <- readStatusFile(statusFile)
	if (status %in% c('submitted', 'started') &&
			isFALSE(slurmJobExists(scenarios[[scenarioName]]$dir))) {
		status <- readStatusFile(statusFile)
		if (status %in% c('submitted', 'started')) {
			status <- 'stale'
		}
	}
	status
}

staleMessage <- function(scenarioName) {
	sprintf(paste0('Scenario %s run is stale: its status file says it is queued or running,\n',
								 '  but SLURM has no job for it, so it was cancelled or killed.\n',
								 '  Delete %s to resubmit it.\n'),
					scenarioName, statusFileOf(scenarioName))
}

# the submit script writes the status file before calling sbatch. A failed
# submission leaves no job behind, so its status file goes again.
submitScenario <- function(scenarioName) {
	deployScenarioFile(scenarioName)
	exitCode <- system(scenarios[[scenarioName]]$call)
	if (exitCode != 0) {
		unlink(statusFileOf(scenarioName))
		setwd(homeWD)
		stop(sprintf('Submitting scenario %s failed with exit code %i, see the output above\n',
								 scenarioName, exitCode))
	}
}

# run scenarios ####
# if they don't already exist

## EMB ####
scenarioName <- 'EMB'
setwd(uncertaintyWD)
status <- scenarioStatus(scenarioName)
cat(sprintf('EMB status: %s\n', status))
if (status == 'stale') {
	setwd(homeWD)
	stop(staleMessage(scenarioName))
}
if (status == 'not started') {
	submitScenario(scenarioName)
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
	statuses[scenarioName] <- scenarioStatus(scenarioName)
}
print(statuses)
for (scenarioName in names(scenarios)) {
	if (statuses[scenarioName] == 'not started') {
		submitScenario(scenarioName)
		statuses[scenarioName] <- 'submitted'
		cat(sprintf('Scenario %s run has been submitted to SLURM, please restart this script once the run has completed\n', scenarioName))
	}
}
for (scenarioName in names(scenarios)) {
	if (is.na(statuses[scenarioName])) {
		statuses[scenarioName] <- 'not started'
	}
	if (statuses[scenarioName] == 'failed') {
		cat(sprintf('Scenario %s run has failed, please check the LOG and then delete the status file\n', scenarioName))
	} else if (statuses[scenarioName] == 'stale') {
		cat(staleMessage(scenarioName))
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
