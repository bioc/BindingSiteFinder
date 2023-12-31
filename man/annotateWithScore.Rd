% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Functions.R
\name{annotateWithScore}
\alias{annotateWithScore}
\title{Annotation function for BSFDataSet object}
\usage{
annotateWithScore(
  object,
  match.ranges = NULL,
  match.score = "score",
  match.option = c("max", "sum", "mean"),
  scoreRanges = lifecycle::deprecated(),
  MatchColScore = lifecycle::deprecated(),
  quiet = FALSE
)
}
\arguments{
\item{object}{a BSFDataSet object}

\item{match.ranges}{a GRanges object, with numeric column for the score to match}

\item{match.score}{character; meta column name of the crosslink site
\code{\link{GenomicRanges}} object that holds the score to match}

\item{match.option}{character; option how score should be matched}

\item{scoreRanges}{deprecated -> use match.ranges instead}

\item{MatchColScore}{deprecated -> use match.score instead}

\item{quiet}{logical; whether to print messages}
}
\value{
an object of class BSFDataSet with updated meta columns of the ranges
}
\description{
This function can be used to annotate a \code{BSFDataSet} object with
merged binding sites with scores from the initial ranges
(eg. PureCLIP scores).
}
\details{
The function is part of the standard workflow performed by \code{\link{BSFind}}.
}
\examples{
if (.Platform$OS.type != "windows") {
    # load data
    csFile <- system.file("extdata", "PureCLIP_crosslink_sites_examples.bed",
                        package="BindingSiteFinder")
    cs = rtracklayer::import(con = csFile, format = "BED",
    extraCols=c("additionalScores" = "character"))
    cs$additionalScores = NULL
    clipFiles <- system.file("extdata", package="BindingSiteFinder")
    # two experimental conditions
    meta = data.frame(
    id = c(1,2,3,4),
    condition = factor(c("WT", "WT", "KD", "KD"),
    levels = c("KD", "WT")),
    clPlus = list.files(clipFiles, pattern = "plus.bw$", full.names = TRUE),
    clMinus = list.files(clipFiles, pattern = "minus.bw$",
     full.names = TRUE))
    bds = BSFDataSetFromBigWig(ranges = cs, meta = meta, silent = TRUE)

    # merge binding sites
    bds <- makeBindingSites(object = bds, bsSize = 9, minWidth = 2,
    minCrosslinks = 2, minClSites = 1)

    # annotate with original pureCLIP score
    bdsRe = annotateWithScore(bds, cs)
}
}
\seealso{
\code{\link{BSFind}}, \code{\link{globalScorePlot}}
}
