test_that(paste("make_standata returns correct data names ",
                "for fixed and random effects"), {
  expect_equal(names(make_standata(rating ~ treat + period + carry 
                                   + (1|subject), data = inhaler)),
               c("N", "Y",  "K", "X", "Z_1_1",
                 "J_1", "N_1", "M_1", "NC_1", "prior_only"))
  expect_equal(names(make_standata(rating ~ treat + period + carry 
                                   + (1+treat|id|subject), data = inhaler,
                                   family = "categorical")),
               c("N", "Y", "K_X2", "X_X2", "Z_1_X2_1", "Z_1_X2_2", 
                 "K_X3", "X_X3", "Z_1_X3_3", "Z_1_X3_4",
                 "K_X4", "X_X4", "Z_1_X4_5", "Z_1_X4_6",
                 "J_1", "N_1", "M_1", "NC_1", "ncat",
                 "prior_only"))
  expect_equal(names(make_standata(rating ~ treat + period + carry 
                                   + (1+treat|subject), data = inhaler,
                                   control = list(not4stan = TRUE))),
               c("N", "Y", "K", "X", "Z_1", "J_1", "N_1", "M_1",
                 "NC_1", "prior_only"))
  
  dat <- data.frame(y = 1:10, g = 1:10, h = 11:10, x = rep(0,10))
  expect_equal(names(make_standata(y ~ x + (1|g) + (1|h), family = "poisson",
                                   data = dat)),
               c("N", "Y", "K", "X", "Z_1_1", "Z_2_1",
                 "J_1", "N_1", "M_1", "NC_1", "J_2", "N_2", "M_2", "NC_2", 
                 "prior_only"))
  expect_true(all(c("Z_1_1", "Z_1_2", "Z_2_1", "Z_2_2") %in%
                  names(make_standata(y ~ x + (1+x|g/h), dat))))
  expect_equal(make_standata(y ~ x + (1+x|g+h), dat),
               make_standata(y ~ x + (1+x|g) + (1+x|h), dat))
})

test_that(paste("make_standata handles variables used as fixed effects", 
                "and grouping factors at the same time"), {
  data <- data.frame(y = 1:9, x = factor(rep(c("a","b","c"), 3)))
  standata <- make_standata(y ~ x + (1|x), data = data)
  expect_equal(colnames(standata$X), c("Intercept", "xb", "xc"))
  expect_equal(standata$J_1, as.array(rep(1:3, 3)))
  standata2 <- make_standata(y ~ x + (1|x), data = data, 
                             control = list(not4stan = TRUE))
  expect_equal(colnames(standata2$X), c("Intercept", "xb", "xc"))
})

test_that(paste("make_standata returns correct data names", 
                "for addition and cs variables"), {
  dat <- data.frame(y = 1:10, w = 1:10, t = 1:10, x = rep(0,10), 
                          c = sample(-1:1,10,TRUE))
  expect_equal(names(make_standata(y | se(w) ~ x, dat, gaussian())), 
               c("N", "Y", "K", "X", "se", "prior_only"))
  expect_equal(names(make_standata(y | weights(w) ~ x, dat, "gaussian")), 
               c("N", "Y", "K", "X", "weights", "prior_only"))
  expect_equal(names(make_standata(y | cens(c) ~ x, dat, "student")), 
               c("N", "Y", "K", "X", "cens", "prior_only"))
  expect_equal(names(make_standata(y | trials(t) ~ x, dat, "binomial")), 
               c("N", "Y", "K", "X", "trials", "prior_only"))
  expect_equal(names(make_standata(y | trials(10) ~ x, dat, "binomial")), 
               c("N", "Y", "K", "X", "trials", "prior_only"))
  expect_equal(names(make_standata(y | cat(11) ~ x, dat, "acat")),
               c("N", "Y", "K", "X", "disc", "ncat", "prior_only"))
  expect_equal(names(make_standata(y | cat(10) ~ x, dat, cumulative())), 
               c("N", "Y", "K", "X", "disc", "ncat", "prior_only"))
  sdata <- make_standata(y | trunc(0,20) ~ x, dat, "gaussian")
  expect_true(all(sdata$lb == 0) && all(sdata$ub == 20))
  sdata <- make_standata(y | trunc(ub = 21:30) ~ x, dat)
  expect_true(all(all(sdata$ub == 21:30)))
})

