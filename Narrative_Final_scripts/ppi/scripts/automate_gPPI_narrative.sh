#!/bin/tcsh

set data_path = /Users/akila/Desktop/OB_Data/fMRI

set run = narrative_cleaned_v2
#foreach sub (44)

foreach sub (05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 48)
echo $sub

feat ${data_path}/OB_0${sub}/Connectivity/PPI/${run}_gPPI_1st_lvl.fsf


end