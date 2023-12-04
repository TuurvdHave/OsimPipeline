%% ID(information about the subject (folder stored,...), mot-file)
function ID(params,input_file,subject,mainpath)

addpath(genpath(fullfile(cd,'GenericSetup')))
addpath(genpath(fullfile(cd,'SubFunctions')))

%%
fid = fopen(params);
raw = fread(fid,inf);
str = char(raw');
fclose(fid);
data = jsondecode(str);



%% Define input
%--------------

main_path       = mainpath;
OpenSim_path    = data.osim_path;
Generic_files   = [mainpath,'\GenericSetup'];
Subject         = char(subject);

ik_filter       = data.ik_filter;
AnalogFrameRate = data.AnalogFrameRate;
VideoFrameRate  = data.VideoFrameRate;


path_input      = fullfile(main_path,Subject);
path_output     = fullfile(main_path,Subject,'Opensim');

%% Initialize processing
%-----------------------

%load OSIM model
model_in  = fullfile(main_path,Subject,[Subject '_Scaled.osim']);
trailname = input_file;
disp(trailname)
temp = char(trailname);
trailname = temp(1:end-4);
%read in the events file
%% Create external loads files
%-----------------------------
%create directory
%----------------
dir_el = fullfile(path_output,'ExternalLoads');
if ~exist(dir_el);
    mkdir(dir_el);
end
if isfolder(fullfile(path_output,'SetUp_InverseKinematics'))
    SetupIK = xml_read(fullfile(path_output,'SetUp_InverseKinematics',[trailname '.xml' ]));

    ExternalLoads = xml_read(strcat(Generic_files, '\ExternalLoads.xml'));
    ExternalLoads.ExternalLoads.datafile = strcat(SetupIK.InverseKinematicsTool.marker_file(1:end-4),'.mot');
    ExternalLoads.ExternalLoads.external_loads_model_kinematics_file = ' ';

    % right leg
    ExternalLoads.ExternalLoads.objects.ExternalForce(1).data_source_name = strcat(SetupIK.InverseKinematicsTool.marker_file(1:end-4),'.mot');

    %left leg
    ExternalLoads.ExternalLoads.objects.ExternalForce(2).data_source_name = strcat(SetupIK.InverseKinematicsTool.marker_file(1:end-4),'.mot');

    %create external loads file
    xml_write([dir_el,'\',[trailname '_ExternalLoads.xml']], ExternalLoads, 'OpenSimDocument');

elseif isfolder(fullfile(path_output,'SetUp_IMU_InverseKinematics')) && isfile(fullfile(path_input,[trailname '.mot'])) 
    ExternalLoads = xml_read(strcat(Generic_files, '\ExternalLoads.xml'));

    ExternalLoads.ExternalLoads.datafile = strcat(fullfile(path_input,[trailname '.mot']));
    ExternalLoads.ExternalLoads.external_loads_model_kinematics_file = ' ';

    % right leg
    ExternalLoads.ExternalLoads.objects.ExternalForce(1).data_source_name = strcat(fullfile(path_input,[trailname '.mot']));;
    %left leg
    ExternalLoads.ExternalLoads.objects.ExternalForce(2).data_source_name = strcat(fullfile(path_input,[trailname '.mot']));;

    %create external loads file
    xml_write([dir_el,'\',[trailname '_ExternalLoads.xml']], ExternalLoads, 'OpenSimDocument');
end 



disp('external Loads file created')
%% Inverse dynamics
%------------------

%prepare directories
%-------------------

output_dyn  = fullfile(path_output,'InverseDynamics');
if ~exist(output_dyn);
    mkdir(output_dyn);
end
setupid = fullfile(path_output,'SetUp_InverseDynamics');
if ~exist(setupid);
    mkdir(setupid);
end
if ~exist([setupid,'\log'])
    mkdir([setupid,'\log']);
end

if isfolder(fullfile(path_output,'SetUp_InverseKinematics'))
    SetupIK = xml_read(fullfile(path_output,'SetUp_InverseKinematics',[trailname '.xml' ]));

    ID_setup = xml_read(strcat(Generic_files, '\ID_Generic.xml'));
    ID_setup.InverseDynamicsTool.model_file = [model_in];
    ID_setup.InverseDynamicsTool.time_range = [string(SetupIK.InverseKinematicsTool.time_range(1,1)) ' ' string(SetupIK.InverseKinematicsTool.time_range(1,2))];
    ID_setup.InverseDynamicsTool.coordinates_file = fullfile(path_output,'InverseKinematics', [trailname '.mot']);
    ID_setup.InverseDynamicsTool.lowpass_cutoff_frequency_for_coordinates = ik_filter;
    ID_setup.InverseDynamicsTool.results_directory = output_dyn;
    ID_setup.InverseDynamicsTool.output_gen_force_file  =  strcat(trailname,'.sto');
    ID_setup.InverseDynamicsTool.external_loads_file = (char(fullfile(dir_el,[trailname  '_ExternalLoads.xml'])));

elseif isfolder(fullfile(path_output,'SetUp_IMU_InverseKinematics')) && isfile(fullfile(path_input,[trailname '.mot'])) && isfile(fullfile(path_output,'SetUp_IMU_InverseKinematics',[trailname '.xml' ]))
    SetupIK = xml_read(fullfile(path_output,'SetUp_IMU_InverseKinematics',[trailname '.xml' ]));
    ID_setup = xml_read(strcat(Generic_files, '\ID_Generic.xml'));
    ID_setup.InverseDynamicsTool.model_file = [model_in];
    ID_setup.InverseDynamicsTool.time_range = [string(SetupIK.IMUInverseKinematicsTool.time_range(1,1)) ' ' string(SetupIK.IMUInverseKinematicsTool.time_range(1,2))];
    ID_setup.InverseDynamicsTool.coordinates_file = fullfile(path_output,'InverseKinematics', [trailname '.mot']);
    ID_setup.InverseDynamicsTool.lowpass_cutoff_frequency_for_coordinates = ik_filter;
    ID_setup.InverseDynamicsTool.results_directory = output_dyn;
    ID_setup.InverseDynamicsTool.output_gen_force_file  =  strcat(trailname,'.sto');
    ID_setup.InverseDynamicsTool.external_loads_file = (char(fullfile(dir_el,[trailname  '_ExternalLoads.xml'])));

else
    ikdata = importdata(fullfile(path_output,'InverseKinematics', [trailname '.mot']));
    time = size(ikdata.data,1)/VideoFrameRate;
    ID_setup = xml_read(strcat(Generic_files, '\ID_Generic.xml'));
    ID_setup.InverseDynamicsTool.model_file = [model_in];
    ID_setup.InverseDynamicsTool.time_range = ['0 ' string(time)];
    ID_setup.InverseDynamicsTool.coordinates_file = fullfile(path_output,'InverseKinematics', [trailname '.mot']);
    ID_setup.InverseDynamicsTool.lowpass_cutoff_frequency_for_coordinates = ik_filter;
    ID_setup.InverseDynamicsTool.results_directory = output_dyn;
    ID_setup.InverseDynamicsTool.output_gen_force_file  =  strcat(trailname,'.sto');
    ID_setup.InverseDynamicsTool.external_loads_file = '';
end



xml_write([setupid,'\',[trailname '.xml' ]], ID_setup, 'OpenSimDocument');

%commando = [fullfile(setupid,[trailname '.xml' ])];
commando = [fullfile(setupid,[trailname '.xml' ]) ' > ' fullfile(setupid,'log',[trailname '.log'])];

if contains(OpenSim_path,'3.')
    exe_path=[OpenSim_path 'id.exe'];
    full_command = [exe_path ' -S  ' commando];
elseif contains(OpenSim_path,'4.')
    exe_path=[OpenSim_path 'opensim-cmd.exe'];
    full_command = [exe_path ' run-tool  ' commando];
end
system(full_command);

if isfile(strcat(output_dyn,'\',trailname,'.sto'))
    disp('ID done')
else
    f = warndlg({['NOPE! Your Inverse dynamics of ' trailname ' did not work.'];...
        'This could have multiple reasons:';...
        '1) Check your OpenSim path in param.json and do not forget the double \\';...
        '2) Make sure the folder construction is similar to the one in the readme.';...
        '3) All paths can not contain spaces as the windows command shell is not able to handle this';...
        '4) check the names of the generic setup files. They should be like written in the readme';...
        });
end

end
