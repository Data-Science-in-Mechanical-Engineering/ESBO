function [Settings] = ESExperimentDefaultSettings(Case)

Settings.InitsampleMode                         = 'List';
Settings.initSampleSize                         = max(length(Case.ub)+1,2);
Settings.Metamodell                             = 'GPRknownMeasNoise';

Settings.MetamodellSettings.lengthRandSearch    = 250;
Settings.MetamodellSettings.relChangeStopCrit   = 10^-4;
Settings.MetamodellSettings.maxiterHypParamOpt  = 15;
Settings.MetamodellSettings.useLinMean          = false;
Settings.MetamodellSettings.useIsoKernel        = false;
Settings.MetamodellSettings.useZeroMean         = true; %
Settings.MetamodellSettings.useGradientBasedOptimization           = true;

Settings.Infillkrit                             = 'MES';
Settings.SurrogateOptimizer                     = 'RandSearch';
Settings.SurrogateOptimizerRSNoOfSamples        = 10000;
Settings.reOptimizingFrequency                  = 1;
Settings.MaxNoOfEvals                           = length(Case.ub)*15;
Settings.MaxCumEpisodeLength                    = Case.maxEpisodeLength*Settings.MaxNoOfEvals;
Settings.NoOfSamplesPerIter                     = 1;

Settings.FlexBoundUpdate                        = true;
Settings.FlexBoundMinValEvas                    = 3;

Settings.MetamodellSettings.noisyObservations   = true;


Settings.OutlierClassification                  = 'virtualData';
Settings.OutlierDetection                       = 'UserDefined';
Settings.OutlierDetectionSettings.minElements   = 3;


Settings.MetamodellSettings.lowerBoundsOnLengthScaleUser = (Case.ub-Case.lb)./100;
Settings.MetamodellSettings.upperBoundsOnLengthScaleUser = (Case.ub-Case.lb)./2;

Settings.saveFigs = false;
Settings.saveWS= false;


end

