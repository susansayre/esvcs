clear all; close all;
dbstop if error

%set run specific parameters
C.interactive = 0;
parcelNum = 100;
regCasesNum = 100;

runID = datestr(now,'yyyymmdd_HHMMSS');
outputPath = fullfile('storedOutput',runID);
if ~exist(outputPath,'dir')
    mkdir(outputPath)
end
C.outputPath = outputPath;

%constant parameters
C.meanDevelop = 10;
C.discount = .95;

baseParams = {
    'varDevelopP'    'variance of development value relative to mean'            [.1];
    'privCostStd'    'epriv mean is xx std devs of develop ben'                  [1];
    'pubBenStd'      'epub mean is xx std devs of develop ben'                   [2];
    'G.developGr'    '(constant) growth rate of priv conversion value'           [0]; %parcels that want to convert regardless prefer now, but more parcels will convert in period2
    'privCostVarRat' 'ratio of epriv var to develop var'                         [1];
    'pubBenVarRat'   'ratio of epub var to develop var'                          [1];
    'rhoBenCost'     'corr btwn public benefit and priv cost'                    [0];
    'rhoBenD'        'corr btwn public benefit and develop value'                [0];
    'rhoCostD'       'corr btwen priv cost and develop value'                    [0];
    'G.envQuad'      ''                                                          [0];
    'numPeriods'     ''                                                          [1];
    'G.fundCostP'    ''                                                          [1];
};

for ii=1:size(baseParams,1)
    eval(['ind.' baseParams{ii,1} '= ii;'])
end

% compStatVars = {
%      'rhoBenCost'   [-.5 0 .5];
%      'rhoBenD'      [-.5 0 .5];
%      'rhoCostD'     [-.5 0 .5];
% };

% compStatVars = {
%      'rhoBenCost'   [-.5 0 .5];
%      'rhoBenD'      [-.5 0 .5];
% };
% compStatVars = {
%     'rhoBenCost'    [-.5 -.25 0 .25 .5];
% };

% compStatVars = {
%     'privCostStd'   [.75 1 1.25];
% };

compStatVars = {
    'rhoBenCost'     [-.5 0 .5];
    'privCostStd'    [.5 1 1.5];
    'pubBenStd'      [.5 1 1.5];
    'privCostVarRat' [.75 1.25];
    'pubBenVarRat'   [.75 1.25];
};
% 
% compStatVars = {
% 	'numPeriods' 	[1 2];
% 	'G.fundCostP'	[1 .9];
% };

compStat = baseParams;
compStatCases = [];
for ii=1:size(compStatVars,1)
    thisInd = eval(['ind.' compStatVars{ii,1}]);
    compStat{thisInd,3} = compStatVars{ii,2};
    compStatCases = [compStatCases thisInd];
end

prepareCompStatArray
randomizationStructure

