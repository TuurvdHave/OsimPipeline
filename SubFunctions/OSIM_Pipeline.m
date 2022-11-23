%% RUN IK AND ID
%==============
clear all, close all,clc
% addpath( genpath(fullfile(cd,'solvemuscleredundancyRoula')));
% addpath(genpath(fullfile(cd,'soft')));

addpath(genpath('C:\Users\u0093377\Documents\Anderen\Roula\OSIM_May\MuscleRedundancySolver'))
addpath(genpath('C:\Users\u0093377\Documents\Projects\OptLoad_Thesis\ProcessingCode\3_OpenSimPipeline\Casadi'));
%% Define input
%--------------

path_input      = 'C:\Users\u0093377\Documents\Anderen\Roula\Data\OSIM_Data'; %directory tp OSIM DATA
path_output     = 'C:\Users\u0093377\Documents\Anderen\Roula\Data\OpenSim'; %output folder/ Subject folder should contain Scaled model. = SubjectNAME_Scaled.osim"
path_c3d        = 'C:\Users\u0093377\Documents\Anderen\Roula\Data\C3D_Data';%directory to C3D data
path_emg        = 'C:\Users\u0093377\Documents\Anderen\Roula\Data\EMG_Data';%directory to EMG data
Subject         = 'RC18'; %Subject to proces
Folders2Process = {'Gait'}; %trialtypes ~subfolders
nFolders        = length(Folders2Process);


IK              = 1; %set 1 if you want to use inverse kinematics for IK.
KS              = 0; %set 1 if you want to use Kalman smoother for IK.
ik_filter       = 10; %filter for kinematics before ID.
AnalogFrameRate = 2000;
VideoFrameRate  = 250;
OffsetTime      = -0.050;




%% Initialize processing

%load OpenSim API
import org.opensim.modeling.*

%load OSIM model
model_in  = fullfile(path_output,Subject,[Subject '_scaled1Tib.osim']);
MyModel = Model((model_in));
MyModel.initSystem();

%generate batch file
batchfile = fullfile(path_output,Subject,[Subject '_Batch.cmd']);
first_iteration = 1;

%create subject actuators file
forcesetfile_gen = 'SO_actuators.xml';
ForceSetFile = fullfile(path_output,Subject,[Subject '_Actuators.xml']);
copyfile(forcesetfile_gen,ForceSetFile);
CreateActuatorsFile(forcesetfile_gen,ForceSetFile,model_in);

%load EMG-channel file
%---------------------
[EMGinfo.num,EMGinfo.txt,EMGinfo.raw] = xlsread(fullfile(path_emg,Subject,'EMG_channels.xlsx'));


for folder = 1:nFolders
    
    %load frames files;
    [Fr.num, Fr.txt, Fr.raw] = xlsread(fullfile(path_input,Subject,[Subject '_Frames.xlsx']),Folders2Process{folder});
    [EMG.num,EMG.txt,EMG.raw] = xlsread(fullfile(path_input,Subject,[Subject '_EMG.xlsx']),Folders2Process{folder});
    
    nfiles = size(Fr.raw,1);
    for file =2% 1:nfiles;
        if ~contains(Fr.raw{file,1},'static')
            
            %% Inverse kinematics
            %--------------------
            
            %prepare directories
            %-------------------
            output_kin  = fullfile(path_output,Subject,'InverseKinematics',Folders2Process{folder});
            if ~exist(output_kin);
                mkdir(fullfile(output_kin,'log'));
            end
            
            setup = fullfile(path_output,Subject,'SetUp_InverseKinematics',Folders2Process{folder});
            if ~exist(setup);
                mkdir(setup);
            end
            
            
            %determine start and end frames;
            %-------------------------------
            
            trc_file = fullfile(path_input,Subject,Folders2Process{folder},[Fr.raw{file,1} '.trc']);
            c3d_file = fullfile(path_c3d,Subject,Folders2Process{folder},[Fr.raw{file,1} '.c3d']);
            
            [Markers,MLabels,VideoFrameRate,AnalogSignals,ALabels, AUnits, AnalogFrameRate,Event,ParameterGroup,CameraInfo]...
                = readC3D(c3d_file);
            
            [ RHeelstrike,LHeelstrike,RToeoff,LToeoff ] = read_events_Nexus( ParameterGroup,ParameterGroup(1).Parameter(1).data(1),VideoFrameRate ); 
            tempname = Fr.raw{file,2}; 
            legcheck = tempname(end-1); 
            
            temptime(1) = round((Fr.raw{file,3}  - ParameterGroup(1).Parameter(1).data(1)+1)./VideoFrameRate,4); 
            temptime(2) = round((Fr.raw{file,4}  - ParameterGroup(1).Parameter(1).data(1)+1)./VideoFrameRate,4); 
