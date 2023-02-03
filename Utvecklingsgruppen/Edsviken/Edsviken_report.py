# -*- coding: utf-8 -*-
"""
Created on Fri Feb  3 13:19:04 2023

@author: PavlosAslanis
"""

import pandas as pd
import os

# Path of input data.
path_input_data_raw = os.path.join(os.getcwd(), 'Input' ,'Edsviken - 2023-02-03 14_03.xlsx')

# Load data in df.
input_df_raw = pd.read_excel(path_input_data_raw)

######################
## Fixing the header. 
######################

# Save the first row as a list
first_row = list(input_df_raw.iloc[0])
# Create a new header by adding the first row to the original header
merged_header = []
for col, val in zip(input_df_raw.columns, first_row):
    merged_header.append(str(col) + "/^/||&" + str(val))

# Select the appropriate header level.    
fixed_header = []
c = 0
for header in merged_header:
    if c<4:
        fixed_header.append(header.split('/^/||&')[0])
    else: 
        fixed_header.append(header.split('/^/||&')[1])
    c+=1
      
# Rename the columns with the new header
input_df_raw.columns = fixed_header

# Drop the first row
input_df_raw = input_df_raw.drop(0)





