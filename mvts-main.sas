/* MVTS Project - January 2025 */

/* Alexander Köhler, M2 EGR */
/* Cerstin Berner, M2 EEE */

/* import data */
PROC IMPORT DATAFILE="/home/u64114842/sasuser.v94/mvts-project-2025/merged_clean.csv"
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
    date_ = INPUT(date, ddmmyy10.); ;
    DROP cpi ppi costs pri date; 
    FORMAT date_ date9.;  /* Example format: 01JAN2006 */
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
RUN;

/* note that we see clear seasonality for costs */






PROC PRINT DATA=work.data_num;  
RUN;


