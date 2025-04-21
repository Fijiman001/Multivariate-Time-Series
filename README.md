# Multivariate-Time-Series

## Possible Extensions and Improvements
- Model using maximum observed perceived risk index not using mean.
- Refine Impulse Response Function Graphs and plotted Confidence Intervals, double check HAC errors are used.
- Repeat Study with extended data and or more spatial granularity.

## Methodological Procedure

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
   
## To-Do in Report

Report: 
- Introduction
- Literature
- Descriptive Evidence --> Bearbeite den Cost Time Series und PRI Time Series, sodass man große Disaster erkennt
- Modelling
- Results
- Robustness mit PPI
- Conclusion
