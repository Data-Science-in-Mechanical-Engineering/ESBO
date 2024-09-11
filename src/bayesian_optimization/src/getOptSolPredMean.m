function [State] = getOptSolPredMean(State,Stats,Settings)


[reinterpolatedY,~] = evalMetaModels(State,Settings,State.EvalSamples.X);

[SortedY,inds] = sort(reinterpolatedY,1);
Xopt = State.EvalSamples.X(inds(1),:);
State.Xopt = Xopt;
State.Yopt = SortedY(1);
State.XSortedEvals = State.EvalSamples.X(inds,:);
State.YSortedEvals = State.EvalSamples.Y(inds,:);
%disp('derp')
end

