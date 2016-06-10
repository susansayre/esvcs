function [expRegPayoff,expLandPayoff] = regObj2(offerVector,previousChoice,randValues,G)
%returns the regulator's payoff in period 2 as a function of the vector of offers made to particular parcels
%when making offers, regulator knows what choice the parcel made last period, v1D, v2D, and envD
%offerVector and previousChoice are parcels x 1 vectors
%randValues is a parcels x randSamples x reg2unknowns array representing possible values for each consequential variable not known by
%the regulator in period2
%each column is equally likely

randCases = size(randValues,2);
convertible = repmat((previousChoice==G.ind.choice.delay),1,randCases);
conservedEarly = repmat((previousChoice==G.ind.choice.conserve),1,randCases);
vpriv2 = randValues(:,:,G.ind.reg2rand.vpriv2);
epriv = randValues(:,:,G.ind.reg2rand.epriv);
vpub = randValues(:,:,G.ind.reg2rand.vpub);
epub = randValues(:,:,G.ind.reg2rand.epub);

offerMat = repmat(offerVector,1,randCases);
conservedNow = convertible.*(offerMat+epriv>vpriv2);
conservedAll = conservedNow + conservedEarly;
converted = 1-conservedAll; %this version assumes that land converted in period 1 yields v1 in that period and v2 for remaining periods

svcsTotal = mean(conservedAll.*epub); %1 x randCases vector of total svc values
valTotal = mean(converted.*vpub*(1+G.vpubGr));
fundCostTotal = G.fundCostP*mean(conservedNow.*offerMat);

expRegPayoff = -mean(valTotal + G.envLin*svcsTotal - fundCostTotal + G.envQuad*svcsTotal.^2);
expLandPayoff = mean(max(offerMat+epriv,vpriv2),2);