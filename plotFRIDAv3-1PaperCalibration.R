source('config.R')
source('plotOverlayedRunsFun.R')

# calibration figure: the frida default run against the data it was fitted to,
# over the historical period. Add entries to varsToPlot to get more panels.

# overlay config ####
overlayNames  <- c('v3.1')
overlayColors <- unname(paperCols[overlayNames])
dataFolders   <- unname(resultFolders[overlayNames])

lwd    <- 1.5
calCol <- 'red'          # the calibration data FRIDA was fitted to
calPch <- 20

# vars ####
# ylim is given in raw data units, it gets multiplied by scale when plotting.
# nTicks forces the number of y tick marks, pick an ylim that divides evenly by
# nTicks - 1 to keep the labels round
varsToPlot <- list(
	fertilizer_demand_total_yearly_demand = list(
		name   = 'Fertilizer Demand',
		unit   = 'Mt N / year',
		scale  = 1,
		ylim   = c(75, 150),
		nTicks = 4
	)
)

# only variables that were actually calibrated against data belong here
calSeries <- lapply(names(varsToPlot), function(varName) {
	orig <- readRDS(file.path(dataFolders[1], paste0(varName, varNameExtra)))$varName.orig
	calibrationSeries(orig)
})
names(calSeries) <- names(varsToPlot)
hasCal <- !sapply(calSeries, is.null)
if (any(!hasCal)) {
	cat(sprintf(paste0('WARNING: no calibration data for %s,\n',
										 '  dropped from the figure.\n'),
							paste(sapply(varsToPlot[!hasCal], `[[`, 'name'), collapse=', ')))
	varsToPlot <- varsToPlot[hasCal]
	calSeries  <- calSeries[hasCal]
}
stopifnot(length(varsToPlot) > 0)

# joint plot ####
cat('Plotting calibration figure\n')
setwd(homeWD)
fig.dir  <- file.path('figures', 'multipanel')
fig.w    <- 9
fig.h    <- 6
fig.unit <- 'cm'
fig.res  <- 450
fig.xlim <- c(1980, 2030)
dir.create(fig.dir, FALSE, TRUE)

cal.ncol            <- min(2, length(varsToPlot))
cal.nrow            <- ceiling(length(varsToPlot) / cal.ncol)
cal.legendHeightMult <- 0.3

png(file.path(fig.dir, 'FigureCalibration.png'),
		width=fig.w * cal.ncol, height=fig.h * (cal.nrow + cal.legendHeightMult),
		units=fig.unit, res=fig.res)
layout(
	matrix(c(1:(cal.nrow * cal.ncol), rep(cal.nrow * cal.ncol + 1, cal.ncol)),
				 byrow=TRUE, ncol=cal.ncol),
	widths  = rep(1, cal.ncol),
	heights = c(rep(1, cal.nrow), cal.legendHeightMult)
)
for (var.i in seq_along(varsToPlot)) {
	varName <- names(varsToPlot)[var.i]
	cat(sprintf('%3i of %3i : %-30s %i calibration points, %i to %i\n',
							var.i, length(varsToPlot), varsToPlot[[var.i]]$name,
							nrow(calSeries[[varName]]),
							min(calSeries[[varName]]$year), max(calSeries[[varName]]$year)))
	par(mar=c(2, 2.4, 2, 1), mgp=c(1.4, 0.5, 0))
	# no CI bands and no median, this figure is about the fit and not the spread.
	# ylim is left to varsToPlot so that it and nTicks stay in one place
	plotOverlayedRuns(dataFolders, overlayColors, varName, CIsToPlot=numeric(0),
										xlim=fig.xlim, xlab='',
										# a single panel needs no panel letter
										titlePrepend=if (length(varsToPlot) > 1) paste0(letters[var.i], ') ') else '',
										drawMedian=FALSE, drawCIOutline=FALSE,
										drawDefaultRun=TRUE, lwd=lwd)
	points(calSeries[[varName]]$year,
				 calSeries[[varName]]$value * varsToPlot[[varName]]$scale,
				 col=calCol, pch=calPch)
}
par(mar=c(0, 0, 0, 0))
plot(0, 0, type='n', axes=FALSE, xlab='', ylab='')
legend('center',
			 legend=c('calibrated run', 'calibration data'),
			 lty=c('solid', NA), lwd=c(lwd, NA),
			 pch=c(NA, calPch), col=c(overlayColors[1], calCol),
			 # side by side is wider than a one panel figure, so stack them instead
			 cex=1, ncol=if (cal.ncol > 1) 2 else 1)
dev.off()
cat(sprintf('Figure saved to %s\n', file.path(fig.dir, 'FigureCalibration.png')))
