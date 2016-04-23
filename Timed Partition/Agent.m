classdef Agent
    
    properties
        ID;
        Map;
        Center;
        TimeLastContact;
        ActiveDensityVector;
        Activeindex;
        State;
        Coverage;
        Centerx;
        Centery;
        
    end
    methods
        %Constructor
        function obj = Agent(ID,Center,Map,Time,State, Coverage)
            p = inputParser;
            p.KeepUnmatched = 1;
            addRequired(p,'ID');
            addRequired(p,'Center');
            addRequired(p,'Map');
            addRequired(p,'Time');
            addRequired(p,'State');
            addRequired(p,'Coverage');
            parse(p,ID,Center,Map,Time,State,Coverage);
            obj.Center = p.Results.Center;
            obj.ID = p.Results.ID;
            obj.Map = p.Results.Map;
            obj.TimeLastContact = p.Results.Time;
            obj.State = p.Results.State;
            obj.Coverage = p.Results.Coverage;
        end
        
        function obj = TimeUpdate(obj,time,w,h,color,transparancy)
            %update timers on Agent. Also creates logical index of active
            %points
            %obj.ActiveMap = Map(obj.Map.Points{find(obj.Map.PointsIndices==obj.Center)});
            obj.ActiveDensityVector = [];
            obj.Activeindex = [];
            activex =[];
            activey = [];
            totalx = [];
            totaly = [];
            centerx =[];
            centery = [];
            for i = 1:length(obj.Map.Points)
                if obj.Map.Points{i}.TimeActive <= time
                    activex(length(activex)+1) = obj.Map.Points{i}.x;
                    activey(length(activey)+1) = obj.Map.Points{i}.y;
                    obj.ActiveDensityVector(length(obj.ActiveDensityVector)+1) = obj.Map.Points{i}.Density;
                    obj.Activeindex(length(obj.Activeindex)+1) = obj.Map.Points{i}.Index;
                end
                if obj.Map.Points{i}.Index == obj.Center
                    centerx = obj.Map.Points{i}.x;
                    centery = obj.Map.Points{i}.y;
                end
                totalx(length(totalx)+1) = obj.Map.Points{i}.x;
                totaly(length(totaly)+1) = obj.Map.Points{i}.y;
                %
                %                 obj.Map.Points{i}.Timer = obj.Map.Points{i}.Timer-dt;
                %                 if (obj.Map.Points{i}.Timer) <= 0
                %                     obj.Map.Points{i}.Timer =0;
                %                     obj.ActiveDensityVector(length(obj.ActiveDensityVector)+1) = obj.Map.Points{i}.Density;
                %                     obj.Activeindex(length(obj.Activeindex)+1) = obj.Map.Points{i}.Index;
                %                 end
            end
            obj = obj.PlotRegion(activex,activey,totalx,totaly,centerx,centery,w,h,color,transparancy);
            obj.Centerx = centerx;
            obj.Centery = centery;
        end
        
        function obj = PlotRegion(obj,activex,activey,totalx,totaly,centerx,centery,w,h,color,transparancy)
            figure(2)
            hold on
            scatter(centerx,centery,250,color,'filled')
            patchesx = [];
            patchesy = [];
            for i = 1:length(totalx)
                TempX = [(totalx(i)-(w/2)) (totalx(i)+(w/2)) (totalx(i)+(w/2)) (totalx(i)-(w/2))];
                TempY = [(totaly(i)+(h/2)) (totaly(i)+(h/2)) (totaly(i)-(h/2)) (totaly(i)-(h/2))];
                patchesx(:,i) = TempX;
                patchesy(:,i) = TempY;
%                 patch(TempX,TempY,color)
            end
            patch(patchesx,patchesy,color)
            alpha(transparancy)
            
            hold off
            
            figure(3)
            hold on
            scatter(centerx,centery,250,color,'filled')
            patchesx = [];
            patchesy = [];
            for i = 1:length(activex)
                TempX = [(activex(i)-(w/2)) (activex(i)+(w/2)) (activex(i)+(w/2)) (activex(i)-(w/2))];
                TempY = [(activey(i)+(h/2)) (activey(i)+(h/2)) (activey(i)-(h/2)) (activey(i)-(h/2))];
                patchesx(:,i) = TempX;
                patchesy(:,i) = TempY;
