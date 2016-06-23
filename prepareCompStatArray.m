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

%set other indicator variables
C.ind.choice.conserve = 2;
C.ind.choice.delay = 1;
C.ind.choice.convert = 3;
%order of choices determines what happens if payoffs are the same. This order assumes landowners take permanent
%conservation first if indifferent, then delay, and finally immediate development.

C.ind.offer1.temp = 1; 
C.ind.offer1.perm = 2;

C.ind.reg2rand.epriv = 1;
C.ind.reg2rand.vpriv2 = 2;
C.ind.reg2rand.epub = 3;
C.ind.reg2rand.vpub = 4;
