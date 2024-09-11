function [Case] = getCases(testcases)
%GETCASES Summary of this function goes here
%   Detailed explanation goes here
for i = 1:length(testcases)
    switch testcases{i}
        %% Simulation experiments
        case 'ThreeTankPI2Var' %!
            Case{i} = getThreeTankPI2Var();
        case 'PIDPTS23Var' %!
            Case{i} = getPT2DeatTimePID3Var();
        case 'CartPoleLQR4Var'
            Case{i} = getCartPoleStateFeedback4Var();
        case 'BoilerBangBang1Var' %!
            Case{i} = getBoilerBangBang1Var();
        case 'ThreeTankMPC5Var'
            Case{i} = getThreeTankMPC5Var();
        
            %% Three tank experiments:
        case 'ThreeTankExpSimTestPI2Var'
            Case{i} = getThreeTankExpSimTestPI2Var();
        case 'ThreeTankExpPI2Var'
            Case{i} = getThreeTankExpPI2Var();      
        otherwise
            error('unknown Testcase')
    end
end
end

