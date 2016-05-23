clear all; close all;
dbstop if error
global G;

%normalize everything on mean env value = 10 and variance env value = 1;
%This implies that the likelihood of negative env values is extremely
%small;

%constant parameters
meanEnv = 10;
varEnv = 1;
delta = .95;
%comparative static parameters
compStat = {
    'muValRat',     'ratio of mean v1 to mean env',                     [.9,1,1.1];
    'varValRat',    'ratio of the variance of v1 to variance of env',	[.75,1,1.25];
    'varVCRat',     'ratio of the variance of vc to variance of v1',    [0]; %0 means value change is constant
    'rhoEV',        'covariance between de and dv',                     [-.5,0, .5];
    'rhoEVC',       'covariance between de and dvc',                    [0];
    'rhoVVC',       'covariance between dv and dvc',                    [0];
    'vardvRat',     'ratio of the variance of dv to variance of v1',    [.25,.5,.75];
    'vardvcRat',    'ratio of the variance of dvc to variance of vc',   [1]; %1 means no random value change
    'muValChangeP', '% increase in mean value',                         [0]; %0 means no trend in value
};

% compStat = {
%     'muValRat',     'ratio of mean v1 to mean env',                     [1];
%     'varValRat',    'ratio of the variance of v1 to variance of env',	[1];
%     'varVCRat',     'ratio of the variance of vc to variance of v1',    [.2];
%     'rhoEV',        'covariance between de and dv',                     [-.5,0, .5];
%     'rhoEVC',       'covariance between de and dvc',                    [0];
%     'rhoVVC',       'covariance between dv and dvc',                    [0];
%     'vardvRat',     'ratio of the variance of dv to variance of v1',    [.25,.75];
%     'vardvcRat',    'ratio of the variance of dvc to variance of vc',   [1];
%     'muValChangeP', '% increase in mean value',                         [-.01, 0, .01, .02, .03, .05];
% };

compStat = {
    'muValRat',     'ratio of mean v1 to mean env',                     [1.5];
    'varValRat',    'ratio of the variance of v1 to variance of env',	[.5, 1.5];
    'varVCRat',     'ratio of the variance of vc to variance of v1',    [0]; %0 means value change is constant
    'rhoEV',        'covariance between de and dv',                     [-.5];
    'rhoEVC',       'covariance between de and dvc',                    [0];
    'rhoVVC',       'covariance between dv and dvc',                    [0];
    'vardvRat',     'ratio of the variance of dv to variance of v1',    [.25,.75];
    'vardvcRat',    'ratio of the variance of dvc to variance of vc',   [1]; %1 means no random value change
    'muValChangeP', '% increase in mean value',                         [0]; %0 means no trend in value
};

for ii=1:length(compStat) 
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

G.parcelDraws = 1000;
G.parcels = 1000;

primitives = {'de','dv','dvc','rv','rvc','const'};
outputs = {'v1','vc','vd2','v2','env','rvt','dvt'};

for ii=1:numel(outputs)
    eval(['G.ind.out.' outputs{ii} ' = ii;'])
end

G.ind.big = G.ind.out;

for ii=1:numel(primitives)
    eval(['G.ind.prim.' primitives{ii} ' = ii;'])
    eval(['G.ind.big.' primitives{ii} ' = numel(outputs) + ii;'])
end

fminsearchOptions = optimset('Display','iter');

permPays = .5*meanEnv:meanEnv/20:1.5*meanEnv;
tempPays = 0:meanEnv/100:.2*meanEnv;

nx1 = length(tempPays); nx2 = length(permPays);
xMat = gridmake(tempPays',permPays');
permPayMat = reshape(xMat(:,2),nx1,nx2);
tempPayMat = reshape(xMat(:,1),nx1,nx2);
    
