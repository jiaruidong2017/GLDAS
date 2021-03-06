!-------------------------------------------------------------------------
! NASA Goddard Space Flight Center Land Information System (LIS) V3.0
! Released May 2004
!
! See SOFTWARE DISTRIBUTION POLICY for software distribution policies
!
! The LIS source code and documentation are in the public domain,
! available without fee for educational, research, non-commercial and
! commercial purposes.  Users may distribute the binary or source
! code to third parties provided this statement appears on all copies and
! that no charge is made for such copies.
!
! NASA GSFC MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE
! SOFTWARE FOR ANY PURPOSE.  IT IS PROVIDED AS IS WITHOUT EXPRESS OR
! IMPLIED WARRANTY.  NEITHER NASA GSFC NOR THE US GOVERNMENT SHALL BE
! LIABLE FOR ANY DAMAGES SUFFERED BY THE USER OF THIS SOFTWARE.
!
! See COPYRIGHT.TXT for copyright details.
!
!-------------------------------------------------------------------------
!BOP
! 
! !ROUTINE: compute_coord_gauss
!
! !DESCRIPTION:
!  This subroutine computes the grid and earth coordinates of 
!  the specified domain for an gaussian cylindrical projection.
!  This routine is based on the grid
!  decoding routines in the ipolates interoplation package. 
!  
!  The input options include :
!  (iopt= 0) grid and earth coordinates of all grid points
!  (iopt=+1) earth coordinates of selected grid coordinates
!  (iopt=-1) grid coordinates of selected earth coordinates
!  The current code recognizes the following projections:
!             (gridDesc(1)=000) equidistant cylindrical
!             (gridDesc(1)=001) mercator cylindrical
!             (gridDesc(1)=003) lambert conformal conical
!             (gridDesc(1)=004) gaussian cylindrical
!             (gridDesc(1)=005) polar stereographic azimuthal
!             (gridDesc(1)=201) staggered rotated equidistant cylindrical
!             (gridDesc(1)=202) rotated equidistant cylindrical

! !REVISION HISTORY: 
!   04-10-96 Mark Iredell;  Initial Specification
!   05-27-04 Sujay Kumar; Modified verision with floating point arithmetic. 
!
!   input argument list:
!     gridDesc     - real (200) domain description parameters
!     iopt     - integer option flag
!                ( 0 to compute earth coords of all the grid points)
!                (+1 to compute earth coords of selected grid coords)
!                (-1 to compute grid coords of selected earth coords)
!     npts     - integer maximum number of coordinates
!     fill     - real fill value to set invalid output data
!                (must be impossible value; suggested value: -9999.)
!     xpts     - real (npts) grid x point coordinates if iopt>0
!     ypts     - real (npts) grid y point coordinates if iopt>0
!     rlon     - real (npts) earth longitudes in degrees e if iopt<0
!                (acceptable range: -360. to 360.)
!     rlat     - real (npts) earth latitudes in degrees n if iopt<0
!                (acceptable range: -90. to 90.)
!     lrot     - integer flag to return vector rotations if 1
!
!   output argument list:
!     xpts     - real (npts) grid x point coordinates if iopt<=0
!     ypts     - real (npts) grid y point coordinates if iopt<=0
!     rlon     - real (npts) earth longitudes in degrees e if iopt>=0
!     rlat     - real (npts) earth latitudes in degrees n if iopt>=0
!     nret     - integer number of valid points computed
!                (-1 if projection unrecognized)
! !INTERFACE:
subroutine compute_coord_gauss(gridDesc,iopt,npts,fill,xpts,ypts,&
     rlon,rlat,nret,lrot)
!EOP
  implicit none
  real, parameter :: pi=3.14159265358979
  integer, parameter :: jgmax=2000
  real :: dpr
  real :: gridDesc(50)
  integer :: iopt,npts,nret
  real :: xpts(npts),ypts(npts),rlon(npts),rlat(npts), rlata,rlatb
  real :: fill,lrot
  integer :: im,jm, jg, j, ja, n
  real :: rlat1,rlon1, rlat2, rlon2
  real :: hi, wb
  real :: dlon
  real :: xmin,xmax,ymin,ymax
  real :: alat(0:jgmax+1),blat(jgmax)
  integer :: iscan,jscan,nscan, iret
  real :: yptsa, yptsb
  integer :: jh, j1, j2
!- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  dpr =180./pi 
  if(gridDesc(1).eq.4.and.gridDesc(10)*2.le.jgmax) then
     im=gridDesc(2)
     jm=gridDesc(3)
     rlat1=gridDesc(4)
     rlon1=gridDesc(5)
     rlat2=gridDesc(7)
     rlon2=gridDesc(8)
     jg=gridDesc(10)*2
     iscan=mod(nint(gridDesc(11))/128,2)
     jscan=mod(nint(gridDesc(11))/64,2)
     nscan=mod(nint(gridDesc(11))/32,2)
     hi=(-1.)**iscan
     jh=(-1)**jscan
     dlon=hi*(mod(hi*(rlon2-rlon1)-1+3600,360.)+1)/(im-1)
     call gausslat(jg,alat(1),blat)
     do ja=1,jg
        alat(ja)=dpr*asin(alat(ja))
     enddo
     alat(0)=180.-alat(1)
     alat(jg+1)=-alat(0)
     j1=1
     do while(j1.lt.jg.and.rlat1.lt.(alat(j1)+alat(j1+1))/2)
        j1=j1+1
     enddo
     j2=j1+jh*(jm-1)
     xmin=0
     xmax=im+1
     if(im.eq.nint(360/abs(dlon))) xmax=im+2
     ymin=0.5
     ymax=jm+0.5
     nret=0
! translate grid coordinates to earth coordinates
     if(iopt.eq.0.or.iopt.eq.1) then
        do n=1,npts
           if(xpts(n).ge.xmin.and.xpts(n).le.xmax.and. & 
                ypts(n).ge.ymin.and.ypts(n).le.ymax) then
              rlon(n)=mod(rlon1+dlon*(xpts(n)-1)+3600,360.)
              j=min(int(ypts(n)),jm)
  if((j1+jh*(j-1)) .ge. 0) rlata=alat(j1+jh*(j-1))
!J              rlata=alat(j1+jh*(j-1))
  if((j1+jh*j) .ge. 0) rlatb=alat(j1+jh*j)
!J              rlatb=alat(j1+jh*j)
              wb=ypts(n)-j
              rlat(n)=rlata+wb*(rlatb-rlata)
              nret=nret+1
           else
              rlon(n)=fill
              rlat(n)=fill
           endif
        enddo
! translate earth coordinates to grid coordinates
     elseif(iopt.eq.-1) then
        if(abs(dlon-gridDesc(9)).gt.0.01) then
           print*, 'problem with the domain calculations : gdswiz04'
           stop
        endif
        do n=1,npts
           xpts(n)=fill
           ypts(n)=fill
           if(abs(rlon(n)).le.360.and.abs(rlat(n)).le.90) then
              xpts(n)=1+hi*mod(hi*(rlon(n)-rlon1)+3600,360.)/dlon
              ja=min(int((jg+1)/180.*(90-rlat(n))),jg)
  if(ja .ge. 0) then
              if(rlat(n).gt.alat(ja)) ja=max(ja-2,0)
              if(rlat(n).lt.alat(ja+1)) ja=min(ja+2,jg)
              if(rlat(n).gt.alat(ja)) ja=ja-1
              if(rlat(n).lt.alat(ja+1)) ja=ja+1
              yptsa=1+jh*(ja-j1)
              yptsb=1+jh*(ja+1-j1)
              wb=(alat(ja)-rlat(n))/(alat(ja)-alat(ja+1))
              ypts(n)=yptsa+wb*(yptsb-yptsa)
              if(xpts(n).ge.xmin.and.xpts(n).le.xmax.and. & 
                   ypts(n).ge.ymin.and.ypts(n).le.ymax) then
                 nret=nret+1
              else
                 xpts(n)=fill
                 ypts(n)=fill
              endif
  endif
           endif
        enddo
     endif
! projection unrecognized
  else
     iret=-1
     if(iopt.ge.0) then
        do n=1,npts
           rlon(n)=fill
           rlat(n)=fill
        enddo
     endif
     if(iopt.le.0) then
        do n=1,npts
           xpts(n)=fill
           ypts(n)=fill
        enddo
     endif
  endif
end subroutine compute_coord_gauss
