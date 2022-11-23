function [LigamentMoment] = determineLigMoment(model_in, kin_in,Misc);
%load OpenSim API
import org.opensim.modeling.*

%load OSIM model
MyModel = Model((model_in));
s = MyModel.initSystem();
MyModel.computeStateVariableDerivatives(s);

coordinateSet = MyModel.getCoordinateSet();
nCoordinates = coordinateSet.getSize();

modelForceSet = MyModel.getForceSet();
nForces = modelForceSet.getSize();

motion = importdata(kin_in);
nJoints = size(motion.colheaders,2)-1;

for time = 1:size(motion.data,1)
    %update state
    for joint = 2:nJoints+1;
        editableCoordSet = MyModel.updCoordinateSet();
        editableCoordSet.get(motion.colheaders{joint}).setValue(s, motion.data(time,joint).*(2*pi()/360));
    end
    for forcenr = 0:nForces-1
        
        if strcmp(modelForceSet.get(forcenr).getConcreteClassName, 'Ligament')
            
            MyLig = Ligament.safeDownCast(modelForceSet.get(forcenr));
            Name = MyLig.getName();
            
            MyLigFLC = MyLig.getForceLengthCurve();
            MyFunction = SimmSpline.safeDownCast(MyLigFLC);
            xArr = MyFunction.getX();
            yArr = MyFunction.getY();
            
            for i = 0:size(xArr)-1;
                X(i+1) = xArr.get(i);
                Y(i+1) = yArr.get(i);
                
                
            end
            
            RestLength = MyLig.getRestingLength();
            CurrentLength = MyLig.getLength(s);
            
            Strain.(Name.toCharArray)(time) =  (CurrentLength )./RestLength;%- RestLength
            RelForce.(Name.toCharArray)(time) =  interp1(X,Y,Strain.(Name.toCharArray)(time));
            Force_form.(Name.toCharArray')(time,1) = RelForce.(Name.toCharArray)(time)*MyLig.getMaxIsometricForce();
            
            for coord = 1:size(Misc.DofNames_Input,2);
                MomentArm.(Name.toCharArray')(time,coord) =  MyLig.computeMomentArm(s,coordinateSet.get(Misc.DofNames_Input{coord}));
            end
        end
    end
end

ligaments = fieldnames(MomentArm);
for lig = 1:size(ligaments,1);
    MomentArm.(ligaments{lig})(abs(MomentArm.(ligaments{lig}))<0.0001)=0;
    Moment(:,:,lig) = Force_form.(ligaments{lig}) .* MomentArm.(ligaments{lig});
    
end

LigamentMoment = sum(Moment,3); 


end
