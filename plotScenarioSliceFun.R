# plots a slice through a family of scenarios: one point per scenario, taken at a
# fixed year, drawn against the value the family sweeps. The counterpart to
# plotOverlayedRuns, which plots the same ensembles as time series. Kept in the
# same visual language so the panels sit next to those figures.
#
# series is a list of what to draw, each element a list of
#   x        the swept values, e.g. the carbon tax levels
#   ciBounds one row per x, the quantile columns of the plotData RDS
#   col      colour, by convention the scenario family
#   lty      line type, used to tell several variables in one panel apart
# A series with no finished run yet is skipped but keeps its place, so the others
# do not change colour once its results arrive.

plotScenarioSlice <- function(series, CIsToPlot,
															main='', xlab='', ylab='',
															xlim=NULL, ylim=NULL, scale=1,
															drawMedian=TRUE, drawCIOutline=TRUE, lwd=1.5) {
	available <- sapply(series, function(s) length(s$x) > 0)

	if (is.null(xlim)) {
		xlim <- if (any(available)) {
			range(unlist(lapply(series[available], `[[`, 'x')))
		} else {
			c(0, 1)
		}
	}
	if (is.null(ylim)) {
		ylim <- if (any(available)) {
			range(do.call(rbind, lapply(series[available], `[[`, 'ciBounds')), na.rm=TRUE) * scale
		} else {
			c(0, 1)
		}
	}

	plot(0, 0, type='n', xlab=xlab, ylab=ylab, xlim=xlim, ylim=ylim, main=main,
			 xaxs='i', yaxs='i', xaxt='n', yaxt='n')
	grid()
	box()
	abline(h=0, col='gray')
	ax <- axTicks(1)
	axis(1, at=ax, labels=FALSE)
	axis(1, at=ax[-c(1, length(ax))], tick=FALSE)
	axis(1, at=ax[1],          labels=ax[1],          tick=FALSE, hadj=0)
	axis(1, at=ax[length(ax)], labels=ax[length(ax)], tick=FALSE, hadj=1)
	ay <- axTicks(2)
	axis(2, at=ay, labels=ay, gap.axis=0)

	# filled CI bands. Unlike the time series version these are not extended past
	# the axis: the data really does stop at the lowest and highest scenario that
	# has been run, and stretching the band would invent scenarios either side
	for (s.i in which(available)) {
		dat <- series[[s.i]]
		for (CItoPlot.i in seq_along(CIsToPlot)) {
			CItoPlot  <- CIsToPlot[CItoPlot.i]
			CIboundQs <- c((1-CItoPlot)/2, 1-(1-CItoPlot)/2)
			polygon(
				x = c(dat$x, rev(dat$x)),
				y = c(dat$ciBounds[, as.character(CIboundQs[1])],
							rev(dat$ciBounds[, as.character(CIboundQs[2])])) * scale,
				col    = adjustcolor(dat$col, alpha.f=0.2/CItoPlot.i),
				border = NA,
				lwd    = lwd/2
			)
		}
	}

	# CI outlines
	if (drawCIOutline) {
		for (s.i in which(available)) {
			dat <- series[[s.i]]
			for (CItoPlot.i in seq_along(CIsToPlot)) {
				CItoPlot  <- CIsToPlot[CItoPlot.i]
				CIboundQs <- c((1-CItoPlot)/2, 1-(1-CItoPlot)/2)
				polygon(
					x = c(dat$x, rev(dat$x)),
					y = c(dat$ciBounds[, as.character(CIboundQs[1])],
								rev(dat$ciBounds[, as.character(CIboundQs[2])])) * scale,
					col    = NA,
					border = adjustcolor(dat$col, alpha.f=1/CItoPlot.i),
					lwd    = lwd/2/CItoPlot.i
				)
			}
		}
	}

	# medians. A series with a single finished run has no line to draw, so it is
	# marked with a point instead of vanishing from the panel
	if (drawMedian) {
		for (s.i in which(available)) {
			dat <- series[[s.i]]
			if (length(dat$x) > 1) {
				lines(dat$x, dat$ciBounds[, '0.5'] * scale,
							lwd=lwd, lty=dat$lty, col=adjustcolor(dat$col, alpha.f=1))
			} else {
				points(dat$x, dat$ciBounds[, '0.5'] * scale,
							 pch=20, col=adjustcolor(dat$col, alpha.f=1))
			}
		}
	}

	# lets the caller build a legend from the series that actually got drawn
	invisible(available)
}
