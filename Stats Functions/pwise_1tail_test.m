function [pairwise_sig, p_vals] = pwise_1tail_test(data_mat, stats_fun)

% keyboard
% Identify Leader

% Find all combinations for pairwise comparisons
comb_ind = nchoosek(1:size(data_mat,2),2);

% Find all forward and reverse of combinations
perm_ind = vertcat(comb_ind, fliplr(comb_ind));


% Number of combinations is also number of comparisons
n_combs = size(comb_ind,1);
n_perms = size(perm_ind,1);

% Perform pairwise comparison
for n=1:n_perms
    [h(n,1),p(n,1)] = stats_fun(data_mat(:,perm_ind(n,1)),...
        data_mat(:,perm_ind(n,2)));
end

% for n=1:n_combs
%     [hb(n,1),pb(n,1)] = ttest(data_mat(:,comb_ind(n,1)),...
%         data_mat(:,comb_ind(n,2)),'tail','both');
% end
% pb*6==min([p(1:6)*12 p(7:12)*12],2)

% Bonferonni Adjustment to pvalue (multiply by # comparisons, min to 1)
p_vals = min([p*n_perms ones(n_perms,1)],[],2);

pairwise_sig = [perm_ind p_vals];
% keyboard