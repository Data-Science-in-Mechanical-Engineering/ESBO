function [Case] = getThreeTankPI2Var()


Case.initFun    = @(Case) initFun(Case);
Case.cleanUpFun = @(Case) cleanUpFun(Case);

%path_set

Case.lb                 =   [0        0];
Case.ub                 =   [3      0.1];
Case.objFuncAnon        =   @(Params,yMin) objectiveFunc(Params,yMin);
Case.maxEpisodeLength   =   476;
Case.CaseName           =  'ThreeTankPI2VarDetWOConstriant';

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
addpath('D:\DSME\MatlabResearchProjects\TestFunctions\Dreitank')
load_system('Dreitank')
set_param('Dreitank','FastRestart','on')
end

function cleanUpFun(Case)

set_param('Dreitank','FastRestart','off')
close_system('Dreitank')
path(Case.initpath);
end

