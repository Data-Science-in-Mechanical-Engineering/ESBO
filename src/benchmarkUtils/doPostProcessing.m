function [testCaseRes] = doPostProcessing(datForPP,ppSettings)
disp('::::: Post Processing :::::')
PlotStyles = {'-o','-+','-*','-x','-s','-d','-^','-v','-p','-h','-<','->','-o','-+','-<','-s','-d'};
Colors     = {[0 0.4470 0.7410],[0.8500 0.3250 0.0980],[0.9290 0.6940 0.1250],[0.4940 0.1840 0.5560],[0.4660 0.6740 0.1880],[0.3010 0.7450 0.9330],[0.6350 0.0780 0.1840],[0 0.4470 0.7410],[0.8500 0.3250 0.0980],[0.9290 0.6940 0.1250],[0.4940 0.1840 0.5560],[0.4660 0.6740 0.1880],[0.3010 0.7450 0.9330],[0.6350 0.0780 0.1840],[0.6350 0.0780 0.1840],[0.4660 0.6740 0.1880],[0 0.4470 0.7410],[0.4940 0.1840 0.5560],[0.6350 0.0780 0.1840]};

% Unpack
testcaseMat = datForPP.testcaseMat;
signature = datForPP.signature;
res_Stats = datForPP.res_Stats;
res_State = datForPP.res_State;
Settings = datForPP.Settings;
titleString = ppSettings.titleString;
testcases = datForPP.BenchmarkSettings.testcases;
if isfield(datForPP,'gridReference')
    gridReference  = datForPP.gridReference;
else
    disp('No grid reference provided.')
    gridReference = [];
end

%showResPerRun = ppSettings.showResPerRun;

%% Post processing settings

%ppSettings.OptimalityEps = [0.01 0.01 0.01 0.01 0.01 0.01 0.01 0.175 0.01 0.01];
ppSettings.OptimalityEps = ones(1,length(testcases))*0.01;

%% get Optimizer names
inds = find(testcaseMat(1,:) == 1);
for i_optimizer = 1:length(inds)
    idx = strfind(signature{i_optimizer},':');
    optimizerSignature{i_optimizer} = signature{i_optimizer}(idx(1)+1:end);
end


%Post processing für predicted Performanc und feasibility


