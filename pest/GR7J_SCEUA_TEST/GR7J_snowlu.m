%function [SIMFLUXES, SIMSTATES] = GR6J(DATA,PARS,STATES)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[PARS]=importdata('PARS.out');
% MATLAB code developed by Mojtaba Sadegh (mojtabasadegh@gmail.com) and Amir AghaKouchak, 
% Center for Hydrometeorology and Remote Sensing (CHRS)
% University of California, Irvine
%
% Last modified on January 5, 2017
%
% Please contact Dr. Amir AghaKouchak (amir.a@uci.edu) for permission to alter the package.
%
% Please contact Mojtaba Sadegh (mojtabasadegh@gmail.com) with any issue.
%
%
%Sadegh M, AghaKouchak A, Flores A, Mallakpour I, Nikoo MR, 2019, A Multi-Model Nonstationary Rainfall-Runoff Modeling Framework: Analysis and Toolbox, Water Resources Management, doi: 10.1007/s11269-019-02283-y
%
% Disclaimer:
% This program (hereafter, software) is designed for instructional, educational and research use only.
% Commercial use is prohibited. The software is provided 'as is' without warranty 
% of any kind, either express or implied. The software could include technical or other mistakes,
% inaccuracies or typographical errors. The use of the software is done at your own discretion and 
% risk and with agreement that you will be solely responsible for any damage and that the authors
% and their affiliate institutions accept no responsibility for errors or omissions in the software
% or documentation. In no event shall the authors or their affiliate institutions be liable to you or
% any third parties for any special, indirect or consequential damages of any kind, or any damages whatsoever. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load DATA
% INPUTS:
% DATA: FIRST COLUMN IS PET (MM/DAY), SECOND COLUMN IS PRECIPITATION (MM/DAY)
% PARS: 4 PARAMETERS OF GR4J MODEL
% STATES: INITIAL STATES (VECTOR OF 2 ELEMENTS)
load STATES
DATE.PRECIP=halil_p
% OUTPUTS:
% SIM_TCI: TOTAL CHANNEL FLOW: MATRIX OF SIZE N*1, N REPRESENTING TIME STEPS
% SIM_GRND: GROUND FLOW: FROM ROUTING RESERVOIR
% SIM_SURF: SURFACE FLOW: FROM DIRECT RUNOFF
% SIMET: SIMULATED EVAPOTRANSPIRATION: MATRIX OF SIZE N*1
% SIMSTATES: SIMULATED STATES: MATRIX OF SIZE N*2,  N REPRESENTING TIME STEPS AND 2 REPRESENTING THE NUMBER OF MODEL STATES
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                            REFERENCES
% REF1: Perrin, Charles, Claude Michel, and Vazken Andréassian. "Improvement of a parsimonious model for streamflow simulation." Journal of Hydrology 279.1 (2003): 275-289.
% FORTRAN SOURCE CODE OF GR4J CAN BE FOUND IN THE R PACKAGE AVAILABLE AT:
% http://webgr.irstea.fr/modeles/journalier-gr4j-2/?lang=en
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% MATLAB code developed by Mojtaba Sadegh (msadegh@uci.edu) and Amir AghaKouchak,
% based on the original FORTRAN code
% on July 27, 2016
% Center for Hydrometeorology and Remote Sensing (CHRS)
% University of California, Irvine
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ACCORDING TO REF1, PAGE 280, RIGHT COLUMN, PARAGRAPH 3, D = 2.5 IS THE OPTIMAL VALUE
D = 2.5;
% DEFINE A PARAMETER NH THAT GOVERNS LENGTH OF UH1 (SHOULD BE LONG ENOUGH)
NH = 20;
% ESTIMATE ORDINATES OF UH1 & UH2 (ROUTING UNIT HYDROGRAPHS)
ORDUH1 = UH1(PARS(4), D, NH); ORDUH2 = UH2(PARS(4), D, NH);
% INITIALIZE STUH1 & STUH2
STUH1 = zeros(NH,1); STUH2 = zeros(2*NH,1);

% DIVIDE DAY INTO DN PARTS
DN = 1;

% PREASSIGN A MATRIX OF SIMSTATES
SIMSTATES = nan(size(DATA.PRECIP,1),4);
% PREASSIGN VARIABLES
[SIMFLUXES.TCI, SIMFLUXES.GRND, SIMFLUXES.SURF, SIMFLUXES.ET] = deal( nan(size(DATA.PRECIP,1),DN) );
% ASSIGN INITIAL VALUE OF THE STATE
SSNOW = STATES(4);

