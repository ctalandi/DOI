#!/bin/bash
# run_nemo_scal.sh
######################################################
#  wrapper for submitting nemo4 scalability experiment
######################################################

usage() {
   echo
   echo "USAGE: $(basename $0) [-h] [-c CORES-per-node] [-x XIOS task-per-core] nxios jpni jpnj jpnij ndepe"
   echo "  "
   echo "  PURPOSE:"
   echo "    Launch scalability experiment corresponding to domain decomposition given"
   echo "    in the arguments."
   echo "  "
   echo "  ARGUMENTS:"
   echo "    jpni : number of subdomains in the I-direction"
   echo "    jpnj : number of subdomains in the J-direction"
   echo "    jpnij : Total number of ocean only subdomains."
   echo "    nxios : Number of xios_server.exe to be launched."
   echo "    ndepe : NEMO task-per-core "
   echo "  "
   echo "  OPTIONS:"
   echo "    -h : print this usage message."
   echo "    -c CORES-per-node : set number of cores per computing node. Default :" $ncpn
   echo "    -x XIOS tasks-per-core: set the number of tasks per core. Default :" $xdepe
   echo "  "
   exit 0
        }

ncpn=128
xdepe=1
ndepe=1

if [ ! $PDIR ] ; then
   echo "ERROR : You must set up your environment for DCM before using the RUN_TOOLS."
   echo "        PDIR environment variable not set."
   usage
fi

while getopts :hcx: opt ; do
   case $opt in
     (h) usage ;;
     (c) ncpn=${OPTARG} ;;
     (x) xdepe=${OPTARG} ;;
     (*) ;;
    esac
done

shift $(($OPTIND-1))

if [ $# != 5 ] ; then
   echo "ERROR: incorrect number of arguments."
   usage
fi

set -x
nxios=$1
jpni=$2
jpnj=$3
jpnij=$4
ndepe=$5

ntasks=$(( jpnij*ndepe + nxios*xdepe ))
nodes=$(( ntasks / ncpn ))
if [ $(( ntasks % ncpn )) != 0 ] ; then
  nodes=$(( nodes + 1 ))
fi
echo 
echo " >>>>>  Total nodes used: $nodes" 
echo 

. ./includefile.sh

# Create namelist from template:
cat ./namelist.${CONFIG_CASE}.tmp  | sed -e "s/<JPNI>/$jpni/g" -e "s/<JPNJ>/$jpnj/g" > namelist.${CONFIG_CASE}

# Create submit script from template:
cat ./${CONFIG_CASE}_${MACHINE}.sh.tmp  | sed -e "s/<JPNIJ>/$jpnij/g" -e "s/<NXIOS>/$nxios/g" -e "s/<NTASKS>/$ntasks/g"  -e "s/<NNODES>/$nodes/g" > ${SUBMIT_SCRIPT}


date
set -x
echo " submitting ${SUBMIT_SCRIPT} ..."

$SUBMIT  ./${SUBMIT_SCRIPT}
