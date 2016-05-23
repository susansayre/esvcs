%creates the basic problem structure
primitives = {'de','dv','dvc','rv','rvc','const'}; %vector of "primitive" characteristics each parcel possesses
outputs = {'v1','vc','vd2','v2','env','rvt','dvt'}; %vector of payoff relevant characterisitics each parcel posses
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
