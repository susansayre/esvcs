function [expRegVal,expLandVal,period1Choice] = land1Choice(offer1,randArrayStruct,randWgtStruct,G)

%extract info about dimensions
ovCases = size(randArrayStruct.reg2,1); %number of cases representing parcels that regulator could observe in period 2
v1Cases = size(randArrayStruct.land1,1); %number of cases of different parcels making choices in period 1
colRepeats = size(randArrayStruct.land1,2)/ovCases; %tells us how many times v1 has to be repeated to get full matrix

%extract/set values that are constant over the looping
v1Land = randArrayStruct.land1(:,:,G.ind.out.v1); %should vary across rows and be constant across columns
v2Land = randArrayStruct.land1(:,:,G.ind.out.v2); %should vary across both rows and columns
choices(:,G.ind.choice.convert) = v1Land(:,1)*(1+G.payoff2Factor);
choices(:,G.ind.choice.conserve) = offer1(G.ind.offer1.perm)*(ones(size(v1Land(:,1)))+G.payoff2Factor);

%initialize rational expectations loop for landowners
period1Choice = G.ind.choice.delay*ones(v1Cases,1);
delay = repmat((period1Choice==G.ind.choice.delay)',ovCases,size(randWgtStruct.reg2,2)/v1Cases);
numChange = 10;
iter = 0;
options.showiter=1;
options.maxgen = 5000;
options.numits = 5000;
options.maxgenlast = 1000; 
maxOffer = max(randArrayStruct.reg2(:,:,G.ind.out.v2),[],2);
offerVector2 = sum(randArrayStruct.reg2(:,:,G.ind.out.v2).*randWgtStruct.reg2.*delay,2)./sum(randWgtStruct.reg2,2);

options = optimset('Display','off','MaxFunEvals',10e5);
% options.showiter = 0;
% options.tol = 1e-4;
while numChange>0
    iter = iter+1;
    period1ChoiceOld = period1Choice;
   %predict regulator choice given a set of period1 choices by landowners
    p1ChoiceMat = repmat(period1ChoiceOld',ovCases,size(randWgtStruct.reg2,2)/v1Cases);
    [test] = regObj2(offerVector2,p1ChoiceMat,randArrayStruct.reg2,randWgtStruct.reg2,G);
%     [offerVector2,fval,exf] = genetic('regObj2',[0*maxOffer maxOffer],options,p1ChoiceMat,randArrayStruct.reg2,randWgtStruct.reg2);
    [offerVector2,fval,exf] = fmincon(@(x) regObj2(x,p1ChoiceMat,randArrayStruct.reg2,randWgtStruct.reg2,G),offerVector2,[],[],[],[],0*maxOffer,maxOffer,'',options);
%     if exf<1;
%         keyboard;
%     end
    %offerVector2 is envDcases*v1Dcases*v2Dcases x 1
    %next line turns into a row vector, repeats for each v1case and then replicates for each corresponding env and v2 case 
    expOffer = repmat(offerVector2',v1Cases,colRepeats); %offerVector depends only on envD, v1D, and v2D
    valDelayCond = max(expOffer,v2Land); %landowner knows she will select the highest offer next period
    expValDelay = sum(valDelayCond.*randWgtStruct.land1,2)./sum(randWgtStruct.land1,2); %integrate out envD, v1D, v2D, v2, and env to get expectation of landowner
    %expValDelay is v1Cases x 1;
    choices(:,G.ind.choice.delay) = offer1(G.ind.offer1.temp) + G.payoff2Factor*expValDelay; 
    [expLandVal,period1Choice] = max(choices,[],2);
    numChange = numel(find(period1Choice-period1ChoiceOld));
    %fprintf('%d',numChange,'/n');
    if iter==20
%         keyboard
    end
end

p1ChoiceMat = repmat(period1Choice',ovCases,size(randWgtStruct.reg2,2)/v1Cases);

%display(['Finished inner optimization in ' num2str(iter) ' steps'])
conserve = (p1ChoiceMat==G.ind.choice.conserve);
convert = (p1ChoiceMat==G.ind.choice.convert);
delay = (p1ChoiceMat==G.ind.choice.delay);

rowProbs = sum(randWgtStruct.reg2,2);

totalSvcs1 = sum((conserve+delay).*randArrayStruct.reg2(:,:,G.ind.out.env).*randWgtStruct.reg2,1)./sum(randWgtStruct.reg2,1);
expectedEnvPayoff1 = (totalSvcs1 + G.envQuad*totalSvcs1.^2)*sum(randWgtStruct.reg2,1)';
expectedValPayoff1 = sum(sum(((convert.*randArrayStruct.reg2(:,:,G.ind.out.v1) - G.fundCostP*(G.ind.offer1.perm*conserve + G.ind.offer1.temp*delay)).*randWgtStruct.reg2)));

expRegVal = expectedValPayoff1 + expectedEnvPayoff1 - fval*G.payoff2Factor;

