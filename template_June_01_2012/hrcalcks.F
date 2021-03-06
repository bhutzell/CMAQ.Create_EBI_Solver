
!------------------------------------------------------------------------!
!  The Community Multiscale Air Quality (CMAQ) system software is in     !
!  continuous development by various groups and is based on information  !
!  from these groups: Federal Government employees, contractors working  !
!  within a United States Government contract, and non-Federal sources   !
!  including research institutions.  These groups give the Government    !
!  permission to use, prepare derivative works of, and distribute copies !
!  of their work in the CMAQ system to the public and to permit others   !
!  to do so.  The United States Environmental Protection Agency          !
!  therefore grants similar permission to use the CMAQ system software,  !
!  but users are requested to provide copies of derivative works or      !
!  products designed to operate in the CMAQ system to the United States  !
!  Government without restrictions as to use by others.  Software        !
!  that is used with the CMAQ system but distributed under the GNU       !
!  General Public License or the GNU Lesser General Public License is    !
!  subject to their copyright restrictions.                              !
!------------------------------------------------------------------------!

C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header$

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

      SUBROUTINE HRCALCKS( NJPHOT, LSUNLIGHT, RJIN, TEMP, PRES, H2O, RK )

C**********************************************************************
C
C  FUNCTION: To compute thermal and photolytic reaction rate 
C            coefficients for each reaction.
C
C  PRECONDITIONS: Photolysis rates for individual species must have 
C                 been calculated and stored in RKPHOT. Expects 
C                 temperature in deg K, pressure in atm., water
C                 vapor in ppmV, and J-values in /min. 
C 
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
R1  REVISION HISTORY: Prototype created by Jerry Gipson, January, 2002
C   31 Mar 09 J.Young: replace include files with mechanism namelists
C   07 Mar 13 B.Hutzell revised type 9 falloff rate constants 
C
C***********************************************************************


      IMPLICIT NONE
      

C..INCLUDES:
      INCLUDE SUBST_RXCMMN 
      
C..ARGUMENTS:
      INTEGER NJPHOT                   ! Number of J-values set in PHOT

      LOGICAL LSUNLIGHT                ! Flag for daytime
 
      REAL      H2O                         ! Cell H2O mixing ratio (ppmV)
      REAL      TEMP                        ! Cell temperature (deg K)
      REAL      PRES                        ! Cell pressure (atm)
      REAL( 8 ) RK( NRXNS )
      REAL      RJIN( NJPHOT )              ! J-values for each cell

                                        
C..PARAMETERS: 
      REAL, PARAMETER :: COEF1     = 7.33981E+15 ! Molec/cc to ppm conv factor coefficient
      REAL, PARAMETER :: CONSTC    = 0.6         ! Constant for reaction type 7
      REAL, PARAMETER :: TI300     = 1.0 / 300.0 ! 1/deg K


C..EXTERNAL FUNCTIONS: None


C..SAVED LOCAL VARIABLES:
      CHARACTER( 16 ), SAVE   :: PNAME = 'HRCALCKS'


C..SCRATCH LOCAL VARIABLES:
      INTEGER NRT            ! Loop index for reaction types
      INTEGER IRXN           ! Reaction number
      INTEGER JNUM           ! J-value species # from PHOT
      INTEGER KNUM           ! Reaction # for a relative rate coeff.
      INTEGER N              ! Loop index for reactions

      REAL    RK0            ! K0 in falloff rate expressions
      REAL    RK1            ! k1 in falloff rate expressions
      REAL    RK2            ! K2 in falloff rate expressions
      REAL    RK3            ! K3 in falloff rate expressions
      REAL    XEND           ! Exponent in falloff rate expressions
      REAL( 8 )  :: CFACT    ! molec/cc to ppm conversion factor   
      REAL( 8 )  :: TINV     ! Reciprocal of temperature, /deg K
         
C***********************************************************************

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Set reciprical of temperatur and mole/cc to ppm conversion factor 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
         TINV  = 1.0 / TEMP
         CFACT = COEF1 * PRES * TINV

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Set photolytic rate coefficients using the photolysis J-values that
c  are stored in RJBLK
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF( .NOT. LSUNLIGHT ) THEN
      
