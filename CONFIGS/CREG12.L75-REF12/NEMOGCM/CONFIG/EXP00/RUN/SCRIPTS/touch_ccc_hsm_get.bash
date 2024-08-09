#!/bin/bash

set -xv 

ccc_hsm status /ccc/store/cont003/gen7420/talandel/CONFIGS/BUILD-CREG/CREG12.L75/CREG12.L75-F/ERA5-DROWNED-NP/199*/*

ccc_hsm status /ccc/store/cont003/gen7420/talandel/CONFIGS/BUILD-CREG/CREG12.L75/CREG12.L75-F/RUNOFFS/HYDROGFD/*199*

ccc_hsm status /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-F/BDYS/FULL-GLORYS12V1/ALL/GLORYS*199*.nc 
#ccc_hsm status /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-F/BDYS/FULL-GLORYS12V1/ALL/GLORYS*CLIM*.nc 


