source('config.R')
source('plotScenarioSliceFun.R')

# sweep config ####
sweepsToPlot <- c('CCS', 'NoCCS')
# the last slice is the end of the period the time series figures show
sliceYears   <- c(2050, 2100, figYearEnd)
overlayColors <- unname(paperCols[sweepsToPlot])

# the EMB baseline sets no carbon tax at all, so it is the 0 $/tCO2e end of every
# sweep and is prepended to each of them. Both families therefore start from the
# same run, and their bands meet at x = 0.
sweepBaselineName  <- 'EMB'
sweepBaselineValue <- 0

CIsToPlot      <- c(0.67)
lwd            <- 1.5
plt.drawMedian    <- TRUE
plt.drawCIOutline <- TRUE
# In a panel showing one variable, colour is the scenario family. In a panel
# overlaying several variables the variables take varOverlayCols (set in
# config.R) and the families fall back to these line types, because a line type
# cannot be told apart once each variable also shades a CI range.
familyLtys <- c('solid', 'dashed', 'dotdash')

# vars ####
# one row of panels per entry, one column per year in sliceYears. An entry can
# hold several variables, which are then drawn in one panel with one line type
# each, e.g. the storage share of the three fossil fuels
sliceXlab <- 'carbon tax, 2021 $/tCO2e'
sliceVars <- list(
	list(
		variables = c('energy_balance_model_surface_temperature_anomaly'),
		name  = 'Surface Temperature Anomaly',
		unit  = '°C',
		scale = 1,
		ylim  = c(1, 6)
	),
	list(
		variables = c('demographics_real_gdp_per_person'),
		name  = 'GDP per Person',
		unit  = 'thsnd. 2021 intl. $ / person',
		scale = 1,
		ylim  = c(0, 120),
		nTicks = 5
	),
	list(
		variables = c('gdp_future_year_in_recession'),
		name  = 'Years spent in recession',
		unit  = 'years',
		scale = 1,
		ylim  = c(0, 40)
	),
	list(
		variables = c('inflation_inflation_index'),
		name  = 'Inflation index',
		unit  = 'index 2021=1',
		scale = 1,
		ylim  = c(0, 25)
	),
	# the three fuels as their own rows. To overlay them in one panel instead,
	# replace the three entries below with the commented one at the end of this
	# list, which draws them in varOverlayCols
	# list(
	# 	variables = c('fossil_energy_coal_share_of_emissions_stored'),
	# 	name  = 'Coal Emissions Stored',
	# 	unit  = '% of emissions',
	# 	scale = 100,
	# 	ylim  = c(0, 105)
	# ),
	# list(
	# 	variables = c('fossil_energy_gas_share_of_emissions_stored'),
	# 	name  = 'Gas Emissions Stored',
	# 	unit  = '% of emissions',
	# 	scale = 100,
	# 	ylim  = c(0, 105)
	# ),
	# list(
	# 	variables = c('fossil_energy_oil_share_of_emissions_stored'),
	# 	name  = 'Oil Emissions Stored',
	# 	unit  = '% of emissions',
	# 	scale = 100,
	# 	ylim  = c(0, 105)
	# ),
	# list(
	# 	variables = c('ccs_yearly_cost_of_storing_co2_per_unit'),
	# 	name  = 'Cost of Storing CO2',
	# 	unit  = '$ / tCO2',
	# 	scale = 1,
	# 	ylim  = c(0, 1500),
	# 	# the x axis is a price per tCO2e as well, so the diagonal marks where
	# 	# storing a tonne costs exactly what emitting it is taxed
	# 	taxReference = TRUE
	# ),
	list(
		variables = c('emissions_share_of_co2_energy_emissions_captured'),
		name  = 'Energy CO2 captured share',
		unit  = '%',
		scale = 100,
		ylim  = c(0, 60),
		nTicks = 4
	),
	# list(
	# 	variables = c('ccs_captured_co2_to_store'),
	# 	name  = 'Storing CO2',
	# 	unit  = 'GtCO2/year',
	# 	scale = 1e-3,
	# 	ylim  = c(0, 20000)*1e-3
	# ),
	list(
		variables = c('ccs_stored_co2'),
		name  = 'Stored CO2',
		unit  = 'GtCO2',
		scale = 1e-3,
		ylim  = c(0, 2000)
	)#,
	# the three fuels overlaid in a single panel, coloured by varOverlayCols
	# list(
	# 	variables = c(coal = 'fossil_energy_coal_endogenous_share_of_emissions_stored',
	# 								gas  = 'fossil_energy_gas_endogenous_share_of_emissions_stored',
	# 								oil  = 'fossil_energy_oil_endogenous_share_of_emissions_stored'),
	# 	name  = 'Share of Emissions Stored',
	# 	unit  = '% of emissions',
	# 	scale = 100,
	# 	ylim  = c(0, 105)
	# )
)

