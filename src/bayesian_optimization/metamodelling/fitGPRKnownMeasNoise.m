function [Model] = fitGPRKnownMeasNoise(X,Y,sigma_Y,Settings)
if nargin == 3
    Settings = sigma_Y;
    sigma_Y = Y*0 + 10^-8;
end
nVars = size(X,2);

%PREDGPRKNOWNMEASNOISE Summary of this function goes here
%   Detailed explanation goes here
constMean = mean(mean(Y));
covFun    = 'covSEard';
if Settings.useGradientBasedOptimization
    NoRandHyps = Settings.lengthRandSearch;
else
    NoRandHyps = 1000;
end

knownNoiseInds = true(size(Y,1),1); %indices of data that have known measurent noise

%if Settings.noisyObservations
knownNoiseInds(isnan(sigma_Y)) = false;
%end

sigma_2 = sigma_Y.^2;
if Settings.useGradientBasedOptimization
    hypBounds = [repmat([-4 1],nVars,1); -1 1];
else
    hypBounds = [repmat([-5 0],nVars,1); -3 3];
end


if Settings.noisyObservations
    hypBounds = [hypBounds;[-4.3429  3]];
else
    hypBounds = [hypBounds;[-4.3429 -4.3429+0.001]]; %log10(exp(-10)) = -4.3429 this is the regularization, i also used with the GPML toolbox
end

%hyp.cov   = [1/2*(log(-1/2*0.25^2/log(0.1))),-1];

if isfield(Settings,'lowerBoundsOnLengthScaleUser')
    hypBounds(1:nVars,1) =  Settings.boundLengthScale(1:nVars,1);
end

if isfield(Settings,'upperBoundsOnLengthScaleUser')
    hypBounds(1:nVars,2) =  Settings.boundLengthScale(1:nVars,2);
end

if isfield(Settings,'scaledUpperBoundOnNoiseUser')
    hypBounds(end,2) =  max(log10(Settings.scaledUpperBoundOnNoiseUser),-4.3429+0.001);

end


for i = 1:size(hypBounds,1)
    hypCandidates(:,i) = rand(NoRandHyps,1)*(hypBounds(i,2) - hypBounds(i,1)) +  hypBounds(i,1);
end
%hypCandidates(:,i+1) = rand(NoRandHyps,1)*(hypBounds(i+1,2) - hypBounds(i+1,1)) +  hypBounds(i+1,1);

tic
for i = 1:NoRandHyps
    %hyp.cov = hypCandidates(i,:);
    loglik(i) = logLikObj(hypCandidates(i,:),X,covFun,sigma_2,Y,knownNoiseInds);
    %     kII = feval(covFun, hyp.cov, X);
    %     if rcond(kII+sigma_2) < 10^-15
    %         loglik(i) = -inf;
    %     else
    %         loglik(i) = -1/2*Y'/(kII+sigma_2)*Y -1/2*log(det(kII+sigma_2));
    %     end
    %     loglik(i)
end
toc
if all(loglik < -10^200)
    disp('Hyperparameter tuning failed!')
end
[~,maxInd] = min(loglik);

if Settings.useGradientBasedOptimization

    objFun =@(params) logLikObj(params,X,covFun,sigma_2,Y,knownNoiseInds);

    if isfield(Settings,'boundLengthScale')
        if ~Settings.noisyObservations
            objFun =@(params) logLikObj([params hypBounds(end,1)],X,covFun,sigma_2,Y,knownNoiseInds);
            try
                [hypOptimized] = fmincon(objFun,hypCandidates(maxInd,1:end-1),[],[],[],[],hypBounds(1:end-1,1),hypBounds(1:end-1,2));%fminsearch(objFun,hypCandidates(maxInd,1:end-1));
                hypOptimized = [hypOptimized hypBounds(end,1)];
            catch
                hypOptimized = [hypCandidates(maxInd,:)];
                warning('Gradient-based Hyperparameter optimization failed')
            end
        else
            try
                [hypOptimized] = fmincon(objFun,hypCandidates(maxInd,:),[],[],[],[],hypBounds(:,1),hypBounds(:,2));
            catch
                hypOptimized = hypCandidates(maxInd,:);
                warning('Gradient-based Hyperparameter optimization failed')
            end
        end
    else
        if ~Settings.noisyObservations
            %             lb = hypBounds(:,1);
            %             lb(1:end-1,1) =  -inf;
            %             ub = hypBounds(:,2);
            %             ub(1:end-1,1) =  inf;
            %             [hypOptimized] = fmincon(objFun,hypCandidates(maxInd,:),[],[],[],[],lb,ub);
            objFun =@(params) logLikObj([params hypBounds(end,1)],X,covFun,sigma_2,Y,knownNoiseInds);
            [hypOptimized] = fminsearch(objFun,hypCandidates(maxInd,1:end-1));
            hypOptimized = [hypOptimized hypBounds(end,1)];
        else
            [hypOptimized] = fminsearch(objFun,hypCandidates(maxInd,:));
        end
    end
    disp('Before Hyperparameter Optimization:')
    hypCandidates(maxInd,:)
    disp('After Hyperparameter Optimization:')
    hypOptimized
    hyp.cov = hypOptimized(1:end-1);
    hyp.lik = hypOptimized(end);
else
    hyp.cov = hypCandidates(maxInd,1:end-1);
    hyp.lik = hypCandidates(maxInd,end);
    disp(hypCandidates(maxInd,:))
end






Model.X = X;
Model.Y = Y;
Model.hyp = hyp;
Model.Settings = Settings;
Model.lik = max(loglik);
Model.sigma_Y = sigma_Y;
Model.sigma_Y(~knownNoiseInds) = 10^hyp.lik;
Model.covFun = covFun;
end


function [loglik] = logLikObj(params,X,covFun,sigma_2,Y,knownNoiseInds)
hyp.cov = params(1:end-1);
sigma_2(~knownNoiseInds) = (10^params(end)).^2;
[loglik] = getLogLik(hyp,X,covFun,diag(sigma_2),Y);
loglik = -loglik;
end



function [loglik] = getLogLik(hyp,X,covFun,sigma_2,Y)

kII = feval(covFun, hyp.cov, X);
if rcond(kII+sigma_2) < 10^-15
    loglik = -inf;
else
    loglik = -1/2*Y'/(kII+sigma_2)*Y -1/2*log(det(kII+sigma_2));
    if isinf(loglik)
        loglik = -inf;
    end
end

if ~isreal(loglik)
    loglik = -inf;
end

end

