[im_file, folder] = uigetfile('*.tif');
t = fullfile(folder,im_file);
redIm = imread(t,1);
greenIm = imread(t,2);
composite = cat(3,redIm,greenIm);
matfile = load(fullfile(folder,strrep(im_file,'.tif','.mat')));
original_bw = matfile.derivedPic.BW_2;
dilated = imdilate(original_bw,strel('disk',1));
eroded = imerode(original_bw,strel('disk',1));
edges = dilated-eroded;
edges_3d = logical(repmat(edges,1,1,2));
composite(edges_3d) = 1023;

rgb_comp = 64*composite;
rgb_comp(:,:,3) = 0;
imagesc(rgb_comp);
bfsave(composite,fullfile(folder,strrep(im_file,'.tif','_combined.tiff')));