%                 patch(TempX,TempY,color)
            end
            patch(patchesx,patchesy,color)
            alpha(transparancy)
            
            hold off
            
        end
        
        
        function obj = smc_update_modified(obj,time,dt, OuterBoundaries, NGridx,NGridy)
            Lmin=[OuterBoundaries(1),OuterBoundaries(2)];
            Lmax=[OuterBoundaries(1)+OuterBoundaries(3),OuterBoundaries(2)+OuterBoundaries(4)];
            Dxsize=OuterBoundaries(3);
            Dysize=OuterBoundaries(4);
            dxgrid=Dxsize/NGridx;
            dygrid=Dysize/NGridy;
            
            uavspeed=(obj.State.MaxSpeed-obj.State.MinSpeed)/2;
            nk=obj.Coverage.nk;
            K=obj.Coverage.K;
            Ck=obj.Coverage.Ck;
            
            %transform active density into total density
            %first sort active index / density vector
            [ActiveIndexSorted, SortIndex] = sort(obj.Activeindex);
            ActiveDensityVectorSorted = obj.ActiveDensityVector(SortIndex);
            DensitySum = sum(ActiveDensityVectorSorted);
            ActiveDensityVectorSorted = ActiveDensityVectorSorted./DensitySum;
            totalindex = 1:NGridx*NGridy;
            totalindex = totalindex';
            TotalDensity = zeros(NGridx*NGridy,1);
            TotalDensity(ismember(totalindex,ActiveIndexSorted)) = ActiveDensityVectorSorted;
            
            
            mu=reshape(TotalDensity,NGridy,NGridx)/(dxgrid*dygrid);
            agentspos=obj.State.Location(end,1:2);
            
            [Gridx,Gridy] = meshgrid(linspace(Lmin(1),Lmax(1),NGridx),linspace(Lmin(2),Lmax(2),NGridy));
            
            xprel = agentspos(1) - Lmin(1);
            yprel = agentspos(2) - Lmin(2);
            
            muk = zeros(nk, nk);
            for kx = 0:nk-1
                for ky = 0:nk-1
                    
                    Dum=mu.*cos(kx/Dxsize*pi*Gridx).*cos(ky/Dysize*pi*Gridy)*dxgrid*dygrid;
                    muk(kx+1, ky+1) =  muk(kx+1, ky+1) + sum(sum(Dum));
                    
                    Ck(kx+1, ky+1) = Ck(kx+1, ky+1) + cos(kx/Dxsize*pi*xprel)*cos(ky/Dysize*pi*yprel)*dt;
                    
                end
            end
            
            % muknew = dct2(mu); % this was missing
            % abs(sum(sum(muk-muknew)))
            
            kxx=0:nk-1; kyy=0:nk-1;
            [kxx,kyy]=meshgrid(kxx,kyy); % this produces transpose compare to looping as in lines 43-52
            lambdakk = 1.0./((1 + kxx.*kxx + kyy.*kyy).^(1.5));  lambdakk= lambdakk/(0.5*0.5);
            lambdakk(:,1)= lambdakk(:,1)*0.5;
            lambdakk(1,:)= lambdakk(1,:)*0.5;
            
            Bxx1=(-kxx*pi/Dxsize).*sin(kxx/Dxsize*pi*xprel).*cos(kyy/Dysize*pi*yprel);  Bxx1= Bxx1';
            Byy1=(-kyy*pi/Dysize).*cos(kxx/Dxsize*pi*xprel).*sin(kyy/Dysize*pi*yprel);  Byy1= Byy1';
            
            Bjxmat=lambdakk.*(Ck-time*muk).*Bxx1;
            Bjymat=lambdakk.*(Ck-time*muk).*Byy1;
            Bjx=sum(sum(Bjxmat));
            Bjy=sum(sum(Bjymat));
            
            if obj.Coverage.VModeltype==1
                
                Bjnorm = sqrt(Bjx^2+Bjy^2);
                if 0
                    u = -uavspeed*Bjx/Bjnorm;
                    v = -uavspeed*Bjy/Bjnorm;
                else
                    u = -K*uavspeed*Bjx;
                    v = -K*uavspeed*Bjy;
                    Vnorm=sqrt(u^2+v^2);
                    if Vnorm>uavspeed
                        u=u*uavspeed/Vnorm;
                        v=v*uavspeed/Vnorm;
                    end
                end
                agentsposnew(1, :) = agentspos(1, :) + [u v] * dt;
                phinew=0;
            else
                uavminspeed=obj.Coverage.MinSpeed;
                uavmaxspeed=obj.Coverage.MaxSpeed;
                wmin=obj.Coverage.MinAngularSpeed;
                wmax=obj.Coverage.MaxAngularSpeed;
                
                phi=obj.State.Location(end,3);
                
                A = Bjx*cos(phi) + Bjy*sin(phi);
                
                if (A>0)
                    vspeed =uavminspeed;
                else
                    vspeed =uavmaxspeed;
                end
                
                B = Bjx*(-sin(phi)) + Bjy*(cos(phi));
                
                if (B>0)
                    w=wmin;
                else
                    w=wmax;
                end
                
                agentsposnew(1, :)= agentspos(1, :) + vspeed*[cos(phi) sin(phi)]*dt;
                phinew = phi+ w*dt;
                
            end
            %% Edit
            %find which index new position is in
%             Xcount = floor((agentsposnew(1)-Lmin(1))/dxgrid);
%             Ycount = floor((agentsposnew(2)-Lmin(2))/dxgrid)+1;
%             positionIndex = Xcount*NGridy+Ycount;
%             if ismember(positionIndex, obj.Activeindex)==0
%                 %head towards agent's center
%                 u = obj.Centerx - agentspos(1);
%                 v = obj.Centery - agentspos(2);
%                 %turn u and v into unit vector
%                 magnitude = sqrt(u^2+v^2);
%                 u = u/magnitude;
%                 v = v/magnitude;
%                 agentsposnew(1,1) = agentspos(1) + u*uavspeed*dt;
%                 agentsposnew(1,2) = agentspos(2) + v*uavspeed*dt;
%                 
%             end
            %%
            
            if (agentsposnew(1,1) < Lmin(1))
                agentsposnew(1,1) = Lmin(1) + (Lmin(1) - agentsposnew(1,1));
            end
            
            if (agentsposnew(1,1) > Lmax(1))
                agentsposnew(1,1) = Lmax(1) - (agentsposnew(1,1) - Lmax(1));
            end
            
            if (agentsposnew(1,2) < Lmin(2))
                agentsposnew(1,2) = Lmin(2) + (Lmin(2) - agentsposnew(1,2));
            end
            
            if (agentsposnew(1,2) > Lmax(2))
                agentsposnew(1,2) = Lmax(2) - (agentsposnew(1,2) - Lmax(2));
            end
            
            obj.Coverage.Ck=Ck;
            obj.State.Location=[obj.State.Location;agentsposnew phinew];
            
        end
    end
end