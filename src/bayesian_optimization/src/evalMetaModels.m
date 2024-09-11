function [Mean,Var,PredNoiseVar,PostSamples,PostCov] = evalMetaModels(State,Settings,X)
c1 = clock;

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


for i = 1: size(X,2)
    X(:,i) = (X(:,i) - State.MM.Scaling.MeanX(i))/State.MM.Scaling.StdX(i);
end

for i = 1: length(State.MM.Models)
        if iscell(Settings.MetamodellSettings)
            currMMSettings = Settings.MetamodellSettings{i};
        else
            currMMSettings = Settings.MetamodellSettings;
        end
    %    try
    if nargout == 3 
        [TempMean, TempVar,TempPredNoiseVar] = evalfunc(X,currMMSettings,State.MM.Models{i});
        PredNoiseVar(:,i) = TempPredNoiseVar*State.MM.Scaling.StdY(i)^2;
    elseif nargout == 4 || nargout == 5
        [TempMean, TempVar,TempPredNoiseVar,TempPostSamples,TempPostCoVar] = evalfunc(X,currMMSettings,State.MM.Models{i});
        PredNoiseVar(:,i) = TempPredNoiseVar*State.MM.Scaling.StdY(i)^2;
        PostSamples{i} = TempPostSamples*State.MM.Scaling.StdY(i) + State.MM.Scaling.MeanY(i);
    if nargout == 5
        PostCov{i} = TempPostCoVar*State.MM.Scaling.StdY(i)^2;
    end
    else
        [TempMean, TempVar] = evalfunc(X,currMMSettings,State.MM.Models{i});
        
    end

    
    Mean(:,i) = TempMean*State.MM.Scaling.StdY(i) + State.MM.Scaling.MeanY(i);
    Var(:,i) = TempVar*State.MM.Scaling.StdY(i)^2;
    
    
end
State.EvalMMtime = etime(clock,c1);
end

