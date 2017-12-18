clc;
close all;
clear;

%% File read-in
v = VideoReader('./../../videos/1.mp4');
% Icons read-in
charaNamesArr = ["ana", "bastion", "doomfist", "dva", "genji", "hanzo", "junkrat", "lucio", "mccree", "mei", "mercy", "moira", "orisa", "pharah", "reaper", "reinhardt", "riptire", "roadhog", "soldier76", "sombra", "symmetra", "torbjon", "tracer", "widowmaker", "winston", "zarya", "zenyatta", "meka", "shield", "supercharger", "teleporter", "turret"];
iconsArr = {};
for i=1:size(charaNamesArr, 2)
    iconsArr{i} = imread(convertStringsToChars("./../../images/icons/" + charaNamesArr(i) + ".png"));
end

%% Elimination evens analysis
eventList = {struct, struct};
tic;
for time = 15.5:0.5:20
    v.CurrentTime = time;
    Itemp = readFrame(v);
    Itemp = imresize(Itemp, 1280/size(Itemp, 2)); % Rescale to width = 1280, currently consider 16:9 only

    charas = getKillEvents(Itemp, eventList, charaNamesArr, iconsArr);
    for i = size(charas, 1):-1:1
        chara1 = charas(i, 1); % left
        chara1{1}.player = "";
        chara1{1}.time = time;
        chara2 = charas(i, 2); % right
        chara2{1}.player = "";
        chara2{1}.time = time;
        if chara1{1}.name == "empty" && chara2{1}.name ~= "empty"
            eventList{end+1, 1} = chara1{1};
            eventList{end, 2} = chara2{1};
        elseif chara1{1}.name ~= "empty" && chara2{1}.name ~= "empty"
            if chara1{1}.name == "mercy" && chara1{1}.team == chara2{1}.team
                eventList{end+1, 1} = chara1{1};
                eventList{end, 2} = chara2{1};
            else
                eventList{end+1, 1} = chara1{1};
                eventList{end, 2} = chara2{1};
            end
        end
    end
end
toc

%% Killfeed console output
for i = 2:size(eventList, 1)
    chara1 = eventList(i, 1); % left
    chara2 = eventList(i, 2); % right
    if chara1{1}.name == "empty" && chara2{1}.name ~= "empty"
        fprintf('%s from team %i suicided at time %.1f(accuracy: %.2f)\n', chara2{1}.name, chara2{1}.team, chara1{1}.time, chara2{1}.coeff);
    elseif chara1{1}.name ~= "empty" && chara2{1}.name ~= "empty"
        if chara1{1}.name == "mercy" && chara1{1}.team == chara2{1}.team
            fprintf('%s from team %i resurrected %s from team %i at time %.1f(accuracy: %.2f, %.2f)\n',...
                chara1{1}.name, chara1{1}.team, chara2{1}.name, chara2{1}.team, chara1{1}.time, chara1{1}.coeff, chara2{1}.coeff);
        else
            fprintf('%s from team %i eliminated %s from team %i at time %.1f(accuracy: %.2f, %.2f)\n',...
                chara1{1}.name, chara1{1}.team, chara2{1}.name, chara2{1}.team, chara1{1}.time, chara1{1}.coeff, chara2{1}.coeff);
        end
    end
end

%% Killfeed file output
fileID = fopen('./../../results/killfeed.csv','w');
fprintf(fileID,'Time,Team1,Player1(Killer),Chara1(Killer),Player2(Resurrector),Chara2(Resurrector),Event,Team2,Player3(Killed),Chara3(Killed),Player4(Resurrected),Chara4(Resurrected)\n');
for i = 2:size(eventList, 1)
    chara1 = eventList(i, 1); % left
    chara1 = chara1{1};
    chara2 = eventList(i, 2); % right
    chara2 = chara2{1};
    if chara1.name == "empty" && chara2.name ~= "empty"
        fprintf(fileID, '%.1f, , , , , , Suicide, %i, %s, %s, , ,\n',...
            chara2.time, chara2.team, chara2.player, chara2.name);
    elseif chara1.name ~= "empty" && chara2.name ~= "empty"
        if chara1.name == "mercy" && chara1.team == chara2.team
            fprintf(fileID, '%.1f, %i, , , %s, %s, Resurrect, %i, , , %s, %s,\n',...
                chara2.time, chara1.team, chara1.player, chara1.name, chara2.team, chara2.player, chara2.name);
        else
            fprintf(fileID, '%.1f, %i, %s, %s, , , Eliminate, %i, %s, %s, , ,\n',...
                chara2.time, chara1.team, chara1.player, chara1.name, chara2.team, chara2.player, chara2.name);
        end
    end
end

fclose('all');
fprintf('Killfeed analysis outputed to /results/killfeed.csv.\n');
%% Ult states analysis
% [ults,ultsVar]= ultStates(Itemp);