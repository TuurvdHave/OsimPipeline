# OsimPipeline

These codes are developed to batch process all your data in OpenSim and convert the output files into a .mat structure that can be used in the plotting/reporting app (patientdisplay).<br>
! The codes assume a very specific structure on how the data is stored !<br>
This code can handle both, .trc and .mot-files but also .MVNX files (output files when measuring with the Xsens). Data should be structured similarly as described. <br>
# steps to do: 
Step 1: Save your OpenSim data as follows .../(Project_name)/(subject_name)/... with here all your .trc and .mot files. When working with Vicon, you can use https://github.com/TuurvdHave/ViconSaving 
these codes to help you export the vicon files to OpenSim files. <br>
<br><br>
<b> when working with .trc and .mot-files </b> <br>
Step 2: Do all the different steps in OpenSim and save your scaled model in the subject's folder with the following name (..."_Scaled.osim") and save the setup files in .../(Project_name)/GenericSetup/...<br>
		as follows:<br>
			- IK setup: IK_generic.xml<br>
			- ID setup: ID_generic.xml<br>
			- Externalloads file: ExternalLoads.xml<br>
			- SO setup: SO_generic.xml<br>
			- Joint contact forces analyses: JRA_generic.xml<br>
<br><br>
<b> when working with .MVNX-files </b> <br>		
Step 2: The model will be scaled based on the height and the weight of the subject which will be asked after running the code Run_all.m. Thereafter, there are two different ways to do the imu-to-segment calibration. 
1) using the static calibration as described in detail here: https://simtk-confluence.stanford.edu:8443/display/OpenSim/OpenSense+-+Kinematics+with+IMU+Data. The code will look for a .mnvx-file that is named "static" to automatically calibrate the model. 
2) using the dynamic calibration procedure described in Di Raimondo et al. https://www.mdpi.com/1424-8220/22/9/3259. The code will look for two .mvnx-files. One should be named "squat" and one should be called "hipfront"
<br><br>

<b> Next steps are again similar for both files </b> <br>	
Step 3: Adapt the params.json file with a text editor. The "osim_path" should refer to intallation folder of your OpenSim. The ks3x or the ks4x should refer to the folder containing the kalman smoother (kalman smoother can be found here: https://simtk.org/projects/kalmanforik)
make sure you have the right KS to your OpenSim version. The other lines should be adapted to the information of your project.<br> 
Step 4: run the matlab code Run_all.m <br>
If you are running dynamic optimization (muscle redundancy solver) (make sure the correct OpenSim is linked to your matlab, for other steps this is not needed) and want to adapt this part to your project, 
make sure you check https://github.com/KULeuvenNeuromechanics/MuscleRedundancySolver. Everthing is documented there. <br>
Step 5: Install the reporting app by double clicking on the Patients Display (Matlab App Installer). After installation, you should be able to see the app in matlab in the tab "app"<br>
Step 6: Run the reporting app and import your own data. <br>
<br><br>
# small remarks:
The DO is genericly only analyzing these DoF 'ankle_angle_l','knee_angle_l','hip_flexion_l','hip_adduction_l','hip_rotation_l'. This can be adapted in the code to fit your project.<br>
The names of the reserve actuators are the DoF names without _reserve (in common practice it is DoF_reserve). Changing the reserve actuators name could result in problems in DO as this code looks in the results from the SO and replaces the SO-results with the DO-results.<br>

 
