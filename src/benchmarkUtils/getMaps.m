function [maps] = getMaps()
%GETMAPS Summary of this function goes here
%   Detailed explanation goes here

%{'BO:MES_VDP'}    {'BO:MES_ESVDP'}    {'BO:MES_ESTR'}    {'BO:MES_LumpedGPPred'}    {'BO:Rand'}    {'BO:Rand_ES'}



color = RWTHcolors();
%BO:MES_LumpedGPPredTrun
maps.dispName = containers.Map({'BO:MES_VDP','BO:MES_ESVDP','BO:MES_ESTR','BO:MES_LumpedGPPred','BO:MES_LumpedGPPred_Hypv2','BO:Rand_ES','BO:MES_LumpedGPPredNoise'  ,'BO:MES_LumpedGPPredTrun','BO:MES_LumpedGPPred_Trun','BO:MES_LumpedGPPred_MC','BO:MES_LumpedGPPredNoise_CN','BO:MES_VDP_CN','BO:MES_ESVDP_CN'  ,'BO:EI'   ,'BO:Rand','BO:EIOutDet','MatBO'   ,'BADS','fmincon','PatternSearch','GA','PSO'}...
                          , {'BO','ESBO-C',            'ESBO-TR'         ,'ESBO-GP'            ,'ESBO-GPv2'                ,'ESRS'        ,'ESBO-GP'                 ,'ESBO-GP-Trun'           ,'ESBO-GP-Trun'             ,'ESBO-GP','MES_LumpedGPPredNoise_CN','MES_VDP_CN','MES_ESVDP_CN','EI-SE-F' ,'RS'   ,'EI-SE-V'    ,'BayesOpt','BADS','Fmincon','PS','GA','PSO'});

maps.color    = containers.Map({'BO:MES_VDP','BO:MES_ESVDP'           ,'BO:MES_ESTR'        ,'BO:MES_LumpedGPPred','BO:MES_LumpedGPPred_Hypv2'    ,'BO:Rand_ES',      'BO:MES_LumpedGPPredNoise'           ,'BO:MES_LumpedGPPredTrun','BO:MES_LumpedGPPred_Trun','BO:MES_LumpedGPPred_MC','BO:MES_LumpedGPPredNoise_CN','BO:MES_VDP_CN',   'BO:MES_ESVDP_CN'        ,'BO:EI'       ,'BO:Rand',           'BO:EIOutDet'         ,'MatBO'          ,'BADS'          ,'fmincon'       ,'PatternSearch' ,'GA'          ,'PSO'}...
                             , {color.violett_100, color.blau_100     ,color.petrol_100     ,color.gruen_100      ,color.tuerkis_100             ,color.rot_100    ,color.gruen_100                  ,color.gelb_100           ,color.rot_100             ,color.gruen_100           ,color.bordeaux_100           ,color.violett_100,  color.lila_100  ,color.gruen_100 ,color.orange_100 ,color.maigruen_100,color.magenta_100,color.magenta_100,color.maigruen_100,color.magenta_100,color.magenta_100,color.magenta_100});

maps.symbol  = containers.Map({'BO:MES_VDP','BO:MES_ESVDP','BO:MES_ESTR','BO:MES_LumpedGPPred','BO:MES_LumpedGPPred_Hypv2','BO:Rand_ES','BO:MES_LumpedGPPredNoise','BO:MES_LumpedGPPred_Trun','BO:MES_LumpedGPPred_MC','BO:MES_LumpedGPPredNoise_CN','BO:MES_VDP_CN','BO:MES_ESVDP_CN'  ,'BO:UCB'  ,'BO:MES_LumpedGPPredTrun'   ,'BO:Rand','BO:EIOutDet','MatBO'   ,'BADS','fmincon','PatternSearch','GA','PSO'}...
                            , {'-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-'});
%, {'-o','-+','-*','-x','-s','-d','-^','-v','-p','-h','-<','->','-o','-+','-<','-s','-d'});

maps.latexTestcaseNo = [9 3 4 5 6 10 8 7 2 1]; 
maps.latexOrderInMat = [10 9 2 3 4 5 8 7 1 6]; 
maps.OptNo = [1:17]; 
% 0 means grid search 
maps.OptNo = [0 10 7 8 9 3 5 11 4 2 6 16 1 17 15 13 12 14 ];
                      
end

