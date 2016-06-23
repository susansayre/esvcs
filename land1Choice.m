function [expRegVal,expLandVal,optOffers,period1Choice,condChoices] = land1Choice(offer1,allValuesArray,gainArray,G,flag,caseID)

if ~exist('flag','var')
    flag = 'l'; %set default flag to learning
end
%disp(['starting land1Choice, ' flag ', ' caseID])
%extract/set values that are constant over the looping
try
   load(fullfile(G.outputPath,['solGuesses/' caseID]))
catch
    period1Choice = G.ind.choice.delay*ones(size(allValuesArray,1),1); %initialize all parcels to delay
    offer0 = (gainArray(:,:,6)>0).*gainArray(:,:,5);
end



numChange = 10;
iter = 0;

switch G.offer1type
    case 'perm'
        offer1perm = offer1;
        offer1temp = 0*offer1;
    case 'temp'
        offer1perm = 0*offer1;
        offer1temp = offer1;
    case 'both'
        offer1perm = offer1(:,G.ind.offer1.perm);
        offer1temp = offer1(:,G.ind.offer1.temp);
end

%note that when allValues has multiple columns, they are all the same for develop and epriv
choices(:,G.ind.choice.convert) = allValuesArray(:,1,G.ind.out.develop)*(1+(1+G.developGr)*G.payoff2Factor);
choices(:,G.ind.choice.conserve) = (offer1perm+allValuesArray(:,1,G.ind.out.epriv))*(1+G.payoff2Factor);

options = optimset('Display','iter','MaxFunEvals',10e5);
% options.showiter = 0;
% options.tol = 1e-4;
while numChange>0
    iter = iter+1;
    period1ChoiceOld = period1Choice;
    nonConvertibleParcels = find(period1Choice~=G.ind.choice.delay);
    %predict regulator choice given a set of period1 choices by landowners
    switch flag
        case 'ni'
            %no info will be revealed next period, can only make a single offer
            thisOffer0 = mean(mean(offer0));
            [optOffer,expPayoffReg2,~,expPayoffIfDelay,condChoices] = regObj2(thisOffer0,period1Choice,allValuesArray,G,'singleOffer');
%             [optOffer,fval,exf] = fmincon(@(x) regObj2(x,period1Choice,allValuesArray,G),thisOffer0,[],[],[],[],0,Inf,'',options);
%             [expPayoffReg2,expPayoffLand2,~,condChoices] = regObj2(optOffer,period1Choice,allValuesArray,G);
            expValDelay = expPayoffIfDelay;
        case 'na'
            %regulator will not make a payment
            optOffer = 0;
            [optOffer,expPayoffReg2,~,expPayoffIfDelay,condChoices] = regObj2(0,period1Choice,allValuesArray,G,'na');
            expValDelay = expPayoffIfDelay;
        otherwise
            %I will learn everything next period (but might be nothing to reveal)
            %need to loop through possible realizations of info next period 
            for ii=1:size(allValuesArray,2)
                %when I know everything, the second dimension of allValuesArray is 1
                thisOffer0 = offer0(:,ii).*(period1Choice==G.ind.choice.delay);
                [condOffers(:,ii),expPayoffReg2(ii),~,expPayoffIfDelay(:,ii),condChoices(:,ii)] = regObj2(thisOffer0,period1Choice,allValuesArray(:,ii,:),G,'allKnown');
            end
        expValDelay = mean(expPayoffIfDelay,2); %integrate out envD, v1D, v2D, v2, and env to get expectation of landowner
    end
    %expValDelay is v1Cases x 1;
    choices(:,G.ind.choice.delay) = offer1temp + allValuesArray(:,1,G.ind.out.epriv) + G.payoff2Factor*expValDelay; %note -- allValues has a nonzero second dimension, epriv is constant across dimensions
    choices = round(choices,4); %avoids flip-flopping due to functionally identical payoffs
    [expLandVal,period1Choice] = max(choices,[],2);
    numChange = numel(find(period1Choice-period1ChoiceOld));
%    fprintf('%d\n',numChange);
    if iter>100
        if G.interactive
            keyboard
        else
            disp('Cutting off iterations in land1Choice')
            save(['land1ChoiceState_' caseID])
            numChange=0;
        end
    end
end
          
conserve = (period1Choice==G.ind.choice.conserve);
convert = (period1Choice==G.ind.choice.convert);
delay = (period1Choice==G.ind.choice.delay);

switch flag
    case 'ni'
        optOffers = optOffer;
    case 'na'
        optOffers = 0;
    case 'pi'
        optOffers = zeros(size(allValuesArray(:,:,1)));
        optOffers(delay) = condOffers(delay);
    case 'l'
        optOffers = condOffers;
        if any(mean(condOffers,2).*(conserve+convert))
             keyboard
        end
end

totalSvcs1 = sum(repmat(conserve+delay,1,size(allValuesArray,2)).*allValuesArray(:,:,G.ind.out.epub)); %sums across parcels
expectedEnvPayoff1 = mean(totalSvcs1 + G.envQuad*totalSvcs1.^2); %averages across cases

totalConv1 = sum(repmat(convert,1,size(allValuesArray,2)).*allValuesArray(:,:,G.ind.out.develop));
expConvPayoff = mean(totalConv1);
expRegVal = expectedEnvPayoff1 + expConvPayoff + mean(expPayoffReg2)*G.payoff2Factor - G.fundCostP*(sum(offer1temp.*delay + offer1perm.*conserve));

if exist('caseID','var')
    if ~exist(fullfile(G.outputPath,'solGuesses'),'dir')
        mkdir(fullfile(G.outputPath,'solGuesses'))
    end
    if isscalar(optOffers)
        offer0 = max(.1,optOffers);
    else
        offer0(period1Choice==G.ind.choice.delay,:) = optOffers(period1Choice==G.ind.choice.delay,:);
    end
    save(fullfile(G.outputPath,'solGuesses',caseID),'period1Choice','offer0')
end

%if strcmp(flag,'l') && nargout>1; keyboard; end