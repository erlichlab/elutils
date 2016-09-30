function ul = getBaseReward(subjid)
try
dbc = db.labdb.getConnection();

%mass = dbc.get('select mass from met.mass where subjid = %d and mdate>',{subjid});
spec = dbc.get('select species from met.subjects where subjid = %d',{subjid});


switch spec{1}
    case 'mouse'
        ul = 2;
        
        ul = max(2,ul);
    case 'rat'
        ul = 8;
        ul = max(8,ul);
    case 'human'
        ul = 10;
        
    otherwise
        ul = 10;
end



catch
    fprintf(2,'Could not get base reward, returning default\n');
    ul = 10;
end
