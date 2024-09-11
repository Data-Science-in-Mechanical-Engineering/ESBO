function [X,State] = resSurfRS(Case,State,infillKritfunc,Settings)


if isfield(Case,'isContext') && any(Case.isContext)
    Case.lb(Case.isContext) = State.currContext;
    Case.ub(Case.isContext) = State.currContext;
end
c1 = clock;

try
    NoOfPoints = Settings.SurrogateOptimizerRSNoOfSamples;
catch
    error('Number of points in Random search is not set correctly.')
end

tic
candidateX = repmat(Case.lb,NoOfPoints,1);
feasible = false(size(candidateX,1),1);
while sum(feasible)/NoOfPoints < 0.2
    candidateXtemp = repmat(Case.lb,NoOfPoints,1) + rand(NoOfPoints,length(Case.lb)).*repmat(Case.ub - Case.lb,NoOfPoints,1);
    candidateX(~feasible,:) = candidateXtemp(~feasible,:);
    if isfield(Case,'nonLinCon')
        feasible = all(Case.nonLinCon(candidateX) <= 0,2);
    else
        feasible = true(size(candidateX,1),1);
    end
    
end
toc
InfillKritVect = zeros(size(candidateX,1),1);

tic
InfillKritVect(feasible) = infillKritfunc(candidateX(feasible,:));
toc

[fvalInitMin,minInd] = min(InfillKritVect);
if ~isnan(fvalInitMin)
    try
        InfillKritVect(minInd);
        xInit = candidateX(minInd,:);
        if isfield(Case,'nonLinCon')
            options = optimoptions('fmincon','Display','iter','MaxFunctionEvaluations',NoOfPoints/20);
            [X,fvalmin,exitflag,output] = fmincon(infillKritfunc,xInit,[],[],[],[],Case.lb,Case.ub,Case.nonLinCon,options);
        else
            options = optimoptions('fmincon','Display','iter','MaxFunctionEvaluations',NoOfPoints/20);
            [X,fvalmin,exitflag,output] = fmincon(infillKritfunc,xInit,[],[],[],[],Case.lb,Case.ub,[],options);
        end
        
        if isfield(Case,'nonLinCon') && ~all(Case.nonLinCon(X) <= 0,2)
            X = xInit;
        end
        if fvalmin > fvalInitMin
            State.EIMax = -fvalInitMin;
            X = xInit;
        else
            State.EIMax = -fvalmin;
        end
    catch
        warning('acquisition function evaluation failed - choosing the next point randomly')
        XFeas = candidateX(feasible,:);
        X = XFeas(ceil(rand(1,1)*length(XFeas)),:);
        State.EIMax = NaN;
    end
else
    warning('No non-Nan acquisiton function value was obtained - choosing the next point randomly')
    XFeas = candidateX(feasible,:);
    X = XFeas(ceil(rand(1,1)*length(XFeas)),:);
    State.EIMax = NaN;
end
State.FindCandidatetime = abs(etime(c1,clock));

end

