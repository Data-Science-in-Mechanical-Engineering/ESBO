function [State,Case] = evalSamples(State,Case,XOrig,Settings,optimizationStartUp)


if nargin < 5
    optimizationStartUp = false;
end

c1 = clock;
failedBool = [];
Constrnt   = [];
X = [];
Y = [];
Constrnt = [];
customNoOfEvals = 0;
if isfield(Settings,'enableEarlyEvalStop') && Settings.enableEarlyEvalStop
    YVect = [];
    episodeLength = [];
end


    

for i = 1:size(XOrig,1)
    disp([num2str(i),'/',num2str(size(XOrig,1))])
    if isfield(Settings,'enableEarlyEvalStop') && Settings.enableEarlyEvalStop
        
        [tempY,tempConstraint,tempYVect,tempepisodeLength,tempInfo] = Case.objFuncAnonES(XOrig(i,:),State.ES.yMin);
        if ~isa(tempY,'double') 
            error('objective function needs to return a double. Otherwise the GPML toolbox breaks')
        end
        if ~isempty(tempConstraint) && ~isa(tempConstraint,'double') 
            error('objective function needs to return a double. Otherwise the GPML toolbox breaks')
        end
        
        
        
        YVect =  [YVect;tempYVect];
        episodeLength = [episodeLength;tempepisodeLength]; 
    else
        [tempY,tempConstraint,tempInfo] = Case.objFuncAnon(XOrig(i,:));
        if ~isa(tempY,'double')
            error('objective function needs to return a double. Otherwise the GPML toolbox breaks')
        end
        if ~isempty(tempConstraint) && ~isa(tempConstraint,'double') 
            error('objective function needs to return a double. Otherwise the GPML toolbox breaks')
        end
    end
        
    
    if isfield(Settings,'simFailedClassifier') && Settings.simFailedClassifier == true && tempInfo.simulationFailed
        failedBool = [failedBool;true];
    else
        failedBool = [failedBool;false];
    end
    tempNoOfEvals = size(tempY,1);
    Y = [Y;tempY];
    X = [X;repmat(XOrig(i,:),tempNoOfEvals,1)];
    if ~isempty(tempConstraint)
        Constrnt= [Constrnt;tempConstraint];%TempConstrnt;
    end
    info{i} = tempInfo;
    if isfield(tempInfo,'totalNumberOfEvals')
        customNoOfEvals = customNoOfEvals + tempInfo.totalNumberOfEvals;
    end
    
    if isfield(info{1,1},'OptimizedPostProcParams')
        OptPostProcParamsTemp(i,:) = info{i}.OptimizedPostProcParams;
        if tempNoOfEvals > 1
            error('not implemented yet')
        end
    end
    
    if isfield(info{1,1},'OptimizedDecCritParams')
        OptDecCritTemp(i,:) = info{i}.OptimizedDecCritParams;
        if tempNoOfEvals > 1
            error('not implemented yet')
        end
    end
    
    if isfield(Settings,'MaxTime')
        if etime(clock,State.StartTime) > Settings.MaxTime
            State.stopOptimization = true;
            save([Case.CaseName,'_TempOptWs'])
            break
        end
    end
end
%X(failedInds,:) = [];
%Y(failedInds,:) = [];

State.customNoOfEvals = customNoOfEvals;

if optimizationStartUp 
    Y = Y(1+Settings.evaluationDelay:end);
end
Y(end+1:end+Settings.evaluationDelay,1) = NaN;
if ~isempty(Constrnt)
    Constrnt = Constrnt(1+Settings.evaluationDelay:end,:);
    Constrnt(end+1:end+Settings.evaluationDelay,:) = NaN;
end


if isfield(info{1,1},'postProcOptInfo')
    for i = 1:length(info)
        State.EvalsInclPp.X = [State.EvalsInclPp.X;[repmat(X(i,:),size(info{1,i}.postProcOptInfo.stateMat,1),1) info{1,i}.postProcOptInfo.stateMat]];
        State.EvalsInclPp.Y = [State.EvalsInclPp.Y;info{1,i}.postProcOptInfo.costMat];
    end
end

if isfield(info{i},'OptimizedDecCritParams')
    State.EvalSamples.OptimizedDecCritParams = [State.EvalSamples.OptimizedDecCritParams;OptDecCritTemp];
end
if isfield(info{i},'OptimizedPostProcParams')
    State.EvalSamples.OptPostProcParams = [State.EvalSamples.OptPostProcParams;OptPostProcParamsTemp];
end

if isfield(Settings,'enableEarlyEvalStop') && Settings.enableEarlyEvalStop
    State.EvalSamples.YVect         = [State.EvalSamples.YVect;                YVect];
    State.EvalSamples.episodeLength = [State.EvalSamples.episodeLength;episodeLength];
end

State.EvalSamples.X = [State.EvalSamples.X ;X];
State.EvalSamples.OutlierBool = [State.EvalSamples.OutlierBool; zeros(size(X,1),1)];
State.EvalSamples.FailedBool  = [State.EvalSamples.FailedBool;  failedBool];
State.EvalSamples.EvalPending = false(size(State.EvalSamples.X,1),1);
State.EvalSamples.EvalPending(end-Settings.evaluationDelay+1:end) = true; 
State.EvalSamples.Y = [State.EvalSamples.Y(1:max(end-Settings.evaluationDelay,0)) ;Y];
State.EvalSamples.Constrnt = [State.EvalSamples.Constrnt(1:max(end-Settings.evaluationDelay,0),:) ;Constrnt];

State.evalTime = abs(etime(c1,clock));
if ~isempty(Y) && ( isfield(Case,'BlackBoxConstraints') && ~(size(Y,2) + size(Constrnt,2)  ==    length(Case.BlackBoxConstraints.ub)))
    error ('Number of black box constraints does not match the number of responses')
end

State.numberOfEvals = size(X,1);
State.totalNumberOfEvals = State.totalNumberOfEvals + State.numberOfEvals;
State.EvalSamples.info = [State.EvalSamples.info info];

end

