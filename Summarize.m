%% Summarize(information about the subject (folder stored,...), Joint contact forces file)
function Summarize(params,input_file,subject,mainpath)

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
disp(data)

%% Define input
%--------------

main_path       = mainpath; 
%Subject         = data.Subject;
Subject         = char(subject); 

path_output     = fullfile(main_path,Subject,'Opensim'); 

%% check for the file 
if isfile(fullfile(path_output,'Stored.mat'))
    load(fullfile(path_output,'Stored.mat'))
else 
end 
%% Initialize processing
%-----------------------
trailname = input_file;
disp(trailname)
temp = char(trailname);
trailname = temp(1:end-32);
% reading in the IK 
IK_path = fullfile(path_output,'InverseKinematics', [trailname '.mot']);
if isfile(IK_path)
Subjects.(char(Subject)).(char(strrep(strrep(strrep(trailname,'#','_'),'-','_'),'+','plus'))).Kinematics = importdata(IK_path);
end 
% reading in the ID 
ID_path = fullfile(path_output,'InverseDynamics', [trailname '.sto']);
if isfile(ID_path)
Subjects.(char(Subject)).(char(strrep(strrep(strrep(trailname,'#','_'),'-','_'),'+','plus'))).Dynamics = importdata(ID_path);
end 
% reading in the SO files 
Muscle_path = fullfile(path_output,'StaticOptimization', [trailname '_StaticOptimization_force.sto']);
if isfile(Muscle_path)
Subjects.(char(Subject)).(char(strrep(strrep(strrep(trailname,'#','_'),'-','_'),'+','plus'))).MuscleForces = importdata(Muscle_path);

Muscle_path = fullfile(path_output,'StaticOptimization', [trailname '_StaticOptimization_activation.sto']);
Subjects.(char(Subject)).(char(strrep(strrep(strrep(trailname,'#','_'),'-','_'),'+','plus'))).MuscleActivations = importdata(Muscle_path);
end 
% reading in the JRF 
JRF_path = fullfile(path_output,'JointReaction', [trailname '_JointReaction_ReactionLoads.sto']);
if isfile(JRF_path)
Subjects.(char(Subject)).(char(strrep(strrep(strrep(trailname,'#','_'),'-','_'),'+','plus'))).JointContactForces = importdata(JRF_path);
end 

save(fullfile(path_output,'Stored.mat'),'Subjects')
save(fullfile(path_output,[trailname '_Done.txt'])) 
disp('Trial saved')

end
