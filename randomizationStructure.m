%creates the basic problem structure
primitives = {'epub' 'epriv' 'vpub' 'vpriv'}; %vector of "primitive" characteristics each parcel possesses
outputs = {'epub' 'epriv' 'vpub' 'vpriv' 'vpub2' 'vpriv2'}; %vector of payoff relevant characterisitics each parcel possesses

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