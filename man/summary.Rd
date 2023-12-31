% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods.R
\docType{methods}
\name{summary}
\alias{summary}
\alias{summary,BSFDataSet-method}
\title{Summary method to for the BSFDataSet}
\usage{
\S4method{summary}{BSFDataSet}(object)
}
\arguments{
\item{object}{a \code{BSFDataSet} object}
}
\value{
summary of the current object
}
\description{
Prints the summaryinformation for the \code{\link{BSFDataSet}} object. This
includes information on samples, conditions and crosslinks.
}
\examples{

# load data
files <- system.file("extdata", package="BindingSiteFinder")
load(list.files(files, pattern = ".rda$", full.names = TRUE))

summary(bds)

}
\seealso{
\code{\link{BSFDataSet}}
}
