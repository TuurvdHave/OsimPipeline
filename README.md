# OsimPipeline

These codes are developed to batch process all your data in OpenSim and convert the output files into a .mat structure that can be used in the plotting/reporting app (patientdisplay).
! The codes assume a very specific structure on how the data is stored !
# steps to do: 
Step 1: Save your OpenSim data as follows .../(Project_name)/(subject_name)/... with here all your .trc and .mot files. When working with Vicon, you can use https://github.com/TuurvdHave/ViconSaving 
these codes to help you export the vicon files to OpenSim files. 
Step 2: Do all the different steps in OpenSim and save your scaled model in the subject's folder with the following name (..."_Scaled.osim") and save the setup files in .../(Project_name)/GenericSetup/...
		as follows:
			- IK setup: IK_generic.xml
			- ID setup: ID_generic.xml
			- Externalloads file: ExternalLoads.xml
			- SO setup: SO_generic.xml
			- Joint contact forces analyses: JRA_generic.xml
Step 3: run the matlab code Run_all.m 
Step 4: Install the reporting app by double clicking on the Patients Display (Matlab App Installer). After installation, you should be able to see the app in matlab in the tab "app"
Step 5: Run the reporting app and import your own data. 

 
