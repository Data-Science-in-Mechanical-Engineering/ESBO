function [hyp] = randomHyperParamSearch(X,Y,Settings,bounds,lengthRandSearch)
%RANDOMHYPERPARAMSEARCH Summary of this function goes here
%   Detailed explanation goes here
D = size(X,2);
% [ is_valid, hyp, inf, mean, cov, lik, msg ] = validate( [], Settings.inf, Settings.mean, Settings.cov, Settings.lik, D);

hyp_cov_count = eval(eval_func(Settings.cov)); % number of covariance hyperparameters
hyp_lik_count = eval(eval_func(Settings.lik)); % number of likelihood hyperparameters
hyp_mean_count = eval(eval_func(Settings.mean)); % number of mean hyperparameters

boundsVect = [];
if ~isfield(bounds,'cov')
    boundsVect = [boundsVect;repmat(bounds.default,hyp_cov_count,1)];
else
    boundsVect = [boundsVect;bounds.cov];
end

if ~isfield(Settings,'useQuadMean')
	Settings.useQuadMean = false;   
end


if ~isfield(bounds,'lik')
    boundsVect = [boundsVect;repmat(bounds.default,hyp_lik_count,1)];
else
    boundsVect = [boundsVect;bounds.lik];
end

if Settings.useQuadMean
    disp('Sampling Hyp. Bounds for quadratic mean!')
    zeroValBounds = [-3 3];
    oneValBounds  = [-3 3];
    halfValBounds = [-3 3];
    
    zeroYSamples = rand(lengthRandSearch,1)*(zeroValBounds(2) - zeroValBounds(1)) + zeroValBounds(1);
    oneYSamples   = rand(lengthRandSearch,D)*(oneValBounds(2) - oneValBounds(1)) + oneValBounds(1);
    halfYSamples  = rand(lengthRandSearch,D)*(halfValBounds(2) - halfValBounds(1)) + halfValBounds(1);
    for i = 1:lengthRandSearch
        a = 2*oneYSamples(i,:) -4* halfYSamples(i,:) + 2*zeroYSamples(i);
        b = -1*oneYSamples(i,:) +4* halfYSamples(i,:) - 3*zeroYSamples(i);
        c = zeroYSamples(i);
        
        meanHyp(i,:) = [zeroYSamples(i) b a];
        
    end
end
if ~isfield(bounds,'mean')
    boundsVect = [boundsVect;repmat(bounds.default,hyp_mean_count,1)];
else
    boundsVect = [boundsVect;bounds.mean];
end


hypParamVect = repmat(boundsVect(:,1)',lengthRandSearch,1) + rand(lengthRandSearch,size(boundsVect,1)).*repmat(boundsVect(:,2)'-boundsVect(:,1)',lengthRandSearch,1);

for i = 1:size(hypParamVect,1)
    hyp.cov = hypParamVect(i,1:hyp_cov_count);
    hyp.lik = hypParamVect(i,hyp_cov_count+1:hyp_cov_count+hyp_lik_count);
    if Settings.useQuadMean
        hyp.mean = meanHyp(i,:);
    else
        hyp.mean = hypParamVect(i,hyp_cov_count+hyp_lik_count+1:end);
    end
    lik(i) = gp(hyp,Settings.inf, Settings.mean, Settings.cov, Settings.lik, X, Y);
end

[~,minInd] = min(lik);
hyp.cov = hypParamVect(minInd,1:hyp_cov_count);
hyp.lik = hypParamVect(minInd,hyp_cov_count+1:hyp_cov_count+hyp_lik_count);
if Settings.useQuadMean
    hyp.mean = meanHyp(minInd,:);
else
    hyp.mean = hypParamVect(minInd,hyp_cov_count+hyp_lik_count+1:end);
end
end

