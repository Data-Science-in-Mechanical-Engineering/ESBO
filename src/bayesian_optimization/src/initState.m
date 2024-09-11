function [State] = initState(Settings)
%INITSTATE Summary of this function goes here
%   Detailed explanation goes here
State.currIter = 1;
State.EvalSamples.X = [];
State.EvalsInclPp.X = [];
State.EvalsInclPp.Y = [];
State.EvalSamples.Y = [];
State.EvalSamples.info = [];
State.EvalSamples.OutlierBool = [];
State.EvalSamples.FailedBool = [];
%State.EvalSamples.FailedEvalBool = [];
State.EvalSamples.isValid = [];
State.EvalSamples.OptPostProcParams = [];
State.EvalSamples.Constrnt = [];
State.EvalSamples.OptimizedDecCritParams  = [];
State.totalNumberOfEvals = 0;
State.StartTime = clock;
State.Yopt = inf;
if isfield(Settings,'enableEarlyEvalStop') && Settings.enableEarlyEvalStop
    State.EvalSamples.YVect         = [];
    State.EvalSamples.episodeLength = [];
    State.ES.yMin = inf;
end
end

