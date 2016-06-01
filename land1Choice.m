function [expRegVal,expLandVal,choice] = land1Choice(offer1,randArrayStruct,randWgtStruct)

global G

delay = ones(size(randWgtStruct.reg2));
numChange = 10;
iter = 0;
options.showiter=1;
options.maxgen = 10000;
options.numits = 10000;
options.maxgenlast = 1000; 
maxOffer = max(randArrayStruct.reg2(:,:,G.ind.out.v2),[],2);
offerVector2 = sum(randArrayStruct.reg2(:,:,G.ind.out.v2).*randWgtStruct.reg2.*delay,2)./sum(randWgtStruct.reg2,2);
options = optimset('Display','off');
while numChange>0
    iter = iter+1;
    convertible = delay;
   %predict regulator choice given convertible decisions
%    [offerVector2,fvalg,exfg,results] = genetic('regObj2',[0*maxOffer maxOffer],options,convertible,randArrayStruct.reg2,randWgtStruct.reg2);
    
    [offerVector2,fval,exf] = fmincon(@(x) regObj2(x,convertible,randArrayStruct.reg2,randWgtStruct.reg2),offerVector2,[],[],[],[],0*maxOffer,maxOffer,'',options);
    if exf<0;
        keyboard;
    end
    %offerVector2 is envDcases*v1Dcases*v2Dcases x 1

    v1 = randArrayStruct.land1(:,:,G.ind.out.v1); %should vary across rows and be constant across columns
    v2 = randArrayStruct.land1(:,:,G.ind.out.v2); %should vary across both rows and columns

    %given land1 info, v1 and v2 are both v1cases x envD*v1D*v2D*v2*env cases
    ovCases = size(offerVector2,1); v1Cases = size(v1,1); colRepeats = size(v1,2)/ovCases;
    expOffer = repmat(offerVector2',v1Cases,colRepeats); %offerVector depends only on envD, v1D, and v2D
    valDelayCond = max(expOffer,v2);
    expValDelay = sum(valDelayCond.*randWgtStruct.land1,2)./sum(randWgtStruct.land1,2); %integrate out envD, v1D, v2D, v2, and env
    %expValDelay is v1Cases x 1;

    [expLandVal,choice] = max([v1(:,1) offer1(G.ind.offer1.perm)*ones(size(v1(:,1))) offer1(G.ind.offer1.temp)+G.discount*expValDelay],[],2);
    choiceReg2Mat = repmat(choice',ovCases,size(randWgtStruct.reg2,2)/v1Cases);
    
    delay = (choiceReg2Mat==3);
    numChange = numel(find(convertible-delay));
    %fprintf('%d',numChange,'/n');
    if iter==20
        keyboard
    end
end

%display(['Finished inner optimization in ' num2str(iter) ' steps'])
conserve = (choiceReg2Mat==2);
convert = (choiceReg2Mat==1);

rowProbs = sum(randWgtStruct.reg2,2);

totalSvcs1 = sum(delay.*randArrayStruct.reg2(:,:,G.ind.out.env).*randWgtStruct.reg2,1)./sum(randWgtStruct.reg2,1);
totalPayoff1 = (1-G.discount)*(totalSvcs1 + G.envQuad*totalSvcs1.^2)*sum(randWgtStruct.reg2,1)';

expRegVal = rowProbs'*(-G.discount*fval + sum((convert.*randArrayStruct.reg2(:,:,G.ind.out.v1) + conserve.*randArrayStruct.reg2(:,:,G.ind.out.env)).*randWgtStruct.reg2,2));
expRegVal = expRegVal + totalPayoff1;

    
