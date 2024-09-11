function varargout = objectiveFunc(x,ymin_in)

t_sim = 40;
%CtrlSettings.K = [0 -18 -166.5 -15.2];
%CtrlSettings.K = [-2 -18 -166.5 -15.2];

CtrlSettings.K = -10.^x;

CostMat.Q = 0.5;
CostMat.R = [1 0 0 0];



ESSettings.tstart   = 0;
ESSettings.tend     = t_sim;
ESSettings.t_obj = 0.1;

if nargout == 5
    simStopTheshold = ymin_in
else
    simStopTheshold = inf;
end

simout = sim('CartPoleMathworksModified.slx','SrcWorkspace','current');
info.maxAngle = max(abs(simout.poleAngle.Data))/pi*180;


j = simout.j.signals.values;
startInd = find(simout.j.time >= ESSettings.tstart,1);

info.startInd = startInd;
yVect         = j(startInd:end)';
yVect = [yVect zeros(1,1+(ESSettings.tend - ESSettings.tstart)/ESSettings.t_obj - length(yVect))];
y             = sum(j);
episodeLength = length(j(startInd:end));

info.simout = simout;
if episodeLength < 1+(ESSettings.tend - ESSettings.tstart)/ESSettings.t_obj
    info.earlyStopping = true;
else
    info.earlyStopping = false;
end

g = [];

varargout{1} = y;
varargout{2} = g;

if nargout == 5
    %[y, g, yVect,episodeLength, info]
    varargout{3} = yVect;
    varargout{4} = episodeLength;
    varargout{5} = info;
elseif nargout == 3
    varargout{3} = info;
end

end