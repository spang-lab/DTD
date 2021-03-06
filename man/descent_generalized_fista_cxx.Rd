% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/function_FISTA.R
\name{descent_generalized_fista_cxx}
\alias{descent_generalized_fista_cxx}
\title{Descent generalized FISTA \cr
(fast iterative shrinkage thresholding algorithm)}
\usage{
descent_generalized_fista_cxx(model, lambda = 0.01, maxit = 500,
  stop.crit.threshold = 1e-13, save.all.tweaks = FALSE,
  learning.rate = NA, line.search.speed = 2, cycles = 5,
  use.restart = TRUE, verbose = FALSE, ...)
}
\arguments{
\item{model}{a model as constructed in interface_cxx.R}

\item{lambda}{non-negative float, regularization factor for ST.FUN function.}

\item{maxit}{integer, maximum number of iterations for the iterative
minimization.}

\item{stop.crit.threshold}{numeric value. The change in either the gradient
or nesterov step has to be at least 'stop.crit.threshold', or the algorithm
will stop.}

\item{save.all.tweaks}{logical, should all tweak vectores during all
iterations be stored.}

\item{learning.rate}{float, step size during optimization. If it is NA,
the learning rate will be estimated as published by Barzilai & Borwein 1988.
Notice, the algorithm adjusts the learning rate during optimization.}

\item{line.search.speed}{numeric, factor with which the learning rate
changes during optimization. If 'line.search.speed' is, e.g.,
2, the learning rate gets doubled if the highest 'cycle' led to the best
eval score. If the 'cycle = 0' led to the best eval score, it would get
halved.}

\item{cycles}{integer, in each iteration one gradient is calculated.
To find the best step size, we do "cycles" steps, and evaluate each of
them to find the best step size.}

\item{use.restart}{logical, restart the algorithm if the update was
not a descent step.}

\item{verbose}{logical, if set to true, will output information during
iteration.}
}
\value{
a list that contains the trained model and its History
}
\description{
descent_generalized_fista takes as input a vector, a gradient function
and an evaluation function (and some additional parameters/functions).
Then, it iteratively minimizes the tweak vector via FISTA
(Beck and Teboulle 2009).
Basically,
the following equations are used:\cr
# prelimary initialization step\cr
for k = 2,..., maxit:\cr
\itemize{
    \item y_vec = NORM.FUN(y_vec)
    \item grad = F.GRAD.FUN(y_vec)\cr
    \item# find best step size between 0 and learning.rate\cr
         for step.size = 0,..., learning.rate:\cr
    \itemize{
        \item u = ST.FUN(y_vec - step.size * grad, step.size * lambda)\cr
        \item eval = EVAL.FUN(u)
    }
    \item # only keep u with minimal eval\cr
    \item tweak.old = tweak.vec\cr
    \item # if it was a descent step: \cr tweak.vec = u
    \item # if it was not a descent step: \cr tweak.vec = tweak.vec \cr#(and restart as suggested in  O’Donoghue & Candes (2012))
    \item # Nesterov extrapolation:
    \item nesterov.direction = tweak.vec - tweak.old
    \item # find best extrapolation size bewteen 0 and FACTOR.FUN(k):\cr
         for ne = 0 ,... FACTOR.FUN(k):\cr
    \itemize{
        \item y_vec = u_vec + ne * nesterov.direction
        \item eval = EVAL.FUN(y_vec)
    }
    \item # only keep y_vec with minimal eval
    \item stop criterion: if the descent in either the gradient
    or the nesterov step was below a critical value, then stop.
}
}
