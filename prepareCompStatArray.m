for ii=1:size(compStat,1) 
	eval([compStat{ii,1} 'Ind = ii;'])
	valArray(1,ii) = compStat{ii,3}(1);
end
valInds = ones(size(valArray));

for ii=1:length(compStat)
	lastVals = valArray;
    lastInds = valInds;
	for jj=2:length(compStat{ii,3})
		newVals = lastVals;
        newInds = lastInds;
		newVals(:,ii)=compStat{ii,3}(jj);
        newInds(:,ii) = jj;
		valArray = [valArray;newVals];
        valInds = [valInds; newInds];        
	end
end
