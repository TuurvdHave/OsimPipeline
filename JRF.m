%% JRF(information about the subject (folder stored,...), Muscle force file)
function JRF(params,input_file,subject,mainpath)

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
disp(data);


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
disp(model_in);
trailname = input_file;
disp(trailname)
temp = char(trailname);
trailname = temp(1:end-29);

        %% Joint Reaction Analysis - STATIC OPTIMIZATION
        %-----------------------------------------------
        SetupSO = xml_read(fullfile(path_output,'SetUp_StaticOptimization',[trailname '.xml' ]));
            %prepare directories
            %-------------------
            output_jrl  = fullfile(path_output,'JointReaction');
            if ~exist(output_jrl);
                mkdir(fullfile(output_jrl,'log'));
            end
            
            setupjrl = fullfile(path_output,'SetUp_JointReaction');
            if ~exist(setupjrl);
                mkdir(setupjrl);
            end
            
            JRF_setup = xml_read(strcat(Generic_files, '/JRA_Generic.xml'));   
            
            JRF_setup.AnalyzeTool.model_file = [model_in];
            JRF_setup.AnalyzeTool.initial_time = [string(SetupSO.AnalyzeTool.initial_time)];
            JRF_setup.AnalyzeTool.final_time = [string(SetupSO.AnalyzeTool.final_time)];
            JRF_setup.AnalyzeTool.coordinates_file = fullfile(path_output,'InverseKinematics', [trailname '.mot']); 
            JRF_setup.AnalyzeTool.external_loads_file = (char(strcat(SetupSO.AnalyzeTool.external_loads_file))); 
            JRF_setup.AnalyzeTool.lowpass_cutoff_frequency_for_coordinates = ik_filter;
            JRF_setup.AnalyzeTool.results_directory = output_jrl;                              
            JRF_setup.AnalyzeTool.AnalysisSet.objects.JointReaction.start_time =[string(SetupSO.AnalyzeTool.initial_time)];
            JRF_setup.AnalyzeTool.AnalysisSet.objects.JointReaction.end_time = [string(SetupSO.AnalyzeTool.final_time)];
            JRF_setup.AnalyzeTool.AnalysisSet.objects.JointReaction.forces_file = (char(strcat(SetupSO.AnalyzeTool.results_directory,'/',trailname,'_StaticOptimization_force.sto'))); 
            JRF_setup.AnalyzeTool.force_set_files = strcat(Generic_files, '/Reserve_actuators.xml');
            JRF_setup.AnalyzeTool.ATTRIBUTE.name = [(char(strcat(trailname)))];

            xml_write([setupjrl,'/',[trailname '.xml' ]], JRF_setup, 'OpenSimDocument');
            
            commando = [fullfile(setupjrl,[trailname '.xml' ])];% '" > "' fullfile(output_jrl,'log',[trailname '.log"'])] ; commando = strrep(commando,'\','/');
            
            if contains(OpenSim_path,'3.')
            exe_path=[OpenSim_path 'analyze.exe'];
            full_command = [exe_path ' -S  ' commando];
           elseif contains(OpenSim_path,'4.') 
            exe_path=[OpenSim_path 'opensim-cmd.exe'];
            full_command = [exe_path ' run-tool  ' commando];
           end 

            system(full_command);
       
        disp('JRF done')      