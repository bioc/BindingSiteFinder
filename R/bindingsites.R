#' Define equally sized binding sites from peak calling results and iCLIP
#' crosslink events.
#'
#' This function performs the merging of single nucleotide crosslink sites into
#' binding sites of a user defined width (\code{bsSize}). Depending on the
#' desired output width crosslink sites with a distance closer than
#' \code{bsSize} -1 are concatenated. Initially all input regions are
#' concatenated and then imperatively merged and extended. Concatenated regions
#' smaller than \code{minWidth} are removed prior to the merge and extension
#' routine. This prevents outlier crosslink pileup, eg. mapping artifacts
#' to be integrated into the final binding sites. All remaining regions are
#' further processed and regions larger than the desired output width are
#' interactively split up by setting always the position with the highest
#' number of crosslinks as center. Regions smaller than the desired width are
#' symmetrically extended. Resulting binding sites are then filtered by the
#' defined constraints.
#'
#' The \code{bsSize} argument defines the final output width of the merged
#' binding sites. It has to be an odd number, to ensure that a binding site
#' has a distinct center.
#'
#' The \code{minWidth} parameter is used to describe the minimum width a ranges
#' has to be after the initial concatenation step. For example:
#' Consider bsSize = 9 and minWidth = 3. Then all initial crosslink sites that
#' are closer to each other than 8 nucleotides (bsSize -1) will be concatenated.
#' Any of these ranges with less than 3 nucleotides of width will be removed,
#' which reflects about 1/3 of the desired binding site width.
#'
#' The argument \code{minCrosslinks} defines how many positions of the binding
#' sites are covered with at least one crosslink event. This threshold has to
#' be defined in conjunction with the binding site width. A default value of 3
#' with a binding site width of 9 means that 1/3 of all positions in the final
#' binding site must be covered by a crosslink event. Setting this filter to 0
#' deactivates it.
#'
#' The \code{minClSites} argument defines how many positions of the binding site
#' must have been covered by the original crosslink site input. If the input was
#' based on the single nucleotide crosslink positions computed by PureCLIP than
#' this filter checks for the number of positions originally identified by
#' PureCLIP in the computed binding sites. The default of \code{minClSites} = 1
#' essentially deactivates this filter. Setting this filter to 0 deactivates it.
#'
#' The options \code{centerIsClSite} and \code{centerIsSummit} ensure that the
#' center of each binding site is covered by an initial crosslink site and
#' represents the summit of crosslink events in the binding site, respectively.
#'
#' The option \code{sub.chr} allows to run the binding site merging on a
#' smaller subset (eg. "chr1") for improoved computational speed when testing
#' the effect of various binding site width and filtering options.
#'
#' @param object a BSFDataSet object (see \code{\link{BSFDataSet}})
#' @param bsSize an odd integer value specifying the size of the output
#' binding sites
#' @param minWidth the minimum size of regions that are subjected to the
#' iterative merging routine, after the initial region concatenation.
#' @param minCrosslinks the minimal number of positions to overlap with at least
#' one crosslink event in the final binding sites
#' @param minClSites the minimal number of crosslink sites that have to
#' overlap a final binding site
#' @param centerIsClSite logical, whether the center of a final binding
#' site must be covered by an initial crosslink site
#' @param centerIsSummit logical, whether the center of a final binding
#' site must exhibit the highest number of crosslink events
#' @param sub.chr chromosome identifier (eg, chr1, chr2) used for subsetting the
#' BSFDataSet object. This option can be used for testing different
#' parameter options
#' @param quiet logical, whether to print info messages
#'
#' @return an object of type BSFDataSet with modified ranges
#'
#' @seealso \code{\link{BSFDataSet}}, \code{\link{BSFind}},
#' \code{\link{mergeCrosslinkDiagnosticsPlot}},
#' \code{\link{makeBsSummaryPlot}}
#'
#' @import GenomicRanges methods
#' @importFrom GenomeInfoDb seqlevels
#' @importFrom dplyr bind_rows
#'
#' @examples
#'
#' # load data
#' files <- system.file("extdata", package="BindingSiteFinder")
#' load(list.files(files, pattern = ".rda$", full.names = TRUE))
#'
#' # standard options, no subsetting
#' bds <- makeBindingSites(object = bds, bsSize = 9, minWidth = 2,
#' minCrosslinks = 2, minClSites = 1)
#'
#' # standard options, with subsetting
#' bds <- makeBindingSites(object = bds, bsSize = 9, minWidth = 2,
#' minCrosslinks = 2, minClSites = 1, sub.chr = "chr22")
#'
#' @export
makeBindingSites <- function(object,
                             bsSize = NULL,
                             minWidth = 2,
                             minCrosslinks = 2,
                             minClSites = 1,
                             centerIsClSite = TRUE,
                             centerIsSummit = TRUE,
                             sub.chr = NA,
                             quiet = FALSE) {
    stopifnot(is(object, "BSFDataSet"))

    # INPUT CHECKS
    # --------------------------------------------------------------------------

    # check meta data
    this.meta = getMeta(object)
    if (length(levels(this.meta$condition)) > 1) {
        msg0 = paste0("Found ", length(levels(this.meta$condition)), " different conditions in the input object.\n")
        msg1 = paste0("It is recommended to only use data from a single condition.\n")
        msg2 = paste0("Please run makeBindingSite sparately for each condition, then combine both objects with combineBSF.\n ")
        if(!quiet) warning((c(msg0,msg1,msg2)))
    }

    # check if bsSize was estimated before or if input is needed
    if (!is.null(object@params$bsSize) & !is.null(object@params$geneFilter)) {
        bsSize = object@params$bsSize
    } else {
        if (is.null(bsSize)) {
            stop("bsSize not set. Please provide a desired binding site width.")
        }
    }
    # check integrity of input values
    if (c(bsSize %% 2) == 0) {
        stop("bsSize is even. An odd number is required to have a distinct binding site center.")
    }
    if (!is.numeric(bsSize)) {
        stop("bsSize must be of type numeric")
    }
    if (!is.numeric(minWidth)) {
        stop("minWidth must be of type numeric")
    }
    if (!is.numeric(minClSites)) {
        stop("minClSites must be of type numeric")
    }
    if (!is.numeric(minCrosslinks)) {
        stop("minCrosslinks must be of type numeric")
    }
    if (minClSites > bsSize) {
        stop("Number of forced crosslink sites is larger than desired binding site size. ")
    }

    #---------------------------------------------------------------------------
    # logical errors
    if (bsSize < minWidth) {
        warning("Desired binding site size is smaller than the minimum merging width.\n
                Be sure to check the minWidth and bsSize parameters")
    }

    #---------------------------------------------------------------------------
    # subsetting options
    if (!is.na(sub.chr)) {
        if (!is.character(sub.chr)) {
            stop("sub.chr must be of type character")
        }
        # subset the signal
        objectSub = .subsetByChr(object = object, chr = sub.chr)
        sgn = getSignal(objectSub)
        rngS0 = getRanges(objectSub)
    }
    # no subsetting
    if (is.na(sub.chr)) {
        sgn = getSignal(object)
        rngS0 = getRanges(object)
    }
    if (length(rngS0) == 0) {
        stop("0 ranges as input.")
    }

    # ---
    # Store function parameters
    optstr = list(bsSize = bsSize, minWidth = minWidth,
                  minCrosslinks = minCrosslinks, minClSites = minClSites,
                  centerIsClSite = centerIsClSite,
                  centerIsSummit = centerIsSummit, sub.chr = sub.chr)
    object@params$makeBindingSites = optstr

    #---------------------------------------------------------------------------
    # prepare data for merging
    sgnMerge = .collapseSamples(sgn)

    # execute filter and merging routines
    mergeCs = .mergeCrosslinkSites(
        rng = rngS0,
        sgn = sgnMerge,
        bsSize = bsSize,
        minWidth = minWidth,
        computeOption = "full"
    )
    rngS1 = mergeCs$rng

    # ---
    # Store data for diagnostic plot in list
    plotDf = mergeCs$countDf
    object@plotData$makeBindingSites$mergeCsData = plotDf


    if (length(rngS1) <= 0) {
        stop("No ranges left after initial crosslink merging. ")
    }

    rngS2 = .filterMinCrosslinks(rng = rngS1,
                                 sgn = sgnMerge,
                                 minCrosslinks = minCrosslinks)
    if (length(rngS2) <= 0) {
        stop("No ranges left after appying minimum crosslink events filter. ")
    }

    rngS3 = .filterMinClSites(rng = rngS2,
                              rng0 = rngS0,
                              minClSites = minClSites)
    if (length(rngS3) <= 0) {
        stop("No ranges left after appying minimum crosslink sites filter. ")
    }

    if (isTRUE(centerIsClSite)) {
        rngS4 = .filterCenterClSite(rng = rngS3, rng0 = rngS0)
    } else {
        rngS4 = rngS3
    }
    if (length(rngS4) <= 0) {
        stop("No ranges left after appying crosslink site has to be center of binding site filter. ")
    }

    if (isTRUE(centerIsSummit)) {
        rngS5 = .filterCenterSummit(rng = rngS4, sgn = sgnMerge)
    } else {
        rngS5 = rngS4
    }
    if (length(rngS5) <= 0) {
        stop("No ranges left after appying binding site center has to be summit filter. ")
    }
    #---------------------------------------------------------------------------
    # Add meta information
    rngS5$bsSize = bsSize

    #---------------------------------------------------------------------------
    # summarize number of ranges after each step
    reportDf = data.frame(
        Option = c(
            "inputRanges",
            "mergeCrosslinkSites",
            "minCrosslinks",
            "minClSites",
            "centerIsClSite",
            "centerIsSummit"
        ),
        nRanges = c(
            length(rngS0),
            length(rngS1),
            length(rngS2),
            length(rngS3),
            ifelse(isTRUE(centerIsClSite),
                   length(rngS4), NA),
            ifelse(isTRUE(centerIsSummit),
                   length(rngS5), NA)
        )
    )
    #---------------------------------------------------------------------------
    # check output
    if (!all(match(seqlevels(rngS5),unique(seqnames(rngS5)), nomatch = 0) > 0)) {
        msgWarningin = paste0("Current definition does not result in binding sites on all chromosomes where signal was present.\n No binding sites on: ",
                              paste(seqlevels(rngS5)[
                                  !match(seqlevels(rngS5),
                                         unique(seqnames(rngS5)),
                                         nomatch = 0) > 0], collapse = " "), "\n")
        if(!quiet) message(msgWarningin)
    }

    # ---
    # Store results for plotting
    object@plotData$makeBindingSites$data = reportDf
    # ---
    # Store for results
    resultLine = data.frame(
        funName = "makeBindingSites()", class = "transform",
        nIn = length(rngS0), nOut = length(rngS5),
        per = paste0(round(length(rngS5)/ length(rngS0), digits = 2)*100,"%"),
        options = paste0("bsSize=", bsSize, ", minWidth=", minWidth, ", minCrosslinks=", minCrosslinks,
                         ", minClSites=", minClSites, ", centerIsClSite=", centerIsClSite,
                         ", centerIsSummit=", centerIsSummit, ", sub.chr=", sub.chr)
    )
    object@results = rbind(object@results, resultLine)
    object@params$bsSize = bsSize

    #---------------------------------------------------------------------------
    # update BSFDataSet with new ranges information
    objectNew = setRanges(object, rngS5, quiet = TRUE)
    objectNew = setSignal(objectNew, sgn, quiet = TRUE)
    objectNew = setSummary(objectNew, reportDf)
    ClipDS = objectNew
    return(ClipDS)
}

################################################################################
# unexported functions

.mergeCrosslinkSites <- function(rng, # a GRanges object; -> holds PureCLIP sites, is single nt size
                                 sgn, # the crosslink signal merged per replicates
                                 bsSize, # the binding site size to compute
                                 minWidth, # the minimal width sites should be retained after intital merge
                                 computeOption = c("full", "simple")
) {

    # initialize local variables
    w <- n.x <- n.y <- iteration <- s <- NULL

    # handle compute options
    computeOption = match.arg(computeOption, choices = c("full", "simple"))

    # summarize signal over all replicates for mergeing
    sgnMergePlus = sgn$signalPlus
    sgnMergeMinus = sgn$signalMinus

    rngS1 = rng

    ### Merge peaks for given bs size
    rngS2 = reduce(rngS1, min.gapwidth = bsSize - 1)

    ### Keep only regions that are larger or equal to minWidth
    # -> if minWiidth == 3, then the smallest range to consider is 3
    rngS3 = rngS2[width(rngS2) >= minWidth]
    names(rngS3) = seq_along(rngS3)

    ### Center detection and extension
    rngCenterPlus <- GRanges()
    rngCenterMinus <- GRanges()
    rngToProcessPlus <- subset(rngS3, strand == "+")
    rngToProcessMinus <- subset(rngS3, strand == "-")

    countDf = data.frame()
    Counter = 0
    while (TRUE) {
        # quit if no more regions to check
        if (length(rngToProcessMinus) == 0 &
            length(rngToProcessPlus) == 0) {
            break
        } else {
            if (length(rngToProcessPlus) != 0) {
                # get max xlink position of each peak
                peaksMaxPosPlus = as.matrix(sgnMergePlus[rngToProcessPlus])
                peaksMaxPosPlus[is.na(peaksMaxPosPlus)] = -Inf
                peaksMaxPosPlus = max.col(peaksMaxPosPlus,
                                          ties.method = "first")

                # make new peaks centered arround max position
                currentPeaksPlus = rngToProcessPlus
                start(currentPeaksPlus) =
                    start(currentPeaksPlus) + peaksMaxPosPlus -1
                end(currentPeaksPlus) = start(currentPeaksPlus)
                currentPeaksPlus = currentPeaksPlus + ((bsSize - 1) / 2)
                # store peaks
                rngCenterPlus = c(rngCenterPlus, currentPeaksPlus)
                # remove peak regions from rest of possible regions
                currentPeaksPlus = as(currentPeaksPlus + ((bsSize - 1) / 2),
                                      "GRangesList")

                # update peak regions that are left for processing
                rngToProcessPlus = unlist(psetdiff(rngToProcessPlus,
                                                   currentPeaksPlus))
            }
            if (length(rngToProcessMinus) != 0) {
                peaksMaxPosMinus = as.matrix(sgnMergeMinus[rngToProcessMinus])
                peaksMaxPosMinus[is.na(peaksMaxPosMinus)] = -Inf
                peaksMaxPosMinus = max.col(peaksMaxPosMinus,
                                           ties.method = "last")

                currentPeaksMinus = rngToProcessMinus
                start(currentPeaksMinus) =
                    start(currentPeaksMinus) + peaksMaxPosMinus -1
                end(currentPeaksMinus) = start(currentPeaksMinus)
                currentPeaksMinus = currentPeaksMinus + ((bsSize - 1) / 2)

                rngCenterMinus = c(rngCenterMinus, currentPeaksMinus)

                currentPeaksMinus =
                    as(currentPeaksMinus + ((bsSize - 1) /2),
                       "GRangesList")

                rngToProcessMinus = unlist(psetdiff(rngToProcessMinus,
                                                    currentPeaksMinus))
            }
            Counter = Counter + 1
        }
        # compute option simple exits the loop after the first iteration, which is
        # when the first round of merge and extend is done
        if (computeOption == "simple") {
            if (length(rngCenterPlus) > 0 | length(rngCenterMinus) > 0){
                break
            }
        }

        # if not simple option is selected, write down stats
        countPlus = tibble(w = width(rngToProcessPlus)) %>% dplyr::count(w)
        countMinus = tibble(w = width(rngToProcessMinus)) %>% dplyr::count(w)
        currCountDf = dplyr::left_join(countPlus, countMinus, by = c("w")) %>%
            replace_na(replace = list(n.x = 0, n.y = 0)) %>% group_by(w) %>%
            mutate(s = sum(n.x + n.y, na.rm = FALSE)) %>%
            mutate(iteration = Counter) %>%
            dplyr::select(iteration, w, s)
        countDf = bind_rows(countDf, currCountDf)

    }
    rngS4 = c(rngCenterPlus, rngCenterMinus)
    rngS4 = .sortRanges(rngS4)

    mcols(rngS4)$bsID = paste0("BS", seq_along(rngS4))

    # manage return
    ret = list(rng = rngS4, countDf = countDf)
    return(ret)
}

.filterMinCrosslinks <- function(rng,
                                 sgn,
                                 minCrosslinks) {
    # filter option disabled
    if (minCrosslinks == 0) {
        rngCurr = rng
        return(rngCurr)
    }
    # filter option should be used
    if (minCrosslinks != 0) {
        sgnMergePlus = sgn$signalPlus
        sgnMergeMinus = sgn$signalMinus

        # check if both strands exists
        if ("+" %in% unique(strand(rng))) {
            # split by strand plus
            rngCurrPlus = rng[strand(rng) == "+"]
            rngCurrPlusMat = as.matrix(sgnMergePlus[rngCurrPlus])
            rngCurrPlus = rngCurrPlus[apply((rngCurrPlusMat > 0), 1, sum) >
                                          minCrosslinks]
        }
        if (!"+" %in% unique(strand(rng))) {
            rngCurrPlus = NULL
        }

        if ("-" %in% unique(strand(rng))) {
            # split by strand minus
            rngCurrMinus = rng[strand(rng) == "-"]
            rngCurrMinusMat = as.matrix(sgnMergeMinus[rngCurrMinus])
            rngCurrMinus = rngCurrMinus[apply((rngCurrMinusMat > 0), 1, sum) >
                                            minCrosslinks]
        }
        if (!"-" %in% unique(strand(rng))) {
            rngCurrMinus = NULL
        }

        # combine sort return
        rngCurr = c(rngCurrPlus, rngCurrMinus)
        rngCurr = .sortRanges(rngCurr)
        # rngCurr = GenomeInfoDb::sortSeqlevels(rngCurr)
        # rngCurr = sort(rngCurr)
        return(rngCurr)
    }



}

#' @importFrom S4Vectors queryHits
.filterCenterClSite <- function(rng, rng0) {
    rngCurr = rng - (unique(width(rng)) - 1) / 2
    rngCurr = rng[queryHits(findOverlaps(rngCurr, rng0))]
    # combine sort return
    rngCurr = .sortRanges(rngCurr)
    return(rngCurr)
}

.filterCenterSummit <- function(rng, sgn) {
    sgnMergePlus = sgn$signalPlus
    sgnMergeMinus = sgn$signalMinus

    if ("+" %in% unique(strand(rng))) {
        rngPlus = rng[strand(rng) == "+"]
        rngCurrPlusMat = as.matrix(sgnMergePlus[rngPlus])
        rngCurrPlusCount = apply(rngCurrPlusMat, 1, max)
        rngCurrPlus = rngPlus[rngCurrPlusCount == rngCurrPlusMat[, (
            (unique(width(rng)) -1) / 2) + 1]]
    }
    if (!"+" %in% unique(strand(rng))) {
        rngCurrPlus = NULL
    }

    if ("-" %in% unique(strand(rng))) {
        rngMinus = rng[strand(rng) == "-"]
        rngCurrMinusMat = as.matrix(sgnMergeMinus[rngMinus])
        rngCurrMinusCount = apply(rngCurrMinusMat, 1, max)
        rngCurrMinus = rngMinus[rngCurrMinusCount == rngCurrMinusMat[, (
            (unique(width(rng)) - 1) / 2) + 1]]
    }
    if (!"-" %in% unique(strand(rng))) {
        rngCurrMinus = NULL
    }

    # combine sort return
    rngCurr = c(rngCurrPlus, rngCurrMinus)
    rngCurr = .sortRanges(rngCurr)
    return(rngCurr)
}

.filterMinClSites <- function(rng, rng0, minClSites) {
    # filter option disabled
    if (minClSites == 0) {
        rngCurr = rng
        return(rngCurr)
    }
    # filter option is used
    if (minClSites != 0) {
        overlaps = findOverlaps(rng, rng0)
        freq = table(queryHits(overlaps))
        idx = as.numeric(names(freq[freq >= minClSites]))
        rngCurr = rng[idx]
        # combine sort return
        rngCurr = .sortRanges(rngCurr)
        return(rngCurr)
    }
}

