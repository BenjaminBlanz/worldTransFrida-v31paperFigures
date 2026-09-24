# builds the paper figures from the runs, or their digests, in dataLocation, see
# config.R. The runs themselves are made with runFRIDAv3-1PaperScenarios.R.

source('config.R')

# the paper figures, numbered as in the paper
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

# results ####
cat('=== results\n')
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
											'Neither the runs nor their digests are in %s.\n'),
							 paste(resultLabels[!resultsAvailable], collapse=', '), dataLocation),
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
