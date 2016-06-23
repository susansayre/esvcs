%matlab script to compute needed matrices from input values
function [allValuesArray,gainArray,G] = prepareData(compStat,valArray,C,thisCase)

%transfer current C values to G
G = C;

for jj=1:length(compStat)
    eval([compStat{jj,1} ' = valArray(jj);'])
end

%G.developGr = (1 - G.discount + developGrR)/G.discount;

varDevelop = C.meanDevelop*varDevelopP;
muPrim(C.ind.prim.pubBen,:) = pubBenStd*varDevelop^.5;
muPrim(C.ind.prim.privCost,:) = privCostStd*varDevelop^.5;
muPrim(C.ind.prim.develop,:) = C.meanDevelop;

varVec(C.ind.prim.pubBen) = pubBenVarRat*varDevelop;
varVec(C.ind.prim.privCost) = privCostVarRat*varDevelop;
varVec(C.ind.prim.develop)= varDevelop;

sigmaPrim = zeros(numel(muPrim),numel(muPrim));
sigmaPrim(C.ind.prim.pubBen,C.ind.prim.privCost) = rhoBenCost*(varVec(C.ind.prim.pubBen)*varVec(C.ind.prim.privCost))^.5;
sigmaPrim(C.ind.prim.pubBen,C.ind.prim.develop) = rhoBenD*(varVec(C.ind.prim.pubBen)*varVec(C.ind.prim.develop))^.5;
sigmaPrim(C.ind.prim.privCost,C.ind.prim.develop) = rhoCostD*(varVec(C.ind.prim.privCost)*varVec(C.ind.prim.develop))^.5;
sigmaPrim = sigmaPrim + sigmaPrim' + diag(varVec);

muDraw = C.Adraw*muPrim;
sigmaDraw = C.Adraw*sigmaPrim*C.Adraw';

if rank(sigmaPrim)<numel(muPrim)
    allValuesArray =[]; gainArray = []; G.skipThisParamSet = 1;
    return
    %check each variable type
else
    G.skipThisParamSet = 0;
end

parcelNum = size(C.stdNormalsPriv,1);
regCasesNum = size(C.stdNormalsReg,2)/numel(C.reg2kInds);

privRands = C.stdNormalsPriv(:,1:numel(C.privRandOutInds))*cholcov(sigmaDraw(C.privRandOutInds,C.privRandOutInds)) + repmat(muDraw(C.privRandOutInds)',parcelNum,1);
privRandsRepeat = repmat(privRands,regCasesNum,1);

transitionMat = sigmaDraw(C.reg2kInds,C.privRandOutInds)/sigmaDraw(C.privRandOutInds,C.privRandOutInds);
condVarMat = sigmaDraw(C.reg2kInds,C.reg2kInds) + transitionMat*sigmaDraw(C.privRandOutInds,C.reg2kInds);
condVarMat = cholcov(condVarMat);

regCases = reshape(C.stdNormalsReg,parcelNum*regCasesNum,numel(C.reg2kInds))*condVarMat; 
regCases = regCases' + muDraw(C.reg2kInds)*ones(1,parcelNum*regCasesNum) + transitionMat*(privRandsRepeat' - repmat(muDraw(C.privRandOutInds),1,parcelNum*regCasesNum));
regCases = regCases';

allValuesDraw = zeros(parcelNum*regCasesNum,numel(C.privRandOutInds)+numel(C.reg2kInds));
for vi=1:numel(C.privRandOutInds);
    eval(['allValuesDraw(:,C.ind.draw.' C.privRandOuts{vi} ')= privRandsRepeat(:,vi);'])
end
for vi=1:numel(C.reg2kInds);
    eval(['allValuesDraw(:,C.ind.draw.' C.reg2ks{vi} ')=regCases(:,vi);'])
end

allValuesDraw(:,C.ind.draw.develop) = muDraw(C.ind.draw.develop);

muOut = C.Aout*muDraw;
sigmaOut = C.Aout*sigmaDraw*C.Aout';

allValues = allValuesDraw*C.Aout';
allValuesArray = reshape(allValues,[parcelNum regCasesNum numel(C.privRandOutInds) + numel(C.reg2kInds)]);