test_that(paste("make_standata accepts correct response variables", 
                "depending on the family"), {
  expect_equal(make_standata(y ~ 1, data = data.frame(y = seq(-9.9,0,0.1)), 
                             family = "student")$Y, as.array(seq(-9.9,0,0.1)))
  expect_equal(make_standata(y ~ 1, data = data.frame(y = 1:10), 
                             family = "binomial")$Y, as.array(1:10))
  expect_equal(make_standata(y ~ 1, data = data.frame(y = 10:20), 
                             family = "poisson")$Y, as.array(10:20))
  expect_equal(make_standata(y ~ 1, data = data.frame(y = rep(-c(1:2),5)), 
                             family = "bernoulli")$Y, as.array(rep(1:0,5)))
  expect_equal(make_standata(y ~ 1, data = data.frame(y = rep(c(TRUE, FALSE),5)),
                             family = "bernoulli")$Y, as.array(rep(1:0,5)))
  expect_equal(make_standata(y ~ 1, data = data.frame(y = rep(1:10,5)), 
                             family = "categorical")$Y, as.array(rep(1:10,5)))
  expect_equal(make_standata(y ~ 1, data = data.frame(y = rep(-4:5,5)), 
                             family = "categorical")$Y, as.array(rep(1:10,5)))
  expect_equal(make_standata(y ~ 1, data = data.frame(y = factor(rep(-4:5,5))), 
                             family = "categorical")$Y, as.array(rep(1:10,5)))
  expect_equal(make_standata(y ~ 1, data = data.frame(y = rep(1:10,5)), 
                             family = "cumulative")$Y, as.array(rep(1:10,5)))
  dat <- data.frame(y = factor(rep(-4:5,5), order = TRUE))
  expect_equal(make_standata(y ~ 1, data = dat, family = "acat")$Y, 
               as.array(rep(1:10,5)))
  expect_equal(make_standata(y ~ 1, data = data.frame(y = seq(1,10,0.1)), 
                             family = "exponential")$Y, as.array(seq(1,10,0.1)))
  dat <- data.frame(y1 = 1:10, y2 = 11:20, x = rep(0,10))
  expect_equal(unname(make_standata(cbind(y1,y2) ~ x, data = dat)$Y), 
               cbind(1:10, 11:20))
})

test_that(paste("make_standata rejects incorrect response variables", 
                "depending on the family"), {
  expect_error(make_standata(y ~ 1, data = data.frame(y = factor(1:10)), 
                             family = "student"),
               "Family 'student' requires numeric responses")
  expect_error(make_standata(y ~ 1, data = data.frame(y = -5:5), 
                             family = "geometric"),
               "Family 'geometric' requires responses to be non-negative integers")
  expect_error(make_standata(y ~ 1, data = data.frame(y = -1:1), 
                             family = "bernoulli"),
               "contain only two different values")
  expect_error(make_standata(y ~ 1, data = data.frame(y = factor(-1:1)), 
                             family = "cratio"),
               "Family 'cratio' requires either integers or ordered factors")
  expect_error(make_standata(y ~ 1, data = data.frame(y = rep(0.5:7.5), 2), 
                             family = "sratio"),
               "Family 'sratio' requires either integers or ordered factors")
  expect_error(make_standata(y ~ 1, data = data.frame(y = rep(-7.5:7.5), 2), 
                             family = "gamma"),
               "Family 'gamma' requires responses to be positive")
  expect_error(make_standata(y ~ 1, data = data.frame(y = c(0, 0.5, 1)),
                             family = Beta()),
               "requires responses between 0 and 1")
  expect_error(make_standata(y ~ 1, data = data.frame(y = c(0, 0.5, 4)),
                             family = von_mises()),
               "requires responses between -pi and pi")
  expect_error(make_standata(y ~ 1, data = data.frame(y = c(-1, 2, 5)),
                             family = hurdle_gamma()),
               "requires responses to be non-negative")
})

test_that("make_standata suggests using family bernoulli if appropriate", {
  expect_message(make_standata(y ~ 1, data = data.frame(y = rep(0:1,5)), 
                               family = "binomial"),
                 paste("family 'bernoulli' might be a more efficient choice."))
  expect_message(make_standata(y ~ 1, data = data.frame(y = rep(0:1,5)), 
                               family = "acat"),
                 paste("family 'bernoulli' might be a more efficient choice."))
  expect_error(make_standata(y ~ 1, data = data.frame(y = rep(0:1,5)), 
                             family = "categorical"),
               paste("At least 3 response categories are required"))
})

