source('config.R')
source('plotOverlayedRunsFun.R')

# overlay config ####
overlayNames  <- c('v3.1')
overlayColors <- unname(paperCols[overlayNames])
dataFolders   <- unname(resultFolders[overlayNames])

CIsToPlot      <- c(0.67, 0.95)
lwd            <- 1.5
plt.drawMedian    <- TRUE
plt.drawCIOutline <- TRUE
calCol            <- 'red'          # the calibration data FRIDA was fitted to
calPch            <- 20

# vars ####
varsToPlot <- list(
	fertilizer_demand_total_yearly_demand = list(
		name  = 'Fertilizer Demand',
		unit  = 'Mt N / year',
		scale = 1,
		ylim  = c(50, 200),
		nTicks = 4
	),
	fertilizer_demand_price_of_fertilizer_feedstock = list(
		name  = 'Price of Fertilizer Feedstock',
		unit  = 'trillion 2021 intl. $/year / Mt N',
		scale = 1e-9,
		ylim  = c(0, 4)*1e9
	)
)

# the calibration series of each variable, matched on the original FRIDA name the
# plotData carries. Only some variables were calibrated against data
calSeries <- lapply(names(varsToPlot), function(varName) {
	orig <- readRDS(file.path(dataFolders[1], paste0(varName, varNameExtra)))$varName.orig
	calibrationSeries(orig)
})
names(calSeries) <- names(varsToPlot)

# joint plot ####
cat('Plotting Figure 5\n')
setwd(homeWD)
fig.dir  <- file.path('figures', 'multipanel')
fig.w    <- 9
fig.h    <- 6
fig.unit <- 'cm'
fig.res  <- 450
fig.xlim <- c(1980, 2100)
dir.create(fig.dir, FALSE, TRUE)

fig5.ncol            <- 2
fig5.nrow            <- 1
fig5.legendHeightMult <- 0.3

png(file.path(fig.dir, 'Figure5.png'),
		width=fig.w * fig5.ncol, height=fig.h * (fig5.nrow + fig5.legendHeightMult),
		units=fig.unit, res=fig.res)
layout(
	matrix(c(1:(fig5.nrow * fig5.ncol), rep(fig5.nrow * fig5.ncol + 1, fig5.ncol)),
				 byrow=TRUE, ncol=fig5.ncol),
	widths  = rep(1, fig5.ncol),
	heights = c(rep(1, fig5.nrow), fig5.legendHeightMult)
)
for (var.i in seq_along(varsToPlot)) {
	varName <- names(varsToPlot)[var.i]
	cat(sprintf('%3i of %3i : %-30s calibration data: %s\n', var.i, length(varsToPlot),
							varsToPlot[[var.i]]$name,
							if (is.null(calSeries[[varName]])) 'none' else
								sprintf('%i points, %i to %i', nrow(calSeries[[varName]]),
												min(calSeries[[varName]]$year), max(calSeries[[varName]]$year))))
	par(mar=c(2, 2.4, 2, 1), mgp=c(1.4, 0.5, 0))
	plotOverlayedRuns(dataFolders, overlayColors, varName, CIsToPlot,
										xlim=fig.xlim, xlab='',
										titlePrepend=paste0(letters[var.i], ') '),
										drawMedian=plt.drawMedian,
										drawCIOutline=plt.drawCIOutline)
	if (!is.null(calSeries[[varName]])) {
		points(calSeries[[varName]]$year,
					 calSeries[[varName]]$value * varsToPlot[[varName]]$scale,
					 col=calCol, pch=calPch)
	}
}
par(mar=c(0, 0, 0, 0))
plot(0, 0, type='n', axes=FALSE, xlab='', ylab='')
legend('center',
			 legend=c(overlayNames, 'calibration data'),
			 border=c(overlayColors, NA),
			 fill=c(adjustcolor(overlayColors, 0.2), NA),
			 pch=c(rep(NA, length(overlayNames)), calPch),
			 col=c(rep(NA, length(overlayNames)), calCol),
			 cex=1, ncol=length(overlayNames) + 1)
dev.off()
cat(sprintf('Figure saved to %s\n', file.path(fig.dir, 'Figure5.png')))
