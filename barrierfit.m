function [A,R,d,F1,F2,adjR2,Gfit] = barrierfit(Aum2,Udata,Gdata,trapez)
% [G]=S.um-2, [A]=um2, [d]=A, [F]=[dF]=eV

if ~exist('trapez')
    trapez=0;
end;

expr=sprintf('G*(%e) + 31.6*(%e)*(F/d)*exp(-d*sqrt(F))*(1 + 0.033*d*d/F*x*x)',Aum2,Aum2);
gmodel=fittype(expr,'coeff',{'G','d','F'});
fo=fitoptions(gmodel);
fo.StartPoint  = [1    10 1]; % [G]=S.um-2, [d]=A, [F]=eV
fo.Lower       = [1e-6 1  0];
fo.Upper       = [1e+6 20 2];
fo.MaxFunEvals = 1000; fo.MaxIter = 1000; fo.DiffMinChange = 1e-100; fo.TolFun = 1e-100; fo.TolX = 1e-20;

[fitmodel,goodness]=fit(Udata',Gdata',gmodel,fo);
Gfit=fitmodel(Udata);

A=Aum2;
G=fitmodel.G;
R=1/fitmodel.G;
d=fitmodel.d;
F=fitmodel.F;
F1=F;
F2=F;
adjR2=goodness.adjrsquare;

if ~trapez return; end;

expr=sprintf('(%e)*(%e) + 31.6*(%e)*(F/d)*exp(-d*sqrt(F))*(1 - 0.0428*dF*d/(F*sqrt(F))*x + 0.033*d*d/F*x*x)',G,Aum2,Aum2);
gmodel=fittype(expr,'coeff',{'d','F','dF'});
fo=fitoptions(gmodel);
fo.StartPoint  = [d           F          0.0];
fo.Lower       = [max(1,d-10) max(0,F-1) -1];
fo.Upper       = [d+10        F+1        +1];
fo.MaxFunEvals   = 20000;
fo.MaxIter       = 20000;
fo.DiffMinChange = 1e-100;
fo.TolFun        = 1e-100;
fo.TolX          = 1e-10;

[fitmodel,goodness]=fit(Udata',Gdata',gmodel,fo);
Gfit=fitmodel(Udata);

% R=1/fitmodel.G;
d=fitmodel.d;
A=Aum2;%fitmodel.A;
F1=fitmodel.F - fitmodel.dF/2;
F2=fitmodel.F + fitmodel.dF/2;
adjR2=goodness.adjrsquare;
