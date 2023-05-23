% Close all open figures
close all

% Clear all variables from workspace
clear all

% Clear the command window
clc

% addpath
addpath(genpath(fullfile(cd,'SubFunctions')))
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
    if strcmpi(folders(i).name,'GenericSetup') == 0
        % If it's not, add the folder name to a cell array called "subjectname"
        subjectname{a} = folders(i).name;
        % Increment the counter
        a = a + 1;
    end
end
%% Defining how to time normalize the trials

Firstanswer = inputdlg({'Based on ground reaction forces?','Based on marker data?','Manual crop? (based on timepoints)'...
    },'Time normalize trials',[1 35],{'Yes','No','No'});
if strcmpi(Firstanswer{1,1},'yes')
    Finalanswer = inputdlg({'Threshold begin in N?','Threshold end in N?'...
        },'Based on ground reaction forces!',[1 35],{'50','50'});
elseif strcmpi(Firstanswer{2,1},'yes')
    Finalanswer = inputdlg({'Which marker should to cropping be based on?','Velocity threshold in m/s'...
        },'Based on ground reaction forces!',[1 35],{'LANK','0.05'});
elseif strcmpi(Firstanswer{3,1},'yes')
    answer = questdlg("This is manually a lot of work as you will be asked to put in the time for every trial for every subject. Are you sure?",'Are you sure?',"yes","no","yes");
    if not(strcmpi(answer,'yes'))
        return
    end
end

%% Cropping TRC and MOT
for subjectnr = 1 : size(subjectname,2)
    filenames = dir(char(fullfile(mainpath,subjectname(subjectnr))));
    a = 3;
    for nfile = 3 : size(filenames,1)
        %% analyzing marker data
        if strcmpi(filenames(nfile).name(end-3:end),'.trc')
            [TRC,labels] = importTRCdata(fullfile(filenames(nfile).folder,filenames(nfile).name));
            MOT = importdata(fullfile(filenames(nfile).folder,[filenames(nfile).name(1:end-4) '.mot']));
            [Markers,MLabels,VideoFrameRate,AnalogSignals,ALabels, AUnits, AnalogFrameRate,Event,ParameterGroup,CameraInfo]...
                = readC3D(fullfile(filenames(nfile).folder,[filenames(nfile).name(1:end-4) '.c3d']));
            Frame = [ParameterGroup(1).Parameter(1).data(1,1)/VideoFrameRate ParameterGroup(1).Parameter(2).data(1,1)/VideoFrameRate];
            if strcmpi(Firstanswer{1,1},'yes')
                for i = [2,8]
                    side = MOT.colheaders{i}(4);
                    % start for the left and right leg
                    check = find(sqrt(MOT.data(:,i).^2+MOT.data(:,i+1).^2+MOT.data(:,i+3).^2)>str2num(Finalanswer{1,1}));
                    con = diff(check);
                    checkdiff = find(con>1);
                    start = check(1,1);
                    for ii = 1:size(checkdiff,1)
                        start(ii+1) = check(checkdiff(ii)+1);
                    end
                    clearvars check con checkdiff
                    % stop for the left and right leg
                    check = find(sqrt(MOT.data(:,i).^2+MOT.data(:,i+1).^2+MOT.data(:,i+3).^2)<str2num(Finalanswer{2,1}));
                    con = diff(check);
                    checkdiff = find(con>1);
                    for ii = 1:size(checkdiff,1)
                        stop(ii) = check(checkdiff(ii)+1);
                    end
                    clearvars check con checkdiff
                    maximum = min(size(start,2),size(stop,2));
                    for ii = 1:size(maximum,2)
                        MOTdata = MOT.data(start(ii):stop(ii),:);
                        startTRC = find(TRC(:,2) == round(MOT.data(start(ii),1),2));
                        stopTRC = find(TRC(:,2) == round(MOT.data(stop(ii),1),2));
                        TRCdata = TRC(startTRC:stopTRC,:);
                        writeMarkersToTRC(fullfile(filenames(nfile).folder,[filenames(nfile).name(1:end-4) side num2str(ii) '.trc']),TRCdata(:,3:end),labels(3:end),VideoFrameRate,...
                            [TRCdata(1,1):TRCdata(end,1)]',TRCdata(:,2),'mm');
                        if i == 2 && strcmpi(side,'l')
                            writeGRFsToMOT(MOTdata(:,8:10),MOTdata(:,2:4),MOTdata(:,11:13),MOTdata(:,5:7),MOTdata(:,18),MOTdata(:,15),AnalogFrameRate,...
                                fullfile(filenames(nfile).folder,[filenames(nfile).name(1:end-4) side num2str(ii) '.mot']),MOTdata(:,1));
                        elseif i == 8 && strcmpi(side,'r')
                            writeGRFsToMOT(MOTdata(:,8:10),MOTdata(:,2:4),MOTdata(:,11:13),MOTdata(:,5:7),MOTdata(:,18),MOTdata(:,15),AnalogFrameRate,...
                                fullfile(filenames(nfile).folder,[filenames(nfile).name(1:end-4) side num2str(ii) '.mot']),MOTdata(:,1));
                        elseif i == 2 && strcmpi(side,'r')
                            writeGRFsToMOT(MOTdata(:,2:4),MOTdata(:,8:10),MOTdata(:,5:7),MOTdata(:,11:13),MOTdata(:,15),MOTdata(:,18),AnalogFrameRate,...
                                fullfile(filenames(nfile).folder,[filenames(nfile).name(1:end-4) side num2str(ii) '.mot']),MOTdata(:,1));
                        elseif i == 8 && strcmpi(side,'l')
                            writeGRFsToMOT(MOTdata(:,2:4),MOTdata(:,8:10),MOTdata(:,5:7),MOTdata(:,11:13),MOTdata(:,15),MOTdata(:,18),AnalogFrameRate,...
                                fullfile(filenames(nfile).folder,[filenames(nfile).name(1:end-4) side num2str(ii) '.mot']),MOTdata(:,1));
                          end
                    end
                end
            elseif strcmpi(Firstanswer{2,1},'yes')
            elseif strcmpi(Firstanswer{3,1},'yes')
            end
            delete(fullfile(filenames(nfile).folder,filenames(nfile).name))
            delete(fullfile(filenames(nfile).folder,[filenames(nfile).name(1:end-4) '.mot']))
        end  
    end
end