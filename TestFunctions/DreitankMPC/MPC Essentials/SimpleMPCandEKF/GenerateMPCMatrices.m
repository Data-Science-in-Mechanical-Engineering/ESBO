function [MCA, MCAB, MPhi] = GenerateMPCMatrices(AD,BD,CD, N1, N2, Nu) 
%#codegen
%#eml
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generiert Matritzen für die MPC für Umsetzung nach Gl. 10.13 im Skript:
% 
% y(.|k) = MCA*x_k + MCAB*u_k-1 + MPhi*delta_uk     (+MCX0_dot*X_dot_AP)*
%
% zugrunde liegende zeitdiskrete Systemdarstellung:
%
% x_k+1 = AD*x_k + BD*uk                            (+ ED*X_dot_AP)*;
% y_k = CD*x_k
%_______________________________________________________________________
% *optionale Erweiterung für Systeme, die in einem instationären
%  Arbeitspunkt linearisiert wurden.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prädiktionshorizont: N1...N2
% Stellhorizont: Nu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Beispielwerte annehmen, wenn keine Funktionsargumentente angegeben sind:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(coder.target)    
    if ~exist('AD','var')
        AD = [0.8187 0; 0 0.9048];
        BD = [0.0906;0.0952];
        CD = [1 0];
        N1 = 1;
        N2 = 10;
        Nu = 3;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Hilfszwischenwerte;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Horizontlaenge = N2-N1+1;
AnzahlStellgroessen = size(BD,2);
AnzahlZustaende = size(AD,1);
AnzahlRegelgroessen = size(CD,1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Matritzen für Freie Regelgröße MCA MCAB und MCX_dot_AP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MCA         = zeros(AnzahlRegelgroessen*(Horizontlaenge)   ,AnzahlZustaende);
MCAB        = zeros(AnzahlRegelgroessen*(Horizontlaenge)   ,AnzahlStellgroessen);
for k = N1:N2
    CDAexpk = CD*(AD^k);
    MCA((k-N1)*AnzahlRegelgroessen+(1:AnzahlRegelgroessen), (1:AnzahlZustaende))= CDAexpk;
    % MCA
    SumAi = zeros(AnzahlZustaende);
    for i = 0:(k-1)
        SumAi = SumAi+AD^i;
    end
    % MCAB
    CDSumAiBd = CD*SumAi*BD;
    MCAB((k-N1)*size(CDSumAiBd,1)+(1:size(CDSumAiBd,1)), (1:size(CDSumAiBd,2)))= CDSumAiBd;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Matrix für erzwungene Regelgröße (MPhi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MPhi =  zeros(AnzahlRegelgroessen*(Horizontlaenge)   ,AnzahlStellgroessen*Nu   );
for i1 = N1:N2
    for i2 = 0:(Nu-1)
        SumAj = zeros(AnzahlZustaende);
        if i1-i2 <1
            continue
        end
        for j = 0:(i1-i2-1)
          SumAj = SumAj+AD^j;
        end
        CDSumAjBD = CD*SumAj*BD;
        MPhi((i1-N1)*AnzahlRegelgroessen+(1:size(CDSumAjBD,1)),i2*AnzahlStellgroessen+(1:size(CDSumAjBD,2)) )  = CDSumAjBD ;
    end
end