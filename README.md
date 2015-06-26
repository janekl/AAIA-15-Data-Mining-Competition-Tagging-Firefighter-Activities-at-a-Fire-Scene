# AAIA`15 Data Mining Competition: Tagging Firefighter Activities at a Fire Scene
The repository contains the winning solution to the AAIA`15 Data Mining Competition: Tagging Firefighter Activities at a Fire Scene organized by University of Warsaw, Poland and Main School of Fire Service, Warsaw Poland. The goal of the contest was to develop a classifier for tagging a firefighter's actions based on sensory recordings from accelerometers and gyroscopes attached to different parts of his/her body. Pay a visit at [the competition's webpage](https://knowledgepit.fedcsis.org/contest/view.php?id=106) for more information.

The document herein describes how to use the enclosed solution. The steps for feature extraction, model estimation and submission generation are presented. The experiments were performed on a single machine with Intel(R) Core(TM) i7-4510U CPU @ 2.00GHz and 16 GB RAM running Ubuntu 14.04.2 LTS. The solution is implemented in [**R**](http://www.r-project.org/), a language and environment for statistical computing.

### Data
Data for running experiment should be downloaded from competition website. There are two datasets: *trainingData.csv* and *testData.csv* along with a file containing target labels *trainingLabels.csv* for the training set. Each dataset contains 20.000 instances of activities performed by different firefighters. Each dataset is of size 2.4 GB. The goal is to label the instances in the test set. 

### Feature extraction
Script *feature_extraction.R* in **scripts** folder contains routines for extracting features from raw time series. Run this script interactively in e.g. RStudio (recommended) to produce two processed datasets: *trainingDataFeatures.csv* and *testDataFeatures.csv* saved in **data** folder. The produced datasets are each of size approximately 1.4 GB. It takes in total about 4h to process both training and test set.

### Model estimation
The final submission was composed of the output from three modifications of Random Forest classifier. The models are specified in *models.R* in **scripts** folder. It takes about 3.5h to train the models.

### Generating submission
Along with estimation of the classifiers, in *models.R* script, the models' predictions are generated and saved in **submissions** folder. Script *majority_voting.R* can be used to blend the three submissions by weighted majority voting. This produces the final submission which yielded the best score during the competition.

### The final word
AAIA`15 Data Mining Contest was an exciting event. Thanks to all the participants for great work and the competition! We hope that the model within this repo will serve as a benchmark for even better performing models.

### References

* AAIA'15 Data Mining Competition: Tagging Firefighter Activities at a Fire Scene, URL: https://knowledgepit.fedcsis.org/contest/view.php?id=106 (last access date 26 June 2015).
* A. Liaw and M. Wiener (2002). Classification and Regression by randomForest. R News 2(3), 18--22.
