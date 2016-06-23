close all
plotOrder = {'na' 'ni' 'l' 'pi'};
compareCases = (1:108);

%extract and store info
for ii=1:numel(plotOrder)
    thisCase = plotOrder{ii};
    for jj=1:numel(compareCases)
        thisInd = compareCases(jj);
        eval(['thisCondChoice = squeeze(condChoices_' thisCase '(thisInd,:,:));'])
        if size(thisCondChoice,1) == 1
            maxInd = 1;
        else
            maxInd = size(thisCondChoice,2);
        end
        eval(['condChoices(:,1:maxInd,ii,jj) = condChoices_' thisCase '(thisInd,:,:);'])
        meanPubBen(:,jj) = squeeze(mean(gainFull(thisInd,:,2:end,1),3))';
        privCost(:,jj) = squeeze(gainFull(thisInd,:,1,2))';
        eval(['expRegVals(jj,ii) = expRegVal_' thisCase '(thisInd);'])
        if strcmp(thisCase,'pi');
            eval(['thisP1C = period1Choice_' thisCase '(thisInd,:,:);'])
            condChoiceLong = (reshape(thisP1C==C.ind.choice.delay,numel(thisP1C),1).*reshape(thisCondChoice,numel(thisCondChoice),1)) + reshape((thisP1C~=C.ind.choice.delay).*thisP1C,numel(thisP1C),1);
            probConserve2(:,ii,jj) = mean(squeeze(reshape(condChoiceLong==C.ind.choice.conserve,size(thisCondChoice))),2)';
            develop1Cases{ii,jj} = [];
            meanOffer1(jj,ii) = mean(mean(squeeze(piOffer(thisInd,:,:))));
        else
            eval(['thisP1C = period1Choice_' thisCase '(thisInd,:);'])
            if ~strcmp(thisCase,'na')
                eval(['meanOffer1(jj,ii) = ' thisCase 'Offer(jj);'])
            end
            develop1Cases{ii,jj} = find(thisP1C==C.ind.choice.convert);
            if numel(thisCondChoice)==numel(privCost(:,jj))
                probConserve2(:,ii,jj) = (thisCondChoice==C.ind.choice.conserve);
            else
                probConserve2(:,ii,jj) = squeeze(mean(thisCondChoice==C.ind.choice.conserve,2));
           
            end
        end
    end
end 

meanProbs = squeeze(mean(probConserve2,2));

maxPrivCost = max(max(privCost));
minPrivCost = min(min(privCost));
maxMeanPubBen = max(max(meanPubBen));
minMeanPubBen = min(min(meanPubBen));

axisLims = [floor(minPrivCost) ceil(maxPrivCost) floor(minMeanPubBen) ceil(maxMeanPubBen)];

minRegVal = floor(min(min(expRegVals/195-10)));
maxRegVal = ceil(max(max(expRegVals/195-10)));

minOffer = floor(min(min(meanOffer1)));
maxOffer = ceil(max(max(meanOffer1)));

myPlots = [];
graySet = .7*[1 1 1];

