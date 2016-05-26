function expPayoff = regObj2(offerVector,convertible,regRandArray,regRandWgts)
%returns the regulator's payoff as a function of the vector of offers made to particular parcels
%inputs:
%   offerVector -- parcelNodes x 1 vector of offers to individual landowners
%   parcelDetMat -- parcelNodes x numKnown+1 matrix of values for the characteristics known by regulator. Last column is
%   the accompanying weights
%   randDrawMat -- randNodes x numRand+1 matrix of values for the characteristics unknown by anyone. Last column is the
%   accompanying weights
global G

randCases = size(regRandWgts,2);
v2 = regRandArray(:,:,G.ind.out.v2);
env = regRandArray(:,:,G.ind.out.env);

conserved = convertible.*(repmat(offerVector,1,randCases)>v2);
converted = convertible.*(1-conserved); %this version assumes that converted land provides all payoff in 1st period

caseProbs = sum(regRandWgts,1);
if abs(sum(caseProbs)-1)>1e-14; keyboard; end

svcsTotal = sum(conserved.*env.*regRandWgts,1)./caseProbs; %1 x randCases vector of total svc values
valTotal = sum(converted.*v2.*regRandWgts,1)./caseProbs;

expPayoff = -(valTotal + svcsTotal +G.envQuad*svcsTotal.^2)*caseProbs';
