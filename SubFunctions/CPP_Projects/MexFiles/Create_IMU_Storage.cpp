#include <OpenSim/OpenSim.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <ctime>  
#include <windows.h>
#include "matrix.h"
#include "mex.h"
using namespace OpenSim;
using namespace SimTK;
using namespace std;

int main()
{

	// Input arguments
	// (1) Filename .sto file
	// (2) nfr
	// (3) nIMU
	// (4) TimeVector
	// (5) Quaternion data
	// (6) Headers

	return 0;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{


	// Read the input information
	//---------------------------

	char *Filename;
	Filename = mxArrayToString(prhs[0]);	
	
	int nfr = (int)*mxGetPr(prhs[1]);

	int nIMU = (int)*mxGetPr(prhs[2]);

	double *time;
	time = mxGetPr(prhs[3]);

	double *Quat;
	Quat = mxGetPr(prhs[4]);

	Array<std::string> Headers;
	char *header;
	for (int c = 0; c <nIMU; c++)
	{
		header = mxArrayToString(mxGetCell(prhs[5], c));
		Headers.append(header);
	}

	// Create the storage file
	OpenSim::TimeSeriesTableQuaternion::RowVector
		Orient_row{nIMU, SimTK::Quaternion() };
	OpenSim::TimeSeriesTableQuaternion::DataTable_ myTable{};

	// Update the table
	SimTK::Quaternion QuadSel(0, 0, 0, 0);
	for (int fr = 0; fr < nfr; fr++)
	{		
		// Update the vector with quaterions
		for (int i = 0; i < nIMU; i++)
		{
			
			for (int qi = 0; qi < 4; qi++)
			{
					int startIMU = i*(nfr * 4);
					int startd = (qi*nfr);
					int index = fr + startIMU + startd;
					QuadSel.set(qi,Quat[index]);
			}
			
			Orient_row[i] = QuadSel;
		}
		myTable.appendRow(time[fr], Orient_row);
	}
	
	// set the column labels
	std::vector <std::string> ColLabels;
	for (int c = 0; c < nIMU; c++)
	{
		ColLabels.push_back(Headers.get(c));
	}
	myTable.setColumnLabels(ColLabels);

	// Save the storage file
	OpenSim::STOFileAdapterQuaternion fileadapter{};
	fileadapter.write(myTable, Filename);

	// Output
	return;
}