source('config.R')
source('plotOverlayedRunsFun.R')

# overlay config ####
overlayNames  <- c('EMB', 'Gov. Inv.', 'Insurance')
overlayColors <- unname(paperCols[overlayNames])
dataFolders   <- unname(resultFolders[overlayNames])

CIsToPlot      <- c(0.67, 0.95)
lwd            <- 1.5
plt.drawMedian    <- TRUE
plt.drawCIOutline <- TRUE

# vars ####
# ylim is given in raw data units, it gets multiplied by scale when plotting
# Figure order is order of this list by row
# 
# Figure layout:
# GDP | Inf | prod
# pC  | Sint| unemp
# pI  | lFai| trans
# gE  | Rint| debt
varsToPlot <- list(
	gdp_real_gdp_in_2021c = list(
		name  = 'GDP',
		unit  = 'trillion 2021 intl. $/year',
		scale = 1e-3,
		ylim  = c(0, 1500)*1e3,
		nTicks = 6
	),
	inflation_inflation_rate = list(
		name  = 'Inflation Rate',
		unit  = '% per year',
		scale = 100,
		ylim  = c(-1, 8)/100
	),
	employment_realised_productivity_growth = list(
		name  = 'Productivity Growth',
		unit  = '% per year',
		scale = 100,
		ylim  = c(0, 3)/100
	),
	circular_flow_real_private_consumption_2021c = list(
		name  = 'Private Consumption',
		unit  = 'trillion 2021 intl. $/year',
		scale = 1e-3,
		ylim  = c(0, 800)*1e3
	),
	government_central_bank_safe_interest = list(
		name  = 'Safe Interest Rate',
		unit  = '% per year',
		scale = 100,
		ylim  = c(0, 20)/100
	),
	employment_unemployment_rate = list(
		name  = 'Unemployment Rate',
		unit  = '% of labour pool',
		scale = 100,
		ylim  = c(0, 10)/100
	),
	gdp_private_investment_in_in_2021c = list(
		name  = 'Private Investment',
		unit  = 'trillion 2021 intl. $/year',
		scale = 1e-3,
		ylim  = c(0, 400)*1e3
	),
	finance_failure_rate = list(
		name  = 'Loan Failure Rate',
		unit  = '% per year',
		scale = 100,
		ylim  = c(0, 20)/100
	),
	government_government_transfers_as_a_share_of_public_expenditure = list(
		name  = 'Transfers as Share of Gov. Exp.',
		unit  = 'ratio',
		scale = 1,
		ylim  = c(0, 2)
	),
	government_public_expenditure_in_2021c = list(
		name  = 'Government Expenditure',
		unit  = 'trillion 2021 intl. $/year',
		scale = 1e-3,
		ylim  = c(0, 400)*1e3
	),
	finance_risky_interest = list(
		name  = 'Risky Interest Rate',
		unit  = '% per year',
		scale = 100,
		ylim  = c(0, 20)/100
	),
	government_debt_to_gdp_ratio = list(
		name  = 'Debt to GDP Ratio',
		unit  = 'ratio',
		scale = 1,
		ylim  = c(0, 2)
	)#,
	# further variables, uncomment to include (adjust fig2.ncol/fig2.nrow to match)
	# gdp_government_consumption_in_2021c = list(
	# 	name  = 'Government Consumption',
	# 	unit  = 'trillion 2021 intl. $/year',
	# 	scale = 1e-3,
	# 	ylim  = c(0, 200)*1e3
	# ),
	# gdp_public_investment_in_2021c = list(
	# 	name  = 'Public Investment',
	# 	unit  = 'trillion 2021 intl. $/year',
	# 	scale = 1e-3,
	# 	ylim  = c(0, 150)*1e3
	# ),
	# finance_measured_default_rate_of_all_assets = list(
	# 	name  = 'Default Rate',
	# 	unit  = 'rate',
	# 	scale = 1,
	# 	ylim  = c(0, 0.04)
	# ),
	# finance_measured_default_rate_of_risky_assets = list(
	# 	name  = 'Default Rate of Risky Loans',
	# 	unit  = 'rate',
	# 	scale = 1,
	# 	ylim  = c(0, 0.04)
	# ),
	# finance_measured_default_rate_of_safe_assets = list(
	# 	name  = 'Default Rate of Safe Loans',
	# 	unit  = 'rate',
	# 	scale = 1,
	# 	ylim  = c(0, 0.04)
	# )
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

fig2.ncol            <- 3
fig2.nrow            <- 4
fig2.legendHeightMult <- 0.3

png(file.path(fig.dir, 'Figure2.png'),
		width=fig.w * fig2.ncol, height=fig.h * (fig2.nrow + fig2.legendHeightMult),
		units=fig.unit, res=fig.res)
layout(
	matrix(c(1:(fig2.nrow * fig2.ncol), rep(fig2.nrow * fig2.ncol + 1, fig2.ncol)),
				 byrow=TRUE, ncol=fig2.ncol),
	widths  = rep(1, fig2.ncol),
	heights = c(rep(1, fig2.nrow), fig2.legendHeightMult)
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
cat(sprintf('Figure saved to %s\n', file.path(fig.dir, 'Figure2.png')))
