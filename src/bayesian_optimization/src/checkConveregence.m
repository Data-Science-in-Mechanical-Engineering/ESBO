function [State] = checkConveregence(Stats,State,Settings)

State.stopOptimization = false;
if isfield(Settings,'MaxNoOfEvals')
    if State.totalNumberOfEvals >=  Settings.MaxNoOfEvals
        State.stopOptimization = true;
    end
end
if isfield(Settings,'MaxCumEpisodeLength') && isfield(State.EvalSamples,'episodeLength')
    if sum(State.EvalSamples.episodeLength) >=  Settings.MaxCumEpisodeLength
        State.stopOptimization = true;
    end
end
if isfield(Settings,'MaxTime')
    if etime(clock,State.StartTime) > Settings.MaxTime
        State.stopOptimization = true;
    end
end

if isfield(Settings,'TargetVal')
    if State.Yopt <= Settings.TargetVal
        State.stopOptimization = true;
    end
end

end

