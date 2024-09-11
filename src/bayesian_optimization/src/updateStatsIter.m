function [Stats,State] = updateStatsIter(Stats, State,Settings)

Stats.totalEvals(State.currIter) = State.totalNumberOfEvals;



if isfield(State,'OutlierDetectCmat')
    Stats.OutlierDetectCmat{State.currIter} = State.OutlierDetectCmat;
    Stats.OutliedetectionAccuracy(State.currIter) = State.OutliedetectionAccuracy;
else
    Stats.OutlierDetectCmat{State.currIter} = [];
    Stats.OutliedetectionAccuracy(State.currIter)= 0;
end
Stats.TimeStamp(State.currIter,:) = clock;

if isfield(State,'ObjFunHist')
    Stats.ObjFunHist = State.ObjFunHist;
end

if isfield(State,'BuildMMtime')
    Stats.BuildMMtime(State.currIter) = State.BuildMMtime;
    Stats.TotalBuildMMtime(State.currIter) = sum(Stats.BuildMMtime);
end

if isfield(State,'EvalMMtime')
    Stats.EvalMMtime(State.currIter) = State.EvalMMtime;
end

if isfield(State,'FindCandidatetime')
    Stats.FindCandidatetime(State.currIter) = State.FindCandidatetime;
end

if isfield(State,'EIMax')
    Stats.EIMax(State.currIter) = State.EIMax;
end

if isfield(State,'EIMaxGA')
    Stats.EIMaxGA(State.currIter) = State.EIMaxGA;
end

if isfield(State,'evalTime')
    Stats.evalTime(State.currIter) = State.evalTime;
end

if isfield(State,'EIMaxSingleProd')
    Stats.EIMaxSingleProd(State.currIter) = State.EIMaxSingleProd;
end

if isfield(State,'EIMaxSingleProd')
    Stats.EvalTime(State.currIter) = evalTime;
    Stats.TotalEvalTime(State.currIter) = sum(Stats.EvalTime);
end

if isfield(State,'Xopt')
    if size(State.Yopt,2) > 1
        Stats.Xopt{State.currIter} = State.Xopt;
        Stats.Yopt{State.currIter} = State.Yopt;
    else
        Stats.Xopt(State.currIter,:) = State.Xopt;
        Stats.Yopt(State.currIter,:) = State.Yopt;
        Stats.XSortedEvals{State.currIter,:} = State.XSortedEvals;
        Stats.YSortedEvals{State.currIter,:} = State.YSortedEvals;
    end
end

if isfield(State,'reintUQuantileOpt')
    Stats.reintUQuantileOpt(State.currIter,:) = State.reintUQuantileOpt;
    Stats.reintConstrntOpt(State.currIter,:) = State.reintConstrntOpt;
end

try
    Stats.objFunCovHyp(State.currIter,:) = State.MM.Models{1,1}.hyp.cov;
catch
    disp('derp')
end

try
    Stats.objFunCovLik(State.currIter,:) = State.MM.Models{1,1}.hyp.lik;
catch
    disp('derp')
end

try
    a = Settings.ESSettings.comparePredWActCost;
catch
    Settings.ESSettings.comparePredWActCost = false;
end

if Settings.ESSettings.comparePredWActCost
    nonFullEpisodeInds = State.EvalSamples.episodeLength ~= max(State.EvalSamples.episodeLength);
    if sum(nonFullEpisodeInds(1:end-1)) == 0
        Stats.ESBias(State.currIter) = NaN;
        Stats.NormESBias(State.currIter) = NaN;
        Stats.ESRMSE(State.currIter) = NaN;
        Stats.NormalizedESRMSE(State.currIter) = NaN;
    else
        Stats.ESBias(State.currIter)            = 0;
        Stats.NormESBias(State.currIter)        = 0;
        Stats.ESRMSE(State.currIter)            = 0;
        Stats.NormESRMSE(State.currIter)        = 0;
        for i = 1: length(nonFullEpisodeInds-1)
            if nonFullEpisodeInds(i)
                if isfield(State.EvalSamples.info{i},'JGt')
                    JGt = State.EvalSamples.info{i}.JGt;
                else
                    JGt = 0;
                end
                if isfield(Settings.ESSettings,'useVDPHeuristic') && Settings.ESSettings.useVDPHeuristic
                    Stats.ESBias(State.currIter) =  Stats.ESBias(State.currIter)+ (State.EvalSamples.virtualY(i) - JGt);
                    Stats.ESRMSE(State.currIter) =  Stats.ESRMSE(State.currIter)+ (State.EvalSamples.virtualY(i) - JGt)^2;
                else
                    Stats.ESBias(State.currIter) =  Stats.ESBias(State.currIter)+ (State.EvalSamples.virtualY(i) - JGt);
                    Stats.NormESBias(State.currIter) =  Stats.NormESBias(State.currIter)+ (State.EvalSamples.virtualY(i) - JGt)/State.EvalSamples.virtualSigma_Y(i);
                    Stats.ESRMSE(State.currIter) =  Stats.ESRMSE(State.currIter)+ (State.EvalSamples.virtualY(i) - JGt)^2;
                    Stats.NormESRMSE(State.currIter) =  Stats.NormESRMSE(State.currIter)+ ((State.EvalSamples.virtualY(i) - JGt)/State.EvalSamples.virtualSigma_Y(i))^2;
                end
            end
        end
        Stats.ESBias(State.currIter)            = Stats.ESBias(State.currIter)      /sum(nonFullEpisodeInds);
        Stats.NormESBias(State.currIter)        = Stats.NormESBias(State.currIter)  /sum(nonFullEpisodeInds);
        Stats.ESRMSE(State.currIter)            = sqrt(Stats.ESRMSE(State.currIter)      /sum(nonFullEpisodeInds));
        Stats.NormESRMSE(State.currIter)        = sqrt(Stats.NormESRMSE(State.currIter)  /sum(nonFullEpisodeInds));
    end
end

Stats.YEstBest(State.currIter) = State.Yopt;

Stats.customNoOfEvals(State.currIter) = State.customNoOfEvals;




Stats.sucEvals(State.currIter) = State.totalNumberOfEvals;
State.currIter = State.currIter+1;
end

