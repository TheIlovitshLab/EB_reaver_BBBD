%{
This script takes a directory of images pre-processed by REAVER, with 
Existing ".mat" analysis files, and computes EB leakage
%}
%% Take care of dependencies
% run DEV_INITIALIZE.m
%% Predefined params
if ~exist('n_px','var')
    n_px = 10;
end
%% Load files
path = uigetdir();
all_files = dir(fullfile(path,'*.mat'));
summary_idx = cellfun(@(x) strcmp(x,'User Verified Table.mat'),...
    {all_files.name});

summary = load(fullfile(path,all_files(summary_idx).name));
data_files = all_files(~summary_idx);
EB_analysis = cellfun(@(x) strfind(x,'EB_analysis'),{data_files.name},'UniformOutput',0);
EB_analysis = cellfun(@(x) isempty(x),EB_analysis);
data_files = data_files(EB_analysis);
verified_files = data_files(cell2mat(summary.userVerified(:,2)));   % Get only verified files

%% create placeholders
n_files = numel(verified_files);
image_name = {verified_files.name}';
vessel_area_fraction = zeros(n_files,1);
mean_segment_diam_um = cell(n_files,1);
median_segment_diam_um = cell(n_files,1);
max_segment_diam_um = cell(n_files,1);
avg_red_px_val = cell(n_files,1);
results = table(image_name,vessel_area_fraction,mean_segment_diam_um,...
    median_segment_diam_um,max_segment_diam_um,avg_red_px_val);
%% Iterate over files
parfor i = 1:n_files
    fprintf('Processing file %d of %d\n',i,numel(verified_files));
    % Calc extravasation for every segment.
    metric_st = reaver_quantify_EB(fullfile(path,verified_files(i).name),n_px);
    metric_st.image_name = image_name(i);
    results_tbl(i,:) = struct2table(orderfields(metric_st,[6,1,2,3,4,5]));
end
writetable(results_tbl,fullfile(path,['EB_extravasation_analysis_',num2str(n_px),'px.csv']));
res = struct('table',results_tbl,'n_px',n_px);
save(fullfile(path,['EB_analysis_',num2str(n_px),'px.mat']),'res');