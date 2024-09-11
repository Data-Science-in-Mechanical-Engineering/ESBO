function [State] = checkConstraints(State,Case,Settings)

if isfield(Case,'BlackBoxConstraints')
    if isfield(Case.BlackBoxConstraints,'Quantile')
        [YMean,YVar] = evalMetaModels(State,Settings,State.EvalSamples.X); 
        
        State.EvalSamples.reintY = YMean(:,1);
        State.EvalSamples.reintConstrnt = YMean(:,[2:end]);
        State.EvalSamples.reintUQuantile = YMean+Case.BlackBoxConstraints.Quantile.*sqrt(YVar);
        
        State.EvalSamples.isValid = all(YMean+Case.BlackBoxConstraints.Quantile.*sqrt(YVar)<= Case.BlackBoxConstraints.ub & YMean-Case.BlackBoxConstraints.Quantile.*sqrt(YVar) >= Case.BlackBoxConstraints.lb,2);
    else
        State.EvalSamples.isValid = all(([State.EvalSamples.Y State.EvalSamples.Constrnt]<= Case.BlackBoxConstraints.ub & [State.EvalSamples.Y State.EvalSamples.Constrnt] >= Case.BlackBoxConstraints.lb),2);
    end
else
    State.EvalSamples.isValid = [ones(size(State.EvalSamples.X,1),1)];
end

State.EvalSamples.isValid = ~(~State.EvalSamples.isValid | State.EvalSamples.OutlierBool | State.EvalSamples.FailedBool | State.EvalSamples.EvalPending);


end