test_that("make_standata returns correct values for addition terms", {
  dat <- data.frame(y = rnorm(9), s = 1:9, w = 1:9, c1 = rep(-1:1, 3), 
                    c2 = rep(c("left","none","right"), 3),
                    c3 = c(rep(c(TRUE, FALSE), 4), FALSE),
                    c4 = c(sample(-1:1, 5, TRUE), rep(2, 4)),
                    t = 11:19)
  expect_equivalent(make_standata(y | se(s) ~ 1, data = dat)$se, 
                    as.array(1:9))
  expect_equal(make_standata(y | weights(w) ~ 1, data = dat)$weights, 
               as.array(1:9))
  expect_equal(make_standata(y | disp(w) ~ 1, data = dat)$disp, 
               as.array(1:9))
  expect_equal(make_standata(y | cens(c1) ~ 1, data = dat)$cens, 
               as.array(rep(-1:1, 3)))
  expect_equal(make_standata(y | cens(c2) ~ 1, data = dat)$cens,
               as.array(rep(-1:1, 3)))
  expect_equal(make_standata(y | cens(c3) ~ 1, data = dat)$cens, 
               as.array(c(rep(1:0, 4), 0)))
  expect_equal(make_standata(y | cens(c4, y + 2) ~ 1, data = dat)$rcens, 
               as.array(c(rep(0, 5), dat$y[6:9] + 2)))
  expect_equal(make_standata(s ~ 1, dat, family = "binomial")$trials, 
               as.array(rep(9, 9)))
  expect_equal(make_standata(s | trials(10) ~ 1, dat, 
                             family = "binomial")$trials, 
               as.array(rep(10, 9)))
  expect_equal(make_standata(s | trials(t) ~ 1, data = dat, 
                             family = "binomial")$trials, 
               as.array(11:19))
  expect_equal(make_standata(s | cat(19) ~ 1, data = dat, 
                             family = "cumulative")$ncat, 
               19)
})

test_that("make_standata rejects incorrect addition terms", {
  dat <- data.frame(y = rnorm(9), s = -(1:9), w = -(1:9), 
                    c = rep(-2:0, 3), t = 9:1, z = 1:9)
  expect_error(make_standata(y | se(s) ~ 1, data = dat), 
               "Standard errors must be non-negative")
  expect_error(make_standata(y | weights(w) ~ 1, data = dat), 
               "Weights must be non-negative")
  expect_error(make_standata(y | cens(c) ~ 1, data = dat))
  expect_error(make_standata(z | trials(t) ~ 1, data = dat, 
                             family = "binomial"),
               "Number of trials is smaller than the number of events")
})

test_that("make_standata handles multivariate models", {
  dat <- data.frame(y1 = 1:10, y2 = 11:20, w = 1:10,
                    x = rep(0,10), tim = 10:1, g = rep(1:2,5))
  
  sdata <- make_standata(cbind(y1, y2) | weights(w) ~ x, data = dat)
  expect_equal(colnames(sdata$Y), c("y1", "y2"))
  expect_equal(sdata$weights, as.array(1:10))
  
  sdata <- make_standata(cbind(y1, y2, y2) ~ x, data = dat)
  expect_equal(colnames(sdata$Y), c("y1", "y2", "y21"))
  
  sdata <- make_standata(cbind(y1 / y2, y2, y1 * 3) ~ x, data = dat)
  expect_equal(colnames(sdata$Y), c("response1", "y2", "response3"))
  
  sdata <- make_standata(cbind(y1, y2) ~ x, dat,
                         autocor = cor_ar(~ tim | g))
  target <- cbind(c(seq(9, 1, -2), seq(10, 2, -2)), 
                  c(seq(19, 11, -2), seq(20, 12, -2)))
  expect_equal(unname(sdata$Y), target)
})

