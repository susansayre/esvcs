%extract values -- constant for a parameter set
%developP1

plotOrder = {'na' 'ni' 'l' 'pi'};
compareCases = {7 43 79};

myPlots = [];
for ii=1:numel(plotOrder)
    thisCase = plotOrder{ii};
    for jj=1:numel(compareCases)
        thisInd = compareCases{jj};
        eval(['thisCondChoice = condChoices_' thisCase '(thisInd,:,:);'])
        meanPubBen = squeeze(mean(gainFull(thisInd,:,2:end,1),3));
        privCost = squeeze(gainFull(thisInd,:,1,2));
        
        corr(meanPubBen',privCost')
        if strcmp(thisCase,'pi');
            eval(['thisP1C = period1Choice_' thisCase '(thisInd,:,:);'])              
            condChoiceLong = (reshape(thisP1C==C.ind.choice.delay,numel(thisP1C),1).*reshape(thisCondChoice,numel(thisCondChoice),1)) + reshape((thisP1C~=C.ind.choice.delay).*thisP1C,numel(thisP1C),1);
            probConserve2 = mean(squeeze(reshape(condChoiceLong==C.ind.choice.conserve,size(thisCondChoice))),2);
            develop1Cases = [];
        else
            eval(['thisP1C = period1Choice_' thisCase '(thisInd,:);'])

            develop1Cases = find(thisP1C==C.ind.choice.convert);
            if numel(thisCondChoice)==numel(privCost)
                probConserve2 = (thisCondChoice==C.ind.choice.conserve);
            else
                probConserve2 = squeeze(mean(thisCondChoice==C.ind.choice.conserve,3));
            end
        end

        if any(thisP1C==C.ind.choice.conserve)
            keyboard
        end

        %mightConserve = find(probConserve2>0);
        %keyboard
        
         %if strcmp(thisCase,'na'); keyboard; end;
        thisPlot = subplot(numel(compareCases),numel(plotOrder),(jj-1)*numel(plotOrder)+ii);
        myPlots = [myPlots thisPlot];
        thisMap = colormap;
        %plot points using probConserve2 to index color
        pointSize = 10;
        scatter(privCost,meanPubBen,pointSize,probConserve2,'filled');
        hold on;
%        scatter(privCost(develop1Cases),meanPubBen(develop1Cases),pointSize,thisMap(end,:),'filled')
        set(gca,'XTick',[0],'YTick',[0])
        grid on
        caxis([0 1])
        storedProb(:,ii,jj) = probConserve2;
    end
    
end

linkaxes(myPlots,'xy')
