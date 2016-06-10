%matlab script to compute needed matrices from input values

A = zeros(numel(outputs),numel(primitives));
muPrim = zeros(numel(primitives),1);
muPrim(G.ind.prim.epub) = meanEnv;
muPrim(G.ind.prim.epriv) = meanEnv*eprivShr;
muPrim(G.ind.prim.vpub) = meanEnv*vpubShr;
muPrim(G.ind.prim.vpriv) = muPrim(G.ind.prim.vpub)*vprivShr;

A(G.ind.out.epub,G.ind.prim.epub) = 1;
A(G.ind.out.epriv,G.ind.prim.epriv) = 1;
A(G.ind.out.vpub,G.ind.prim.vpub) = 1;
A(G.ind.out.vpriv,G.ind.prim.vpriv) = 1;
A(G.ind.out.vpub2,G.ind.prim.vpub) = (1+G.vpubGr);
A(G.ind.out.vpriv2,G.ind.prim.vpriv) = (1+G.vprivGr);

varVec(G.ind.prim.epub) = varEnv;
varVec(G.ind.prim.epriv) = eprivVarRat*varEnv;
varVec(G.ind.prim.vpub)= vpubVarRat*varEnv;
varVec(G.ind.prim.vpriv) = vprivVarRat*vpubVarRat*varEnv;

sigmaPrimMat = zeros(numel(primitives),numel(primitives));
sigmaPrimMat(G.ind.prim.epub,G.ind.prim.epriv) = rhoEpubPriv*(varVec(G.ind.prim.epub)*varVec(G.ind.prim.epriv))^.5;
sigmaPrimMat(G.ind.prim.epub,G.ind.prim.vpub) = rhoEVpub*(varVec(G.ind.prim.epub)*varVec(G.ind.prim.vpub))^.5;
sigmaPrimMat(G.ind.prim.epub,G.ind.prim.vpriv) = rhoEVpubPriv*(varVec(G.ind.prim.epub)*varVec(G.ind.prim.vpriv))^.5;
sigmaPrimMat(G.ind.prim.epriv,G.ind.prim.vpub) = rhoEVprivPub*(varVec(G.ind.prim.epriv)*varVec(G.ind.prim.vpub))^.5;
sigmaPrimMat(G.ind.prim.epriv,G.ind.prim.vpriv) = rhoEVpriv*(varVec(G.ind.prim.epriv)*varVec(G.ind.prim.vpriv))^.5;
sigmaPrimMat(G.ind.prim.vpub,G.ind.prim.vpriv) = rhoVpubPriv*(varVec(G.ind.prim.vpub)*varVec(G.ind.prim.vpriv))^.5;
sigmaPrimMat = sigmaPrimMat + sigmaPrimMat' + diag(varVec);

muOut = A*muPrim;
sigmaOut = A*sigmaPrimMat*A';

Abig = [A; eye(numel(primitives))];
% muBig(:,ii) = Abig*muPrim;
% sigmaBig(:,:,ii) = Abig*sigmaPrimMat*Abig';

varies = ones(numel(outputs),1);
if rank(sigmaPrimMat)<numel(primitives)
    keyboard
    %check each variable type
else
    evalStatement={};
end

parcelNum = 30;
regCasesNum = 15;
randRegNum = 15;

rng default
p = haltonset(2,'Skip',1e3,'Leap',1e2);
p = scramble(p,'RR2');
privRandOutInds = [G.ind.out.epriv G.ind.out.vpriv];
privRands = norminv(net(p,parcelNum));
privRands = privRands*cholcov(sigmaOut(privRandOutInds,privRandOutInds)) + repmat(muOut(privRandOutInds)',parcelNum,1);

reg2kInds = [G.ind.out.epub G.ind.out.vpub];
transitionMat = sigmaOut(reg2kInds,privRandOutInds)/sigmaOut(privRandOutInds,privRandOutInds);
condVarMat = sigmaOut(reg2kInds,reg2kInds) + transitionMat*sigmaOut(privRandOutInds,reg2kInds);
condVarMat = cholcov(condVarMat);
privRandsRepeat = repmat(privRands,regCasesNum,1);

regCases = norminv(net(p,parcelNum*regCasesNum))*condVarMat; 
regCases = regCases' + muOut(reg2kInds)*ones(1,parcelNum*regCasesNum) + transitionMat*(privRandsRepeat' - repmat(muOut(privRandOutInds),1,parcelNum*regCasesNum));
regCases = regCases';

allValues = [privRandsRepeat regCases];

randDraw2Inds(G.ind.reg2rand.epriv) = G.ind.out.epriv;
randDraw2Inds(G.ind.reg2rand.vpriv2) = G.ind.out.vpriv2;

transitionMat = sigmaOut(randDraw2Inds,reg2kInds)/sigmaOut(reg2kInds,reg2kInds);
regCasesRepeat = repmat(regCases,randRegNum,1);
condVarMat = sigmaOut(randDraw2Inds,randDraw2Inds) + transitionMat*sigmaOut(reg2kInds,randDraw2Inds);
condVarMat = cholcov(condVarMat);

randDraw2 = norminv(net(p,parcelNum*regCasesNum*randRegNum))*condVarMat;
randCases = randDraw2' + muOut(randDraw2Inds)*ones(1,parcelNum*regCasesNum*randRegNum) + transitionMat*(regCasesRepeat' - repmat(muOut(reg2kInds),1,parcelNum*randRegNum*regCasesNum));
randCases = randCases';
randCases = [randCases regCasesRepeat];

reshapedCases = reshape(randCases,[numel(randDraw2Inds)+2,parcelNum,regCasesNum,randRegNum]);
randValues = permute(reshapedCases,[2 4 1 3]); %switch the order so v1 varies on rows, v2 and env across columns, first page is variable and last page is reg2 draw.

G.envLin = 1-G.envQuad*meanEnv;
r = 1/G.discount - 1;
if numPeriods == Inf
    G.payoff2Factor = 1/r;
else
    G.payoff2Factor = (1-1/(1+r)^numPeriods)/r;
end