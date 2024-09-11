function varargout = objectiveFunc(controlParam,ymin_in)


kp= controlParam(1,1); ki= controlParam(1,2);

tstart = 5;     % start of reference jump
tend   = 100;    % end of reference jump

ESSettings.tstart   = tstart;
ESSettings.tend     = tend;
if nargin == 2
    simStopTheshold     = ymin_in
else
    simStopTheshold = inf;
end
ESSettings.t_obj = 0.2;
simout = sim('Dreitank','SrcWorkspace','current');
info.simout = simout;

j = simout.j.signals.values;
startInd = find(simout.j.time >= tstart,1);

info.startInd = startInd;
%info.JGt      = sum(info.simoutComplete.j.signals.values(startInd:end));
yVect         = j(startInd:end)';
yVect = [yVect zeros(1,476 - length(yVect))];
y             = sum(j);
episodeLength = length(j(startInd:end));

info.simout = simout;
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