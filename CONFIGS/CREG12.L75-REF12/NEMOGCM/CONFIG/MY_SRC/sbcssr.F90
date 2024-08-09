MODULE sbcssr
   !!======================================================================
   !!                       ***  MODULE  sbcssr  ***
   !! Surface module :  heat and fresh water fluxes a restoring term toward observed SST/SSS
   !!======================================================================
   !! History :  3.0  !  2006-06  (G. Madec)  Original code
   !!            3.2  !  2009-04  (B. Lemaire)  Introduce iom_put
   !!----------------------------------------------------------------------

   !!----------------------------------------------------------------------
   !!   sbc_ssr       : add to sbc a restoring term toward SST/SSS climatology
   !!   sbc_ssr_init  : initialisation of surface restoring
   !!----------------------------------------------------------------------
   USE oce            ! ocean dynamics and tracers
   USE dom_oce        ! ocean space and time domain
   USE sbc_oce        ! surface boundary condition
   USE phycst         ! physical constants
   USE sbcrnf         ! surface boundary condition : runoffs
!CT for SEDNA !!{ DRAKKAR 
   USE shapiro        ! used in case of ln_sssr_flt
!CT for SEDNA !!}
   !
   USE fldread        ! read input fields
   USE in_out_manager ! I/O manager
   USE iom            ! I/O manager
   USE lib_mpp        ! distribued memory computing library
   USE lbclnk         ! ocean lateral boundary conditions (or mpp link)
   USE lib_fortran    ! Fortran utilities (allows no signed zero when 'key_nosignedzero' defined)  
