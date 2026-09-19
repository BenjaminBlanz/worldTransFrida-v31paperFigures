source('config.R')

# overburned area figure: the fire damage function used in FRIDA, i.e. the
# global overburned area as a function of the surface temperature anomaly.
#
# The fit is done on two observational series that are paired by position, one
# value per year 1901 to 2019:
#   - the ISIMIP2a GSWP3 surface temperature anomaly relative to preindustrial
#     (gswp3TasFile). Its year column is an artefact of how the series was
#     digitised and is not used, the years come from the overburning data
#   - the global overburning percentiles of Burton et al. (2024), figure 3
#     (overburnedAreaFile), three rows per year holding the p10, p50 and p90
# A quadratic is fitted to each percentile separately, exactly as in the python
# script the figure comes from. Note that the data only covers roughly 0 to
# 1.3 °C, everything above that is extrapolation.

# figure config ####
obaCols <- c(p50 = '#000000',   # median, black like the reference run elsewhere
						 p10 = '#0072B2',   # low, Okabe-Ito blue
						 p90 = '#D55E00')   # high, Okabe-Ito vermillion
lwd <- 1.5

# the fits are drawn over this temperature range, the data itself ends near 1.3
fig.xlim <- c(0, 5)
fig.ylim <- c(0, 300)
fig.nTicks <- 4           # pick an ylim that divides evenly by nTicks - 1

plt.drawRange <- TRUE     # shade between the p10 and the p90 fit
plt.drawData  <- FALSE    # add the underlying Burton et al. points

# data ####
tasData <- read.csv(file.path(homeWD, gswp3TasFile), stringsAsFactors=FALSE)
obaData <- read.csv(file.path(homeWD, overburnedAreaFile), check.names=FALSE,
										stringsAsFactors=FALSE)
names(obaData) <- c('year', 'overburning')

# three rows per year become one row with the three percentiles as columns. They
# are sorted rather than taken in file order, low to high is what makes them the
# p10, p50 and p90
obaByYear <- do.call(rbind, lapply(split(obaData$overburning, obaData$year), sort))
colnames(obaByYear) <- c('p10', 'p50', 'p90')
stopifnot(nrow(obaByYear) == nrow(tasData))

tas <- tasData$tas

# quadratic damage function, a*x^2 + b*x + c, one fit per percentile ####
quadFits <- lapply(colnames(obaByYear), function(q) {
	lm(obaByYear[, q] ~ tas + I(tas^2))
})
names(quadFits) <- colnames(obaByYear)

quad <- function(fit, x) {
	co <- coef(fit)
	co[1] + co[2] * x + co[3] * x^2
}

tasPlot <- seq(fig.xlim[1], fig.xlim[2], length.out=100)
obaFit  <- lapply(quadFits, quad, x=tasPlot)

for (q in names(quadFits)) {
	cat(sprintf('%s : %6.3f x^2 + %6.3f x + %6.3f,  %5.1f %% at %g °C\n',
							q, coef(quadFits[[q]])[3], coef(quadFits[[q]])[2],
							coef(quadFits[[q]])[1], quad(quadFits[[q]], fig.xlim[2]), fig.xlim[2]))
}

# plot ####
cat('Plotting overburned area figure\n')
setwd(homeWD)
fig.dir  <- file.path('figures', 'multipanel')
fig.w    <- 12   # wider than a panel of the multipanel figures, the legend of
fig.h    <- 6    # three entries does not fit next to itself in 9 cm
fig.unit <- 'cm'
fig.res  <- 450
dir.create(fig.dir, FALSE, TRUE)

oba.legendHeightMult <- 0.3

png(file.path(fig.dir, 'FigureOverburnedArea.png'),
		width=fig.w, height=fig.h * (1 + oba.legendHeightMult),
		units=fig.unit, res=fig.res)
layout(matrix(1:2, ncol=1), heights=c(1, oba.legendHeightMult))

par(mar=c(2.4, 2.4, 2, 1), mgp=c(1.4, 0.5, 0))
plot(0, 0, type='n',
		 xlab='Surface Temperature Anomaly (°C)', ylab='%',
		 xlim=fig.xlim, ylim=fig.ylim,
		 main='Overburned Area',
		 xaxs='i', yaxs='i', xaxt='n', yaxt='n')
# tick positions are worked out before anything is drawn, so that the grid can be
# put exactly where the tick marks end up, as in plotOverlayedRunsFun.R
ax <- axTicks(1)
ay <- seq(par('usr')[3], par('usr')[4], length.out=fig.nTicks)
abline(v=ax, col='lightgray', lty='dotted')
abline(h=ay, col='lightgray', lty='dotted')
box()
abline(h=0, col='gray')
axis(1, at=ax, labels=FALSE)
axis(1, at=ax[-c(1, length(ax))], tick=FALSE)
axis(1, at=ax[1],          labels=ax[1],          tick=FALSE, hadj=0)
axis(1, at=ax[length(ax)], labels=ax[length(ax)], tick=FALSE, hadj=1)
axis(2, at=ay, labels=ay, gap.axis=0)

# the p10 to p90 range, shaded the way the ensemble ranges are in the other
# figures
if (plt.drawRange) {
	polygon(x=c(tasPlot, rev(tasPlot)),
					y=c(obaFit$p10, rev(obaFit$p90)),
					col=adjustcolor(obaCols['p50'], alpha.f=0.1), border=NA)
}

if (plt.drawData) {
	for (q in colnames(obaByYear)) {
		points(tas, obaByYear[, q], col=adjustcolor(obaCols[q], alpha.f=0.4), pch=20,
					 cex=0.5)
	}
}

for (q in c('p10', 'p90', 'p50')) {   # median last so it stays on top
	lines(tasPlot, obaFit[[q]], col=obaCols[q], lwd=lwd)
}

par(mar=c(0, 0, 0, 0))
plot(0, 0, type='n', axes=FALSE, xlab='', ylab='')
legend('center',
			 legend=c('Median (p50)', 'Low (p10)', 'High (p90)'),
			 col=unname(obaCols[c('p50', 'p10', 'p90')]),
			 lty='solid', lwd=lwd, cex=0.9, ncol=3)
dev.off()
cat(sprintf('Figure saved to %s\n',
						file.path(fig.dir, 'FigureOverburnedArea.png')))
