for ii=1:108
    if skippedCase(ii)
        continue
    end
    load(fullfile(outputPath,['case' num2str(ii)]),'allValuesArray','gainArray')
    allValuesFull(ii,:,:,:) = allValuesArray;
    gainFull(ii,:,:,:) = gainArray;
end

save(fullfile(outputPath,'fullResults'))