c..If dark in every cell, zero all photolysis rate coefficients      
         DO NRT = 1, NMPHOT
            IRXN = IPH( NRT, 1 )
            RK( IRXN ) = 0.0
         END DO

      ELSE
      
c..otherwise do all absolute rates first and then relative rates
         DO NRT = 1, NMPHOT
            IF( IPH( NRT, 3 ) .NE. 0 ) THEN
               IRXN = IPH( NRT, 1 )
               JNUM = IPH( NRT, 2 )
               RK( IRXN ) = RTDAT( 1, IRXN ) * RJIN( JNUM )
            END IF
         END DO

         DO NRT = 1, NMPHOT
            IF( IPH( NRT, 3 ) .EQ. 0 ) THEN
               IRXN = IPH( NRT, 1 )
               KNUM = IPH( NRT, 2 )
               RK( IRXN ) = RTDAT( 1,IRXN ) * RK( KNUM )
            END IF
         END DO
      END IF 
       
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Do reaction type 1: k=A
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO NRT = 1, KTN1
         IRXN = KRX1( NRT )
         RK( IRXN ) = RTDAT(1, IRXN )
      END DO
   
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Do reaction type 2: k=A*(T/300)**B
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO NRT = 1, KTN2
         IRXN = KRX2( NRT )
         RK( IRXN ) = RTDAT( 1, IRXN ) * ( TEMP * TI300 ) **
     &                RTDAT( 2, IRXN )
      END DO
   
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Do reaction type 3: k=A*exp(C/T)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO NRT = 1, KTN3
         IRXN = KRX3( NRT )
         RK( IRXN ) = RTDAT( 1, IRXN ) * EXP( RTDAT( 3, IRXN ) * TINV )
      END DO
   
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Do reaction type 4: k=A*((T/300)**B)*exp(C/T)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO NRT = 1, KTN4
         IRXN = KRX4( NRT )
         RK( IRXN ) = RTDAT( 1, IRXN ) * ( TEMP *
     &                TI300 ) ** RTDAT( 2, IRXN ) * 
     &                EXP( RTDAT( 3, IRXN ) * TINV )
      END DO
   
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Do reaction type 7: k=A*(1+0.6*P)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO NRT = 1, KTN7
         IRXN = KRX7( NRT )
         RK( IRXN ) = RTDAT( 1, IRXN ) * ( 1.0 + CONSTC * PRES )
      END DO

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Do fall offs and special type %2 (ktype 8)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc       
      DO 100 NRT = 1, NFALLOFF

         IRXN = IRRFALL( NRT )

         IF( KTYPE( IRXN ) .EQ. 8 ) THEN
            RK0 = RTDAT( 1, IRXN ) * EXP( RTDAT( 2, IRXN ) * TINV )
            RK2 = RTDAT( 3, IRXN ) * EXP( RFDAT( 1, NRT )  * TINV )
            RK3 = 1.0E+06 * CFACT * RFDAT( 2, NRT ) * 
     &            EXP( RFDAT( 3, NRT ) * TINV )
            RK( IRXN ) = RK0 + ( RK3 / ( 1.0 + RK3 / RK2 ) ) 

         ELSEIF( KTYPE( IRXN ) .EQ. 9 ) THEN
            RK1 = RTDAT( 1,IRXN ) * EXP( RTDAT( 2, IRXN ) * TINV ) 
     &             * ( TEMP * TI300 ) ** RFDAT( 2, NRT )

            RK2 = 1.0E+06 * CFACT * RTDAT( 3,IRXN )
     &             * EXP( RFDAT( 1, NRT )  * TINV )
     &             * ( TEMP * TI300 ) ** RFDAT( 3, NRT )

            RK3 = RFDAT( 4, NRT ) * EXP( RFDAT( 5, NRT )  * TINV )

            RK( IRXN ) = RK1 + RK2 + RK3

         ELSE
            RK0 = 1.0E+06 * CFACT * 
     &            RTDAT( 1, IRXN ) * ( TEMP * TI300 ) ** 
     &            RTDAT( 2, IRXN ) * EXP( RTDAT( 3, IRXN ) * TINV )
            RK1 = RFDAT( 1,  NRT ) * ( TEMP * TI300 ) ** 
     &            RFDAT( 2,  NRT ) * EXP( RFDAT( 3,NRT ) * TINV ) 
            XEND = 1.0 / (( 1.0 + ( ( 1.0 / RFDAT( 5, NRT ) ) *
     &             LOG10( RK0 / RK1 ) ) **2 ) )
            RK( IRXN ) = ( RK0 / ( 1.0 + RK0 / RK1 ) ) *
     &                     RFDAT( 4, NRT ) ** XEND
         END IF