# read the slices ####
# every scenario file is read once and sliced for all years. Scenarios whose run
# has not produced results yet are dropped as if they were not configured, and
# that is checked per variable, because a run being plotted right now can already
# have one of them written and not the other
cat('Plotting FigureNotUsed7\n')
setwd(homeWD)
sliceVarNames <- unlist(lapply(sliceVars, `[[`, 'variables'))
# what to call each variable in the warnings, the row name plus which of the
# row's variables it is where a row holds more than one
sliceVarLabels <- unlist(lapply(sliceVars, function(v) {
	if (length(v$variables) > 1 && !is.null(names(v$variables))) {
		paste0(v$name, ' (', names(v$variables), ')')
	} else {
		v$name
	}
}))
names(sliceVarLabels) <- sliceVarNames
slices <- list()
for (sweepName in sweepsToPlot) {
	sweep <- rbind(
		data.frame(value     = sweepBaselineValue,
							 scenario  = sweepBaselineName,
							 folder    = unname(resultFolders[[sweepBaselineName]]),
							 row.names = NULL, stringsAsFactors = FALSE),
		carbonTaxSweeps[[sweepName]]
	)
	haveIt <- list()
	slices[[sweepName]] <- lapply(sliceVarNames, function(varName) {
		files <- file.path(sweep$folder, paste0(varName, varNameExtra))
		have  <- file.exists(files)
		haveIt[[varName]] <<- have
		ciBounds <- do.call(rbind, lapply(files[have], function(f) {
			readRDS(f)$ciBounds[as.character(sliceYears), , drop=FALSE]
		}))
		# one entry per year, each holding the tax levels and their quantiles
		lapply(seq_along(sliceYears), function(y.i) {
			list(x        = sweep$value[have],
					 ciBounds = ciBounds[seq(y.i, by=length(sliceYears), length.out=sum(have)), ,
															 drop=FALSE])
		})
	})
	names(slices[[sweepName]]) <- sliceVarNames

	# one warning per distinct set of missing scenarios, naming the variables it
	# applies to, so identical gaps in several variables do not repeat themselves
	missingSets <- split(names(haveIt),
											 sapply(haveIt, function(h) paste(sweep$value[!h], collapse=', ')))
	for (missingLevels in names(missingSets)) {
		if (missingLevels == '') next
		varNames <- missingSets[[missingLevels]]
		cat(sprintf(paste0('WARNING: %s results are not complete for %s,\n',
											 '  %i of %i missing (%s). The plot will contain gaps where\n',
											 '  those scenarios would have been.\n'),
								sweepName, paste(sliceVarLabels[varNames], collapse=', '),
								sum(!haveIt[[varNames[1]]]), nrow(sweep), missingLevels))
	}
	cat(sprintf('  %-6s %s of %i scenarios available\n', sweepName,
							paste(range(sapply(haveIt, sum)), collapse=' to '), nrow(sweep)))
}

