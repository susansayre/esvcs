function[expRegPayoff,expLandPayoff] = singleObj(offer,idx,otherOffer,previousChoice,randValues,G)

offerVector = otherOffer;
offerVector(idx) = offer;
[expRegPayoff,expLandPayoff] = regObj2(offerVector,previousChoice,randValues,G);