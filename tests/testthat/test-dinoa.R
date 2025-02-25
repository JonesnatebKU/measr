test_that("dina model works", {
  # optim model -----
  out <- capture.output(
    suppressMessages(
      dina <- measr_dcm(data = dina_data, missing = NA, qmatrix = q_matrix,
                        resp_id = "resp_id", item_id = "item", type = "dina",
                        method = "optim", seed = 63277)
    )
  )

  expect_s3_class(dina, "measrfit")
  expect_s3_class(dina, "measrdcm")
  expect_equal(names(dina),
               c("data", "prior", "stancode", "method", "algorithm",
                 "backend", "model", "model_fit", "criteria", "reliability",
                 "file", "version"))
  expect_equal(names(dina$data), c("data", "qmatrix"))
  expect_equal(dina$data$data,
               dina_data %>%
                 tidyr::pivot_longer(-resp_id, names_to = "item_id",
                                     values_to = "score") %>%
                 dplyr::mutate(resp_id = factor(resp_id),
                               item_id = factor(item_id,
                                                levels = unique(item_id))))
  expect_equal(dina$data$qmatrix,
               q_matrix %>%
                 dplyr::rename(item_id = item) %>%
                 dplyr::mutate(item_id = factor(item_id,
                                                levels = unique(item_id))))
  expect_equal(dina$prior, default_dcm_priors(type = "dina"))
  expect_snapshot(dina$stancode)
  expect_equal(dina$method, "optim")
  expect_equal(dina$algorithm, "LBFGS")
  expect_type(dina$model, "list")
  expect_equal(names(dina$model),
               c("par", "value", "return_code", "theta_tilde"))
  expect_type(dina$model_fit, "list")
  expect_type(dina$criteria, "list")
  expect_type(dina$reliability, "list")
  expect_null(dina$file)
  expect_equal(names(dina$version), c("measr", "rstan", "StanHeaders"))

  dina_comp <- tibble::enframe(dina$model$par) %>%
    dplyr::filter(grepl("^Vc|slip|guess", .data$name)) %>%
    dplyr::mutate(name = gsub("Vc", "nu", .data$name)) %>%
    dplyr::left_join(true_dinoa, by = c("name" = "param"))

  comp_cor <- cor(dina_comp$value, dina_comp$true)
  comp_dif <- abs(dina_comp$value - dina_comp$true)

  print(comp_cor)
  print(max(comp_dif))

  expect_true(comp_cor > 0.85)
  expect_true(max(comp_dif) < 0.2)

  # mcmc model -----
  # skip_on_cran()
  # out <- capture.output(
  #   suppressWarnings(suppressMessages(
  #     dina_mcmc <- measr_dcm(data = dina_data, missing = NA, qmatrix = q_matrix,
  #                            resp_id = "resp_id", item_id = "item",
  #                            type = "dina", method = "mcmc", iter = 300,
  #                            cores = 1, chains = 1, warmup = 150, refresh = 0)
  #   ))
  # )
  #
  # expect_s3_class(dina_mcmc, "measrfit")
  # expect_s3_class(dina_mcmc, "measrdcm")
  # expect_equal(names(dina_mcmc),
  #              c("data", "prior", "stancode", "method", "algorithm",
  #                "backend", "model", "model_fit", "criteria", "reliability",
  #                "file", "version"))
  # expect_equal(names(dina_mcmc$data), c("data", "qmatrix"))
  # expect_equal(dina_mcmc$data$data,
  #              dina_data %>%
  #                tidyr::pivot_longer(-resp_id, names_to = "item_id",
  #                                    values_to = "score") %>%
  #                dplyr::mutate(resp_id = factor(resp_id),
  #                              item_id = factor(item_id,
  #                                               levels = unique(item_id))))
  # expect_equal(dina_mcmc$data$qmatrix,
  #              q_matrix %>%
  #                dplyr::rename(item_id = item) %>%
  #                dplyr::mutate(item_id = factor(item_id,
  #                                               levels = unique(item_id))))
  # expect_equal(dina_mcmc$prior, default_dcm_priors(type = "dina"))
  # expect_snapshot(dina_mcmc$stancode)
  # expect_equal(dina_mcmc$method, "mcmc")
  # expect_equal(dina_mcmc$algorithm, "NUTS")
  # expect_s4_class(dina_mcmc$model, "stanfit")
  # expect_type(dina_mcmc$model_fit, "list")
  # expect_type(dina_mcmc$criteria, "list")
  # expect_type(dina_mcmc$reliability, "list")
  # expect_null(dina_mcmc$file)
  # expect_equal(names(dina_mcmc$version), c("measr", "rstan", "StanHeaders"))
  #
  # dina_mcmc_comp <- rstan::summary(dina_mcmc$model)$summary %>%
  #   tibble::as_tibble(rownames = "param") %>%
  #   dplyr::filter(grepl("^Vc|slip|guess", .data$param)) %>%
  #   dplyr::mutate(param = gsub("Vc", "nu", .data$param)) %>%
  #   dplyr::left_join(true_dinoa, by = "param")
  #
  # comp_cor <- cor(dina_mcmc_comp$mean, dina_mcmc_comp$true)
  # comp_dif <- abs(dina_mcmc_comp$mean - dina_mcmc_comp$true)
  # expect_true(comp_cor > 0.85)
  # expect_true(max(comp_dif) < 0.15)
})
