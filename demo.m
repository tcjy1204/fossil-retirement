% codes for fossil fuel infrastructure retirement sequencing
% data for running the codes are stored in the file: code and data
% change the paths in the codes below for running codes on other computers
clear;clc;
tic
current_path = fileparts(mfilename('fullpath'));
%% coal Stated Policies
path=fullfile(current_path, 'coal.xlsx');
path1=fullfile(current_path, 'futureproduction.xlsx');
pathtcs=fullfile(current_path, 'coal\STEPS.xlsx');
coal_d0=xlsread(path,'23','d2:i1266');% emission/yr,coal output/yr, and workforce of each coal mine
latlon=xlsread(path,'23','b2:c1266');
procode=xlsread(path,'23','w2:w1266');
l=size(coal_d0,1);
t=ones(l,1);% 1 for sites with output
coal_d=[coal_d0,t,coal_d0(:,2),latlon,procode];%11 column
coal_d2=coal_d;
coal_ew=xlsread(path1,'coal','k5:k31');% future coal production
coal_ew2=coal_ew-910.7473617;% exclude coal that are not covered by inventory
coal_r=-(coal_ew2-sum(coal_d(:,2)));%reduction in inventory needed
per=2024:1:2050;% period span
lper=size(per,2);
pei=xlsread(path,'23','m2:m1266');%emission inensity of production tCO2e/t
% sorted by output
o_nc_o=zeros(l,lper);% output reduction by natural closure
o_pf_o=zeros(l,lper);% output reduction by carbon tax-driven closure
o_fo_o=zeros(l,lper);% output reduction by directly forced closure
e_nc_o=zeros(l,lper);% emission reduction by natural closure
e_pf_o=zeros(l,lper);% emission reduction by carbon tax-driven closure
e_fo_o=zeros(l,lper);% emission reduction by directly forced closure
op=xlsread(path,'23','j2:j1266');%original environmental cost without carbon tax
cart=xlsread(path1,'carbontax','j5:k31');%carbon tax 2030-2050
pf=zeros(l,lper);% environmental cost with carbon tax for production emission
spf=zeros(l,lper);% environmental cost with carbon tax for all emission
tpf=zeros(l,lper);
coalemo=zeros(l,lper);
coalomo=zeros(l,lper);
coallmo=zeros(l,lper);
coalpfmo=zeros(l,lper);
coalomob=zeros(l,lper);
lato=zeros(l,lper);
lono=zeros(l,lper);
procodeo=zeros(l,lper);
for i=1:lper % 24-50
    pf(:,i)=op-pei.*cart(i,1);
    spf(:,i)=coal_d(:,5).*cart(i,1);%environmental cost considering all emissions
    tpf(:,i)=spf(:,i).*coal_d(:,2);% total environmental cost M CNY
    coal_d=[coal_d2, tpf(:,i)];% 12 col
    for j=1:l
        if coal_d(j,6)<=i% no resources
            o_nc_o(j,i)=coal_d2(j,2);
            e_nc_o(j,i)=coal_d2(j,1);
            coal_d(j,7)=0;
            coal_d(j,1)=0;
            coal_d(j,2)=0;
            coal_d(j,3)=0;
            coal_d(j,12)=0;
        end
        if pf(j,i)<=0 && coal_d(j,6)>i% stranded by carbon tax
            o_pf_o(j,i)=coal_d2(j,2);
            e_pf_o(j,i)=coal_d2(j,1);
            coal_d(j,7)=0;
            coal_d(j,1)=0;
            coal_d(j,2)=0;
            coal_d(j,3)=0;
            coal_d(j,12)=0;
        end
    end
    coal_d_so=sortrows(coal_d,[7 8 -4]);% sorted by status, output and depth
    coalemo(:,i)=coal_d_so(:,1);% emission matrix sorted by status, output and depth
    coalomo(:,i)=coal_d_so(:,2);% output matrix sorted by status, output and depth
    coallmo(:,i)=coal_d_so(:,3);% labor matrix sorted by status, output and depth
    coalpfmo(:,i)=coal_d_so(:,12);% environmental cost matrix sorted by status, output and depth
    lato(:,i)=coal_d_so(:,9);
    lono(:,i)=coal_d_so(:,10);
    procodeo(:,i)=coal_d_so(:,11);
    coalemo0=coalemo;
    coalomo0=coalomo;
    coallmo0=coallmo;
    coalpfmo0=coalpfmo;
    coalomob(:,i)=coal_d_so(:,8);
    coal_r(coal_r>sum(coalomob(:,i)))=sum(coalomob(:,i));% reduction cannot beyond inventory
    for j=1:l
        if sum(coalomob(1:j,i))>=coal_r(i) && sum(coalomob(1:(j-1),i))<coal_r(i)
            coalemo(1:(j-1),i)=0;
            coalomo(1:(j-1),i)=0;
            coallmo(1:(j-1),i)=0;
            coalpfmo(1:(j-1),i)=0;
            coalomo(j,i)=sum(coalomob(1:j,i))-coal_r(i);
            coalemo(j,i)=coalemo0(j,i)./coalomob(j,i).*(sum(coalomob(1:j,i))-coal_r(i));
            coallmo(j,i)=coallmo0(j,i)./coalomob(j,i).*(sum(coalomob(1:j,i))-coal_r(i));
            coalpfmo(j,i)=coalpfmo0(j,i)./coalomob(j,i).*(sum(coalomob(1:j,i))-coal_r(i));           
        end
    end
    for j=1:l
        if coalemo(j,i)==0 && coal_d_so(j,7)==1
            o_fo_o(j,i)=coalomob(j,i);
            e_fo_o(j,i)=coalemo0(j,i);
        end
        if coalemo(j,i)~=0 && coalemo(j,i)<coalemo0(j,i)
            o_fo_o(j,i)=(coal_r(i)-sum(coalomob(1:j-1,i)));
            e_fo_o(j,i)=coalemo0(j,i)./coalomob(j,i).*o_fo_o(j,i);
        end
    end
