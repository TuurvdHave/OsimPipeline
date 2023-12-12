% Close all open figures
close all

% Clear all variables from workspace
clear all

% Clear the command window
clc

%% Input parameters for the code (no paths need to be adapted)

% Use uigetdir to allow the user to select the folder where the project is stored
mainpath = uigetdir(cd,'Select the folder where you stored your project with all particpants');

% Get a list of all the files and folders in the project folder
folders = dir(mainpath);

% Set a counter to keep track of the number of participants
a = 1;

% Loop through all the folders in the project folder
for i = 3 : size(folders,1)
    % Check if the folder is named "GenericSetup"
    if strcmpi(folders(i).name,'GenericSetup') == 0 && strcmpi(folders(i).name,'params.json') == 0 
        % If it's not, add the folder name to a cell array called "subjectname"
        subjectname{a} = folders(i).name;
        % Increment the counter
        a = a + 1;
    end
end

% Use uigetfile to allow the user to select the params.json file for specific inputs
[file,path] = uigetfile('*.*','Select params.json file to define specific inputs');

% answering which steps of the pipeline to run. This is not performed
% automatically as the codes wants to run parallell computations
MoInanswer = inputdlg({'Are you analyzing Mocap or Incap data'},'Analyses',[1 35],{'Mocap/Incap'});
if strcmpi(MoInanswer{1},'Mocap')
    answer = inputdlg({'IK? Answer with yes or no','KS?','ID?','SO?','DO?','JRF?','Save in .mat?'},'Analyses',[1 35],{'yes','no','yes','yes','no','yes','yes'});
elseif strcmpi(MoInanswer{1},'Incap')
    answer = inputdlg({'Scaling? Answer with yes or no','Convert to STO?','Dynamic calibration?','IK?','ID?','SO?','DO?','JRF?','Save in .mat?'},'Analyses',[1 35],{'yes','yes','yes','no','no','no','no','no','no'});
end

for subjectnr = 1 : size(subjectname,2)
    if strcmpi(MoInanswer{1},'Incap') && strcmpi(answer(1,1),'yes') && ~exist(char(fullfile(mainpath,subjectname(subjectnr),[char(subjectname(subjectnr)) '.osim'])))
        height(subjectnr) = str2double(inputdlg(['Type the height of ' subjectname(subjectnr)  ' (cm):']));
        weight(subjectnr) = str2double(inputdlg(['Type the weight of ' subjectname(subjectnr) ' (kg):']));
    end
end 
%% Running the analysis
for subjectnr = 1 : size(subjectname,2)
    filenames = dir(char(fullfile(mainpath,subjectname(subjectnr))));
    parpool(3)
    parfor nfile = 3 : size(filenames,1)
        %% analyzing marker data
        if strcmpi(filenames(nfile).name(end-3:end),'.trc') && strcmpi(MoInanswer{1},'Mocap')
            % Use inputdlg to get yes or no answers to questions about which analyses to run
            if strcmpi(answer(1,1),'yes')
                IK(fullfile(path,file),filenames(nfile).name,subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(2,1),'yes')
                KS(fullfile(path,file),filenames(nfile).name,subjectname(subjectnr),mainpath);
            end
            % when events are used in vicon one .trc can result in multiple .mot files.
            % the name of output kinematicfiles
            % will be changed according to the event. The final name is
            % checked here. 
            kinfile = dir(char(fullfile(mainpath,subjectname(subjectnr),'OpenSim\InverseKinematics')));
            kinfilenames = {kinfile(~[kinfile.isdir]).name};
            for f = 1 : sum(contains(kinfilenames,filenames(nfile).name(1:end-4)))
                [row,col] = find(contains(kinfilenames,filenames(nfile).name(1:end-4)));
                sub = char(kinfilenames(:,col(f)));
                finfilename = sub(1:end-4);
                if strcmpi(answer(3,1),'yes')
                    ID(fullfile(path,file),[finfilename '.mot'],subjectname(subjectnr),mainpath);
                end
                if strcmpi(answer(4,1),'yes')
                    SO(fullfile(path,file),[finfilename '_ExternalLoads.xml'],subjectname(subjectnr),mainpath);
                end
                if strcmpi(answer(5,1),'yes')
                    DO(fullfile(path,file),[finfilename '_ExternalLoads.xml'],subjectname(subjectnr),mainpath);
                end
                if strcmpi(answer(6,1),'yes')
                    JRF(fullfile(path,file),[finfilename '_StaticOptimization_force.sto'],subjectname(subjectnr),mainpath);
                end
                if strcmpi(answer(7,1),'yes')
                    Summarize(fullfile(path,file),[finfilename '_JointReaction_ReactionLoads.sto'],subjectname(subjectnr),mainpath);
                end

            end
            %% Analyzing the IMU data
        elseif strcmpi(filenames(nfile).name(end-4:end),'.mvnx') && strcmpi(MoInanswer{1},'Incap')
            % Use inputdlg to get yes or no answers to questions about which analyses to run
            if strcmpi(answer(1,1),'yes') && ~exist(char(fullfile(mainpath,subjectname(subjectnr),[char(subjectname(subjectnr)) '.osim'])))
                LinScaling(fullfile(path,file),subjectname(subjectnr),mainpath,height(subjectnr),weight(subjectnr));
            end
            if strcmpi(answer(2,1),'yes')
                MVNXtoSTO(fullfile(path,file),filenames(nfile).name,subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(3,1),'yes') && ~exist(char(fullfile(mainpath,subjectname(subjectnr),[char(subjectname(subjectnr)) '_Scaled.osim'])))
                MVNXtoSTO(fullfile(path,file),'squat.mvnx',subjectname(subjectnr),mainpath);
                MVNXtoSTO(fullfile(path,file),'hipfront.mvnx',subjectname(subjectnr),mainpath);
                IMU_Placer_GdR(fullfile(path,file),subjectname(subjectnr),mainpath);
            elseif strcmpi(answer(3,1),'no')
                MVNXtoSTO(fullfile(path,file),'Static.mvnx',subjectname(subjectnr),mainpath);
                IMU_Placer(fullfile(path,file),subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(4,1),'yes')
                IMU_IK(fullfile(path,file),filenames(nfile).name,subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(5,1),'yes')
                ID(fullfile(path,file),[filenames(nfile).name(1:end-5) '.mot'],subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(6,1),'yes')
                SO(fullfile(path,file),[filenames(nfile).name(1:end-5) '_ExternalLoads.xml'],subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(7,1),'yes')
                DO(fullfile(path,file),[filenames(nfile).name(1:end-5) '_ExternalLoads.xml'],subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(8,1),'yes')
                JRF(fullfile(path,file),[filenames(nfile).name(1:end-5) '_StaticOptimization_force.sto'],subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(9,1),'yes')
                Summarize(fullfile(path,file),[filenames(nfile).name(1:end-5) '_JointReaction_ReactionLoads.sto'],subjectname(subjectnr),mainpath);
            end
        end % if .trc
    end % for nfiles
    delete(gcp('nocreate'))
end % for subjectnr

