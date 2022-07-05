codeunit 80005 Test
{
     Permissions = TableData "Sales Invoice Line" = rm;
var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
        WsError:text;
        ShopifyBase:Label '/admin/api/2021-10/';
    trigger OnRun()
    Begin
        Error('This is a test for Vic');
    End;
 
    procedure Testrun()
    var
        OrdApp:Record "PC Shopfiy Order Applications";
        DiscApps:record "PC Shopify Disc Apps";
        CU:Codeunit "PC Shopify Routines";
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        Sinv:Record "Sales Invoice Line";
        win:dialog;
        i:integer;
        Item:record Item;
    begin
        Item.reset;
        Item.Setrange(Type,Item.Type::Inventory);
        IF Item.findset then
        repeat
            Item."Price Includes VAT" := Item."VAT Prod. Posting Group" = 'GST10';
            Item.Modify(False);
            Item.Update_Parent();
        until Item.Next = 0;    
        exit;
 





        Sinv.Reset;
        Sinv.Setfilter("Shopify Application ID",'>0');
        If Sinv.Findset then Sinv.ModifyAll("Shopify Application ID",0,False);
        OrdApp.Reset();
        If OrdApp.FindSet() then
            repeat
                     Sinv.Reset;
                        Sinv.Setrange("Shopify Order ID",OrdApp."Shopify Order ID");
                        If Sinv.Findset then
                            if DiscApps.Get(OrdApp."Shopify Application Type",OrdApp."Shopify Disc App Code") then        
                                Sinv.modifyall("Shopify Application ID",DiscApps."Shopify App ID",false);
                        If i Mod 10 = 0 then Commit;
            until OrdApp.next = 0;
            Commit;
    end;                        
   /*     Win.Open('Updating Order No  #1##############');
        OrdHr.reset;
        Ordhr.Setfilter("Shopify Order ID",'>0');
        OrdHr.Setrange("Order Status",OrdHr."Order Status"::Closed);
        If OrdHr.findset then
        repeat
            Buff.Reset;
            Buff.Setrange("Shopify Order ID",OrdHr."Shopify Order ID");
            If Buff.Findset then
            begin
                Win.Update(1,OrdHr."Shopify Order No.");
                OrdHr."Cash Receipt Status" := Buff."Cash Receipt Status";
                OrdHr."Invoice Applied Status" := Buff."Invoice Applied Status";
                OrdHr."Payment Gate Way" := Buff."Payment Gate Way";
                OrdHr."Proc Time" := Buff."Proc Time";
                OrdHr."Processed Date" := Buff."Processed Date";
                OrdHr."Processed Time" := Buff."Processed Time";
                OrdHr."Reference No" := Buff."Reference No";
                OrdHr."Transaction Type" := Buff."Transaction Type";
                OrdHr."Shopify Financial Status" := Buff."Shopify Financial Status";
                OrdHr.modify(false);
            end;
        until OrdHr.next = 0;
        win.close;
        */
    /*Procedure Testrun2()
    var
        Buff:record "PC Shopify Order Buffer";
        SinvLine:record "Sales Invoice Line";
        OrdHdr:record "PC Shopify Order Header";
        Cnt:integer;
    begin
       Buff.Reset;
       If Buff.findset then
       repeat
            Clear(BUff."Is In BC");
            Buff."BC Reference No." := 'N/A';
            OrdHdr.reset;
            OrdHdr.Setrange("Shopify Order ID",Buff."Shopify Order ID");
            If OrdHdr.findset then
            begin
                OrdHdr."Order Total" := BUff."Order Total";
                OrdHdr.Modify;
                Buff."BC Reference No." := OrdHdr."BC Reference No.";
                Buff."Is In BC"  := True;
            end;
            If Buff."Transaction Type" = 'refund' then
            begin       
                Buff."Order Total" := ABS(Buff."Order Total");
                Buff."Order Type" := Buff."Order Type"::CreditMemo;
            end;
            Buff.Modify();
        Until Buff.next = 0;
    end;*/
    procedure Get_Shopify_Orders(StartIndex:BigInteger):Boolean
    var
        OrdHdr:record "PC Shopify Order Header";
        OrdApp:record "PC Shopfiy Order Applications";
        OrdLine:record "PC Shopify Order Lines";
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
        ExFlg: Boolean;
        Status:text;
        OrdhdrEX:Record "PC Shopify Order Header";
        Item:record Item;
        ItemUnit:record "Item Unit of Measure";
        DimVal:record "Dimension Value";
        TstVal:text;
        recCnt:Integer;
        StartDate:date;
        CU:codeunit "PC Shopify Routines";
    begin
        //CU.Process_Refunds();
        OrdHdr.reset;
        OrdHdr.setrange("Order Type",OrdHdr."Order Type"::CreditMemo);
        OrdHdr.Setrange("Shopify Order Status",'FULLFILLED');
        If OrdHdr.FindSet() then
        repeat
            OrdhdrEX.Reset();
            OrdhdrEX.Setrange("Order Type",OrdhdrEX."Order Type"::Invoice);
            OrdhdrEX.Setrange("Shopify Order ID",OrdHdr."Shopify Order ID");
            If OrdhdrEX.Findset then
                If ABS(OrdHdr."Order Total") = ABS(OrdhdrEX."Order Total") then
                begin
                    OrdHdr.Delete(True);
                    OrdhdrEX.Delete(True);
               end;
        until OrdHdr.next = 0;
        /*



        if GuiAllowed then win.Open('Retrieving Order No    #1###########\'
                                   + 'Processing Order No    #2###########');
        Clear(indx);
        Clear(Cnt);
        OrdHdr.Reset;
        OrdHdr.SetCurrentKey("Shopify Order No.");
        if OrdHdr.findlast then Indx := OrdHdr."Shopify Order No.";
   
        Indx := 46786;

        OrdHdr.Reset;
        OrdHdr.SetFilter("Shopify Order No.",'>=%1',Indx);
        If OrdHdr.FindFirst() then 
            Indx := OrdHdr."Shopify Order ID";
        Clear(PayLoad);
        Clear(Parms);
        Clear(recCnt);
        Parms.Add('since_id',Format(indx));
        Parms.add('status','any');
        Parms.Add('limit','250');
        Parms.Add('fields','id,cancelled_at,fulfillment_status,order_number,discount_applications,line_items,processed_at'
                +',currency,total_discounts,total_shipping_price_set,financial_status,total_price,total_tax');
        if Not Cu.Shopify_Data(Paction::GET,ShopifyBase + 'orders/count.json'
                                        ,Parms,PayLoad,Data) then Exit(false);
        Data.Get('count',JsToken[1]);
        Cnt := JsToken[1].AsValue().AsInteger();
        repeat
            Cnt -= 250;
            Sleep(10);
            CU.Shopify_Data(Paction::GET,ShopifyBase + 'orders.json'
                ,Parms,PayLoad,Data);
            if Data.Get('orders',JsToken[1]) then
            begin
                JsArry[1] := JsToken[1].AsArray();
                for i := 0 to JsArry[1].Count - 1 do
                begin
                    JsArry[1].get(i,Jstoken[1]);
                    if Jstoken[1].SelectToken('order_number',Jstoken[2]) then
                        If Not JsToken[2].asvalue.IsNull then
                            if GuiAllowed then Win.Update(1,Jstoken[2].AsValue().AsBigInteger());
                    Clear(Indx);
                    Flg := Jstoken[1].SelectToken('id',Jstoken[2]);
                    If Flg Then Flg := Not Jstoken[2].AsValue().IsNull;
                    If Flg then Indx := Jstoken[2].AsValue().AsBigInteger();
                    If Flg then Flg := Jstoken[1].SelectToken('cancelled_at',Jstoken[2]);
                    if Flg then Flg := Jstoken[2].AsValue().IsNull;
                    if Flg Then Flg := Jstoken[1].SelectToken('financial_status',Jstoken[2]);
                    if Flg Then Flg := Not Jstoken[2].AsValue().IsNull;
                    If Flg then Flg := Jstoken[2].AsValue().AsText().ToUpper() in ['PAID','REFUNDED','PARTIALLY_REFUNDED'];
                    If Flg then Flg := Jstoken[1].SelectToken('fulfillment_status',Jstoken[2]);
                    If Flg then
                    begin
                        if Jstoken[1].SelectToken('order_number',Jstoken[2]) then
                            If Not JsToken[2].asvalue.IsNull then
                                if GuiAllowed then Win.Update(2,Jstoken[2].AsValue().AsBigInteger());
                        OrdhdrEX.Init;
                        OrdHdrEX."Order Type" := OrdHdrEx."Order Type"::Invoice;
                        OrdHdrEX."Shopify Order ID" := indx;
                        Get_Order_Transactions(OrdHdrEX);
                        OrdHdr.Reset;
                        OrdHdr.Setrange("Shopify Order ID",indx);
                        If OrdHdr.findset then
                        begin
                            OrdHdr."Reference No" := OrdhdrEX."Reference No";
                            OrdHdr.Modify(False);      
                        end;
                    end;
                end;
            end;
            Parms.Remove('since_id');
            Parms.Add('since_id',Format(indx));
        until cnt <=0; 
        Win.close;*/
    end;
    local procedure Get_Order_Transactions(var Ordhdr:record "PC Shopify Order Header")
    var
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:JsonArray;
        JsToken:array[3] of JsonToken;
        i:integer;
        CU:codeunit "PC Shopify Routines";
    Begin
        Clear(Parms);
        Ordhdr."Transaction Date" := Today;
        Ordhdr."Transaction Type" := 'sale';
        if CU.Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr."Shopify Order ID") + '/transactions.json'
                                     ,Parms,PayLoad,Data) then
        begin                             
            If Data.Get('transactions',JsToken[1]) then
            begin
                JsArry := JsToken[1].AsArray();
                If JsArry.Count = 0 then OrdHdr."Transaction Type" := 'promotion'
                else
                begin
                    For i := 0 to Jsarry.Count - 1 do
                    Begin     
                        JsArry.get(i,JsToken[1]);
                        if Jstoken[1].SelectToken('status',JsToken[2]) then
                            If not JsToken[2].AsValue().IsNull then
                                If (JsToken[2].AsValue().AsText().ToUpper() = 'SUCCESS')then
                                begin
                                    If i = 0 then
                                    Begin
                                        if JsToken[1].SelectToken('kind',JsToken[2]) then
                                            If not JsToken[2].AsValue().IsNull then
                                            begin
                                                OrdHdr."Transaction Type" := Copystr(JsToken[2].AsValue().AsText(),1,25);
                                                If JsToken[2].AsValue().AsText().ToUpper() = 'REFUND' then 
                                                    Ordhdr."Order Type" := Ordhdr."Order Type"::CreditMemo;
                                            end;        
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
                                        if JsToken[1].SelectToken('receipt',JsToken[2]) then
                                        begin
                                            If JsToken[2].SelectToken('transaction_id',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                    OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                            end        
                                            else if JsToken[2].SelectToken('payment_id',JsToken[3]) then
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
                                        If (OrdHdr."Payment Gate Way" <> '') AND (OrdHdr."Reference No" = '') then
                                            if JsToken[1].SelectToken('source_name',JsToken[2]) then
                                                If not Jstoken[2].AsValue().IsNull then
                                                    OrdHdr."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);    
                                    end
                                    else If Ordhdr."Gift Card Total" = 0 then
                                            if JsToken[1].SelectToken('receipt',JsToken[2]) then
                                                if JsToken[2].SelectToken('gift_card_id',JsToken[3]) then
                                                    If not Jstoken[3].AsValue().IsNull then
                                                        If JsToken[1].SelectToken('amount',JsToken[3]) then
                                                            If not Jstoken[3].AsValue().IsNull then
                                                                Ordhdr."Gift Card Total" := JsToken[3].AsValue().AsDecimal();
                                end;
                    end;
                end;  
           end;
        end;                            
    end;
}