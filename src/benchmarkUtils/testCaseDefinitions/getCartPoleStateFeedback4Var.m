function [Case] = getCartPoleStateFeedback4Var()


Case.initFun    = @(Case) initFun(Case);
Case.cleanUpFun = @(Case) cleanUpFun(Case);





xInit = [0.3010    1.2553    2.2214    1.1818];

%path_set

Case.lb                 =                   xInit - [1.5 1 1 1];
Case.ub                 =                   xInit + [1.5 0.5 0.5 0.5];

Case.maxEpisodeLength   =   401;
Case.CaseName           =  'PT2DeatTimePIDDetWOConstriant';

Case.OutlierDetectionFun = @(y,g,info) userDefinedOutlierDetectFun(y,g,info);
Case = Case.initFun(Case);
Case.objFuncAnon   = @(Params) objectiveFunc(Params);
Case.objFuncAnonES = @(Params,ymin_in) objectiveFunc(Params,ymin_in);
Case.cleanUpFun(Case);
end



function [OutlierBool] = userDefinedOutlierDetectFun(y,g,info)
% No crash constraints
OutlierBool = info.maxAngle > 90;
end


function Case = initFun(Case)
Case.initpath = path;
addpath('TestFunctions\CartPole')
load_system('CartPoleMathworksModified')
%set_param('PT2WDeadTime','FastRestart','on')
end

function cleanUpFun(Case)
%set_param('PT2WDeadTime','FastRestart','off')
close_system('CartPoleMathworksModified')
path(Case.initpath);
end

