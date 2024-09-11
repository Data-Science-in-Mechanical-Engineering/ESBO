function [State] = fitMetaModels(State,Settings,Stats,Case)
c1 = clock;
%merge evaluated designs


if ~isfield(State,'useVirtualSigmaYData')
    State.useVirtualSigmaYData = false;
end

if ~isfield(State.EvalSamples,'OutlierBool') || size(State.EvalSamples.OutlierBool,1) ~= size(State.EvalSamples.X,1)
    warning('FitMetaModels: The field Outlier Bool was not set.')
    State.EvalSamples.OutlierBool = zeros(size(State.EvalSamples.X,1),1);
    
end

if ~isfield(State.EvalSamples,'FailedBool') || size(State.EvalSamples.FailedBool,1) ~= size(State.EvalSamples.X,1)
    warning('FitMetaModels: The field Failed Bool was not set correctly.')
    State.EvalSamples.FailedBool = zeros(size(State.EvalSamples.X,1),1);
end


if ~isfield(State.EvalSamples,'EvalPendingl') 
    State.EvalSamples.EvalPending = false(size(State.EvalSamples.X,1),1);
end



samplesGP = ~(State.EvalSamples.OutlierBool | State.EvalSamples.FailedBool | State.EvalSamples.EvalPending); %Boolean which tells us which points to use for the GP!  

if isfield(State,'useVirtualYData') && State.useVirtualYData
    virtualYDataInds = State.EvalSamples.virtualY(:,1) ~= 0;
    samplesGP(virtualYDataInds) = true;
    virtualYDataIndsTarget = virtualYDataInds(samplesGP);
end

% if sum(samplesGP) <= 1
%     samplesGP(~samplesGP) = true;
% end

X = State.EvalSamples.X(samplesGP,:);
if isfield(State.EvalSamples,'Constrnt') && ~isempty(State.EvalSamples.Constrnt)
    Ytemp = [State.EvalSamples.Y(samplesGP,:) State.EvalSamples.Constrnt(samplesGP,:)];
    if isfield(State,'useVirtualYData') && State.useVirtualYData
        Ytemp(virtualYDataIndsTarget,:) = State.EvalSamples.virtualY(virtualYDataInds,:);
    end
else
    Ytemp = State.EvalSamples.Y(samplesGP,:);
    if isfield(State,'useVirtualYData') && State.useVirtualYData
        Ytemp(virtualYDataIndsTarget) = State.EvalSamples.virtualY(virtualYDataInds,:);
    end
end

for i = 1:size(Ytemp,2)
    [~ , uniqueYidns{i}] = unique([X,Ytemp(:,i)],'rows');
    Y{i} = Ytemp(uniqueYidns{i},i);
end

if isfield(State,'useVirtualSigmaYData') && State.useVirtualSigmaYData 
    Y_Sigma{1} = State.EvalSamples.virtualSigma_Y;
    Y_Sigma{1} = Y_Sigma{1}(samplesGP);
    Y_Sigma{1} = Y_Sigma{1}(uniqueYidns{i});
end
    

%Scale X and Y to zero mean and unity Std

if ~isfield(State,'enforceRefit')
    State.enforceRefit = false;
end
if ~isfield(State,'refuseRefit')
    State.refuseRefit = false;
end
if ~isfield(Stats,'sucEvals') && ~State.refuseRefit 
    State.enforceRefit = true;
end
if ~isfield(Settings,'maxIntError')
    Settings.maxIntError = 10^10;
end



if ~State.refuseRefit  &&  (State.enforceRefit || ~isfield(State,'MM') || (State.totalNumberOfEvals - Stats.sucEvals(State.LastHyperParamOpt)  >=  Settings.reOptimizingFrequency))
    %Update Scaling ONLY when Metamodel is updated with hyper parameter
    %optimisation
    uniqueX = unique(X,'rows');
    for i = 1:size(X,2)
        %State.MM.Scaling.MeanX(i) = mean(uniqueX(:,i));
        %State.MM.Scaling.StdX(i) = std(uniqueX(:,i)); 
        %Achtung! Die x-Werte werden auf den unit cube skaliert!!!
        State.MM.Scaling.MeanX(i) = Case.lb(i);
        State.MM.Scaling.StdX(i) = Case.ub(i)-Case.lb(i);
    end
    
    for i = 1:length(Y)
        State.MM.Scaling.MeanY(i) = mean(Y{i});
        State.MM.Scaling.StdY(i) = max(std(Y{i}),10^-10);
    end
end

for i = 1:size(X,2)
    X(:,i) = (X(:,i) - State.MM.Scaling.MeanX(i))/State.MM.Scaling.StdX(i);
