% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/brmsfit-methods.R
\name{summary.brmsfit}
\alias{summary.brmsfit}
\title{Create a summary of a fitted model represented by a \code{brmsfit} object}
\usage{
\method{summary}{brmsfit}(object, waic = FALSE, loo = FALSE, R2 = FALSE,
  priors = FALSE, prob = 0.95, use_cache = TRUE, ...)
}
\arguments{
\item{object}{An object of class \code{brmsfit}}

\item{waic, loo}{Logical; Indicating if the LOO or WAIC information
criteria should be computed and shown in the summary. 
Defaults to \code{FALSE}.}

\item{R2}{Logical; Indicating if the Bayesian R-squared
should be computed and shown in the summary. 
Defaults to \code{FALSE}.}

\item{priors}{Logical; Indicating if priors should be included 
in the summary. Default is \code{FALSE}.}

\item{prob}{A value between 0 and 1 indicating the desired probability 
to be covered by the uncertainty intervals. The default is 0.95.}

\item{use_cache}{Logical; Indicating if summary results should
be cached for future use by \pkg{rstan}. Defaults to \code{TRUE}.
For models fitted with earlier versions of \pkg{brms},
it may be necessary to set \code{use_cache} to
\code{FALSE} in order to get the \code{summary} 
method working correctly.}

\item{...}{Other potential arguments}
}
\description{
Create a summary of a fitted model represented by a \code{brmsfit} object
}
\author{
Paul-Christian Buerkner \email{paul.buerkner@gmail.com}
}