for i_testcase = 1:size(res_Stats,2) % loop over number of testcases
    noOfRuns = size(res_Stats,1);
    testCaseRes.feasibility{i_testcase} = [];
    testCaseRes.ybest{i_testcase} = [];
    for i_run = 1:noOfRuns
        if ~isfield(res_Stats{i_run,i_testcase},'Yopt')
            tempYOpt = NaN;
            tempXOpt = NaN;
        elseif contains(signature{i_testcase},'BO') && ~contains(signature{i_testcase},'MatBO')
            %tempYOpt = [NaN(Settings{i_run,i_testcase}.initSampleSize-1,1) ; res_Stats{i_run,i_testcase}.Yopt];
            %tempXOpt = [NaN(Settings{i_run,i_testcase}.initSampleSize-1,size(res_Stats{i_run,i_testcase}.Xopt,2)) ; res_Stats{i_run,i_testcase}.Xopt];
            tempYOpt = [res_State{i_run,i_testcase}.EvalSamples.Y];
            tempXOpt = [res_State{i_run,i_testcase}.EvalSamples.X];
            %tempXOpt = [NaN(Settings{i_run,i_testcase}.initSampleSize-1,size(res_Stats{i_run,i_testcase}.Xopt,2)) ; res_Stats{i_run,i_testcase}.Xopt];
            if ppSettings.deterministicObjective
                %tempYOpt = [NaN(Settings{i_run,i_testcase}.initSampleSize-1,1) ; res_Stats{i_run,i_testcase}.Yopt];
                %tempXOpt = [NaN(Settings{i_run,i_testcase}.initSampleSize-1,size(res_Stats{i_run,i_testcase}.Xopt,2)) ; res_Stats{i_run,i_testcase}.Xopt];
                tmpOptY = inf;
                for i = 1:size(tempXOpt,1)
                    optSampleInd = find(all(res_State{i_run,i_testcase}.EvalSamples.X == repmat(tempXOpt(i,:),size(res_State{i_run,i_testcase}.EvalSamples.X,1),1),2));
                    if ~isempty(optSampleInd)
                        [tempYOpt(i)] = min(res_State{i_run,i_testcase}.EvalSamples.Y(optSampleInd,1),tmpOptY);
                        tmpOptY = tempYOpt(i);
                        if tempYOpt(i) == res_State{i_run,i_testcase}.EvalSamples.Y(optSampleInd,1)
                            tempXOpt(i,:) = res_State{i_run,i_testcase}.EvalSamples.X(optSampleInd,:);
                        else
                            tempXOpt(i,:) = tempXOpt(i-1,:);
                        end

                    end
                end
            else
                error('Not supprted anymore.')
            end

        else
            tempYOpt = res_Stats{i_run,i_testcase}.Yopt;
            tempXOpt = res_Stats{i_run,i_testcase}.Xopt;
        end


        if ppSettings.earlyStoppingPP

            caseInd             = find(testcaseMat(:,i_testcase));
            maxEpistodeLength   = datForPP.Cases{1,caseInd}.maxEpisodeLength;
            maxNumberOfTimeSteps = Settings{1,i_testcase}.MaxCumEpisodeLength;
            xInterp = linspace(maxEpistodeLength,maxNumberOfTimeSteps,100);
            if ~(isfield(Settings{1,i_testcase},'enableEarlyEvalStop') && Settings{1,i_testcase}.enableEarlyEvalStop)
                if ~isempty(res_State{i_run,i_testcase})
                    tempYOptReint = interp1([maxEpistodeLength:maxEpistodeLength:maxEpistodeLength*length(tempYOpt)],tempYOpt,xInterp,'previous',min(tempYOpt));
                else
                    tempYOptReint = NaN;
                end
            else
                if ~isempty(res_State{i_run,i_testcase})
                    tempYOptReint = interp1(cumsum(res_State{i_run,i_testcase}.EvalSamples.episodeLength),tempYOpt,xInterp,'previous',min(tempYOpt));
                else
                    tempYOptReint = NaN;
                end



            end
        else
            caseInd             = find(testcaseMat(:,i_testcase));
            if isfield(ppSettings,'maxSamplesPerCase') 
                tempYOpt(end+1: ppSettings.maxSamplesPerCase(caseInd) ) = tempYOpt(end);
            end
        end

        testCaseRes.xbest{i_testcase,i_run} = tempXOpt;
        testCaseRes.feasibility{i_testcase} = concatRow(testCaseRes.feasibility{i_testcase},~isinf(tempYOpt));
        if ppSettings.earlyStoppingPP
            testCaseRes.ybest{i_testcase}(i_run,:) = tempYOptReint;
            testCaseRes.xAxis{i_testcase} = xInterp;
        else
            testCaseRes.ybest{i_testcase}       = concatRow(testCaseRes.ybest{i_testcase},tempYOpt);
            testCaseRes.xAxis{i_testcase}       = [1:1:size(testCaseRes.ybest{i_testcase},2)];
        end
    end
    testCaseRes.ybest{i_testcase}(isinf(testCaseRes.ybest{i_testcase})) = NaN;
    %calculateMeanFeasibility
    testCaseRes.avgfeas{i_testcase}     = mean(testCaseRes.feasibility{i_testcase},1);
    testCaseRes.stdfeas{i_testcase}  = std(testCaseRes.feasibility{i_testcase},0,1);

    testCaseRes.avgybest{i_testcase}    = mean(testCaseRes.ybest{i_testcase},1,'omitnan');
    testCaseRes.medianybest{i_testcase} = median(testCaseRes.ybest{i_testcase},1,'omitnan');
    %testCaseRes.medianybest{i_testcase} = mean(testCaseRes.ybest{i_testcase},1,'omitnan');
    %warning('upper line changed from median to mean')
    testCaseRes.quant80ybest{i_testcase}= quantile(testCaseRes.ybest{i_testcase},0.8,1);

    %testCaseRes.avgybest{i_testcase} = mean(testCaseRes.ybest{i_testcase},1,'omitnan');
    testCaseRes.stdybest{i_testcase} = std(testCaseRes.ybest{i_testcase},0,1,'omitnan');

end


