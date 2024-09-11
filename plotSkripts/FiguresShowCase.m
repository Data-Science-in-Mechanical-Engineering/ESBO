
function FiguresShowCase(State,Case,Stats,Settings,infillKritfunc,FigSettings)
%PLOTPROGRESSMPC Summary of this function goes here
%   Detailed explanation goes here


MarkerSpec = {'b'};

xPlot = linspace(Case.lb(1), Case.ub(1), 1000)';
for i = 1: size(xPlot,1)
    [Mean(i,1),Var(i,1),PredNoiseVar(i,1)] = evalMetaModels(State,Settings,xPlot(i));
end
tic
[MES] = infillKritfunc(xPlot);
toc
%FigSettings = struct;
YSamplesErr = State.EvalSamples.virtualSigma_Y;
YSamplesErr(isnan(YSamplesErr)) = 0;


% ######################## Plot for experimental results! ################

DesiredFigWidth = 16.9/3*4;
DesiredFigHeight = 5; % [cm]


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
hOffset = 0.035;

N_Subplots_horizontal = 3;
N_Subplots_vertical = 1;
vMarginTop = 0.05;
vMarginBottom = 0.15+ 0.02;
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

s1 = subplot(1,3,1);
s1.OuterPosition = [Xpos(plotNumber(2)) Ypos(plotNumber(1)) width height];
s1.Position(3) = width-(s1.Position(1) - s1.OuterPosition(1));
s1.Position(4) = height-(s1.Position(2) - s1.OuterPosition(2));

colorArray = [FigSettings.color.blau_100;FigSettings.color.petrol_100;FigSettings.color.orange_100;FigSettings.color.rot_100];

for i = 1:size(State.EvalSamples.YVect,1)
    p(i) = plot(cumsum(State.EvalSamples.YVect(i,1:State.EvalSamples.episodeLength(i))),'LineWidth',1.2,'Color',colorArray(i,:))
    hold all
end
text( 70 , 0.33 , "$\theta_1$",Interpreter="latex") 
text( 185 , 0.18 , "$\theta_2$",Interpreter="latex") 
text( 63 , 0.18 , "$\theta_3$",Interpreter="latex") 
text( 155 , 0.235 , "$\theta_4$",Interpreter="latex") 
%legend(p,{"\theta_1","\theta_2","\theta_3","\theta_4"},'location','southeast')


errorbar([197],FigSettings.MCCustomErrorBars.mean(1),FigSettings.MCCustomErrorBars.sigma(1),'+', 'Color', [FigSettings.color.orange_100], 'MarkerFaceColor', FigSettings.color.orange_100, 'MarkerSize',5,'LineWidth',1.5);
errorbar([197],FigSettings.MCCustomErrorBars.mean(2),FigSettings.MCCustomErrorBars.sigma(2),'+', 'Color', [FigSettings.color.rot_100], 'MarkerFaceColor', FigSettings.color.rot_100, 'MarkerSize',5,'LineWidth',1.5);


plot([1 size(State.EvalSamples.YVect,2)],[State.Yopt State.Yopt],'Color',FigSettings.color.schwarz_50,'LineWidth',0.8)
xlim([1 size(State.EvalSamples.YVect,2)])
xlabel('Episode Time',Interpreter='latex')
xticks([State.EvalSamples.episodeLength(3) State.EvalSamples.episodeLength(4) size(State.EvalSamples.YVect,2)])
yticks([ 0.211])
yticklabels({  "$J^*_4$"});
xticklabels({ "$T_3$","$T_4$","$T_{\mathrm{max}}$"});
s1.TickLabelInterpreter = 'latex';
ylabel('Cumulated Cost $\Sigma j_t$',Interpreter='latex')

plotNumber = [1, 2]; % [Zeile, Spalte]

s25 = subplot(1,3,2);
s25.OuterPosition = [Xpos(plotNumber(2)) Ypos(plotNumber(1)) width height];
s25.Position(3) = width-(s25.Position(1) - s25.OuterPosition(1));
s25.Position(4) = height-(s25.Position(2) - s25.OuterPosition(2));

