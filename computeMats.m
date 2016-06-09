%matlab script to compute needed matrices from input values

A = zeros(numel(outputs),numel(primitives));
muPrim = zeros(numel(primitives),1);
muPrim(G.ind.prim.dv) = meanEnv*muValRat;
muPrim(G.ind.prim.de) = meanEnv;
muPrim(G.ind.prim.dvc) = muValChangeP*meanEnv*muValRat;

A(G.ind.out.v1,[G.ind.prim.dv G.ind.prim.rv]) = 1;
A(G.ind.out.v2D,[G.ind.prim.dv G.ind.prim.dvc]) = 1;
A(G.ind.out.v2,[G.ind.prim.dv G.ind.prim.rv G.ind.prim.dvc G.ind.prim.rvc]) = 1;
A(G.ind.out.env,[G.ind.prim.de G.ind.prim.re]) = 1;
A(G.ind.out.envD,G.ind.prim.de) = 1;
A(G.ind.out.v1D,G.ind.prim.dv) = 1;

varVal = varValRat*varEnv;
varVec(G.ind.prim.de) = vardeRat*varEnv;
varVec(G.ind.prim.dv)= vardvRat*varVal;
varVec(G.ind.prim.dvc) = vardvcRat*varVCRat*varVal;
varVec(G.ind.prim.re) = (1-vardeRat)*varEnv;
varVec(G.ind.prim.rv) = (1-vardvRat)*varVal;
varVec(G.ind.prim.rvc) = (1-vardvcRat)*varVCRat*varVal;

sigmaPrimMat = zeros(numel(primitives),numel(primitives));
sigmaPrimMat(G.ind.prim.de,G.ind.prim.dv) = rhoEV*(varVec(G.ind.prim.de)*varVec(G.ind.prim.dv))^.5;
sigmaPrimMat(G.ind.prim.de,G.ind.prim.dvc) = rhoEVC*(varVec(G.ind.prim.de)*varVec(G.ind.prim.dvc))^.5;
sigmaPrimMat(G.ind.prim.dv,G.ind.prim.dvc) = rhoVVC*(varVec(G.ind.prim.dv)*varVec(G.ind.prim.dvc))^.5;

sigmaPrimMat = sigmaPrimMat + sigmaPrimMat' + diag(varVec);

muOut = A*muPrim;
sigmaOut = A*sigmaPrimMat*A';

Abig = [A; eye(numel(primitives))];
muBig(:,ii) = Abig*muPrim;
sigmaBig(:,:,ii) = Abig*sigmaPrimMat*Abig';

if muOut(G.ind.out.v1)~= meanEnv*muValRat
    error('v1 mean is wrong')
end

varies = ones(numel(outputs),1);
if rank(sigmaPrimMat)<numel(primitives)
    keyboard
    %check each variable type
    foundCases = 0;
    if sigmaPrimMat(G.ind.prim.de,G.ind.prim.de)==0
        error('I will learn nothing about env svc next period. Not relevant to our problem')
    end
    if sigmaPrimMat(G.ind.prim.re,G.ind.prim.re)==0
        foundCases = foundCases+1;
        varies(G.ind.out.env) = 0;
        disp('I will learn env svc perfectly next period.')
        evalStatement{foundCases} = 'randOutMat(:,G.ind.out.env) = randOutMat(:,G.ind.out.envD) + muPrim(G.ind.out.re);';
    end
    if sigmaPrimMat(G.ind.prim.dv,G.ind.prim.dv)==0
        disp('I will learn nothing about current value next period.')
        if sigmaPrimMat(G.ind.rv,G.ind.prim.rv)==0
            error('There is no variation in value this period. All landowners will make same choice.')
        end
        foundCases = foundCases+1;
        varies(G.ind.out.v1D) = 0;
        evalStatement{foundCases} = 'randOutMat(:,G.ind.out.v1D) = randOutMat(:,G.ind.out.v1) -  muPrim(G.ind.out.dv);';
    end
    if sigmaPrimMat(G.ind.prim.rv,G.ind.prim.rv)==0
        disp('I will learn first period value perfectly next period.')
        foundCases = foundCases+1;
        varies(G.ind.out.v1) = 0;
        evalStatement{foundCases} = 'randOutMat(:,G.ind.out.v1) = randOutMat(:,G.ind.out.v1D) + muPrim(G.ind.prim.rv);';
    end
    if sigmaPrimMat(G.ind.prim.dvc,G.ind.prim.dvc)==0
        disp('I will observe no unique info about change in value')
        foundCases = foundCases+1;
        varies(G.ind.out.v2D) = 0;
        evalStatement{foundCases} = 'randOutMat(:,G.ind.out.v2D) = randOutMat(:,G.ind.out.v1D) + muPrim(G.ind.prim.dvc);';
    end
    if sigmaPrimMat(G.ind.prim.rvc,G.ind.prim.rvc)==0
        disp('There is no random fluctuation in value change')
        foundCases = foundCases+1;
        varies(G.ind.out.v2) = 0;
        evalStatement{foundCases} = 'randOutMat(:,G.ind.out.v2) = randOutMat(:,G.ind.out.v2D) + randOutMat(:,G.ind.out.v1) - randOutMat(:,G.ind.out.v1D) + muPrim(G.ind.prim.rvc);';
    end
    if rank(sigmaPrimMat)+foundCases<numel(primitives)
        disp('I don''t seem to have solved your problem')
        keyboard
    end 