%Post processing für validation Performance und feasibility
for i_testcase = 1: size(res_Stats,2)
    disp(['Testcase ',num2str(i_testcase),'/',num2str(size(res_Stats,2))])
    %noOfRuns = size(res_Stats,1)-1;
    caseNo   = find(testcaseMat(:,i_testcase));
    if contains(signature{i_testcase},'noise') && ~all(isnan(testCaseRes.xbest{i_testcase,i_run}))
        for i_run = 1:noOfRuns
            [validationStats{i_testcase,i_run}] = getValidationPerformance(testCaseRes.xbest{i_testcase,i_run},Case{caseNo},BenchmarkSettings.NoValidationSims);
            testCaseRes.feasibilityVal{i_testcase}(i_run,:)    = validationStats{i_testcase,i_run}.Valid;
            testCaseRes.perfVal{i_testcase}(i_run,:) = validationStats{i_testcase,i_run}.meanPerf;
            testCaseRes.perfVal{i_testcase}(i_run,~testCaseRes.feasibilityVal{i_testcase}(i_run,:))= NaN;
        end

        testCaseRes.avgfeasVal{i_testcase}  = mean(testCaseRes.feasibilityVal{i_testcase},1);
        testCaseRes.avgperfVal{i_testcase}  = mean(testCaseRes.perfVal{i_testcase},1,'omitnan');
        testCaseRes.stdfeasVal{i_testcase}  = std(testCaseRes.feasibilityVal{i_testcase},0,1);
        testCaseRes.stdperfVal{i_testcase} = std(testCaseRes.perfVal{i_testcase},0,1,'omitnan');

    end
    %testCaseResVal.avgfeas
    % AverageStuff over the runs!
end

%Caluclate percentage of solved instances
%Find min and max observed val for each testcase

for i_Case = 1: length(testcases)
    inds = find(testcaseMat(i_Case,:) == 1);
    overallMin(i_Case) = inf;
    overallMax(i_Case) = -inf;
    for i_run = 1:noOfRuns
        for i_optimizer = 1:length(inds)
            if ~contains(signature{inds(i_optimizer)},'OutDet')
                overallMax(i_Case) = max(overallMax(i_Case),max(testCaseRes.ybest{inds(i_optimizer)}(i_run,:)));
                [tmpMin tmpMinInd] = min(testCaseRes.ybest{inds(i_optimizer)}(i_run,:));
                if overallMin(i_Case) > tmpMin
                    overallMin(i_Case) =  tmpMin;
                    if ~ppSettings.earlyStoppingPP
                        overallXOpt{i_Case} = testCaseRes.xbest{inds(i_optimizer),i_run}(tmpMinInd,:);
                    end
                end
                %if min(res_Stats{i_run,inds(i_optimizer)}.Yopt) < 0
                %                     disp(signature{inds(i_optimizer)})
                %                 end
            end
        end
    end
end
if isfield(datForPP,'overallMin')
    overallMin = datForPP.overallMin;
end
OptimalityGap = overallMax-overallMin;



%Create Ranking
%Average Rank only over cases the runs for which all optiizers have been
%completed!

