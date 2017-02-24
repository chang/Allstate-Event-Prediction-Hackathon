require(dplyr)
require(ggplot2)
require(tidyr)
require(stringr)
require(xgboost)
require(magrittr)
require(Matrix)

DIRPATH = "~/Documents/allstate/"
setwd(DIRPATH)

process_data <- function(dat){
  # process data into form where id is primary key, extracting features:
  # first event id, last event id, frequency counts of ids
  
  # get first event, last event (response), and count of events
  critical_events <- dat %>% group_by(id) %>% 
    summarise(last_event_time = max(timestamp), 
              last_event = last(event),
              first_event = first(event),
              first_event_time = min(timestamp),
              count_events = n()) %>% 
    select(-last_event_time, -first_event_time)
  
  # get frequency counts
  count_events <- dat %>% 
    group_by(id, event) %>% 
    summarise(n = n()) %>% 
    spread(event, n)
  count_events[is.na(count_events)] <- 0
  
  return(left_join(critical_events, count_events))
}

# MAIN
# To create training and testing dataset
# 1. extract all ids from 'train' that are in 'test' and convert to training data
# 2. get last event from leftover ids, remove those rows, and use the event as response
# 2.1. as next step, generate more training data by moving backwards another event in time

train_raw <- read.csv("data/train.csv")
test_raw <- read.csv("data/test.csv")
subm <- read.csv("data/sample_submission.csv")

test <- process_data(filter(train_raw, id %in% test_raw$id))

response <- train_raw %>% 
  filter(!(id %in% test_raw$id)) %>%
  group_by(id) %>% 
  summarise(response = last(event), last_timestamp = last(timestamp))

train <- train_raw %>% 
  filter(!(id %in% test_raw$id) & !(timestamp %in% response$last_timestamp)) %>% 
  process_data() %>% 
  left_join(response %>% select(-last_timestamp)) %>% 
  mutate(last_event = as.factor(last_event), 
         first_event = as.factor(first_event),
         response = as.factor(response))

# add id prefix as feature
train$prefix <- as.factor(substr(as.character(train$id), 0, 1))
test$prefix <- as.factor(substr(as.character(test$id), 0, 1))

## TRAIN
names(train) <- make.names(names(train))
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
test$last_event <- as.factor(test$last_event) #  IS THIS WHAT WAS SCREWING ME UP ARE YOU SHITTING ME
test$first_event <- as.factor(test$first_event)

names(test) <- make.names(names(test))
test_xgb <- sparse.model.matrix( ~ ., data=select(test, -id))
test_xgb_pred <- predict(fit, test_xgb)  # this will give probability predictions as a vector
test_xgb_pred_df <- data.frame(matrix(test_xgb_pred, ncol = 10, byrow = T))

# make extra sure we're populating events in the right order
events <- train$response
events_coded <- as.integer(train$response) - 1  # if in doubt, check levels with coded vars

names(test_xgb_pred_df) <- paste("event_", levels(events), sep="")

out <- bind_cols(select(test, id), test_xgb_pred_df)

write.csv(out, "eric_submission_2.csv", row.names = F)





  










