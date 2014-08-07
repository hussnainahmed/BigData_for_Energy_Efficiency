energy_file <- file.choose()
preprocess <- function (fileloc = energy_file){
        
        main_table <- read.csv(fileloc, header=TRUE, sep=",")
        #colnames(main_table) <- c("dev_id","building","meter","type","date","hour","consumption")
        main_table$date <- as.POSIXct(as.character(main_table$date),format="%Y%m%d")
        main_table["month"] <- NA
        main_table$month <- months(main_table$date, abbreviate = TRUE)
        main_table <- main_table[main_table!="Dec",]
        require(sqldf)
       
        main_elect = sqldf("SELECT BuildingID AS did, vac AS building,type,date,hour,Consumption AS consumption, month FROM main_table WHERE type='elect' ")
        main_heating = sqldf("SELECT BuildingID AS did, vac AS building,type,date,hour,Consumption AS consumption, month FROM main_table WHERE type='Dist_Heating' ")
        main_water = sqldf("SELECT BuildingID AS did, vac AS building,type,date,hour,Consumption AS consumption, month FROM main_table WHERE type='Water' ")
        main_rp = sqldf("SELECT BuildingID AS did, vac AS building,type,date,hour,Consumption AS consumption, month FROM main_table WHERE type='React_Power' ")
        
        print("calculating averages")
        # daily avaerages 
        avg_daily_elec<- sqldf("SELECT building, date, month, AVG(consumption) AS avg_hourly_consumption FROM main_elect GROUP by building,date ORDER BY building DESC")
        avg_monthly_elec<- sqldf("SELECT building, month, AVG(avg_hourly_consumption) AS avg_consumption FROM avg_daily_elec GROUP by building,month ORDER BY building DESC")
        
        avg_daily_heating <- sqldf("SELECT building, date, month, AVG(consumption) AS avg_hourly_consumption FROM main_heating GROUP by building,date ORDER BY building DESC")
        avg_monthly_heating <- sqldf("SELECT building, month, AVG(avg_hourly_consumption) AS avg_consumption FROM avg_daily_heating GROUP by building,month ORDER BY building DESC")
        
        print("Formulating Final Matrix")
        main_matrix <- sqldf("SELECT avg_monthly_elec.building, avg_monthly_elec.month, avg_monthly_elec.avg_consumption AS elec_consumption, avg_monthly_heating.avg_consumption AS heating_consumption  FROM  avg_monthly_elec INNER JOIN avg_monthly_heating  ON avg_monthly_elec.building = avg_monthly_heating.building AND avg_monthly_elec.month=avg_monthly_heating.month")
        main_matrix <- main_matrix[with(main_matrix, order(main_matrix$building,main_matrix$month,decreasing = TRUE)), ]
        
        main_matrix
       
        
        #months
        
}
add_area <- function (address_file = "C:/IDBM/Sentiment Analysis/CIVIS/Data/vtt/hld_addresses_area.csv",data= energy_matrix){
        address <- read.csv(address_file,header=TRUE, sep=",")
        address <- address[complete.cases(address[,3]),]
        colnames(address) <-c("building","address","area")
        merged <- merge(data,address,all=FALSE)
        merged$elec_Wh_per_m2 <- (merged$elec_consumption/merged$area)*1000
        merged$heating_Wh_per_m2 <- (merged$heating_consumption/merged$area)*1000
        energy_area_matrix <- merged[,c(1,5,2,6,7,8)]
        energy_area_matrix
}

energy_matrix <- preprocess()
energy <- add_area()
energy.features = energy
energy.features[1:4] <- list(NULL)
input = scale(energy.features, center=TRUE, scale=TRUE)
results = kmeans(input,4)
building <- c(energy$building)
month <- c(energy$month)
area <- c(round(as.numeric(energy$floor_area),1))
elec_Wh_per_m2 <- c(round(as.numeric(energy$elec_Wh_per_m2),1))
heating_Wh_per_m2 <- c(round(as.numeric(energy$heating_Wh_per_m2),1))
cluster <- c(results$cluster)
main_matrix_k4 <- data.frame(building,month,elec_Wh_per_m2,heating_Wh_per_m2,cluster)
path <- getwd() 
appendage <- ".txt" 
t_string <- format(Sys.time(), format = "%Y-%j-%H%M%S") 
energy_file <- file.path(path, paste0("/","energy_classes",t_string, appendage,sep="")) 
write.table(main_matrix_k4, file = energy_file,row.names=FALSE)




        