end

for i = 1:length(Y)
    Y{i} = (Y{i} - State.MM.Scaling.MeanY(i))/State.MM.Scaling.StdY(i);
end

if State.useVirtualSigmaYData
   for i = 1:length(Y)
        Y_Sigma{i} = Y_Sigma{i}/State.MM.Scaling.StdY(i);
   end
end



% Create new Metamodel?

if strcmp(Settings.Metamodell,'GPR')
    fitfunc = @fitGPR;
    evalfunc =  @predictGPR;
    updatefunc = @updateGPR;
    updateWOHOfunc = @updateWOHOGPR;
elseif strcmp(Settings.Metamodell,'GPRknownMeasNoise')
    fitfunc = @fitGPRKnownMeasNoise;
    evalfunc =  @predictGPRKnownMeasNoise;
else
    error('unknown metamodel')
end

if ~State.refuseRefit  &&  (~isfield(State.MM,'Models') || State.enforceRefit)
    %There are no old models in existence create new models
        
    for i = 1:length(Y)
        if iscell(Settings.MetamodellSettings)
            currMMSettings = Settings.MetamodellSettings{i};
        else
            currMMSettings = Settings.MetamodellSettings;
        end
        currMMSettings = scaleLengthScaleBounds(currMMSettings,State.MM.Scaling,X,i);
        MSE = inf;
        counter = 0;
        while MSE > Settings.maxIntError
            counter = counter +1;
            if counter > 5
                Y{i} = Y{i} + rand(size(Y{i}))-0.5;
                %currMMSettings.boundLengthScale = [-inf inf];
                Settings.maxIntError= inf;
            end
            if State.useVirtualSigmaYData
                State.MM.Models{i} = fitfunc(X(uniqueYidns{i},:),Y{i},Y_Sigma{i},currMMSettings);
            else
                State.MM.Models{i} = fitfunc(X(uniqueYidns{i},:),Y{i},currMMSettings);
            end
            try
                [w,~] = gp_pak(State.MM.Models{i}.gp);
            catch
                w = [];
            end
            try
                [Mean,Var] = evalfunc(X(uniqueYidns{i},:),currMMSettings,State.MM.Models{i});
                MSE = sum((Mean-Y{i}).^2)/length(Mean);
                if MSE> Settings.maxIntError
                    try
                        State.MM.unSucParams{i} = [State.MM.unSucParams{i};w];
                    catch
                        State.MM.unSucParams{i} = [w];
                    end
                else
                    try
                        State.MM.SucParams{i} = [State.MM.SucParams{i};w];
                    catch
                        State.MM.SucParams{i} = [w];
                    end
                end
             
            catch
                Mean = Y(:,i);
            end
        end
    
        
    end
    State.LastHyperParamOpt = State.currIter;
else
    %Check wether hyper parameter optimisation needs to be performed
    if  ~State.refuseRefit  && (State.totalNumberOfEvals - Stats.sucEvals(State.LastHyperParamOpt)  >=  Settings.reOptimizingFrequency)
        %Perform hyper Prameter Optimisation
        for i = 1:length(Y)
            
            if iscell(Settings.MetamodellSettings)
                currMMSettings = Settings.MetamodellSettings{i};
            else
                currMMSettings = Settings.MetamodellSettings;
            end
            currMMSettings = scaleLengthScaleBounds(currMMSettings,State.MM.Scaling,X,i);
            
            
            
            try
                State.MM.PrevModels{i} = State.MM.Models{i};
            catch
            end
            if State.useVirtualSigmaYData
                returnedModel = fitfunc(X(uniqueYidns{i},:),Y{i},Y_Sigma{i},currMMSettings);
            else
                returnedModel = fitfunc(X(uniqueYidns{i},:),Y{i},currMMSettings);%updatefunc(X,Y(:,i),currMMSettings,State.MM.Models{i});
            end
            if isempty(returnedModel)
                State.MM.Models{i} = fitfunc(X(uniqueYidns{i},:),Y{i},currMMSettings);
            else
                State.MM.Models{i} = returnedModel;
            end
            
            
            try
                [Mean,Var] = evalfunc(X(uniqueYidns{i},:),currMMSettings,State.MM.Models{i});
            catch
                Mean = Y{i};
            end
            
        end
        State.LastHyperParamOpt = State.currIter;
    else
        for i = 1:length(Y)
                 
            if iscell(Settings.MetamodellSettings)
                currMMSettings = Settings.MetamodellSettings{i};
            else
                currMMSettings = Settings.MetamodellSettings;
            end
            currMMSettings = scaleLengthScaleBounds(currMMSettings,State.MM.Scaling,X,i);
            
            try
                State.MM.PrevModels{i} = State.MM.Models{i};
            catch
            end
            State.MM.Models{i} = updateWOHOfunc(X(uniqueYidns{i},:),Y{i},currMMSettings,State.MM.Models{i});
            try
                [Mean,Var] = evalfunc(X(uniqueYidns{i},:),currMMSettings,State.MM.Models{i});
            catch
                Mean = Y{i};
            end
            %             if any(abs(Y(:,i) - Mean) > 0.01)
            %                 figure
            %                 plot(Mean,Y(:,i),'*')
            %                 warning('Something went wrong. The metamodel is performing very poorly on the test data.')
            %             end
            
        end
    end
    
