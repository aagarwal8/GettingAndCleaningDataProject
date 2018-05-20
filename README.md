# Getting & Cleaning Data Course Project

This readme file describes the assumptions made for this project, and how the main script (run_analysis.R) works.

## Assumptions
* The data for the project is available in a directory called "UCI HAR Dataset"
* The folder structure for "UCI HAR Dataset" has not been altered in any way
* The main script "run_analysis.R" is in the parent directory of "UCI HAR Dataset"

## Workings of the main script
1. The main script for processing the data is "run_analysis.R"
2. At the begining of the script, 2 functions are defined for better readability of the code & to prevent code-redundancy
  * Since we have to load the exact same type of data twice: once for train & once for test group, a function **loaddataset(group)** has been created, which will load the dataset as described by the "group" parameter. The function returns the dataset which will have subject, activity_id, followed by 561 observations (each named as V{id}, where id is the feature id from features.txt from the original dataset)
  * Another function **getdescriptivefeaturenames(old_colnames)** has been created so the descriptive feature names can be retreived from the column names in the format "V{id}". The function removes "()" from the feature description, and also replaces "-" with "_".
3. The project makes heavy use of data.table, dplyr & tidyr packages, activy labels and features are loaded in separate data tables to be used later (for substituting the ids with descriptive values)
4. rbindlist() is used to merge test & train data sets by column names
5. Using regular expression on the feature description values, only those features are retrieved which are either mean or standard deviation
6. Using the activity labels data table loaded earlier, activity ids are replaced with descriptive values
7. Then using the getdescriptivefeaturenames(), the column names in the dataset are updated to have descriptive names
8. Lastly, using tidyr's gather & spread methods, along with dplyr's group_by & summarise methods, dataset is transformed into a wide-body tidy dataset, where means of all the variables are available by every subject & the activity they performed