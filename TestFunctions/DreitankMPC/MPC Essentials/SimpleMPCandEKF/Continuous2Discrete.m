function [AD, BD, CD] = Continuous2Discrete(A,B,C,T)
%#codegen
%#eml
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Konvertierung kontinuierliche zur zeitdiskreten Zustandsraumdarstellung
% mit Abtastzeit T für Systeme ohne Durchgriff (D=0)
% Entspricht Umsetzung der Gleichungen 9.101 im Skript.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% kontinuierlich:
% x_dot = A*x + B*u;
% y = CD*x
% zeitdiskret:
% x_k+1 = AD*x_k + BD*uk;
% y_k = C*x_k
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hinweis: Die Gleichungen aus dem Skript
% AD = expm(A*T);
% BD = (AD-eye(size(A)))*inv(A)*B;
% funktionieren eigentlich auch direkt, geben aber Probleme,sobald 
% Integratoren (Nullzeilen in A-Matrix enthalten sind. Deshalb ist die
% anschließende Implementierung an Matlab's C2D angelehnt.
% Es sollte aber ggf. auch eine sauberere  Lösung geben. Gerne Info@Re
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Beispielwerte annehmen, wenn keine Funktionsargumentente angegeben sind:
if isempty(coder.target)    
    if ~exist('A','var')
        A = [-2 0; 0 -1 ];
        B = [1; 1];
        C = [1 0];
        T = 0.1;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hilfszwischenwerte;
AnzahlStellgroessen = size(B,2);
AnzahlZustaende = size(A,1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generierung AD und BD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = expm([[A B]*T; zeros(AnzahlStellgroessen,AnzahlZustaende+AnzahlStellgroessen)]);
AD = s(1:AnzahlZustaende,1:AnzahlZustaende);
BD = s(1:AnzahlZustaende,AnzahlZustaende+1:AnzahlZustaende+AnzahlStellgroessen);
CD = C;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Erweiterung um Instationären Term bei X_dot_AP ~= 0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ist das System zum Zeitpunkt der Linearisierung nicht stationär, so 
% muss dies für ein Korrektes Modell berücksichtigt werden.
%
% kontinuierlich:
% x_dot = A*x + B*u + X_dot_AP;
% y = C*x
% zeitdiskret:
% x_k+1 = AD*x_k + BD*uk + ED*X_dot_AP;
% y_k = C*x_k
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s2 = expm([[A eye(size(A))]*T; zeros(AnzahlZustaende,AnzahlZustaende+AnzahlZustaende)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%