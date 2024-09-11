function [MCA,MCAB,MCAZ,MPhi] = GenerateMPCMatrices_withDelay(A,B,C,Z,N1,N2,Nu) 
%% Nur für Delay Nt = N1
Nt = N1;

%% Zählvariablen
H = N2-N1+1;
nU = size(B,2);
nX = size(A,1);
nY = size(C,1);

%% Matrizen Init
MCA         = zeros(nY*H,nX);
MCAB        = zeros(nY*H,nU);
MCAZ        = zeros(nY*H,1);
MPhi        = zeros(nY*H,Nu);

%% MCA
countCol = 1;
for k = N1-Nt:N2-Nt
   MCA(countCol:countCol+1,:) = C*A^k;
   countCol = countCol + nY;
end

%% MCAB & MCAZ
countCol = 1;
for k = N1-Nt-1:N2-Nt-1
    sumA = zeros(length(A));
    for i = 0:k
       sumA = sumA + A^i;
    end
    MCAB(countCol:countCol+1,:) = C*sumA*B;
    MCAZ(countCol:countCol+1,:) = C*sumA*Z;
    countCol = countCol + nY;
end

%% MPhi
countRow = 1;
for k = N1-Nt:N2-Nt %Zeile
    countCol = 1;
    for i = k-1:-1:k-Nu %Spalte
        if i < 0
            MPhi(countRow:countRow+nY-1,countCol) = zeros(nY,nU);
        else
            sumA = eye(length(A));
            for j = 1:i
                sumA = sumA + A^j;
            end
            MPhi(countRow:countRow+nY-1,countCol) = C*sumA*B;
        end
        countCol = countCol + nU;
    end    
    countRow = countRow + nY;
end