test_that(paste("make_standata returns correct data", 
                "for autocorrelations structures"), {
  dat <- data.frame(y=1:10, x=rep(0,10), tim=10:1, g = rep(3:4,5))
  expect_equal(make_standata(y ~ x, data = dat,
                             autocor = cor_arr(~tim|g))$Yarr,
               cbind(c(0,9,7,5,3,0,10,8,6,4)))
  expect_equal(make_standata(y ~ x, data = dat,
                             autocor = cor_arr(~tim|g, r = 2))$Yarr,
               cbind(c(0,9,7,5,3,0,10,8,6,4), c(0,0,9,7,5,0,0,10,8,6)))
  expect_equal(make_standata(y ~ x, data = dat,
                             autocor = cor_ma(~tim|g))$J_lag,
               c(1, 1, 1, 1, 0, 1, 1, 1, 1, 0))
  expect_equal(make_standata(y ~ x, data = dat,
                             autocor = cor_ar(~tim|g, p = 2))$J_lag,
               c(1, 2, 2, 2, 0, 1, 2, 2, 2, 0))
  standata <- make_standata(y ~ x, data = dat,
                            autocor = cor_ar(~tim|g, cov = TRUE))
  expect_equal(standata$begin_tg, as.array(c(1, 6)))
  expect_equal(standata$nobs_tg, as.array(c(5, 5)))
})

test_that("make_standata allows to retrieve the initial data order", {
  dat <- data.frame(y1 = rnorm(100), y2 = rnorm(100), 
                          id = sample(1:10, 100, TRUE), 
                          time = sample(1:100, 100))
  # univariate model
  sdata1 <- make_standata(y1 ~ 1, data = dat, 
                          autocor = cor_ar(~time|id),
                          control = list(save_order = TRUE))
  expect_equal(dat$y1, as.numeric(sdata1$Y[attr(sdata1, "old_order")]))
  # multivariate model
  sdata2 <- make_standata(cbind(y1, y2) ~ 1, data = dat, 
                          autocor = cor_ma(~time|id),
                          control = list(save_order = TRUE))
  expect_equal(c(dat$y1, dat$y2), 
               as.numeric(sdata2$Y[attr(sdata2, "old_order"), ]))
})

test_that("make_standata handles covariance matrices correctly", {
  A <- structure(diag(1, 4), dimnames = list(1:4, NULL))
  expect_equivalent(make_standata(count ~ Trt_c + (1|visit), data = epilepsy,
                                  cov_ranef = list(visit = A))$Lcov_1, A)
  B <- diag(1, 4)
  expect_error(make_standata(count ~ Trt_c + (1|visit), data = epilepsy,
                             cov_ranef = list(visit = B)),
               "Row names are required")
  B <- structure(diag(1, 4), dimnames = list(2:5, NULL))
  expect_error(make_standata(count ~ Trt_c + (1|visit), data = epilepsy,
                             cov_ranef = list(visit = B)),
               "Row names .* do not match")
  B <- structure(diag(1:5), dimnames = list(c(1,5,2,4,3), NULL))
  expect_equivalent(make_standata(count ~ Trt_c + (1|visit), data = epilepsy,
                             cov_ranef = list(visit = B))$Lcov_1,
                    t(chol(B[c(1,3,5,4), c(1,3,5,4)])))
  B <- A
  B[1,2] <- 0.5
  expect_error(make_standata(count ~ Trt_c + (1|visit), data = epilepsy,
                             cov_ranef = list(visit = B)),
               "not symmetric")
})

test_that("(deprecated) brmdata is backwards compatible", {
  dat <- data.frame(y = 1:10, x = sample(1:5, 10, TRUE))
  expect_identical(SW(brmdata(y ~ x + (1|x), data = dat, 
                           family = "poisson")), 
                   make_standata(y ~ x + (1|x), data = dat, 
                                 family = "poisson"))
  expect_identical(SW(brmdata(y ~ 1, data = dat, 
                              family = "acat", partial = ~ x)), 
                   SW(make_standata(y ~ 1, data = dat, 
                                    family = "acat", partial = ~ x)))
})

