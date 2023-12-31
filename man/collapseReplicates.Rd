% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/exports.R
\name{collapseReplicates}
\alias{collapseReplicates}
\title{Collapse signal from replicates}
\usage{
collapseReplicates(object, collapseAll = FALSE)
}
\arguments{
\item{object}{a \code{BSFDataSet} object}

\item{collapseAll}{TRUE/FALSE, if all samples should be collapsed (TRUE), or
if samples should be kept separate by condition (FALSE)}
}
\value{
object of type \code{\link{BSFDataSet}} with updated signal
}
\description{
Collapses all replicates merges all samples from a \link{BSFDataSet} object
into a single signal stream, only split by minus and plus strand.
}
\examples{

# load data
files <- system.file("extdata", package="BindingSiteFinder")
load(list.files(files, pattern = ".rda$", full.names = TRUE))

bdsNew = collapseReplicates(bds)

}
\seealso{
\code{\link{BSFDataSet}}
}
