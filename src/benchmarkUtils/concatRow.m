function  [mat] = concatRow(mat,vect)


if isempty(mat)
mat(1,:) = vect;
return
end

vectLen = length(vect);
matCol = size(mat,2);

if vectLen > matCol
    mat =  [mat repmat(mat(:,end),1,vectLen-matCol)];
end

if vectLen < matCol
    vect(end:end +  matCol-vectLen) = vect(end);
end



mat(end+1,:) = vect;

end