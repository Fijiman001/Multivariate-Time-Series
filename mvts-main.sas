 /* MVTS Project - January 2025 */

/* Alexander Köhler, M2 EGR  u64130652 */ 
/* Cerstin Berner, M2 EEE u64114842 */

/* import data */
PROC IMPORT DATAFILE="/home/u64130652/sasuser.v94/mvts-project-2025/merged_clean_adjusted.csv"
    OUT=work.data
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
    GUESSINGROWS=MAX;  /* Makes sure SAS scans all rows before deciding variable types */
    DATAROW=2; /* Start reading data from row 2 */
RUN;

/* check data types*/

PROC CONTENTS DATA=work.data;
RUN;

DATA work.data_num;
    SET work.data;
    costs_num = INPUT(costs, BEST12.);
    cpi_num = INPUT(cpi, BEST12.);
    ppi_num = INPUT(ppi, BEST12.);
    pri_num = INPUT(pri, BEST12.); 
    temp_date = put(date, 10.);
    date_ = input(temp_date, MMDDYYYY10.);
    DROP cpi ppi costs pri temp_date date VAR6; 
    FORMAT date_ yymmdd10.;  /* Example format: 01JAN2006 */
RUN;

PROC CONTENTS DATA=work.data_num;
RUN;

/* Plot time series + ACF and PACF */

/* PRI Time Series*/
PROC SGPLOT DATA=work.data_num;
    SERIES X=date_ Y=pri_num;  
    WHERE date_ > '01JAN2005'd;
    TITLE "PRI Time Series";
RUN;
/* PRI ACF and PACF*/
PROC ARIMA DATA=work.data_num;
    /* IDENTIFY VAR=pri_num(1); */ /* if we want first difference directly*/
    IDENTIFY VAR=pri_num;
RUN;



/* CPI Time Series*/
PROC SGPLOT DATA=work.data_num;
    SERIES X=date_ Y=cpi_num;  
    WHERE date_ > '01JAN1995'd;
    TITLE "CPI Time Series";
RUN;
/* CPI ACF and PACF*/
PROC ARIMA DATA=work.data_num;
    /* IDENTIFY VAR=cpi_num(1); */ /* if we want first difference directly*/
    IDENTIFY VAR=cpi_num;
RUN;


/* PPI Time Series*/
PROC SGPLOT DATA=work.data_num;
    SERIES X=date_ Y=ppi_num;  
    WHERE date_ > '01JAN1995'd;
    TITLE "PPI Time Series";
RUN;
/* PPI ACF and PACF*/
PROC ARIMA DATA=work.data_num;
    /* IDENTIFY VAR=ppi_num(1); */ /* if we want first difference directly*/
    IDENTIFY VAR=ppi_num;
RUN;

/* Costs Time Series*/
PROC SGPLOT DATA=work.data_num;
    SERIES X=date_ Y=costs_num;  
    WHERE date_ > '01JAN1980'd;
    TITLE "Costs Time Series";
RUN;
/* Costs ACF and PACF*/
PROC ARIMA DATA=work.data_num;
    /* IDENTIFY VAR=ppi_num(1); */ /* if we want first difference directly*/
    IDENTIFY VAR=costs_num;
RUN; /* note that we see clear seasonality for costs */

/* unit root testing */

/* PRI: could be stationary - have to test with ADF without trend component */
proc autoreg;
    model costs_num = / stationarity = (ADF, PHILLIPS, ERS, NG, KPSS=(KERNEL=NW auto));
    model pri_num = / stationarity = (ADF, PHILLIPS, ERS, NG, KPSS=(KERNEL=NW auto));
run;
quit;


/*Test Unit Root for first log difference of ppi and cpi*/

/* first difference (cpi, ppi) and log (for costs)*/
DATA work.data_num;
    SET work.data_num;
    costs_log = Log(costs_num);
    costs_logfd = DIF(costs_log);
    
    cpi_fd = DIF(cpi_num);
    cpi_log = Log(cpi_num);
    cpi_logfd = DIF(cpi_log);
    
    ppi_fd = DIF(ppi_num); 
    ppi_log = Log(ppi_num);
    ppi_logfd = DIF(ppi_log);
    
    /* also take log f.d. of PRI as it is not stationary*/
   	pri_fd = DIF(pri_num);
   	pri_log = Log(pri_num);
   	pri_logfd = DIF(pri_log);
RUN;

