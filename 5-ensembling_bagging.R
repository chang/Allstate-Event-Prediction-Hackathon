###
# bag the best submission along with 4 good submissions
###
source("1-dependencies.R")
source("2-load_process_data.R")

predict_xgboost <- function(fit, test){
    ## PREDICT
    test_xgb <- sparse.model.matrix( ~ ., data=select(test, -id))
    test_xgb_pred <- predict(fit, test_xgb)  # this will give probability predictions as a vector
    test_xgb_pred_df <- data.frame(matrix(test_xgb_pred, ncol = 10, byrow = T))
    
    # make extra sure we're populating events in the right order
    events <- train$response
    events_coded <- as.integer(train$response) - 1  # if in doubt, check levels with coded vars
    
    names(test_xgb_pred_df) <- paste("event_", levels(events), sep="")
    
    out <- bind_cols(select(test, id), test_xgb_pred_df)
    return(out)
}

fit1 <- xgboost(data=train_matrix, 
               label=response, 
               objective = "multi:softprob",
               num_class = 10,
               eta = .05, 
               max_depth = 6,
               subsample = .6,
               colsample_bytree = .8,
               nthread = 7,
               nrounds = 292, 
               eval_metric="mlogloss")

fit2 <- xgboost(data=train_matrix, 
                label=response, 
                objective = "multi:softprob",
                num_class = 10,
                eta = .05, 
                max_depth = 6,
                subsample = .8,
                colsample_bytree = .8,
                nthread = 7,
                nrounds = 294, 
                eval_metric="mlogloss")

fit3 <- xgboost(data=train_matrix, 
                label=response, 
                objective = "multi:softprob",
                num_class = 10,
                eta = .05, 
                max_depth = 4,
                subsample = .8,
                colsample_bytree = .8,
                nthread = 7,
                nrounds = 750, 
                eval_metric="mlogloss")

fit4 <- xgboost(data=train_matrix, 
                label=response, 
                objective = "multi:softprob",
                num_class = 10,
                eta = .05, 
                max_depth = 6,
                subsample = .8,
                colsample_bytree = .6,
                nthread = 7,
                nrounds = 350, 
                eval_metric="mlogloss")


fit1_pred <- predict_xgboost(fit1, test)
fit2_pred <- predict_xgboost(fit2, test)
fit3_pred <- predict_xgboost(fit3, test)
fit4_pred <- predict_xgboost(fit4, test)

fit_best2 <- predict_xgboost(fit_best2, test)
best_pred <- read.csv("submissions/eric_submission_5.csv")

bagged <- best_pred

for (col in names(best_pred)[2:11]) {
    bagged[,col] <- (fit1_pred[,col] +
                     fit2_pred[,col] +
                     fit3_pred[,col] +
                     fit4_pred[,col] +
                     3 * best_pred[,col] +
                     3 * fit_best2[,col]) / 10
}

write.csv(bagged, "eric_submission_7_bagged.csv", row.names = F)



