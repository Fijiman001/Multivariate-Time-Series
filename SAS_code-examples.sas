
/* get working directory */

%PUT %SYSGET(HOME);
RUN;


/* Quarterly Data from Example on US GDP */
PROC IMPORT DATAFILE="/home/u64114842/sasuser.v94/mvts-project-2025/gdpusa.csv" /* import data set */ 
    OUT=work.mydata
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/* _N_ assigns row numbers as an artificial index */
/* Create the log-transformed GDP variable */
DATA work.timeseries;
    SET work.mydata;
    IF GDPC1 > 0 THEN loggdp = log(GDPC1); /* Ensure no log of 0 or negative values, could be useful for later*/
    TIME = _N_; 
    fd_gdp = DIF(GDPC1);
RUN;

/* Plot the original time series */
PROC SGPLOT DATA=work.timeseries;
    SERIES X=TIME Y=GDPC1;  /* Replace 'gdp' with your actual variable */
    TITLE "GDP Time Series";
RUN;

/* For US GDP, we can already see a trend --> unit root very possible, so we do first difference to get rid of it */

/* Plot the FD time series */
PROC SGPLOT DATA=work.TIMESERIES;
    SERIES X=TIME Y=fd_gdp;  
    TITLE "FD GDP Time Series";
RUN;

/* ACF and PACF */

PROC ARIMA DATA=work.timeseries;
   IDENTIFY VAR=GDPC1 NLAG=50; /* ACF and PACF for 50 lags */
RUN;

/* normally here we would ideally see AR or MA behaviour --> if not ARIMA definition using iterative method*/

/* UNIT ROOT TEST , simple example --> need to specify tested lag first*/
PROC AUTOREG DATA=work.TIMESERIES;
    MODEL fd_gdp = / STATIONARITY=(KPSS=(Kernel=NW auto), ERS, NP=8);
RUN; 

/* UNIT ROOT TEST , more specific and for multiple variables */

data a;set database; 
loggdp=log(GDPC1_20221222);
logpce=log(PCECC96);
run;
proc autoreg;
model loggdp =/stationarity = (ADF, PHILLIPS, ERS, NG, KPSS=(KERNEL=NW auto));
model logpce =/stationarity = (ADF, PHILLIPS, ERS, NG, KPSS=(KERNEL=NW auto));
run; 
quit;

PROC ARIMA DATA=work.timeseries;
   IDENTIFY VAR=fd_gdp NLAG=50; /* ACF and PACF for 50 lags */
RUN;
QUIT;


/* from his empirical example - 'simple VAR estimations' */
/* here we do not use the same data set as before anymore */

/* non cointegration test */
data a;set a;by date;
proc reg;
model logWR = productivity/DW;
output out=b R=res;
run;
quit;
data b;set b; by date;
proc gplot;
plot res*date;
run;
quit;
data b;set b; by date;

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

data b;set b;
if dres8^=.;
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
quit;

data b;set b; by date;
/* lag order selected : 1 */ 
proc reg;
model dres = res1 dres1;
run;
quit;

data a;set a;by date; 
dlogWR = dif(logWR);
dprod = dif(productivity);
proc varmax;
   id date interval=qtr;
   model dlogWR dprod  / p=8 noint lagmax=9
                 print=(estimates diagnose);
   causal group1=(dlogWR) group2=(dprod);
   causal group1=(dprod) group2=(dlogWR);
   output out=for lead=4;
run;
quit;





