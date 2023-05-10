function IMU_Placer(params,subject,mainpath)
%% IMU Placer - OpenSense Standard
% Syntax: IMU_Placer(params,input_file,subject,mainpath)
%
% Inputs:
%   params - a JSON file containing parameters for IK setup
%   input_file - the name of the static mat file
%   subject - the name of the subject to process
%   mainpath - the path to the main directory containing all files
%
% Outputs:
%   None
%
% Example usage: IK('params.json', 'motioncapture.trc', 'subject1', '/path/to/files')

% Add required directories to the MATLAB path
addpath(genpath(fullfile(cd,'GenericSetup')))
addpath(genpath(fullfile(cd,'SubFunctions')))

% Load the parameters file (in JSON format)
fid = fopen(params); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
data = jsondecode(str);


% Set up paths for input and output files
main_path       = mainpath; 
OpenSim_path    = data.osim_path; 
Generic_files   = [mainpath,'\GenericSetup'];
Subject         = char(subject); 
path_input      = fullfile(main_path,Subject); 
path_output     = fullfile(main_path,Subject,'Opensim'); 

%% IMU Placer - OpenSense Standard
%-------------------
setupplacer = fullfile(path_output,'Setup_IMU_Placer');
if ~exist(setupplacer)
    mkdir(setupplacer);
end

Placer = xml_read(strcat(Generic_files,'\IMU_Placer_Generic.xml'));
Placer.IMUPlacer.model_file = [path_input '\' Subject '.osim'];
if [path_input '\static_orientations.sto']
    Placer.IMUPlacer.orientation_file_for_calibration = [path_input '\static_orientations.sto'];
end
Placer.IMUPlacer.output_model_file = [path_input '\' Subject '_Scaled.osim'];
Placer.IMUPlacer.sensor_to_opensim_rotations = '-1.5707963267948966 0 0';
Pref.StructItem = true;
xml_write(fullfile(setupplacer,['placer_setup.xml']), Placer, 'OpenSimDocument',Pref);

commando = fullfile(setupplacer,['placer_setup.xml']); 

exe_path=[OpenSim_path 'opensense.exe'];
full_command = [exe_path ' -C "'  commando];
system(full_command);

disp('IMU Placer done')
