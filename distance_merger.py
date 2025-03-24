#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Mar 13 08:57:23 2025
ancient_individual_sampler.py

1. Take one excel as an input and print the number of individuals 
2. Take one annotation file in EIGENSTRAT FORMAT and print the number of individuals
3. Find similar individuals to the ones in the excel format, but in different ages
4. Save them to a sepparate file
@author: inf-40-2024
"""
### Modules and functions
import pandas as pd
import sys
#individuals_file = sys.argv[1]
#ancestries_file =sys.argv[2]

distance_files = pd.read_csv("new_distances.txt", sep = " ")
ancient_annotation = pd.read_csv("v54.1.p1_1240K_public.anno", sep = "\t")

# Rename the annote column
ancient_annotation.rename(columns ={"Genetic ID": "IID2"}, inplace= True)
ancient_annotation.rename(columns ={"Date mean in BP in years before 1950 CE [OxCal mu for a direct radiocarbon date, and average of range for a contextual date]": "Years BP"}, inplace= True)
# Join both dataframes using the first column of distance files
merged_df = distance_files.merge(ancient_annotation, on= "IID2", how = "inner")
# Keep only the interesting columns: Era	 Population	Year (BP)	Region	Lat	Long	CultureID	Dist
reduced_merged_df = merged_df[["Political Entity", "Lat.", "Long.", "DST", "Years BP" ]]
# Split into three files: all, modern and ancient
reduced_merged_df.to_csv("all_indivs_mapped", sep= "\t", index = False)
#reduced_merged_df["Years BP" == 0].to_csv("all_indivs_mapped", index = False)
#reduced_merged_df["Years BP" > 0].to_csv("all_indivs_mapped", index = False)
