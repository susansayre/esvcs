%matlab script to compute needed matrices from input values

A = zeros(numel(outputs),numel(primitives));

A(G.ind.out.v1,G.ind.prim.const) = meanEnv*muValRat;
A(G.ind.out.env,G.ind.prim.const) = meanEnv;
A(G.ind.out.vc,G.ind.prim.const) = muValChangeP*A(G.ind.out.v1,G.ind.prim.const);
A(G.ind.out.v1,[G.ind.prim.dv G.ind.prim.rv]) = 1;
A(G.ind.out.vc,[G.ind.prim.dvc G.ind.prim.rvc]) = 1;
A(G.ind.out.env,G.ind.prim.de) = 1;
A(G.ind.out.rvt,[G.ind.prim.rv G.ind.prim.rvc]) = 1;
A(G.ind.out.dvt,[G.ind.prim.dv G.ind.prim.dvc]) = 1;

A(G.ind.out.v2,:) = A(G.ind.out.v1,:) + A(G.ind.out.vc,:);
A(G.ind.out.vd2,:) = A(G.ind.out.v2,:) - A(G.ind.out.rvt,:);

varVal = varValRat*varEnv;
varVec(G.ind.prim.de) = varEnv;
varVec(G.ind.prim.dv)= vardvRat*varVal;
varVec(G.ind.prim.dvc) = vardvcRat*varVCRat*varVal;
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
