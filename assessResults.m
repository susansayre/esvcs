%assess results

%arrange outputs in arrays
arrangeThese = {'expRegVal_na' 'expLandVal_na' 'period1Choice_na' 'condChoices_na' ...
    'piOffer' 'expRegVal_pi' 'piExf' 'expLandVal_pi' 'optOffers_pi' 'period1Choice_pi' 'condChoices_pi' ...
    'niOffer' 'niExf' 'expRegVal_ni' 'expLandVal_ni' 'optOffers_ni' 'period1Choice_ni' 'condChoices_ni' ...
    'lOffer' 'lExf' 'expRegVal_l' 'expLandVal_l' 'optOffers_l' 'period1Choice_l' 'condChoices_l' ...
    'probCases' compStatVars{:,1} 'gainNi' 'gainPi' 'gainL' 'pGainL' 'pGainNi' 'deltaOffer' 'deltaGainP' 'deltaGain'};

%get comp stat size and order
[~,compStatSortOrder] = sort(compStatCases);
for ii=1:numel(compStatSortOrder)
    thisVar = compStatVars{compStatSortOrder(ii),1}
    compStatOrder{ii} = thisVar;
    compStatSizes(ii) = numel(compStatVars{compStatSortOrder(ii),2});
    eval([thisVar '= valArray(:,ind.' thisVar ');'])
end

for ii=1:numel(arrangeThese)
    thisVar = arrangeThese{ii};
    eval(['thisSize = size(' thisVar ');'])
    if thisSize(1)==1; 
        thisSize=thisSize(2);
    end
    reshapeSize = [compStatSizes thisSize(2:end)];
    eval([ thisVar 'Array = reshape(' thisVar ',reshapeSize);'])
end
    
save(fullfile(outputPath,'fullResults'))

