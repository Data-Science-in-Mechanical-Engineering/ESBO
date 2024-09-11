function [Case] = getThreeTankExpPI2Var()


Case.initFun    = @(Case) initFun(Case);
Case.cleanUpFun = @(Case) cleanUpFun(Case);

%path_set

Case.lb                 =   [-0.5 -5];
Case.ub                 =   [0 -2]; % [0.5 -2]
Case.lbFlex             =   [-inf -inf];
Case.ubFlex             =   [inf inf];
Case.objFuncAnon        =   @(Params,yMin) objectiveFunc(Params,yMin);
Case.maxEpisodeLength   =   476;
Case.CaseName           =  'ThreeTankPIExp2VarDetWOConstriant';

Case.OutlierDetectionFun = @(y,g,info) userDefinedOutlierDetectFun(y,g,info);
Case = Case.initFun(Case);
Case.objFuncAnon   = @(Params) objFunDreitankt(Params,'PI_v3');
Case.objFuncAnonES = @(Params,ymin_in) objFunDreitankt(Params,'PI_v3',ymin_in);
Case.cleanUpFun(Case);
end



function [OutlierBool] = userDefinedOutlierDetectFun(y,g,info)
% No crash constraints
OutlierBool = false;
end


function Case = initFun(Case)
Case.initpath = path;
addpath('D:\DSME\MatlabResearchProjects\EarlyStoppingBO\ModelsExperiment')
%load_system('PI_v3_sim')
%set_param('PI_v3_sim','FastRestart','on')
end

function cleanUpFun(Case)

%set_param('PI_v3_sim','FastRestart','off')
%close_system('PI_v3_sim')
path(Case.initpath);
end

