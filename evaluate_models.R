

result <- cv$evaluation_log
min_index <- which(result$test_mlogloss_mean == min(result$test_mlogloss_mean))
message("Minimum test logloss: ", result$test_mlogloss_mean[min_index], 
        "\nIterations: ", min_index,
        "\nDataset size: ", length(cv$folds[[1]]) * length(cv$folds))

ggplot(result, aes(x=iter, y=test_mlogloss_mean)) + geom_line()