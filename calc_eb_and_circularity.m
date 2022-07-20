function [eb_ext_in_segments,circularities] = ...
    calc_eb_and_circularity(rcind_seg_cell,...
    all_seg_rads,...
    bw_vessels,...
    redIm,...
    from_px,...
    n_px,...
    normFlag)
% Function to calculate EB extravasation around deifferent vessel segments
% according to previous vessel segmentation. return statistics for the 
% extravasation in the range (from_px, from_px + n_px] around the vessel
% Input arguements:
%     rcind_seg_cell = cell array with every cell containing [row,col]
%         coordinates of a vessel segment
%     all_seg_rads = radii of segments. for dilation.
%     bw_vessels = processed binary image of blood vessles and background
%     redIm = image of EB channel
%     from_px = the starting distance in pixels
%     n_px = how many pixels of extravasation
%     normFlag  = Boolean flag to normalize image to range of [0,1]
% Output arguements:
%     eb_ext_in_segments = vector of size n_segments where each element
%        contains the median pixel value of a (j/10)*n_px 
%         neighborhood around the i-th segment in the EB image

eb_ext_in_segments = zeros(length(rcind_seg_cell),1); % Create a placeholder
circularities = zeros(length(rcind_seg_cell),1);

if nargin < 6
    normFlag = 0;
end
if normFlag == 1
    redIm = rescale(double(redIm));
end
% max_eb_inside = 0;

se_from = strel('disk',from_px,0); 
se_to = strel('disk',n_px,0); 
for n=1:size(rcind_seg_cell,1)  % loop through all segments
    se_small = strel('disk',ceil(all_seg_rads(n)),0); % Create a specific structure element for wire dilation 
    centerline = sub2ind(size(bw_vessels), rcind_seg_cell{n}(:,1),rcind_seg_cell{n}(:,2));    % get all wire-frame elements of the segment (represent the centerline)
    single_seg_bw = false(size(redIm));
    single_seg_bw(centerline) = 1;    % set only the segment wireframe to True
    single_vessel_mask = blockdilate(single_seg_bw,se_small); % Dilate the wire
    single_vessel_mask = single_vessel_mask & bw_vessels; % constrain to only what is inside the vessel
    if from_px == 0
        start_dist = single_vessel_mask;
    else
        start_dist = blockdilate(single_vessel_mask,se_from); % Dilate the single vessel
    end
    end_dist = blockdilate(start_dist, se_to);
    single_vessel_perivasc_mask = logical(end_dist-start_dist);
    single_vessel_perivasc_mask = ...
        logical((single_vessel_perivasc_mask | bw_vessels)-bw_vessels); % Make sure not to take anything thats' within a vessel
    in_vessel_mask = blockdilate(single_seg_bw,strel('disk',ceil(all_seg_rads(n)),0));
    in_vessel_mask = in_vessel_mask & bw_vessels;
    props = regionprops(in_vessel_mask,'Area','Perimeter');
    if numel(props) > 1
        % If there are multiple areas only take the largest
        [~,I] = sort([props.Area]);
        props = props(I(end),:);
    end
    circularities(n) = 4*pi*props.Area/(props.Perimeter^2);
%     if normFlag ==1 
%         eb_ext_in_segments(n) = ...
%             double(median(redIm(single_vessel_perivasc_mask),'all'))./...
%             double(median(redIm(in_vessel_mask),'all'));
% %         eb_ext_in_segments(n) = double(median(redIm(single_vessel_mask),'all'));
    if n_px > 0
        eb_ext_in_segments(n) = ...
            double(median(redIm(single_vessel_perivasc_mask),'all'));
    else
        eb_ext_in_segments(n) = double(median(redIm(in_vessel_mask),'all'));
    end
%     max_eb_cur = max(redIm(single_vessel_mask),[],'all');
%     max_eb_inside = max([max_eb_inside, max_eb_cur]);
    % Visualization if needed for debugging and n_px optimzation
%     extra_vessel_red = redIm.*uint8(~bw_vessels); % remove vessles from red channel
%     k = cat(3,extra_vessel_red,zeros(size(extra_vessel_red)),...
%         2^6.*uint8(single_vessel_perivasc_mask));
%     k = k + 2^8*uint8(repmat(single_seg_bw,1,1,3));
%     imshow(k); 
%     pause(0.5);
    %
end
% eb_ext_in_segments = eb_ext_in_segments./double(max(redIm,[],'all'));
end