normRands = randn(G.parcels,1);
for ii=1:size(valArray,1)
%for ii=1:1
    
    for jj=1:length(compStat)
        eval([compStat{jj,1} ' = valArray(ii,jj);'])
    end
    
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

	v1 = sigmaOut(G.ind.out.v1,G.ind.out.v1)*normRands + muOut(G.ind.out.v1);
    [v1,v1Wgt] = qnwnorm(50,muOut(G.ind.out.v1),sigmaOut(G.ind.out.v1,G.ind.out.v1));
    
	expectedPayoff = expVal2(v1,muBig(:,ii),sigmaBig(:,:,ii));
    
    saveas(gcf,['expVal2case' num2str(ii)],'epsc')
    close
    
    if isempty(expectedPayoff)
        x(ii,:) = -100; fval(ii) = -100;
        continue
    end
       
    [svcsCondMean,svcsCondSigma] = condDist(G.ind.big.env,muBig(:,ii),sigmaBig(:,:,ii),G.ind.big.v1,v1);
    
    x0 = [(1-delta)*meanEnv; .9*v1'*v1Wgt];
    x0 = [(1-delta)*v1'*v1Wgt; 0];
    
    [xi,fvali,exitflag] = fminsearch(@(x) regulatorPayoff(x,v1,delta,expectedPayoff,svcsCondMean,v1Wgt),x0,fminsearchOptions);
    [~,landPayoff,choice] = regulatorPayoff(xi,v1,delta,expectedPayoff,svcsCondMean,v1Wgt);
    
%     [permi,permvali,permexfi] = fminsearch(@(x) regulatorPayoff([0; x],v1,delta,expectedPayoff,svcsCondMean,v1Wgt),.9*v1'*v1Wgt,fminsearchOptions);
%     [permReg,permLand,permChoice] = regulatorPayoff([0;8.1],v1,delta,expectedPayoff,svcsCondMean,v1Wgt);
     %check zero
    [zVal,zlP,zC] = regulatorPayoff([0;0],v1,delta,expectedPayoff,svcsCondMean,v1Wgt);
    if zVal<fvali
        x(ii,:) = [0 0]; fval(ii,:) = -zVal; exf(ii,:) =-99;
        landPayoffs(ii,:) = zlP; choices(ii,:) = zC;
    else
        x(ii,:) = xi; fval(ii,:)=-fvali; exf(ii,:)=exitflag;
        landPayoffs(ii,:) = landPayoff; choices(ii,:)=choice;
    end
    [maxVal,bestUse] = max([v1,svcsCondMean,(1+muValChangeP)*v1]');
    firstBest(ii,:) = sum(maxVal);
    vals(ii,:) = v1;
    sbRat(ii,:) =  fval(ii)/firstBest(ii);
    expectedPayoffs(ii,:) = expectedPayoff;
    condSvcMeans(ii,:) = svcsCondMean;
    
    for jj=1:length(xMat)
        [payoffj,landPayoffj,choicej] = regulatorPayoff(xMat(jj,:),v1,delta,expectedPayoff,svcsCondMean);
        regPayoff(ii,jj) = -payoffj;
        landPayoffGrid(jj,:,ii) = landPayoffj;
        choiceGrid(jj,:,ii) = choicej;
        numConvert(jj,ii) = sum(choicej==1);
        numDelay(jj,ii) = sum(choicej==2);
        numConserve(jj,ii) = sum(choicej==3);
    end
    
    figure()
    [c,h] = contour(tempPayMat,permPayMat,reshape(regPayoff(ii,:),nx1,nx2)); clabel(c,h);
    hold on;
    plot(x(ii,1),x(ii,2),'x')
    saveas(gcf,['regPayoff_' num2str(ii)],'epsc')
    
    figure()
    subplot(2,2,1)
    [c,h] = contour(tempPayMat,permPayMat,reshape(numConvert(:,ii),nx1,nx2)); clabel(c,h);
    hold on;
    plot(x(ii,1),x(ii,2),'x')

    subplot(2,2,2)
    [c,h] = contour(tempPayMat,permPayMat,reshape(numDelay(:,ii),nx1,nx2)); clabel(c,h);
    hold on;
    plot(x(ii,1),x(ii,2),'x')
    
    subplot(2,2,3)
    [c,h] = contour(tempPayMat,permPayMat,reshape(numConserve(:,ii),nx1,nx2)); clabel(c,h);
    hold on;
    plot(x(ii,1),x(ii,2),'x')
    
    saveas(gcf,['choices_' num2str(ii)],'epsc')
    close all
    
end

save outputFile

	