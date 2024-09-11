function [Case] = getBoilerBangBang1Var()


Case.initFun    = @(Case) initFun(Case);
Case.cleanUpFun = @(Case) cleanUpFun(Case);




%path_set

Case.lb                 =                   5;
Case.ub                 =                   500;

Case.maxEpisodeLength   =   701;
Case.CaseName           =  'BoilerBangBangWOConstriant';

Case.OutlierDetectionFun = @(y,g,info) userDefinedOutlierDetectFun(y,g,info);
Case = Case.initFun(Case);
Case.objFuncAnon   = @(Params) objectiveFunc(Params);
Case.objFuncAnonES = @(Params,ymin_in) objectiveFunc(Params,ymin_in);
Case.cleanUpFun(Case);
end



function [OutlierBool] = userDefinedOutlierDetectFun(y,g,info)
% No crash constraints
OutlierBool = false;
end


function Case = initFun(Case)
Case.initpath = path;
addpath('TestFunctions\Boiler')
load_system('boiler')
%set_param('PT2WDeadTime','FastRestart','on')
end

function cleanUpFun(Case)

%set_param('PT2WDeadTime','FastRestart','off')
%close_system('PT2WithDeadTime')
path(Case.initpath);
end