else
    evalStatement={};
end

v1Num = 30;
l2InfoNum = 15;
randNum = 15;

rng default
p = haltonset(1,'Skip',1e3,'Leap',1e2);
p = scramble(p,'RR2');
v1Rands = norminv(net(p,v1Num));
v1Rands = sort(v1Rands);

reg2kInds = [G.ind.out.v1D G.ind.out.v2D G.ind.out.envD];
v1Values = muOut(G.ind.out.v1) + sigmaOut(G.ind.out.v1,G.ind.out.v1)*v1Rands;

v1ValuesRepeat = repmat(v1Values,l2InfoNum,1);

regCases = mvnrnd(0*reg2kInds,sigmaOut(reg2kInds,reg2kInds)+sigmaOut(reg2kInds,G.ind.out.v1)*inv(sigmaOut(G.ind.out.v1,G.ind.out.v1))*sigmaOut(G.ind.out.v1,reg2kInds),v1Num*l2InfoNum); 
regCases = regCases' + muOut(reg2kInds)*ones(1,v1Num*l2InfoNum) + sigmaOut(reg2kInds,G.ind.out.v1)/sigmaOut(G.ind.out.v1,G.ind.out.v1)*(v1ValuesRepeat' - muOut(G.ind.out.v1));
regCases = regCases';

allValues = [v1ValuesRepeat regCases];

randDraw2Inds(G.ind.reg2rand.v2) = G.ind.out.v2;
randDraw2Inds(G.ind.reg2rand.env) = G.ind.out.env;
condInds = [G.ind.out.v1 reg2kInds];
randDraw2 = mvnrnd(0*randDraw2Inds,sigmaOut(randDraw2Inds,randDraw2Inds)+sigmaOut(randDraw2Inds,condInds)/(sigmaOut(condInds,condInds))*sigmaOut(condInds,randDraw2Inds),v1Num*l2InfoNum*randNum);
randCases = randDraw2' + muOut(randDraw2Inds)*ones(1,v1Num*l2InfoNum*randNum) + sigmaOut(randDraw2Inds,condInds)/(sigmaOut(condInds,condInds))*repmat(allValues' - muOut(condInds)*ones(1,v1Num*l2InfoNum),1,randNum);
randCases = randCases';

reshapedCases = reshape(randCases,[numel(randDraw2Inds),v1Num,l2InfoNum,randNum]);
randValues = permute(reshapedCases,[2 4 1 3]); %switch the order so v1 varies on rows, v2 and env across columns, first page is variable and last page is reg2 draw.

G.envLin = 1-G.envQuad*meanEnv;
r = 1/G.discount - 1;
if numPeriods == Inf
    G.payoff2Factor = 1/r;
else
    G.payoff2Factor = (1-1/(1+r)^numPeriods)/r;
end