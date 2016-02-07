#Use data.frame
require(data.table)
require(dplyr)
library(plyr)

#Download and unzip data
getwd()
if(!file.exists("./Project/data")){
    dir.create("./Project/data");
}
download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", "./Project/data/DataSet.zip",method="curl")
dateDownloaded <- date()
unzip("./Project/data/DataSet.zip", exdir = "./Project/data/extracted/" )
list.files("./Project/data/extracted/", recursive=TRUE )

#Read the data
fpath <- "./Project/data/extracted/UCI HAR Dataset/"
subject_train <- fread(paste0(fpath, "train/subject_train.txt"))
subject_test <- fread(paste0(fpath, "test/subject_test.txt"))
data_train <- data.table(read.table(paste0(fpath, "train/X_train.txt")))
data_test <- data.table(read.table(paste0(fpath, "test/X_test.txt")))
act_train <- fread(paste0(fpath, "train/y_train.txt"))
act_test <- fread(paste0(fpath, "test/y_test.txt"))
activities <- fread(paste0(fpath, "activity_labels.txt"))
features  <- fread(paste0(fpath, "features.txt"))

#Set names for dictionaries
setnames(activities, names(activities), c("activity", "activityName"))
setnames(features, names(features), c("featureNum", "featureName"))


#Merging test and train data and activities/subject 
subject_all <- rbind(subject_train, subject_test)
setnames(subject_all, "V1","subject")
act_all <- rbind(act_train, act_test)
setnames(act_all, "V1","activity")
tbl <- rbind(data_train, data_test)
dt_sa <- cbind(subject_all, act_all)
tbl <- cbind(dt_sa, tbl)

#Extract only the mean and standard deviation columns
setkey(tbl, subject, activity)
features <- features[grepl("mean\\(\\)|std\\(\\)", featureName)]
features$feature <- features[, paste0("V", featureNum)]
select <- c(key(tbl), features$feature)
tbl <- tbl[, select, with = FALSE]
head(dtFeatures)
features$feature

#Normalize the table
tbl <- merge(tbl, activities, by = "activity", all.x = TRUE)
setkey(tbl, subject, activity, activityName)
tbl$activity <- factor(tbl$activityName)

#renaming features
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

#Summarizing
TidyData <- ddply(tbl, c("subject","activity"), numcolwise(mean))
write.table(TidyData, "./Project/GettingDataProjectTidyData.txt", row.name=FALSE)

#Little info
names(TidyData)
str(TidyData)
