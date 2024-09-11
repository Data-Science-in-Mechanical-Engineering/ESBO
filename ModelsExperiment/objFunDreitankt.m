function varargout = objFunDreitankt(controllerParams,MdlName,ymin_in)
%assign controler parameters
kp = 10^controllerParams(1);       % Default value: 1
ki = 10^controllerParams(2);       % Default value: 0.02
V101_ref = 0;%43.3; % Default value: 43.3



upperBound1stank = 7.5*10^-3;

persistent lastTendClock
if isempty(lastTendClock)
    Parameters.idleTime = 0;
else
    Parameters.idleTime = max(75 - etime(clock,lastTendClock),0);
end
Parameters.stoppingTime  = 10;
Parameters.changeValTime = 5;
Parameters.expTime       = 95;


if nargin == 3
    simStopTheshold     = ymin_in
else
    simStopTheshold = inf;
end
ESSettings.t_obj = 0.2;
ESSettings.TimeOffset = Parameters.idleTime + Parameters.changeValTime;
ESSettings.tstart = 0;
ESSettings.tend = ESSettings.tstart + Parameters.expTime;


simout = sim(MdlName,'SrcWorkspace','current');


%dummy safety constrraing maximum water level
g = double(max(max(simout.waterLevels.signals.values)));

if g > 7.49*10^-3
    info.isOutlier = true;
else
    info.isOutlier = false;
end



lastTendClock = clock;
tstart = min(simout.enableControl.time(simout.enableControl.signals.values > 0.5));
tend = max(simout.enableControl.time(simout.enableControl.signals.values > 0.5)+0.1);


j = simout.j.signals.values;
startInd = find(simout.j.time >= tstart,1);
endInd   = find(simout.j.time >= tend,1);

info.startInd = startInd;
info.endInd   = endInd;
%info.JGt      = sum(info.simoutComplete.j.signals.values(startInd:end));
yVect         = j(startInd:endInd)';
yVect = [yVect zeros(1,476 - length(yVect))];


if info.isOutlier
    yVect(yVect == 0) = max(yVect);  
    episodeLength = 476;
end

y             = sum(yVect);

episodeLength = length(j(startInd:endInd));

%info.simout = simout;
if episodeLength < 476
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