# joint plot ####
fig.dir  <- file.path('figures', 'multipanel')
fig.w    <- 7
fig.h    <- 5
fig.unit <- 'cm'
fig.res  <- 450
# the full configured sweep, so the axis does not shift as the remaining runs land
fig.xlim <- range(sweepBaselineValue,
									unlist(lapply(carbonTaxSweeps[sweepsToPlot], `[[`, 'value')))
dir.create(fig.dir, FALSE, TRUE)

fig7.ncol            <- length(sliceYears)
fig7.nrow            <- length(sliceVars)
fig7.legendHeightMult <- 0.3

png(file.path(fig.dir, 'FigureNotUsed7.png'),
		width=fig.w * fig7.ncol, height=fig.h * (fig7.nrow + fig7.legendHeightMult),
		units=fig.unit, res=fig.res)
layout(
	matrix(c(1:(fig7.nrow * fig7.ncol), rep(fig7.nrow * fig7.ncol + 1, fig7.ncol)),
				 byrow=TRUE, ncol=fig7.ncol),
	widths  = rep(1, fig7.ncol),
	heights = c(rep(1, fig7.nrow), fig7.legendHeightMult)
)
drawnAnywhere <- rep(FALSE, length(sweepsToPlot))
for (v.i in seq_along(sliceVars)) {
	sliceVar <- sliceVars[[v.i]]
	for (y.i in seq_along(sliceYears)) {
		panel.i <- (v.i - 1) * length(sliceYears) + y.i
		cat(sprintf('%3i of %3i : %s in %i\n', panel.i, fig7.nrow * fig7.ncol,
								sliceVar$name, sliceYears[y.i]))
		# one series per family per variable of this row
		overlaid <- length(sliceVar$variables) > 1
		series <- list()
		seriesFamily <- integer()
		for (f.i in seq_along(sweepsToPlot)) {
			for (var.i in seq_along(sliceVar$variables)) {
				series[[length(series) + 1]] <- c(
					slices[[sweepsToPlot[f.i]]][[sliceVar$variables[var.i]]][[y.i]],
					if (overlaid) {
						list(col=varOverlayCols[var.i], lty=familyLtys[f.i])
					} else {
						list(col=overlayColors[f.i], lty='solid')
					}
				)
				seriesFamily <- c(seriesFamily, f.i)
			}
		}
		par(mar=c(3, 2.4, 2, 1), mgp=c(1.4, 0.5, 0))
		available <- plotScenarioSlice(
			series, CIsToPlot,
			main=paste0(letters[panel.i], ') ', sliceVar$name, ' in ', sliceYears[y.i]),
			xlab=sliceXlab, ylab=sliceVar$unit,
			xlim=fig.xlim, ylim=sliceVar$ylim, scale=sliceVar$scale, nTicks=sliceVar$nTicks,
			drawMedian=plt.drawMedian, drawCIOutline=plt.drawCIOutline, lwd=lwd
		)
		if (isTRUE(sliceVar$taxReference)) {
			abline(0, 1, lty='dotted', col='gray40', lwd=lwd)
		}
		# a row overlaying several variables needs its own key for their colours
		if (overlaid && !is.null(names(sliceVar$variables))) {
			legend('bottomright', legend=names(sliceVar$variables),
						 col=varOverlayCols[seq_along(sliceVar$variables)],
						 lty='solid', lwd=lwd, bg='white', cex=0.9)
		}
		for (f.i in seq_along(sweepsToPlot)) {
			drawnAnywhere[f.i] <- drawnAnywhere[f.i] || any(available[seriesFamily == f.i])
		}
	}
}
par(mar=c(0, 0, 0, 0))
plot(0, 0, type='n', axes=FALSE, xlab='', ylab='')
legend('center',
			 legend=sweepsToPlot[drawnAnywhere],
			 border=overlayColors[drawnAnywhere],
			 fill=adjustcolor(overlayColors[drawnAnywhere], 0.2), cex=1,
			 ncol=max(1, sum(drawnAnywhere)))
dev.off()
cat(sprintf('Figure saved to %s\n', file.path(fig.dir, 'FigureNotUsed7.png')))
