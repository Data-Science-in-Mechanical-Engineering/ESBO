clear all
close all
restoredefaultpath
clc
rng(1)

addpath('src\benchmarkUtils');
addpath('plotSkripts')

% load results from the experiment
BenchmarkSettings.ResultsPath = strcat('results\harware_experiment');
% load results from the simulation
datForPPSimLS = load('results\test_results.mat');%load('results\simulation_experiment');

% some settings for post processing
ppSettings.titleString = 'Results';
ppSettings.maps                      = getMaps();
ppSettings.useRegret                 = true; 
ppSettings.showResPerRun             = true;
ppSettings.deterministicObjective    = true;
ppSettings.objectiveClipForPP        = true;
ppSettings.earlyStoppingPP           = false;
ppSettings.maxSamplesPerCase         = 45*[1 2 3 4 5];

ppSettings.ylim                 = [400 700; 8.5*10^-5 10.5*10^-5;0 270; 0 20000;0.08 .2 ];
ppSettings.averageRegretYLim    = [-0.5 1.5];


% do the actual post processing
datForPP                        = load(BenchmarkSettings.ResultsPath);

[ExperimentRes]                 = doPostProcessing(datForPP,ppSettings);

ppSettings.earlyStoppingPP           = true;
[ExperimentResES] = doPostProcessing(datForPP,ppSettings);


ppSettings.earlyStoppingPP           = true;

datForPPSimLSWOTrun = getDatForOptimizers(datForPPSimLS,[2 3 7 1 5 6]); % Do not show results of the 4th method (heteroscedastic GP-model)

ppSettings.earlyStoppingPP = true;
[SimResESLSWOTrun] = doPostProcessing(datForPPSimLSWOTrun ,ppSettings);
ppSettings.earlyStoppingPP = false;
[SimResLSWOTrun] = doPostProcessing(datForPPSimLSWOTrun ,ppSettings);



%% Generate Figures
close all
% Generate Figure for the experimental results
FiguresExperiment

% Generate Figure for the simulation results
FiguresSim


%% Visualization of the method
clear all
useMC = true;
MCNoiseLabel = 9;

addpath('src\bayesian_optimization')
addpath(['src\bayesian_optimization\metamodelling\'])
addpath('src\bayesian_optimization\src\')
addpath('src\bayesian_optimization\src\acquisitionFun\')
addpath('src\bayesian_optimization\gpml-matlab-v4.1-2017-10-19')
addpath('src\benchmarkUtils');
addpath('plotSkripts')
startup
vD = load('results\ExampleWSForMethodsFig.mat');

vD.Settings.enableEarlyEvalStop               = true;
vD.Settings.ESSettings.useVDPHeuristic        = false;
vD.Settings.ESSettings.estimateFutureCost     = false;  % If this is false only abort if we are strictly worse than the optimum 
vD.Settings.ESSettings.estimateFutureCostConf = inf;   
vD.Settings.ESSettings.comparePredWActCost    = false; 
vD.Settings.ESSettings.useEpisodeTimeMax      = false;

vD.Settings.Metamodell = 'GPRknownMeasNoise'; % this is needed because we predict mean and uncertainty for the measurements that were aborted early
vD.Settings.ESSettings.enableGPPred = true;
vD.Settings.ESSettings.useLumpedPred = true;
vD.Settings.ESSettings.useTruncatedMomentMatching = false;

if ~useMC
    rng(2)
else
    rng(MCNoiseLabel)
end
if useMC
    [vDTemp.State] = genESVirtDat(vD.State,vD.Settings,vD.Case);
    vD.Settings.ESSettings.useLumbedGPMC = true;

end
if ~useMC
    rng(2)
else
    rng(MCNoiseLabel)
end
[vD.State] = genESVirtDat(vD.State,vD.Settings,vD.Case);
vD.State.EvalSamples.X = [1:1:size(vD.State.EvalSamples.X,1)]';
vD.Case.lb = min(vD.State.EvalSamples.X);
vD.Case.ub = max(vD.State.EvalSamples.X);

useInds = [1 2 6 7]; 

vD.State.EvalSamples.X = vD.State.EvalSamples.X(useInds);
vD.State.EvalSamples.X = [0.45 0.25 0.8 0.65]';
vD.Case.lb = 0;
vD.Case.ub = 1;
vD.State.EvalSamples.Y = vD.State.EvalSamples.Y(useInds);
vD.State.EvalSamples.virtualY     = vD.State.EvalSamples.virtualY (useInds);
vD.State.EvalSamples.virtualSigma_Y    = vD.State.EvalSamples.virtualSigma_Y (useInds);
vD.State.EvalSamples.YVect    = vD.State.EvalSamples.YVect (useInds,:);
vD.State.EvalSamples.episodeLength    = vD.State.EvalSamples.episodeLength (useInds);

vD.State.EvalSamples.YVect(4,:) = vD.State.EvalSamples.YVect(4,:)*1.1;
vD.State.EvalSamples.virtualY(4) = vD.State.EvalSamples.virtualY(4)*1.1;
vD.State.EvalSamples.virtualY(3) = vD.State.EvalSamples.virtualY(3)*0.7;

vD.State.EvalSamples.virtualSigma_Y(4) = vD.State.EvalSamples.virtualSigma_Y(4)*1.5;
vD.State.EvalSamples.episodeLength(4) = 151;

[vD.State] = fitMetaModels(vD.State,vD.Settings,vD.Stats,vD.Case);

vD.State.MM.Models{1}.hyp.cov(1) = -2.5;
%vD.State.
vD.infillKritfunc = prepMES(vD.State,vD.Settings,vD.Case);

FigSettings.color = RWTHcolors();
FigSettings.beta = 1;
FigSettings.xLim = [0 1];
FigSettings.yLim = [0.1 0.55];
FigSettings.XLabel = "Controller Parameter";
FigSettings.xPlotEnd = 1;
FigSettings.useMC = useMC;
if useMC
    vDTemp.State.EvalSamples.Y = vDTemp.State.EvalSamples.Y(useInds);
    vDTemp.State.EvalSamples.virtualY     = vDTemp.State.EvalSamples.virtualY (useInds);
    vDTemp.State.EvalSamples.virtualSigma_Y    = vDTemp.State.EvalSamples.virtualSigma_Y (useInds);
    vDTemp.State.EvalSamples.YVect    = vDTemp.State.EvalSamples.YVect (useInds,:);
    vDTemp.State.EvalSamples.episodeLength    = vDTemp.State.EvalSamples.episodeLength (useInds);

    vDTemp.State.EvalSamples.YVect(4,:) = vDTemp.State.EvalSamples.YVect(4,:)*1.1;
    vDTemp.State.EvalSamples.virtualY(4) = vDTemp.State.EvalSamples.virtualY(4)*1.1;
    vDTemp.State.EvalSamples.virtualSigma_Y(4) = vDTemp.State.EvalSamples.virtualSigma_Y(4)*1.5;
    vDTemp.State.EvalSamples.virtualY(3,:) = vDTemp.State.EvalSamples.virtualY(3,:)*0.7;
end

FigSettings.MCCustomErrorBars.sigma = vDTemp.State.EvalSamples.virtualSigma_Y(end-1:end);
FigSettings.MCCustomErrorBars.mean = vDTemp.State.EvalSamples.virtualY(end-1:end);
FigSettings.MCCustomErrorBars.x = vD.State.EvalSamples.X(3:4);
FiguresShowCase(vD.State,vD.Case,vD.Stats,vD.Settings,vD.infillKritfunc,FigSettings);







