function [tmpState] = outClassVirtDat(State,Stats,Case,Settings)

if sum(State.EvalSamples.OutlierBool) > 0 %&& size(State.EvalSamples.X,1) >= Settings.OutlierDetectionSettings.
    %Evaluate Model at outlier locations
    ourliers = State.EvalSamples.X(logical(State.EvalSamples.OutlierBool),:);

    [Mean,Var] = evalMetaModels(State,Settings,ourliers);

    NoOfResponses = size(Mean,2);
    tmpState = State;
    tmpState.enforceRefit = true;
    tmpState.refuseRefit  = true;
    if isfield(Case,'isContext')
        % get effective context length scale
        
        for i = 1:length(State.MM.Models)
            unscaledLengthScales(i,:) = exp(State.MM.Models{i}.hyp.cov(1:end-1)).*State.MM.Scaling.StdX; 
        end
        if sum(Case.isContext) > 1
            error('not supported')
        end
        effectiveLengthScale = min(unscaledLengthScales,[],1);
        if sum(~State.EvalSamples.isValid & (abs(State.currContext - State.EvalSamples.X(:,Case.isContext)) < effectiveLengthScale(Case.isContext))) <= 2;
            worstnonOutlierSample = inf;
        else
            worstnonOutlierSample  = max(State.EvalSamples.Y(~State.EvalSamples.OutlierBool)); 
        end
        
        
    else
        worstnonOutlierSample  = max(State.EvalSamples.Y(~State.EvalSamples.OutlierBool));
    end
    if isfield(Settings,'enableEarlyEvalStop') && Settings.enableEarlyEvalStop && Settings.ESSettings.useEpisodeTimeMax
        worstnonOutlierSample = max(State.EvalSamples.virtualY(~State.EvalSamples.OutlierBool));
        YOpt = min(State.EvalSamples.virtualY(~State.EvalSamples.OutlierBool));
    else
        YOpt = State.Yopt;
    end
    
    
    tmp = min((max(Mean(:,1),YOpt) + 3*sqrt(Var(:,1))),worstnonOutlierSample);
    
    tmpState.EvalSamples.virtualY = zeros(size(State.EvalSamples.Y));

    tmpState.EvalSamples.virtualY(logical(State.EvalSamples.OutlierBool),1) = tmp;

    
    if NoOfResponses > 1
        tmpState.EvalSamples.virtualY(logical(State.EvalSamples.OutlierBool),2:NoOfResponses) = Mean(:,2:NoOfResponses);
    end
    
    tmpState.useVirtualYData = true;
    try
    [tmpState] = fitMetaModels(tmpState,Settings,Stats,Case);
    catch
        tmpState.refuseRefit  = false;
        [tmpState] = fitMetaModels(tmpState,Settings,Stats,Case);
    end

    if isfield(Case,'isContext') && any(Case.isContext) && tmpState.refuseRefit 
        for i = 2:size(Mean,2)
            tmpState.MM.Models{i} = State.MM.Models{i};
        end
    end
    tmpState.useVirtualYData = false;
    tmpState.enforceRefit = true;
    tmpState.refuseRefit  = false;
   
else
    tmpState = State;
    return 
end
end

