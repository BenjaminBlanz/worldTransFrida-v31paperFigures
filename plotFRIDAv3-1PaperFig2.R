source('config.R')
source('plotOverlayedRunsFun.R')

# overlay config ####
overlayNames  <- c('v2.1', 'v3.1')
overlayColors <- unname(paperCols[overlayNames])
dataFolders   <- unname(resultFolders[overlayNames])

CIsToPlot      <- c(0.67, 0.95)
lwd            <- 1.5
plt.drawMedian    <- TRUE
plt.drawCIOutline <- TRUE

# vars ####
# ylim is given in raw data units, it gets multiplied by scale when plotting
varsToPlot <- list(
	land_use_global_burned_area_due_to_climate_change = list(
		name  = 'Burned Area due to Climate Change',
		unit  = 'MHa/year',
		scale = 1,
		ylim  = c(0, 300)
	),
	transportation_energy_demand_average_daily_demand_per_capita = list(
		name  = 'Transportation Energy Demand',
		unit  = 'kWh/person/day',
		scale = 1e3,
		ylim  = c(0, 20)*1e-3
	),
	wind_energy_wind_energy_full_load_hours = list(
		name  = 'Wind Energy Full Load Hours',
		unit  = 'hours/year',
		scale = 1,
		ylim  = c(1750, 1800)
	),
	demographics_life_expectancy = list(
		name  = 'Life Expectancy',
		unit  = 'years',
		scale = 1,
		ylim  = c(60, 90)
	)
)

# joint plot ####
cat('Plotting Figure 2\n')
setwd(homeWD)
fig.dir  <- file.path('figures', 'multipanel')
fig.w    <- 7
fig.h    <- 5
fig.unit <- 'cm'
fig.res  <- 450
fig.xlim <- c(2020, 2100)
dir.create(fig.dir, FALSE, TRUE)

fig3.ncol            <- 2
fig3.nrow            <- 2
fig3.legendHeightMult <- 0.3

png(file.path(fig.dir, 'Figure2.png'),
		width=fig.w * fig3.ncol, height=fig.h * (fig3.nrow + fig3.legendHeightMult),
		units=fig.unit, res=fig.res)
layout(
	matrix(c(1:(fig3.nrow * fig3.ncol), rep(fig3.nrow * fig3.ncol + 1, fig3.ncol)),
				 byrow=TRUE, ncol=fig3.ncol),
	widths  = rep(1, fig3.ncol),
	heights = c(rep(1, fig3.nrow), fig3.legendHeightMult)
)
# not every variable exists in every run, only the runs that end up drawn
# somewhere in the figure belong in the legend
drawnAnywhere <- rep(FALSE, length(dataFolders))
for (var.i in seq_along(varsToPlot)) {
	par(mar=c(2, 2.4, 2, 1), mgp=c(1.4, 0.5, 0))
	available <- plotOverlayedRuns(dataFolders, overlayColors, names(varsToPlot)[var.i], CIsToPlot,
																 xlim=fig.xlim, xlab='',
																 titlePrepend=paste0(letters[var.i], ') '),
																 drawMedian=plt.drawMedian,
																 drawCIOutline=plt.drawCIOutline)
	drawnAnywhere <- drawnAnywhere | available
	cat(sprintf('%3i of %3i : %-34s %s\n', var.i, length(varsToPlot),
							varsToPlot[[var.i]]$name,
							if (all(available)) {
								'all runs'
							} else {
								sprintf('only %s, not in %s',
												paste(overlayNames[available], collapse=', '),
												paste(overlayNames[!available], collapse=', '))
							}))
}
par(mar=c(0, 0, 0, 0))
plot(0, 0, type='n', axes=FALSE, xlab='', ylab='')
legend('center',
			 legend=overlayNames[drawnAnywhere],
			 border=overlayColors[drawnAnywhere],
			 fill=adjustcolor(overlayColors[drawnAnywhere], 0.2), cex=1,
			 ncol=sum(drawnAnywhere))
dev.off()
cat(sprintf('Figure saved to %s\n', file.path(fig.dir, 'Figure3.png')))