for ii=1:size(meanProbs,2)
%for ii=1:1
    titleString = ['\mu_{e} = ' num2str(pubBenStd(ii)) ', \mu_{d} = ' num2str(privCostStd(ii)) ', \Sigma_{ee} = ' num2str(pubBenVarRat(ii)) ', \Sigma_{dd} = ' num2str(privCostVarRat(ii)) ', \Sigma_{ed} = ' num2str(rhoBenCost(ii))];
    neverConserved = find(meanProbs(:,ii)==0);
    alwaysConserved = find(meanProbs(:,ii)==1);
    percentcAll = numel(alwaysConserved);
    conservedNi = setxor(find(probConserve2(:,2,ii)==1),alwaysConserved);
    if any(conservedNi)
        maxcNiVal = max(privCost(conservedNi,ii));
        belowMax = find(privCost(:,ii)<=maxcNiVal);
        percentcNi = numel(belowMax);
        if any(probConserve2(belowMax,2,ii)<1); keyboard; end;
    else
        maxcNiVal = max(privCost(alwaysConserved,ii));
        percentcNi = percentcAll;
    end
    everConservedL = setxor(find(probConserve2(:,3,ii)>0),alwaysConserved);
    everConservedPi = setxor(find(probConserve2(:,4,ii)>0),alwaysConserved);
    ecPiNotL = setxor(everConservedL,everConservedPi);    
    thisPlot = figure();
    colormap(thisPlot,myMap)
    myPlots = [myPlots thisPlot];
    %plot points using probConserve2 to index color
    pointSize = 50;
    hold on;
    scatter(privCost(neverConserved,ii),meanPubBen(neverConserved,ii),pointSize,graySet,'Marker','o');
    scatter(privCost(alwaysConserved,ii),meanPubBen(alwaysConserved,ii),pointSize,graySet,'filled','Marker','o'); 
    scatter(privCost(everConservedPi,ii),meanPubBen(everConservedPi,ii),1.5*pointSize,probConserve2(everConservedPi,4,ii),'LineWidth',2,'Marker','o');
    scatter(privCost(everConservedL,ii),meanPubBen(everConservedL,ii),pointSize,probConserve2(everConservedL,3,ii),'filled','Marker','o');
%    scatter(privCost(ecPiNotL),meanPubBen(ecPiNotL,ii),.5*pointSize,'white','filled','Marker','o');
    %scatter(privCost(conservedNi),meanPubBen(conservedNi),.2*pointSize,'black','Marker','x');
    %        scatter(privCost(develop1Cases),meanPubBen(develop1Cases),pointSize,thisMap(end,:),'filled')
    axis(axisLims)
    title(titleString)
    ylabel('Public Benefit of Conservation')
    xlabel('Private Benefit of Development')
    set(gca,'XTick',[axisLims(1) 0 axisLims(2)],'YTick',[axisLims(3) 0 axisLims(4)])
    grid on
    caxis([0 1])
    cbar = colorbar;
    cbar.Label.String = 'Probability Conserved';
    line([maxcNiVal maxcNiVal],axisLims(3:4),'Color',graySet,'LineStyle','--')
    niTextHeight = .75*axisLims(4)*(rhoBenCost(ii)<=0) + .5*axisLims(3)*(rhoBenCost(ii)>0);
    naTextHeight = .9*axisLims(4);
    text(maxcNiVal,niTextHeight,{'\leftarrow Max d_{i} conserved'; ['      w/ no info (' num2str(percentcNi) '%)']})
    text(-2.9,naTextHeight,[ num2str(percentcAll) '% always conserved'])
    eval(['saveas(myPlots(ii),fullfile(outputPath,''graphs'',''conserveScatter_case' num2str(ii) '''),''epsc'');'])
    %close
    
    figure()
    bar(expRegVals(ii,:)/195-10)
    title(titleString)
    thisAxis = axis;
    thisAxis(3) = minRegVal;
    thisAxis(4) = maxRegVal;
    ylabel('Mean Expected Public Benefit')
    set(gca,'XTickLabels',{'No Action' 'No Info' 'Learning' 'Perfect Info'})
    eval(['saveas(gcf,fullfile(outputPath,''graphs'',''regPayRaw_case' num2str(ii) '''),''epsc'');'])
    axis(thisAxis);
    eval(['saveas(gcf,fullfile(outputPath,''graphs'',''regPayScaled_case' num2str(ii) '''),''epsc'');'])
   
    figure()
    bar(meanOffer1(ii,:))
    thisAxis = axis;
    thisAxis(3) = minOffer;
    thisAxis(4) = maxOffer;
    title(titleString)
    ylabel('Mean Period 1 Offer')
    set(gca,'XTickLabels',{'No Action' 'No Info' 'Learning' 'Perfect Info'})
    eval(['saveas(gcf,fullfile(outputPath,''graphs'',''offerRaw_case' num2str(ii) '''),''epsc'');'])
    axis(thisAxis);
    eval(['saveas(gcf,fullfile(outputPath,''graphs'',''offerScaled_case' num2str(ii) '''),''epsc'');'])
    close all
end