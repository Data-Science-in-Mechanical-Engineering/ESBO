function [Settings] = Rand(SettingsDefault)

Settings = SettingsDefault;

NoOfFullEpisodes = Settings.MaxNoOfEvals;

Settings.SurrogateOptimizer = 'Rand';

Settings.enableEarlyEvalStop               = false;
Settings.ESSettings.useVDPHeuristic        = false;
Settings.ESSettings.estimateFutureCost     = false;  
Settings.ESSettings.estimateFutureCostConf = inf;   %
Settings.ESSettings.comparePredWActCost    = false; 

end

