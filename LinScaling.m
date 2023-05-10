function LinScaling(params,subject,mainpath,height,weight)
% Model Linear Scaling - function to perform linear scaling in OpenSim
% Syntax: LinScaling(params,input_file,subject,mainpath,height,weight)
%
% Inputs:
%   params - a JSON file containing parameters for IK setup
%   subject - the name of the subject to process
%   mainpath - the path to the main directory containing all files
%   height - height of the subject 
%   weight - weight of the subject 
%
% Outputs:
%   Scaled model 
%
% Example usage: IK('params.json', 'subject1', '/path/to/files', 175, 65)

% Add required directories to the MATLAB path
addpath(genpath(fullfile(cd,'GenericSetup')))
addpath(genpath(fullfile(cd,'SubFunctions')))

% Load the parameters file (in JSON format)
fid = fopen(params); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
data = jsondecode(str);

% Set up paths for input and output files
main_path       = mainpath; 
OpenSim_path    = data.osim_path; 
Generic_files   = [mainpath,'\GenericSetup'];
Subject         = char(subject); 
path_input      = fullfile(main_path,Subject); 
path_output     = fullfile(main_path,Subject,'Opensim'); 

% Linear scale the participant
scale_factor = height/171;

%prepare directories
%-------------------
setupscale = fullfile(path_output,'Setup_Scale');
if ~exist(setupscale)
    mkdir(setupscale);
end

% Creating the Scaling Tool

Scaling = xml_read(strcat(Generic_files,'/Scaling_Generic.xml'));
for i = 1:size(Scaling.ScaleTool.ModelScaler.ScaleSet.objects.Scale,2)
    Scaling.ScaleTool.ModelScaler.ScaleSet.objects.Scale(i).scales =  [scale_factor,scale_factor,scale_factor];
end
Scaling.ScaleTool.mass = weight;
Scaling.ScaleTool.height = height;
Scaling.ScaleTool.GenericModelMaker.model_file = [Generic_files,'/Generic.osim'];
Scaling.ScaleTool.MarkerPlacer.output_model_file = [path_input,'/',Subject,'.osim'];
Scaling.ScaleTool.ModelScaler.output_model_file = [path_input,'/',Subject,'.osim'];

Pref.StructItem = false;
xml_write(fullfile(setupscale,['scale_setup.xml']), Scaling, 'OpenSimDocument',Pref);

% run the scaling 

commando = fullfile(setupscale,['scale_setup.xml']);

exe_path=[OpenSim_path 'opensim-cmd.exe'];
full_command = [exe_path ' run-tool "'  commando];

system(full_command);

disp('Scaling done')
