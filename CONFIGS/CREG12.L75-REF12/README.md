# CREG12.L75-REF12 <br>
This reprository hold #1 the NEMO code source as associated input files as well (hereafter namelists) and #2 the list of input files such as the grid, the bathymetry and the surface forcing used to perform the numerical experiment named CREG12.L75-REF12.<br>

## OVERVIEW
CREG12.L75-REF12 is an ocean/sea-ice numerical experiment that relies on the NEMO numerical plateform [NEMO](https://www.nemo-ocean.eu). It aims at simulating the ocean/sea-ice dynamics over the north Atlantic ocean (starting from ~25°N), the Greenland-Iceland-Norway seas and the whole Arctic basin with a limit along the Bering strait.<br>
* The horizontal grid is a 1/12 degree i.e. from ~8km up to ~4km in most of the Arctic basin.
* A 75 vertical levels from 1m close to the surface up to 200m below 4000m.
* The model time step ∆t=270s for most of the experiment. 
* The period simulated spans the range 1979-2021.

## NUMERICS & PHYSICS ACTIVATED
Main evolution against the previous reference experiment CREG12.L75-REF09 are listed below:<br>
** switch to the TEOS-10 equation of state using the absolute salinity and the conservative temperature <br>
** the vertical coordinates z-star which is a non-linear free surface leading to a variable volume of the ocean and much better salinity conservation <br>
** the 3rd order UBS momentum flux formulation and the 2nd order FCT scheme for tracers advection <br>
** additional bi-Laplacian viscosity and diffusivity formulation depending on the local velocity <br>
** the SI3 sea-ice model  <br>

### SOURCE CODE : 
   * The ocean/sea ice model: <br>
	** The initial code source relies on the official NEMO release 4.2.2. Information can be found there https://forge.ipsl.jussieu.fr/nemo/wiki/Users#. The whole official code release 4.2.2 [NEMO](./NEMOGCM/NEMO) is available as the specific code changes as well associated to this experiement in the [MY_SRC](./NEMOGCM/CONFIG/CREG12.L75-REF12/MY_SRC). The [ARCH](./NEMOGCM/ARCH) give a list all computers architecture on wich NEMO has been compiled as templates.
   * The XIOS libray to perform outputs:<br>
	** The XIOS library revision 2503 has been downloaded and compiled. More information can be found there [XIOS](https://forge.ipsl.jussieu.fr/nemo/chrome/site/doc/NEMO/guide/html/install.html#extract-and-install-xios).

### INPUT FILES :
1 - Time invariant input files:
   * Domain_cfg: ```CREG12.L75-REF09_domain_cfg_20230801_Z.nc```, this file is required since the NEMO release 4.2; it relies on a bathymetry and a coordinates files  <br>
        **Bathymetry: <br>
	*** Description: ocean depth in meters (zero over land grid points). This file has been extracted from an existing global ORCA12 configuration file.<br>
	*** File name: ```bathymetry_CREG12_V3.3_20230801.nc```<br>
        ** Coordinates: <br>
	*** Description: horizontal grid scale factors as the geographical location of each Arakaw-C grid type point. This file has been extracted from an existing global ORCA12 configuration file.  <br>
	*** File name: ```coordinates_CREG12_lbclnk_noz_vh20160930.nc```<br>
   * Ocean initialisation: <br>
	** Description: [World Ocean Atlas 2009](https://www.nodc.noaa.gov/OC5/WOA09/pubwoa09.html) at 1°x1° climatology potential temperature (Locarnini et al. 2010) and practical salinity (Antonov et al. 2010), fields have been converted into conservative temperature and absolute salinity using the [GSW](http://www.teos-10.org/pubs/gsw/html/gsw_contents.html) package.   <br>
	** File name:```woa09_SalAbs_monthly_1deg_SA_CMA_drowned_Ex_L75.nc, woa09_ConTem_monthly_1deg_CT_CMA_drowned_Ex_L75.nc``` <br>
   * Ice initialisation:<br>
	** Description: January 1979 sea-ice initial state relies on the [PIOMAS](http://psc.apl.uw.edu/research/projects/arctic-sea-ice-volume-anomaly/data/) re-analysis dataset (Zhang and Rothrock, 2003, Mon. Weather Rev.). <br>
	** File name:```CREG12.L75_PIOMAS_y1979_Z.nc```<br>
   * Tidal mixing parametrization: <br>
	** Description: A new comprehensive parameterization of mixing by breaking internal tides and lee waves (de Lavergne et al., 2020, JAMES) <br>
	** Files name:```CREG12.L75_mixing_power_XXX_20210729.nc``` XXX stands for either sho, nsq, cri or bot and 2 decay scales files: ```CREG12.L75_decay_scale_bot_20210729.nc``` and ```CREG12.L75_decay_scale_cri_20221124.nc```<br>
   * Distance to the coast:<br>
	** Description: gives the distance to the coast of each ocean grid points. It is used to switch off the SSS restoring in a 150km wide range from the coast. Furthermore, the damping has been totaly removed over the Arctic Basin & the Barents Sea through this file<br>
	** File name: ```dist_coast_CREG12.L75-REF12.nc```<br>

2 - Time varying input files:
   * Surface forcing:<br>
	** Description: The [ERA5](https://cds.climate.copernicus.eu) atmospheric forcing data set with a 0.25° horizontal resolution. Turbulent and radiative fluxes are computed using the ```CORE bulk formulae``` (from NCAR). A light change has been done on the last raw of the wind compondnents to get rid of the hole located at the north pole if original fields are not adapted. Also, the surface current feedback to the wind stress computation following Renault et al. 200 paramertization has been activated; the ice velocities are no more taken into account in the calculation of the stress above the sea-ice <br>
	** File name: ```ERA5_<var>_drwndNP_yXXXX.nc``` <var> stands for either u10,v10,msl,mtpr,msr,msdwlwrf,msdwswrf,t2m,d2m for the 2 wind components, mean sea-level pressure, mean total precipitation, mean snow fall rate, mean downward long and short-wave radiation flux, 2 metre temperature, 2 metre dewpoint temperature.  <br>
	** Frequency: hourly <br>
   * Rivers discharge fluxes:<br>
	** Description: The original HYDRO re-analysis dataset has been mapped to the CREG12 domain.  (Stadnyk et al. 2021, Elementa. ) <br>
	** File name: ```CREG12_ReNat_HydroGFD_HBC_runoff_monthly_yXXX.nc``<br>
	** Frequency: monthly<br>
   * Open boundaries:<br>
	** Description: 2 open boundaries conditions limit the CREG regional domain; at the Bering strait and in the sub-tropics about 25DdegN in the North Atlantic. Data used have been extracted from the global GLORYS 1/12° re-analysis and vertically interpolated to fit the 75 vertical levels. The original data have been also converted into both conservative temperature and absolute salinity usig the [GSW](http://www.teos-10.org/pubs/gsw/html/gsw_contents.html) package. Finally, since this reanalysis starts in 1993 onward, a climatology over the years 1993-2021 has been built to force the boundaries from 1979 to 1992. Finally, the inflow through the Bering strait has been constrained to be close to recent observation with a mean volume transport about 1.4 Sv, leading to change the meridionnal veolicities. <br>
	** File name: ```GLORYS12V1-CREG12.L75_SUBTROPGYRE_<temp>.1d_<var>.nc``` and ```GLORYS12V1-CREG12.L75_BERING_<temp>.1d_<var>.nc```. <var> stands vor SSH, U, V, T, S and ice for the Bering open boundary while <temp> stands for either CLIM-1993-2020 or the current year starting from 1993 onward<br>
	** Frequency: daily <br>
   * World Ocean Atlas 2009 surface salinity (Antonov et al. 2010):<br>
	** Description: Sea surface salinity restoring with a piston velocity of 167 mm/day ( 60 days/10 meters); original practical salinity has been converted to absolute salinity using the [GSW](http://www.teos-10.org/pubs/gsw/html/gsw_contents.html) package <br>
	** File name: ```woa09_SAsss01-12_monthly_1deg_SA_CMA_drowned_Ex_L75.nc```<br>
	** Frequency: monthly<br>
   * World Ocean Atlas 2009 surface temperature (Locarnini et al. 2010) :<br>
	** Description: to avoid SSS restoring where the SST climatology temperature is at the freezing point, i.e. in presence of sea-ice; original potential temperature has been converted to conservative temperature using the [GSW](http://www.teos-10.org/pubs/gsw/html/gsw_contents.html) package<br>
	** File name: ```.woa09_CTsst01-12_monthly_1deg_CT_CMA_drowned_Ex_L75.nc```<br>
	** Frequency: monthly<br>