for i_Case = 1: length(testcases)
    inds = find(testcaseMat(i_Case,:) == 1);
    comletedRunsPerCase(i_Case) = max(find(all(~cellfun(@isempty,res_Stats(:,inds)),2)));
    for i_run = 1:comletedRunsPerCase(i_Case)
        testCaseRes.perf{i_Case,i_run} =  [];
        testCaseRes.perfreint{i_Case,i_run} =  [];
        for i_optimizer = 1:length(inds)
            testCaseRes.perf{i_Case,i_run} = concatRow(testCaseRes.perf{i_Case,i_run},testCaseRes.ybest{inds(i_optimizer)}(i_run,:));
            %testCaseRes.perf{i_Case,i_run}(i_optimizer,:) = testCaseRes.ybest{inds(i_optimizer)}(i_run,:);
        end
        for i_eval = 1:size(testCaseRes.perf{i_Case,i_run},2)
            tmpResults = testCaseRes.perf{i_Case,i_run}(:,i_eval);
            tmpResults(isnan(tmpResults)) = inf;
            tmpRank    = tiedrank(tmpResults);
            testCaseRes.Rank{i_Case,i_run}(:,i_eval) = tmpRank;
            for i_optimizer = 1:length(inds)
                testCaseRes.RankPerAlgo{i_Case,i_optimizer}(i_run,i_eval)  = tmpRank(i_optimizer);
            end
        end
        if ppSettings.earlyStoppingPP
            for i_eval = 1:size(testCaseRes.perfreint{i_Case,i_run},2)
                tmpResults = testCaseRes.perfreint{i_Case,i_run}(:,i_eval);
                tmpResults(isnan(tmpResults)) = inf;
                tmpRank    = tiedrank(tmpResults);
                testCaseRes.Rankreint{i_Case,i_run}(:,i_eval) = tmpRank;
                for i_optimizer = 1:length(inds)
                    testCaseRes.RankPerAlgoreint{i_Case,i_optimizer}(i_run,i_eval)  = tmpRank(i_optimizer);
                end
            end
        end



    end
    if ~isempty(gridReference)
        %Get iterations after which the baseline has been beaten:
        %testCaseRes.evalBeforeBaseline{i_Case}(i_optimizer,i_run)
        for i_optimizer = 1:length(inds)
            for i_run = 1:comletedRunsPerCase(i_Case)
                tmpBetterThanBl = find(testCaseRes.perf{i_Case,i_run}(i_optimizer,:) < gridReference.yOpt(i_Case));
                if isempty(tmpBetterThanBl)
                    testCaseRes.noEvalBeforeBaseline{i_Case}(i_optimizer,i_run) = NaN;
                else
                    while true
                        startPoint = tmpBetterThanBl(1);
                        if isempty(setdiff(tmpBetterThanBl(1),startPoint:size(testCaseRes.perf{i_Case,i_run},2)))
                            break
                        else
                            tmpBetterThanBl(1) = [];
                            if isempty(tmpBetterThanBl)
                                break
                            end
                        end
                    end
                    if isempty(tmpBetterThanBl)
                        testCaseRes.noEvalBeforeBaseline{i_Case}(i_optimizer,i_run) = NaN;
                    end
                    testCaseRes.noEvalBeforeBaseline{i_Case}(i_optimizer,i_run) = tmpBetterThanBl(1);
                end
            end
        end

        %Average the Baseline stats over all runs
        testCaseRes.baselineExtdPercentage(i_Case,:) =   sum(~isnan(testCaseRes.noEvalBeforeBaseline{i_Case}),2)./size(testCaseRes.noEvalBeforeBaseline{i_Case},2);
        testCaseRes.baselineExtdTimeMean(i_Case,:) = nanmean(testCaseRes.noEvalBeforeBaseline{i_Case},2);
        testCaseRes.baselineExtdTimeMedian(i_Case,:) = nanmedian(testCaseRes.noEvalBeforeBaseline{i_Case},2);

        for i_optimizer = 1:length(inds)
            testCaseRes.medianImprovementOverBaseline(i_Case,i_optimizer) =  testCaseRes.medianybest{inds(i_optimizer)}(end) - gridReference.yOpt(i_Case);
        end
    end
    %Average the Rank over all runs
    for i_optimizer = 1:length(inds)
        testCaseRes.AverageRankPerAlgo{i_Case}(i_optimizer,:) = mean(testCaseRes.RankPerAlgo{i_Case,i_optimizer},1);
        testCaseRes.StdRankPerAlgo{i_Case}(i_optimizer,:) = std(testCaseRes.RankPerAlgo{i_Case,i_optimizer},0,1);
    end

    for i_eval = 1:size(testCaseRes.AverageRankPerAlgo{i_Case},2)
        %find optimizer with lowest average Rank:
        [~,minInd] = min(testCaseRes.AverageRankPerAlgo{i_Case}(:,i_eval));
        %test weather each of the other algorithms is significantly wors
        %than the others
        for i_optimizer = 1:length(inds)
            if i_optimizer == minInd
                testCaseRes.significantlyWorseThanBest{i_Case}(i_optimizer,i_eval) = false;
            else
                %Nullhypothese H_0:          Median von Best ist größer oder gleich wie der Median von Kandidat
                %Alternativhpothese H_1:     Median von Best ist kleiner als der Median von Kandidat
                [p,h,stats] = ranksum(testCaseRes.RankPerAlgo{i_Case,minInd}(:,i_eval),testCaseRes.RankPerAlgo{i_Case,i_optimizer}(:,i_eval),'tail','left');
                testCaseRes.significantlyWorseThanBest{i_Case}(i_optimizer,i_eval) = h==1;
            end
        end
    end

end
%Iterate over epsilon such that the best algotihm has x% solving
%percentage

