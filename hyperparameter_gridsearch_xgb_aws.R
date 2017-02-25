###
# performs hyperparameter gridsearch
###
source("dependencies.R")
source("load_process_data.R")

DIRECTORY = "xgboost_gridsearch_5fold"
dir.create(DIRECTORY, showWarnings = FALSE)

sink(paste(DIRECTORY, "/gridsearch_log_output.txt", sep=""), type="output")  # log output just in case...

# GRIDSEARCH
K_FOLDS = 5

grid_search <- expand.grid(
    nrounds = 2000,
    eta = c(0.01, 0.005),
    max_depth = c(4, 6, 8, 10, 12),
    subsample = c(.8, 1),
    colsample_bytree = c(.6, .8, 1)
)

grid_search$min_logloss <- 0
grid_search$optimal_nround <- 0
grid_search$best_iter_from_xgb <- 0
grid_search$cv_time <- 0

message("Beginning gridsearch. Testing ", nrow(grid_search), " configurations.")

for (i in seq(1, nrow(grid_search), 1)){
    # grab parameters from grid search
    nrounds_ <- grid_search[i, 'nrounds']
    eta_ <- grid_search[i, 'eta']
    max_depth_ <- grid_search[i, 'max_depth']
    subsample_ <- grid_search[i, 'subsample']
    colsample_bytree_ <- grid_search[i, 'colsample_bytree']
    
    start <- proc.time()
    # run cross validation
    cv <- xgb.cv(data = train_matrix,
                 label = response,
                 objective = "multi:softprob",
                 num_class = 10,
                 metrics = "mlogloss",
                 early_stopping_rounds = 30,
                 prediction = TRUE,
                 nfold = K_FOLDS,
                 nrounds = nrounds_,
                 eta = eta_,
                 max_depth = max_depth_,
                 subsample = subsample_,
                 colsample_bytree = colsample_bytree_
                 )
    time_elapsed <- (proc.time() - start)['elapsed']
    eval_log <- cv$evaluation_log
    
    # save out of fold predictions for ensembling later on
    filepath <- paste(DIRECTORY, "/cv_oof_predictions_config_", i, ".csv", sep="")
    write.csv(data.frame(cv$pred), file=filepath, row.names = FALSE)
    
    # save results... and write to file, just in case
    grid_search$min_logloss[i] <- min(eval_log$test_mlogloss_mean)[1]
    grid_search$optimal_nround[i] <- which(eval_log$test_mlogloss_mean == min(eval_log$test_mlogloss_mean))[1]
    grid_search$best_iter_from_xgb[i] <- cv$best_iteration
    grid_search$cv_time[i] <- time_elapsed
    write.csv(grid_search, paste(DIRECTORY, "/gridsearch_results.csv", sep=""))
    gc()  # call garbage collection to free memory
    
    message("Configuration ", i, " of ", nrow(grid_search), " complete. Took ", time_elapsed, " seconds.")
}

sink()  # close connection

########################################################################################################

DIRECTORY = "xgboost_gridsearch_10fold"
dir.create(DIRECTORY, showWarnings = FALSE)

sink(paste(DIRECTORY, "/gridsearch_log_output.txt", sep=""), type="output")  # log output just in case...

# GRIDSEARCH
K_FOLDS = 10

grid_search <- expand.grid(
    nrounds = 2000,
    eta = 0.01,
    max_depth = c(4, 6, 8, 10, 12),
    subsample = c(.8, 1),
    colsample_bytree = c(.6, .8, 1)
)

grid_search$min_logloss <- 0
grid_search$optimal_nround <- 0
grid_search$best_iter_from_xgb <- 0
grid_search$cv_time <- 0

message("Beginning gridsearch. Testing ", nrow(grid_search), " configurations.")

for (i in seq(1, nrow(grid_search), 1)){
    # grab parameters from grid search
    nrounds_ <- grid_search[i, 'nrounds']
    eta_ <- grid_search[i, 'eta']
    max_depth_ <- grid_search[i, 'max_depth']
    subsample_ <- grid_search[i, 'subsample']
    colsample_bytree_ <- grid_search[i, 'colsample_bytree']
    
    start <- proc.time()
    # run cross validation
    cv <- xgb.cv(data = train_matrix,
                 label = response,
                 objective = "multi:softprob",
                 num_class = 10,
                 metrics = "mlogloss",
                 early_stopping_rounds = 30,
                 prediction = TRUE,
                 nfold = K_FOLDS,
                 nrounds = nrounds_,
                 eta = eta_,
                 max_depth = max_depth_,
                 subsample = subsample_,
                 colsample_bytree = colsample_bytree_
    )
    time_elapsed <- (proc.time() - start)['elapsed']
    eval_log <- cv$evaluation_log
    
    # save out of fold predictions for ensembling later on
    filepath <- paste(DIRECTORY, "/cv_oof_predictions_config_", i, ".csv", sep="")
    write.csv(data.frame(cv$pred), file=filepath, row.names = FALSE)
    
    # save results... and write to file, just in case
    grid_search$min_logloss[i] <- min(eval_log$test_mlogloss_mean)[1]
    grid_search$optimal_nround[i] <- which(eval_log$test_mlogloss_mean == min(eval_log$test_mlogloss_mean))[1]
    grid_search$best_iter_from_xgb[i] <- cv$best_iteration
    grid_search$cv_time[i] <- time_elapsed
    write.csv(grid_search, paste(DIRECTORY, "/gridsearch_results.csv", sep=""))
    gc()  # call garbage collection to free memory
    
    message("Configuration ", i, " of ", nrow(grid_search), " complete. Took ", time_elapsed, " seconds.")
}

sink()  # close connection