%             LHeelstrike = [LHeelstrike,0.2 0.4];
            if strcmp(legcheck,'R'); 
                [val,index_min] = min(abs(RHeelstrike-temptime(1)));
               [val,index_min2] = min(abs(RToeoff-temptime(2)));
               Times.(Folders2Process{folder})(file,1) = round(RHeelstrike(index_min),3); 
               Times.(Folders2Process{folder})(file,2) = round(RToeoff(index_min2),3); 
            elseif strcmp(legcheck,'L'); 
               [val,index_min] = min(abs(LHeelstrike-temptime(1))); 
               [val,index_min2] = min(abs(LToeoff-temptime(2)));
               Times.(Folders2Process{folder})(file,1) = round(LHeelstrike(index_min),3); 
               Times.(Folders2Process{folder})(file,2) = round(LToeoff(index_min2),3); 
            end
               
%             Times.(Folders2Process{folder})(file,1) = 0.167;%round((Fr.raw{file,3}  - ParameterGroup(1).Parameter(1).data(1)+1)./VideoFrameRate,4);
%             Times.(Folders2Process{folder})(file,2) =0.313;%round((Fr.raw{file,4}  - ParameterGroup(1).Parameter(1).data(1)+1)./VideoFrameRate,4);
            
            ikTool = InverseKinematicsTool('IK_Generic.xml');
            ikTool.setMarkerDataFileName(trc_file)
            ikTool.setStartTime(Times.(Folders2Process{folder})(file,1));
            ikTool.setEndTime(Times.(Folders2Process{folder})(file,2));
            ikTool.setOutputMotionFileName(fullfile(output_kin, [Fr.raw{file,2},'.mot']))
            
            ikTool.print(fullfile(setup,[Fr.raw{file,2} '.xml']));
            
            %adapt model file name
            xmlParsing = xml_read(fullfile(setup,[Fr.raw{file,2} '.xml']));
            xmlParsing.InverseKinematicsTool.model_file = model_in;
            xml_write(fullfile(setup,[Fr.raw{file,2} '.xml']),xmlParsing,'OpenSimDocument');
            
            commando = [fullfile(setup,[Fr.raw{file,2} '.xml' ]) '" > "' fullfile(output_kin,'log',[Fr.raw{file,2} '.log"'])]; commando = strrep(commando,'\','/');
            
            if IK
                full_command = ['ik -S "'  commando];
            elseif KS
                full_command = ['ks -S "'  commando];
            end
            system(full_command);
            
            
            %% Create external loads files
            %-----------------------------
            
            %create directory
            %----------------
            dir_el = fullfile(path_output,Subject,'ExternalLoads',Folders2Process{folder});
            if ~exist(dir_el);
                mkdir(dir_el);
            end
            
            grf = fullfile(path_input,Subject,Folders2Process{folder},[Fr.raw{file,1} '.mot']);
            %rigth leg
            stor = Storage(AnalogFrameRate,grf);
            ForceR = ExternalForce(stor);
            ForceR.setName('Right');
            ForceR.setAppliedToBodyName('calcn_r');
            ForceR.setForceIdentifier('R_ground_force_v');
            ForceR.setPointIdentifier('R_ground_force_p');
            ForceR.setTorqueIdentifier('R_ground_torque_');
            ForceR.setPointExpressedInBodyName('ground');
            ForceR.setForceExpressedInBodyName('ground');
            
            %left leg
            stor = Storage(AnalogFrameRate,grf);
            ForceL = ExternalForce(stor);
            ForceL.setName('Left');
            ForceL.setAppliedToBodyName('calcn_l');
            ForceL.setForceIdentifier('L_ground_force_v');
            ForceL.setPointIdentifier('L_ground_force_p');
            ForceL.setTorqueIdentifier('L_ground_torque_');
            ForceL.setPointExpressedInBodyName('ground');
            ForceL.setForceExpressedInBodyName('ground');
            
            %create external loads file
            Loads = ExternalLoads();
            Loads.setName('Loads');
            Loads.setDataFileName(grf); %grf-file
            Loads.setExternalLoadsModelKinematicsFileName(fullfile(output_kin, [Fr.raw{file,2},'.mot'])); %motion file
            Loads.setLowpassCutoffFrequencyForLoadKinematics(ik_filter);
            Loads.cloneAndAppend(ForceR);
            Loads.cloneAndAppend(ForceL);
            
            Loads.print(fullfile(dir_el,[Fr.raw{file,2} '.xml']));
            
            
            %% Inverse dynamics
            %------------------
            
            %prepare directories
            %-------------------
            output_dyn  = fullfile(path_output,Subject,'InverseDynamics',Folders2Process{folder});
            if ~exist(output_dyn);
                mkdir(fullfile(output_dyn,'log'));
            end
            
            setupid = fullfile(path_output,Subject,'SetUp_InverseDynamics',Folders2Process{folder});
            if ~exist(setupid);
                mkdir(setupid);
            end
            
            
            idTool = InverseDynamicsTool('ID_Generic.xml');
            idTool.setModel(MyModel);
            idTool.setModelFileName(char(model_in));
            idTool.setCoordinatesFileName(fullfile(output_kin, [Fr.raw{file,2},'.mot']))
            idTool.setOutputGenForceFileName([Fr.raw{file,2} '.sto']);
            idTool.setLowpassCutoffFrequency(ik_filter);
            idTool.setStartTime(Times.(Folders2Process{folder})(file,1));
            idTool.setEndTime(Times.(Folders2Process{folder})(file,2));
            idTool.setResultsDir(output_dyn);
            idTool.setExternalLoadsFileName(fullfile(dir_el,[Fr.raw{file,2} '.xml']));
            idTool.print(fullfile(setupid,[Fr.raw{file,2} '.xml']));
            
            commando = [fullfile(setupid,[Fr.raw{file,2} '.xml']) '" > "' fullfile(output_dyn,'log',[Fr.raw{file,2} '.log"'])] ; commando = strrep(commando,'\','/');
            full_command = ['id -S "'  commando];
            system(full_command);
            
            
            %% Static optimization
            %---------------------
            
            %prepare directories
            %-------------------
            output_so  = fullfile(path_output,Subject,'StaticOptimization',Folders2Process{folder});
            if ~exist(output_so);
                mkdir(fullfile(output_so,'log'));
            end
            output_so2  = fullfile(path_output,Subject,'StaticOptimizationEMG',Folders2Process{folder},Fr.raw{file,2});
            if ~exist(output_so2);
                mkdir(fullfile(output_so2,'log'));
            end
            
            setupso = fullfile(path_output,Subject,'SetUp_StaticOptimization',Folders2Process{folder});
            if ~exist(setupso);
                mkdir(setupso);
            end
            
            
            soTool = AnalyzeTool('SO_Generic.xml');
            soTool.setModel(MyModel);
            soTool.setName(Fr.raw{file,2});
            soTool.setModelFilename(model_in);
            soTool.setCoordinatesFileName(fullfile(output_kin, [Fr.raw{file,2},'.mot']))
            soTool.setLowpassCutoffFrequency(ik_filter);
            soTool.setStartTime(Times.(Folders2Process{folder})(file,1));
            soTool.setFinalTime(Times.(Folders2Process{folder})(file,2));
            soTool.setReplaceForceSet(0);
            soTool.setForceSetFiles(ArrayStr(ForceSetFile,1))
            soTool.setResultsDir(fullfile(output_so,Fr.raw{file,2}));
            soTool.setExternalLoadsFileName(fullfile(dir_el,[Fr.raw{file,2} '.xml']));
            soTool.print(fullfile(setupso,[Fr.raw{file,2} '.xml']));
            
            commando = [fullfile(setupso,[Fr.raw{file,2} '.xml']) '" > "' fullfile(output_so,'log',[Fr.raw{file,2} '.log"'])] ; commando = strrep(commando,'\','/');
            full_command = ['analyze -S "'  commando];
            system(full_command);
            %
            %% EMG-constrained Static Optimization
            %-------------------------------------
            output_ma  = fullfile(path_output,Subject,'MuscleAnalysis',Folders2Process{folder});
            if ~exist(output_ma);
                mkdir(output_ma);
            end
            
            if ~exist( fullfile(output_ma,Fr.raw{file,2}))&& ~contains(Fr.raw{file,2},'static')
                mkdir(fullfile(output_ma,Fr.raw{file,2}))
            end
            
            
            Misc.DofNames_Input={'ankle_angle_r','knee_angle_r','hip_flexion_r','hip_adduction_r','hip_rotation_r','ankle_angle_l','knee_angle_l','hip_flexion_l','hip_adduction_l','hip_rotation_l'};
            
%                         Misc.DofNames_Input={'ankle_angle_l','knee_angle_l','hip_flexion_l','hip_adduction_l','hip_rotation_l'};
%                      

%                             Misc.DofNames_Input={'ankle_angle_r','knee_flexion_r','hip_flexion_r','hip_adduction_r','hip_rotation_r',...
%                             'ankle_angle_l','knee_flexion_l','hip_flexion_l','hip_adduction_l','hip_rotation_l'};
            
            Misc.RunAnalysis = 1;   % boolean to select if you want to run the muscle analysis
            Misc.Par_Elastic = 1;   % boolean to select if you want a parallel elastic element in your model
            Misc.FL_Relation = 0;   % boolean to select if you want a account for force-length and force-velocity properties
            Misc.EMGconstr = 1;     % Boolean to select EMG constrained option
            Misc.EMGfile = fullfile(path_emg,Subject,Folders2Process{folder},'Normalized',[Fr.raw{file,2} '_EMG.mot']);
            Misc.EMGbounds = [-0.1 0.1];    % upper and lower bound for deviation simulated and measured muscle activity
            Misc.EMGBoundBool = 1;
           Misc.EMGObjBool = 1;
Misc.wEMG       = 0.5;              % weight factor for part EMG in the objective function

% Misc.MaxScale    = 10;  % maximal value to scale EMG
            
%             Misc.BoundsScaleEMG = [0.1 1.2];
            % Provide the correct headers int case you EMG file has not the same
            % headers as the muscle names in OpenSim (leave empty when you don't want
            % to use this)
            Misc.EMGheaders = {'time',EMGinfo.txt{:,2}};
            % channels you want to use for EMG constraints
            Emg2Use =  EMG.num(file,:);
            c = 0;
            for i = 1:length(Emg2Use)
                if Emg2Use(i) == 1
                    c = c+1;
                    Misc.EMGSelection(c,1) = EMGinfo.txt(i,2);
                end
            end
            
            % Use this structure if you want to use one EMG channel for multiple
            % muscles in the opensim model. The first name of each row is the reference
            % and should always be in the header of the EMGfile or in the  EMGheaders.
                        Misc.EMG_MuscleCopies_temp = {'bflh_r','bfsh_r';...
                            'bflh_l','bfsh_l';...
                            'vaslat_r','vasint_r';...
                            'vaslat_l','vasint_l';...
                            'semiten_r','semimem_r';...
                            'semiten_l','semimem_l'};
                        
%                                 Misc.EMG_MuscleCopies_temp = {'bflh_l','bfsh_l';...
%                                                        'vaslat_l','vasint_l';'semiten_l','semimem_l'};
%             
         
%             Misc.EMG_MuscleCopies_temp = {'semiten_l','semimem_l'};
            CopyCount = 0;
            for i = 1:size(Misc.EMG_MuscleCopies_temp,1);
                if sum(strcmp(Misc.EMG_MuscleCopies_temp{i,1},Misc.EMGSelection))
                    CopyCount = CopyCount +1;
                    Misc.EMG_MuscleCopies{CopyCount,1} = Misc.EMG_MuscleCopies_temp{i,1};
                    Misc.EMG_MuscleCopies{CopyCount,2} = Misc.EMG_MuscleCopies_temp{i,2};
                end
            end
            %            Misc.EMG_MuscleCopies = {};
            Misc.ActDynEMG = 1;
            Misc.BoundsScale_EMG = 1;
            Misc.BoundsScaleEMG = [0.9 1.2];
            Misc.ActBound = 0;
            Misc.PlotBool = 1;
            Misc.f_cutoff_IK= 10;
            time = Times.(Folders2Process{folder})(file,:);
            
            Misc.Set_ATendon_ByName =...
    {'soleus_l',20;...
    'lat_gas_l',20;...
    'med_gas_l',20;};
Misc.Mesh_Frequency = 200;

            %             time(1,2) = time(1,2)-0.01;
            Out_path     = fullfile(pwd,'Results');                    % folder to store results
Misc.IKfile  = fullfile(output_kin, [Fr.raw{file,2},'.mot']);
Misc.IDfile  = fullfile(output_dyn, [Fr.raw{file,2},'.sto']);
% Misc.EMGfile = fullfile(pwd,'EMG_gait_6.mot');

            Misc.filename = Fr.raw{file,2};
            [Results,DatStore] = SolveMuscleRedundancy_EMG(model_in,time,Out_path,Misc);

            
%             [DatStore]=SolveStaticOptOnly(model_in,fullfile(output_kin, [Fr.raw{file,2},'.mot']),fullfile(output_dyn, [Fr.raw{file,2},'.sto']),time,fullfile(output_ma,Fr.raw{file,2}),Misc);
            
            %save results figure to check; 
%             output_figure = fullfile(output_so2,[Fr.raw{file,2} '_EMGvsPred']);
%             print(gcf,output_figure,'-dpng','-r150'); 
%             close all; 
            
            %merge results from static optimization and dynamic optimization
            %---------------------------------------------------------------
            
            so_file =  fullfile(output_so,Fr.raw{file,2},[Fr.raw{file,2} '_StaticOptimization_force.sto']);
            so_file_out =  fullfile(output_so2,[Fr.raw{file,2} '_StaticOptimization_force.sto']);
            [header, names, data, fpath] = SIMM_ReadMotion(so_file);
            
            endind = find(round(data(:,1),3) == round(DatStore.time(end,1),3));
            
            for m = 1:size(DatStore.MuscleNames,2);
                ind = find(strcmp(DatStore.MuscleNames{m},names));
                data(1:endind,ind) =  DatStore.SoForce(:,m);
            end
            %
            for m =  1:size( Misc.DofNames_Input,2)
                ind =find(strcmp([Misc.DofNames_Input{m} '_reserve'],names));
                data(1:endind,ind) = DatStore.SoRAct(:,m);
            end
            q.data  = data;
            q.labels = names;
            
            write_motionFile(q, so_file_out);
            
            
            clear Misc header names data q
            
            %% Joint Reaction Analysis
            %-------------------------
            
            %prepare directories
            %-------------------
            output_jrl  = fullfile(path_output,Subject,'JointReaction',Folders2Process{folder});
            if ~exist(output_jrl);
                mkdir(fullfile(output_jrl,'log'));
            end
            
            setupjrl = fullfile(path_output,Subject,'SetUp_JointReaction',Folders2Process{folder});
            if ~exist(setupjrl);
                mkdir(setupjrl);
            end
            
            
            jrTool = AnalyzeTool('JRA_Generic.xml');
            jrTool.setModel(MyModel);
            jrTool.setModelFilename(char(model_in));
            jrTool.setName(Fr.raw{file,2})
            jrTool.setCoordinatesFileName(fullfile(output_kin, [Fr.raw{file,2},'.mot']))
            jrTool.setLowpassCutoffFrequency(ik_filter);
            jrTool.setStartTime(Times.(Folders2Process{folder})(file,1));
            jrTool.setFinalTime(Times.(Folders2Process{folder})(file,2));
            jrTool.setReplaceForceSet(0);
            jrTool.setForceSetFiles(ArrayStr(ForceSetFile,1))
            jrTool.setResultsDir(output_jrl);
            jrTool.setExternalLoadsFileName(fullfile(dir_el,[Fr.raw{file,2} '.xml']));
            
            %adapt analysisset
            AnalysisSet = jrTool.getAnalysisSet();
            A = AnalysisSet.get('JointReaction');
            JR = JointReaction.safeDownCast(A);
            
            %This is the directory to the forces output from static optimization.
            Name.force_SO = [output_so2 '\'  Fr.raw{file,2} '_StaticOptimization_force.sto'];
            JR.setForcesFileName(Name.force_SO);
            
            jrTool.print(fullfile(setupjrl,[Fr.raw{file,2} '.xml']));
            
            commando = [fullfile(setupjrl,[Fr.raw{file,2} '.xml']) '" > "' fullfile(output_jrl,'log',[Fr.raw{file,2} '.log"'])] ; commando = strrep(commando,'\','/');
            full_command = ['analyze -S "'  commando];
            system(full_command);
            
            
            %% Decompose contact forces in medial-lateral component. 
            %------------------------------------------------------
             jrl_in = fullfile(output_jrl,[Fr.raw{file,2} '_JointReaction_ReactionLoads.sto']); 
            
            [MedLatCFR,MedLatCFL] = DecomposeCF(model_in,jrl_in);
           
            %add medial_lateralLoading To JointReactionAnalysis file
%             jrl_in = fullfile(output_jrl,[Fr.raw{file,2} '_JointReaction_ReactionLoads.sto']); 
            
            [header, names, data, fpath] = SIMM_ReadMotion(jrl_in);
            q.data  = [data,MedLatCFR,MedLatCFL];
            temp ={names,{'Med_R';'Lat_R';'Med_L';'Lat_L'}};
            q.labels = cat(1,temp{:});
            
            write_motionFile(q, jrl_in);
            
            
        end %if static
    end %loop nfiles
end %loop over Folders2Process

disp('Setup files written and data is processed')

