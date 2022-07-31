function bifurcation_density = b_density(mat_path)
% Function to extract the number of bifurcations per volume
%     mat_math = path to a .mat file containing the verified image
%                parameters, BW image and wireframe
st = load(mat_path);
n_bif = length(st.derivedPic.branchpoints);
image_volume = st.imageSize(1)*st.imageSize(2)*20;
bifurcation_density = (n_bif/image_volume)/(st.image_resolution^2);
bifurcation_density = bifurcation_density*10^9; % To go from um^-3 to mm^-3
end