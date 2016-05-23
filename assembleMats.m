
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
    
    %call script to compute A, mu, and sigma matrices/vectors from the
    %compStat parameters for this case
    computeMats
    
	v1 = sigmaOut(G.ind.out.v1,G.ind.out.v1)*normRands + muOut(G.ind.out.v1);
    [v1,v1Wgt] = qnwnorm(50,muOut(G.ind.out.v1),sigmaOut(G.ind.out.v1,G.ind.out.v1));
    
	expectedPayoff = expVal2(v1,muBig(:,ii),sigmaBig(:,:,ii));
    
    saveas(gcf,fullfile(outputPath,['expVal2case' num2str(ii)]),'epsc')
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
    saveas(gcf,fullfile(outputPath,['regPayoff_' num2str(ii)]),'epsc')
    
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
    
    saveas(gcf,fullfile(outputPath,['choices_' num2str(ii)]),'epsc')
    close all
    
end

save(fullfile(outputPath,'outputFile'))

	