function [Settings,Cases,State,Stats] = runSeedsAndCases(BenchmarkSettings)

functionPath = mfilename('fullpath');
folderPath   = strrep(functionPath,'\runSeedsAndCases','');
addpath(strcat(folderPath,'\testCaseDefinitions'));
addpath(BenchmarkSettings.BOPath);
addpath(strcat(BenchmarkSettings.BOPath,'\src'));



[Cases] = getCases(BenchmarkSettings.testcases);

initSamples = cell(0);
res_State   = cell(0);
res_Stats   = cell(0);




try
    prevResults = load(BenchmarkSettings.ResultsPath);
    disp('Previous results loaded. Continuing')
catch
    disp('No previous results found. Starting from scratch.')
end

if exist('prevResults','var') && BenchmarkSettings.NoOfRuns < prevResults.BenchmarkSettings.NoOfRuns
    error('The number of iteration of the current run are smaller than that of the revious run')
end

%% Create initial samples
for i_iteration = 1:BenchmarkSettings.NoOfRuns
    %loop over testcases
    for i_testcase = 1: length(BenchmarkSettings.testcases)
        %find testcase ind in previous results:
        if exist('prevResults','var')
            prevTestcaseInd{i_testcase} = find(strcmp(BenchmarkSettings.testcases{i_testcase},prevResults.BenchmarkSettings.testcases));
            try
                previnitSampling = prevResults.initSamples{i_iteration,prevTestcaseInd{i_testcase}};
                if isempty(previnitSampling)
                    prevTestcaseInd{i_testcase}  = [];
                end
            catch
                prevTestcaseInd{i_testcase}  = [];
            end

        else
            prevTestcaseInd{i_testcase}  = [];
        end
        
        if isempty(prevTestcaseInd{i_testcase})
            [initSamples{i_iteration,i_testcase},~] = randomSampling(Cases{i_testcase},1000);
        else
            initSamples{i_iteration,i_testcase} =  previnitSampling;
        end
    end
end


%% Setup Case and Settings for the current run without starting the actual optimisation
for i_iteration = 1:BenchmarkSettings.NoOfRuns
    counter = 1; %Testcase - optimizer combinations
    %loop over testcases
    for i_testcase = 1: length(BenchmarkSettings.testcases)
        %loop over optimizers
        for i_opt = 1:length(BenchmarkSettings.optimizers)
            switch BenchmarkSettings.optimizers{i_opt}
                %loop over acquisition Functions
                case 'BO'
                    defaultSettings = BenchmarkSettings.defaultSettingsFun(Cases{i_testcase});
                    for i_BOVariant = 1: length(BenchmarkSettings.BOVariants)

                        Settings{i_iteration,counter} = BenchmarkSettings.BOSettingsFun{i_BOVariant}(defaultSettings);
                        signature{counter} = [BenchmarkSettings.testcases{i_testcase},':',BenchmarkSettings.optimizers{i_opt},':',BenchmarkSettings.BOVariants{i_BOVariant}];
                        testcaseMat(i_testcase,counter) = 1;
                        %                         save('Results')
                        counter = counter +1;
                    end
                otherwise
                    error('unknown optimizer')
            end
        end

    end
end

% Iterate over the signatures of the current run and find potentially
% corresponding sgnatures of hte revios run
if exist('prevResults','var')
    deleteSigInds = false(length(signature),1);
    if isfield(BenchmarkSettings,'redoSignatureString') && length(BenchmarkSettings.redoSignatureString) > 0
        warning('The results of some signatures will be deleted and run again!')

        disp('The following experiments will be run again!')
        for i_signature = 1:length(signature)
            for i_deleteSig = 1:length(BenchmarkSettings.redoSignatureString)
                if contains(signature(i_signature),BenchmarkSettings.redoSignatureString(i_deleteSig))
                    deleteSigInds(i_signature) = true;
                    disp(signature(i_signature));
                end
            end
        end
        disp(['A total of ',num2str(sum(deleteSigInds)),' experiments will be repeated. Do you agree?'])
        w = waitforbuttonpress;
    end
    for i_signature = 1:length(signature)
        ind = find(strcmp(signature{i_signature},prevResults.signature));
        if ~isempty(ind)&& ~deleteSigInds(i_signature)
            for i_iteration = 1:BenchmarkSettings.NoOfRuns
                try
                    res_Stats{i_iteration,i_signature} = prevResults.res_Stats{i_iteration,ind};
                    res_State{i_iteration,i_signature} = prevResults.res_State{i_iteration,ind};
                catch
                end
            end
        end
    end
end



%%Calculate Reference
if (exist('prevResults','var') && isfield(prevResults,'gridReference')) && ~BenchmarkSettings.regenGridRef
    error('Needs to be checked!')
    [gridReference] = getGridReference(Cases,testcases,testcaseMat,prevResults.gridReference);
elseif isfield(BenchmarkSettings,'UseGridReference') && ~BenchmarkSettings.UseGridReference

else
    error('Needs to be checked!')
    [gridReference] = getGridReference(Cases,testcases,testcaseMat,[]);
end


clear prevResults

save(BenchmarkSettings.ResultsPath,'-v7.3')
lastSaveTime = clock;
%% Perform the optimization!

for i_iteration = 1:BenchmarkSettings.NoOfRuns
    counter = 1; %Testcase - optimizer combinations
    %loop over testcases
    for i_testcase = 1: length(BenchmarkSettings.testcases)
        %loop over optimizers
        for i_opt = 1:length(BenchmarkSettings.optimizers)
            switch BenchmarkSettings.optimizers{i_opt}
                %loop over BO variants
                case 'BO'
                    Cases{i_testcase}.Initsamples = initSamples{i_iteration,i_testcase}(1:Settings{i_iteration,counter}.initSampleSize,:);
                    for i_BOVariant = 1:length(BenchmarkSettings.BOVariants)
                        if (any(size(res_Stats) < [i_iteration,counter]) || isempty(res_Stats{i_iteration,counter})) && i_iteration <= BenchmarkSettings.tempEvalCap(i_testcase)
                            Cases{i_testcase} = Cases{i_testcase}.initFun(Cases{i_testcase});
                            [res_State{i_iteration,counter},res_Stats{i_iteration,counter}] = EGO(Cases{i_testcase},Settings{i_iteration,counter});
                            Cases{i_testcase}.cleanUpFun(Cases{i_testcase});
                            if etime(clock,lastSaveTime) > BenchmarkSettings.saveInterval*60
                                save(BenchmarkSettings.ResultsPath,'-v7.3')
                                lastSaveTime = clock;
                            end
                        end
                        counter = counter +1;
                    end                   
                otherwise
                    error('unknown optimizer')
            end
        end

    end
end



save(BenchmarkSettings.ResultsPath,'-v7.3')
lastSaveTime = clock;


