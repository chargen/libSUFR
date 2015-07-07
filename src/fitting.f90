!> \file fitting.f90  Procedures to fit functions to data


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
!> \brief  Procedures to fit functions to data

module SUFR_fitting
  implicit none
  save
  
contains
  
  !*********************************************************************************************************************************
  !> \brief  Fit the model coefficients using a chi^2 method
  !!
  !! Do a chi^2-minimisation fit of ndat data points xdat and ydat, the latter with errors yerr, to function func.  The fit uses
  !! the ncoef coefficients stored in coef() that should be varied if the corresponding entry in varc =1, fixed if =0.
  !!
  !! The fitting function must be provided as the subroutine myFunc which returns a value y = myFunc(x, basefunc, ncoef), where
  !!   y is a linear combination of x, i.e.  y = SUM(i=1,ncoef) coef(i) * basefunc(i)(x).
  !!   For example, for a polynomial, basefunc(i) = x**(i-1).
  !!
  !! The routine returns the fit coefficients in coef(), the variance-covariance matrix in covar sith size ncov, and the chi^2 value
  !!   in chi2.
  !!
  !!
  !! \param  xdat    X values of the data (ndat)
  !! \param  ydat    Y values of the data (ndat)
  !! \param  yerr    Standard deviations of the y values (ndat)
  !! \param  ndat    Number of data points
  !!
  !! \retval coef    Coefficients of the fitting function (ncoef)
  !! \param  varc    Fix coefficient coef(i) if varc(i)=0, otherwise fit it (ncoef)
  !! \param  ncoef   Number of coefficients of the fitting function
  !!
  !! \retval covar   Covariance matrix (ncov,ncov)
  !! \param  ncov    Size of both dimensions of covar()
  !! \retval chi2    Chi^2
  !!
  !! \param  myFunc  External subroutine that describes the model value of Y for given value X
  !!
  !! \note
  !! - Needs sort_var_covar() and solve_linear_equations_Gauss_Jordan()
  !!
  !! \see Numerical Recipes in Fortran 77, Sect.15.4
  !!
  
 subroutine linear_fit_yerr(xdat,ydat,yerr,ndat,  coef,varc,ncoef,  covar,ncov, chi2, myFunc)
    use SUFR_kinds, only: double
    use SUFR_system, only: warn, quit_program_error
    implicit none
    integer, parameter :: mMax = 50
    integer, intent(in) :: ncoef,varc(ncoef),ncov,ndat
    real(double), intent(in) :: xdat(ndat),ydat(ndat), yerr(ndat)
    real(double), intent(inout) :: coef(ncoef)
    real(double), intent(out) :: chi2,covar(ncov,ncov)
    
    integer :: ii,ij,ik,il,im, nfit
    real(double) :: sig2i,tot,wt,ym, basefunc(mMax),beta(mMax)
    external myFunc
    
    if(minval(abs(yerr)).lt.10*tiny(yerr)) call quit_program_error('libSUFR linear_fit_yerr(): errors cannot be zero', 0)
    
    ! Determine number of parameters that need to be fit:
    nfit = 0
    do ij=1,ncoef
       if(varc(ij).ne.0) nfit = nfit+1
    end do
    if(nfit.eq.0) call warn('libSUFR linear_fit_yerr():  No parameters to be fit for', 0)
    
    covar(1:nfit,1:nfit) = 0.d0
    beta(1:nfit) = 0.d0
    
    do ii=1,ndat
       call myFunc(xdat(ii),ncoef, basefunc)
       ym = ydat(ii)
       if(nfit.lt.ncoef) then
          do ij=1,ncoef
             if(varc(ij).eq.0) ym = ym-coef(ij)*basefunc(ij)
          end do
       end if
       sig2i = 1.d0/yerr(ii)**2
       
       ij = 0
       do il=1,ncoef
          if(varc(il).ne.0) then
             ij = ij+1
             wt = basefunc(il)*sig2i
             
             ik = 0
             do im=1,il
                if(varc(im).ne.0) then
                   ik = ik+1
                   covar(ij,ik) = covar(ij,ik)+wt*basefunc(im)
                end if
             end do
             beta(ij) = beta(ij)+ym*wt
          end if
       end do
    end do
    
    do ij=2,nfit
       do ik=1,ij-1
          covar(ik,ij) = covar(ij,ik)
       end do
    end do
    
    ! Solve the linear algebraic equations using Gauss-Jordan elimination:
    call solve_linear_equations_Gauss_Jordan(covar,nfit,ncov, beta,1,1)
    
    ij = 0
    do il=1,ncoef
       if(varc(il).ne.0) then
          ij = ij+1
          coef(il) = beta(ij)
       end if
    end do
    
    chi2 = 0.d0
    do ii=1,ndat
       call myFunc(xdat(ii),ncoef, basefunc)
       
       tot = sum(coef(1:ncoef)*basefunc(1:ncoef))
       chi2 = chi2  +  ( (ydat(ii)-tot) / yerr(ii) )**2
    end do
    
    ! Sort the resulting variance-covariance matrix:
    call sort_var_covar(covar,ncov,ncoef,varc,nfit)
    
  end subroutine linear_fit_yerr
  !*********************************************************************************************************************************
  
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Levenberg-Marquardt method to reduce the value of chi-squared of a fit of a set of data points with errors in Y to a
  !!         non-linear function
  !!
  !! \param xDat     X data points to fit
  !! \param yDat     Y data points to fit
  !! \param ySig     Standard deviations for yDat
  !! \param nDat     Number of data points in X and Y
  !!
  !! \param fCoef    Coefficients for the non-linear function myFunc, updated after each call
  !! \param iCoef    Determines which coefficients for the non-linear function myFunc should be fitted for.  Set iCoef(i) = 0 in 
  !!                   order to keep fCoef(i) fixed
  !! \param nCoef    Number of coefficients used to describe the non-linear function myFunc
  !!
  !! \param covar    Variance-covariance matrix - returned on last call with lambda.  Fixed parameters return zero (co)variances
  !! \param curvMat  Hessian/curvature matrix - double partial derivative of chi squared to two coefficients fCoef
  !! \param nMat     Size of the matrices; > nCoef
  !!
  !! \param chiSq    Chi squared
  !! \param lambda   Set to <0 for initialisation in the first call.  Set to ==0 to return the variance-covariance and curvature
  !!                   matrices on the last call.  Lambda decreases 10x if chiSq becomes smaller, and increases 10x otherwise.
  !! \param myFunc   External subroutine that describes the model value of Y and partial derivatives dY/dXi for given value X and
  !!                   function coefficients fCoef
  !!
  !!
  !! \see  Numerical Recipes in Fortran, 15.5: Modelling of Data / Non-linear models
  !! 
  !! \note  Uses sort_var_covar(), solve_linear_equations_Gauss_Jordan() and nonlin_fit_eval()
  
  subroutine nonlin_fit_yerr(xDat,yDat, ySig, nDat, fCoef,iCoef,nCoef, covar, curvMat, nMat, chiSq, lambda, myFunc)
    use SUFR_kinds, only: double
    use SUFR_numerics, only: deq0
    
    implicit none
    integer, intent(in) :: nCoef,nMat,nDat,iCoef(nCoef)
    real(double), intent(in) :: ySig(nDat), xDat(nDat), yDat(nDat)
    real(double), intent(inout) :: fCoef(nCoef), lambda
    real(double), intent(out) :: curvMat(nMat,nMat), covar(nMat,nMat), chiSq
    
    integer, parameter :: mMax = 20
    integer :: j,k,l,mFit
    real(double) :: oChiSq,tryCoef(mMax),dChiSq(mMax),dfCoef(mMax)
    
    save oChiSq,tryCoef,dChiSq,dfCoef,mFit
    external myFunc
    
    if(.false.) call myFunc()  ! An EXTERNAL subroutine must be CALLed
    
    ! Initialisation on the first call:
    if(lambda.lt.0.d0) then
       mFit = 0
       do j=1,nCoef
          if(iCoef(j).ne.0) mFit = mFit + 1
       end do
       
       lambda = 0.001d0
       
       ! Evaluate the linearized curvature matrix and vector dChiSq/dfCoef, and compute chi squared:
       call nonlin_fit_eval(xDat,yDat, ySig, nDat, fCoef,iCoef,nCoef, curvMat,dChiSq, nMat, chiSq, myFunc)
       
       oChiSq = chiSq
       do j=1,nCoef
          tryCoef(j) = fCoef(j)
       end do
    end if
    
    
    ! Augment the diagonal elements of the variance-covariance matrix:
    do j=1,mFit
       do k=1,mFit
          covar(j,k) = curvMat(j,k)
       end do
       
       covar(j,j) = curvMat(j,j) * (1.d0+lambda)
       dfCoef(j)  = dChiSq(j)
    end do
    
    
    ! Solve the linear algebraic equations using Gauss-Jordan elimination:
    call solve_linear_equations_Gauss_Jordan(covar,mFit,nMat,dfCoef,1,1)
    
    
    ! Compute the variance-covariance and curvature matrices on the last call, and return:
    if(deq0(lambda)) then
       call sort_var_covar(covar,  nMat, nCoef,iCoef, mFit)
       call sort_var_covar(curvMat,nMat, nCoef,iCoef, mFit)
       return
    end if
    
    
    ! Update the trial coefficients:
    j = 0
    do l=1,nCoef
       if(iCoef(l).ne.0) then
          j = j+1
          tryCoef(l) = fCoef(l) + dfCoef(j)
       end if
    end do
    
    
    ! Evaluate the linearized curvature matrix and vector dChiSq/dfCoef, and compute chi squared:
    call nonlin_fit_eval(xDat,yDat, ySig, nDat, tryCoef,iCoef,nCoef, covar, dfCoef,nMat, chiSq, myFunc)
    
    
    ! If the new chi squared is better (smaller) than the old value, accept this solution and decrease lambda...
    if(chiSq.lt.oChiSq) then
       lambda = 0.1d0*lambda
       oChiSq = chiSq
       do j=1,mFit
          do k=1,mFit
             curvMat(j,k) = covar(j,k)
          end do
          dChiSq(j) = dfCoef(j)
       end do
       
       do l=1,nCoef
          fCoef(l) = tryCoef(l)
       end do
       
    else                                          !  ...otherwise keep the old chi squared and increase lambda:
       
       lambda = 10*lambda
       chiSq = oChiSq
       
    end if
    
  end subroutine nonlin_fit_yerr
  !*********************************************************************************************************************************
  
  
  !*********************************************************************************************************************************
  !> \brief  Evaluate the linearized fitting matrix curvMat, and vector dChiSq, and calculate the chi squared (chiSq)
  !!
  !! \param xDat     X data points to fit
  !! \param yDat     Y data points to fit
  !! \param ySig     Standard deviations for yDat
  !! \param nDat     Number of data points in X and Y
  !!
  !! \param fCoef    Coefficients for the non-linear function myFunc, updated after each call
  !! \param iCoef    Determines which coefficients for the non-linear function myFunc should be fitted for.  Set iCoef(i) = 0 in 
  !!                   order to keep fCoef(i) fixed
  !! \param nCoef    Number of coefficients used to describe the non-linear function myFunc
  !!
  !! \param curvMat  Hessian/curvature matrix - double partial derivative of chi squared to two coefficients fCoef
  !! \param dChiSq   Vector containing the partial derivatives of chiSq to each coefficient in fCoef
  !! \param nMat     Size of the matrices; > nCoef
  !!
  !! \param chiSq    Chi squared
  !! \param myFunc   External subroutine that describes the model value of Y and partial derivatives dY/dXi for given value X and
  !!                   function coefficients fCoef
  !!
  !!
  !! \see  Numerical Recipes in Fortran, 15.5: Modelling of Data / Non-linear models
  
  subroutine nonlin_fit_eval(xDat,yDat, ySig, nDat, fCoef,iCoef,nCoef, curvMat,dChiSq, nMat, chiSq, myFunc)
    use SUFR_kinds, only: double
    implicit none
    integer, intent(in) :: nCoef,nMat,nDat,iCoef(nCoef)
    real(double), intent(in) :: xDat(nDat),yDat(nDat),ySig(nDat), fCoef(nCoef)
    real(double), intent(out) :: chiSq,curvMat(nMat,nMat),dChiSq(nCoef)
    
    integer, parameter :: mMax = 20
    integer :: mFit,i,j,k,l,m
    real(double) :: dy,sig2i,wt,ymod,dyda(mMax)
    external myFunc
    
    
    ! Determine the number of non-fixed parameters:
    mFit = 0
    do j=1,nCoef
       if(iCoef(j).ne.0) mFit = mFit + 1
    end do
    
    
    ! Initialise the curvature matrix and chiSq-derivative vector:
    do j=1,mFit
       do k=1,j
          curvMat(j,k) = 0.d0
       end do
       dChiSq(j) = 0.d0
    end do
    
    
    ! Sum over all data points:
    chiSq = 0.d0
    do i=1,nDat
       call myFunc(xDat(i), fCoef, ymod, dyda, nCoef)
       
       sig2i = 1.d0/(ySig(i)**2)  ! 1/sigma^2
       dy = yDat(i) - ymod
       
       j = 0
       do l=1,nCoef
          if(iCoef(l).ne.0) then
             j = j+1
             wt = dyda(l)*sig2i
             k = 0
             
             do m=1,l
                if(iCoef(m).ne.0) then
                   k = k+1
                   curvMat(j,k) = curvMat(j,k) + wt*dyda(m)
                end if
             end do
             
             dChiSq(j) = dChiSq(j) + dy*wt
          end if
       end do
       
       chiSq = chiSq + dy**2 * sig2i  ! Compute chi squared
    end do
    
    
    ! Fill in the symmetric side of the curvature matrix:
    do j=2,mFit
       do k=1,j-1
          curvMat(k,j) = curvMat(j,k)
       end do
    end do
    
  end subroutine nonlin_fit_eval
  !*********************************************************************************************************************************
  
  !*********************************************************************************************************************************
  !> \brief  Example function of nonlin_fit_yerr() from Numerical Recipes: return the value and partial derivatives
  !!
  !! \param Ncg    Number of coefficients (3) * number of Gaussians
  !! \param xDat   Input X values for the data points
  !! \param fCoef  Vector of coefficients that describe the function.  Here: 1: B_k, 2: E_k, 3: G_k
  !!
  !! \retval yDat  Y values for the data points
  !! \retval dyda  Partial derivatives for yDat:  1: dy/dB_k, 2: dy/dE_k, 3: dy/dG_k
  !!
  !! \note
  !! - This example represents the sum of a number of K=Ncg/3 Gaussians, described by the function:
  !!     y(x)  =  Sum_k=1,K  B_k  exp[ - ( (x-E_k)/G_k )^2 ],
  !!     where B_k is the height, E_k the centre and G_k the width of the k-th Gaussian.
  !!
  !! \see  Numerical Recipes in Fortran, 15.5: Modelling of Data / Non-linear models
  
  subroutine nonlin_fit_eval_ex_Gauss(Ncg, xDat,fCoef,  yDat,dyda)
    use SUFR_kinds, only: double
    
    implicit none
    integer, intent(in) :: Ncg
    real(double), intent(in) :: xDat,fCoef(Ncg)
    real(double), intent(out) :: yDat,dyda(Ncg)
    
    integer :: k
    real(double) :: arg,ex,fac
    
    
    yDat = 0.d0
    do k=1,Ncg-1,3
       arg = (xDat - fCoef(k+1)) / fCoef(k+2)  ! (x-E_k)/G_k
       ex  = exp(-arg**2)                      ! exp[ - ( (x-E_k)/G_k )^2 ]
       fac = fCoef(k) * ex * 2 * arg           ! 2 * B_k * exp[ - ( (x-E_k)/G_k )^2 ] * (x-E_k)/G_k
       
       yDat      = yDat + fCoef(k)*ex          ! y = y  +  B_k * exp[ - ( (x-E_k)/G_k )^2 ]  - add up the different Gaussians
       
       dyda(k)   = ex                          ! dy/dB = exp[]
       dyda(k+1) = fac / fCoef(k+2)            ! dy/dE = 2 * B_k * exp[ - ( (x-E_k)/G_k )^2 ] * (x-E_k)/G_k^2
       dyda(k+2) = fac * arg / fCoef(k+2)      ! dy/dG = 2 * B_k * exp[ - ( (x-E_k)/G_k )^2 ] * (x-E_k)^2/G_k^3
    end do
    
  end subroutine nonlin_fit_eval_ex_Gauss
  !*********************************************************************************************************************************
  
  
  !*********************************************************************************************************************************
  !> \brief  Sort covariance matrix returned by linear_fit_yerr() to true order of fitting coefficients
  !!
  !! \param  covar  Covariance matrix
  !! \param  ncov   Size of both dimensions of covar()
  !! \param  ncoef  Number of coefficients of the fitting function
  !! \param  varc   Fix coefficient coef(i) if varc(i)=0, otherwise fit for it
  !! \param  nfit   Number of parameters that need to be fit for
  !!
  !! \see Numerical Recipes in Fortran 77, Sect.15.4
  !!
  
  subroutine sort_var_covar(covar,ncov,ncoef,varc,nfit)
    use SUFR_kinds, only: double
    use SUFR_system, only: swapdbl
    
    implicit none
    integer, intent(in) :: ncov,ncoef, varc(ncoef),nfit
    real(double), intent(inout) :: covar(ncov,ncov)
    
    integer :: ii,ij,ik
    
    do ii=nfit+1,ncoef
       do ij=1,ii
          covar(ii,ij) = 0.d0
          covar(ij,ii) = 0.d0
       end do
    end do
    
    ik = nfit
    
    do ij=ncoef,1,-1
       if(varc(ij).ne.0) then
          do ii=1,ncoef
             call swapdbl(covar(ii,ij), covar(ii,ik))  ! Swap the two numbers
          end do
          
          do ii=1,ncoef
             call swapdbl(covar(ij,ii), covar(ik,ii))  ! Swap the two numbers
          end do
          
          ik = ik-1
       end if
    end do
    
  end subroutine sort_var_covar
  !*********************************************************************************************************************************
  
  
  
  !*********************************************************************************************************************************
  !> \brief  Solve a set of linear algebraic equations using Gauss-Jordan elimination.
  !!
  !! \param matArr   Input: array containing the matrix to be inverted - output: array containing the inverted matrix  (I/O)
  !! \param Nmat     Dimension of the equation set
  !! \param NmatArr  Physical dimensions of the array matArr  (NmatArr x NmatArr)
  !!
  !! \param vecArr   Input: array containing Nvec right-hand side vectors - output: solution vectors  (I/O)
  !! \param Nvec     Number of vectors in vecArr
  !! \param NvecArr  One of the physical dimensions of the array vecArr  (NmatArr x NvecArr)
  !!
  !! \see Numerical Recipes in Fortran 77, Sect.2.1
  !!
  
  subroutine solve_linear_equations_Gauss_Jordan(matArr,Nmat,NmatArr, vecArr,Nvec,NvecArr)
    use SUFR_kinds, only: double
    use SUFR_system, only: warn, swapdbl
    
    implicit none
    integer, intent(in) :: Nmat,NmatArr, Nvec,NvecArr
    real(double), intent(inout) :: matArr(NmatArr,NmatArr),vecArr(NmatArr,NvecArr)
    
    integer, parameter :: Nmax = 50  ! Maximum allowed value for Nmat
    integer :: ii,icol,irow,ij,ik,il,ll,indxc(Nmax),indxr(Nmax),ipiv(Nmax)
    real(double) :: arrmax,tmpdbl,pivinv
    
    
    icol = 0
    irow = 0
    ipiv(1:Nmat) = 0
    
    
    do ii=1,Nmat
       ! Find maximum array value:
       arrmax = 0.d0
       do ij=1,Nmat
          if(ipiv(ij).ne.1) then
             do ik=1,Nmat
                if(ipiv(ik).eq.0) then
                   if(abs(matArr(ij,ik)).ge.arrmax) then
                      arrmax = abs(matArr(ij,ik))
                      irow = ij
                      icol = ik
                   end if
                else if(ipiv(ik).gt.1) then
                   call warn('libSUFR solve_linear_equations_Gauss_Jordan():  singular matrix',0)
                end if
             end do
          end if
       end do
       
       ipiv(icol) = ipiv(icol) + 1
       
       if(irow.ne.icol) then
          do il=1,Nmat
             call swapdbl(matArr(irow,il), matArr(icol,il))
          end do
          
          do il=1,Nvec
             call swapdbl(vecArr(irow,il), vecArr(icol,il))
          end do
       end if
       
       indxr(ii) = irow
       indxc(ii) = icol
       
       if(abs(matArr(icol,icol)).lt.10*tiny(matArr)) call warn('libSUFR solve_linear_equations_Gauss_Jordan():  singular matrix', 0)
       
       pivinv = 1.d0/matArr(icol,icol)
       matArr(icol,icol) = 1.d0
       
       matArr(icol,1:Nmat) = matArr(icol,1:Nmat)*pivinv
       vecArr(icol,1:Nvec) = vecArr(icol,1:Nvec)*pivinv
       
       do ll=1,Nmat
          if(ll.ne.icol) then
             tmpdbl = matArr(ll,icol)
             matArr(ll,icol) = 0.d0
             matArr(ll,1:Nmat) = matArr(ll,1:Nmat) - matArr(icol,1:Nmat)*tmpdbl
             vecArr(ll,1:Nvec) = vecArr(ll,1:Nvec) - vecArr(icol,1:Nvec)*tmpdbl
          end if
       end do
    end do
    
    do il=Nmat,1,-1
       if(indxr(il).ne.indxc(il)) then
          do ik=1,Nmat
             call swapdbl(matArr(ik,indxr(il)), matArr(ik,indxc(il)))
          end do
       end if
    end do
    
  end subroutine solve_linear_equations_Gauss_Jordan
  !*********************************************************************************************************************************
  
  
  
  
  !*********************************************************************************************************************************
  !> \brief  User-provided base function to fit a polynomial to
  !!
  !! \param  xval      X value to evaluate yval = basefunc_polynimial(xval) for
  !! \param  ncoef     Number of coefficients for the base function
  !!
  !! \retval basefunc  Base function i for coefficent i.  For a polynomial, BF(i) = x**(i-1)
  
  subroutine basefunc_polynomial(xval,ncoef, basefunc)
    use SUFR_kinds, only: double
    implicit none
    integer, intent(in) :: ncoef
    real(double), intent(in) :: xval
    real(double), intent(out) :: basefunc(ncoef)
    
    integer :: coefi
    
    basefunc(1) = 1.d0
    do coefi = 2,ncoef
       basefunc(coefi) = basefunc(coefi-1) * xval
    end do
    
  end subroutine basefunc_polynomial
  !*********************************************************************************************************************************
  
  
  
  
end module SUFR_fitting
!***********************************************************************************************************************************

