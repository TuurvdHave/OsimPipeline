%% LOAD and Create Sensor Structfs 

% names = {'d1','d2', 'd3', 'd4','d5','d6','d7','d8','d9','d10','d11','d12','d13','d14','d15','d16','d17','d18','d19'};
% 
% DS = struct();
% for i = 1:length(names)
%     if i<10
%         load(['IMU_00', num2str(i), '_v1']);
% %         load(['Session1-00', num2str(i),'_DataM']);
%     else
%         load(['IMU_0', num2str(i), '_v1']);
% %         load(['Session1-0', num2str(i),'_DataM']);
%     end
%     DS.(names{i}) =  OpenIMUs_CreateSensStruct_MVN_v3(fs, a, m, q);
% end
%% SAVE DATA
% save('Data_Struct_S01', 'DS');
%% Movement range
%5) Walk1
% close all;figure;
% plot(DS.d7.femur_r.g(:,2));hold on;
% plot(DS.d7.femur_l.g(:,2));
% plot(DS.d7.pelvis.g(:,1));grid on;


DS.d1.standing_range = 1:10;
DS.d1.sit_range = 11:length(time);
% DS.d1.walking_range = 1:length(time);
% DS.d1.trunk_rot_range = 1:length(time);

