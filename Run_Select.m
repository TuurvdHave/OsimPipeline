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

for x = 1:length(trcFilenames)
    if iscell(trcFilenames)
        filename = char(trcFilenames(x));
    elseif isstr(trcFilenames)
        filename = char(trcFilenames);
    end
    a = 3;
    %% Running the analysis
    if strcmpi(filename(end-3:end),'.trc')
        % Use inputdlg to get yes or no answers to questions about which analyses to run
        if ~exist('answer')
            answer = inputdlg({'IK? Answer with yes or no','KS?','ID?','SO?','DO?','JRF?','Save in .mat?'},'Analyses',[1 35],{'yes','yes','yes','yes','yes','yes','yes'});
        end
        if strcmpi(answer(1,1),'yes')
            IK(fullfile(path,file),filename,subjectname,mainpath);
        end
        if strcmpi(answer(2,1),'yes')
            KS(fullfile(path,file),filename,subjectname,mainpath);
        end
        % when events files are used the name of output kinematicfiles
        % will be changed according to the event. The final name is
        % checked here
        kinfilenames = dir(char(fullfile(mainpath,subjectname,'OpenSim\InverseKinematics')));
        if strcmpi(filename,kinfilenames(a).name(1:end-4)) % if no events are detected
            finfilename = filename;
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
            a = a + 1;
        else
            for ii = a : size(kinfilenames,1)
                if not(strcmpi(kinfilenames(a).name(end-3:end),'.sto'))
                    finfilename = kinfilenames(a).name(1:end-4);
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
                    a = a +1;
                end
            end
        end
        %% Analyzing the IMU data
    elseif strcmpi(filenames(nfile).name(end-4:end),'.mvnx')
        % Use inputdlg to get yes or no answers to questions about which analyses to run
        if ~exist('answer')
            answer = inputdlg({'Scaling? Answer with yes or no','Convert to STO?','Dynamic calibration?','IK?','ID?','SO?','DO?','JRF?','Save in .mat?'},'Analyses',[1 35],{'yes','yes','yes','no','no','no','no','no','no'});
        end
        if strcmpi(answer(1,1),'yes') && ~exist(char(fullfile(mainpath,subjectname,[char(subjectname) '.osim'])))
            height = str2double(inputdlg('Type the height of the participant (cm):'));
            weight = str2double(inputdlg('Type the weight of the participant (kg):'));
            LinScaling(fullfile(path,file),subjectname,mainpath,height,weight);
        end
        if strcmpi(answer(2,1),'yes')
            MVNXtoSTO(fullfile(path,file),filenames(nfile).name,subjectname,mainpath);
        end
        if strcmpi(answer(3,1),'yes') && ~exist(char(fullfile(mainpath,subjectname,[char(subjectname) '_Scaled.osim'])))
            MVNXtoSTO(fullfile(path,file),'squat.mvnx',subjectname,mainpath);
            MVNXtoSTO(fullfile(path,file),'hipfront.mvnx',subjectname,mainpath);
            IMU_Placer_GdR(fullfile(path,file),subjectname,mainpath);
        elseif strcmpi(answer(3,1),'no') && ~exist(char(fullfile(mainpath,subjectname,[char(subjectname) '_Scaled.osim'])))
            MVNXtoSTO(fullfile(path,file),'Static.mvnx',subjectname,mainpath);
            IMU_Placer(fullfile(path,file),subjectname,mainpath);
        end
        if strcmpi(answer(4,1),'yes')
            IMU_IK(fullfile(path,file),filenames(nfile).name,subjectname,mainpath);
        end
        if strcmpi(answer(5,1),'yes')
            ID(fullfile(path,file),[filenames(nfile).name(1:end-5) '.mot'],subjectname,mainpath);
        end
        if strcmpi(answer(6,1),'yes')
            SO(fullfile(path,file),[filenames(nfile).name(1:end-5) '_ExternalLoads.xml'],subjectname,mainpath);
        end
        if strcmpi(answer(7,1),'yes')
            DO(fullfile(path,file),[filenames(nfile).name(1:end-5) '_ExternalLoads.xml'],subjectname,mainpath);
        end
        if strcmpi(answer(8,1),'yes')
            JRF(fullfile(path,file),[filenames(nfile).name(1:end-5) '_StaticOptimization_force.sto'],subjectname,mainpath);
        end
        if strcmpi(answer(9,1),'yes')
            Summarize(fullfile(path,file),[filenames(nfile).name(1:end-5) '_JointReaction_ReactionLoads.sto'],subjectname,mainpath);
        end

    end % if .trc
end
