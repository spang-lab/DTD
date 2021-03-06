% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/function_normToCount.R
\name{normalize_to_count}
\alias{normalize_to_count}
\title{normalize_to_count}
\usage{
normalize_to_count(expr.data, count = NA)
}
\arguments{
\item{expr.data}{numeric matrix, with features as rows and samples as columns.
Notice, 'normalize_to_count' normalizes the columns of this matrix.}

\item{count}{float, 0 < 'count', to which every sample of expr.data is scaled.
If 'is.na(count)' count is set to nrow(expr.data)}
}
\value{
'ret', matrix with same dimension as 'expr.data'
}
\description{
'normalize_to_count' takes a numeric matrix 'expr.data' with only
non-negative entries and normalizes each column (=> sample) to a total
number of counts.\cr
For every sample i, each feature j gets scaled to
 \deqn{expr.data[j, i] = (count * expr.data[j, i]) / sum(expr.data[, i])}
}
\examples{
library(DTD)
some.matrix <- matrix(abs(rnorm(1000 * 5)), ncol = 5, nrow = 1000)
# each sample (=column) has different number of total counts:
apply(some.matrix, 2, sum)

normalized.matrix <- normalize_to_count(some.matrix)

# check:
apply(normalized.matrix, 2, sum)
}
