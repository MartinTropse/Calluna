# -*- coding: utf-8 -*-
"""
Created on Fri Feb  3 13:19:04 2023

@author: PavlosAslanis
"""

import pandas as pd
import os

# Path of input data.
path_input_data_raw = os.path.join(os.getcwd(), 'Input' ,'Edsviken skogsvik december 2022.xlsx')#.replace('\\','\')

# Load data in df.
input_df_raw = pd.read_excel(path_input_data_raw)
