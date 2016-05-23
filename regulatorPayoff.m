function [payoff,landPayoff,choice] = regulatorPayoff(x,v1,delta,expectedPayoff,svcsCondMean,v1Wgt)

    if ~exist('v1Wgt')
        v1Wgt = 1/numel(v1)*ones(size(v1));
    end
    choices = [v1 x(1)+delta*expectedPayoff x(2)*ones(size(expectedPayoff))];
    [landPayoff,choice] = max(choices,[],2);
    payoff = -((choice==1).*v1 + (choice==2).*((1-delta)*svcsCondMean+delta*expectedPayoff)+(choice==3).*svcsCondMean)'*v1Wgt;
    
%     convert = v1(find(choice==1));
%     conserve = v1(find(choice==3));
%     delay = v1(find(choice==2));
%     
%     if any(convert)
%         if any(conserve)
%             if any(delay)
%                 type='All';
%                 
%                 [thresholds,sortOrder] = sort([min(convert) max(convert) min(conserve) max(conserve) min(delay) max(delay)]);
%                 
%                 if sortOrder == [1 2 3 4 5 6]
%                     overlap = 'N';
%                     order = 'convert, conserve, delay';
%                 elseif sortOrder == [1 2 5 6 3 4]
%                     overlap = 'N';
%                     order = 'convert, delay, conserve';
%                 elseif sortOrder == [3 4 1 2 5 6]
%                     overlap = 'N';
%                     order = 'conserve, convert, delay';
%                 elseif sortOrder == [3 4 5 6 1 2]
%                     overlap = 'N';
%                     order = 'conserve, delay, convert';
%                 elseif sortOrder == [5 6 1 2 3 4]
%                     overlap = 'N';
%                     order = 'delay, convert, conserve';
%                 elseif sortOrder == [5 6 3 4 1 2];
%                     overlap = 'N';
%                     order = 'delay, conserve, convert';
%                 else
%                     overlap = 'Y';
%                     order = '?';
%                 end
%             else
%                 type = 'conv,cons';
%                 [thresholds,sortOrder] = sort([min(convert) max(convert) min(conserve) max(conserve)]);
%                 
%                 if sortOrder == [1 2 3 4]
%                     overlap = 'N';
%                     order = 'convert, conserve';
%                 elseif sortOrder == [3 4 1 2]
%                     overlap = 'N';
%                     order = 'conserve, convert';
%                 else
%                     overlap = 'Y';
%                     order = '?';
%                 end
%             end
%         elseif any(delay)
%                 type = 'conv,delay';
%                 [thresholds,sortOrder] = sort([min(convert) max(convert) min(delay) max(delay)]);
%                 
%                 if sortOrder == [1 2 3 4]
%                     overlap = 'N';
%                     order = 'convert, delay';
%                 elseif sortOrder == [3 4 1 2]
%                     overlap = 'N';
%                     order = 'delay, convert';
%                 else
%                     overlap = 'Y';
%                     order = '?';
%                 end
%         else
%             type = 'convert';
%             overlap = 'N';
%             order = 'NA';
%         end
%     elseif any(conserve)
%         if any(delay)
%                 type = 'cons,delay';
%                 [thresholds,sortOrder] = sort([min(conserve) max(conserve) min(delay) max(delay)]);
%                 
%                 if sortOrder == [1 2 3 4]
%                     overlap = 'N';
%                     order = 'conserve, delay';
%                 elseif sortOrder == [3 4 1 2]
%                     overlap = 'N';
%                     order = 'delay, conserve';
%                 else
%                     overlap = 'Y';
%                     order = '?';
%                 end
%         else
%             type = 'conserve';
%             overlap = 'N';
%             order = 'NA';
%         end
%     elseif any(delay)
%         type = 'delay';
%         overlap = 'N';
%         order = 'NA';
%     else
%         error('How can I have no choice?')
%     end
%     
%    if overlap == 'Y'
%         keyboard
%    end
           
               
                    
         