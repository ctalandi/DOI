#!/bin/bash 

if [ ! -d /ccc/scratch/cont003/gen15098/talandel/ONGOING-RUNS/TMPDIR_CREG12.L75-REF12 ] ; then mkdir /ccc/scratch/cont003/gen15098/talandel/ONGOING-RUNS/TMPDIR_CREG12.L75-REF12 ; fi 

cd /ccc/scratch/cont003/gen15098/talandel/ONGOING-RUNS/TMPDIR_CREG12.L75-REF12

ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/woa09_ConTem_monthly_1deg_CT_CMA_drowned_Ex_L75.nc .
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/woa09_SalAbs_monthly_1deg_SA_CMA_drowned_Ex_L75.nc .
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/woa09_CTsst01-12_monthly_1deg_CT_CMA_drowned_Ex_L75.nc .
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/woa09_SAsss01-12_monthly_1deg_SA_CMA_drowned_Ex_L75.nc .

ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-F/reshape_WOA09_REG1toCREG12_bilin.nc .
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-F/SST_reshape_WOA09_REG1toCREG12_bilin.nc .

ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/CREG12.L75_PIOMAS_y1979_Z.nc  .
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/CREG12.L75_PIOMAS_y2000_Z.nc  .


ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-F/BDYS/FULL-GLORYS12V1/ALL/GLORYS12V1-CREG12.L75_BERING_CLIM-1993-2020.1d_icemod.nc .


ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/CREG12.L75_mixing_power_bot_20210729.nc  .
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/CREG12.L75_mixing_power_nsq_20210729.nc  .
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/CREG12.L75_mixing_power_cri_20210729.nc  . 
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/CREG12.L75_mixing_power_sho_20210729.nc  .
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/CREG12.L75_decay_scale_bot_20210729.nc   .
ln -sf /ccc/scratch/cont003/gen7420/gen7420/CREG/CREG12.L75/CREG12.L75-I/CREG12.L75_decay_scale_cri_20221124.nc   .