/* take log cost and not fd. of costs, as with f.d. value is 0 unless there was a value in the period before.*/
proc autoreg;
    model costs_log = / stationarity = (ADF, PHILLIPS, ERS, NG, KPSS=(KERNEL=NW auto));
    model cpi_logfd = / stationarity = (ADF, PHILLIPS, ERS, NG, KPSS=(KERNEL=NW auto));
    model ppi_logfd = / stationarity = (ADF, PHILLIPS, ERS, NG, KPSS=(KERNEL=NW auto));
    model pri_fd = / stationarity = (ADF, PHILLIPS, ERS, NG, KPSS=(KERNEL=NW auto));
run;
quit;

/* Overview:
costs_log is stil not stationary, maybe centre around the trend?
CPI is stationary
PPI should be stationary if we exclude the extreme spike at the end
PRI is stationary

In any case, below is the code for a VAR model estimation.
We first need to ensure no cointegration is present between our original time series.
 */


/* Log transformation and differencing for stationarity analysis */
proc arima data=work.data_num;
    identify var=cpi_logfd stationarity=(adf=(0,1,2,3,4,5));
    identify var=costs_log stationarity=(adf=(0,1,2,3,4,5));
    identify var=pri_fd stationarity=(adf=(0,1,2,3,4,5));
run;
/* only costs ADF test is not rejected? */


/* We create a filtered dataset only looking at the time period after 2005: as this is when we have PRI data */
data work.data_filtered;
    set work.data_num; 
    where date_ >= input('2005-01-01', yymmdd10.) and date_ <= input('2019-01-01', yymmdd10.); /* Keep data between 2005 and 2019 */
    keep date_ costs_log cpi_logfd pri_fd pri_num cpi_log ppi_log ppi_logfd;
run;

/*Wir sollten versuchen NAs mit 0 zu ersetzen?*/
data work.data_filtered;
    set work.data_filtered;
    array num_vars _numeric_;  /* Create an array of all numeric variables */
    do i = 1 to dim(num_vars);
        if num_vars[i] = . then num_vars[i] = 1; /* Replace missing with 1, as log */
    end;
    drop i;  /* Drop the loop variable */
run;

/* Ensure there is no cointegration between the series, Note: we need to ensure that the variables are stationary for later!!!! */
proc varmax data=work.data_filtered;
    id date_ interval=month;
    model costs_log cpi_log pri_num / p=8 cointtest=(johansen=(type=trace));
run;
quit;
/* We reject Cointegration, no rank of cointegraion, can estimate as a VAR in difference. */

/* Estimate the VAR model and generate impulse response functions */
proc varmax data=work.data_filtered;
    id date_ interval=month;
    model costs_log cpi_logfd pri_fd / p=8 lagmax=9 
                                      minic=(p=4 q=4 type=HQC)
                                      print=(estimates diagnose impulse=ORTH);
    causal group1=(pri_fd) group2=(costs_log);
    causal group1=(pri_fd) group2=(cpi_logfd costs_log);
    output out=forecast lead=6; /* 6-month forecast */
run;
quit;

proc varmax data=work.data_filtered;
    id date_ interval=month;
    model cpi_logfd pri_fd = costs_log cpi_log pri_num / p=8 nocurrentx xlag=1;
run;
quit;

/*PPI robustness */
proc varmax data=work.data_filtered;
    id date_ interval=month;
    model ppi_logfd pri_fd = costs_log ppi_log pri_num / p=8 nocurrentx xlag=1;
run;
quit;

/*  We look at the fit of our VAR model, Ich verstehe nicht weshalb Gregoir xlag=1 und nocurrentx benutzt in seinem Code.
Aber es funktioniert.... */
proc varmax data=work.forecast plots=residual(residual normal);
model costs_log cpi_logfd pri_fd/ p=8 nocurrentx xlag=1 print=(diagnose);
run;
/* 
Von den Graphiken / Resultaten her sieht es aus also ob wir keine signifikanten Koeffizienten habe, außer für den PRI Index,
welcher eine gewisse Autokorrelation zeigt. Fazit, wir sehen keine signifikante Korrelation zwischen Unwetter verursachten Kosten
und Versicherung CPI / auch nicht von PRI auf CPI. Unsere Hypothese wird nicht von den Daten unterstützt, vermutlich auch wegen der
Daten Selektion und die Datentransformationen die wir machen.
*/


/* Plot the impulse response functions, not working currently */
proc sgplot data=work.forecast;
    where _TYPE_="IMPULSE"; /* Filter impulse response data */
    series x=_NAME_ y=pri_fd / group=VAR lineattrs=(pattern=solid);
    series x=_NAME_ y=cpi_logfd / group=VAR lineattrs=(pattern=dash);
    series x=_NAME_ y=costs_log / group=VAR lineattrs=(pattern=dot);
    xaxis label="Lag" grid;
    yaxis label="Response" grid;
run;
quit;


PROC PRINT DATA=work.data_filtered;  
RUN;

