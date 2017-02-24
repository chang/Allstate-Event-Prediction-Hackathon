require(dplyr)
require(ggplot2)
require(tidyr)
require(stringr)
require(xgboost)
require(magrittr)
require(Matrix)

DIRPATH = "~/Documents/allstate/"
setwd(DIRPATH)

# MAIN

# add id prefix as feature
train$prefix <- as.factor(substr(as.character(train$id), 0, 1))
test$prefix <- as.factor(substr(as.character(test$id), 0, 1))

## TRAIN
t <- sparse.model.matrix(response ~ ., data=select(train, -id))
r <- as.integer(train$response) - 1

cv <- 
  xgb.cv(data=t, 
         label=r, 
         objective = "multi:softprob",
         num_class = 10,
         eta = .1, 
         max_depth = 6,
         nthread = 8,
         nfold = 3,
         nrounds = 250, 
         metrics="mlogloss")


fit <- xgboost(data=t, 
               label=r, 
               objective = "multi:softprob",
               num_class = 10,
               eta = .1, 
               max_depth = 6,
               nthread = 6,
               nrounds = 171, 
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

write.csv(out, "eric_submission_2.csv", row.names = F)





  










