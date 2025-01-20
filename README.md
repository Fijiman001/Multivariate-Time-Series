# Multivariate-Time-Series

Die Daten, die für SAS genutzt werden nennen sich 'merged_clean'. Der cleaning Code ist in der R file.

Der SAS Code, der für die eigentliche Analyse genutzt wird, ist der "mvts-main.sas" Code. Ich habe da schon mal die Daten importiert und umgewandelt und die Plots erstellt. 

Cerstin, 20. Januar: In mvts-main wurden die unit root tests mit log-difference wiederholt für alle drei variablen. Ich suche noch nach einem geigneten Filter für Costs, deswegen sind die daten gerade erst in der log difference.


Noch zu tun ist: 

Analysis/Modelling:
- AR/MA p-q Wahl und Modelling
- Falls ARMA: Iterative p-q Selektion
- Cointegration Test
- VAR Model Estimation

Report: 
- Introduction
- Literature
- Descriptive Evidence --> Bearbeite den Cost Time Series und PRI Time Series, sodass man große Disaster erkennt
- Modelling
- Results
- Robustness mit PPI
- Conclusion
