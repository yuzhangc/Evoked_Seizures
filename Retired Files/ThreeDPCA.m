% 3D PCA With Output Array
    for sz = 1:length(output_array)
    pca3D_output(:,:,sz) = output_array{sz};
    end

    % Permute So that Output is Time
    pca3D_output = permute(pca3D_output,[2,3,1]);

    % Hyperspace PCA - Uses image like processing and then rescale
    [outputDataCube,coeff,var] = hyperpca(pca3D_output,6);
    newDataCube = rescale(outputDataCube,0,1);
    
    % Plot PCAs (This is currently over ALL seizures, not time, so is like principal seizure? before permutation)
    figure
    montage(newDataCube,'BorderSize',[10 10],'Size',[1 6]);

    % Unfortunately this is a plot of which seizure is represented in PC
    % space not seizure by time.
    figure
    plot(coeff);