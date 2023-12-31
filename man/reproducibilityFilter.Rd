% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Functions.R
\name{reproducibilityFilter}
\alias{reproducibilityFilter}
\title{Replicate reproducibility filter function}
\usage{
reproducibilityFilter(
  object,
  cutoff = NULL,
  nReps = NULL,
  minCrosslinks = 1,
  returnType = c("BSFDataSet", "data.frame"),
  n.reps = lifecycle::deprecated(),
  min.crosslinks = lifecycle::deprecated(),
  quiet = FALSE
)
}
\arguments{
\item{object}{a BSFDataSet object}

\item{cutoff}{numeric; percentage cutoff to be used for the
reproducibility quantile filtering}

\item{nReps}{numeric; number of replicates that must meet the cutoff
defined in \code{cutoff} for a binding site to be called reproducible.
Defaults to N-1.}

\item{minCrosslinks}{numeric; minimal number of crosslinks a binding
site needs to have to be called reproducible. Acts as a lower boundary for
\code{cutoff}. Defaults to 1.}

\item{returnType}{one of "BSFDataSet" or "data.frame". "BSFDataSet" is the
default and "matrix" can be used for easy plotting.}

\item{n.reps}{deprecated -> use nReps instead}

\item{min.crosslinks}{deprecated -> use minCrosslinks instead}

\item{quiet}{logical; whether to print messages}
}
\value{
an object of type BSFDataSet
}
\description{
For each replicate the number of binding sites with a certain number of
crosslinks is calculated. A quantile based threshold (\code{cutoff}) is
applied to each replicate. This indicates how many of the merged binding
sites are supported by crosslinks from the respective replicate. Next, one
can specify how many replicates need to pass the defined threshold for a
binding site to be considered reproducible.
}
\details{
If \code{cutoff} is a single number then the indicated cutoff will be
applied to all replicates. If it is a vector then each element in the vector
is applied to all replicates of the respective condition. The order is
hereby given by the levels of the condition column of the meta data
(see \code{\link{BSFDataSet}},\code{\link{getMeta}}). If the condition
specific filter is applied, a meta column is added to the GRanges of the
\code{BSFDataSet} object, indicating the support for each condition.

If \code{nReps} is a single number then this number is used as treshold for
all binding sites. If it is a vector then it is applied to the replicates of
the respective condition (like in \code{cutoff}). This allows the
application of different thresholds for experiments of different
experimental conditions. If the condition specific filter is applied, a meta
column is added to the GRanges of the \code{BSFDataSet} object,
indicating the support for each condition.

The function is part of the standard workflow performed by \code{\link{BSFind}}.
}
\examples{
# load data
files <- system.file("extdata", package="BindingSiteFinder")
load(list.files(files, pattern = ".rda$", full.names = TRUE))

# merge binding sites
bds <- makeBindingSites(object = bds, bsSize = 9)

# use default return with condition specific threshold
bds = reproducibilityFilter(bds, cutoff = 0.1, nReps = 1)

}
\seealso{
\code{\link{BSFind}},
\code{\link{reproducibilityFilterPlot}},
\code{\link{reproducibilitySamplesPlot}},
\code{\link{reproducibilityScatterPlot}}
}
