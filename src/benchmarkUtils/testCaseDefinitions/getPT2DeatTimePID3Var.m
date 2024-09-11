function [Case] = getPT2DeatTimePID3Var()


Case.initFun    = @(Case) initFun(Case);
Case.cleanUpFun = @(Case) cleanUpFun(Case);


PlantSettings.K     = 4;
PlantSettings.w0    = 0.5;
PlantSettings.D     = 0.5;
PlantSettings.DeadTime     = round(0.1/0.01);




%path_set

Case.lb                 =                   log10([0.1 0.1 0.1]);
Case.ub                 =                   log10([10  10  10]);

Case.maxEpisodeLength   =   501;
Case.CaseName           =  'PT2DeatTimePIDDetWOConstriant';

Case.OutlierDetectionFun = @(y,g,info) userDefinedOutlierDetectFun(y,g,info);
Case = Case.initFun(Case);
Case.objFuncAnon   = @(Params) objectiveFunc(Params,PlantSettings);
Case.objFuncAnonES = @(Params,ymin_in) objectiveFunc(Params,PlantSettings,ymin_in);
Case.cleanUpFun(Case);
end



function [OutlierBool] = userDefinedOutlierDetectFun(y,g,info)
% No crash constraints
OutlierBool = info.OverShoot > 2;
end


function Case = initFun(Case)
Case.initpath = path;
addpath('TestFunctions\PT2WithDeadTime')
load_system('PT2WDeadTime')
%set_param('PT2WDeadTime','FastRestart','on')
end

function cleanUpFun(Case)

%set_param('PT2WDeadTime','FastRestart','off')
%close_system('PT2WithDeadTime')
path(Case.initpath);
end