!CT for SEDNA add the function to compute frezing point {
   USE eosbn2         ! equation of state
!CT for SEDNA add the function to compute frezing point }

   IMPLICIT NONE
   PRIVATE

   PUBLIC   sbc_ssr        ! routine called in sbcmod
   PUBLIC   sbc_ssr_init   ! routine called in sbcmod
   PUBLIC   sbc_ssr_alloc  ! routine called in sbcmod

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   erp   !: evaporation damping   [kg/m2/s]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   qrp   !: heat flux damping        [w/m2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   coefice   !: under ice relaxation coefficient

   !                                   !!* Namelist namsbc_ssr *
   INTEGER, PUBLIC ::   nn_sstr         ! SST/SSS restoring indicator
   INTEGER, PUBLIC ::   nn_sssr         ! SST/SSS restoring indicator
   REAL(wp)        ::   rn_dqdt         ! restoring factor on SST and SSS
   REAL(wp)        ::   rn_deds         ! restoring factor on SST and SSS
   LOGICAL         ::   ln_sssr_bnd     ! flag to bound erp term 
   REAL(wp)        ::   rn_sssr_bnd     ! ABS(Max./Min.) value of erp term [mm/day]
   INTEGER         ::   nn_sssr_ice     ! Control of restoring under ice
!CT for SEDNA from { DRAKKAR 
   LOGICAL, PUBLIC ::   ln_sssr_flt     ! flag to filter sss for restoring
   INTEGER, PUBLIC ::   nn_shap_iter    ! number of iteration for shapiro
   LOGICAL, PUBLIC ::   ln_sssr_ice     ! flag to turn off/on SSS restoring under Sea-ice
!CT for SEDNA }

   REAL(wp) , ALLOCATABLE, DIMENSION(:) ::   buffer   ! Temporary buffer for exchange
   TYPE(FLD), ALLOCATABLE, DIMENSION(:) ::   sf_sst   ! structure of input SST (file informations, fields read)
   TYPE(FLD), ALLOCATABLE, DIMENSION(:) ::   sf_sss   ! structure of input SSS (file informations, fields read)
!CT for SEDNA from { DRAKKAR : limit sss restoring in the coastal area
   LOGICAL         :: ln_sssr_msk
   TYPE(FLD_N)     :: sn_coast
   REAL(wp), PUBLIC, ALLOCATABLE, DIMENSION(:,:) :: distcoast   ! use to read the distance and then for weight purpose

   REAL(wp)        :: rn_dist      ! (km) decaying lenght scale for SSS restoring near the coast
!CT for SEDNA }

   !! * Substitutions
#  include "do_loop_substitute.h90"
   !!----------------------------------------------------------------------
   !! NEMO/OCE 4.0 , NEMO Consortium (2018)
   !! $Id: sbcssr.F90 14834 2021-05-11 09:24:44Z hadcv $
   !! Software governed by the CeCILL license (see ./LICENSE)
   !!----------------------------------------------------------------------
CONTAINS

   SUBROUTINE sbc_ssr( kt )
      !!---------------------------------------------------------------------
      !!                     ***  ROUTINE sbc_ssr  ***
      !!
      !! ** Purpose :   Add to heat and/or freshwater fluxes a damping term
      !!                toward observed SST and/or SSS.
      !!
      !! ** Method  : - Read namelist namsbc_ssr
      !!              - Read observed SST and/or SSS
      !!              - at each nscb time step
      !!                   add a retroaction term on qns    (nn_sstr = 1)
      !!                   add a damping term on sfx        (nn_sssr = 1)
      !!                   add a damping term on emp        (nn_sssr = 2)
      !!---------------------------------------------------------------------
      INTEGER, INTENT(in   ) ::   kt   ! ocean time step
      !!
      INTEGER  ::   ji, jj   ! dummy loop indices
      REAL(wp) ::   zerp     ! local scalar for evaporation damping
      REAL(wp) ::   zqrp     ! local scalar for heat flux damping
      REAL(wp) ::   zsrp     ! local scalar for unit conversion of rn_deds factor
      REAL(wp) ::   zerp_bnd ! local scalar for unit conversion of rn_epr_max factor
      INTEGER  ::   ierror   ! return error code
!CT for SEDNA from { DRAKKAR 
      REAL(wp) , DIMENSION (jpi,jpj) :: zsss_m ! temporary array

      REAL(wp) , DIMENSION (jpi,jpj) :: zsssr_ice ! temporary array
      REAL(wp) , DIMENSION (jpi,jpj) :: zt_fzp    ! temporary array
      REAL(wp) ::   zii, zjj
!CT for SEDNA }
      !!
      CHARACTER(len=100) ::  cn_dir          ! Root directory for location of ssr files
      TYPE(FLD_N) ::   sn_sst, sn_sss        ! informations about the fields to be read
      !!----------------------------------------------------------------------
      !
      IF( nn_sstr + nn_sssr /= 0 ) THEN
         !
         IF( nn_sstr == 1)   CALL fld_read( kt, nn_fsbc, sf_sst )   ! Read SST data and provides it at kt
         IF( nn_sssr >= 1)   CALL fld_read( kt, nn_fsbc, sf_sss )   ! Read SSS data and provides it at kt
         !
!CT for SEDNA { Read climatological temparature to avoid SSS restoring in areas where it is close to the freezing point {
         IF ( .NOT. ln_sssr_ice) THEN
             CALL fld_read( kt, nn_fsbc, sf_sst )   ! Read SST data and provides it at kt
         ENDIF
!CT for SEDNA } Read climatological temparature to avoid SSS restoring in areas where it is close to the freezing point }
         !                                         ! ========================= !
         IF( MOD( kt-1, nn_fsbc ) == 0 ) THEN      !    Add restoring term     !
            !                                      ! ========================= !
            !
            IF(     nn_sstr == 1 ) THEN                                   !* Temperature restoring term
               DO_2D( nn_hls, nn_hls, nn_hls, nn_hls )
                  zqrp = rn_dqdt * ( sst_m(ji,jj) - sf_sst(1)%fnow(ji,jj,1) ) * tmask(ji,jj,1)
                  qns(ji,jj) = qns(ji,jj) + zqrp
                  qrp(ji,jj) = zqrp
               END_2D
            ELSEIF( nn_sssr == 2 ) THEN
               qrp(:,:) = 0._wp   ! necessary init, see bellow: qrp(ji,jj) = qrp(ji,jj) - ...
            ENDIF
            !
            IF( nn_sssr /= 0 .AND. nn_sssr_ice /= 1 ) THEN
              ! use fraction of ice ( fr_i ) to adjust relaxation under ice if nn_sssr_ice .ne. 1
              ! n.b. coefice is initialised and fixed to 1._wp if nn_sssr_ice = 1
               DO_2D( nn_hls, nn_hls, nn_hls, nn_hls )
                  SELECT CASE ( nn_sssr_ice )
                    CASE ( 0 )    ;  coefice(ji,jj) = 1._wp - fr_i(ji,jj)              ! no/reduced damping under ice
                    CASE  DEFAULT ;  coefice(ji,jj) = 1._wp + ( nn_sssr_ice - 1 ) * fr_i(ji,jj) ! reinforced damping (x nn_sssr_ice) under ice )
                  END SELECT
               END_2D
            ENDIF
            !
            IF( nn_sssr == 1 ) THEN                                   !* Salinity damping term (salt flux only (sfx))
               zsrp = rn_deds / rday                                  ! from [mm/day] to [kg/m2/s]
               DO_2D( nn_hls, nn_hls, nn_hls, nn_hls )
                  zerp = zsrp * ( 1. - 2.*rnfmsk(ji,jj) )   &      ! No damping in vicinity of river mouths
                     &        *   coefice(ji,jj)            &      ! Optional control of damping under sea-ice
                     &        * ( sss_m(ji,jj) - sf_sss(1)%fnow(ji,jj,1) ) * tmask(ji,jj,1)
                  sfx(ji,jj) = sfx(ji,jj) + zerp                 ! salt flux
                  erp(ji,jj) = zerp / MAX( sss_m(ji,jj), 1.e-20 ) ! converted into an equivalent volume flux (diagnostic only)
               END_2D
               !
            ELSEIF( nn_sssr == 2 ) THEN                               !* Salinity damping term (volume flux (emp) and associated heat flux (qns)
               zsrp = rn_deds / rday                                  ! from [mm/day] to [kg/m2/s]
               zerp_bnd = rn_sssr_bnd / rday                          !       -              -    
!CT for SEDNA { from DRAKKAR using filtered sss for restoring 
               IF (ln_sssr_flt ) THEN
                  CALL Shapiro_1D ( sss_m(:,:), nn_shap_iter, 'ORCA_GLOB', zsss_m )
                  zsss_m = zsss_m * tmask(:,:,1)
               ELSE
                  zsss_m = sss_m * tmask(:,:,1)
               ENDIF
!CT for SEDNA } using filtered sss for restoring 

!CT for SEDNA turn on/off damping under sea-ice {
               zsssr_ice(:,:) = 1._wp
               IF ( .NOT. ln_sssr_ice ) THEN
                   WHERE( fr_i(:,:) > 0._wp ) zsssr_ice(:,:) = 0._wp
               ENDIF
               ! Avoid SSS damping in areas where climatology has negative
               ! temperature, i.e. with potential sea-ice  
               CALL eos_fzp( sf_sss(1)%fnow(:,:,1), zt_fzp(:,:) )
               WHERE( sf_sst(1)%fnow(:,:,1) <= zt_fzp(:,:) ) zsssr_ice(:,:) = 0._wp
!CT for SEDNA turn on/off damping under sea-ice } 

               DO_2D( nn_hls, nn_hls, nn_hls, nn_hls )
!CT for SEDNA { from DRAKKAR : using filtered sss for restoring 
                  !zerp = zsrp * ( 1. - 2.*rnfmsk(ji,jj) )   &      ! No damping in vicinity of river mouths
                  !   &        *   coefice(ji,jj)            &      ! Optional control of damping under sea-ice
                  !   &        * ( sss_m(ji,jj) - sf_sss(1)%fnow(ji,jj,1) )   &
                  !   &        / MAX(  sss_m(ji,jj), 1.e-20   ) * tmask(ji,jj,1)
                  !IF( ln_sssr_bnd )   zerp = SIGN( 1.0_wp, zerp ) * MIN( zerp_bnd, ABS(zerp) )
                  !emp(ji,jj) = emp (ji,jj) + zerp
                  !qns(ji,jj) = qns(ji,jj) - zerp * rcp * sst_m(ji,jj)
                  !erp(ji,jj) = zerp
                  !qrp(ji,jj) = qrp(ji,jj) - zerp * rcp * sst_m(ji,jj)
                  zerp = zsrp * ( 1. - 2.*rnfmsk(ji,jj) )   &      ! No damping in vicinity of river mouths
                     &        * ( zsss_m(ji,jj) - sf_sss(1)%fnow(ji,jj,1) )   &
                     &        / MAX(  zsss_m(ji,jj), 1.e-20   ) * tmask(ji,jj,1)
                  IF( ln_sssr_bnd )   zerp = SIGN( 1.0_wp, zerp ) * MIN( zerp_bnd, ABS(zerp) )

                  zii=1170 ; zjj=970
                  IF ( mig(ji) == zii .AND. mjg(jj) == zjj ) THEN 
                        IF(  kt == nit000 ) THEN
                                WRITE(numout,*) '                    zerp:' , zerp 
                                WRITE(numout,*) '                    distcoast:' , distcoast ( ji,jj )
                                WRITE(numout,*) '                    zsssr_ice:' , zsssr_ice ( ji,jj )
                                WRITE(numout,*) '                    ln_sssr_msk:' , ln_sssr_msk
                        ENDIF
                  ENDIF

                  IF( ln_sssr_msk )   zerp = zerp * distcoast(ji,jj) ! multiply by weigh to fade zerp out near the coast

                  IF ( mig(ji) == zii .AND. mjg(jj) == zjj ) THEN 
                      IF(  kt == nit000 ) THEN
                          WRITE(numout,*) '                     zerp *  distcoast :' , zerp 
                      ENDIF
                  ENDIF
                  emp(ji,jj) = emp (ji,jj) + zerp * zsssr_ice(ji,jj)
                  qns(ji,jj) = qns(ji,jj) - zerp * rcp * sst_m(ji,jj) * zsssr_ice(ji,jj)
                  erp(ji,jj) = zerp * zsssr_ice(ji,jj)
                  qrp(ji,jj) = qrp(ji,jj) - zerp * rcp * sst_m(ji,jj) * zsssr_ice(ji,jj)

                  IF ( mig(ji) == zii .AND. mjg(jj) == zjj ) THEN 
                      IF(  kt == nit000 ) THEN
                          WRITE(numout,*) '                     zerp* zsssr_ice(ji,jj):' , zerp * zsssr_ice(ji,jj) 
                          WRITE(numout,*) '                     erp:' , erp( ji,jj )
                          WRITE(numout,*) '                               ' 
                      ENDIF
                  ENDIF

               END_2D
!CT for SEDNA } from DRAKKAR : using filtered sss for restoring 
            ENDIF
            ! outputs
            CALL iom_put( 'hflx_ssr_cea', qrp(:,:) )
            IF( nn_sssr == 1 )   CALL iom_put( 'sflx_ssr_cea',  erp(:,:) * sss_m(:,:) )
            IF( nn_sssr == 2 )   CALL iom_put( 'vflx_ssr_cea', -erp(:,:) )
            !
         ENDIF
         !
      ENDIF
      !
   END SUBROUTINE sbc_ssr

 
   SUBROUTINE sbc_ssr_init
      !!---------------------------------------------------------------------
      !!                  ***  ROUTINE sbc_ssr_init  ***
      !!
      !! ** Purpose :   initialisation of surface damping term
      !!
      !! ** Method  : - Read namelist namsbc_ssr
      !!              - Read observed SST and/or SSS if required
      !!---------------------------------------------------------------------
      INTEGER  ::   ji, jj   ! dummy loop indices
      REAL(wp) ::   zerp     ! local scalar for evaporation damping
      REAL(wp) ::   zqrp     ! local scalar for heat flux damping
      REAL(wp) ::   zsrp     ! local scalar for unit conversion of rn_deds factor
      REAL(wp) ::   zerp_bnd ! local scalar for unit conversion of rn_epr_max factor
      INTEGER  ::   ierror   ! return error code
      !!
!CT for SEDNA !!{ DRAKKAR 
      INTEGER  ::   ii0, ii1, ii2, ij0, ij1, ij2, inum
      REAL(wp) ::   zalph
      CHARACTER(LEN=100) ::  cl_coastfile
!!CT for SEDNA !}
      CHARACTER(len=100) ::  cn_dir          ! Root directory for location of ssr files
      TYPE(FLD_N) ::   sn_sst, sn_sss        ! informations about the fields to be read
      NAMELIST/namsbc_ssr/ cn_dir, nn_sstr, nn_sssr, rn_dqdt, rn_deds, sn_sst, &
              & sn_sss, ln_sssr_bnd, rn_sssr_bnd, nn_sssr_ice
!!CT for SEDNA !{ DRAKKAR 
      NAMELIST/namsbc_ssr/ ln_sssr_flt, ln_sssr_msk, sn_coast, rn_dist, nn_shap_iter, ln_sssr_ice
!!CT for SEDNA !}
      INTEGER     ::  ios
      !!----------------------------------------------------------------------
      !
      IF(lwp) THEN
         WRITE(numout,*)
         WRITE(numout,*) 'sbc_ssr : SST and/or SSS damping term '
         WRITE(numout,*) '~~~~~~~ '
      ENDIF
      ! 
      READ  ( numnam_ref, namsbc_ssr, IOSTAT = ios, ERR = 901)
901   IF( ios /= 0 )   CALL ctl_nam ( ios , 'namsbc_ssr in reference namelist' )

      READ  ( numnam_cfg, namsbc_ssr, IOSTAT = ios, ERR = 902 )
902   IF( ios >  0 )   CALL ctl_nam ( ios , 'namsbc_ssr in configuration namelist' )
      IF(lwm) WRITE ( numond, namsbc_ssr )

      IF(lwp) THEN                 !* control print
         WRITE(numout,*) '   Namelist namsbc_ssr :'
         WRITE(numout,*) '      SST restoring term (Yes=1)             nn_sstr        = ', nn_sstr
         WRITE(numout,*) '         dQ/dT (restoring magnitude on SST)     rn_dqdt     = ', rn_dqdt, ' W/m2/K'
         WRITE(numout,*) '      SSS damping term (Yes=1, salt   flux)  nn_sssr        = ', nn_sssr
         WRITE(numout,*) '                       (Yes=2, volume flux) '
         WRITE(numout,*) '         dE/dS (restoring magnitude on SST)     rn_deds     = ', rn_deds, ' mm/day'
         WRITE(numout,*) '         flag to bound erp term                 ln_sssr_bnd = ', ln_sssr_bnd
         WRITE(numout,*) '         ABS(Max./Min.) erp threshold           rn_sssr_bnd = ', rn_sssr_bnd, ' mm/day'
         WRITE(numout,*) '      Cntrl of surface restoration under ice nn_sssr_ice    = ', nn_sssr_ice
         WRITE(numout,*) '          ( 0 = no restoration under ice)'
         WRITE(numout,*) '          ( 1 = restoration everywhere  )'
         WRITE(numout,*) '          (>1 = enhanced restoration under ice  )'
!CT for SEDNA !!{ DRAKKAR 
         WRITE(numout,*) '      Filtering of sss for restoring         ln_sssr_flt = ', ln_sssr_flt 
         WRITE(numout,*) '      Apply SSS restoring under sea-ice      ln_sssr_ice = ', ln_sssr_ice 
         WRITE(numout,*) '         ln_sssr_ice overright the nn_sssr_ice official parameter'
         IF ( ln_sssr_flt ) THEN
            WRITE(numout,*) '      Number of used Shapiro filter           nn_shap_iter = ', nn_shap_iter
         ENDIF
         WRITE(numout,*) '      Limit sss restoring near the coast     ln_sssr_msk = ', ln_sssr_msk
         IF ( ln_sssr_msk ) WRITE(numout,*) '      Decaying lenght scale from the coast   rn_dist     = ', rn_dist, ' km'
!CT for SEDNA !!}
      ENDIF
      !
      IF( nn_sstr == 1 ) THEN      !* set sf_sst structure & allocate arrays
         !
         ALLOCATE( sf_sst(1), STAT=ierror )
         IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate sf_sst structure' )
         ALLOCATE( sf_sst(1)%fnow(jpi,jpj,1), STAT=ierror )
         IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate sf_sst now array' )
         !
         ! fill sf_sst with sn_sst and control print
         CALL fld_fill( sf_sst, (/ sn_sst /), cn_dir, 'sbc_ssr', 'SST restoring term toward SST data', 'namsbc_ssr', no_print )
         IF( sf_sst(1)%ln_tint )   ALLOCATE( sf_sst(1)%fdta(jpi,jpj,1,2), STAT=ierror )
         IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate sf_sst data array' )
         !
      ENDIF
      !
      IF( nn_sssr >= 1 ) THEN      !* set sf_sss structure & allocate arrays
         !
         ALLOCATE( sf_sss(1), STAT=ierror )
         IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate sf_sss structure' )
         ALLOCATE( sf_sss(1)%fnow(jpi,jpj,1), STAT=ierror )
         IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate sf_sss now array' )
         !
         ! fill sf_sss with sn_sss and control print
         CALL fld_fill( sf_sss, (/ sn_sss /), cn_dir, 'sbc_ssr', 'SSS restoring term toward SSS data', 'namsbc_ssr', no_print )
         IF( sf_sss(1)%ln_tint )   ALLOCATE( sf_sss(1)%fdta(jpi,jpj,1,2), STAT=ierror )
         IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate sf_sss data array' )
         !
!CT for SEDNA { Required to avoid SSS restoring in areas where climatology temperature is close to the freezing point }
         IF ( .NOT. ln_sssr_ice) THEN
             ALLOCATE( sf_sst(1), STAT=ierror )
             IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate sf_sst structure' )
             ALLOCATE( sf_sst(1)%fnow(jpi,jpj,1), STAT=ierror )
             IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate sf_sst now array' )
             !
             ! fill sf_sst with sn_sst and control print
             CALL fld_fill( sf_sst, (/ sn_sst /), cn_dir, 'sbc_ssr', 'SST restoring term toward SST data', 'namsbc_ssr' )
             IF( sf_sst(1)%ln_tint )   ALLOCATE( sf_sst(1)%fdta(jpi,jpj,1,2), STAT=ierror )
             IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate sf_sst data array' )
         ENDIF
!CT for SEDNA } Required to avoid SSS restoring in areas where climatology temperature is close to the freezing point }
!for SEDNA !!{ DRAKKAR 
         ! if masking of coastal area is used
         IF ( ln_sssr_msk ) THEN
            ALLOCATE( distcoast(jpi,jpj),STAT=ierror )  
            IF( ierror > 0 )   CALL ctl_stop( 'STOP', 'sbc_ssr: unable to allocate erp and qrp array' )
            WRITE(cl_coastfile,'(a,a)' ) TRIM( cn_dir ), TRIM( sn_coast%clname )
            CALL iom_open ( cl_coastfile, inum )                          ! open file
            CALL iom_get  ( inum, jpdom_global, sn_coast%clvar, distcoast ) ! read tcoast  in m
!CT         WRITE(numout,*) '                    distcoast just read ', distcoast ( mi0(1170):mi1(1170) , mj0(970):mj1(970) )
            CALL iom_close( inum )
            ! transform distcoast to weight 
            rn_dist=rn_dist*1000.  ! tranform rn_dist to m
            distcoast(:,:)=0.5*(tanh(3.*(distcoast(:,:)*distcoast(:,:)/rn_dist/rn_dist - 1 )) + 1 )
            !CT the distcoast field is not exactly zero but has a weak value ~2.472e-3 far from the coast.
            !CT We then force it to be zero exactly below 2.5e-3
            WHERE( distcoast(:,:) < 2.5e-3 ) distcoast(:,:) = 0._wp

!CT         WRITE(numout,*) '                    distcoast weight ', distcoast ( mi0(1170):mi1(1170) , mj0(970):mj1(970) )

         ENDIF
!CT for SEDNA !!}
      ENDIF
      !
      coefice(:,:) = 1._wp         !  Initialise coefice to 1._wp ; will not need to be changed if nn_sssr_ice=1
      !                            !* Initialize qrp and erp if no restoring 
      IF( nn_sstr /= 1 .AND. nn_sssr /= 2 )   qrp(:,:) = 0._wp
      IF( nn_sssr /= 1 .AND. nn_sssr /= 2 )   erp(:,:) = 0._wp
      !
   END SUBROUTINE sbc_ssr_init
         
   INTEGER FUNCTION sbc_ssr_alloc()
      !!----------------------------------------------------------------------
      !!               ***  FUNCTION sbc_ssr_alloc  ***
      !!----------------------------------------------------------------------
      sbc_ssr_alloc = 0       ! set to zero if no array to be allocated
      IF( .NOT. ALLOCATED( erp ) ) THEN
         ALLOCATE( qrp(jpi,jpj), erp(jpi,jpj), coefice(jpi,jpj), STAT= sbc_ssr_alloc )
         !
         IF( lk_mpp                  )   CALL mpp_sum ( 'sbcssr', sbc_ssr_alloc )
         IF( sbc_ssr_alloc /= 0 )   CALL ctl_warn('sbc_ssr_alloc: failed to allocate arrays.')
         !
      ENDIF
   END FUNCTION
      
   !!======================================================================
END MODULE sbcssr
