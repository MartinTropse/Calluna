import os
import pandas as pd
import re
import matplotlib.pyplot as plt
from dateutil.relativedelta import relativedelta 
os.chdir('/Users/patrickgant/Documents')
# Read in the water chemistry data
vatten_kemi = pd.read_csv("Cementa provplanerade vattenprover - 2023-01-30 15_46.csv")
# Read in station depth
VattenkemiStationerDistance = pd.read_csv("VattenkemiStationerDistance.csv")
# It may be nessecary to remove certain characters within the dataframe. Below is an example of how to preform this task.
# However it may be easier to preform this step in excel before converting a copy to csv.
df = vatten_kemi.replace({',':''}, regex=True)
df = df.replace({'_':' '}, regex=True)
df = df.replace({'T4':'T'}, regex = True)
# Split column Provpunkt into three columns and rearage them.
df[['Område','Provpunkt','Place']] = df['Provpunkt'].str.split(' ', 2, expand = True)
col = df.pop("Place")
df.insert(1,"Place", col)
col = df.pop("Område")
df.insert(2,"Område", col)
#Remove columns that only have NaN in them
df = df.dropna(axis=1, how='all')
#Assign station depths
for i in range(len(df)):
    items = df.loc[i,'Provpunkt']
    index = VattenkemiStationerDistance['Stationsnamn'].isin([items])
    true_indices = [index for index, element in enumerate(index) if element]
    depth = VattenkemiStationerDistance.loc[true_indices[0],'Vattendjup vid stationen (m)']
    df.loc[i,'djup'] = depth
#Join depth and place columns
df["Place"] = df[["Place", "djup"]].agg(' '.join, axis = 1)
#Drop the extra depth data column
df = df.drop(['djup'], axis = 1)
#Remove columns "Oljetyp  C10" and "Oljetyp > C10" to make it easier to iterate through the dataframe
col_Olj_C10 = df.pop("Oljetyp  C10")
col_Olj_C10_2 = df.pop("Oljetyp > C10")
#Replace the område names
df = df.replace({'CePå':'påverkansområde'})
df = df.replace({'CeKo':'kontrollområde'})
df = df.replace({'CeNa':'naturreservat'})
# Sort dataframe by date.
df = df.sort_values("Ankomstdatum", axis = 0, ascending = True)
#df = df.sort_values("Provpunkt", axis = 0, ascending = True)
# Turn Ankomstdatum into datetime.
df['Ankomstdatum'] = pd.to_datetime(df['Ankomstdatum'],format = '%Y/%m/%d')
#Create a list of the column names for use later
column_names = df.columns.values.tolist()
#Create empty dataframe
parameter = pd.DataFrame()
currentDate = df['Ankomstdatum'].iloc[0]
endDate = df['Ankomstdatum'].iloc[140]
#If further temporal analysis is needed later on the dataframe below would be used for that, 
#anything with Analysis refers to this
#Analysis = pd.DataFrame()

#Loop checks each parameter for records on the current date and creates a boxplot for each station
for a in range(7,147):
    param = column_names[a]
    # add ("%m%Y") to check year
    if currentDate.strftime("%m") <= endDate.strftime("%m"):
        for b in range(1,6):
            for i in range(len(df)):
                date = df['Ankomstdatum'].iloc[i]
                # add ("%m%Y") to check year
                if date.strftime("%m") == currentDate.strftime("%m"):
                    prov = df.iloc[i,0]
                    place = df.iloc[i,1]
                    Område =  df.iloc[i,2]
                    v = df.iloc[i,a]
                    parameter.loc[i,'Provpunkt'] = prov
                    parameter.loc[i,'Område'] = Område
                    parameter.loc[i,'Place'] = place
                    parameter.loc[i,f'{param}'] = v
                    #Analysis.loc[i,'Ankomstdatum'] = date
                    #Analysis.loc[i,'Provpunkt'] = prov
                # if ((f'{param}' not in Analysis.columns)):
                #     Analysis[f'{param}'] = np.nan
                #     Analysis.loc[i,f'{param}'] = v
                # else:
                    #Analysis.loc[i,f'{param}'] = v
            name = f'{param}'
            parameter = parameter.dropna(axis = 0)
            if parameter.empty:
                currentDate = currentDate + relativedelta(months=+1)
                parameter = pd.DataFrame()
            else:
                # Edit name of parameter allowing it to be saved with the proper name
                namesave = re.sub('["^(/)$"]','', name)
                #Set path for new folders where each individual parameter will be saved
                newpath = f'/Users/patrickgant/Documents/VattenKemi/{namesave}'
                if not os.path.exists(newpath):
                    os.makedirs(newpath)
                parameter_bplt = parameter.boxplot(by = 'Provpunkt', column = f'{param}')
                parameter_bplt.plot()
                parameter_bplt.get_figure().suptitle('')
                #Change plot title name
                parameter_bplt.get_figure().gca().set_title(f'{name}  {currentDate.strftime("%B %Y")}')
                #Set path to the newly created folder for the boxplot to be saved in
                plt.savefig(f'/Users/patrickgant/Documents/VattenKemi/{namesave}/{namesave}_{currentDate.strftime("%B %Y")}.png', format = 'png')
                currentDate = currentDate + relativedelta(months=+1)
                parameter = pd.DataFrame()
        currentDate = df['Ankomstdatum'].iloc[0]
    else: 
        currentDate = df['Ankomstdatum'].iloc[0]
        parameter = pd.DataFrame()
#Analysis.to_csv('/Users/patrickgant/Documents/Analysis.csv', header= True, encoding='UTF-8')    