end



% Decide wether hyperparameters are fitted or not.



State.BuildMMtime = etime(clock,c1);
end

function currMMSettings = scaleLengthScaleBounds(currMMSettings,Scaling,X,i)
%Scale Length Scales
ScalingStdX = Scaling.StdX;
if isfield(currMMSettings,'fixedMean') && ~isnan(currMMSettings.fixedMean(i))
    currMMSettings.scaledFixedMean = (currMMSettings.fixedMean(i)-Scaling.MeanY(i))./Scaling.StdY(i);
end

if isfield(currMMSettings,'upperBoundOnNoiseUser')
    currMMSettings.scaledUpperBoundOnNoiseUser = currMMSettings.upperBoundOnNoiseUser/Scaling.StdY;
end

if isfield(currMMSettings,'boundLengthScale')
    %disp('user defined length scale bounds are ignored')
    upperBound = currMMSettings.boundLengthScale(:,end);
else
    upperBound = inf*ones(1,size(X,2));
end

if isfield(currMMSettings,'upperBoundsOnLengthScaleUser')
    if iscell(currMMSettings.upperBoundsOnLengthScaleUser)
        tmpUB = currMMSettings.upperBoundsOnLengthScaleUser{i}; 
    else
        tmpUB = currMMSettings.upperBoundsOnLengthScaleUser;
    end
    if size(tmpUB,2) ~= size(X,2) && size(tmpUB,2) ~= 1
        error('Bounds on length scale have invalid entries')
    else
        if isfield(currMMSettings,'useIsoKernel') && currMMSettings.useIsoKernel
            scaledLs = tmpUB./mean(ScalingStdX);
            
            upperBound = min(upperBound,1/2*(log(-1/2*scaledLs^2/log(0.1))));
            error('not tested yet')
        else
            for i_Dim = 1:size(X,2)
                scaledLs(i_Dim) = tmpUB(i_Dim)./ScalingStdX(i_Dim);
                upperBound(i_Dim) = min([1/2*(log(-1/2*scaledLs(i_Dim)^2/log(0.1))),upperBound(i_Dim)]);
                % currMMSettings.boundLengthScale(i,:) = [ 1/2*(log(-1/2*scaledLs(i)^2/log(0.1))) ,upperBound(i)];
                %Settings.MetamodellSettings.boundLengthScale(i,:) = min(log(Settings.MetamodellSettings.lowerBoundsOnLengthScaleUser./State.MM.Scaling.StdX(i)),10);
            end
        end
        %end
    end
    if ~isfield(currMMSettings,'lowerBoundsOnLengthScaleUser')
        error('Not tested yet')
    end
end


if isfield(currMMSettings,'lowerBoundsOnLengthScaleUser')
    if size(currMMSettings.lowerBoundsOnLengthScaleUser,2) ~= size(X,2) && size(currMMSettings.lowerBoundsOnLengthScaleUser,2) ~= 1
        error('Bounds on length scale have invalid entries')
    else
        if isfield(currMMSettings,'useIsoKernel') && currMMSettings.useIsoKernel
            scaledLs = currMMSettings.lowerBoundsOnLengthScaleUser./mean(ScalingStdX);
            currMMSettings.boundLengthScale = [ 1/2*(log(-1/2*scaledLs^2/log(0.1))) ,upperBound(1)];
            error('not tested yet')
        else
            for i_Dim = 1:size(X,2)
                scaledLs(i_Dim) = currMMSettings.lowerBoundsOnLengthScaleUser(i_Dim)./ScalingStdX(i_Dim);
                currMMSettings.boundLengthScale(i_Dim,:) = [ 1/2*(log(-1/2*scaledLs(i_Dim)^2/log(0.1))) ,upperBound(i_Dim)];
                %Settings.MetamodellSettings.boundLengthScale(i,:) = min(log(Settings.MetamodellSettings.lowerBoundsOnLengthScaleUser./State.MM.Scaling.StdX(i)),10);
            end
        end
        %end
    end
end
end
