function expVal = expVal2(v1,muVec,sigmaMat)
global G

[condMean,condSigma] = condDist([G.ind.big.env,G.ind.big.v2],muVec,sigmaMat,G.ind.big.v1,v1);

if isempty(condMean)
    expVal = [];
    return
end

if condSigma(2,2) == 0;
    [vals,weights] = qnwnorm(5,0,condSigma(1,1));
    vals = [vals, 0*vals];
else
    [vals,weights] = qnwnorm([5,5],[0 0],condSigma);
end

v2 = repmat(vals(:,2)',length(v1),1) + repmat(condMean(:,2),1,size(vals,1));
env = repmat(vals(:,1)',length(v1),1) + repmat(condMean(:,1),1,size(vals,1));
maxVal = max(v2,env);

[esorted,esortInd] = sort(env,2);
[msorted,msortInd] = sort(maxVal,2);
for ii=1:length(v1); 
    esortWeight(ii,:) = weights(esortInd(ii,:));
    msortWeight(ii,:) = weights(msortInd(ii,:));
%    vsortWeight(ii,:) = weights(vsortInd(ii,:));
end;
esortF = cumsum(esortWeight,2);
msortF = cumsum(msortWeight,2);

[eLBP,eLBInd] = min(abs(esortF-.05),[],2);
[eUBP,eUBInd] = min(abs(esortF-.95),[],2);
[mLBP,mLBInd] = min(abs(msortF-.05),[],2);
[mUBP,mUBInd] = min(abs(msortF-.95),[],2);

for ii=1:length(v1); 
   envLB(ii) = esorted(ii,eLBInd(ii));
   envUB(ii) = esorted(ii,eUBInd(ii));
   maxLB(ii) = msorted(ii,mLBInd(ii));
   maxUB(ii) = msorted(ii,mUBInd(ii));
end

figure()
plot(v1,maxVal*weights,'b');
hold on;
plot(v1,maxLB,'r')
plot(v1,maxUB,'g')

convert = v2>env;
expVal = (v2.*convert + (1-convert).*env)*weights;



