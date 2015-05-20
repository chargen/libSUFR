!> \file command_line.f90  Procedures to handle command-line options and arguments


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
!> \brief  Procedures to handle command-line options and arguments

module SUFR_command_line
  implicit none
  save
  
contains
  
  
  !*********************************************************************************************************************************
  !> \brief  Get an integer from the command line
  !! 
  !! \param n        Number of command-line argument (1,2,...)
  !! \retval arg     Value of the argument
  !! \retval status  Exit status: 0: ok, !=0: not ok
  
  subroutine get_command_argument_i(n,arg, status)
    implicit none
    integer, intent(in) :: n
    integer, intent(out) :: arg
    integer, intent(out), optional :: status
    integer :: lstatus
    character :: str*(199)
    
    call get_command_argument(n,str)
    read(str,*, iostat=lstatus) arg
    
    if(present(status)) status = lstatus
    
  end subroutine get_command_argument_i
  !*********************************************************************************************************************************
  
  
  !*********************************************************************************************************************************
  !> \brief  Get a long integer from the command line
  !! 
  !! \param n        Number of command-line argument (1,2,...)
  !! \retval arg     Value of the argument
  !! \retval status  Exit status: 0: ok, !=0: not ok
  
  subroutine get_command_argument_l(n,arg, status)
    use SUFR_kinds, only: long
    implicit none
    integer, intent(in) :: n
    integer(long), intent(out) :: arg
    integer, intent(out), optional :: status
    integer :: lstatus
    character :: str*(199)
    
    call get_command_argument(n,str)
    read(str,*, iostat=lstatus) arg
    
    if(present(status)) status = lstatus
    
  end subroutine get_command_argument_l
  !*********************************************************************************************************************************
  
  
  !*********************************************************************************************************************************
  !> \brief  Get a double-precision real from the command line
  !! 
  !! \param n        Number of command-line argument (1,2,...)
  !! \retval arg     Value of the argument
  !! \retval status  Exit status: 0: ok, !=0: not ok
  
  subroutine get_command_argument_d(n, arg, status)
    use SUFR_kinds, only: double
    implicit none
    integer, intent(in) :: n
    real(double), intent(out) :: arg
    integer, intent(out), optional :: status
    integer :: lstatus
    character :: str*(199)
    
    call get_command_argument(n,str)
    read(str,*, iostat=lstatus) arg
    
    if(present(status)) status = lstatus
    
  end subroutine get_command_argument_d
  !*********************************************************************************************************************************
  
  
  !*********************************************************************************************************************************
  !> \brief  Get a single-precision real from the command line
  !! 
  !! \param n        Number of command-line argument (1,2,...)
  !! \retval arg     Value of the argument
  !! \retval status  Exit status: 0: ok, !=0: not ok
  
  subroutine get_command_argument_r(n,arg, status)
    implicit none
    integer, intent(in) :: n
    real, intent(out) :: arg
    integer, intent(out), optional :: status
    integer :: lstatus
    character :: str*(199)
    
    call get_command_argument(n,str)
    read(str,*, iostat=lstatus) arg
    
    if(present(status)) status = lstatus
    
  end subroutine get_command_argument_r
  !*********************************************************************************************************************************
  
  
end module SUFR_command_line
!***********************************************************************************************************************************

