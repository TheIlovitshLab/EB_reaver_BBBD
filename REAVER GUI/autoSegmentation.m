function autoSegmentation(preds_dir)

    %%
%     preds_dir = dir("dataset\data_for_segmentation");
    preds_dir = dir(preds_dir);
    preds_folder = preds_dir.folder;
    
    all_preds = {preds_dir.name};
    all_preds = all_preds(:, 3:end);
    
    base_names = {};
    for n = 1:length(all_preds)
        name = strsplit(all_preds{n}, '.');
        if name{2} == 'tif'
            base_names{end+1} = name{1};
        end
    end
    
    %%
    for i = 1:length(base_names)
        base_name = base_names{i};  
        img_struct = load(strcat(preds_folder, '\', base_name, '.mat'));
        model_seg = load(strcat(preds_folder, '\', base_name, '_BW.mat'));
        
        % resize the predicted mat to image size (just to make sure)
        model_seg.pred = imresize(model_seg.pred, img_struct.imageSize);
    
        img_struct.derivedPic.BW_2 = logical(model_seg.pred);
        
        img_struct_name = strcat(preds_folder, '\', base_name, '.mat');
        model_seg_name = strcat(preds_folder, '\', base_name, '_BW.mat');
    
        % save struct and delete predicted mat file
        save(img_struct_name, '-struct', 'img_struct', 'imageDirectory', ...
            'derivedPic', 'metrics', 'constants', 'image_resolution', 'imageSize');
        delete(model_seg_name)
    end
end


