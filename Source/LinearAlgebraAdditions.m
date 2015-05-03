// Douglas Hill, May 2015

#import "LinearAlgebraAdditions.h"

NSString *LAObjectDescription(la_object_t object)
{
	la_count_t const cols = la_matrix_cols(object);
	la_count_t const rows = la_matrix_rows(object);
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@; Cols: %ld; Rows: %ld; Status: %ld", [object class], cols, rows, la_status(object)];
	
	double buffer[cols * rows];
	la_status_t const status = la_matrix_to_double_buffer(buffer, cols, object);
	
	if (status != LA_SUCCESS) {
		[description appendFormat:@"\nCould not read values: %ld", status];
		return description;
	}
	
	[description appendString:@"\n"];
	
	for (la_count_t rowIndex = 0; rowIndex < rows; ++rowIndex) {
		for (la_count_t colIndex = 0; colIndex < cols; ++colIndex) {
			[description appendFormat:@"%g ", buffer[rowIndex * cols + colIndex]];
		}
		[description appendString:@"\n"];
	}
	
	[description appendString:@"\n"];
	
	return description;
}

LA_FUNCTION LA_NONNULL LA_AVAILABILITY LA_RETURNS_RETAINED
la_object_t dh_la_solve(la_object_t matrix_system, la_object_t obj_rhs)
{
	NSCAssert(la_matrix_rows(matrix_system) == la_matrix_rows(obj_rhs), @"Dimension mismatch");
	NSCAssert(la_matrix_rows(matrix_system) >= la_matrix_cols(matrix_system), @"Dimension mismatch: not enough observations");
	
	__CLPK_integer m = la_matrix_rows(matrix_system); // Height of A and b, number of observations
	__CLPK_integer n = la_matrix_cols(matrix_system); // Width of A and height of x, number of coefficients
	__CLPK_integer nrhs = la_matrix_cols(obj_rhs);    // Width of b and x
	
	double *Adata = malloc(m * n * sizeof(double));
	la_status_t aReadingStatus = la_matrix_to_double_buffer(Adata, m, la_transpose(matrix_system));
	
	double *bdata = malloc(m * nrhs * sizeof(double));
	la_status_t bReadingStatus = la_matrix_to_double_buffer(bdata, m, la_transpose(obj_rhs));
	
	// Find the least squares solution to the overdetermined linear system Ax = b
	// http://www.netlib.org/lapack/lug/node27.html
	
	char trans = 'n';
	//	__CLPK_integer optimumWorkSize;
	__CLPK_doublereal optimumWorkSizeFloat;
	__CLPK_integer getOptimumWorkSize = -1;
	__CLPK_integer status;
	dgels_(&trans, &m, &n, &nrhs, Adata, &m, bdata, &m, &optimumWorkSizeFloat, &getOptimumWorkSize, &status);
	
	if (status < 0) {
		printf("Could not find optimum workspace size. Status is: %ld\n\n", (long)status);
		return nil;
	}
	
	__CLPK_integer optimumWorkSize = optimumWorkSizeFloat; // This really looks like what you’re supposed to do.
	__CLPK_doublereal *workspace = malloc(optimumWorkSize * sizeof(__CLPK_doublereal));
	dgels_(&trans, &m, &n, &nrhs, Adata, &m, bdata, &m, workspace, &optimumWorkSize, &status);
	free(workspace);
	workspace = NULL;
	
	free(Adata);
	Adata = NULL;
	
	if (status < 0) {
		printf("Could not solve for x. Status is: %ld\n\n", (long)status);
		return nil;
	}
	
	la_object_t X = la_transpose(la_matrix_from_double_buffer(bdata, nrhs, n, m, LA_NO_HINT, LA_ATTRIBUTE_ENABLE_LOGGING));
	
	free(bdata);
	bdata = NULL;
	
	return X;
	
	// TODO: Fix returning early leaking memory
}
