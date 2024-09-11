function [Settings] = ESBenchDefaultSettings_BoundedLS(Case)

Settings.InitsampleMode                         = 'List';
Settings.initSampleSize                         = max(length(Case.ub),2);
Settings.Metamodell                             = 'GPRknownMeasNoise'; % this is needed because we predict mean and uncertainty for the measurements that were aborted early
Settings.MetamodellSettings.useGradientBasedOptimization = true;
Settings.MetamodellSettings.noisyObservations   = false;
Settings.MetamodellSettings.lengthRandSearch    = 250;
Settings.MetamodellSettings.relChangeStopCrit   = 10^-4;
Settings.MetamodellSettings.maxiterHypParamOpt  = 15;
Settings.MetamodellSettings.useLinMean          = false;
Settings.MetamodellSettings.useIsoKernel        = false;
Settings.MetamodellSettings.useZeroMean         = true; %



Settings.Infillkrit                             = 'MES';
Settings.SurrogateOptimizer                     = 'RandSearch';
Settings.SurrogateOptimizerRSNoOfSamples        = 10000;
Settings.reOptimizingFrequency                  = 1;
Settings.MaxNoOfEvals                           = length(Case.ub)*15;
Settings.MaxCumEpisodeLength                    = Case.maxEpisodeLength*Settings.MaxNoOfEvals;
Settings.NoOfSamplesPerIter                     = 1;


Settings.MetamodellSettings.noisyObservations   = false;


Settings.OutlierClassification                  = 'virtualData';
Settings.OutlierDetection                       = 'UserDefined';
Settings.OutlierDetectionSettings.minElements   = 3; % start if at least three samples are available

Settings.MetamodellSettings.lowerBoundsOnLengthScaleUser = (Case.ub-Case.lb)./100;
Settings.MetamodellSettings.upperBoundsOnLengthScaleUser = (Case.ub-Case.lb)./2;


end

