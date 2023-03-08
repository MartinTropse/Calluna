# -*- coding: utf-8 -*-
"""
Created on Sun Feb  5 13:39:52 2023
@author: MartinAndersson
"""

import tabula.io as ti
import pandas as pd
import re
import os

pd.options.mode.chained_assignment = None  # default='warn'
##This frontpage functions works on none suspenderade reports 


#Use two apply functions to identify the true position in row and column index      
def frontPage(myFrontpage):
    df = myFrontpage
    colID=df.filter(regex=("Provnummer.*")).columns.to_list()
    startRow=df.loc[(df[colID[0]] == 'Analys')|(df[colID[0]] == 'Analys ')].index.to_numpy()
    dfCh=df.iloc[startRow[0]+1:df.shape[0],:]
    dfSt=df.iloc[0:startRow[0]-1:,:]
    dfSt = dfSt.astype("str")
    dateMask=dfSt.apply(lambda x: x.str.contains("^[0-9]{4}-[0-9]{2}-[0-9]{2}", regex = True), axis = 1)    
    dateDf=dfSt.loc[dateMask.apply(lambda x:any(x), axis = 1),dateMask.apply(lambda x:any(x))] #Use two apply functions to identify the true position in row and column index
    if(sum(dateDf.shape) == 0):
       print("Found alternative date") 
       dateMaskAlt=dfSt.apply(lambda x: x.str.contains("(?i)(?<=prov).+?\d{4}-\d{2}-\d{2}$", regex = True), axis = 1)
       dateDfAlt=dfSt.loc[dateMaskAlt.apply(lambda x:any(x), axis = 1),dateMaskAlt.apply(lambda x:any(x), axis = 0)]
       dateVal=re.search('\d{4}-\d{2}-\d{2}', str(dateDfAlt.iloc[0,0])).group(0)
    else:
        dateVal = dateDf.iloc[0,0]
    mtchPrv=re.search("(?<=Provnummer: ).*",df.columns.to_list()[0])
    dfCh.rename(columns={dfCh.columns[0]: "Analys"}, inplace=True)
    if(sum(dfCh.columns == "Ankomsttemp °C Kem") == 0): #If|else that seperate two versions of the front page and changes them into one uniformed format.  
        digPatn = '^((<|>)\d+\.\d+$|^\d+\.\d$|^\d+$|^\d+\,\d$)'    
        untPatn = '\w+\/l'
        for colPos, colVal in zip(range(0,len(dfCh.columns)),dfCh.columns): 
            try:
                myDig=any(dfCh[colVal].apply(lambda x: bool(re.search(digPatn, str(x)))))
                if(myDig):
                    dfCh.rename(columns = {dfCh.columns[colPos]:"Result"}, inplace = True)
            except Exception as e:
                print(e)
            try:
                myUnt=any(dfCh[colVal].apply(lambda x: bool(re.search(untPatn, str(x)))))
                if(myUnt):
                    dfCh.rename(columns = {dfCh.columns[colPos]:"Method"}, inplace =True)
            except Exception as e:
                print(e)
        dfCh.dropna(axis = 1)
        dfCh=dfCh.drop(dfCh.filter(regex='^Unnamed:.+$'), axis =1)                 
    else:
        dfCh=dfCh.drop(dfCh.filter(regex='^Unnamed:.+$'), axis =1)
        dfCh.iloc[:,1]=dfCh.loc[:,"Ankomsttemp °C Kem"].str.replace("[0-9]{2}%$","", regex = True)
        dfCh.iloc[:,1]=dfCh.loc[:,"Ankomsttemp °C Kem"].str.replace("< ", "<")
        dfCh.iloc[:,1]=dfCh.loc[:,"Ankomsttemp °C Kem"].str.replace("\s[0-9]\.[0-9]$","",regex = True)
        dfCh[['Result', "Method"]]=dfCh.iloc[:,1].str.split(" ", 1, expand = True)
    topFrame=dfCh.loc[:,['Analys','Result','Method']]
    topFrame.loc[topFrame["Analys"] == "pH","Method"] = "." #Adds a "." to prevent pH-method to be interpreted as null
    topFrame['Analys'] = topFrame['Analys']+"_"+topFrame['Method']
    topFrame = topFrame.transpose()
    topFrame.columns = topFrame.iloc[0,:]
    topFrame = topFrame.iloc[[1],:]
    topFrame.reset_index(inplace=True, drop=True)
    metaFrame = pd.DataFrame({"Provnum":mtchPrv.group(),"Date":dateVal}, index=[0])
    topFrame = pd.concat([metaFrame, topFrame], axis = 1) # Need to have same/compatibel index to work? Ignore index = True?
    return(topFrame)

