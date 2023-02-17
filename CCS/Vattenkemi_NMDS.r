rm(list =ls())

setwd("C:/Calluna/Projekt/CementaSlite/Hydrografi")

dfSt=read.csv("VattenkemiStationerDistance.csv")
dfCh=read.csv("CementaProvplaneradeVattenprover_202302.csv")

names(dfCh) = gsub("\\.+","_",names(dfCh))
names(dfCh) = gsub("_$","",names(dfCh))

dfCh$Provpunkt=gsub("^.+_","",dfCh$Provpunkt)
dfCh$Provpunkt=gsub(",.+$","",dfCh$Provpunkt)
names(dfSt) = gsub("\\.+","_",names(dfSt)) 
names(dfSt) = gsub("_$","",names(dfSt)) 

dfSw = dfSt[,c(2,5:10)]
names(dfSw)[1] = "Provpunkt"

mrgDf=merge(dfSw, dfCh, by = "Provpunkt")

dfSw$Provpunkt[unique(dfSw$Provpunkt) %in% unique(dfCh$Provpunkt)]
dfSw$Provpunkt[!(unique(dfSw$Provpunkt) %in% unique(dfCh$Provpunkt))] # Samples not in water chem data

mrgDf[mrgDf == "ND"] <- NA
mrgDf[mrgDf == ""] <-NA

rmvDf=mrgDf[,colSums(is.na(mrgDf)) == 129]#Change
mrgDf=mrgDf[,colSums(is.na(mrgDf)) != 129]#Change

mrgDf=as.data.frame(apply(mrgDf,2,function(x) gsub("(>|<)","", x)))
mrgDf=as.data.frame(apply(mrgDf,2,function(x) gsub(",","\\.", x)))

mrgDf[,12:dim(mrgDf)[2]]=as.data.frame(sapply(mrgDf[,12:dim(mrgDf)[2]], function(x) as.numeric(x)))

aFrame = as.data.frame(matrix(nrow = length(unique(mrgDf$Provpunkt)), ncol = 0))
aFrame$Station = unique(mrgDf$Provpunkt)

for(aCol in names(mrgDf)[12:dim(mrgDf)[2]]){
  aVec=tapply(mrgDf[,aCol], mrgDf$Provpunkt, function(x) mean(x, na.rm=TRUE))
  aCec=aVec/mean(mrgDf[,aCol], na.rm = TRUE)
  tmpDf=as.data.frame(do.call(cbind,list(aCec)))
  aCond=sum(!(is.na(tmpDf$V1))) #Checks if all stations got a numeric value 
  bCond=sum(row.names(tmpDf) == aFrame$Station) # Checks that stations order are identical 
  if(aCond == length(aFrame$Station) & bCond == length(aFrame$Station)){
    print(tmpDf)
    #Sys.sleep(0.5)
    names(tmpDf) = aCol
    aFrame=cbind(aFrame, tmpDf)
  }
}

lowVar=as.data.frame(apply(aFrame[,2:dim(aFrame)[2]], 2, function(x) max(x)/min(x)) < 1.1)
highVar=as.data.frame(apply(aFrame[,2:dim(aFrame)[2]], 2, function(x) max(x)/min(x)) > 1.5)

names(highVar)[1] = "highVarBool"
names(lowVar)[1] = "lowVarBool"


{
  sink("lowVarParameter.txt")
  lowVarParameter=row.names(lowVar)[lowVar$lowVarBool]
  print(lowVarParameter)
  sink()
}

{
  sink("highVarParameter.txt")
  highVarParameter=row.names(highVar)[highVar$highVarBool]
  print(highVarParameter)
  sink()
}

{
  sink("noDetectionParameter.txt")
  nonDtcParameter=names(rmvDf)[4:dim(rmvDf)[2]]
  print(nonDtcParameter)
  sink()
}  

library(vegan)
library(viridis)

NMDS_Data=aFrame[,c("Station", highVarParameter)]
names(NMDS_Data)[1] = "Provpunkt"

env=dfSt[,c("Stationsnamn","Transect","distance","Vattendjup_vid_stationen_m")]
row.names(env) = env$Stationsnamn

NMDS_Data=as.data.frame(t(NMDS_Data[,-1]))
NMDS_Data=NMDS_Data[,!(grepl("(N|K)",names(NMDS_Data)))]

NMDS_HighVar=metaMDS(NMDS_Data,distance = "bray",K=2, trymax=10000)

HighScore = scores(NMDS_HighVar)
HighScore = as.data.frame(HighScore$species)

mrgHigh=merge(HighScore, env, by = 'row.names')

hgg = ggplot(data=mrgHigh, aes(x=NMDS1, y=NMDS2, color = Transect, label=Stationsnamn))+geom_point(size = 3)
hgg = hgg + geom_text(hjust = 1.75, vjust = -1.0, size = 2)
hgg = hgg + theme_bw()+labs(title = "NMDS: Water chemistry HighVar parameters")
hgg = hgg + scale_color_viridis(discrete = TRUE)