end
coal_so_ye=sum(coalemo,1)/1000;% yearly emissionGtCO2e
coal_so_yo=sum(coalomo,1);% yearly output Mt

% sorted by emission intensity
o_nc_e=zeros(l,lper);% output reduction by natural closure
o_pf_e=zeros(l,lper);% output reduction by carbon tax-driven closure
o_fo_e=zeros(l,lper);% output reduction by directly forced closure
e_nc_e=zeros(l,lper);% emission reduction by natural closure
e_pf_e=zeros(l,lper);% emission reduction by carbon tax-driven closure
e_fo_e=zeros(l,lper);% emission reduction by directly forced closure
op=xlsread(path,'23','j2:j1266');%original cost without carbon tax
cart=xlsread(path1,'carbontax','j5:k31');%carbon tax 2030-2050
pf=zeros(l,lper);
spf=zeros(l,lper);% environmental cost with carbon tax for all emission
tpf=zeros(l,lper);
coaleme=zeros(l,lper);
coalome=zeros(l,lper);
coallme=zeros(l,lper);
coalpfme=zeros(l,lper);
coalomeb=zeros(l,lper);
late=zeros(l,lper);
lone=zeros(l,lper);
procodee=zeros(l,lper);
coal_d=[coal_d0,t,coal_d0(:,2),latlon,procode];
for i=1:lper % 24-50
    pf(:,i)=op-pei.*cart(i,1);
    spf(:,i)=coal_d(:,5).*cart(i,1);%environmental cost considering all emissions
    tpf(:,i)=spf(:,i).*coal_d(:,2);% total environmental cost M CNY
    coal_d=[coal_d2, tpf(:,i)];% 12 col
    for j=1:l
        if coal_d(j,6)<=i% no resources        
            o_nc_e(j,i)=coal_d2(j,2);
            e_nc_e(j,i)=coal_d2(j,1);
            coal_d(j,7)=0;
            coal_d(j,1)=0;
            coal_d(j,2)=0;
            coal_d(j,3)=0;
            coal_d(j,12)=0;
        end   
        if pf(j,i)<=0 && coal_d(j,6)>i% stranded by carbon tax
            o_pf_e(j,i)=coal_d2(j,2);
            e_pf_e(j,i)=coal_d2(j,1);
            coal_d(j,7)=0;
            coal_d(j,1)=0;
            coal_d(j,2)=0;
            coal_d(j,3)=0;
            coal_d(j,12)=0;           
        end
    end
    coal_d_se=sortrows(coal_d,[7 -5 -4]);% sorted by status, emission intensity and depth
    coaleme(:,i)=coal_d_se(:,1);% emission matrix sorted by status, output and depth
    coalome(:,i)=coal_d_se(:,2);% output matrix sorted by status, output and depth
    coallme(:,i)=coal_d_se(:,3);% labor matrix sorted by status, output and depth
    coalpfme(:,i)=coal_d_se(:,12);% environmental cost matrix sorted by status, output and depth
    late(:,i)=coal_d_se(:,9);
    lone(:,i)=coal_d_se(:,10);
    procodee(:,i)=coal_d_se(:,11);
    coaleme0=coaleme;
    coalome0=coalome;
    coallme0=coallme;
    coalpfme0=coalpfme;
    coalomeb(:,i)=coal_d_se(:,8);
    coal_r(coal_r>sum(coalomeb(:,i)))=sum(coalomeb(:,i));% reduction cannot beyond inventory
    for j=1:l
        if sum(coalomeb(1:j,i))>=coal_r(i) && sum(coalomeb(1:(j-1),i))<coal_r(i)
            coaleme(1:(j-1),i)=0;
            coalome(1:(j-1),i)=0;
            coallme(1:(j-1),i)=0;
            coalpfme(1:(j-1),i)=0;
            coalome(j,i)=sum(coalomeb(1:j,i))-coal_r(i);
            coaleme(j,i)=coaleme0(j,i)./coalomeb(j,i).*(sum(coalomeb(1:j,i))-coal_r(i));
            coallme(j,i)=coallme0(j,i)./coalomeb(j,i).*(sum(coalomeb(1:j,i))-coal_r(i));
            coalpfme(j,i)=coalpfme0(j,i)./coalomeb(j,i).*(sum(coalomeb(1:j,i))-coal_r(i));           
        end
    end

    for j=1:l
        if coaleme(j,i)==0 && coal_d_se(j,7)==1
            o_fo_e(j,i)=coalomeb(j,i);
            e_fo_e(j,i)=coaleme0(j,i);
        end
        if coaleme(j,i)~=0 && coaleme(j,i)<coaleme0(j,i)
            o_fo_e(j,i)=(coal_r(i)-sum(coalomeb(1:j-1,i)));
            e_fo_e(j,i)=coaleme0(j,i)./coalomeb(j,i).*o_fo_e(j,i);
        end
    end
