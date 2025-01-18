# Clean the data set before inserting into SAS

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

merged$costs = as.numeric(merged$costs)
merged$ppi = as.numeric(merged$ppi)
merged$cpi = as.numeric(merged$cpi)
merged$pri = as.numeric(merged$pri)

merged[is.na(merged) == TRUE] <- ""

write.table(merged, "merged_clean.csv", 
            sep = ",", row.names = FALSE, col.names = TRUE, 
            quote = FALSE, na = "")



  

