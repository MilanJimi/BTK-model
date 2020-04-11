classdef btk_model<handle
    properties (SetAccess = private)
    end

    properties (SetAccess = public)
        F1 = 0;
        F2 = 0;
        A  = 0;
        d  = 0;
    end
    
    methods
        function obj = btk_model(energyRange,Nprecis)
            global Npoints N_FACT BAR_N_PARTS divN_PARTS divN1_PARTS div2N_PARTS;

            Npoints = Nprecis-1;
            BAR_N_PARTS = 10;
            divN_PARTS = 1/BAR_N_PARTS;
            divN1_PARTS = 1/(BAR_N_PARTS-1);
            div2N_PARTS = 0.5*divN_PARTS;
            N_FACT = 5;
            
            global k NF vF e;
            
            k = 8.617347e-5;
            NF = 1e27;
            vF = 1e5;
            e  = 1.6e-19;
            
            global energyComputationRange Eint_rng EmaxRange dE dE_2 N Nhalf T;
            global energiesTable energiesFineTable derivatedFermiFunction normalizedDerivatedFermiFunction transportProbability;

            energyComputationRange = energyRange;
            Eint_rng = (N_FACT-1)*energyRange;
            EmaxRange = N_FACT*energyRange;
            N = 0;
            Nhalf = 0;
            dE = 0;
            dE_2 = 0;
            T = 0;
            energiesTable = [];  % tabulka dostupnych diskretnych energii (energiesTable(N/2) = 0)
            energiesFineTable = []; % jemnejsia tabulka energii, kde je zratana Fermiho funkcia
            derivatedFermiFunction = [];
            normalizedDerivatedFermiFunction = []; % predratana derivacia fermiho funkcie normovanej tak, aby integral bol 1
            transportProbability = [];  % pravdepodobnosti prechodu cez barieru pre energiesTable(:)
        end
        
        function obj = setTemp(obj,temperature)
            global Npoints EmaxRange dE dE_2 N Nhalf k ikT kT T Ei1 Ei2;
            global N_FACT energiesTable normalizedDerivatedFermiFunction;
            
            T = temperature;
            kT = k*T;
            ikT = 1/kT;
            
            Nhalf = round(N_FACT*Npoints/2);
            N = 2*Nhalf;
            dE = 2*EmaxRange/N;
            dE_2 = EmaxRange/N;
            energiesTable = zeros([1 N]);
            derivatedFermiFunction = zeros([1 N]);
            normalizedDerivatedFermiFunction = zeros([1 N]);
            
            akT = 0.01*kT;
            D = 1-4*akT;
            Emin = kT*log((1-2*akT-sqrt(D))/(2*akT));
            Emax = kT*log((1-2*akT+sqrt(D))/(2*akT));
            Ei1 = 0;
            Ei2 = 0;
            dE_10 = dE/10;
            for i=1:N
                % dE/2 je kvoli tomu, aby tam nebola nulova hodnota a aby som nemusel osetrovat delenie nulou
                E = -EmaxRange + i*dE - dE_2;
                energiesTable(i) = E;
                if (Ei1==0) && (E+dE>=Emin) 
                    Ei1 = i;
                end;
                
                if (Ei1>0) && (Ei2==0)
                    Ebot = E - dE_2;
                    Etop = E + dE_2;
                    ff = 0;
                    nff = 0;
                    for Ej=Ebot:dE_10:Etop
                        % Fermi function nie je zaujímavá, iba jej derivácia
                        [fermiFunction,dff] = obj.FermiFun(Ej);
                        ff = ff + dff;
                        nff = nff+1;
                    end;
                    derivatedFermiFunction(i) = ff/nff;
%                     [ft,derivatedFermiFunction(i)] = obj.FermiFun(energiesTable(i));
                else
                    derivatedFermiFunction(i) = 0;
                end;
                if (Ei2==0) && (E>=Emax) 
                    Ei2 = i;
                end;
            end;
            % Normalize
            normalizedDerivatedFermiFunction = derivatedFermiFunction/sum(derivatedFermiFunction);
