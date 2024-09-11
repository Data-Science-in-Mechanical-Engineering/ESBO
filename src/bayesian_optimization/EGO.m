function [State,Stats] = EGO(Case,Settings)
%Main BO Script. EGO: Efficient Global Optimization

origPath = path;


[Case,Settings] = verifyDescription(Case,Settings);

splittedPath = strsplit(mfilename('fullpath'),'\');

addpath([strjoin(splittedPath(1:end-1),'\'),'\Metamodelling'])
addpath([strjoin(splittedPath(1:end-1),'\'),'\gpml-matlab-v4.1-2017-10-19'])
addpath([strjoin(splittedPath(1:end-1),'\'),'\src'])
addpath([strjoin(splittedPath(1:end-1),'\'),'\src\acquisitionFun']) 
addpath([strjoin(splittedPath(1:end-1),'\'),'\simulinkUtils'])
startup

[State] = initState(Settings);

Stats.sucEvals(1) = 0;

if ~isfield(Case,'IntegerFlag')
    Case.IntegerFlag = logical(zeros(size(Case.lb)));
  
end

%Initial Sampling

if strcmp(Settings.InitsampleMode,'Rand') 
    [X,Case] = randomSampling(Case,Settings.initSampleSize);
elseif strcmp(Settings.InitsampleMode,'List')
    X = Case.Initsamples;
else
    error('Unknown Initial random sampling mode.')
end

disp('Perform initial sampling')

if ~strcmp(Settings.InitsampleMode,'PrevSampling')
    [State,Case] = evalSamples(State,Case,X,Settings,true);
end

if isfield(Settings,'OutlierDetection')
    if strcmp(Settings.OutlierDetection,'UserDefined')
        [State,Stats] = outlierDetectionUDF(State,Settings.OutlierDetectionSettings,Settings,Stats,Case);
    else
        error('Unknown outlier detection method!')
    end
end

if Settings.enableEarlyEvalStop
    State = genESVirtDat(State,Settings,Case);
end

[State] = fitMetaModels(State,Settings,Stats,Case);


if isempty(State.EvalSamples.X)
    return
end

State = checkConstraints(State,Case,Settings);

[State] = getOptSolEval(State,Stats,Settings);

[Stats,State] = updateStatsIter(Stats, State,Settings);

%Enter main Optimisation loop

State.stopOptimization = false;

[State] = checkConveregence(Stats,State,Settings);


while ~State.stopOptimization
    %Retrieve Context if Optimization is contextual
    
    
    newSampleFound = false;
    while ~newSampleFound
        if isfield(Settings,'OutlierClassification') || (isfield(Settings,'ESSettings') && Settings.ESSettings.useVDPHeuristic)
            if strcmp(Settings.OutlierClassification,'virtualData')
                State = outClassVirtDat(State,Stats,Case,Settings);
                State.pOutlierFun =@(x) zeros(size(x,1),1);
            else
                State.pOutlierFun =@(x) zeros(size(x,1),1);
            end
        else
            State.pOutlierFun =@(x) zeros(size(x,1),1);
        end
        

        State.pFailedFun =@(x) zeros(size(x,1),1);



        if any(State.EvalSamples.EvalPending)
            [State] = evalPendingVirtDat(State,Stats,Case,Settings);
        end
        
        %prepare infillkrit
        if strcmp(Settings.Infillkrit,'MES')
            infillKritfunc = prepMES(State,Settings,Case);
        else
            error('Unknown infill criterion.')
        end
        
        %Optimize Infillkriterion
        
            if strcmp(Settings.SurrogateOptimizer,'RandSearch')
                [X,State]= resSurfRS(Case,State,infillKritfunc,Settings);
            elseif strcmp(Settings.SurrogateOptimizer,'Rand')
                [X,Case] = randomSampling(Case,Settings.NoOfSamplesPerIter);
            else
                error('Unknown surrogate Optimizer.')
            end
       

            newSampleFound = true;
        
    end
    
    
    
    [State,Case] = evalSamples(State,Case,X,Settings);
    
    
    if isfield(Settings,'OutlierDetection')
        if strcmp(Settings.OutlierDetection,'UserDefined')
            [State,Stats] = outlierDetectionUDF(State,Settings.OutlierDetectionSettings,Settings,Stats,Case);
  
        else
            error('Unknown outlier detection method!')
        end
    end
    
    if Settings.enableEarlyEvalStop
        State = genESVirtDat(State,Settings,Case);
    end

    
    
    [State] = fitMetaModels(State,Settings,Stats,Case);
    
    
    
    State = checkConstraints(State,Case,Settings);
    
    
    
    [State] = getOptSolEval(State,Stats,Settings);
    

    
    [Stats,State] = updateStatsIter(Stats, State,Settings);

    [State] = checkConveregence(Stats,State,Settings);

    % Save workspace to the log folder
    if isfield(Settings,'saveWS') && Settings.saveWS
        % Chech wether the Folder Exists
    if ~exist('log', 'dir')
       mkdir('log')
    end 
        save(['log/',Case.CaseName,'_iter_',num2str(State.currIter)])
    else
        warning('Auto safe disabeled')
    end
    
end

path(origPath);

end


function [Case,Settings] = verifyDescription(Case,Settings)

if ~isfield(Settings,'enableEarlyEvalStop')
    Settings.enableEarlyEvalStop = false;
end

if ~isfield(Settings,'enableLMMPrior')
    Settings.enableLMMPrior= false;
end

if Settings.enableLMMPrior
    if ~strcmp(Settings.Infillkrit,'EIWithPrior')
        error('with the setting Settings.enableLMMPrior enabled, only the accquisition function EIWithPrior is supported')
    end
end



if ~isfield(Settings,'ESSettings') || ~isfield(Settings.ESSettings,'useEpisodeTimeMax')
    Settings.ESSettings.useEpisodeTimeMax = false;
end


if ~isfield(Settings,'evaluationDelay')
    Settings.evaluationDelay = 0;
else
    if Settings.initSampleSize < 1 + Settings.evaluationDelay
        error('Too little initial samples provided to satisfy the evaluation delay')
    end
end


end