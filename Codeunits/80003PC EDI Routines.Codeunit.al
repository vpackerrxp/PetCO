codeunit 80003 "PC EDI Routines"
{
    Var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
        errText:text;

    trigger OnRun()
    begin
        Process_EDI_Transaction_Documents();
        House_Keeping();        
    end;
    local procedure CallRESTWebService(var RestRec : Record "PC RESTWebServiceArguments";Parms:Dictionary of [text,text];Data:text) : Boolean
    var
        Client : HttpClient;
        Headers : HttpHeaders;
        RequestMessage : HttpRequestMessage ;
        ResponseMessage : HttpResponseMessage;
        Content : HttpContent;
        AuthText : text;
        HttpUrl :text;
        i:Integer;  
        ParmKeys: List of [Text];
        ParmVals: List of [Text];
        ParmData:text;
    begin
        RequestMessage.Method := Format(RestRec.RestMethod);
        HttpUrl := RestRec.URL;
        If Parms.Count > 0 then
        begin
            If not HttpUrl.EndsWith('?') then HttpUrl += '?';
            ParmKeys := Parms.Keys();
            ParmVals := Parms.Values();
            If Parms.Count > 1 then
            begin
                for i:= 1 to Parms.Count - 1 do
                begin
                    ParmKeys.Get(i,ParmData);
                    HttpUrl += ParmData + '=';
                    ParmVals.Get(i,ParmData);
                    HttpUrl += ParmData + '&';
                end;
            end 
            else
                i:= 0;
            i+=1;        
            ParmKeys.Get(i,ParmData);
            HttpUrl += ParmData + '=';
            ParmVals.Get(i,ParmData);
            HttpUrl += ParmData;
        end;
        RequestMessage.SetRequestUri(HttpUrl);
        if not RequestMessage.GetHeaders(Headers) then exit(false);
        If Restrec."Sps Access Token 1" <> '' then Headers.Add('Authorization', 'Bearer ' + RestRec."SPS Access Token 1" +  RestRec."SPS Access Token 2");
        If Restrec.RestMethod  in [RestRec.RestMethod::POST
                                  ,RestRec.RestMethod::PUT,RestRec.RestMethod::PATCH] then
        begin
            // get the payload data now
            Content.WriteFrom(Data);
            if Not Content.GetHeaders(Headers) Then Exit(false);
            Headers.Clear();
            If RestRec."Token Type" = RestRec."Token Type"::SpsData then
                Headers.Add('Content-Type','application/text')
            else
                Headers.Add('Content-Type','application/json');
           RequestMessage.Content := Content;  
        end; 
        Client.Clear();
        If Client.Send(RequestMessage, ResponseMessage) then
        begin        
            Headers := ResponseMessage.Headers;
            RestRec.SetResponseHeaders(Headers);
            Content := ResponseMessage.Content;
            RestRec.SetResponseContent(Content);
            EXIT(ResponseMessage.IsSuccessStatusCode);
        end
        else
            Exit(False);    
    end;
    local procedure House_Keeping()
    var
        Logs:record "Job Queue Log Entry";
    begin
        Logs.Reset;
        Logs.Setrange("Object Type to Run",Logs."Object Type to Run"::Codeunit);
        Logs.setrange("Object ID to Run",Codeunit::"PC EDI Routines");
        Logs.Setrange(Status,Logs.Status::Success);
        Logs.Setfilter("End Date/Time",'<%1',CreateDateTime(Today,0T));
        If Logs.Findset then Logs.DeleteAll(false);
    end;
    local procedure EDI_Data(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:jsonobject;DataFlg:boolean): boolean
    var
        Ws:Record "PC RestWebServiceArguments";
        Setup:record "Sales & Receivables Setup";
    begin
        Setup.Get();
        Ws.init;
        Ws.Url := Request;
        If DataFlg then
            Ws."Token Type" := Ws."Token Type"::SpsData
        else
            Ws."Token Type" := Ws."Token Type"::SpsAuth;
        ws."SPS Access Token 1" := Setup."SPS Access Token 1"; 
        ws."SPS Access Token 2" := Setup."SPS Access Token 2"; 
        Ws.RestMethod := Method;
        Clear(errText);
        if CallRESTWebService(ws,Parms,Payload) then
           exit(Data.ReadFrom(ws.GetResponseContentAsText()))
        else
        begin
            errText := ws.GetResponseContentAsText();      
            exit(false);
        end;    
    end; 
    local procedure EDI_Data_AsArray(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:JsonArray): boolean
    var
        Ws:Record "PC RestWebServiceArguments";
        Setup:record "Sales & Receivables Setup";
    begin
        Setup.Get();
        Ws.init;
        Ws.Url := Request;
        Ws."Token Type":= Ws."Token Type"::SpsData;
        ws."SPS Access Token 1" := Setup."SPS Access Token 1"; 
        ws."SPS Access Token 2" := Setup."SPS Access Token 2"; 
        Ws.RestMethod := Method;
        Clear(errText);
        if CallRESTWebService(ws,Parms,Payload) then
           exit(Data.ReadFrom(ws.GetResponseContentAsText()))
        else
        begin
            errText := ws.GetResponseContentAsText();      
            exit(false);
        end;    
    end; 

    local procedure EDI_XML_Data(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:XmlDocument;DataFlg:boolean): boolean
    var
        Ws:Record "PC RestWebServiceArguments";
        Setup:record "Sales & Receivables Setup";
    begin
        Setup.Get();
        Ws.init;
        Ws.Url := Request;
        If DataFlg then
            Ws."Token Type" := Ws."Token Type"::SpsData
        else
            Ws."Token Type" := Ws."Token Type"::SpsAuth;
        ws."SPS Access Token 1" := Setup."SPS Access Token 1"; 
        ws."SPS Access Token 2" := Setup."SPS Access Token 2"; 
        Ws.RestMethod := Method;
        Clear(errText);
        if CallRESTWebService(ws,Parms,Payload) then
           exit(XmlDocument.ReadFrom(ws.GetResponseContentAsText(),Data))
        else
        begin
            errText := ws.GetResponseContentAsText();      
            exit(false);
        end;    
    end; 
    procedure Get_EDI_Access_Token(ClearKey:boolean):Boolean
    var
        Setup:Record "Sales & Receivables Setup";
        Jsobj:JsonObject;
        Parms:Dictionary of [text,text];
        Payload:Text;
        Jstoken:JsonToken;
        //request:Label 'https://auth.spscommerce.com/oauth/token';
    begin
        Setup.Get;
        If Setup."SPS Token Date" < TODAY then
        begin         
            Clear(Setup."SPS Access Token 1");
            Clear(Setup."SPS Access Token 2");
            Setup.Modify(false);
            Commit();
        end;
        If ClearKey then CLear(Setup."SPS Access Token 1");    
        If Setup."SPS Access Token 1" = '' then
        begin    
            Clear(Parms);
            Clear(Jsobj);
            Clear(Payload);
            Jsobj.add('grant_type','client_credentials');
            jsobj.add('client_id',Setup."SPS Client ID");
            jsobj.add('client_secret',Setup."SPS Secret Key");
            Jsobj.add('audience','api://api.spscommerce.com/');
            Jsobj.WriteTo(Payload);
            clear(Jsobj);
            If EDI_Data(Paction::POST,Setup."SPS EDI Auth Token Folder Path",Parms,Payload,Jsobj,false) then
            begin
                Jsobj.get('access_token',JStoken);
                Setup."SPS Access Token 1" := CopyStr(Jstoken.AsValue().AsText(),1,1000);
                Setup."SPS Access Token 2" := CopyStr(Jstoken.AsValue().AsText(),1001,200);
                Setup."SPS Token Date" := Today;
                Setup.modify(false);
                Commit;     
            end
            else
                if GuiAllowed then Message(errText);
        end;
        exit(Setup."SPS Access Token 1" <> '');        
    end;
    local procedure Ascii_Parser(val:text):Text
    var
        i:integer;
        j:integer;
        RetVal:text;
    begin
        Clear(retVal);    
        for i:= 1 to strlen(val) do
        begin
            For j:= 32 to 255 do
                if Val[i] = j then
                    RetVal += Val[i]
        end;
        exit(retval);
    end;
    local procedure GTIN_Parser(Val:Text):text
    var
        i:integer;
        j:integer;
        RetVal:text;
    begin
        Clear(retVal);    
        for i:= 1 to strlen(val) do
        begin
            For j:= 48 to 57 do
                if Val[i] = j then
                    RetVal += Val[i]
        end;
        exit(retval);
    end;
    Procedure Build_EDI_Purchase_Order(var PurchHdr:record "Purchase Header";FuncCode:Code[10]):Boolean;
    var
        PurchLine:record "Purchase Line";
        XmlDoc:XmlDocument;
        CurrNode:Array[4] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        LineNo:Integer;
        Ven:Record Vendor;
        Loc:Record Location;
        Item:record Item;
        Comm:Record "Purch. Comment Line";
        Comments:text;
        Jsobj:JsonObject;
        Parms:Dictionary of [text,text];
        Payload:Text;
        //request:Label 'https://api.spscommerce.com/transactions/v2/';
        //Path:Label 'in/';
        CompInfo:record "Company Information";
        CUF:Codeunit "PC Fulfilio Routines";
        Ret:Boolean;
        Setup:record "Sales & Receivables Setup";
    Begin
        If FuncCode = '' then Exit;
        Setup.get;
        Ret := Get_EDI_Access_Token(false);
        if Ret then
        begin
            If FuncCode = 'ORIGINAL' then
            begin
                PurchHdr.CalcFields(Amount);
                If PurchHdr."Invoice Discount Value" > 0 then
                    PurchHdr."Invoice Disc %" := PurchHdr."Invoice Discount value" * 100/(PurchHdr.Amount + PurchHdr."Invoice Discount value")
                else
                    Clear(PurchHdr."Invoice Disc %");
                PurchHdr.modify(false);
            end;
            CompInfo.get;
            XmlDoc := XmlDocument.Create();
            CuXML.AddRootElement(XmlDoc,'PurchaseOrder',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'Header','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'PurchaseOrderNumber',PurchHdr."No.",'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'MessageFunctionCode',FuncCode,'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'PurchaseOrderDate',Format(PurchHdr."Order Date",0,'<Day,2>-<Month,2>-<Year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'RequestedDeliveryDate',Format(PurchHdr."Requested Receipt Date",0,'<Day,2>-<Month,2>-<year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'RequestedDeliveryTime',Format(PurchHdr."Requested Receipt Time",0,'<Hours24,2>:<Minutes,2>:<Seconds,2>'),'',CurrNode[2]);
            If PurchHdr."Fulfilo Order ID" > 0 then
                CuXML.AddElement(CurrNode[1],'BookingReferenceNumber',PurchHdr."Fulfilo External Id",'',CurrNode[2])
            else
                CuXML.AddElement(CurrNode[1],'BookingReferenceNumber','','',CurrNode[2]);
            Clear(Comments);
            Comm.reset;
            Comm.Setrange("Document Type",PurchHdr."Document Type");
            Comm.Setrange("No.",PurchHdr."No.");
            If Comm.findset then  
            repeat
                Comments += Comm.Comment + ' ';
            until Comm.Next = 0;                
            CuXML.AddElement(CurrNode[1],'Notes',Comments,'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','BUYER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','PETCULTURE','',CurrNode[1]);
            If Compinfo."Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',CompInfo.Name + ' ' + Compinfo."Name 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'PartyName',CompInfo.Name,'',CurrNode[1]);
            If CompInfo."Address 2" <> '' then     
                CuXML.AddElement(CurrNode[2],'Address',CompInfo.Address + ' ' + CompInfo."Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',CompInfo.Address,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',CompInfo.City,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',compinfo.County,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',compinfo."Post Code",'',CurrNode[1]);
            If CompInfo."Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Country',CompInfo."Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',CompInfo."Contact Person",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Phone',Compinfo."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Compinfo."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SUPPLIER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier',PurchHdr."Buy-from Vendor No.",'',CurrNode[1]);
            If PurchHdr."Buy-from Vendor Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',PurchHdr."Buy-from Vendor Name" + ' ' + PurchHdr."Buy-from Vendor Name 2",'',CurrNode[1])
            else
                 CuXML.AddElement(CurrNode[2],'PartyName',PurchHdr."Buy-from Vendor Name",'',CurrNode[1]);
            if  PurchHdr."Buy-from Address 2" <> '' then   
                CuXML.AddElement(CurrNode[2],'Address',PurchHdr."Buy-from Address" + ' ' + PurchHdr."Buy-from Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',PurchHdr."Buy-from Address",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',PurchHdr."Buy-from City",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',PurchHdr."Buy-from County",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',PurchHdr."Buy-from Post Code",'',CurrNode[1]);
            if PurchHdr."Buy-from Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Country',PurchHdr."Buy-from Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',PurchHdr."Buy-from Contact",'',CurrNode[1]);
            Ven.Get(PurchHdr."Buy-from Vendor No.");
            CuXML.AddElement(CurrNode[2],'Phone',Ven."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Ven."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SHIPTO','',CurrNode[1]);
            Loc.Get(PurchHdr."Location Code");
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','DC'+ Loc.Code,'',CurrNode[1]);
            If Loc."Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',Loc.Name + ' ' + Loc."Name 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'PartyName',Loc.Name,'',CurrNode[1]);
            if Loc."Address 2" <> '' then    
                CuXML.AddElement(CurrNode[2],'Address',Loc.Address + ' ' + Loc."Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',Loc.Address,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',Loc.City,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',Loc.County,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',Loc."Post Code",'',CurrNode[1]);
            If Loc."Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
            CuXML.AddElement(CurrNode[2],'Country',Loc."Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',loc.Contact,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Phone',Loc."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Loc."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
            If PurchHdr."Currency Code" = '' then
                CuXML.AddElement(CurrNode[1],'Currency','AUD','',CurrNode[2])
            else
                CuXML.AddElement(CurrNode[1],'Currency',PurchHdr."Currency Code",'',CurrNode[2]);
            PurchHdr.CalcFields(Amount,"Amount Including VAT");    
            If PurchHdr."Invoice Discount Value" > 0 then
            begin
                CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
                CuXML.AddElement(CurrNode[1],'AllowancesOrCharges','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrCharge','ALLOWANCE','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeIdentifier','ORDDISC','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeDescription','Order Discount','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeAmount',Format(PurchHdr."Invoice Discount Value",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
               //See if tax applies or not   
                If PurchHdr."Amount" <> PurchHdr."Amount Including VAT" then
                begin
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate',Format(PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount',Format(PurchHdr."Invoice Discount Value"/100 * (PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount")),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                end
                else
                begin    
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate','0','',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount','0','',CurrNode[1]);
                end;    
            end;
            PurchLine.Reset;
            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
            PurchLine.setrange("Document No.",PurchHdr."No.");
            Purchline.Setrange(Type,PurchLine.type::Item);
            PurchLine.Setrange("No.",'FREIGHT');
            Purchline.Setfilter(Quantity,'>0');
            If Purchline.Findset then
            begin
                CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
                CuXML.AddElement(CurrNode[1],'AllowancesOrCharges','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrCharge','CHARGE','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeIdentifier','FC','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeDescription','Freight Cost','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeAmount',Format(PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                //CuXML.AddElement(CurrNode[2],'AllowanceOrChargePercentage','0','',CurrNode[1]);
                If PurchLine."VAT %" > 0 then
                begin
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate',Format(PurchLine."VAT %",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount',Format(PurchLine."Line Amount" * PurchLine."VAT %"/100,0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                end
                else
                begin    
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate','0','',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount','0','',CurrNode[1]);
                end; 
            end;
            Clear(LineNo);    
            CuXML.FindNode(CurrNode[1],'//PurchaseOrder',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'LineItems','','',CurrNode[1]);
            Purchline.SetFilter("No.",'<>FREIGHT');
            If PurchLine.findset then
            repeat
                LineNo += 1;
                CuXML.AddElement(CurrNode[1],'LineItem','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'LineNumber',Format(PurchLine."Line No."),'',CurrNode[3]);
                Item.Get(PurchLine."No.");
                CuXML.AddElement(CurrNode[2],'GTIN',GTIN_parser(Item.GTIN),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'BuyerPartNumber',PurchLine."No.",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'VendorPartNumber',Purchline."Vendor Item No.",'',CurrNode[3]);
                If PurchLine."Description 2" <> '' then
                    CuXML.AddElement(CurrNode[2],'ProductDescription',Ascii_parser(PurchLine.Description) + ' ' + Ascii_parser(PurchLine."Description 2"),'',CurrNode[3])
                else
                    CuXML.AddElement(CurrNode[2],'ProductDescription',Ascii_parser(PurchLine.Description),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'OrderQty',Format(PurchLine.Quantity,0,'<Precision,2><Standard Format,0>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'OrderQtyUOM',PurchLine."Unit of Measure Code",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'PackSize',Format(PurchLine."Qty. per Unit of Measure",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'UnitPrice',Format(PurchLine."Direct Unit Cost",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'TaxRate',Format(PurchLine."VAT %",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                If PurchLine."Line Discount %" > 0 then 
                begin
                    CuXML.AddElement(CurrNode[2],'AllowancesOrCharges','','',CurrNode[3]);
                    CuXML.AddElement(CurrNode[3],'AllowanceOrCharge','ALLOWANCE','',CurrNode[4]);
                    CuXML.AddElement(CurrNode[3],'AllowanceOrChargePercentage',Format(PurchLine."Line Discount %",0,'<Precision,2><Standard Format,1>'),'',CurrNode[4]);
                    CuXML.AddElement(CurrNode[3],'AllowanceOrChargeAmount',Format(PurchLine."Line Discount Amount"/Purchline.Quantity,0,'<Precision,2><Standard Format,1>'),'',CurrNode[4]);
                end;    
                CuXML.AddElement(CurrNode[2],'LineAmountExcGST',Format(PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'LineAmountGST',Format(PurchLine."Line Amount" * PurchLine."VAT %"/100,0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'LineAmountIncGST',Format(Purchline."Line Amount" + (PurchLine."Line Amount" * PurchLine."VAT %"/100),0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
            until PurchLine.next = 0;
            CuXML.FindNode(CurrNode[2],'//PurchaseOrder',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'Summary','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'NumberOfLines',Format(LineNo),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'OrderAmountExcGST',Format(PurchHdr.Amount,0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'OrderAmountGST',Format(PurchHdr."Amount Including VAT" - PurchHdr.Amount,0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'OrderAmountIncGST',Format(PurchHdr."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            XmlDoc.WriteTo(Payload);
            Payload := Payload.Replace('utf-16','utf-8');
            Clear(Jsobj);
            Clear(parms);
            Ret := EDI_Data(Paction::POST,Setup."SPS EDI Base Folder Path" + Setup."SPS EDI In Folder" + PurchHdr."No." + '.xml',Parms,Payload,Jsobj,true);
            If Ret then
            begin
                Case FuncCode of
                    'ORIGINAL':PurchHdr."EDI Transaction Status" := PurchHdr."EDI Transaction Status"::ORIGINAL;
                    'REPLACE':PurchHdr."EDI Transaction Status" := PurchHdr."EDI Transaction Status"::REPLACE;
                    'CANCEL':
                        begin
                            PurchHdr."EDI Transaction Status" := PurchHdr."EDI Transaction Status"::CANCEL;
                            If PurchHdr."Fulfilo Order ID" > 0 then CUF.Cancel_ASN(PurchHdr);
                        end;
                End;
                PurchHdr.modify(False);
            end;    
            Commit;
        end;
        exit(Ret);
    End;
    procedure Simulate_EDI_Processing(Mode:Boolean)
    var
        jobque:record "Job Queue Entry";
    begin
        Jobque.Reset;
        jobque.Setrange("Object Type to Run",jobque."Object Type to Run"::Codeunit);
        jobque.setrange("Object ID to Run",Codeunit::"PC EDI Routines");
        If jobque.findset then
        Begin
            If Mode then
                jobque.SetStatus(jobque.Status::Ready)
            else    
                jobque.SetStatus(jobque.Status::"On Hold");
        end;    
    end;

    procedure Process_EDI_Transaction_Documents()
    var
        Parms:Dictionary of [text,text];
        Payload:Text;
        JsToken:array[2] of JsonToken;
        JSArray:JsonArray;
        FileLst:List of [Text];
        i:Integer;
        j:integer;
        XmlDoc:XmlDocument;
        CurrNode:Array[4] of XmlNode;
        xmlNodeLst:XmlNodeList;
        CuXML:Codeunit "XML DOM Management";
        EDIHdrBuff:array[2] of record "PC EDI Header Buffer";
        hasData:Boolean;
        Outstrm:OutStream;
        PurchHdr:record "Purchase Header";
        ExcpMsg:record "PC EDI Exception Messages";
        CUF:Codeunit "PC Fulfilio Routines";
        win:Dialog; 
        Setup:record "Sales & Receivables Setup";
        PayTerm:record "Payment Terms";
    begin
        // house keep the table
        EDIHdrBuff[1].Reset;
        EDIHdrBuff[1].Setfilter("Date Received",'<%1',CalcDate('-3M',Today));
        If EDIHdrBuff[1].findset then EDIHdrBuff[1].DeleteAll();
       // now see what's in the EDI out Box
        Setup.Get; 
        If Get_EDI_Access_Token(false) then
        begin
            Clear(Parms);
            Clear(Payload);
            Clear(JSArray);
            Clear(Filelst);
            If EDI_Data_AsArray(Paction::Get,Setup."SPS EDI Base Folder Path" + Setup."SPS EDI Out Folder" +  '*',Parms,Payload,JSArray) then
            begin
                for i := 0 to JSArray.Count - 1 do
                begin
                    JSArray.get(i,JsToken[1]);
                    JsToken[1].SelectToken('key',JsToken[2]);
                    FileLst.Add(JsToken[2].AsValue().AsText());
                end;
                for i := 1 to FileLst.Count do
                begin
                    Clear(Parms);
                    Clear(Payload);
                    Clear(hasData);
                    If EDI_XML_Data(Paction::Get,Setup."SPS EDI Base Folder Path" + FileLst.Get(i),Parms,Payload,XmlDoc,true) then
                    begin
                        EDIHdrBuff[1].init;
                        Clear(EDIHdrBuff[1].ID);
                        EDIHdrBuff[1].Insert;
                        EDIHdrBuff[1]."Date Received" := Today;
                        CurrNode[1] := XmlDoc.AsXmlNode();
                        If CuXML.FindNode(CurrNode[1],'//PurchaseOrderResponse',CurrNode[2]) then
                        begin
                            EDIHdrBuff[1]."Response Type" := EDIHdrBuff[1]."Response Type"::Response;
                            CuXML.FindNode(CurrNode[1],'//PurchaseOrderResponse/Header/PurchaseOrderNumber',CurrNode[2]);
                            EDIHdrBuff[1]."Purchase Order No." := CurrNode[2].AsXmlElement().InnerText;
                            CuXML.FindNode(CurrNode[1],'//PurchaseOrderResponse/Header',CurrNode[2]);
                            CurrNode[2].AsXmlElement().SelectNodes('NameAddressParty',xmlNodeLst);
                            hasData := True;
                        end
                        else If CuXML.FindNode(CurrNode[1],'//DespatchAdvice',CurrNode[2]) then
                        begin
                            EDIHdrBuff[1]."Response Type" := EDIHdrBuff[1]."Response Type"::Dispatch;
                            CuXML.FindNode(CurrNode[1],'//DespatchAdvice/Header/PurchaseOrderNumber',CurrNode[2]);
                            EDIHdrBuff[1]."Purchase Order No." := CurrNode[2].AsXmlElement().InnerText;
                            CuXML.FindNode(CurrNode[1],'//DespatchAdvice/Header',CurrNode[2]);
                            CurrNode[2].AsXmlElement().SelectNodes('NameAddressParty',xmlNodeLst);
                            hasData := True;
                        end
                        else If CuXML.FindNode(CurrNode[1],'//Invoice',CurrNode[2]) then
                        begin
                            CuXML.FindNode(CurrNode[1],'//Invoice/Header/InvoiceType',CurrNode[2]);
                            If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'DR'then
                                EDIHdrBuff[1]."Response Type" := EDIHdrBuff[1]."Response Type"::Invoice
                            else
                                EDIHdrBuff[1]."Response Type" := EDIHdrBuff[1]."Response Type"::CreditNote;
                            CuXML.FindNode(CurrNode[1],'//Invoice/Header/PurchaseOrderNumber',CurrNode[2]);
                            EDIHdrBuff[1]."Purchase Order No." := CurrNode[2].AsXmlElement().InnerText;
                            CuXML.FindNode(CurrNode[1],'//Invoice/Header',CurrNode[2]);
                            CurrNode[2].AsXmlElement().SelectNodes('NameAddressParty',xmlNodeLst);
                            hasData := True;
                        end
                        else If CuXML.FindNode(CurrNode[1],'//InventoryReport',CurrNode[2]) then
                        begin
                            EDIHdrBuff[1]."Response Type" := EDIHdrBuff[1]."Response Type"::Inventory;
                            EDIHdrBuff[1]."Purchase Order No." := 'N/A';
                            CuXML.FindNode(CurrNode[1],'//InventoryReport/Header/InventoryReportIssueDate',CurrNode[2]);
                            Evaluate(EDIHdrBuff[1]."Date Received",CurrNode[2].AsXmlElement().InnerText);
                            CuXML.FindNode(CurrNode[1],'//InventoryReport/Header',CurrNode[2]);
                            CurrNode[2].AsXmlElement().SelectNodes('NameAddressParty',xmlNodeLst);
                            hasData := True;
                        end;
                        if hasData then
                        begin
                            For j := 1 to XMLNodeLst.Count do
                            begin
                                XmlNodeLst.Get(j,CurrNode[1]);
                                CuXML.FindNode(CurrNode[1],'PartyCodeQualifier',CurrNode[2]);
                                If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'SUPPLIER' then
                                begin
                                    CuXML.FindNode(CurrNode[1],'PartyIdentifier',CurrNode[2]);
                                    EDIHdrBuff[1]."Supplier No." := CurrNode[2].AsXmlElement().InnerText;
                                    break;    
                                end;
                            end;
                            Clear(EDIHdrBuff[1].Processed);
                            EDIHdrBuff[1].Data.CreateOutStream(Outstrm);
                            XmlDoc.WriteTo(Payload);
                            Outstrm.Write(Payload);    
                            // get rid of old inventory report if there
                            If EDIHdrBuff[1]."Response Type" = EDIHdrBuff[1]."Response Type"::Inventory then
                            begin
                                EDIHdrBuff[2].Reset;
                                EDIHdrBuff[2].Setrange("Purchase Order No.",'N/A');
                                EDIHdrBuff[2].Setrange("Supplier No.",EDIHdrBuff[1]."Supplier No.");
                                EDIHdrBuff[2].Setfilter(ID,'<%1',EDIHdrBuff[1].ID);
                                If EDIHdrBuff[2].findset then EDIHdrBuff[2].DeleteAll();
                            end;    
                            EDIHdrBuff[1].Modify();
                        end 
                        else
                            EDIHdrBuff[1].Delete();
                        EDI_XML_Data(Paction::DELETE,Setup."SPS EDI Base Folder Path" + FileLst.Get(i),Parms,Payload,XmlDoc,true);
                    end;
               end;
            end;
            //send any new PO's to EDI now    
            PurchHdr.reset;
            PurchHdr.Setrange(Status,PurchHdr.status::Released);
            PurchHdr.Setrange("Order Type",PurchHdr."Order Type"::Fulfilo);
            //PurchHdr.Setrange("EDI Status",PurchHdr."EDI Status"::"EDI Vendor");
            //PurchHdr.Setrange("No.",'PO-00000996');
            If PurchHdr.findset then
            repeat
                If PurchHdr."EDI Status" = PurchHdr."EDI Status"::"EDI Vendor" then
                begin
                    If PurchHdr."EDI Transaction Status" = PurchHdr."EDI Transaction Status"::" " then
                    begin
                        Build_EDI_Purchase_Order(PurchHdr,'ORIGINAL');
                        EDI_Execution_Transaction_Log(PurchHdr,0);
                    end;
                    if (PurchHdr."Fulfilo Order ID" > 0) And (PurchHdr."Fulfilo ASN Status" <> PurchHdr."Fulfilo ASN Status"::Completed) then
                        CUF.Get_ASN_Order_Status(PurchHdr,False);
                    If PurchHdr."EDI Transaction Status" > 0 then
                        Process_EDI_Documents(PurchHdr);
                End  //Here we automate ASN Status for Non EDI Vendors 
                else if (PurchHdr."Fulfilo Order ID" > 0) And (PurchHdr."Fulfilo ASN Status" <> PurchHdr."Fulfilo ASN Status"::Completed) then
                    CUF.Get_ASN_Order_Status(PurchHdr,False);
            until PurchHdr.next = 0;
             //see if any credit notes exist
            Process_EDI_Credits();
        end;     
    end;
    local procedure Init_Excpt_Msg(var ExcpMsg:record "PC EDI Exception Messages";var PH:Record "Purchase Header")
    begin
        ExcpMsg.Init();
        Clear(ExcpMsg.ID);
        ExcpMsg.insert;
        ExcpMsg."Purchase Order No." := PH."No.";
        ExcpMsg."Exception Date" := TODAY;
    end;
    local procedure EDI_Execution_Log(var EDIBuff:Record "PC EDI Header Buffer")
    var
        EXLog:Record "PC EDI Execution Log";
    begin
        EXLog.init;
        Clear(EXLog.ID);
        EXLog.insert;
        EXLog."Execution Date/Time" := CurrentDateTime();
        Exlog."Purchase Order No." := EDIBuff."Purchase Order No.";
        EXLog.Vendor := EDIBuff."Supplier No.";
        Exlog."EDI Execution Action" := EDIBuff."Response Type";
        Exlog.modify;
    end; 
    local procedure EDI_Execution_Transaction_Log(var PO:Record "Purchase Header";RespType:Integer)
    var
        EXLog:Record "PC EDI Execution Log";
    begin
        EXLog.init;
        Clear(EXLog.ID);
        EXLog.insert;
        EXLog."Execution Date/Time" := CurrentDateTime();
        Exlog."Purchase Order No." := PO."No.";
        EXLog.Vendor := PO."Buy-from Vendor No.";
        Exlog."EDI Execution Action" := RespType;
        Exlog."Transaction Status" := PO."EDI Transaction Status";
        Exlog.modify;
    end; 
    local procedure Process_EDI_Documents(var PurchHdr:record "Purchase Header")
    var
        XmlDoc:XmlDocument;
        CurrNode:Array[4] of XmlNode;
        xmlNodeLst:array[2] of XmlNodeList;
        CuXML:Codeunit "XML DOM Management";
        EDIHdrBuff:record "PC EDI Header Buffer";
        Instrm:InStream;
        BuffData:text;
        PurchLine:Record "Purchase Line";
        XmlPath:text;
        SKUKeys:list of [text];
        SKUList:Dictionary of [text,Boolean];
        TstSku:Boolean;
        Excp:record "PC Purch Exceptions";
        ExcpMsg:record "PC EDI Exception Messages"; 
        LineNo:Integer;
        Qty:Decimal;
        UOM:Code[10];
        Price:decimal;
        i:integer;
        j:Integer;
        origQty:array[2] of decimal;
        OrdCnt:Integer;
        EDICnt:Integer;
        CUF:Codeunit "PC Fulfilio Routines";
        CUP:Codeunit "Purch.-Post";
        CUS:Codeunit "PC Shopify Routines";
        DspChg:boolean;
        LineDisc:Decimal;
        LineDiscAmt:decimal;
        Setup:Record "Sales & Receivables Setup";
        Tolerances:array[3] of Decimal;
        tstDate:date;
        GLSetup:record "General Ledger Setup";
        PstDate:date;
        Itemtmp:record Item temporary;
        ItemTmp2:record Item temporary;
        PayTermMsg:text;
        CUPT:Codeunit "Purch - Calc Disc. By Type";
        CRLF:text[2];
        Flg:Boolean;
        mesg:text;
        FirstResp:Boolean;
        respChg:boolean;
        PurchHdrTemp:record "Purchase Header" temporary;
        PurchLineTemp:record "Purchase Line" temporary;
        PayTerms:record "Payment Terms";
    begin
        Clear(PurchHdrTemp);
        Clear(PurchLineTemp);
        // See if any exceptions already exist
        ExcpMsg.reset;
        ExcpMsg.Setrange("Purchase Order No.",PurchHdr."No.");
        if ExcpMsg.findset then
        begin 
            // check that the log entry exists
            if not Excp.Get(PurchHdr."No.") then
            begin
                Cus.Send_Email_Msg('EDI Exceptions Exist For PO No ' + PurchHdr."No.",'',False,'');        
                Excp.init; 
                Excp."Purchase Order No." := PurchHdr."No.";
                Excp."Exception Date" := Today;
                Excp.Insert;
            end;
            Exit;
        end;
        PurchHdrtemp.Copy(PurchHdr);
        Setup.get;
        Tolerances[1] := Setup."EDI Order Value Tolerance %"/100;
        Tolerances[2] := Setup."EDI Line Value Tolerance %"/100;
        Tolerances[3] := Setup."EDI Line Qty Tolerance %"/100;
        CRLF[1] := 13;
        CRLF[2] := 10;
        Clear(PayTermMsg);
        Clear(OrdCnt);
        Clear(EDICnt);
        Clear(SKUList);
        Clear(SKUKeys);
        PurchLine.reset;
        PurchLine.Setrange("Document Type",PurchHdr."Document Type");
        PurchLine.setrange("Document No.",PurchHdr."No.");
        Purchline.Setrange(Type,PurchLine.type::Item);
        PurchLine.Setfilter("No.",'<>FREIGHT');
        Purchline.Setfilter(Quantity,'>0');
        If PurchLine.findset then
        begin 
            OrdCnt := Purchline.Count;
            repeat
                If SKUList.ContainsKey(PurchLine."No.") then
                    SkuList.Set(PurchLine."No.",false)    
               else
                    SkuList.Add(PurchLine."No.",false);    
            until PurchLine.next = 0;
        end;
        EDIHdrBuff.Reset;
        EDIHdrBuff.Setrange(Processed,false);
        Case PurchHdr."Fulfilo ASN Status" of
            PurchHdr."Fulfilo ASN Status"::" ",PurchHdr."Fulfilo ASN Status"::"In Progress":
            Begin
                EDIHdrBuff.Setrange("Response Type",EDIHdrBuff."Response Type"::Response);
                XmlPath := '//PurchaseOrderResponse/';
            end;    
            PurchHdr."Fulfilo ASN Status"::Pending:
            begin
                EDIHdrBuff.Setrange("Response Type",EDIHdrBuff."Response Type"::Dispatch);
                XmlPath := '//DespatchAdvice/';
            end;    
            PurchHdr."Fulfilo ASN Status"::Completed:
            begin
                EDIHdrBuff.Setrange("Response Type",EDIHdrBuff."Response Type"::Invoice);
                XmlPath := '//Invoice/';
            end;
            else
               exit;
        end;  
        EDIHdrBuff.Setrange("Purchase Order No.",PurchHdr."No."); 
        if EDIhdrbuff.findset then 
        begin
            EDI_Execution_Log(EDIHdrBuff);
            if PurchHdr."EDI Transaction Status" = PurchHdr."EDI Transaction Status"::CANCEL then
            begin
                EDIHdrBuff.Processed := True;
                EDIHdrBuff.Modify(false);
                exit;
            end;
            EDIhdrbuff.Data.CreateInStream(Instrm);
            EDIhdrbuff.CalcFields(Data);
            Instrm.Read(BuffData);
            XmlDocument.ReadFrom(BuffData,xmldoc);
            CurrNode[1] := XmlDoc.AsXmlNode();
            Case EDIHdrBuff."Response Type" of
                EDIHdrBuff."Response Type"::Response:
                begin
                    FirstResp := PurchHdr."EDI Transaction Status" = PurchHdr."EDI Transaction Status"::ORIGINAL;
                    PurchHdr."EDI Response Received" := True;
                    PurchHdr.Modify(false);
                    Clear(respChg);
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header/MessageFunctionCode',CurrNode[2]);
                    If CurrNode[2].AsXmlElement().InnerText = 'REJECTED' then
                    begin
                        Init_Excpt_Msg(ExcpMsg,PurchHdr);
                        ExcpMsg."Exception Message" := 'EDI Response ->Complete PO Order has been Rejected by Supplier';
                        ExcpMsg.modify;
                        EDIHdrBuff.Processed := True;
                        EDIHdrBuff.Modify(false);
                        exit;                                
                    end;
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header/RequestedDeliveryDate',CurrNode[2]);
                    If Evaluate(tstDate,Currnode[2].AsXmlElement().InnerText) then
                    Begin
                       /* If Tstdate < PurchHdr."Requested Receipt Date" then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Response -> Requested Delivery Date %1 < PO Request Delivery Date %2'
                                                                    ,tstDate,PurchHdr."Requested Receipt Date");
                            ExcpMsg.modify;
                        end;
                        If Tstdate > CalcDate('+'+ Format(Setup."EDI Del Date Tolerance Days") + 'D',PurchHdr."Requested Receipt Date")  then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Response -> Requested Delivery Date %1 > PO Request Delivery Date with Tolerance %2'
                                                                    ,tstDate,
                                                                    CalcDate('+'+ Format(Setup."EDI Del Date Tolerance Days") + 'D',PurchHdr."Requested Receipt Date"));
                            ExcpMsg.modify;
                        end;*/
                        If Tstdate <> PurchHdr."Requested Receipt Date" then
                        begin
                            PurchHdrTemp."Requested Receipt Date" := TstDate;
                            respChg := true;
                        end;
                    end 
                    else
                    begin
                        Init_Excpt_Msg(ExcpMsg,PurchHdr);
                        ExcpMsg."Exception Message" := 'EDI Response -> Unable to evaluate EDIRequested Delivery Date';
                        ExcpMsg.modify;
                    end;    
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('NameAddressParty',xmlNodeLst[1]);
                    For j := 1 to XMLNodeLst[1].Count do
                    begin
                        XmlNodeLst[1].Get(j,CurrNode[1]);
                        CuXML.FindNode(CurrNode[1],'PartyCodeQualifier',CurrNode[2]);
                        If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'SUPPLIER' then
                        begin
                            CuXML.FindNode(CurrNode[1],'PartyIdentifier',CurrNode[2]);
                            If PurchHdr."Buy-from Vendor No." <>  CurrNode[2].AsXmlElement().InnerText then
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Response -> Supplier %1 does not Match PO Supplier %2'
                                                            , CurrNode[2].AsXmlElement().InnerText,PurchHdr."Buy-from Vendor No.");
                                ExcpMsg.modify;
                            end;
                        end;
                        If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'SHIPTO' then
                        begin
                            CuXML.FindNode(CurrNode[1],'PartyIdentifier',CurrNode[2]);
                            If 'DC' + PurchHdr."Location Code" <>  CurrNode[2].AsXmlElement().InnerText then
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Response -> Shipto Location %1 does not Match PO Shipto Location %2'
                                                            , CurrNode[2].AsXmlElement().InnerText,'DC' + PurchHdr."Location Code");
                                ExcpMsg.modify;
                            end;
                        end;
                    end;
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('AllowancesOrCharges',xmlNodeLst[1]);
                    PurchLine.SetRange("No.",'FREIGHT');
                    Flg := Purchline.findset;
                    For j := 1 to xmlNodeLst[1].count do
                    begin
                        XmlNodeLst[1].Get(j,CurrNode[1]);
                        CuXML.Findnode(CurrNode[1],'AllowanceOrChargeAmount',CurrNode[2]);
                        Evaluate(Price,CurrNode[2].AsXmlElement().InnerText);
                        CuXML.Findnode(CurrNode[1],'AllowanceOrChargeIdentifier',CurrNode[2]);
                        if CurrNode[2].AsXmlElement().InnerText = 'FC' then
                        begin
                            PurchLine.SetRange("No.",'FREIGHT');
                            If Purchline.findset then
                            begin
                                If Price > PurchLine."Line Amount" then
                                begin
                                    Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                    ExcpMsg."Exception Message" := strsubStno('EDI Response -> Freight Rate %1 exceeds PO Freight Rate %2'
                                                                        ,Round(Price,2), PurchLine."Line Amount");
                                    ExcpMsg.modify;
                                end
                                else If Price < PurchLine."Line Amount" then
                                begin
                                    PurchLineTemp.copy(PurchLine);
                                    PurchLineTemp."Direct Unit Cost" := Price;
                                    PurchLineTemp.insert;
                                    respChg := True;
                                end;
                                Clear(Flg);
                            end
                            Else
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Response -> EDI Freight Charge %1 supplied for No Freight PO'
                                                                            ,Round(price,2));                          
                                ExcpMsg.modify;
                            end;
                        end;                   
                    end;
                    // see if freight removed
                    if flg then
                    begin
                        PurchLineTemp.copy(PurchLine);
                        PurchLineTemp."Direct Unit Cost" := 0;
                        PurchLineTemp.Quantity := 0;
                        PurchLineTemp.insert;
                    end;
                    Itemtmp.reset;
                    If Itemtmp.findset Then Itemtmp.DeleteAll(false);
                    CuXML.FindNode(CurrNode[1],XMLPath + 'LineItems',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('LineItem',xmlNodeLst[1]);
                    For i := 1 to XMLNodeLst[1].Count do
                    begin
                        EDICnt +=1;
                        XmlNodeLst[1].Get(i,CurrNode[1]);
                        CuXML.FindNode(CurrNode[1],'LineNumber',CurrNode[2]);
                        Evaluate(LineNo,CurrNode[2].AsXmlElement().InnerText);
                        If Purchline.Get(PurchHdr."Document Type",PurchHdr."No.",LineNo) then
                        begin
                            Clear(LineDisc);
                            Clear(LineDiscAmt);
                            CuXML.FindNode(CurrNode[1],'DeliverQty',CurrNode[2]);
                            Evaluate(Qty,CurrNode[2].AsXmlElement().InnerText);
                            CuXML.FindNode(CurrNode[1],'OrderQtyUOM',CurrNode[2]);
                            UOM := CurrNode[2].AsXmlElement().InnerText.ToUpper();
                            CuXML.FindNode(CurrNode[1],'UnitPrice',CurrNode[2]);
                            Evaluate(Price,CurrNode[2].AsXmlElement().InnerText);
                            if CuXML.FindNode(CurrNode[1],'AllowancesOrCharges',CurrNode[2]) then
                            begin
                                CuXML.FindNode(CurrNode[2],'AllowanceOrChargeAmount',CurrNode[3]);
                                Evaluate(LineDiscAmt,CurrNode[3].AsXmlElement().InnerText); 
                                CuXML.FindNode(CurrNode[2],'AllowanceOrChargePercentage',CurrNode[3]);
                                Evaluate(LineDisc,CurrNode[3].AsXmlElement().InnerText);
                            end;    
                            CuXML.FindNode(CurrNode[1],'BuyerPartNumber',CurrNode[2]);
                            // check that the Item matches the line Number
                            If PurchLine."No." = CurrNode[2].AsXmlElement().InnerText.ToUpper() then
                            begin
                                SKUList.Set(PurchLine."No.",True);
                                If Itemtmp.get(PurchLine."No.") then 
                                Begin
                                    Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                    ExcpMsg."Exception Message" := strsubStno('EDI Response -> Item %1 Received Multiple Times Via EDI'
                                                                                ,Purchline."No.");                          
                                    ExcpMsg.modify;
                                end
                                else
                                begin
                                    ItemTmp."No." := PurchLine."No.";
                                    Itemtmp.insert(false);
                                    origQty[1] := PurchLine."Original Order Qty";
                                    origQty[2] := PurchLine."Original Order Qty(base)";
                                    CuXML.FindNode(CurrNode[1],'LineActionCode',CurrNode[2]);
                                    If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'REJECTED' then
                                        Clear(Qty)
                                    else if CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'ACCEPTED' then
                                    begin
                                        For j:= 1 to 4 do
                                        begin
                                            Case j of
                                                1:
                                                begin
                                                    Flg := Qty <> PurchLine.Quantity;
                                                    mesg := 'EDI Qty ' + Format(qty) + ' <> PO Qty ' + Format(PurchLine.Quantity); 
                                                end;
                                                2:
                                                begin
                                                    Flg := UOM <> PurchLine."Unit of Measure Code";
                                                    mesg := 'EDI UOM ' + UOM + ' <> PO UOM ' + PurchLine."Unit of Measure Code";
                                                end;
                                                3:
                                                begin
                                                    Flg := round(Price,2) <> Round(PurchLine."Direct Unit Cost",2);
                                                    Mesg := 'EDI Cost ' + Format(round(Price,2)) + ' <> PO Cost ' + Format(Round(PurchLine."Direct Unit Cost",2));         
                                                end;
                                                4:
                                                begin
                                                    Flg := round(LineDisc,2) <> round(PurchLine."Line Discount %",2);
                                                    mesg := 'EDI Line Disc % ' + Format(LineDisc,2) + ' <> PO Line Disc % ' + Format(round(PurchLine."Line Discount %",2));
                                                end;
                                            end;
                                            if Flg then
                                            begin
                                                Qty := -1;
                                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                                ExcpMsg."Exception Message" := strsubStno('EDI Response -> ACCEPTED ' + mesg 
                                                                                + ' for Item No %1 at Order Line No %2',
                                                                                    Purchline."No.",LineNo);                          
                                                ExcpMsg.modify;
                                            end;
                                        end;
                                    end
                                    else if CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'CHANGED' then
                                    begin
                                        For j:= 1 to 4 do
                                        begin
                                            Case j of
                                                1:
                                                begin
                                                    Flg := Qty > PurchLine.Quantity + (PurchLine.Quantity * Tolerances[3]);
                                                    mesg := 'EDI Qty ' + Format(qty) + ' > PO Qty ' + Format(PurchLine.Quantity 
                                                                                                + (PurchLine.Quantity * Tolerances[3])); 
                                                end;
                                                2:
                                                begin
                                                    Flg := UOM <> PurchLine."Unit of Measure Code";
                                                    mesg := 'EDI UOM ' + UOM + ' <> PO UOM ' + PurchLine."Unit of Measure Code";
                                                end;
                                                3:
                                                begin
                                                    Flg := round(Price,2) > Round(PurchLine."Direct Unit Cost" + (PurchLine."Direct Unit Cost" * Tolerances[2]),2);
                                                    Mesg := 'EDI Cost ' + Format(round(Price,2)) + ' > PO Cost ' + Format(Round(PurchLine."Direct Unit Cost" 
                                                                                                                + (PurchLine."Direct Unit Cost" * Tolerances[2]),2));         
                                                end;
                                                4:
                                                begin
                                                    Flg := round(LineDisc,2) < round(PurchLine."Line Discount %",2);
                                                    mesg := 'EDI Line Disc % ' + Format(LineDisc,2) + ' < PO Line Disc % ' + Format( round(PurchLine."Line Discount %",2));
                                                end;
                                            end;
                                            if Flg then
                                            begin
                                                Qty := -1;
                                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                                ExcpMsg."Exception Message" := strsubStno('EDI Response -> CHANGED ' + mesg 
                                                                                + ' for Item No %1 at Order Line No %2 is beyond acceptable limits for PO Line Values',
                                                                                    Purchline."No.",LineNo);                          
                                                ExcpMsg.modify;
                                            end;
                                        end;
                                    end;    
                                    If Qty > -1 then
                                    begin
                                        If Not respChg then
                                            Respchg := (PurchLine.Quantity <> qty) or
                                                        (PurchLine."Line Discount %" <> LineDisc) or
                                                        (Purchline."Direct Unit Cost" <> Price);
                                        PurchLineTemp.Copy(PurchLine);
                                        PurchLineTemp.Quantity := qty;
                                        PurchLineTemp."Original Order Qty" := origQty[1];
                                        PurchLinetemp."Original Order Qty(base)" := origQty[2];
                                        PurchLineTemp."Line Discount %" := LineDisc;
                                        PurchLineTemp."Direct Unit Cost" := Price;
                                        PurchLineTemp.Insert;      
                                    end;
                                end;    
                            end
                            else
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Response -> Item %1 does not match PO Item No for PO Order Line No %2 ',
                                                                            CurrNode[2].AsXmlElement().InnerText,LineNo);                          
                                ExcpMsg.modify(false);
                            end;
                        end    
                        else
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Response -> Failed to locate PO Order Line No %1',LineNo);
                            ExcpMsg.modify;
                        end;             
                    end;
                    /*
                    SKUKeys := SKUList.Keys;    
                    For j := 1 to SKUKeys.count do
                    begin
                        Skulist.Get(SkuKeys.Get(j),TstSku);
                        If Not TstSku then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Response -> Item %1 on PO not found in the EDI Response',
                                                                        SkuKeys.Get(j));
                            ExcpMsg.modify;
                        end;    
                    end;
                    */
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('AllowancesOrCharges',xmlNodeLst[1]);
                    Clear(Flg);
                    For j := 1 to xmlNodeLst[1].count do
                    begin
                        XmlNodeLst[1].Get(j,CurrNode[1]);
                        CuXML.Findnode(CurrNode[1],'AllowanceOrChargeAmount',CurrNode[2]);
                        Evaluate(Price,CurrNode[2].AsXmlElement().InnerText);
                        CuXML.Findnode(CurrNode[1],'AllowanceOrChargeIdentifier',CurrNode[2]);
                        If CurrNode[2].AsXmlElement().InnerText = 'ORDDISC' then
                        begin
                            Flg := True;
                            PurchLine.reset;
                            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                            PurchLine.setrange("Document No.",PurchHdr."No.");
                            Purchline.Setrange(Type,PurchLine.type::Item);
                            Purchline.Setfilter(Quantity,'>0');
                            If PurchLine.findset then
                            begin
                                PurchLine.CalcSums("Line Amount");
                                Price := Price/PurchLine."Line Amount" * 100;
                                If (Price < PurchHdr."Invoice Disc %") then
                                begin
                                    Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                    ExcpMsg."Exception Message" := strsubStno('EDI Response -> Invoice Discount Percentage %1 < PO Invoice Discount Percentage %2'
                                                                        ,Round(Price,2),PurchHdr."Invoice Disc %");
                                    ExcpMsg.modify;
                                end
                                else
                                    PurchHdrTemp."Invoice Disc %" := Price;
                            end;                      
                        end 
                    end;
                    // see if invoice discount is still on response.
                    If (PurchHdr."Invoice Discount Value" > 0) and Not Flg then
                    begin
                        Init_Excpt_Msg(ExcpMsg,PurchHdr);
                        ExcpMsg."Exception Message" := strsubStno('EDI Response -> Invoice Discount Value %1 not detected for PO'
                                                                    ,PurchHdr."Invoice Discount Value");
                        ExcpMsg.modify;
                    end;
                end;
                EDIHdrBuff."Response Type"::Dispatch:
                begin
                    Clear(DspChg);
                    PurchHdr."EDI Dispatch Received" := True;
                    PurchHdr.modify(false);
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header/EstimatedDeliveryDate',CurrNode[2]);
                    If Evaluate(tstDate,Currnode[2].AsXmlElement().InnerText) then
                    begin
                        /*If Tstdate < PurchHdr."Requested Receipt Date" then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Despatch -> Requested Delivery Date %1 < PO Request Delivery Date %2'
                                                                        ,tstDate,PurchHdr."Requested Receipt Date");
                            ExcpMsg.modify;
                        end;
                        If Tstdate > CalcDate('+'+ Format(Setup."EDI Del Date Tolerance Days") + 'D',PurchHdr."Requested Receipt Date")  then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Response -> Requested Delivery Date %1 > PO Request Delivery Date with Tolerance %2'
                                                                    ,tstDate,
                                                                    CalcDate('+'+ Format(Setup."EDI Del Date Tolerance Days") + 'D',PurchHdr."Requested Receipt Date"));
                            ExcpMsg.modify;
                        end;
                        */
                        If Tstdate <> PurchHdr."Requested Receipt Date" then
                        begin
                            PurchHdrTemp."Requested Receipt Date" := TstDate;
                            respChg := true;
                        end;
                    end 
                    else
                    begin
                        Init_Excpt_Msg(ExcpMsg,PurchHdr);
                        ExcpMsg."Exception Message" := 'EDI Despatch -> Unable to evaluate EDIRequested Delivery Date';
                        ExcpMsg.modify;
                    end;
                    /*    
                    CUXML.FindNode(CurrNode[1],XMLPath + 'Header/BookingReferenceNumber',CurrNode[2]);
                    If Evaluate(j,CurrNode[2].AsXmlElement().InnerText) then
                    begin
                        If PurchHdr."Fulfilo Order ID" <> j then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := strsubStno('EDI Despatch -> ASN No %1 does not match PO ASN No %2'
                                                                ,j,PurchHdr."Fulfilo Order ID");
                            ExcpMsg.modify;
                        end;
                    end 
                    else
                    begin
                        Init_Excpt_Msg(ExcpMsg,PurchHdr);
                        ExcpMsg."Exception Message" := strsubStno('EDI Despatch -> ASN No %1 is not valid'
                                                        ,CurrNode[2].AsXmlElement().InnerText);
                        ExcpMsg.modify;
                    end; 
                    */        
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('NameAddressParty',xmlNodeLst[1]);
                    For j := 1 to XMLNodeLst[1].Count do
                    begin
                        XmlNodeLst[1].Get(j,CurrNode[1]);
                        CuXML.FindNode(CurrNode[1],'PartyCodeQualifier',CurrNode[2]);
                        If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'SUPPLIER' then
                        begin
                            CuXML.FindNode(CurrNode[1],'PartyIdentifier',CurrNode[2]);
                            If PurchHdr."Buy-from Vendor No." <>  CurrNode[2].AsXmlElement().InnerText then
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Despatch -> Supplier %1 does not Match PO Supplier %2'
                                                            , CurrNode[2].AsXmlElement().InnerText,PurchHdr."Buy-from Vendor No.");
                                ExcpMsg.modify;
                            end;
                        end;
                        If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'SHIPTO' then
                        begin
                            CuXML.FindNode(CurrNode[1],'PartyIdentifier',CurrNode[2]);
                            If 'DC' + PurchHdr."Location Code" <>  CurrNode[2].AsXmlElement().InnerText then
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Despatch -> Shipto Location %1 does not Match PO Shipto Location %2'
                                                            , CurrNode[2].AsXmlElement().InnerText,'DC' + PurchHdr."Location Code");
                                ExcpMsg.modify;
                            end;
                        end;
                    end;
                    Itemtmp.reset;
                    If Itemtmp.findset Then Itemtmp.DeleteAll(false);
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Packages',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('Package',xmlNodeLst[1]);
                    For i := 1 to XMLNodeLst[1].Count do
                    begin
                        XmlNodeLst[1].Get(i,CurrNode[1]);
                        CuXML.FindNode(CurrNode[1],'LineItems',CurrNode[2]);
                        CurrNode[2].AsXmlElement().SelectNodes('LineItem',xmlNodeLst[2]);
                        For j := 1 to XMLNodeLst[2].Count do
                        begin
                            XmlNodeLst[2].Get(j,CurrNode[1]);
                            CuXML.FindNode(CurrNode[1],'BuyerPartNumber',CurrNode[2]);
                            If not Itemtmp.Get(CurrNode[2].AsXmlElement().InnerText) then
                            begin
                                Itemtmp.Init;
                                Itemtmp."No." := CurrNode[2].AsXmlElement().InnerText;
                                CuXML.FindNode(CurrNode[1],'LineNumber',CurrNode[2]);
                                Evaluate(Itemtmp."Price Unit Conversion",CurrNode[2].AsXmlElement().InnerText);
                                CuXML.FindNode(CurrNode[1],'ShipQtyUOM',CurrNode[2]);
                                Itemtmp."Base Unit of Measure" := CurrNode[2].AsXmlElement().InnerText;
                                //CuXML.FindNode(CurrNode[1],'VendorPartNumber',CurrNode[2]);
                                //Itemtmp."Vendor Item No." := CurrNode[2].AsXmlElement().InnerText;
                                Itemtmp.insert(false);       
                            end;
                            CuXML.FindNode(CurrNode[1],'ShipQty',CurrNode[2]);
                            Evaluate(Qty,CurrNode[2].AsXmlElement().InnerText);
                            ItemTmp."Unit Price" += qty;
                            Itemtmp.modify(false);
                        end;     
                    end;
                    Itemtmp2.reset;
                    If Itemtmp2.findset Then Itemtmp2.DeleteAll(false);
                    Itemtmp.Reset;
                    If ItemTmp.findset then i:= Itemtmp.count;
                    If i > 0 then
                    repeat
                        EDICnt += 1;
                        LineNo := Itemtmp."Price Unit Conversion";    
                        If Purchline.Get(PurchHdr."Document Type",PurchHdr."No.",LineNo) then
                        begin
                            // check that the Item matches the line Number
                            If PurchLine."No." = Itemtmp."No." then
                            begin
                                SKUList.Set( PurchLine."No.",True);
                                If Itemtmp2.get(PurchLine."No.") then 
                                Begin
                                    Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                    ExcpMsg."Exception Message" := strsubStno('EDI Despatch -> Item %1 Received Multiple Times Via EDI'
                                                                            ,Purchline."No.");                          
                                    ExcpMsg.modify;
                                end
                                else
                                begin
                                    ItemTmp2."No." := PurchLine."No.";
                                    Itemtmp2.insert(false);
                                    origQty[1] := PurchLine."Original Order Qty";
                                    origQty[2] := PurchLine."Original Order Qty(base)";
                                    Qty := Itemtmp."Unit Price";
                                    UOM := Itemtmp."Base Unit of Measure";
                                    For j:= 1 to 2 do
                                    begin
                                        Case j of
                                            1:
                                            begin
                                                Flg := Qty > PurchLine.Quantity + (PurchLine.Quantity * Tolerances[3]);
                                                mesg := 'EDI Qty ' + Format(qty) + ' > PO Qty ' + Format(PurchLine.Quantity 
                                                                                        + (PurchLine.Quantity * Tolerances[3])); 
                                            end;
                                            2:
                                            begin
                                                Flg := UOM <> PurchLine."Unit of Measure Code";
                                                mesg := 'EDI UOM ' + UOM + ' <> PO UOM ' + PurchLine."Unit of Measure Code";
                                            end;
                                        end;    
                                        if Flg then
                                        begin
                                            Qty := -1;
                                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                            ExcpMsg."Exception Message" := strsubStno('EDI Despatch -> ' + mesg 
                                                                            + ' for Item No %1 at Order Line No %2 is beyond acceptable limits for PO Line Values',
                                                                                Purchline."No.",LineNo);                          
                                            ExcpMsg.modify;
                                        end;
                                    end;
                                    If Qty > -1 then
                                    begin    
                                        If PurchLine.Quantity <> Qty then 
                                        begin
                                            PurchLineTemp.Copy(PurchLine);
                                            PurchLineTemp.Quantity := qty;
                                            PurchLineTemp."Original Order Qty" := origQty[1];
                                            PurchLinetemp."Original Order Qty(base)" := origQty[2];
                                            PurchLineTemp.Insert;      
                                            DspChg := true;
                                        end;
                                    end;
                                end;        
                            end
                            else
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Despatch -> Item %1 does not match PO Item No for Order Line No %2 ',
                                                                        Itemtmp."No.",LineNo);                          
                                ExcpMsg.modify(false);
                            end;
                        end    
                        else
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Despatch -> Failed to locate Order Line No %1 on PO',LineNo);
                            ExcpMsg.modify;
                        end;
                    until Itemtmp.next = 0;
                    /*
                    SKUKeys := SKUList.Keys;    
                    For j := 1 to SKUKeys.count do
                    begin
                        Skulist.Get(SkuKeys.Get(j),TstSku);
                        If Not TstSku then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Despatch -> Item %1 on PO not found in the despatch',
                                                                        SkuKeys.Get(j));
                            ExcpMsg.modify;
                        end;    
                    end;
                    */
                end; 
                EDIHdrBuff."Response Type"::Invoice:
                begin
                    PurchHdr."EDI Invoice Received" := True;
                    PurchHdr.modify(false);
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header/InvoiceNumber',CurrNode[2]);
                    PurchHdrTemp."Vendor Invoice No." := CurrNode[2].AsXmlElement().InnerText;
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('NameAddressParty',xmlNodeLst[1]);
                    For j := 1 to XMLNodeLst[1].Count do
                    begin
                        XmlNodeLst[1].Get(j,CurrNode[1]);
                        CuXML.FindNode(CurrNode[1],'PartyCodeQualifier',CurrNode[2]);
                        If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'SUPPLIER' then
                        begin
                            CuXML.FindNode(CurrNode[1],'PartyIdentifier',CurrNode[2]);
                            If PurchHdr."Buy-from Vendor No." <>  CurrNode[2].AsXmlElement().InnerText then
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> Supplier %1 does not Match PO Supplier %2'
                                                            , CurrNode[2].AsXmlElement().InnerText,PurchHdr."Buy-from Vendor No.");
                                ExcpMsg.modify;
                            end;
                        end;
                        If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'SHIPTO' then
                        begin
                            CuXML.FindNode(CurrNode[1],'PartyIdentifier',CurrNode[2]);
                            If 'DC' + PurchHdr."Location Code" <>  CurrNode[2].AsXmlElement().InnerText then
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> Shipto Location %1 does not Match PO Shipto Location %2'
                                                            , CurrNode[2].AsXmlElement().InnerText,'DC' + PurchHdr."Location Code");
                                ExcpMsg.modify;
                            end;
                        end;
                    end;
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header',CurrNode[2]);
                    if CurrNode[2].AsXmlElement().SelectNodes('PaymentTerms',xmlNodeLst[1]) then
                        For i:= 1 to xmlNodeLst[1].count do
                        begin
                            If i = 1 then 
                                PayTermMsg := StrSubstNo('Payment Terms Summary For Invoice Ref No %1',PurchHdr."Vendor Invoice No.") + CRLF;
                            XmlNodeLst[1].Get(i,CurrNode[1]);
                            CuXML.FindNode(CurrNode[1],'TermsDescription',CurrNode[2]);
                            PayTermMsg += 'Terms Desc -> ' + CurrNode[2].AsXmlElement().InnerText + CRLF;
                            CuXML.FindNode(CurrNode[1],'TermsDueDate',CurrNode[2]);
                            PayTermMsg += 'Terms DueDate -> ' + CurrNode[2].AsXmlElement().InnerText + CRLF;
                            CuXML.FindNode(CurrNode[1],'TermsDiscountPercentage',CurrNode[2]);
                            PayTermMsg += 'Terms Disc % -> ' + CurrNode[2].AsXmlElement().InnerText + CRLF;
                            CuXML.FindNode(CurrNode[1],'TermsDiscountAmount',CurrNode[2]);
                            PayTermMsg += 'Terms Disc Amt -> ' + CurrNode[2].AsXmlElement().InnerText + CRLF + CRLF;
                        end;
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('AllowancesOrCharges',xmlNodeLst[1]);
                    PurchLine.SetRange("No.",'FREIGHT');
                    Flg := Purchline.findset;
                    For j := 1 to xmlNodeLst[1].count do
                    begin
                        XmlNodeLst[1].Get(j,CurrNode[1]);
                        CuXML.Findnode(CurrNode[1],'AllowanceOrChargeAmount',CurrNode[2]);
                        Evaluate(Price,CurrNode[2].AsXmlElement().InnerText);
                        CuXML.Findnode(CurrNode[1],'AllowanceOrChargeIdentifier',CurrNode[2]);
                        if CurrNode[2].AsXmlElement().InnerText = 'FC' then
                        begin
                            PurchLine.SetRange("No.",'FREIGHT');
                            If Purchline.findset then
                            begin
                                If Price > PurchLine."Line Amount" then
                                begin
                                    Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                    ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> Freight Rate %1 exceeds PO Freight Rate %2'
                                                                    ,Round(Price,2), PurchLine."Line Amount");
                                    ExcpMsg.modify;
                                end
                                else If Price < PurchLine."Line Amount" then
                                begin
                                    PurchLineTemp.copy(PurchLine);
                                    PurchLineTemp."Direct Unit Cost" := Price;
                                    PurchLineTemp.insert;
                                    respChg := True;
                                end;
                                clear(flg);
                            end
                            Else
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> EDI Freight Charge %1 supplied for No Freight PO'
                                                                            ,Round(price,2));                          
                                ExcpMsg.modify;
                            end;
                        end;                   
                    end;
                    // see if freight removed
                    if flg then
                    begin
                        PurchLineTemp.copy(PurchLine);
                        PurchLineTemp."Direct Unit Cost" := 0;
                        PurchLineTemp.Quantity := 0;
                        PurchLineTemp.insert;
                    end;
                    CuXML.FindNode(CurrNode[1],XMLPath + 'LineItems',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('LineItem',xmlNodeLst[1]);
                    For i := 1 to XMLNodeLst[1].Count do
                    begin
                        EDICnt +=1;
                        XmlNodeLst[1].Get(i,CurrNode[1]);
                        CuXML.FindNode(CurrNode[1],'LineNumber',CurrNode[2]);
                        Evaluate(LineNo,CurrNode[2].AsXmlElement().InnerText);
                        If Purchline.Get(PurchHdr."Document Type",PurchHdr."No.",LineNo) then
                        begin
                            Clear(LineDisc);
                            Clear(LineDiscAmt);
                            CuXML.FindNode(CurrNode[1],'InvoiceQty',CurrNode[2]);
                            Evaluate(Qty,CurrNode[2].AsXmlElement().InnerText);
                            CuXML.FindNode(CurrNode[1],'InvoiceQtyUOM',CurrNode[2]);
                            UOM := CurrNode[2].AsXmlElement().InnerText.ToUpper();
                            CuXML.FindNode(CurrNode[1],'UnitPrice',CurrNode[2]);
                            Evaluate(Price,CurrNode[2].AsXmlElement().InnerText);
                            if CuXML.FindNode(CurrNode[1],'AllowancesOrCharges',CurrNode[2]) then
                            begin
                                CuXML.FindNode(CurrNode[2],'AllowanceOrChargeAmount',CurrNode[3]);
                                Evaluate(LineDiscAmt,CurrNode[3].AsXmlElement().InnerText); 
                                CuXML.FindNode(CurrNode[2],'AllowanceOrChargePercentage',CurrNode[3]);
                                Evaluate(LineDisc,CurrNode[3].AsXmlElement().InnerText);
                            end;
                            CuXML.FindNode(CurrNode[1],'BuyerPartNumber',CurrNode[2]);
                            // check that the Item matches the line Number
                            If PurchLine."No." = CurrNode[2].AsXmlElement().InnerText then
                            begin
                                SKUList.Set(PurchLine."No.",True);
                                If Itemtmp.get(PurchLine."No.") then 
                                Begin
                                    Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                    ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> Item %1 Received Multiple Times Via EDI'
                                                                            ,Purchline."No.");                          
                                    ExcpMsg.modify;
                                end
                                else
                                begin
                                    ItemTmp."No." := PurchLine."No.";
                                    Itemtmp.insert(false);
                                    For j:= 1 to 4 do
                                    begin
                                        Case j of
                                            1:
                                            begin
                                                Flg := Qty <> PurchLine.Quantity;
                                                mesg := 'EDI Qty ' + Format(qty) + ' <> PO Qty ' + Format(PurchLine.Quantity); 
                                            end;
                                            2:
                                            begin
                                                Flg := UOM <> PurchLine."Unit of Measure Code";
                                                mesg := 'EDI UOM ' + UOM + ' <> PO UOM ' + PurchLine."Unit of Measure Code";
                                            end;
                                            3:
                                            begin
                                                Flg := round(Price,2) > Round(PurchLine."Direct Unit Cost" + (PurchLine."Direct Unit Cost" * Tolerances[2]),2);
                                                Mesg := 'EDI Cost ' + Format(round(Price,2)) + ' > PO Cost ' + Format(Round(PurchLine."Direct Unit Cost" 
                                                                                                        + (PurchLine."Direct Unit Cost" * Tolerances[2]),2));         
                                            end;
                                            4:
                                            begin
                                                Flg := round(LineDisc,2) < round(PurchLine."Line Discount %",2);
                                                mesg := 'EDI Line Disc % ' + Format(LineDisc,2) + ' < PO Line Disc % ' + Format( round(PurchLine."Line Discount %",2));
                                            end;
                                        end;
                                        if Flg then
                                        begin
                                            Qty := -1;
                                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                            ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> ' + mesg 
                                                                            + ' for Item No %1 at Order Line No %2 is beyond acceptable limits for PO Line Values',
                                                                                Purchline."No.",LineNo);                          
                                            ExcpMsg.modify;
                                        end;
                                    end;
                                    If (Qty > -1) then
                                    begin
                                        PurchLineTemp.copy(PurchLine);
                                        PurchLineTemp."Direct Unit Cost" := Price;
                                        PurchLineTemp."Line Discount %" := LineDisc;
                                        PurchLineTemp.insert;
                                    end; 
                                end;       
                            end
                            else
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> Item %1 does not match PO Item No for Order Line No %2 ',
                                                                            CurrNode[2].AsXmlElement().InnerText,LineNo);                          
                                ExcpMsg.modify(false);
                            end;
                        end   
                        else
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Invoice -> Failed to locate Order Line No %1',LineNo);
                            ExcpMsg.modify;
                        end;
                    END;
                    SKUKeys := SKUList.Keys;    
                    For j := 1 to SKUKeys.count do
                    begin
                        Skulist.Get(SkuKeys.Get(j),TstSku);
                        If Not TstSku then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := StrSubstNo('EDI Invoice -> Item %1 on PO not found in the EDI invoice',
                                                                    SkuKeys.Get(j));
                            ExcpMsg.modify;
                        end;    
                    end;
                    CuXML.FindNode(CurrNode[1],XMLPath + 'Header',CurrNode[2]);
                    CurrNode[2].AsXmlElement().SelectNodes('AllowancesOrCharges',xmlNodeLst[1]);
                    Clear(Flg);
                    For j := 1 to xmlNodeLst[1].count do
                    begin
                        XmlNodeLst[1].Get(j,CurrNode[1]);
                        CuXML.Findnode(CurrNode[1],'AllowanceOrChargeAmount',CurrNode[2]);
                        Evaluate(Price,CurrNode[2].AsXmlElement().InnerText);
                        CuXML.Findnode(CurrNode[1],'AllowanceOrChargeIdentifier',CurrNode[2]);
                        If CurrNode[2].AsXmlElement().InnerText = 'ORDDISC' then
                        begin
                            Flg := True;
                            PurchLine.reset;
                            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                            PurchLine.setrange("Document No.",PurchHdr."No.");
                            Purchline.Setrange(Type,PurchLine.type::Item);
                            Purchline.Setfilter(Quantity,'>0');
                            If PurchLine.findset then
                            begin
                                PurchLine.CalcSums("Line Amount");
                                Price := Price/PurchLine."Line Amount" * 100;
                                If (Round(Price,2) < Round(PurchHdr."Invoice Disc %",2)) then
                                begin
                                    Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                    ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> Invoice Discount Percentage %1 < PO Invoice Discount Percentage %2'
                                                                        ,round(Price,2),PurchHdr."Invoice Disc %");
                                    ExcpMsg.modify;
                                end
                                else
                                    PurchHdrTemp."Invoice Disc %" := Round(Price,2);
                            end;                      
                        end 
                    end;
                    If (PurchHdr."Invoice Discount Value" > 0) and Not Flg then
                    begin
                        Init_Excpt_Msg(ExcpMsg,PurchHdr);
                        ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> Invoice Discount %1 not detected for PO'
                                                            ,PurchHdr."Invoice Discount Value");
                        ExcpMsg.modify;
                    end;
               end;
            END;
           /* if EDICnt <> OrdCnt AND then
            begin
                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                Case PurchHdr."Fulfilo ASN Status" of
                    //PurchHdr."Fulfilo ASN Status"::" ",PurchHdr."Fulfilo ASN Status"::"In Progress":
                    //    ExcpMsg."Exception Message" := StrsubStno('EDI Response -> Order Line count %1 does not match PO Line count %2.',i,OrdCnt);
                    PurchHdr."Fulfilo ASN Status"::Pending:
                        ExcpMsg."Exception Message" := StrsubStno('EDI Despatch -> Order Line count %1 does not match PO Line count %2.',i,OrdCnt);
                    PurchHdr."Fulfilo ASN Status"::Completed:
                        ExcpMsg."Exception Message" := StrsubStno('EDI Invoice -> Order Line count %1 does not match PO Line count %2.',i,OrdCnt);
                end;
                ExcpMsg.modify;
            end;
            */
            // see if any exception Occurred now 
            ExcpMsg.reset;
            ExcpMsg.Setrange("Purchase Order No.",PurchHdr."No.");
            If not ExcpMsg.findset then
            begin
                PurchHdr."Requested Receipt Date" := PurchHdrTemp."Requested Receipt Date";
                PurchHdr."Invoice Disc %" := PurchHdrTemp."Invoice Disc %";
                PurchHdr."Vendor Invoice No." := PurchHdrTemp."Vendor Invoice No.";
                PurchHdr.Status := PurchHdr.Status::Open;
                PurchHdr.modify(false);
                PurchLineTemp.reset;
                If PurchLineTemp.findset then
                repeat
                    PurchLine.get(PurchLineTemp."Document Type",PurchLineTemp."Document No.",PurchLineTemp."Line No.");
                    Purchline.validate(Quantity,PurchLineTemp.Quantity);
                    PurchLine."Original Order Qty" := PurchLineTemp."Original Order Qty";
                    PurchLine."Original Order Qty(Base)" := PurchLinetemp."Original Order Qty(base)";
                    PurchLine.validate("Line Discount %",PurchLineTemp."Line Discount %");
                    PurchLine.validate("Direct Unit Cost",PurchLineTemp."Direct Unit Cost");
                    Purchline.Modify;
                until PurchLineTemp.next = 0;
                //Here we zero any line on the PO that is not in the response or the Despatch info now as requested by PC
                If EDIHdrBuff."Response Type" in [EDIHdrBuff."Response Type"::Response,EDIHdrBuff."Response Type"::Dispatch] then
                begin
                    SKUKeys := SKUList.Keys;    
                    For j := 1 to SKUKeys.count do
                    begin
                        Skulist.Get(SkuKeys.Get(j),TstSku);
                        If Not TstSku then
                        begin
                            PurchLine.Reset;
                            Purchline.Setrange("Document Type",PurchHdr."Document Type");
                            PurchLine.Setrange("Document No.",PurchHdr."No.");
                            Purchline.Setrange(Type,PurchLine.type::Item);
                            PurchLine.Setrange("No.",SkuKeys.Get(j));
                            If PurchLine.findset then
                            begin
                                PurchLineTemp."Original Order Qty" := PurchLine."Original Order Qty";
                                PurchLineTemp."Original Order Qty(Base)" := PurchLine."Original Order Qty(base)";
                                Purchline.validate(Quantity,0);
                                PurchLine."Original Order Qty" := PurchLineTemp."Original Order Qty";
                                PurchLine."Original Order Qty(Base)" := PurchLinetemp."Original Order Qty(base)";
                                Purchline.Modify();
                            end;    
                        end;
                    end;
                end;        
                Case EDIHdrBuff."Response Type" of
                    EDIHdrBuff."Response Type"::Response:
                    begin
                        If PurchHdr."Invoice Disc %" > 0 then
                        begin
                            PurchLine.reset;
                            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                            PurchLine.setrange("Document No.",PurchHdr."No.");
                            Purchline.Setrange(Type,PurchLine.type::Item);
                            Purchline.Setfilter(Quantity,'>0');
                            If PurchLine.findset then
                            begin
                                PurchLine.CalcSums("Line Amount");
                                Cupt.ApplyInvDiscBasedOnAmt(PurchLine."Line Amount" * PurchHdr."Invoice Disc %"/100,PurchHdr);
                            end;
                        end; 
                        PurchHdr.Status := PurchHdr.Status::Released;
                        PurchHdr.modify(false);
                        If PurchHdr."Fulfilo Order ID" = 0 then
                            If not CUF.Create_ASN(PurchHdr) then
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := 'EDI Response -> Failed to Create a valid ASN with Fulfilio.';
                                ExcpMsg.modify;
                            end;
                        Commit;
                        If Not ExcpMsg.FindSet() then
                           If FirstResp or respChg then
                           begin 
                                Build_EDI_Purchase_Order(PurchHdr,'REPLACE');
                                EDI_Execution_Transaction_Log(PurchHdr,1);
                           end;    
                    end;
                    EDIHdrBuff."Response Type"::Dispatch:
                    begin
                        PurchHdr.Status := PurchHdr.Status::Released;
                        PurchHdr.modify(false);
                        If DspChg then
                            If not CUF.Update_ASN(PurchHdr) then
                            begin
                                Init_Excpt_Msg(ExcpMsg,PurchHdr);
                                ExcpMsg."Exception Message" := 'EDI Despatch -> Failed to Update ASN with Fulfilio.';
                                ExcpMsg.modify;
                            end
                    end;
                    EDIHdrBuff."Response Type"::Invoice:
                    begin
                        If PurchHdr."Invoice Disc %" > 0 then
                        begin
                            PurchLine.reset;
                            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                            PurchLine.setrange("Document No.",PurchHdr."No.");
                            Purchline.Setrange(Type,PurchLine.type::Item);
                            Purchline.Setfilter(Quantity,'>0');
                            If PurchLine.findset then
                            begin
                                PurchLine.CalcSums("Line Amount");
                                Cupt.ApplyInvDiscBasedOnAmt(PurchLine."Line Amount" * PurchHdr."Invoice Disc %"/100,PurchHdr);
                            end;
                        end;
                        CuXML.FindNode(CurrNode[2],XMLPath + 'Summary',CurrNode[1]);
                        CuXml.Findnode(CurrNode[1],'InvoiceAmountIncGST',CurrNode[2]);
                        Evaluate(Price,CurrNode[2].AsXmlElement().InnerText);
                        PurchHdr.CalcFields("Amount Including VAT");
                        If round(Price,2) > round(PurchHdr."Amount Including VAT" + (PurchHdr."Amount Including VAT" * Tolerances[1]),2) then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := strsubStno('EDI Invoice -> Total Value %1 exceeds PO Total value %2 tolerance.',
                                                                    round(price,2),PurchHdr."Amount Including VAT" + (PurchHdr."Amount Including VAT" * Tolerances[1]));
                            ExcpMsg.modify;
                        end;
                        Clear(PstDate);
                        GLSetup.get;
                        If (GLsetup."Allow Posting To" <> 0D) AND (GLsetup."Allow Posting To" < Today) then
                        begin
                            PstDate := GLSetup."Allow Posting To";
                            Clear(GLSetup."Allow Posting To");
                            GLSetup.Modify(false);
                        end;
                       // need to delete any line that has zero qty so we can post
                        PurchLine.reset;
                        PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                        PurchLine.setrange("Document No.",PurchHdr."No.");
                        Purchline.Setrange(Type,PurchLine.type::Item);
                        PurchLine.Setrange(Quantity,0);
                        If PurchLine.findset Then PurchLine.DeleteAll();
                        PurchHdr.Invoice := true;
                        PurchHdr.Receive := true;
                        PurchHdr.Status := PurchHdr.Status::Released;
                        PurchHdr.Validate("Posting Date",Today);
                        if PayTerms.get(PurchHdr."Payment Terms Code") then
                            PurchHdr.validate("Due Date",Calcdate(Format(Payterms."Due Date Calculation"),Today));
                        PurchHdr.Modify(False);    
                        Commit;
                        If not CUP.run(PurchHdr) then
                        begin
                            Init_Excpt_Msg(ExcpMsg,PurchHdr);
                            ExcpMsg."Exception Message" := 'EDI Invoice -> Failed to Post PO';
                            ExcpMsg.modify;
                        end;
                        If PstDate <> 0D then
                        begin
                            GLSetup."Allow Posting To" := PstDate;
                            GLSetup.Modify(false);
                        end;
                        If PayTermMsg <> '' then Cus.Send_Email_Msg('EDI Invoice Payment Terms Advice',PayTermMsg,False,'');
                    end;
                end;
            end;
            If ExcpMsg.findset then
            begin
                Cus.Send_Email_Msg('EDI Exceptions Exist For PO No ' + PurchHdr."No.",'',False,'');        
                if not Excp.Get(PurchHdr."No.") then
                begin
                    Excp.init; 
                    Excp."Purchase Order No." := PurchHdr."No.";
                    Excp."Exception Date" := Today;
                    Excp.Insert;
                end;
            end;
            EDIHdrBuff.Processed := True;
            EDIHdrBuff.Modify(false);
        end;
        If PurchHdr.Status <> PurchHdr.Status::Released then
        begin
            PurchHdr.Status := PurchHdr.Status::Released;
            PurchHdr.Modify(False);
        end;  
    end;
    local Procedure Process_EDI_Credits()
    var
        XmlDoc:XmlDocument;
        CurrNode:Array[2] of XmlNode;
        xmlNodeLst:XmlNodeList;
        CuXML:Codeunit "XML DOM Management";
        EDIHdrBuff:record "PC EDI Header Buffer";
        Instrm:InStream;
        BuffData:text;
        PurchLine:Record "Purchase Line";
        XmlPath:text;
        LineNo:Integer;
        i:integer;
        CUP:Codeunit "Purch.-Post";
        PstPurch:Record "Purch. Inv. Header";
        PurchHdr:record "Purchase Header";
        item:record Item;
        CUS:Codeunit "PC Shopify Routines";
    begin
        EDIHdrBuff.Reset;
        EDIHdrBuff.Setrange(Processed,false);
        EDIHdrBuff.Setrange("Response Type",EDIHdrBuff."Response Type"::CreditNote);
        XmlPath := '//Invoice/';
        if EDIhdrbuff.findset then
        repeat
            EDIhdrbuff.Data.CreateInStream(Instrm);
            EDIhdrbuff.CalcFields(Data);
            Instrm.Read(BuffData);
            XmlDocument.ReadFrom(BuffData,xmldoc);
            CurrNode[1] := XmlDoc.AsXmlNode();
            CuXML.findnode(CurrNode[1],XmlPath + 'Header/PurchaseOrderNumber',CurrNode[2]);
            //see if the posted purchase invoice exist 
            PstPurch.reset;
            PstPurch.Setrange("Order No.",CurrNode[2].AsXmlElement().InnerText);
            If PstPurch.findset then
            begin
                Clear(LineNo);
                PurchHdr.init;
                PurchHdr.Validate("Document Type",PurchHdr."Document Type"::"Credit Memo");
                PurchHdr.Validate("Buy-from Vendor No.",EDIHdrBuff."Supplier No.");
                PurchHdr.insert(true);
                CuXML.FindNode(CurrNode[1],XMLPath + 'Header',CurrNode[2]);
                CurrNode[2].AsXmlElement().SelectNodes('NameAddressParty',xmlNodeLst);
                For i := 1 to XMLNodeLst.Count do
                begin
                    XmlNodeLst.Get(i,CurrNode[1]);
                    CuXML.FindNode(CurrNode[1],'PartyCodeQualifier',CurrNode[2]);
                    If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'SHIPTO' then
                    begin
                        CuXML.FindNode(CurrNode[1],'PartyIdentifier',CurrNode[2]);
                        PurchHdr.Validate("Location Code",CurrNode[2].AsXmlElement().InnerText.Replace('DC',''));
                    end;
                end;    
                CuXML.findnode(CurrNode[1],XmlPath + 'Header/OriginalInvoiceNumber',CurrNode[2]);
                PurchHdr."Vendor Cr. Memo No." := CurrNode[2].AsXmlElement().InnerText;
                PurchHdr.Modify(true);
                CuXML.findnode(CurrNode[1],XmlPath + 'LineItems',CurrNode[2]);
                CurrNode[2].SelectNodes('LineItem',xmlNodeLst);
                For i:= 1 to xmlNodeLst.count do
                begin
                    xmlNodeLst.get(i,CurrNode[1]);
                    If CuXML.findnode(CurrNode[1],'BuyerPartNumber',CurrNode[2]) then
                        If Item.Get(CurrNode[2].AsXmlElement().InnerText) then
                        begin
                            LineNo += 10000;
                            PurchLine.init;
                            PurchLine.validate("Document Type",PurchHdr."Document Type");
                            PurchLine.validate("Document No.",PurchHdr."No.");
                            PurchLine.validate("Line No.",LineNo);
                            PurchLine.Insert(True);
                            PurchLine.validate(Type,PurchLine.Type::Item);
                            PurchLine.Validate("No.",Item."No.");
                            CuXML.findnode(CurrNode[1],'InvoiceQtyUOM',CurrNode[2]);
                            PurchLine.validate("Unit of Measure Code",CurrNode[2].AsXmlElement().InnerText);
                            CuXML.findnode(CurrNode[1],'InvoiceQty',CurrNode[2]);
                            Evaluate(PurchLine.Quantity,CurrNode[2].AsXmlElement().InnerText);
                            PurchLine.Validate(Quantity,PurchLine.Quantity);
                            CuXML.findnode(CurrNode[1],'UnitPrice',CurrNode[2]);
                            Evaluate(PurchLine."Direct Unit Cost",CurrNode[2].AsXmlElement().InnerText);
                            PurchLine.validate("Direct Unit Cost",PurchLine."Direct Unit Cost");
                            CuXML.findnode(CurrNode[1],'TaxRate',CurrNode[2]);
                            Evaluate(PurchLine."VAT %",CurrNode[2].AsXmlElement().InnerText);
                            PurchLine.Validate("VAT %",PurchLine."VAT %");
                            if CuXML.Findnode(CurrNode[1],'AllowancesOrCharges',CurrNode[2]) then
                            begin
                                CuXML.Findnode(CurrNode[2],'AllowancesOrCharge',CurrNode[1]);
                                If CurrNode[1].AsXmlElement().InnerText = 'ALLOWANCE' then
                                begin
                                    CuXML.Findnode(CurrNode[1],'AllowanceOrChargePercentage',CurrNode[2]);
                                    Evaluate(PurchLine."Line Discount %",CurrNode[2].AsXmlElement().InnerText);
                                    PurchLine.validate("Line Discount %",PurchLine."Line Discount %");
                                end;
                            end;
                            PurchLine.modify(true);
                        end;                                  
                end;
                CUS.Send_Email_Msg('Purchase Credit Note ' +  PurchHdr."No." + 'has been created via EDI','',False,'');        
                EDIHdrBuff.Processed := True;
                EDIHdrBuff.Modify(false);
            end;    
       Until EDIHdrBuff.next = 0; 
    end;
    local procedure Check_PurchaseDoc(Var PurchHdr:Record "Purchase Header")
    var
        PurchLine:array[2] of record "Purchase Line";
        Loc:Record Location;    
    begin
        if PurchHdr."Order Type" = PurchHdr."Order Type"::Fulfilo then
        begin      
            If (PurchHdr."Requested Receipt Date" = 0D) Or (PurchHdr."Requested Receipt Time" = 0T) then
                Error('Both Requested Receipt Date and or Requested Receipt Time must be defined');
            if Not Loc.get(PurchHdr."Location Code") then
                Error('Location code is not defined');
            If Loc."Fulfilo Warehouse ID" = 0 then
                error('Fulfilio Warehouse ID is invalid correct and retry');
            PurchLine[1].reset;
            PurchLine[1].SetCurrentKey("Line No.");
            PurchLine[1].Setrange("Document Type",PurchHdr."Document Type");
            PurchLine[1].Setrange("Document No.",PurchHdr."No.");
            PurchLine[1].Setrange(Type,PurchLine[1].Type::Item);
            repeat
                Purchline[2].CopyFilters(Purchline[1]);
                Purchline[2].Setrange("No.",Purchline[1]."No.");
                If Purchline[2].Count > 1 then
                    Error('%1 is repeated on PO\Only Unique SKU No. are allowed',Purchline[1]."No.");
            until PurchLine[1].next = 0;
        end;
    end;
   [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendPurchaseDocForApproval', '', true, true)]
    local procedure "Approvals Mgmt._OnSendPurchaseDocForApproval"(var PurchaseHeader: Record "Purchase Header")
    begin
        Check_PurchaseDoc(PurchaseHeader);    
    end;
 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnBeforeManualReleasePurchaseDoc', '', true, true)]
    local procedure "Release Purchase Document_OnBeforeManualReleasePurchaseDoc"
    (
        var 
            PurchaseHeader: Record "Purchase Header";
		    PreviewMode: Boolean
    )
    begin
        Check_PurchaseDoc(PurchaseHeader);    
    end;
}