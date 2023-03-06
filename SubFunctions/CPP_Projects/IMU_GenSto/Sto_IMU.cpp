/* -------------------------------------------------------------------------- *
 *                            OpenSim:  exampleMOTFileAdapter.cpp             *
 * -------------------------------------------------------------------------- *
 * The OpenSim API is a toolkit for musculoskeletal modeling and simulation.  *
 * See http://opensim.stanford.edu and the NOTICE file for more information.  *
 * OpenSim is developed at Stanford University and supported by the US        *
 * National Institutes of Health (U54 GM072970, R24 HD065690) and by DARPA    *
 * through the Warrior Web program.                                           *
 *                                                                            *
 * Copyright (c) 2005-2017 Stanford University and the Authors                *
 * Authors:                                                                   *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may    *
 * not use this file except in compliance with the License. You may obtain a  *
 * copy of the License at http://www.apache.org/licenses/LICENSE-2.0.         *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 * -------------------------------------------------------------------------- */

#include "OpenSim/Common/Adapters.h"
#include <fstream>
//#include "Simbody.h"
//#include "OpenSim.h"
#include "OpenSim\Common\TimeSeriesTable.h"
#include "OpenSim/Common/FileAdapter.h"

int main() {
    std::string filename{"Template_Quat.sto"};

	// Test if we can read a storage file with quaternions
    OpenSim::STOFileAdapterQuaternion fileadapter{};
    auto table1 = fileadapter.read(filename);

   
	// Test is we can make a vector with quaternions
	int last_size = 1024;
	int n_imus = 2;
	OpenSim::TimeSeriesTableQuaternion::RowVector
		orientation_row_vector{n_imus, SimTK::Quaternion()};

	SimTK::Quaternion quad_Zero(0, 0, 0, 0);
	orientation_row_vector[0] = quad_Zero;
	orientation_row_vector[1] = quad_Zero;

	OpenSim::TimeSeriesTableQuaternion::DataTable_ myTable{};

	std::vector <std::string> ColLabels;
	ColLabels.push_back("0");
	ColLabels.push_back("1");
	myTable.setColumnLabels(ColLabels);
	//myTable.setColumnLabel(0, "testIMUHeader");
	//myTable.setColumnLabel(0, "TestIMU");
	//myTable.setColumnLabel(1, "TestIMU");
	myTable.appendRow(0.00, orientation_row_vector);
	myTable.appendRow(0.25, orientation_row_vector);
	myTable.appendRow(0.5, orientation_row_vector);
	fileadapter.write(myTable, "MyFirstTable.sto");


    return 0;
}