%             Ei2-Ei1
        end;
        
        function obj = precalculateBar(obj,DGZ, proximityGap)
            
            global zParam deltaParam gParam Z2 D2 G2;
            
            deltaParam = 1e-3*DGZ(1);
            zParam = DGZ(2);
            gParam = 1e-3*DGZ(3);
            D2 = deltaParam*deltaParam;
            Z2 = zParam*zParam;
            G2 = gParam*gParam;

            global N Nhalf dE energiesTable transportProbability;
            
            [m,n] = size(energiesTable);
            transportProbability = zeros([m,n]);
            dE_20 = dE/20;
            for i=1:Nhalf
                E = energiesTable(i);
                % pravdepodobnost prechodu cez barieru pre zaporne energie (|E| < Delta)
                if (i>1) && (energiesTable(i)>-10*deltaParam)
                    Ebot = (energiesTable(i-1) + E)/2;
                    Etop = (energiesTable(i+1) + E)/2;
                    tProbability = 0;
                    fineProbabilitySamples = 0;
                    % 20x jemnejsi integral
                    for Ej=Ebot:dE_20:Etop
                        tProbability = tProbability + obj.btkTunnelProbability(Ej, proximityGap);
                        fineProbabilitySamples = fineProbabilitySamples+1;
                    end;
                    transportProbability(i) = tProbability/fineProbabilitySamples;
                else
                    % pravdepodobnost prechodu cez barieru pre kladne energie (|E| > Delta)
                    transportProbability(i) = obj.btkTunnelProbability(energiesTable(i), proximityGap);
                end;
                % Pravdepodobnost je symetricka
                transportProbability(N-i+1) = transportProbability(i);
            end;
        end;
        
        function obj = precalculateBarForPolarization(obj,DGZ, proximityGap)
            
            global zParam deltaParam gParam Z2 D2 G2;
            
            deltaParam = 1e-3*DGZ(1);
            zParam = DGZ(2);
            gParam = 1e-3*DGZ(3);
            D2 = deltaParam*deltaParam;
            Z2 = zParam*zParam;
            G2 = gParam*gParam;

            global N Nhalf dE energiesTable transportProbability;
            
            [m,n] = size(energiesTable);
            transportProbability = zeros([m,n]);
            dE_10 = dE/20;
            for i=1:Nhalf
                E = energiesTable(i);
                % pravdepodobnost prechodu cez barieru pre zaporne energie
                if (i>1) && (energiesTable(i)>-10*deltaParam)
                    E1 = (energiesTable(i-1) + E)/2;
                    E2 = (energiesTable(i+1) + E)/2;
                    tp = 0;
                    ntp = 0;
                    for Ej=E1:dE_10:E2
                       tp = tp + obj.btkTunnelProbability_polarized(Ej, proximityGap);
                        ntp = ntp+1;
                    end;
                    transportProbability(i) = tp/ntp;
                else
                    transportProbability(i) = obj.btkTunnelProbability_polarized(energiesTable(i), proximityGap);
                end;
                % pravdepodobnost prechodu cez barieru pre kladne energie
                transportProbability(N-i+1) =  transportProbability(i);
            end;
        end;
        
        function dIdV = localDeriv(obj,V)
            global dE Z2 Ei1 Ei2 normalizedDerivatedFermiFunction transportProbability;
            intg = 0;
            Vi = floor(V/dE);
            for i = Ei1:Ei2
                i_bias = i+Vi;%max(1,min(i+Vi,N));
                intg = intg + normalizedDerivatedFermiFunction(i)*transportProbability(i_bias);
            end;
            dIdV = (1 + Z2)*intg;
        end;
        
        function [V,dIdV] = calcDiffChar(obj,hWait,DGZW)
            
            global energyComputationRange dE energiesTable;
            
            [m,n] = size(energiesTable);
            Npoints = round(2*energyComputationRange/dE);
            V = zeros([1 Npoints]);
            dIdV1 = zeros([1 Npoints]);
            dIdV2 = [];
            dIdV_Polarization = zeros([1 Npoints]);

            proximityGap = 1e-3*DGZW(9);
            precalculateBar(obj,DGZW(1:3), proximityGap);
            
            index = 1;
            for i=1:n/2
                if (energiesTable(i)>=-energyComputationRange) && (energiesTable(i)<=0)
                    % prva polovicka diferecialky
                    V(index) = energiesTable(i);
                    dIdV1(index) = obj.localDeriv(energiesTable(i));
                    % druha polovicka je zrkadlovy obraz
                    V(Npoints-index+1) = -V(index);
                    dIdV1(Npoints-index+1) = dIdV1(index);
                    index = index+1;
                end;
                if hWait~=0
                    waitbar(i/n,hWait);
                end;
            end;
            
            W = DGZW(7);
            if W>0
                dIdV2 = zeros([1 Npoints]);
                
                precalculateBar(obj,DGZW(4:6));

                index = 1;
                for i=1:n/2
                    if (energiesTable(i)>=-energyComputationRange) && (energiesTable(i)<=0)
                        dIdV2(index) = obj.localDeriv(energiesTable(i));
                        dIdV2(Npoints-index+1) = dIdV2(index);
                        index = index+1;
                    end;
                    if hWait~=0
                        waitbar(i/n,hWait);
                    end;
                end;
            end; 
            
            if isempty(dIdV2)
                dIdV_PrePolarization = dIdV1;
            else
                dIdV_PrePolarization = (1-W)*dIdV1 + W*dIdV2;
            end;
            
            P = DGZW(8);
            precalculateBarForPolarization(obj, DGZW(1:3), proximityGap);
            index = 1;
            for i=1:n/2
                if (energiesTable(i)>=-energyComputationRange) && (energiesTable(i)<=0)
                    V(index) = energiesTable(i);
                    dIdV_Polarization(index) = obj.localDeriv(energiesTable(i));
                    V(Npoints-index+1) = -V(index);
                    dIdV_Polarization(Npoints-index+1) = dIdV_Polarization(index);
                    index = index+1;
                end;
                if hWait~=0
                    waitbar(i/n,hWait);
                end;
            end;
                
            
            dIdV = (1-P)*dIdV_PrePolarization + P*dIdV_Polarization;
        end;
        
        function [dIdV_norm,Rsquared,VARres,Scale,Shift] = normDiffChar(obj,X,Y,V,dIdV)
            
            global energyComputationRange;
            
            NormTilde = 1.0;
            BTKTilde  = 1.0;
            Scale     = 1.0;
            Eover     = 0.9*energyComputationRange;
            
            Ys = Y(abs(X)>Eover);
            Ns = length(Ys);
            if Ns>0
                NormTilde = sum(Ys)/Ns;
            end;
            
            Ys = dIdV(abs(V)>Eover);
            Ns = length(Ys);
            if Ns>0
                BTKTilde  = sum(Ys)/Ns;
            end;
            
            Xs = X(abs(X)<Eover);
            Ys = Y(abs(X)<Eover);
            Ns = length(Xs);
            Ymean = mean(Ys);
            SStot = sum((Ys - Ymean).^2);
            Yf = interp1(V,dIdV,Xs','linear');
            SSres = sum((Ys - Yf').^2);
            Rsquared = 1 - SSres/SStot;
            VARres = SSres/Ns;
            
            NormMax = max(Y);
            BTKMax  = max(dIdV);
            if (BTKMax~=BTKTilde)
%                 Scale = (NormMax-NormTilde)/(BTKMax-BTKTilde);
%                 Scale = max(0.01,min(Scale,1.0));
                Scale = 1;
            end;
            Shift = Scale*(BTKTilde-1)+1-NormTilde;
            
            dIdV_norm = Scale*(dIdV-1)+1-Shift;
        end;
        
        function Temp = getTemp(obj)
            global T;
            Temp = T;
        end;
        
        function I = localBgCurrent(obj,A,d,F,dF,U)
            [m,n] = size(obj.energiesTable);
            intg = 0;
            Uabs = abs(U);
            Ustp = Uabs/100;
            for i=0:Ustp:Uabs
%                P = obj.tun_prob(i,d,F,U);
                P = obj.asym_tun_prob(i,d,F,dF,U);
                intg = intg + P*Ustp;
            end;
            I = (A*1E-12)*obj.NF*obj.e*obj.vF*intg*sign(U);
        end;

        function [V,dIdV] = calcBgDiffChar(obj,A,d,F,dF)
            [m,n] = size(obj.energiesTable);
            energyRange = obj.energyComputationRange;
            Estp = energyRange/20;
            Npoints = round(2*energyRange/Estp)+1;
            V = zeros([1 Npoints]);
            IV = zeros([1 Npoints]);
            dIdV = zeros([1 Npoints]);
            index = 1;
            for i=-energyRange:Estp:energyRange
                V(index) = i;
                IV(index) = obj.localBgCurrent(A,d,F,dF,i);
                index = index+1;
            end;
            invdE2 = 1/(2*Estp);
            for i=2:Npoints-1
                dIdV(i) = (IV(i+1)-IV(i-1))*invdE2;
            end;
            V(Npoints)=[];
            dIdV(Npoints)=[];
            V(1)=[];
            dIdV(1)=[];
        end;
    end
    
    methods(Static)
        function [f,df] = FermiFun(E)
            global ikT;
            ex = exp(E*ikT);
            if ex==Inf
                f=0;
                df=0;
                return;
            end;
            f = 1./(1 + ex);
            if nargout>1
                df = f.*f.*ex.*ikT;
            end;
        end;

        function [f,df] = biasFermiFun(E,V)
            global ikT;
            ex = exp((E-V)*ikT);
            f = 1/(1 + ex);
            if nargout>1
                df = f*f*ex*ikT;
            end;
        end;

        % Generalization of the BTK Theory to the Case of Finite Quasiparticle Lifetimes
        % Yousef Rohanizadegan
        function [uSquared, vSquared] = getCoherenceFactorSquares(E, Delta)
            global gParam;
            dampedE = abs(E)-i*gParam;

            uSquared = (1 + sqrt(dampedE^2 - Delta^2)/dampedE)/2;
            vSquared = 1 - uSquared;
        end;

        % Andreev reflections at metal superconductor point contacts: Measurement and analysis
        % G. J. Strijkers, et al.
        function transportProbability = btkTunnelProbability(E, proximityGap)
            global zParam Z2 deltaParam gParam;
            [u1Squared, v1Squared] = btk_model.getCoherenceFactorSquares(E, proximityGap);
            [u2Squared, v2Squared] = btk_model.getCoherenceFactorSquares(E, deltaParam);
            if abs(E) < proximityGap
                dampedE = abs(E)-i*gParam;
                A = abs(proximityGap^2/(E^2 + (proximityGap^2 - E^2)*(1+2*Z2)^2));
                B = 1-A;
            elseif abs(E) < deltaParam
                gamma1Squared = (u1Squared + (u1Squared - v1Squared)*Z2)^2;
                A = abs(u1Squared*v1Squared/gamma1Squared);
                B = 1-A;
            else  
                gamma2Squared = u1Squared*v1Squared + (u2Squared - v2Squared)*(u2Squared + Z2 + Z2*(1+Z2)*(u2Squared - v2Squared));
                A = abs(u1Squared*v1Squared/gamma2Squared);
                B = abs((Z2*(Z2 + 1)*(u2Squared - v2Squared)^2)/gamma2Squared);
            end;
            transportProbability = 1 + A - B;
        end;
        
        function transportProbability = btkTunnelProbability_polarized(E, proximityGap)
            global zParam Z2 deltaParam;

            [u2Squared, v2Squared] = btk_model.getCoherenceFactorSquares(E, deltaParam);
            if abs(E) < deltaParam
                A = 0;
                B = 1;
            else 
                gamma3Squared = (u2Squared - v2Squared)*(u2Squared + Z2 + Z2*(1+Z2)*(u2Squared - v2Squared));
                A = 0;
                B = abs(Z2*(Z2 + 1)*(u2Squared - v2Squared)^2/gamma3Squared);
            end;
            transportProbability = 1 + A - B;
        end;
        
        function transportProbability = tun_prob(E,d,F,U) % E [eV], U [V]
            global BAR_N_PARTS divN_PARTS div2N_PARTS;
            
            U = abs(U);
            if (E<F+U/2)
                dd = d*divN_PARTS;
                arg=zeros([1 BAR_N_PARTS]);
                for i=1:BAR_N_PARTS
                    arg(i) = sqrt(F + U*(2*i-1)*div2N_PARTS - E)*dd;
                end;
                transportProbability = exp(-sum(arg));
            else
                transportProbability = 1;
            end;
        end;

        function transportProbability = asym_tun_prob(E,d,F1,dF12,U) % E [eV], U [V]
            global BAR_N_PARTS divN_PARTS divN1_PARTS div2N_PARTS;
            
            if (U>0)
                F = F1;
                dF = dF12;
            else
                F = F1 + dF12;
                dF = -dF12;
            end;
            U = abs(U);
            if (E<F+U/2)
                dd = d*divN_PARTS;
                arg=zeros([1 BAR_N_PARTS]);
                for i=1:BAR_N_PARTS
                    arg(i) = sqrt(F + (i-1)*divN1_PARTS*dF + U*(2*i-1)*div2N_PARTS - E)*dd;
                end;
                transportProbability = exp(-sum(arg));
            else
                transportProbability = 1;
            end;
        end;
    end;
end
