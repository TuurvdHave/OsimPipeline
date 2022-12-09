close all 
clear all 
clc 
%% Input parameters for the code (no paths need to be adapted)
mainpath = uigetdir(cd,'Select the folder where you stored your project with all particpants');
folders = dir(mainpath);
a = 1; 
for i = 3 : size(folders,1)
    if strcmpi(folders(i).name,'GenericSetup') == 0 
        subjectname{a} = folders(i).name;
        a = a + 1; 
    end 
end 
[file,path] = uigetfile('*.*','Select params.json file to define specific inputs');
answer = inputdlg({'IK? Answer with yes or no','KS?','ID?','SO?','DO?','JRF?','Save in .mat?'},'Analyses',[1 35],{'yes','yes','yes','yes','yes','yes','yes'});
%% Running the analysis 
for subjectnr = 1 : size(subjectname,2)
    filenames = dir(char(fullfile(path,subjectname(subjectnr))));
    for nfile = 3 : size(filenames,1)
        if strcmpi(filenames(nfile).name(end-3:end),'.trc')
            if strcmpi(answer(1,1),'yes')
            IK(fullfile(path,file),filenames(nfile).name,subjectname(subjectnr),mainpath);
            end 
            if strcmpi(answer(2,1),'yes')
            KS(fullfile(path,file),filenames(nfile).name,subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(3,1),'yes')
            ID(fullfile(path,file),[filenames(nfile).name(1:end-4) '.mot'],subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(4,1),'yes')
            SO(fullfile(path,file),[filenames(nfile).name(1:end-4) '_ExternalLoads.xml'],subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(5,1),'yes')
            DO(fullfile(path,file),[filenames(nfile).name(1:end-4) '_ExternalLoads.xml'],subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(6,1),'yes')
            JRF(fullfile(path,file),[filenames(nfile).name(1:end-4) '_StaticOptimization_force.sto'],subjectname(subjectnr),mainpath);
            end
            if strcmpi(answer(7,1),'yes')
            Summarize(fullfile(path,file),[filenames(nfile).name(1:end-4) '_JointReaction_ReactionLoads.sto'],subjectname(subjectnr),mainpath);
            end 
        end 
    end 
end 