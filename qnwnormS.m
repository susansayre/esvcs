% QNWNORMS Computes nodes and weights for multivariate normal distribution
% by drawing on a pre-saved array for a standard mv normal distribution
% The pre-saved matrix can be created using qnwnorm from the compecon toolbox
%USAGE
%   [x,w] = qnwnorm(n,mu,var,usesqrtm);
% INPUTS
%   n   : 1 by d vector of number of nodes for each variable
%   mu  : 1 by d mean vector
%   var : d by d positive definite covariance matrix
%   usesqrtm: (optional) 0/1 if 1 uses sqrtm to factorize var rather than chol
%                sqrtm produces a symmetric set of nodes that are
%                invariant to reordering. defaults to chol
% OUTPUTS
%   x   : prod(n) by d matrix of evaluation nodes
%   w   : prod(n) by 1 vector of probabilities
% 
% To compute expectation of f(x), where x is N(mu,var), write a
% function f that returns m-vector of values when passed an m by d
% matrix, and write [x,w]=qnwnorm(n,mu,var); E[f]=w'*f(x);


function [x,w] = qnwnormS(n,mu,var)
usesqrtm = optget('qnwnorm','usesqrtm',0);

if unique(n)~=n
    error('Have not coded different num nodes yet.')
end

d = length(n); num = n(1);
if nargin<3, var=eye(d); end
if nargin<2, mu=zeros(1,d); end
if size(mu,1)>1, mu=mu'; end

try
    load(['qnNormMat_' num2str(d) 'vars_' num2str(num) 'nodes']);
catch
    error(['Have not saved a matrix for ' num2str(d) ' vars and ' num2str(num) ' nodes yet.'])
end

if usesqrtm
  x = x*sqrtm(var)+mu(ones(prod(n),1),:);
else
  x = x*chol(var)+mu(ones(prod(n),1),:);
end
