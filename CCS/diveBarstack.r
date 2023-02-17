rm(list = ls())

library(openxlsx)
library(reshape2)
library(ggplot2)
library(viridis)
library(RColorBrewer)

setwd("C:/Calluna/Projekt/CementaSlite/Script/DivingGraphs")

df=read.csv("sub_transekt_utf.csv")

names(df)=gsub("Taxon(tä.+|_tä.+)_","TaxaCoverage_",names(df), ignore.case = TRUE)  
names(df)=gsub("Substrat(tä.+|_tä.+)_","SubstrateCoverage_",names(df), ignore.case = TRUE)    

names(df)=gsub("Substrat_täckningsgrad", "SubstrateCoverage_1", names(df), ignore.case = TRUE)
names(df)=gsub("Taxon_täckningsgrad", "TaxaCoverage_1", names(df), ignore.case = TRUE)

names(df)=gsub("^Taxon$", "Taxon_1", names(df), ignore.case = TRUE)
names(df)=gsub("^Substrat$", "Substrat_1", names(df), ignore.case = TRUE)

bigTax=data.frame(matrix(nrow = 0, ncol = 4))
names(bigTax) = c("avsnittID", "transektID","taxa","taxaCoverage")

#Stack the data into long format
for(val in 1:10){
  taxaCov = paste0("TaxaCoverage_",val)
  taxOn = paste0("Taxon_",val)
  tempDf=df[,c("avsnitt_ID","TransektID",taxOn,taxaCov)]
  names(tempDf) = c("avsnittID", "transektID","taxa","taxaCoverage")
  bigTax=rbind(bigTax, tempDf)
}
rm(tempDf)

bigTax=na.omit(bigTax)

sort(table(bigTax$taxa)) # check and for misspellings and potentially fix by adding substitutions below  
bigTax$taxa=(gsub("Myti.+", "Mytilus edulis", bigTax$taxa))
bigTax$taxa=gsub("Amphibalanus.+", "Amphibalanus improvisus", bigTax$taxa)

#Hexa color list              
colList= c("#234d20","#36802d", "#77ab59", "#c9df8a", "#f0f7da","#eeaf61", "#fb9062", 
                    "#ee5d6c","#ce4993", "#6a0d83","#daf8e3", "#97ebdb","#00c2c7",
                    "#0086ad","#005582", "#343d46","#4f5b66","#65737e", "#a7adba", "#baeb34")

#Twenty most abundant species in diving data, use ~ sort(table(df$taxa)) to update/change list
taxList=c("Chara aspera","Spirulina","Cladophora rupestris","Aglaothamnion roseum", 
         "Chaetomorpha linum","Ulva","Zannichellia palustris","Ephydatia fluviatilis","Ruppia","Cladophora glomerata",
         "Coccotylus/Phyllophora","Stuckenia pectinata","Zostera marina","Fucus vesiculosus","Ectocarpus/Pylaiella", 
         "Amphibalanus improvisus","Polysiphonia fucoides", "Ceramium tenuicorne", "Furcellaria lumbricalis", "Mytilus edulis")  

#Creates a color/species matching dataframe 
colDf=data.frame(taxa =  sort(taxList),
                 color = colList)

#loop to create subset data for each transect, select color and export is stackbar charts as pdf.   
for(tranID in unique(bigTax$transektID)){
  subTax=bigTax[grepl(tranID,bigTax$transektID),] # Select the transect to include
  #This one is a bit complicated, but it converts the found taxa into a joint search string 
  #which then is used to subset the diving dataset and select the matching colors.
  subTax=subTax[grepl(paste0("^",taxList,"$", collapse = "|"), subTax$taxa),]
  subColor=colDf$color[grep(paste0("^",unique(subTax$taxa),"$", collapse = "|"), colDf$taxa)]
  subTax[,1:3]=lapply(subTax[,1:3], as.factor)
  
  fileNm = paste0("Dyktransekt_",tranID,".pdf")
  
  stGG1=ggplot(data=subTax,aes(x=subTax$avsnittID,y=subTax$taxaCoverage, fill = subTax$taxa))
  stGG1=stGG1 + geom_bar(stat="identity", colour = "black", size=0.05)
  stGG1=stGG1 + facet_wrap(~subTax$transektID, scale = "free")
  stGG1=stGG1 + theme_bw(18) + labs(x="Dive squares", y="Coverage")
  stGG1=stGG1 + theme(axis.text.x = element_blank(), legend.title = element_blank(),
                      axis.text.y = element_text(size = 14), 
                      legend.text = element_text(size = 12),legend.position = "bottom")
  stGG1=stGG1 + scale_fill_manual(values = subColor)
  if(length(unique(subTax$taxa))>12){
    stGG1=stGG1 + guides(fill=guide_legend(nrow=4,byrow=TRUE))
  }
  ggsave(filename = fileNm, plot=stGG1, device = cairo_pdf, width = 10, height = 14, units = "in")
}
