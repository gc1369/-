%绘制甘特图
function f = ganttChart1(J,P_chromosome,M,mac_t)
    P=P_chromosome(1,1:size(P_chromosome,2)-6);
    p_text=[];%记录工件的工序信息
    m_info=[];%记录设备的加工信息
    p_color=[];%颜色信息
    color=['r','g','b','c','m','y'];
    for i=1:size(J,2)
        p_index=find(P==i);
        color_i=mod(i,6)+1;
        for j=1:size(p_index,2)
            p_var=p_index(j);
            p_text(p_var)=j;
            p_color(p_var)=color_i;
        end
    end
    for i=1:J(1).num_mac
        m_index=find(M==i);
        if size(m_index,1)>=1 && size(m_index,2)>=1
            for j=1:size(m_index,2)
                m_var=m_index(j);
                m_info(m_var)=j;
            end
        end
    end
    n_bay_nb=J(1).num_mac;%total bays  //机器数目
    n_task_nb=length(P);
    c_time=P_chromosome(size(P,2)+1);%所需的消耗时间
    d_time=P_chromosome(size(P,2)+2);%延期时间
    e_load=P_chromosome(size(P,2)+3);%设备负荷
    e_cons=P_chromosome(size(P,2)+4);%能量消耗
    axis([0,P_chromosome(size(P,2)+1)+2,0,n_bay_nb+0.5]);%x轴 y轴的范围
    set(gca,'xtick',0:2:c_time) ;%x轴的增长幅度
    set(gca,'ytick',0:1:n_bay_nb+0.5) ;%y轴的增长幅度
    xlabel('加工时间'),ylabel('机器号');%x轴 y轴的名称
    sche_info=sprintf('最大完工时间:%d  总延期:%d 设备总负载:%d 能耗总量:%.2fKw/h',c_time,d_time,e_load,e_cons)
    title(sche_info);%图形的标题
    rec=[0,0,0,0];
    for i =1:n_task_nb  
        rec(1) = mac_t{M(i)}(m_info(i),1);%矩形的横坐标
        rec(2) = M(i)-0.3;%矩形的纵坐标
        rec(3) = mac_t{M(i)}(m_info(i),2)-mac_t{M(i)}(m_info(i),1);%矩形的x轴方向的长度
        rec(4) = 0.6; 
        txt=sprintf('p(%d,%d)=%d',P(i),p_text(i),mac_t{M(i)}(m_info(i),2)-mac_t{M(i)}(m_info(i),1));%将机器号，工序号，加工时间连城字符串
        rectangle('Position',rec,'LineWidth',0.5,'LineStyle','-','FaceColor',color(p_color(i)));%draw every rectangle  
        text(mac_t{M(i)}(m_info(i),1)+0.2,M(i),txt,'FontWeight','Bold','FontSize',14);%label the id of every task  ，字体的坐标和其它特性
    end
end
