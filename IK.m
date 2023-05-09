function IK(params,input_file,subject,mainpath)
% IK - function to perform inverse kinematics on motion capture data using OpenSim
% Syntax: IK(params,input_file,subject,mainpath)
%
% Inputs:
%   params - a JSON file containing parameters for IK setup
%   input_file - the name of the TRC file to use for IK
%   subject - the name of the subject to process
%   mainpath - the path to the main directory containing all files
%
% Outputs:
%   None
%
% Example usage: IK('params.json', 'motioncapture.trc', 'subject1', '/path/to/files')

% Add required directories to the MATLAB path
addpath(genpath(fullfile(cd,'GenericSetup')))
addpath(genpath(fullfile(cd,'SubFunctions')))

% Load the parameters file (in JSON format)
disp('Loading params file')
fid = fopen(params);
raw = fread(fid,inf);
str = char(raw');
fclose(fid);
data = jsondecode(str);
disp('Loaded parameters')
disp(data);

% Set up paths for input and output files
main_path       = mainpath;
OpenSim_path    = data.osim_path;
Generic_files   = [mainpath,'\GenericSetup'];
Subject         = char(subject);
ik_filter       = data.ik_filter;
AnalogFrameRate = data.AnalogFrameRate;
VideoFrameRate  = data.VideoFrameRate;
path_input      = fullfile(main_path,Subject);
path_output     = fullfile(main_path,Subject,'Opensim');
model_in  = fullfile(main_path,Subject,[Subject '_Scaled.osim']);

% Process each motion trial separately
if isfile(fullfile(main_path,Subject,[input_file(1:end-4) '.csv']))
    Fr = importFrames(fullfile(main_path,Subject,[input_file(1:end-4) '.csv']));
    nfiles = size(Fr,1);
    for file = 3:2:nfiles-1
        if ~contains(input_file,'static')

            % Determine start and end frames
            if strcmp(string(Fr.FootStrike(file)),'Foot Strike') && strcmp(string(Fr.FootStrike(file+1)),'Foot Off')
                Times(file,1) = Fr.Time(file);
                Times(file,2) = Fr.Time(file+1);
                Side = char(Fr.General(file));
            else
                break
            end

            % Set up directories for IK
            output_kin  = fullfile(path_output,'InverseKinematics');
            if ~exist(output_kin);
                mkdir(output_kin);
            end
            setup = fullfile(path_output,'SetUp_InverseKinematics');
            if ~exist(setup);
                mkdir(setup);
            end
            if ~exist([setup,'\log'])
                mkdir([setup,'\log']);
            end

            % Set up the IK parameters in an XML file
            SetupIK = xml_read(strcat(Generic_files, '\IK_Generic.xml'));
            SetupIK.InverseKinematicsTool.model_file = [model_in];
            SetupIK.InverseKinematicsTool.time_range = [string(Times(file,1)),' ' string(Times(file,2))];
            SetupIK.InverseKinematicsTool.marker_file = strcat(path_input,'\', input_file);
            SetupIK.InverseKinematicsTool.output_motion_file = strcat(output_kin,'\', input_file(1:end-4), Side ,num2str((file-1)/2),'.mot');
            SetupIK.InverseKinematicsTool.results_directory = output_kin;
            xml_write(fullfile(setup,[input_file(1:end-4) Side num2str((file-1)/2) '.xml' ]), SetupIK, 'OpenSimDocument');

            % Run the IK tool

            %commando = fullfile(setup,[input_file(1:end-4) Side num2str((file-1)/2) '.xml' ]);
            commando = [fullfile(setup,[input_file(1:end-4) Side num2str((file-1)/2) '.xml' ]) ' > ' fullfile(setup,'log',[input_file(1:end-4) Side num2str((file-1)/2) '.log'])];

            if contains(OpenSim_path,'3.')
                exe_path=[OpenSim_path 'ik.exe'];
                full_command = [exe_path ' -S  ' commando];
            elseif contains(OpenSim_path,'4.')
                exe_path=[OpenSim_path 'opensim-cmd.exe'];
                full_command = [exe_path ' run-tool  ' commando];
            end

            system(full_command);

            if isfile(strcat(output_kin,'\', input_file(1:end-4), Side ,num2str((file-1)/2),'.mot'))
                disp('IK done')
            else
                f = warndlg({'NOPE! Your Inverse kinematics did not work.';...
                    'This could have multiple reasons:';...
                    '1) Check your OpenSim path in param.json and do not forget the double \\';...
                    '2) Make sure the folder construction is similar to the one in the readme.';...
                    '3) All paths can not contain spaces as the windows command shell is not able to handle this';...
                    });
            end

        end %if static
    end % for frames
else
    if ~contains(input_file(1:end-4),'static')
        % Set up directories for IK
        output_kin  = fullfile(path_output,'InverseKinematics');
        if ~exist(output_kin)
            mkdir(output_kin);
        end
        setup = fullfile(path_output,'SetUp_InverseKinematics');
        if ~exist(setup)
            mkdir(setup);
        end
        if ~exist([setup,'\log'])
            mkdir([setup,'\log']);
        end

        %r Read in the trc-file to extract the time

        [TRCdata, labels] = importTRCdata(char(fullfile(main_path,Subject,input_file)));

        % Set up the IK parameters in an XML file

        SetupIK = xml_read(strcat(Generic_files, '\IK_Generic.xml'));
        SetupIK.InverseKinematicsTool.model_file = [model_in];
        SetupIK.InverseKinematicsTool.time_range = [string(TRCdata(1,2)) ' ' string(TRCdata(end,2))];
        SetupIK.InverseKinematicsTool.marker_file = strcat(path_input,'\', input_file(1:end-4), '.trc');
        SetupIK.InverseKinematicsTool.output_motion_file = strcat(output_kin,'\', input_file(1:end-4),'.mot');
        SetupIK.InverseKinematicsTool.results_directory = output_kin;
        xml_write(fullfile(setup,[input_file(1:end-4) '.xml' ]), SetupIK, 'OpenSimDocument');

        % Run the IK tool

        %commando = [fullfile(setup,[input_file(1:end-4) '.xml' ])];
        commando = [fullfile(setup,[input_file(1:end-4) '.xml' ]) ' > ' fullfile(setup,'log',[input_file(1:end-4) '.log'])];


        if contains(OpenSim_path,'3.')
            exe_path=[OpenSim_path 'ik.exe'];
            full_command = [exe_path ' -S  ' commando];
        elseif contains(OpenSim_path,'4.')
            exe_path=[OpenSim_path 'opensim-cmd.exe'];
            full_command = [exe_path ' run-tool  ' commando];
        end

        system(full_command);

        if isfile(strcat(output_kin,'\', input_file(1:end-4), Side ,num2str((file-1)/2),'.mot'))
            disp('IK done')
        else
            f = warndlg({'NOPE! Your Inverse kinematics did not work.';...
                'This could have multiple reasons:';...
                '1) Check your OpenSim path in param.json and do not forget the double \\';...
                '2) Make sure the folder construction is similar to the one in the readme.';...
                '3) All paths can not contain spaces as the windows command shell is not able to handle this';...
                });
        end
    end
end
