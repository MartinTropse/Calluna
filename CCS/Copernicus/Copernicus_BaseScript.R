library(raster)
library(ncdf4)
library(ncdf4.helpers)
library(ggplot2)
library(lubridate)
library(stats)
library(reshape2)

"""
Script containg examples of different calculations, subset and export of Copernicus marine data
based on models from SMHI and others. 

All data are from the marine 

"""

#Example of raster extraction from copernicus ncdf4 satellit data 
setwd("C:/Calluna/Projekt/CementaSlite/RemoteSensing/Copernicus_BaltFys/Hourly_BGC_003_007/Raw_202111_202211")


nc_data=ncdf4::nc_open("CMEMS-BALTICSEA_003_006-bottomT_mlotst_so_sob_thetao-2019.nc")

#Extract meta data as a text-file 
{
  sink("nc_phy2019_hour.txt")
  print(nc_data)
  sink()
}

theDepth=ncvar_get(nc_data, "depth")
theLat=ncvar_get(nc_data, "lat")
theLon=ncvar_get(nc_data, "lon")
theTime=ncvar_get(nc_data, "time")
length(theLat)
length(theLon)

ymax = max(theLat)
ymin = min(theLat)
xmax = max(theLon)
xmin = min(theLon)

myExt = extent(c(xmin, xmax, ymin, ymax))

paraMtr = "bottomT" # Parameter of interest
data_array=ncvar_get(nc_data, paraMtr) # Extract parameter from ncdf4 data

#Convert time dimensions to date format 
dateValues=ncdf4.helpers::nc.get.time.series(nc_data, time.dim.name= "time",correct.for.gregorian.julian = FALSE) #

#Set raster dimensions and extract as geotif
myRast=raster::raster(t(data_array[18,11,]), crs=CRS("+proj=longlat +datum=WGS84 +no_defs"))
myRast=flip(myRast, direction = "y")
extent(myRast) = myExt
plot(myRast)

#writeRaster(myRast, "harborTest", "GTiff")


"""
Overview of seechi depth, based on SMHI Copernicus models for hourly & daily data
"""

###Hourly data 2022-03|2022-06### 
setwd("C:/Calluna/Projekt/CementaSlite/RemoteSensing/Copernicus_BaltFys/Hourly_BGC_003_007")
list.files()

nc_data=ncdf4::nc_open("dataset-bal-analysis-forecast-bio-hourly_1658318540933.nc")

#Creates a text file using the file meta data, including parameters and their abbreviations, 
#The time and spatial dimensions of the data etc. 
{
  sink("nc_phy2019_hourNew.txt")
  print(nc_data)
  sink()
}

theDepth=ncvar_get(nc_data, "depth")
theLat=ncvar_get(nc_data, "lat")
theLon=ncvar_get(nc_data, "lon")
theTime=ncvar_get(nc_data, "time")
length(theLat)
length(theLon)

print(paste("The start date:",as.Date(min(theTime), origin = "1900-01-01")))
print(paste("The end date:",as.Date(max(theTime), origin = "1900-01-01")))
#enDf$Date=lubridate::as_datetime(enDf$Date, tz = "CET")

ymax = max(theLat)
ymin = min(theLat)
xmax = max(theLon)
xmin = min(theLon)

myExt = extent(c(xmin, xmax, ymin, ymax))

paraMtr = "zsd" #Parameter of interest
data_array=ncvar_get(nc_data, paraMtr) #Extract parameter of interest from dataset

dateValues=ncdf4.helpers::nc.get.time.series(nc_data, time.dim.name= "time",correct.for.gregorian.julian = FALSE) #
dataSlice=data_array[,,1]

dateList = vector()
schList = vector()
schLmean = vector()
schList[1] = 0


#Storing maximum mean values, iterating through each hour of the dataset(I think!)
for(aHour in seq(length(dateValues))){
  schMean=mean(data_array[,,aHour], na.rm = TRUE)
  schLmean= append(schLmean,schMean) 
  if(schMean > max(schList)){
    schList=append(schList, schMean)
    dateList=append(dateList, aHour)
  }
}

