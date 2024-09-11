clear all
close all
restoredefaultpath
clc
rng(1)

addpath('src\benchmarkUtils');
addpath('BOSettings')

BenchmarkSettings.BOPath      = 'src\bayesian_optimization';
BenchmarkSettings.ResultsPath = 'results\test_results';

BenchmarkSettings.optimizers        = {'BO'}; 
BenchmarkSettings.UseGridReference  = false;

BenchmarkSettings.NoOfRuns         = 10; % Number of Seeds. In the original paper, we used ten seeds.
BenchmarkSettings.NoValidationSims = 0;
BenchmarkSettings.tempEvalCap         = [10 10 10 10 10];
BenchmarkSettings.saveInterval = 20; % save results every 20 minutes 

BenchmarkSettings.testcases                 = {'BoilerBangBang1Var','ThreeTankPI2Var','PIDPTS23Var','CartPoleLQR4Var','ThreeTankMPC5Var'};
BenchmarkSettings.BOVariants                = {'MES_VDP','MES_ESVDP','MES_ESTR','MES_LumpedGPPred','Rand','Rand_ES','MES_LumpedGPPred_MC'};

BenchmarkSettings.BOSettingsFun             = {@MES_VDP,@MES_ESVDP,@MES_ESTR,@MES_LumpedGPPred,@Rand,@Rand_ES,@MES_LumpedGPPredMC}; 
BenchmarkSettings.defaultSettingsFun        = @ESBenchDefaultSettings_BoundedLS;


runSeedsAndCases(BenchmarkSettings);
    


