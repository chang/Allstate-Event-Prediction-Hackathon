###
# loads and featurizes data
###
DIRPATH = "~/Documents/Allstate-Event-Prediction-Hackathon/"
setwd(DIRPATH)

source("dependencies.R")


process_data <- function(dat, is_training_data){
  # process data into form where id is primary key, extracting features:
  # first event id, last event id, frequency counts of ids
  
  if (is_training_data) {
    responses <- dat %>% group_by(id) %>% 
                         summarise(last_timestamp = last(timestamp), 
                                   response=last(event)) %>% 
                         mutate(response = as.factor(response))
    
    assert_that(all(table(dat$timestamp) == 1))  # getting response rows like this depends on timestamps being unique
    row_is_response <- (dat$timestamp %in% responses$timestamp)
    dat <- dat %>% filter(!row_is_response)
  }
  
  # get first event, last event (response), and count of events
  critical_events <- dat %>% group_by(id) %>% 
    summarise(last_event = last(event),
              first_event = first(event),
              count_events = n()) %>% 
    mutate(last_event = as.factor(last_event),
           first_event = as.factor(first_event))
  
  # get frequency counts
  count_events <- dat %>% 
    group_by(id, event) %>% 
    summarise(n = n()) %>% 
    spread(event, n)
  count_events[is.na(count_events)] <- 0
  names(count_events) <- make.names(names(count_events))
  
  if (is_training_data) {
    # if we're making training data, join responses back in
    critical_events <- left_join(critical_events, responses, by='id')
  }
  
  return(left_join(critical_events, count_events))
}


augment_data <- function(dat, train, n_events){
  # generates more training data by recalculating features
  # on ids with n occured events by removing the nth observation 
  # and setting event[n-1] as response. 
  # iteratively "shaves" dataset down from max n_events to ids with only 2 events
  out <- data.frame(names(train))
  
  
  
}

# MAIN
# To create training and testing dataset
# 1. extract all ids from 'train' that are in 'test' and convert to training data
# 2. get last event from leftover ids, remove those rows, and use the event as response
# 2.1. as next step, generate more training data by moving backwards another event in time

train_raw <- read.csv("data/train.csv")
test_raw <- read.csv("data/test.csv")
subm <- read.csv("data/sample_submission.csv")

# move features from the training set to test set now
test_raw <- left_join(test_raw, filter(train_raw, id %in% test_raw$id))
train_raw <- filter(train_raw, !(id %in% test_raw$id))
assert_that(all(!train_raw$id %in% test_raw$id))  # assert no overlap between training and test sets

# extract features
test <- process_data(test_raw, is_training_data = FALSE)
train <- process_data(train_raw, is_training_data = TRUE)














