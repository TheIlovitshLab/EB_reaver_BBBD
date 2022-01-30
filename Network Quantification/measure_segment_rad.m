function [all_seg_rads, index_tbl] =...
    measure_segment_rad(rcind_seg_cell,bw_seg,rc_ep)
%{
    Function to measure the median radius of each segment
    Input arguements:
        rcind_seg_cell = vertical cell array. every cell contains the 
                            [row,col] ccordinates of all the wire-frame
                            pixels belonging to that segment
        bw_seg = BW image of segmented vessels
        rc_ep = [row,col] coordinates of all end points
    Output arguements:
        all_seg_rads = table with number of rows equal to number of
            segments, every row contains the median, max and min redius of
            that segment
%}
    
% linearize indices
lind_ep = sub2ind(size(bw_seg), rc_ep(:,1), rc_ep(:,2));

ed_gs = bwdist(~bw_seg);    % for each point calculate the distance to the nearest black point (background).
   
median_seg_rads = zeros(1, size(rcind_seg_cell,1));
max_seg_rads = zeros(1, size(rcind_seg_cell,1));
min_seg_rads = zeros(1, size(rcind_seg_cell,1));

is_ep_seg = false(1, size(rcind_seg_cell,1));
for n=1:size(rcind_seg_cell,1)  % loop through all segments
    lind_seg = sub2ind(size(bw_seg), rcind_seg_cell{n}(:,1),rcind_seg_cell{n}(:,2));    % get all wire-frame elements of the segment (represent the middle-line)
    median_seg_rads(n) = median(ed_gs(lind_seg));    % Average distance between mid-line and vessel edge (gives the average vessel radius)
    max_seg_rads(n) = max(ed_gs(lind_seg));    % Average distance between mid-line and vessel edge (gives the average vessel radius)
    min_seg_rads(n) = min(ed_gs(lind_seg));    % Average distance between mid-line and vessel edge (gives the average vessel radius)

    % Are the first or last segment points also an endpoint
    is_ep_seg(n) = ~isempty(intersect([lind_seg(1) lind_seg(end)],lind_ep));
end
all_seg_rads = table(median_seg_rads',min_seg_rads',max_seg_rads',...
    'VariableNames',{'median','min','max'});
index_tbl.end_seg_idx = is_ep_seg;

end

