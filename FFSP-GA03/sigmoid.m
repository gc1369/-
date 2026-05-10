clear;clc;
% 测试自适应交叉概率曲线
pcmax = 0.8;
pcmin = 0.5;

c0 = 9.903438;

% 平均适应值
fitvalue_avg =14 ;
%最大适应值
fitvalue_min =5 ;

x = fitvalue_min :0.1: fitvalue_avg;
 myFun =@(x)(pcmax - pcmin)./(1+exp(-c0 + 2*c0*(x-fitvalue_min)/(fitvalue_avg -fitvalue_min))) + pcmin;

y = myFun(x);

plot(x,y);
xlabel('适应值');
ylabel('交叉概率');
