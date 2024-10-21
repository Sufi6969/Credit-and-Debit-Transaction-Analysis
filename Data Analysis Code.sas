proc import datafile='/home/u63391350/Project 3/New_Account.xlsx' out=New_Account dbms=xlsx replace;
    sheet='Sheet1';
    getnames=yes;
run;
proc import datafile='/home/u63391350/Project 3/New_Card.xlsx' out=New_Card dbms=xlsx replace;
    sheet='Sheet1';
    getnames=yes;
run;
proc import datafile='/home/u63391350/Project 3/District.xlsx' out=District dbms=xlsx replace;
    sheet='Sheet1';
    getnames=yes;
run;
proc import datafile='/home/u63391350/Project 3/Loan.xlsx' out=Loan dbms=xlsx replace;
    sheet='Sheet1';
    getnames=yes;
run;
proc import datafile='/home/u63391350/Project 3/New_Client.xlsx' out=New_Client dbms=xlsx replace;
    sheet='Sheet1';
    getnames=yes;
run;
proc import datafile='/home/u63391350/Project 3/New_Disposition.xlsx' out=New_Disposition dbms=xlsx replace;
    sheet='Sheet1';
    getnames=yes;
run;
proc import datafile='/home/u63391350/Project 3/New_Transaction.xlsx' out=New_Transaction dbms=xlsx replace;
    sheet='Sheet1';
    getnames=yes;
run;
proc import datafile='/home/u63391350/Project 3/Order.xlsx' out=Order dbms=xlsx replace;
    sheet='Sheet1';
    getnames=yes;
run;
/***********************************************************************************************************/
/*Sorting And Merge Data*/
proc sort data=New_Account;
  by Account_id;
run;
proc sort data=New_Transaction;
  by Account_id;
run;
data Merged;
    merge New_Account (in=a) New_Transaction (in=b);
    by Account_id;
    if a and b;
run;
/*Merge*/
proc sort data=Merged;
  by District_id;
run;
proc sort data=District;
  by District_id;
run;
data Final_Merged;
    merge Merged (in=a) District (in=b);
    by District_id;
    if a and b;
run;

/***********************************************11111********************************************************/
/* Problem Statement 1: Filter Credit transactions from Moravia and Prague */
data Credit_Transactions;
  set Final_Merged;
  where Type = 'CREDIT' and (Region = 'north Moravia' or Region = 'south Moravia' or Region = 'Prague');
run;

/* PS1.A: Acount wise Aggregate */
proc sort data=Credit_Transactions;
  by Account_id;
run;
proc means data=Credit_Transactions noprint;
  by Account_id;
  var Amount;
  output out=Account_Wise_Summary(keep=Account_id Total_Amount) sum=Total_Amount;
run;


/***********************************************22222********************************************************/
/* Problem Statement 2: Analysis of Highly Populated versus Low populated Districts */
proc means data=District noprint;
    var Population;
    output out=AveragePopulation(drop=_type_ _freq_) mean=AvgPopulation;
run;
/* Step 2: Identify the top 5 highly populated districts and the 5 lowest populated districts */
proc sort data=District;
    by descending Population;
run;
data DateFix;
    set Final_Merged;
    if Date > 930708;
    keep District_id District_Name Type Amount Region Population;
run;
data HighLowPopulated;
    set DateFix;
    if Population > 133884 then Density = 'Highly Populated';
    else if Population < 133884 then Density = 'Low Populated';
   keep District_id District_Name Type Amount Region Population Density;
run;

proc sql;
    create table Low5Debit as
    select District_id, District_Name, Type, sum(Amount) as Total_Amount, Region, Population, Density
    from HighLowPopulated
    where Type='DEBIT'
    group by District_id, District_Name, Type, Region, Population, Density
    having Density = 'Low Populated'  
    order by Population;
quit;
proc sql;
 select distinct *
 from Low5Debit
 where monotonic() <= 5 
 order by Population;
quit;
proc sql;
    create table High5Debit as
    select District_id, District_Name, Type, sum(Amount) as Total_Amount, Region, Population, Density
    from HighLowPopulated
    where Type='DEBIT'
    group by District_id, District_Name, Type, Region, Population, Density
    having Density = 'Highly Populated'  
    order by Population desc;
quit;
proc sql;
 select distinct *
 from High5Debit
 where monotonic() <= 5 
 order by Population desc;
quit;
/**********CERDIT************/
proc sql;
    create table Low5Credit as
    select District_id, District_Name, Type, sum(Amount) as Total_Amount, Region, Population, Density
    from HighLowPopulated
    where Type='CREDIT'
    group by District_id, District_Name, Type, Region, Population, Density
    having Density = 'Low Populated'  
    order by Population;
