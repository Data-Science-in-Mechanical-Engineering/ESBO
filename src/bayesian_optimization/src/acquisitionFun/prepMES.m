function [infillKritfunc] = prepMES(State,Settings,Case)

% taken from paper https://arxiv.org/pdf/1703.01968.pdf

%% Create a probability distribution for y* (the optimum function value considering constraints.) 

% Get 2000 randomly selected points on which to evaluate the posterior
[XGrid,~] = randomSampling(Case,2000);

%XGrid = linspace(Case.lb,Case.ub,200)';

Settings.MetamodellSettings.returnLatentMean = true;
[meanVector,varVector,obsNoise] = evalMetaModels(State,Settings,XGrid);


%The following function is taken from the code of the paper and works for
%maximization: Therefore the inversion:

meanVector = -meanVector;   

%yy are the evaluated samples until now.
yy = -State.EvalSamples.Y;

sigma0 = obsNoise(1); %Observation noise is uniform Carefull this is the variance not the Standarddeviation

nK = 100; %10 Samples of the optimum are taken. In the paper 1, 10 and 100 were taken
sx = length(meanVector);
%MESGRID Summary of this function goes here
%   Detailed explanation goes here
% Avoid numerical errors by enforcing variance to be positive.
varVector(varVector<=sigma0+eps) = sigma0+eps;
% Obtain the posterior standard deviation.
sigVector = sqrt(varVector);
% Define the CDF of the function upper bound.
probf = @(m0) prod(normcdf((m0 - meanVector)./sigVector));
% Randomly sample the function upper bounds from a Gumbel distribution
% that approximates the CDF.

% Find the sample range [left, right].

% Use the fact that the function upper bound is greater than the max of
% the observations.
left = max(yy);
if probf(left) < 0.25
    right = max(meanVector+5*sigVector);
    while (probf(right) < 0.75)
        right = right + right - left;
    end
    mgrid = linspace(left, right, 100);
    
    prob = prod(normcdf((repmat(mgrid,[sx,1]) - repmat(meanVector ...
        ,[1,100]))./repmat(sigVector,[1, 100])),1);
    % Find the median and quartiles.
    med = find_between(0.5, probf, prob, mgrid, 0.01);
    q1 = find_between(0.25, probf, prob, mgrid, 0.01);
    q2 = find_between(0.75, probf, prob, mgrid, 0.01);
    % Approximate the Gumbel parameters alpha and beta.
    beta=(q1-q2)/(log(log(4/3)) - log(log(4)));
    alpha = med+beta*log(log(2));
    assert(beta > 0);
    % Sample from the Gumbel distribution.
    maxes = - log( -log(rand(1, nK)) ) .* beta + alpha;
    maxes(maxes < left + 5*sqrt(sigma0)) = left + 5*sqrt(sigma0);
else
    % In rare cases, the GP shows that with probability at least 0.25,
    % the function upper bound is smaller than the max of
    % the observations. We manually set the samples maxes to be
    maxes = left + 5*sqrt(sigma0);
end



evalMMFunc = @(x) evalMetaModels(State,Settings,x);

infillKritfunc = @(x) -MES(x,maxes,evalMMFunc);

infillKritfunc =@(x) infillKritfunc(x).*(1-State.pOutlierFun(x)).*(1-State.pFailedFun(x)); 
 
end

