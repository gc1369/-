%% 输入best_individual,运行解码函数，使用机器开始时间，结束时间，最大完工时间,输出甘特图
function gantt(best_individual)
global K Mac_nb n m Mk;
    [max_finish,~,end_time,start_time,mac_Jn] = decode(best_individual);
    % 初始化矩阵和数组
    mac_start = cell(1,Mac_nb);
    mac_end = cell(1,Mac_nb);
    mac_serial = cell(1,Mac_nb);%     mac_serial = cell(1,10);

    %% 转换数据储存形式

    %mac_Jn 转为 mac_serial,n*k 的数组改为1*Mac_nb的数组

        for j = 1:m % 工序
            for i = 1: K(j)% 
                    mac_serial{ 1 ,i+Mk(1,j)-1 } = mac_Jn{j,i};              
                    B = j*ones(length(mac_Jn{j,i}),1);
                    mac_serial{1,i+Mk(1,j)-1 } = horzcat(mac_serial{1,i+Mk(1,j)-1 },B);
            end  
        end      

    % end_time和start_time由mac_Jn索引导出mac_start和mac_end              
           for j = 1:m 
                for k =  1:K(j) %1到3个机器                
                    for i = 1:length(mac_Jn{j,k})
                        mac_end{1,Mk(1,j)+k-1}(1,i) = end_time(mac_Jn{j,k}(i),j); 
                        mac_start{1,Mk(1,j)+k-1}(1,i) = start_time(mac_Jn{j,k}(i),j);
                    end           
                end
           end    

    %% 绘图
    axis([0,max_finish,0,Mac_nb+0.5]);%x轴 y轴的范围
    X = [0:30:max_finish-5,max_finish];% x轴的增长幅度以及最大值,根据输出图形修改此处
    set(gca,'xtick',X) ; 
    set(gca,'ytick',0:1:Mac_nb+0.5) ; % y轴的增长幅度
    xlabel('加工时间','FontName','微软雅黑','Color','b','FontSize',10)
    ylabel('机器号','FontName','微软雅黑','Color','b','FontSize',10,'Rotation',90)
    title('甘特图','fontname','微软雅黑','Color','b','FontSize',16);%图形的标题
    color=rand(n,3);%生成随机的颜色,并使其方差和大于0.3，防止出现多个相似颜色

    while sum(var(color))<0.26
        color=rand(n,3);
    end
    for i=1:Mac_nb
        for j=1:length(mac_start{i})
            rec=[mac_start{i}(j),i-0.3,mac_end{i}(j)-mac_start{i}(j),0.6];%设置矩形的位置，[矩形左下顶点的x坐标，y坐标，长度，高度]
            txt=sprintf('p(%d,%d)=%3.1f',mac_serial{i}(j,1),mac_serial{i}(j,2),mac_end{i}(j)-mac_start{i}(j));
            %将工序号，加工时间连城字符串
            rectangle('Position',rec,'LineWidth',0.5,'LineStyle','-','FaceColor',color(mac_serial{i}(j,1),:));%画每个矩形  
            text(mac_start{i}(j)+0.2,i,txt,'FontWeight','Bold','FontSize',10);%在矩形上标注工序号，加工时间
        end
    end    
    
end