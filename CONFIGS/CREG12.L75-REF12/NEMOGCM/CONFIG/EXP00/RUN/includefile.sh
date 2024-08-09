#!/bin/bash
date
set -x
########################################################################
#       2. PATHNAME   AND  VARIABLES INITIALISATION                    #
##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#
# Some FLAGS (formely deduced from cpp.options) 1= yes, 0= no
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# non standard features (even in DRAKKAR) ( no namelist nor cpp keys defined for that ! ) 
 UBAR_TIDE=0                          # 2D tidal bottom friction
 WAFDMP=0                             # Use WAter Flux DaMPing ( read previous SSS damping climatology in a file)

 RST_SKIP=1                           # if set, checking of the existence of the full set of restart files is disable (save time !)
 # next flags should be set to 1 if using DCM rev > 1674, to 0 otherwise.
 RST_DIRS=1                           # if set, assumes that restart files are written on multiple directories.
 RST_READY=1                          # if set assumes that restart file are ready to be read by NEMO (no links).
 MULTIRST=1                           # Do we want multi-restarts during one year simulation, @ 6, 7, 8 months and at the year end 

 monthly=0                            # set to 1 for 1mo job segments (for correct update of db file)
 semestrial=0                         # set to 1 for 6mo job segments (for correct update of db file)


#########################################################################

 CONFIG=CREG12.L75
 CASE=REF12
 CONFIG_CASE=${CONFIG}-${CASE}

# Environmemt and miscelaneous
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
login_node=node    # usefull on jade or an any machines requiring scp or ssh to access remote data
MAILTO=ctalandi@ifremer.fr
ACCOUNT=gen15098       # account number for project submission (e.g curie, vayu ...)
QUEUE=rome         # queue name (e.g. curie )

# Directory names
#~~~~~~~~~~~~~~~~
# 
#WORKDIR=/scratch/$USER
TMPDIR=${CCCSCRATCHDIR}/ONGOING-RUNS/TMPDIR_${CONFIG_CASE}
MACHINE=irene

case  $MACHINE  in
( occigen | jean-zay) SUBMIT=sbatch  ;;
( irene  ) SUBMIT=ccc_msub ;;
( ada    ) SUBMIT=SUBMIT=llsubmit ;;
( *      )  echo $MACHINE not yet supported for SUBMIT definition
esac

SUBMIT_SCRIPT=${CONFIG_CASE}_${MACHINE}.sh     # name of the script to be launched by run_nemo in CTL

if [ ! -d ${TMPDIR} ] ; then mkdir -p $TMPDIR ; fi

#
# Directory on the storage file system (F_xxx)
F_S_DIR=${SDIR}/${CONFIG}/${CONFIG_CASE}-S       # Stockage
F_R_DIR=${SDIR}/${CONFIG}/${CONFIG_CASE}-R       # Restarts
F_I_DIR=${SDIR}/${CONFIG}/${CONFIG}-I            # Initial + data
F_DTA_DIR=${SDIR}/${CONFIG}/${CONFIG}-I          # data dir
F_FOR_DIR=${SDIR}/DATA_FORCING/DFS5.2_RD/ALL    # in function 3.2
F_OBC_DIR=${SDIR}/${CONFIG}/${CONFIG}-I/OBC      # OBC files
F_BDY_DIR=${SDIR}/${CONFIG}/${CONFIG}-I/BDY      # BDY files
F_MASK_DIR=${SDIR}/${CONFIG}/${CONFIG}-I/MASK    # AABW damping , Katabatic winds
F_INI_DIR=${SDIR}/${CONFIG}/${CONFIG}-I/          
F_WEI_DIR=$SDIR/${CONFIG}/${CONFIG}-I/

F_OBS_DIR=/ccc/work/cont003/drakkar/drakkar      # for OBS operator
F_ENA_DIR=${P_OBS_DIR}/ENACT-ENS
F_SLA_DIR=${P_OBS_DIR}/j2

