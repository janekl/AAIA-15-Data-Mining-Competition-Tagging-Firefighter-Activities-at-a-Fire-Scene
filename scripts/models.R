# The script for model training and submission generation
library("randomForest")
library("stringi")

# Load data into memory (this takes about 10 min for single dataset file)
train <- read.csv(file.path("..", "data", "trainingDataFeatures.csv")) 
test <- read.csv(file.path("..", "data", "testDataFeatures.csv"))
train_labels <- read.csv(file.path("..", "data", "trainingLabels.csv"), header=TRUE)
posture <- train_labels$posture

# NOTE: Setting a proper column order is necessary to reproduce the submissions 
# generated during competition. This is necessary as we employed Random Forest model which, 
# well, uses some randomness for its good performance. During the contest our data were merged 
# from different tables (as repeatedly new features were extracted during the competition). 
# Now the data are generated using a self-contained *feature_extraction.R* script. The appropriate 
# column order (as used during competition) is stored in *column_order.txt* file in **data** folder. 
# To impose this order uncomment the following lines:
#column_order <- readLines(file.path("..", "data", "column_order.txt"))
#train <- train[, column_order]
#test <- test[, column_order]
# However, the model is composed of relatively large number of trees, so each run should 
# yield similar score. If you don't wish to impose old column order, the new predictions 
# will overlap with the ones submitted as winning solution in about 98% test set instances. 
# You can well proceed with the given new column order.

# An auxiliary function to produce submission from the stepwise model
generate_submission <- function(lasek_step1, lasek_step2, test_set, out_file){
  pred_posture <- predict(lasek_step1, test_set)
  posture <- pred_posture
  pred_action <- predict(lasek_step2, cbind(test_set, posture))
  if(!missing(out_file))
    writeLines(paste(pred_posture, pred_action, sep=","), out_file)
  return(invisible(data.frame("posture" = pred_posture, "action" = pred_action)))
}

# ------------------------------------- MODELS -------------------------------------
# 1. Balanced Random Forest classifier
set.seed(5)
lasek_all_step1_ver1 <- randomForest(x = train, y = train_labels$posture, 
                                     ntree = 700, mtry = 300, sampsize = rep(400, 5), 
                                     nodesize = 1, do.trace = T)
lasek_all_step2_ver1 <- randomForest(x = cbind(train, posture), y = train_labels$action, 
                                     ntree = 700, mtry = 300, sampsize =  rep(90, 16), 
                                     nodesize = 1, do.trace = T)

generate_submission(lasek_all_step1_ver1, lasek_all_step2_ver1, test, file.path("..", "submissions", "submission01.csv"))

# 2. We set attibute `nodesize = 3` to reduce overfitting to training data
set.seed(5)
lasek_all_step1_ver2 <- randomForest(x = train, y = train_labels$posture, 
                                     ntree = 700, mtry = 300, sampsize = rep(400, 5), 
                                     nodesize = 3, do.trace = T)
lasek_all_step2_ver2 <- randomForest(x = cbind(train, posture), y = train_labels$action, 
                                     ntree = 700, mtry = 300, sampsize = rep(90, 16), 
                                     nodesize = 3, do.trace = T)

generate_submission(lasek_all_step1_ver2, lasek_all_step2_ver2, test, file.path("..", "submissions", "submission02.csv"))

# 3. We drop data from the left arm of a firefighters as well as some part of quantiles
set.seed(5)
select <- !stri_detect_regex(colnames(train), "((acc)|(gyr))_left_arm_(x|y|z)") & !stri_detect_regex(colnames(train), "(q[02468])|(q95)|(q99)")
lasek_all_step1_ver3 <- randomForest(x = train[,select], y = train_labels$posture, 
                                     ntree = 700, mtry = 300, sampsize = rep(400, 5), 
                                     nodesize = 3, do.trace = T)
lasek_all_step2_ver3 <- randomForest(x = cbind(train[,select], posture), y = train_labels$action, 
                                     ntree = 700, mtry = 300, sampsize = rep(90, 16), 
                                     nodesize = 3, do.trace = T)

generate_submission(lasek_all_step1_ver3, lasek_all_step2_ver3, test, file.path("..", "submissions", "submission03.csv"))
