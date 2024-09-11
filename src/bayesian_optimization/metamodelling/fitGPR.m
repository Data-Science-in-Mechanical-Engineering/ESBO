function Model = fitGPR(X,Y,Settings)
%addpath('..\..\gpml-matlab-v4.1-2017-10-19')
%startup
%Settings.cov = {'covSum', {'covSEard','covNoise
%Settings.cov = {'covSEard'};'}};
if all(Y == 0)
    Y = Y + rand(size(Y))*0.01;
end

if isfield(Settings,'useIsoKernel')
    if Settings.useIsoKernel
        Settings.cov = {'covSEiso'};
    else
        Settings.cov = {'covSEard'};
    end
else
    Settings.cov = {'covSEard'};
end

if isfield(Settings,'useMatern52Kernel')
    if Settings.useMatern52Kernel
        Settings.cov = {@covMaternard ,5};
    else
        Settings.cov = {'covSEard'};
    end
else
    Settings.cov = {'covSEard'};
end


if isfield(Settings,'useZeroMean')
    if Settings.useZeroMean
        Settings.mean = @meanZero;
    else
        Settings.mean = @meanConst;
    end
elseif isfield(Settings,'useLinMean')
    if Settings.useLinMean
        Settings.mean = @meanLinear;
    else
        Settings.mean = @meanConst;
    end
elseif isfield(Settings,'useQuadMean')
    if Settings.useQuadMean
        mc = {@meanConst};
        mq = {@meanPoly,2};
        Settings.mean  = {'meanSum',{mc,mq}};
    else
        Settings.mean = @meanConst;
    end
else
    Settings.useQuadMean = false;
    Settings.mean = @meanConst;
end


if isfield(Settings,'useStudentTLik') && Settings.useStudentTLik
    Settings.lik = @likT;
    Settings.inf = @infLaplace;
else
    Settings.lik = @likGauss;
    Settings.inf = @infExact;
end
bounds.default = [-4 1];
if isfield(Settings,'boundLengthScale')
    %Default upper bound on the unit cube with k_krit = 0.1 and dkrit =
    %see also (testUserDefinedLength)
    Settings.boundLengthScale(:,2) = min(Settings.boundLengthScale(:,2),1/2*(log(-1/2*1^2/log(0.9))));
    %Settings.boundLengthScale(:,2) = min(Settings.boundLengthScale(:,2),1/2*(log(-1/2*1^2/log(0.1))));
    %Settings.boundLengthScale(:,2) = min(Settings.boundLengthScale(:,2),1);
    Settings.boundLengthScale(Settings.boundLengthScale(:,1) >= Settings.boundLengthScale(:,2),2) = inf;
end

if isfield(Settings,'scaledFixedMean')
    bounds.mean = [Settings.scaledFixedMean Settings.scaledFixedMean];
    Settings.mean = @meanConst;
    pc = {@priorClamped};
    prior.mean = pc;
end


if ~Settings.noisyObservations
    bounds.lik = [-10 -10];
    pc = {@priorClamped};
    prior.lik = pc;
    
end
%     Settings.cov = {'covSum', {'covSEard','covNoise'}};

if isfield(Settings,'useGammaPrior') && Settings.useGammaPrior
    if isfield(Settings,'boundLengthScale')
        warning ('Bounds on Length scales are not used with gamma prior')
    end
    if ~Settings.useIsoKernel
        for i = 1:size(X,2)
            %pgamma   = {@priorGamma,2,1/16};
            pgamma   = {@priorGamma,1,1/8};
            pgammatr = {@priorTransform,@exp,@exp,@log,pgamma};
            bounds.cov(i,:) = [-10,1];
            prior.cov{i,1} = pgammatr ;
        end
    else
        i =1;
        %pgamma   = {@priorGamma,3,1/16};
        pgamma   = {@priorGamma,1,1/8};
        pgammatr = {@priorTransform,@exp,@exp,@log,pgamma};
        bounds.cov(i,:) = [-10,1];
        prior.cov{i,1} = pgammatr ;
    end
    
    bounds.cov(i+1,:) = bounds.default;
    prior.cov{i+1,1} = [];
elseif isfield(Settings,'boundLengthScale')
    for i = 1: size(Settings.boundLengthScale,1)
        pl_tr  = {@priorSmoothBox2,exp(Settings.boundLengthScale(i,1)),exp(Settings.boundLengthScale(i,2)),150000};
        pl = {@priorTransform,@exp,@exp,@log,pl_tr};
        bounds.cov(i,:) = [Settings.boundLengthScale(i,1),Settings.boundLengthScale(i,2)];
        prior.cov{i,1} = pl;
        %hyp.cov(i) = max(min(Settings.boundLengthScale(i,2),hyp.cov(i)),Settings.boundLengthScale(i,1));
    end
    bounds.cov(i+1,:) = bounds.default;
    prior.cov{i+1,1} = [];
end









try
    Settings.inf = {@infPrior,Settings.inf,prior};
catch
end


% Set initial bounds on the quadratic trend funtion


% if ~isfield(Settings,'boundLengthScale')
%     bounds=[-4,0];
% else
%     bounds=[Settings.boundLengthScale(1,1), 0];
% end
%hyp.lik = -10; %hyp = log sn

%bounds = [bounds.cov];

%hyp = gp_initial(bounds,Settings.inf, Settings.mean, Settings.cov , Settings.lik, X, Y,1,Settings.lengthRandSearch);

[hypOld] = randomHyperParamSearch(X,Y,Settings,bounds,Settings.lengthRandSearch);

% hypTemp.cov  = [-1.1507, -0.7636, -0.9919, -0.6452];
% hypTemp.lik  = [-0.0736];
% hypTemp.mean = [];


%[hypOld] = randomHyperParamSearch(X,Y,Settings,bounds,2000);


likOld = gp(hypOld,Settings.inf, Settings.mean, Settings.cov, Settings.lik, X, Y);
counter = 50;
while true
    [hyp, ~] = minimize(hypOld , @gp, -100, Settings.inf, Settings.mean, Settings.cov, Settings.lik, X, Y);
    liknew = gp(hyp,Settings.inf, Settings.mean, Settings.cov, Settings.lik, X, Y);
    liknew = liknew(end);
    if abs(likOld-liknew) < abs(likOld*Settings.relChangeStopCrit)
        break
    elseif (isinf(liknew)||liknew > likOld )&& ~isinf(likOld)
        hyp = hypOld;
        break;
    else
        likOld = liknew;
    end
    counter = counter -1;
    if counter == 0
        Model = [];
        disp('Hyper parameter tuning failed!')
        %Hyper oarameter tuning failed
        return;
    end
    hyp = hypOld;
end

disp(hyp.cov)
try
    disp(Settings.boundLengthScale)
catch
end
[~,~,Model.post] = gp(hyp,Settings.inf, Settings.mean, Settings.cov, Settings.lik, X, Y);
Model.X = X;
Model.Y = Y;
Model.hyp = hyp;
Model.Settings = Settings;
Model.lik = liknew;
end
