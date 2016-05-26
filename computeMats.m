%matlab script to compute needed matrices from input values

A = zeros(numel(outputs),numel(primitives));

A(G.ind.out.v1D,G.ind.prim.const) = meanEnv*muValRat;
A(G.ind.out.v1D,G.ind.prim.dv) = 1;

A(G.ind.out.v1,:) = A(G.ind.out.v1D,:);
A(G.ind.out.v1,G.ind.prim.rv) = 1;

A(G.ind.out.v2D,G.ind.prim.const) = muValChangeP*A(G.ind.out.v1,G.ind.prim.const);
A(G.ind.out.v2D,G.ind.prim.dvc) = 1;
A(G.ind.out.v2D,:) = A(G.ind.out.v2D,:) + A(G.ind.out.v1D,:);

A(G.ind.out.v2,:) = A(G.ind.out.v2D,:);
A(G.ind.out.v2,[G.ind.prim.rv G.ind.prim.rvc]) = 1;

A(G.ind.out.envD,G.ind.prim.const) = meanEnv;
A(G.ind.out.envD,G.ind.prim.de) = 1;

A(G.ind.out.env,:) = A(G.ind.out.envD,:);
A(G.ind.out.env,G.ind.prim.re) = 1;

varVal = varValRat*varEnv;
varVec(G.ind.prim.de) = vardeRat*varEnv;
varVec(G.ind.prim.dv)= vardvRat*varVal;
varVec(G.ind.prim.dvc) = vardvcRat*varVCRat*varVal;
varVec(G.ind.prim.re) = (1-vardvRat)*varEnv;
varVec(G.ind.prim.rv) = (1-vardvRat)*varVal;
varVec(G.ind.prim.rvc) = (1-vardvcRat)*varVCRat*varVal;
varVec(G.ind.prim.const) = 0;

sigmaPrimMat = zeros(numel(primitives),numel(primitives));
sigmaPrimMat(G.ind.prim.de,G.ind.prim.dv) = rhoEV*(varVec(G.ind.prim.de)*varVec(G.ind.prim.dv))^.5;
sigmaPrimMat(G.ind.prim.de,G.ind.prim.dvc) = rhoEVC*(varVec(G.ind.prim.de)*varVec(G.ind.prim.dvc))^.5;
sigmaPrimMat(G.ind.prim.dv,G.ind.prim.dvc) = rhoVVC*(varVec(G.ind.prim.dv)*varVec(G.ind.prim.dvc))^.5;

sigmaPrimMat = sigmaPrimMat + sigmaPrimMat' + diag(varVec);
muPrim(G.ind.prim.const,1) = 1;

muOut = A*muPrim;
sigmaOut = A*sigmaPrimMat*A';

Abig = [A; eye(numel(primitives))];
muBig(:,ii) = Abig*muPrim;
sigmaBig(:,:,ii) = Abig*sigmaPrimMat*Abig';

if muOut(G.ind.out.v1)~= meanEnv*muValRat
    error('v1 mean is wrong')
end

%Generate a representative sample with weights for the outputs of interest
approxNodes = 5; %number of nodes for each variable

[~,p] = chol(sigmaOut);
if p
    try
        sqrtm(sigmaOut);
    catch
        display('I can''t figure out how to generate your variable')
    end
    optset('qnwnorm','usesqrtm',1);
else
    optset('qnwnorm','usesqrtm',0);
end
[randOutMat,randWgtVec] = qnwnorm(approxNodes*ones(size(muOut)),muOut,sigmaOut);

reshapeSize = approxNodes*ones(1,size(muOut,1));
randOutArray = reshape(randOutMat,[reshapeSize numel(muOut)]);
randWgtArray = reshape(randWgtVec,reshapeSize);

for di=1:numel(G.decisionMakers)
    thisDecisionMaker = G.decisionMakers{di};
    eval(['[randArrayStruct.' thisDecisionMaker ',randWgtStruct.' thisDecisionMaker '] = dmInfo(G.' thisDecisionMaker ',randOutArray,randWgtArray);'])
end