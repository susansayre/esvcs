%creates the basic problem structure
primitives = {'de','dv','dvc','rv','rvc','re','const'}; %vector of "primitive" characteristics each parcel possesses
outputs = {'v1','v2','env','envD','v1D','v2D'}; %vector of payoff relevant characterisitics each parcel posses, %critical that v1 is first
%outputs = A*prim;

%create indicator variables for primitives, outputs, and "big" which is
%primitives stacked below outputs

for ii=1:numel(outputs)
    eval(['G.ind.out.' outputs{ii} ' = ii;'])
end

G.ind.big = G.ind.out;

for ii=1:numel(primitives)
    eval(['G.ind.prim.' primitives{ii} ' = ii;'])
    eval(['G.ind.big.' primitives{ii} ' = numel(outputs) + ii;'])
end

%landowner time 2 knows everything but re
G.decisionMakers = {'land1' 'land2' 'reg1' 'reg2'};
G.land2.knowns = {'v1' 'v2' 'envD' 'v1D' 'v2D'};
G.land2.unknowns = {'env'};

G.land1.knowns = {'v1'};
G.land1.unknowns = {'envD' 'v1D' 'v2D' 'v2' 'env'}; %note: very important that first three elements are in same order as reg2knowns

G.reg1.knowns = {};
G.reg1.unknowns = outputs;

G.reg2.knowns = {'envD' 'v1D' 'v2D'};
G.reg2.unknowns = {'v1' 'v2' 'env'}; %note: very important that first element is v1;

for di=1:numel(G.decisionMakers);
    thisDecisionMaker = G.decisionMakers{di};
    theseKnowns = eval(['G.' thisDecisionMaker '.knowns']);
    theseUnknowns = eval(['G.' thisDecisionMaker '.unknowns']);
    eval(['G.' thisDecisionMaker '.knownInds = [];'])
    eval(['G.' thisDecisionMaker '.unknownInds = [];'])
    for ki=1:numel(theseKnowns)
        eval(['G.' thisDecisionMaker '.knownInds(ki) = G.ind.out.' theseKnowns{ki} ';'])
    end
    for ui=1:numel(theseUnknowns)
        eval(['G.' thisDecisionMaker '.unknownInds(ui) = G.ind.out.' theseUnknowns{ui} ';'])
    end
end
  