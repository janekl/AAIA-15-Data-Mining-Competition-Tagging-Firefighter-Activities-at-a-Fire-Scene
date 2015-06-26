# A script for performing majority voting from different submissions
train_labels <- read.csv(file.path("..", "data", "trainingLabels.csv"), header=TRUE)

# Choose submissions for voting from **submissions** folder
subs <- c("submission01.csv", 
          "submission02.csv", 
          "submission03.csv")

# Assign weighted vote for each of the submissions. As the first submission yielded the highest accuracy 
# score we give it a higher weight (to resolve ties).
votes <- c(1.5, 1, 1)

# Load submissions
submissions <- vector("list", length(subs))
for(i in seq_along(subs)){
  submissions[[i]] <- read.csv(file.path("..", "submissions", subs[i]), header = FALSE, stringsAsFactors = FALSE)
}

# Voting for 'posture' class
posture_labels <- levels(train_labels$posture)
posture_votes <- matrix(0, ncol = length(posture_labels), nrow = 20000)
colnames(posture_votes) <- posture_labels

for(i in 1:nrow(posture_votes)){
  for(j in 1:length(submissions)){
    posture_votes[i, submissions[[j]][i, 1]] <- posture_votes[i, submissions[[j]][i, 1]] + votes[j]
  }
}

# Voting for 'action' class
action_labels <- levels(train_labels$action)
action_votes <- matrix(0, ncol = length(action_labels), nrow = 20000)
colnames(action_votes) <- action_labels

for(i in 1:nrow(action_votes)){
  for(j in 1:length(submissions)){
    action_votes[i, submissions[[j]][i, 2]] <- action_votes[i, submissions[[j]][i, 2]] + votes[j]
  }
}

# Results of voting
vote_for_posture <- apply(posture_votes, 1, which.max)
final_posture_label <- posture_labels[vote_for_posture]

vote_for_action <- apply(action_votes, 1, which.max)
final_action_label <- action_labels[vote_for_action]

table(final_action_label, final_posture_label)
writeLines(paste(final_posture_label, final_action_label, sep=","), file.path("..", "submissions", "majority_voting.csv"))
