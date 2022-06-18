function results_tbl = ...
    EB_analysis_entire_folder(n_px, path, normalizeRed, multidist)
% Function to iterate over a directory of images pre-processed by REAVER, with 
% Existing ".mat" analysis files, and compute EB leakage
% Input arguements:
%     n_px = width of perivascular are in pixels
%     path = path to a folder pre-processed by REAVER
%     NormalizeRed = boolean flag to determine if to normalize the red
%         intensity in the perivascular area by the red intenity inside
%     multidist = wether to perform extravasation calculation on multiple
%         distances (boolean 0/1)
% Output arguements:
%     results_tbl = table on n rows corresponding to n files in path. for
%         each file it contains all vessel segments median diameter and
%         extravasation (median red intensity in perivascular area). this
%         table alongside the n_px value is written to a mat file in the path
%         folder

    %% Predefined params
    if nargin < 4
        multidist = 0;
    end
    if nargin < 3
        normalizeRed = 0;
    end
    if nargin < 2
        path = uigetdir();
    end
    if nargin == 0
        n_px = 10;
    end
    %% Load files
    all_files = dir(fullfile(path,'*.mat'));
    summary_idx = cellfun(@(x) strcmp(x,'User Verified Table.mat'),...
        {all_files.name});
    summary = load(fullfile(path,all_files(summary_idx).name));
    data_files = all_files(~summary_idx);
    EB_analysis = cellfun(@(x) strfind(x,'EB_analysis'),{data_files.name},'UniformOutput',0);
    non_analysis = cellfun(@(x) isempty(x),EB_analysis);
    data_files = data_files(non_analysis);
    verified = summary.userVerified(cell2mat(summary.userVerified(:,2)),1);
    verified = cellfun(@(x) strrep(x,'.tif','.mat'),verified,'UniformOutput',false);
    [~,~,verified_idx] = intersect(verified',{data_files.name});
    verified_files = data_files(verified_idx);   % Get only verified files

    %% create placeholders
    n_files = numel(verified_files);
    image_name = {verified_files.name}';
    vessel_area_fraction = zeros(n_files,1);
    mean_segment_diam_um = cell(n_files,1);
    median_segment_diam_um = cell(n_files,1);
    max_segment_diam_um = cell(n_files,1);
    avg_red_px_val = cell(n_files,1);
    results_tbl = table(image_name,vessel_area_fraction,mean_segment_diam_um,...
        median_segment_diam_um,max_segment_diam_um,avg_red_px_val);
    %% Iterate over files
    parfor i = 1:n_files
        fprintf('Processing file %d of %d\n',i,numel(verified_files));
        % Calc extravasation for every segment.
        metric_st = ...
            reaver_quantify_EB(fullfile(path,verified_files(i).name),...
            n_px, normalizeRed, multidist);
        metric_st.image_name = image_name(i);
        results_tbl(i,:) = struct2table(orderfields(metric_st,[6,1,2,3,4,5]));
    end
    res = struct('table',results_tbl,'n_px',n_px);
    switch multidist
        case 1
            save(fullfile(path,['EB_analysis_upto_',num2str(n_px),'px.mat']),...
                'res');
        case 0
            save(fullfile(path,['EB_analysis_',num2str(n_px),'px.mat']),...
                'res');
    end
end