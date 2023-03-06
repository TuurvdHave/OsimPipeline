function IMU_IK(params,input_file,subject,mainpath)
%% MVNXtoSTO (covert .mvnx file from Xsens to .sto format for OpenSense processing)
% Syntax: MVNXtoSTO(params,input_file,subject,mainpath)
%
% Inputs:
%   params - a JSON file containing parameters for IK setup
%   input_file - the name of the MVNX file to convert
%   subject - the name of the subject to process
%   mainpath - the path to the main directory containing all files
%
% Outputs:
%   None
%
% Example usage: MVNXtoSTO('params.json', 'motioncapture.mvnx', 'subject1', '/path/to/files')

% Add required directories to the MATLAB path
addpath(genpath(fullfile(cd,'GenericSetup')))
addpath(genpath(fullfile(cd,'SubFunctions')))

% Load the parameters file (in JSON format)
disp('Loading params file')
fid = fopen(params); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
data = jsondecode(str);
disp('Loaded parameters')
disp(data);

% Set up paths for input and output files
main_path       = mainpath; 
OpenSim_path    = data.osim_path; 
Generic_files   = [mainpath,'\GenericSetup'];
Subject         = char(subject); 
path_input      = fullfile(main_path,Subject); 
path_output     = fullfile(main_path,Subject,'Opensim'); 

            %% IMU Inverse Kinematics
            %--------------------

            %prepare directories
            %-------------------
            output_kin  = fullfile(path_output,'InverseKinematics');
            if ~exist(output_kin);
                mkdir(output_kin);
            end
            setupimuik = fullfile(path_output,'Setup_IMU_InverseKinematics');
            if ~exist(setupimuik)
                mkdir(setupimuik);
            end
            % calculate end time of the trial
            load(fullfile(path_input,[input_file(1:end-5) '_DataMatrix.mat']))
            time_length = time(end);

            SetupIMUIK = xml_read(strcat(Generic_files, '/IMU_IK_Generic.xml'));
            SetupIMUIK.IMUInverseKinematicsTool.model_file = [path_input '/' Subject '_Scaled.osim'];
            SetupIMUIK.IMUInverseKinematicsTool.time_range = string([0, time_length]);
            SetupIMUIK.IMUInverseKinematicsTool.output_motion_file = strcat(output_kin,'/', input_file(1:end-5),'.mot');
            SetupIMUIK.IMUInverseKinematicsTool.results_directory = output_kin;
            SetupIMUIK.IMUInverseKinematicsTool.orientations_file = fullfile(path_input, append(input_file(1:end-5), '_orientations.sto'));
            SetupIMUIK.IMUInverseKinematicsTool.sensor_to_opensim_rotations = '-1.5707963267948966 0 0';

            xml_write(fullfile(setupimuik,[input_file(1:end-5) '.xml' ]), SetupIMUIK, 'OpenSimDocument');
            commando = fullfile(setupimuik,[input_file(1:end-5) '.xml' ]);

            exe_path=[OpenSim_path 'opensense.exe'];
            full_command = [exe_path ' -IK "'  commando];
            system(full_command);
            disp('IMU IK done')
