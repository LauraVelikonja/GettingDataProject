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



Use data.frame
--------------

```r
require("data.table")
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
tbl <- data.table(melt(tbl, key(tbl), variable.name = "feature"))
tbl <- merge(tbl, features, by = "feature",            all.x = TRUE)
```

Converting activity and feature to factor 
-----------------------------------------

```r
tbl$activity <- factor(tbl$activityName)
tbl$feature <- factor(tbl$featureName)
```

Prepare factor columns
----------------------

```r
n <- length(tbl$feature)
tbl$axis <- factor(n, c("X","Y","Z")) #X/Y/Z/NA
tbl$move <- factor(n, c("Body", "Gravity")) #body/gravity
tbl$gear <- factor(n, c("Accelerometer","Gyroscope")) #gyro/accelerometer
tbl$unit <- factor(n, c("Time","Frequency")) #time/freq
tbl$type <- factor(n, c("Mean","Stddev")) #mean/stddev
tbl$jerk <- factor(n, c("Jerk")) #jerk
tbl$magnitude <- factor(n, c("MAgnitude")) #magnitude
```

Filling factor columns
----------------------

```r
tbl[grepl("X$", tbl$feature)==TRUE]$axis<-"X"
tbl[grepl("Y$", tbl$feature)==TRUE]$axis<-"Y"
tbl[grepl("Z$", tbl$feature)==TRUE]$axis<-"Z"
tbl[grepl("BodyAcc", tbl$feature)==TRUE]$move<-"Body"
tbl[grepl("GravityAcc", tbl$feature)==TRUE]$move<-"Gravity"
tbl[grepl("Acc", tbl$feature)==TRUE]$gear<-"Accelerometer"
tbl[grepl("Gyro", tbl$feature)==TRUE]$gear<-"Gyroscope"
tbl[grepl("^t", tbl$feature)==TRUE]$unit<-"Time"
tbl[grepl("^f", tbl$feature)==TRUE]$unit<-"Frequency"
tbl[grepl("mean()", tbl$feature)==TRUE]$type<-"Mean"
tbl[grepl("std()", tbl$feature)==TRUE]$type<-"Stddev"
tbl[grepl("Jerk", tbl$feature)==TRUE]$jerk<-"Jerk"
tbl[grepl("Magnitude", tbl$feature)==TRUE]$magnitude<-"Magnitude"
```

Converting to and saving the tidy data table 
--------------------------------------------

```r
setkey(tbl, subject, activity, unit, move, gear, jerk, magnitude, type, axis)
TidyData <- tbl[, list(count = .N, value = mean(value)), by = key(tbl)]
#saving TidyData
write.table(TidyData, "./Project/GettingDataProjectTidyData.txt", row.name=FALSE)
```

```r
key(TidyData)
```
```
[1] "subject"   "activity"  "unit"      "move"      "gear"      "jerk"      "magnitude" "type"      "axis"  
```

Structure of tidy data
----------------------


Variable name    | Description
-----------------|------------
subject          | Subject identificator (the actual body id)
activity         | Activity name
unit             | Time domain signal or frequency domain signal
move             | Acceleration signal (Body or Gravity)
gear             | Measuring gear (Accelerometer or Gyroscope)
type             | Variable (mean or std)
jerk             | Jerk signal
magnitude        | Magnitude of the signals 
axis             | Signal direction axis (X, Y, or Z)
count            | Count of data points used to compute `average`
value            | Average of each variable for each activity and each subject


```r
head(TidyData, 50)
```

