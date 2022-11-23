%% ID(information about the subject (folder stored,...), mot-file)
function ID(params,input_file,subject,mainpath)

addpath(genpath(fullfile(cd,'GenericSetup')))
addpath(genpath(fullfile(cd,'SubFunctions')))

%% 
disp('Loading params file')
fid = fopen(params); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
data = jsondecode(str);
disp('Loaded parameters')
disp(data)


%% Define input
%--------------

main_path       = mainpath; 
OpenSim_path    = data.osim_path; 
Generic_files   = 'GenericSetup';
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
disp(model_in);
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
        
        SetupIK = xml_read(fullfile(path_output,'SetUp_InverseKinematics',[trailname '.xml' ]));
        
        ExternalLoads = xml_read(strcat(Generic_files, '\ExternalLoads.xml'));      
                    ExternalLoads.ExternalLoads.datafile = strcat(SetupIK.InverseKinematicsTool.marker_file(1:end-4),'.mot');
                    ExternalLoads.ExternalLoads.external_loads_model_kinematics_file = ' ';  

                    % right leg
                    ExternalLoads.ExternalLoads.objects.ExternalForce(1).applied_to_body = 'calcn_r';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(1).force_expressed_in_body = 'ground';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(1).point_expressed_in_body = 'ground';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(1).force_identifier = 'R_ground_force_v';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(1).point_identifier = 'R_ground_force_p';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(1).torque_identifier = 'R_ground_torque_';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(1).data_source_name = strcat(SetupIK.InverseKinematicsTool.marker_file(1:end-4),'.mot');
        
                    %left leg
                    ExternalLoads.ExternalLoads.objects.ExternalForce(2).applied_to_body = 'calcn_l';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(2).force_expressed_in_body = 'ground';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(2).point_expressed_in_body = 'ground';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(2).force_identifier = 'L_ground_force_v';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(2).point_identifier = 'L_ground_force_p';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(2).torque_identifier = 'L_ground_torque_';
                    ExternalLoads.ExternalLoads.objects.ExternalForce(2).data_source_name = strcat(SetupIK.InverseKinematicsTool.marker_file(1:end-4),'.mot');

        
                %create external loads file
                xml_write([dir_el,'\',[trailname '_ExternalLoads.xml']], ExternalLoads, 'OpenSimDocument');
        
        disp('external Loads file created')
        %% Inverse dynamics
        %------------------
        
        %prepare directories
        %-------------------
        
        output_dyn  = fullfile(path_output,'InverseDynamics');
        if ~exist(output_dyn);
            mkdir(fullfile(output_dyn,'log'));
        end
        
        setupid = fullfile(path_output,'SetUp_InverseDynamics');
        if ~exist(setupid);
            mkdir(setupid);
        end
        
        SetupIK = xml_read(fullfile(path_output,'SetUp_InverseKinematics',[trailname '.xml' ])); 
        
        ID_setup = xml_read(strcat(Generic_files, '\ID_Generic.xml'));   
                  ID_setup.InverseDynamicsTool.model_file = [model_in];
                  ID_setup.InverseDynamicsTool.time_range = [string(SetupIK.InverseKinematicsTool.time_range(1,1)) ' ' string(SetupIK.InverseKinematicsTool.time_range(1,2))];
                  ID_setup.InverseDynamicsTool.coordinates_file = fullfile(path_output,'InverseKinematics', [trailname '.mot']); 
                  ID_setup.InverseDynamicsTool.lowpass_cutoff_frequency_for_coordinates = ik_filter; 
                  ID_setup.InverseDynamicsTool.results_directory = output_dyn;
                  ID_setup.InverseDynamicsTool.output_gen_force_file  =  strcat(trailname,'.sto'); 
                  ID_setup.InverseDynamicsTool.external_loads_file = (char(fullfile(dir_el,[trailname  '_ExternalLoads.xml']))); 
                  xml_write([setupid,'\',[trailname '.xml' ]], ID_setup, 'OpenSimDocument');
  
            commando = [fullfile(setupid,[trailname '.xml' ]) '" > "' fullfile(output_dyn,'log',[trailname '.log"'])]; commando = strrep(commando,'\','/');
            
            exe_path=[OpenSim_path 'id.exe'];
            full_command = [exe_path ' -S "'  commando];
            system(full_command);
            
            disp('ID done')

end
