source('config.R')

# plot config ####
CIsToPlot      <- c(0.67, 0.95)
lwd            <- 1.5
plt.drawMedian    <- TRUE
plt.drawCIOutline <- TRUE

# vars ####
varsToPlot <- list(
	inflation_inflation_rate = list(
		name='Inflation Rate',
		unit='% per year',
		scale=100,
		ylim=c(-0.05, 0.15),
		xlim=c(1980, 2150)
	),
	energy_demand_demand_for_energy = list(
		name='Energy Demand',
		unit='EWh per year',
		scale=1e-3,
		ylim=c(0, 200000)
	),
	energy_investments_gross_investments_in_renewables = list(
		name='Investment in Renewables',
		unit='Trillion 2021$ per year',
		scale=1e-12,
		ylim=c(0, 10e12)
	),
	energy_investments_investments_in_fossil_energy = list(
		name='Investment in Fossils',
		unit='Trillion 2021$ per year',
		scale=1e-12,
		ylim=c(0, 2e12)
	),
	energy_investments_investments_in_nuclear_capacity = list(
		name='Investment in Nuclear',
		unit='Trillion 2021$ per year',
		scale=1e-12,
		ylim=c(0, 2e12)
	),
	employment_unemployment_rate = list(
		name='Unemployment Share',
		unit='%',
		scale=100,
		ylim=c(0.0, 0.25)
	),
	finance_stranded_capital_related_defaults = list(
		name='Stranded Capital Related Loan Defaults',
		unit='Trillion $ per year',
		scale=1e-3,
		ylim=c(0, 100000)
	),
	energy_balance_model_surface_temperature_anomaly = list(
		name='Surface Temperature Anomaly',
		unit='°C',
		scale=1,
		ylim=c(0, 5)
	),
	gdp_real_gdp_in_2021c = list(
		name='GDP',
		unit='trillion constant 2021 intl. $',
		scale=1e-3,
		ylim=c(0, 2e6)
	),
	fossil_energy_secondary_fossil_energy_output = list(
		name='Fossil Energy Production',
		unit='PWh per year',
		scale=1e-3,
		ylim=c(0, 140000)
	),
	renewable_energy_renewable_energy_output = list(
		name='Renewable Energy Production',
		unit='PWh per year',
		scale=1e-3,
		ylim=c(0, 140000),
		yaxs='i'
	),
	nuclear_energy_nuclear_energy_output = list(
		name='Nuclear Energy Production',
		unit='PWh per year',
		scale=1e-3,
		ylim=c(0, 140000),
		yaxs='i'
	),
	emissions_co2_emissions_from_energy = list(
		name='CO2 Emissions from Energy',
		unit='GtC',
		scale=1e-3,
		ylim=c(0, 5e4)
	)
)

