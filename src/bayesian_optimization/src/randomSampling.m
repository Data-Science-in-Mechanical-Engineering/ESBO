function [X,Case] = randomSampling(Case,NumberOfSamples)

rng('shuffle')

if isfield(Case,'IntegerFlag')
    if isfield(Case,'StepSize')
        Case.DiscreteParamSpace = genDiscreteParamSpace(Case.lb,Case.ub,Case.IntegerFlag,Case.StepSize);
        Case.RefinementLevel = ones(size(Case.DiscreteParamSpace,1),1);
        randInds = ceil(rand(1,NumberOfSamples) * size(Case.DiscreteParamSpace,1));
        X = Case.DiscreteParamSpace(randInds,:);
    else
        X = repmat(Case.lb,NumberOfSamples,1);
        notAllPointsFeasible = true;
        feasVect = zeros(NumberOfSamples,1);
        while notAllPointsFeasible
            notFeasInds = find(~feasVect);
            X(notFeasInds,:) = repmat(Case.lb,length(notFeasInds),1);
            for i = 1:size(X,2)
                X(notFeasInds,i) = X(notFeasInds,i) + rand(length(notFeasInds),1)*(Case.ub(i)-Case.lb(i));
            end
            X(:,Case.IntegerFlag) = round(X(:,Case.IntegerFlag));
            if ~isfield(Case,'nonLinCon')
                notAllPointsFeasible = false;
            else
                for i = 1:size(X,1)
                    feasVect(i) = all(Case.nonLinCon(X(i,:))<= 0);
                end
                disp(sum(feasVect))
                notAllPointsFeasible = ~all(feasVect);
            end
        end
    end
else
    X = repmat(Case.lb,NumberOfSamples,1);
    for i = 1:size(X,2)
        X(:,i) = X(:,i) + rand(NumberOfSamples,1)*(Case.ub(i)-Case.lb(i));
    end
    
end







end

