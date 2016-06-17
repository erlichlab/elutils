function y=colors(x)
% rgb=colors(name)
% Returns the RGB value of a named color.
% http://www.rapidtables.com/web/color/RGB_Color.htm
% if called with no inputs returns a list of valid color names.
% Feel free to add additional colors

O={'maroon', [128,0,0]/255;
'dark red', [139,0,0]/255;
'brown', [165,42,42]/255;
'firebrick', [178,34,34]/255;
'crimson', [220,20,60]/255;
'red', [255,0,0]/255;
'tomato', [255,99,71]/255;
'coral', [255,127,80]/255;
'indian red', [205,92,92]/255;
'light coral', [240,128,128]/255;
'dark salmon', [233,150,122]/255;
'salmon', [250,128,114]/255;
'light salmon', [255,160,122]/255;
'orange red', [255,69,0]/255;
'dark orange', [255,140,0]/255;
'orange', [255,165,0]/255;
'gold', [255,215,0]/255;
'dark golden rod', [184,134,11]/255;
'golden rod', [218,165,32]/255;
'pale golden rod', [238,232,170]/255;
'dark khaki', [189,183,107]/255;
'khaki', [240,230,140]/255;
'olive', [128,128,0]/255;
'yellow', [255,255,0]/255;
'yellow green', [154,205,50]/255;
'dark olive green', [85,107,47]/255;
'olive drab', [107,142,35]/255;
'lawn green', [124,252,0]/255;
'chart reuse', [127,255,0]/255;
'green yellow', [173,255,47]/255;
'dark green', [0,100,0]/255;
'green', [0,128,0]/255;
'forest green', [34,139,34]/255;
'lime', [0,255,0]/255;
'lime green', [50,205,50]/255;
'light green', [144,238,144]/255;
'pale green', [152,251,152]/255;
'dark sea green', [143,188,143]/255;
'medium spring green', [0,250,154]/255;
'spring green', [0,255,127]/255;
'sea green', [46,139,87]/255;
'medium aqua marine', [102,205,170]/255;
'medium sea green', [60,179,113]/255;
'light sea green', [32,178,170]/255;
'dark slate gray', [47,79,79]/255;
'teal', [0,128,128]/255;
'dark cyan', [0,139,139]/255;
'aqua', [0,255,255]/255;
'cyan', [0,255,255]/255;
'light cyan', [224,255,255]/255;
'dark turquoise', [0,206,209]/255;
'turquoise', [64,224,208]/255;
'medium turquoise', [72,209,204]/255;
'pale turquoise', [175,238,238]/255;
'aqua marine', [127,255,212]/255;
'powder blue', [176,224,230]/255;
'cadet blue', [95,158,160]/255;
'steel blue', [70,130,180]/255;
'corn flower blue', [100,149,237]/255;
'deep sky blue', [0,191,255]/255;
'dodger blue', [30,144,255]/255;
'light blue', [173,216,230]/255;
'sky blue', [135,206,235]/255;
'light sky blue', [135,206,250]/255;
'midnight blue', [25,25,112]/255;
'navy', [0,0,128]/255;
'dark blue', [0,0,139]/255;
'medium blue', [0,0,205]/255;
'blue', [0,0,255]/255;
'royal blue', [65,105,225]/255;
'blue violet', [138,43,226]/255;
'indigo', [75,0,130]/255;
'dark slate blue', [72,61,139]/255;
'slate blue', [106,90,205]/255;
'medium slate blue', [123,104,238]/255;
'medium purple', [147,112,219]/255;
'dark magenta', [139,0,139]/255;
'dark violet', [148,0,211]/255;
'dark orchid', [153,50,204]/255;
'medium orchid', [186,85,211]/255;
'purple', [128,0,128]/255;
'thistle', [216,191,216]/255;
'plum', [221,160,221]/255;
'violet', [238,130,238]/255;
'magenta', [255,0,255]/255;
'orchid', [218,112,214]/255;
'medium violet red', [199,21,133]/255;
'pale violet red', [219,112,147]/255;
'deep pink', [255,20,147]/255;
'hot pink', [255,105,180]/255;
'light pink', [255,182,193]/255;
'pink', [255,192,203]/255;
'antique white', [250,235,215]/255;
'beige', [245,245,220]/255;
'bisque', [255,228,196]/255;
'blanched almond', [255,235,205]/255;
'wheat', [245,222,179]/255;
'corn silk', [255,248,220]/255;
'lemon chiffon', [255,250,205]/255;
'light golden rod yellow', [250,250,210]/255;
'light yellow', [255,255,224]/255;
'saddle brown', [139,69,19]/255;
'sienna', [160,82,45]/255;
'chocolate', [210,105,30]/255;
'peru', [205,133,63]/255;
'sandy brown', [244,164,96]/255;
'burly wood', [222,184,135]/255;
'tan', [210,180,140]/255;
'rosy brown', [188,143,143]/255;
'moccasin', [255,228,181]/255;
'navajo white', [255,222,173]/255;
'peach puff', [255,218,185]/255;
'misty rose', [255,228,225]/255;
'lavender blush', [255,240,245]/255;
'linen', [250,240,230]/255;
'old lace', [253,245,230]/255;
'papaya whip', [255,239,213]/255;
'sea shell', [255,245,238]/255;
'mint cream', [245,255,250]/255;
'slate gray', [112,128,144]/255;
'light slate gray', [119,136,153]/255;
'light steel blue', [176,196,222]/255;
'lavender', [230,230,250]/255;
'floral white', [255,250,240]/255;
'alice blue', [240,248,255]/255;
'ghost white', [248,248,255]/255;
'honeydew', [240,255,240]/255;
'ivory', [255,255,240]/255;
'azure', [240,255,255]/255;
'snow', [255,250,250]/255;
'black', [0,0,0]/255;
'dim gray', [105,105,105]/255;
'gray', [128,128,128]/255;
'dark gray', [169,169,169]/255;
'silver', [192,192,192]/255;
'light gray', [211,211,211]/255;
'gainsboro', [220,220,220]/255;
'white smoke', [245,245,245]/255;
'white', [255,255,255]/255;};

if nargin==0
    y=O(:,1);
else
    cind=strcmp(O(:,1),x);
    if all(cind==0)
        y=[0 0 0];
        fprintf(2,'Do not know color "%s"\n',x)
    else
        y=O{strcmp(O(:,1),x),2};
    end
end