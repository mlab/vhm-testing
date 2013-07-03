function pace_param=pacemaker_new(pace_param, A_get, V_get, pace_inter) %ventricular based, or atrial based LR timing
% This function update parameters for the pacemaker in one time stamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs:
% A_get: Boolean, Atrium event sensed. Signal generated by the interface
%        function
% V_get: Boolean, Ventricle event sensed. Signal generated by the interface
%        function
% pace_param: Struct, parameters for the DDD pacemaker
%       Notations:
%               Components and their corresponding outputs:
%                      name                             output
%               LRI(Lowest rate interval)                  A_pace
%               AVI(Atrialventricular interval)            V_pace
%               ARP(Atrium repolarization period)          A_sense
%               VRP(Ventricular repolarization period)     V_sense
%               URI(Upper rate Interval)                    none
%               VSP (Ventricular Safety Period)
%               PVARP (Post Ventricular Atrial Refractory Period)
%               
%
%    Parameters:
%    mode_switch: determines if can switch between modes ('on' or 'off')
%           mode: current pacemaker mode, can be either 'DDD' or 'VDI'
%        LRI_cur: Current LRI timer value (in milliseconds)
%        LRI_def: Default LRI timer value (in milliseconds)
% LRI_extend_avi: if LRI is in extended AVI ('on' if counting in extended
% AVI, 'off' if not)
%       pAVI_cur: = Current pacing AVI timer value (in milliseconds)
%       pAVI_def: = Default pacing AVI timer value (in milliseconds)
%       sAVI_cur: = Current sensing AVI timer value (in milliseconds)
%       sAVI_def: = Default sensing AVI timer value (in milliseconds)
%        AVI_cur: Current AVI timer value (in milliseconds)
%        AVI_def: Default AVI timer value (in milliseconds)
%            AVI: AVI state (either 'S' for sensing, 'P' for pacing, or 'off')
%         a_pace: atrial pacing mode (0 if not pacing, 1 if pacing)
%         v_pace: ventricular pacing mode (0, if not pacing, 1 if pacing)
%        a_sense: atrial sensing mode (0 if not sensing, 1 if sensing)
%        v_sense: ventricular sensing mode (0 is not sensing, 1 if sensing)
%          PVARP: PVARP state (either 'on' or 'off')
%            VRP: VRP state (either 'on' or 'off')
%            URI: URI state (either 'on' or 'off')
%       AF_count: amount of consecutive fast event counts i.e. when A-A
%       interval > AF_thresh before Pacemaker is switched to VDI mode.
%       AF_limit: total amount of consecutive fast A-A intervals that
%       defines Supraventricular Tachycardia.
%      AF_thresh: time in milliseconds between atrial events. Used to define if pacing is fast or slow ( A-A interval < thresh = slow, A-A interval > thresh =
%      fast)
%      PVARP_cur: Current PVARP timer value (in milliseconds)
%      PVARP_def: Default PVARP timer value (in milliseconds)
%        VRP_def: Default VRP timer value (in milliseconds)
%        VRP_cur: Current VRP timer value (in milliseconds)
%        URI_cur: Current URI timer value (in milliseconds)
%        URI_def: Default URI timer value (in milliseconds)
%            ABP: postatrialventricular blocking period (in milliseconds)
%          a_ref: atrial refractory signal (0 or 1)
%    AF_interval: measured time of A-A interval (in milliseconds)
%      VSP_sense: Ventricular sensing period = time delay between v_sense and v_pace
%            VSP: determines if VSP is used for v_pace. (otherwise wait until AVI) 
%           PAVB: Post atrialventricular blocking period (in milliseconds)
%            PVC: Premature ventricular complex (time in milliseconds)         
%          v_ref: venticular refractory signal (0 or 1);
%
%pace_inter: determines the step size (in milliseconds) of each iteration
%            of the function. This is generally 1 millisecond
%vsp_en: enables VSP. (0 to disable, 1 to enable)
%
% Outputs:
% pace_para: updated version of the input
% A_pace: Boolean, Atrial pacing signal sending to the interface function
% V_pace: Boolean, Ventricle pacing signal sending to the interface
% function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pace_para{6,1}: current pacemaker mode, can be either DDD or VDI
% pace_para{6,2}: mode switch function on/off,VSP on/off
% pace_para{6,3}: fast stimuli counts, will switch to VDI after count down
% to 0
% pace_para{6,4}: threshold for slow rate
% pace_para{6,5}: counter for intervals between consecutive atrial beats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% local signal variables
a_s=0;
a_p=0;
v_s=0;
v_p=0;
a_r=0;
v_r=0;
%% Two clocks
% A timer
if pace_param.a_sense || pace_param.a_pace
    pace_param.AT=0;
else
    pace_param.AT=pace_param.AT+1;
end

% V timer
if pace_param.v_sense || pace_param.v_pace
    pace_param.VT=0;
else
    pace_param.VT=pace_param.VT+1;
end
%% Filters
% A filter
if A_get
    if pace_param.AT>=pace_param.PAARP && pace_param.VT>=pace_param.PVARP
        a_s=1;
       
    end
    if pace_param.AT>=pace_param.PAAB && pace_param.AT<=pace_param.PAARP
        a_r=1;
    end
    if pace_param.VT>=pace_param.PVAB && pace_param.VT<=pace_param.PVARP
        a_r=1;
    end
    if pace_param.AT<=pace_param.PAAB
    end
    if pace_param.VT<=pace_param.PVAB
    end
end
       
% V filter
if V_get
    pace_param.PVARP=pace_param.PVARP_def;
    if pace_param.AT>=pace_param.VSP_thresh && pace_param.VT>=pace_param.PVVRP
        v_s=1;
    end
    if pace_param.VT>=pace_param.PVVB && pace_param.VT<=pace_param.PVVRP
        v_r=1;
        pace_param.PVARP=400;
    end
    if pace_param.AT<=pace_param.PAVB
    end
    if pace_param.AT<=pace_param.VSP_thresh
        pace_param.VSP=1;
    end
    if pace_param.VT<=pace_param.PVVB
    end
end

%% Paces
% A Pace
if pace_param.VT>=pace_param.TLRI-pace_param.TAVI && pace_param.AT>=pace_param.TLRI
    a_p=1;
  
end

% V Pace
if pace_param.VSP==1 && pace_param.AT>=110 && pace_param.A_det==1
    v_p=1;
    pace_param.VSP=0;
end
if pace_param.VT>=pace_param.TLRI
    v_p=1;
end
if pace_param.VSP==0 && pace_param.AT>=pace_param.TAVI && pace_param.VT>=pace_param.TURI && pace_param.A_det==1
    v_p=1;
end
%% update the local variables to global variables
% temp={a_p;v_p;a_s;v_s;0};
% temp=[pace_para(1:5,1:4),temp];
% pace_para=[temp;pace_para(6,:)];
pace_param.a_sense=a_s;
pace_param.a_pace=a_p;
pace_param.v_sense=v_s;
pace_param.v_pace=v_p;
pace_param.a_ref=a_r;
pace_param.v_ref=v_r;
if a_s || a_p
    pace_param.A_det=1;

end





