#' Visualize the path of each \eqn{g_i} over all iterations
#'
#' With this function the regression path of each \eqn{g_i} over all iterations
#' can be plotted. Notice, that if there are many genes in your model, it may
#' be hard to distinguish between each path. As a solution the parameter
#' "number.pics" can be set to a higher integer.
#' Then, the visualization will be split into more pictures.
#' In each picture all \eqn{g_i} get collected that end up in the same
#' quantile range. E.g if you split into 3 pictures, the first picture includes
#' all genes that result into the quantile range from 0\% Qu to 33\% Qu of all
#' g.\cr There are parameters (G.TRANSFORM.FUN and ITER.TRANSFORM.FUN) to
#' transform the g vector, and iteration number. These make the plot more
#' understandable, e.g. if the distribution of the g vector is dominated by
#  same outliers, applying a log transformation helps.
#' For an example see section "g-Path" in the package vignette
#' `browseVignettes("DTD")`
#'
#' @param DTD.model either a numeric vector with length of nrow(X), or a list
#' returned by \code{\link{train_deconvolution_model}},
#' \code{\link{DTD_cv_lambda_cxx}}, or \code{\link{descent_generalized_fista}}.
#' @param number.pics integer, into how many pictures should the
#' resutlt be split
#' @param G.TRANSFORM.FUN function, that expects a vector of numerics,
#' and returns a vector of the same length. Will be applied on each intermediate
#''g' vector. Set 'G.TRANSFORM.FUN' to identity if no transformation is required.
#' If you change 'G.TRANSFORM.FUN' don't forget to adjust the y.lab parameter.
#' @param ITER.TRANSFORM.FUN function, that expects a vector of numerics,
#' and returns a vector of the same length. Will be applied on the
#' iteration/x.axis of the plot. Set 'ITER.TRANSFORM.FUN' to identity if no
#' transformation is required. If you change 'ITER.TRANSFORM.FUN' don't forget
#' to adjust the x.lab parameter
#' @param y.lab string, used as y label on the plot
#' @param x.lab string, used as x label on the plot
#' @param show.legend logical, should the legend be plotted? Notice that the
#' legend will be plotted in a additional figure, and can be visualized via
#' 'grid::grid.draw', or 'plot'
#' @param subset NA, or a vector of strings,that match the rownames of
#' 'DTD.model$History'. Only these entries will be visualized.
#' If set to NA, all entries are plotted
#' @param title string, additionally title
#'
#' @import ggplot2
#' @import reshape2
#' @return list, with "gPath" entry. "gPath" will be a ggplot object.
#' Depending on "show.legend" the list has a second entry named "legend".
#' "legend" will be a grid object, which can be plotted via 'plot',
#' or 'grid::grid.draw'.
#' @export
ggplot_gpath <- function(DTD.model,
                         number.pics = 3,
                         G.TRANSFORM.FUN = log10p1,
                         ITER.TRANSFORM.FUN = identity,
                         y.lab = "log10(g+1)",
                         x.lab = "iteration",
                         subset = NA,
                         title = "",
                         show.legend = FALSE) {
  # safety check: number.pics
  test <- test_integer(number.pics,
                       output.info = c("ggplot_gpath", "number.pics"),
                       min = 1,
                       max = Inf)
  # end -> number.pics
  # safety check: y.lab
  y.lab <- test_string(test.value = y.lab, output.info = c("ggplot_gpath", "y.lab"))
  # end -> y.lab
  # safety check: x.lab
  x.lab <- test_string(test.value = x.lab, output.info = c("ggplot_gpath", "x.lab"))
  # end -> y.lab
  # safety check: title
  title <- test_string(test.value = title, output.info = c("ggplot_gpath", "title"))
  # end -> title
  # safety check: show.legend
  test <- test_logical(test.value = show.legend,
                       output.info = c("ggplot_gpath", "show.legend"))
  # end -> show.legend

  # for gPath, the following elements are needed:
  # - 'History' of learning
  # Either it is provided as a list ...
  if(is.list(DTD.model)){ # model is provided as list. Therefore, select 'best.model':
    if("best.model" %in% names(DTD.model)){
      fista.output <- DTD.model$best.model
      if("History" %in% names(fista.output)){
        f.history <- fista.output$History
      }
    }else{
      if(!"History" %in% names(DTD.model)){
        stop("In ggplot_gpath: 'DTD.model' can not be used (provide a DTD.model with 'History' entry)")
      }else{
        fista.output <- DTD.model
      }
    }
  }else{
    # ... or only the History matrix is provided:
    if(!is.matrix(DTD.model)){
      stop("In ggplot_gpath: 'DTD.model' can not be used (provide a DTD.model with 'History' entry)")
    }else{
      f.history <- DTD.model
    }
  }
  tweak <- f.history[, ncol(f.history)]
  # safety check: G.TRANSFORM.FUN
  useable.g.trans.fun <- try(G.TRANSFORM.FUN(tweak), silent = TRUE)
  if(any(grepl(x = useable.g.trans.fun, pattern = "Error")) || any(!is.numeric(useable.g.trans.fun))){
    stop("In ggplot_gpath: 'G.TRANSFORM.FUN' does not return numeric vector.")
  }
  # end -> G.TRANSFORM.FUN

  # safety check: ITER.TRANSFORM.FUN
  useable.iter.trans.fun <- try(ITER.TRANSFORM.FUN(1:length(tweak)), silent = TRUE)
  if(any(grepl(x = useable.iter.trans.fun, pattern = "Error")) || any(!is.numeric(useable.iter.trans.fun))){
    stop("In ggplot_gpath: 'ITER.TRANSFORM.FUN' does not return numeric vector.")
  }
  # end -> ITER.TRANSFORM.FUN

  # if:
  # - subset is not na,
  # - any subset is within rownames
  if (!all(is.na(subset)) && any(subset %in% rownames(f.history))) {
    subset <- subset[subset %in% rownames(f.history)]
    f.history <- f.history[subset, , drop = FALSE]
    tweak <- tweak[subset]
  } else {
    if (!all(is.na(subset))) {
      message("In ggplot_gpath: subset could not be used, therefore complete tweak, and history will be used\n")
    }
  }

  # We start by calculating in which quantile range each gene falls:
  # Therefore, we calculate how many quantile ranges are necessary (depending on the number.pics parameter)
  pic.sep <- as.numeric(format(x = seq(0, 1, length.out = (number.pics + 1))[2:(number.pics + 1)], digits = 2))
  # Next we calculate the value of the quantiles in our g vector ...
  quantile.values <- sapply(X = pic.sep, FUN = stats::quantile, x = abs(tweak), na.rm = TRUE)
  # ... and name them without the "%" sign
  names(quantile.values) <- gsub("%", "", names(quantile.values))

  # Now we know the quantile values, next we have to test in which quantile ranges our value fall.
  # Therefore the following function helps.
  # It takes a numeric value x, and returns the position of the first quantile value that is below it
  quantile.apply.function <- function(x, values = quantile.values) {
    winner <- which(values >= abs(x))[1]
    return(winner)
  }
  # apply the function ...
  quantile.per.gene <- sapply(tweak, quantile.apply.function)
  # ... set names
  names(quantile.per.gene) <- rownames(f.history)

  # For easy visualization with the ggplot2 package we need the f.history matrix in long format:
  f.h.melt <- reshape2::melt(f.history,
                             varnames = c("geneName", "iteration"),
                             value.name = "g"
  )

  # add the "q"unatile "p"er "g"ene information (with the names, not the positions!)
  f.h.melt$qpg <- factor(as.numeric(names(quantile.values[quantile.per.gene[f.h.melt$geneName]])))
  # Reset the levels to more interpretable
  levels(f.h.melt$qpg) <- paste0("below ", levels(f.h.melt$qpg), "% Quantile")

  # Transform g and iter
  f.h.melt$g <- G.TRANSFORM.FUN(f.h.melt$g)
  f.h.melt$iteration <- ITER.TRANSFORM.FUN(f.h.melt$iteration)


  # Plot the picture (notice that this plot is with the legend!)
  pics <- ggplot2::ggplot(
    f.h.melt,
    aes_string(x = "iteration", y = "g", group = "geneName", colour = "geneName")
  ) +
    ggplot2::geom_line() +
    ggplot2::ylab(y.lab) +
    ggplot2::xlab(x.lab) +
    ggplot2::ggtitle(title) +
    ggplot2::facet_grid(. ~ qpg)

  ret <- list()
  # Store the picture WITHOUT the legend
  ret[["gPath"]] <- pics + theme(legend.position = "none")

  # Only if required, extract the legend from "pics" and provide as a entry in ret
  if (show.legend) {
    tmp <- ggplot2::ggplot_gtable(ggplot_build(pics))
    tmp.leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
    legend <- tmp$grobs[[tmp.leg]]
    ret[["legend"]] <- legend
  }
  # return ret (including the picture without legend, and the legend if required)
  return(ret)
}


log10p1 <- function(g){return(log10(g+1))}
