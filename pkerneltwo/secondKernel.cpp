#include <math.h>
#include <matrix.h>
#include <mex.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "SW.h"

void mexFunction(int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[])
{
    
    const mwSize *dims;
    const mxArray *cell; //the input cell
    double *outputMatrixPr; // the pointer to the output matrix (the Kernel Matrix)
    
    mxArray *outputMatrix;
    const mwSize *dimArray, *dimArray2;
    mwSize dimsMatrix[2];
    
    //associate inputs
    cell = prhs[0]; //first input is our cell variable
    
    
    const bool exactOrAprox = *mxGetPr(prhs[1]);
    const int aproxN = *mxGetPr(prhs[2]);
    
    //get dimensions of input cell
    dims = mxGetDimensions(prhs[0]); //get the number of dimensions in the variable
    dimsMatrix[0] = dims[1];
    dimsMatrix[1] = dims[1];
    
    //associate outputs
    outputMatrix = plhs[0] = mxCreateNumericArray(2, dimsMatrix, mxDOUBLE_CLASS, mxREAL); //generate a square matrix for output
    
    //associate pointers
    outputMatrixPr = mxGetPr(outputMatrix);
    
    for (size_t jcell=0; jcell<dims[1]; jcell++) { //loop the 2nd dimensions (the columns)
        mxArray * cellElement = mxGetCell(cell,jcell); //get a cell element
        double* p = mxGetPr(cellElement);            //get the Pointer to the cell element
        size_t number_of_dims = mxGetNumberOfDimensions(cellElement); //get the number of dimensions for the current cell entry (matrix)
        dimArray = mxGetDimensions(cellElement); //get the dimensions
        
        //loop the rows
        for (size_t kcell=jcell+1; kcell<dims[1]; kcell++) { //loop the 2nd dimensions (the columns), ignore the first one
            mxArray * cellElement2 = mxGetCell(cell,kcell); //get a cell element
            double* p2 = mxGetPr(cellElement2);            //get the Pointer to the cell element
            
            //get dimensions of second current element
            size_t number_of_dims2 = mxGetNumberOfDimensions(cellElement2); //get the number of dimensions for the current cell entry (matrix)
            dimArray2 = mxGetDimensions(cellElement2); //get the dimensions
                    
            PD pd1(dimArray[0]);
            PD pd2(dimArray2[0]);
            
            for (size_t a=0; a<dimArray[0]; a++) {
                double x=p[a];
                double y=p[a+dimArray[0]];
                pd1[a] = std::make_pair(x, y);                
            }
            for (size_t b=0; b<dimArray2[0]; b++) {
                double x2=p2[b];
                double y2=p2[b+dimArray2[0]];
                pd2[b] = std::make_pair(x2, y2);                
            }   

            using Gudhi::sliced_wasserstein::compute_approximate_SW;
            using Gudhi::sliced_wasserstein::compute_exact_SW;
            outputMatrixPr[jcell*dims[1]+kcell] = exactOrAprox ? compute_exact_SW(pd1, pd2) : compute_approximate_SW(pd1, pd2, aproxN);
        }
                
    }
    
}