quit;
proc sql;
 select distinct *
 from Low5Credit
 where monotonic() <= 5 
 order by Population;
quit;
proc sql;
    create table High5Credit as
    select District_id, District_Name, Type, sum(Amount) as Total_Amount, Region, Population, Density
    from HighLowPopulated
    where Type='CREDIT'
    group by District_id, District_Name, Type, Region, Population, Density
    having Density = 'Highly Populated'  
    order by Population desc;
quit;
proc sql;
 select distinct *
 from High5Credit
 where monotonic() <= 5 
 order by Population desc;
quit;

/***********************************************33333********************************************************/
/* Count of cards held by females in the middle-aged category */
proc sql;
create table Midage_Female as
select *
from New_client
inner join New_Disposition
on New_client.client_id=New_Disposition.client_id
inner join New_Card
on New_Card.Disp_id=New_Disposition.Disp_id;
quit;
proc sql;
  select count(*) as CardCount
  from Midage_Female
  where Gender = 'FEMALE' and Age_levels = 'MIDDLE AGED';
quit;

/***********************************************44444********************************************************/
proc sql;
create table Sal3 as
select *
from District
inner join New_Client
on New_client.District_id=District.District_id
inner join New_Disposition
on New_Disposition.Client_id=New_Client.Client_id
inner join New_Card
on New_Card.Disp_id=New_Disposition.Disp_id;
quit;

proc sql;
  select count(*) as Card_9000
  from Sal3
  where AverageSalary > 9000 ;
quit;

/***********************************************55555********************************************************/
proc sql;
create table Loan1 as
select *
from District
inner join New_Account
on District.District_id=New_Account.District_id
inner join Loan
on Loan.Account_id=New_Account.Account_id;
quit;

proc sql;
create table Loan2 as
select  input(CrimeNinefive, 8.) as Crime95 , District_Name ,Amount
from Loan1
Having Crime95 > 6000;
quit;
proc sql;
select count(*) as LoanCount
from Loan2
where Crime95 > 6000;
quit;
proc sql;
create table Loan_per_district as
select  District_Name ,Sum(Amount) as Total_Loan
from Loan2
group by District_Name;
quit;
proc sql;
select *
from Loan_per_district;
quit;
/***********************************************66666********************************************************/
proc sql;
create table BankUnEmp as
select *
from District
inner join New_Account on District.District_id = New_Account.District_id
inner join Order on Order.Account_id = New_Account.Account_id;
quit;
data BankUnEm;
    set BankUnEmp;
    if UnEmpNF > 2 and UnEmpNS > 2 then Alert = 'High_UnEmp_Rate';
    else  Alert = 'Unknown';
    keep District_name District_id Alert UnEmpNS UnEmpNF Bank_to Amount ;
run;

proc sql;
    create table CombinedAmounts as
    select District_Name,
           Bank_to,
           sum(Amount) as Total_Amount  
    from BankUnEm
    where Alert = 'High_UnEmp_Rate'
    group by District_Name, Bank_to
    order by District_Name, Total_Amount desc;
quit;
proc sql;
select distinct District_name, Bank_to , Total_Amount
from CombinedAmounts
group by   Bank_to, Total_Amount, District_name
order by District_name;
quit;

/***********************************************77777********************************************************/

proc sql;
create table Dis_Max as
select k_symbol, District_name,
       sum(Amount) as Total_Pay
from District
left join New_Account on New_Account.District_id = District.District_id
left join Order on Order.Account_id = New_account.Account_id
group by k_symbol, District_name
order by k_symbol, Total_Pay desc;
quit;
proc sql;
select *
from Dis_Max
Where k_symbol = 'UVER'
having monotonic() = 1
order by k_symbol, Total_Pay desc;
quit;
proc sql;
select *
from Dis_Max
Where k_symbol = 'SIPO'
having monotonic() = 1
order by k_symbol, Total_Pay desc;
quit;
proc sql;
select *
from Dis_Max
Where k_symbol = 'POJISTNE'
having monotonic() = 1
order by k_symbol, Total_Pay desc;
quit;
proc sql;
select *
from Dis_Max
Where k_symbol = 'LEASING'
having monotonic() = 1
order by k_symbol, Total_Pay desc;
quit;
/***********************************************88888********************************************************/

proc sql;
    create table Loan2 as
    select District_id ,Account_id, UnEmpNS, UnEmpNF, District_name , Status, AverageSalary 
    from Loan1
   group by Status;
quit;

