function [tmpDatForPP] = getDatForOptimizers(datForPP,optIndsCol,optIndsRow)
% Calculate all relevant columns

relcolumns = [];
noOfOpt = size(datForPP.res_State,2)/length(datForPP.Cases);
for i_case = 1:length(datForPP.Cases)
    relcolumns = [relcolumns  (i_case-1)*noOfOpt+optIndsCol];
end
if nargin == 3
    relRows = optIndsRow;
else
    relRows = [1:1:size(datForPP.res_State,1)];
end

tmpDatForPP.testcaseMat = datForPP.testcaseMat(:,relcolumns);

tmpDatForPP.signature           = datForPP.signature(relcolumns);
tmpDatForPP.res_Stats           = datForPP.res_Stats(relRows,relcolumns);
tmpDatForPP.res_State = datForPP.res_State(relRows,relcolumns);
tmpDatForPP.Settings = datForPP.Settings(relRows,relcolumns(relcolumns <= size(datForPP.Settings,2)));
tmpDatForPP.BenchmarkSettings = datForPP.BenchmarkSettings;
tmpDatForPP.Cases = datForPP.Cases;
try
tmpDatForPP.gridReference.yOpt  = datForPP.gridReference.yOpt;
catch
end
try
tmpDatForPP.randRef.median = datForPP.randRef.median;
catch
end
try
tmpDatForPP.overallMin = datForPP.overallMin;
catch
end
end