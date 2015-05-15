!> \file date_and_time.f90  Procedures to manipulate date and time


!  Copyright (c) 2002-2015  AstroFloyd - astrofloyd.org
!   
!  This file is part of the libSUFR package, 
!  see: http://libsufr.sourceforge.net/
!   
!  This is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published
!  by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!  
!  This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
!  
!  You should have received a copy of the GNU General Public License along with this code.  If not, see 
!  <http://www.gnu.org/licenses/>.




!***********************************************************************************************************************************
!> \brief  Procedures for manipulation of date and time

module SUFR_date_and_time
  implicit none
  save
  
contains
  
  
  !*********************************************************************************************************************************
  !> \brief  Convert a calendar date to JD.  Input and output in UT.
  !!
  !! \param yy  The year (int)
  !! \param mm  The month (int)
  !! \param dd  The day (double)
  !!
  !! \retval  cal2jd  The Julian day number (double)
  
  function cal2jd(yy,mm,dd)
    use SUFR_kinds, only: double
    
    implicit none
    real(double), intent(in) :: dd
    integer, intent(in) :: yy,mm
    
    real(double) :: cal2jd,d
    integer :: y,m,a,b,greg
    
    y = yy
    m = mm
    d = dd
    greg = 0                 ! Julian or gregorian?
    
    if(y.gt.1582) greg = 1
    if(y.eq.1582) then
       if(m.gt.10) greg = 1
       if((m.eq.10).and.(d.ge.15)) greg = 1
    end if
    !greg=0                 ! Force julian/gregorian calendar
    
    if(m.le.2) then 
       y = y-1
       m = m+12
    end if
    b = 0
    
    if(greg.eq.1) then     ! For a Gregorian date
       a = floor(y/100.d0)
       b = 2 - a + floor(a/4.d0)
    end if
    
    cal2jd = floor(365.25d0*(y+4716)) + floor(30.6001d0*(m+1)) + d + b - 1524.5d0
    
  end function cal2jd
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Convert a Julian day to a calendar date (fractional day) - in UT
  !!
  !! \param  jd  Julian day (UT)
  !! \retval yy  Year (CE)
  !! \retval mm  Month
  !! \retval dd  Day of month (+ fraction)
  
  subroutine jd2cal(jd, yy,mm,dd)
    use SUFR_kinds, only: double, dbl, long
    
    implicit none
    real(double), intent(in) :: jd
    integer, intent(out) :: yy,mm
    real(double), intent(out) :: dd
    real(double) :: f
    integer(long) :: z,a,b,c,d,e,alpha
    
    ! Some programs may return JD=-huge if no solution is found - catch this
    if(jd.gt.abs(huge(jd))*0.1_dbl) then
       yy = 0
       mm = 0
       dd = 0.0_dbl
       return
    end if
    
    
    z = floor(jd+0.5d0)
    f = jd + 0.5d0 - z
    if(z.lt.2299161) then   ! Use the Julian calendar
       a = z
    else                    ! Use the Gregorian calendar
       alpha = floor((z-1867216.25d0)/36524.25d0)
       a = z + 1 + alpha - floor(alpha/4.d0)
    end if
    
    b = a + 1524
    c = floor((b - 122.1d0)/365.25d0)
    d = floor(365.25d0*c)
    e = floor((b-d)/30.6001d0)
    dd = b - d - floor(30.6001d0*e) + f
    
    if(e.lt.14) then
       mm = int(e - 1)
    else
       mm = int(e - 13)
    end if
    
    if(mm.gt.2) then
       yy = int(c - 4716)
    else
       yy = int(c - 4715)
    end if
    
  end subroutine jd2cal
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Convert a Julian day to date and time (h,m,s, UT)
  !!
  !! \param  jd  Julian day (UT)
  !!
  !! \retval yy  Year (CE, UT)
  !! \retval mm  Month (UT)
  !! \retval d   Day (UT)
  !! \retval h   Hour (UT)
  !! \retval m   Minute (UT)
  !! \retval s   Second (+ fraction, UT)
  
  subroutine jd2dtm(jd,  yy,mm,d, h,m,s)
    use SUFR_kinds, only: double, dbl
    use SUFR_constants, only: mlen
    
    implicit none
    real(double), intent(in) :: jd
    integer, intent(out) :: yy,mm,d,h,m
    real(double), intent(out) :: s
    real(double) :: dd,tm
    
    call jd2cal(jd,  yy,mm,dd)
    mlen(2) = 28 + leapyr(yy)
    
    ! jd2cal returns zeroes if JD not defined (i.e., JD=-huge), and mlen(mm) is not defined - catch this:
    if(yy.eq.0.and.mm.eq.0) then
       d = 0
       h = 0
       m = 0
       s = 0.0_dbl
       return
    end if
    
    d  = int(dd)
    tm = (dd - dble(d))*24.d0
    h  = int(tm)
    m  = int((tm-h)*60.d0)
    s  = (tm-h-m/60.d0)*3600.d0
    
  end subroutine jd2dtm
  !*********************************************************************************************************************************
  
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Convert a Julian day to time (UT, h)
  !!
  !! \param jd  Julian day (UT)
  
  function jd2time(jd)
    use SUFR_kinds, only: double
    
    implicit none
    real(double), intent(in) :: jd
    real(double) :: jd2time,dd
    integer :: mm,yy
    
    call jd2cal(jd, yy,mm,dd)
    jd2time = (dd - floor(dd))*24.d0
    
  end function jd2time
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Convert date and time (y,m,d, h,m,s) to JD.  Input and output in UT.
  !! 
  !! \param yy          The year (int)
  !! \param mmo         The month (int)
  !! \param dd          The day (int)
  !! \param h           The hour (int)
  !! \param m           The minute (int)
  !! \param s           The second (double)
  !! \retval ymdhms2jd  The Julian day number (double)
  
  function ymdhms2jd(yy,mmo,dd, h,m,s)
    use SUFR_kinds, only: double
    
    implicit none
    integer, intent(in) :: yy,mmo,dd,h,m
    real(double), intent(in) :: s
    real(double) ymdhms2jd
    
    integer :: y,mo
    real(double) :: d
    
    y = yy
    mo = mmo
    d = dble(dd) + dble(h)/24.d0 + dble(m)/1440.d0 + s/86400.d0
    ymdhms2jd = cal2jd(y,mo,d)
    
  end function ymdhms2jd
  !*********************************************************************************************************************************
  
  
  !*********************************************************************************************************************************
  !> \brief Convert date and time (h) to a Julian day -  input in UT
  !!
  !! \param yy    Year (CE)
  !! \param mo    Month
  !! \param dd    Day of month
  !! \param time  Time (hours)
  
  function dtm2jd(yy,mo,dd,time)
    use SUFR_kinds, only: double
    
    implicit none
    integer, intent(in) :: yy,mo,dd
    real(double), intent(in) :: time
    real(double) :: d,dtm2jd
    
    d = dble(dd) + time/24.d0
    dtm2jd = cal2jd(yy,mo,d)
    
  end function dtm2jd
  !*********************************************************************************************************************************
  
  
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Convert time (h) to hours and minutes
  !!
  !! \param  tm  Time (hours)
  !! \retval h   Hours
  !! \retval m   Minutes (integer)
  
  subroutine tm2hm(tm,h,m)
    use SUFR_kinds, only: double
    implicit none
    real(double), intent(in) :: tm
    integer, intent(out) :: h,m
    
    h = floor(tm)
    m = nint((tm-dble(h))*60)
    
    if(m.ge.60) then
       h = h+1
       m = m-60
    end if
    if(h.ge.24) h = h-24
    
  end subroutine tm2hm
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Convert time (h) to hours, minutes and seconds
  !!
  !! \param  tm  Time (hours)
  !! \retval h   Hours
  !! \retval m   Minutes
  !! \retval s   Seconds (integer)
  
  subroutine tm2hms(tm,h,m,s)
    use SUFR_kinds, only: double
    implicit none
    real(double), intent(in) :: tm
    integer, intent(out) :: h,m,s
    
    h = floor(tm)
    m = floor((tm-dble(h))*60)
    s = nint((tm - dble(h) - dble(m)/60.d0)*3600)
    
    if(s.ge.60) then
       m = m+1
       s = s-60
    end if
    if(m.ge.60) then
       h = h+1
       m = m-60
    end if
    if(h.ge.24) h = h-24
    
  end subroutine tm2hms
  !*********************************************************************************************************************************
  
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Calculates day of week (0 - Sunday, ... 6).  Output for timezone of input - call dow_ut(jd+tz/24.d0) for local time.
  !!
  !! \param  jd0  Julian day number (double)
  !! \retval dow_ut  The day-of-week number, 0-6 for Sun-Sat (int)
  
  function dow_ut(jd0)
    use SUFR_kinds, only: double
    
    implicit none
    real(double), intent(in) :: jd0
    integer :: dow_ut
    real(double) :: jd,x
    
    jd = dble(nint(jd0)) - 0.5d0
    x = (jd + 1.5d0)/7.d0
    
    dow_ut = nint(jd + 1.5d0 - floor(x)*7.d0)
    
  end function dow_ut
  !*********************************************************************************************************************************
  
  
  !*********************************************************************************************************************************
  !> \brief  Calculate day of year (1-366) from JD
  !!
  !! \param jd0  Julian day
  
  function doy(jd0)
    use SUFR_kinds, only: double
    
    implicit none
    real(double), intent(in) :: jd0
    integer :: doy,yr,mon
    real(double) :: jd1,dy
    
    call jd2cal(jd0, yr,mon,dy)
    jd1 = cal2jd(yr,1,0.5d0)
    doy = nint(jd0-jd1)
    
  end function doy
  !*********************************************************************************************************************************
  
  

  !*********************************************************************************************************************************
  !> \brief  Calculate day of year (1-366) from year,month,day
  !!
  !! \param yr   Year (CE)
  !! \param mon  Month
  !! \param dy   Day of month
  
  function ymd2doy(yr,mon,dy)
    use SUFR_kinds, only: double
    
    implicit none
    integer, intent(in) :: yr,mon,dy
    real(double) :: jd0,jd1
    integer :: ymd2doy
    
    jd0 = cal2jd(yr,mon,dble(dy))
    jd1 = cal2jd(yr,1,0.5d0)
    ymd2doy = nint(jd0-jd1)
    
  end function ymd2doy
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Calculate month and day  from  day of year and year
  !!
  !! \param doy   Day of year number
  !! \param yr    Year (CE)
  !! \retval mon  Month of year
  !! \retval dy   Day of month
  !!
  !! \note year is input
  
  subroutine doy2md(doy,yr, mon,dy)
    use SUFR_kinds, only: double
    
    implicit none
    integer, intent(in) :: doy,yr
    integer, intent(out) :: mon,dy
    integer :: yr1
    real(double) :: jd1,dy1
    
    jd1 = cal2jd(yr,1,dble(doy))
    call jd2cal(jd1,yr1,mon,dy1)
    dy = floor(dy1)
    
  end subroutine doy2md
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Calculate whether year is leap (1) or not (0).  The number of days in February is then given by 28 + leapyr(yr)
  !!
  !! \param yr  Year (CE)
  
  function leapyr(yr)
    
    implicit none
    integer, intent(in) :: yr
    integer :: leapyr
    
    leapyr = nint( cal2jd(yr,3,1.d0) - cal2jd(yr,2,29.d0) )
    
  end function leapyr
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Return JD as date and time in ISO_8601 format (e.g. 2014-03-24T20:48:01+00:00)
  !!
  !! \param jd  Julian day
  !! \param tz  Time zone
  
  function jd2iso8601(jd, tz)
    use SUFR_kinds, only: double
    
    implicit none
    real(double), intent(in) :: jd,tz
    character :: jd2iso8601*(30), tzsign  ! Need 25 for -999 <= year <= 9999
    integer :: dy,yr,mon, hr,mn,se, tzhr,tzmn
    real(double) :: day, time
    
    call jd2cal(jd + tz/24.d0, yr,mon,day)
    dy = floor(day)
    time = (day - dble(dy)) * 24.d0
    call tm2hms(time, hr,mn,se)
    call tm2hm(abs(tz), tzhr,tzmn)
    
    tzsign = '+'
    if(tz.lt.0.d0) tzsign = '-'
    
    write(jd2iso8601,'(I0, 7(A1,I2.2) )') yr,'-',mon,'-',dy,'T',hr,':',mn,':',se, tzsign,tzhr,':',tzmn
    
  end function jd2iso8601
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Convert a Julian day (UT) to a GPS time (seconds since 1980-01-06 - 2000-01-01 = 630720013.0)
  !!
  !! \param jd  Julian day (UT)
  !!
  !! \todo Check leap seconds sicne 2009
  
  function jd2gps(jd)
    use SUFR_kinds, only: double
    
    implicit none
    real(double), intent(in) :: jd
    real(double) :: jd2gps
    
    jd2gps = (jd - 2451544.5d0)*86400.d0 + 630720013.d0
    
    if(jd.lt.2444239.5d0) write(0,*) 'Leap seconds are not taken into account when computing GPS time before 1/1/1980!'
    
    if(jd.lt.2444786.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/7/1981
    if(jd.lt.2445151.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/7/1982
    if(jd.lt.2445516.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/7/1983
    if(jd.lt.2446247.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/7/1985
    if(jd.lt.2447161.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/1/1988
    if(jd.lt.2447892.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/1/1990
    if(jd.lt.2448257.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/1/1991
    if(jd.lt.2448804.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/7/1992
    if(jd.lt.2449169.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/7/1993
    if(jd.lt.2449534.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/7/1994
    if(jd.lt.2450083.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/1/1996
    if(jd.lt.2450630.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/7/1997
    if(jd.lt.2451179.5d0) jd2gps = jd2gps - 1  ! Leap second on 1/1/1999
    if(jd.ge.2453736.5d0) jd2gps = jd2gps + 1  ! Leap second on 1/1/2006
    if(jd.ge.2454832.5d0) jd2gps = jd2gps + 1  ! Leap second on 1/1/2009
    !if(jd.ge..5d0) jd2gps = jd2gps + 1  ! Leap second on 1//19
    
  end function jd2gps
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Convert a Julian day (UT) to Unix time (seconds since 1970-01-01)
  !!
  !! \param jd  Julian day (UT)
  
  function jd2unix(jd)
    use SUFR_kinds, only: double
    
    implicit none
    real(double), intent(in) :: jd
    real(double) :: jd2unix
    
    jd2unix = (jd - 2440587.5d0)*86400  ! jd since 1970-01-01, converted to seconds
    
  end function jd2unix
  !*********************************************************************************************************************************
  
  
  
end module SUFR_date_and_time
!***********************************************************************************************************************************

