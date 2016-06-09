function [dmRandArray,dmRandWgts] = dmInfo(dmIDStruct,randArray,randWgt)
%generate decision-maker time specific randomizations
%step 1: reorder the random array so that everything the decision maker knows comes first and the things they don't know
%follow
%step 2: reshape the large array into a smaller array knownCases x unknownCases x vars

randArraySize = size(randArray);
kNum = prod(randArraySize(dmIDStruct.knownInds));
uNum = prod(randArraySize(dmIDStruct.unknownInds));

order = [dmIDStruct.knownInds dmIDStruct.unknownInds];

dmRandArray = reshape(permute(randArray,[order numel(randArraySize)]),[kNum uNum randArraySize(end)]);
dmRandWgts = reshape(permute(randWgt,order),kNum,uNum);
