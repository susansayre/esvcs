function[expRegPayoff,expLandPayoff] = singleObj(offer,idx,otherOffer,previousChoice,randValues,G)

offerVector = otherOffer;
offerVector(idx) = offer;
[expRegPayoff,expLandPayoffAll] = regObj2(offerVector,previousChoice,randValues,G);

expLandPayoff = expLandPayoffAll(idx);