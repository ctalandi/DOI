#!/bin/bash

# 2023-04-25
module purge
module load intel/20.0.4
module load mpi/openmpi/4.1.4
module load flavor/hdf5/parallel hdf5/1.8.20
module load netcdf-fortran/4.4.4
module load feature/bridge/heterogenous_mpmd
module load DCM/4.2.2
