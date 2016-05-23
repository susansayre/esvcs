permPay = x(:,2); tempPay = x(:,1);

%compute bounds for different choices and see if they overlap
bounds = [];
for ii=1:3
    for jj=1:size(choices,1)
        myVals = vals(jj,find(choices(jj,:)==ii));
        if any(myVals)
            myBounds(jj,1) = min(myVals);
            myBounds(jj,2) = max(myVals);
        else
            myBounds(jj,:) = [0 0];
        end
    end
    bounds = [bounds myBounds];
end

outputVars = {'sbRat', 'fval', 'firstBest','permPay','tempPay'};

for ii=1:length(compStat)
    thisVar = compStat{ii,1};
    cases = numel(compStat{ii,3});
    if cases>1
        for jj=2:cases
            val0Inds = find(valInds(:,ii)==jj-1);
            val1Inds = find(valInds(:,ii)==jj);
            figure()
            for kk = 1:numel(outputVars)
                outputName = ['diff.' outputVars{kk} '.' thisVar];
                eval([ outputName '(:,jj-1) = (' outputVars{kk} '(val1Inds) - ' outputVars{kk} '(val0Inds))./(valArray(val1Inds,ii)-valArray(val0Inds,ii));'])
                subplot(2,3,kk)
                eval(['plot(' outputName '(:,jj-1),''x'')'])
                title(outputVars{kk})
           end
         suptitle([ thisVar num2str(jj-1)])
        end
    end
end


for ii=1:length(compStat)
    compStat{ii,4} = numel(compStat{ii,3});
end

variedInds = find(cell2mat(compStat(:,4))>1);
numCases = numel(variedInds);
if numCases>4; break; end

for ii=1:numCases %each variable creates pages once
    pageVarInd = variedInds(ii);
    pageVar = compStat{pageVarInd,1};
    for pp=1:compStat{pageVarInd,4} %figure out which page we're 
        thisPageInds = find(valInds(:,pageVarInd)==pp); %rows of output that could go on this page.
        for jj=1:numCases %each variable will be a row variable for one set of pages for every page variable
            if jj==ii; continue; end; %don't treat the page var as a row var
            rowVarInd = variedInds(jj);
            rowVar = compStat{rowVarInd,1};
            numRows = compStat{rowVarInd,4};
            for kk=1:numCases 
                if kk==ii || kk==jj; continue; end; %don't treat page or row var as col var
                colVarInd = variedInds(kk);
                colVar = compStat{colVarInd,1};
                numCols = compStat{colVarInd,4};
                numCheck = 0;
                for ll=1:numCases 
                    if ll==ii || ll==jj || ll==kk; continue; end %don't treat page, row or col var as series var, I should get past this only once
                    if numCheck; display('I should not be here'); keyboard; end
                    numCheck = numCheck+1;
                    serVarInd = variedInds(ll);
                    serVar = compStat{serVarInd,1};
                    numSeries = compStat{serVarInd,4};                    
                    %page type is determined, now we start to create figure
                    valFig = figure();
                    suptitle([pageVar ' = ' num2str(valArray(thisPageInds(1),pageVarInd)) ', seriesVar=' serVar])                
                   for ri = 1:numRows
                        thesePRinds = intersect(thisPageInds,find(valInds(:,rowVarInd)==ri));
                        for ci = 1:numCols
                            thesePRCinds = intersect(thesePRinds,find(valInds(:,colVarInd)==ci));
                            subplot(numRows,numCols,ci+(ri-1)*numCols)
                            title([rowVar '=' num2str(valArray(thesePRCinds(1),rowVarInd)) ', ' colVar '=' num2str(valArray(thesePRCinds(1),colVarInd))])
                            hold on;
                            for si = 1:numSeries
                                finalInds = intersect(thesePRCinds,find(valInds(:,serVarInd)==si));
                                plot(vals(finalInds,:),vals(finalInds,:)-delta*expectedPayoffs(finalInds,:))
                                legendNames{si} = [serVar '=' num2str(valArray(finalInds(1),serVarInd))];
                            end
                            axis([0 20 -10 10])
                        end
                    end
                end
                saveas(gcf,fullfile(outputPath,['diffs' rowVar '_x_' colVar '_by_' pageVar '_' num2str(pp)]),'epsc')
            end
        end
    end
end
    