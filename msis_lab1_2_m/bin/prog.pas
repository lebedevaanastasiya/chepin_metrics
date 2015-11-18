program primer1; //мама 
var s1,s2:string;
    i:integer;   
	{ str:string;}
	season: (summer, autumn, winter, spring);

const count=455;

var
  a, b, h: real;
  x, y, v: real;

     begin
     write('a= ');
     readln(a);
     write('b= ');
     readln(b);
     write('h= ');
     readln(h);

     if (a>b) or (h<=0) then
          writeln('Data is not correct.Please try again')


    else
       begin

          x:=a;
          v:=Exp(6.3)+x;
//hgjhfdskjhdfk
             while x<b-h/1000 do
		
                begin
                    if (x<>0)  then
                      begin
                           if v>0 then
                            y:=(1/3)*Exp((1/7)*Ln(v))*Abs(cos((2*x)/3)-cos(3/x));
                             if v<0 then
                             y:=(1/3)*(-1)*Exp((1/7)*Ln(abs(v)))*Abs(cos((2*x)/3)-cos(3/x));
                             if v=0 then
                             writeln('y=0')
                             else
                            writeln('y(', x:8:4, ') = ', y:8:4);
                            x:=x+h;
                            v:=Exp(6.3)+x;

                        end
                        

                   else
                       begin
                         writeln('Function does not exist in ', x:8:4);
                         x:=x+h;
                         v:=Exp(6.3)+x;
                   end;

               end;

       x:=b;
       
        if (x=0) then
           writeln('Function does not exist in ', x:8:4)

        else
            begin
              if v>0 then
              y:=(1/3)*Exp((1/7)*Ln(v))*Abs(cos((2*x)/3)-cos(3/x));
              if v<0 then
              y:=(1/3)*(-1)*Exp((1/7)*Ln(abs(v)))*Abs(cos((2*x)/3)-cos(3/x));
              if v=0 then
              writeln('y=0')
              else
              writeln('y(', x:8:4, ') = ', y:8:4);
            end;

      end;
  Readln;
end.