#Create function for secondary pages 
def SecondaryPage(mySecpage):
    scDf = mySecpage
    scDf.loc[-1] = scDf.columns
    scDf.index = scDf.index + 1
    scDf.sort_index(inplace=True)
    scDf.rename(columns={scDf.columns[0] :"Analys", scDf.columns[1]:"Result", scDf.columns[2]:"Method"}, inplace=True)
    scDf = scDf.loc[:,["Analys", "Result", "Method"]]
    scDf['Analys']=scDf['Analys']+"_"+scDf['Method']
    scDf = scDf.dropna()
    scDf = scDf.transpose()
    scDf.reset_index(inplace=True, drop = True)
    scDf.columns = scDf.iloc[0,:]
    scDf = scDf.iloc[[1],:]
    scDf.reset_index(inplace=True, drop = True)
    return scDf


def tableAdjustment(aFrame):
    if(any(aFrame.columns.str.contains(r"^Provnummer:$"))):
        print("Modifing table to enable conversion")
        prvID = aFrame.columns.str.contains(r"^Provnummer:$")
        numID = aFrame.columns.str.contains(r"^[0-9]{1,3}-[0-9]{4}-[0-9].+$")
        numStr = aFrame.loc[:,numID].squeeze().name
        prvStr = aFrame.loc[:,prvID].squeeze().name
        aFrame[numStr] = aFrame[numStr].fillna('')
        aFrame[prvStr] = aFrame[prvStr].fillna('')
        aFrame[prvStr] = aFrame[prvStr] +" "+aFrame[numStr]
        aFrame.rename(columns={prvStr:(aFrame.columns[0]+" "+aFrame.columns[1])}, inplace = True)
        aFrame.drop(labels=numStr, axis = 1, inplace =True)
        return aFrame
    else:
        return aFrame
    
# Set pdf-folder to run script against
myPath = r"C:/Calluna/Data/SandBox/Convert_PDF_Table/Analyssvar/Fria vattenmassan 2022/Juni/Påverkansområde CePå/kontrollerade prover/CePå_Y allt ok"
os.chdir(myPath) 
myFolder=myPath.split("/")[-1]
pd.set_option("display.max_columns", 500)

fileFilter = [x for x in os.listdir(myPath) if x.endswith(".pdf")]

#aPdf="C:/Calluna/Data/SandBox/Convert_PDF_Table/Analyssvar/Fria vattenmassan 2022/Juni/Påverkansområde CePå/kontrollerade prover/CePå_C allt ok/CePa_C botten (177-2022-06100828)_177-2022-06291685_01.pdf"
#dfs = ti.read_pdf(aPdf, pages = "all")

logicGate = True
myPdfs=pd.DataFrame()

for aPdf in fileFilter:
    print(f"\nAnalysing:\n{aPdf}")
    secPages = pd.DataFrame()
    pdfNm=re.search(".+?(?=_[0-9]{3})",aPdf).group()
    logicGate = True
    pdfPath = myPath+"/"+aPdf
    dfs = ti.read_pdf(pdfPath, pages = "all")
    for aTbl in range(0, len(dfs)):
        if(logicGate):
            print("Working on first page")
            dfs[aTbl] = tableAdjustment(dfs[aTbl])
            myFront = frontPage(dfs[aTbl])
            watChmCol = myFront.columns[2:myFront.shape[1]]
            myFront['Name'] = re.search(".+?(?=_[0-9]{3})",aPdf).group()
            myFront = myFront.loc[:,~myFront.columns.duplicated()].copy()
            myFront = myFront.reindex(["Provnum", "Date","Name"] + list(watChmCol),axis =1)
            logicGate = False
        else:
            print("Working on secondary page")
            mySec = SecondaryPage(dfs[aTbl])
            secPages=pd.concat([secPages, mySec], axis =1)
    myTables = pd.concat([myFront, secPages], axis =1)
    myTables = myTables.loc[:,~myTables.columns.duplicated()].copy()
    myTables.columns = myTables.columns.fillna("MissingName")
    myEnd = myTables.reindex(sorted(myTables.columns[3:myTables.shape[1]],key=str.casefold), axis = 1)
    myTables = pd.concat([myTables.iloc[:,[0,1,2]], myEnd], axis =1)
    myPdfs = pd.concat([myPdfs, myTables], axis = 0)
print(f"\nExporting data:\nVattenkemi_FranPdf_{myFolder}.csv \n\nTo directory:\n{myPath}")
myPdfs.to_csv(f"Vattenkemi_FranPdf_{myFolder}.csv", index =False) 
#This export assumes that the path is written with forward slash "/". 