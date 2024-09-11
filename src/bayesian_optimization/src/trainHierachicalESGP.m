function [GPModelTree] = trainHierachicalESGP(paramMat,jMat,EpisodeLength,outlierBool,Case,noisyObs)


jModelSettings.Metamodell = 'GPR';
jModelSettings.MetamodellSettings.noisyObservations = noisyObs;
jModelSettings.MetamodellSettings.lengthRandSearch = 50;%250;
jModelSettings.MetamodellSettings.relChangeStopCrit = 10^-4;
jModelSettings.MetamodellSettings.maxiterHypParamOpt = 5;%15;
jModelSettings.MetamodellSettings.NoOfPostSample = 50;
jModelStats = struct();

EpisodeLength(outlierBool) = Case.maxEpisodeLength;
uniqueEL = unique(EpisodeLength);
noOfModels = length(uniqueEL)-1;

if noOfModels == 0
    GPModelTree = [];
    return
end


for i = 1:length(uniqueEL)
   episodeLengthInds(uniqueEL(i) == EpisodeLength) = i; 
end
tic 
for i = 1:length(uniqueEL)-1
    GPModelTree.Models{i}.startInd           = uniqueEL(end-i) + 1;
    GPModelTree.Models{i}.endInd             = uniqueEL(end-i +1);
    GPModelTree.Models{i}.trainEpisodeInds   = find(episodeLengthInds > max(episodeLengthInds)-i & ~outlierBool');
    GPModelTree.Models{i}.State.EvalSamples.X = paramMat(GPModelTree.Models{i}.trainEpisodeInds,:);
    GPModelTree.Models{i}.State.EvalSamples.Y = sum(jMat(GPModelTree.Models{i}.trainEpisodeInds,[GPModelTree.Models{i}.startInd:GPModelTree.Models{i}.endInd]),2);
    GPModelTree.Models{i}.State.currIter = 1;
    GPModelTree.Models{i}.Case.lb = Case.lb;
    GPModelTree.Models{i}.Case.ub = Case.ub;
    GPModelTree.Models{i}.State = fitMetaModels(GPModelTree.Models{i}.State,jModelSettings,jModelStats,GPModelTree.Models{i}.Case);
end
toc

% Assign relevant models
for i = 1:length(episodeLengthInds)
    GPModelTree.PredModelInds{i} = [1:1:(length(uniqueEL)-episodeLengthInds(i))];
end
GPModelTree.Settings = jModelSettings;
end

