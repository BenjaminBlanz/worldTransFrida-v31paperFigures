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
varsToPlot <- list(
	energy_balance_model_surface_temperature_anomaly = list(
		name  = 'Surface Temperature Anomaly',
		unit  = '°C',
		scale = 1,
		ylim  = c(0, 8)
	),
	demographics_real_gdp_per_person = list(
		name  = 'GDP per Person',
		unit  = 'thsnd. 2021 intl. $ / person',
		scale = 1,
		ylim  = c(0,120)
	),
	demographics_population = list(
		name  = 'Population',
		unit  = 'billion people',
		scale = 1e-3,
		ylim  = c(0,12)*1e3
	),
	land_use_cropland = list(
		name  = 'Cropland',
		unit  = 'MHa',
		scale = 1,
		ylim  = c(0,5000)
	),
	land_use_forest_land = list(
		name  = 'Forest Land',
		unit  = 'MHa',
		scale = 1,
		ylim  = c(0,5000)
	),
	land_use_grassland = list(
		name  = 'Grassland',
		unit  = 'MHa',
		scale = 1,
		ylim  = c(0,5000)
	),
	energy_demand_demand_for_energy = list(
		name  = 'Energy Demand',
		unit  = 'EWh per year',
		scale = 1e-3,
		ylim  = c(0, 300)*1e3
	),
	land_nutrients_fertilizer_use = list(
		name  = 'Fertilizer Use',
		unit  = 'MtN/year',
		scale = 1,
		ylim  = c(0,400)#,
		# nTicks = 5
	)
)

# joint plot ####
cat('Plotting Figure 1\n')
setwd(homeWD)
fig.dir  <- file.path('figures', 'multipanel')
fig.w    <- 7
fig.h    <- 5
fig.unit <- 'cm'
fig.res  <- 450
fig.xlim <- c(2020, 2100)
dir.create(fig.dir, FALSE, TRUE)

fig1.ncol            <- 2
fig1.nrow            <- 4
fig1.legendHeightMult <- 0.3

png(file.path(fig.dir, 'Figure1.png'),
		width=fig.w * fig1.ncol, height=fig.h * (fig1.nrow + fig1.legendHeightMult),
		units=fig.unit, res=fig.res)
layout(
	matrix(c(1:(fig1.nrow * fig1.ncol), rep(fig1.nrow * fig1.ncol + 1, fig1.ncol)),
				 byrow=TRUE, ncol=fig1.ncol),
	widths  = rep(1, fig1.ncol),
	heights = c(rep(1, fig1.nrow), fig1.legendHeightMult)
)
for (var.i in seq_along(varsToPlot)) {
	cat(sprintf('%3i of %3i : %s\n', var.i, length(varsToPlot), varsToPlot[[var.i]]$name))
	par(mar=c(2, 2.4, 2, 1), mgp=c(1.4, 0.5, 0))
	plotOverlayedRuns(dataFolders, overlayColors, names(varsToPlot)[var.i], CIsToPlot,
										xlim=fig.xlim, xlab='',
										titlePrepend=paste0(letters[var.i], ') '),
										drawMedian=plt.drawMedian,
										drawCIOutline=plt.drawCIOutline)
}
par(mar=c(0, 0, 0, 0))
plot(0, 0, type='n', axes=FALSE, xlab='', ylab='')
legend('center',
			 legend=overlayNames,
			 border=overlayColors,
			 fill=adjustcolor(overlayColors, 0.2), cex=1,
			 ncol=length(overlayNames))
dev.off()
cat(sprintf('Figure saved to %s\n', file.path(fig.dir, 'Figure1.png')))
