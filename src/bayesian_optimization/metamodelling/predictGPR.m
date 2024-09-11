function [Mean, Var,sn2,R,varPost] = predictGPR(XTest,Settings,Model)

if ~isfield(Model,'post')
    [Mean, Var,fMean,fVar] = gp(Model.hyp, Model.Settings.inf, Model.Settings.mean, Model.Settings.cov, Model.Settings.lik, Model.X, Model.Y, XTest);
    %Model.post = post;
else
    [Mean, Var,fMean,fVar] = gp(Model.hyp, Model.Settings.inf, Model.Settings.mean, Model.Settings.cov, Model.Settings.lik, Model.X, Model.post, XTest);
    
    %     if ~Settings.noisyObservations
%         for i = 1:size(XTest,1)
%             equalInd = find(all(XTest(i,:) == Model.X,2));
%             if ~isempty(equalInd)
%                 Mean(i) = Model.Y(equalInd);
%                 Var(i)  = 10^-10;
%             end
%         end
%     end
end
if nargout >= 3
    sn2 = ones(size(Var))*exp(2*Model.hyp.lik);
end
%%Sample form posterior
if nargout == 4 || nargout == 5
    if iscell(Model.Settings.cov) && length(Model.Settings.cov) == 2
        kTT = feval(Model.Settings.cov{1},Model.Settings.cov{2}, Model.hyp.cov, XTest);
        kTI = feval(Model.Settings.cov{1},Model.Settings.cov{2}, Model.hyp.cov, XTest,Model.X);
        kII = feval(Model.Settings.cov{1},Model.Settings.cov{2}, Model.hyp.cov, Model.X);
    else
        kTT = feval(Model.Settings.cov{1}, Model.hyp.cov, XTest);
        kTI = feval(Model.Settings.cov{1}, Model.hyp.cov, XTest,Model.X);
        kII = feval(Model.Settings.cov{1}, Model.hyp.cov, Model.X);
    end
    sigma = exp(2*Model.hyp.lik)*eye(size(Model.X,1));
    
    % Posterior covariance matrix
    %varPost    = kTT - kTI/(kII+sigma)*kTI' + exp(2*hyp.lik)*eye(size(xs,1));
    varPost = kTT - kTI/(kII+sigma)*kTI';
    
    varPost = triu(varPost.',1) + tril(varPost);
    success = false;
    while ~success
    try
        if ~isfield(Settings,'NoOfPostSamples')
            Settings.NoOfPostSamples = 1;
        end
        R = mvnrnd(Mean,varPost,Settings.NoOfPostSamples);
        success = true;
    catch
        varPost = varPost + 10^-6*eye(size(XTest,1));
    end
        
    end
end
if isfield(Settings,'returnLatentMean') && Settings.returnLatentMean
    Mean = fMean;
    Var  = fVar;
end
%Rlat = mvnrnd(Mean,varlat,NoOfSamples); 
end