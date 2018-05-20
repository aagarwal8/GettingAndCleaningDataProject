# function loads either the "train" or "test" dataset based on the group parameter
loaddataset <- function(group) {
    # verify group value
    if (!(group %in% c("test", "train"))) {
        stop("Invalid value for group. Only 'test' & 'train' are allowed.")
    }
    # verify all files exist
    data_dir <- "./UCI HAR Dataset/"
    subject_filename <- paste0(data_dir, group, "/subject_", group, ".txt")
    activities_filename <- paste0(data_dir, group, "/y_", group, ".txt")
    data_filename <- paste0(data_dir, group, "/X_", group, ".txt")
    if (!file.exists(subject_filename)) {
        stop(paste(subject_filename, "does not exit."))
    } else if (!file.exists(activities_filename)) {
        stop(paste(activities_filename, "does not exit."))
    } else if (!file.exists(data_filename)) {
        stop(paste(data_filename, "does not exit."))
    }

    # load subjects
    subjects <- fread(subject_filename, header = F, col.names = c("subject"))
    # add an id column that will be used later to join the different datasets
    subjects[, id := .I]
    setkey(subjects, "id")

    # load activities performed by the subjects
    activities <- fread(activities_filename, header = F, col.names = c("activity_id"))
    # add an id column that will be used later to join the different datasets
    activities[, id := .I]
    setkey(activities, "id")

    # load readings/data
    data <- fread(data_filename, header = F, sep = " ")
    # add an id column that will be used later to join the different datasets
    data[, id := .I]
    setkey(data, "id")

    # finally create a single dataset
    dataset <- inner_join(subjects, activities, by="id") %>%
                    select(id, subject, activity_id) %>%
                    inner_join(data, by="id")
                    select(everything(), -id)

    # return the dataset
    invisible(dataset)
}

# for a given character vector (old_colnames)
# the function returns the descriptive names for each column which is in the format "V<<id>>"
# descriptive names are looked up in the features dataset (loaded from features.txt) by id
# any value not in the above format is returned as-is
getdescriptivefeaturenames <- function(old_colnames) {
    new_colnames <- character()
    for (name in old_colnames) {
        if (substr(name, 1, 1) == "V") {
            # extract the ID
            id <- as.numeric(gsub("^V","", name))
            # remove "()" & replace "-" with "_" in the name, and then append to the new_colnames vector
            new_colnames <- c(new_colnames, gsub("-", "_", gsub("\\(\\)", "", features[id]$description)))
        } else {
            # do nothing; simply append the column name
            new_colnames <- c(new_colnames, name)
        }
    }

    # return the dataset
    invisible(new_colnames)
}

# load needed libraries
library(data.table)
library(dplyr)
library(tidyr)

# load activity labels
activity_labels <- fread("./UCI HAR Dataset/activity_labels.txt", sep = " ", header = F, col.names = c("activity_id", "activity"))

# load features
features <- fread("./UCI HAR Dataset/features.txt", sep = " ", header = F, col.names = c("id", "description"))

# merge the test & train datasets (***Requirement #1***)
# only select data for mean & standard deviation measurements (***Requirement #2***)
# replace activity id with activity description (***Requirement #3***)
data <- rbindlist(list(loaddataset("test"), loaddataset("train")), use.names = T) %>%
            select(c(1, 2, num_range("V", features[grepl('mean\\(\\)|std\\(\\)', features$description), id]))) %>%
            inner_join(activity_labels, by="activity_id") %>%
            select(subject, activity, everything(), -activity_id)

# add descriptive column names (***Requirement #4***)
colnames(data) <- getdescriptivefeaturenames(colnames(data))

# final tidy dataset with means of all variables by subject & activity (***Requirement #5***)
write.table(data %>%
                gather(key="variable", value="value", -(1:2)) %>%
                group_by(subject, activity, variable) %>%
                summarise(mean=mean(value)) %>%
                spread(key = "variable", value = "mean"), file = "tidy_dataset.txt", row.names = FALSE)