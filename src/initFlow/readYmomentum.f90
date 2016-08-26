       subroutine readYmomentum(nTypeMismatch)
!
!       readYmomentum reads the y-momentum variable from the given     
!       place in the cgns file. If the y-momentum itself is not stored 
!       then it is tried to construct it from the y-velocity and       
!       density; it is assumed that the latter is already stored in    
!       the pointer variable w.                                        
!       If it is not possible to create the y-velocity an error        
!       message is printed and the program will stop.                  
!       It is assumed that the pointers in blockPointers already       
!       point to the correct block.                                    
!
       use constants
       use cgnsNames
       use blockPointers, only : w, nbklocal
       use IOModule, only : IOVar
       use restartMod, only : nVar, solID, buffer, varNames, rhoScale, &
            velScale, varTypes
       use utils, only : setCGNSRealType, terminate
       use sorting, only : bsearchStrings
       implicit none
!
!      Subroutine argument.
!
       integer(kind=intType), intent(inout) :: nTypeMismatch
!
!      Local variables
!
       integer :: realTypeCGNS

       integer(kind=intType) :: i, j, k, nn, mm, po, ip, jp, kp
       integer(kind=intType) :: iBeg, iEnd, jBeg, jEnd, kBeg, kEnd

       real(kind=realType) :: momScale

       ! Set the cell range to be copied from the buffer.

       iBeg = lbound(buffer,1); iEnd = ubound(buffer,1)
       jBeg = lbound(buffer,2); jEnd = ubound(buffer,2)
       kBeg = lbound(buffer,3); kEnd = ubound(buffer,3)

       ! Compute the momentum scaling factor, set the cgns real type and
       ! abbreviate the solution variable and the pointer offset to
       ! improve readability.

       momScale     = rhoScale*velScale
       realTypeCGNS = setCGNSRealType()

       po = IOVar(nbkLocal,solID)%pointerOffset
       w => IOVar(nbkLocal,solID)%w

       ! Find out if the Y-momentum is present in the solution file.

       mm = nVar
       nn = bsearchStrings(cgnsMomY, varNames, mm)

       testMyPresent: if(nn > 0) then

         ! Y-momentum is present. First determine whether or not a type
         ! mismatch occurs. If so, update nTypeMismatch.

         if(realTypeCGNS /= varTypes(nn)) &
           nTypeMismatch = nTypeMismatch + 1

         ! Read the y-momentum from the restart file and store it in buffer.

         call readRestartVariable(varNames(nn))

         ! Copy the variables from buffer into w. Multiply by the scale
         ! factor to obtain the correct non-dimensional value and take
         ! the possible pointer offset into account.

         do k=kBeg,kEnd
           kp = k+po
           do j=jBeg,jEnd
             jp = j+po
             do i=iBeg,iEnd
               ip = i+po
               w(ip,jp,kp,imy) = buffer(i,j,k)*momScale
             enddo
           enddo
         enddo

         ! Y-momentum is read, so a return can be made.

         return

       endif testMyPresent

       ! Y-momentum is not present. Check for y-velocity.

       nn = bsearchStrings(cgnsVelY, varNames, mm)

       testVyPresent: if(nn > 0) then

         ! Y-velocity is present. First determine whether or not a type
         ! mismatch occurs. If so, update nTypeMismatch.

         if(realTypeCGNS /= varTypes(nn)) &
           nTypeMismatch = nTypeMismatch + 1

         ! Read the y-velocity from the restart file and store it in buffer.

         call readRestartVariable(varNames(nn))

         ! Copy the variables from buffer into w. Multiply by the
         ! density and velocity scaling factor to obtain to correct
         ! non-dimensional value. Take the possible pointer offset
         ! into account.

         do k=kBeg,kEnd
           kp = k+po
           do j=jBeg,jEnd
             jp = j+po
             do i=iBeg,iEnd
               ip = i+po
               w(ip,jp,kp,imy) = buffer(i,j,k)*w(ip,jp,kp,irho)*velScale
             enddo
           enddo
         enddo

         ! Y-momentum is constructed, so a return can be made.

         return

       endif testVyPresent

       ! Y-momentum could not be created. Terminate.

       call terminate("readYmomentum", &
                      "Y-Momentum could not be created")

       end subroutine readYmomentum
