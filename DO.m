%% DO(information about the subject (folder stored,...), External_loads file)
function DO(params,input_file,subject,mainpath)

%% first the SO has to run before you can run the DO 
SO(params,input_file,subject,mainpath)
%% 

addpath(genpath(fullfile(cd,'GenericSetup')))
addpath(genpath(fullfile(cd,'SubFunctions')))
addpath(genpath(fullfile(cd,'MuscleRedundancySolver-master')))
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
trailname = temp(1:end-18);
%% Dynamic optimization
        %---------------------
            SetupID = xml_read(fullfile(path_output,'SetUp_InverseDynamics',[trailname '.xml' ]));
            %prepare directories
            %-------------------
            output_so  = fullfile(path_output,'StaticOptimization');
            if ~exist(output_so);
                mkdir(output_so);
            end
            setupso = fullfile(path_output,'SetUp_StaticOptimization');
            if ~exist(setupso);
                mkdir(setupso);
            end
            
            %Properties EMG-constrained            
            
            Misc.IKfile  = {fullfile(path_output,'InverseKinematics', [trailname '.mot'])};
            Misc.IDfile  = {fullfile(path_output,'InverseDynamics', [trailname '.sto'])};
            
            info = importdata(fullfile(path_output,'InverseKinematics', [trailname '.mot']));
            
            Misc.DofNames_Input={'ankle_angle_l','knee_angle_l','hip_flexion_l','hip_adduction_l','hip_rotation_l'}; %Indicate for which dof you want to solve the optimization.
%             for i = 8:size(info.colheaders,2)
%             Misc.DofNames_Input{i-7} = info.colheaders{i};
%             end 
            
            Misc.model_path = model_in;
            
            Misc.MRSBool = 1;
            Misc.RunAnalysis    = 1;   % boolean to select if you want to run the muscle analysis
            Misc.Par_Elastic    = 1;   % boolean to select if you want a parallel elastic element in your model
            Misc.FL_Relation    = 1;   % boolean to select if you want a account for force-length and force-velocity properties
            Misc.EMGconstr      = 0;   % Boolean to select EMG constrained option
            Misc.ActBound       = 0;
            Misc.PlotBool       = 0;
            Misc.f_cutoff_IK    = ik_filter;
            Misc.PerformDyn     = 1;
            Misc.EMGBoundBool   = 0;
            
            time = [SetupID.InverseDynamicsTool.time_range(1,1) SetupID.InverseDynamicsTool.time_range(1,2)];
            
            %             Misc.Set_ATendon_ByName =...
            %                 {'soleus_l',20;...
            %                 'gaslat_l',20;...
            %                 'gasmed_l',20;...
            %                 'soleus_r',20;...
            %                 'gaslat_r',20;...
            %                 'gasmed_r',20};
            Misc.Mesh_Frequency = 100;
            Misc.f_cutoff_ID = ik_filter;
            Misc.OutPath = output_so;
            Misc.filename = trailname;

            if (time(1,2)-time(1,1))>0.18
            [Results,DatStore,Misc] = solveMuscleRedundancy(time,Misc);
            else 
                return
            end 
            
            %merge results from static optimization and EMG-Constrained static optimization
            %------------------------------------------------------------------------------
            
            if isfile(fullfile(output_so,[trailname '_StaticOptimization_force.sto']))
            so_file =  fullfile(output_so,[trailname '_StaticOptimization_force.sto']);
            so_file_out =  fullfile(output_so,[trailname '_StaticOptimization_force.sto']);
            [header, names, data, fpath] = SIMM_ReadMotion(so_file);
            
            startind = find(round(data(:,1),3) == round(DatStore.time(1,1),3));
            endind = find(round(data(:,1),3) == round(DatStore.time(end,1),3));
            
            for m = 1:size(DatStore.MuscleNames,2);
                ind = find(strcmp(DatStore.MuscleNames{m},names));
                data(startind:endind,ind) =  interp1(Results.Time.genericMRS,Results.TForce.genericMRS(m,:)',data(startind:endind,1));
            end
            
            
            if size(Results.RActivation.genericMRS,2)< size(Results.Time.genericMRS,1);
                %                 missing = size(data,1)-size(Results.RActivation.genericMRS,2);
                missing = length(Results.Time.genericMRS)-size(Results.RActivation.genericMRS,2);
                Results.RActivation.genericMRS = [Results.RActivation.genericMRS,ones(size(Results.RActivation.genericMRS,1),missing).*NaN];
            end
            for m =  1:size(Misc.DofNames_Input{1,1},2)
                ind =find(strcmp(Misc.DofNames_Input{1,1}{m},names));%'_reserve'
                %             data(1:endind,ind) = Results.RActivation.genericMRS(m,:)';
                data(startind:endind,ind) = interp1(Results.Time.genericMRS,Results.RActivation.genericMRS(m,:)',data(startind:endind,1));
            end
            q.data  = data;
            q.labels = names;
            
            write_motionFile(q, so_file_out);    
            end 
          
        disp('DO done')