function [Settings] = MES_LumpedGPPredMC(SettingsDefault)

Settings = SettingsDefault;

NoOfFullEpisodes = Settings.MaxNoOfEvals;

Settings.enableEarlyEvalStop               = true;
Settings.ESSettings.useVDPHeuristic        = false;
Settings.ESSettings.estimateFutureCost     = false;  
Settings.ESSettings.estimateFutureCostConf = inf;   
Settings.ESSettings.comparePredWActCost    = false; 
Settings.ESSettings.useEpisodeTimeMax      = false;


Settings.Metamodell = 'GPRknownMeasNoise'; 
Settings.ESSettings.enableGPPred = true;
Settings.ESSettings.useLumpedPred = true;
Settings.ESSettings.useTruncatedMomentMatching = false;
Settings.ESSettings.useLumbedGPMC = true;

Settings.MaxNoOfEvals= ceil(NoOfFullEpisodes*3);
end