qSch=quantile(schLmean, probs = seq(0,1,0.05))
schData=as.data.frame(schLmean)
schData$numVal = seq(dim(schData)[1])
schData=schData[which(schData$schLmean >= qSch[20]),]

dateValues[schData$numVal]
data_array[,,schData$numVal]

###Daily data between 2022-12-25|2020-10-02
setwd("C:/Calluna/Projekt/CementaSlite/RemoteSensing/Copernicus_BaltFys/Dailty_BGC_202212")
ncday_data=ncdf4::nc_open("cmems_mod_bal_bgc_anfc_P1D-m_1671547866902.nc")

"C:/Calluna/Projekt/CementaSlite/RemoteSensing/Copernicus_BaltFys/Dailty_BGC_202212/cmems_mod_bal_bgc_anfc_P1D-m_1671547866902.nc"

theDepth=ncvar_get(ncday_data, "depth")
theLat=ncvar_get(ncday_data, "lat")
theLon=ncvar_get(ncday_data, "lon")
theTime=ncvar_get(ncday_data, "time")

ymax = max(theLat)
ymin = min(theLat)
xmax = max(theLon)
xmin = min(theLon)

myExt = extent(c(xmin, xmax, ymin, ymax))

paraMtr = "zsd"
data_array=ncvar_get(ncday_data, paraMtr)

dateValues=ncdf4.helpers::nc.get.time.series(ncday_data, time.dim.name= "time",correct.for.gregorian.julian = FALSE) #
data_array[is.na(data_array)] = 0 

dateList = vector()
schList = vector()
schList[1] = 0
schLmean = vector()

#Find days with maximum sechidepth 
for(aDay in seq(length(dateValues))){
  schMean = mean(data_array[,,aDay])
  schLmean = append(schLmean,schMean) 
  if(schMean > max(schList)){
    schList=append(schList, schMean)
    dateList=append(dateList, aDay)
  }
}

qSch=quantile(schLmean, probs = seq(0,1,0.05))
schData=as.data.frame(schLmean)
schData$numVal = seq(dim(schData)[1])
schData=schData[which(schData$schLmean >= qSch[20]),]

dateValues[schData$numVal]
#max(schData$schLmean)
schData[which(schData$numVal == 107),]
which(data_array[,,107] > 0)

topDate = vector()
topMean = vector()

for(numDate in schData$numVal){
  meltSlice=melt(data_array[,,numDate])
  meltSlice=meltSlice[which(meltSlice$value>0),]
  topMean=append(topMean, mean(meltSlice$value))
  topDate=append(topDate,dateValues[numDate])
}

dateValues[107]
meltSlice=melt(data_array[,,107])
meltSlice=meltSlice[which(meltSlice$value>0),]
mean(meltSlice$value) 

myRast=raster::raster(t(data_array[,,107]), crs=CRS("+proj=longlat +datum=WGS84 +no_defs"))
myRast=flip(myRast, direction = "y")
extent(myRast) = myExt
plot(myRast)
writeRaster(myRast, "TestSechiRaster.tif", "GTiff")

"""
- #11.6429 for highest sechi-depth day 2021-01-16 : 12:00 
- Strong sechi dates 2020-12 22-25, 29-31. 2021-01 01-02, 07-26.
- Sechi Depth Range 11.38787 - 11.6951
- The SMHI model however overestimate sechiDepth, thus we reduce it to 11.  
- SDB can generally be done between 1-1.2 sechidepth, i.e. 11 - 13.2 meters
- Feasibility layer could be divided into 10, 11, 12, 13 meters of depth
"""

dfSchi=as.data.frame(matrix(nrow = 41, ncol = 2))
dfSchi$V1 = topDate
dfSchi$V2 = topMean

