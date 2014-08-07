
add_area <- function (address_file = "C:/IDBM/Sentiment Analysis/CIVIS/Data/vtt/hld_addresses_area.csv",data= energy_matrix){
        address <- read.csv(address_file,header=TRUE, sep=",")
        address <- address[complete.cases(address[,3]),]
        colnames(address) <-c("building","address","area")
        merged <- merge(data,address,all=FALSE)
        merged$elec_Wh_per_m2 <- (merged$elec_consumption/merged$area)*1000
        merged$heat_Wh_per_m2 <- (merged$heat_consumption/merged$area)*1000
        energy_area_matrix <- merged[,c(1,5,2,6,7,8)]
        energy_area_matrix
}
fileloc <- file.choose()
data <- read.table(fileloc,header=FALSE,sep=",")
colnames(data) <- c("building","month","elec_consumption","heat_consumption")
energy_matrix <- data[data$elec_consumption > 0 & data$heat_consumption > 0,]
#energy_matrix <- preprocess()
energy <- add_area()
energy.features = energy
energy.features[1:4] <- list(NULL)
input = scale(energy.features, center=TRUE, scale=TRUE)
results = kmeans(input,4)
building <- c(energy$building)
month <- c(energy$month)
area <- c(round(as.numeric(energy$floor_area),1))
elec_Wh_per_m2 <- c(round(as.numeric(energy$elec_Wh_per_m2),1))
heat_Wh_per_m2 <- c(round(as.numeric(energy$heat_Wh_per_m2),1))
cluster <- c(results$cluster)
main_matrix_k4 <- data.frame(building,month,elec_Wh_per_m2,heat_Wh_per_m2,cluster)
path <- getwd() 
appendage <- ".txt" 
t_string <- format(Sys.time(), format = "%Y-%j-%H%M%S") 
energy_file <- file.path(path, paste0("/","energy_classes",t_string, appendage,sep="")) 
write.table(main_matrix_k4, file = energy_file,row.names=FALSE)




        