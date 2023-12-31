% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PlotFunction.R
\name{transcriptRegionOverlapsPlot}
\alias{transcriptRegionOverlapsPlot}
\title{UpSet-plot to that shows the transcript region overlaps}
\usage{
transcriptRegionOverlapsPlot(object, text.size = NULL, show.title = TRUE)
}
\arguments{
\item{object}{a \code{\link{BSFDataSet}} object}

\item{text.size}{numeric; fontsize of all numbers on axis}

\item{show.title}{logical; if plot title should be visible}
}
\value{
a plot of type \code{\link{ggplot}}
}
\description{
A diagnostic function that plots the transcript regions of binding sites
on overlapping loci. The function \code{\link{assignToTranscriptRegions}} is expected to be
executed prior to calling this plot function.
}
\examples{
# load clip data
files <- system.file("extdata", package="BindingSiteFinder")
load(list.files(files, pattern = ".rda$", full.names = TRUE))
load(list.files(files, pattern = ".rds$", full.names = TRUE)[1])
load(list.files(files, pattern = ".rds$", full.names = TRUE)[2])
bds = makeBindingSites(object = bds, bsSize = 9)
bds = assignToGenes(bds, anno.genes = gns)
bds = assignToTranscriptRegions(object = bds, anno.transcriptRegionList = regions)
transcriptRegionOverlapsPlot(bds)

}
\seealso{
\code{\link{assignToTranscriptRegions}} \code{\link{transcriptRegionSpectrumPlot}}
}
