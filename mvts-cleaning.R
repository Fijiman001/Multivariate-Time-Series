# Clean the fucking data set before inserting into SAS

library(readr)
library(dplyr)

setwd("/Users/cerstinberner/Desktop/M2-EMP.-ECON-&-ECONOMETRICS/Semester I/Multivariate Time Series/Empirical Project/Data")

merged <- read.csv("Merged.csv")
View(merged)
colnames(merged)

colnames(merged) <- c("date", "costs", "pri", "cpi", "ppi")

class(merged) # have to handle this specifically

# get rid of "-" and put NA instead

merged[merged == " -   "] <- NA
merged$costs <- trimws(merged$costs)
merged$costs <- gsub("[^0-9.-]", "", merged$costs)
merged[merged == ""] <- NA

write.csv(merged, "merged_clean.csv")





  

