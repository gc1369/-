function newpop = mutation(pop) %两点点变异
    global n m pop_size Mk;
    pm = 0.25; % 变异概率
    
      % 动态交叉概率自适应函数 pc为交叉概率
        pmmax = 0.5;      pmmin = 0.2;        c0 = 9.903438;
        [fitvalue_v,~,~] = fitnessfun(pop);
        fitvalue_avg = sum(fitvalue_v)/pop_size; %平均favg
        fitvalue_min = min(fitvalue_v); % fmin 
        myFun =@(x)(pmmax - pmmin)./(1+exp(-c0 + 2*c0*(x-fitvalue_min)/(fitvalue_avg -fitvalue_min))) + pmmin; % x =fivalue    
         % 新种群第i个个体适应度如果优于平均值则减小概率，否则取pmmax
    for i=1:pop_size
        
        pm = pmmax + pmmin - myFun(fitvalue_v(i));  
        
        randrow = randi([(i-1)*n+1 i*n]); %随机选择行
        randcol =randi([1 m]); % 随机选择列
        
        if rand<pm  %  如果随机数小于变异概率，则执行变异操作
            pop(randrow,randcol) = randi([Mk(1,randcol), Mk(2,randcol)]) + 0.1*randi([0 9] );
            newpop((i-1)*n+1:i*n,:) = pop((i-1)*n+1:i*n,:);
            %     首先随机选择一个基因位置，
            %     然后随机生成一个新的基因值，并将其替换原来的基因值
        else  % 如果随机数大于变异概率，则直接将种群的基因组信息复制到新的种群中
            newpop((i-1)*n+1:i*n,:) = pop((i-1)*n+1:i*n,:);
            
        randrow = randi([(i-1)*n+1 i*n]); %随机选择行
        randcol =randi([1 m]); % 随机选择列
        
        if rand<pm  %  如果随机数小于变异概率，则执行变异操作
            pop(randrow,randcol) = randi([Mk(1,randcol), Mk(2,randcol)]) + 0.1*randi([0 9] );
            newpop((i-1)*n+1:i*n,:) = pop((i-1)*n+1:i*n,:);
            %     首先随机选择一个基因位置，
            %     然后随机生成一个新的基因值，并将其替换原来的基因值
        else  % 如果随机数大于变异概率，则直接将种群的基因组信息复制到新的种群中
            newpop((i-1)*n+1:i*n,:) = pop((i-1)*n+1:i*n,:);    
            
        end 
    end
end