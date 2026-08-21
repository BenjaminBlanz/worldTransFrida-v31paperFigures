# builds the paper figures: first the scenario runs, then every paper figure.
#
# The runs rely on the uncertainty analysis scripts which assume the presence of a 
# SLURM scheduler on the system. The location of the uncertainty script has to be
# specified in the config.R

source('config.R')

scenarioScript <- 'runFRIDAv3-1PaperScenarios.R'
figureScripts  <- sort(list.files('.', pattern='^plotFRIDAv3-1PaperFig[0-9]+\\.R$'))

homeWD <- getwd()
# the scripts share this session, each one sources config.R to initialise itself.
# A script that stops part way through can leave the working directory changed or
# a graphics device open, either of which would break the scripts after it, so
# those two are put back the way they were.
runScript <- function(f) {
	devsBefore <- dev.list()
	on.exit({
		setwd(homeWD)
		for (d in setdiff(dev.list(), devsBefore)) dev.off(d)
	})
	source(f)
}

# scenario runs ####
cat('=== scenario runs\n')
if (dir.exists(uncertaintyWD)) {
	cat(sprintf('%s\n', scenarioScript))
	scenarioErr <- tryCatch({
		runScript(scenarioScript)
		NULL
	}, error=function(e) conditionMessage(e))
	if (!is.null(scenarioErr)) {
		# the runs are not all through yet. The scenario script's own message says
		# what to do, so it stands and nothing gets plotted from incomplete output.
		stop(scenarioErr, call.=FALSE)
	}
} else {
	cat(sprintf(paste0('WARNING: uncertaintyWD %s is not reachable, so this is not the\n',
										 '  machine the scenario runs happen on. Skipping %s and\n',
										 '  continuing with the results that are already available.\n'),
							uncertaintyWD, scenarioScript))
}

# results ####
cat('\n=== results\n')
# v3.1 and EMB are the same run, so report each distinct folder once
resultPaths      <- unique(unname(resultFolders))
resultLabels     <- sapply(resultPaths, function(p) {
	paste(names(resultFolders)[resultFolders == p], collapse=' / ')
})
resultsAvailable <- dir.exists(resultPaths)
for (r.i in seq_along(resultPaths)) {
	cat(sprintf('  %-13s %-8s %s\n', resultLabels[r.i],
							ifelse(resultsAvailable[r.i], 'found', 'MISSING'), resultPaths[r.i]))
}
if (!all(resultsAvailable)) {
	stop(sprintf(paste0('results for %s are not available.\n',
											'Make sure uncertaintyWD (%s) is present on this machine, or mounted\n',
											'below %s, and that the scenarios have been run with %s.\n'),
							 paste(resultLabels[!resultsAvailable], collapse=', '),
							 uncertaintyWD, localMountPoint, scenarioScript),
			 call.=FALSE)
}

# figures ####
cat(sprintf('\n=== building %i figure(s)\n', length(figureScripts)))
figureErrs <- list()
for (f in figureScripts) {
	cat(sprintf('\n--- %s\n', f))
	err <- tryCatch({
		runScript(f)
		NULL
	}, error=function(e) conditionMessage(e))
	if (!is.null(err)) {
		figureErrs[[f]] <- err
		cat(sprintf('FAILED: %s\n', err))
	}
}

cat('\n=== summary\n')
for (f in figureScripts) {
	cat(sprintf('  %-28s %s\n', f, ifelse(is.null(figureErrs[[f]]), 'ok', 'FAILED')))
}
if (length(figureErrs) > 0) {
	stop(sprintf('%i of %i figure script(s) failed\n',
							 length(figureErrs), length(figureScripts)), call.=FALSE)
}
cat(sprintf('All figures written to %s\n', file.path('figures', 'multipanel')))
