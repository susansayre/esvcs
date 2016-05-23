%use quadrature to get reasonable proxies for de, dv, and dvc with
%weights as known by regulator
knownVals = {'de' 'dv' 'dvc'};
for ki = 1:numel(knownVals)
    knownInds(ki) = eval(['G.ind.big.' knownVals{ki}]);
    eval(['G.ind.known.' knownVals{ki} '=ki;'])
end
muKnown = muBig(knownInds);
sigKnown = sigmaBig(knownInds,knownInds);

%pull out the inds that represented primitives that actually vary in
%this compStat simulation
varyInds = find(diag(sigKnown)~=0);
noVaryInds = find(diag(sigKnown)==0);
muHatKnown = muKnown(varyInds);
sigHatKnown = sigKnown(varyInds);
detNodes = 5; %nodes for each variable in deterministic quadrature approximation
[detHatMat,detWgts] = qnwnorm(detNodes*ones(size(muHatKnown)),muHatKnown,sigHatKnown);

detMat(:,varyInds) = detHatMat; 
detMat(:,noVaryInds) = muKnown(noVaryInds);

%rows of detMat represent cases with probabilities contained in corresponding row of detWgts
%columns of detMat give the values for the variables in knownInds.

randVals = {'re' 'rv' 'rvc'};
for ri = 1:numel(randVals)
    randInds(ri) = eval(['G.ind.big.' randVals{ri}]);
    eval(['G.ind.rand.' randVals{ri} '=ri;'])
end
muRand = muBig(randInds);
sigRand = sigmaBig(randInds,randInds);

%pull out the inds that represented primitives that actually vary in
%this compStat simulation
varyInds = find(diag(sigRand)~=0);
noVaryInds = find(diag(sigRand)==0);
muHatRand = muRand(varyInds);
sigHatRand = sigRand(varyInds);
randNodes = 5; %nodes for each variable in deterministic quadrature approximation
[randHatMat,randWgts] = qnwnorm(detNodes*ones(size(muHatRand)),muHatRand,sigHatRand);

randMat(:,varyInds) = randHatMat; 
randMat(:,noVaryInds) = muRand(noVaryInds);
