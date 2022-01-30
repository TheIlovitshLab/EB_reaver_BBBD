function rcind_seg_cell = skel_2_linesegs(sp_wire,rc_bp,rc_ep)
% TODO: improve segment detection!
%{
Function to extract all segments (longer than 5 px) from a wire frame. for
each segment coordinates of all points in segment are saved.

Input arguements:
    sp_wire = vessel wireframe, logical array with dimensions equal to 
                those of the image.
    rc_bp = branchpoint coordinates specified as [row,column] couples vector
    rc_ep = endpoints coordinates specified as [row,column] couples vector

Output arguements:
    rcind_seg_cell = vertical cell array with every cell containing 
                    [row, col] coordinates of all points belonging to that
                    segment
%}

% Get wire/skeleton and trace
bw_init_skel = full(sp_wire);
bw_skel_index = 1:numel(bw_init_skel);


% get coordinates of both endpoints and branchpoints
rc_pts = vertcat(rc_bp,rc_ep);

bw_border = false(size(bw_init_skel));  % Generate a logical image of borders
bw_border(1,:)=1; bw_border(:,1)=1;
bw_border(end,:)=1; bw_border(:,end)=1;
%     imshow()
[re, ce]= ind2sub(size(bw_init_skel), ...
    bw_skel_index(bwmorph(bw_init_skel,'endpoints') & bw_border)); % Get coordinates of all borders and end points.
rc_pts = vertcat(rc_pts, [re' ce']); % rc_pts contains all the ends of segments


bw_pts = false(size(sp_wire));
bw_pts(sub2ind(size(sp_wire),rc_pts(:,1),rc_pts(:,2)))=1;   % bw_pts is a logical array with only the rc_pts as true


% Initialize place holders
rcind_seg_cell_cells = cell(1,1);  

% Initilize skeleton image of the wireframe where parts get iteratively processed
bw_skel_rem = bw_init_skel;

% Need to loop on skeleton until all of it is traced
for n=1:size(rc_bp.^2)  % rc_bp.^2 is chosen randomly to over-kill
    
    % Find first element of skeleton
    skel_lind = bw_skel_index(bw_skel_rem); % Indexes of pixels in the wireframe BW image that are logical 1
    if isempty(skel_lind), break; end
    [ri, ci] = ind2sub(size(bw_skel_rem),skel_lind(1)); % get the coordinates of the 1st logical 1 pixel in the list
    
    % Take remaining wire, trace
    trace = bwtraceboundary(bw_skel_rem,[ri ci],'W');
    
    % Find branchpoints and endpoints in skeleton trace list
    is_bp = false(size(trace,1),1);
    bp_lind = 1:numel(is_bp);
    for k=1:size(is_bp)
        is_bp(k) = ismember(trace(k,:),rc_pts,'rows');
    end
    bp_ind = bp_lind(is_bp);
    
    % Segments are trace pixels in between branchpoints (inclusive of bp)
    rcind_seg_cell_cells{n} = cell(numel(bp_ind)-1,1);
    for k=2:numel(bp_ind)
        tr = trace(bp_ind(k-1):bp_ind(k),1:2);
        % Sort ccordinates from top to bottom- for removal of non-unique segments later on
        rcind_seg_cell_cells{n}{k-1} = sortrows(tr); % Save all wire-frame points between 2 adjacent branchpoints (as segment)
    end
   
    % Remove current segment from remaining trace image
    bw_skel_rem(sub2ind(size(bw_skel_rem), trace(:,1),trace(:,2)))=0;
    
    % Add end points back in, then remove lone points (particles smaller than 2 px)
    bw_skel_rem = bwareaopen(bw_skel_rem |  bw_pts,2);
    
end   
    
rcind_seg_cell = vertcat(rcind_seg_cell_cells{:});

% delete segments less than 5 pixels in length
rcind_seg_cell(cellfun(@(x) size(x,1) <=5, rcind_seg_cell))=[];

% delete non-unique segments
rcind_seg_cell = uniquearray(rcind_seg_cell);
%    
end


