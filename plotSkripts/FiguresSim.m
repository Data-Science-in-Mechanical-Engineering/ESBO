% ######################## Plot for experimental results! ################

DesiredFigWidth = 16.9/3*4;
DesiredFigHeight = 6.5+0.02; % [cm]


NewPaperSize = [ DesiredFigWidth  DesiredFigHeight];
summaryFig = figure;

summaryFig.Units = 'centimeters'; % set figure position to cm

% h.Position([1:2]) = [h.Position(1)-10, h.Position(2)-8.5]; % set figure position before resize
summaryFig.Position([3:4]) = NewPaperSize; % resize figure (length x width)
summaryFig.PaperSize = NewPaperSize;
summaryFig.OuterPosition;

movegui(summaryFig,'center')


hMarginLeft = 0.025;
hMarginRight = 0.02;
hOffset = 0.045;

N_Subplots_horizontal = 4;
N_Subplots_vertical = 1;
vMarginTop = 0.20;
vMarginBottom = 0.1+ 0.02;
vOffset = 0.1;

width = (1 - (hMarginLeft + hMarginRight + hOffset*(N_Subplots_horizontal-1)))/N_Subplots_horizontal;
height = (1 - (vMarginTop + vMarginBottom + vOffset*(N_Subplots_vertical-1)))/N_Subplots_vertical;

Xpos = hMarginLeft;
Ypos = vMarginBottom;

if (N_Subplots_horizontal > 1)
    for i=2:N_Subplots_horizontal
        Xpos(i) = Xpos(i-1)+hOffset+width;
    end
end

if (N_Subplots_vertical > 1)
    for i=2:N_Subplots_vertical
        Ypos(i) = Ypos(i-1)+vOffset+height;
    end
end

Ypos = fliplr(Ypos);

testCaseRes = SimResESLSWOTrun;
optimizerSignature = testCaseRes.optimizerSignature;

plotNumber = [1, 1]; % [Zeile, Spalte]

s1 = subplot(1,4,1);
s1.OuterPosition = [Xpos(plotNumber(2)) Ypos(plotNumber(1)) width height];
s1.Position(3) = width-(s1.Position(1) - s1.OuterPosition(1));
s1.Position(4) = height-(s1.Position(2) - s1.OuterPosition(2));

for i_optimizer = 1:length(SimResESLSWOTrun.optimizerSignature)
      plot([1:1:300],testCaseRes.OverallAvgRank(i_optimizer,:) , ppSettings.maps.symbol(optimizerSignature{i_optimizer}),'LineWidth',1.5,'Color',ppSettings.maps.color(optimizerSignature{i_optimizer}),'DisplayName',ppSettings.maps.dispName(optimizerSignature{i_optimizer}),'MarkerIndices',1:10:100);
    hold all
end


xlabel('Simulation Time / %')
xticks([0 25 50 75 100]*3)
xticklabels({'0','25','50','75','100'});
ylabel('Average Rank')

plotNumber = [1, 2]; % [Zeile, Spalte]

s25 = subplot(1,4,2);
s25.OuterPosition = [Xpos(plotNumber(2)) Ypos(plotNumber(1)) width height];
s25.Position(3) = width-(s25.Position(1) - s25.OuterPosition(1));
s25.Position(4) = height-(s25.Position(2) - s25.OuterPosition(2));

for i_optimizer = 1:length(SimResESLSWOTrun.optimizerSignature)
    plot([1:1:300],log10(testCaseRes.OverallAvgScaledGap(i_optimizer,:)) ,ppSettings.maps.symbol(optimizerSignature{i_optimizer}),'LineWidth',1.5,'Color',ppSettings.maps.color(optimizerSignature{i_optimizer}),'DisplayName',ppSettings.maps.dispName(optimizerSignature{i_optimizer}),'MarkerIndices',1:30:300);
    hold all
end

xlabel('Simulation Time / %')
xticks([0 25 50 75 100]*3)
xticklabels({'0','25','50','75','100'});
ylabel('log10 Median Scaled Regret')

ylim(([-0.6 1.5]))
    

lgd = legend('location','northoutside','FontSize',8,'Box','Off');
lgd.NumColumns = 5;

testCaseRes = SimResLSWOTrun;
optimizerSignature = testCaseRes.optimizerSignature;


plotNumber = [1, 3]; % [Zeile, Spalte]
s2 = subplot(1,4,3);
s2.OuterPosition = [Xpos(plotNumber(2)) Ypos(plotNumber(1)) width height];
s2.Position(3) = width-(s2.Position(1) - s2.OuterPosition(1));
s2.Position(4) = height-(s2.Position(2) - s2.OuterPosition(2));
for i_optimizer = 1:length(SimResESLSWOTrun.optimizerSignature)
      plot([1:1:300],testCaseRes.OverallAvgRank(i_optimizer,:) , ppSettings.maps.symbol(optimizerSignature{i_optimizer}),'LineWidth',1.5,'Color',ppSettings.maps.color(optimizerSignature{i_optimizer}),'DisplayName',ppSettings.maps.dispName(optimizerSignature{i_optimizer}),'MarkerIndices',1:30:300);
    hold all
end
xlabel('Simulation Episodes')
xticks([0 33.33 66.67 100])
xlim([0,100])
xticklabels({'0','5d','10d','15d'});
ylabel('Average Rank')


plotNumber = [1, 4];
figure(summaryFig)
s3 = subplot(1,4,4);
s3.OuterPosition = [Xpos(plotNumber(2)) Ypos(plotNumber(1)) width height];
s3.Position(3) = width-(s3.Position(1) - s3.OuterPosition(1));
s3.Position(4) = height-(s3.Position(2) - s3.OuterPosition(2));
for i_optimizer = 1:length(SimResESLSWOTrun.optimizerSignature)
    plot([1:1:300],log10(testCaseRes.OverallAvgScaledGap(i_optimizer,:)) ,ppSettings.maps.symbol(optimizerSignature{i_optimizer}),'LineWidth',1.5,'Color',ppSettings.maps.color(optimizerSignature{i_optimizer}),'DisplayName',ppSettings.maps.dispName(optimizerSignature{i_optimizer}),'MarkerIndices',1:10:300);
    hold all
end

xlabel('Simulation Episodes')
xticks([0 33.33 66.67 100])
xlim([0,100])
xticklabels({'0','5d','10d','15d'});
ylabel('log10 Median Scaled Regret')
ylim(([-0.7 1.5]))

set(findall(summaryFig,'-property','FontSize'),'FontSize',8); % change font size
set(findall(summaryFig,'-property','TickDir'),'TickDir','out');
%set(findall(summaryFig,'-property','XMinorTick'),'XMinorTick','off');
%set(findall(summaryFig,'-property','YMinorTick'),'YMinorTick','off');
set(findall(summaryFig,'-property','XGrid'),'XGrid','on');
set(findall(summaryFig,'-property','YGrid'),'YGrid','on');
set(findall(summaryFig,'-property','LineWidth'),'Linewidth',1.2);