```
   subject activity      unit    move          gear jerk magnitude   type axis count        value
 1:       1   LAYING      Time    Body Accelerometer Jerk        NA   Mean    X    50  0.081086534
 2:       1   LAYING      Time    Body Accelerometer Jerk        NA   Mean    Y    50  0.003838204
 3:       1   LAYING      Time    Body Accelerometer Jerk        NA   Mean    Z    50  0.010834236
 4:       1   LAYING      Time    Body Accelerometer Jerk        NA   Mean   NA    50 -0.954396265
 5:       1   LAYING      Time    Body Accelerometer Jerk        NA Stddev    X    50 -0.958482112
 6:       1   LAYING      Time    Body Accelerometer Jerk        NA Stddev    Y    50 -0.924149274
 7:       1   LAYING      Time    Body Accelerometer Jerk        NA Stddev    Z    50 -0.954855111
 8:       1   LAYING      Time    Body Accelerometer Jerk        NA Stddev   NA    50 -0.928245628
 9:       1   LAYING      Time    Body Accelerometer   NA        NA   Mean    X    50  0.221598244
10:       1   LAYING      Time    Body Accelerometer   NA        NA   Mean    Y    50 -0.040513953
11:       1   LAYING      Time    Body Accelerometer   NA        NA   Mean    Z    50 -0.113203554
12:       1   LAYING      Time    Body Accelerometer   NA        NA   Mean   NA    50 -0.841929152
13:       1   LAYING      Time    Body Accelerometer   NA        NA Stddev    X    50 -0.928056469
14:       1   LAYING      Time    Body Accelerometer   NA        NA Stddev    Y    50 -0.836827406
15:       1   LAYING      Time    Body Accelerometer   NA        NA Stddev    Z    50 -0.826061402
16:       1   LAYING      Time    Body Accelerometer   NA        NA Stddev   NA    50 -0.795144864
17:       1   LAYING      Time Gravity Accelerometer   NA        NA   Mean    X    50 -0.248881798
18:       1   LAYING      Time Gravity Accelerometer   NA        NA   Mean    Y    50  0.705549773
19:       1   LAYING      Time Gravity Accelerometer   NA        NA   Mean    Z    50  0.445817720
20:       1   LAYING      Time Gravity Accelerometer   NA        NA   Mean   NA    50 -0.841929152
21:       1   LAYING      Time Gravity Accelerometer   NA        NA Stddev    X    50 -0.896830018
22:       1   LAYING      Time Gravity Accelerometer   NA        NA Stddev    Y    50 -0.907720007
23:       1   LAYING      Time Gravity Accelerometer   NA        NA Stddev    Z    50 -0.852366290
24:       1   LAYING      Time Gravity Accelerometer   NA        NA Stddev   NA    50 -0.795144864
25:       1   LAYING      Time      NA     Gyroscope Jerk        NA   Mean    X    50 -0.107270949
26:       1   LAYING      Time      NA     Gyroscope Jerk        NA   Mean    Y    50 -0.041517287
27:       1   LAYING      Time      NA     Gyroscope Jerk        NA   Mean    Z    50 -0.074050121
28:       1   LAYING      Time      NA     Gyroscope Jerk        NA   Mean   NA    50 -0.963461030
29:       1   LAYING      Time      NA     Gyroscope Jerk        NA Stddev    X    50 -0.918608521
30:       1   LAYING      Time      NA     Gyroscope Jerk        NA Stddev    Y    50 -0.967907244
31:       1   LAYING      Time      NA     Gyroscope Jerk        NA Stddev    Z    50 -0.957790160
32:       1   LAYING      Time      NA     Gyroscope Jerk        NA Stddev   NA    50 -0.935840983
33:       1   LAYING      Time      NA     Gyroscope   NA        NA   Mean    X    50 -0.016553094
34:       1   LAYING      Time      NA     Gyroscope   NA        NA   Mean    Y    50 -0.064486124
35:       1   LAYING      Time      NA     Gyroscope   NA        NA   Mean    Z    50  0.148689436
36:       1   LAYING      Time      NA     Gyroscope   NA        NA   Mean   NA    50 -0.874759548
37:       1   LAYING      Time      NA     Gyroscope   NA        NA Stddev    X    50 -0.873543868
38:       1   LAYING      Time      NA     Gyroscope   NA        NA Stddev    Y    50 -0.951090440
39:       1   LAYING      Time      NA     Gyroscope   NA        NA Stddev    Z    50 -0.908284663
40:       1   LAYING      Time      NA     Gyroscope   NA        NA Stddev   NA    50 -0.819010170
41:       1   LAYING Frequency    Body Accelerometer Jerk        NA   Mean    X    50 -0.957073884
42:       1   LAYING Frequency    Body Accelerometer Jerk        NA   Mean    Y    50 -0.922462610
43:       1   LAYING Frequency    Body Accelerometer Jerk        NA   Mean    Z    50 -0.948060904
44:       1   LAYING Frequency    Body Accelerometer Jerk        NA   Mean   NA    50 -0.933300361
45:       1   LAYING Frequency    Body Accelerometer Jerk        NA Stddev    X    50 -0.964160709
46:       1   LAYING Frequency    Body Accelerometer Jerk        NA Stddev    Y    50 -0.932217870
47:       1   LAYING Frequency    Body Accelerometer Jerk        NA Stddev    Z    50 -0.960586987
48:       1   LAYING Frequency    Body Accelerometer Jerk        NA Stddev   NA    50 -0.921803976
49:       1   LAYING Frequency    Body Accelerometer   NA        NA   Mean    X    50 -0.939099052
50:       1   LAYING Frequency    Body Accelerometer   NA        NA   Mean    Y    50 -0.867065205
    subject activity      unit    move          gear jerk magnitude   type axis count        value
```








