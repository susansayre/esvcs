function [condMean,condSigma] = condDist(varInds,muVec,sigmaMat,condInds,condVals)

if cond(sigmaMat(condInds,condInds))>1e15
    condMean = []; condSigma = [];
    return
end
    
basePiece = muVec(varInds)-sigmaMat(varInds,condInds)*inv(sigmaMat(condInds,condInds))*muVec(condInds);
if numel(condVals) == numel(condInds)
    try
        condMean = basePiece + sigmaMat(varInds,condInds)*inv(sigmaMat(condInds,condInds))*condVals;
    catch
        condMean = basePiece + sigmaMat(varInds,condInds)*inv(sigmaMat(condInds,condInds))*condVals;
    end
elseif size(condVals,1) == numel(condInds)
    condMean = repmat(basePiece,1,size(condVals,2))+sigmaMat(varInds,condInds)*inv(sigmaMat(condInds,condInds))*condVals;
elseif size(condVals,2) == numel(condInds)
    condMean = transpose(repmat(basePiece,1,size(condVals,1))+sigmaMat(varInds,condInds)*inv(sigmaMat(condInds,condInds))*condVals');
else
    keyboard
end

%conditional variance depends on which variables are known but does NOT
%depend on the specific values of those variables
condSigma = sigmaMat(varInds,varInds)-sigmaMat(varInds,condInds)*inv(sigmaMat(condInds,condInds))*sigmaMat(condInds,varInds);

end
