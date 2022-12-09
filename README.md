# OsimPipeline

These codes are developed to batch process all your data in OpenSim and convert the output files into a .mat structure that can be used in the plotting/reporting app (patientdisplay).
! The codes assume a very specific structure on how the data is stored !
# steps to do: 
Step 1: Save your OpenSim data as follows .../(Project_name)/(subject_name)/... with here all your .trc and .mot files. When working with Vicon, you can use https://github.com/TuurvdHave/ViconSaving 
these codes to help you export the vicon files to OpenSim files. <br>
Step 2: Do all the different steps in OpenSim and save your scaled model in the subject's folder with the following name (..."_Scaled.osim") and save the setup files in .../(Project_name)/GenericSetup/...<br>
		as follows:<br>
			- IK setup: IK_generic.xml<br>
			- ID setup: ID_generic.xml<br>
			- Externalloads file: ExternalLoads.xml<br>
			- SO setup: SO_generic.xml<br>
			- Joint contact forces analyses: JRA_generic.xml<br>
Step 3: Adapt the params.json file with a text editor. The "osim_path" should refer to intallation folder of your OpenSim. The ks3x or the ks4x should refer to the folder containing the kalman smoother (kalman smoother can be found here: https://simtk.org/projects/kalmanforik)
make sure you have the right KS to your OpenSim version. The other lines should be adapted to the information of your project.<br> 
Step 4: run the matlab code Run_all.m <br>
If you are running dynamic optimization (muscle redundancy solver) (make sure the correct OpenSim is linked to your matlab, for other steps this is not needed) and want to adapt this part to your project, 
make sure you check https://github.com/KULeuvenNeuromechanics/MuscleRedundancySolver. Everthing is documented there. <br>
Step 5: Install the reporting app by double clicking on the Patients Display (Matlab App Installer). After installation, you should be able to see the app in matlab in the tab "app"<br>
Step 6: Run the reporting app and import your own data. <br>

 
