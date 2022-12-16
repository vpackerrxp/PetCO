codeunit 80001 "PC Fulfilio Routines"
{
   var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
    procedure FulFilio_Data(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:jsonobject): boolean
    var
       Setup:Record "Sales & Receivables Setup";
       Ws:Record "PC RestWebServiceArguments";
       Cu:Codeunit "PC Shopify Routines";
     begin
        Setup.get;
        Ws.init;
        If Setup."Use Fulfilo Dev Access" then
            Ws.URL := Setup."Dev FulFilio Connnect Url"
        else
            Ws.URL := Setup."FulFilio Connnect Url";
        ws."Access Token" := Setup."FulFilio Access Token";
        Ws.Url += Request;
        ws."Token Type" := ws."Token Type"::FulFilio;
        ws.Accept := '*/*';
        Ws.RestMethod := Method;
        if cu.CallRESTWebService(ws,Parms,Payload) then
            exit(Data.ReadFrom(ws.GetResponseContentAsText()))
        else
        begin
            if Data.ReadFrom(ws.GetResponseContentAsText()) then;
            exit(false);
        end;    
    end;
    //routine to ensure fulfilio access has the most upto date access token
    local procedure Get_Fulfilo_AccessToken():Boolean
    var
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Setup:Record "Sales & Receivables Setup";
        Ws:Record "PC RestWebServiceArguments";
        flg:Boolean;
        Cu:Codeunit "PC Shopify Routines";
    begin
        Clear(Parms);
        Clear(Data);
        Clear(PayLoad);
        Setup.get;
        Data.Add('client_id',Setup."FulFilio Client ID");
        Data.add('client_secret',Setup."FulFilio Client Secret");
        Flg := Setup."FulFilio Refresh Token" <> ''; 
        If Not Flg then Flg := FulFilo_Login_Connection();
        If Flg then
        begin
            Data.add('refresh_token',Setup."FulFilio Refresh Token");
            Data.WriteTo(PayLoad);
            Ws.init;
            Ws.URL := Setup."FulFilio Connnect Url" + '/api/v1/refresh-token';
            Clear(ws."Access Token");
            ws.Accept := '*/*';
            ws."Token Type" := ws."Token Type"::FulFilio;
            Ws.RestMethod := Ws.RestMethod::POST;
            if Cu.CallRESTWebService(ws,Parms,Payload) then
            begin;
                Data.ReadFrom(ws.GetResponseContentAsText());
                Data.Get('data',JsToken[1]);
                jstoken[1].SelectToken('access_token',JsToken[2]);
                Setup."FulFilio Access Token" := JsToken[2].AsValue().Astext;
                Jstoken[1].SelectToken('refresh_token',JsToken[2]);
                Setup."FulFilio Refresh Token" := JsToken[2].AsValue().Astext;
                Setup.Modify(False);
                Commit;
                Exit(true);
            end
            else   
                exit(false);
        end;
    end;    
procedure FulFilo_Login_Connection():Boolean
    var
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Setup:Record "Sales & Receivables Setup";
        Ws:Record "PC RestWebServiceArguments";
        Cu:Codeunit "PC Shopify Routines";
    begin
        Clear(Parms);
        Clear(Data);
        Setup.get;
        Ws.init;
        Clear(ws."Access Token");
         
        If Setup."Use Fulfilo Dev Access" then
        begin
            Data.Add('store_id',Setup."Dev FulFilio Store ID");
            Data.Add('client_id',Setup."Dev FulFilio Client ID");
            Data.add('client_secret',Setup."Dev FulFilio Client Secret");
            Data.add('username',Setup."Dev FulFilio UserName");
            Data.add('password',Setup."Dev FulFilio Password");
            Ws.URL := Setup."Dev FulFilio Connnect Url" + '/api/v1/login';     
        end
        else
        begin    
            Data.Add('store_id',Setup."FulFilio Store ID");
            Data.Add('client_id',Setup."FulFilio Client ID");
            Data.add('client_secret',Setup."FulFilio Client Secret");
            Data.add('username',Setup."FulFilio UserName");
            Data.add('password',Setup."FulFilio Password");
            Ws.URL := Setup."FulFilio Connnect Url" + '/api/v1/login';
        end;    
        Data.WriteTo(PayLoad);
        Clear(ws."Access Token");
        ws.Accept := '*/*';
        ws."Token Type" := ws."Token Type"::FulFilio;
        Ws.RestMethod := Ws.RestMethod::POST;
        if cu.CallRESTWebService(ws,Parms,Payload) then
        begin;
            Data.ReadFrom(ws.GetResponseContentAsText());
            Data.Get('data',JsToken[1]);
            jstoken[1].SelectToken('access_token',JsToken[2]);
            Setup."FulFilio Access Token" := JsToken[2].AsValue().Astext;
            Jstoken[1].SelectToken('refresh_token',JsToken[2]);
            Setup."FulFilio Refresh Token" := JsToken[2].AsValue().Astext;
            Setup.Modify(False);
            commit;
            Exit(true);
        end
        else   
            exit(false);
    end;
// Create Fulfilo ASN for passed PO information
    procedure Create_ASN(var PurchHdr:Record "Purchase Header"):Boolean
    var
        PurchLine:Array[2] of record "Purchase Line";
        Data:JsonObject;
        JsArry:JsonArray;
        JsObj:JsonObject;
        JsObj1:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Loc:record Location;
        Qty:Decimal;
        Ref:text;
        Flg:Boolean;
        Wght:Decimal;
        ItemUnit:Record "Item Unit of Measure";
        LineNo:Integer;
        ASNTrack:Record "PC ASN Tracking";
    begin
        Flg := false;
        if Not Loc.get(PurchHdr."Location Code") then
        begin
            If GuiAllowed Then Message('Location code is not defined');
            Exit(flg);
        end;
        If Loc."Fulfilo Warehouse ID" = 0 then
        begin
            If GuiAllowed Then Message('Fulfilio Warehouse ID is invalid correct and retry');
            Exit(flg);
        end;
        PurchLine[1].reset;
        PurchLine[1].SetCurrentKey("Line No.");
        PurchLine[1].Setrange("Document Type",PurchLine[1]."Document Type"::Order);
        PurchLine[1].Setrange("Document No.",PurchHdr."No.");
        PurchLine[1].Setrange(Type,PurchLine[1].Type::Item);
        PurchLine[1].Setfilter("No.",'<>FREIGHT');
        PurchLine[1].SetFilter(Quantity,'>0');
        If Not Purchline[1].Findset then
        begin
            If GuiAllowed Then Message('Purchase order containes no item lines');
            exit(flg);
        end;
        Purchline[1].CalcSums(Quantity);
        Qty := Purchline[1].Quantity; 
        Clear(Wght);
        Purchline[2].CopyFilters(Purchline[1]);
        repeat
            If ItemUnit.Get(Purchline[1]."No.",PurchLine[1]."Unit of Measure code") then
                Wght += Purchline[1].Quantity * ItemUnit.Weight;  
            Purchline[2].Setrange("No.",Purchline[1]."No.");
            If Purchline[2].Count > 1 then
            begin
                If GuiAllowed Then message('%1 is repeated on PO\Only Unique SKU No. are allowed',Purchline[1]."No.");
                exit(flg);
            end;    
        until PurchLine[1].next = 0;
        If (PurchHdr."Requested Receipt Date" = 0D)
            AND (PurchHdr."Promised Receipt Date" = 0D) then
        begin
            If GuiAllowed Then Message('Requested And Or Promised Receipt Dates Are Missing');
            exit(flg);
        end;    
        // ensure we have a new Access token    
        if FulFilo_Login_Connection() then
        Begin
            Clear(Parms);
            Clear(PayLoad);
            Clear(Data);
            Clear(JsObj1);
            Clear(JsArry);
            JsObj1.add('external_id',PurchHdr."No.");
            JsObj1.add('warehouse_id',Loc."Fulfilo Warehouse ID");
            Ref := PurchHdr."No.";
            Clear(LineNo);
            JsObj1.Add('reference_number',Ref.replace('-',''));
            PurchLine[1].Findset;
            repeat
                LineNo +=1;
                Clear(JsObj);
                JsObj.add('sku',PurchLine[1]."No.");
                JsObj.add('quantity',Format(PurchLine[1]."Quantity (base)",0,'<Integer>'));
                JsObj.add('forwarders_ref','PCFORWARDER');
                JsObj.add('invoice_number','PCINVOICE');
                JsObj.add('order_number',Ref.replace('-',''));
                JsObj.add('order_line_number',Format(LineNo,0,'<Integer>'));
                JsArry.Add(JsObj);
            until PurchLine[1].next = 0;
            JsObj1.Add('products',JsArry);
            If PurchHdr."Promised Receipt Date" <> 0D then
                JsObj1.Add('due_date',Format(PurchHdr."Promised Receipt Date",0,'<year4>-<Month,2>-<Day,2>'))
            else
                JsObj1.Add('due_date',Format(PurchHdr."Requested Receipt Date",0,'<year4>-<Month,2>-<Day,2>'));
            JsObj1.Add('container_type','LCL');
            jsobj1.add('package_type','Cartons');
            jsobj1.Add('package_count',Format(Qty,0,'<Integer>'));
            jsobj1.Add('package_total_weight',Format(wght,0,'<Precision,2><Standard Format,1>'));
            JsObj1.WriteTo(PayLoad);
            FulFilio_Data(Paction::POST,'/api/v1/asns',Parms,PayLoad,Data);
            Data.Get('success',JsToken[1]);
            If JsToken[1].AsValue().AsBoolean() then
            begin
                Data.Get('data',JsToken[1]);
                JsArry := JsToken[1].AsArray;
                JsArry.get(0,JsToken[1]);
                if JsToken[1].SelectToken('record_id',JsToken[2]) then
                    If not JsToken[2].AsValue().IsNull then
                    Begin
                        PurchHdr."Fulfilo Order ID" := JsToken[2].AsValue().AsInteger();
                        Flg := True;
                    end; 
                if JsToken[1].SelectToken('record_external_id',JsToken[2]) then
                    If not JsToken[2].AsValue().IsNull then
                        PurchHdr."Fulfilo External Id" := CopyStr(JsToken[2].AsValue().AsCode,1,100);
                If JsToken[1].SelectToken('record_identifier',JsToken[2]) then
                    If not JsToken[2].AsValue().IsNull then
                        PurchHdr."Fulfilo Identifier" := CopyStr(JsToken[2].AsValue().AsCode,1,100);
                PurchHdr."Fulfilo ASN Status" := PurchHdr."Fulfilo ASN Status"::"In Progress";
                PurchHdr.Modify(false);
                ASNTrack.init;
                Clear(ASNTrack.ID);
                ASNTrack.insert;
                ASNTrack."ASN Creation Date/Time" := CurrentDateTime;
                ASNTrack."PO No." := PurchHdr."No.";
                ASNTrack."Total Qty" := Qty;
                ASNTrack."Total Weight" := Wght;
                ASNTrack."ASN No." := PurchHdr."Fulfilo External Id";
                ASNTrack.Modify();
                Commit;
            end        
            else
            begin
                Data.Get('errors',JsToken[1]);
                JsArry := JsToken[1].AsArray;
                JsArry.get(0,JsToken[1]);
                JsToken[1].SelectToken('message',JsToken[2]);
                iF GuiAllowed then Message(JsToken[2].AsValue().AsText());
            end;
        end
        else
            If GuiAllowed Then Message('Failed to get Access connect to Fulfilio');            
        exit(flg);
    end;
    //routine to update exist PO's that have an ASN with Fulfilo but require changes
    procedure Update_ASN(var PurchHdr:record "Purchase Header"):Boolean
    var
        PurchLine:array[2] of record "Purchase Line";
        Data:JsonObject;
        JsArry:JsonArray;
        JsObj:JsonObject;
        JsObj1:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Loc:record Location;
        Ref:text;
        Flg:Boolean;
        Qty:Decimal;
        Wght:Decimal;
        ItemUnit:Record "Item Unit of Measure";
        LineNo:Integer;
    Begin
        flg := false;
        if PurchHdr."Fulfilo Order ID" = 0 then
        begin
            If GuiAllowed then Message('Fulfilio Order ID is missing');
            exit(flg);
        end;
        if Not Loc.get(PurchHdr."Location Code") then
        begin
            If GuiAllowed then Message('Location code is not defined');
            Exit(flg);
        end;
        If Loc."Fulfilo Warehouse ID" = 0 then
        begin
            If GuiAllowed then Message('Fulfilio Warehouse ID is invalid correct and retry');
            Exit(flg);
        end;
        PurchLine[1].reset;
        PurchLine[1].SetCurrentKey("Line No.");
        PurchLine[1].Setrange("Document Type",PurchLine[1]."Document Type"::Order);
        PurchLine[1].Setrange("Document No.",PurchHdr."No.");
        PurchLine[1].Setrange(Type,PurchLine[1].Type::Item);
        PurchLine[1].Setfilter("No.",'<>FREIGHT');
        PurchLine[1].SetFilter(Quantity,'>0');
        If Not Purchline[1].Findset then
        begin
            If GuiAllowed then Message('Purchase order containes no item lines');
            exit(flg);
        end;
        Purchline[1].CalcSums(Quantity);
        Qty := Purchline[1].Quantity;
        Clear(Wght); 
        Purchline[2].CopyFilters(Purchline[1]);
        repeat
            If ItemUnit.Get(Purchline[1]."No.",PurchLine[1]."Unit of Measure code") then
                Wght += Purchline[1].Quantity * ItemUnit.Weight;  
             Purchline[2].Setrange("No.",Purchline[1]."No.");
            If Purchline[2].Count > 1 then
            begin
                If GuiAllowed then message('%1 is repeated on PO\Only Unique SKU No. are allowed',Purchline[1]."No.");
                exit(flg);
            end;    
        until PurchLine[1].next = 0;
        If (PurchHdr."Requested Receipt Date" = 0D)
            AND (PurchHdr."Promised Receipt Date" = 0D) then
        begin
            If GuiAllowed then Message('Requested And Or Promised Receipt Dates Are Missing');
            exit(flg);
        end;    
         // ensure we have a new Access token    
        if FulFilo_Login_Connection() then
        Begin
            Clear(Parms);
            Clear(PayLoad);
            Clear(Data);
            Clear(JsObj1);
            Clear(JsArry);
            JsObj1.add('external_id',PurchHdr."No.");
            JsObj1.add('warehouse_id',Loc."Fulfilo Warehouse ID");
            Ref := PurchHdr."No.";
            Clear(LineNo);
            JsObj1.Add('reference_number',Ref.replace('-',''));
            PurchLine[1].Findset;
            repeat
                LineNo += 1;
                Clear(JsObj);
                JsObj.add('sku',PurchLine[1]."No.");
                JsObj.add('quantity',Format(PurchLine[1]."Quantity (base)",0,'<Integer>'));
                JsObj.add('forwarders_ref','PCFORWARDER');
                JsObj.add('invoice_number','PCINVOICE');
                JsObj.add('order_number',Ref.replace('-',''));
                JsObj.add('order_line_number',Format(LineNo,0,'<Integer>'));
                JsArry.Add(JsObj);
            until PurchLine[1].next = 0;
            JsObj1.Add('products',JsArry);
            If PurchHdr."Promised Receipt Date" <> 0D then
                JsObj1.Add('due_date',Format(PurchHdr."Promised Receipt Date",0,'<year4>-<Month,2>-<Day,2>'))
            else
                JsObj1.Add('due_date',Format(PurchHdr."Requested Receipt Date",0,'<year4>-<Month,2>-<Day,2>'));
            JsObj1.Add('container_type','LCL');
            jsobj1.add('package_type','Cartons');
            jsobj1.Add('package_count',Format(Qty,0,'<Integer>'));
            jsobj1.Add('package_total_weight',Format(Wght,0,'<Precision,2><Standard Format,1>'));
            JsObj1.WriteTo(PayLoad);
            If FulFilio_Data(Paction::PUT,'/api/v1/asns/' + Format(PurchHdr."Fulfilo Order ID"),Parms,PayLoad,Data) then
            begin
                Data.Get('success',JsToken[1]);
                Flg := JsToken[1].AsValue().AsBoolean();
            end
            else     
                If GuiAllowed Then Message('Failed Communications to Fulfilio for Update ASN');            
        end            
        else
            If GuiAllowed Then Message('Failed to get Access connect to Fulfilio');            
         exit(flg);
   end;
   //routine to cancel existing fulfilo ASN 
    procedure Cancel_ASN(var PurchHdr:record "Purchase Header"):Boolean
    var
        Data:JsonObject;
        JsToken:JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Flg:Boolean;
    Begin
        flg := false;
        if PurchHdr."Fulfilo Order ID" = 0 then
        begin
            if GuiAllowed then Message('Fulfilio Order ID is missing');
            exit(flg);
        end;
        Clear(data);
        Clear(parms);
        if FulFilo_Login_Connection() then
        Begin
            If FulFilio_Data(Paction::PUT,'/api/v1/asns/' + Format(PurchHdr."Fulfilo Order ID") + '/cancel',Parms,PayLoad,Data) then
            begin
                Data.Get('success',JsToken);
                flg := JsToken.AsValue().AsBoolean();
                If flg then 
                Begin
                    PurchHdr."Fulfilo ASN Status" := PurchHdr."Fulfilo ASN Status"::Cancelled;
                    PurchHdr.modify(false);
                    Commit;
                end;
            end 
            else
                If GuiAllowed Then Message('Failed Communications to Fulfilio for Cancel ASN');            
                
        end                  
        else
            If GuiAllowed Then Message('Failed to get Access connect to Fulfilio');            
        exit(flg);                
    end;
    //routine to assess the Fulfilo PO status
    procedure Get_ASN_Order_Status(var Purchdr:Record "Purchase Header";UseDisplay:boolean):Boolean
    var
        Data:JsonObject;
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Ref:text;
        flg:Boolean;
    begin
        flg := false;
      // ensure we have a new Access token    
        if FulFilo_Login_Connection() then
        Begin
            Clear(parms);
            Ref := Purchdr."No.";
            Parms.Add('term',ref.Replace('-',''));
            Parms.Add('limit','1');
            If FulFilio_Data(Paction::GET,'/api/v1/asns',Parms,PayLoad,Data) then
            begin
                Data.Get('success',JsToken[1]); 
                If JsToken[1].AsValue().AsBoolean() then
                begin
                    Data.Get('data',JsToken[1]);
                    JsArry := JsToken[1].AsArray;
                    If JsArry.Count > 0 then
                    begin
                        JsArry.get(0,JsToken[1]);
                        JsToken[1].SelectToken('status',JsToken[2]); 
                        Case JsToken[2].AsValue().AsText().ToUpper() of
                            'COMPLETED':Purchdr."Fulfilo ASN Status" := Purchdr."Fulfilo ASN Status"::Completed;
                            'CANCELLED':Purchdr."Fulfilo ASN Status" := Purchdr."Fulfilo ASN Status"::Cancelled;
                            'RECEIVED AT DOCK':Purchdr."Fulfilo ASN Status" := Purchdr."Fulfilo ASN Status"::"Received At Dock";
                            'IN PROGRESS':Purchdr."Fulfilo ASN Status" := Purchdr."Fulfilo ASN Status"::"In Progress";
                            'PENDING':Purchdr."Fulfilo ASN Status" := Purchdr."Fulfilo ASN Status"::Pending;
                            'ON HOLD':Purchdr."Fulfilo ASN Status" := Purchdr."Fulfilo ASN Status"::"On Hold";
                        end;
                        Purchdr.Modify(false);
                        Commit;
                        Exit(Get_ASN_StockReceipt(Purchdr,UseDisplay));
                    end
                    else 
                        Exit(true);    
                end 
                else
                    If GuiAllowed Then Message('Failed Communications to Fulfilio for ASN Status');            
            end;
        end
        else
            If GuiAllowed Then Message('Failed to get Access connect to Fulfilio');            
        exit(flg);
    end;
    // routine to update PO information with fulfilo received stock for commpleted PO's
    local procedure Init_Excpt_Msg(var ExcpMsg:record "PC EDI Exception Messages";var PH:Record "Purchase Header")
    begin
        ExcpMsg.Init();
        Clear(ExcpMsg.ID);
        ExcpMsg.insert;
        ExcpMsg."Purchase Order No." := PH."No.";
        ExcpMsg."Exception Date" := TODAY;
    end;
    local Procedure Get_ASN_StockReceipt(var PurchHdr:record "Purchase Header";UseDisplay:Boolean):Boolean
    var
        Corr:Record "PC Purchase Corrections";
        i:Integer;
        Sku:text;
        qty:array[2] of Decimal;
        flg:Boolean;
        PurchLine:record "Purchase Line";
        Data:JsonObject;
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        POEx:Record "PC Purch Exceptions";
        Excnt:integer;
        NoOrd:Integer;
        InvOrd:Integer;
        SKUKeys:list of [text];
        SKUList:Dictionary of [text,Decimal];
        LineNo:Integer;
        Item:record Item;
        IsRel:Boolean;
        Excp:record "PC Purch Exceptions";
        ExcpMsg:record "PC EDI Exception Messages"; 
   begin
        Flg := false;
        If  PurchHdr."Fulfilo ASN Status" <> PurchHdr."Fulfilo ASN Status"::Completed then Exit(True);
        IsRel := PurchHdr.Status = PurchHdr.Status::Released;
        PurchHdr.Status := PurchHdr.Status::Open;
        PurchHdr.Modify(False);    
        Clear(LineNo);
        Purchline.Reset;
        PurchLine.Setrange("Document No.",PurchHdr."No.");
        PurchLine.Setrange("Document Type",PurchHdr."Document Type");
        If Purchline.findlast then LineNo := Purchline."Line No.";
        Corr.Reset();
        Corr.Setrange(User,UserId);
        If Corr.findset then Corr.DeleteAll();    
        Clear(data);
        Clear(Parms);
        Clear(PayLoad);
        If FulFilio_Data(Paction::GET,'/api/v1/asns/' + Format(PurchHdr."Fulfilo Order ID") +'/stockreceipts',Parms,PayLoad,Data) Then 
        begin
            Data.Get('data',JsToken[1]);
            Clear(Excnt);
            Clear(NoOrd);
            Clear(InvOrd);
            JsArry := JsToken[1].AsArray;
            if Not JsArry.get(0,JsToken[1]) then
            begin
                If GuiAllowed then Error('Failed To Retrieve Stock Receipt Json Token');
                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                ExcpMsg."Exception Message" := 'EDI Fulfilio -> Failed To Retrieve Stock Receipt Json Token';
                ExcpMsg.modify;
                if not Excp.Get(PurchHdr."No.") then
                begin
                    Excp.init; 
                    Excp."Purchase Order No." := PurchHdr."No.";
                    Excp."Exception Date" := Today;
                    Excp.Insert;
                end;
                exit(false);
            end;
            JsToken[1].SelectToken('stock_receipt_products',JsToken[2]);
            JsArry := JsToken[2].AsArray;
            For i := 0 to JsArry.Count - 1 do
            begin
                JsArry.get(i,JsToken[1]);
                JsToken[1].SelectToken('sku',JsToken[2]);
                sku := JsToken[2].AsValue().AsCode();
                JsToken[1].SelectToken('quantity',JsToken[2]);
                qty[1] := JsToken[2].AsValue().AsDecimal();
                If SKUList.ContainsKey(Sku) then
                begin
                    SKuList.get(SKU,qty[2]);
                    SkuList.Set(SKU,qty[1] + Qty[2]);    
                end
                else
                    SkuList.Add(SKU,qty[1]);    
            end;
            SKUKeys := SKUList.Keys;    
            // here we loop and check the received fulfilio qty to the ordered qty    
            For i := 1 to SKUKeys.count do
            begin
                Skulist.Get(SkuKeys.Get(i),Qty[1]);
                Purchline.Reset;
                PurchLine.Setrange("Document No.",PurchHdr."No.");
                PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                Purchline.Setrange(type,PurchLine.type::Item);
                Purchline.Setrange("No.",SkuKeys.Get(i));
                If Purchline.Findset then
                begin
                    If UseDisplay then
                    begin
                        Corr.init;
                        Clear(Corr.ID);
                        Corr.Insert();
                        Corr.User := UserId;
                        Corr.PO := PurchHdr."No.";
                        Corr.SKU := Purchline."No.";
                        Corr.description := PurchLine.Description;
                        Corr."Original Order Qty" := PurchLine."Quantity (base)";
                        Corr."Fulfilo Corrected Qty" := qty[1];
                        if Qty[1] <> PurchLine."Quantity (base)" then Corr."Correction Status" := Corr."Correction Status"::Corrected;
                        Corr.Modify();
                    end;
                    if Qty[1] <> PurchLine."Quantity (base)" then Excnt += 1;
                    Purchline."Fulfilo Recvd Qty" := Qty[1];
                    Purchline.Modify(False);
                end
                else
                begin
                    If Item.Get(SkuKeys.Get(i)) then
                    Begin               
                        LineNo += 10000;
                        Purchline.Init;
                        PurchLine.Validate("Document No.",PurchHdr."No.");
                        PurchLine.Validate("Document Type",PurchHdr."Document Type");
                        Purchline.Validate("Line No.",LineNo);
                        Purchline.insert;
                        Purchline.validate(type,PurchLine.type::Item);
                        Purchline.validate("No.",SkuKeys.Get(i));
                        Purchline.Validate("Unit of Measure Code",Item."Base Unit of Measure");
                        Purchline.Validate(Quantity,Qty[1]);
                        Purchline."Fulfilo Recvd Qty" := Qty[1];
                        Clear(Purchline."Original Order Qty");
                        Clear(Purchline."Original Order Qty(base)");
                        Clear(Purchline."Original Order UOM");
                        Purchline.Modify();
                        If UseDisplay then
                        begin
                            Corr.init;
                            Clear(Corr.ID);
                            Corr.Insert();
                            Corr.User := UserId;
                            Corr.PO := PurchHdr."No.";
                            Corr.SKU := Purchline."No.";
                            Corr.description := PurchLine.Description;
                            Corr."Original Order Qty" := 0;
                            Corr."Fulfilo Corrected Qty" := qty[1];
                            Corr."Correction Status" := Corr."Correction Status"::"Not Ordered";
                            Corr.Modify();
                        end;
                        NoOrd += 1;
                    end
                    else If UseDisplay then
                    begin
                        Corr.init;
                        Clear(Corr.ID);
                        Corr.Insert();
                        Corr.User := UserId;
                        Corr.PO := PurchHdr."No.";
                        Corr.SKU := SkuKeys.Get(i);
                        Corr.description := 'Unknown SKU Error';
                        Corr."Original Order Qty" := 0;
                        Corr."Fulfilo Corrected Qty" := qty[1];
                        Corr."Correction Status" := Corr."Correction Status"::"Unknown SKU";
                        Corr.Modify();
                    end;
                    InvOrd += 1;
                end;
            end;
            Purchline.Reset;
            PurchLine.Setrange("Document No.",PurchHdr."No.");
            PurchLine.Setrange("Document Type",PurchLine."Document Type"::Order);
            Purchline.Setrange(type,PurchLine.type::Item);
            PurchLine.Setrange("Fulfilo Recvd Qty",-1);
            If Purchline.Findset then
            repeat
                Excnt += 1;
                Purchline."Fulfilo Recvd Qty" := 0;
                Purchline.Modify(False);
                If UseDisplay then
                begin
                    Corr.init;
                    Clear(Corr.ID);
                    Corr.Insert();
                    Corr.User := UserId;
                    Corr.PO := PurchHdr."No.";
                    Corr.SKU := PurchLine."No.";
                    Corr.description := PurchLine.Description;
                    Corr."Original Order Qty" := PurchLine."Quantity (base)";
                    Corr."Fulfilo Corrected Qty" := 0;
                    if 0 <> PurchLine."Quantity (base)" then Corr."Correction Status" := Corr."Correction Status"::Corrected;
                    Corr.Modify();
                end;
            Until PurchLine.Next = 0;
            If (Excnt > 0) Or (NoOrd > 0) Or (InvOrd > 0) then
            begin
                If POEx.Get(PurchHdr."No.") then
                begin
                    POEx."Exception Count" := Excnt;
                    POEx."Not On Order Exception Count" := NoOrd;
                    POEx."Unknown SKU Exception Count" := InvOrd;
                    POEx.modify;
                end
                else
                begin
                    POEx.init;
                    POEx."Purchase Order No." := PurchHdr."No.";
                    POEx."Exception Date" := Today;
                    POEx."Exception Count" := Excnt;
                    POEx."Not On Order Exception Count" := NoOrd;
                    POEx."Unknown SKU Exception Count" := InvOrd;
                    POEx.insert;
                end;
                ExcpMsg.Reset;
                ExcpMsg.Setrange("Purchase Order No.",PurchHdr."No.");
                ExcpMsg.SetFilter("Exception Message",'*Receipting Errors*');
                If Not ExcpMsg.findset then
                begin
                    Init_Excpt_Msg(ExcpMsg,PurchHdr);
                    ExcpMsg."Exception Message" := 'EDI Fulfilio -> Receipting Errors have occured .. Check Fulfilio Exceptions';
                    ExcpMsg.modify;
                end;    
            end
            else
                flg := true;
        end
        else
        begin
            If GuiAllowed Then Message('Failed Communications to Fulfilio for stock receipts');
            ExcpMsg.Reset;
            ExcpMsg.Setrange("Purchase Order No.",PurchHdr."No.");
            ExcpMsg.SetFilter("Exception Message",'EDI Fulfilio -> Failed*');
            If Not ExcpMsg.findset then
            begin
                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                ExcpMsg."Exception Message" := 'EDI Fulfilio -> Failed Communications to Fulfilio for stock receipts';
                ExcpMsg.modify;
            end;    
        end;
        If IsRel then
        begin 
            PurchHdr.Status := PurchHdr.Status::Released;
            PurchHdr.Modify(false);
        end;    
        commit;
        ExcpMsg.reset;
        ExcpMsg.Setrange("Purchase Order No.",PurchHdr."No.");
        If ExcpMsg.findset then
        begin
            if not Excp.Get(PurchHdr."No.") then
            begin
                Excp.init; 
                Excp."Purchase Order No." := PurchHdr."No.";
                Excp."Exception Date" := Today;
                Excp.Insert;
            end;
        end;
        exit(Flg);             
    end;
    Procedure Build_Fulfilo_Inventory_Levels():Boolean
    var
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        i:Integer;
        Cnt:Integer;
        Finv:Record "PC Fulfilo Inventory";
        RunFlg:Boolean;
    Begin
        Clear(RunFlg);
        if FulFilo_Login_Connection() then
        Begin
            Clear(Cnt);
            Finv.Reset;
            If Finv.Findset then Finv.Deleteall();    
            Parms.add('limit','250');
            Parms.add('page','1');
            if FulFilio_Data(Paction::GET,'/api/v1/inventories',Parms,PayLoad,Data) then
            Begin
                if Data.Get('success',JsToken[1]) then 
                Begin
                    If JsToken[1].AsValue().AsBoolean() then
                    begin
                        Data.Get('pagination',JsToken[1]);
                        JsToken[1].SelectToken('number_of_pages',JsToken[2]);
                        Cnt := JsToken[2].AsValue().AsInteger();
                        Process_FulFilo_Stock_Levels(Data,1,Cnt);
                    end;     
                    If Cnt > 1 then 
                    begin
                        For i := 2 To Cnt do
                        begin
                            Clear(Parms);
                            Clear(PayLoad);
                            Clear(Data);
                            Parms.add('limit','250');
                            Parms.add('page',Format(i));
                            FulFilio_Data(Paction::GET,'/api/v1/inventories',Parms,PayLoad,Data);
                            if Data.Get('success',JsToken[1]) then
                                If JsToken[1].AsValue().AsBoolean() then Process_FulFilo_Stock_Levels(Data,i,Cnt);
                        end;        
                    end;
                    RunFlg := True;
                end;    
            end 
            else If GuiAllowed then Message('Failed Communications to fulfilio for inventory levels');
        end
        else If GuiAllowed then Message('Failed fulfilio login');
        exit(RunFlg);   
    end;
    Procedure Build_Fulfilo_Inventory_Deltas(Offset:Integer):Boolean
    var
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        i:Integer;
        Cnt:Integer;
        FRes:Record "PC Fulfilo Inv. Delta Reasons";
        RunFlg:Boolean;
    begin
        Clear(RunFlg);
        if FulFilo_Login_Connection() then
        Begin
            Clear(Cnt);
            FRes.Reset;
            if Fres.FindSet() then Fres.DeleteAll();
            If Offset = 0 then Offset := 7;
            Clear(Cnt);        
            Clear(Parms);
            Clear(PayLoad);
            Clear(Data);
            Parms.add('limit','250');
            Parms.add('page','1');
            Parms.Add('adjusted_from',Format(CalcDate('-'+ Format(Offset) + 'D',Today),0,'<Year4>-<Month,2>-<Day,2>T00%3A00%3A00%2B00%3A00'));    
            Parms.Add('adjusted_to',Format(Today,0,'<Year4>-<Month,2>-<Day,2>T00%3A00%3A00%2B00%3A00'));
            if FulFilio_Data(Paction::GET,'/api/v1/deltas',Parms,PayLoad,Data) then
            begin
                Data.Get('success',JsToken[1]); 
                If JsToken[1].AsValue().AsBoolean() then
                begin
                    Data.Get('pagination',JsToken[1]);
                    JsToken[1].SelectToken('number_of_pages',JsToken[2]);
                    Cnt := JsToken[2].AsValue().AsInteger();
                    Process_Fulfilo_Inv_Deltas(Data,1,Cnt);
                end;     
                If Cnt > 1 then 
                begin
                    For i := 2 To Cnt do
                    begin
                        Clear(Parms);
                        Clear(PayLoad);
                        Clear(Data);
                        Parms.add('limit','250');
                        Parms.add('page',Format(i));
                        Parms.Add('adjusted_from',Format(CalcDate('-'+ Format(Offset) + 'D',Today),0,'<Year4>-<Month,2>-<Day,2>T00%3A00%3A00%2B00%3A00'));    
                        Parms.Add('adjusted_to',Format(Today,0,'<Year4>-<Month,2>-<Day,2>T00%3A00%3A00%2B00%3A00'));
                        FulFilio_Data(Paction::GET,'/api/v1/deltas',Parms,PayLoad,Data);
                        Data.Get('success',JsToken[1]); 
                        If JsToken[1].AsValue().AsBoolean() then Process_Fulfilo_Inv_Deltas(Data,i,Cnt);
                    end;        
                end; 
                RunFlg := True; 
            end
            else If GuiAllowed then Message('Failed Communications with fulfilio for deltas');    
        end
        else If GuiAllowed then Message('Failed fulfilio login');
        exit(RunFlg);       
    end;    
    local procedure Process_Fulfilo_Stock_Levels(var Data:JsonObject;Cnt:Integer;PagCnt:integer)
    var
        Parms:Dictionary of [text,text];
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Loc:record Location;
        Item:Record Item;
        qty:decimal;
        i:integer;
        win:dialog;
        Finv:Record "PC Fulfilo Inventory";
        CRLF:Text[2];
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        Data.Get('data',JsToken[1]);                            
        JsArry := JsToken[1].AsArray;
        if (JsArry.count > 0) AND GuiAllowed then win.Open('Fulfilio SKU Data Block #1### of ' + Format(PagCnt) + CRLF
                                                        +  'Fulfilio -> #2#############');
        If GuiAllowed then win.update(1,Cnt);                                                
        For i:= 0 to JsArry.Count - 1 do
        begin
            JsArry.get(i,JsToken[1]);
            jstoken[1].SelectToken('sku',JsToken[2]);
            if GuiAllowed then Win.Update(2,JsToken[2].AsValue().AsCode());
            If Item.Get(JsToken[2].AsValue().AsCode()) then
            begin
                jstoken[1].SelectToken('quantity',JsToken[2]);            
                qty := JsToken[2].AsValue().AsDecimal();
                jstoken[1].SelectToken('warehouse',JsToken[2]);
                JsToken[2].SelectToken('id',JsToken[1]);
                Loc.reset;
                Loc.Setrange("Fulfilo Warehouse ID",JsToken[1].AsValue().AsInteger());
                If Loc.findset then 
                Begin
                    If Not Finv.get(Item."No.",Loc.Code) then
                    begin
                        Finv.SKU := Item."No.";
                        Finv."Location Code" := Loc.Code;
                        Finv.Insert;
                    end;
                    Finv.Qty := qty;
                    Finv.Modify();        
                end;
            end;
        end;
        if (JsArry.count > 0) and GuiAllowed then win.Close;
    end;
 local procedure Process_Fulfilo_Inv_Deltas(var Data:JsonObject;Cnt:integer;PagCnt:Integer)
    var
        Parms:Dictionary of [text,text];
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Loc:record Location;
        Item:Record Item;
        qty:decimal;
        i:integer;
        win:dialog;
        FRes:Record "PC Fulfilo Inv. Delta Reasons";
        FTrack:Record "PC BC Fulfilio Inv Chg Tracker";
        Adj:DateTime;
        TxtDat:text;
        dat: Date;
        Tim:Time;
        reas:code[5];
        CRLF:Text[2];
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        Data.Get('data',JsToken[1]);                            
        JsArry := JsToken[1].AsArray;
        if (JsArry.count > 0) AND GuiAllowed then win.Open('Fulfilio SKU Delta Data Block #1### of ' + Format(PagCnt) + CRLF
                                                          +'Fulfilio Delta -> #2#############');

        If GuiAllowed then win.update(1,Cnt);                                                
        For i:= 0 to JsArry.Count - 1 do
        begin
            JsArry.get(i,JsToken[1]);
            jstoken[1].SelectToken('sku',JsToken[2]);
            if GuiAllowed then Win.Update(2,JsToken[2].AsValue().AsCode());
            If Item.Get(JsToken[2].AsValue().AsCode()) then
            begin
                jstoken[1].SelectToken('warehouse',JsToken[2]);
                JsToken[2].SelectToken('id',JsToken[1]);
                Loc.reset;
                Loc.Setrange("Fulfilo Warehouse ID",JsToken[1].AsValue().AsInteger());
                If Loc.findset then 
                Begin
                    JsArry.get(i,JsToken[1]);
                    jstoken[1].SelectToken('reason_code',JsToken[2]);
                    If Not Jstoken[2].AsValue().IsNull then
                        If Jstoken[2].AsValue().AsText().StartsWith('SA') then
                        begin
                            reas := Jstoken[2].AsValue().AsCode();
                            jstoken[1].SelectToken('adjusted_at',JsToken[2]);
                            TxtDat := Jstoken[2].AsValue().Astext;
                            EVALUATE(DAT,Copystr(TxtDat,9,2)+ '/' + CopyStr(TxtDat,6,2) + '/' + CopyStr(TxtDat,1,4));
                            Evaluate(Tim,CopyStr(txtDat,12,8)); 
                            Adj := CreateDateTime(DAT,Tim);
                            If Not FRes.get(Item."No.",Loc.Code,Adj) then
                            begin
                                Fres.init;
                                FRes.SKU := Item."No.";
                                FRes."Location Code" := Loc.Code;
                                FRes."Adjusted DateTime" := ADj;
                                FRes.Insert;
                            end;
                            Fres."Reason Code" := Reas;
                            Case Fres."Reason Code" of
                                'SA1': FRes."Reason Description" := 'Damaged In Transit';
                                'SA2': FRes."Reason Description" := 'Damaged in Warehouse';
                                'SA3': FRes."Reason Description" := 'Receipt Error';
                                'SA4': FRes."Reason Description" := 'Cycle Count Variance';
                                'SA5': FRes."Reason Description" := 'Manufacturer Defect';
                                'SA6': FRes."Reason Description" := 'Re-work';
                                'SA7': FRes."Reason Description" := 'Consumed to packing';
                                'SA8': FRes."Reason Description" := 'Kitting';
                                'SA9': FRes."Reason Description" := 'Quarantined-non-saleable';
                                'SA10': FRes."Reason Description" := 'Quarantined-saleable';
                                'SA11': FRes."Reason Description" := 'Quarantined on Receipt';
                                'RCP': FRes."Reason Description" := 'Receipt';
                                'PCK': FRes."Reason Description" := 'Sales order';
                            end;    
                            jstoken[1].SelectToken('sub_reason_code',JsToken[2]);
                            If Not Jstoken[2].AsValue().IsNull then
                            begin
                                FRes."Sub Reason Code" := JsToken[2].AsValue().AsCode();
                                Case Fres."Sub Reason Code" of
                                    'RTS': FRes."Sub Reason Description" := 'Return to Sender';
                                    'ASN': FRes."Sub Reason Description" := 'Advanced Shipping Notice';
                                    'OTH': FRes."Sub Reason Description" := 'Other';
                                    'RET': FRes."Sub Reason Description" := 'Customer Return';
                                end;
                            end;
                            jstoken[1].SelectToken('delta',JsToken[2]);
                            Fres."Adjusted Qty" := JsToken[2].AsValue().AsDecimal();
                            If FTrack.get(FRes.SKU,FRes."Location Code",Fres."Adjusted DateTime") then
                            begin
                                Fres."Adjusted In BC" := true;
                                FRes."BC Adjustment DateTime" := FTrack."BC Adjusted DateTime";
                            end;
                            Fres.Modify();
                        end;
                end;            
            End;
        end;
        if (JsArry.count > 0) AND GuiAllowed then win.Close;
    end;
    procedure Adjust_Inventory(var Item:record Item;Loc:Code[10];Qty:Decimal;Var Reas:record "PC Fulfilo Inv. Delta Reasons"):Boolean;
    var
        ItemJrnLine:Record	"Item Journal Line";	
        CuItemJrnl:Codeunit	"Item Jnl.-Post Line";	
        ItemJrnBatch:Record	"Item Journal Batch";	
        Reason:Record	"Reason Code";
        FTrck:Record "PC BC Fulfilio Inv Chg Tracker";
        GLSetup:record "General Ledger Setup";
        PstDate:date;
        flg:boolean;
    begin
        IF NOT Reason.GET('FULADJST') THEN
        BEGIN
            Reason.Code := 'FULADJST';
            Reason.Description := 'Fulfilio Adjustments';
            Reason.INSERT;
        END;
        IF NOT ItemJrnBatch.GET('ITEM','FULADJST') THEN
        BEGIN
            ItemJrnBatch."Journal Template Name" := 'ITEM';
            ItemJrnBatch.Name := 'FULADJST';
            ItemJrnBatch.Description := 'Fulfilio Adjustments';
            ItemJrnBatch."Reason Code" := Reason.Code;
            ItemJrnBatch."Template Type" := ItemJrnBatch."Template Type"::Item;
            ItemJrnBatch.INSERT;
        END;
        Clear(PstDate);
        GLSetup.get;
        If (GLSetup."Allow Posting To" <> 0D) And (GLSetup."Allow Posting To" < Today) then
        begin
            PstDate := GLSetup."Allow Posting To";
            Clear(GLSetup."Allow Posting To");
            GLSetup.Modify(false);
        end;
        CLEAR(ItemJrnLine);
        ItemJrnLine.INIT;
        ItemJrnLine."Journal Template Name" := ItemJrnBatch."Journal Template Name";
        ItemJrnLine."Journal Batch Name" := ItemJrnBatch.Name;
        ItemJrnLine."Document No." := STRSUBSTNO('FUL - %1',FORMAT(WORKDATE,0,'<Day,2>/<Month,2>/<Year4>'));
        ItemJrnLine."Line No." := 10000;
        ItemJrnLine."Posting Date" := TODAY;
        If Qty < 0 then
            ItemJrnLine."Entry Type" := ItemJrnLine."Entry Type"::"Negative Adjmt."
        else
            ItemJrnLine."Entry Type" := ItemJrnLine."Entry Type"::"Positive Adjmt.";
        ItemJrnLine.Description := 'Fulfilio Balance Adjustment';
        ItemJrnLine.VALIDATE("Item No.",Item."No.");
        ItemJrnLine.VALIDATE("Unit Cost",Item."Unit Cost");
        ItemJrnLine.VALIDATE("Location Code",Loc);
        ItemJrnLine.VALIDATE("Unit of Measure Code",Item."Base Unit of Measure");
        ItemJrnLine.VALIDATE(Quantity,ABS(qty));
        if not Reas.IsEmpty then          
        begin
            ItemJrnLine."Reason Code" := Reas."Reason Code";
            ItemJrnLine."Return Reason Code" := ItemJrnLine."Reason Code";
            If Not FTrck.get(Reas.SKU,Reas."Location Code",Reas."Adjusted DateTime") then
            begin
                FTrck.init;
                FTrck.SKU := Reas.SKU;
                FTrck."Location Code" := Reas."Location Code";
                FTrck."Fulfilio Adjusted DateTime" := Reas."Adjusted DateTime";
                Ftrck.Insert();
            end;
            FTrck."BC Adjusted DateTime" := CurrentDateTime;
            FTrck."Adjusted Qty" := qty;
            FTrck.Modify();
            Reas."Adjusted In BC" := true;
            reas."BC Adjustment DateTime" := CurrentDateTime;
            reas.modify();
        end
        else
        begin
            ItemJrnLine."Reason Code" := ItemJrnBatch."Reason Code";
            ItemJrnLine."Return Reason Code" := ItemJrnBatch."Reason Code";
        end;
        COMMIT;
        Flg := CuItemJrnl.RUN(ItemJrnLine);
        If PstDate <> 0D then
        begin
            GLSetup."Allow Posting To" := PstDate;
            GLSetup.Modify(false);
        end;
        exit(flg);
    end;
    procedure Adjust_QC_Inventory(var Item:record Item;Qty:Decimal):Boolean;
    var
        ItemJrnLine:Record	"Item Journal Line";	
        CuItemJrnl:Codeunit	"Item Jnl.-Post Line";	
        ItemJrnBatch:Record	"Item Journal Batch";	
        Reason:Record	"Reason Code";
        GLSetup:record "General Ledger Setup";
        PstDate:date;
        flg:boolean;
    begin
        IF NOT Reason.GET('FULADJST') THEN
        BEGIN
            Reason.Code := 'FULADJST';
            Reason.Description := 'Fulfilio Adjustments';
            Reason.INSERT;
        END;
        IF NOT ItemJrnBatch.GET('ITEM','FULADJST') THEN
        BEGIN
            ItemJrnBatch."Journal Template Name" := 'ITEM';
            ItemJrnBatch.Name := 'FULADJST';
            ItemJrnBatch.Description := 'Fulfilio Adjustments';
            ItemJrnBatch."Reason Code" := Reason.Code;
            ItemJrnBatch."Template Type" := ItemJrnBatch."Template Type"::Item;
            ItemJrnBatch.INSERT;
        END;
        Clear(PstDate);
        GLSetup.get;
        If (GLSetup."Allow Posting To" <> 0D) And (GLSetup."Allow Posting To" < Today) then
        begin
            PstDate := GLSetup."Allow Posting To";
            Clear(GLSetup."Allow Posting To");
            GLSetup.Modify(false);
        end;
        CLEAR(ItemJrnLine);
        ItemJrnLine.INIT;
        ItemJrnLine."Journal Template Name" := ItemJrnBatch."Journal Template Name";
        ItemJrnLine."Journal Batch Name" := ItemJrnBatch.Name;
        ItemJrnLine."Document No." := STRSUBSTNO('FUL - %1',FORMAT(WORKDATE,0,'<Day,2>/<Month,2>/<Year4>'));
        ItemJrnLine."Line No." := 10000;
        ItemJrnLine."Posting Date" := TODAY;
        If Qty < 0 then
            ItemJrnLine."Entry Type" := ItemJrnLine."Entry Type"::"Negative Adjmt."
        else
            ItemJrnLine."Entry Type" := ItemJrnLine."Entry Type"::"Positive Adjmt.";
        ItemJrnLine.Description := 'Fulfilio Balance Adjustment';
        ItemJrnLine.VALIDATE("Item No.",Item."No.");
        ItemJrnLine.VALIDATE("Unit Cost",Item."Unit Cost");
        ItemJrnLine.VALIDATE("Location Code",'QC');
        ItemJrnLine.VALIDATE("Unit of Measure Code",Item."Base Unit of Measure");
        ItemJrnLine.VALIDATE(Quantity,ABS(qty));
        ItemJrnLine."Reason Code" := ItemJrnBatch."Reason Code";
        ItemJrnLine."Return Reason Code" := ItemJrnBatch."Reason Code";
        COMMIT;
        Flg := CuItemJrnl.RUN(ItemJrnLine);
        If PstDate <> 0D then
        begin
            GLSetup."Allow Posting To" := PstDate;
            GLSetup.Modify(false);
        end;
        exit(flg);
    end;

   // rountine called via Inventory Update to Proces outstanding PO's
    /*local procedure Process_Fulfilo_Purchase_Orders()
    var
        PurchHdr:Record "Purchase Header";
        Purchline:record "Purchase Line";
        Cu:Codeunit "Purchase Batch Post Mgt.";
        Excp:record "PC Purch Exceptions";
    begin
        PurchHdr.Reset;
        PurchHdr.Setrange("Document Type",PurchHdr."Document Type"::Order);
        PurchHdr.Setrange("Order Type",PurchHdr."Order Type"::Fulfilo);
        PurchHdr.Setrange(Status,PurchHdr.Status::Released);
        PurchHdr.SetFilter("Fulfilo ASN Status",'<>%',PurchHdr."Fulfilo ASN Status"::Completed);
        If PurchHdr.FindSet() then
        repeat
            Get_ASN_Order_Status(PurchHdr,false);
            Commit;    
        until PurchHdr.next = 0;
        PurchHdr.Setrange("Fulfilo ASN Status", PurchHdr."Fulfilo ASN Status"::Completed);
        if PurchHdr.FindSet() then
        repeat
            If Not Excp.Get(PurchHdr."No.") then
            begin
                Purchline.Reset;
                Purchline.Setrange("Document Type",PurchHdr."Document Type");
                Purchline.Setrange("Document No.",PurchHdr."No.");
                Purchline.Setfilter("Qty. to Receive (Base)",'>0');
                If Purchline.findset then Cu.RunBatch(PurchHdr,false,WorkDate(),False,True,True,False);
            end;    
        Until PurchHdr.next = 0;
    end;
   */ 
  // routine to include rebate information as required on purchase lines
    Procedure Purch_Rebates(var Purchline:record "Purchase Line")
    var
        SupBrand:Record "PC Supplier Brand Rebates";
        PurchHdr:record "Purchase Header";    
        Item:Record Item;
    begin
        PurchHdr.Get(Purchline."Document Type",Purchline."Document No.");
        If (Purchline.Type = Purchline.Type::Item) AND (PurchHdr."Order Type" = Purchhdr."Order Type"::Fulfilo) then
        begin
            Item.Get(Purchline."No.");
            If Item.Type = Item.Type::Inventory then
            begin
                SupBrand.reset;
                SupBrand.Setrange("Supplier No.",Purchline."Buy-from Vendor No.");
                SupBrand.Setrange(Brand,Item.Brand);
                SupBrand.Setrange("Rebate Status",SupBrand."Rebate Status"::Open);
                SupBrand.Setfilter("Rebate Start Date Period",'<=%',Today);
                If SupBrand.Findset then
                begin
                    Purchline."Line Rebate %" := SupBrand."Volume Rebate %";
                    Purchline."Line Rebate %" += SupBrand."Marketing Rebate %";
                    Purchline."Line Rebate %" += SupBrand."Supply Chain Rebate %";
                    Purchline.Brand := SupBrand.Brand;
                    Purchline."Rebate Supplier No." := SupBrand."Rebate Supplier No.";
                end;
                Purchline.validate("Indirect Cost %",-Purchline."Line Rebate %");    
            end;    
        end;    
    end; 
 // event on Purchase Post to check for discrepencies with fulfilo PO's
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', true, true)]
    local procedure "Purch.-Post_OnBeforePostPurchaseDoc"
    (
        var PurchaseHeader: Record "Purchase Header";
		PreviewMode: Boolean;
		CommitIsSupressed: Boolean;
		var HideProgressWindow: Boolean
    )
    var
        Flg:boolean;
        PurchLine:record "Purchase Line";
        Excp:record "PC Purch Exceptions";
    begin
        Flg := True;
        If PurchaseHeader."Rebate Post Lock" then Error('Posting Blocked Due To Rebate Processing In Operation\'
                                                      + 'Complete Rebate Processing and Retry');
        if PurchaseHeader."Order Type" = PurchaseHeader."Order Type"::Fulfilo then
        begin
            If PurchaseHeader."Fulfilo ASN Status" = PurchaseHeader."Fulfilo ASN Status"::Completed then
            begin
                PurchLine.Reset;
                Purchline.Setrange("Document Type",PurchaseHeader."Document Type");
                Purchline.Setrange("Document No.",PurchaseHeader."No.");
                Purchline.Setrange(Type,PurchLine.type::Item);
                If Purchline.findset then
                repeat
                    Flg := Purchline."Quantity (Base)" <> PurcHline."Fulfilo Recvd Qty";
                until (Purchline.Next = 0) or Flg;
                If Flg Then Error('Purchase Order Still Contains Fulfilio Exception Qtys .. Correct And Retry');
                // remove the exception record now
                if Excp.Get(PurchaseHeader."No.") then Excp.Delete;
            end   
            else If Not Confirm('This Fulfilio Order does not have a ASN Completed Status ... Continue on regardless',false) then
                error('');
        end;          
    end;
  // event to build rebates for rebate processing
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostItemLine', '', true, true)]
    local procedure "Update Accural Rebates"
    (
        PurchaseLine: Record "Purchase Line";
        CommitIsSupressed: Boolean;
        PurchaseHeader: Record "Purchase Header";
        RemQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoicedBase: Decimal
    )
    var
        Reb:Record "PC Purchase Rebates";
        SupBrand:Record "PC Supplier Brand Rebates";
        Item:Record Item;
        i:Integer;    
        Amt:Decimal;
    begin
        If (PurchaseHeader."Order Type" = PurchaseHeader."Order Type"::fulfilo) 
            And (Purchaseline."Document type" = PurchaseLine."Document Type"::order)
            And (Purchaseline.Type = PurchaseLine.Type::Item)
            And (PurchaseLine."Indirect Cost %" < 0) then
        begin
            Amt := ABS(Purchaseline.Amount * (PurchaseLine."Indirect Cost %"/100));  
            Item.Get(Purchaseline."No.");
            SupBrand.reset;
            SupBrand.Setrange("Supplier No.",PurchaseHeader."Buy-from Vendor No.");
            SupBrand.Setrange(Brand,Item.Brand);
            SupBrand.Setrange("Rebate Status",SupBrand."Rebate Status"::Open);
            SupBrand.Setfilter("Rebate Start Date Period",'<=%',Today);
            If SupBrand.Findset then
                For i:= 1 to 3 do
                begin
                    Reb.init;
                    Clear(Reb.ID);
                    Reb.Insert();
                    Reb."Document No." := PurchaseHeader."Posting No.";
                    Reb."Rebate Date" := PurchaseHeader."Posting Date";
                    Reb."Supplier No." := PurchaseHeader."Buy-from Vendor No.";
                    Reb."Rebate Supplier No." := SupBrand."Rebate Supplier No.";
                    Reb."Item No." := PurchaseLine."No.";
                    Reb."Document Line No." := PurchaseLine."Line No.";
                    Reb.Brand := SupBrand.Brand;
                    Case i of
                        1:
                        begin
                            Reb."Rebate Type" := Reb."Rebate Type"::Volume;
                            Reb."Rebate Value" := amt * ABS(SupBrand."Volume Rebate %"/PurchaseLine."Indirect Cost %");
                            Reb."Rebate %" := SupBrand."Volume Rebate %";  
                        end;
                        2:
                        begin
                            Reb."Rebate Type" := Reb."Rebate Type"::Marketing;
                            Reb."Rebate Value" := amt * ABS(SupBrand."Marketing Rebate %"/PurchaseLine."Indirect Cost %");
                            Reb."Rebate %" := SupBrand."Marketing Rebate %";  
                        end;
                        3:
                        begin
                            Reb."Rebate Type" := Reb."Rebate Type"::"Data Share";
                            Reb."Rebate Value" := amt * ABS(SupBrand."Supply Chain Rebate %"/PurchaseLine."Indirect Cost %"); 
                            Reb."Rebate %" := SupBrand."Supply Chain Rebate %"; 
                        end;
                    end;
                    Reb.Modify();
                end;
        end;               
    end;
}