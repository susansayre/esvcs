function [offerVector,expRegPayoff,expLandPayoff,expPayoffIfDelay,condChoice] = regObj2(offerVector,previousChoice,randValues,G,optType)
%returns the regulator's payoff in period 2 as a function of the vector of offers made to particular parcels
%when making offers, regulator knows what choice the parcel made last period, v1D, v2D, and envD
%offerVector and previousChoice are parcels x 1 vectors
%randValues is a parcels x randSamples x reg2unknowns array representing possible values for each consequential variable not known by
%the regulator in period2
%each column is equally likely

randCases = size(randValues,2); %will only be larger than 1 in my no info case
parcelNum = size(randValues,1);

%Alternate test for testing effect of rhoBenD and rhoCostD
absValueDeltaGain = abs(max(randValues(:,:,G.ind.out.develop) - randValues(:,:,G.ind.out.epriv),[],2) - min(randValues(:,:,G.ind.out.develop) - randValues(:,:,G.ind.out.epriv),[],2));
if max(absValueDeltaGain)>1e-14
    keyboard
end
% if any(max(randValues(:,:,G.ind.out.develop),[],2)-min(randValues(:,:,G.ind.out.develop),[],2))
%     keyboard
% end
% if any(max(randValues(:,:,G.ind.out.epriv),[],2)-min(randValues(:,:,G.ind.out.epriv),[],2))
%     keyboard
% end        
 
switch optType
    case 'na'
        %not doing optimization, only compute payoffs
        optimize = 0;
        offerMat = zeros(size(randValues(:,:,1)));
        offerMat = offerVector;
        numOffers = 1;
    case 'singleOffer'
        %no info known can only make single offer
        %verify that develop and epriv are constant across rows of randValues
        changeCosts = randValues(:,1,G.ind.out.develop)*(1+G.developGr)-randValues(:,1,G.ind.out.epriv);
        possibleOffers = unique([0;changeCosts(find(changeCosts>0))]); 
        numOffers = numel(possibleOffers);
        offerMat = permute(repmat(possibleOffers,[1 randCases parcelNum]),[3 2 1]); %constant by row and column, varies by page;

    case 'allKnown'
        %no randomness is left
        optimize = 1;
        offerMat = offerVector;
        if randCases>1
            error('Shouldn''t have multiple rand cases in this situation')
        end
        numOffers = 1;
        if any(offerVector.*(previousChoice~=1))
            keyboard
        end
    case 'multOfferEV'
        error('have not coded this option yet')
    otherwise
        error(['I don''t recognize optType ' optType])
end

convertible = repmat((previousChoice==G.ind.choice.delay),[1 randCases numOffers]);
conservedEarly = repmat((previousChoice==G.ind.choice.conserve),[1 randCases numOffers]);
develop2 = repmat(randValues(:,:,G.ind.out.develop),[1 1 numOffers])*(1+G.developGr);
epriv = repmat(randValues(:,:,G.ind.out.epriv),[1 1 numOffers]);
epub = repmat(randValues(:,:,G.ind.out.epub),[1 1 numOffers]);

numOfferChange = 1;
iter = 0;
while numOfferChange>0
    iter = iter+1;
    if iter>15; keyboard; end
    netConserveBen = round(offerMat+epriv - develop2,13);
    conservedNow = convertible.*(netConserveBen>=0);
    convertNow = convertible.*(netConserveBen<0);
    conservedAll = conservedNow + conservedEarly;
    converted = 1-conservedAll; %this version assumes that land converted in period 1 yields v1 in that period and v2 for remaining periods

    svcsTotal = squeeze(sum(conservedAll.*epub)); %randCases x numOffers matrix of total svc values
    valTotal = squeeze(sum(converted.*develop2)); %randCases x numOffers matrix of total develop values
    fundCostTotal = squeeze(G.fundCostP*sum(conservedNow.*offerMat)); %randCases x numOffers matrix of total fundCosts

    expRegPayoff = mean(valTotal + G.envLin*svcsTotal - fundCostTotal + G.envQuad*svcsTotal.^2); %1 x numOffer vector of payoffs
    expLandPayoff = squeeze(mean(max(offerMat+epriv,develop2),2)); %parcelNum x numOffers matrix of expPayoffs if delay
            
    expPayoffIfDelay = expLandPayoff;
    
    if numOffers>1
        %pick best offer
        [bestPayoff,bestPayoffInd] = max(expRegPayoff);
        expRegPayoff = bestPayoff;
        expPayoffIfDelay = expLandPayoff(:,bestPayoffInd);
        condChoice = G.ind.choice.conserve*conservedNow(:,1,bestPayoffInd) + G.ind.choice.convert*convertNow(:,1,bestPayoffInd);
        numOfferChange = 0;
    elseif optimize
        
        if randCases>1
            error('Have not coded expectedValue optimization with multiple offers')
        end
        dEnvPayoff = G.envLin +2*G.envQuad*svcsTotal;
                
        costToChange = max(0,develop2 - epriv); %required payment to induce parcel to remain forested
        benefitOfConservation = repmat(dEnvPayoff,parcelNum,1).*epub - develop2 - costToChange;
        
        %making multiple offers

        parcelsMaybePaid = intersect(find(previousChoice~=G.ind.choice.delay),find(costToChange>0)); %parcels that didn't delay before and have to be induced to stay forested
        worthPaying = benefitOfConservation>0; %parcels whose benefit of remaining forested is greater than their cost

        induceThese = convertNow.*worthPaying;
        stopThese = conservedNow.*(1-worthPaying).*(offerVector>0); %parcels remaining forested whose benefit of remaining forested is less than the cost

        if any(induceThese)
            offerMat(find(induceThese)) = costToChange(find(induceThese));
        end
        if any(stopThese)
              offerMat(find(stopThese)) = 0;
        end
        numOfferChange = sum([induceThese; stopThese]);
        
        changeInds = intersect(worthPaying,parcelsMaybePaid);
        expPayoffIfDelay(changeInds,:) = mean(develop2(changeInds,:),2); %regulator makes the parcels it wants to change whole
        condChoice = G.ind.choice.conserve*conservedNow + G.ind.choice.convert*convertNow;
        if G.interactive && any(offerMat.*(1-convertible))
            keyboard
        end
        offerVector = offerMat;
    else
        condChoice = G.ind.choice.conserve*conservedNow + G.ind.choice.convert*convertNow;
        numOfferChange = 0;
    end
end