for ii = 1:size(DATA.PRECIP,1)
    
    % HANDLE NONSTATIONARY PARAMETER: IF EXISTS
    if isfield(DATA, 'TIMEVARYING_PAR')
        if ~isempty(DATA.TIMEVARYING_PAR)
            if ii <= DATA.TIMEVARYING_START_IDX
                PARS(DATA.TIMEVARYING_PAR) = DATA.TIMEVARYING_START_VALUE;
            elseif ii > DATA.TIMEVARYING_START_IDX && ii < DATA.TIMEVARYING_FINISH_IDX
                PARS(DATA.TIMEVARYING_PAR) = DATA.TIMEVARYING_START_VALUE + (DATA.TIMEVARYING_FINISH_VALUE - DATA.TIMEVARYING_START_VALUE)/(DATA.TIMEVARYING_FINISH_IDX - DATA.TIMEVARYING_START_IDX) * (ii - DATA.TIMEVARYING_START_IDX);
            elseif ii >= DATA.TIMEVARYING_FINISH_IDX
                PARS(DATA.TIMEVARYING_PAR) = DATA.TIMEVARYING_FINISH_VALUE;
            end
        end
    end
    
    % DIVIDE DAY INTO DN SECTIONS
    for jj = 1:DN
        % ASSIGN PET & PRECIP & TEMPERATURE
        PET = 1/DN * DATA.PET(ii,1);
        P = 1/DN * DATA.PRECIP(ii,1);
        T = DATA.TEMP(ii,1);
        
        % RUN SNOW MODULE TO QUANTIFY LIQUID WATER (NEW P)
        DD = PARS(7); % DEGREE DAY
        [P,SSNOW] = SNOW_MODULE(DD,0,P,T,SSNOW);
        
        % RUN GR6J FOR ONE STEP
        [Q,QR,QD,SIMET,STATES,STUH1,STUH2] = GR6J_main(STATES,STUH1,STUH2,ORDUH1,ORDUH2,PARS,P,PET,NH);
        % TOTAL CHANNEL FLOW
        SIMFLUXES.TCI(ii,jj) = Q;
        % ROUTED FLOW
        SIMFLUXES.QR(ii,jj) = QR;
        % DIRECT FLOW
        SIMFLUXES.QD(ii,jj) = QD;
        % SIMULATED ET
        SIMFLUXES.ET(ii,jj) = SIMET;
    end
    % STORE STATES
    SIMSTATES(ii,1) = STATES(1);
    SIMSTATES(ii,2) = STATES(2);
    SIMSTATES(ii,3) = STATES(3);
    SIMSTATES(ii,4) = SSNOW;
end
NS=1-sum((SIMFLUXES.TCI-DATA.FLOW).^2)/sum((DATA.FLOW-mean(DATA.FLOW)).^2)
csvwrite('OF.out',NS)
% exit
%end

function [Q,QR,QD,SIMET,STATES,STUH1,STUH2] = GR6J_main(STATES,STUH1,STUH2,ORDUH1,ORDUH2,PARS,P,PET,NH)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUTS:
% STATES: THE 2 STATES OF GR4J AT THE BEGINING OF TIME STEP (mm)
% STUH1: UH1 AT THE BEGINING OF TIME STEP (mm)
% STUH2: UH2 AT THE BEGINING OF TIME STEP (mm)
% ORDUH1: ORDINATES OF UH1 (-)
% ORDUH2: ORDINATES OF UH2 (-)
% PARS: MODEL PARAMETER VALUES
% P: PRECIPITATION (mm/day)
% EP: POTENTIAL EVAPOTRANSPIRATION (mm/day)
%
% OUTPUTS:
% Q: TOTAL FLOW (mm)
% QR: ROUTED FLOW (mm)
% QD: DIRECT FLOW (mm)
% SIMET: SIMULATED EVAPOTRANSPIRATION (mm)
% STATES: THE 2 STATES OF GR4J AT THE END OF TIME STEP (mm)
% STUH1: UH1 AT THE END OF TIME STEP (mm)
% STUH2: UH2 AT THE END OF TIME STEP (mm)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FRACTION OF PR GOING TO UH1: ACCORDING TO REF1, PAGE 280, RIGHT COLUMN, PARAGRAPH 3
B = PARS(8)%0.9;
C = 0.4;

