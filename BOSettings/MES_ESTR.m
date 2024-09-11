function [Settings] = MES_ESTR(SettingsDefault)

Settings = SettingsDefault;

NoOfFullEpisodes = Settings.MaxNoOfEvals;

Settings.enableEarlyEvalStop               = true;
Settings.ESSettings.useVDPHeuristic        = false;
Settings.ESSettings.estimateFutureCost     = false;   
Settings.ESSettings.estimateFutureCostConf = inf;  
Settings.ESSettings.comparePredWActCost    = false; 
Settings.ESSettings.enableGPPred = false;
Settings.ESSettings.useLumpedPred = false;
Settings.ESSettings.useEpisodeTimeMax = true;


Settings.MaxNoOfEvals= ceil(NoOfFullEpisodes*3);
end

