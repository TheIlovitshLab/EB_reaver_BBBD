empty_mask = false(1200,1920);
vessel_mask = cat(3,empty_mask,10*derivedPic.BW_2);
comp = cat(3, vessel_mask, empty_mask);
wire = imdilate(derivedPic.wire,strel('disk',2,0));
wire_mask = repmat(wire,1,1,3);
% wire_mask = false(1200,1920,2);
% wire_mask = cat(3, wire_mask,wire);
comp(wire_mask) = 255;
imshow(comp)
imwrite(comp,...
    fullfile("C:\Users\Admin\Documents\Studies\Masters\Research\My papers\Sharon's paper folder\Figures\image processing scheme",...
    'segmentation and wire.jpg'));