#/bin/bash

set -xv 

module purge
#module load intel/20.0.4
#module load mpi/openmpi/4.1.4
module load flavor/hdf5/parallel hdf5/1.8.20
module load netcdf-fortran/4.4.4
module load gnu/8.3.0 

module load boost
module load blitz
module load feature/bridge/heterogenous_mpmd


./make_xios --arch X64_IRENE-AMD —full