targetSolvingPercentage = 0.2;
counter = 1;
while true

    %Check wether problems have been solved
    for i_Case = 1: length(testcases)
        inds = find(testcaseMat(i_Case,:) == 1);
        for i_run = 1:comletedRunsPerCase(i_Case)
            %for i_optimizer = 1:length(inds)
            testCaseRes.solved{i_Case,i_run} = testCaseRes.perf{i_Case,i_run} < (overallMin(i_Case) + OptimalityGap(i_Case)*ppSettings.OptimalityEps(i_Case));
            %testCaseRes.solved{i_Case,i_run} = testCaseRes.perf{i_Case,i_run} < overallMin(i_Case)*(1+ppSettings.OptimalityEps(i_Case));
            %end
        end
    end

    %Average percentage of solved Runs over all runs
    for i_Case = 1: length(testcases)
        inds = find(testcaseMat(i_Case,:) == 1);
        for i_optimizer = 1:length(inds)
            testCaseRes.AverageSolved{i_Case}(i_optimizer,:) = zeros(1,size(testCaseRes.solved{i_Case,1},2));
            for i_run = 1:comletedRunsPerCase(i_Case)
                testCaseRes.AverageSolved{i_Case}(i_optimizer,:) = testCaseRes.AverageSolved{i_Case}(i_optimizer,:) + testCaseRes.solved{i_Case,i_run}(i_optimizer,:);
            end
            testCaseRes.AverageSolved{i_Case}(i_optimizer,:) = testCaseRes.AverageSolved{i_Case}(i_optimizer,:)./comletedRunsPerCase(i_Case);
        end
        maxAverageSolved(i_Case) = max(max(testCaseRes.AverageSolved{i_Case}));
    end


    if all(maxAverageSolved >= targetSolvingPercentage) && all(maxAverageSolved <= targetSolvingPercentage) || counter > 400
        break
    end
    ppSettings.OptimalityEps = (maxAverageSolved >= targetSolvingPercentage & maxAverageSolved <= targetSolvingPercentage).*ppSettings.OptimalityEps  + (maxAverageSolved < targetSolvingPercentage).*ppSettings.OptimalityEps*1.2 + (maxAverageSolved > targetSolvingPercentage).*ppSettings.OptimalityEps*0.95 ;
    counter = counter + 1;
    disp(counter)
    disp(maxAverageSolved)
    disp(ppSettings.OptimalityEps)
end

% Calculate Percentage of the algorithms beating certain levels starting
% from the baseline and going down to the value which the best algorithm
% beats only 20% of the time
if ~isempty(gridReference)
    noOfLevels = 9;
    for i_level = 1:noOfLevels
        for i_Case = 1: length(testcases)
            inds = find(testcaseMat(i_Case,:) == 1);
            for i_run = 1:comletedRunsPerCase(i_Case)
                if i_level == 1
                    testCaseRes.refBeaten{i_Case,i_run} = testCaseRes.perf{i_Case,i_run} < gridReference.yOpt(i_Case);
                end
                testCaseRes.levelBeaten{i_level}{i_Case,i_run} = testCaseRes.perf{i_Case,i_run} < (gridReference.yOpt(i_Case)*((1-(i_level-1)/(noOfLevels-1)))+(i_level-1)/(noOfLevels-1)*(overallMin(i_Case) + OptimalityGap(i_Case)*ppSettings.OptimalityEps(i_Case)));
            end
        end

        for i_Case = 1: length(testcases)
            inds = find(testcaseMat(i_Case,:) == 1);
            for i_optimizer = 1:length(inds)

                if i_level == 1
                    testCaseRes.AverageRefBeaten{i_Case}(i_optimizer,:) = zeros(1,size(testCaseRes.refBeaten{i_Case,1},2));
                    for i_run = 1:comletedRunsPerCase(i_Case)
                        testCaseRes.AverageRefBeaten{i_Case}(i_optimizer,:) = testCaseRes.AverageRefBeaten{i_Case}(i_optimizer,:) + testCaseRes.refBeaten{i_Case,i_run}(i_optimizer,:);
                    end
                    testCaseRes.AverageRefBeaten{i_Case}(i_optimizer,:) = testCaseRes.AverageRefBeaten{i_Case}(i_optimizer,:)./comletedRunsPerCase(i_Case);
                end
                testCaseRes.AverageLevelBeaten{i_Case,i_level}(i_optimizer,:) = zeros(1,size(testCaseRes.refBeaten{i_Case,1},2));
                for i_run = 1:comletedRunsPerCase(i_Case)
                    testCaseRes.AverageLevelBeaten{i_Case,i_level}(i_optimizer,:) = testCaseRes.AverageLevelBeaten{i_Case,i_level}(i_optimizer,:) + testCaseRes.levelBeaten{i_level}{i_Case,i_run}(i_optimizer,:);
                end
                testCaseRes.AverageLevelBeaten{i_Case,i_level}(i_optimizer,:) = testCaseRes.AverageLevelBeaten{i_Case,i_level}(i_optimizer,:)./comletedRunsPerCase(i_Case);


            end
        end
    end