test_that("make_standata correctly prepares data for non-linear models", {
  flist <- list(a ~ x + (1|1|g), b ~ mono(z) + (1|1|g))
  data <- data.frame(y = rnorm(9), x = rnorm(9), z = sample(1:9, 9), 
                     g = rep(1:3, 3))
  sdata <- make_standata(bf(y ~ a - b^z, flist = flist, nl = TRUE), 
                         data = data)
  expect_equal(names(sdata), 
    c("N", "Y", "C_1", "K_a", "X_a", "Z_1_a_1", 
      "K_b", "X_b", "Kmo_b", "Imo_b", "Xmo_b_1", "Jmo_b", 
      "con_simo_b_1", "Z_1_b_2", "J_1", "N_1", 
      "M_1", "NC_1", "prior_only")
  )
  expect_equal(colnames(sdata$X_a), c("Intercept", "x"))
  expect_equal(sdata$J_1, as.array(data$g))
  
  sdata <- make_standata(bf(y ~ a - b^z, flist = flist, nl = TRUE), 
                         data = data, control = list(not4stan = TRUE))
  expect_equal(colnames(sdata$C), "z")
  
  bform <- bf(y ~ x) + 
    nlf(sigma ~ a1 * exp(-x/(a2 + z)),
        a1 ~ 1, a2 ~ z + (x|g)) +
    lf(alpha ~ x)
  sdata <- make_standata(bform, data, family = skew_normal())
  sdata_names <- c("C_sigma_1", "C_sigma_2", "X_sigma_a2", "Z_1_sigma_a2_1")
  expect_true(
    all(sdata_names %in% names(sdata))
  )
})

test_that("make_standata correctly prepares data for monotonic effects", {
  data <- data.frame(y = rpois(120, 10), x1 = rep(1:4, 30), 
                     x2 = factor(rep(c("a", "b", "c"), 40), ordered = TRUE))
  sdata <- make_standata(y ~ mo(x1)*mo(x2)*y, data = data)
  sdata_names <- c("Xmo_1", "Imo", "Jmo",  "con_simo_8", "con_simo_5")
  expect_true(all(sdata_names %in% names(sdata)))
  expect_equivalent(sdata$Xmo_1, as.array(data$x1 - 1))
  expect_equivalent(sdata$Xmo_2, as.array(as.numeric(data$x2) - 1))
  expect_equal(
    as.vector(unname(sdata$Jmo)), 
    rep(c(max(data$x1) - 1, length(unique(data$x2)) - 1), 4)
  )
  expect_equal(sdata$con_simo_1, rep(1, 3))
  
  prior <- set_prior("dirichlet(1:3)", coef = "mox11", 
                     class = "simo", dpar = "sigma")
  sdata <- make_standata(bf(y ~ 1, sigma ~ mo(x1)), 
                         data = data, prior = prior)
  expect_equal(sdata$con_simo_sigma_1, 1:3)
  
  prior <- c(
    set_prior("normal(0,1)", class = "b", coef = "mox1"),
    set_prior("dirichlet(c(1, 0.5, 2))", class = "simo", coef = "mox11"),
    prior_(~dirichlet(c(1, 0.5, 2)), class = "simo", coef = "mox1:mox21")
  )
  sdata <- make_standata(y ~ mo(x1)*mo(x2), data = data, prior = prior)
  expect_equal(sdata$con_simo_1, c(1, 0.5, 2))
  expect_equal(sdata$con_simo_3, c(1, 0.5, 2))
  
  prior <- c(set_prior("dirichlet(c(1,0.5,2))", class = "simo", coef = "mox21"))
  expect_error(
    make_standata(y ~ mo(x2), data = data, prior = prior),
    "Invalid Dirichlet prior for the simplex of coefficient 'mox21'", 
    fixed = TRUE
  )
})

test_that("make_standata returns fixed residual covariance matrices", {
  data <- data.frame(y = 1:5)
  V <- diag(5)
  expect_equal(make_standata(y~1, data, autocor = SW(cor_fixed(V)))$V, V)
  expect_error(make_standata(y~1, data, autocor = cor_fixed(diag(2))),
               "'V' must have the same number of rows as 'data'")
})

test_that("make_standata returns data for bsts models", {
  dat <- data.frame(y = 1:5, g = c(1:3, sample(1:3, 2, TRUE)), t = 1:5)
  expect_equal(make_standata(y~1, data = dat, autocor = cor_bsts(~t|g))$tg,
               as.array(sort(dat$g)))
  expect_equivalent(make_standata(bf(y~1, sigma ~ 1), data = dat, 
                                  autocor = cor_bsts(~t|g))$X_sigma[, 1],
                    rep(1, nrow(dat)))
})

