%matlab script to compute needed matrices from input values
[allValuesArray,gainArray,G] = prepareData(
for jj=1:length(compStat)
    eval([compStat{jj,1} ' = valArray(jj);'])
end

muPrim = zeros(numel(primitives),1);
muPrim(C.ind.prim.epub) = C.meanDevelop + epubStd*C.varDevelop^.5;
muPrim(C.ind.prim.epriv) = C.meanDevelop - eprivStd*C.varDevelop^.5;
muPrim(C.ind.prim.develop) = C.meanDevelop;

varVec(C.ind.prim.epub) = varDevelop*epubVarRat;
varVec(C.ind.prim.epriv) = eprivVarRat*C.varDevelop;
varVec(C.ind.prim.develop)= C.varDevelop;

sigmaPrim = zeros(numel(primitives),numel(primitives));
sigmaPrim(C.ind.prim.epub,C.ind.prim.epriv) = rhoEpubPriv*(varVec(C.ind.prim.epub)*varVec(C.ind.prim.epriv))^.5;
sigmaPrim(C.ind.prim.epub,C.ind.prim.develop) = rhoEpubD*(varVec(C.ind.prim.epub)*varVec(C.ind.prim.develop))^.5;
sigmaPrim(C.ind.prim.epriv,C.ind.prim.develop) = rhoEprivD*(varVec(C.ind.prim.epriv)*varVec(C.ind.prim.develop))^.5;
sigmaPrim = sigmaPrim + sigmaPrim' + diag(varVec);

if rank(sigmaPrim)<numel(primitives)
    continue
    %check each variable type
else
    evalStatement={};
end

parcelNum = size(C.stdNormals,1);
regCasesNum = size(C.stdNormals,1)/parcelNum;

for vi=1:numel(C.privRandOuts)
    privRandOutInds(vi) = eval(['C.ind.prim.' C.privRandOuts{vi}]);
end
for vi=1:numel(C.reg2ks)
    reg2kInds(vi) = eval(['C.ind.prim.' C.reg2ks{vi}]);
end

privRands = C.stdNormals1(:,1:numel(privRandOutInds))*cholcov(sigmaPrim(privRandOutInds,privRandOutInds)) + repmat(muPrim(privRandOutInds)',parcelNum,1);

transitionMat = sigmaPrim(reg2kInds,privRandOutInds)/sigmaPrim(privRandOutInds,privRandOutInds);
condVarMat = sigmaPrim(reg2kInds,reg2kInds) + transitionMat*sigmaPrim(privRandOutInds,reg2kInds);
condVarMat = cholcov(condVarMat);
privRandsRepeat = repmat(privRands,regCasesNum,1);

regCases = C.stdNormals(:,numel(privRandOutInds)+1:numel(reg2kInds)+numel(privRandOutInds))*condVarMat; 
regCases = regCases' + muPrim(reg2kInds)*ones(1,parcelNum*regCasesNum) + transitionMat*(privRandsRepeat' - repmat(muPrim(privRandOutInds),1,parcelNum*regCasesNum));
regCases = regCases';

for vi=1:numel(privRandOutInds);
    eval(['allValues(:,C.ind.prim.' C.privRandOuts{vi} ')= privRandsRepeat(:,vi);'])
end
for vi=1:numel(reg2kInds);
    eval(['allValues(:,C.ind.prim.' C.reg2ks{vi} ')=regCases(:,vi);'])
end

allValuesArray = reshape(allValues,[parcelNum regCasesNum numel(privRandOutInds) + numel(reg2kInds)]);

C.envLin = 1-C.envQuad*muPrim(C.ind.prim.epub);
r = 1/C.discount - 1;
if numPeriods == Inf
    C.payoff2Factor = 1/r;
else
    C.payoff2Factor = (1-1/(1+r)^numPeriods)/r;
end

