# shared overlay plotting function used by the paper figure scripts

plotOverlayedRuns <- function(folders, colors, varName, CIsToPlot,
															drawMedian=TRUE, titlePrepend='',
															xlab='Year', xlim=NULL, ylim=NULL, drawCIOutline=TRUE,
															vars=varsToPlot, lwd=1.5, drawDefaultRun=FALSE, ...) {
	# a variable need not be present in every folder, e.g. when it was only
	# introduced in a later FRIDA version. Folders lacking it are left out of the
	# panel, the others are still drawn.
	available <- file.exists(file.path(folders, paste0(varName, varNameExtra)))
	varData <- vector('list', length(folders))
	varData[available] <- lapply(folders[available], function(f) {
		readRDS(file.path(f, paste0(varName, varNameExtra)))
	})

	# determine axis limits from the first folder that has the variable
	if (is.null(xlim)) {
		xlim <- if (any(available)) {
			as.numeric(range(varData[[which(available)[1]]]$years))
		} else {
			c(0, 1)
		}
	}
	if (is.null(ylim)) {
		if (!is.null(vars[[varName]]$ylim)) {
			ylim <- vars[[varName]]$ylim * vars[[varName]]$scale
		} else if (any(available)) {
			allBounds <- do.call(rbind, lapply(varData[available], `[[`, 'ciBounds'))
			ylim <- as.numeric(range(allBounds, na.rm=TRUE)) * vars[[varName]]$scale
		} else {
			ylim <- c(0, 1)
		}
	}

	plot(0, 0, type='n', xlab=xlab, ylab=vars[[varName]]$unit,
			 xlim=xlim, ylim=ylim,
			 main=paste0(titlePrepend, vars[[varName]]$name),
			 xaxs='i', yaxs='i', xaxt='n', yaxt='n')
	# the tick positions are worked out before anything is drawn, so that the grid
	# can be put exactly where the tick marks end up. grid() draws at the default
	# tick positions, which are not the ones nTicks asks for
	ax <- axTicks(1)
	nTicks <- vars[[varName]]$nTicks
	ay <- if (is.null(nTicks)) axTicks(2) else seq(par('usr')[3], par('usr')[4],
																								 length.out=nTicks)
	abline(v=ax, col='lightgray', lty='dotted')
	abline(h=ay, col='lightgray', lty='dotted')
	box()
	abline(h=0, col='gray')
	axis(1, at=ax, labels=FALSE)
	axis(1, at=ax[-c(1, length(ax))], tick=FALSE)
	axis(1, at=ax[1],          labels=ax[1],          tick=FALSE, hadj=0)
	axis(1, at=ax[length(ax)], labels=ax[length(ax)], tick=FALSE, hadj=1)
	axis(2, at=ay, labels=ay, gap.axis=0)

	# filled CI bands
	for (o.i in which(available)) {
		dat <- varData[[o.i]]
		for (CItoPlot.i in seq_along(CIsToPlot)) {
			CItoPlot  <- CIsToPlot[CItoPlot.i]
			CIboundQs <- c((1-CItoPlot)/2, 1-(1-CItoPlot)/2)
			varLength <- nrow(dat$ciBounds)
			polygon(
				x = c(-9999, dat$years, 9999, 9999, rev(dat$years), -9999),
				y = c(dat$ciBounds[, as.character(CIboundQs[1])][c(1, 1:varLength, varLength)],
							rev(dat$ciBounds[, as.character(CIboundQs[2])])[c(1, 1:varLength, varLength)]) * vars[[varName]]$scale,
				col    = adjustcolor(colors[o.i], alpha.f=0.2/CItoPlot.i),
				border = NA,
				lwd    = lwd/2
			)
		}
	}

	# CI outlines
	if (drawCIOutline) {
		for (o.i in which(available)) {
			dat <- varData[[o.i]]
			for (CItoPlot.i in seq_along(CIsToPlot)) {
				CItoPlot  <- CIsToPlot[CItoPlot.i]
				CIboundQs <- c((1-CItoPlot)/2, 1-(1-CItoPlot)/2)
				varLength <- nrow(dat$ciBounds)
				polygon(
					x = c(-9999, dat$years, 9999, 9999, rev(dat$years), -9999),
					y = c(dat$ciBounds[, as.character(CIboundQs[1])][c(1, 1:varLength, varLength)],
								rev(dat$ciBounds[, as.character(CIboundQs[2])])[c(1, 1:varLength, varLength)]) * vars[[varName]]$scale,
					col    = NA,
					border = adjustcolor(colors[o.i], alpha.f=1/CItoPlot.i),
					lwd    = lwd/2/CItoPlot.i
				)
			}
		}
	}

	# medians
	if (drawMedian) {
		for (o.i in which(available)) {
			dat <- varData[[o.i]]
			lines(dat$years,
						dat$ciBounds[, '0.5'] * vars[[varName]]$scale,
						lwd=lwd, col=adjustcolor(colors[o.i], alpha.f=1))
		}
	}

	# the frida default run, for figures showing the fit rather than the spread
	if (drawDefaultRun) {
		for (o.i in which(available)) {
			dat <- varData[[o.i]]
			lines(dat$years, dat$defaultRun * vars[[varName]]$scale,
						lwd=lwd, col=adjustcolor(colors[o.i], alpha.f=1))
		}
	}

	# lets the caller build a legend from the runs that actually got drawn
	invisible(available)
}
