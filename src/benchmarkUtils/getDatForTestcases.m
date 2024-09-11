function [tmpDatForPP] = getDatForTestcases(datForPP,testCaseinds)
% Calculate all relevant columns

relcolumns = [];
for i_case = testCaseinds
    relcolumns = [relcolumns  find(datForPP.testcaseMat(i_case,:))];
end
tmpDatForPP.testcaseMat = datForPP.testcaseMat(testCaseinds,relcolumns);
tmpDatForPP.randRef.median = datForPP.randRef.median(testCaseinds);
tmpDatForPP.overallMin = datForPP.overallMin(testCaseinds);

tmpDatForPP.signature           = datForPP.signature(relcolumns);
tmpDatForPP.res_Stats           = datForPP.res_Stats(:,relcolumns);
tmpDatForPP.res_State = datForPP.res_State(:,relcolumns);
tmpDatForPP.Settings = datForPP.Settings(:,relcolumns(relcolumns <= size(datForPP.Settings,2)));
tmpDatForPP.testcases = datForPP.testcases(testCaseinds);
tmpDatForPP.gridReference.yOpt  = datForPP.gridReference.yOpt(testCaseinds);

end