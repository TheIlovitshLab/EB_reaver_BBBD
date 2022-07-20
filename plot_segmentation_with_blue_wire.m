comp = 255*ones(1200,1920,3);
comp(repmat(derivedPic.BW_2,1,1,3)) = 0;
wire = imdilate(derivedPic.wire,strel('disk',1,0));
wire_mask = false(1200,1920,2);
wire_mask = cat(3, wire_mask,wire);
comp(wire_mask) = 255;
imshow(comp)
imwrite(comp,...
    fullfile(["C:\Users\Admin\Documents\Studies\Masters\Research\My papers\Sharon's",...
    " paper folder\Figures\image processing scheme"],...
    'segmentation and wire.jpg'));