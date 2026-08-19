source('config.R')

# overlay config ####
dataFolders  <- c(
	'/home/benjamin/mnt/levante/work/mh0033/b383346/Legacy_WorldTransFrida-Uncertainty/workOutput/UA_EMBv6Try2_nS100000/figures/CI-plots/completeEquallyWeighted/plotData/',
	'/home/benjamin/mnt/levante/work/uc1275/u244021/WorldTransFrida-Uncertainty-FRIDA-development/workOutput/UA-v3-1-2026-08-18-S100000-policy_EMB-ClimateFeedback_On-ClimateSTAOverride_Off/figures/CI-plots/completeEquallyWeighted/plotData/'
)
overlayColors <- c('black', 'blue')
overlayNames  <- c('v2.1', 'v3.1')

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
		unit  = 'constant 2021 intl. $ per person',
		scale = 1,
		ylim  = c(0,120)
	),
	demographics_population = list(
		name  = 'Population',
		unit  = 'billion people',
		scale = 1e-3,
		ylim  = c(7,12)*1e3
	),
	land_use_cropland = list(
		name  = 'Cropland',
		unit  = 'MHa',
		scale = 1,
		ylim  = c(1000,3000)
	),
	land_use_forest_land = list(
		name  = 'Forest Land',
		unit  = 'MHa',
		scale = 1,
		ylim  = c(2500,4500)
	),
	land_use_grassland = list(
		name  = 'Grassland',
		unit  = 'MHa',
		scale = 1,
		ylim  = c(3000,4000),
		nTicks = 5
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
		ylim  = c(0,400),
		nTicks = 5
	)
)

# plot fun ####
plotOverlayedRuns <- function(folders, colors, varName, CIsToPlot,
															drawMedian=TRUE, titlePrepend='',
															xlab='Year', xlim=NULL, ylim=NULL, drawCIOutline=TRUE, ...) {
	varData <- lapply(folders, function(f) {
		readRDS(file.path(f, paste0(varName, varNameExtra)))
	})

	# determine axis limits from first folder's data
	if (is.null(xlim)) {
		xlim <- as.numeric(range(varData[[1]]$years))
	}
	if (is.null(ylim)) {
		if (is.null(varsToPlot[[varName]]$ylim)) {
			allBounds <- do.call(rbind, lapply(varData, `[[`, 'ciBounds'))
			ylim <- as.numeric(range(allBounds, na.rm=TRUE)) * varsToPlot[[varName]]$scale
		} else {
			ylim <- varsToPlot[[varName]]$ylim * varsToPlot[[varName]]$scale
		}
	}

	plot(0, 0, type='n', xlab=xlab, ylab=varsToPlot[[varName]]$unit,
			 xlim=xlim, ylim=ylim,
			 main=paste0(titlePrepend, varsToPlot[[varName]]$name),
			 xaxs='i', yaxs='i', xaxt='n', yaxt='n')
	grid()
	box()
	abline(h=0, col='gray')
	ax <- axTicks(1)
	axis(1, at=ax, labels=FALSE)
	axis(1, at=ax[-c(1, length(ax))], tick=FALSE)
	axis(1, at=ax[1],          labels=ax[1],          tick=FALSE, hadj=0)
	axis(1, at=ax[length(ax)], labels=ax[length(ax)], tick=FALSE, hadj=1)
	nTicks <- varsToPlot[[varName]]$nTicks
	ay <- if (is.null(nTicks)) axTicks(2) else seq(par('usr')[3], par('usr')[4], 
																								 length.out=nTicks)
	axis(2, at=ay, labels=ay, gap.axis=0)

	# filled CI bands
	for (o.i in seq_along(folders)) {
		dat <- varData[[o.i]]
		for (CItoPlot.i in seq_along(CIsToPlot)) {
			CItoPlot  <- CIsToPlot[CItoPlot.i]
			CIboundQs <- c((1-CItoPlot)/2, 1-(1-CItoPlot)/2)
			varLength <- nrow(dat$ciBounds)
			polygon(
				x = c(-9999, dat$years, 9999, 9999, rev(dat$years), -9999),
				y = c(dat$ciBounds[, as.character(CIboundQs[1])][c(1, 1:varLength, varLength)],
							rev(dat$ciBounds[, as.character(CIboundQs[2])])[c(1, 1:varLength, varLength)]) * varsToPlot[[varName]]$scale,
				col    = adjustcolor(colors[o.i], alpha.f=0.2/CItoPlot.i),
				border = NA,
				lwd    = lwd/2
			)
		}
	}

	# CI outlines
	if (drawCIOutline) {
		for (o.i in seq_along(folders)) {
			dat <- varData[[o.i]]
			for (CItoPlot.i in seq_along(CIsToPlot)) {
				CItoPlot  <- CIsToPlot[CItoPlot.i]
				CIboundQs <- c((1-CItoPlot)/2, 1-(1-CItoPlot)/2)
				varLength <- nrow(dat$ciBounds)
				polygon(
					x = c(-9999, dat$years, 9999, 9999, rev(dat$years), -9999),
					y = c(dat$ciBounds[, as.character(CIboundQs[1])][c(1, 1:varLength, varLength)],
								rev(dat$ciBounds[, as.character(CIboundQs[2])])[c(1, 1:varLength, varLength)]) * varsToPlot[[varName]]$scale,
					col    = NA,
					border = adjustcolor(colors[o.i], alpha.f=1/CItoPlot.i),
					lwd    = lwd/2/CItoPlot.i
				)
			}
		}
	}

	# medians
	if (drawMedian) {
		for (o.i in seq_along(folders)) {
			dat <- varData[[o.i]]
			lines(dat$years,
						dat$ciBounds[, '0.5'] * varsToPlot[[varName]]$scale,
						lwd=lwd, col=adjustcolor(colors[o.i], alpha.f=1))
		}
	}
}

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
