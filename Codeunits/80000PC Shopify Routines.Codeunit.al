codeunit 80000 "PC Shopify Routines"
{
    var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
        WsError:text;
        ShopifyBase:Label '/admin/api/2022-07/';
    
    trigger OnRun()
    Var
        Log:record "PC Execution Log";
        i:Integer;
        Setup:Record "Sales & Receivables Setup";
    begin
        Setup.Get;
        Log.LockTable(True);
        For i:= 1 to 4 do
        begin    
            Log.init;
            Clear(Log.ID);
            log.insert;
            Commit;
            Log."Execution Start Time" := CurrentDateTime;
            case i of
                1:
                begin
                    Log."Operation" := 'Synchronise Shopify Items';
                    ClearLastError();
                    If Process_Items('',False) then
                        Log.Status := Log.Status::Pass
                    else
                    Begin
                        log."Error Message" := CopyStr(GetLastErrorText,1,250);
                        Send_Email_Msg('Synchronise Shopify Items Error',log."Error Message",Setup."Exception Email Address");
                        Send_Email_Msg('Synchronise Shopify Items Error',log."Error Message",'vpacker@practiva.com.au');
                        Send_Email_Msg('Synchronise Shopify Items Error',log."Error Message",'christopher.cheung@petculture.com.au');
                        Send_Email_Msg('Synchronise Shopify Items Error',log."Error Message",'jessie.sun@petculture.com.au');
                    end;    
                end;
                2:
                begin
                    Log."Operation" := 'Out Of Stock Shopify Items';
                    ClearLastError();
                    If Process_Out_Of_Stock_Shopify_Items() then
                        Log.Status := Log.Status::Pass
                    else
                    Begin
                        log."Error Message" := CopyStr(GetLastErrorText,1,250);
                        Send_Email_Msg('Out Of Stock Items Error',log."Error Message",Setup."Exception Email Address");
                        Send_Email_Msg('Out Of Stock Items Error',log."Error Message",'vpacker@practiva.com.au');
                        Send_Email_Msg('Out Of Stock Items Error',log."Error Message",'christopher.cheung@petculture.com.au');
                        Send_Email_Msg('Out Of Stock Items Error',log."Error Message",'jessie.sun@petculture.com.au');
                    end;    
                end;
                3:
                begin
                    Log."Operation" := 'Retrieve Shopify Orders';
                    ClearLastError();
                    if Get_Shopify_Orders(0,0) then
                        Log.Status := Log.Status::Pass
                    else
                    Begin
                        log."Error Message" := CopyStr(GetLastErrorText,1,250);
                        Send_Email_Msg('Retrieve Shopify Orders Error',log."Error Message",Setup."Exception Email Address");
                        Send_Email_Msg('Retrieve Shopify Orders Error',log."Error Message",'vpacker@practiva.com.au');
                        Send_Email_Msg('Retrieve Shopify Orders Error',log."Error Message",'christopher.cheung@petculture.com.au');
                        Send_Email_Msg('Retrieve Shopify Orders Error',log."Error Message",'jessie.sun@petculture.com.au');
                    end;    
                end;
                4:
                begin
                    Log."Operation" := 'Process Shopify Orders';
                    ClearLastError();
                    If Process_Orders(false,0) then 
                        Log.Status := Log.Status::Pass
                    else
                    Begin
                        log."Error Message" := CopyStr(GetLastErrorText,1,250);
                        Send_Email_Msg('Process Shopify Orders Error',log."Error Message",Setup."Exception Email Address");
                        Send_Email_Msg('Process Shopify Orders Error',log."Error Message",'vpacker@practiva.com.au');
                        Send_Email_Msg('Process Shopify Orders Error',log."Error Message",'christopher.cheung@petculture.com.au');
                        Send_Email_Msg('Process Shopify Orders Error',log."Error Message",'jessie.sun@petculture.com.au');
                    end;    
                end;
            end;
            Log."Execution Time" := CurrentDateTime;
            log.Modify();
            Commit;
        end;
        House_Keeping();   
    end;
    // General Routine to provide the Rest Api Calls
    // Arguments Passed via the support RESTAPI Table,distcionary of the HTTP parms list,payload Data
    procedure CallRESTWebService(var RestRec : Record "PC RESTWebServiceArguments";Parms:Dictionary of [text,text];Data:text) : Boolean
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
        if RestRec."Access Token" <> '' then
        begin
            If RestRec."Token Type" =  RestRec."Token Type"::Shopify then
                Headers.Add('Authorization', 'Basic ' + RestRec."Access Token")
            else
                Headers.Add('Authorization', 'Bearer ' + RestRec."Access Token");
        end;
        if RestRec.Accept <> '' then Headers.Add('Accept', RestRec."Accept");
        If Restrec.RestMethod  in [RestRec.RestMethod::POST
                                  ,RestRec.RestMethod::PUT,RestRec.RestMethod::PATCH] then
        begin
            // get the payload data now
            Content.WriteFrom(Data);
            if Not Content.GetHeaders(Headers) Then Exit(false);
            Headers.Clear();
            Headers.Add('Content-Type','application/json');
            Headers.Add('Content-Length',Format(StrLen(Data)));
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
    // routine to handle All Shopify API Calls
    procedure Shopify_Data(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:jsonobject): boolean
    var
       Setup:Record "Sales & Receivables Setup";
       Ws:Record "PC RestWebServiceArguments";
       Cu:Codeunit "Base64 Convert";
    begin
        Setup.get;
        Clear(WsError);
        Ws.LockTable(True);
        Ws.init;
        If Setup."Use Shopify Dev Access" then
        Begin 
            Ws.URL := Setup."Dev Shopify Connnect Url";
            ws."Access Token" := cu.ToBase64(Setup."Dev Shopify API Key" + ':' + Setup."Dev Shopify Password");
        End
        else
        begin
            Ws.URL := Setup."Shopify Connnect Url";
            ws."Access Token" := cu.ToBase64(Setup."Shopify API Key" + ':' + Setup."Shopify Password");
         end;
        Ws.Url += Request;
        ws."Token Type" := ws."Token Type"::Shopify;
        Ws.RestMethod := Method;
        if CallRESTWebService(ws,Parms,Payload) then
           exit(Data.ReadFrom(ws.GetResponseContentAsText()))
        else
        begin
            WsError := ws.GetResponseContentAsText(); 
            exit(false);
        end;
    end; 
    //Routine to handle all Fulfilo API Calls
    local procedure House_Keeping()
    var
        Logs:record "Job Queue Log Entry";
        Log:record "PC Execution Log";        
    begin
        if logs.RecordLevelLocking then
        begin
            Logs.Reset;
            Logs.Setrange("Object Type to Run",Logs."Object Type to Run"::Codeunit);
            Logs.setrange("Object ID to Run",Codeunit::"PC Shopify Routines");
            Logs.Setrange(Status,Logs.Status::Success);
            Logs.Setfilter("End Date/Time",'<%1',CreateDateTime(Calcdate('-5D',Today),0T));
            If Logs.Findset then Logs.DeleteAll(false);
            Logs.setrange("Object ID to Run",Codeunit::"PC EDI Routines");
            If Logs.Findset then Logs.DeleteAll(false);
            Logs.setrange("Object ID to Run",Codeunit::"PC Watchdog");
            If Logs.Findset then Logs.DeleteAll(false);
        end;
        Log.reset;
        log.Setrange(Operation,'');
        If log.FindSet() then
            log.DeleteAll(false);
    end;

    local procedure Update_Error_Log(Err:text)
    var
        Log:record "PC Shopify Update Log";
    begin
        Log.init;
        Clear(log.ID);
        Log.insert;
        Log."Error Date/Time" := CurrentDateTime();
        Log."Error Condition" := Err;
        Log."Web Service Error" := Copystr(WsError,1,2048);
        Log.Modify;
    end;
    local Procedure Check_For_Price_Change()
    var
        Sprice:array[2] of record "PC Shopfiy Pricing";
        ChMsg:text;
        TstDate:date;
        Setup:record "Sales & Receivables Setup";
    begin
        Setup.Get;
        Clear(ChMsg);    
        Sprice[1].Reset;
        Sprice[1].Setrange("Ending Date",CalcDate('1D',Today));
        If Sprice[1].findset then
        repeat
            Sprice[2].Reset;
            Sprice[2].Setrange("Item No.",Sprice[1]."Item No.");
            Sprice[2].Setrange("Starting Date",Sprice[1]."Ending Date");        
            If Sprice[2].Findset then CHMsg += Check_Change(Sprice[1],Sprice[2]); 
        Until Sprice[1].next = 0;
        If Strlen(ChMsg) > 0 then Send_Email_Msg('Price Change Alerts',ChMsg,Setup."Exception Email Address");
    end;
    local procedure Check_Change(Sp1:record"PC Shopfiy Pricing";SP2:record "PC Shopfiy Pricing"):text
    var
        Msg:text; 
        Flg:Boolean;
        CRLF:Text[2];
    Begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        Clear(Flg);
        Msg := SP1."Item No." +  ' ';
        if  Sp1."New RRP Price" <> Sp2."New RRP Price" then
        begin
            Msg += StrsubStno('Current RRP = %1,New RRP = %2,',SP1."New RRP Price",SP2."New RRP Price");
            Flg := True;
        end;    
        if  Sp1."Sell Price" <> Sp2."Sell Price" then
        begin
            Msg += StrsubStno('Current SellPrice = %1,New SellPrice = %2,',SP1."Sell Price",SP2."Sell Price");
            Flg := True;
        end;    
        if  Sp1."Platinum Member Disc %" <> Sp2."Platinum Member Disc %" then
        begin
            Msg += StrsubStno('Current Platinum Member Discount = %1,New Platinum Member Discount = %2,',SP1."Platinum Member Disc %",SP2."Platinum Member Disc %");
            Flg := True;
        end;    
        if  Sp1."Gold Member Disc %" <> Sp2."Gold Member Disc %" then
        begin
            Msg += StrsubStno('Current Gold Member Discount = %1,New Gold Member Discount = %2,',SP1."Gold Member Disc %",SP2."Gold Member Disc %");
            Flg := True;
        end;    
        if  Sp1."Silver Member Disc %" <> Sp2."Silver Member Disc %" then
        begin
            Msg += StrsubStno('Current Silver Member Discount = %1,New Silver Member Discount = %2,',SP1."Silver Member Disc %",SP2."Silver Member Disc %");
            Flg := True;
        end;    
        if  Sp1."Auto Order Disc %" <> Sp2."Auto Order Disc %" then
        begin
            Msg += StrsubStno('Current Auto Order Discount = %1,New Auto Order Discount = %2,',SP1."Auto Order Disc %",SP2."Auto Order Disc %");
            Flg := True;
        end;    
        if  Sp1."VIP Disc %" <> Sp2."VIP Disc %" then
        begin
            Msg += StrsubStno('Current VIP Discount = %1,New VIP Discount = %2,',SP1."VIP Disc %",SP2."VIP Disc %");
            Flg := True;
        end;    
        If Flg then
            Exit(Msg.Remove(Msg.LastIndexOf(','),1) + ' As @ ' + Format(Sp2."Starting Date") + CRLF)
        else
            exit('');        
    End;
    local Procedure Refresh_Product_Pricing(ItemNo:code[20])
    var
        Item:record Item;
        Rel:record "PC Shopify Item Relations";
        Filt:text;
        Wind:Dialog;
        RRP:Decimal;
        Price:Decimal;
    Begin
        if GuiAllowed then Wind.Open('Refreshing Product Sell Prices #1#############');
         // See if email alerts required for a price change or not
        Check_For_Price_Change();
        Clear(Filt);
        if ItemNo <> '' then
        begin
            Rel.Reset;
            Rel.Setrange("Parent Item No.",ItemNo);
            If Rel.findset then
            repeat
                Filt += Rel."Child Item No." + '|';
            until Rel.next = 0
            else
                exit;    
        end;
        Item.LockTable(true);
        Item.Reset;
        Item.Setrange(Type,Item.Type::Inventory);
        If Filt <> '' then
            Item.Setfilter("No.",Filt.Remove(Filt.LastIndexOf('|'),1));
        If Item.Findset then
        repeat
            If guiallowed then wind.Update(1,Item."No.");
            Price := Item.Get_Price(RRP);
  //          If (Price <= 0) AND (Item."Is In Shopify Flag") AND (Item."Shopify Product Variant ID" > 0) then
  //              Error('SKU %1 has price set @ %2',Item."No.",Price)
  //          else    
            Item.Validate("Current Price",Price);
            If (RRP > 0) And (RRP <> Item."Unit Price") then
                Item."Unit Price" := RRP;
            Item.Validate("Current RRP",Item."Unit Price");
            Item.validate("Current PDisc",Item.Get_Shopify_Disc(0));
            Item.validate("Current GDisc",Item.Get_Shopify_Disc(1));
            Item.validate("Current SDisc",Item.Get_Shopify_Disc(2));
            Item.validate("Current VDisc",Item.Get_Shopify_Disc(3));
            Item.validate("Current ADisc",Item.Get_Shopify_Disc(4));
            Item.validate("Current PlatADisc",Item.Get_Shopify_Disc(5));
            Item.validate("Current GoldADisc",Item.Get_Shopify_Disc(6));
            Item.Validate("Current Width",Item.Get_Product_Size(0));
            Item.Validate("Current Length",Item.Get_Product_Size(1));
            Item.Validate("Current Height",Item.Get_Product_Size(2));
            Item.Modify(False);
        until Item.next = 0;    
        Commit;
        if GuiAllowed then Wind.Close;
    End;
    local procedure Build_Product_Handle(Handle:text):Text
    Var
        HTemp:Text;
        Item:Record Item;
        i:Integer;
        Reqd:Boolean;
    Begin
        HTemp := Handle.ToLower().Replace(' ','-');
        Htemp := HTemp.Replace('+','-');
        Htemp := HTemp.Replace('&','-');
        Htemp := HTemp.Replace('#','-');
        Htemp := HTemp.Replace('%','-');
        If HTemp.endswith('-')  then
            HTemp := CopyStr(Htemp,1,StrLen(HTemp) - 1); 
        Reqd := True;
        Clear(i);
        While Reqd do
        begin
            i+=1;
            Item.reset;
            Item.Setrange("Shopify Product Handle",Htemp);
            Reqd := Item.Findset;
            If Reqd then HTemp += '-' + Format(i);  
        end;
        Exit(HTemp);    
    end;
    local procedure Build_Shopify_Parents(ItemFilt:Code[20])
    var
        Item:Record Item;
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:jsonArray;
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        wind:Dialog;
        Rel:record "PC Shopify Item Relations";
        i:Integer;
        Flg:Boolean;
        ItTxt:text;
        Log:record "PC Shopify Update Log";
        Handle:text;
    begin
        Item.reset;
        If Itemfilt <> '' then
            Item.Setrange("No.",ItemFilt);
        Item.Setrange("Shopify Update Flag",True);
        Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
        If Item.FindSet() then
        repeat
            Rel.Reset();
            Rel.Setrange("Parent Item No.",Item."No.");
            If Rel.FindSet() then 
                rel.Modifyall("Update Required",true,false);
            Clear(Item."Shopify Update Flag");
            Item.Modify(False);
        until Item.Next = 0;
        Commit;
        // start by doing any brand new items
        If GuiAllowed then Wind.Open('Creating Shopify Item #1################');
        Clear(JsObj);
        Clear(Jsobj1);
        Clear(Parms);
        Item.reset;
        If Itemfilt <> '' then
            Item.Setrange("No.",ItemFilt);
        Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
        // ensure they have a title always
        Item.Setfilter("Shopify Title",'<>%1','');
        Item.SetRange("Shopify Product ID",0); 
        If Item.findset then
        repeat
            Clear(Jsobj);
            Clear(Jsobj1);
            // ensure it's not a child item
            Flg := True; 
            Rel.Reset();
            Rel.Setrange("Child Item No.",Item."No.");
            If Not Rel.findset then
            begin
                ItTxt :=  Item."No.";
                // see if this is a parent but has no item relations defined
                If ItTxt.StartsWith('PAR-') then
                begin
                    Rel.reset;
                    Rel.Setrange("Parent Item No.",Item."No.");
                    Flg := Rel.findset;
                end;
                If Flg then
                begin    
                    // see if this is a parent without any children
                    Rel.reset;
                    Rel.Setrange("Parent Item No.",Item."No.");
                    If Rel.Findset then Flg := Rel.Count > 0;
                end; 
                If Flg then
                begin
                    If GuiAllowed then Wind.Update(1,Item."No."); 
                    JsObj.Add('title',Item."Shopify Title");
                    Handle := Build_Product_Handle(Item."Shopify Title");
                    JsObj.Add('handle',Handle);
                    JsObj.Add('status','draft');
                    Clear(Jsobj1);
                    JsObj1.Add('product',JsObj);
                    JsObj1.WriteTo(PayLoad);
                    Sleep(300);
                    If Shopify_Data(Paction::POST,ShopifyBase + 'products.json',Parms,Payload,Data) then
                    Begin
                        Data.Get('product',JsToken[1]);
                        JsToken[1].AsObject().SelectToken('variants',JsToken[2]);
                        JsArry := jstoken[2].AsArray(); 
                        JsArry.Get(0,JsToken[1]);       
                        Jstoken[1].SelectToken('product_id',JsToken[2]);
                        Item.validate("Shopify Product ID",JsToken[2].AsValue().AsBigInteger());
                        Jstoken[1].SelectToken('id',JsToken[2]);
                        Item.validate("Shopify Product Variant ID",jsToken[2].AsValue().AsBigInteger());
                        Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                        Item.validate("Shopify Product Inventory ID",JsToken[2].AsValue().AsBigInteger());
                        Item.validate("CRM Shopify Product ID",Item."Shopify Product ID");
                        Item."Shopify Product Handle" := Handle; 
                        Item."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                        Item."Shopify Publish Flag" := true;  // flag as a new Item 
                        Item."Is In Shopify Flag" := True;
                        Clear(Item."Is Child Flag");
                        Rel.reset;
                        Rel.Setrange("Parent Item No.",Item."No.");
                        If Rel.Findset then 
                        Begin
                            rel.Modifyall("Update Required",true,false);
                            Item."Purchasing Blocked" := true;
                        end;    
                        item.modify(false);
                    end
                    else
                        Update_Error_Log(StrSubstNo('Failed to create item %1 in Shopify',Item."No."));
                end;
            end;        
        until Item.next = 0;
        Commit;
        If GuiAllowed then wind.Close();
    end;
    Procedure Fix_Product_Handles()
    Var
        Item:Record Item;
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        JsArry:jsonArray;
        JsToken:array[2] of JsonToken;
        i:Integer;
        win:dialog;
    Begin
        Win.Open('Processing Item #1###########');
        Clear(parms);
        Parms.add('fields','handle');
        Item.reset;
        Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
        // ensure they have a title always
        Item.Setfilter("Shopify Title",'<>%1','');
        Item.SetFilter("Shopify Product ID",'>0');
        Item.SetRange("Is Child Flag",False);
        Item.Setrange("Shopify Product Handle",'');
        If Item.Findset then
        repeat
            sleep(100);
            If Shopify_Data(Paction::GET,ShopifyBase + 'products/' + Format(Item."Shopify Product ID") +'.json'
                            ,Parms,Payload,Data) then
            begin                 
                if Data.Get('product',JsToken[1]) then
                    If JsToken[1].SelectToken('handle',jstoken[2]) then
                    begin
                        Win.Update(1,Item."No.");
                        Item."Shopify Product Handle" := JsToken[2].AsValue().AsText();
                        Item.Modify(False);
                    end;
            end;
        until Item.next = 0;
        Win.Close;    
    end;    
    local procedure Get_Parent_Variant_Structure(var Item:Record Item;var SkuLst:List of [Text];var SkuIdLst:list of [BigInteger]):BigInteger
    Var 
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        JsArry:jsonArray;
        JsToken:array[2] of JsonToken;
        i:Integer;
        ProdID:BigInteger;
    Begin
        Clear(ProdID);
        Clear(SkuLst);
        Clear(SkuIdLst);
        Sleep(100);
        Parms.add('fields','variants');
        If Shopify_Data(Paction::GET,ShopifyBase + 'products/' + Format(Item."Shopify Product ID") +'.json'
                        ,Parms,Payload,Data) then
        begin                 
            if Data.Get('product',JsToken[1]) then
                If JsToken[1].SelectToken('variants',jstoken[2]) then
                begin
                    JsArry := JsToken[2].AsArray();
                    for i := 0 to JsArry.Count - 1 do
                    begin
                        JsArry.get(i,JsToken[1]);
                        jstoken[1].SelectToken('sku',JsToken[2]);
                        SkUlst.Add(JsToken[2].AsValue().AsCode());
                        jstoken[1].SelectToken('id',JsToken[2]);
                        SkuIDlst.Add(JsToken[2].AsValue().AsBigInteger());
                        jstoken[1].SelectToken('product_id',JsToken[2]);
                        ProdID := JsToken[2].AsValue().AsBigInteger();
                    end;
                end;    
        end;
        Sleep(100);
        If (ProdID = 0) and (Strlen(Item."Shopify Product Handle") > 0) then
        begin
            Parms.Add('handle',Item."shopify product handle");
            If Shopify_Data(Paction::GET,ShopifyBase + 'products.json'
                                ,Parms,Payload,Data) then 
            begin
                if Data.Get('products',JsToken[1]) then
                    If JsToken[1].AsArray().get(0,JsToken[2]) then
                        If JsToken[2].SelectToken('variants',jstoken[1]) then
                        begin
                            JsArry := JsToken[1].AsArray();
                            for i := 0 to JsArry.Count - 1 do
                            begin
                                JsArry.get(i,JsToken[1]);
                                jstoken[1].SelectToken('sku',JsToken[2]);
                                SkUlst.Add(JsToken[2].AsValue().AsCode());
                                jstoken[1].SelectToken('id',JsToken[2]);
                                SkuIDlst.Add(JsToken[2].AsValue().AsBigInteger());
                                jstoken[1].SelectToken('product_id',JsToken[2]);
                                ProdID := JsToken[2].AsValue().AsBigInteger();
                            end;
                        end;    
            end;
        end;    
        exit(ProdID);     
    End; 
    local procedure Check_Shopify_Child_Structure(ItemFilt:Code[20])
    var
        Item:Array[2] of Record Item;
        Rel:record "PC Shopify Item Relations";
        SkuLst:List of [Text];
        SkuIDlst:list of [BigInteger];
        ChildItem:text[20];
        i:integer;
        ErrFlg:Boolean;
        win:Dialog;
        ProdID:BigInteger;
        VarID:BigInteger;
    begin
        If GuiAllowed then Win.Open('Checking Parent/Child Structure #1############'
                                   + 'Logging Error Item #2#############');
        Item[1].LockTable(true);
        Item[1].reset;
        If Itemfilt <> '' then
            Item[1].Setrange("No.",ItemFilt);
        Item[1].Setrange("Shopify Item",Item[1]."Shopify Item"::Shopify);
        // ensure they have a title always
        Item[1].Setfilter("Shopify Title",'<>%1','');
        Item[1].SetFilter("Shopify Product ID",'>0');
        Item[1].SetRange("Is Child Flag",False); 
        If Item[1].Findset then
        repeat
            If GuiAllowed then Win.Update(1,Item[1]."No.");
            // Check its not a stand alone Parent
            Rel.Reset;
            Rel.SetCurrentKey("Child Position");
            Rel.Setrange("Parent Item No.",Item[1]."No.");
            Rel.Setrange("Un Publish Child",False);
            If Rel.Findset then
                If Rel.Count > 1 then
                Begin               // now get the linked child structure
                    Clear(ErrFlg);
                    Clear(i);   
                    ProdID := Get_Parent_Variant_Structure(Item[1],SkuLst,SkuIDlst);
                    If ProdID = 0 then 
                        ErrFlg := true
                    else    
                        repeat
                            i+=1;
                            If Skulst.Get(i,ChildItem) then
                            begin
                                if Rel."Child Item No." <> ChildItem then
                                    ErrFlg := True;
                            End 
                            else
                                ErrFlg := true;
                        until (Rel.next = 0) or Errflg;           
                    If ErrFlg then 
                    begin
                        If GuiAllowed then Win.Update(2,Item[1]."No.");
                        If ProdID = 0 then
                            Update_Error_Log(StrSubStno('Parent %1 Shopify Product ID %2 and or Handle cannot be found in Shopify'
                                                                ,Item[1]."No.",Item[1]."Shopify Product ID"))
                        else
                            Update_Error_log(Strsubstno('Parent %1 has missing variants and or variant positions are not correct',Item[1]."No."));
                        //Delete_Items(Item[1]."No.",True);
                        // make sure it remains published now
                        //Build_Shopify_Parents(Item[1]."No.",False);
                    end
                    Else
                    begin
                        Clear(i);   
                        If Rel.Findset then 
                        repeat
                            i+=1;
                            Skulst.Get(i,ChildItem);
                            SkuIDlst.Get(i,VarID);
                            Item[2].Get(ChildItem);
                            If Item[2]."Shopify Product Variant ID" <> VarID then
                            begin
                                Item[2].Validate("Shopify Product Variant ID",VarID);
                                Item[2].Modify(False);
                            end;
                            Clear(errflg);    
                            If i = 1 then
                            begin                       
                                If Item[1]."Shopify Product ID" <> ProdID then
                                Begin                  
                                    Item[1].Validate("Shopify Product ID",ProdID);
                                    Item[1].Modify(False);
                                end;    
                                If Item[1]."Shopify Product Variant ID" <> VarID then
                                Begin
                                    Item[1].Validate("Shopify Product Variant ID",VarID);
                                    Item[1].Modify(False);
                                end;    
                        end;
                        until rel.next = 0;            
                    end;
                    If GuiAllowed then Win.Update(2,'');
                end;
        until Item[1].next = 0;
        If GuiAllowed then win.close;    
    end;
    local procedure Build_Shopify_Children(ItemFilt:Code[20])
    var
        Item:array[2] of Record Item;
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:jsonArray;
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        wind:Dialog;
        Rel:record "PC Shopify Item Relations";
        i:Integer;
        price:Decimal;
        Flg:Boolean;
        Log:record "PC Shopify Update Log";
        ItemUnit:record "Item Unit of Measure";
        RRP:Decimal;
    begin
        If GuiAllowed then 
            Wind.open('Updating Shopify Item           #1#################\'
                     +'Creating/Updating Shopify Child #2#################');
        Item[1].LockTable(true);
        Item[1].Reset;
        If Itemfilt <> '' then
            Item[1].Setrange("No.",ItemFilt);
        Item[1].Setrange("Shopify Item",Item[1]."Shopify Item"::Shopify);
        Item[1].SetFilter("Shopify Product ID",'>0'); 
        If Item[1].findset then
        repeat
            If GuiAllowed then Wind.Update(1,Item[1]."No.");
             // make sure it's not Parent item now 
            Rel.Reset;
            Rel.SetCurrentKey("Child Position");
            Rel.Setrange("Parent Item No.",Item[1]."No.");
            if not Rel.findset then
            begin 
                If GuiAllowed then Wind.Update(2,Item[1]."No.");
                Clear(Jsobj);
                Clear(Jsobj1);
                JsObj.Add('id',Item[1]."Shopify Product Variant ID");
                JsObj.Add('sku',Item[1]."No.");
                JsObj.Add('option1',Item[1]."Shopify Body Html");
                price := Item[1].Get_Price(RRP);
                If (RRP > 0) AND (RRP <> Item[1]."Unit Price") then
                    Item[1]."Unit Price" := RRP;
                JsObj.Add('price',Format(price,0,'<Precision,2><Standard Format,1>'));
                if Price < Item[1]."Unit Price" then
                    JsObj.Add('compare_at_price',Format(Item[1]."Unit Price",0,'<Precision,2><Standard Format,1>'))
                else
                    JsObj.Add('compare_at_price','');
                JsObj.Add('inventory_management','shopify');
                JsObj.Add('barcode',Item[1].GTIN);
                JsObj.Add('taxable',Item[1]."Price Includes VAT");
                If ItemUnit.Get(Item[1]."No.",Item[1]."Base Unit of Measure") then
                begin
                    JsObj.Add('weight',Format(ItemUnit.Weight,0,'<Precision,2><Standard Format,1>'));
                    JsObj.Add('weight_unit','kg');
                end;     
                jsObj1.Add('variant',JsObj);
                JsObj1.WriteTo(PayLoad);
                Sleep(300);
                If Shopify_Data(Paction::PUT,ShopifyBase + 'variants/'+ Format(Item[1]."Shopify Product Variant ID") +'.json'
                         ,Parms,Payload,Data) then
                begin
                    Clear(Item[1]."Is Child Flag");
                    Item[1].Modify(false);
                end
                else
                    Update_Error_Log(StrSubstNo('Failed to update Standalone Item %1 with variant ID %2',Item[1]."No.",Item[1]."Shopify Product Variant ID"));    
            end
            else
            begin
                Clear(i);
                Rel.Setrange("Update Required",true);
                Rel.Setrange("Un Publish Child",False);
                if Rel.Findset then
                begin
                    //Check_Product_Structure(Item[1]);
                    repeat
                        i+=1;
                        Item[2].Get(Rel."Child Item No.");
                        If GuiAllowed then Wind.Update(2,Item[2]."No.");
                        Clear(Jsobj);
                        Clear(Jsobj1);
                        JsObj.Add('sku',Item[2]."No.");
                        JsObj.Add('option1',Item[2]."Shopify Body Html");
                        price := Item[2].Get_Price(RRP);
                        If (RRP > 0) AND (RRP <> Item[2]."Unit Price") then
                            Item[2]."Unit Price" := RRP;
                        JsObj.Add('price',format(price,0,'<Precision,2><Standard Format,1>'));
                        if (Price < Item[2]."Unit Price")  then
                            JsObj.Add('compare_at_price',format(Item[2]."Unit Price",0,'<Precision,2><Standard Format,1>'))
                        else
                            JsObj.Add('compare_at_price','');
                        JsObj.Add('inventory_management','shopify');
                        JsObj.Add('barcode',Item[2].GTIN);
                        JsObj.Add('taxable',Item[2]."Price Includes VAT");
                        If ItemUnit.Get(Item[2]."No.",Item[2]."Base Unit of Measure") then
                        begin
                            JsObj.Add('weight',Format(ItemUnit.Weight,0,'<Precision,2><Standard Format,1>'));
                            JsObj.Add('weight_unit','kg');
                        end;     
                        If (Item[2]."Shopify Product Variant ID" = 0) then
                        begin
                            if i = 1 then
                            begin
                                Clear(Item[2]."Shopify Product ID");
                                Item[2].validate("Shopify Product Variant ID",Item[1]."Shopify Product Variant ID");
                                Item[2].validate("Shopify Product Inventory ID",Item[1]."Shopify Product Inventory ID");
                                Item[2]."Shopify Transfer Flag" := true;  // flag the creation of a new Item variant
                                Item[2]."Is In Shopify Flag" := True;
                                Item[2]."Is Child Flag" := True;
                                Item[2].Validate("CRM Shopify Product ID",Item[1]."CRM Shopify Product ID");
                                Clear(Item[2]."Key Info Changed Flag");
                                Item[2].Modify(false);
                            end
                        end;
                        jsObj1.Add('variant',JsObj);
                        Clear(PayLoad);
                        JsObj1.WriteTo(PayLoad);
                        If (Item[2]."Shopify Product Variant ID" = 0) then    
                        begin
                            Sleep(300);
                            If Shopify_Data(Paction::POST,
                                ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") +'/variants.json'
                                ,Parms,Payload,Data) then
                            begin     
                                Data.Get('variant',JsToken[1]);
                                Jstoken[1].SelectToken('id',JsToken[2]);
                                Item[2].validate("Shopify Product ID",0);
                                Item[2].validate("Shopify Product Variant ID",JsToken[2].AsValue().AsBigInteger());
                                Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                                Item[2].validate("Shopify Product Inventory ID",JsToken[2].AsValue().AsBigInteger());
                                Item[2]."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                                Item[2]."Is In Shopify Flag" := True;
                                Item[2]."Is Child Flag" := True;
                                Item[2].validate("CRM Shopify Product ID",Item[1]."CRM Shopify Product ID");
                                Clear(Item[2]."Key Info Changed Flag");
                                item[2].modify(false);
                                Clear(Rel."Update Required");
                                Rel.Modify(False);
                             end
                            else
                                Update_Error_Log(StrSubstNo('Failed to create Child Item %1 with Parent Item %2 using Product ID %3',Item[2]."No.",Item[1]."No.",Item[1]."Shopify Product ID"));
                        end        
                        else
                        begin
                            Sleep(300);
                            If Shopify_Data(Paction::PUT,
                                ShopifyBase +'variants/'+ Format(Item[2]."Shopify Product Variant ID") + '.json'
                                ,Parms,Payload,Data) Then
                            begin
                                Item[2]."Is Child Flag" := True;
                                Clear(Item[2]."Key Info Changed Flag");
                                Item[2].validate("CRM Shopify Product ID",Item[1]."CRM Shopify Product ID");
                                Item[2].Validate("Shopify Product ID",0);
                                item[2].modify(false);
                                Clear(Rel."Update Required");
                                Rel.Modify(False);
                             end
                            else
                                Update_Error_Log(StrSubstNo('Failed to update Child Item %1 with Parent Item %2 using Product ID %3,Variant ID %4',Item[2]."No."
                                                                ,Item[1]."No.",Item[1]."Shopify Product ID",Item[2]."Shopify Product Variant ID"));
                             
                        end;
                   until Rel.next = 0;
                end;    
            end;
            Commit;
        Until Item[1].next = 0;
        If GuiAllowed then Wind.Close;
    end;
    local procedure Build_Shopify_Item_Costs(ItemFilt:Code[20])
    var
        Item:Record Item;
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:jsonArray;
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        wind:Dialog;
        PCost:record "PC Purchase Pricing";
        Cst:Decimal;
        Supp:code[20];
        SReb:record "PC Supplier Brand Rebates";
    begin
       If GuiAllowed then Wind.open('Checking Inventory Product ID #1##################');
        If Itemfilt = '' then
        Begin
            Clear(Parms);
            Item.LockTable(true);
            Item.Reset;
            Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
            Item.Setrange(Type,Item.Type::Inventory);
            Item.Setfilter("Shopify Product Variant ID",'>0');
            Item.SetRange("Shopify Product Inventory ID",0);
            If Item.findset then
            repeat
                if GuiAllowed then wind.update(1,Item."No.");
                Sleep(100);
                If Shopify_Data(Paction::GET,ShopifyBase +'variants/'+ Format(Item."Shopify Product Variant ID") + '.json'
                                    ,Parms,Payload,Data) Then
                    if Data.get('variant',JsToken[1]) then
                        If JsToken[1].SelectToken('inventory_item_id',JsToken[2]) then
                            If not JsToken[2].AsValue().IsNull then
                            begin
                                Item.Validate("Shopify Product Inventory ID",JsToken[2].AsValue().AsBigInteger());
                                Item.Modify(false);     
                            end;    
            until Item.next = 0;
            Commit;
            If GuiAllowed then 
            begin
                wind.Close();
                Wind.open('Updating Item Costs  #1##################');
            end;
            Clear(Parms);
            Item.Reset;
            Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
            Item.Setrange(Type,Item.Type::Inventory);
            Item.Setfilter("Shopify Product Inventory ID",'>0');
            If Item.findset then
            repeat
                Cst := Item."Unit Cost";
                If Cst = 0 then
                begin
                    Cst := 99999;
                    PCost.reset;
                    PCost.Setrange("Item No.",Item."No.");
                    If PCost.findset then
                    repeat
                        If PCost."Unit Cost" < Cst then
                        begin 
                            Cst := PCost."Unit Cost"; 
                            Supp := PCost."Supplier Code";
                        end;    
                    until PCost.next = 0;
                    If Cst < 99999 then
                    begin
                        SReb.reset;
                        SReb.Setrange("Supplier No.",Supp);
                        SReb.Setrange(Brand,Item.Brand);
                        Sreb.SetRange("Rebate Status",Sreb."Rebate Status"::Open);
                        If SReb.FindSet() then
                            Cst -= (Cst*Sreb."Marketing Rebate %"/100 + Cst* SReb."Supply Chain Rebate %"/100 
                                        + Cst*SReb."Volume Rebate %"/100);
                    end;
                end;    
                If Cst < 99999 then
                begin
                    If GuiAllowed then wind.Update(1,Item."No.");
                    Clear(Jsobj);
                    Clear(JsObj1);
                    JsObj.Add('id',Item."Shopify Product Inventory ID");
                    JsObj.Add('cost',format(Cst * 1.1,0,'<Precision,2><Standard Format,1>'));
                    JsObj1.Add('inventory_item',JsObj);
                    JsObj1.WriteTo(PayLoad);
                    Shopify_Data(Paction::PUT,
                                ShopifyBase +'inventory_items/'+ Format(Item."Shopify Product Inventory ID") + '.json'
                                ,Parms,Payload,Data); 
                end;
            until Item.next = 0;
        end;
        if GuiAllowed then Wind.close;
    end;
    local procedure Unpublish_Shopify_Items(ItemFilt:Code[20])
    var
        Item:Record Item;
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:jsonArray;
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        wind:Dialog;
        Log:record "PC Shopify Update Log";
    begin
        If GuiAllowed then Wind.open('Unpublishing Shopify Item #1#################');
        Item.LockTable(true);
        Item.Reset;
        Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
        If Itemfilt <> '' then
            Item.Setrange("No.",ItemFilt);
        Item.Setfilter("Shopify Product ID",'>0');
        Item.Setrange("Shopify Publish Flag",True);
        If Item.findset then
        repeat
            If GuiAllowed then Wind.Update(1,Item."No.");
            Clear(Jsobj);
            Clear(Jsobj1);
            JsObj.Add('id',Item."Shopify Product ID");
            JsObj.Add('published',False);
            jsObj1.Add('product',JsObj);
            JsObj1.WriteTo(PayLoad);
            if Not Shopify_Data(Paction::PUT,
                       ShopifyBase + 'products/'+ Format(Item."Shopify Product ID") + '.json'
                            ,Parms,Payload,Data) then
                Update_Error_Log(StrSubstNo('Failed to Unpublish Parent Item %1 Using Product ID %2'
                                                ,Item."No.",Item."Shopify Product ID"));              
        until Item.Next = 0;
        If GuiAllowed then Wind.Close; 
    end;
    procedure Publish_UnPublish_Shopify_Items(ItemFilt:Code[20];PubCtrl:boolean)
    var
        Item:Record Item;
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:jsonArray;
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        wind:Dialog;
        Log:record "PC Shopify Update Log";
    begin
        Item.Reset;
        Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
        If Itemfilt <> '' then
            Item.Setrange("No.",ItemFilt);
        Item.Setfilter("Shopify Product ID",'>0');
        If Item.findset then
        Begin
            Clear(Jsobj);
            Clear(Jsobj1);
            JsObj.Add('id',Item."Shopify Product ID");
            JsObj.Add('published',PubCtrl);
            jsObj1.Add('product',JsObj);
            JsObj1.WriteTo(PayLoad);
            if Not Shopify_Data(Paction::PUT,
                       ShopifyBase + 'products/'+ Format(Item."Shopify Product ID") + '.json'
                            ,Parms,Payload,Data) then
                Update_Error_Log(StrSubstNo('Failed to Unpublish Parent Item %1 Using Product ID %2'
                                                ,Item."No.",Item."Shopify Product ID"));
            Item."Shopify Publish Flag" := Not PubCtrl;
            Item.modify(False);
        end;
    end;    
  /*  local procedure Organise_Shopify_Items(ItemFilt:Code[20])
    var
        Item:array[2] of Record Item;
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:jsonArray;
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        wind:Dialog;
        ItTxt:text;
        Rel:record "PC Shopify Item Relations";
        i:Integer;
        price:Decimal;
        Flg:Boolean;
        Log:record "PC Shopify Update Log";
        ItemUnit:record "Item Unit of Measure";
    begin
        If GuiAllowed then 
            Wind.open('Updating Shopify Parent    #1##################\'
                     +'Organising Shopify Child   #2##################');
        Clear(Parms);
        Item[1].Reset;
        If Itemfilt <> '' then
            Item[1].Setrange("No.",ItemFilt);
        Item[1].Setrange("Shopify Item",Item[1]."Shopify Item"::Shopify);
        Item[1].Setfilter("Shopify Product ID",'>0');
        Item[1].Setrange("Is Child Flag",False);
        If Item[1].findset then
        repeat
            If GuiAllowed then Wind.Update(1,Item[1]."No.");
            Clear(JsObj);
            Clear(jsobj1);
            Clear(JsArry); 
            Clear(flg);
            Rel.Reset;
            Rel.SetCurrentKey("Child Position");
            Rel.Setrange("Parent Item No.",Item[1]."No.");
            Rel.Setrange("Update Required",true);
            Rel.Setrange("Un Publish Child",False);
            If Rel.findset then
               If Rel.Count > 1 then
                repeat
                    Item[2].Get(Rel."Child Item No.");
                    If GuiAllowed then Wind.Update(2,Item[2]."No.");
                    If Item[2]."Shopify Product Variant ID" > 0 then
                    begin
                        If Not Flg then
                        Begin
                            Item[1]."Shopify Product Variant ID" := Item[2]."Shopify Product Variant ID";
                            Item[1].Modify(False);
                        end;    
                        flg := true;
                        Clear(Jsobj);
                        JsObj.Add('id',Item[2]."Shopify Product Variant ID");
                        JsArry.Add(JsObj.AsToken());
                    end; 
                until Rel.next = 0;
            if Flg then
            begin
                Clear(Jsobj);
                jsObj.Add('variants',JsArry);
                JsObj.Add('id',Item[1]."Shopify Product ID");
                JsObj1.add('product',Jsobj);
                Clear(PayLoad);
                Clear(Data);
                JsObj1.WriteTo(PayLoad);
                If Not Shopify_Data(Paction::PUT,
                         ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") +'.json'
                         ,Parms,Payload,Data) then Update_Error_Log(StrSubstNo('Failed to Organise Children of Parent Item %1 Using Product ID %2'
                                                                    ,Item[1]."No.",Item[1]."Shopify Product ID"));     
            end;
            // remove Any parents with no children
            ItTxt := Item[1]."No.";
            Item[1].CalcFields("Shopify Child Count");
            If (Item[1]."Shopify Child Count" = 0) AND Ittxt.StartsWith('PAR-') then
            begin 
               if Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' + Format(Item[1]."Shopify Product ID") + '.json'
                                        ,Parms,PayLoad,Data) then
                begin                        
                    Clear_Flags(Item[1]);
                    // ensure they are not done next time 
                    Clear(Item[1]."Shopify Item");
                    Item[1].Modify(False);                              
                end;
            end;
            Rel.Reset;
            Rel.Setrange("Parent Item No.",Item[1]."No.");
            If Rel.findset then Rel.ModifyAll("Update Required",false,false);
        Until Item[1].next = 0;
        If GuiAllowed then Wind.Close;
    end;*/

    local procedure Update_Shopify_Items_Key_Info(ItemFilt:Code[20])
    var
        Item:Record Item;
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:jsonArray;
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        wind:Dialog;
        Log:record "PC Shopify Update Log";
    begin
        If GuiAllowed then Wind.open('Refreshing Shopify Item #1#################');
        // update any changes to titles etc
        Item.LockTable(true);
        Item.Reset;
        Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
        If Itemfilt <> '' then
            Item.Setrange("No.",ItemFilt);
        Item.Setfilter("Shopify Product ID",'>0');
        Item.Setrange("Key Info Changed Flag",true);
        If Item.findset then
        repeat
            if GuiAllowed Then Wind.Update(1,Item."No.");
            Clear(Jsobj);
            Clear(Jsobj1);
            JsObj.Add('id',Item."Shopify Product ID");
            JsObj.Add('title',Item."Shopify Title");
            jsObj1.Add('product',JsObj);
            JsObj1.WriteTo(PayLoad);
            If Shopify_Data(Paction::PUT,
                       ShopifyBase + 'products/'+ Format(Item."Shopify Product ID") + '.json'
                            ,Parms,Payload,Data) then
            begin                
                Clear(Item."Key Info Changed Flag");
                Item.Modify(False);
            end
            else
                Update_Error_Log(StrSubstNo('Failed to Refresh Key Info for Parent Item %1 Using Product ID %2'
                                                                    ,Item."No.",Item."Shopify Product ID"));                      
        until Item.Next = 0;
        If GuiAllowed Then Wind.close;
    end;

   //rountine to Process Item transfers to shopify
   [TryFunction]
    procedure Process_Items(ItemFilt: Code[20];Bypass:Boolean)
    var
        Log:record "PC Shopify Update Log";
        Setup:Record "Sales & Receivables Setup";
    begin
        Refresh_Product_Pricing(ItemFilt);
        If Not Bypass then
            Check_Shopify_Child_Structure(ItemFilt);
        Build_Shopify_Parents(ItemFilt);
        Build_Shopify_Children(ItemFilt);
        If Not Bypass then 
            Build_Shopify_Item_Costs(ItemFilt);   
        Unpublish_Shopify_Items(ItemFilt);
        Update_Shopify_Items_Key_Info(ItemFilt);
        Commit;
        Log.Reset;
        Log.Setfilter("Error Date/Time",'>=%1',CreateDateTime(Today(),0T));
        Log.Setrange("Web Service Error",'');
        If Log.Findset then
        begin
            Setup.get;
            //Send_Email_Msg('Shopify Item Synch Errors','Please check the Shopify Update Log it contains errors for todays date','vpacker@practiva.com.au');
            //Send_Email_Msg('Shopify Item Synch Errors','Please check the Shopify Update Log it contains errors for todays date',Setup."Shopify Excpt Email Address");
        end;
    end;
    [TryFunction]
    procedure Process_Out_Of_Stock_Shopify_Items();
    var
        Item:Array[2] of record Item;
        ItemTemp:record Item temporary;
        Cu:Codeunit "PC Fulfilio Routines";
        Bom:record "BOM Component";
        FInv:Record "PC Fulfilo Inventory";
        Rel:record "PC Shopify Item Relations";
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        RunFlg:Boolean;
        Win:Dialog;
   begin
        ItemTemp.reset;
        If ItemTemp.Findset Then ItemTemp.DeleteAll(False);
        RunFlg := CU.Build_Fulfilo_Inventory_Levels(); 
        If RunFlg then
        begin
            If GuiAllowed then Win.Open('Checking Item   #1#############'
                                   +'Processing Item #2#############');
            Item[1].LockTable(true);
            Item[1].Reset;
            Item[1].Setrange("Purchasing Blocked",True);
            Item[1].Setrange(Type,Item[1].Type::Inventory);
            Item[1].Setrange("Assembly BOM",False);
            Item[1].Setrange("Is In Shopify Flag",true);
            If Item[1].Findset then
            repeat
                If GuiAllowed Then Win.update(1,Item[1]."No.");
                Finv.Reset;
                Finv.Setrange(SKU,Item[1]."No.");
                If Finv.Findset then
                begin
                    FInv.CalcSums(Qty);
                    If Finv.Qty <= 0 then
                    begin
                        If GuiAllowed Then Win.update(2,Item[1]."No.");
                        If Delete_Shopify_Child(Item[1]) then
                        begin
                            // here we check if the SKU is in a BOM as well 
                            Bom.Reset;
                            Bom.Setrange(Type,Bom.Type::Item);
                            Bom.Setrange("No.",Item[1]."No.");
                            If Bom.Findset then
                            begin
                                Item[2].get(Bom."Parent Item No.");
                                Delete_Shopify_Child(Item[2]);      
                            end;
                        end;    
                        Rel.Reset;
                        Rel.Setrange("Child Item No.",Item[1]."No.");
                        Rel.Setrange("Un Publish Child",false);
                        If Rel.Findset then
                        Begin    
                            Rel."Un Publish Child" := True;
                            Rel.Modify(True);
                            Item[1].Validate("Shopify Product Variant ID",0);
                            Clear(Item[1]."Is In Shopify Flag");
                            Item[1]."Shopify Transfer Flag" := true;
                            Item[1].Modify(False);
                        End;
                        Commit;
                        Rel.Setrange("Un Publish Child",True);
                        If Rel.Findset then
                        begin
                            Bom.Reset;
                            Bom.Setrange(Type,Bom.Type::Item);
                            Bom.Setrange("No.",Item[1]."No.");
                            If Bom.Findset then
                            begin
                                Rel.Reset;
                                Rel.Setrange("Child Item No.",Bom."Parent Item No.");
                                Rel.Setrange("Un Publish Child",false);
                                If Rel.Findset then
                                begin
                                    Rel."Un Publish Child" := True;
                                    Rel.Modify(True);
                                    Item[2].get(Bom."Parent Item No.");
                                    Item[2].validate("Shopify Product Variant ID",0);
                                    Clear(Item[2]."Is In Shopify Flag");
                                    Item[2]."Shopify Transfer Flag" := true;
                                    Item[2].Modify(False);
                                end;
                            end;
                        end;
                        Commit;
                        Clear(Parms);
                        Clear(PayLoad);
                        Clear(Data);
                        Item[2].get(Rel."Parent Item No.");
                        Item[2].CalcFields("Shopify Child Count");
                        If (Item[2]."Shopify Child Count" = 0) then
                        begin 
                            Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' + Format(Item[2]."Shopify Product ID") + '.json'
                                        ,Parms,PayLoad,Data);
                            Clear_Flags(Item[2],false);
                            Clear(Item[2]."Shopify Item");
                            Item[2].Modify(False);                              
                        end
                        else
                        Begin
                            Item[2]."Shopify update Flag" := True;
                            Item[2].Modify(False);
                            If Not ItemTemp.get(rel."Parent Item No.") then
                            begin
                                ItemTemp.init;
                                ItemTemp."No." := rel."Parent Item No.";
                                ItemTemp.Insert(False);
                            end;
                        end;
                    end
                    //here we see if the item has been returned and needs to be 
                    //Re-established
                    else If (Finv.Qty > 0) And Not (Item[1]."Is In Shopify Flag") then
                    begin
                        Rel.Reset;
                        Rel.Setrange("Child Item No.",Item[1]."No.");
                        Rel.Setrange("Un Publish Child",True);
                        If Rel.Findset then
                        Begin    
                            If GuiAllowed Then Win.update(2,Item[1]."No.");
                            Clear(Rel."Un Publish Child");
                            Rel.Modify(True);
                            Item[2].Get(Rel."Parent Item No.");
                            Item[2]."Shopify Item" := Item[2]."Shopify Item"::Shopify;
                            Item[2]."Shopify update Flag" := True;
                            Item[2].Modify(False);
                            If Not ItemTemp.get(rel."Parent Item No.") then
                            begin
                                ItemTemp.init;
                                ItemTemp."No." := rel."Parent Item No.";
                                ItemTemp.Insert(False);
                            end;
                        end;     
                    end;    
                end;         
            until Item[1].next = 0;
            ItemTemp.Reset;
            If ItemTemp.Findset then 
            repeat
                Process_Items(ItemTemp."No.",False);
            until ItemTemp.Next = 0;       
            If GuiAllowed then win.close;
        end;
    end;
    procedure Check_Product_ID(Item:record Item;var Cnt:integer):Text
    Var 
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        JsArry:jsonArray;
        JsToken:array[2] of JsonToken;
        i:Integer;
        RetVal:Text;
        CRLF:text[2];
    Begin
        Clear(cnt);
        CRLF[1] := 13;
        CRLF[2] := 10;
        Clear(RetVal);
        Clear(Parms);
        Clear(PayLoad);
        Parms.add('fields','variants');
        If Shopify_Data(Paction::GET,ShopifyBase + 'products/'+ Format(Item."Shopify Product ID") + '.json'
                            ,Parms,Payload,Data) then 
        begin
            Data.Get('product',JsToken[1]);
            JsToken[1].SelectToken('variants',jstoken[2]);
            JsArry := JsToken[2].AsArray();
            for i := 0 to JsArry.Count - 1 do
            begin
                Cnt+=1;
                JsArry.get(i,JsToken[1]);
                jstoken[1].SelectToken('sku',JsToken[2]);
                RetVal += 'SKU -> ' + JsToken[2].AsValue().AsCode();
                JsToken[1].SelectToken('id',JsToken[2]);
                RetVal += ' ID  -> ' + Format(JsToken[2].AsValue().AsBigInteger()) + CRLF;
            end
        end
        else
            RetVal := 'Product ID not Found'; 
        exit(RetVal);                          
    End;
    local procedure Get_Parent_Variant_Structure(ProdID:BigInteger;var ChildLst:List of [Text])
    Var 
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        JsArry:jsonArray;
        JsToken:array[2] of JsonToken;
        i:Integer;
    Begin
        Clear(ChildLst);
        Clear(Parms);
        Clear(PayLoad);
        Parms.add('fields','variants');
        If Shopify_Data(Paction::GET,ShopifyBase + 'products/'+ Format(ProdID) + '.json'
                            ,Parms,Payload,Data) then 
        begin
            Data.Get('product',JsToken[1]);
            JsToken[1].SelectToken('variants',jstoken[2]);
            JsArry := JsToken[2].AsArray();
            for i := 0 to JsArry.Count - 1 do
            begin
                JsArry.get(i,JsToken[1]);
                jstoken[1].SelectToken('sku',JsToken[2]);
                Childlst.Add(JsToken[2].AsValue().AsCode());
            end
        end;
    End;
    local procedure Delete_Shopify_Child(var Item:Record Item):Boolean
    var
        Flg:Boolean;
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Rel:Array[2] of Record "PC Shopify Item Relations";
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        Item2:record Item;
        ItemUnit:record "Item Unit of Measure";
        i:integer;
    begin
        Clear(flg);
        If Item."CRM Shopify Product ID" > 0 then
        begin
            Item2.reset;
            Item2.Setrange("Shopify Product ID",Item."CRM Shopify Product ID");
            If Item2.Findset then
            begin
                Rel[1].Reset;
                Rel[1].Setrange("Parent Item No.",Item2."No.");
                Rel[1].Setrange("Un Publish Child",False);
                If Rel[1].findset then
                begin
                    Clear(Parms);
                    Clear(Data);
                    Clear(PayLoad);
                    If (Item."Shopify Product Variant ID" > 0) 
                    And (Rel[1].Count > 1) then
                    begin
                        Parms.Add('fields','variants');
                        if Not Shopify_Data(Paction::GET,ShopifyBase + 'products/' + Format(Item."CRM Shopify Product ID") + '.json'
                                    ,Parms,PayLoad,Data) then
                            exit(Flg);
                        Data.Get('product',JsToken[1]);
                        JsToken[1].SelectToken('variants',jstoken[2]);
                        JsArry := JsToken[2].AsArray();
                        for i := 0 to JsArry.Count - 1 do
                        begin
                            JsArry.get(i,JsToken[1]);
                            jstoken[1].SelectToken('sku',JsToken[2]);
                            if JsToken[2].AsValue().AsCode() = Item."No." then
                            begin
                                Clear(Parms);
                                JsToken[1].SelectToken('id',JsToken[2]);
                                If Not Shopify_Data(Paction::DELETE,ShopifyBase + 'products/'+ Format(Item."CRM Shopify Product ID") 
                                                        + '/variants/' + Format(jstoken[2].AsValue().AsBigInteger()) + '.json'
                                                        ,Parms,Payload,Data) Then
                                    exit(False)                                                                            
                                else                                                                                                    
                                    break;
                            end;
                        end;
                        Item.Validate("Shopify Product Variant ID",0);
                        Clear(Item."Is In Shopify Flag");
                        Item."Shopify Transfer Flag" := true;
                        Item.Modify(False);
                        Rel[2].Reset;
                        Rel[2].Setrange("Parent Item No.",Rel[1]."Parent Item No.");
                        Rel[2].Setrange("Child Item no.",Item."No.");
                        if Rel[2].Findset then
                        begin
                            Rel[2]."Un Publish Child" := True;
                            Rel[2].Modify(false);
                        end;
                        flg := true;
                    End;
                end;
            end;
        end;            
        exit(Flg);
    end;

    procedure Update_Shopify_Child(var Item:Record Item;Act:option Delete,Create):Boolean
    var
        Flg:Boolean;
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Rel:Array[2] of Record "PC Shopify Item Relations";
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        price:Decimal;
        Item2:record Item;
        ItemUnit:record "Item Unit of Measure";
        i:integer;
        RRP:Decimal;
    begin
        Clear(flg);
        If Item."CRM Shopify Product ID" > 0 then
        begin
            Item2.reset;
            Item2.Setrange("Shopify Product ID",Item."CRM Shopify Product ID");
            If Item2.Findset then
            begin
                Rel[1].Reset;
                Rel[1].Setrange("Parent Item No.",Item2."No.");
                If (Act = Act::Delete) then 
                    Rel[1].Setrange("Un Publish Child",False)
                else
                    Rel[1].Setrange("Un Publish Child",True);
                If Rel[1].findset then
                begin
                    Clear(Parms);
                    Clear(Data);
                    Clear(PayLoad);
                    If (Act = Act::Delete) And (Item."Shopify Product Variant ID" > 0) 
                    And (Rel[1].Count > 1) then
                    begin
                        Parms.Add('fields','variants');
                        if Not Shopify_Data(Paction::GET,ShopifyBase + 'products/' + Format(Item."CRM Shopify Product ID") + '.json'
                                    ,Parms,PayLoad,Data) then
                        begin 
                            If GuiAllowed then message(strsubstno('Failed to retrieve Item %1 with product ID %2 from shopify',Item."No.",Item."CRM Shopify Product ID")); 
                            exit(Flg);
                        end;    
                        Data.Get('product',JsToken[1]);
                        JsToken[1].SelectToken('variants',jstoken[2]);
                        JsArry := JsToken[2].AsArray();
                        for i := 0 to JsArry.Count - 1 do
                        begin
                            JsArry.get(i,JsToken[1]);
                            jstoken[1].SelectToken('sku',JsToken[2]);
                            if JsToken[2].AsValue().AsCode() = Item."No." then
                            begin
                                Clear(Parms);
                                JsToken[1].SelectToken('id',JsToken[2]);
                                If Not Shopify_Data(Paction::DELETE,ShopifyBase + 'products/'+ Format(Item."CRM Shopify Product ID") 
                                                        + '/variants/' + Format(jstoken[2].AsValue().AsBigInteger()) + '.json'
                                                        ,Parms,Payload,Data) Then
                                begin
                                    Update_Error_Log(StrSubstNo('Failed to delete Item %1 using product Id %2 variant %3 from shopify',Item."No."
                                                                                                                ,Item."CRM Shopify Product ID"
                                                                                                                ,jstoken[2].AsValue().AsBigInteger()));
                                    If GuiAllowed then Message(StrSubstNo('Failed to delete Item %1 using product Id %2 variant %3 from shopify',Item."No."
                                                                                                                ,Item."CRM Shopify Product ID"
                                                                                                                ,jstoken[2].AsValue().AsBigInteger()));
                                    exit(False);                                                                            
                                end                                                                                
                                else                                                                                                    
                                    break;
                            end;
                        end;
                        Item.validate("Shopify Product Variant ID",0);
                        Clear(Item."Is In Shopify Flag");
                        Item."Shopify Transfer Flag" := true;
                        Item.Modify(False);
                        Rel[2].Reset;
                        Rel[2].Setrange("Parent Item No.",Rel[1]."Parent Item No.");
                        Rel[2].Setrange("Child Item no.",Item."No.");
                        if Rel[2].Findset then
                        begin
                            Rel[2]."Un Publish Child" := True;
                            Rel[2].Modify(false);
                        end;
                        flg := true;
                    End 
                    else If (Act = Act::Create) And (Item."Shopify Product Variant ID" = 0) Then 
                    begin
                        Clear(Jsobj);
                        Clear(Jsobj1);
                        JsObj.Add('sku',Item."No.");
                        JsObj.Add('option1',Item."Shopify Body Html");
                        price := Item.Get_Price(RRP);
                        If (RRP > 0) AND (RRP <> Item."Unit Price") then
                            Item."Unit Price" := RRP;
                        JsObj.Add('price',format(price,0,'<Precision,2><Standard Format,1>'));
                        if (Price < Item."Unit Price")  then
                            JsObj.Add('compare_at_price',format(Item."Unit Price",0,'<Precision,2><Standard Format,1>'))
                        else
                            JsObj.Add('compare_at_price','');
                        JsObj.Add('inventory_management','shopify');
                        If ItemUnit.Get(Item."No.",Item."Base Unit of Measure") then
                        begin
                            JsObj.Add('weight',Format(ItemUnit.Weight,0,'<Precision,2><Standard Format,1>'));
                            JsObj.Add('weight_unit','kg');
                        end;     
                        jsObj1.Add('variant',JsObj);
                        Clear(PayLoad);
                        JsObj1.WriteTo(PayLoad);
                        If Shopify_Data(Paction::POST,
                                ShopifyBase + 'products/'+ Format(Item."CRM Shopify Product ID") +'/variants.json'
                                ,Parms,Payload,Data) then
                        begin             
                            Data.Get('variant',JsToken[1]);
                            Jstoken[1].SelectToken('id',JsToken[2]);
                            Item.validate("Shopify Product Variant ID",JsToken[2].AsValue().AsBigInteger());
                            Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                            Item.validate("Shopify Product Inventory ID",JsToken[2].AsValue().AsBigInteger());
                            Item."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                            Item."Is In Shopify Flag" := True;
                            Item."Is Child Flag" := True;
                            Item.modify(false);
                            Rel[2].Reset;
                            Rel[2].Setrange("Parent Item No.",Rel[1]."Parent Item No.");
                            Rel[2].Setrange("Child Item no.",Item."No.");
                            if Rel[2].Findset then
                            begin
                                Rel[2]."Un Publish Child" := False;
                                Rel[2].Modify(false);
                            end;    
                            Flg := True;
                        end
                        else
                        begin
                            Update_Error_Log(StrSubstNo('Failed to create Item %1 as a variant in shopify using product ID %2',Item."no.",Item."CRM Shopify Product ID"));
                            If GuiAllowed then Message(StrSubstNo('Failed to create Item %1 as a variant in shopify using product ID %2',Item."no.",Item."CRM Shopify Product ID"));    
                            exit(false);
                        end;    
                    end;
                end;
            end;
        end;    
        exit(Flg);
    end;
    // Routine to move SKU from one parenet to another
    procedure Move_Shopify_SKU(var MRel:record "PC Shopify Item Relations" temporary):Boolean
    var
        Flg:Boolean;
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Rel:Record "PC Shopify Item Relations";
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsToken:array[2] of JsonToken;
        JsArry:JsonArray;
        price:Decimal;
        Item:array[2] of record Item;
        ItemUnit:record "Item Unit of Measure";
        i:Integer;
        Pos:Integer;
        RRP:Decimal;
    begin
        Clear(Flg);
        If Mrel."Move To Parent" <> '' then
        begin
            Item[1].Get(Mrel."Move To Parent");
            If Item[1]."Shopify Product ID" > 0 then
            begin    
                // see if source parent has enough children after the strip
                Rel.Reset;
                Rel.Setrange("Parent Item No.",MRel."Parent Item No.");
                Rel.Findset();
                If Rel.Count - 1 > 0 then
                begin
                    Item[2].Get(Mrel."Child Item No.");
                    // see if the option we are about to move is already in the target
                    Clear(Parms); 
                    Parms.Add('fields','variants');
                    if not Shopify_Data(Paction::GET,ShopifyBase + 'products/' + Format(Item[1]."CRM Shopify Product ID") + '.json'
                                ,Parms,PayLoad,Data) then
                        error(strsubstno('Failed to retrieve Item %1 using product ID %2 from shopify',Item[1]."No.",Item[1]."CRM Shopify Product ID"));
                    Data.Get('product',JsToken[1]);
                    JsToken[1].SelectToken('variants',jstoken[2]);
                    JsArry := JsToken[2].AsArray();
                    for i := 0 to JsArry.Count - 1 do
                    begin
                        JsArry.get(i,JsToken[1]);
                        jstoken[1].SelectToken('option1',JsToken[2]);
                        If JsToken[2].AsValue().AsText() = Item[2]."Shopify Title" Then
                        begin
                            iF GuiAllowed then Message('Destination Parent already has a Variant with Option = %1 .. Move is invalid',Item[2]."Shopify Title");
                            exit(false);
                        end; 
                    end;
                    // now see if this is unpublished already ie we don't need to remove from 
                    // existing parent
                    If Not MRel."Un Publish Child" AND (Item[2]."CRM Shopify Product ID" > 0) then 
                    begin
                        if Not Shopify_Data(Paction::GET,ShopifyBase + 'products/' + Format(Item[2]."CRM Shopify Product ID") + '.json'
                                    ,Parms,PayLoad,Data) then
                            error(strsubstno('Failed to retrieve Item %1 using product ID %2 from shopify',Item[2]."No.",Item[2]."CRM Shopify Product ID"));
                        Data.Get('product',JsToken[1]);
                        JsToken[1].SelectToken('variants',jstoken[2]);
                        JsArry := JsToken[2].AsArray();
                        for i := 0 to JsArry.Count - 1 do
                        begin
                            JsArry.get(i,JsToken[1]);
                            jstoken[1].SelectToken('sku',JsToken[2]);
                            if JsToken[2].AsValue().AsCode() = Item[2]."No." then
                            begin
                                Clear(Parms);
                                JsToken[1].SelectToken('id',JsToken[2]);
                                sleep(100);
                                Flg := Shopify_Data(Paction::DELETE,ShopifyBase + 'products/'+ Format(Item[2]."CRM Shopify Product ID") 
                                                        + '/variants/' + Format(jstoken[2].AsValue().AsBigInteger()) + '.json'
                                                        ,Parms,Payload,Data);
                                break;
                            end;    
                        end;
                    end
                    else
                        Flg := True;
                    If Flg then
                    begin
                        // now we are ready to move to new parent            
                        Clear(Jsobj);
                        Clear(Jsobj1);
                        JsObj.Add('sku',Item[2]."No.");
                        JsObj.Add('option1',Item[2]."Shopify Body Html");
                        price := Item[2].Get_Price(RRP);
                        If (RRP > 0) AND (RRP <> Item[2]."Unit Price") then
                            Item[2]."Unit Price" := RRP;
                        JsObj.Add('price',format(price,0,'<Precision,2><Standard Format,1>'));
                        if (Price < Item[2]."Unit Price")  then
                            JsObj.Add('compare_at_price',format(Item[2]."Unit Price",0,'<Precision,2><Standard Format,1>'))
                        else
                            JsObj.Add('compare_at_price','');
                        JsObj.Add('inventory_management','shopify');    
                        If ItemUnit.Get(Item[2]."No.",Item[2]."Base Unit of Measure") then
                        begin
                            JsObj.Add('weight',Format(ItemUnit.Weight,0,'<Precision,2><Standard Format,1>'));
                            JsObj.Add('weight_unit','kg');
                        end;     
                        jsObj1.Add('variant',JsObj);
                        Clear(PayLoad);
                        JsObj1.WriteTo(PayLoad);
                        Flg := Shopify_Data(Paction::POST,
                                    ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") +'/variants.json'
                                    ,Parms,Payload,Data);
                        if Flg then            
                        begin
                            // save to remove from old parent relation
                            Rel.Get(Mrel."Parent Item No.",Mrel."Child Item No.");
                            POS := Rel."Child Position";
                            Rel.Delete();
                            Data.Get('variant',JsToken[1]);
                            Jstoken[1].SelectToken('id',JsToken[2]);
                            Item[2].validate("Shopify Product Variant ID",JsToken[2].AsValue().AsBigInteger());
                            Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                            Item[2].validate("Shopify Product Inventory ID",JsToken[2].AsValue().AsBigInteger());
                            Item[2]."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                            Item[2]."Is In Shopify Flag" := True;
                            Item[2]."Is Child Flag" := True;
                            Item[2].Validate("CRM Shopify Product ID",Item[1]."Shopify Product ID");
                            Item[2].modify(false);
                            // build new parent relation
                            Rel.init;
                            Rel."Parent Item No." := Item[1]."No.";
                            Rel."Child Item No." := Item[2]."No.";
                            Rel."Child Position" := POS;
                            Rel.Insert(True);
                            Commit;
                        end
                        else
                        begin 
                            // here if something went wrong we reasign back to original parent
                            Item[1].Get(MRel."Parent Item No.");
                            If Shopify_Data(Paction::POST,
                                    ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") +'/variants.json'
                                    ,Parms,Payload,Data) then
                            begin        
                                Data.Get('variant',JsToken[1]);
                                Jstoken[1].SelectToken('id',JsToken[2]);
                                Item[2].validate("Shopify Product Variant ID",JsToken[2].AsValue().AsBigInteger());
                                Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                                Item[2].validate("Shopify Product Inventory ID",JsToken[2].AsValue().AsBigInteger());
                                Item[2]."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                                Item[2]."Is In Shopify Flag" := True;
                                Item[2]."Is Child Flag" := True;
                                Item[2].Validate("CRM Shopify Product ID",Item[1]."Shopify Product ID");
                                Item[2].modify(false);
                            end;
                        end;
                    end;
                end;
            end;            
        end;
        exit(flg);
    end;   
    // Simple routine to test Shopify Connection is working 
    procedure Shopify_Test_Connection():Boolean
    var
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
    begin
        Clear(Parms);
        exit(Shopify_Data(Paction::GET,
                        ShopifyBase + 'products/count.json'
                        ,Parms,Payload,Data));
    end;
    //Simple routine to set all the items flags in a clear state
    local procedure Clear_Flags(var Item:Record Item;NoChg:Boolean)
    begin
        Item.validate("Shopify Product ID",0);
        Item.validate("Shopify Product Variant ID",0);
        Item.validate("Shopify Product Inventory ID",0);
        Item.validate("Shopify Location Inventory ID",0);
        Item."Shopify Transfer Flag" := True;
        If Item.Type = Item.type::"Non-Inventory" then
        begin 
            Item.validate("CRM Shopify Product ID",0);
            If Not NoChg then
                Item."Shopify Item" := Item."Shopify Item"::internal;
        end;    
        Clear(Item."Shopify Publish Flag");
        Clear(Item."Is In Shopify Flag");
        Clear(Item."Shopify Product Handle");
        Item."Shopify Update Flag" := true;
        Item.Modify(false);
    end;
    //routine to remove items from shopify
    procedure Delete_Items(ItemFilt:Code[20];NoChg:boolean):Boolean
    var
        Item:array[2] of Record Item;
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        rel:record "PC Shopify Item Relations";
    begin
        Item[1].Reset;
        Item[1].Setrange("No.",ItemFilt);
        Item[1].Setfilter("Shopify Product ID",'>0');
        If Item[1].Findset then
        begin
            Clear(Data);
            Clear(PayLoad);
            Clear(Parms);
            if Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' 
                        + Format(Item[1]."Shopify Product ID") + '.json'
                         ,Parms,PayLoad,Data) then
            begin
                Clear_Flags(Item[1],NoChg);
                // see if we have some children
                Rel.Reset;
                rel.Setrange("Parent Item No.",Item[1]."No.");
                If Rel.findset then
                repeat
                    if Item[2].Get(Rel."Child Item No.") then Clear_Flags(Item[2],NoChg);
                until rel.next = 0;
            end;
            Check_Delete_By_Handle(Item[1],NoChg);
            Clear_Flags(Item[1],NoChg);
            Commit;    
            exit(true);
        end;    
        exit(true);
    end;
    //extra precautionary delete mechanism to ensure removal of product from shopify
    local procedure Check_Delete_By_Handle(var Item:record Item;NoChg:Boolean)
    var
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        JsArry:jsonArray;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Item2:Record Item;
        rel:record "PC Shopify Item Relations";
        Flg:Boolean;
        i:integer;
    begin
        If Strlen(Item."Shopify Product Handle") > 0 then
        begin
            Clear(Flg);
            Clear(Parms);
            Clear(Data);
            Clear(PayLoad);
            Parms.Add('fields','id');
            Parms.Add('handle',Item."Shopify Product Handle");
            if Shopify_Data(Paction::GET,ShopifyBase + 'products.json'
                         ,Parms,PayLoad,Data) then
            begin
                Data.Get('products',JsToken[1]);
                JsArry := JsToken[1].AsArray();
                for i := 0 to JsArry.Count - 1 do
                begin
                    Clear(Parms);
                    JsArry.get(i,JsToken[1]);
                    jstoken[1].SelectToken('id',JsToken[2]);
                    If Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' 
                                    + JsToken[2].AsValue().AsText() + '.json'
                                    ,Parms,PayLoad,Data) then
                    Begin              
                        Clear_Flags(Item,NoChg);
                        Rel.Reset;
                        rel.Setrange("Parent Item No.",Item."No.");
                        If Rel.findset then
                        repeat
                            Item2.Get(Rel."Child Item No.");
                            Clear_Flags(Item2,NoChg);
                        until rel.next = 0;
                    end;    
                end;
            end;    
            Commit;
        end;        
    end;
    // routine to compare BC product ID's with Shopify ID's 
    // and remove any shopify products that BC does not know about
    Procedure Remove_Shopify_Duplicates()
    var
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        JsArry:jsonArray;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        i:integer;
        Cnt:Integer;
        remCnt:integer;
        Item:record Item;
        win:dialog;
        indx:BigInteger;
    begin
        If GuiAllowed then win.Open('Removing Product ID #1################\'
                                   +'Removal Count #2######');
        Clear(Parms);
        Clear(Data);
        Clear(PayLoad);
        Clear(remCnt);
        Clear(indx);
        if Shopify_Data(Paction::GET,ShopifyBase + 'products/count.json'
                     ,Parms,PayLoad,Data) then
        begin
            Data.Get('count',JsToken[1]);
            Cnt := JsToken[1].AsValue().AsInteger();
            repeat
                Cnt -= 250;
                Clear(Parms);
                Parms.Add('limit','250');   
                Parms.Add('fields','id');
                Parms.Add('since_id',Format(indx));
                sleep(10);
                if Shopify_Data(Paction::GET,ShopifyBase + 'products.json'
                         ,Parms,PayLoad,Data) then
                begin
                    Clear(Parms);
                    Data.Get('products',JsToken[1]);
                    JsArry := JsToken[1].AsArray();
                    for i := 0 to JsArry.Count - 1 do
                    begin
                        JsArry.get(i,JsToken[1]);
                        jstoken[1].SelectToken('id',JsToken[2]);
                        Item.Reset;
                        Item.Setrange("Shopify Product ID",JsToken[2].AsValue().AsBigInteger());
                        If Not Item.Findset then  
                        Begin
                            sleep(100);
                            if Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' 
                                        + JsToken[2].AsValue().AsText() + '.json'
                                        ,Parms,PayLoad,Data) then
                            begin 
                                RemCnt +=1;
                                if GuiAllowed then 
                                begin
                                    win.Update(1,JsToken[2].AsValue().AsText());
                                    Win.update(2,remCnt);
                                end;    
                            end;                    
                        end;
                    end;
                    indx := JsToken[2].AsValue().AsBigInteger();
                end;    
            until Cnt <= 0;
            if GuiAllowed then
            begin
                win.close;
                Message('%1 Duplicates have been removed from Shopify',Remcnt);
            end;    
        end;
    end;     
    //routine to purge all data from shopify 
    procedure Clean_Shopify()
    var
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        JsArry:jsonArray;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        i:integer;
        Cnt:Integer;
        remCnt:integer;
        Item:record Item;
        win:dialog;
        indx:BigInteger;
    begin
        if GuiAllowed then win.Open('Removing Product ID #1################\'
                                   +'Removal Count #2######');
        Clear(Parms);
        Clear(Data);
        Clear(PayLoad);
        Clear(remCnt);
        Clear(indx);
        if Shopify_Data(Paction::GET,ShopifyBase + 'products/count.json'
                     ,Parms,PayLoad,Data) then
        begin
            Data.Get('count',JsToken[1]);
            Cnt := JsToken[1].AsValue().AsInteger();
            if Cnt > 0 then 
            begin
                repeat
                    Cnt -= 250;
                    Clear(Parms);
                    Parms.Add('limit','250');   
                    Parms.Add('fields','id');
                    Parms.Add('since_id',Format(indx));
                    sleep(10);
                    if Shopify_Data(Paction::GET,ShopifyBase + 'products.json'
                            ,Parms,PayLoad,Data) then
                    begin
                        Clear(Parms);
                        Data.Get('products',JsToken[1]);
                        JsArry := JsToken[1].AsArray();
                        for i := 0 to JsArry.Count - 1 do
                        begin
                            JsArry.get(i,JsToken[1]);
                            jstoken[1].SelectToken('id',JsToken[2]);
                            sleep(100);
                            if Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' 
                                            + JsToken[2].AsValue().AsText() + '.json'
                                            ,Parms,PayLoad,Data) then
                            begin
                                RemCnt +=1;
                                if GuiAllowed then
                                begin
                                    win.Update(1,JsToken[2].AsValue().AsText());
                                    Win.update(2,remCnt);
                                end;    
                            end;                    
                        end;
                    end;
                    Indx := JsToken[2].AsValue().AsBigInteger();
                until Cnt <= 0;
            end;    
            if GuiAllowed then win.close;
            Item.Reset;
            Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
            Item.findset;
            repeat
                Clear_Flags(Item,False);
            until Item.next = 0;    
        end;            
    end;     
    // simple routine to access the corect price for SKU's in Shopify
    local procedure Check_For_Order_Corrections(Var Ordhdr:record "PC Shopify Order Header")
    var
        OrdLine:array[2] of Record "PC Shopify Order Lines";
        Item:Record Item;
        Excp:record "PC Shopify Order Exceptions";
    begin
        //Exceptions no longer required now
        Excp.Reset;
        Excp.Setrange(ShopifyID,OrdHdr.ID);
        If Excp.Findset then Excp.Deleteall();
        OrdLine[1].reset;
        OrdLine[1].SetFilter("Item No.",'<>%1&<>%2','','GIFT_CARD');
        Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
        If OrdLine[1].Findset then
        repeat
            If OrdLine[1]."FulFilo Shipment Qty" > OrdLine[1]."Order Qty" then
            begin
                OrdLine[2].CopyFilters(OrdLine[1]);
                OrdLine[2].Setrange("Item No.",OrdLine[1]."Item No.");
                OrdLine[2].Setrange("FulFilo Shipment Qty",0);
                If Ordline[2].findset then
                begin
                    OrdLine[2].CalcSums("Order qty");
                    If OrdLine[1]."Order Qty" + OrdLine[2]."Order Qty" = OrdLine[1]."FulFilo Shipment Qty" then
                    begin
                        OrdLine[1]."FulFilo Shipment Qty" := OrdLine[1]."Order Qty";
                        repeat
                            OrdLine[2]."FulFilo Shipment Qty" := OrdLine[2]."Order Qty";
                            OrdLine[2]."Location Code" := OrdLine[1]."Location Code";
                            OrdLine[2]."Unit Of Measure" := OrdLine[1]."Unit Of Measure";    
                            OrdLine[2].Modify();
                        until OrdLine[2].next = 0;    
                        OrdLine[1].modify;
                    end;    
                end;
            end
            else If (Ordhdr."Shopify Order Status" in ['PARTIAL','FULFILLED']) AND 
                (OrdLine[1]."FulFilo Shipment Qty" = 0) AND (OrdLine[1]."Order Qty" > 0) then
            begin
                OrdLine[1]."FulFilo Shipment Qty" := OrdLine[1]."Order Qty";
                OrdLine[1]."Location Code" := 'NSW';
                If Item.get(OrdLine[1]."Item No.") then
                    OrdLine[1]."Unit Of Measure" := Item."Base Unit of Measure";
                Clear(OrdLine[1]."Auto Delivered");        
                OrdLine[1].modify;
            end;                              
        until OrdLine[1].next = 0;
    end;
    local procedure Update_Order_Locations(OrdID:BigInteger):Boolean
    var
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:Array[3] of JsonArray;
        JsToken:array[2] of JsonToken;
        Loc:record Location;
        OrdHdr:record "PC Shopify Order Header";
        OrdLine:array[2] of Record "PC Shopify Order Lines";
        Setup:Record "Sales & Receivables Setup";
        StoreID:Integer;
        lineID:BigInteger;
        i:integer;
        j:integer;
        k:integer;
        Sku:Code[20];
        Item:record Item;
        Qty:Decimal;
        Excp:Record "PC Shopify Order Exceptions";
        Bom:record "BOM Component";
        Flg:Boolean;
        CU:Codeunit "PC Fulfilio Routines";
        OrdTot:Decimal;
        DisTot:Decimal;
        win:Dialog;
    begin
        if GuiAllowed then Win.Open('Processing Order No #1############');
        Ordhdr.Reset;
        OrdHdr.SetRange("Order Status",Ordhdr."Order Status"::Open);
        If OrdID <> 0 then OrdHdr.setrange(ID,OrdID);
        OrdHdr.Setrange("Order Type",OrdHdr."Order Type"::CreditMemo,OrdHdr."Order Type"::Cancelled);
        If OrdHdr.Findset then
        repeat
            Excp.Reset;
            Excp.Setrange(ShopifyID,OrdHdr.ID);
            If Excp.Findset then Excp.Deleteall();
            if GuiAllowed then Win.Update(1,OrdHdr."Shopify Order No.");
            OrdLine[1].Reset;
            Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
            OrdLine[1].SetFilter("Item No.",'<>%1','');
            OrdLine[1].SetFilter("Order Qty",'>0');
            If Ordline[1].FindSet() then
            repeat
                Item.get(OrdLine[1]."Item No.");
                // here we expand the Bom Components
                If Item.HasBOM() then
                begin
                    i := -1;
                    Bom.Reset;
                    Bom.Setrange("Parent Item No.",Item."No.");
                    Bom.Setrange(Type,Bom.Type::Item);
                    If Bom.Findset then
                    repeat
                        i += 1;
                        If i = 0 then
                        begin
                            OrdTot := OrdLine[1]."Base Amount";
                            DisTot := OrdLine[1]."Discount Amount";
                            Ordline[1]."Bundle Item No." := Item."No.";
                            Ordline[1]."Bundle Order Qty" := Ordline[1]."Order Qty";
                            Ordline[1]."Bundle Unit Price" := Ordline[1]."Unit Price";
                            Ordline[1]."BOM Qty" := Bom."Quantity per";
                            Ordline[1]."Item No." := Bom."No.";
                            Ordline[1]."Order Qty" := Ordline[1]."Bundle Order Qty" * Ordline[1]."BOM Qty";
                            OrdLine[1]."FulFilo Shipment Qty" := OrdLine[1]."Order Qty";
                            Ordline[1]."Unit Price" := Ordline[1]."Bundle Unit Price"/Ordline[1]."BOM Qty";
                            Ordline[1]."Unit Price" := (Ordline[1]."Unit Price" * Bom."Bundle Price Value %")/100;
                            If OrdLine[1]."Location Code" = '' then
                            begin
                                OrdLine[1]."Location Code" := 'QC';
                                If OrdHdr."Order Type" = OrdHdr."Order Type"::Cancelled then
                                    OrdLine[1]."Location Code" := 'NSW';
                            end;        
                            OrdLine[1]."Unit Of Measure" := Bom."Unit of Measure Code";
                            OrdLine[1]."Discount Amount" :=  (DisTot * Bom."Bundle Price Value %")/100;
                            OrdLine[1]."Base Amount" := (OrdTot * Bom."Bundle Price Value %")/100;
                            Ordline[1].Modify(false);
                            OrdLine[2].Copy(Ordline[1]);    
                        end
                        else
                        begin
                            Clear(OrdLine[2].ID);
                            Ordline[2]."BOM Qty" := Bom."Quantity per";
                            Ordline[2]."Item No." := Bom."No.";
                            Ordline[2]."Order Qty" := Ordline[2]."Bundle Order Qty" * Ordline[2]."BOM Qty";
                            OrdLine[2]."FulFilo Shipment Qty" := OrdLine[2]."Order Qty";
                            Ordline[2]."Unit Price" := Ordline[2]."Bundle Unit Price"/Ordline[2]."BOM Qty";
                            Ordline[2]."Unit Price" := (Ordline[2]."Unit Price" * Bom."Bundle Price Value %")/100;
                            OrdLine[2]."Unit Of Measure" := Bom."Unit of Measure Code";
                            OrdLine[2]."Discount Amount" :=  (DisTot * Bom."Bundle Price Value %")/100;
                            OrdLine[2]."Base Amount" := (OrdTot * Bom."Bundle Price Value %")/100;
                            OrdLine[2]."Order Line No" += i;
                            OrdLine[2].Insert();
                        end;          
                    until Bom.Next = 0;
                end
                else
                begin
                    If OrdLine[1]."Location Code" = '' then
                    begin
                        OrdLine[1]."Location Code" := 'QC';
                        If OrdHdr."Order Type" = OrdHdr."Order Type"::Cancelled then
                            OrdLine[1]."Location Code" := 'NSW';
                    end;        
                    OrdLine[1]."Unit Of Measure" := Item."Base Unit of Measure";
                    OrdLine[1]."FulFilo Shipment Qty" := OrdLine[1]."Order Qty";
                end; 
                Ordline[1].Modify(false);
            until OrdLine[1].next = 0;
            OrdHdr."Fulfilo Shipment Status" := OrdHdr."Fulfilo Shipment Status"::Complete;
            OrdHdr.modify;
        until OrdHdr.next = 0;  
        Flg := CU.FulFilo_Login_Connection();
        If Flg then
        begin
            Setup.get;
            If Setup."Use Fulfilo Dev Access" then
                StoreID := Setup."Dev FulFilio Store ID"
            else
                StoreID := Setup."FulFilio Store ID";
            Ordhdr.Reset;
            OrdHdr.SetRange("Order Status",Ordhdr."Order Status"::Open);
            OrdHdr.Setrange("Order Type",OrdHdr."Order Type"::Invoice);
            If OrdId <> 0 then OrdHdr.Setrange(ID,OrdID);
            OrdHdr.Setrange("Fulfilo Shipment Status",OrdHdr."Fulfilo Shipment Status"::InComplete);
            OrdHdr.Setfilter("Shopify Order Status",'<>NULL');
            //OrdHdr.Setfilter("Shopify Order Member Status",'<>%1','');
            If OrdHdr.Findset then
            repeat
                if GuiAllowed then Win.Update(1,OrdHdr."Shopify Order No.");
                OrdLine[1].Reset;
                Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
                OrdLine[1].SetFilter("Item No.",'<>%1&<>%2','','GIFT_CARD');
                OrdLine[1].SetFilter("Order Qty",'>0');
                If Ordline[1].FindSet() then
                repeat
                    Item.get(OrdLine[1]."Item No.");
                    // here we expand the Bom Components
                    If Item.HasBOM() then
                    begin
                        i := -1;
                        Bom.Reset;
                        Bom.Setrange("Parent Item No.",Item."No.");
                        Bom.Setrange(Type,Bom.Type::Item);
                        If Bom.Findset then
                        repeat
                            i += 1;
                            If i = 0 then
                            begin
                                OrdTot := OrdLine[1]."Base Amount";
                                DisTot := OrdLine[1]."Discount Amount";
                                Ordline[1]."Bundle Item No." := Item."No.";
                                Ordline[1]."Bundle Order Qty" := Ordline[1]."Order Qty";
                                Ordline[1]."Bundle Unit Price" := Ordline[1]."Unit Price";
                                Ordline[1]."BOM Qty" := Bom."Quantity per";
                                Ordline[1]."Item No." := Bom."No.";
                                Ordline[1]."Order Qty" := Ordline[1]."Bundle Order Qty" * Ordline[1]."BOM Qty";
                                Ordline[1]."Unit Price" := Ordline[1]."Bundle Unit Price"/Ordline[1]."BOM Qty";
                                Ordline[1]."Unit Price" := (Ordline[1]."Unit Price" * Bom."Bundle Price Value %")/100;
                                OrdLine[1]."Unit Of Measure" := Bom."Unit of Measure Code";
                                OrdLine[1]."Discount Amount" :=  (DisTot * Bom."Bundle Price Value %")/100;
                                OrdLine[1]."Base Amount" := (OrdTot * Bom."Bundle Price Value %")/100;
                                Clear(OrdLine[1]."FulFilo Shipment Qty");
                                Ordline[1].Modify(false);
                                OrdLine[2].Copy(Ordline[1]);    
                            end
                            else
                            begin
                                Clear(OrdLine[2].ID);
                                Ordline[2]."BOM Qty" := Bom."Quantity per";
                                Ordline[2]."Item No." := Bom."No.";
                                Ordline[2]."Order Qty" := Ordline[2]."Bundle Order Qty" * Ordline[2]."BOM Qty";
                                Ordline[2]."Unit Price" := Ordline[2]."Bundle Unit Price"/Ordline[2]."BOM Qty";
                                Ordline[2]."Unit Price" := (Ordline[2]."Unit Price" * Bom."Bundle Price Value %")/100;
                                OrdLine[2]."Unit Of Measure" := Bom."Unit of Measure Code";
                                OrdLine[2]."Discount Amount" :=  (DisTot * Bom."Bundle Price Value %")/100;
                                OrdLine[2]."Base Amount" := (OrdTot * Bom."Bundle Price Value %")/100;
                                OrdLine[2]."Order Line No" += i;
                                OrdLine[2].Insert();
                            end;          
                        until Bom.Next = 0;
                    end
                    else If Item.Type = Item.Type::"Non-Inventory" then
                    begin
                        OrdLine[1]."Location Code" := 'NSW';
                        OrdLine[1]."Unit Of Measure" := Item."Base Unit of Measure";
                        OrdLine[1]."FulFilo Shipment Qty" := OrdLine[1]."Order Qty";
                        OrdLine[1].modify;
                    end
                    else If OrdLine[1]."FulFilo Shipment Qty" <> 0 then
                    begin
                        Clear(OrdLine[1]."FulFilo Shipment Qty");
                        OrdLine[1].Modify(false);
                    end;
                Until OrdLine[1].next = 0;
                // clear the exception log
                Excp.Reset;
                Excp.Setrange(ShopifyID,OrdHdr.ID);
                If Excp.Findset then Excp.Deleteall();
                Clear(Data);
                Clear(PayLoad);
                Clear(Parms);
                // check that the order is not just for non inventory items
                OrdLine[1].Reset;
                Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
                OrdLine[1].SetRange("FulFilo Shipment Qty",0);
                OrdLine[1].SetFilter("Item No.",'<>%1&<>%2','','GIFT_CARD');
                OrdLine[1].SetFilter("Order Qty",'>0');
                if OrdLine[1].findset then
                begin
                    if CU.FulFilio_Data(Paction::GET,'/api/v1/stores/' + Format(StoreID) 
                                            +'/salesorders/eid/' + Format(OrdHdr."Shopify Order ID") 
                                            + '/shipments',Parms,PayLoad,Data) then 
                    begin                        
                        Data.Get('success',JsToken[1]); 
                        If JsToken[1].AsValue().AsBoolean() then
                        begin
                            Data.Get('data',JsToken[1]);
                            JsArry[1] := JsToken[1].AsArray();
                            For i := 0 to JsArry[1].count - 1  do
                            begin
                                JsArry[1].Get(i,JsToken[1]);
                                JsToken[1].SelectToken('warehouse',jstoken[2]);
                                JsToken[2].AsObject().SelectToken('id',jstoken[1]);
                                Loc.Reset;
                                Loc.Setrange("Fulfilo Warehouse ID",JsToken[1].AsValue().AsInteger());
                                If Loc.Findset then
                                begin
                                    JsArry[1].Get(i,JsToken[1]);
                                    JsToken[1].SelectToken('packages',jstoken[2]);
                                    JsArry[2] := JsToken[2].AsArray();
                                    For j := 0 to JsArry[2].count - 1 do
                                    begin
                                        JsArry[2].Get(j,JsToken[1]);
                                        Jstoken[1].SelectToken('packed_products',JsToken[2]);
                                        JsArry[3] := JsToken[2].AsArray();
                                        For K := 0 to JsArry[3].count - 1 do
                                        begin
                                            JsArry[3].Get(k,JsToken[1]);
                                            JsToken[1].SelectToken('external_order_product_id',jstoken[2]);
                                            If Not JsToken[2].AsValue().IsNull then
                                            begin
                                                lineID := JsToken[2].AsValue().AsBigInteger();
                                                JsToken[1].SelectToken('sku',jstoken[2]);
                                                sku := JsToken[2].AsValue().AsCode();
                                                OrdLine[1].Reset;
                                                Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
                                                Ordline[1].setrange("Order Line ID",lineID);
                                                Ordline[1].Setrange("Item No.",sku);
                                                Ordline[1].Setfilter("Order Qty",'>0');
                                                Ordline[1].Setrange("Fulfilo Shipment Qty",0);
                                                If Ordline[1].FindSet then
                                                begin
                                                    Ordline[1]."Location Code" := Loc.Code;
                                                    Item.Get(Ordline[1]."Item No.");
                                                    Ordline[1]."Unit Of Measure" := Item."Base Unit of Measure";    
                                                    JsToken[1].SelectToken('quantity_shipped',jstoken[2]);
                                                    Qty := Jstoken[2].AsValue().AsDecimal();
                                                    // copy the order incase we need to create a new line
                                                    OrdLine[2].Copy(Ordline[1]);
                                                    OrdLine[1]."Fulfilo Shipment Qty" := qty;
                                                    If Ordline[1]."Order Qty" > Qty then
                                                    Begin
                                                        Clear(OrdLine[2].ID);
                                                        Ordline[2]."Discount Amount" -= Ordline[1]."Discount Amount" * Qty/OrdLine[1]."Order Qty";
                                                        Ordline[2]."Base Amount" -= Ordline[1]."Base Amount" * Qty/OrdLine[1]."Order Qty";
                                                        Ordline[2]."Tax Amount" -= Ordline[1]."Tax Amount" * Qty/OrdLine[1]."Order Qty";
                                                        OrdLine[2]."Order Qty" -= Qty;
                                                        Ordline[1]."Discount Amount" := Ordline[1]."Discount Amount" * Qty/OrdLine[1]."Order Qty";
                                                        Ordline[1]."Base Amount" := Ordline[1]."Base Amount" * Qty/OrdLine[1]."Order Qty";
                                                        Ordline[1]."Tax Amount" := Ordline[1]."Tax Amount" * Qty/OrdLine[1]."Order Qty";
                                                        OrdLine[1]."Order Qty" := Qty;        
                                                        // create new line for update for next location qty
                                                        OrdLine[2]."Order Line No" += 1;
                                                        Ordline[2].insert;
                                                    end
                                                    else If Qty > Ordline[1]."Order Qty" then
                                                        OrdLine[1]."Fulfilo Shipment Qty" := Ordline[1]."Order Qty";     
                                                    Ordline[1].Modify(false);
                                                    Commit;
                                                end;    
                                            end
                                            else
                                            begin
                                                JsToken[1].SelectToken('sku',jstoken[2]);
                                                Excp.init;
                                                Clear(Excp.ID);
                                                Excp.insert;
                                                Excp.ShopifyID := OrdHdr.ID;
                                                Excp.Exception := StrsubStno('Fulfilio -> external_order_product_id returned NULL value for Product %1',JsToken[2].AsValue().AsCode()); 
                                                excp.Modify();
                                            end;
                                        end;        
                                    end;    
                                end 
                                else
                                Begin
                                    Excp.init;
                                    Clear(Excp.ID);
                                    Excp.insert;
                                    Excp.ShopifyID := OrdHdr.ID;
                                    Excp.Exception := StrsubStno('Fulfilio -> Warehouse ID %1 not defined in Locations',JsToken[1].AsValue().AsInteger()); 
                                    excp.Modify();
                                end;
                            end;
                            Excp.Reset;
                            Excp.Setrange(ShopifyID,OrdHdr.ID);
                            If Not Excp.Findset then
                            begin
                                // Check we have some lines that were fulfilled
                                OrdLine[1].Reset;
                                Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
                                OrdLine[1].SetFilter("Fulfilo Shipment Qty",'>0');
                                OrdLine[1].SetFilter("Item No.",'<>%1&<>%2','','GIFT_CARD');
                                OrdLine[1].SetFilter("Order Qty",'>0');
                                If OrdLine[1].Findset then
                                    If OrdLine[1].Count > 0 then
                                    begin
                                        Ordline[1].SetRange("Fulfilo Shipment Qty");
                                    If OrdLine[1].Findset then
                                    begin
                                        Ordline[1].CalcSums("Base Amount","Discount Amount");
                                        OrdTot := OrdLine[1]."Base Amount";
                                        DisTot := OrdLine[1]."Discount Amount";
                                        OrdLine[1].SetRange("Fulfilo Shipment Qty",0);
                                        If OrdLine[1].Findset then
                                        begin
                                            Ordline[1].CalcSums("Base Amount","Discount Amount");
                                            OrdTot -= OrdLine[1]."Base Amount";
                                            DisTot -= OrdLine[1]."Discount Amount";
                                            If (OrdHdr."Order Total" = OrdTot - DisTot + OrdHdr."Freight Total") then
                                                OrdLine[1].ModifyAll("Not Supplied",True);     
                                        end;
                                    end;
                                end;
                            end;            
                            OrdLine[1].Reset;
                            Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
                            OrdLine[1].Setrange("Not Supplied",False);
                            OrdLine[1].SetFilter("Item No.",'<>%1&<>%2','','GIFT_CARD');
                            OrdLine[1].SetFilter("Order Qty",'>0');
                            If Ordline[1].Findset then
                            begin
                                Check_For_Order_Corrections(OrdHdr);                                    
                                Ordline[1].CalcSums("Order Qty","Fulfilo Shipment Qty");
                                If Ordline[1]."Order Qty" = Ordline[1]."FulFilo Shipment Qty" then 
                                begin
                                    OrdLine[1].SetRange("Fulfilo Shipment Qty",0);
                                    If Ordline[1].Findset then
                                    begin
                                        Excp.init;
                                        Clear(Excp.ID);
                                        Excp.insert;
                                        Excp.ShopifyID := OrdHdr.ID;
                                        Excp.Exception := StrsubStno('Fulfilio -> Total Order Qty = Shipped Qty yet some order lines have not been shipped.. Check order lines where Shipped Qty > Order Qty'); 
                                        excp.Modify();
                                    end
                                    else
                                    begin
                                        OrdHdr."Fulfilo Shipment Status" := OrdHdr."Fulfilo Shipment Status"::Complete;       
                                        OrdHdr.Modify();
                                    end;    
                                end
                                else
                                begin
                                    Excp.init;
                                    Clear(Excp.ID);
                                    Excp.insert;
                                    Excp.ShopifyID := OrdHdr.ID;
                                    Excp.Exception := StrsubStno('Fulfilio -> Order Total Qty = %1,Fulfilio Shipped Total Qty = %2.',Ordline[1]."Order Qty", Ordline[1]."FulFilo Shipment Qty"); 
                                    excp.Modify();
                                    repeat
                                        If Ordline[1]."FulFilo Shipment Qty" = 0 then
                                        begin
                                            Excp.init;
                                            Clear(Excp.ID);
                                            Excp.insert;
                                            Excp.ShopifyID := OrdHdr.ID;
                                            if OrdLine[1]."Bundle Item No." <> '' then
                                                Excp.Exception := StrsubStno('Fulfilio -> Bundle Item %1 possibly changed directly in Fulfilio',OrdLine[1]."Bundle Item No.")
                                            else
                                                Excp.Exception := StrsubStno('Fulfilio -> Item %1 possibly changed directly in Fulfilio',OrdLine[1]."Item No.");
                                            excp.Modify();
                                        end;
                                    until OrdLine[1].next = 0;        
                                end;
                            end;
                            Update_Order_Application(OrdHdr);
                        end
                        else
                        begin
                            Data.Get('message',JsToken[1]);
                            Excp.init;
                            Clear(Excp.ID);
                            Excp.insert;
                            Excp.ShopifyID := OrdHdr.ID;
                            Excp.Exception := 'Fulfilio -> ' + Jstoken[1].AsValue().AsText();
                            excp.Modify();
                        end;
                    end
                    else
                    begin
                        Excp.init;
                        Clear(Excp.ID);
                        Excp.insert;
                        Excp.ShopifyID := OrdHdr.ID;
                        Excp.Exception := 'Failed to retrieve Shopify Order ID ' + Format(OrdHdr."Shopify Order ID") +' via Fulfilio Shipments API';
                        excp.Modify();
                    end;
                end
                else
                begin
                    OrdHdr."Fulfilo Shipment Status" := OrdHdr."Fulfilo Shipment Status"::Complete;       
                    OrdHdr.Modify();
                end;    
            until OrdHdr.next = 0;  
        end;
        Commit;
        if GuiAllowed then Win.Close;
        exit(flg);
    end;
    //routine to update the Order applications    
    local Procedure Update_Order_Application(var OrdHdr:Record "PC Shopify Order Header")
    var
        OrdLine:Record "PC Shopify Order Lines";
        OrdApp:Record "PC Shopfiy Order Applications";
        DiscApp:Record "PC Shopify Disc Apps";
    Begin
        OrdLine.Reset;
        Ordline.SetRange("ShopifyID",OrdHdr.ID);
        If Ordline.findset then
        repeat
            Clear(Ordline."Shopify Application ID");
            OrdApp.Reset;
            OrdApp.Setrange("ShopifyID",OrdHdr.ID);
            OrdApp.Setrange("Shopify Disc App Index",OrdLine."Shopify Application Index");
            If OrdApp.findset then
                If DiscApp.Get(OrdApp."Shopify Application Type",OrdApp."Shopify Disc App Code",OrdApp."Shopify Disc App Value") then
                    Ordline."Shopify Application ID" := DiscApp."Shopify App ID";
            Ordline.Modify();
        until Ordline.next = 0;    
    End;
    // Routine To Call Shopify and fetch the orders
    
    local procedure Check_For_Gift_Card(PJstoken:JsonToken;ID:BigInteger):Boolean
    var
        JsArry:JsonArray;
        JsToken:Array[2] of JsonToken;
        i:Integer;
        Dat:date;
        HasGiftCard:Boolean;
        exflg:Boolean;
        Setup:record "Sales & Receivables Setup";
    Begin 
        Setup.Get;
        exflg := True;
        Clear(HasGiftCard);
        if PJstoken.SelectToken('processed_at',Jstoken[1]) then
            If Not JsToken[1].AsValue().IsNull then
                If Evaluate(Dat,Copystr(JsToken[1].AsValue().AsText(),9,2) + '/' 
                        + Copystr(JsToken[1].AsValue().AsText(),6,2) + '/' + Copystr(JsToken[1].AsValue().AsText(),1,4)) then
        begin                   
            If PJstoken.SelectToken('line_items',Jstoken[1]) then
            begin
                JsArry := JsToken[1].AsArray();
                For i := 0 to JsArry.Count - 1 do
                begin
                    JsArry.get(i,JsToken[1]);
                    If JsToken[1].SelectToken('gift_card',JsToken[2]) then
                        if not Jstoken[2].AsValue().IsNull then
                            HasGiftcard := JsToken[2].AsValue().AsBoolean();
                    If HasGiftCard then break;                 
                end;
            end;
            // we have a gift card now see if we have waited long enough to process it now
            If HasGiftCard then 
                if Dat >= CalcDate('-4D',Today) then
                begin
                    Clear(exflg);
                    If Setup."Gift Card Order Index" = 0 Then
                        Setup."Gift Card Order Index" := ID
                    else if ID < Setup."Gift Card Order Index" then
                        Setup."Gift Card Order Index" := ID;
                    Setup.Modify(False);    
                end;
        end;
        exit(Exflg)
    End;
    local procedure Build_Order_Reconciliation(var JsRefToken:JsonToken;CFlg:Boolean)
    var
        OrdRec:array[2] of record "PC Order Reconciliations";
        Jstoken:array[2] of JsonToken;
        JsArry:array[2] of JsonArray;
        Dat:text;
        i,j:integer;
        Flg:Boolean;
        InvFlg:Boolean;
    begin
        Clear(InvFlg);
        JsReftoken.SelectToken('id',Jstoken[2]);
        If Cflg then
        begin
            Flg := Not OrdRec[1].Get(Jstoken[2].AsValue().AsBigInteger(),Ordrec[1]."Shopify Order Type"::Cancelled);
            InvFlg := OrdRec[1].Get(Jstoken[2].AsValue().AsBigInteger(),Ordrec[1]."Shopify Order Type"::Invoice);
        end    
        else
        Begin
            Flg := Not OrdRec[1].Get(Jstoken[2].AsValue().AsBigInteger(),Ordrec[1]."Shopify Order Type"::Invoice);
            // saftey to ensure the cancelled is not there already
            If Flg then
                Flg := Not OrdRec[1].Get(Jstoken[2].AsValue().AsBigInteger(),Ordrec[1]."Shopify Order Type"::Cancelled);
        end;
        If Flg Then
        begin
            // see if we have the invoice but need to change it to Cancelled
            If InvFlg then 
                OrdRec[1].Delete();
            OrdRec[1].Init();
            OrdRec[1]."Shopify Order ID" := Jstoken[2].AsValue().AsBigInteger();
            OrdRec[1]."Shopify Display ID" := OrdRec[1]."Shopify Order ID"; 
            OrdRec[1]."Shopify Order Type" := OrdRec[1]."Shopify Order Type"::Invoice;
            If CFlg then
                OrdRec[1]."Shopify Order Type" := OrdRec[1]."Shopify Order Type"::Cancelled;
            OrdRec[1].insert;
        end;    
        JsReftoken.SelectToken('order_number',Jstoken[2]);
        OrdRec[1]."Shopify Order No" := Jstoken[2].AsValue().AsBigInteger();
        If JsReftoken.SelectToken('processed_at',Jstoken[2]) then
            if Not JsToken[2].AsValue().IsNull then
            begin
                Dat:= Copystr(Jstoken[2].AsValue().astext,1,10);
                if Evaluate(OrdRec[1]."Shopify Order Date",Copystr(Dat,9,2) + '/' + Copystr(Dat,6,2) + '/' + Copystr(Dat,1,4)) then;
            end;    
        Get_Order_Reconciliation_Transactions(OrdRec[1]);
     //   If OrdRec[1]."Payment Gate Way" = OrdRec[1]."Payment Gate Way"::AfterPay then;
        OrdRec[1].Modify();
        If JsRefToken.SelectToken('refunds',JsToken[2]) then
        Begin
            OrdRec[2].Copy(OrdRec[1]);
            OrdRec[2]."Shopify Order Type" := OrdRec[2]."Shopify Order Type"::Refund;
            Clear(OrdRec[2]."Order Total");
            JsArry[1] := JsToken[2].AsArray();
            If JsArry[1].Count > 0 then
                For i := 0 to JsArry[1].Count - 1 do
                begin
                    JsArry[1].get(i,JsToken[1]);
                    Jstoken[1].SelectToken('processed_at',Jstoken[2]);
                    if Not JsToken[2].AsValue().IsNull then
                    begin
                        Dat:= Copystr(Jstoken[2].AsValue().astext,1,10);
                        if Evaluate(OrdRec[2]."Shopify Order Date",Copystr(Dat,9,2) + '/' + Copystr(Dat,6,2) + '/' + Copystr(Dat,1,4)) then;
                    end;    
                    JsToken[1].SelectToken('transactions',JsToken[2]);
                    JsArry[2] := JsToken[2].AsArray();
                    For j := 0 to JsArry[2].Count - 1 do
                    begin
                        JsArry[2].get(j,JsToken[1]);
                        if JsToken[1].SelectToken('amount',Jstoken[2]) then
                            If not Jstoken[2].AsValue().IsNull then
                                OrdRec[2]."Order Total" += Jstoken[2].AsValue().AsDecimal();
                    end;
                end;
            If OrdRec[2]."Order Total" > 0 then    
                If Not OrdRec[1].Get(OrdRec[2]."Shopify Order ID",OrdRec[2]."Shopify Order Type") then
                    OrdRec[2].Insert;
        end;
        Commit;    
    end;
    [TryFunction]
    procedure Get_Shopify_Orders(StartIndex:BigInteger;EndOrderNo:BigInteger)
    var
        OrdHdr:Array[2] of record  "PC Shopify Order Header";
        OrdApp:record "PC Shopfiy Order Applications";
        OrdLine:Array[2] of record "PC Shopify Order Lines";
        indx:BigInteger;
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:Array[3] of JsonArray;
        JsToken:array[2] of JsonToken;
        cnt: integer;
        i:integer;
        j:integer;
        k:integer;
        dat:Text;
        flg:boolean;
        win:dialog ;
        Setup:record "Sales & Receivables Setup";
        Item:record Item;
        ItemUnit:record "Item Unit of Measure";
        DimVal:record "Dimension Value";
        TstVal:text;
        recCnt:Integer;
        StartDate:date;
        CancelFlg:boolean;    
    begin
        if Not Item.Get('GIFT_CARD') then
        begin
            Item.init;
            Item.validate("No.",'GIFT_CARD');
            Item.Insert();
            Item.Description := 'Gift Card';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'VOUCHER');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            If Not ItemUnit.get('GIFT_CARD','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'GIFT_CARD';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;
        if GuiAllowed then win.Open('Retrieving Order No    #1###########\'
                                   +'Processing Order No    #2###########\'
                                   +'Order Type             #3###########');
        Setup.Get;
        Clear(indx);
        Clear(Cnt);
        OrdHdr[1].Reset;
        OrdHdr[1].SetCurrentKey("Shopify Order No.");
        if OrdHdr[1].findlast then Startdate := OrdHdr[1]."Shopify Order Date";
        OrdHdr[1].Reset;
        OrdHdr[1].SetCurrentKey("Shopify Order No.");
        Case Date2DWY(today,1) of
            2,4: OrdHdr[1].Setfilter("Shopify Order Date",'<=%1',CalcDate('-5D',Startdate));
            6: OrdHdr[1].Setfilter("Shopify Order Date",'<=%1',CalcDate('-3W',Startdate));
        end;    
        if OrdHdr[1].findlast then Indx := OrdHdr[1]."Shopify Order No."; 
        OrdHdr[1].Reset;
        OrdHdr[1].SetFilter("Shopify Order No.",'>=%1',Indx);
        If OrdHdr[1].FindFirst() then 
            Indx := OrdHdr[1]."Shopify Order ID"
        else
            Clear(Indx);        
        If StartIndex <> 0 then indx := StartIndex;
        If Setup."Gift Card Order Index" > 0 then
            If Indx > Setup."Gift Card Order Index" then
                indx := Setup."Gift Card Order Index";
        Clear(Setup."Gift Card Order Index");
        Setup.modify(false);    
        Clear(PayLoad);
        Clear(Parms);
        Clear(recCnt);
        Parms.Add('since_id',Format(indx));
        Parms.add('status','any');
        Parms.Add('limit','250');
        Parms.Add('fields','id,cancelled_at,fulfillment_status,order_number,discount_applications,line_items,processed_at'
                +',currency,total_discounts,total_shipping_price_set,financial_status,total_price,total_tax,refunds');
        if Not Shopify_Data(Paction::GET,ShopifyBase + 'orders/count.json',Parms,PayLoad,Data) then Exit(false);
        Data.Get('count',JsToken[1]);
        Cnt := JsToken[1].AsValue().AsInteger();
        repeat
            Cnt -= 250;
            Sleep(10);
            Shopify_Data(Paction::GET,ShopifyBase + 'orders.json',Parms,PayLoad,Data);
            if Data.Get('orders',JsToken[1]) then
            begin
                JsArry[1] := JsToken[1].AsArray();
                for i := 0 to JsArry[1].Count - 1 do
                begin
                    JsArry[1].get(i,Jstoken[1]);
                    Flg := True;
                    if Jstoken[1].SelectToken('order_number',Jstoken[2]) then
                        If Not JsToken[2].asvalue.IsNull then
                        begin
                            if GuiAllowed then Win.Update(1,Jstoken[2].AsValue().AsBigInteger());
                            If (EndOrderNo > 0) and (Jstoken[2].AsValue().AsBigInteger() >= EndOrderNo) then
                            begin    
                                Clear(Flg);
                                Clear(Cnt);
                            end;
                        end;    
                    Clear(Indx);
                    If Flg Then Flg := Jstoken[1].SelectToken('id',Jstoken[2]);
                    If Flg Then Flg := Not Jstoken[2].AsValue().IsNull;
                    Indx := Jstoken[2].AsValue().AsBigInteger();
                    If Flg then Flg := Jstoken[1].SelectToken('cancelled_at',Jstoken[2]);
                    If Flg then CancelFlg := Not Jstoken[2].AsValue().IsNull; 
                    if Flg Then Flg := Jstoken[1].SelectToken('financial_status',Jstoken[2]);
                    if Flg Then Flg := Not Jstoken[2].AsValue().IsNull;
                    If Flg then Flg := Jstoken[2].AsValue().AsText().ToUpper() in ['PAID','REFUNDED','PARTIALLY_REFUNDED'];
                    If Flg then Flg := Jstoken[1].SelectToken('fulfillment_status',Jstoken[2]);
                    If Flg Then
                    Begin
                        Build_Order_Reconciliation(Jstoken[1],CancelFlg);
                        IF Not CancelFlg then
                            Flg := Not Jstoken[2].AsValue().IsNull;
                    end;    
                    if Flg Then Flg := Check_For_Gift_Card(jstoken[1],indx);
                    If Flg then
                    begin
                        OrdHdr[1].Reset;
                        OrdHdr[1].Setrange("Shopify Order ID",indx);
                        OrdHdr[1].SetFilter("Order Type",'%1|%2',OrdHdr[1]."Order Type"::Invoice,OrdHdr[1]."Order Type"::Cancelled);
                        Flg := not OrdHdr[1].Findset;
                    end;         
                    If Flg then 
                    begin
                        OrdHdr[1].init;
                        Clear(OrdHdr[1].ID);
                        OrdHdr[1].insert(True);
                        OrdHdr[1]."Order Type" := OrdHdr[1]."Order Type"::Invoice;
                        OrdHdr[1]."Shopify Order ID" := indx;
                        Jstoken[1].SelectToken('financial_status',Jstoken[2]);
                        OrdHdr[1]."Shopify Financial Status" := Jstoken[2].AsValue().Astext().ToUpper();
                        Ordhdr[1]."Shopify Order Status" := 'FULFILLED';
                        If CancelFlg then
                        Begin
                            OrdHdr[1]."Order Type" := OrdHdr[1]."Order Type"::Cancelled;
                            OrdHdr[1]."Refunds Checked" := true;
                        end    
                        else
                        Begin
                            Jstoken[1].SelectToken('fulfillment_status',Jstoken[2]);
                            If Jstoken[2].AsValue().Astext().ToUpper() = 'PARTIAL' then
                                OrdHdr[1]."Shopify Order Status" := 'PARTIAL';
                        end;            
                        if Jstoken[1].SelectToken('order_number',Jstoken[2]) then
                            If Not JsToken[2].asvalue.IsNull then
                            begin
                                OrdHdr[1]."Shopify Order No." := Jstoken[2].AsValue().AsBigInteger();
                                if GuiAllowed then
                                begin 
                                    Win.Update(2,OrdHdr[1]."Shopify Order No.");
                                    Win.Update(3,Format(OrdHdr[1]."Order Type"));
                                end;    
                            end;    
                        if Jstoken[1].SelectToken('processed_at',Jstoken[2]) then
                            If Not JsToken[2].AsValue().IsNull then
                            begin
                                Dat:= Copystr(Jstoken[2].AsValue().astext,1,10);
                                if Evaluate(OrdHdr[1]."Shopify Order Date",Copystr(Dat,9,2) + '/' + Copystr(Dat,6,2) + '/' + Copystr(Dat,1,4)) then;
                            end;    
                        if Jstoken[1].SelectToken('currency',Jstoken[2]) then
                            If Not JsToken[2].AsValue().IsNull then
                                OrdHdr[1]."Shopify Order Currency" := CopyStr(Jstoken[2].AsValue().AsCode(),1,10);
                        If Jstoken[1].SelectToken('total_discounts',Jstoken[2]) then
                            If Not JsToken[2].AsValue().IsNull then
                                OrdHdr[1]."Discount Total" := JsToken[2].AsValue().AsDecimal();
                        if Jstoken[1].SelectToken('total_price',Jstoken[2]) then
                            If Not JsToken[2].AsValue().IsNull then
                                OrdHdr[1]."Order Total" := JsToken[2].AsValue().AsDecimal();
                        If Jstoken[1].SelectToken('total_shipping_price_set',Jstoken[2]) then
                            If Jstoken[2].AsObject().SelectToken('shop_money',JsToken[1]) then
                                If Jstoken[1].Asobject().SelectToken('amount',Jstoken[2]) then
                                    If Not JsToken[2].AsValue().IsNull then
                                        OrdHdr[1]."Freight Total" := JsToken[2].AsValue().AsDecimal();
                        if Jstoken[1].SelectToken('total_tax',Jstoken[2]) then
                            if not Jstoken[2].AsValue().IsNull then
                                OrdHdr[1]."Tax Total" := JsToken[2].AsValue().AsDecimal();
                        Ordhdr[1].Modify();
                        recCnt +=1;
                        if JsArry[1].get(i,Jstoken[1]) Then
                        begin
                            If Jstoken[1].SelectToken('discount_applications',Jstoken[2]) then
                                If JsToken[2].AsArray().Count > 0 then
                                begin
                                    JsArry[2] := JsToken[2].AsArray();
                                    for j := 0 to JsArry[2].Count - 1 do
                                    begin
                                        JsArry[2].get(j,Jstoken[1]);
                                        OrdApp.init;
                                        Clear(OrdApp.ID);
                                        OrdApp.Insert;
                                        OrdApp.ShopifyID := OrdHdr[1].ID;
                                        OrdApp."Shopify Order ID" := OrdHdr[1]."Shopify Order ID";
                                        if JsToken[1].Selecttoken('type',JsToken[2]) then
                                            if not Jstoken[2].AsValue().IsNull then
                                                OrdApp.validate("Shopify App Type",JsToken[2].AsValue().AsText());
                                        if JSToken[1].SelectToken('description',jsToken[2]) then
                                            if not Jstoken[2].AsValue().IsNull then
                                                OrdApp."Shopify Disc App Description" := CopyStr(Jstoken[2].AsValue().AsCode(),1,100)
                                        else if JSToken[1].SelectToken('title',jsToken[2]) then
                                            if not Jstoken[2].AsValue().IsNull then
                                                OrdApp."Shopify Disc App Description" := CopyStr(Jstoken[2].AsValue().AsCode(),1,100);
                                        if JSToken[1].SelectToken('code',jsToken[2]) then
                                            if not Jstoken[2].AsValue().IsNull then
                                                OrdApp."Shopify Disc App Code" := CopyStr(Jstoken[2].AsValue().AsCode(),1,100);
                                        if JSToken[1].SelectToken('value',jsToken[2]) then
                                            if not Jstoken[2].AsValue().IsNull then
                                                OrdApp."Shopify Disc App value" := jsToken[2].AsValue().AsDecimal();
                                        if JSToken[1].SelectToken('value_type',jsToken[2]) then
                                            if not Jstoken[2].AsValue().IsNull then
                                                OrdApp."Shopify Disc App value Type" := jsToken[2].AsValue().Astext;
                                        OrdApp."Shopify Disc App Index" := j;
                                        OrdApp.modify(true);
                                    end;
                                end;
                            JsArry[1].get(i,Jstoken[1]);
                            If Jstoken[1].SelectToken('line_items',Jstoken[2]) then
                                If jsToken[2].AsArray().Count > 0 then
                                begin
                                    JsArry[2] := JsToken[2].AsArray();
                                    for j := 0 to JsArry[2].Count - 1 do
                                    begin
                                        JsArry[2].get(j,JsToken[1]);
                                        OrdLine[1].init;
                                        Clear(OrdLine[1].ID);
                                        Ordline[1].insert;
                                        Ordline[1]."Shopify Order ID" := OrdHdr[1]."Shopify Order ID";
                                        Ordline[1].ShopifyID := OrdHdr[1].ID;
                                        Ordline[1]."Order Line No" := (j + 1) * 10;
                                        if JsToken[1].SelectToken('id',JsToken[2]) Then
                                        begin
                                            if not Jstoken[2].AsValue().IsNull then
                                            Begin    
                                                OrdLine[1]."Order Line ID" := JsToken[2].AsValue().AsBigInteger();
                                                If JsToken[1].SelectToken('sku',JsToken[2]) then
                                                begin
                                                    If Not JsToken[2].AsValue().IsNull then
                                                    begin
                                                        Ordline[1]."Item No." := CopyStr(jstoken[2].AsValue().AsCode(),1,20);
                                                        If JsToken[1].SelectToken('gift_card',JsToken[2]) then
                                                            if not Jstoken[2].AsValue().IsNull then
                                                                if JsToken[2].AsValue().AsBoolean() then
                                                                    Ordline[1]."Item No." := 'GIFT_CARD';
                                                        if JsToken[1].SelectToken('quantity',JsToken[2]) then
                                                            if not Jstoken[2].AsValue().IsNull then
                                                                Ordline[1]."Order Qty" :=  jstoken[2].AsValue().AsDecimal();
                                                        if JsToken[1].SelectToken('price',JsToken[2]) then
                                                            if not Jstoken[2].AsValue().IsNull then
                                                                Ordline[1]."Unit Price" :=  jstoken[2].AsValue().AsDecimal();
                                                        if JsToken[1].SelectToken('total_discount',JsToken[2]) then
                                                            if not Jstoken[2].AsValue().IsNull then
                                                                Ordline[1]."Discount Amount" := jstoken[2].AsValue().AsDecimal();
                                                        Ordline[1]."Shopify Application Index" := -1;
                                                        if JsToken[1].SelectToken('discount_allocations',JsToken[2]) then
                                                        begin
                                                            If JsToken[2].AsArray().Count > 0 then
                                                            begin
                                                                Jstoken[2].AsArray().get(0,Jstoken[1]);
                                                                if jstoken[1].SelectToken('discount_application_index',JsToken[2]) then
                                                                    if not Jstoken[2].AsValue().IsNull then
                                                                        Ordline[1]."Shopify Application Index" := JsToken[2].AsValue().AsInteger();
                                                                if jstoken[1].SelectToken('amount',JsToken[2]) then
                                                                    if not Jstoken[2].AsValue().IsNull then
                                                                        Ordline[1]."Discount Amount" := jstoken[2].AsValue().AsDecimal(); 
                                                            end;    
                                                        end;
                                                        Ordline[1]."Tax Amount" := 0;
                                                        JsArry[2].get(j,JsToken[1]);
                                                        if JsToken[1].SelectToken('tax_lines',JsToken[2]) then
                                                        begin
                                                            If JsToken[2].AsArray().Count > 0 then
                                                            begin
                                                                Jstoken[2].AsArray().get(0,Jstoken[1]);
                                                                if jstoken[1].SelectToken('price',JsToken[2]) then
                                                                    if not Jstoken[2].AsValue().IsNull then
                                                                        Ordline[1]."Tax Amount" := jstoken[2].AsValue().AsDecimal();
                                                            end;    
                                                        end;
                                                        JsArry[2].get(j,JsToken[1]);
                                                        Clear(OrdLine[1]."Auto Delivered");
                                                        if JsToken[1].SelectToken('properties',JsToken[2]) then
                                                        begin
                                                            If JsToken[2].AsArray().Count > 0 then
                                                            begin
                                                                JsArry[3] := JsToken[2].AsArray();
                                                                for k := 0 to JsArry[3].Count - 1 do
                                                                begin
                                                                    JsArry[3].get(k,JsToken[1]);
                                                                    If JsToken[1].SelectToken('name',JsToken[2]) then
                                                                        if not Jstoken[2].AsValue().IsNull then
                                                                            If JsToken[2].AsValue().AsText() = '_subscription_line_item' then
                                                                                If JsToken[1].SelectToken('value',JsToken[2]) then
                                                                                    if not Jstoken[2].AsValue().IsNull then
                                                                                        If Evaluate(OrdLine[1]."Auto Delivered",JsToken[2].AsValue().Astext) then             
                                                                                            break;
                                                                end;    
                                                            end;
                                                        end;
                                                        Ordline[1]."Base Amount" := Ordline[1]."Order Qty" * Ordline[1]."Unit Price";
                                                        If Item.Get(Ordline[1]."Item No.") then
                                                            Ordline[1].modify(false)
                                                        else OrdLine[1].Delete();
                                                    end
                                                        else OrdLine[1].Delete();
                                                end
                                                else
                                                    OrdLine[1].delete();    
                                            end    
                                            else
                                                OrdLine[1].delete;
                                        end
                                        else
                                            OrdLine[1].delete;
                                    end;  
                                end; 
                            end
                            else if GuiAllowed then
                            begin 
                                Win.Update(2,'');
                                Win.update(3,'');
                            end;
                            OrdLine[1].reset;
                            OrdLine[1].Setrange(ShopifyID,OrdHdr[1].ID);
                            If Not OrdLine[1].FindSet() then
                            begin
                                OrdHdr[1].Delete(True);
                                RecCnt -=1;
                            end
                            else if OrdHdr[1]."Order Type" = OrdHdr[1]."Order Type"::Cancelled then 
                            begin
                                OrdHdr[2].Copy(OrdHdr[1]);
                                OrdHdr[2]."Order Type" := OrdHdr[2]."Order Type"::CreditMemo;
                                Clear(OrdHdr[2].ID);
                                OrdHdr[2].insert(true);
                                repeat    
                                    OrdLine[2].copy(OrdLine[1]);
                                    OrdLine[2].ShopifyID := OrdHdr[2].ID;
                                    Clear(OrdLine[2].ID);
                                    OrdLine[2].Insert();
                                until OrdLine[1].next = 0;    
                            end;
                    end
                    else if GuiAllowed then
                    begin 
                        Win.Update(2,'');
                        Win.update(3,'');
                    end;
                end;
            end;
            Parms.Remove('since_id');
            Parms.Add('since_id',Format(indx));
            If recCnt > 50 then
            begin
                Clear(RecCnt);
                Commit;
            end;
        until Cnt <=0; 
        Commit;
        Process_Current_Refunds(false);
        //do every 7 days on Saturday
        If Date2DWY(today,1) = 6 then Process_Refunds(0);
        //Do every 7 days on Sunday
        If Date2DWY(today,1) = 7 then Check_For_Extra_Refunds(0);
        If Not Dimval.Get('REFUNDS','UNSPECIFIED') then
        begin
            Dimval.init;
            DimVal."Dimension Code" := 'REFUNDS';
            DimVal.Code := 'UNSPECIFIED';
            DimVal.Name := Dimval.Code;
            DimVal."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;
            Dimval.insert;
        end;
        Clear(Parms);
        Parms.Add('fields','note');
        OrdHdr[1].Reset;
        OrdHdr[1].Setrange(OrdHdr[1]."Order Type",OrdHdr[1]."Order Type"::CreditMemo);
        OrdHdr[1].Setrange("Order Status",OrdHdr[1]."Order Status"::Open);
        if OrdHdr[1].Findset then
        repeat
            OrdLine[1].reset;
            OrdLine[1].Setrange(ShopifyID,OrdHdr[1].ID);
            If OrdLine[1].findset then
            begin
                Clear(PayLoad);
                if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr[1]."Shopify Order ID") +'/refunds.json'
                                ,Parms,PayLoad,Data) then
                begin                
                    Data.Get('refunds',JsToken[1]);
                    if Not JsToken[1].AsArray().get(0,JsToken[2]) then
                        OrdLine[1].modifyall("Reason Code",'UNSPECIFIED')
                    else
                    begin    
                        JsToken[2].AsObject().SelectToken('note',JsToken[1]);
                        If Jstoken[1].AsValue().IsNull then
                        begin
                            OrdLine[1].modifyall("Reason Code",'UNSPECIFIED');
                        end    
                        else
                        begin 
                            if Strlen(CopyStr(JsToken[1].AsValue().AsText().ToUpper(),1,20)) > 0 then
                            begin
                                Dimval.reset;
                                DimVal.Setrange("Dimension Code",'REFUNDS');
                                If DimVal.Findset then
                                repeat
                                    TstVal := DimVal.Code;
                                    Flg := Tstval.Contains(CopyStr(JsToken[1].AsValue().AsText().ToUpper(),1,20));
                                    If Flg Then OrdLine[1].modifyall("Reason Code",Dimval.Code);
                                until (Dimval .next = 0) Or Flg;
                            end 
                            else
                                Clear(Flg);         
                            If Not Flg then OrdLine[1].modifyall("Reason Code",'UNSPECIFIED');
                        end
                    end    
                end     
                else
                    OrdLine[1].modifyall("Reason Code",'UNSPECIFIED');
            end;        
        Until OrdHdr[1].next = 0;
        if GuiAllowed then win.Close;
    end;
    procedure Get_Order_Reconciliation_Transactions(var OrdRec:record "PC Order Reconciliations")
    var
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:JsonArray;
        JsToken:array[3] of JsonToken;
        i:integer;
        PayGate:Text;
    Begin
        OrdRec."Payment Gate Way" := OrdRec."Payment Gate Way"::Misc;
        Clear(OrdRec."Order Total");
        Clear(OrdRec."Reference No");
        Clear(Parms);
        if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdRec."Shopify Order ID") + '/transactions.json'
                                     ,Parms,PayLoad,Data) then
        begin                             
            If Data.Get('transactions',JsToken[1]) then
            begin
                JsArry := JsToken[1].AsArray();
                If JsArry.Count > 0 then
                    For i := 0 to Jsarry.Count - 1 do
                    Begin     
                        JsArry.get(i,JsToken[1]);
                        JsToken[1].SelectToken('kind',JsToken[2]); 
                        If JsToken[2].AsValue().AsText().ToUpper().Contains('SALE') then
                        begin
                            Jstoken[1].SelectToken('status',JsToken[2]);
                            If (JsToken[2].AsValue().AsText().ToUpper() = 'SUCCESS') then
                            begin
                                JsToken[1].SelectToken('amount',JsToken[2]);
                                OrdRec."Order Total" += JsToken[2].AsValue().AsDecimal();
                                JsToken[1].SelectToken('gateway',JsToken[2]);
                                If not Jstoken[2].AsValue().IsNull then
                                begin
                                    PayGate := CopyStr(JsToken[2].AsValue().AsText(),1,25).ToUpper();
                                    If PayGate.Contains('SHOPIFY') then
                                        OrdRec."Payment Gate Way" := OrdRec."Payment Gate Way"::"Shopify Pay"
                                    else If PayGate.Contains('PAYPAL') then
                                        OrdRec."Payment Gate Way" := OrdRec."Payment Gate Way"::Paypal
                                    else If PayGate.Contains('AFTER') then
                                        OrdRec."Payment Gate Way" := OrdRec."Payment Gate Way"::AfterPay
                                    else If PayGate.Contains('ZIP') then
                                        OrdRec."Payment Gate Way" := OrdRec."Payment Gate Way"::Zip;
                                end;
                                if JsToken[1].SelectToken('source_name',JsToken[2]) then
                                    If not Jstoken[2].AsValue().IsNull then
                                        OrdRec."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);    
                                if JsToken[1].SelectToken('receipt',JsToken[2]) then
                                begin
                                    If JsToken[2].SelectToken('transaction_id',JsToken[3]) then
                                    begin
                                        If not Jstoken[3].AsValue().IsNull then
                                            OrdRec."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                    end        
                                    else If JsToken[2].SelectToken('TransactionID',JsToken[3]) then
                                    begin
                                        If not Jstoken[3].AsValue().IsNull then
                                            OrdRec."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                    end        
                                    else if JsToken[2].SelectToken('payment_id',JsToken[3]) then
                                    begin
                                        If not Jstoken[3].AsValue().IsNull then
                                            OrdRec."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                    end        
                                    else if JsToken[2].SelectToken('x_reference',JsToken[3]) then
                                    begin
                                        If not Jstoken[3].AsValue().IsNull then
                                            OrdRec."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                    end        
                                    else if JsToken[2].SelectToken('token',JsToken[3]) then
                                    begin
                                        If not Jstoken[3].AsValue().IsNull then
                                            OrdRec."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                    end        
                                    else if JsToken[2].SelectToken('gift_card_id',JsToken[3]) then
                                    Begin
                                        If not Jstoken[3].AsValue().IsNull then
                                            OrdRec."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25);
                                    end;               
                                end;
                            end;
                        end;                    
                end;
            end;
        end;                  
        If OrdRec."Reference No" = '' then
        begin
            Clear(Data);
            Clear(Parms);
            Parms.Add('fields','note,note_attributes,source_name,total_shipping_price_set,total_price');
            if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdRec."Shopify Order ID") + '.json'
                                    ,Parms,PayLoad,Data) then
            begin
                If Data.Get('order',JsToken[1]) then
                begin
                    If Jstoken[1].SelectToken('total_price',Jstoken[2]) then
                        If Not JsToken[2].AsValue().IsNull then
                                OrdRec."Order Total" := JsToken[2].AsValue().AsDecimal();
                    If JsToken[1].SelectToken('source_name',JsToken[2]) then
                        If not Jstoken[2].AsValue().IsNull then
                            If JsToken[2].AsValue().AsText().ToUpper().Contains('MARKET') then
                            begin
                                OrdRec."Payment Gate Way" := OrdRec."Payment Gate Way"::MarketPlace; 
                                If JsToken[1].SelectToken('note',JsToken[2]) then
                                    If not Jstoken[2].AsValue().IsNull then
                                        OrdRec."Reference No" := CopyStr(Extract_MarketPlace_Invoice_Number(JsToken[2].AsValue().AsText()),1,25);
                                If OrdRec."Reference No" = '' then
                                    If JsToken[1].SelectToken('note_attributes',JsToken[2]) then
                                        If JsToken[2].AsArray().Get(0,JsToken[1]) then
                                            If JsToken[1].SelectToken('value',JsToken[2]) then
                                                If not Jstoken[2].AsValue().IsNull then
                                                    OrdRec."Reference No" := JsToken[2].AsValue().AsText();
                            end 
                            else
                                OrdRec."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);            
                end;
            end;
        end;
    end;
    local procedure Get_Order_Transactions(var Ordhdr:record "PC Shopify Order Header")
    var
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:JsonArray;
        JsToken:array[3] of JsonToken;
        i:integer;
    Begin
        Clear(Parms);
        Ordhdr."Transaction Date" := Today;
        OrdHdr."Transaction Type" := 'promotion';
        Clear(Ordhdr."Reference No");
        if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr."Shopify Order ID") + '/transactions.json'
                                     ,Parms,PayLoad,Data) then
        begin                             
            If Data.Get('transactions',JsToken[1]) then
            begin
                JsArry := JsToken[1].AsArray();
                For i := 0 to Jsarry.Count - 1 do
                Begin     
                    JsArry.get(i,JsToken[1]);
                    JsToken[1].SelectToken('kind',JsToken[2]); 
                    If JsToken[2].AsValue().AsText().ToUpper().Contains('SALE') then
                    begin
                        Jstoken[1].SelectToken('status',JsToken[2]);
                        If (JsToken[2].AsValue().AsText().ToUpper() = 'SUCCESS') then
                        begin
                            OrdHdr."Transaction Type" := 'sale';
                            If JsToken[1].SelectToken('gateway',JsToken[2]) then
                                If not Jstoken[2].AsValue().IsNull then
                                    OrdHdr."Payment Gate Way" := CopyStr(JsToken[2].AsValue().AsText(),1,25);
                            if JsToken[1].SelectToken('processed_at',JsToken[2]) then
                                If not Jstoken[2].AsValue().IsNull then
                                    If Evaluate(OrdHdr."Processed Date",CopyStr(JsToken[2].AsValue().AsText(),9,2) + '/' + 
                                        CopyStr(JsToken[2].AsValue().AsText(),6,2) + '/' +
                                        CopyStr(JsToken[2].AsValue().AsText(),1,4) + '/' ) then
                                        begin                
                                            OrdHdr."Processed Time" := CopyStr(JsToken[2].AsValue().AsText(),12,8);
                                            if not Evaluate(OrdHdr."Proc Time",OrdHdr."Processed Time") then
                                                OrdHdr."Proc Time" := 0T;
                                        end; 
                            if JsToken[1].SelectToken('source_name',JsToken[2]) then
                                If not Jstoken[2].AsValue().IsNull then
                                    OrdHdr."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);    
                            if JsToken[1].SelectToken('receipt',JsToken[2]) then
                            begin
                                If JsToken[2].SelectToken('transaction_id',JsToken[3]) then
                                begin
                                    If not Jstoken[3].AsValue().IsNull then
                                        OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                end        
                                else if JsToken[2].Asobject.SelectToken('payment_id',JsToken[3]) then
                                begin
                                    If not Jstoken[3].AsValue().IsNull then
                                        OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                end        
                                else if JsToken[2].SelectToken('x_reference',JsToken[3]) then
                                begin
                                    If not Jstoken[3].AsValue().IsNull then
                                        OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                end        
                                else if JsToken[2].SelectToken('token',JsToken[3]) then
                                begin
                                    If not Jstoken[3].AsValue().IsNull then
                                        OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                end        
                                else if JsToken[2].SelectToken('gift_card_id',JsToken[3]) then
                                Begin
                                    If not Jstoken[3].AsValue().IsNull then
                                    begin
                                        OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25);
                                        If JsToken[1].SelectToken('amount',JsToken[3]) then
                                            If not Jstoken[3].AsValue().IsNull then
                                                Ordhdr."Gift Card Total" := JsToken[3].AsValue().AsDecimal();
                                    end; 
                                end;
                            end;
                        end;
                    end;  
                end;
            end;
        end;                  
        If OrdHdr."Reference No" = '' then
        begin
            Clear(Data);
            Clear(Parms);
            Parms.Add('fields','note,source_name');
            if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr."Shopify Order ID") + '.json'
                                    ,Parms,PayLoad,Data) then
            begin
                If Data.Get('order',JsToken[1]) then
                begin
                    If JsToken[1].SelectToken('source_name',JsToken[2]) then
                        If not Jstoken[2].AsValue().IsNull then
                            If JsToken[2].AsValue().AsText().ToUpper().Contains('MARKET') then
                            begin
                                If JsToken[1].SelectToken('note',JsToken[2]) then
                                    If not Jstoken[2].AsValue().IsNull then
                                    begin
                                        OrdHdr."Reference No" := CopyStr(Extract_MarketPlace_Invoice_Number(JsToken[2].AsValue().AsText()),1,25);
                                        OrdHdr."Payment Gate Way" := 'market_place';
                                    end;
                            end 
                            else
                                OrdHdr."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);            
                                            
                end;
            end;
        end;
    end; 
    procedure Process_Current_Refunds(BypassDateFilter:Boolean):Integer
    var
        Recon:record "PC Order Reconciliations";
        OrdHdr:record "PC Shopify Order Header";
        Cnt:integer;
    Begin
        Clear(Cnt);
        Recon.Reset;
        Recon.Setrange("Apply Status",Recon."Apply Status"::UnApplied,Recon."Apply Status"::CashApplied);
        Recon.Setrange("Shopify Order Type",Recon."Shopify Order Type"::Refund);
        Recon.Setrange("Extra Refund Count",0);
        If Not BypassDateFilter then
            Recon.Setfilter("Shopify Order Date",'>=%1',Calcdate('-3W',Today));
        If Recon.Findset then
        repeat
            OrdHdr.reset;
            OrdHdr.Setrange("Shopify Order ID",Recon."Shopify Order ID");
            OrdHdr.Setrange("Order Type",OrdHdr."Order Type"::CreditMemo);
            If Not OrdHdr.findset then
            begin
                OrdHdr.Setrange("Order Type",OrdHdr."Order Type"::Invoice);
                OrdHdr.Setrange("Order Status",OrdHdr."Order Status"::Closed);
                If OrdHdr.FindSet() then
                begin
                    Clear(OrdHdr."Refunds Checked");
                    OrdHdr.Modify(False);
                    Commit;     
                    Process_Refunds(Recon."Shopify Order No");
                    Cnt+=1;
                end;    
            end;        
        until Recon.next = 0;
        exit(cnt);    
    End;
                       
    procedure Process_Refunds(RefundID:BigInteger)
    var
        OrdHdr:array[2] of record "PC Shopify Order Header";
        OrdLine:record "PC Shopify Order Lines";
        indx:BigInteger;
        JsArry:array[2] of JsonArray;
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsToken:array[3] of JsonToken;
        i,j:integer;
        dat:Text;
        win:Dialog;
        RecCnt:integer;
        TransAmount:Array[2] of Decimal;
        Item:record Item;
        Itemunit:record "Item Unit of Measure";
        OrdExist:Boolean;
        RefQty:Decimal;
        OrigQty:Decimal;
        Setup:record "Sales & Receivables Setup";
    begin
        if Not Item.Get('NON_REFUND_ITEM') then
        begin
            Item.init;
            Item.validate("No.",'NON_REFUND_ITEM');
            Item.Insert();
            Item.Description := 'Anonymous Refund Item';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'VOUCHER');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            If Not ItemUnit.get('NON_REFUND_ITEM','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'NON_REFUND_ITEM';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;
        if GuiAllowed then win.Open('Retrieving Order No    #1###########\'
                                   +'Processing Order No    #2###########');
        Setup.get;
        If Setup."Refund Order Lookback Period" = 0 then
        begin
            Setup."Refund Order Lookback Period" := 2;
            Setup.modify(False);
        end;
        Clear(PayLoad);
        Clear(Parms);
        Clear(RecCnt);
        Parms.Add('fields','refunds');
        OrdHdr[1].Reset;
        OrdHdr[1].SetCurrentKey("Shopify Order No.");
        OrdHdr[1].Setrange("Order Status",OrdHdr[1]."Order Status"::Closed);
        OrdHdr[1].SetFilter("BC Reference No.",'<>%1','');
        OrdHdr[1].Setrange("Order Type",OrdHdr[1]."Order Type"::Invoice);
        If RefundID <> 0 then 
            OrdHdr[1].Setrange("Shopify Order No.",RefundID)
        else
            OrdHdr[1].SetFilter("Shopify Order Date",'<=%1',CalcDate('-' + Format(Setup."Refund Order Lookback Period") + 'W',Today));    
        OrdHdr[1].Setrange("Refunds Checked",False);
        If OrdHdr[1].FindSet() then
            repeat
                if GuiAllowed then 
                begin 
                    Win.Update(1,OrdHdr[1]."Shopify Order No.");
                    Win.Update(2,'');
                end;    
                if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr[1]."Shopify Order ID") + '.json'
                                                ,Parms,PayLoad,Data) then
                Begin
                    Clear(OrdExist);
                    Data.Get('order',JsToken[1]);
                    If JsToken[1].SelectToken('refunds',JsToken[2]) then
                    Begin
                        JsArry[1] := JsToken[2].AsArray();
                        For i := 0 to JsArry[1].Count - 1 do
                        begin
                            JsArry[1].get(i,JsToken[1]);
                            Clear(TransAmount);
                            JsToken[1].SelectToken('transactions',JsToken[2]);
                            JsArry[2] := JsToken[2].AsArray();
                            if JsArry[2].Count > 0  then
                            begin
                                JsArry[2].get(0,JsToken[1]);
                                if JsToken[1].SelectToken('amount',Jstoken[2]) then
                                    If not Jstoken[2].AsValue().IsNull then
                                        TransAmount[1] := Jstoken[2].AsValue().AsDecimal();
                            end;
                            TransAmount[2] := TransAmount[1];
                            JsArry[1].get(i,JsToken[1]);
                            If i = 0 then
                            begin
                                if JsToken[1].SelectToken('order_id',JsToken[2]) then
                                    if not JsToken[2].AsValue().IsNull then
                                        indx := JsToken[2].AsValue().AsBigInteger();
                                OrdHdr[2].Reset;
                                OrdHdr[2].Setrange("Order Type",OrdHdr[2]."Order Type"::CreditMemo);
                                OrdHdr[2].Setrange("Shopify Order ID",indx);
                                OrdExist := Not OrdHdr[2].Findset;
                                If OrdExist then
                                begin
                                    if GuiAllowed then Win.Update(2,OrdHdr[1]."Shopify Order No.");
                                    OrdHdr[2].init;
                                    Clear(OrdHdr[2].ID);
                                    OrdHdr[2].insert(True);
                                    OrdHdr[2]."Shopify Order Status" := 'FULFILLED';
                                    OrdHdr[2]."Order Type" := OrdHdr[2]."Order Type"::CreditMemo;
                                    OrdHdr[2]."Shopify Order ID" := indx;
                                    OrdHdr[2]."Shopify Order No." := OrdHdr[1]."Shopify Order No.";
                                    OrdHdr[2]."Transaction Type" := 'refund';
                                    OrdHdr[2]."Shopify Financial Status" := 'REFUNDED';
                                    if Jstoken[1].SelectToken('processed_at',Jstoken[2]) then
                                    begin
                                        Dat:= Copystr(Jstoken[2].AsValue().astext,1,10);
                                        If Evaluate(OrdHdr[2]."Shopify Order Date",Copystr(Dat,9,2) + '/' + Copystr(Dat,6,2) + '/' + Copystr(Dat,1,4)) then;
                                    end;
                                    OrdHdr[2]."Shopify Order Currency" := OrdHdr[1]."Shopify Order Currency";
                                    JsToken[1].SelectToken('transactions',JsToken[2]);
                                    JsArry[2] := JsToken[2].AsArray();
                                    If JsArry[2].Count > 0  then
                                    begin
                                        JsArry[2].get(0,JsToken[1]);
                                        if JsToken[1].SelectToken('gateway',Jstoken[2]) then
                                            If not Jstoken[2].AsValue().IsNull then
                                                OrdHdr[2]."Payment Gate Way" := CopyStr(JsToken[2].AsValue().AsText(),1,25);
                                        if JsToken[1].SelectToken('processed_at',JsToken[2]) then
                                            If not Jstoken[2].AsValue().IsNull then
                                                If Evaluate(OrdHdr[2]."Processed Date",CopyStr(JsToken[2].AsValue().AsText(),9,2) + '/' + 
                                                                    CopyStr(JsToken[2].AsValue().AsText(),6,2) + '/' +
                                                                    CopyStr(JsToken[2].AsValue().AsText(),1,4) + '/' ) then
                                                begin                
                                                    OrdHdr[2]."Processed Time" := CopyStr(JsToken[2].AsValue().AsText(),12,8);
                                                    if not Evaluate(OrdHdr[2]."Proc Time",OrdHdr[2]."Processed Time") then
                                                        OrdHdr[2]."Proc Time" := 0T;
                                                end; 
                                        if JsToken[1].SelectToken('source_name',JsToken[2]) then
                                            If not Jstoken[2].AsValue().IsNull then
                                                OrdHdr[2]."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);    
                                        if JsToken[1].SelectToken('receipt',JsToken[2]) then
                                        begin
                                            If JsToken[2].SelectToken('transaction_id',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                    OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                            end        
                                            else if JsToken[2].SelectToken('payment_id',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                    OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                            end        
                                            else if JsToken[2].SelectToken('x_reference',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                    OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                            end
                                            else if JsToken[2].SelectToken('token',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                    OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                            end
                                            else if JsToken[2].SelectToken('gift_card_id',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                begin
                                                    OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25);
                                                    If JsToken[1].SelectToken('amount',JsToken[3]) then
                                                        If not Jstoken[3].AsValue().IsNull then
                                                            Ordhdr[2]."Gift Card Total" := JsToken[3].AsValue().AsDecimal();
                                                end;
                                            end;
                                        end;                    
                                    end;
                                    If OrdHdr[2]."Reference No" = '' then
                                    begin
                                        Clear(Data);
                                        Clear(Parms);
                                        Parms.Add('fields','note,source_name');
                                        if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr[2]."Shopify Order ID") + '.json'
                                                                ,Parms,PayLoad,Data) then
                                        begin
                                            If Data.Get('order',JsToken[1]) then
                                            begin
                                                If JsToken[1].SelectToken('source_name',JsToken[2]) then
                                                    If not Jstoken[2].AsValue().IsNull then
                                                        If JsToken[2].AsValue().AsText().ToUpper().Contains('MARKET') then
                                                        begin
                                                            If JsToken[1].SelectToken('note',JsToken[2]) then
                                                                If not Jstoken[2].AsValue().IsNull then
                                                                begin
                                                                    OrdHdr[2]."Reference No" := CopyStr(Extract_MarketPlace_Invoice_Number(JsToken[2].AsValue().AsText()),1,25);
                                                                    OrdHdr[2]."Payment Gate Way" := 'market_place';
                                                                end;
                                                        end 
                                                        else
                                                            OrdHdr[2]."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);            
                                            end;
                                        end; 
                                    end;
                                    RecCnt += 1;
                                    Ordhdr[2].Modify(False);
                                end;
                            end;
                            If OrdExist then
                            begin        
                                JsArry[1].Get(i,JsToken[2]);
                                JsToken[2].SelectToken('refund_line_items',JsToken[1]);
                                Jsarry[2] := JsToken[1].AsArray();
                                If JsArry[2].Count > 0 then Clear(TransAmount[1]);
                                For j := 0 to JsArry[2].Count - 1 do
                                begin
                                    JsArry[2].get(j,JsToken[2]);
                                    Clear(RefQty);
                                    if JsToken[2].Asobject.AsToken.SelectToken('quantity',JsToken[1]) then
                                        if not Jstoken[1].AsValue().IsNull then
                                            RefQty :=  jstoken[1].AsValue().AsDecimal();
                                    If JsToken[2].SelectToken('line_item',Jstoken[1]) then
                                    begin
                                        OrdLine.init;
                                        Clear(OrdLine.ID);
                                        Ordline.insert;
                                        Ordline."Shopify Order ID" := OrdHdr[2]."Shopify Order ID";
                                        OrdLine.ShopifyID := Ordhdr[2].ID;
                                        Ordline."Order Line No" := (j + 1) * 10;
                                        if JsToken[1].Asobject.AsToken.SelectToken('id',JsToken[2]) Then
                                        begin
                                            if not Jstoken[2].AsValue().IsNull then
                                            Begin    
                                                OrdLine."Order Line ID" := JsToken[2].AsValue().AsBigInteger();
                                                If JsToken[1].Asobject.AsToken.SelectToken('sku',JsToken[2]) then
                                                begin
                                                    If Not JsToken[2].AsValue().IsNull then
                                                    begin
                                                        Ordline."Item No." := jstoken[2].AsValue().AsCode();
                                                        OrdLine."Order Qty" := RefQty;
                                                        If JsToken[1].Asobject.AsToken.SelectToken('gift_card',JsToken[2]) then
                                                            if not Jstoken[2].AsValue().IsNull then
                                                                if JsToken[2].AsValue().AsBoolean() then
                                                                    Ordline."Item No." := 'GIFT_CARD';
                                                        OrdLine."Location Code" := 'QC';
                                                        OrdLine."FulFilo Shipment Qty" := OrdLine."Order Qty";
                                                        Clear(OrigQty);            
                                                        if JsToken[1].Asobject.AsToken.SelectToken('quantity',JsToken[2]) then
                                                            if not Jstoken[2].AsValue().IsNull then
                                                                OrigQty := jstoken[2].AsValue().AsDecimal();
                                                        if JsToken[1].Asobject.AsToken.SelectToken('price',JsToken[2]) then
                                                            if not Jstoken[2].AsValue().IsNull then
                                                                Ordline."Unit Price" :=  jstoken[2].AsValue().AsDecimal();
                                                        if JsToken[1].Asobject.AsToken.SelectToken('total_discount',JsToken[2]) then
                                                            if not Jstoken[2].AsValue().IsNull then
                                                                Ordline."Discount Amount" := jstoken[2].AsValue().AsDecimal();
                                                        Ordline."Shopify Application Index" := -1;
                                                        if JsToken[1].Asobject.AsToken.SelectToken('discount_allocations',JsToken[2]) then
                                                        begin
                                                            If JsToken[2].AsArray().Count > 0 then
                                                            begin
                                                                Jstoken[2].AsArray().get(0,Jstoken[3]);
                                                                if jstoken[3].SelectToken('discount_application_index',JsToken[2]) then
                                                                    if not Jstoken[2].AsValue().IsNull then
                                                                        Ordline."Shopify Application Index" := JsToken[2].AsValue().AsInteger();
                                                                if jstoken[3].SelectToken('amount',JsToken[2]) then
                                                                    if not Jstoken[2].AsValue().IsNull then
                                                                        Ordline."Discount Amount" := jstoken[2].AsValue().AsDecimal(); 
                                                            end;    
                                                        end;
                                                        If OrigQty > 0 then
                                                        begin
                                                            If Ordline."Discount Amount" > 0 then
                                                                Ordline."Discount Amount" := (Ordline."Discount Amount" * OrdLine."Order Qty")/OrigQty;  
                                                            Clear(Ordline."Tax Amount");
                                                            If JsToken[1].Asobject.AsToken.SelectToken('tax_lines',JsToken[2]) then
                                                            begin
                                                                If JsToken[2].AsArray().Count > 0 then
                                                                begin
                                                                    Jstoken[2].AsArray().get(0,Jstoken[3]);
                                                                    if jstoken[3].SelectToken('price',JsToken[2]) then
                                                                        if not Jstoken[2].AsValue().IsNull then
                                                                            Ordline."Tax Amount" := jstoken[2].AsValue().AsDecimal();
                                                                end;    
                                                            end;
                                                            If Ordline."Tax Amount" > 0 then
                                                                Ordline."Tax Amount" := (Ordline."Tax Amount" * OrdLine."Order Qty")/OrigQty;  
                                                            Ordline."Base Amount" := Ordline."Order Qty" * Ordline."Unit Price";
                                                            If Item.Get(Ordline."Item No.") then
                                                            Begin
                                                                OrdLine."Unit Of Measure" := Item."Base Unit of Measure";
                                                                Ordline.modify(False);
                                                            end    
                                                            else
                                                                OrdLine.Delete();
                                                        end
                                                        else
                                                            OrdLine.delete;            
                                                    end
                                                    else
                                                        OrdLine.Delete();
                                                end
                                                else
                                                    OrdLine.Delete();
                                            end
                                            else
                                                OrdLine.Delete();
                                        end
                                        else
                                            OrdLine.Delete();
                                    end;
                                end;
                                //see if this is a refund with no items involved
                                If TransAmount[1] > 0 then
                                begin
                                    OrdLine.reset;
                                    OrdLine.Setrange(ShopifyID,OrdHdr[2].ID);
                                    j:= 10;
                                    If OrdLine.findlast then j += OrdLine."Order Line No"; 
                                    OrdLine.init;
                                    Clear(OrdLine.ID);
                                    Ordline.insert;
                                    Ordline."Shopify Order ID" := OrdHdr[2]."Shopify Order ID";
                                    OrdLine.ShopifyID := Ordhdr[2].ID;
                                    Ordline."Order Line No" := j;
                                    Ordline."Item No." := 'NON_REFUND_ITEM';
                                    OrdLine."Location Code" := 'QC';
                                    Item.Get(Ordline."Item No.");
                                    OrdLine."Unit Of Measure" := Item."Base Unit of Measure";
                                    OrdLine."Order Qty" := 1;
                                    OrdLine."Unit Price" := TransAmount[1];
                                    Ordline."FulFilo Shipment Qty" := 1;
                                    Ordline."Shopify Application Index" := -1;
                                    OrdLine."Discount Amount" := 0;
                                    OrdLine."Tax Amount" := 0;
                                    Ordline."Base Amount" := Ordline."Order Qty" * Ordline."Unit Price";
                                    OrdLine.modify(false);
                                end;    
                                Commit;
                            end;
                        end;
                        if OrdExist then
                        begin        
                            OrdLine.reset;
                            OrdLine.Setrange(ShopifyID,OrdHdr[2].ID);
                            If OrdLine.findset then
                            begin
                                OrdLine.CalcSums("Base Amount","Discount Amount","Tax Amount");
                                OrdHdr[2]."Tax Total" := OrdLine."Tax Amount";
                                OrdHdr[2]."Discount Total" := OrdLine."Discount Amount";
                                OrdHdr[2]."Order Total" := OrdLine."Base Amount" - OrdLine."Discount Amount";
                                //If TransAmount[2] <> OrdHdr[2]."Order Total" then 
                                //    OrdHdr[2]."Order Total" := TransAmount[2];    
                                OrdHdr[2].Modify(False);
                            end
                            else
                            begin
                                OrdHdr[2].Delete(True);
                                RecCnt -=1;
                            end;
                        end;
                    end;
                end;    
                OrdHdr[1]."Refunds Checked" := True;
                OrdHdr[1].Modify(false);
                If RecCnt > 50 then
                begin
                    Clear(RecCnt);
                    Commit;
                end;          
            until OrdHdr[1].next = 0;
        if GuiAllowed then Win.Close;
        Commit;
        If RefundID <> 0 then Check_For_Extra_Refunds(RefundID); 
    end; 
    procedure Check_For_Extra_Refunds(RefundID:BigInteger)
    var
        OrdHdr:array[2] of record "PC Shopify Order Header";
        OrdLine:record "PC Shopify Order Lines";
        Recon:Array[2] of record "PC Order Reconciliations";
        JsToken:array[2] of JsonToken;
        JsArry:array[2] of JsonArray;
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        i,j:integer;
        RefiD:BigInteger;
        ReFTot:Decimal;
        Item:Record Item;
        Win:Dialog;
        Setup:Record "Sales & Receivables Setup";
    Begin
        Setup.Get;
        If Setup."Ext Refund Order Lookback Per" = 0 then
        begin
            Setup."Ext Refund Order Lookback Per" := 3;
            Setup.Modify(False);
            Commit;
        end;
        Clear(PayLoad);
        Clear(Parms);
        Parms.Add('fields','refunds');
        Clear(Data);
        if GuiAllowed then win.Open('Retrieving Order No    #1###########\'
                                   +'Processing Order No    #2###########\'
                                   +'Adding Refund Order No #3############');
        OrdHdr[1].Reset;
        OrdHdr[1].SetCurrentKey("Shopify Order No.");
        OrdHdr[1].Setrange("Order Status",OrdHdr[1]."Order Status"::Closed);
        OrdHdr[1].SetFilter("BC Reference No.",'<>%1','');
        OrdHdr[1].Setrange("Order Type",OrdHdr[1]."Order Type"::Invoice);
        If RefundID <> 0 then
            OrdHdr[1].SetRange("Shopify Order No.",RefundID)
        else    
            OrdHdr[1].SetFilter("Shopify Order Date",'>=%1',CalcDate('-' + Format(Setup."Ext Refund Order Lookback Per") + 'M',Today));
        OrdHdr[1].Setrange("Refunds Checked",True);
        If OrdHdr[1].Findset then
        repeat
            if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr[1]."Shopify Order ID") + '.json'
                                                ,Parms,PayLoad,Data) then
            Begin
                If GuiAllowed then Win.Update(1,OrdHdr[1]."Shopify Order No.");
                Clear(RefTot);
                Data.Get('order',JsToken[1]);
                If JsToken[1].SelectToken('refunds',JsToken[2]) then
                Begin
                    JsArry[1] := JsToken[2].AsArray();
                    If JsArry[1].Count > 0 then
                        For i := 0 to JsArry[1].Count - 1 do
                        begin
                            JsArry[1].get(i,JsToken[1]);
                            JsToken[1].SelectToken('transactions',JsToken[2]);
                            JsArry[2] := JsToken[2].AsArray();
                            For j := 0 to JsArry[2].Count - 1 do
                            begin
                                JsArry[2].get(j,JsToken[1]);
                                if JsToken[1].SelectToken('amount',Jstoken[2]) then
                                    If not Jstoken[2].AsValue().IsNull then
                                        RefTot += Jstoken[2].AsValue().AsDecimal();
                            end;
                        end;
                    If ReFTot > 0 then
                    begin
                        Recon[1].Reset;
                        Recon[1].Setrange("Shopify Display ID",OrdHdr[1]."Shopify Order ID");
                        Recon[1].Setrange("Shopify Order Type",Recon[1]."Shopify Order Type"::Refund);
                        If Recon[1].FindSet() then
                        Begin
                            Recon[1].CalcSums("Order Total");
                            If RefTot > Recon[1]."Order Total" then
                            begin
                                If GuiAllowed then Win.Update(2,OrdHdr[1]."Shopify Order No.");
                                Recon[2].Copy(Recon[1]);
                                Get_Order_Reconciliation_Transactions(Recon[2]);            
                                Clear(Recon[2]."Apply Status");
                                Recon[2]."Order Total" := RefTot - Recon[1]."Order Total";
                                Clear(Recon[2]."Extra Refund Count");
                                While Recon[1].Get(Recon[2]."Shopify Order ID",Recon[2]."Shopify Order Type") do
                                Begin
                                    Recon[2]."Shopify Order ID" += 1;
                                    Recon[2]."Extra Refund Count" +=1;
                                end;    
                                Recon[2].Insert;
                                For RefiD := OrdHdr[1]."Shopify Order ID" to Recon[2]."Shopify Order ID" - 1 do
                                begin
                                    OrdHdr[2].reset;
                                    OrdHdr[2].Setrange("Shopify Order ID",RefID);
                                    OrdHdr[2].Setrange("Order Type",OrdHdr[2]."Order Type"::CreditMemo);
                                    If OrdHdr[2].FindSet() then
                                    begin
                                        OrdLine.Reset;
                                        OrdLine.Setrange(ShopifyID,OrdHdr[2].ID);
                                        If OrdLine.Findset then
                                        Begin
                                            OrdLine.CalcSums("Base Amount","Discount Amount");
                                            ReFTot -= (OrdLine."Base Amount" + OrdHdr[2]."Freight Total" - OrdLine."Discount Amount");
                                            Recon[2]."Refund Shopify ID" := OrdHdr[2]."Shopify Order ID";
                                        End;
                                    end;    
                                end;
                                If ReFTot = 0 then
                                    Recon[2].Modify()
                                else
                                begin
                                    If GuiAllowed then Win.Update(3,OrdHdr[1]."Shopify Order No.");
                                    OrdHdr[2].Init;
                                    Clear(OrdHdr[2].ID);
                                    OrdHdr[2].Insert();
                                    OrdHdr[2]."Shopify Order ID" := Recon[2]."Shopify Order ID";
                                    OrdHdr[2]."Order Type" := OrdHdr[2]."Order Type"::CreditMemo;
                                    OrdHdr[2]."Shopify Order Date" := OrdHdr[1]."Shopify Order Date";
                                    OrdHdr[2]."Transaction Date" := Today;
                                    OrdHdr[2]."Shopify Order No." := OrdHdr[1]."Shopify Order No.";
                                    OrdHdr[2]."Fulfilo Shipment Status" := OrdHdr[2]."Fulfilo Shipment Status"::Complete;
                                    OrdHdr[2]."Shopify Order Currency" := OrdHdr[1]."Shopify Order Currency";
                                    OrdHdr[2]."Order Total" := RefTot;
                                    OrdHdr[2]."Shopify Order Status" := 'FULFILLED';
                                    OrdHdr[2].Modify(False);
                                    OrdLine.Init();
                                    Clear(OrdLine.ID);
                                    OrdLine.insert;
                                    OrdLine."Shopify Order ID" := OrdHdr[2]."Shopify Order ID";
                                    OrdLine.ShopifyID := Ordhdr[2].ID;
                                    Ordline."Order Line No" := 10;
                                    Ordline."Item No." := 'NON_REFUND_ITEM';
                                    OrdLine."Location Code" := 'QC';
                                    Item.Get(Ordline."Item No.");
                                    OrdLine."Unit Of Measure" := Item."Base Unit of Measure";
                                    OrdLine."Order Qty" := 1;
                                    OrdLine."Unit Price" := ReFTot;
                                    Ordline."FulFilo Shipment Qty" := 1;
                                    Ordline."Shopify Application Index" := -1;
                                    OrdLine."Discount Amount" := 0;
                                    OrdLine."Tax Amount" := 0;
                                    Ordline."Base Amount" := Ordline."Order Qty" * Ordline."Unit Price";
                                    OrdLine.modify(false);
                                    // Here we align existing Recon entries that don't have 
                                    // a return order in place with the created return order
                                    Recon[1].Reset;
                                    Recon[1].Setrange("Shopify Display ID",OrdHdr[1]."Shopify Order ID");
                                    Recon[1].Setrange("Shopify Order Type",Recon[1]."Shopify Order Type"::Refund);
                                    Recon[1].Setrange("Refund Shopify ID",0);
                                    Recon[1].Setrange("Extra Refund Count",0);
                                    If Recon[1].Findset then
                                    repeat
                                        OrdHdr[2].reset;
                                        OrdHdr[2].Setrange("Shopify Order ID",Recon[1]."Shopify Order ID");
                                        OrdHdr[2].Setrange("Order Type",OrdHdr[2]."Order Type"::CreditMemo);
                                        If Not OrdHdr[2].Findset then
                                        begin
                                            Recon[1]."Refund Shopify ID" := OrdHdr[2]."Shopify Order ID";
                                            Recon[1].Modify();
                                        end;
                                    until Recon[1].next = 0;    
                                end;
                                Commit;
                            end;
                        end;
                    End
                    else If GuiAllowed then
                    Begin 
                        Win.Update(2,'');
                        Win.Update(3,'');
                    end;    
                end;
            end;        
        Until Ordhdr[1].next = 0;
        If GuiAllowed then Win.CLose;
    End;
    local Procedure Extract_MarketPlace_Invoice_Number(Val:text):text
    var
        Retval:text;
        i:integer; 
    Begin
        Clear(retval);
        For i:= 1 to StrLen(val) do
            if (Val[i] >= '0') and (Val[i] <= '9') then
                retval += Val[i];
        exit(retval);
    End;
    procedure Send_Email_Msg(Subject:text;Body:text;Recip:text):Boolean;
    var
        //EM:Codeunit "SMTP Mail";
        EM:Codeunit "Email Message";
        Emailer:Codeunit Email;    
    begin
        /*
        Setup.get;
        Clear(Recip);
        If ExRecip <> '' then 
            Recip := ExRecip
        else
        begin    
            if Mode then
                Recip := Setup."Exception Email Address"
            else
                Recip := Setup."EDI Exception Email Address";
        end;*/                 
        If Recip.Contains('@') then
        begin
            EM.Create(Recip,Subject,Body);
            Exit(Emailer.Send(EM,Enum::"Email Scenario"::Default));
        end;
        exit(false);
    end;
    [TryFunction]
    procedure Send_PO_Email(PurchHdr:record "Purchase Header");
    var
        Ven:record Vendor;
        CustRepSel:Record "Custom Report Selection";
        CustRep:Record "Custom Report Layout";
        PurchHdrloc:Record "Purchase Header"; 
        ReportLayoutSelection: Record "Report Layout Selection";
        DocSendProf:record "Document Sending Profile";
    begin
        DocSendProf.Reset;
        DocSendProf.Setrange(Code,'PC PURCH');
        If not DocSendProf.Findset then
        begin
            DocSendProf.Init;
            DocSendProf.Validate(Code,'PC PURCH');
            DocSendProf.Description := 'PC Purchase Doc Profile';               
            DocSendProf.Validate(Printer,DocSendProf.Printer::No);
            DocSendProf.Validate("E-Mail",DocSendProf."E-Mail"::"Yes (Prompt for Settings)");
            DocSendProf.validate("E-Mail Attachment",DocSendProf."E-Mail Attachment"::PDF);
            DocSendProf.Validate(Disk,DocSendProf.Disk::No);
            DocSendProf.validate("Electronic Document",DocSendProf."Electronic Document"::No);
            DocSendProf.Validate(Default,False);
            DocSendProf.Insert();
        end;    
        ven.Get(PurchHdr."Buy-from Vendor No.");
        If Ven."Document Sending Profile" = '' then
        begin
            Ven."Document Sending Profile" := DocSendProf.Code;
            Ven.Modify(False);
            Commit;
        end;    
        If Ven."Operations E-Mail".Contains('@') then
        begin
            CustRep.Reset;
            CustRep.Setrange("Report ID",80001);
            CustRep.Setrange("Built-In",False);
            CustRep.Setrange(Type,CustRep.Type::Word);
            CustRep.Setfilter(Description,'PC NSW*');
            If PurchHdr."Location Code" = 'VIC' then
                CustRep.Setfilter(Description,'PC VIC*');
            If Not CustRep.Findset then
                Error('Custom Report Layout 80001 is not defined');
            CustRepSel.reset;
            CustRepSel.Setrange("Source Type",Database::Vendor);
            CustRepSel.Setrange("Source No.",PurchHdr."Buy-from Vendor No.");
            CustRepSel.Setrange(Usage,CustRepSel.Usage::"P.Order");
            If CustRepSel.Findset then CustRepSel.DeleteAll(true);
            CustRepSel.Init;
            CustRepSel.Validate("Source Type",Database::Vendor);
            CustRepSel.Validate("Source No.",PurchHdr."Buy-from Vendor No.");
            CustRepSel.Validate(Usage,CustRepSel.Usage::"P.Order");
            CustRepSel.Validate(Sequence,1);
            CustRepSel.Validate("Report ID",80001);
            CustRepSel.Insert(true);
            CustRepSel.Validate("Use for Email Attachment",true);
            CustRepSel.Validate("Use for Email Body",true);
            CustRepSel.validate("Email Body Layout Code",CustRep.Code);
            CustRepSel."Send To Email"  := Ven."Operations E-Mail";
            CustRepSel.Modify();
            Commit;
            PurchHdrloc.Reset();
            PurchHdrloc.Setrange("Document Type",PurchHdr."Document Type");
            PurchHdrloc.Setrange("No.",PurchHdr."No.");
            PurchHdrloc.findset;
            PurchHdrloc.SendRecords();
            Clear(Ven."Document Sending Profile");
            Ven.Modify(False);
            Commit;
        end
        else
            Error('Operation Email %1 is invalid email Address',Ven."Operations E-Mail");
    end;
    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnSendVendorRecordsOnBeforeLookupProfile', '', true, true)]
    local procedure "Document Sending Profile_OnSendVendorRecordsOnBeforeLookupProfile"
    (
        ReportUsage: Integer;
		RecordVariant: Variant;
		VendorNo: Code[20];
		var RecRefToSend: RecordRef;
		SingleVendorSelected: Boolean;
		var ShowDialog: Boolean
    )
    begin
        ShowDialog := false;
    end;

