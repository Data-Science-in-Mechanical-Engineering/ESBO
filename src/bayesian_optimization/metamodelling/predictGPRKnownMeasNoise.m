function [Mean, Var,sn2,R,varPost] = predictGPRKnownMeasNoise(XTest,Settings,Model)

covFun = Model.covFun; 
constMean = 0;
y = Model.Y;
x = Model.X;
x_test = XTest;
hyp = Model.hyp;
hypOrig = Model.hyp;
sigma_2 = diag(Model.sigma_Y.^2);
for i = 1:size(y,2)
    hyp.cov =1/2*(hyp.cov + hypOrig.cov);
    while true
    
    kII = feval(covFun, hyp.cov, x);
    kTT = feval(covFun, hyp.cov, x_test);
    kTI = feval(covFun, hyp.cov, x_test,x);
    
    % Posterior covariance matrix
    %varPost    = kTT - kTI/(kII+sigma)*kTI' + exp(2*hyp.lik)*eye(size(xs,1));
    if rcond(kII+sigma_2) < 10^-15
        hyp.cov(1) = hyp.cov(1) - 0.01;  
    else
        break
    end
    end
    varPost  = kTT - kTI/(kII+sigma_2)*kTI';
    varPost = triu(varPost.',1) + tril(varPost);
    meanPost = constMean + kTI/(kII+sigma_2)*(y(:,i)-constMean);
    
    
    if nargout > 3 
        success = false;
        R = [];
        while ~success
            try
                R = [R; mvnrnd(meanPost,varPost,NoOfPostSamples)];
                success = true;
            catch
                varPost = varPost + 10^-6*eye(size(x_test,1));
            end
        end
    end
    
    Mean(:,i)   = meanPost;
    Var(:,i) = diag(varPost);
end
sn2 = Var*0;
Var(Var<0) = 0;
end

