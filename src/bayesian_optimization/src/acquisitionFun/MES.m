function [MES] = MES(x,maxes,evalMMFunc)

%Taken from paper: https://arxiv.org/pdf/1703.01968.pdf

nK = length(maxes);
sx = size(x,1);

[meanVector,Yvar] = evalMMFunc(x); % Prediction of the latent function mean is enabled in the prep Function
meanVector = -meanVector;
sigVector = sqrt(Yvar);
gamma = (repmat(maxes,[sx 1]) - repmat(meanVector, [1, nK])) ...
        ./ repmat(sigVector, [1, nK]);
    pdfgamma = normpdf(gamma);
    cdfgamma = normcdf(gamma);
    MES = sum(gamma.*pdfgamma./(2*cdfgamma) - log(cdfgamma),2);

end