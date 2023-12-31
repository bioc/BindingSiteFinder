% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PlotFunction.R
\name{quickFigure}
\alias{quickFigure}
\title{Quick figures}
\usage{
quickFigure(
  object,
  what = c("main", "supp"),
  save.filename = NULL,
  save.width = 10,
  save.height = 12,
  save.device = "pdf",
  quiet = TRUE,
  ...
)
}
\arguments{
\item{object}{a \code{\link{BSFDataSet}} object}

\item{what}{character; the plotting option. One of: 'main', 'supp'}

\item{save.filename}{File name to create on the disc}

\item{save.width}{numeric; plot size width}

\item{save.height}{numeric; plot size height}

\item{save.device}{charcter; Device to use. One of: 'pdf', 'png', ...}

\item{quiet}{whether to print messages}

\item{...}{further arguments passed to \code{\link[ggplot2]{ggsave}}}
}
\value{
a plot
}
\description{
Summarize all results in a set of quick figures. Depending on how the
function is called a different set of analytic plots are arranged into
either a 'main' or 'supplementary' type multi-panel figure.
}
\examples{
# load clip data
files <- system.file("extdata", package="BindingSiteFinder")
load(list.files(files, pattern = ".rda$", full.names = TRUE))
load(list.files(files, pattern = ".rds$", full.names = TRUE)[1])
load(list.files(files, pattern = ".rds$", full.names = TRUE)[2])
bds = BSFind(bds, anno.genes = gns, anno.transcriptRegionList = regions,
 est.subsetChromosome = "chr22")
quickFigure(bds)

}
\seealso{
\code{\link{BSFind}}
}
