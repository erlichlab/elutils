function y=randInts(n, s, f)
%y=randInts(n, s, f)  n is a size vector. [rows x cols]

if s>f
    s=bitxor(s,f);
    f=bitxor(s,f);
    s=bitxor(s,f);
end

fct=1+f-s;
y=floor(rand(n)*fct)+s;