end
coal_se_ye=sum(coaleme,1)/1000;% yearly emission GtCO2e
coal_se_yo=sum(coalome,1);% yearly output Mt

% output
xlswrite(pathtcs,coalomo,'coalomo','a1');
xlswrite(pathtcs,coalemo,'coalemo','a1');
xlswrite(pathtcs,coallmo,'coallmo','a1');
xlswrite(pathtcs,coalpfmo,'coalpfmo','a1');
xlswrite(pathtcs,coalome,'coalome','a1');
xlswrite(pathtcs,coaleme,'coaleme','a1');
xlswrite(pathtcs,coallme,'coallme','a1');
xlswrite(pathtcs,coalpfme,'coalpfme','a1');
xlswrite(pathtcs,lato,'lato','a1');
xlswrite(pathtcs,lono,'lono','a1');
xlswrite(pathtcs,late,'late','a1');
xlswrite(pathtcs,lone,'lone','a1');

pceo=[zeros(31,27),(1:1:31)'];
for i=1:27
    for j=1:l
        for g=1:31
            if procodeo(j,i)==pceo(g,28)
                pceo(g,i)=pceo(g,i)+coalemo(j,i);
            end
        end
    end
end
tpceo=sum(pceo(:,1:27),2);

pcee=[zeros(31,27),(1:1:31)'];
for i=1:27
    for j=1:l
        for g=1:31
            if procodee(j,i)==pcee(g,28)
                pcee(g,i)=pcee(g,i)+coaleme(j,i);
            end
        end
    end
end
tpcee=sum(pcee(:,1:27),2);
%% coal Announced Pledges
path=fullfile(current_path, 'coal.xlsx');
path1=fullfile(current_path, 'futureproduction.xlsx');
pathtca=fullfile(current_path, 'coal\APS.xlsx');
coal_d0=xlsread(path,'23','d2:i1266');% emission/yr,coal output/yr, and workforce of each coal mine
l=size(coal_d0,1);
t=ones(l,1);% 1 for sites with output
coal_d=[coal_d0,t,coal_d0(:,2),latlon,procode];
coal_d2=coal_d;
coal_ew=xlsread(path1,'coal','l5:l31');% future coal production
coal_ew2=coal_ew-910.7473617;% exclude coal that are not covered by inventory
coal_r=-(coal_ew2-sum(coal_d(:,2)));%reduction in inventory needed
per=2024:1:2050;% period span
lper=size(per,2);
pei=xlsread(path,'23','m2:m1266');%emission inensity of production tCO2e/t
% sorted by output
o_nc_o=zeros(l,lper);% output reduction by natural closure
o_pf_o=zeros(l,lper);% output reduction by carbon tax-driven closure
o_fo_o=zeros(l,lper);% output reduction by directly forced closure
e_nc_o=zeros(l,lper);% emission reduction by natural closure
e_pf_o=zeros(l,lper);% emission reduction by carbon tax-driven closure
e_fo_o=zeros(l,lper);% emission reduction by directly forced closure
op=xlsread(path,'23','j2:j1266');%original environmental cost without carbon tax
cart=xlsread(path1,'carbontax','j5:k31');%carbon tax 2030-2050
pf=zeros(l,lper);% output reduction by directly forced closure
spf=zeros(l,lper);% environmental cost with carbon tax for all emission
tpf=zeros(l,lper);
coalemo=zeros(l,lper);
coalomo=zeros(l,lper);
coallmo=zeros(l,lper);
coalpfmo=zeros(l,lper);
coalomob=zeros(l,lper);
lato=zeros(l,lper);
lono=zeros(l,lper);
procodeo=zeros(l,lper);
for i=1:lper % 24-50
    pf(:,i)=op-pei.*cart(i,2);
    spf(:,i)=coal_d(:,5).*cart(i,2);%environmental cost considering all emissions
    tpf(:,i)=spf(:,i).*coal_d(:,2);% total environmental cost M CNY
    coal_d=[coal_d2, tpf(:,i)];% 12 col
    for j=1:l
        if coal_d(j,6)<=i% no resources
            o_nc_o(j,i)=coal_d2(j,2);
            e_nc_o(j,i)=coal_d2(j,1);
            coal_d(j,7)=0;
            coal_d(j,1)=0;
            coal_d(j,2)=0;
            coal_d(j,3)=0;
            coal_d(j,12)=0;           
        end
        if pf(j,i)<=0 && coal_d(j,6)>i% stranded by carbon tax
            o_pf_o(j,i)=coal_d2(j,2);
            e_pf_o(j,i)=coal_d2(j,1);
            coal_d(j,7)=0;
            coal_d(j,1)=0;
            coal_d(j,2)=0;
            coal_d(j,3)=0;
            coal_d(j,12)=0;           
        end
    end
    coal_d_so=sortrows(coal_d,[7 8 -4]);% sorted by status, output and depth
    coalemo(:,i)=coal_d_so(:,1);% emission matrix sorted by status, output and depth
    coalomo(:,i)=coal_d_so(:,2);% output matrix sorted by status, output and depth
    coallmo(:,i)=coal_d_so(:,3);% labor matrix sorted by status, output and depth
    coalpfmo(:,i)=coal_d_so(:,12);% environmental cost matrix sorted by status, output and depth
    lato(:,i)=coal_d_so(:,9);
    lono(:,i)=coal_d_so(:,10);
    procodeo(:,i)=coal_d_so(:,11);
    coalemo0=coalemo;
    coalomo0=coalomo;
    coallmo0=coallmo;
    coalpfmo0=coalpfmo;
    coalomob(:,i)=coal_d_so(:,8);
    coal_r(coal_r>sum(coalomob(:,i)))=sum(coalomob(:,i));% reduction cannot beyond inventory
    for j=1:l
        if sum(coalomob(1:j,i))>=coal_r(i) && sum(coalomob(1:(j-1),i))<coal_r(i)
            coalemo(1:(j-1),i)=0;
            coalomo(1:(j-1),i)=0;
            coallmo(1:(j-1),i)=0;
            coalpfmo(1:(j-1),i)=0;
            coalomo(j,i)=sum(coalomob(1:j,i))-coal_r(i);
            coalemo(j,i)=coalemo0(j,i)./coalomob(j,i).*(sum(coalomob(1:j,i))-coal_r(i));
            coallmo(j,i)=coallmo0(j,i)./coalomob(j,i).*(sum(coalomob(1:j,i))-coal_r(i));
            coalpfmo(j,i)=coalpfmo0(j,i)./coalomob(j,i).*(sum(coalomob(1:j,i))-coal_r(i));           
        end
    end
    for j=1:l
        if coalemo(j,i)==0 && coal_d_so(j,7)==1
            o_fo_o(j,i)=coalomob(j,i);
            e_fo_o(j,i)=coalemo0(j,i);
        end
        if coalemo(j,i)~=0 && coalemo(j,i)<coalemo0(j,i)
            o_fo_o(j,i)=(coal_r(i)-sum(coalomob(1:j-1,i)));
            e_fo_o(j,i)=coalemo0(j,i)./coalomob(j,i).*o_fo_o(j,i);
        end
    end
end
coal_so_ye=sum(coalemo,1)/1000;% yearly emissionGtCO2e
coal_so_ye_cum=cumsum(coal_so_ye);% cumulative yearly emission
coal_so_yo=sum(coalomo,1);% yearly output Mt
% sorted by emission intensity
o_nc_e=zeros(l,lper);% output reduction by natural closure
o_pf_e=zeros(l,lper);% output reduction by carbon tax-driven closure
o_fo_e=zeros(l,lper);% output reduction by directly forced closure
e_nc_e=zeros(l,lper);% emission reduction by natural closure
e_pf_e=zeros(l,lper);% emission reduction by carbon tax-driven closure
e_fo_e=zeros(l,lper);% emission reduction by directly forced closure
op=xlsread(path,'23','j2:j1266');%original cost without carbon tax
cart=xlsread(path1,'carbontax','j5:k31');%carbon tax 2030-2050
pf=zeros(l,lper);
spf=zeros(l,lper);% environmental cost with carbon tax for all emission
tpf=zeros(l,lper);
coaleme=zeros(l,lper);
coalome=zeros(l,lper);
coallme=zeros(l,lper);
coalpfme=zeros(l,lper);
coalomeb=zeros(l,lper);
late=zeros(l,lper);
lone=zeros(l,lper);
procodee=zeros(l,lper);
coal_d=[coal_d0,t,coal_d0(:,2),latlon,procode];
for i=1:lper % 24-50
    pf(:,i)=op-pei.*cart(i,2);
    spf(:,i)=coal_d(:,5).*cart(i,2);%environmental cost considering all emissions
    tpf(:,i)=spf(:,i).*coal_d(:,2);% total environmental cost M CNY
    coal_d=[coal_d2, tpf(:,i)];% 12 col
    for j=1:l
        if coal_d(j,6)<=i% no resources
            o_nc_e(j,i)=coal_d2(j,2);
            e_nc_e(j,i)=coal_d2(j,1);
            coal_d(j,7)=0;
            coal_d(j,1)=0;
            coal_d(j,2)=0;
            coal_d(j,3)=0;
            coal_d(j,12)=0;           
        end
        if pf(j,i)<=0 && coal_d(j,6)>i% stranded by carbon tax
            o_pf_e(j,i)=coal_d2(j,2);
            e_pf_e(j,i)=coal_d2(j,1);
            coal_d(j,7)=0;
            coal_d(j,1)=0;
            coal_d(j,2)=0;
            coal_d(j,3)=0;  
            coal_d(j,12)=0;           
        end
    end   
    coal_d_se=sortrows(coal_d,[7 -5 -4]);% sorted by status, emission intensity and depth
    coaleme(:,i)=coal_d_se(:,1);% emission matrix sorted by status, output and depth
    coalome(:,i)=coal_d_se(:,2);% output matrix sorted by status, output and depth
    coallme(:,i)=coal_d_se(:,3);% labor matrix sorted by status, output and depth
    coalpfme(:,i)=coal_d_se(:,12);% environmental cost matrix sorted by status, output and depth
    late(:,i)=coal_d_se(:,9);
    lone(:,i)=coal_d_se(:,10);
    procodee(:,i)=coal_d_se(:,11);
    coaleme0=coaleme;
    coalome0=coalome;
    coallme0=coallme;    
    coalpfme0=coalpfme;
    coalomeb(:,i)=coal_d_se(:,8);
    coal_r(coal_r>sum(coalomeb(:,i)))=sum(coalomeb(:,i));% reduction cannot beyond inventory
    for j=1:l
        if sum(coalomeb(1:j,i))>=coal_r(i) && sum(coalomeb(1:(j-1),i))<coal_r(i)
            coaleme(1:(j-1),i)=0;
            coalome(1:(j-1),i)=0;
            coallme(1:(j-1),i)=0;     
            coalpfme(1:(j-1),i)=0;
            coalome(j,i)=sum(coalomeb(1:j,i))-coal_r(i);
            coaleme(j,i)=coaleme0(j,i)./coalomeb(j,i).*(sum(coalomeb(1:j,i))-coal_r(i));
            coallme(j,i)=coallme0(j,i)./coalomeb(j,i).*(sum(coalomeb(1:j,i))-coal_r(i));  
            coalpfme(j,i)=coalpfme0(j,i)./coalomeb(j,i).*(sum(coalomeb(1:j,i))-coal_r(i));           
        end
    end
    for j=1:l
        if coaleme(j,i)==0 && coal_d_se(j,7)==1
            o_fo_e(j,i)=coalomeb(j,i);
            e_fo_e(j,i)=coaleme0(j,i);
        end
        if coaleme(j,i)~=0 && coaleme(j,i)<coaleme0(j,i)
            o_fo_e(j,i)=(coal_r(i)-sum(coalomeb(1:j-1,i)));
            e_fo_e(j,i)=coaleme0(j,i)./coalomeb(j,i).*o_fo_e(j,i);
        end
    end
end
coal_se_ye=sum(coaleme,1)/1000;% yearly emission GtCO2e
coal_se_ye_cum=cumsum(coal_se_ye);% cumulative yearly emission
coal_se_yo=sum(coalome,1);% yearly output Mt
% output
xlswrite(pathtca,coalomo,'coalomo','a1');
xlswrite(pathtca,coalemo,'coalemo','a1');
xlswrite(pathtca,coallmo,'coallmo','a1');
xlswrite(pathtca,coalpfmo,'coalpfmo','a1');
xlswrite(pathtca,coalome,'coalome','a1');
xlswrite(pathtca,coaleme,'coaleme','a1');
xlswrite(pathtca,coallme,'coallme','a1');
xlswrite(pathtca,coalpfme,'coalpfme','a1');
xlswrite(pathtca,lato,'lato','a1');
xlswrite(pathtca,lono,'lono','a1');
xlswrite(pathtca,late,'late','a1');
xlswrite(pathtca,lone,'lone','a1');

pceo=[zeros(31,27),(1:1:31)'];
for i=1:27
    for j=1:l
        for g=1:31
            if procodeo(j,i)==pceo(g,28)
                pceo(g,i)=pceo(g,i)+coalemo(j,i);
            end
        end
    end
end
tpceo=sum(pceo(:,1:27),2);

pcee=[zeros(31,27),(1:1:31)'];
for i=1:27
    for j=1:l
        for g=1:31
            if procodee(j,i)==pcee(g,28)
                pcee(g,i)=pcee(g,i)+coaleme(j,i);
            end
        end
    end
end
tpcee=sum(pcee(:,1:27),2);
toc
