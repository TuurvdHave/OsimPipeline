function IMU_Placer_GdR(params,subject,mainpath)
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

%% IMU Placer GdR - Dynamic calibration (placer) of the IMU probes on the body
%
% Code elaborated by Di Raimondo, Giacomo
% please cite doi.org/10.3390/s22093259
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The code will only run after the generic IMU_Placer.
% The necessary inputs are squat and hip abduction (optional) trials,
% which must be named as "squat.mvnx" and "hipfront.mvnx"
    hipfront = true;
    squat_struct = load([path_input, '\squat.mat']);
    load([path_input, '\squat_DataMatrix.mat']);
    rawData = squat_struct.rawData;

    run import_sto_MNV_to_Tables_v1
    a_squat = a;
    q_squat = q;
    m_squat = m;
    hipfront_struct =  load([path_input, '\hipfront.mat']);
    load([path_input, '\hipfront_DataMatrix.mat'])
    rawData = hipfront_struct.rawData;

    run import_sto_MNV_to_Tables_v1
    a_hipfront = a;
    q_hipfront = q;
    m_hipfront = m;

    a = [a_squat; a_hipfront];
    q = [q_squat; q_hipfront];
    m = [m_squat; m_hipfront];

 % Squat calibration & hip front

    fs = rawData.framerate;

    [DS.d1]=OpenIMUs_CreateSensStruct_MVN_v3(fs, a, m, q);
    DS.d1.standing_range = 1:10;
    DS.d1.sit_range = 11:length(a_squat.time);
    DS.d1.adduction_range_r = length(a_squat.time)+1:length(a.time);
    DS.d1.adduction_range_l = length(a_squat.time)+1:length(a.time);

    %     if [path_output '\dynamic_calibration_orientations.sto']
    disp('Dynamic calibration...')
    run OpenIMUs_FC_M1_v3.m

    % Calibrate Model
    coord_estimation = true;
    visualizeIMU = false;

    run OpenIMUs_CE_v2.m
    % SAVE model Calibrated
    new_model_Name = [path_input,'\' Subject '_Scaled.osim' ];
    model.print(new_model_Name);
    disp('Model Saved')

    pause(2)
    disp([char(13), '-------- Calibration done ----------'])

