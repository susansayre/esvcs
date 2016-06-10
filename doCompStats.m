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
    'eprivShr'      'ratio of means of priv and public env value. s/b <1'       [.8];
    'vpubShr'       'ratio of means of public conversion to env value.'         [1];
    'vprivShr'      'ratio of means of priv and public conversion value s/b>1'  [1.2];
    'G.vpubGr'        '(constant) growth rate of public conversion value'       [0];
    'G.vprivGr'       '(constant) growth rate of priv conversion value'         [.1];
    'eprivVarRat'   'ratio of epriv var to epub var'                            [1];
    'vpubVarRat'    'ratio of vpub var to epub var'                             [1];
    'vprivVarRat'   'ratio of vpriv var to vpub var'                            [1];
    'rhoEpubPriv'   'corr btwn public and priv env value'                       [0];
    'rhoEVpub'      'corr btwn public env and conv value'                       [0];
    'rhoEVpubPriv'  'corr btwn public env and priv conv value'                  [-.5 0 .5];
    'rhoEVprivPub'  'corr btwn priv env and pub conv value'                     [0];
    'rhoEVpriv'     'corr btwen priv env and conv value'                        [0];
    'rhoVpubPriv'   'corr between public and priv conv value'                   [0];
    'G.envQuad'     ''                                                          [0];
    'numPeriods'    ''                                                          [1];
    'G.fundCostP'   ''                                                          [.1];
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
    offer1 = [muOut(G.ind.out.vpriv)-muOut(G.ind.out.epriv) .1*(muOut(G.ind.out.vpriv)-muOut(G.ind.out.epriv))];
    maxSurplus = max(privRands(:,2)-privRands(:,1));
   
    [optOffer,regPayoff2,exf2] = fmincon(@(x) -land1Choice(x,privRands,randValues,G,['case' num2str(ii)]),offer1,[],[],[],[],0*offer1,Inf+ offer1,'',options);
    %keyboard
     save(fullfile(outputPath,[ runID '_case' num2str(ii)]))
end
    
    