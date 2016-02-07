run_analysis.R
============
By Vladimir Zaytsev, 01/31/2016 


Getting and Cleaning Data Course Project
----------------------------------------

>The purpose of this project is to demonstrate your ability to collect, work with, and clean a data set. The goal is to prepare tidy data that can be used for later analysis. You will be graded by your peers on a series of yes/no questions related to the project. You will be required to submit: 1) a tidy data set as described below, 2) a link to a Github repository with your script for performing the analysis, and 3) a code book that describes the variables, the data, and any transformations or work that you performed to clean up the data called CodeBook.md. You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.
>One of the most exciting areas in all of data science right now is wearable computing - see for example this article . Companies like Fitbit, Nike, and Jawbone Up are racing to develop the most advanced algorithms to attract new users. The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained:

http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

>Here are the data for the project:

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

>You should create one R script called run_analysis.R that does the following.
>1. Merges the training and the test sets to create one data set.
>2. Extracts only the measurements on the mean and standard deviation for each measurement.
>3. Uses descriptive activity names to name the activities in the data set
>4. Appropriately labels the data set with descriptive variable names.
>5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

Implementation
--------------

>We are going to use data.table package for loading and converting the data. We are going to bind test and training data sets together and use melt, merge and grouping to convert data to tidy starndards. For column names I decided to use all lowercase short names instead of camel notation used in the original feature list. 



Use packages
------------

```r
require(data.table)
require(dplyr)
library(plyr)
```

Download and unzip data
-------------

```r
getwd()
if(!file.exists("./Project/data")){
    dir.create("./Project/data");
}
download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", "./Project/data/DataSet.zip",method="curl")
dateDownloaded <- date()
unzip("./Project/data/DataSet.zip", exdir = "./Project/data/extracted/" )
list.files("./Project/data/extracted/", recursive=TRUE )
```

List the files
--------------

>After careful reading README.txt and features_info.txt and poking the files, we get some rough idea that we do not need files in "Inertial Signals" subfolders.

```
 [1] "UCI HAR Dataset/activity_labels.txt"                         
 [2] "UCI HAR Dataset/features_info.txt"                           
 [3] "UCI HAR Dataset/features.txt"                                
 [4] "UCI HAR Dataset/README.txt"                                  
 [5] "UCI HAR Dataset/test/Inertial Signals/body_acc_x_test.txt"   
 [6] "UCI HAR Dataset/test/Inertial Signals/body_acc_y_test.txt"   
 [7] "UCI HAR Dataset/test/Inertial Signals/body_acc_z_test.txt"   
 [8] "UCI HAR Dataset/test/Inertial Signals/body_gyro_x_test.txt"  
 [9] "UCI HAR Dataset/test/Inertial Signals/body_gyro_y_test.txt"  
[10] "UCI HAR Dataset/test/Inertial Signals/body_gyro_z_test.txt"  
[11] "UCI HAR Dataset/test/Inertial Signals/total_acc_x_test.txt"  
[12] "UCI HAR Dataset/test/Inertial Signals/total_acc_y_test.txt"  
[13] "UCI HAR Dataset/test/Inertial Signals/total_acc_z_test.txt"  
[14] "UCI HAR Dataset/test/subject_test.txt"                       
[15] "UCI HAR Dataset/test/X_test.txt"                             
[16] "UCI HAR Dataset/test/y_test.txt"                             
[17] "UCI HAR Dataset/train/Inertial Signals/body_acc_x_train.txt" 
[18] "UCI HAR Dataset/train/Inertial Signals/body_acc_y_train.txt" 
[19] "UCI HAR Dataset/train/Inertial Signals/body_acc_z_train.txt" 
[20] "UCI HAR Dataset/train/Inertial Signals/body_gyro_x_train.txt"
[21] "UCI HAR Dataset/train/Inertial Signals/body_gyro_y_train.txt"
[22] "UCI HAR Dataset/train/Inertial Signals/body_gyro_z_train.txt"
[23] "UCI HAR Dataset/train/Inertial Signals/total_acc_x_train.txt"
[24] "UCI HAR Dataset/train/Inertial Signals/total_acc_y_train.txt"
[25] "UCI HAR Dataset/train/Inertial Signals/total_acc_z_train.txt"
[26] "UCI HAR Dataset/train/subject_train.txt"                     
[27] "UCI HAR Dataset/train/X_train.txt"                           
[28] "UCI HAR Dataset/train/y_train.txt"
```

