// Douglas Hill, May 2015

@import Accelerate;
@import Foundation;

/**
 @brief Returns a string representation of a linear algebra matrix or vector.
 @param object The linear algebra matrix or vector.
 @return A string representation of @c object.
 */
NSString *LAObjectDescription(la_object_t object);

/**
 @brief An alternative to @c la_solve to work around a problem discussed in Apple bug report 20428946.
 Unlike @c la_solve, this method correctly handles @c matrix_system being non-square. See https://gist.github.com/douglashill/6da856e9ff06bbe724a2
 @param matrix_system A matrix describing the left-hand side of the system.
 @param obj_rhs       A vector or matrix describing one or more right-hand sides for which the equations are to be solved.
 @return A matrix of the solution(s) of the system of equations.
 */
LA_FUNCTION LA_NONNULL LA_RETURNS_RETAINED
la_object_t dh_la_solve(la_object_t matrix_system, la_object_t obj_rhs);
