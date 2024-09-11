function [Settings] = Rand_ES(SettingsDefault)

Settings = SettingsDefault;

NoOfFullEpisodes = Settings.MaxNoOfEvals;

Settings.SurrogateOptimizer = 'Rand';

Settings.enableEarlyEvalStop               = true;
Settings.ESSettings.useVDPHeuristic        = true;
Settings.ESSettings.estimateFutureCost     = false;  
Settings.ESSettings.estimateFutureCostConf = inf;   
Settings.ESSettings.comparePredWActCost    = false; 
Settings.MaxNoOfEvals= ceil(NoOfFullEpisodes*3);


end

