       SUBROUTINE WR_DATA

C**********************************************************************
C
C  FUNCTION: Create source code for the hrdata module in EBI
C
C  PRECONDITIONS: None
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by Jerry Gipson, February, 2004
C                    Modified 7/09 to include SSA - J. Gipson
C
C**********************************************************************
      USE ENV_VARS
      USE GLOBAL_DATA

      IMPLICIT NONE

C..INCLUDES: 
      INCLUDE SUBST_IOPARMS        ! IOAPI parameters
      INCLUDE SUBST_IODECL         ! IOAPI declarations
      INCLUDE SUBST_RXCMMN         ! Mechanism data
      
C..ARGUMENTS: None

C..PARAMETERS: None

C..EXTERNAL FUNCTIONS:
      INTEGER   JUNIT      ! gets unit no.
      INTEGER   INDEX1     ! find position of string in list

C..SAVED LOCAL VARIABLES: None
 
C..SCRATCH LOCAL VARIABLES:
      CHARACTER(  16 )  ::    PNAME = 'WR_DATA'    ! Program name
      CHARACTER( 256 )  ::    MSG                  ! Message text
      CHARACTER( 100 )  ::    LINEIN               ! Input line
      CHARACTER( 256 )  ::    FNAME                ! Name of file to open

      INTEGER  :: EPOS         ! end pos of string
      INTEGER  :: IND          ! array index
      INTEGER  :: IIN          ! Unit no. of input file
      INTEGER  :: IOUT         ! Unit no. of output file
      INTEGER  :: LOGDEV       ! Unit no. of logdev
      INTEGER  :: N            ! Loop index

      LOGICAL  :: LOUT1 = .FALSE.  ! Flag for line 1 output processed
      LOGICAL  :: LOUT2 = .FALSE.  ! Flag for line 2 output processed
      LOGICAL  :: LOUT3 = .FALSE.  ! Flag for line 3 output processed
      LOGICAL  :: LOUT4 = .FALSE.  ! Flag for group 4 output processed
      LOGICAL  :: LOUT5 = .FALSE.  ! Flag for group 5 output processed


C**********************************************************************

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Open ouput file and code template 
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      LOGDEV = INIT3()

      EPOS = LEN_TRIM( OUTPATH )

      FNAME = OUTPATH( 1 : EPOS ) // '/hrdata_mod.F' 

      IOUT = JUNIT()

      OPEN( UNIT = IOUT, FILE = FNAME, ERR = 9000 )


      IIN = JUNIT()

      EPOS = LEN_TRIM( TMPLPATH )

      FNAME = TMPLPATH( 1 : EPOS ) // '/hrdata_mod.F' 

      OPEN( UNIT = IIN, FILE = FNAME, ERR = 9000 )


      IF( LWR_COPY ) CALL WR_COPYRT( IOUT )

      IF( LWR_CVS_HDR ) CALL WR_CVSHDR( IOUT )

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Read, modify, and write code from template
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

  100 CONTINUE

      READ( IIN, 92000, END = 1000 ) LINEIN

      IF( LINEIN( 1 : 1 ) .NE. 'R' ) THEN

         WRITE( IOUT, 92000 ) LINEIN( 1 : LEN_TRIM( LINEIN ) )

      ELSE

         IF( LINEIN( 2 : 2 ) .EQ. '1' .AND. .NOT. LOUT1 ) THEN

            WRITE( IOUT, 93000 ) GC_TAG( 1 : LEN_TRIM( GC_TAG ) )

            LOUT1 = .TRUE. 

         ELSEIF( LINEIN( 2 : 2 ) .EQ. '2' .AND. .NOT. LOUT2 ) THEN

            WRITE( IOUT, 93020 ) CR_DATE( 1 : LEN_TRIM( CR_DATE ) )

            LOUT2 = .TRUE. 
            
         ELSEIF( LINEIN( 2 : 2 ) .EQ. '3' .AND. .NOT. LOUT3 ) THEN

            IF( LPAR_NEG ) WRITE( IOUT, 93040 ) 

            LOUT3 = .TRUE.

         ELSEIF( LINEIN( 2 : 2 ) .EQ. '5' .AND. .NOT. LOUT5 ) THEN

            IF( LDEGRADE_SUBS ) WRITE( IOUT, 93045 ) LINEIN( 3 : LEN_TRIM( LINEIN ) )

            LOUT5 = .FALSE.

         END IF

      END IF

      GO TO 100

 1000 CONTINUE


ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Generate the species indices
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      IF( .NOT. L_ALL_MECHS ) THEN

         WRITE( IOUT, 93050 )

         DO N = 1, N_GC_SPC

            EPOS = LEN_TRIM( GC_SPC( N ) )

            WRITE( IOUT, 93080 ) GC_SPC( N ) ( 1 : EPOS )

         END DO

      ELSE


c..write gas species indices (names)
         WRITE( IOUT, 93060 )

         DO N = 1, N_GC_ONLY_SPC

            EPOS = LEN_TRIM( GC_ONLY_SPC( N ) )

            WRITE( IOUT, 93080 ) GC_ONLY_SPC( N ) ( 1 : EPOS )
  
         END DO

c..write the ae and aq species
         IF( N_AE_SPC .GT. 0 ) THEN
 
            WRITE( IOUT, 93100 )

            DO N = 1, N_AE_SPC
               WRITE( IOUT, 93080 ) AE_SPC( N )
            END DO

         END IF
            
         IF( N_AQ_SPC .GT. 0 ) THEN

            WRITE( IOUT, 93120 )

            DO N = 1, N_AQ_SPC
               WRITE( IOUT, 93080 ) AQ_SPC( N )
            END DO

         END IF

      END IF

      WRITE( IOUT, 93140 )

      CLOSE( IIN )

      CLOSE( IOUT )

      NOUTFLS = NOUTFLS + 1
      OUTFLNAM( NOUTFLS ) = 'hrdata_mod.F'

      RETURN 

 9000 MSG = 'ERROR: Could not open ' // FNAME( 1 : LEN_TRIM( FNAME ) )

      CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT2 )
       
92000 FORMAT( A )

93000 FORMAT( 'C  PRECONDITIONS: For the ', A, ' family of mechanisms' )
93020 FORMAT( 'C  REVISION HISTORY: Created by EBI solver program, ', A )
93040 FORMAT( 6X, 'REAL, ALLOCATABLE ::  PNEG(  : )     ',
     &            '! Negative production rates' )
93050 FORMAT( 'c..Species indices' )
93060 FORMAT( 'c..Gas species indices' )
93080 FORMAT( 6X, 'INTEGER   ', A )
93100 FORMAT( /'c..Aerosol species indices' )
93120 FORMAT( /'c..AQ chemistry species indices' )
93140 FORMAT( /6X, 'END MODULE HRDATA' )
93045 FORMAT(  2X, A )
      END

