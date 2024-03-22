00100	defint i-n
00200	recsiz%=32
00300	open "R",1,"B:RANTEST.ASC",recsiz%
00400	for i=1 to 20
00500	  print #1, using "$$#,###.##   ";1000*i,102.34*i*i
00600	  put 1,i
00700	next i
00800	for i=1 to 20
00900	  get 1,i
01000	  line input #1, prices$
01100	  print i,prices$
01200	next i
01300	close 1
01400	end
r i=1 to 20
00900	  get 1,i
01000	  line input #1, prices