% %%%%%%%%%%%%special code for testing effect of rhoBenD and rhoCostD
% parcelNum = 400; regCasesNum = 100;
% privCostDraw = C.stdNormals1*sigmaDraw(C.ind.draw.privCost,C.ind.draw.privCost) + muDraw(C.ind.draw.privCost); %only works because variances are currently all zero
% privCostDrawRepeat = repmat(privCostDraw,100,1);
% 
% transitionMat = sigmaDraw(C.ind.draw.pubBen,C.ind.draw.privCost)/sigmaDraw(C.ind.draw.privCost,C.ind.draw.privCost);
% condVarMat = sigmaDraw(C.ind.draw.pubBen,C.ind.draw.pubBen) + transitionMat*sigmaDraw(C.ind.draw.privCost,C.ind.draw.pubBen);
% condVarMat = cholcov(condVarMat);
% 
% pubBenDraw = reshape(C.stdNormals2,20*100,1)*condVarMat;
% pubBenDraw = pubBenDraw' + muDraw(C.ind.draw.pubBen) + transitionMat*(privCostDrawRepeat' - muDraw(C.ind.draw.privCost));
% pubBenDraw = pubBenDraw';
% 
% condInds = [C.ind.draw.privCost C.ind.draw.pubBen];
% drawInd = C.ind.draw.develop;
% 
% privCostDrawFull = repmat(privCostDrawRepeat,20,1);
% pubBenDrawFull = repmat(pubBenDraw,20,1);
% condDraw = [privCostDrawFull pubBenDrawFull];
% 
% transitionMat = sigmaDraw(drawInd,condInds)/sigmaDraw(condInds,condInds);
% condVarMat = sigmaDraw(drawInd,drawInd) + transitionMat*sigmaDraw(condInds,drawInd);
% condVarMat = cholcov(condVarMat);
% 
% developDraw = reshape(C.stdNormals3,20*100*20,1)*condVarMat;
% developDraw = developDraw' + muDraw(drawInd) + transitionMat*(condDraw' - repmat(muDraw(condInds),1,20*100*20));
% developDraw = developDraw';
% 
% developDraw = reshape(C.stdNormals3,100*20*20,1);
% 
% allValuesDraw(:,C.ind.draw.privCost) = condDraw(:,1);
% allValuesDraw(:,C.ind.draw.pubBen) = condDraw(:,2);
% allValuesDraw(:,C.ind.draw.develop) = developDraw;
% 
% allValues = allValuesDraw*C.Aout';
% 
% allValuesArray1 = reshape(allValues,[20 100 20 3]);
% allValuesArray = permute(allValuesArray1,[1 3 2 4]);
% allValuesArray = reshape(allValuesArray,[400 100 3]);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

G.envLin = 1-G.envQuad*muOut(C.ind.out.epub)*parcelNum;
r = 1/C.discount - 1;
if numPeriods == Inf
    G.payoff2Factor = 1/r;
else
    G.payoff2Factor = (1-1/(1+r)^numPeriods)/r;
end

%add the mean realizations of epub to the beginning of allValuesArray to use in my pi calcs
allValuesArray = [mean(allValuesArray,2) allValuesArray];

gainArray(:,:,1) = allValuesArray(:,:,G.ind.out.epub) - allValuesArray(:,:,G.ind.out.develop);
gainArray(:,:,2) = allValuesArray(:,:,G.ind.out.develop) - allValuesArray(:,:,G.ind.out.epriv);
gainArray(:,:,3) = (gainArray(:,:,2)>0).*(gainArray(:,:,1)>0).*max(0,(gainArray(:,:,1)-G.fundCostP*gainArray(:,:,2))); %have to paid to conserve & better to conserve * max(0, benefit of conservation - cost)

gainArray(:,:,4) = allValuesArray(:,:,G.ind.out.epub) - allValuesArray(:,:,G.ind.out.develop)*(1+G.developGr);
gainArray(:,:,5) = allValuesArray(:,:,G.ind.out.develop)*(1+G.developGr) - allValuesArray(:,:,G.ind.out.epriv);
gainArray(:,:,6) = (gainArray(:,:,5)>0).*(gainArray(:,:,1)>0).*max(0,gainArray(:,:,1)-G.fundCostP*gainArray(:,:,2));

save(fullfile(C.outputPath,thisCase))
