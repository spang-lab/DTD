% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/function_mix_many_samples.R
\name{mix_samples}
\alias{mix_samples}
\title{Mix samples for loss-function learning DTD}
\usage{
mix_samples(expr.data, pheno, included.in.X, n.samples = 1000,
  n.per.mixture = 100, verbose = FALSE, normalize.to.count = TRUE)
}
\arguments{
\item{expr.data}{numeric matrix, with features as rows and samples as columns}

\item{pheno}{named vector of strings, with pheno information ('pheno')
for each sample in 'expr.data'. names(pheno)' must all be in
'colnames(expr.data)'}

\item{included.in.X}{vector of strings, indicating types that are in the
reference matrix. Only those types, and sorted in that order, will be
included in the quantity matrix. Notice, every profile of 'expr.data' might
be included in the mixture. But the quantity matrix only reports quantity
information for the cell types in 'included.in.X'. This means, that the
sum per mixture in the 'quantities' matrix must not add up to 1.}

\item{n.samples}{integer above 0, numbers of samples to be drawn}

\item{n.per.mixture}{integer above 0, below ncol(expr.data),
how many samples should be included per mixutre}

\item{verbose}{logical, should information be printed to console?}

\item{normalize.to.count}{logical, normalize each mixture?}
}
\value{
list with two entries: 'mixtures' and 'quantities'.
}
\description{
'mix_samples' takes a gene expresssion matrix ('expr.data'),
and 'pheno' information.
It then mixes the samples with known quantities such that it can be
used for loss-function learning digital tissue deconvolution.
For a mixture it randomly selects "n.samples" samples from "expr.data",
and averages over them. Using the information stored in pheno, it can get
the quantities per cell in each mixture.
Notice, in the mixtures, the frequency of a cell type is reflected
by their occurrence in 'pheno'. A cell type that is uncommon, can not occur
 frequently in the mixtures. In such a case, consider using
 \code{\link{mix_samples_with_jitter}}
}
\examples{
library(DTD)
random.data <- generate_random_data(
      n.types = 10,
      n.samples.per.type = 150,
      n.features = 250,
      sample.type = "Cell",
      feature.type = "gene"
      )

# normalize all samples to the same amount of counts:
normalized.data <- normalize_to_count(random.data)

# extract indicator list.
# This list contains the Type of the sample as value, and the sample name as name
indicator.list <- gsub("^Cell[0-9]*\\\\.", "", colnames(random.data))
names(indicator.list) <- colnames(random.data)

# extract reference matrix X
# First, decide which cells should be deconvoluted.
# Notice, in the mixtures there can be more cells than in the reference matrix.
include.in.X <- paste0("Type", 2:7)

percentage.of.all.cells <- 0.2
sample.X <- sample_random_X(
      included.in.X = include.in.X,
      pheno = indicator.list,
      expr.data = normalized.data,
      percentage.of.all.cells = percentage.of.all.cells
      )
X.matrix <- sample.X$X.matrix
samples.to.remove <- sample.X$samples.to.remove

# all samples that have been used in the reference matrix, must not be included in
# the test/training set
remaining.mat <- random.data[, -which(colnames(random.data) \%in\% samples.to.remove)]
train.samples <- sample(
      x = colnames(remaining.mat),
      size = ceiling(ncol(remaining.mat)/2),
      replace = FALSE
      )
test.samples <- colnames(remaining.mat)[which(!colnames(remaining.mat) \%in\% train.samples)]

train.mat <- remaining.mat[, train.samples]
test.mat <- remaining.mat[, test.samples]

indicator.train <- indicator.list[names(indicator.list) \%in\% colnames(train.mat)]
training.data <- mix_samples(
      expr.data = train.mat,
      pheno = indicator.train,
      included.in.X = include.in.X,
      n.samples = 500,
      n.per.mixture = 100,
      verbose = FALSE
      )

indicator.test <- indicator.list[names(indicator.list) \%in\% colnames(test.mat)]
test.data <-  mix_samples(
      expr.data = test.mat,
      pheno = indicator.test,
      included.in.X = include.in.X,
      n.samples = 500,
      n.per.mixture = 100,
      verbose = FALSE
      )
# In order to show, that in our mixtures, the sum over the quantities in a
# mixture might not be 1:
sum.per.mixture <- apply(test.data$quantities, 2, sum)
plot(sum.per.mixture)
}