test_that("make_standata returns data for GAMMs", {
  dat <- data.frame(y = rnorm(10), x1 = rnorm(10), x2 = rnorm(10),
                    x3 = rnorm(10), z = rnorm(10), g = factor(rep(1:2, 5)))
  sdata <- make_standata(y ~ s(x1) + z + s(x2, by = x3), data = dat)
  expect_equal(sdata$nb_1, 1)
  expect_equal(as.vector(sdata$knots_2), 8)
  expect_equal(dim(sdata$Zs_1_1), c(10, 8))
  expect_equal(dim(sdata$Zs_2_1), c(10, 8))
  
  sdata <- make_standata(bf(y ~ lp, lp ~ s(x1) + z + s(x2, by = x3), 
                            nl = TRUE), data = dat)
  expect_equal(sdata$nb_lp_1, 1)
  expect_equal(as.vector(sdata$knots_lp_2), 8)
  expect_equal(dim(sdata$Zs_lp_1_1), c(10, 8))
  expect_equal(dim(sdata$Zs_lp_2_1), c(10, 8))
  
  sdata <- make_standata(y ~ g + s(x2, by = g), data = dat)
  expect_true(all(c("knots_1", "knots_2") %in% names(sdata)))
  
  sdata <- make_standata(y ~ t2(x1, x2), data = dat)
  expect_equal(sdata$nb_1, 3)
  expect_equal(as.vector(sdata$knots_1), c(9, 6, 6))
  expect_equal(dim(sdata$Zs_1_1), c(10, 9))
  expect_equal(dim(sdata$Zs_1_3), c(10, 6))
  
  expect_error(make_standata(y ~ te(x1, x2), data = dat),
               "smooths 'te' and 'ti' are not yet implemented")
})

test_that("make_standata returns correct group ID data", {
  form <- bf(count ~ Trt_c + (1+Trt_c|3|visit) + (1|patient), 
             shape ~ (1|3|visit) + (Trt_c||patient))
  sdata <- make_standata(form, data = epilepsy, family = negbinomial())
  expect_true(all(c("Z_1_1", "Z_2_2", "Z_3_shape_1", "Z_2_shape_3") %in% 
                    names(sdata)))
  
  form <- bf(count ~ a, sigma ~ (1|3|visit) + (Trt_c||patient),
             a ~ Trt_c + (1+Trt_c|3|visit) + (1|patient), nl = TRUE)
  sdata <- make_standata(form, data = epilepsy, family = student())
  expect_true(all(c("Z_3_sigma_1", "Z_2_a_1", "Z_2_sigma_3",  
                    "Z_1_a_1") %in% names(sdata)))
})

test_that("make_standata handles population-level intercepts", {
  dat <- data.frame(y = 10:1, x = 1:10)
  sdata <- make_standata(y ~ 0 + x, data = dat)
  expect_equal(unname(sdata$X[, 1]), dat$x)
  
  sdata <- make_standata(y ~ x, dat, cumulative(),
                         control = list(not4stan = TRUE))
  expect_equal(unname(sdata$X[, 1]), dat$x)
  
  sdata <- make_standata(y ~ 0 + intercept + x, data = dat)
  expect_equal(unname(sdata$X), cbind(1, dat$x))
})

test_that("make_standata handles category specific effects", {
  sdata <- make_standata(rating ~ period + carry + cse(treat), 
                         data = inhaler, family = sratio())
  expect_equivalent(sdata$Xcs, matrix(inhaler$treat))
  sdata <- make_standata(rating ~ period + carry + cse(treat) + (cse(1)|subject), 
                         data = inhaler, family = acat())
  expect_equivalent(sdata$Z_1_3, as.array(rep(1, nrow(inhaler))))
  sdata <- make_standata(rating ~ period + carry + (cse(treat)|subject), 
                         data = inhaler, family = cratio())
  expect_equivalent(sdata$Z_1_4, as.array(inhaler$treat))
  expect_error(make_standata(rating ~ 1 + cse(treat), data = inhaler,
                             family = "cumulative"), "only meaningful")
  expect_error(make_standata(rating ~ 1 + (treat + cse(1)|subject), 
                             data = inhaler, family = "cratio"), 
               "category specific effects in separate group-level terms")
})

test_that("make_standata handles wiener diffusion models", {
  dat <- RWiener::rwiener(n=100, alpha=2, tau=.3, beta=.5, delta=.5)
  dat$x <- rnorm(100)
  dat$dec <- ifelse(dat$resp == "lower", 0, 1)
  dat$test <- "a"
  sdata <- make_standata(q | dec(resp) ~ x, data = dat, family = wiener())
  expect_equal(sdata$dec, as.array(dat$dec))
  sdata <- make_standata(q | dec(dec) ~ x, data = dat, family = wiener())
  expect_equal(sdata$dec, as.array(dat$dec))
  expect_error(make_standata(q | dec(test) ~ x, data = dat, family = wiener()),
               "Decisions should be 'lower' or 'upper'")
})