f = [Mean(:,end)+FigSettings.beta*sqrt(Var); flipdim(Mean(:,end)-FigSettings.beta*sqrt(Var),1)];
p5 = fill([xPlot; flipdim(xPlot,1)], f, [7 7 7]/8);
hold all
pmean(1) = plot(xPlot,Mean(:,1),'k','LineWidth',1.2)
if FigSettings.useMC
    errorbar(FigSettings.MCCustomErrorBars.x(1),FigSettings.MCCustomErrorBars.mean(1),FigSettings.MCCustomErrorBars.sigma(1),'+', 'Color', [FigSettings.color.orange_100], 'MarkerFaceColor', FigSettings.color.orange_100, 'MarkerSize',5,'LineWidth',1.5);
    errorbar(FigSettings.MCCustomErrorBars.x(2),FigSettings.MCCustomErrorBars.mean(2),FigSettings.MCCustomErrorBars.sigma(2),'+', 'Color', [FigSettings.color.rot_100], 'MarkerFaceColor', FigSettings.color.rot_100, 'MarkerSize',5,'LineWidth',1.5);

  %  errorbar(FigSettings.MCCustomErrorBars.x,FigSettings.MCCustomErrorBars.mean,FigSettings.MCCustomErrorBars.sigma,'+', 'Color', FigSettings.color.blau_100, 'MarkerFaceColor', FigSettings.color.orange_100, 'MarkerSize',5,'LineWidth',1.5);
end
for i = 1:1:4
p2 = errorbar(State.EvalSamples.X(i),State.EvalSamples.virtualY(i),YSamplesErr(i),'o', 'Color', colorArray(i,:), 'MarkerFaceColor', colorArray(i,:), 'MarkerSize',5);
end


xlabel('Controller Parameters',Interpreter='latex')
xticks([0.25 0.45 0.65 0.8])
yticks([])
s25.TickLabelInterpreter = 'latex';
xticklabels({'$\theta_1$','$\theta_2$','$\theta_4$','$\theta_3$'});
ylabel('Objective J',Interpreter='latex')

%ylim(([-0.6 1.5]))



plotNumber = [1, 3]; % [Zeile, Spalte]
s2 = subplot(1,3,3);
s2.OuterPosition = [Xpos(plotNumber(2)) Ypos(plotNumber(1)) width height];
s2.Position(3) = width-(s2.Position(1) - s2.OuterPosition(1));
s2.Position(4) = height-(s2.Position(2) - s2.OuterPosition(2));

[~,maxMESInd] = max(log10(-MES));
plot(xPlot,log10(-MES),'LineWidth',1.2,'Color',FigSettings.color.blau_100)
hold all
plot(xPlot(maxMESInd),log10(-MES(maxMESInd)),'^','Color', FigSettings.color.schwarz_100,'MarkerFaceColor', FigSettings.color.schwarz_100, 'MarkerSize',8)

ylim([-3 1])
xlabel('Controller Parameters',Interpreter='latex')
xticks([0.25 0.45  xPlot(maxMESInd) 0.65 0.8])
yticks([])
s2.TickLabelInterpreter = 'latex';
xticklabels({'$\theta_1$','$\theta_2$','$\theta_5$','$\theta_4$','$\theta_3$'});
ylabel('Ac. Fun. $\alpha$',Interpreter='latex')


set(findall(summaryFig,'-property','FontSize'),'FontSize',10); % change font size
set(findall(summaryFig,'-property','TickDir'),'TickDir','out');
%set(findall(summaryFig,'-property','XMinorTick'),'XMinorTick','off');
%set(findall(summaryFig,'-property','YMinorTick'),'YMinorTick','off');
set(findall(summaryFig,'-property','XGrid'),'XGrid','off');
set(findall(summaryFig,'-property','YGrid'),'YGrid','off');
%set(findall(summaryFig,'-property','LineWidth'),'Linewidth',1.2);




end


