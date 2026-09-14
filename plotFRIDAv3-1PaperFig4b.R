source('config.R')
source('plotOverlayedRunsFun.R')

# the variables of Figure 4 as time series: instead of slicing the whole carbon
# tax sweep at a few years, the 100 $/tCO2e run of each sweep is followed over
# time next to the EMB baseline.

# overlay config ####
# the two tax runs are sweep runs and so not part of resultFolders, which
# runFRIDAv3-1PaperAll.R requires to be complete, so their folders are looked up
# here. A run without results yet leaves its ensemble out of the panels.
overlayScenarios <- c(
	'EMB'              = 'EMB',
	'100$ tax w CCS'   = 'v31Doc_CCS_c100',
	'100$ tax w/o CCS' = 'v31Doc_NoCCS_c100'
)
overlayNames  <- names(overlayScenarios)
overlayColors <- unname(paperCols[overlayNames])
dataFolders   <- unname(sapply(overlayScenarios, function(s) plotDataFolder(scenarios[[s]]$dir)))

CIsToPlot      <- c(0.67, 0.95)
lwd            <- 1.5
plt.drawMedian    <- TRUE
plt.drawCIOutline <- TRUE

# vars ####
# the rows of Figure 4, in the same order and with the same limits. Unlike there,
# ylim is given in raw data units, it gets multiplied by scale when plotting
#
# Figure layout:
# STA   | GDPpp    | recession
# infl  | captured | stored
varsToPlot <- list(
	energy_balance_model_surface_temperature_anomaly = list(
		name  = 'Surface Temperature Anomaly',
		unit  = '°C',
		scale = 1,
		ylim  = c(0, 6)
	),
	demographics_real_gdp_per_person = list(
		name  = 'GDP per Person',
		unit  = 'thsnd. 2021 intl. $ / person',
		scale = 1,
		ylim  = c(0, 120)
	),
	gdp_future_year_in_recession = list(
		name  = 'Years spent in recession',
		unit  = 'years',
		scale = 1,
		ylim  = c(0, 50)
	),
	inflation_inflation_index = list(
		name  = 'Inflation index',
		unit  = 'index 2021=1',
		scale = 1,
		ylim  = c(0, 30)
	),
	emissions_share_of_co2_energy_emissions_captured = list(
		name  = 'Energy CO2 captured share',
		unit  = '%',
		scale = 100,
		ylim  = c(0, 100)/100
	),
	ccs_stored_co2 = list(
		name  = 'Stored CO2',
		unit  = 'GtCO2',
		scale = 1e-3,
		ylim  = c(0, 2000)*1e3
	)
)

# joint plot ####
cat('Plotting Figure 4b\n')
setwd(homeWD)
for (o.i in which(!dir.exists(dataFolders))) {
	cat(sprintf('WARNING: no results for %s (%s) in\n  %s\n  it is left out of the figure.\n',
							overlayNames[o.i], overlayScenarios[o.i], dataFolders[o.i]))
}
fig.dir  <- file.path('figures', 'multipanel')
fig.w    <- 7
fig.h    <- 5
fig.unit <- 'cm'
fig.res  <- 450
fig.xlim <- c(figYearStart, figYearEnd)
dir.create(fig.dir, FALSE, TRUE)

fig4b.ncol            <- 3
fig4b.nrow            <- 2
fig4b.legendHeightMult <- 0.3

png(file.path(fig.dir, 'Figure4b.png'),
		width=fig.w * fig4b.ncol, height=fig.h * (fig4b.nrow + fig4b.legendHeightMult),
		units=fig.unit, res=fig.res)
layout(
	matrix(c(1:(fig4b.nrow * fig4b.ncol), rep(fig4b.nrow * fig4b.ncol + 1, fig4b.ncol)),
				 byrow=TRUE, ncol=fig4b.ncol),
	widths  = rep(1, fig4b.ncol),
	heights = c(rep(1, fig4b.nrow), fig4b.legendHeightMult)
)
drawnAnywhere <- rep(FALSE, length(overlayNames))
for (var.i in seq_along(varsToPlot)) {
	cat(sprintf('%3i of %3i : %s\n', var.i, length(varsToPlot), varsToPlot[[var.i]]$name))
	par(mar=c(2, 2.4, 2, 1), mgp=c(1.4, 0.5, 0))
	available <- plotOverlayedRuns(dataFolders, overlayColors, names(varsToPlot)[var.i], CIsToPlot,
																 xlim=fig.xlim, xTicks=figYearTicks, xlab='',
																 titlePrepend=paste0(letters[var.i], ') '),
																 drawMedian=plt.drawMedian,
																 drawCIOutline=plt.drawCIOutline)
	drawnAnywhere <- drawnAnywhere | available
}
par(mar=c(0, 0, 0, 0))
plot(0, 0, type='n', axes=FALSE, xlab='', ylab='')
legend('center',
			 legend=overlayNames[drawnAnywhere],
			 border=overlayColors[drawnAnywhere],
			 fill=adjustcolor(overlayColors[drawnAnywhere], 0.2), cex=1,
			 ncol=max(1, sum(drawnAnywhere)))
dev.off()
cat(sprintf('Figure saved to %s\n', file.path(fig.dir, 'Figure4b.png')))