The files that we need are:
---------------------------

File name               | Description
------------------------|------------------------------------------
activity_labels.txt     | Activity dictionary
features.txt            | Features dictionary
test/subject_test.txt   | Test study subject ID
test/X_test.txt         | Collected test data
test/y_test.txt         | Test activity (references)
train/subject_train.txt | Train study subject ID            
train/X_train.txt       | Collected training data
train/y_train.txt       | Training activity (references)




Read the data
-------------

```r
fpath <- "./Project/data/extracted/UCI HAR Dataset/"
subject_train <- fread(paste0(fpath, "train/subject_train.txt"))
subject_test <- fread(paste0(fpath, "test/subject_test.txt"))
data_train <- data.table(read.table(paste0(fpath, "train/X_train.txt")))
data_test <- data.table(read.table(paste0(fpath, "test/X_test.txt")))
act_train <- fread(paste0(fpath, "train/y_train.txt"))
act_test <- fread(paste0(fpath, "test/y_test.txt"))
activities <- fread(paste0(fpath, "activity_labels.txt"))
features  <- fread(paste0(fpath, "features.txt"))
```

>Set key names for dictionaries

```r
setnames(activities, names(activities), c("activity", "activityName"))
setnames(features, names(features), c("featureNum", "featureName"))
```

Merging test and train data and activities/subject 
--------------------------------------------------
```r
subject_all <- rbind(subject_train, subject_test)
setnames(subject_all, "V1","subject")
act_all <- rbind(act_train, act_test)
setnames(act_all, "V1","activity")
tbl <- rbind(data_train, data_test)
dt_sa <- cbind(subject_all, act_all)
tbl <- cbind(dt_sa, tbl)
```

Extract only the mean and standard deviation columns
----------------------------------------------------

> Course project task 2 was to select specified data only. According to data description in the archive, we need to use fields with names containing "std" or "mean"

```r
setkey(tbl, subject, activity)
features <- features[grepl("mean\\(\\)|std\\(\\)", featureName)]
features$feature <- features[, paste0("V", featureNum)]
select <- c(key(tbl), features$feature)
tbl <- tbl[, select, with = FALSE]
head(dtFeatures)
```
>

```
  featureNum       featureName feature
1:          1 tBodyAcc-mean()-X      V1
2:          2 tBodyAcc-mean()-Y      V2
3:          3 tBodyAcc-mean()-Z      V3
4:          4  tBodyAcc-std()-X      V4
5:          5  tBodyAcc-std()-Y      V5
6:          6  tBodyAcc-std()-Z      V6
```

```r
features$feature
```

```
 [1] "V1"   "V2"   "V3"   "V4"   "V5"   "V6"   "V41"  "V42"  "V43"  "V44"  "V45"  "V46" 
[13] "V81"  "V82"  "V83"  "V84"  "V85"  "V86"  "V121" "V122" "V123" "V124" "V125" "V126"
[25] "V161" "V162" "V163" "V164" "V165" "V166" "V201" "V202" "V214" "V215" "V227" "V228"
[37] "V240" "V241" "V253" "V254" "V266" "V267" "V268" "V269" "V270" "V271" "V345" "V346"
[49] "V347" "V348" "V349" "V350" "V424" "V425" "V426" "V427" "V428" "V429" "V503" "V504"
[61] "V516" "V517" "V529" "V530" "V542" "V543"
```




Normalize the table
-------------------

```r
tbl <- merge(tbl, activities, by = "activity", all.x = TRUE)
setkey(tbl, subject, activity, activityName)
tbl$activity <- factor(tbl$activityName)
```

Renaming the futures
--------------------

