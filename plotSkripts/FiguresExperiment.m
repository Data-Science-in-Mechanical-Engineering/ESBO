% ######################## Plot for experimental results! ################

color = RWTHcolors();

DesiredFigWidth = 16.9/2/3*4;
DesiredFigHeight = 6.5/2*3; % [cm]
NewPaperSize = [ DesiredFigWidth  DesiredFigHeight];
experimentFig = figure;
experimentFig.Units = 'centimeters'; % set figure position to cm
% h.Position([1:2]) = [h.Position(1)-10, h.Position(2)-8.5]; % set figure position before resize
experimentFig.Position([3:4]) = NewPaperSize; % resize figure (length x width)
experimentFig.PaperSize = NewPaperSize;
experimentFig.OuterPosition;
movegui(experimentFig,'center')

hMarginLeft = -0.2;
hMarginRight = 0.05;
hOffset = 0.045;

N_Subplots_horizontal = 1;
N_Subplots_vertical = 2;
vMarginTop = 0.01;
vMarginBottom = 0.05;
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

plotNumber = [1, 1]; % [Zeile, Spalte]

s1 = subplot(2,1,1);
s1.OuterPosition = [Xpos(plotNumber(2)) Ypos(plotNumber(1)) width height];
s1.Position(3) = width-(s1.Position(1) - s1.OuterPosition(1));
s1.Position(4) = height-(s1.Position(2) - s1.OuterPosition(2));

for i_optimizer = 1:1:4
    optimizerSignature = ExperimentResES.optimizerSignature ;

end

for i_optimizer = 1:1:4
    try
     pltY = (ExperimentResES.MedianPerAlgo{1}(i_optimizer,:)-ExperimentResES.overallMin)/(ExperimentResES.randRef.median - ExperimentResES.overallMin);
   
        p(i_optimizer) = stairs(linspace(476/60,30*476/60,100)*0.2,pltY ,ppSettings.maps.symbol(optimizerSignature{i_optimizer}),'LineWidth',1.5,'Color',ppSettings.maps.color(optimizerSignature{i_optimizer}),'DisplayName',ppSettings.maps.dispName(optimizerSignature{i_optimizer}));
    hold all
    catch
    end
end
legend(p,'location','northeast')
ylim([-0.5 1.1])
ylim([0 15])
xlim([0, 30*476/60*0.2])
%xlabel([0 [1:1:100]/30*476/60])
xlabel('Experimentation time / min')
ylabel('Median Scaled Regret')



plotNumber = [2, 1]; % [Zeile, Spalte]

s2 = subplot(2,1,2);
s2.OuterPosition = [Xpos(plotNumber(2)) Ypos(plotNumber(1)) width height];
s2.Position(3) = width-(s2.Position(1) - s2.OuterPosition(1));
s2.Position(4) = height-(s2.Position(2) - s2.OuterPosition(2));

for i_optimizer = 1:1:4
    optimizerSignature = ExperimentRes.optimizerSignature ;
    
end

for i_optimizer = 1:1:4
    try
    %pltY = log10((ExperimentRes.MedianPerAlgo{1}(i_optimizer,:)-ExperimentRes.overallMin)/(ExperimentRes.randRef.median - ExperimentRes.overallMin));
    pltY = (ExperimentRes.MedianPerAlgo{1}(i_optimizer,:)-ExperimentRes.overallMin)/(ExperimentRes.randRef.median - ExperimentRes.overallMin);
   
        p(i_optimizer) = stairs(pltY ,ppSettings.maps.symbol(optimizerSignature{i_optimizer}),'LineWidth',1.5,'Color',ppSettings.maps.color(optimizerSignature{i_optimizer}),'DisplayName',ppSettings.maps.dispName(optimizerSignature{i_optimizer}));
    hold all
catch
    end
end
%legend(p)
ylim([-0.5 1.1])
ylim([0 15])
xlim([0 30])
xlabel('Experimental Episodes')
ylabel('Median Scaled Regret')
%xticks([0 20 40 60 80 100])
%xticklabels({'0','20%','40%','60%','80%','100%'});
%ylabel('$J^*$')
set(findall(experimentFig,'-property','FontSize'),'FontSize',8); % change font size
set(findall(experimentFig,'-property','TickDir'),'TickDir','out');
%set(findall(experimentFig,'-property','XMinorTick'),'XMinorTick','off');
%set(findall(experimentFig,'-property','YMinorTick'),'YMinorTick','off');
set(findall(experimentFig,'-property','XGrid'),'XGrid','on');
set(findall(experimentFig,'-property','YGrid'),'YGrid','on');
%set(findall(experimentFig,'-property','LineWidth'),'Linewidth',1.2);