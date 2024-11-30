10 for y=-12 to 12
20 for x=-39 to 39
30 ca=x*0.0458
40 cb=y*0.08333
50 a=ca
60 b=cb
70 for i=0 to 15
80 t=a*a-b*b+ca
90 b=2*a*b+cb
100 a=t
110 if (a*a+b*b)>4 then goto 200
120 next i
130 print " ";
140 goto 210
200 if i>9 then i=i+7
205 print chr$(48+i);
210 next x
220 print
230 next y
999 system
