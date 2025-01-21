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


/* We create a filtered dataset only looking at the time period after 2005: as this is when we have PRI data */
data work.data_filtered;
    set work.data_num; 
    where date_ >= input('2005-01-01', yymmdd10.) and date_ <= input('2019-01-01', yymmdd10.); /* Keep data between 2005 and 2019 */
run;

/*Wir sollten versuchen NAs mit 0 zu ersetzen?*/
data work.data_filtered;
    set work.data_filtered;
    array num_vars _numeric_;  /* Create an array of all numeric variables */
    do i = 1 to dim(num_vars);
        if num_vars[i] = . then num_vars[i] = 0; /* Replace missing with 0, for costs */
    end;
    drop i;  /* Drop the loop variable */
run;

/* unit root testing */
proc autoreg;
    model costs_num = / stationarity = (ADF, PHILLIPS, NG, KPSS=(KERNEL=NW auto));
    model pri_num = / stationarity = (ADF, PHILLIPS, NG, KPSS=(KERNEL=NW auto));
    model cpi_num = / stationarity = (ADF, PHILLIPS, NG, KPSS=(KERNEL=NW auto));
    model ppi_num = / stationarity = (ADF, PHILLIPS, NG, KPSS=(KERNEL=NW auto));
run;
/*
costs: reject unit root, ADF and NG and Perron MZalpha, do not reject stationarity !
pri_num: reject unit root, and reject stationarity, can be AR(2) due to PACF
cpi_num: do not reject unit root in all cases, reject stationarity. I(1) varaible
ppi_nunm: do not reject unit root in all cases, reject stationarity. I(1) varaibles
*/

/* We check log costs and the difference of log cpi as cpi_num is I(1).
As CPI is the only integrated variable, we difference it to model it in our VAR model. */
DATA work.data_filtered;
    SET work.data_filtered;
    cpi_logfd = DIF(Log(cpi_num));
RUN;

proc autoreg data=work.data_filtered;
    model cpi_logfd = / stationarity = (ADF, PHILLIPS, NG, KPSS=(KERNEL=NW auto));
run;

/* cpi_logfd: we reject unit root now, and can thus use it in our VAR model */



/* 
To double check, we test for a cointegration relationship between cpi_num and costs, in case costs are in reality I(1). (Robustness check)
*/
data work.data_filtered;set work.data_filtered; by date_;
proc reg data=work.data_filtered;
	model cpi_num = costs_num;
	output out=work.reg_results Residual=res;
run;
quit;
data work.reg_results;set work.reg_results; by date_;
/*R^2 very low, coefficient for cost_num is very low, insignificant compared to 0.*/
proc gplot;
	plot res*date_;
run;
quit;
/* Plot of residuals, looks non-stationary */
/* ADF test - Residuals have a unit root and are highly autocorrelated  */
proc autoreg data=work.reg_results;
    model res = / stationarity=(ADF, PHILLIPS, NG, KPSS=(KERNEL=NW auto));
run;

data b; set b; by date_; 
    /* ADF for non-cointegration */ 
    /* lag order selection */ 
    dres = dif(res); 
    res1 = lag(res); 
    dres1 = lag(dif(res)); 
    dres2 = lag2(dif(res)); 
    dres3 = lag3(dif(res)); 
    dres4 = lag4(dif(res)); 
    dres5 = lag5(dif(res)); 
    dres6 = lag6(dif(res)); 
    dres7 = lag7(dif(res)); 
    dres8 = lag8(dif(res)); 
run;
/* first lag of residual is significant, for residual explanation, 2nd at 10% */
data b; set b; 
if dres8^= .;
proc reg;
	model dres = res1 dres1-dres8;
	d1: test dres8;
	d2: test dres7-dres8;
	d3: test dres6-dres8;
	d4: test dres5-dres8;
	d5: test dres4-dres8;
	d6: test dres3-dres8;
	d7: test dres2-dres8;
	d8: test dres1-dres8;
run;
data b; set b; by date_; /* test select 1 lag, as reject H0: lag8 to lag1 = 0 for this one*/
proc reg;
	model dres = res1 dres1;
run;
/* to maintain H_0: lag 8 is not in the data
we do not reject d7: lag 8 -> lag 2. but we reject d8: lag8 -> lag 1, meaning lag 1 is non-zero. 
from the regression, we maintain the null with a p-value of 0.9943 that the coefficient for the residuals 
are not significantly different from 0 when regressing the lagged residuals on themselves. FD of residual explains all the variation,
 the level of the residual res1 is not significant.
So the time series costs_num and cpi_num are not cointegrated as the residuals from the regression are not stationary.
*/

/* Alternative is the Johansen test*/
proc varmax data=work.data_filtered;
    id date_ interval=month;
    model costs_num cpi_num/ p=8 cointtest=(johansen=(type=trace));
run;
/* We reject Cointegration, full rank of cointegraion, can estimate as a VAR in difference. */


/* We proceed with the VAR model estimations, using cpi in FD(log)*/

proc arima data=work.data_filtered;
    identify var=cpi_logfd stationarity=(adf=(0,1,2,3,4,5));
    identify var=costs_num stationarity=(adf=(0,1,2,3,4,5));
    identify var=pri_num stationarity=(adf=(0,1,2,3,4,5));
run;



/* Estimate the VAR model and generate impulse response functions */
proc varmax data=work.data_filtered plots=(impulse forecast);
    id date_ interval=month;
    model costs_num cpi_logfd pri_num / p=8 lagmax=9 
                                      minic=(p=4 q=4 type=HQC)
                                      print=(estimates diagnose impulse=ORTH);
    causal group1=(costs_num) group2=(cpi_logfd);
    causal group1=(costs_num) group2=(pri_num);
    causal group1=(pri_num) group2=(cpi_logfd);
    output out=work.forecast lead=6; /* 6-month forecast */
run;
quit;
/* Results are very interesting. Granger Causality von PRI auf cpi ist significant.
 Modell basierend auf HQC und minimum likelihood wäre VARMA(1,1), AR1 und MA1.
 VAR cross-coefficients not significant though.
 no cross-correlation of residuals
 
 */



/*PPI robustness */
proc varmax data=work.data_filtered;
    id date_ interval=month;
    model ppi_logfd pri_fd = costs_log ppi_log pri_num / p=8 nocurrentx xlag=1;
run;
quit;