numPIcases = 5;
options = optimset('Display','off');
%conduct the comparative static loops
skippedCase = zeros(1,size(valArray,1));
parfor ii=1:size(valArray,1)
%for ii=1:1
    
    thisCase = ['case' num2str(ii)];
    [allValuesArray,gainArray,G] = prepareData(compStat,valArray(ii,:),C,thisCase);  
    
    if G.skipThisParamSet
        skippedCase(ii) = 1;
        continue
    end
    
    %compute actions/payoffs with no regulator action
    [expRegVal_na(ii),expLandVal_na(ii,:),~,period1Choice_na(ii,:),condChoices_na(ii,:,:)] = land1Choice(0,allValuesArray(:,2:end,:),gainArray(:,2:end,:),G,'na');
    
    %compute optimal single period offers with perfect info at mean values
    doTheseInds = (1:numPIcases);
    doTheseValues = allValuesArray(:,doTheseInds,:);
    thisGainArray = gainArray(:,doTheseInds,:);
    [piOffer(ii,:,:),expRegVal_pi(ii,:),piExf(ii,:),expLandVal_pi(ii,:,:),optOffers_pi(ii,:,:),period1Choice_pi(ii,:,:),condChoices_pi(ii,:,:)] = piSolve(doTheseValues,thisGainArray,G,thisCase,options);
    
    %compute optimal single period offers with no info revealed in period 2
    offer0 = max(mean((gainArray(:,2:end,3)>0).*gainArray(:,2:end,2)));

    %testni(ii) = land1Choice(offer0,allValuesArray(:,2:end,:),gainArray(:,2:end,:),G,'ni',[thisCase 'ni']);
    disp(['starting ni solve case ii=' num2str(ii)])
    [offerNi,valNi,exfNi] = fmincon(@(x) -land1Choice(x,allValuesArray(:,2:end,:),gainArray(:,2:end,:),G,'ni'),offer0,[],[],[],[],0,Inf,'',options);
    niOffer(ii) = offerNi; niExf(ii) = exfNi;
    [expRegVal_ni(ii),expLandVal_ni(ii,:),optOffers_ni(ii,:),period1Choice_ni(ii,:),condChoices_ni(ii,:,:)] = land1Choice(offerNi,allValuesArray(:,2:end,:),gainArray(:,2:end,:),G,'ni',[thisCase 'ni']);

    %compute optimal single period offers with all info revealed in period 2
    %testl(ii) = land1Choice(offer0,allValuesArray(:,2:end,:),gainArray(:,2:end,:),G,'l',['case' num2str(ii) 'l']);     
    disp(['starting l solve case ii=' num2str(ii)])
    [offerL,valL,exfL] = fmincon(@(x) -land1Choice(x,allValuesArray(:,2:end,:),gainArray(:,2:end,:),G,'l'),offer0,[],[],[],[],0,Inf,'',options);
    lOffer(ii) = offerL; lExf(ii) = exfL;
    if valL>valNi
        disp(['learning seems to make you worse off in ' thisCase])
        if G.interactive
            keyboard
        end
    end
    [expRegVal_l(ii),expLandVal_l(ii,:),optOffers_l(ii,:,:),period1Choice_l(ii,:),condChoices_l(ii,:,:)] = land1Choice(offerL,allValuesArray(:,2:end,:),gainArray(:,2:end,:),G,'l',[thisCase 'l']);
    
    probCases(ii,:) = mean(squeeze(mean(gainArray>0)));
     %save(fullfile(outputPath,thisCase))
    allValuesFull(ii,:,:,:) = allValuesArray;
    gainFull(ii,:,:,:) = gainArray;
end

%compareCases
skippedThese = find(skippedCase==1);
for jj=1:numel(skippedThese)
        ii=skippedThese(jj);
        expRegVal_na(ii) = NaN; expLandVal_na(ii,:) = NaN; period1Choice_na(ii,:) = NaN; condChoices_na(ii,:,:) = NaN;
        piOffer(ii,:,:) = NaN; expRegVal_pi(ii,:) = NaN; piExf(ii,:) = NaN; expLandVal_pi(ii,:,:) = NaN; optOffers_pi(ii,:,:) = NaN; period1Choice_pi(ii,:,:) = NaN; condChoices_pi(ii,:,:) = NaN;
        niOffer(ii) = NaN; niExf(ii) = NaN; expRegVal_ni(ii) = NaN; expLandVal_ni(ii,:) = NaN; optOffers_ni(ii,:) = NaN; period1Choice_ni(ii,:) = NaN; condChoices_ni(ii,:,:) = NaN;
        lOffer(ii) = NaN; lExf(ii)=NaN; expRegVal_l(ii)=NaN;expLandVal_l(ii,:)=NaN;optOffers_l(ii,:,:)=NaN;period1Choice_l(ii,:)=NaN;condChoices_l(ii,:,:)=NaN;
        probCases(ii,:) = NaN;
end

gainNi = expRegVal_ni - expRegVal_na;
gainPi = mean(expRegVal_pi,2)' - expRegVal_na;
gainL = expRegVal_l - expRegVal_na;
pGainL = gainL./gainPi;
pGainNi = gainNi./gainPi;

deltaOffer = lOffer-niOffer;
deltaGainP = pGainL - pGainNi;
deltaGain = gainL - gainNi;
changePayCases = find(deltaOffer);

save(fullfile(outputPath,'fullResults'))
disp('Computed full run')    