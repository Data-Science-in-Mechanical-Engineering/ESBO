function [State] = genESVirtDat(State,Settings,Case)

if strcmp(Settings.OutlierClassification,'virtualData') && sum(~State.EvalSamples.OutlierBool) >= Settings.OutlierDetectionSettings.minElements
    outlierBool = logical(State.EvalSamples.OutlierBool);
else
    outlierBool = false(size(State.EvalSamples.YVect,1),1);
end

if isfield(Settings.ESSettings,'useEpisodeTimeMax') && Settings.ESSettings.useEpisodeTimeMax % This is the code for ESBO-TR (Sec. V.B.b )
    State.useVirtualYData = true;
    State.useVirtualSigmaYData = false;
    close all
    figure
    YMin = min(State.EvalSamples.Y(State.EvalSamples.episodeLength == Case.maxEpisodeLength));
    State.ES.yMin = YMin;
    for i = 1:size(State.EvalSamples.YVect,1)
        timeInterpX = cumsum(State.EvalSamples.YVect(i,1:State.EvalSamples.episodeLength(i)));
        timeInterpY = [1:1:State.EvalSamples.episodeLength(i)];
        [timeInterpX,inds,~] = unique(timeInterpX);
        timeInterpY = timeInterpY(inds);
        episodeLengthAdj(i)= interp1(timeInterpX,timeInterpY, YMin ,'linear',State.EvalSamples.episodeLength(i));
        color = [i/size(State.EvalSamples.YVect,1) 0 0];

        plot(cumsum(State.EvalSamples.YVect(i,1:State.EvalSamples.episodeLength(i))'),'Color',color)
        hold all
        plot(episodeLengthAdj(i),YMin,'k*')
        if ~outlierBool(i)
            State.EvalSamples.virtualY(i,1) = -episodeLengthAdj(i);
            State.EvalSamples.virtualSigma_Y(i,1) = nan;
        else
            State.EvalSamples.virtualY(i,1) = 0;
            State.EvalSamples.virtualSigma_Y(i,1) = nan;
        end
    end
    return
end



% assign settings for metamodelling
if isfield(Settings.ESSettings,'useVDPHeuristic') && Settings.ESSettings.useVDPHeuristic % Code for ESBO-C (V.B.a) - see also outClassVirtDat.m
    shortInds = State.EvalSamples.episodeLength ~= Case.maxEpisodeLength;
    State.EvalSamples.OutlierBool(shortInds) = true;
else
    State.useVirtualYData = true;
    State.useVirtualSigmaYData = true;
end
noOfSimSamples = 100;

for i = 1:Case.maxEpisodeLength
    nonNaNInds{i} = find(~isnan(State.EvalSamples.YVect(:,i)));
    noNonNaNinds(i) = length(nonNaNInds{i});
end

if isfield(Settings.ESSettings,'enableGPPred') && ...
        Settings.ESSettings.enableGPPred && sum(State.EvalSamples.episodeLength ~= Case.maxEpisodeLength) > 0 ...
        && ~Settings.ESSettings.useLumpedPred
        % Here, we tried to build a model for j(\theta,t) directly. This was
        % not succesfull. If you have questions do not hesitate to contact
        % the authors.
        error('not implemented')
elseif isfield(Settings.ESSettings,'enableGPPred') && ...
        Settings.ESSettings.enableGPPred && sum(State.EvalSamples.episodeLength ~= Case.maxEpisodeLength) > 0 ...
        && Settings.ESSettings.useLumpedPred % Code for ESBO-GP (Sec. V.B.c)
    [GPModelTree] = trainHierachicalESGP(State.EvalSamples.X, State.EvalSamples.YVect,...
        State.EvalSamples.episodeLength,outlierBool,Case,Settings.MetamodellSettings.noisyObservations);
end

close all

for i = 1:size(State.EvalSamples.YVect,1)
    if outlierBool(i)
        State.EvalSamples.virtualY(i,1) = 0;
        State.EvalSamples.virtualSigma_Y(i,1) = nan;
    else

        State.EvalSamples.virtualY(i,1) = State.EvalSamples.Y(i);
        State.EvalSamples.virtualSigma_Y(i,1) = nan;

    end
end

figure

for i = 1:size(State.EvalSamples.YVect,1)
    color = [i/size(State.EvalSamples.YVect,1) 0 0];

    plot(cumsum(State.EvalSamples.YVect(i,1:State.EvalSamples.episodeLength(i))'),'Color',color)
    hold all
    % Calculate virtual data points

    if ~(State.EvalSamples.episodeLength(i) == Case.maxEpisodeLength) && ~outlierBool(i)




        %initialize cost trajectories with the true cost obtained so far
        costTrajectories = zeros(noOfSimSamples,Case.maxEpisodeLength);
        costTrajectories(1:noOfSimSamples,1:State.EvalSamples.episodeLength(i)) = repmat(cumsum(State.EvalSamples.YVect(i,1:State.EvalSamples.episodeLength(i))),noOfSimSamples,1);


        if isfield(Settings.ESSettings,'enableGPPred') && ...
                Settings.ESSettings.enableGPPred && ~Settings.ESSettings.useLumpedPred
            error('Not implemented')
        elseif isfield(Settings.ESSettings,'enableGPPred') && ...
                Settings.ESSettings.enableGPPred && Settings.ESSettings.useLumpedPred

            jObserved = sum(State.EvalSamples.YVect(i,1:State.EvalSamples.episodeLength(i)),2);


            jPred = predHierachicalESGP(i,State.EvalSamples.X(i,:),GPModelTree);
            %mu, sigma
            if isfield(Settings.ESSettings,'useTruncatedMomentMatching') && Settings.ESSettings.useTruncatedMomentMatching
                % not used anymore - in the final implementation we ensure in the sampling that predicted costs are never negative 
                tic
                clearvars mu_matched s2_matched

                for i_mm = 1:1:size(jPred,1)
                    % from
                    % https://en.wikipedia.org/wiki/Truncated_normal_distribution
                    alpha = (0 - jPred(i_mm,1))/jPred(i_mm,2);

                    Z = 1-normcdf(alpha);
                    
                    normpdfalpha = normpdf(alpha);

                    mu_matched(i_mm) = jPred(i_mm,1) +  jPred(i_mm,2)*normpdfalpha/Z;
                    s2_matched(i_mm) = jPred(i_mm,2)^2 * (1 + alpha*normpdfalpha/Z - (alpha*normpdfalpha/Z)^2 );
                    
                    if Z == 0 || s2_matched(i_mm)<=0
                        % Most of the probability mass is negative
                        % Keep the uncertainty constant and shift the mean
                        % to 3sigma
                        mu_matched(i_mm) = 3*jPred(i_mm,2);
                        s2_matched(i_mm) = jPred(i_mm,2)^2;
                        continue
                    end


                    plotRange = [min(mu_matched(i_mm) - 3*sqrt(s2_matched(i_mm)),jPred(i_mm,1) - 3*jPred(i_mm,2)),max(mu_matched(i_mm) - 3*sqrt(s2_matched(i_mm)),jPred(i_mm,1) + 3*jPred(i_mm,2))];

                   
                    if normcdf(0,mu_matched(i_mm),sqrt(s2_matched(i_mm))) > normcdf(-3)
                        %disp('MLE ')
                        pd = makedist('Normal');
                        pd.mu = jPred(i_mm,1);
                        pd.sigma = jPred(i_mm,2);
                        pd = truncate(pd,0,inf);
                        data = random(pd,1000,1);
                        %stdData = std(Data);
                        %Data = std(Data);
                        newpdf = @(x1,mu) normpdf(x1,mu,mu/3);
                        [phat,ci] = mle(data,'pdf',newpdf,'Start',mu_matched(i_mm),'LowerBound',0);
                        % plotMLE = newpdf(plotX,phat);
                        % plot(plotX,plotMLE,'DisplayName','MLE')
                        s2_matched(i_mm) = (phat/3)^2;
                        mu_matched(i_mm) = phat;
                    end
                    if mu_matched(i_mm) < 0
                        error('something went wrong!')
                    end
                    if any(isinf(mu_matched)) || any(~isreal(s2_matched))
                        error('something went wrong')
                    end

                    %disp('reduction to a fraction of  ')
                    %disp(normcdf(0,mu_matched(i_mm),sqrt(s2_matched(i_mm)))/normcdf(0,jPred(i_mm,1),jPred(i_mm,2)))
                end
                disp('Time for MLE')
                toc
                State.EvalSamples.virtualY(i,1) = jObserved + sum(mu_matched);
                State.EvalSamples.virtualSigma_Y(i,1) = sqrt(sum(s2_matched));

            else
                State.EvalSamples.virtualY(i,1) = jObserved + sum(max(jPred(:,1),0));
                State.EvalSamples.virtualSigma_Y(i,1) = sqrt(sum(jPred(:,2).^2));
            end
            
            if isfield(Settings.ESSettings,'useLumbedGPMC') && Settings.ESSettings.useLumbedGPMC
                % Sampling of one virtual observation in ESBO-GP (Sec. V.B.c ) 
                mcPoint = max(State.EvalSamples.virtualY(i,1) - jObserved + randn(1,1)*State.EvalSamples.virtualSigma_Y(i,1),0);
                State.EvalSamples.virtualY(i,1) = jObserved + mcPoint;
                State.EvalSamples.virtualSigma_Y(i,1)  = NaN;
            end

            plot(cumsum(State.EvalSamples.YVect(i,1:State.EvalSamples.episodeLength(i))'),'Color',color)
            try
                plot(cumsum(State.EvalSamples.info{i}.simoutComplete.j.signals.values(State.EvalSamples.info{i}.startInd:end)),':','Color',color);
            catch
            end

            errorbar(Case.maxEpisodeLength,State.EvalSamples.virtualY(i,1),State.EvalSamples.virtualSigma_Y(i,1),'Color',color)
            plot([State.EvalSamples.episodeLength(i) Case.maxEpisodeLength],[sum(State.EvalSamples.YVect(i,1:State.EvalSamples.episodeLength(i))),   State.EvalSamples.virtualY(i)],'Color',color);



        else
            % This is only used in ESBO-C if not enough complete episodes have been observed.
            % For example, it would be hard to train the GP model with only one complete episode. 
            % Simulate cost trajectories by choosing randomly between the
            % samples obtained so far.
            for i_sample = 1:noOfSimSamples
                for i_episode = State.EvalSamples.episodeLength(i): Case.maxEpisodeLength
                    costTrajectories(i_sample,i_episode) = costTrajectories(i_sample,i_episode-1) + State.EvalSamples.YVect(nonNaNInds{i_episode}(ceil(rand(1,1)*noNonNaNinds(i_episode))),i_episode);
                end
            end
            % obtain expected cost by averaging over the simulated trajectories
            tmpAvgCost = mean(costTrajectories,1);
            tmpStdCost = std(costTrajectories,0,1);
            State.EvalSamples.virtualY(i,1) = tmpAvgCost(end);
            State.EvalSamples.virtualSigma_Y(i,1) = tmpStdCost(end);
            plot(tmpAvgCost,'Color',color)
            hold all
            plot(tmpAvgCost + 2*tmpStdCost,'--','Color',color);
            plot(tmpAvgCost - 2*tmpStdCost,'--','Color',color);
            try
                plot(cumsum(State.EvalSamples.info{i}.simoutComplete.j.signals.values(State.EvalSamples.info{i}.startInd:end)),':','Color',color);
            catch
            end
        end
    end
end


xlabel('Time Steps')
ylabel('j')

% calculate lower bound for episode abortion

costTrajectories = zeros(noOfSimSamples,Case.maxEpisodeLength);
minTraj = zeros(1,Case.maxEpisodeLength);
for i_sample = 1:noOfSimSamples
    for i_episode = 2: Case.maxEpisodeLength
        costTrajectories(i_sample,i_episode) = costTrajectories(i_sample,i_episode-1) + State.EvalSamples.YVect(nonNaNInds{i_episode}(ceil(rand(1,1)*noNonNaNinds(i_episode))),i_episode);
        minTraj(1,i_episode) = minTraj(1,i_episode-1) + min(State.EvalSamples.YVect(nonNaNInds{i_episode},i_episode));
    end
end
tmpAvgCost = mean(costTrajectories,1);
tmpStdCost = std(costTrajectories,0,1);
tmpminCost = minTraj;

minCost = min(State.EvalSamples.Y(State.EvalSamples.episodeLength == Case.maxEpisodeLength));
if isinf(Settings.ESSettings.estimateFutureCostConf)
    lowerCumCostBound = max(tmpminCost - 0.1*tmpStdCost,0);
else
    error('not used in final implementation')
    lowerCumCostBound = max(tmpAvgCost -  Settings.ESSettings.estimateFutureCostConf*tmpStdCost,0);
end

abbortThreshHold = minCost-( lowerCumCostBound(end)- lowerCumCostBound);


if Settings.ESSettings.estimateFutureCost
    error('not used in final implementation')
    State.ES.yMin = abbortThreshHold;
    plot(abbortThreshHold,'b')
else
    State.ES.yMin = minCost;

    plot([1 length(tmpAvgCost)],[State.ES.yMin State.ES.yMin],'b')
end

