###
# train, evaluate, and predict with xgboost
###
setwd("~/Documents/Allstate-Event-Prediction-Hackathon/")
source("1-dependencies.R")
source("2-load_process_data.R")


eval_cv <- function(evaluation_log){
    # input: xgb_cross_validation$evaluation_log
    # output: min test logloss, number of iterations, and dataset size
    min_index <- which(evaluation_log$test_mlogloss_mean == min(evaluation_log$test_mlogloss_mean))
    message("Minimum test logloss: ", evaluation_log$test_mlogloss_mean[min_index], 
            "\nIterations: ", min_index,
            "\nDataset size: ", length(cv$folds[[1]]) * length(cv$folds))
    
    out = list("min_logloss" = evaluation_log$test_mlogloss_mean[min_index],
               "min_index" = min_index,
               "n" = length(cv$folds[[1]]) * length(cv$folds))
    return(out)
}


## TRAIN
cv <-
    xgb.cv(data=train_matrix,
           label=response,
           objective = "multi:softprob",
           num_class = 10,
           eta = .1,
           max_depth = 6,
           nfold = 3,
           nrounds = 200,
           metrics="mlogloss")
eval_cv(cv$evaluation_log)


fit <- xgboost(data=train_matrix, 
               label=response, 
               objective = "multi:softprob",
               num_class = 10,
               eta = .1, 
               max_depth = 6,
               nthread = 6,
               nrounds = 116, 
               eval_metric="mlogloss")

## PREDICT
test_xgb <- sparse.model.matrix( ~ ., data=select(test, -id))
test_xgb_pred <- predict(fit, test_xgb)  # this will give probability predictions as a vector
test_xgb_pred_df <- data.frame(matrix(test_xgb_pred, ncol = 10, byrow = T))

# make extra sure we're populating events in the right order
events <- train$response
events_coded <- as.integer(train$response) - 1  # if in doubt, check levels with coded vars

names(test_xgb_pred_df) <- paste("event_", levels(events), sep="")

out <- bind_cols(select(test, id), test_xgb_pred_df)

write.csv(out, "eric_submission_4.csv", row.names = F)
















