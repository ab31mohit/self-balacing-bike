## Copyright (C) 1994-2011 John W. Eaton
##
## This file is part of Octave.
##
## Octave is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {Function File} {} null (@var{A})
## @deftypefnx {Function File} {} null (@var{A}, @var{tol})
## Return an orthonormal basis of the null space of @var{A}.
##
## The dimension of the null space is taken as the number of singular
## values of @var{A} not greater than @var{tol}.  If the argument @var{tol}
## is missing, it is computed as
##
## @example
## max (size (@var{A})) * max (svd (@var{A})) * eps
## @end example
## @seealso{orth}
## @end deftypefn

## Author: KH <Kurt.Hornik@wu-wien.ac.at>
## Created: 24 December 1993.
## Adapted-By: jwe
## Adapted-By: Olaf Till <i7tiol@t-online.de>

## This function has also been submitted to Octave (bug #33503).

function retval = __null_optim__ (A, tol)

  if (isempty (A))
    retval = [];
  else
    [U, S, V] = svd (A);

    [rows, cols] = size (A);

    [S_nr, S_nc] = size (S);

    if (S_nr == 1 || S_nc == 1)
      s = S(1);
    else
      s = diag (S);
    endif

    if (nargin == 1)
      if (isa (A, "single"))
        tol = max (size (A)) * s (1) * (meps = eps ("single"));
      else
        tol = max (size (A)) * s (1) * (meps = eps);
      endif
    elseif (nargin != 2)
      print_usage ();
    endif

    rank = sum (s > tol);

    if (rank < cols)
      retval = V (:, rank+1:cols);

      if (rows >= cols)
        cb = columns (retval);

        if (cb > 1)

          ## For multidimensional null spaces LAPACK seems to return
          ## very large error angles (> pi/2) for the basis vectors, so
          ## we cannot use these angles to determine which elements of
          ## the basis vectors could be zero. In some of such cases
          ## LAPACK seems to set elements "meant" to be zero exactly to
          ## zero in the basis vectors, so we don't need to do anything.
          ## In the other cases, we can't do anything.

        else

          ## Set those elements of each vector to zero whose absolute
          ## values are smallest and which together could be zero
          ## without making the angle to the originally computed vector
          ## larger than given by the error bound. Do this in an
          ## approximative but numerically feasible way.

          ## The following code still treats the multidimensional case
          ## though it currently doesn't arrive here.

          ## error bounds of basis vectors in radians, see LAPACK user
          ## guide, http://www.netlib.org/lapack/lug/node96.html
	  if (true)  # test for Octave version once submitted patch is
                                # applied to Octave (bug #33503)
	    __disna__ = @ __disna_optim__;
	  endif
          ## This deviates from the LAPACK reference by the factor "2 *
          ## max(size(A))". This deviation is chosen because the results
          ## in setting elements to zero are better so. ("tol" used
          ## above for the rank test also seems to deviate from LAPACK
          ## reference, by factor "max(size(A))".
          ebnd = 2 * tol ./ (__disna__ ("R", s, rows, cols)(rank+1:cols));

          ## sort elements by magnitude
          sb = conj (retval) .* retval;
          [sb, idx] = sort (sb);
          idx += repmat (0:cols:cols*(cb-1), cols, 1); # for un-sorting

          ## norms of vectors made by all elements up to this
          sb = sqrt (cumsum (sb));

          ## The norm of the vectors made up by elements settable to
          ## zero is small enough to be approximately equal to the angle
          ## between the full vectors before and after setting these
          ## elements to zero (considering the norms of the full vectors
          ## being 1). Index of approximated angles not exceeding error
          ## bound.
          zidx = sb <= repmat (ebnd.', cols, 1);

          ## set indexed elements to zero in original basis
          retval(idx(zidx)) = 0;

        endif

      else
        ## no error bounds computable with LAPACK

        ## this is from original null.m
        retval(abs (retval) < meps) = 0;
      endif
    else
        retval = zeros (cols, 0);
    endif
  endif

endfunction
