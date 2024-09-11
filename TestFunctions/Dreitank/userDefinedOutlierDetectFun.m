function [OutlierBool] = userDefinedOutlierDetectFun(y,g,info)
%x(1): Decision Variable
%x(2): Kontext

OutlierBool = info.outlier;
% 
% y    = sin(x(:,1)).*x(:,1); %Objective function
% y(x(:,1) > 5) = 20;
% g    = [];                                 %Constraint
% info = [];                                 %user data


end


