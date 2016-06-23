%creates the basic problem structure
primitives = {'pubBen' 'privCost' 'develop'}; 
drawVars = {'pubBen' 'privCost' 'develop'}; %vector of "primitive" characteristics each parcel possesses
outputs = {'epub','epriv','develop'};

C.offer1type = 'temp';

for ii=1:numel(primitives)
    eval(['C.ind.prim.' primitives{ii} ' = ii;'])
end
for ii=1:numel(drawVars)
    eval(['C.ind.draw.' drawVars{ii} ' = ii;'])
end
for ii=1:numel(outputs)
    eval(['C.ind.out.' outputs{ii} ' = ii;'])
end 

C.Adraw = eye(numel(drawVars));

C.Aout = zeros(numel(outputs),numel(primitives));

C.Aout(C.ind.out.epub,[C.ind.draw.pubBen C.ind.draw.develop]) = 1;
C.Aout(C.ind.out.epriv,C.ind.draw.privCost) = -1;
C.Aout(C.ind.out.epriv,C.ind.draw.develop) = 1;
C.Aout(C.ind.out.develop,C.ind.draw.develop) = 1;

%draw randoms
C.privRandOuts = {'privCost' 'develop'};
C.reg2ks = {'pubBen'};

for vi=1:numel(C.privRandOuts)
    C.privRandOutInds(vi) = eval(['C.ind.draw.' C.privRandOuts{vi}]);
end
for vi=1:numel(C.reg2ks)
    C.reg2kInds(vi) = eval(['C.ind.draw.' C.reg2ks{vi}]);
end

rng default
p = haltonset(numel(C.privRandOutInds),'Skip',1e3,'Leap',1e2);
p = scramble(p,'RR2');

C.stdNormalsPriv = norminv(net(p,parcelNum));

p2 = haltonset(parcelNum*numel(C.reg2ks),'Skip',1e3','Leap',1e2);
p2 = scramble(p2,'RR2');
C.stdNormalsReg = norminv(net(p2,regCasesNum))';

% %test effect of rhoBenD and rhoCostD
% rng default
% p = haltonset(1,'Skip',1e3,'Leap',1e2);
% p = scramble(p,'RR2');
% C.stdNormals1 = norminv(net(p,20));
% 
% p2 = haltonset(20,'skip',1e3,'Leap',1e2);
% p2 = scramble(p2,'RR2');
% C.stdNormals2 = norminv(net(p2,100));
% 
% p3 = haltonset(100*20,'skip',1e3,'Leap',1e2);
% p3 = scramble(p3,'RR2');
% C.stdNormals3 = norminv(net(p3,20));