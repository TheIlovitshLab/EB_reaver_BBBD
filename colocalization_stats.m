function R = colocalization_stats(path)
% Function to extract the pearson 2d correlation and the manders
% coefficient between red and green channel of all images in the folder.
% Binarizatoin done automatically with otsus' algorithm.
    all_files = dir(fullfile(path,'*.mat'));
    summary_idx = cellfun(@(x) strcmp(x,'User Verified Table.mat'),...
        {all_files.name});

    summary = load(fullfile(path,all_files(summary_idx).name));
    data_files = all_files(~summary_idx);
    EB_analysis = cellfun(@(x) strfind(x,'EB_analysis'),{data_files.name},'UniformOutput',0);
    EB_analysis = cellfun(@(x) isempty(x),EB_analysis);
    data_files = data_files(EB_analysis);
    verified_files = data_files(cell2mat(summary.userVerified(:,2)));   % Get only verified files

    R = zeros(1,numel(verified_files));
    M_r = R;

    for i = 1:numel(verified_files)
       name = verified_files(i).name;
       im = [];
       for ch = 1:2
           im = cat(3,im,imread(fullfile(path,[name(1:end-3),'tif']),ch));
       end
       red = im2double(im(:,:,1));
       green = im2double(im(:,:,2));
       R(i) = corr2(red,green);
    end
end