names(dfSchi) = c("Date", "SechiDepth_Mean")
write.csv(dfSchi, "SechiDepth_202012_Slite.csv", row.names = FALSE)

S
"""
#Loops for subsetting, calculating and exporting data. Including calculating values 
#for bottom depths across hetergenous depth, quantile, min, mean and max raster values.
"""
library(ncdf4) # package for netcdf manipulation
library(raster) # package for raster manipulation
library(rgdal) # package for geospatial analysis
library(ggplot2) # package for plotting

setwd("C:/Calluna/Projekt/CementaSlite/RemoteSensing/Copernicus_BaltFys/Monthly_BGC_003_007")
rm(list=ls())

#nc_dataDay=nc_open("dataset-bal-analysis-forecast-phy-dailymeans_1657797649987.nc") #Copernicus dataset: BALTICSEA_REANALYSIS_PHY_003_06  
nc_dataMth=nc_open("dataset-bal-analysis-forecast-bio-monthlymeans_1658132139997.nc") #Copernicus dataset  

{
  sink("BGC_003_007.txt")
  print(nc_dataMth)
  sink()
}

theParm = "nh4"
data_array = ncvar_get(nc_dataMth, theParm)

lonMt = ncvar_get(nc_dataMth, "lon")
latMt = ncvar_get(nc_dataMth, "lat")
myMtTime = ncvar_get(nc_dataMth, "time")
myMtDepth = ncvar_get(nc_dataMth, "depth")

ymx = max(latMt)
ymn = min(latMt)
xmn = min(lonMt)
xmx = max(lonMt)

mntExt = extent(c(xmn, xmx, ymn, ymx))

mapSeq=seq(from=1, to=length(myMtTime), by=1)
depthMx = matrix(nrow = dim(data_array)[1], ncol=dim(data_array)[2])

#Finds the maximum depth in NTCDF4 that has a measured value for each coordinate. The value returned is the "depth category", not an actual depth,
for(y in seq(1,length(latMt),1)){
  #print(y)
  for(x in seq(1,length(lonMt),1)){
    logicGate = TRUE
    #print(x)
    for(dpt in seq(1, length(myMtDepth), 1)){
      dptVal=data_array[x,y,dpt,1]
      if(dpt == 1 & is.na(data_array[x,y,dpt,1])){
        print(paste(x,y,"Coordinate is NA"))
        break
      }
      if(is.na(dptVal) & logicGate == TRUE & dpt > 1){
        depthMx[x,y] = dpt-1
        logicGate = FALSE
      }
    }  
  }
}

#Creates geotiffs for each time slice of the NC data.
for(aTime in mapSeq) {
  timeMap=siconc_array[,,aTime]
  print(timeMap)
  Rst=raster(t(timeMap), crs=CRS("+proj=longlat +datum=WGS84 +no_defs"))
  Rst=flip(Rst, direction = "y")
  extent(Rst) = mntExt
  myName = paste0("iceCover", aTime,".tif")
  writeRaster(Rst, myName, "GTiff", overwrite=TRUE)
}

myMax=matrix(nrow = length(latMt), ncol=length(lonMt))
myMin=matrix(nrow = length(latMt), ncol=length(lonMt))
myMean=matrix(nrow = length(latMt), ncol=length(lonMt))

#Calculate highest 10% percentile, for 3D array.
for(y in seq(1,length(latMt),1)){
  for(x in seq(1,length(lonMt),1)){
    myQuant=quantile(data_array[x,y,], probs=seq(0,1,by=0.1),na.rm=TRUE)
    myMax[y,x]=myQuant[10] # 10% highest percentile
  }
}

#Calculate lowest 10% percentile, for 3D array.  
for(y in seq(1,length(latMt),1)){
  for(x in seq(1,length(lonMt),1)){
    myQuant=quantile(data_array[x,y,], probs=seq(0,1,by=0.1),na.rm=TRUE)
    myMin[y,x]=myQuant[1] # 10% lowest percentile
  }
}