100   CONTINUE

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Do reaction type 5 and 6 (multipliers of above reactions)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO NRT = 1, KTN5
         IRXN = KRX5( NRT )
         KNUM = INT( RTDAT( 3, IRXN ) )
         RK( IRXN ) = RK( KNUM ) / ( RTDAT( 1,IRXN ) *
     &                EXP( RTDAT( 2, IRXN ) / TEMP ) )
      END DO

      DO NRT = 1, KTN6
         IRXN = KRX6( NRT )
         KNUM = INT( RTDAT( 2,IRXN ) )
         RK( IRXN ) = RK( KNUM ) * RTDAT( 1, IRXN )
      END DO

R2

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Convert to ppm units as needed
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF( KUNITS .EQ. 2 ) THEN

         DO 200 N = 1, NRXNS

            IF( KTYPE( N ) .NE. 0 ) THEN   ! Do all non-photolytic reactions

               IF( IORDER( N ) .EQ. 2 ) THEN

                  RK( N ) = RK( N ) * 60.0 * CFACT

               ELSEIF( IORDER( N ) .EQ. 3 ) THEN

                  RK( N ) = RK( N ) * 60.0 * CFACT * CFACT

               ELSEIF( IORDER( N ) .EQ. 1 ) THEN

                  RK( N ) = RK( N ) * 60.0 

               ELSEIF( IORDER( N ) .EQ. 0 ) THEN

                  RK( N ) = RK( N ) * 60.0 / CFACT

               END IF

            END IF

200      CONTINUE
      ELSE

         DO 300 N = 1, NFALLOFF      ! Do Falloff reactions only

            IRXN = IRRFALL( N )

            IF( IORDER( IRXN ) .EQ. 2 ) THEN

               RK( IRXN ) = RK( IRXN ) * 60.0 * CFACT

            ELSEIF( IORDER( IRXN ) .EQ. 3 ) THEN

               RK( IRXN ) = RK( IRXN ) * 60.0 * CFACT * CFACT

            END IF

300      CONTINUE

      END IF            
  
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Multiply rate constants by [M], [O2], [N2], or [H2O] where needed
c  and return
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF( NWM .GT. 0 ) THEN
         DO NRT = 1, NWM
            IRXN = NRXWM( NRT )
            RK( IRXN ) = RK( IRXN ) * ATM_AIR
         END DO
      END IF

      IF( NWO2 .GT. 0 ) THEN
         DO NRT = 1, NWO2
            IRXN = NRXWO2( NRT )
            RK( IRXN ) = RK( IRXN ) * ATM_O2
         END DO
      END IF

      IF( NWN2 .GT. 0 ) THEN
         DO NRT = 1, NWN2
            IRXN = NRXWN2( NRT )
            RK( IRXN ) = RK( IRXN ) * ATM_N2
         END DO
      END IF

      IF( NWW .GT. 0 ) THEN
         DO NRT = 1, NWW
            IRXN = NRXWW( NRT )
            RK( IRXN ) = RK( IRXN ) * H2O
         END DO
      END IF

      IF( NWCH4 .GT. 0 ) THEN
         DO NRT = 1, NWCH4
            IRXN = NRXWCH4( NRT )
            RK( IRXN ) = RK( IRXN ) * ATM_CH4 
         END DO
      END IF


      IF( NWH2 .GT. 0 ) THEN
         DO NRT = 1, NWH2
            IRXN = NRXWH2( NRT )
            RK( IRXN ) = RK( IRXN ) * ATM_H2
         END DO
      END IF

      RETURN

      END



