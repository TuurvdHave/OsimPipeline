%% SO(information about the subject (folder stored,...), External_loads file)
function SO(params,input_file,subject,mainpath)

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
Generic_files   = [main_path '/GenericSetup'];
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
trailname = temp(1:end-18);
%% Static optimization
        %---------------------
         SetupID = xml_read(fullfile(path_output,'SetUp_InverseDynamics',[trailname '.xml' ]));
            %prepare directories
            %-------------------
            output_so  = fullfile(path_output,'StaticOptimization');
            if ~exist(output_so);
                mkdir(fullfile(output_so,'log'));
            end
            
            setupso = fullfile(path_output,'SetUp_StaticOptimization');
            if ~exist(setupso);
                mkdir(setupso);
            end
            
            SO_setup = xml_read(strcat(Generic_files, '/SO_Generic.xml'));   
            SO_setup.AnalyzeTool.model_file = [model_in];
            SO_setup.AnalyzeTool.initial_time = [string(SetupID.InverseDynamicsTool.time_range(1,1))];
            SO_setup.AnalyzeTool.final_time = [string(SetupID.InverseDynamicsTool.time_range(1,2))];
            SO_setup.AnalyzeTool.coordinates_file = fullfile(path_output,'InverseKinematics', [trailname '.mot']); 
            SO_setup.AnalyzeTool.external_loads_file = (char(strcat(SetupID.InverseDynamicsTool.external_loads_file))); 
            SO_setup.AnalyzeTool.lowpass_cutoff_frequency_for_coordinates = ik_filter;
            SO_setup.AnalyzeTool.results_directory = output_so;                                
            SO_setup.AnalyzeTool.AnalysisSet.objects.StaticOptimization.start_time = [string(SetupID.InverseDynamicsTool.time_range(1,1))];
            SO_setup.AnalyzeTool.AnalysisSet.objects.StaticOptimization.end_time = [string(SetupID.InverseDynamicsTool.time_range(1,2))];                           
            SO_setup.AnalyzeTool.force_set_files = strcat(Generic_files, '/DC_MW_musc_Strong_actuators.xml'); 
            SO_setup.AnalyzeTool.ATTRIBUTE.name = [(char(strcat(trailname)))];
            
            xml_write([setupso,'/',[trailname '.xml' ]], SO_setup, 'OpenSimDocument');

            commando = [fullfile(setupso,[trailname '.xml' ])];% '" > "' fullfile(output_so,'log',[trailname '.log"'])] ; commando = strrep(commando,'\','/');
            exe_path=[OpenSim_path 'opensim-cmd'];
            full_command = [exe_path ' run-tool ' commando];

            system(full_command);
          
        disp('SO done')