%% SIMULATE INTERCEPTION AND PRODUCTION STORE
% IF PRECIP IS LESS THAN PET, NOTHING IS CONTRIBUTED TO THE PRODUCTION STORE
if P <= PET
    % NET EVAPOTRANSPIRATION CAPACITY
    EN = PET - P;
    % NET PRECIPITATION
    PN = 0;
    % "NET EVAPOTRANSPIRATION CAPACITY" DIVIDED BY "MAX CAPACITY OF PRODUCTION STORE" USED IN EQ 4 OF REF1
    WS = EN/PARS(1);
    % SET A MAX OF 13 FOR WS
    WS = min(WS, 13);
    % TANH PART OF EQ 4
    TWS = tanh(WS);
    % PRODUCTION STORE LEVEL DIVIDED BY ITS MAX USED IN EQ 4
    SR = STATES(1)/PARS(1);
    % EVAPORATION FROM PRODUCTION STORE (NAMED ES IN REF1, EQ 4)
    ER = ( STATES(1)*(2-SR)*TWS ) / ( 1+(1-SR)*TWS );
    % SIMULATED ET: SUMMATION OF PRECIP AND THAT PORTION FROM PRODUCTION STORE
    SIMET = ER + P;
    % UPDATE STATES
    STATES(1) = STATES(1) - ER; %STATES(1) = max( STATES(1), 0 );
    % NO WATER GOES TO ROUTING IN THIS CASE
    PR = 0;
else
    % NET EVAPOTRANSPIRATION CAPACITY
    EN = 0;
    % SIMULATED EVAPOTRANSPIRATION
    SIMET = PET;
    % NET PRECIPITATION
    PN = P - PET;
    % "NET PRECIPITATION" DIVIDED BY "MAX CAPACITY OF PRODUCTION STORE" USED IN EQ 3 OF REF1
    WS = PN/PARS(1);
    % SET A MAX OF 13 FOR WS
    WS = min(WS, 13);
    % TANH PART OF EQ 3
    TWS = tanh(WS);
    % PRODUCTION STORE LEVEL DIVIDED BY ITS MAX USED IN EQ 3
    SR = STATES(1)/PARS(1);
    % PORTION OF PN THAN FILLS PRODUCTION STORE AS IN EQ 3 OF REF1
    PS = ( PARS(1)*(1-SR^2)*TWS ) / ( 1+SR*TWS );
    % AMOUNT OF WATER GOING TO ROUTING DIRECTLY FROM PN
    PR = PN - PS;
    % UPDATE STATES
    STATES(1) = STATES(1) + PS; %STATES(1) = max( STATES(1), 0 );
end

%% SIMULATE PRODUCTION STORE (PERCOLATION) EQ 6 OF REF1
STATES(1) = max( STATES(1), 0 );
PERC = STATES(1) * (  1 - ( 1 + (4/9 * STATES(1)/PARS(1))^4 )^(-0.25)  );

% UPDATE STATES
STATES(1) = STATES(1) - PERC; %STATES(1) = max( STATES(1), 0 );

% ADD PERCOLATION TO THE AMOUNT OF WATER GOING TO ROUTING DIRECTLY FROM PN
% PR REPRESENTS EFFECTIVE RAINFALL
PR = PR + PERC;

%% SPLIT EFFECTIVE RAINFALL (PR) BETWEEN TWO ROUTING COMPONENTS UH1 (90%) & UH2 (10%)
PRHU1 = B * PR; PRHU2 = (1 - B) * PR;

%% CONVOLUTION OF UNIT HYDROGRAPHS
% CONVOLUTION OF UH1
for j = 1:max(1, min( NH-1, ceil(PARS(4)) )),
    STUH1(j) = STUH1(j+1) + ORDUH1(j) * PRHU1;
end
STUH1(NH) = ORDUH1(NH) * PRHU1;

% CONVOLUTION OF UH2
for j = 1:max(1, min( 2*NH-1, 2*ceil(PARS(4)) )),
    STUH2(j) = STUH2(j+1) + ORDUH2(j) * PRHU2;
end
STUH2(2*NH) = ORDUH2(2*NH) * PRHU2;

%% INTERCATCHMENT SEMI-EXCHANGE, EQ 2 OF REF2
EXCH = PARS(2) * ( STATES(2)/PARS(3) - PARS(5) );

