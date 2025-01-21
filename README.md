# Multivariate-Time-Series

Die Daten, die für SAS genutzt werden nennen sich 'merged_clean'. Der cleaning Code ist in der R file.

Der SAS Code, der für die eigentliche Analyse genutzt wird, ist der "mvts-main.sas" Code. Ich habe da schon mal die Daten importiert und umgewandelt und die Plots erstellt. 

Cerstin, 20. Januar: In mvts-main wurden die unit root tests mit log-difference wiederholt für alle drei variablen. Ich suche noch nach einem geigneten Filter für Costs, deswegen sind die daten gerade erst in der log difference.

Alex, 20. Januar: Bin am VAR model programmieren und cointegration tests am machen. Zeitspanne der Data wurde reduziert auf 2005 bis ende 2018 ("data_filtered"), da wir für die Zeit PRI und Cost daten haben. Ich habe das Daten Format der .csv file geändert und den Code, sodass SAS die Daten jetzt richtig lest. WICHTIG!!!!: benutze bitte die neue Datei mit dem Code, darin wurden die Daten neu Formatiert. Code für Cointegration muss nich geschrieben werde, die Daten umformatierung hat zu lange gedauert...

Alex, 21. Januar: VAR model estimation und kointegrations Tests Code läuft jetzt, VAR Residuen analyse wurde auch programmiert. Was fehlt sind noch die Impulse Response Funktions. Unsere Resultate zeigen jedoch, dass wir (im Moment mit den jetzigen Daten und den transformationen die wir gemacht haben) keine signifikante Korrelation zwischen Costs und CPI bzw. zwischen PRI und CPI sehen. Können wir später besprechen. Robustness mit PPI und mit daten bis 2023? sollte noch gemacht werden, vielleicht nur zwischen CPI und PRI oder PPI und PRI.

Cerstin, 21. Januar: Ich habe mir sein empirical example noch mal angeschaut und den folgenden Workflow erarbeitet, wonach die analyse stattfinden sollte:

1) Check time series visually
2) Check for unit roots
3) Johansen Cointegration Test (For Multiple Variables) 
	-> Yes: Do VECM, No: VAR (potentially in first difference)


4) ADF on residuals - Engle-Granger Cointegration Test for two variables:

	Run Regression Between the Two Non-Stationary Series; residuals represent the deviations from the estimated long-run relationship.
		
	Do ADF on Residuals:
		
		Null Hypothesis: The residuals have a unit root (i.e., are non-stationary) → No cointegration.

		Alternative Hypothesis: The residuals are stationary (I(0)) → Cointegration exists.

5) Do Var estimation if not cointegrated, Vecm if cointegrated 
6) DO Granger Causality Test To determine whether one variable 
	can predict another (e.g., does productivity cause wages?)
	
	Null Hypothesis: Variable in group1 does not Granger-cause variable in group2.
	
	If rejected (p-value < 0.05) → Granger causality exists.

7) Refine lag selection using AIC/BIC in PROC VARMAX. Note here: He sets specific lags in his examples, e.g. maxp = 8 but I am very sure that he had a general idea about his TS, this is not arbitrary. I suggest we use HQC to let SAS define the model parameters.

8) After Estimating a VAR or VECM, We Perform an Impulse Response Function (IRF) Analysis.
   


Report: 
- Introduction
- Literature
- Descriptive Evidence --> Bearbeite den Cost Time Series und PRI Time Series, sodass man große Disaster erkennt
- Modelling
- Results
- Robustness mit PPI
- Conclusion