end
findRandRef = false;

if ~isfield(datForPP,'randRef')
    randInd = find(strcmp(optimizerSignature,'BO:Rand'));
    findRandRef = true;
    if isempty(randInd)
        randInd = find(strcmp(optimizerSignature,'BO:Rand_ES'));
        if isempty(randInd)
            error('Cout not find random sampling benchmark')
        end
    end
end




%Calculate scaled median regret
for i_Case = 1: length(testcases)
    testCaseRes.MedianPerAlgo{i_Case}   = [];
    testCaseRes.Quant80PerAlgo{i_Case}  = [];
    inds = find(testcaseMat(i_Case,:) == 1);
    for i_optimizer = 1:length(inds)
        %testCaseRes.MedianPerAlgo{i_Case}(i_optimizer,:) = testCaseRes.medianybest{inds(i_optimizer)};
        testCaseRes.MedianPerAlgo{i_Case} = concatRow(testCaseRes.MedianPerAlgo{i_Case},testCaseRes.medianybest{inds(i_optimizer)});
    end
    if findRandRef
        datForPP.randRef.median(i_Case) = testCaseRes.MedianPerAlgo{i_Case}(randInd,end);
    end
    for i_optimizer = 1:length(inds)
        %testCaseRes.Quant80PerAlgo{i_Case}(i_optimizer,:) = testCaseRes.quant80ybest{inds(i_optimizer)};
        testCaseRes.Quant80PerAlgo{i_Case} =  concatRow(testCaseRes.Quant80PerAlgo{i_Case},testCaseRes.quant80ybest{inds(i_optimizer)});
    end
    testCaseRes.lowestFinalMedian(i_Case) = min(testCaseRes.MedianPerAlgo{i_Case}(:,end));
    %testCaseRes.ScaledMedianGapPerAlgo{i_Case} = (testCaseRes.MedianPerAlgo{i_Case}-testCaseRes.lowestFinalMedian(i_Case))/(overallMax(i_Case) - testCaseRes.lowestFinalMedian(i_Case));
    if ~ppSettings.useRegret
        testCaseRes.ScaledMedianGapPerAlgo{i_Case} = (testCaseRes.MedianPerAlgo{i_Case})/(datForPP.randRef.median(i_Case) );
        testCaseRes.Scaled80quantileGapPerAlgo{i_Case} = (testCaseRes.Quant80PerAlgo{i_Case})/(datForPP.randRef.median(i_Case));
    else
        testCaseRes.ScaledMedianGapPerAlgo{i_Case} = (testCaseRes.MedianPerAlgo{i_Case}-overallMin(i_Case))/(datForPP.randRef.median(i_Case) - overallMin(i_Case));
        testCaseRes.Scaled80quantileGapPerAlgo{i_Case} = (testCaseRes.Quant80PerAlgo{i_Case}-overallMin(i_Case))/(datForPP.randRef.median(i_Case) - overallMin(i_Case));
    end
end




% do distinct post processing for early stopping:





testCaseRes.randRef =  datForPP.randRef;



% CalculateAverageRank over all testcases:
testCaseRes.OverallAvgRank = zeros(size(testCaseRes.AverageRankPerAlgo{1,1},1),300);
testCaseRes.OverallSumSignificantlyWorse = zeros(size(testCaseRes.AverageRankPerAlgo{1,1},1),300);
testCaseRes.OverallAvgSolve = zeros(size(testCaseRes.AverageRankPerAlgo{1,1},1),300);
testCaseRes.OverallAvgRefBeaten = zeros(size(testCaseRes.AverageRankPerAlgo{1,1},1),300);
testCaseRes.OverallAvgScaledGap = zeros(size(testCaseRes.AverageRankPerAlgo{1,1},1),300);
testCaseRes.OverallAvgQuantScaledGap = zeros(size(testCaseRes.AverageRankPerAlgo{1,1},1),300);

