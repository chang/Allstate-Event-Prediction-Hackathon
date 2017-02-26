###
# Visualize and prototype new features.
###

source("1-dependencies.R")
source("2-load_process_data.R")
require(stats)
require(scatterplot3d)

# visualize distribution of event counts. maybe cluster to find groups. LCA?
train_viz <- gather(train, X30018:X45003, key="event", value="count")
train_viz$event <- as.factor(train_viz$event)

ggplot(train_viz %>% filter(count < 8)) + 
    geom_histogram(aes(x=count), binwidth=1) + 
    facet_grid(event ~ .)


# pca to visualize dimensionally reduced data
train_pca <- select(train, X30018:X45003)
train_pca_fit <- stats::prcomp(train_pca)
summary(train_pca_fit)  # 3 PCAs capture 75% of variance. 7 PCAs capture 96.2%. probs not worth it to toss features for xgboost
pc1 <- train_pca_fit$x[,'PC1']
pc2 <- train_pca_fit$x[,'PC2']
pc3 <- train_pca_fit$x[,'PC3']


# kmeans cluster the features
combined_full <- bind_rows(train, test)
combined <- combined_full %>% select(X30018:X45003)
result <- c()
for (i in seq(1, 8, 1)){
    combined_k <- kmeans(combined, i)
    message(combined_k$tot.withinss, "   ", combined_k$totss)
    result <- c(result, combined_k$tot.withinss)
}
ggplot(data=data.frame(x=seq(1, 8, 1), ss=result)) + geom_line(aes(x, ss))  # 5 clusters
kmeans_clusters <- kmeans(combined, centers = 5)
combined_full$kmeans_cluster <- as.factor(kmeans_clusters$cluster)

message("joining kmeans clusters to training data")
train <- left_join(train, select(combined_full, id, kmeans_cluster)) # doesn't appear to help


# check distributions of events. are there any features that are significantly different between training and testing?   
train_temp <- train
test_temp <- test
train_temp$set <- "train"
test_temp$set <- "test"
combined <- bind_rows(train_temp, test_temp) %>% mutate(set = as.factor(set))
events <- names(train[6:15])
assert_that(all(substr(events, 1, 1) == "X"))
for (event in events) {
    message(event)
    plt <- 
        ggplot(combined, aes_string(x=event)) + 
            geom_histogram(binwidth=1) + 
            facet_grid(set ~ .)
    plot(plt)
}


# parallelized randomForest - must specify nthreads = 8.
parallelRandomForest::randomForest()