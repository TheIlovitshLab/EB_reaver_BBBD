function [eb_grouped,diams_grouped] = intogroups(eb,diams,th)
%{
Function to devide vessles into groups based on thresholds
Input arguements:
    eb = vector of red intensity measurements for multiple segments
    diams = the coresponding diameters of the segments
    th = vector of thresholds for diameters
Output arguemrnts:
    eb_grouped = cell vector of length numel(th)+1, where each cell
    contains the eb values of segments belogning to the specific bin
%}
    eb_grouped = cell(length(th)+1,1);
    diams_grouped = eb_grouped;
    th = [0,th];
    for i = 1:length(th)-1
        eb_grouped{i} = eb(th(i)<=diams & diams<=th(i+1));
        diams_grouped{i} = diams(th(i)<=diams & diams<=th(i+1));
    end
end