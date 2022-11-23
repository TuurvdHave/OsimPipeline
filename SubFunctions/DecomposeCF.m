function [MedLatCFR,MedLatCFL] = DecomposeCF(model_in,jrl_in) 

%load OpenSim API
import org.opensim.modeling.*

%load OSIM model
MyModel = Model((model_in));
s = MyModel.initSystem();
MyModel.computeStateVariableDerivatives(s);

jointset = MyModel.getJointSet(); 
bodyset = MyModel.getBodySet(); 
femurR = bodyset.get('femur_r');
Disp = femurR.getDisplayer();
ScaleFactor = ArrayDouble.createVec3([0,0,0]);
Disp.getScaleFactors(ScaleFactor); 
ScaleR = ScaleFactor.get(0);

femurL = bodyset.get('femur_l');
Disp = femurL.getDisplayer();
ScaleFactor = ArrayDouble.createVec3([0,0,0]);
Disp.getScaleFactors(ScaleFactor); 
ScaleL = ScaleFactor.get(0);


%Determine Inter condyle distance
%--------------------------------
dicR = 0.04*ScaleR; 
dicL = 0.04*ScaleL; 


jrf = importdata(jrl_in); 

%Right knee
%----------
mcont = jrf.data(:,find(strcmp('walker_knee_r_on_tibia_r_in_tibia_r_mx',jrf.colheaders)):find(strcmp('walker_knee_r_on_tibia_r_in_tibia_r_mz',jrf.colheaders))); 
fcont = jrf.data(:,find(strcmp('walker_knee_r_on_tibia_r_in_tibia_r_fx',jrf.colheaders)):find(strcmp('walker_knee_r_on_tibia_r_in_tibia_r_fz',jrf.colheaders)));

fcont(:,4) = sqrt(fcont(:,1).^2+fcont(:,2).^2+fcont(:,3).^2);

M= mcont(:,3); 
F = fcont(:,2); 
r1 = dicR/2;
r2 = -dicR/2; 

MedialContactForceR = (M -F*r2)./(r1-r2);
LateralContactForceR = F-MedialContactForceR;

%Left knee
%----------
mcont = jrf.data(:,find(strcmp('walker_knee_l_on_tibia_l_in_tibia_l_mx',jrf.colheaders)):find(strcmp('walker_knee_l_on_tibia_l_in_tibia_l_mz',jrf.colheaders))); 
fcont = jrf.data(:,find(strcmp('walker_knee_l_on_tibia_l_in_tibia_l_fx',jrf.colheaders)):find(strcmp('walker_knee_l_on_tibia_l_in_tibia_l_fz',jrf.colheaders)));

fcont(:,4) = sqrt(fcont(:,1).^2+fcont(:,2).^2+fcont(:,3).^2);

M= mcont(:,3); 
F = fcont(:,2); 
r1 = dicL/2;
r2 = -dicL/2; 

MedialContactForceL = (M -F*r2)./(r1-r2);
LateralContactForceL = F-MedialContactForceL;



%plot to check
%-------------
TotalContactForceR = MedialContactForceR + LateralContactForceR;
TotalContactForceL = MedialContactForceL + LateralContactForceL;


MedLatCFR = [MedialContactForceR,LateralContactForceR];
MedLatCFL = [MedialContactForceL,LateralContactForceL];

% figure
% subplot(121)
% plot(MedialContactForceL,'LineWidth',2);
% hold on
% plot(LateralContactForceL,'LineWidth',2);
% plot(TotalContactForceL,'LineWidth',2);
% title('LeftKnee')
% legend('Medial Contact Force','Lateral Contact Force','Total Contact Force')
% 
% subplot(122)
% plot(MedialContactForceR,'LineWidth',2);
% hold on
% plot(LateralContactForceR,'LineWidth',2);
% plot(TotalContactForceR,'LineWidth',2);
% title('RightKnee')
% legend('Medial Contact Force','Lateral Contact Force','Total Contact Force')

%% COMPARE TO OSIM JOint reaction.

cfR = jrf.data(:,find(strcmp(jrf.colheaders,'walker_knee_r_on_tibia_r_in_tibia_r_fx')):find(strcmp(jrf.colheaders,'walker_knee_r_on_tibia_r_in_tibia_r_fz')));
cfL = jrf.data(:,find(strcmp(jrf.colheaders,'walker_knee_l_on_tibia_l_in_tibia_l_fx')):find(strcmp(jrf.colheaders,'walker_knee_l_on_tibia_l_in_tibia_l_fz')));

cfR(:,4) = sqrt(cfR(:,1).^2 + cfR(:,2).^2 + cfR(:,3).^2);
cfL(:,4) = sqrt(cfL(:,1).^2 + cfL(:,2).^2 + cfL(:,3).^2);

% figure 
% subplot(221)
% plot(cfL,'Linewidth',1.5)
% legend('X','Y','Z','Res')
% title('Opensim: left knee')
% 
% subplot(222)
% plot(cfR,'Linewidth',1.5)
% legend('X','Y','Z','Res')
% title('Opensim: right knee')
% 
% subplot(223)
% plot(cfL(:,[2]),'Linewidth',1.5)
% hold on
% % plot(cfL(:,[4]),'Linewidth',1.5)
% plot(TotalContactForceL,'Linewidth',1.5)
% legend('OpenSim Y','Total')
% title('Opensim vs Decomposition: left knee')
% subplot(224)
% plot(cfR(:,2),'Linewidth',1.5)
% hold on
% % plot(cfR(:,[4]),'Linewidth',1.5)
% plot(TotalContactForceR,'Linewidth',1.5)
% legend('OpenSim Y','Total')
% title('Opensim vs Decomposition: right knee')