if ~isempty(gridReference)
    for i_level = 1:noOfLevels
        testCaseRes.OverallAvgLevelBeaten{i_level} = zeros(size(testCaseRes.AverageRankPerAlgo{1,1},1),100);
    end
end
for iCase = 1 : length(testcases)
    tmp = testCaseRes.AverageRankPerAlgo{iCase};
    NoOfSamples = size(tmp,2);
    testCaseRes.OverallAvgRank = testCaseRes.OverallAvgRank + interp1([1:1:NoOfSamples]./NoOfSamples*300,tmp',[1:1:300],'previous')';
    tmp = testCaseRes.significantlyWorseThanBest{iCase};
    testCaseRes.OverallSumSignificantlyWorse = testCaseRes.OverallSumSignificantlyWorse + interp1([1:1:NoOfSamples]./NoOfSamples*300,double(tmp'),[1:1:300],'previous')';
    tmp = testCaseRes.AverageSolved{iCase};
    NoOfSamples = size(tmp,2);
    testCaseRes.OverallAvgSolve = testCaseRes.OverallAvgSolve + interp1([1:1:NoOfSamples]./NoOfSamples*300,tmp',[1:1:300],'previous')';
    tmp = testCaseRes.ScaledMedianGapPerAlgo{iCase};
    NoOfSamples = size(tmp,2);
    testCaseRes.OverallAvgScaledGap = testCaseRes.OverallAvgScaledGap + interp1([1:1:NoOfSamples]./NoOfSamples*300,tmp',[1:1:300],'previous')';

    tmp = testCaseRes.Scaled80quantileGapPerAlgo{iCase};
    NoOfSamples = size(tmp,2);
    testCaseRes.OverallAvgQuantScaledGap = testCaseRes.OverallAvgQuantScaledGap + interp1([1:1:NoOfSamples]./NoOfSamples*300,tmp',[1:1:300],'previous')';

    testCaseRes.interp80quantileGapPerAlgo{iCase} = interp1([1:1:NoOfSamples]./NoOfSamples*300,tmp',[1:1:300],'previous')';
    if ~isempty(gridReference)
        tmp = testCaseRes.AverageRefBeaten{iCase};
        NoOfSamples = size(tmp,2);
        testCaseRes.OverallAvgRefBeaten = testCaseRes.OverallAvgRefBeaten + interp1([1:1:NoOfSamples]./NoOfSamples*300,tmp',[1:1:300],'previous')';

        for i_level = 1:noOfLevels
            tmp = testCaseRes.AverageLevelBeaten{iCase,i_level};
            NoOfSamples = size(tmp,2);
            testCaseRes.OverallAvgLevelBeaten{i_level} = testCaseRes.OverallAvgLevelBeaten{i_level} + interp1([1:1:NoOfSamples]./NoOfSamples*300,tmp',[1:1:300],'previous')';
        end
    end

end

testCaseRes.OverallAvgRank = testCaseRes.OverallAvgRank./length(testcases);
testCaseRes.OverallAvgSolve = testCaseRes.OverallAvgSolve./length(testcases);
testCaseRes.OverallAvgScaledGap = testCaseRes.OverallAvgScaledGap ./length(testcases);
testCaseRes.OverallAvgQuantScaledGap = testCaseRes.OverallAvgQuantScaledGap ./length(testcases);
testCaseRes.OverallAvgRefBeaten= testCaseRes.OverallAvgRefBeaten ./length(testcases);
if ~isempty(gridReference)
    for i_level = 1:noOfLevels
        testCaseRes.OverallAvgLevelBeaten{i_level}= testCaseRes.OverallAvgLevelBeaten{i_level} ./length(testcases);
    end

    figure

    if noOfLevels == 9
        noOfRows    = 3;
        noOfColumns = 3;
    end
    for i_level = 1:noOfLevels
        subplot(noOfRows, noOfColumns,i_level)
        for i_optimizer = 1:length(inds)
            plot([1:1:300],testCaseRes.OverallAvgLevelBeaten{i_level}(i_optimizer,:) ,PlotStyles{i_optimizer}(1:end),'LineWidth',1.5,'Color',Colors{i_optimizer},'DisplayName',signature{inds(i_optimizer)});
            hold all
        end
        title([titleString,': ',num2str(1-(i_level-1)/(noOfLevels-1),2),'Ref +' num2str((i_level-1)/(noOfLevels-1),2),'Opt. Beaten'])
        ylim([0 1])
    end
end

for i_eval = 1:size(testCaseRes.interp80quantileGapPerAlgo{1},2)
    %find optimizer with lowest average Rank:
    if ~all(isnan(testCaseRes.OverallAvgQuantScaledGap(:,i_eval)))
        [~,minInd] =  min(testCaseRes.OverallAvgQuantScaledGap(:,i_eval));
    else
        for i_optimizer = 1:length(inds)
            testCaseRes.quant80SignWorseThanBest(i_optimizer,i_eval) = false;
        end
        continue
    end

    % collect samples for the best optimizers!
    quantilePerCaseMin = zeros(1,size(testCaseRes.interp80quantileGapPerAlgo,2));

    for i_case = 1: length(testcases)
        quantilePerCaseMin(1,i_case) = testCaseRes.interp80quantileGapPerAlgo{i_case}(minInd,i_eval);
    end
    %test weather each of the other algorithms is significantly wors
    %than the others
    for i_optimizer = 1:length(inds)
        if i_optimizer == minInd
            testCaseRes.quant80SignWorseThanBest(i_optimizer,i_eval) = false;
        else
            %collect Samples for the caindidate

            % collect samples for the best optimizers!
            quantilePerCase = zeros(1,size(testCaseRes.interp80quantileGapPerAlgo,2));

            for i_case = 1: length(testcases)
                quantilePerCase(1,i_case) = testCaseRes.interp80quantileGapPerAlgo{i_case}(i_optimizer,i_eval);
            end


            %Nullhypothese H_0:          Median von Best ist größer oder gleich wie der Median von Kandidat
            %Alternativhpothese H_1:     Median von Best ist kleiner als der Median von Kandidat
            if all(isnan(quantilePerCase))
                testCaseRes.quant80SignWorseThanBest(i_optimizer,i_eval) = false;
            else
                [p,h,stats] = ranksum(quantilePerCaseMin,quantilePerCase,'tail','left');
                testCaseRes.quant80SignWorseThanBest(i_optimizer,i_eval) = h==1;
            end
        end

    end

end

% figure
% plot the final statistics for each testcase and algorithms at the end
for i_case = 1:size(testCaseRes.perf,1)
    for i_opt = 1:size(testCaseRes.perf{i_case},1)
        for i_run = 1:comletedRunsPerCase(i_case)
            if ~ppSettings.useRegret
                testCaseRes.finalPerf.raw{i_case,i_opt}(i_run ) = (testCaseRes.perf{i_case,i_run}(i_opt,end))/(datForPP.randRef.median(i_case));
            else
                testCaseRes.finalPerf.raw{i_case,i_opt}(i_run ) = (testCaseRes.perf{i_case,i_run}(i_opt,end)-overallMin(i_case))/(datForPP.randRef.median(i_case) - overallMin(i_case));
            end
        end
        testCaseRes.finalPerf.median(i_case,i_opt) = median(testCaseRes.finalPerf.raw{i_case,i_opt});
        testCaseRes.finalPerf.mean(i_case,i_opt) = mean(testCaseRes.finalPerf.raw{i_case,i_opt});
        testCaseRes.finalPerf.quant80(i_case,i_opt) = quantile(testCaseRes.finalPerf.raw{i_case,i_opt},[0.8]);
        testCaseRes.finalPerf.quant20(i_case,i_opt) = quantile(testCaseRes.finalPerf.raw{i_case,i_opt},[0.2]);
        testCaseRes.finalPerf.std(i_case,i_opt) = std(testCaseRes.finalPerf.raw{i_case,i_opt});
    end


    for i_opt = 1:size(testCaseRes.perf{i_case},1)
        testCaseRes.finalPerf.medianRank(i_case,i_opt) = 1 + sum(testCaseRes.finalPerf.median(i_case,:) < testCaseRes.finalPerf.median(i_case,i_opt)) ;
    end
end


legend

testCaseRes.overallMin = overallMin;
try
    testCaseRes.overallXOpt = overallXOpt;
catch
end
testCaseRes.optimizerSignature = optimizerSignature;
testCaseRes.gridReference = gridReference;

end

