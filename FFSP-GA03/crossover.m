function newpop = crossover(dad,mom)
    pc = 0.8;
    global n m pop_size;
    
        % 动态交叉概率自适应函数 pc为交叉概率
        pcmax = 0.7;      pcmin = 0.3;        c0 = 9.903438;
        [fitvalue_v,~,~] = fitnessfun(dad); % fc为父代中个体
        fitvalue_avg = sum(fitvalue_v)/pop_size; %平均favg
        fitvalue_min = min(fitvalue_v); % fmin 
        myFun =@(x)(pcmax - pcmin)./(1+exp(-c0 + 2*c0*(x-fitvalue_min)/(fitvalue_avg -fitvalue_min))) + pcmin;
        % x =fivalue    
        % 父代种群第i个个体适应度如果优于平均值则减小概率，否则取pcmax
    for i=1:pop_size   
        
        pc = pcmax + pcmin - myFun(fitvalue_v(i));    
        
        if rand<pc %如果随机数小于交叉概率，则执行交叉操作
            cpoint = randi([1 m-1]); % 随机选择一个交叉点 cpoint
            newpop((i-1)*n+1:i*n,:) = [dad((i-1)*n+1:i*n,1:cpoint) mom((i-1)*n+1:i*n,cpoint+1:end)];
            %将父代和母代的基因组信息在交叉点处进行切割，
            %并将父代的前半部分和母代的后半部分组合成新的个体，存储在 newpop_matrix 中
            %父代工序12加母代工序3生成新种群
        else
            newpop((i-1)*n+1:i*n,:) = dad((i-1)*n+1:i*n,:);
            % 如果随机数大于交叉概率，则直接将父代的基因组信息复制到新的个体中
        end
               
    end
end

