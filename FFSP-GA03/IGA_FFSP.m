%% 柔性流水车间调度  遗传算法
function  [T,E,F] = IGA_FFSP()
clc;clear all;
% 定义全局变量与符号说明
global time %用时矩阵
global power % 能耗矩阵
global n % n 为工件个数
global pop_size % 种群规模
global m % 工序数量
global K % 第m工序可选km台机器
global Mac_nb % Mac_nb为机器总数
global Mk %对应开始和结束机器序号

%% 模型数据设置 与读取
load('time.mat') % 加工时长time矩阵
load('Pj_K.mat')  % 加工工序Pj对应的并行机数量 存储于向量K
load('power.mat') % 能耗矩阵power

%% 算法参数设置
pop_size = 300;  % 种群规模
maxgen = 50; % 进化代数

% 由K转换为Mk 工序对应开始和结束机器序号
% 对于工序j Mk(1,q)为起始,Mk(2,q)为结束
[n,Mac_nb] = size(time); % n为工件个数,Mac_nb为机器总数
m = length(K);% m为工序数
Mk = zeros(2,m);Mk(1,1) = 1;Mk(2,1) = K(1); 
for i = 2:m
    Mk(1,i) = Mk(2,i-1)+1;
    Mk(2,i) =  Mk(1,i) + K(i) - 1;
end

%% 初始化种群
pop = zeros(pop_size*n,m);
% 整数表示采用机器，小数表示加工机器
for q=1:pop_size 
    for i=1:n 
        for j = 1:m
            pop((q-1)*n+i,j)=randi([Mk(1,j),Mk(2,j)])+0.1*randi([0,9]);
        end
    end
 end

BestFit = zeros(maxgen,1); % 初始化矩阵，记录全局最优值，列向量
for i=1:maxgen % 迭代
    %% 计算适应度值
    [fitvalue_v,~,~] = fitnessfun(pop);%调用适应度函数
    BestFit(i) = min(fitvalue_v); % 每一次迭代中都找到pop个适应值中最小值
    %一共迭代maxgen次，也就是在pop*maxgen个解中找最优，最小化最大完工时间      
    [dad,mom] = selection(pop,fitvalue_v);%% 选择     
    newpop = crossover(dad,mom); %% 交叉   
    newpop = mutation(newpop);%% 变异
    pop = newpop;      
end

[fitvalue_v,max_finish_v,energySum_v] = fitnessfun(pop);%最后一代适应度
% 计算交叉变异后的最优种群适应度并将结果存储在fitvalue中。
[min_fitvalue_v,minindex] = min(fitvalue_v);
% 使用min函数找到个体适应度值向量中的最小值及其对应的索引，索引可以找到第几个个体
% min_fitvalue_v存储了最短的加工时长，而minindex存储了具有最短加工时长的个体在种群中的索引

disp(strcat('方案完工时长为：',num2str(max_finish_v(minindex))));
disp(strcat('方案总能耗为：',num2str(energySum_v(minindex))));
%以字符串形式显示结果
T = max_finish_v(minindex);
E = energySum_v(minindex);
F = min_fitvalue_v;
best_individual = pop((minindex-1)*n+1:minindex*n,:);%根据索引找到第几个个体
% fprintf('最合适加工方案为：');
% best_individual

%% 绘图 算法迭代收敛图,柔性流水车间甘特图
figure;
x = 1:maxgen;
plot(x,BestFit,'linewidth',1.2);
xlabel('迭代次数');  
ylabel('适应值');
title('IGA算法迭代收敛图');
figure;
gantt(best_individual);

end
    