```r
features$featureName<- gsub("mean\\(\\)","Mean",features$featureName)
features$featureName<- gsub("^t","Time.",features$featureName)
features$featureName<- gsub("^f","Frequency.",features$featureName)
features$featureName<- gsub("std\\(\\)","Stddev",features$featureName)
features$featureName<- gsub("-X$",".X",features$featureName)
features$featureName<- gsub("-Y$",".Y",features$featureName)
features$featureName<- gsub("-Z$",".Z",features$featureName)
features$featureName<- gsub("Gyro","Gyroscope.",features$featureName)
features$featureName<- gsub("Body","Body.",features$featureName)
features$featureName<- gsub("Gravity","Gyroscope.",features$featureName)
features$featureName<- gsub("Mag","Magnitude.",features$featureName)
features$featureName<- gsub("Acc","Acceleration.",features$featureName)
features$featureName<- gsub("-","",features$featureName)

for (i in (1:length(features$featureName))) {
    setnames(tbl, features$feature, features$featureName)
}
```


Summarizing and saving
----------------------

```r
TidyData <- ddply(tbl, c("subject","activity"), numcolwise(mean))
write.table(TidyData, "./Project/GettingDataProjectTidyData.txt", row.name=FALSE)
```

```r
names(TidyData)
```
```
 [1] "subject"                                               "activity"                                             
 [3] "Time.Body.Acceleration.Mean.X"                         "Time.Body.Acceleration.Mean.Y"                        
 [5] "Time.Body.Acceleration.Mean.Z"                         "Time.Body.Acceleration.Stddev.X"                      
 [7] "Time.Body.Acceleration.Stddev.Y"                       "Time.Body.Acceleration.Stddev.Z"                      
 [9] "Time.Gyroscope.Acceleration.Mean.X"                    "Time.Gyroscope.Acceleration.Mean.Y"                   
[11] "Time.Gyroscope.Acceleration.Mean.Z"                    "Time.Gyroscope.Acceleration.Stddev.X"                 
[13] "Time.Gyroscope.Acceleration.Stddev.Y"                  "Time.Gyroscope.Acceleration.Stddev.Z"                 
[15] "Time.Body.Acceleration.JerkMean.X"                     "Time.Body.Acceleration.JerkMean.Y"                    
[17] "Time.Body.Acceleration.JerkMean.Z"                     "Time.Body.Acceleration.JerkStddev.X"                  
[19] "Time.Body.Acceleration.JerkStddev.Y"                   "Time.Body.Acceleration.JerkStddev.Z"                  
[21] "Time.Body.Gyroscope.Mean.X"                            "Time.Body.Gyroscope.Mean.Y"                           
[23] "Time.Body.Gyroscope.Mean.Z"                            "Time.Body.Gyroscope.Stddev.X"                         
[25] "Time.Body.Gyroscope.Stddev.Y"                          "Time.Body.Gyroscope.Stddev.Z"                         
[27] "Time.Body.Gyroscope.JerkMean.X"                        "Time.Body.Gyroscope.JerkMean.Y"                       
[29] "Time.Body.Gyroscope.JerkMean.Z"                        "Time.Body.Gyroscope.JerkStddev.X"                     
[31] "Time.Body.Gyroscope.JerkStddev.Y"                      "Time.Body.Gyroscope.JerkStddev.Z"                     
[33] "Time.Body.Acceleration.Magnitude.Mean"                 "Time.Body.Acceleration.Magnitude.Stddev"              
[35] "Time.Gyroscope.Acceleration.Magnitude.Mean"            "Time.Gyroscope.Acceleration.Magnitude.Stddev"         
[37] "Time.Body.Acceleration.JerkMagnitude.Mean"             "Time.Body.Acceleration.JerkMagnitude.Stddev"          
[39] "Time.Body.Gyroscope.Magnitude.Mean"                    "Time.Body.Gyroscope.Magnitude.Stddev"                 
[41] "Time.Body.Gyroscope.JerkMagnitude.Mean"                "Time.Body.Gyroscope.JerkMagnitude.Stddev"             
[43] "Frequency.Body.Acceleration.Mean.X"                    "Frequency.Body.Acceleration.Mean.Y"                   
[45] "Frequency.Body.Acceleration.Mean.Z"                    "Frequency.Body.Acceleration.Stddev.X"                 
[47] "Frequency.Body.Acceleration.Stddev.Y"                  "Frequency.Body.Acceleration.Stddev.Z"                 
[49] "Frequency.Body.Acceleration.JerkMean.X"                "Frequency.Body.Acceleration.JerkMean.Y"               
[51] "Frequency.Body.Acceleration.JerkMean.Z"                "Frequency.Body.Acceleration.JerkStddev.X"             
[53] "Frequency.Body.Acceleration.JerkStddev.Y"              "Frequency.Body.Acceleration.JerkStddev.Z"             
[55] "Frequency.Body.Gyroscope.Mean.X"                       "Frequency.Body.Gyroscope.Mean.Y"                      
[57] "Frequency.Body.Gyroscope.Mean.Z"                       "Frequency.Body.Gyroscope.Stddev.X"                    
[59] "Frequency.Body.Gyroscope.Stddev.Y"                     "Frequency.Body.Gyroscope.Stddev.Z"                    
[61] "Frequency.Body.Acceleration.Magnitude.Mean"            "Frequency.Body.Acceleration.Magnitude.Stddev"         
[63] "Frequency.Body.Body.Acceleration.JerkMagnitude.Mean"   "Frequency.Body.Body.Acceleration.JerkMagnitude.Stddev"
[65] "Frequency.Body.Body.Gyroscope.Magnitude.Mean"          "Frequency.Body.Body.Gyroscope.Magnitude.Stddev"       
[67] "Frequency.Body.Body.Gyroscope.JerkMagnitude.Mean"      "Frequency.Body.Body.Gyroscope.JerkMagnitude.Stddev"```
```

```r
str(TidyData)
```

```
'data.frame':	180 obs. of  68 variables:
 $ subject                                              : int  1 1 1 1 1 1 2 2 2 2 ...
 $ activity                                             : Factor w/ 6 levels "LAYING","SITTING",..: 1 2 3 4 5 6 1 2 3 4 ...
 $ Time.Body.Acceleration.Mean.X                        : num  0.222 0.261 0.279 0.277 0.289 ...
 $ Time.Body.Acceleration.Mean.Y                        : num  -0.04051 -0.00131 -0.01614 -0.01738 -0.00992 ...
 $ Time.Body.Acceleration.Mean.Z                        : num  -0.113 -0.105 -0.111 -0.111 -0.108 ...
 $ Time.Body.Acceleration.Stddev.X                      : num  -0.928 -0.977 -0.996 -0.284 0.03 ...
 $ Time.Body.Acceleration.Stddev.Y                      : num  -0.8368 -0.9226 -0.9732 0.1145 -0.0319 ...
 $ Time.Body.Acceleration.Stddev.Z                      : num  -0.826 -0.94 -0.98 -0.26 -0.23 ...
 $ Time.Gyroscope.Acceleration.Mean.X                   : num  -0.249 0.832 0.943 0.935 0.932 ...
 $ Time.Gyroscope.Acceleration.Mean.Y                   : num  0.706 0.204 -0.273 -0.282 -0.267 ...
 $ Time.Gyroscope.Acceleration.Mean.Z                   : num  0.4458 0.332 0.0135 -0.0681 -0.0621 ...
 $ Time.Gyroscope.Acceleration.Stddev.X                 : num  -0.897 -0.968 -0.994 -0.977 -0.951 ...
 $ Time.Gyroscope.Acceleration.Stddev.Y                 : num  -0.908 -0.936 -0.981 -0.971 -0.937 ...
 $ Time.Gyroscope.Acceleration.Stddev.Z                 : num  -0.852 -0.949 -0.976 -0.948 -0.896 ...
 $ Time.Body.Acceleration.JerkMean.X                    : num  0.0811 0.0775 0.0754 0.074 0.0542 ...
 $ Time.Body.Acceleration.JerkMean.Y                    : num  0.003838 -0.000619 0.007976 0.028272 0.02965 ...
 $ Time.Body.Acceleration.JerkMean.Z                    : num  0.01083 -0.00337 -0.00369 -0.00417 -0.01097 ...
 $ Time.Body.Acceleration.JerkStddev.X                  : num  -0.9585 -0.9864 -0.9946 -0.1136 -0.0123 ...
 $ Time.Body.Acceleration.JerkStddev.Y                  : num  -0.924 -0.981 -0.986 0.067 -0.102 ...
 $ Time.Body.Acceleration.JerkStddev.Z                  : num  -0.955 -0.988 -0.992 -0.503 -0.346 ...
 $ Time.Body.Gyroscope.Mean.X                           : num  -0.0166 -0.0454 -0.024 -0.0418 -0.0351 ...
 $ Time.Body.Gyroscope.Mean.Y                           : num  -0.0645 -0.0919 -0.0594 -0.0695 -0.0909 ...
 $ Time.Body.Gyroscope.Mean.Z                           : num  0.1487 0.0629 0.0748 0.0849 0.0901 ...
 $ Time.Body.Gyroscope.Stddev.X                         : num  -0.874 -0.977 -0.987 -0.474 -0.458 ...
 $ Time.Body.Gyroscope.Stddev.Y                         : num  -0.9511 -0.9665 -0.9877 -0.0546 -0.1263 ...
 $ Time.Body.Gyroscope.Stddev.Z                         : num  -0.908 -0.941 -0.981 -0.344 -0.125 ...
 $ Time.Body.Gyroscope.JerkMean.X                       : num  -0.1073 -0.0937 -0.0996 -0.09 -0.074 ...
 $ Time.Body.Gyroscope.JerkMean.Y                       : num  -0.0415 -0.0402 -0.0441 -0.0398 -0.044 ...
 $ Time.Body.Gyroscope.JerkMean.Z                       : num  -0.0741 -0.0467 -0.049 -0.0461 -0.027 ...
 $ Time.Body.Gyroscope.JerkStddev.X                     : num  -0.919 -0.992 -0.993 -0.207 -0.487 ...
 $ Time.Body.Gyroscope.JerkStddev.Y                     : num  -0.968 -0.99 -0.995 -0.304 -0.239 ...
 $ Time.Body.Gyroscope.JerkStddev.Z                     : num  -0.958 -0.988 -0.992 -0.404 -0.269 ...
 $ Time.Body.Acceleration.Magnitude.Mean                : num  -0.8419 -0.9485 -0.9843 -0.137 0.0272 ...
 $ Time.Body.Acceleration.Magnitude.Stddev              : num  -0.7951 -0.9271 -0.9819 -0.2197 0.0199 ...
 $ Time.Gyroscope.Acceleration.Magnitude.Mean           : num  -0.8419 -0.9485 -0.9843 -0.137 0.0272 ...
 $ Time.Gyroscope.Acceleration.Magnitude.Stddev         : num  -0.7951 -0.9271 -0.9819 -0.2197 0.0199 ...
 $ Time.Body.Acceleration.JerkMagnitude.Mean            : num  -0.9544 -0.9874 -0.9924 -0.1414 -0.0894 ...
 $ Time.Body.Acceleration.JerkMagnitude.Stddev          : num  -0.9282 -0.9841 -0.9931 -0.0745 -0.0258 ...
 $ Time.Body.Gyroscope.Magnitude.Mean                   : num  -0.8748 -0.9309 -0.9765 -0.161 -0.0757 ...
 $ Time.Body.Gyroscope.Magnitude.Stddev                 : num  -0.819 -0.935 -0.979 -0.187 -0.226 ...
 $ Time.Body.Gyroscope.JerkMagnitude.Mean               : num  -0.963 -0.992 -0.995 -0.299 -0.295 ...
 $ Time.Body.Gyroscope.JerkMagnitude.Stddev             : num  -0.936 -0.988 -0.995 -0.325 -0.307 ...
 $ Frequency.Body.Acceleration.Mean.X                   : num  -0.9391 -0.9796 -0.9952 -0.2028 0.0382 ...
 $ Frequency.Body.Acceleration.Mean.Y                   : num  -0.86707 -0.94408 -0.97707 0.08971 0.00155 ...
 $ Frequency.Body.Acceleration.Mean.Z                   : num  -0.883 -0.959 -0.985 -0.332 -0.226 ...
 $ Frequency.Body.Acceleration.Stddev.X                 : num  -0.9244 -0.9764 -0.996 -0.3191 0.0243 ...
 $ Frequency.Body.Acceleration.Stddev.Y                 : num  -0.834 -0.917 -0.972 0.056 -0.113 ...
 $ Frequency.Body.Acceleration.Stddev.Z                 : num  -0.813 -0.934 -0.978 -0.28 -0.298 ...
 $ Frequency.Body.Acceleration.JerkMean.X               : num  -0.9571 -0.9866 -0.9946 -0.1705 -0.0277 ...
 $ Frequency.Body.Acceleration.JerkMean.Y               : num  -0.9225 -0.9816 -0.9854 -0.0352 -0.1287 ...
 $ Frequency.Body.Acceleration.JerkMean.Z               : num  -0.948 -0.986 -0.991 -0.469 -0.288 ...
 $ Frequency.Body.Acceleration.JerkStddev.X             : num  -0.9642 -0.9875 -0.9951 -0.1336 -0.0863 ...
 $ Frequency.Body.Acceleration.JerkStddev.Y             : num  -0.932 -0.983 -0.987 0.107 -0.135 ...
 $ Frequency.Body.Acceleration.JerkStddev.Z             : num  -0.961 -0.988 -0.992 -0.535 -0.402 ...
 $ Frequency.Body.Gyroscope.Mean.X                      : num  -0.85 -0.976 -0.986 -0.339 -0.352 ...
 $ Frequency.Body.Gyroscope.Mean.Y                      : num  -0.9522 -0.9758 -0.989 -0.1031 -0.0557 ...
 $ Frequency.Body.Gyroscope.Mean.Z                      : num  -0.9093 -0.9513 -0.9808 -0.2559 -0.0319 ...
 $ Frequency.Body.Gyroscope.Stddev.X                    : num  -0.882 -0.978 -0.987 -0.517 -0.495 ...
 $ Frequency.Body.Gyroscope.Stddev.Y                    : num  -0.9512 -0.9623 -0.9871 -0.0335 -0.1814 ...
 $ Frequency.Body.Gyroscope.Stddev.Z                    : num  -0.917 -0.944 -0.982 -0.437 -0.238 ...
 $ Frequency.Body.Acceleration.Magnitude.Mean           : num  -0.8618 -0.9478 -0.9854 -0.1286 0.0966 ...
 $ Frequency.Body.Acceleration.Magnitude.Stddev         : num  -0.798 -0.928 -0.982 -0.398 -0.187 ...
 $ Frequency.Body.Body.Acceleration.JerkMagnitude.Mean  : num  -0.9333 -0.9853 -0.9925 -0.0571 0.0262 ...
 $ Frequency.Body.Body.Acceleration.JerkMagnitude.Stddev: num  -0.922 -0.982 -0.993 -0.103 -0.104 ...
 $ Frequency.Body.Body.Gyroscope.Magnitude.Mean         : num  -0.862 -0.958 -0.985 -0.199 -0.186 ...
 $ Frequency.Body.Body.Gyroscope.Magnitude.Stddev       : num  -0.824 -0.932 -0.978 -0.321 -0.398 ...
 $ Frequency.Body.Body.Gyroscope.JerkMagnitude.Mean     : num  -0.942 -0.99 -0.995 -0.319 -0.282 ...
 $ Frequency.Body.Body.Gyroscope.JerkMagnitude.Stddev   : num  -0.933 -0.987 -0.995 -0.382 -0.392 ...
```






