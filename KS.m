%% IK(information about the subject (folder stored,...), trc-file)
function KS(params,input_file,subject,mainpath)

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
KS3_path        = data.ks3x;
KS4_path        = data.ks4x;

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
if isfile(fullfile(main_path,Subject,[trailname '.csv']))
Fr = importFrames(fullfile(main_path,Subject,[trailname '.csv']));

nfiles = size(Fr,1);
for file = 3:2:nfiles-1
    if ~contains(trailname,'static')
        
        %% Determine start and end frames;
        %---------------------------------
            if strcmp(string(Fr.FootStrike(file)),'Foot Strike') && strcmp(string(Fr.FootStrike(file+1)),'Foot Off')
            Times(file,1) = Fr.Time(file);
            Times(file,2) = Fr.Time(file+1);
            Side = char(Fr.General(file));
            else 
                break
            end
        %% Inverse kinematics
        %--------------------
        
        %prepare directories
        %-------------------
        output_kin  = fullfile(path_output,'InverseKinematics');
        if ~exist(output_kin);
            mkdir(output_kin);
        end
        setup = fullfile(path_output,'SetUp_InverseKinematics');
        if ~exist(setup);
            mkdir(setup);
        end
              SetupIK = xml_read(strcat(Generic_files, '\IK_Generic.xml'));
                                SetupIK.InverseKinematicsTool.model_file = [model_in];
                                SetupIK.InverseKinematicsTool.time_range = [string(Times(file,1)),' ' string(Times(file,2))];
                                SetupIK.InverseKinematicsTool.marker_file = strcat(path_input,'\', trailname, '.trc'); 
                                SetupIK.InverseKinematicsTool.output_motion_file = strcat(output_kin,'\', trailname, Side ,num2str((file-1)/2),'.mot'); 
                                SetupIK.InverseKinematicsTool.results_directory = output_kin;
                                xml_write(fullfile(setup,[trailname Side num2str((file-1)/2) '.xml' ]), SetupIK, 'OpenSimDocument'); 
            
             commando = fullfile(setup,[trailname Side num2str((file-1)/2) '.xml' ]); % '" > "' fullfile(output_kin,'log',[trailname Side num2str((file-1)/2) '.log"'])];
            
           % exe_path=[OpenSim_path 'ik.exe'];
           if contains(OpenSim_path,'3.')
            exe_path=[ KS3_path  'ks.exe'];
            full_command = [exe_path ' -S  ' commando];
           elseif contains(OpenSim_path,'4.') 
            exe_path=[ KS4_path  'ks.exe'];
            full_command = [exe_path ' -S  ' commando];
           end 

            system(full_command);
            
            disp('IK done')

    end %if static
end % for frames 
else
    if ~contains(trailname,'static')
        %% Inverse kinematics
        %--------------------
        
        %prepare directories
        %-------------------
        output_kin  = fullfile(path_output,'InverseKinematics');
        setup = fullfile(path_output,'SetUp_InverseKinematics');
        if ~exist(setup);
            mkdir(setup);
        end
       [TRCdata, labels] = importTRCdata(char(fullfile(main_path,Subject,input_file)));
              SetupIK = xml_read(strcat(Generic_files, '\IK_Generic.xml'));
                                SetupIK.InverseKinematicsTool.model_file = [model_in];
                                SetupIK.InverseKinematicsTool.time_range = [string(TRCdata(1,2)) ' ' string(TRCdata(end,2))];
                                SetupIK.InverseKinematicsTool.marker_file = strcat(path_input,'\', trailname, '.trc'); 
                                SetupIK.InverseKinematicsTool.output_motion_file = strcat(output_kin,'\', trailname,'.mot'); 
                                SetupIK.InverseKinematicsTool.results_directory = output_kin;
                                xml_write(fullfile(setup,[trailname '.xml' ]), SetupIK, 'OpenSimDocument'); 
            
            commando = [fullfile(setup,[trailname '.xml' ])];%'" > "' fullfile(output_kin,'log',[trailname '.log"'])]; commando = strrep(commando,'\','/');
            
            if contains(OpenSim_path,'3.')
            exe_path=[ KS3_path  'ks.exe'];
            full_command = [exe_path ' -S  ' commando];
           elseif contains(OpenSim_path,'4.') 
            exe_path=[ KS4_path  'ks.exe'];
            full_command = [exe_path ' -S  ' commando];
           end 

            system(full_command);
            
            disp('IK done')

    end 
end 