function [State] = getOptSolEval(State,Stats,Settings,Case)

if size(State.EvalSamples.Y,2) == 1  
    %warning('Not tested yet!')
    validInds = find(State.EvalSamples.isValid);
    invalidInds = find(~State.EvalSamples.isValid);
    if Settings.MetamodellSettings.noisyObservations && ~(Settings.enableEarlyEvalStop && Settings.ESSettings.useEpisodeTimeMax)
        [YMean,YVar] = evalMetaModels(State,Settings,State.EvalSamples.X); %Note that Ymean is identical to fmean
    else
        YMean = State.EvalSamples.Y;
    end
    tempY = YMean(:,1);
    if isfield(Settings,'enableEarlyEvalStop') && Settings.enableEarlyEvalStop
        tempY(~(State.EvalSamples.episodeLength == max(State.EvalSamples.episodeLength))) = inf;
    end
    tempY(invalidInds) = inf;
    [SortedY,inds] = sort(tempY);
    Xopt = State.EvalSamples.X(inds(1),:);
    State.Xopt = Xopt;
    State.Yopt = SortedY(1);
    if isfield(State.EvalSamples,'reintConstrnt')
        State.reintConstrntOpt = State.EvalSamples.reintConstrnt(inds(1),:);
        State.reintUQuantileOpt = State.EvalSamples.reintUQuantile(inds(1),:);
        
    end
    State.nonDominatedInds =inds(1);
    State.ObjFunHist = State.EvalSamples.Y;
    State.XSortedEvals = State.EvalSamples.X(inds,:);
    State.YSortedEvals = SortedY;
else
    if isfield(State,'nonDominatedInds')
        nonDominatedIndsOld = State.nonDominatedInds;
    end
    State.nonDominatedInds = nonDominatedSorting(State);
    
    Xopt = State.EvalSamples.X(State.nonDominatedInds,:);
    State.Xopt = Xopt;
    State.Yopt = State.EvalSamples.Y(State.nonDominatedInds,:);
    if isfield(State,'infoopt')
        deleteInds = [];
        for i = 1:length(nonDominatedIndsOld)
            
            if ~any(nonDominatedIndsOld(i) == State.nonDominatedInds)
                deleteInds = [deleteInds i];
                
            end
        end
        State.infoopt(deleteInds) = [];
        newPointInds =  find(State.nonDominatedInds > (size(State.EvalSamples.X,1)-length(State.info)));
        State.infoopt(newPointInds) = State.info(State.nonDominatedInds(newPointInds) -(size(State.EvalSamples.X,1)-length(State.info)));
    else
        State.infoopt = State.info(State.nonDominatedInds);
    end
end

%disp('derp')
end

