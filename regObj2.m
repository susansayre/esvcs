function expPayoff = regObj2(offerVector,previousChoice,regRandArray,regRandWgts,G)
%returns the regulator's payoff as a function of the vector of offers made to particular parcels
%inputs:
%   offerVector -- parcelNodes x 1 vector of offers to individual landowners
%   parcelDetMat -- parcelNodes x numKnown+1 matrix of values for the characteristics known by regulator. Last column is
%   the accompanying weights
%   randDrawMat -- randNodes x numRand+1 matrix of values for the characteristics unknown by anyone. Last column is the
%   accompanying weights

convertible = (previousChoice==G.ind.choice.delay);
randCases = size(regRandWgts,2);
v2 = regRandArray(:,:,G.ind.out.v2);
env = regRandArray(:,:,G.ind.out.env);

offerMat = repmat(offerVector,1,randCases);
conservedNow = convertible.*(offerMat>v2);
conservedAll = conservedNow + (previousChoice==G.ind.choice.conserve);
converted = 1-conservedAll; %this version assumes that land converted in period 1 yields v1 in that period and v2 for remaining periods

caseProbs = sum(regRandWgts,1);

svcsTotal = sum(conservedAll.*env.*regRandWgts,1)./caseProbs; %1 x randCases vector of total svc values
valTotal = sum(converted.*v2.*regRandWgts,1)./caseProbs;
fundCostTotal = sum(G.fundCostP*conservedNow.*offerMat.*regRandWgts,1)./caseProbs;

expPayoff = -(valTotal + G.envLin*svcsTotal - fundCostTotal + G.envQuad*svcsTotal.^2)*caseProbs';
%keyboard
