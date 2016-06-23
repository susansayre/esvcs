function  [piOffer,piVal,piExf,expLandVal,optOffers,period1Choice,condChoices] = piSolve(doTheseValues,thisGainArray,G,thisCase,options);

    for jj=1:size(doTheseValues,2)
        thisID = [thisCase '_' num2str(jj) 'pi'];
        thisOffer0 = 1.1*(thisGainArray(:,jj,3)>0).*thisGainArray(:,jj,2);
        theseValues = doTheseValues(:,jj,:);
        theseGains = thisGainArray(:,jj,:);
        testpi = land1Choice(thisOffer0,theseValues,theseGains,G,'pi',thisID);
        disp(['starting pi solve ' thisCase ', jj=' num2str(jj) ])
        [piOffer(:,jj),~,piExf(:,jj)] = fmincon(@(x) -land1Choice(x,theseValues,theseGains,G,'pi'),thisOffer0,[],[],[],[],0*thisOffer0,Inf+thisOffer0,'',options);
        [piVal(:,jj),expLandVal(:,jj),optOffers(:,jj),period1Choice(:,jj),condChoices(:,jj)] = land1Choice(piOffer(:,jj),theseValues,theseGains,G,'pi');

    end
