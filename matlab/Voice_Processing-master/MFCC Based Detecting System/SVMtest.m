clc;
%% Train
FrameLen = 300;
FrameInc = 210;
ADR = 1;%not downsample
segment = 60;
do_feat_ext=true;%if extract testMFCC
model=modelTrain(segment,ADR,do_feat_ext);
%load 'D:\liblinear-2.1\matlab\MFCC\MFCCmodel.mat';
if (do_feat_ext)
    %% Read testData
    fprintf(1,'Start to read testData...\n');
    Truefiles = dir('D:\testdata_true\');
    Falsefiles = dir('D:\testdata_false\');
    Truefiles = Truefiles(3:end);
    Falsefiles = Falsefiles(3:end);
    y_true=[];
    y_false=[];
    %% Feature Extraction
    fprintf(1,'Start to get true testData...\n');
    for fn=1:length(Truefiles)
    filepath=fullfile('D:\testdata_true\',Truefiles(fn).name);
    [ start, stop, totalTime, audioOut, fsOut ] = getActiveSpeech( filepath, ADR, FrameLen, FrameInc);
    y_true=[y_true;audioOut(floor(start*fsOut):floor(stop*fsOut),1)];
    end
    MSPC_true=MFCC_feature(y_true,fsOut,segment);
    fprintf(1,'End to get true testData...\n');
    fprintf(1,'Start to get false testData...\n');
    for fn=1:length(Falsefiles)
    filepath=fullfile('D:\testdata_false\',Falsefiles(fn).name);
    [ start, stop, totalTime, audioOut, fsOut ] = getActiveSpeech( filepath, ADR, FrameLen, FrameInc);
    y_false=[y_false;audioOut(floor(start*fsOut):floor(stop*fsOut),1)];
    end
    MSPC_false=MFCC_feature(y_false,fsOut,segment);
    fprintf(1,'End to get false testData...\n');
    MSPC=[MSPC_true;MSPC_false];
    label=[ones(size(MSPC_true,1),1);zeros(size(MSPC_false,1),1)];
    save('D:\liblinear-2.1\matlab\MFCC\testData.mat','MSPC');
    save('D:\liblinear-2.1\matlab\MFCC\testLabel.mat','label');
end;
load 'D:\liblinear-2.1\matlab\MFCC\testData.mat';
load 'D:\liblinear-2.1\matlab\MFCC\testLabel.mat';
%% predict
fprintf(1,'Start modelTesting...\n');
[predict_label, accuracy, prob_estimates]=predict(label,sparse(MSPC),model);
fprintf(1,'End modelTesting...\n');
%[predict_label, accuracy, dec_values] = svmpredict(label, MSPC, model);
%accuracy=length(find(predict_label==label))/length(label)*100;
T_NUM=length(find(label==1));
F_NUM=length(label)-T_NUM;

flex_predict_label = predict_label;
for i=2:length(label)-1
    flex_predict_label(i) =( (predict_label(i-1)+predict_label(i)+predict_label(i+1))/3 > 1/2); 
end
predict_label = flex_predict_label;

TP=length(find(predict_label(1:T_NUM)==label(1:T_NUM)));
FP=length(find(predict_label(T_NUM+1:end)~=label(T_NUM+1:end)));

Precision=TP/(TP+FP)*100;
Recall=TP/T_NUM*100;
F_Measure=2/(100/Precision+100/Recall);

FAR = FP/F_NUM*100;
FRR = (T_NUM - TP)/T_NUM*100;

ex=length(find(predict_label==label));%tmp(:,k)
acc=ex*100/length(label);