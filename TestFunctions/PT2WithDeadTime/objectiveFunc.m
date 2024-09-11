function varargout = objectiveFunc(x,PlantSettings,ymin_in)

t_sim = 50;

CtrlSettings.kp  = 10^x(1);
CtrlSettings.ki  = 10^x(2);
CtrlSettings.kd  = 10^x(3);

disp('kp ki kd')
disp([CtrlSettings.kp CtrlSettings.ki CtrlSettings.kd ]);


ESSettings.tstart   = 0;
ESSettings.tend     = t_sim;
ESSettings.t_obj = 0.1;

if nargout == 5
    simStopTheshold = ymin_in
else
    simStopTheshold = inf;
end

simout = sim('PT2WDeadTime.slx','SrcWorkspace','current');
w = simout.w.signals.values;
y = simout.y.signals.values;

overshootInds = find(y > w);
if isempty(overshootInds)
    riseTime = simout.tout(end);
else
    riseTime = simout.tout(overshootInds(1));
end

sgnerror = sign(w-y);

info.NoOfOscillations = sum(sgnerror(1:end-1) ~= sgnerror(2:end));

overShoot = max(max(y - w),0);
steadyStateError = abs(y(end) - w(end));

info.riseTime               = riseTime;
info.OverShoot              = overShoot;
info.steadyStateError       = steadyStateError;



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