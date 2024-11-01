% the main function of DAEA
% the data set is in the file /dataset e.g.: dataset/9Tumor.mat 
% the results are saved as a .mat file, and main results are:
%     unionPF is the PF of the final population
%     unionPFfit is the object function (size of features and the error rate on test set)
% If you want to run DAEA in a new data set:
%      add the data set name into dataNameArray (see in line 4)
%      add the data set file into //dataset
clc
clear
tic;
algorithmName = 'DAEA';  
dataNameArray = {'colon'}; %data set
global maxFES
maxFES = 100;  % max number of iteration
global choice
choice = 0.6; % the threshold choose features
global sizep
sizep = 300; % size of population
%%%%%%%%%%%%
global LOOCV
LOOCV = 1; % use 10fold when LOOCV = 1
global fold
fold = 5;
%%%%%%%%%%%%
if LOOCV == 1 
    iterator = 5;
else
    iterator = 0;
end
global CNTTIME
CNTTIME = maxFES*iterator;
% ...之前的代码...

for data = 1:length(dataNameArray)
    clc
    clearvars -except dataNameArray data algorithmName maxFES choice sizep iterator LOOCV fold
    outcome = cell(iterator,8);
    errorOnTest = zeros(iterator,2);
    aveTrain1 = 0;
    aveTrain2 = 0;
    unionPF = [];
    unionPFfit = [];
    aveunionPF = [0 0];
    for i = 1:iterator
        fprintf('-----Now: %d-----\n',i);
        dataName = dataNameArray{data};
        if LOOCV == 1
            fprintf('LOOCV\n');
            [train_F,train_L,test_F,test_L] = DIVDATA5fold(dataName, i);  %read data
        else
            [train_F,train_L,test_F,test_L] = DIVDATA37(dataName);
        end
        % return cell "outcome" as results, DAEA is the algorithm
        [outcome{i,1},outcome{i,2},outcome{i,3},outcome{i,4},outcome{i,5},outcome{i,6},outcome{i,7}] = DAEA(train_F,train_L,maxFES,sizep);
 
        ofit = outcome{i,4};
        Tsite = outcome{i,5};
        Toff = outcome{i,3};
        Tgood = Toff(Tsite,:);
        unionPF = [unionPF;Tgood];
        tempE = 0;
        tempF = 0;
        for j = 1:size(Tgood,1) % test population "unionPF" on test set
            FeatureSubset = Tgood(j,:);
            CInsTrain = train_F;
            CInsTrain(:,~FeatureSubset) = 0;
            mdl = ClassificationKNN.fit(CInsTrain,train_L,'NumNeighbors',5);
            [label] = predict(mdl,test_F);
            Popscore = 0;
            for k = 1:size(test_F,1)
                if label(k) == test_L(k)
                    Popscore = Popscore+1;
                end
            end
            temp1 = 1-Popscore/size(test_F,1);
            temp2 = sum(FeatureSubset);
            tempE = tempE + temp1;
            tempF = tempF + temp2;
            unionPFfit = [unionPFfit;[temp1 temp2]]; %unionPFfit 
        end
        errorOnTest(i,1) = tempE/size(Tgood,1); %errorOnTest
        errorOnTest(i,2) = tempF/size(Tgood,1);
        aveTrain1 = aveTrain1 + outcome{i,6}(1);
        aveTrain2 = aveTrain2 + outcome{i,6}(2);
        
        % Identify and print the first Pareto front for this iteration
        [FrontNOunion,~] = NDSort(unionPFfit(:,1:2),size(unionPFfit,1));
        siteunionPF = find(FrontNOunion == 1);
        if ~isempty(siteunionPF)
            fprintf('First Pareto Front for iteration %d:\n', i);
            disp(unionPFfit(siteunionPF, :));
        else
            fprintf('No Pareto Front found for iteration %d.\n', i);
        end
    end
    aver_errorOnTest = mean(errorOnTest); %
    aveTrain1 = aveTrain1/iterator;
    aveTrain2 = aveTrain2/iterator;
    [FrontNOunion,~] = NDSort(unionPFfit(:,1:2),size(unionPFfit,1));
    siteunionPF = find(FrontNOunion ==1);  
    aveunionPF = mean(unionPFfit(siteunionPF,:)); %
    disp(min(unionPFfit(:,1)));
    clear CLinsTrain label mdl Popscore temp1 temp2 tempE tempF test_F test_L train_F train_L j k
    savename = [algorithmName '-' dataNameArray{data}]; 
    save(savename);% the results is saved 
    % unionPF is the PF of the final population
    % unionPFfit is the object function (size of features and the error rate on test set)

    % Output the First Pareto Front for all iterations
    fprintf('First Pareto Front for all iterations:\n');
    disp(unionPFfit(siteunionPF, :));
end
toc;
