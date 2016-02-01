#Use data.frame
require("data.table")


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

head(features)

features$feature

#Normalize the table
tbl <- merge(tbl, activities, by = "activity", all.x = TRUE)
setkey(tbl, subject, activity, activityName)
tbl <- data.table(melt(tbl, key(tbl), variable.name = "feature"))
tbl <- merge(tbl, features, by = "feature",            all.x = TRUE)

#Converting activity and feature to factor 
tbl$activity <- factor(tbl$activityName)
tbl$feature <- factor(tbl$featureName)

#Prepare factor columns
n <- length(tbl$feature)
tbl$axis <- factor(n, c("X","Y","Z")) #X/Y/Z/NA
tbl$move <- factor(n, c("Body", "Gravity")) #body/gravity
tbl$gear <- factor(n, c("Accelerometer","Gyroscope")) #gyro/accelerometer
tbl$unit <- factor(n, c("Time","Frequency")) #time/freq
tbl$type <- factor(n, c("Mean","Stddev")) #mean/stddev
tbl$jerk <- factor(n, c("Jerk")) #jerk
tbl$magnitude <- factor(n, c("MAgnitude")) #magnitude

#filling factor columns
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

#converting multi-row to tidy table 
setkey(tbl, subject, activity, unit, move, gear, jerk, magnitude, type, axis)
TidyData <- tbl[, list(count = .N, value = mean(value)), by = key(tbl)]

#saving TidyData
write.table(TidyData, "./Project/GettingDataProjectTidyData.txt", row.name=FALSE)
key(TidyData)
head(TidyData, 50)