#Calculate highest 10% percentile, for 4D array with varying depth
for(y in seq(1,length(latMt),1)){
  for(x in seq(1,length(lonMt),1)){
    print(paste("Checking coordinate",x,y))
    if(is.na(depthMx[x,y])){
      print("Skipping out, again!")
    }
    else {
      myQuant=quantile(data_array[x,y,1:depthMx[x,y],], probs=seq(0,1,by=0.1),na.rm=TRUE)
      print("Finally getting some work done!")
      print(paste("The current depth category:",depthMx[x,y]))
      print(myQuant[11])
      myMax[y,x]=myQuant[11] # 10% highest percentile
      Sys.sleep(0.1)
    }
  }
}

maxRst=raster(myMax, crs=CRS("+proj=longlat +datum=WGS84 +no_defs"))
maxRst=flip(maxRst, direction="y")
extent(maxRst) = mntExt
writeRaster(maxRst, paste0(theParm,"_Max10Quant.tif"),"GTiff", overwrite = TRUE)

#Calculate lowest 10% percentile, for 4D array with varying depth
for(y in seq(1,length(latMt),1)){
  for(x in seq(1,length(lonMt),1)){
    print(paste("Checking coordinate",x,y))
    if(is.na(depthMx[x,y])){
      print("Skipping out,again!")
    }
    else {
      myQuant=quantile(data_array[x,y,1:depthMx[x,y],], probs=seq(0,1,by=0.1),na.rm=TRUE)
      print("Finally getting some work done!")
      print(paste("The current depth category:",depthMx[x,y]))
      print(myQuant[1])
      myMin[y,x]=myQuant[1] # 10% lowest percentile
      Sys.sleep(0.1)
    }
  }
}

minRst=raster(myMin, crs=CRS("+proj=longlat +datum=WGS84 +no_defs"))
minRst=flip(minRst, direction="y")
extent(minRst) = mntExt

writeRaster(minRst, paste0(theParm,"_Min10Quant.tif"),"GTiff", overwrite = TRUE)

#Calculate mean array, for 4D array with varying depth
for(y in seq(1,length(latMt),1)){
  for(x in seq(1,length(lonMt),1)){
    print(paste("Checking coordinate",x,y))
    if(is.na(depthMx[x,y])){
      print("Skipping out, again!")
    }
    else {
      aMean=mean(data_array[x,y,1:depthMx[x,y],])
      print("Finally getting some work done!")
      print(paste("The current depth category:",depthMx[x,y]))
      myMean[y,x]=aMean # Mean value for each time 
      Sys.sleep(0.1)
    }
  }
}

meanRst=raster(myMean, crs=CRS("+proj=longlat +datum=WGS84 +no_defs"))
meanRst=flip(meanRst, direction="y")
extent(meanRst) = mntExt

writeRaster(meanRst, paste0(theParm,"_Mean.tif"),"GTiff", overwrite = TRUE)


###Get the max and min percentile per square over the timeperiod###
dimOut=dim(btmTStack)

latSeq=seq(from=1, to=dimOut[1], by=1)
lonSeq=seq(from=1, to=dimOut[2], by=1)

myMax=matrix(nrow = dimOut[1], ncol=dimOut[2])
myMin=matrix(nrow = dimOut[1], ncol=dimOut[2])

#Goes through all array index, for every position a quantile of all time periods are created, 
#the 10% percentile value is then added to a new matrix at the same index
for(y in latSeq){
  for(x in lonSeq){
    myQuant=quantile(btmTStack[y,x,], probs=seq(0,1,by=0.1),na.rm=TRUE)
    myMax[y,x]=myQuant[10] # 10% highest percentile
  }
}

for(y in latSeq){
  for(x in lonSeq){
    myQuant=quantile(so_slice1999[y,x,], probs=seq(0,1,by=0.1),na.rm=TRUE)
    myMin[y,x]=myQuant[2] # 10% lowest percentile
  }
}