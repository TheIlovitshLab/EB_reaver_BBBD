function eb_grouped = intogroups(eb,diams,th)
    eb_grouped = cell(3,1);
    eb_grouped{1} = eb(diams<=th(1));
    eb_grouped{2} = eb(diams>th(1) & diams<= th(2));
    eb_grouped{3} = eb(diams>th(2));
end