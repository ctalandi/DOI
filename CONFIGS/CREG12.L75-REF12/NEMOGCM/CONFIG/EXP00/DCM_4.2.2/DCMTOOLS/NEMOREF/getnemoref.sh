#!/bin/bash

# note that you also need xios2 for compiling the code
#  This NEMO revision was compiled and ran successfully with
# xios rev 1587 of http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/dev/dev_olga
# to be compiled out of the DCM structure.
#  NEMO fcm files should indicate the xios root directory
#svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/trunk -r 10089 NEMO4
#svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/trunk -r 10374 NEMO4
# as of Jan 29, 2019 :
#svn co -r 10650 https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as od May 17, 2019
#svn co -r 10992  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as od May 18, 2019
#svn co -r 10997  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as od May 23, 2019
#svn co -r 11040  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as of June,4  2019
#svn co -r 11075  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as of November, 14 2019
#svn co -r 11902  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0.1 NEMO4
# as of March, 25 2020
#svn co -r 12604  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0.1 NEMO4
# as of March, 27 2020
#svn co -r 12591  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r4.0.2 NEMO4
# as of December, 03 2020
#svn co https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r4.0.4 NEMO4_r4.0.4
# as of February 8th 2021
#svn co https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r4.0.5 NEMO4_r4.0.5
# as of June 28th 2022
# The git command doesn't work on Rome for external web, so I downloaded it on my laptop then transfert it 
#git clone --branch 4.2.2 https://forge.nemo-ocean.eu/nemo/nemo.git nemo_4.2.2
