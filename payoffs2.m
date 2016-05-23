function [payoff,converted] = payoffs2(offerVector,parcelCharMat,flag)

%returns the regulator's payoff as a function of the vector of offers made
%to particular parcels

v2 = ; %economic values if converted
env = ; %contribution to svc level if conserved

conserved = offerVector>v2;
converted = 1-conserved;

switch flag
    case 'l'
        %landowner payoff
        payoff = converted.*v2 + conserved.*offerVector;
    case 'r'
        %regulator payoff;
        payoff = (converted.*v2 + conserved.*env)*weights;
    otherwise
        error(['Invalid flag ' flag ])
end
