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
results_tbl = table;
results_tbl.image_name = {verified_files.name}';
%% Iterate over files
for i = 1:numel(verified_files)
    fprintf('Processing file %d of %d\n',i,numel(verified_files));
    % Calc extravasation for every segment.
    [metric_st, ~] = ...
        reaver_quantify_EB(fullfile(path,verified_files(i).name),n_px);
    f = fields(metric_st) ;
    for k=1:numel(f)
        results_tbl.(f{k})(i) = metric_st.(f{k});  
    end
end
writetable(results_tbl,fullfile(path,['EB_extravasation_analysis_',num2str(n_px),'px.csv']));
res = struct('table',results_tbl,'n_px',n_px);
save(fullfile(path,['EB_analysis_',num2str(n_px),'px.mat']),'res');