test_that("make_standata handles noise-free terms", {
  N <- 30
  dat <- data.frame(
    y = rnorm(N), x = rnorm(N), z = rnorm(N),
    xsd = abs(rnorm(N, 1)), zsd = abs(rnorm(N, 1)),
    ID = rep(1:5, each = N / 5)
  )
  sdata <- make_standata(
    bf(y ~ me(x, xsd)*me(z, zsd)*x, sigma ~ me(x, xsd)), 
    data = dat
  )
  expect_equal(sdata$Xn_1, as.array(dat$x))
  expect_equal(sdata$noise_2, as.array(dat$zsd))
  expect_equal(unname(sdata$Cme_3), dat$x)
  expect_equal(sdata$Kme, 6)
})

test_that("make_standata handles multi-membership models", {
  dat <- data.frame(y = rnorm(10), g1 = c(7:2, rep(10, 4)),
                    g2 = 1:10, w1 = rep(1, 10),
                    w2 = rep(abs(rnorm(10))))
  sdata <- make_standata(y ~ (1|mm(g1,g2,g1,g2)), data = dat)
  expect_true(all(paste0(c("W_1_", "J_1_"), 1:4) %in% names(sdata)))
  expect_equal(sdata$W_1_4, rep(0.25, 10))
  # this checks whether combintation of factor levels works as intended
  expect_equal(sdata$J_1_1, as.array(c(6, 5, 4, 3, 2, 1, 7, 7, 7, 7)))
  expect_equal(sdata$J_1_2, as.array(c(8, 1, 2, 3, 4, 5, 6, 9, 10, 7)))
})

test_that("make_standata handles calls to the 'poly' function", {
  dat <- data.frame(y = rnorm(10), x = rnorm(10))
  expect_equal(colnames(make_standata(y ~ 1 + poly(x, 3), dat)$X),
               c("Intercept", "polyx31", "polyx32", "polyx33"))
})

test_that("make_standata allows fixed auxiliary parameters", {
  dat <- list(y = 1:10)
  expect_equal(make_standata(bf(y ~ 1, nu = 3), dat, student())$nu, 3)
  expect_equal(make_standata(y ~ 1, dat, acat())$disc, 1)
  expect_error(make_standata(bf(y ~ 1, bias = 0.5), dat),
               "Invalid fixed parameters: 'bias'")
})

test_that("make_standata correctly includes offsets", {
  data <- data.frame(y = rnorm(10), x = rnorm(10), c = 1)
  sdata <- make_standata(bf(y ~ x + offset(c), sigma ~ offset(c + 1)), data)
  expect_equal(sdata$offset, data$c)
  expect_equal(sdata$offset_sigma, data$c + 1)
  sdata <- make_standata(y ~ x + offset(c) + offset(x), data)
  expect_equal(sdata$offset, data$c + data$x)
})

test_that("make_standata includes data for mixture models", {
  data <- data.frame(y = rnorm(10), x = rnorm(10), c = 1)
  form <- bf(y ~ x, mu1 ~ 1, family = mixture(gaussian, gaussian))
  sdata <- make_standata(form, data)
  expect_equal(sdata$con_theta, c(1, 1))
  expect_equal(dim(sdata$X_mu1), c(10, 1))
  expect_equal(dim(sdata$X_mu2), c(10, 2))
  
  form <- bf(y ~ x, family = mixture(gaussian, gaussian))
  sdata <- make_standata(form, data, prior = prior(dirichlet(10, 2), theta))
  expect_equal(sdata$con_theta, c(10, 2))
  
  form <- bf(y ~ x, theta1 = 1, theta2 = 3, family = mixture(gaussian, gaussian))
  sdata <- make_standata(form, data)
  expect_equal(sdata$theta1, 1/4)
  expect_equal(sdata$theta2, 3/4)
})

test_that("make_standata includes data for Gaussian processes", {
  dat <- data.frame(y = rnorm(10), x1 = sample(1:10, 10))
  sdata <- make_standata(y ~ gp(x1), dat)
  expect_equal(max(sdata$Xgp_1) - min(sdata$Xgp_1), 1) 
  sdata <- make_standata(y ~ gp(x1, scale = FALSE), dat)
  expect_equal(max(sdata$Xgp_1) - min(sdata$Xgp_1), 9) 
})

