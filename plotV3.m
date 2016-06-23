close all
plotOrder = {'na' 'ni' 'l' 'pi'};
compareCases = (1:108);

%extract and store info
for ii=1:numel(plotOrder)
    thisCase = plotOrder{ii};
    for jj=1:numel(compareCases)
        thisInd = compareCases(jj);
        pubBen(:,jj) = reshape(gainFull(thisInd,:,2:end,1),100^2,1);
        privCost(:,jj) = reshape(gainFull(thisInd,:,2:end,2),100^2,1);
        switch thisCase
            case 'l'
                conserved(:,ii,jj) = reshape(condChoices_l(thisInd,:,:)==C.ind.choice.conserve,100^2,1);
                delayed(:,ii,jj) = repmat(period1Choice_l(thisInd,:)'==C.ind.choice.delay,100,1);
            case 'pi'
                conserved(:,ii,jj) = (pubBen(:,jj)>max(0,privCost(:,jj)))+(privCost(:,jj)<0);
                delayed(:,ii,jj) = conserved(:,ii,jj);
            otherwise
                %parcels do the same thing in both periods
                eval(['conserved(:,ii,jj) = repmat(period1Choice_' thisCase '(thisInd,:)''==C.ind.choice.delay,100,1);'])
                delayed(:,ii,jj) = conserved(:,ii,jj);
        end
    end
end


maxPrivCost = max(max(privCost));
minPrivCost = min(min(privCost));
maxMeanPubBen = max(max(pubBen));
minMeanPubBen = min(min(pubBen));

axisLims = [floor(minPrivCost) ceil(maxPrivCost) floor(minMeanPubBen) ceil(maxMeanPubBen)];

graySet = .8*[1 1 1];

for ii=1:108
%for ii=1:1
    titleString = ['\mu_{e} = ' num2str(pubBenStd(ii)) ', \mu_{d} = ' num2str(privCostStd(ii)) ', \Sigma_{ee} = ' num2str(pubBenVarRat(ii)) ', \Sigma_{dd} = ' num2str(privCostVarRat(ii)) ', \Sigma_{ed} = ' num2str(rhoBenCost(ii))];
    neverConserved = find(sum(conserved(:,:,ii),2)==0);
    alwaysConserved = find(sum(conserved(:,:,ii),2)==4);
    percentcAll = round(numel(alwaysConserved)/100);
    conservedNi = setxor(find(conserved(:,2,ii)),alwaysConserved);
    if any(conservedNi)
        maxcNiVal = max(privCost(conservedNi,ii));
        belowMax = find(privCost(:,ii)<=maxcNiVal);
        percentcNi = numel(belowMax)/100;
    else
        maxcNiVal = max(privCost(alwaysConserved,ii));
        percentcNi = percentcAll;
    end
    conservedL = setxor(find(conserved(:,3,ii)),alwaysConserved);
    percentcL = numel(find(period1Choice_l(ii,:)==C.ind.choice.delay));
    conservedLNi = setxor(find(sum(conserved(:,2:3,ii),2)==2),alwaysConserved);
    conservedLnotNi = setxor(conservedL,conservedLNi);
    conservedNiNotL = setxor(conservedNi,conservedLNi);
    conservedPi = intersect(find(conserved(:,4,ii)),find(sum(conserved(:,1:3,ii),2)==0));
    pointSize = 3;
    hold on;
    darkGreen = .25*[0 1 0];
    lightGreen = .5*[0 1 0];
    vlGreen = .75*[0 1 0];
    plot(privCost(alwaysConserved,ii),pubBen(alwaysConserved,ii),'x','MarkerFace',.5*graySet,'MarkerEdge',.5*graySet,'MarkerSize',.5*pointSize); 
    plot(privCost(conservedLNi,ii),pubBen(conservedLNi,ii),'gd','MarkerSize',pointSize);
    plot(privCost(conservedNiNotL,ii),pubBen(conservedNiNotL,ii),'bo','MarkerSize',pointSize);
    plot(privCost(conservedLnotNi,ii),pubBen(conservedLnotNi,ii),'kd','MarkerEdge','k','MarkerSize',pointSize);
    plot(privCost(conservedPi,ii),pubBen(conservedPi,ii),'cd','MarkerSize',pointSize);
    plot(privCost(neverConserved,ii),pubBen(neverConserved,ii),'d','MarkerEdge',graySet,'MarkerSize',.5*pointSize);
    axis(axisLims)
    title(titleString)
    ylabel('Public Benefit of Conservation')
    xlabel('Private Benefit of Development')
    set(gca,'XTick',[axisLims(1) 0 axisLims(2)],'YTick',[axisLims(3) 0 axisLims(4)])
    grid on
    line(niOffer(ii)*[1 1],axisLims(3:4),'Color',graySet,'LineStyle','--')
    line(lOffer(ii)*[1 1],axisLims(3:4),'Color',lightGreen,'LineStyle',':')
%    line([0 axisLims(2)],[0 axisLims(4)],'Color','black','LineStyle','--')
    niTextHeight = .9*axisLims(4);
    naTextHeight = .9*axisLims(4);
    lTextHeight = .9*axisLims(3);
    text(niOffer(ii),niTextHeight,['\leftarrow No info offer (' num2str(percentcNi) '% Accept)'])
    text(lOffer(ii),lTextHeight,['\leftarrow Learning offer (' num2str(percentcL) '% Accept)'])
    text(-2.9,naTextHeight,[ num2str(percentcAll) '% always conserved'])
    eval(['saveas(gcf,fullfile(outputPath,''graphs'',''allScatter' num2str(ii) '''),''epsc'');'])
    close
    
end