# plot fun ####
plotOverlayedScenarios <- function(scenariosToPlot, varName, CIsToPlot,
																	 drawMedian=TRUE, titlePrepend='',
																	 xlab='Year', xlim=NULL, ylim=NULL, drawCIOutline=TRUE, ...) {
	varData <- list()
	for (scenario.i in 1:length(scenariosToPlot)) {
		scenarioName <- names(scenariosToPlot)[scenario.i]
		varData[[scenarioName]] <- readRDS(file.path(dataLocation, scenariosToPlot[[scenarioName]]$dir,
																								 'figures', 'CI-plots', 'completeEquallyWeighted', 'plotData',
																								 paste0(varName, varNameExtra)))
		if (scenario.i == 1) {
			if (is.null(xlim)) {
				if (is.null(varsToPlot[[varName]]$xlim)) {
					xlim <- as.numeric(range(varData[[scenarioName]]$years))
				} else {
					xlim <- varsToPlot[[varName]]$xlim
				}
			}
			if (is.null(ylim)) {
				if (is.null(varsToPlot[[varName]]$ylim)) {
					ylim <- as.numeric(range(varData[[scenarioName]]$ciBounds) * varsToPlot[[varName]]$scale)
				} else {
					ylim <- varsToPlot[[varName]]$ylim * varsToPlot[[varName]]$scale
				}
			}
			plot(0, 0, type='n', xlab=xlab, ylab=varsToPlot[[varName]]$unit,
					 xlim=xlim, ylim=ylim,
					 main=paste0(titlePrepend, varsToPlot[[varName]]$name),
					 xaxs='i', yaxs='i', xaxt='n')
			grid()
			box()
			abline(h=0, col='gray')
			ax <- axTicks(1)
			axis(1, at=ax, labels=FALSE)
			axis(1, at=ax[-c(1, length(ax))], tick=FALSE)
			axis(1, at=ax[1],          labels=ax[1],          tick=FALSE, hadj=0)
			axis(1, at=ax[length(ax)], labels=ax[length(ax)], tick=FALSE, hadj=1)
		}
		for (CItoPlot.i in 1:length(CIsToPlot)) {
			CItoPlot  <- CIsToPlot[CItoPlot.i]
			CIboundQs <- c((1-CItoPlot)/2, 1-(1-CItoPlot)/2)
			varLength <- length(varData[[scenarioName]]$ciBounds[, as.character(CIboundQs[1])])
			polygon(x = c(-9999, varData[[scenarioName]]$years, 9999,
										9999, rev(varData[[scenarioName]]$years), -9999),
							y = c(varData[[scenarioName]]$ciBounds[, as.character(CIboundQs[1])][c(1, 1:varLength, varLength)],
										rev(varData[[scenarioName]]$ciBounds[, as.character(CIboundQs[2])])[c(1, 1:varLength, varLength)]) * varsToPlot[[varName]]$scale,
							col=adjustcolor(scenariosToPlot[[scenarioName]]$areaCol, alpha.f=0.2/CItoPlot.i),
							border=NA, lwd=lwd/2, lty=scenario.i)
		}
	}
	if (drawCIOutline) {
		for (scenario.i in 1:length(scenariosToPlot)) {
			scenarioName <- names(scenariosToPlot)[scenario.i]
			for (CItoPlot.i in 1:length(CIsToPlot)) {
				CItoPlot  <- CIsToPlot[CItoPlot.i]
				CIboundQs <- c((1-CItoPlot)/2, 1-(1-CItoPlot)/2)
				varLength <- length(varData[[scenarioName]]$ciBounds[, as.character(CIboundQs[1])])
				polygon(x = c(-9999, varData[[scenarioName]]$years, 9999,
											9999, rev(varData[[scenarioName]]$years), -9999),
								y = c(varData[[scenarioName]]$ciBounds[, as.character(CIboundQs[1])][c(1, 1:varLength, varLength)],
											rev(varData[[scenarioName]]$ciBounds[, as.character(CIboundQs[2])])[c(1, 1:varLength, varLength)]) * varsToPlot[[varName]]$scale,
								col=NA,
								border=adjustcolor(scenariosToPlot[[scenarioName]]$areaCol, alpha.f=1/CItoPlot.i),
								lwd=lwd/2/CItoPlot.i, lty=scenariosToPlot[[scenarioName]]$lty)
			}
		}
	}
	if (drawMedian) {
		for (scenario.i in 1:length(scenariosToPlot)) {
			lines(varData[[scenario.i]]$years,
						varData[[scenario.i]]$ciBounds[, '0.5'] * varsToPlot[[varName]]$scale,
						lwd=lwd, lty=scenariosToPlot[[scenario.i]]$lty,
						col=adjustcolor(scenariosToPlot[[scenario.i]]$col, alpha.f=1))
		}
	}
}

# individual plots ####
setwd(homeWD)
fig.dir  <- file.path('figures', 'individual')
fig.w    <- 15
fig.h    <- 15
fig.unit <- 'cm'
fig.res  <- 450
fig.xlim <- c(2020, 2100)
dir.create(fig.dir, FALSE, TRUE)

