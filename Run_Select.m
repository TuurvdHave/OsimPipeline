% Close all open figures
close all

% Clear all variables from workspace
clear all

% Clear the command window
clc

%% Input parameters for the code (no paths need to be adapted)

% selecting multiple or just one trail to analyse
[trcFilenames,path] = uigetfile('*',  'Select .trc or .MVNX files to process . . .',  'MultiSelect', 'on');
tss = strsplit(path,'\');
subjectname = tss{end-1};
mainpath = fullfile(tss{1:end-2});

% Use uigetfile to allow the user to select the params.json file for specific inputs
[file,path] = uigetfile('*.*','Select params.json file to define specific inputs');

tf = iscellstr(trcFilenames);
if tf == 0
    LengthFilenames = 1;
else
    LengthFilenames = length(trcFilenames);
end

% answering which steps of the pipeline to run. This is not performed
% automatically as the codes wants to run parallell computations
MoInanswer = inputdlg({'Are you analyzing Mocap or Incap data'},'Analyses',[1 35],{'Mocap/Incap'});
if strcmpi(MoInanswer{1},'Mocap')
    answer = inputdlg({'IK? Answer with yes or no','KS?','ID?','SO?','DO?','JRF?','Save in .mat?'},'Analyses',[1 35],{'yes','no','yes','yes','no','yes','yes'});
elseif strcmpi(MoInanswer{1},'Incap')
    answer = inputdlg({'Scaling? Answer with yes or no','Convert to STO?','Dynamic calibration?','IK?','ID?','SO?','DO?','JRF?','Save in .mat?'},'Analyses',[1 35],{'yes','yes','yes','no','no','no','no','no','no'});
end

    if strcmpi(MoInanswer{1},'Incap') && strcmpi(answer(1,1),'yes') && ~exist(char(fullfile(mainpath,subjectname,[char(subjectname) '.osim'])))
        height(subjectnr) = str2double(inputdlg(['Type the height of ' subjectname  ' (cm):']));
        weight(subjectnr) = str2double(inputdlg(['Type the weight of ' subjectname ' (kg):']));
    end


parpool(3)
parfor x = 1:LengthFilenames
    filename = char(trcFilenames(x));
    %% analyzing marker data
    if strcmpi(filename(end-3:end),'.trc') && strcmpi(MoInanswer{1},'Mocap')
        % Use inputdlg to get yes or no answers to questions about which analyses to run
        if strcmpi(answer(1,1),'yes')
            IK(fullfile(path,file),filename,subjectname,mainpath);
        end
        if strcmpi(answer(2,1),'yes')
            KS(fullfile(path,file),filename,subjectname,mainpath);
        end
        % when events are used in vicon one .trc can result in multiple .mot files.
        % the name of output kinematicfiles
        % will be changed according to the event. The final name is
        % checked here.
        kinfile = dir(char(fullfile(mainpath,subjectname,'OpenSim\InverseKinematics')));
        kinfilenames = {kinfile(~[kinfile.isdir]).name};
        for f = 1 : sum(contains(kinfilenames,filename(1:end-4)))
            [row,col] = find(contains(kinfilenames,filename(1:end-4)));
            sub = char(kinfilenames(:,col(f)));
            finfilename = sub(1:end-4);
            if strcmpi(answer(3,1),'yes')
                ID(fullfile(path,file),[finfilename '.mot'],subjectname,mainpath);
            end
            if strcmpi(answer(4,1),'yes')
                SO(fullfile(path,file),[finfilename '_ExternalLoads.xml'],subjectname,mainpath);
            end
            if strcmpi(answer(5,1),'yes')
                DO(fullfile(path,file),[finfilename '_ExternalLoads.xml'],subjectname,mainpath);
            end
            if strcmpi(answer(6,1),'yes')
                JRF(fullfile(path,file),[finfilename '_StaticOptimization_force.sto'],subjectname,mainpath);
            end
            if strcmpi(answer(7,1),'yes')
                Summarize(fullfile(path,file),[finfilename '_JointReaction_ReactionLoads.sto'],subjectname,mainpath);
            end

        end
        %% Analyzing the IMU data
    elseif strcmpi(filename(end-4:end),'.mvnx') && strcmpi(MoInanswer{1},'Incap')
        % Use inputdlg to get yes or no answers to questions about which analyses to run
        if strcmpi(answer(1,1),'yes') && ~exist(char(fullfile(mainpath,subjectname,[char(subjectname) '.osim'])))
            LinScaling(fullfile(path,file),subjectname,mainpath,height(subjectnr),weight(subjectnr));
        end
        if strcmpi(answer(2,1),'yes')
            MVNXtoSTO(fullfile(path,file),filename,subjectname,mainpath);
        end
        if strcmpi(answer(3,1),'yes') && ~exist(char(fullfile(mainpath,subjectname,[char(subjectname) '_Scaled.osim'])))
            MVNXtoSTO(fullfile(path,file),'squat.mvnx',subjectname,mainpath);
            MVNXtoSTO(fullfile(path,file),'hipfront.mvnx',subjectname,mainpath);
            IMU_Placer_GdR(fullfile(path,file),subjectname,mainpath);
        elseif strcmpi(answer(3,1),'no')
            MVNXtoSTO(fullfile(path,file),'Static.mvnx',subjectname,mainpath);
            IMU_Placer(fullfile(path,file),subjectname,mainpath);
        end
        if strcmpi(answer(4,1),'yes')
            IMU_IK(fullfile(path,file),filename,subjectname,mainpath);
        end
        if strcmpi(answer(5,1),'yes')
            ID(fullfile(path,file),[filename(1:end-5) '.mot'],subjectname,mainpath);
        end
        if strcmpi(answer(6,1),'yes')
            SO(fullfile(path,file),[filename(1:end-5) '_ExternalLoads.xml'],subjectname,mainpath);
        end
        if strcmpi(answer(7,1),'yes')
            DO(fullfile(path,file),[filename(1:end-5) '_ExternalLoads.xml'],subjectname,mainpath);
        end
        if strcmpi(answer(8,1),'yes')
            JRF(fullfile(path,file),[filename(1:end-5) '_StaticOptimization_force.sto'],subjectname,mainpath);
        end
        if strcmpi(answer(9,1),'yes')
            Summarize(fullfile(path,file),[filename(1:end-5) '_JointReaction_ReactionLoads.sto'],subjectname,mainpath);
        end
    end % if .trc
end % for nfiles
delete(gcp('nocreate'))