test_that("make_standata includes data for SAR models", {
  data(oldcol, package = "spdep")
  sdata <- make_standata(CRIME ~ INC + HOVAL, data = COL.OLD, 
                         autocor = cor_lagsar(COL.nb))
  expect_equal(dim(sdata$W), rep(nrow(COL.OLD), 2))
  
  expect_error(
    make_standata(CRIME ~ INC + HOVAL, data = COL.OLD, 
                  autocor = cor_lagsar(matrix(1:4, 2, 2))),
    "Dimensions of 'W' must be equal to the number of observations"
  )
})

test_that("make_standata includes data for CAR models", {
  dat = data.frame(y = rnorm(10), x = rnorm(10))
  edges <- cbind(1:10, 10:1)
  W <- matrix(0, nrow = 10, ncol = 10)
  for (i in seq_len(nrow(edges))) {
    W[edges[i, 1], edges[i, 2]] <- 1 
  } 
  
  sdata <- make_standata(y ~ x, dat, autocor = cor_car(W))
  expect_equal(sdata$Nloc, 10)
  expect_equal(sdata$Nneigh, rep(1, 10))
  expect_equal(sdata$edges1, as.array(10:6))
  expect_equal(sdata$edges2, as.array(1:5))
  
  rownames(W) <- c("a", 2:9, "b")
  dat$group <- rep(c("a", "b"), each = 5)
  sdata <- make_standata(y ~ x, dat, autocor = cor_car(W, ~1|group))
  expect_equal(sdata$Nloc, 2)
  expect_equal(sdata$edges1, as.array(2))
  expect_equal(sdata$edges2, as.array(1))
  
  # test error messages
  rownames(W) <- c(1:9, "a")
  expect_error(make_standata(y ~ x, dat, autocor = cor_car(W, ~1|group)), 
               "Row names of 'W' do not match")
  rownames(W) <- NULL
  expect_error(make_standata(y ~ x, dat, autocor = cor_car(W, ~1|group)),
               "Row names are required for 'W'")
  W[1, 10] <- 0
  expect_error(make_standata(y ~ x, dat, autocor = cor_car(W)),
               "'W' must be symmetric")
  W[10, 1] <- 0
  expect_error(make_standata(y ~ x, dat, autocor = cor_car(W)),
               "All locations should have at least one neighbor")
})

test_that("make_standata incldudes data of special priors", {
  dat <- data.frame(y = 1:10, x1 = rnorm(10), x2 = rnorm(10))
  
  # horseshoe prior
  hs <- horseshoe(7, scale_global = 2, df_global = 3,
                  df_slab = 6, scale_slab = 3)
  sdata <- make_standata(y ~ x1*x2, data = dat, 
                         prior = set_prior(hs))
  expect_equal(sdata$hs_df, 7)
  expect_equal(sdata$hs_df_global, 3)
  expect_equal(sdata$hs_df_slab, 6)
  expect_equal(sdata$hs_scale_global, 2)
  expect_equal(sdata$hs_scale_slab, 3)
  
  hs <- horseshoe(par_ratio = 0.1)
  sdata <- make_standata(y ~ x1*x2, data = dat, prior = set_prior(hs))
  expect_equal(sdata$hs_scale_global, 0.1 / sqrt(nrow(dat)))
  
  # lasso prior
  sdata <- make_standata(y ~ x1*x2, data = dat,
                         prior = prior(lasso(2, scale = 10)))
  expect_equal(sdata$lasso_df, 2)
  expect_equal(sdata$lasso_scale, 10)
  
  # horseshoe and lasso prior applied in a non-linear model
  hs_a1 <- horseshoe(7, scale_global = 2, df_global = 3)
  lasso_a2 <- lasso(2, scale = 10)
  sdata <- make_standata(
    bf(y ~ a1 + a2, a1 ~ x1, a2 ~ 0 + x2, nl = TRUE),
    data = dat, sample_prior = TRUE,
    prior = c(set_prior(hs_a1, nlpar = "a1"),
              set_prior(lasso_a2, nlpar = "a2"))
  )
  expect_equal(sdata$hs_df_a1, 7)
  expect_equal(sdata$lasso_df_a2, 2)
})
