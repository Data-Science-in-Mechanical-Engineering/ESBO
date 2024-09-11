function [State,Stats] = outlierDetectionUDF(State,OutlierDetectSettings,Settings,Stats,Case)


if size(State.EvalSamples.X,1) >= OutlierDetectSettings.minElements
    
    for i = 1:size(State.EvalSamples.X,1)
        if ~isempty(State.EvalSamples.Constrnt)
            State.EvalSamples.OutlierBool(i) = Case.OutlierDetectionFun(State.EvalSamples.Y(i,:),State.EvalSamples.Constrnt(i,:),State.EvalSamples.info{i});
        else
            State.EvalSamples.OutlierBool(i) = Case.OutlierDetectionFun(State.EvalSamples.Y(i,:),[],State.EvalSamples.info{i});
        end
    end
    
    if sum(~State.EvalSamples.OutlierBool) < OutlierDetectSettings.minElements
        State.EvalSamples.OutlierBool(:) = false;
    end
    
end


end

