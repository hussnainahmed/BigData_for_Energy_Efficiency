/******************************************
*******************************************
******Apache Pig Script for****************
*******************************************
*******************************************/ 
 /usr/lib/pig/piggybank.jar;
REGISTER /home/cloudera/joda-time-2.4/joda-time-2.4.jar;
DEFINE CustomFormatToISO org.apache.pig.piggybank.evaluation.datetime.convert.CustomFormatToISO();
DEFINE ISOToUnix org.apache.pig.piggybank.evaluation.datetime.convert.ISOToUnix();
rmf energy_consumption_matrix;
energy = LOAD 'small/hld_masked.csv' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',') AS (dev:int, building:chararray, meternumb:int ,type:chararray, date:chararray,hr:int,consumption:int);
NARM = FILTER energy BY (building matches 'Building.*');
elect = FILTER NARM BY type == 'elect';
heat = FILTER NARM BY type == 'Dist_Heating';
elec_group  = GROUP elect BY (building,date);
avg_daily_elec = FOREACH elec_group GENERATE group, AVG(elect.consumption) AS avg_hourly_consumption;
avg_daily_elec_months = FOREACH avg_daily_elec GENERATE group.building,avg_hourly_consumption, GetMonth(ToDate(group.date,'yyyyMMdd')) AS month;
avg_monthly_elec_group = GROUP avg_daily_elec_months BY (building,month); 
avg_monthly_elec = FOREACH avg_monthly_elec_group  GENERATE group.building,group.month, AVG(avg_daily_elec_months.avg_hourly_consumption) AS avg_monthly_consumption;
monthly_elec = FILTER avg_monthly_elec BY month!=12;
heat_group  = GROUP heat BY (building,date);
avg_daily_heat = FOREACH heat_group GENERATE group, AVG(heat.consumption) AS avg_hourly_consumption;
avg_daily_heat_months = FOREACH avg_daily_heat GENERATE group.building,avg_hourly_consumption, GetMonth(ToDate(group.date,'yyyyMMdd')) AS month;
avg_monthly_heat_group = GROUP avg_daily_heat_months BY (building,month); 
avg_monthly_heat = FOREACH avg_monthly_heat_group  GENERATE group.building,group.month, AVG(avg_daily_heat_months.avg_hourly_consumption) AS avg_monthly_consumption;
monthly_heat = FILTER avg_monthly_heat BY month!=12;
main_matrix = JOIN monthly_elec BY (building,month), monthly_heat BY (building,month);
energy_comsumption_matrix = FOREACH main_matrix GENERATE $0 as building, $1 as month, $2 as elect_consumption, $5 as heat_consumption;
STORE energy_comsumption_matrix INTO 'energy_consumption_matrix' USING PigStorage(',');
