###
# ensemble the out of fold estimates to form new 
###
source("dependencies.R")
source("load_process_data.R")

MODEL_DIRECTORY <- "ensemble_models"
model_list <- list.files(MODEL_DIRECTORY)
message("Found ", len(model_list), " models. Generating joint dataset and training xgboost.")

model_params <- list()
model_oof <- list()

i = 1
for (model in model_list) {
    model_oof[[i]] <- read.csv(paste(MODEL_DIRECTORY, "/", model_list, sep=""))
    names(model_oof[[i]]) <- paste(names(model_oof[[i]]), "_", i, sep="")
    i = i + 1
}

### BAGGING




### WEIGHTED BAGGING


### XGBOOST META MODEL