%% SIMULATE ROUTING STORE R
% FOLLOWING 4 LINES ARE NOT NECESSARY FOR MODELING Q
AEXCH1 = EXCH;
if ( STATES(2) + STUH1(1) + EXCH ) < 0,
    AEXCH1 = -STATES(2) - STUH1(1);
end

% STUH1(1) REPRESENTS Q9
% UPDATE STATES
STATES(2) = STATES(2) + (1 - C) * STUH1(1) + EXCH; STATES(2) = max(STATES(2), 0);
% OUTFLOW OF ROUTING RESERVOIR
QR = STATES(2) * (  1 - ( 1+(STATES(2)/PARS(3))^4 )^(-0.25)  ); %QR = max(QR, 0);
% UPDATE STATES
STATES(2) = STATES(2) - QR; %STATES(2) = max(STATES(2), 0);

%% SIMULATE EXPONENTIAL ROUTING STORE C
% UPDATE STATE
STATES(3) = STATES(3) + C * STUH1(1) + EXCH;
AR = STATES(3) / PARS(6); AR = min(AR, 33); AR = max(AR, -33);

% ESTIMATE QR1: QR2 IN FIGURE 2 OF REF 2
if AR > 7,
    QR1 = STATES(3) + PARS(6) / exp(AR);
elseif AR < -7,
    QR1 = PARS(6) * exp(AR);
else
    QR1 = PARS(6) * log( exp(AR) + 1 );
end

% UPDATE STATES
STATES(3) = STATES(3) - QR1;

%% SIMULATE DIRECT PORTION OF RUNOFF
% FOLLOWING 4 LINES ARE NOT NECESSARY FOR MODELING Q
AEXCH2 = EXCH;
if (STUH2(1) + EXCH) < 0,
    AEXCH2 = -STUH2(1);
end

% DIRECT RUNOFF: STUH2(1) REPRESENTS Q1
QD = max(STUH2(1)+EXCH, 0);

%% TOTAL RUNOFF
Q = QR + QD + QR1; Q = max( Q, 0 );
end

% ESTIMATE ORDINATES OF UH1 (ROUTING UNIT HYDROGRAPH) BASED ON SUCCESSIVE DIFFERENCES ON THE S CURVE SS2
function ORDUH1 = UH1(C,D,NH)
% C IS TIME CONSTANT (TIME BASE OF UH1), IDENTICAL TO PAR(4)
% D IS THE EXPONENT

% ESTIMATE ORDINATES OF UH1
for i = 1:NH
    ORDUH1(i) = SS1(i,C,D) - SS1(i-1,C,D);
end
end

% ESTIMATE ORDINATES OF UH2 (ROUTING UNIT HYDROGRAPH) BASED ON SUCCESSIVE DIFFERENCES ON THE S CURVE SS2
function ORDUH2 = UH2(C,D,NH)
% C IS TIME CONSTANT (TIME BASE OF UH1), IDENTICAL TO PAR(4)
% D IS THE EXPONENT

% ESTIMATE ORDINATES OF UH2
for i = 1:2*NH
    ORDUH2(i) = SS2(i,C,D) - SS2(i-1,C,D);
end
end

% ESTIMATE VALUES OF THE S CURVE (CUMALATIVE PROPORTION OF THE INPUT WITH TIME) OF UH1
function SH1 = SS1(i,C,D)
% C IS TIME CONSTANT (TIME BASE OF UH1), IDENTICAL TO PAR(4)
% D IS THE EXPONENT
% i IS THE TIME STEP

% SEE EQs 9-11 OF REF1
if i <= 0,
    SH1 = 0;
elseif i < C,
    SH1 = (i/C)^D;
else
    SH1 = 1;
end

end

% ESTIMATE VALUES OF THE S CURVE (CUMALATIVE PROPORTION OF THE INPUT WITH TIME) OF UH1
function SH2 = SS2(i,C,D)
% C IS TIME CONSTANT (TIME BASE OF UH1), IDENTICAL TO PAR(4)
% D IS THE EXPONENT
% i IS THE TIME STEP

% SEE EQs 9-11 OF REF1
if i <= 0,
    SH2 = 0;
elseif i <= C,
    SH2 = 0.5 * (i/C)^D;
elseif i <  2*C
    SH2 = 1 - 0.5 * (2 - i/C)^D;
else
    SH2 = 1;
end

end