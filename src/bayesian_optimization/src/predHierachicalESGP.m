function [pred] = predHierachicalESGP(ind,Params,Model)


pred = [];

currModelInds = Model.PredModelInds{ind};

for i = 1:length(currModelInds)
    [Mean, Var] = evalMetaModels(Model.Models{currModelInds(i)}.State,Model.Settings,Params);
    pred = [pred;[Mean sqrt(Var)]];
end


end