data Loan2;
  set Loan2;
  if Status = 'A' then Message = 'Paid';
  else if Status = 'B' then Message = 'NotPaid';
  else if Status = 'C' then Message = 'Running';
  else if Status = 'D' then Message = 'Debt';
run;
data Loan2;
  set Loan2;
  if UnEmpNS > 2 or UnEmpNS > 2 then Alert = 'High';
  else if UnEmpNF < 2 or UnEmpNS < 2 then Alert = 'Low';
  else  Alert = 'Unknown';
run;
proc sql;
    select count(*) as Paid
    from Loan2
    where Status = 'A' and Message = 'Paid';
quit;
proc sql;
    select count(*) as NotPaid
    from Loan2
    where Status = 'B' ;
quit;
proc sql;
    select count(*) as Running
    from Loan2
    where Status = 'C' ;
quit;
proc sql;
    select count(*) as Debt
    from Loan2
    where Status = 'D' ;
quit;
/***********************************************99999********************************************************/
data Loan2;
  set Loan2;
  if AverageSalary > 10000 then Alert = 'HSal';
  else if AverageSalary <= 10000  then Alert = 'LSal';
  else  Alert = 'Unknown';
run;
proc sql;
    select count(*) as HighSalary
    from Loan2
    where AverageSalary > 10000 and Status = 'A';
quit;

proc sql;
    select count(*) as LowSalary
    from Loan2
    where AverageSalary <= 10000 and Status = 'A' ;
quit;

/*********************************************** 10 10 10 ***************************************************/
proc sql;
    create table PerOr_Loan as
    select District.District_id, District_Name , k_symbol , Type
    from Order 
    inner join New_Account  on Order.Account_id = New_Account.Account_id
    inner join New_Disposition  on New_Disposition.Account_id = New_Account.Account_id
    inner join District  on District.District_id = New_Account.District_id
    where K_symbol = 'POJISTNE'
    having Type = 'OWNER';
quit;

proc sql;
select distinct District_name, Type, k_symbol
from PerOr_Loan
where K_symbol = 'POJISTNE';
quit;

/*********************************************** 11 11 11 ***************************************************/
proc sql;
    create table BohemiaVsMoravia as
    select District.Region, New_Client.Gender, District.District_name, New_Card.Type
    from New_Client 
    inner join District on New_Client.District_id = District.District_id
    inner join New_Disposition on New_Client.Client_id = New_Disposition.Client_id
    inner join New_Card on New_Card.Disp_id = New_Disposition.Disp_id
    where District.Region in ('central Bohemia', 'east Bohemia', 'west Bohemia',
    'south Bohemia', 'north Bohemia','south Moravia', 'north Moravia');
quit;

proc sql;
select count(*) as MoraviaGoldCard
from BohemiaVsMoravia
where Gender = 'MALE' and Type = 'GOLD' and Region in ('south Moravia' ,'north Moravia');
quit;
 
proc sql;
select count(*) as BohemiaGoldCard
from BohemiaVsMoravia
where Gender = 'MALE' and Type = 'GOLD' and Region in ('central Bohemia', 'east Bohemia', 'west Bohemia',
    'south Bohemia', 'north Bohemia');
quit; 
/*********************************************** 13 13 13 ***************************************************/

proc sql;
create table Card_Debt as
select *
from New_Card
inner join New_Disposition on New_Disposition.Disp_id = New_Card.Disp_id
inner join Loan on Loan.Account_id = New_Disposition.Account_id;
quit;

proc sql;
select count(*) as CardandDebt
from Card_Debt
where Type in ('JUNIOR' , 'CLASSIC') and Status = 'D';
quit; 
/***********************************************14 14 14  ***************************************************/
proc sql;
    create table MidagvsAdu as
    select Age_levels, Status
    from New_Client 
    inner join New_Disposition d on New_Disposition.Client_id = New_Client.Client_id
    inner join Loan on New_Disposition.Account_id = Loan.Account_id
    where Age_levels in ('ADULT', 'MIDDLE AGED')
    group by Age_levels;
quit;

proc sql;
    select count(*) as PaidMidAge
    from MidagvsAdu
    where Age_levels = "MIDDLE AGED" and Status = 'A';
quit;
proc sql;
    select count(*) as PaidMidAdult
    from MidagvsAdu
    where Age_levels = "ADULT" and Status = 'A';
quit;
proc sql;
    select count(*) as DebtMidAge
    from MidagvsAdu
    where Age_levels = "MIDDLE AGED" and Status = 'D';
quit;
proc sql;
    select count(*) as DebtMidAdult
    from MidagvsAdu
    where Age_levels = "ADULT" and Status = 'D';
quit;