# Directories on the production machine (P_xxx)
SHAREDSCRATCHDIR=/ccc/scratch/cont003/gen7420/gen7420
P_S_DIR=${CCCSCRATCHDIR}/${CONFIG}/${CONFIG_CASE}-S
P_R_DIR=${CCCSCRATCHDIR}/${CONFIG}/${CONFIG_CASE}-R
P_I_DIR=${SHAREDSCRATCHDIR}/CREG/${CONFIG}/${CONFIG}-I                  
P_DTA_DIR=${SHAREDSCRATCHDIR}/CREG/${CONFIG}/${CONFIG}-I
P_FOR_DIR=${SHAREDSCRATCHDIR}/CREG/${CONFIG}/${CONFIG}-F/ERA5-DROWNED-NP/ALL
#P_FOR_DIR=/ccc/scratch/cont003/gen15098/talandel/CREG12.L75/CREG12.L75-F/ERA5
P_OBC_DIR=${SHAREDSCRATCHDIR}/CREG/${CONFIG}/${CONFIG}-F/BDYS/FULL-GLORYS12V1/ALL
P_BDY_DIR=${SHAREDSCRATCHDIR}/CREG/${CONFIG}/${CONFIG}-F/BDYS/FULL-GLORYS12V1/ALL
#P_OBC_DIR=/ccc/scratch/cont003/gen15098/talandel/CREG12.L75/CREG12.L75-F/BDYS
#P_BDY_DIR=/ccc/scratch/cont003/gen15098/talandel/CREG12.L75/CREG12.L75-F/BDYS

P_RNF_DIR=${SHAREDSCRATCHDIR}/CREG/${CONFIG}/${CONFIG}-F/RUNOFFS/HYDROGFD
P_WEI_DIR=${SHAREDSCRATCHDIR}/CREG/${CONFIG}/${CONFIG}-F

P_CTL_DIR=${PDIR}/RUN_${CONFIG}/${CONFIG_CASE}/CTL      # directory from which the job is  launched
P_CDF_DIR=${PDIR}/RUN_${CONFIG}/${CONFIG_CASE}/CTL/CDF  # directory from which the diags are launched
P_EXE_DIR=${PDIR}/RUN_${CONFIG}/${CONFIG_CASE}/EXE      # directory where to find opa
P_UTL_DIR=${REFDIR2}/tools/REBUILD_MPP                   # root directory of the build_nc programs (under bin )
P_XIOS_DIR=${CCCWORKDIRGEN7420}/TOOLS/XIOS/xios-trunk_r2503    # root directory of the XIOS library and xios_server.exe

#RUNTOOLS=/ccc/cont003/home/gen7420/talandel/DEV/DCM/DCM_4.2.2/RUNTOOLS  # RUNTOOLS directory
RUNTOOLS=/ccc/work/cont003/gen7420/talandel/TOOLS/DCM/DCM_4.2.2/RUNTOOLS  # RUNTOOLS directory

# Executable code
#~~~~~~~~~~~~~~~~
EXEC=$P_EXE_DIR/nemo4.exe                              # nemo ...
XIOS_EXEC=$P_XIOS_DIR/bin/xios_server.exe              # xios server (used if code compiled with key_iomput
#MERGE_EXEC=$P_UTL_DIR/mergefile4.exe                   # rebuild program (REBUILD_MPP TOOL)  either on the fly (MERGE=1) 
MERGE_EXEC=$P_UTL_DIR/mergefile_mpp4.exe              # rebuild program (REBUILD_MPP TOOL)  either on the fly (MERGE=1) 
                                                       # or in specific job (MERGE=0). MERGE and corresponding cores number
                                                       # are set in CTL/${SUBMIT_SCRIPT}
                                                       # if you want netcdf4 output use mergefile_mpp4.exe

# In the following, set the name of some files that have a hard coded name in NEMO. Files with variable names
# are directly set up in the corresponding namelist, the script take care of them.
# For the following files, if not relevant set the 'world' name to ''
# set specific file names (data )(world name )                 ;   and their name in NEMO
#--------------------------------------------------------------------------------------------------------
# Internal wave mixing 
MXP_BOT=CREG12.L75_mixing_power_bot_20210729.nc        ;       NEMO_MXP_BOT=CREG12.L75_mixing_power_bot_20210729.nc
MXP_SHO=CREG12.L75_mixing_power_sho_20210729.nc        ;       NEMO_MXP_SHO=CREG12.L75_mixing_power_sho_20210729.nc
MXP_CRI=CREG12.L75_mixing_power_cri_20210729.nc        ;       NEMO_MXP_CRI=CREG12.L75_mixing_power_cri_20210729.nc
MXP_NSQ=CREG12.L75_mixing_power_nsq_20210729.nc        ;       NEMO_MXP_NSQ=CREG12.L75_mixing_power_nsq_20210729.nc
                                                                                                                   
DSC_BOT=CREG12.L75_decay_scale_bot_20210729.nc         ;       NEMO_DSC_BOT=CREG12.L75_decay_scale_bot_20210729.nc
DSC_CRI=CREG12.L75_decay_scale_cri_20221124.nc         ;       NEMO_DSC_CRI=CREG12.L75_decay_scale_cri_20221124.nc

# Control parameters
# -----------------
MAXSUB=30            # resubmit job till job $MAXSUB
