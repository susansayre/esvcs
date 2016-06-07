clear all; close all;
dbstop if error

runID = datestr(now,'yyyymmdd_HHMMSS');
outputPath = fullfile('storedOutput',runID);
if ~exist(outputPath,'dir')
    mkdir(outputPath)
end

%normalize everything on mean env value = 10 and variance env value = 1;
%This implies that the likelihood of negative env values is extremely
%small;

%constant parameters
meanEnv = 1;
varEnv = 1;
delta = .95;

compStat = {
    'muValRat',     'ratio of mean v1 to mean env',                     [1];
    'varValRat',    'ratio of the variance of v1 to variance of env',	[1];
    'varVCRat',     'ratio of the variance of vc to variance of v1',    [.1]; %0 means value change is constant across parcels
    'rhoEV',        'covariance between de and dv',                     [-.5 0 .5];
    'rhoEVC',       'covariance between de and dvc',                    [0];
    'rhoVVC',       'covariance between dv and dvc',                    [0];
    'vardvRat',     'ratio of the variance of dv to variance of v1',    [.5];
    'vardvcRat',    'ratio of the variance of dvc to variance of vc',   [.5]; %1 means no random value change
    'muValChangeP', '% increase in mean value',                         [0]; %0 means no trend in value
    'G.envQuad',    '',                                                 [0 -.1 -.2];
    'vardeRat',     'ratio of the variance of de to variance of env',   [.8];
    'G.fundCostP',  'cost of funds to pay fees',                        [.01];
    'numPeriods', 'number of periods we receive period 2 payoff',     [5];
};

prepareCompStatArray
randomizationStructure
G.discount = delta;
%conduct the comparative static loops
nochanges = zeros(size(valArray,1),1);
for ii=1:size(valArray,1)
%for ii=1:1
    
    for jj=1:length(compStat)
        eval([compStat{jj,1} ' = valArray(ii,jj);'])
    end
    
    %call script to compute A, mu, and sigma matrices/vectors from the
    %compStat parameters for this case and use quadrature to generate reasonable samples
    computeMats
    %next steps -- figure out how regulator optimizes given samples. Inner
    %optimization is for each parcel, across possible randMat draws
    
    %outer optimization will be across detMat draws because they aren't
    %known a priori. Have to account for the possibility that only certain
    %parcels will remain convertible in period 1.
    options = optimset('Display','iter');
    %options.showiter = 1;
    offer1 = [.2*muOut(G.ind.out.env) 1*muOut(G.ind.out.v1)];
    maxV1 = max(randArrayStruct.land1(:,1,G.ind.out.v1));
   
    %[expRegVal,expLandVal,choice] = land1Choice(offer1,randArrayStruct,randWgtStruct);
    v1Vals = randArrayStruct.land1(:,1,G.ind.out.v1);
    v1Vals = [0; v1Vals; 1.5*v1Vals(end)];
    offerCases = gridmake(v1Vals,v1Vals);
    parfor ti = 1:size(offerCases,1)
        expRegVal(ti) = land1Choice(offerCases(ti,:),randArrayStruct,randWgtStruct,G);
    end
    [regPayoff,caseInd] = max(expRegVal);
    optOfferGrid = offerCases(caseInd,:);
    [optOffer,regPayoff2,exf2] = fmincon(@(x) land1Choice(x,randArrayStruct,randWgtStruct,G),optOfferGrid,[],[],[],[],0*optOfferGrid,Inf+optOfferGrid,'',options);
     save(fullfile(outputPath,[ runID '_case' num2str(ii)]))
end
    
    