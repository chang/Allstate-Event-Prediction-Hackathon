###
# loads and featurizes data
###

source("dependencies.R")

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