function [timeDomainRes] = zeitbereichsInfo(controlParam)


kp= controlParam(1,1); ki= controlParam(1,2);
simout = sim('Dreitank','SrcWorkspace','current');

tstart = 5;     % start of reference jump
tend   = 100;    % end of reference jump 

withinEpisodeInds = simout.waterLevels.time >= tstart & simout.waterLevels.time <= tend;



timeDomainRes.kp = kp;
timeDomainRes.ki = ki;


timeDomainRes.time        = simout.waterLevels.time(withinEpisodeInds);
timeDomainRes.waterLevel1 = simout.waterLevels.signals.values(withinEpisodeInds,1)*100;
timeDomainRes.waterLevel2 = simout.waterLevels.signals.values(withinEpisodeInds,2)*100; 
timeDomainRes.waterLevel3 = simout.waterLevels.signals.values(withinEpisodeInds,3)*100; 
timeDomainRes.refLevel3   = simout.reference.signals.values(withinEpisodeInds)*100;
timeDomainRes.pumpCmd     = simout.pumpCmd.signals.values(withinEpisodeInds);





end