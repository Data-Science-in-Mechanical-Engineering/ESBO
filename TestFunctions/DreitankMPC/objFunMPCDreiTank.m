function varargout = objFunMPCDreiTank(params,ymin_in)

% addpath(genpath('MPC Essentials'))

%global MPC
%global EKF

%% add MPC Essentials to path

% MPC tuning --> lambda ~ Quotient Q/R
%MPC.lambda = [0.0000005,0.0000005,0.00000005];

%DefaultParameters:

%params = [ -log10([0.0000005,0.0000005,0.00000005]) 0 0 0 ]


% EKF tuning --> three disturbance states, R is fixed
%EKF.lambda = [1 1 1 10^2 5^2 5^2];


upperBound1stank = 7.5*10^-3;

%MPC.lambda = 10.^params(1:3);

MPC.Q_MPCDiag = 10.^params(1:3);        % Regelgrössen
MPC.R_MPCDiag = [1 [10 10].^params(4)]; % Stellgrössen

EKF.lambda = [1 1 1 [100 25 25].*[10 10 10].^params(5)];

T_MPC = 0.1;
N1 = 1;
N2 = 40;
Nu = 10;
PlotEnabled = 0;
StepByStep = 0;

%assignin('base','MPC.lambda',MPC.lambda)
%assignin('base','EKF.lambda',EKF.lambda)
%evalin('base',EKF.lambda)

tstart = 50;
tend   = 150;

%% Real System
%sim("MIMO_MPC_Dreitank");
%sim("MIMO_MPC_Dreitank_EKF")


ESSettings.tstart   = tstart;
ESSettings.tend     = tend;
ESSettings.t_obj    = 0.5;

if nargout == 5
    simStopTheshold = ymin_in;
else
    simStopTheshold = inf;
end




%% Simulated System
%sim("Simulation_MIMO_MPC_Dreitank");
tic
simout = sim("Simulation_MIMO_MPC_Dreitank_EKF",'SrcWorkspace','current');
toc

maxVolume1stTank = double(max(max( simout.waterLevels.signals.values)));






j = simout.j.signals.values;
startInd = find(simout.j.time >= ESSettings.tstart,1);

info.startInd = startInd;
yVect         = j(startInd:end)';
yVect = [yVect zeros(1,1+(ESSettings.tend - ESSettings.tstart)/ESSettings.t_obj - length(yVect))];
y             = sum(j);
episodeLength = length(j(startInd:end));

%info.simout = simout;
if episodeLength < 1+(ESSettings.tend - ESSettings.tstart)/ESSettings.t_obj
    info.earlyStopping = true;
else
    info.earlyStopping = false;
end


if maxVolume1stTank > upperBound1stank
    info.isOutlier = true;
else
    info.isOutlier = false;
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

%%%



end