## legend ####
png(file.path(fig.dir, 'legend.png'), width=7, height=3, units=fig.unit, res=fig.res)
par(mar=c(0, 0, 0, 0))
plot(0, 0, type='n', axes=FALSE, xlab='', ylab='')
legend('center',
			 legend=scenarioBeautyNames,
			 border=scenarioCols,
			 fill=adjustcolor(scenarioCols, 0.2), cex=0.5)
dev.off()

## plots ####
cat('Plotting\n')
for (i in 1:length(varsToPlot)) {
	cat(sprintf('%3i of %3i : %s\n', i, length(varsToPlot), varsToPlot[[i]]$name))
	png(file.path(fig.dir, paste0(names(varsToPlot)[i], '.png')),
			width=fig.w, height=fig.h, units=fig.unit, res=fig.res)
	plotOverlayedScenarios(scenarios, names(varsToPlot)[i], CIsToPlot,
												 drawMedian=plt.drawMedian,
												 drawCIOutline=plt.drawCIOutline,
												 xlim=fig.xlim)
	dev.off()
}

# joint plot ####
cat('Plotting multipanel figure\n')
setwd(homeWD)
fig.dir  <- file.path('figures', 'multipanel')
fig.w    <- 7
fig.h    <- 5
fig.unit <- 'cm'
fig.res  <- 450
fig.xlim <- c(2020, 2100)
dir.create(fig.dir, FALSE, TRUE)

# 3 columns
# GDP    | Emissions | STA
# En Dmd | Unemp     | Infl Rt
# Inv F  | Inv R     | Inv N
# Prod F | Prod R    | Prod N
#            legend
fig1.vars <- c(
	'gdp_real_gdp_in_2021c',                          'emissions_co2_emissions_from_energy',              'energy_balance_model_surface_temperature_anomaly',
	'energy_demand_demand_for_energy',                 'employment_unemployment_rate',                     'inflation_inflation_rate',
	'energy_investments_investments_in_fossil_energy', 'energy_investments_gross_investments_in_renewables','energy_investments_investments_in_nuclear_capacity',
	'fossil_energy_secondary_fossil_energy_output',    'renewable_energy_renewable_energy_output',          'nuclear_energy_nuclear_energy_output'
)

fig1.ncol            <- 3
fig1.nrow            <- 4
fig1.legendHeightMult <- 0.3
png(file.path(fig.dir, 'Figure1.png'),
		width=fig.w * fig1.ncol, height=fig.h * (fig1.nrow + fig1.legendHeightMult),
		units=fig.unit, res=fig.res)
layout(matrix(c(1:(fig1.nrow * fig1.ncol), rep((fig1.nrow * fig1.ncol + 1), fig1.ncol)),
							byrow=TRUE, ncol=fig1.ncol),
			 widths=rep(1, fig1.ncol),
			 heights=c(rep(1, fig1.nrow), fig1.legendHeightMult))
for (var.i in 1:length(fig1.vars)) {
	par(mar=c(2, 2.4, 2, 1), mgp=c(1.4, 0.5, 0))
	plotOverlayedScenarios(scenarios, fig1.vars[var.i], CIsToPlot,
												 xlim=fig.xlim, xlab='',
												 titlePrepend=paste0(letters[var.i], ') '),
												 drawMedian=plt.drawMedian,
												 drawCIOutline=plt.drawCIOutline)
}
par(mar=c(0, 0, 0, 0))
plot(0, 0, type='n', axes=FALSE, xlab='', ylab='')
legend('center',
			 legend=scenarioBeautyNames,
			 border=scenarioCols,
			 fill=adjustcolor(scenarioAreaCols, 0.2), cex=1,
			 ncol=floor(length(scenarios) / 2))
dev.off()
