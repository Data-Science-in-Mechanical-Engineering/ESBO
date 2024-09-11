function [Case] = getThreeTankMPC5Var()


Case.initFun    = @(Case) initFun(Case);
Case.cleanUpFun = @(Case) cleanUpFun(Case);

%path_set

Case.lb                 =   [6.3010    6.3010    7.3010         0         0] - 3;
Case.ub                 =   [6.3010    6.3010    7.3010         0         0] + 3;
Case.objFuncAnon        =   @(Params,yMin) objectiveFunc(Params,yMin);
Case.maxEpisodeLength   =   201;
Case.CaseName           =  'ThreeTankMPC5VarDetWOConstriant';

Case.OutlierDetectionFun = @(y,g,info) userDefinedOutlierDetectFun(y,g,info);
Case = Case.initFun(Case);
Case.objFuncAnon   = @(Params) objFunMPCDreiTank(Params);
Case.objFuncAnonES = @(Params,ymin_in) objFunMPCDreiTank(Params,ymin_in);
Case.cleanUpFun(Case);
end



function [OutlierBool] = userDefinedOutlierDetectFun(y,g,info)
% No crash constraints
OutlierBool = false;
end


function Case = initFun(Case)
Case.initpath = path;
addpath('TestFunctions\DreitankMPC')
addpath('TestFunctions\DreitankMPC\Simulation')
addpath(genpath('TestFunctions\DreitankMPC\MPC Essentials'))
%load_system('Simulation_MIMO_MPC_Dreitank_EKF')
%set_param('Simulation_MIMO_MPC_Dreitank_EKF','FastRestart','on')
end

function cleanUpFun(Case)

%set_param('Simulation_MIMO_MPC_Dreitank_EKF','FastRestart','off')
close_system('Simulation_MIMO_MPC_Dreitank_EKF')
path(Case.initpath);
end