/*
    procedure Send_PO_Email(PurchHdr:record "Purchase Header"):Boolean;
    var
        Ven:record Vendor;
        TmpBlob:Codeunit "Temp Blob";
        OutStrm:OutStream;
        InStrm:InStream;
        RecRef:RecordRef;
        FldRef:FieldRef;
        Doc:Codeunit "Document-Mailing";
        Body:Text;
        CRLF:Text;
        Setup:record "Sales & Receivables Setup";
        Flg:Boolean;
    begin
        Setup.get;
        RecRef.Open(Database::"Purchase Header");
        Fldref := RecRef.Field(purchHdr.FieldNo("Document Type"));
        FldRef.Setrange(PurchHdr."Document Type");
        FldRef := RecRef.Field(PurchHdr.FieldNo("No."));
        FldRef.SetRange(PurchHdr."No.");
        TmpBlob.CreateOutStream(OutStrm);
        If Report.SaveAs(405,'',ReportFormat::Pdf,OutStrm,RecRef) then
        begin
            CRLF := '<BR>';
            TmpBlob.CreateInStream(InStrm);
            Ven.Get(PurchHdr."Buy-from Vendor No.");
            Body := 'Hi,' + CRLF + CRLF;
            Body += 'Please see attached PO for Syd DC.' + CRLF + CRLF;
            Body += PurchHdr."No." + ' ASN:' + PurchHdr."Fulfilo External Id" + ' - WH:' 
                    + PurchHdr."Location Code" + ' - Requested Delivery Date:' + Format(PurchHdr."Requested Receipt Date") + CRLF + CRLF;
            Body += 'To arrange a delivery time slot,please contact the relevant DC via email to confirm date and time of delivery.' + CRLF + CRLF;
            Body += 'In the email please include the PetCulture ASN number to make the booking.' + CRLF + CRLF;
            Body += 'When arranging delivery in NSW,please email:' + CRLF;
            Body += 'Sydney DC:When arranging delivery,please email Sydney3pl@fulfilio.com.au and operations@petculture.com.au' + CRLF + CRLF;
            Body += 'Remember to label your shipment with PetCulture PO & ASN.' + CRLF + CRLF;
            Body += 'If you have any questions, please don''t hesitate to contact us.' + CRLF + CRLF;
            Body += 'Thanks,' + CRLF;
            Body += 'Luken' + CRLF + CRLF;
            Body += 'PetCulture Sales & Operations.' + CRLF + 'www.petculture.com.au';
            Flg := Doc.EmailFileFromStream(InStrm,PurchHdr."No." + '.pdf',Body,Ven.Name.Replace('-','') + ' - ' + PurchHdr."No." + ' - ' + PurchHdr."Location Code"
                    ,Ven."Operations E-Mail",True,-1);
            If Flg and (Setup."PO CC email Address" <> '') then        
                Flg := Doc.EmailFileFromStream(InStrm,PurchHdr."No." + '.pdf',Body,Ven.Name.Replace('-','') + ' - ' + PurchHdr."No." + ' - ' + PurchHdr."Location Code"
                        ,Setup."PO CC email Address",True,-1);
            exit(Flg);    
        end;            
        exit(false);
    end;
  
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeEmailFileInternal', '', true, true)]
    local procedure "Document-Mailing_OnBeforeEmailFileInternal"
    (
        var TempEmailItem: Record "Email Item";
		var HtmlBodyFilePath: Text[250];
		var EmailSubject: Text[250];
		var ToEmailAddress: Text[250];
		var PostedDocNo: Code[20];
		var EmailDocName: Text[250];
		var HideDialog: Boolean;
		var ReportUsage: Integer;
		var IsFromPostedDoc: Boolean;
		var SenderUserID: Code[50];
		var EmailScenario: Enum "Email Scenario"
    )
    var
        Flds:list of [text]; 
        PurHdr:record "Purchase Header";
        Flg:boolean;
    begin
        Flds := EmailSubject.Split(' - ');
        If Flds.Count > 1 then
            If PurHdr.Get(PurHdr."Document Type"::Order,Flds.Get(2)) then
                EmailScenario := Enum::"Email Scenario"::"Purchase Order";

    end;*/
    procedure Get_Dim_Set_Id(Member:Code[20];OrdType:Code[20];Item:Code[20]):Integer
    var
        DimSet:record "Dimension Set Entry" temporary;
        DimVal:record "Dimension Value";
        Defdim:record "Default Dimension";
        DimMgt:Codeunit DimensionManagement;
    begin
        if DefDim.Get(DataBase::Item,Item,'DEPARTMENT') then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'DEPARTMENT');
            DimSet.validate("Dimension Value Code",Defdim."Dimension Value Code");
            DimSet.insert;
        end;
       if DefDim.Get(DataBase::Item,Item,'CATEGORY') then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'CATEGORY');
            DimSet.validate("Dimension Value Code",Defdim."Dimension Value Code");
            DimSet.insert;
        end;
        if DefDim.Get(DataBase::Item,Item,'SUB-CATEGORY') then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'SUB-CATEGORY');
            DimSet.validate("Dimension Value Code",Defdim."Dimension Value Code");
            DimSet.insert;
        end;
        if DefDim.Get(DataBase::Item,Item,'BRAND') then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'BRAND');
            DimSet.validate("Dimension Value Code",Defdim."Dimension Value Code");
            DimSet.insert;
        end;
        If DimVal.Get('CUSTOMER TYPE',Member) then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'CUSTOMER TYPE');
            DimSet.validate("Dimension Value Code",Member);
            DimSet.insert;
            DimSet.init;
            DimSet.Validate("Dimension Code",'ORDER TYPE');
            DimSet.validate("Dimension Value Code",OrdType);
            Dimset.insert;
            Exit(DimMgt.GetDimensionSetID(DimSet));
        end;
        Exit(0);   
    end;
    local procedure Clear_QC_Stock()
    var
        Item:Record Item;
        Cu:Codeunit "PC Fulfilio Routines";
    begin
        Item.Reset;
        Item.Setrange(Type,Item.Type::Inventory);
        Item.Setrange("Location Filter",'QC');
        If Item.findSet then
        repeat
            Item.CalcFields(Inventory);
            If Item.Inventory <> 0 then Cu.Adjust_QC_Inventory(Item,-Item.Inventory);
        until Item.next = 0;
    end;
    procedure Credit_Correction(ID:BigInteger)
    var
        SinvLine:Record "Sales Invoice Line";
        SalesHdr:Record "Sales Header";
        SalesLine:record "Sales Line";
        Cu:Codeunit "Sales-Post";
        PCHdr:Record "PC Shopify Order Header";
        lineNo:Integer;
        CuRel:Codeunit "Release Sales Document";
    begin
        SinvLine.reset;
        SinvLine.Setrange("Shopify Order ID",ID);
        If SinvLine.Findset then
        begin
            Clear(lineNo);
            SalesHdr.Init();
            SalesHdr.validate("Document Type",SalesHdr."Document Type"::"Credit Memo");
            SalesHdr.Validate("Sell-to Customer No.",'PETCULTURE');
            SalesHdr.validate("Prices Including VAT",True);
            SalesHdr."Your Reference" := 'SHOPIFY CORRECTION';
            SalesHdr."Reason Code" := 'CUSTRETURN';
            SalesHdr.Insert(true);
            repeat
                lineNo += 10;
                Clear(SalesLine);
                SalesLine.init;
                SalesLine.Validate("Document Type",SalesHdr."Document Type");
                SalesLine.Validate("Document No.",SalesHdr."No.");
                SalesLine."Line No." := lineNo;
                SalesLine.insert(true);
                SalesLine.Validate(Type,SalesLine.Type::Item);
                SalesLine.validate("No.",SinvLine."No.");
                SalesLine.Validate("Location Code",Sinvline."Location Code");
                SalesLine.Validate("VAT Prod. Posting Group",SinvLine."VAT Prod. Posting Group");
                SalesLine.Validate("Unit of Measure Code",Sinvline."Unit of measure code");
                SalesLine.Validate(Quantity,SinvLine.Quantity);
                Salesline.Validate("Unit Price",SinvLine."Unit Price");
                Salesline.Validate("Line Discount Amount",SinvLine."Line Discount Amount");
                Salesline."Shopify Order ID" := ID;
                SalesLine.Modify(true);
                // here we establish the 
            until SinvLine.next = 0;
            Commit;
            if CuRel.Run(SalesHdr) then 
                If CU.Run(SalesHdr) then
                begin
                    PCHdr.Reset();
                    PCHdr.Setrange("Shopify Order ID",ID);
                    If PCHdr.findset then
                    begin
                        Clear(PCHdr."BC Reference No.");
                        Clear(PCHdr."Order Status");
                        PCHdr.modify(false);
                        Process_Orders(true,ID);
                        Commit;
                        PchDr.FindSet();
                        Message('Order No %1 has been corrected',PCHdr."BC Reference No.");
                    end;
                 end;
            end;     
    end;
    local procedure Add_Rebate_Entries(var SLine:record "Sales Line";var Lineno:Integer;Var RebateTot:Array[2] of Decimal;var RDesc:array[2] of Code[20])
    var
        CmpReb:Record "PC Campaign Rebates";
        CmpSku:record "PC Campaign SKU New";
        SalesLine:Record "Sales Line";
        i:Integer;
        RunFlg:Boolean;
        GLSetup:Record "General Ledger Setup";
        PurchCst:record "PC Purchase Pricing";
    begin
        GLSetup.get;
        For i := 1 to 2 do
        begin
            CmpReb.reset;
            Clear(RunFlg);
            Case i Of 
                1:
                begin
                    CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::Campaign);
                    CmpReb.SetFilter("Campaign Start Date",'>%1&<=%2',0D,SLine."Shopify Order Date");
                    CmpReb.SetFilter("Campaign End Date",'>=%1',SLine."Shopify Order Date");
                    RunFlg := True;
                end;
                2:
                begin
                    CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::"Auto Delivery");
                    RunFlg := Sline."Auto Delivered";
                end;    
            end;
            If RunFlg then
                If CmpReb.findset then
                repeat
                    CmpSku.Reset;
                    CmpSku.Setrange("Rebate Supplier No.",CmpReb."Rebate Supplier No.");
                    CmpSku.Setrange(Campaign,CmpReb.Campaign);
                    CmpSku.Setrange(SKU,SLine."No.");
                    CmpSku.SetFilter("Rebate Amount",'>0');
                    If CmpSku.findset then
                    begin
                        PurchCst.Reset;
                        PurchCst.SetCurrentKey("End Date");
                        PurchCst.SetAscending("End Date",false);
                        PurchCst.Setrange("Item No.",CmpSku.SKU);
                        PurchCst.Setrange("Supplier Code",SLine."Rebate Supplier No.");
                        PurchCst.SetFilter("Start Date",'<=%1',SLine."Shopify Order Date");
                        PurchCst.Setfilter("End Date",'%1|>=%2',0D,SLine."Shopify Order Date");
                        If PurchCst.Findset then
                        begin
                            LineNo += 10;
                            Clear(SalesLine);
                            SalesLine.init;
                            SalesLine.Validate("Document Type",SLine."Document Type");
                            SalesLine.Validate("Document No.",SLine."Document No.");
                            SalesLine."Line No." := LineNo;
                            Salesline.insert(true);
                            SalesLine.Validate(Type,SalesLine.Type::"G/L Account");
                            // Rebate Amount entered as a percentage now
                            If i = 1 then
                            begin
                                SalesLine.validate("No.",GLSetup."Campaign Rebate Posting Acc");
                                SalesLine.Description := 'Campaign Rebate ' + CmpReb.Campaign;
                                SLine."Campaign Rebate" := True;
                                SLine."Campaign Rebate Supplier" := CmpReb."Rebate Supplier No.";
                                SLine."Campaign Rebate Amount" := ((PurchCst."Unit Cost" * CmpSku."Rebate Amount")/100) * SLine.Quantity;
                                Sline."Campaign Rebate Code"  := CmpReb.Campaign;
                                Sline."Campaign Rebate %" := CmpSku."Rebate Amount";
                            end    
                            else
                            begin
                                SalesLine.validate("No.",Glsetup."Auto Order Rebate Posting Acc");
                                SalesLine.Description := 'Auto Delivery Rebate ' + CmpReb.Campaign;
                                SLine."Auto Delivery Rebate Supplier" := CmpReb."Rebate Supplier No.";
                                Sline."Auto Delivery Rebate Amount" := ((PurchCst."Unit Cost" * CmpSku."Rebate Amount")/100) * SLine.Quantity;
                                Sline."Auto Delivery Rebate Code" := CmpReb.Campaign;
                                Sline."Auto Delivery Rebate %" := CmpSku."Rebate Amount";
                            end;    
                            SalesLine.Validate(Quantity,SLine.Quantity);
                            Salesline.Validate("Unit Price",(PurchCst."Unit Cost" * CmpSku."Rebate Amount")/100);
                            RebateTot[i] += ((PurchCst."Unit Cost" * CmpSku."Rebate Amount")/100) * SLine.Quantity;
                            RDesc[i] := CmpReb.Campaign;
                            Salesline."Shopify Order ID" := SLine."Shopify Order ID";
                            SalesLine."Shopify Order Date" := Sline."Shopify Order Date";
                            SalesLine."Rebate Supplier No." := CmpReb."Rebate Supplier No.";
                            SalesLine.Modify(true);
                        end;
                    end;    
                Until CmpReb.next = 0;
        end;
    end;
    // Here is where we process all received orders
    [TryFunction]
    procedure Process_Orders(Bypass:Boolean;OrdNoID:Biginteger)
    var
        SalesHdr:record "Sales Header";
        SalesLine:Record "Sales Line";
        SalesInvHdr:record "Sales Invoice Header";
        SalesCrdHdr:Record "Sales Cr.Memo Header";
        OrdNo:Code[20];
        OrdNos:list of [Code[20]];
        OrdTypes:list of [Enum "Sales Document Type"];
        //OrdNosCnt:integer;
        Cu:Codeunit "Sales-Post";
        CuRel:Codeunit "Release Sales Document";
        PCOrdHdr:record "PC Shopify Order Header";
        PCOrdLin:record "PC Shopify Order Lines";
        Cust:Record Customer;
        LineNo:Integer;
        Item:Record Item;
        loop:Integer;
        ExFlg:Boolean;
        Res:Record "Reason Code";
        SaleDocType:Record "Sales Header";
        Loc:Record Location;
        ItemUnit:Record "Item Unit of Measure";
        unit:record "Unit of Measure";
        Result:Boolean;
        i:Decimal;
        Rindx:Integer;
        win:dialog;
        Excp:Record "PC Shopify Order Exceptions";
        Dim:record Dimension;
        Dimval:Record "Dimension Value";
        OrdType:Code[20];
        GLSetup:record "General Ledger Setup";
        PstDate:date;
        Disc:Decimal;
        ProcCnt:Integer;
        OrderCnt:Integer;
        RebateSum:Array[2] of Decimal;
        RebateDesc:array[2] of Code[20];
        RebTotaler:Array[2] of Decimal;
        Setup:record "Sales & Receivables Setup";
    begin
        If Not Res.get('CUSTRETURN') then
        begin
            Res.Init;
            Res.Code := 'CUSTRETURN';
            Res.Description := 'Customer Return';
            Res.Insert();
        end;
        If Not Unit.get('EA') then
        begin
            Unit.init;
            unit.Code := 'EA';
            Unit.Description := 'Each';
            Unit.insert;
        end;
        if Not Item.Get('SHIPPING') then
        begin
            Item.init;
            Item.validate("No.",'SHIPPING');
            Item.Insert();
            Item.Description := 'Do not remove used internally';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'FREIGHTOUT');
            Item.validate("VAT Prod. Posting Group",'GST10');
              If Not ItemUnit.get('SHIPPING','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'SHIPPING';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;    
        if Not Item.Get('GIFT_CARD_REDEEM') then
        begin
            Item.init;
            Item.validate("No.",'GIFT_CARD_REDEEM');
            Item.Insert();
            Item.Description := 'Do not remove used internally';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'VOUCHER');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            If Not ItemUnit.get('GIFT_CARD_REDEEM','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'GIFT_CARD_REDEEM';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;
        if Not Item.Get('DISCOUNTS') then
        begin
            Item.init;
            Item.validate("No.",'DISCOUNTS');
            Item.Insert();
            Item.Description := 'Do not remove used internally';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'FREIGHTOUT');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            If Not ItemUnit.get('DISCOUNTS','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'DISCOUNTS';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;
        if Not Item.Get('REBATE_REV_AUTO') then
        begin
            Item.init;
            Item.validate("No.",'REBATE_REV_AUTO');
            Item.Insert();
            Item.Description := 'Do not remove used internally';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'REBATE AUTO');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            If Not ItemUnit.get('REBATE_REV_AUTO','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'REBATE_REV_AUTO';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;
        if Not Item.Get('REBATE_REV_CAMP') then
        begin
            Item.init;
            Item.validate("No.",'REBATE_REV_CAMP');
            Item.Insert();
            Item.Description := 'Do not remove used internally';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'REBATE CAMP');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            If Not ItemUnit.get('REBATE_REV_CAMP','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'REBATE_REV_CAMP';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;
       // Location for return Orders    
        If not Loc.Get('QC') then
        begin
            loc.init;
            Loc.Code := 'QC';
            Loc."Use As In-Transit" := false;
            loc.insert;
        end;
        If Not Dim.Get('CUSTOMER TYPE') then
        begin
            Dim.Init();
            Dim.validate(Code,'CUSTOMER TYPE');
            Dim.Name := 'Customer Types';
            Dim."Code Caption" := 'Customer Types';
            Dim.insert;      
        end;
        If Not Dimval.get(Dim.Code,'GUEST') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'GUEST');
            Dimval.Name := 'Guest Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'PLATINUM') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'PLATINUM');
            Dimval.Name := 'Platimun Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'GOLD') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'GOLD');
            Dimval.Name := 'Gold Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'SILVER') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'SILVER');
            Dimval.Name := 'Silver Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'BRONZE') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'BRONZE');
            Dimval.Name := 'Bronze Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dim.Get('ORDER TYPE') then
        begin
            Dim.Init();
            Dim.validate(Code,'ORDER TYPE');
            Dim.Name := 'Order Types';
            Dim."Code Caption" := 'Order Types';
            Dim.insert;      
        end;
        If Not Dimval.get(Dim.Code,'STANDARD') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'STANDARD');
            Dimval.Name := 'Standard Order';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'AUTO ORDER') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'AUTO ORDER');
            Dimval.Name := 'Auto Order';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;
        Clear(PstDate);
        GLSetup.get;
        Setup.Get;
        If (GLSetup."Auto Order Rebate Posting Acc" = '') Or (GLSetup."Campaign Rebate Posting Acc" = '') then
            Error('Rebate posting accounts have not been defined');
        If (GLSetup."Allow Posting To" <> 0D) And (GLSetup."Allow Posting To" < Today) then
        begin
            PstDate := GLSetup."Allow Posting To";
            Clear(GLSetup."Allow Posting To");
            GLSetup.Modify(false);
        end;
        //safety to ensure all items are saleable
        Item.Reset;
        Item.Setrange(Blocked,true);
        If Item.Findset Then Item.ModifyAll(Blocked,false,false);
        Item.Reset;
        Item.Setrange("Sales Blocked",true);
        If Item.Findset Then Item.ModifyAll("Sales Blocked",false,false);
        If Not Bypass Then Result := update_Order_Locations(OrdNoID);
        If Result then Result := Cust.Get('PETCULTURE');
        if Result then
        begin
            If OrdNoID <> 0 then
            begin  
                Excp.Reset();
                Excp.Setrange(ShopifyID,OrdNoID);
                If Excp.findset then Exit; 
                PCOrdHdr.reset;
                PCOrdHdr.Setrange(ID,OrdNoID);
                If PCOrdHdr.findset then
                begin
                    PCOrdLin.Reset;
                    PCOrdlin.SetRange("ShopifyID",PCOrdHdr.ID);
                    PCOrdLin.Setfilter("Item No.",'<>%1&<>%2','','GIFT_CARD');
                    PCOrdLin.SetFilter("Order Qty",'>0');
                    If PCOrdlin.Findset then
                    begin
                        PCOrdlin.CalcSums("Order Qty","Fulfilo Shipment Qty");
                        If PCOrdlin."Order Qty" = PCOrdlin."FulFilo Shipment Qty" then 
                        begin
                            PCOrdLin.SetRange("Fulfilo Shipment Qty",0);
                            if PCOrdlin.Findset then
                            begin
                                Excp.init;
                                Clear(Excp.ID);
                                Excp.insert;
                                Excp.ShopifyID := PCOrdHdr.ID;
                                Excp.Exception := StrsubStno('Fulfilio -> Total Order Qty = Shipped Qty yet some order lines have not been shipped.. Check order lines where Shipped Qty > Order Qty'); 
                                excp.Modify();
                            end
                            else
                            begin
                                PCOrdHdr."Fulfilo Shipment Status" := PCOrdHdr."Fulfilo Shipment Status"::Complete;       
                                PCOrdHdr.Modify();
                            end;    
                        end
                        else
                        begin
                            Excp.init;
                            Clear(Excp.ID);
                            Excp.insert;
                            Excp.ShopifyID := PCOrdHdr.ID;
                            Excp.Exception := StrsubStno('FulFilio -> Order Total Qty = %1,Shipped Total Qty = %2',PCOrdlin."Order Qty", PCOrdlin."FulFilo Shipment Qty"); 
                            excp.Modify();
                            Result := False;
                        end;    
                    end;    
                end;
            end;
            If Result then
            begin
                Clear(OrdNos);
                clear(OrdTypes);
                if GuiAllowed Then Win.Open('Processing Orders #1####### of #2#########');
                For Loop := 1 to 2 do
                begin
                    Clear(OrderCnt);
                    PCOrdHdr.reset;
                    PCOrdHdr.Setrange("Order Status",PCOrdHdr."Order Status"::Open);
                    PCOrdHdr.Setrange("BC Reference No.",'');
                    If OrdNoID <> 0 then PCOrdHdr.Setrange(ID,OrdNoID);
                    if Loop = 1 then
                    begin
                        PCOrdHdr.Setrange("Fulfilo Shipment Status",PCOrdHdr."Fulfilo Shipment Status"::Complete);
                        PCordHdr.Setfilter("Order Type",'%1|%2',PCOrdHdr."Order Type"::Invoice,PCOrdHdr."Order Type"::Cancelled);
                    end    
                    else 
                        PCOrdHdr.Setrange("Order Type",PCordHdr."Order Type"::CreditMemo);
                    Clear(ProcCnt);
                    Clear(RebateSum);
                    Clear(RebateDesc);
                    Clear(i);
                    If PCOrdHdr.findset then
                    Begin
                        if GuiAllowed then win.update(2,PCOrdHdr.Count);
                        repeat
                            OrderCnt += 1;
                            If ProcCnt = 0 then
                            begin
                                Clear(LineNo);
                                Clear(SalesHdr);
                                SalesHdr.init;
                                if Loop = 1 then
                                    SalesHdr.validate("Document Type",SalesHdr."Document Type"::Invoice)
                                else
                                    SalesHdr.validate("Document Type",SalesHdr."Document Type"::"Credit Memo");
                                SaleDocType."Document Type" := SalesHdr."Document Type";    
                                SalesHdr.Validate("Sell-to Customer No.",Cust."No.");
                                SalesHdr.validate("Prices Including VAT",True);
                                SalesHdr."Your Reference" := 'SHOPIFY ORDERS';
                                SalesHdr.Insert(true);
                                OrdNo := SalesHdr."No.";
                                OrdNos.add(OrdNo);
                                OrdTypes.add(SalesHdr."Document Type");
                            end;
                            ProcCnt += 1;
                            if GuiAllowed Then Win.Update(1,OrderCnt);
                            Clear(ExFlg);
                            Clear(RebTotaler);
                            PCOrdLin.Reset();
                            PCOrdLin.Setrange(ShopifyID,PCOrdHdr.ID);
                            PCOrdLin.Setrange("Not Supplied",False);
                            PCOrdLin.Setfilter("Item No.",'<>%1','');
                            PCOrdLin.Setfilter("Order Qty",'>0');
                            If PCOrdLin.FindSet then
                            repeat
                                exFlg := Item.Get(PCOrdLin."Item No.");
                                if exflg Then exflg := Not Item.Blocked;
                                if exFlg then exflg := Item."Gen. Prod. Posting Group" <> '';
                                If exflg then exflg := Item."VAT Prod. Posting Group" <> '';
                                If exflg then exflg := PCOrdLin."Unit Of Measure" <> '';
                                If exflg then exflg := PCOrdLin."Location Code" <> '';
                                If exflg then exflg := Not Item."Sales Blocked";
                                If exflg then 
                                begin
                                    LineNo += 10;
                                    Clear(SalesLine);
                                    SalesLine.init;
                                    SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                    SalesLine.Validate("Document No.",SalesHdr."No.");
                                    SalesLine."Line No." := LineNo;
                                    // here we establish the 
                                    Salesline.insert(true);
                                    SalesLine.Validate(Type,SalesLine.Type::Item);
                                    SalesLine.validate("No.",Item."No.");
                                    If Item.Type = Item.Type::Inventory then
                                        SalesLine.Validate("Location Code",PCOrdLin."Location Code");
                                    Salesline."Bundle Item No." :=  PCOrdLin."Bundle Item No.";
                                    Salesline."Bundle Order Qty" := PcOrdlin."Bundle Order Qty";
                                    Salesline."Bundle Unit Price" := PcOrdlin."Bundle Unit Price";
                                    If PCOrdHdr."Shopify Order Currency" <> 'AUD' then
                                        SalesLine.validate("Currency Code",PCOrdHdr."Shopify Order Currency");
                                    If (PCOrdLin."Tax Amount" = 0) and (SalesLine."VAT %" > 0) then
                                        SalesLine.Validate("VAT Prod. Posting Group",'NO GST')
                                    else If (PCOrdLin."Tax Amount" > 0) and (SalesLine."VAT %" = 0) then
                                        SalesLine.Validate("VAT Prod. Posting Group",'GST10');
                                    SalesLine.Validate("Unit of Measure Code",PCOrdLin."Unit Of Measure");
                                    SalesLine.Validate(Quantity,PCOrdLin."Order Qty");
                                    Salesline.Validate("Unit Price",PcordLin."Unit Price");
                                    Salesline.Validate("Line Discount Amount",PCOrdLin."Discount Amount");
                                    Salesline."Shopify Order ID" := PCordHdr."Shopify Order ID";
                                    SalesLine."Shopify Application ID" := PCOrdLin."Shopify Application ID";
                                    SalesLine."Rebate Supplier No." := Item."Vendor No.";
                                    SalesLine."Rebate Brand" := Item.Brand;
                                    OrdType := 'STANDARD';
                                    SalesLine."Auto Delivered" := PCOrdLin."Auto Delivered";
                                    If SalesLine."Auto Delivered" then OrdType := 'AUTO ORDER';
                                    Salesline."Dimension Set ID" := Get_Dim_Set_Id(PCOrdHdr."Shopify Order Member Status",OrdType,Item."No.");
                                /*    SalesLine."Auto Delivered" := (PCOrdHdr[1]."Shopify Order Member Status" = 'GOLD') Or 
                                                                    (PCOrdHdr[1]."Shopify Order Member Status" = 'PLATINUM') OR 
                                                                    (PCOrdLin."Auto Delivered");*/
                                    if loop = 2 then
                                        SalesLine."Palatability Reason" := PCOrdLin."Reason Code";
                                    Salesline."Shopify Order Date" := PCOrdHdr."Shopify Order Date";
                                // only add rebates for invoice types
                                    If PCOrdHdr."Order Type" = PCOrdHdr."Order Type"::Invoice then                    
                                        Add_Rebate_Entries(Salesline,LineNo,RebTotaler,RebateDesc);
                                    SalesLine.Modify(true);
                            end;
                            Until (PCOrdLin.next = 0) Or Not exFlg;
                            // check to make sure all the shopify order lines were resolved ie BC Item exists
                            If Not exflg then
                            begin
                            // that are not complete ie missing an item ref in BC
                                SalesLine.Reset();
                                salesLine.Setrange("Document Type",SalesHdr."Document Type");
                                SalesLine.SetRange("Document No.",SalesHdr."No.");
                                SalesLine.Setrange("Shopify Order ID",PCOrdHdr."Shopify Order ID");
                                If salesLine.Findset then 
                                begin
                                    SalesLine.deleteall(true);
                                    if GuiAllowed then Message(strsubstno('Shopify Order No %1 skipped due to invalid item lines being detected.'
                                                            ,PCOrdHdr."Shopify Order No."));
                                    Excp.init;
                                    Clear(Excp.ID);
                                    Excp.insert;
                                    Excp.ShopifyID := PCOrdHdr.ID;
                                    Excp.Exception := StrsubStno('Order Process -> Order Item %1 is missing critical setup information',Item."No."); 
                                    excp.Modify();
                                    // here we remove any Rebate totals if the entire orderlines are wiped out
                                    Clear(RebTotaler);
                                end
                                else
                                begin
                                    Excp.init;
                                    Clear(Excp.ID);
                                    Excp.insert;
                                    Excp.ShopifyID := PCOrdHdr.ID;
                                    Excp.Exception := 'Order Process -> Order contains no items with order qty > 0 '; 
                                    excp.Modify();
                                end;
                            end
                            else
                            Begin
                                RebateSum[1] += RebTotaler[1]; // Campaign Totaler
                                RebateSum[2] += RebTotaler[2]; // Auto Order Totaler
                            // Now see if any shipping is defined against this Shopify Order
                                If PCOrdHdr."Freight Total" > 0 then
                                begin
                                    LineNo += 10;
                                    Clear(SalesLine);
                                    SalesLine.init;
                                    SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                    SalesLine.Validate("Document No.",SalesHdr."No.");
                                    SalesLine."Line No." := LineNo;
                                    Salesline.insert(true);
                                    SalesLine.Validate(Type,SalesLine.Type::Item);
                                    SalesLine.validate("No.",'SHIPPING');
                                    SalesLine.Validate("VAT Prod. Posting Group",'GST10');
                                    If PCOrdHdr."Shopify Order Currency" <> 'AUD' then
                                        SalesLine.validate("Currency Code",PCOrdHdr."Shopify Order Currency");
                                    SalesLine.Validate("Unit of Measure Code",'EA');    
                                    SalesLine.Validate(Quantity,1);
                                    Clear(Salesline."Auto Delivered");
                                    Salesline."Shopify Order ID" := PCordHdr."Shopify Order ID";
                                    Salesline.Validate("Unit Price",PCOrdHdr."Freight Total");
                                    Salesline."Shopify Order Date" := PCOrdHdr."Shopify Order Date";
                                    SalesLine.Modify(true);
                                end;
                                If PCOrdHdr."Gift Card Total" > 0 then
                                begin
                                    LineNo += 10;
                                    Clear(SalesLine);
                                    SalesLine.init;
                                    SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                    SalesLine.Validate("Document No.",SalesHdr."No.");
                                    SalesLine."Line No." := LineNo;
                                    Salesline.insert(true);
                                    SalesLine.Validate(Type,SalesLine.TYpe::Item);
                                    SalesLine.validate("No.",'GIFT_CARD_REDEEM');
                                    SalesLine.Validate("VAT Prod. Posting Group",'NO GST');
                                    If PCOrdHdr."Shopify Order Currency" <> 'AUD' then
                                        SalesLine.validate("Currency Code",PCOrdHdr."Shopify Order Currency");
                                    SalesLine.Validate("Unit of Measure Code",'EA');    
                                    SalesLine.Validate(Quantity,1);
                                    Salesline.Validate("Unit Price",-PCOrdHdr."Gift Card Total");
                                    Clear(Salesline."Auto Delivered");
                                    Salesline."Shopify Order ID" := PCordHdr."Shopify Order ID";
                                    Salesline."Shopify Order Date" := PCOrdHdr."Shopify Order Date";
                                    SalesLine.Modify(true);
                                end;
                                //Check that All Order lines are applicable
                                PCOrdLin.Reset();
                                PCOrdLin.Setrange(ShopifyID,PCOrdHdr.ID);
                                PCOrdLin.Setrange("Not Supplied",True);
                                PCOrdLin.Setfilter("Item No.",'<>%1','');
                                PCOrdLin.Setfilter("Order Qty",'>0');
                                If Not PCOrdLin.FindSet then
                                begin
                                    Salesline.Reset;
                                    SalesLine.Setrange("Shopify Order ID",PCOrdHdr."Shopify Order ID");
                                    SalesLine.Setrange("Document Type",SalesHdr."Document Type");
                                    SalesLine.Setrange("Document No.",SalesHdr."No.");
                                    If SalesLine.Findset then
                                    begin
                                        SalesLine.Calcsums("Line Discount Amount");
                                        If PCOrdHdr."Discount Total" > 0 then
                                        begin
                                            Disc := SalesLine."Line Discount Amount" - PCOrdHdr."Discount Total";
                                            If Disc <> 0 then
                                            begin
                                                LineNo += 10;
                                                Clear(SalesLine);
                                                SalesLine.init;
                                                SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                                SalesLine.Validate("Document No.",SalesHdr."No.");
                                                SalesLine."Line No." := LineNo;
                                                Salesline.insert(true);
                                                SalesLine.Validate(Type,SalesLine.TYpe::Item);
                                                SalesLine.validate("No.",'DISCOUNTS');
                                                SalesLine.Validate("VAT Prod. Posting Group",'NO GST');
                                                If PCOrdHdr."Shopify Order Currency" <> 'AUD' then
                                                    SalesLine.validate("Currency Code",PCOrdHdr."Shopify Order Currency");
                                                SalesLine.Validate("Unit of Measure Code",'EA');    
                                                SalesLine.Validate(Quantity,1);
                                                Clear(Salesline."Auto Delivered");
                                                Salesline."Shopify Order ID" := PCordHdr."Shopify Order ID";
                                                Salesline.Validate("Unit Price",Disc);
                                                Salesline."Shopify Order Date" := PCOrdHdr."Shopify Order Date";
                                                SalesLine.Modify(true);
                                            end;
                                        end;
                                    end;        
                                end;    
                                // flag this shopify order as closed now
                                // and save the BC order no
                                PCOrdHdr."BC Reference No." := OrdNo;
                                PCOrdHdr.Modify();
                            end;
                            If ProcCnt >= 500 then
                            begin
                                Clear(ProcCnt);
                                If Loop = 1 then
                                begin
                                    For Rindx := 1 to 2 Do
                                    Begin
                                        If RebateSum[Rindx] > 0 then
                                        begin
                                            LineNo += 10;
                                            Clear(SalesLine);
                                            SalesLine.init;
                                            SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                            SalesLine.Validate("Document No.",SalesHdr."No.");
                                            SalesLine."Line No." := LineNo;
                                            Salesline.insert(true);
                                            SalesLine.Validate(Type,SalesLine.TYpe::Item);
                                            If Rindx = 1 then
                                                SalesLine.validate("No.",'REBATE_REV_CAMP')
                                            else
                                                SalesLine.validate("No.",'REBATE_REV_AUTO');
                                            SalesLine.Validate("VAT Prod. Posting Group",'NO GST');
                                            SalesLine.Validate("Unit of Measure Code",'EA');    
                                            SalesLine.Validate(Quantity,1);
                                            Clear(Salesline."Auto Delivered");
                                            Salesline.Validate("Unit Price",-RebateSum[Rindx]);
                                            If Rindx = 1 then
                                            begin
                                                SalesLine.Description := 'Campaign Rebate ' + RebateDesc[Rindx];
                                                SalesLine."Campaign Rebate Code" := RebateDesc[Rindx];
                                            end
                                            else
                                            begin
                                                SalesLine.Description := 'Auto Delivery Rebate ' + RebateDesc[Rindx];
                                                SalesLine."Auto Delivery Rebate Code" := RebateDesc[Rindx];
                                            end;    
                                            SalesLine.Modify(true);
                                            Clear(RebateSum[Rindx]);
                                            Clear(RebateDesc[Rindx]);
                                        end;
                                    end;
                                end 
                                else 
                                    SalesHdr."Reason Code" := 'CUSTRETURN'; 
                                SalesHdr.Modify(true);
                                Commit;
                            end;    
                        Until PCOrdHdr.next = 0;
                    end;    
                    If ProcCnt > 0 then
                    begin
                        // check and ensure some sales lines were created now
                        SalesLine.reset;
                        SalesLine.Setrange("Document Type",SalesHdr."Document Type");
                        SalesLine.SetRange("Document No.",OrdNo);
                        If SalesLine.Findset then
                        begin
                            If Loop = 1 then
                            begin
                                For Rindx := 1 to 2 Do
                                Begin
                                    If RebateSum[Rindx] > 0 then
                                    begin
                                        LineNo += 10;
                                        Clear(SalesLine);
                                        SalesLine.init;
                                        SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                        SalesLine.Validate("Document No.",SalesHdr."No.");
                                        SalesLine."Line No." := LineNo;
                                        Salesline.insert(true);
                                        SalesLine.Validate(Type,SalesLine.TYpe::Item);
                                        If Rindx = 1 then
                                            SalesLine.validate("No.",'REBATE_REV_CAMP')
                                        else
                                            SalesLine.validate("No.",'REBATE_REV_AUTO');
                                        SalesLine.Validate("VAT Prod. Posting Group",'NO GST');
                                        SalesLine.Validate("Unit of Measure Code",'EA');    
                                        SalesLine.Validate(Quantity,1);
                                        Clear(Salesline."Auto Delivered");
                                        Salesline.Validate("Unit Price",-RebateSum[Rindx]);
                                        If Rindx = 1 then
                                        begin
                                            SalesLine.Description := 'Campaign Rebate ' + RebateDesc[Rindx];
                                            SalesLine."Campaign Rebate Code" := RebateDesc[Rindx];
                                        end
                                        else
                                        begin
                                            SalesLine.Description := 'Auto Delivery Rebate ' + RebateDesc[Rindx];
                                            SalesLine."Auto Delivery Rebate Code" := RebateDesc[Rindx];
                                        end;    
                                        SalesLine.Modify(true);
                                        Clear(RebateSum[Rindx]);
                                        Clear(RebateDesc[Rindx]);
                                    end;
                                end;
                            end 
                            else 
                                SalesHdr."Reason Code" := 'CUSTRETURN'; 
                            SalesHdr.Modify(true);
                            Commit;
                        end;
                    end;
                end; 
                Commit;           
                if GuiAllowed Then Win.Close;
                For i := 1 to OrdNos.Count do
                begin
                    If SalesHdr.get(OrdTypes.get(i),OrdNos.get(i)) then
                    begin
                        // check and ensure some sales lines were created now
                        SalesHdr.SetHideValidationDialog(true);
                        SalesLine.reset;
                        SalesLine.Setrange("Document Type",SalesHdr."Document Type");
                        SalesLine.SetRange("Document No.",SalesHdr."No.");
                        if SalesLine.Findset then
                        begin
                            Commit;
                            if CuRel.Run(SalesHdr) then
                                if Cu.Run(SalesHdr) then
                                begin
                                    PCOrdHdr.Reset;
                                    PCOrdHdr.Setrange("Order Status",PCOrdHdr."Order Status"::Open);
                                    PCOrdHdr.Setrange("BC Reference No.",OrdNos.get(i));
                                    if PCOrdHdr.Findset then
                                    begin
                                        PCOrdHdr.ModifyAll("Order Status",PCOrdHdr."Order Status"::Closed);
                                        If OrdTypes.get(i) = SalesHdr."Document Type"::Invoice then
                                        begin
                                            SalesInvHdr.Reset;
                                            SalesInvHdr.Setrange("Pre-Assigned No.",OrdNos.get(i));
                                            if SalesInvHdr.findset then
                                            begin
                                                PCOrdHdr.Reset;
                                                PCOrdHdr.Setrange("Order Status",PCOrdHdr."Order Status"::Closed);
                                                PCOrdHdr.Setrange("BC Reference No.",OrdNos.get(i));
                                                if PCOrdHdr.Findset then
                                                    PCOrdHdr.Modifyall("BC Reference No.",SalesInvHdr."No.");
                                            end; 
                                        end 
                                        else
                                        begin
                                            SalesCrdHdr.Reset;
                                            SalesCrdHdr.Setrange("Pre-Assigned No.",OrdNos.get(i));
                                            if SalesCrdHdr.findset then
                                            begin
                                                PCOrdHdr.Reset;
                                                PCOrdHdr.Setrange("Order Status",PCOrdHdr."Order Status"::Closed);
                                                PCOrdHdr.Setrange("BC Reference No.",OrdNos.get(i));
                                                if PCOrdHdr.Findset then
                                                    PCOrdHdr.Modifyall("BC Reference No.",SalesCrdHdr."No.");
                                            end; 
                                        end;
                                    end;
                                    Commit; 
                                end;
                        end
                        else
                           SalesHdr.Delete(True);
                    end;    
                end;
            End;
        end;        
        If Excp.count > 1 then Send_Email_Msg('Order Exceptions','Check Shopify Sales Orders .. Exceptions exist requiring manual intervention.',Setup."Exception Email Address");
        If PstDate <> 0D then
        begin
            GLSetup."Allow Posting To" := PstDate;
            GLSetup.Modify(false);
        end;
        Commit;
        Clear_QC_Stock();    
    end;
    procedure Correct_Sales_Prices(SkuFilt:Code[20])
    var
    Sprice:Array[3] of record "PC Shopfiy Pricing";
    Sku:Code[20];
    StartDate:date;
    begin
        Clear(SKU);
        Sprice[1].Reset;
        If SkuFilt <> '' then
            Sprice[1].Setrange("Item No.",SkuFilt);
        Sprice[1].Setrange("Ending Date",0D);
        If Sprice[1].Findset then
        repeat
            If SKU <> Sprice[1]."Item No." then
            begin
                SKU :=  Sprice[1]."Item No.";
                Sprice[2].Reset;
                Sprice[2].Setrange("Ending Date",0D);
                Sprice[2].Setrange("Item No.",SKU);
                If Sprice[2].Count > 1 then
                begin
                    Sprice[2].Findset;
                    StartDate := CalcDate('-1Y',Sprice[2]."Starting Date");
                    repeat
                        If Sprice[2]."Starting Date" > StartDate then
                            StartDate := Sprice[2]."Starting Date";
                    until Sprice[2].next = 0;
                    Sprice[2].SetFilter("Starting Date",'<>%1',StartDate);
                    If Sprice[2].Findset then Sprice[2].ModifyAll("Ending Date",StartDate,false);
                    Sprice[2].SetFilter("Starting Date",'<=%1',Today);
                    Sprice[2].SetRange("Ending Date",StartDate);
                    If Sprice[2].Count > 1 then
                    begin
                        Sprice[2].Findset;
                        StartDate := Sprice[2]."Starting Date";
                        repeat
                            If Sprice[2]."Starting Date" > StartDate then
                            Begin
                                Sprice[3].Copyfilters(Sprice[2]);
                                Sprice[3].Setrange("Starting Date",StartDate);
                                If Sprice[3].findset then
                                Begin
                                    Sprice[3]."Ending Date" := StartDate;
                                    Sprice[3].Modify();
                                end;     
                                StartDate := Sprice[2]."Starting Date";
                            end;            
                        until Sprice[2].next = 0;
                    end;
                end;
            end;                
        until Sprice[1].next = 0;
        Sprice[1].Reset;
        If SkuFilt <> '' then
            Sprice[1].Setrange("Item No.",SkuFilt);
        Sprice[1].Setfilter("Ending Date",'<>%1&<%2',0D,Today);
        If Sprice[1].Findset then Sprice[1].DeleteAll(False);
    end;
    procedure Correct_Purchase_Costs(SkuFilt:Code[20])
    var
    PCost:Array[3] of record "PC Purchase Pricing";
    Sku:Code[20];
    StartDate:date;
    begin
        Clear(SKU);
        PCost[1].Reset;
        If SkuFilt <> '' then
            Pcost[1].Setrange("Item No.",SkuFilt);
        PCost[1].Setrange("End Date",0D);
        If PCost[1].Findset then
        repeat
            If SKU <> Pcost[1]."Item No." then
            begin
                SKU :=  Pcost[1]."Item No.";
                Pcost[2].Reset;
                Pcost[2].Setrange("End Date",0D);
                Pcost[2].Setrange("Item No.",SKU);
                If Pcost[2].Count > 1 then
                begin
                    Pcost[2].Findset;
                    StartDate := CalcDate('-1Y',Pcost[2]."Start Date");
                    repeat
                        If Pcost[2]."Start Date" > StartDate then
                            StartDate := Pcost[2]."Start Date";
                    until Pcost[2].next = 0;
                    Pcost[2].SetFilter("Start Date",'<>%1',StartDate);
                    If Pcost[2].Findset then Pcost[2].ModifyAll("End Date",StartDate,false);
                    Pcost[2].SetFilter("Start Date",'<=%1',Today);
                    Pcost[2].SetRange("End Date",StartDate);
                    If Pcost[2].Count > 1 then
                    begin
                        Pcost[2].Findset;
                        StartDate := Pcost[2]."Start Date";
                        repeat
                            If Pcost[2]."Start Date" > StartDate then
                            Begin
                                Pcost[3].Copyfilters(Pcost[2]);
                                Pcost[3].Setrange("Start Date",StartDate);
                                If Pcost[3].findset then
                                Begin
                                    Pcost[3]."End Date" := StartDate;
                                    Pcost[3].Modify();
                                end;     
                                StartDate := Pcost[2]."Start Date";
                            end;            
                        until Pcost[2].next = 0;
                    end;
                end;
            end;                
        until Pcost[1].next = 0;
        Pcost[1].Reset;
        If SkuFilt <> '' then
            Pcost[1].Setrange("Item No.",SkuFilt);
        Pcost[1].Setfilter("End Date",'<>%1&<=%2',0D,Today);
        If Pcost[1].Findset then Pcost[1].DeleteAll(False);
    end;
 
}