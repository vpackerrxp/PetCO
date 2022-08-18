page 80032 "PC Auto Delivery Processing"
{
    Caption = 'Auto Delivery Processing';
    PageType = Worksheet;
    UsageCategory = Tasks;
    ApplicationArea = All;
    SourceTable = "Sales Invoice Line";
    SourceTableTemporary = true;
    Permissions = tabledata 113 = rmid;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    layout
    {
       area(Content)
        {
            Group(Filters)
            {
                field("From Posting Date Filter"; Postdate[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Postdate[2] <> 0D then
                        if Postdate[1] > Postdate[2]  then Clear(Postdate[1]);
                        Refress_data_msg(true);
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Postdate[1]);
                        Refress_data_msg(true);
                    end;
                }
                field("To Posting Date Filter"; Postdate[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If PostDate[1] <> 0D then
                        if Postdate[2] < Postdate[1] then Clear(PostDate[2]);
                        Refress_data_msg(true);
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(PostDate[2]);
                        Refress_data_msg(true);
                    end;
                }
                field("Supplier Filter"; Supp)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vend:record Vendor;
                        Pg:Page "Vendor List";
                    begin
                        Vend.Reset;
                        Vend.setfilter("No.",'SUP-*');
                        If Vend.findset then
                        begin
                            Pg.SetTableView(Vend);
                            Pg.LookupMode := true;
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Vend);
                                Supp := Vend."No.";
                                Refress_data_msg(true);
                            end;
                       end;
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Supp);
                        Refress_data_msg(true);
                    end;
                }
                field("Brand Filter"; Brd)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Pg:Page "PC Supplier Brand List";
                        Brad:record "PC Supplier Brand Rebates";
                    begin
                        pg.LookupMode := true;
                        If Pg.RunModal() = Action::LookupOK then
                        begin
                            Pg.GetRecord(Brad);
                            Brd := Brad.Brand;
                            Refress_data_msg(true);
                        end; 
                    end;       
                    trigger OnAssistEdit()
                    begin
                        Clear(Brd);
                        Refress_data_msg(true);
                   end;
                }
               field("Claim Filter"; Claim)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        Refress_data_msg(true);
                   end;
                }
                 Field("Rebate Posting Date";PstDate)
                {
                    Caption = 'Auto Delivery Rebate Posting Date';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.update(true);       
                    end;
                }
                field("Y";'Display Data')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    begin
                        SetFilters();
                   end;
                }
                field("X";RefMsg)
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    ShowCaption = false;
                }
            } 
            repeater(Group)
            {
                field("Posting Date"; rec."Posting Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Document No"; rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                   trigger OnDrillDown()
                    var
                        SInvHdr:Record "Sales Invoice Header";
                    begin
                        if SInvHdr.get(rec."Document No.") then
                            Page.RunModal(Page:: "Posted Sales Invoice",SInvHdr)
                    End;
                }
                field("Item No."; rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Order Qty"; rec."Quantity (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Order Qty';
                    Editable = false;
                }
                field("Unit Price"; rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price';
                    Editable = false;
                }
                field("Line Amount"; rec."Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Line Amount';
                    Editable = false;
                }
                field("Line Discount %"; rec."Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Line Disc %';
                    Editable = false;
                }
                field("Unit Cost"; rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost';
                    Editable = false;
                }
                /*
                field("Margin %"; Get_Profits(True))
                {
                    ApplicationArea = All;
                    Caption = 'Margin %';
                    Editable = false;
                }
                field("Markup %"; Get_Profits(False))
                {
                    ApplicationArea = All;
                    Caption = 'Markup %';
                    Editable = false;
                }
                */
                field("UOM"; rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'UOM';
                    Editable = false;
                }
                field("Supplier No."; rec."Supplier No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Brand; rec.Brand)
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Auto Delivery Claim Amount"; Get_Auto_Claim_Amount())
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Rebate Amount';
                }
                field("Claim Status"; rec."Palatability Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Favorable;
                    Caption = 'Claim Status';
                    StyleExpr =  rec."Palatability Status" =  rec."Palatability Status"::Claimed;
                }
            }
            Group(Totals)
            {
                field("No of Records"; rec.Count)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                 field("Total Sales Qty"; Get_Qty_Totals())
                {
                    ApplicationArea = All;
                    Editable = false;
                    DecimalPlaces = 0:2;
                    Style = Strong;
                }
                field("Total Sales Amount";Get_Price_Totals())
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                field("Total Cost Amount";Get_Cost_Totals())
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
      /*          field("Average Margin %";Get_Profit_Averages(True))
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                field("Average Markup %";Get_Profit_Averages(false))
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
             */   
            }
            
        }
    }
  
    actions
    {
        area(Processing)
        {
            action(Process)
            {
                ApplicationArea = All;
                trigger OnAction();
                var
                    SupReb:Record "PC Supplier brand Rebates"; 
                    SInvLine:record "Sales Invoice Line";
                    SalesHdr:record "Sales Header";
                    SalesLine:record "Sales Line";
                    vend:record Vendor;
                    Cust:record Customer;
                    ClaimTot:Decimal;
                    PCrd:Record "Purch. Cr. Memo Hdr.";
                    SalesInvHdr:record "Sales Invoice Header";
                    PurchHdr:Record "Purchase Header";
                    PurchLine:record "Purchase Line";
                    GenLed:Record "General Ledger Setup";
                    Cu:Codeunit "Purch.-Post";
                    CU2:Codeunit "Sales-Post";
                    pg:page "Posted Purchase Credit Memos";
                    pg2:page "Posted Sales Invoices";
                    Res:Record "Reason Code";
                    PSetup:Record "Purchases & Payables Setup";
                    ExtDoc:Boolean;
                    Cnt:Integer;
                    MsgSupp:boolean;
                begin
                    PSetup.Get;
                    Extdoc := PSetup."Ext. Doc. No. Mandatory";
                    Clear(PSetup."Ext. Doc. No. Mandatory");
                    PSetup.Modify;
                    Commit;
                    GenLed.Get;
                    If (GenLed."Auto Order Rebate Acc" <> '') AND (PstDate <> 0D) then
                    begin
                        If Not Res.get('AUTODELIV') then
                        begin
                            Res.Init;
                            Res.Code := 'AUTODELIV';
                            Res.Description := 'Auto Delivery';
                            Res.Insert();
                        end;
                        Clear(MsgSupp);
                        If Supp = '' then MsgSupp := Confirm('Supress Vendor Rebate Notifications');
                        case StrMenu('Process As Purchase Credit,Process As Sales Invoice') of
                            1:
                            begin
                                SInvline.Copyfilters(rec);
                                SInvLine.Setrange("Palatability Status",SinvLine."Palatability Status"::Unclaimed);
                                If Not SInvLine.findset then 
                                begin
                                    Message('Your Filtered Data does not consist of Unclaimed Auto Delivered Items');
                                    exit;      
                                end;
                                Clear(Cnt);
                                Vend.reset;
                                if Supp <> '' then
                                    Vend.setrange("No.",SUPP)
                                else    
                                    Vend.setfilter("No.",'SUP-*');
                                If Vend.findset then
                                repeat
                                    Clear(ClaimTot);                      
                                    SInvline.Setrange("Rebate Supplier No.",vend."No.");
                                    If Sinvline.Findset then
                                    repeat
                                        SupReb.reset;
                                        SupReb.Setrange("Supplier No.",vend."No.");
                                        SupReb.Setrange(Brand,SInvLine."Rebate Brand");
                                        If SupReb.Findset then    
                                            ClaimTot +=  SInvLine."Unit Cost" * SInvLine."Quantity (Base)" * SupReb."Auto Order Rebate %"/100;   
                                    Until SInvline.Next = 0;
                                    If ClaimTot > 0 then 
                                    begin
                                        PurchHdr.Init;
                                        PurchHdr.Validate("Document Type",PurchHdr."Document Type"::"Credit Memo");
                                        PurchHdr.insert(true);
                                        PurchHdr.Validate("Buy-from Vendor No.",Vend."No.");
                                        PurchHdr.validate("Posting Date",PstDate);
                                        PurchHdr."Your Reference" := StrSubStno('Rebates as of %1',TODAY);
                                        PurchHdr."Reason Code" := res.Code;
                                        PurchHdr.Invoice := True;
                                        PurchHdr.Receive := true;
                                        PurchHdr.modify(True);
                                        PurchLine.Init;
                                        Purchline.Validate("Document Type",PurchHdr."Document Type");
                                        PurchLine.validate("Document No.",PurchHdr."No.");
                                        Purchline.validate("Line No.",10000);
                                        PurchLine.insert(true);
                                        PurchLine.validate(Type,PurchLine.Type::"G/L Account");
                                        PurchLine.Validate("No.",GenLed."Auto Order Rebate Acc");
                                        PurchLine.validate(Quantity,1);
                                        Purchline.Validate("Direct Unit Cost",ClaimTot);
                                        If (Postdate[1] <> 0D) and (Postdate[2] <> 0D) then
                                            Purchline.Description := StrSubStno('%1 - %2 Auto Order Rebate',Postdate[1],Postdate[2])
                                        else If (Postdate[1] <> 0D) then
                                            Purchline.Description := StrSubStno('%1.. Auto Order Rebate',Postdate[1])
                                        else If (Postdate[2] <> 0D) then
                                                Purchline.Description := StrSubStno('..%1 Auto Order Rebate',Postdate[2])
                                        else 
                                                Purchline.Description := StrSubStno('%1 Auto Order Rebate',Today);
                                         Purchline.modify;
                                        Commit;
                                        If Cu.Run(PurchHdr) then
                                        begin
                                            SInvLine.Modifyall("Palatability Status",SInvLine."Palatability Status"::Claimed,false);
                                            Cnt += 1;
                                        end
                                        else
                                            Message('Posting Error -> %1',GetLastErrorText());
                                    end    
                                    else If Not MsgSupp then
                                        message('Vendor %1 has no claim rebates detected in the data .. check if Auto Delivery Rebate Percentages have been defined',Vend."No.")    
                                Until Vend.next = 0;
                                If Cnt > 0 then 
                                begin 
                                    Commit;
                                    PCrd.reset;
                                    PCrd.Setrange("Posting Date",PstDate);
                                    If Pcrd.FindSet() then
                                    begin
                                        Pg.SetTableView(Pcrd);
                                        Pg.RunModal();
                                    end;    
                                    Message(StrSubStno('%1 Purchase Credits have been processed',cnt));
                                end;
                            end;
                            2:
                            begin
                                SInvline.Copyfilters(rec);
                                SInvLine.Setrange("Palatability Status",SinvLine."Palatability Status"::Unclaimed);
                                If Not SInvLine.findset then 
                                begin
                                    Message('Your Filtered Data does not consist of Unclaimed Auto Delivered Items');
                                    exit;      
                                end;
                                Clear(Cnt);
                                Vend.reset;
                                if Supp <> '' then
                                    vend.setrange("No.",SUPP)
                                else    
                                    Vend.setfilter("No.",'SUP-*');
                                If Vend.findset then
                                repeat
                                    Clear(ClaimTot);                      
                                    SInvline.Setrange("Rebate Supplier No.",vend."No.");
                                    If Sinvline.Findset then
                                    repeat
                                        SupReb.reset;
                                        SupReb.Setrange("Supplier No.",vend."No.");
                                        SupReb.Setrange(Brand,SInvLine."Rebate Brand");
                                        If SupReb.Findset then    
                                            ClaimTot +=  SInvLine."Unit Cost" * SInvLine."Quantity (Base)" * SupReb."Auto Order Rebate %"/100;   
                                    Until SInvline.Next = 0;
                                    If ClaimTot > 0 then 
                                    begin
                                        If Not Cust.Get(Vend."No.") then
                                        begin
                                            Cust.Init;
                                            Cust.Validate("No.",Vend."No.");
                                            Cust.Insert();
                                            Cust.Name := Vend.Name;
                                            Cust."Name 2" := Vend."Name 2";
                                            Cust.Address := Vend.Address;
                                            Cust."Address 2" := Vend."Address 2";
                                            Cust.validate("Country/Region Code",Vend."Country/Region Code");  
                                            Cust.Validate(County,Vend.County);
                                            Cust.Validate("Post Code",Vend."Post Code");
                                            Cust.validate("Gen. Bus. Posting Group",Vend."Gen. Bus. Posting Group");
                                            Cust.Validate("VAT Bus. Posting Group",Vend."VAT Bus. Posting Group");
                                            Cust.validate("Customer Posting Group",'DOMESTIC');
                                            Cust."Prices Including VAT" := false;
                                            Cust.modify;
                                        end;
                                        SalesHdr.Init;
                                        SalesHdr.Validate("Document Type",SalesHdr."Document Type"::Invoice);
                                        SalesHdr.insert(true);
                                        SalesHdr.Validate("Sell-to Customer No.",Cust."No.");
                                        SalesHdr.validate("Posting Date",PstDate);
                                        SalesHdr."Your Reference" := StrSubStno('Rebates as of %1',TODAY);
                                        SalesHdr."Reason Code" := res.code;
                                        SalesHdr.Invoice := True;
                                        SalesHdr.Receive := true;
                                        SalesHdr.modify(True);
                                        Salesline.Init;
                                        Salesline.Validate("Document Type",SalesHdr."Document Type");
                                        SalesLine.validate("Document No.",SalesHdr."No.");
                                        Salesline.validate("Line No.",10000);
                                        SalesLine.insert(true);
                                        SalesLine.validate(Type,SalesLine.Type::"G/L Account");
                                        SalesLine.Validate("No.",GenLed."Auto Order Rebate Acc");
                                        SalesLine.validate(Quantity,1);
                                        Salesline.Validate("Unit Price",ClaimTot);
                                        Salesline."Auto Delivered" := False;
                                        If (Postdate[1] <> 0D) and (Postdate[2] <> 0D) then
                                            Salesline.Description := StrSubStno('%1 - %2 Auto Order Rebate',Postdate[1],Postdate[2])
                                        else If (Postdate[1] <> 0D) then
                                            Salesline.Description := StrSubStno('%1.. Auto Order Rebate',Postdate[1])
                                        else If (Postdate[2] <> 0D) then
                                                Salesline.Description := StrSubStno('..%1 Auto Order Rebate',Postdate[2])
                                        else 
                                                Salesline.Description := StrSubStno('%1 Auto Order Rebate',Today);
                                        Salesline.modify;
                                        Commit;
                                        If Cu2.Run(SalesHdr) then
                                        begin
                                            SInvLine.Modifyall("Palatability Status",SInvLine."Palatability Status"::Claimed,false);
                                            Cnt += 1;
                                        end
                                        else
                                            message('Posting Error - > %1',GetLastErrorText())
                                    end
                                    else If Not MsgSupp then
                                        message('Vendor %1 has no claim rebates detected in the data .. check if Auto Delivery Rebate Percentages have been defined',Vend."No.")    
                                Until Vend.next = 0;
                                If Cnt > 0 then 
                                begin 
                                    Commit;
                                    SalesHdr.reset;
                                    SalesInvHdr.Setrange("Posting Date",PstDate);
                                    SalesInvHdr.Setrange("Reason Code",res.Code);
                                    If SalesInvHdr.FindSet() then
                                    begin
                                        Pg2.SetTableView(SalesInvHdr);
                                        Pg2.RunModal();
                                    end;    
                                    Message(StrSubStno('%1 Sales Invoice Credits have been processed',cnt));
                                end;
                            end;
                        end;    
                    end         
                    else
                    begin
                        If PstDate = 0D then message('Please provide a rebate posting date');
                        If GenLed."Auto Order Rebate Acc" = '' then 
                            message('Auto Order Rebate Acc not defined in General Ledger Setup.');
                    end;
                    SetFilters();
                end;
            }
            action("Auto Order Management")
            {
                ApplicationArea = All;
                trigger OnAction();
                var
                    Pg:Page "PC Supplier Brand Rebates";
                begin    
                    Pg.Set_Page_Mode(1,'');
                    Pg.RunModal();
                end;    
            }
        }
    }
    local procedure SetFilters()
    var
        win:Dialog;
        SINV:Record "Sales Invoice Line";
    begin
        win.Open('Rendering Data .. Please Wait');
        rec.Reset;
        If rec.FindSet() Then Rec.DeleteAll(False);
        SINV.Reset;
        SINV.Setrange(Type,SINV.type::Item);
        SINV.SetFilter("No.",'SKU*');
        SINV.Setrange("Auto Delivered",True);
        if (PostDate[1] <> 0D) AND ( PostDate[2] <> 0D) then
            SINV.SetRange("Posting Date",PostDate[1],PostDate[2])
        else if (PostDate[1] <> 0D) then
            SINV.Setfilter("Posting Date",'%1..',PostDate[1])
        else if (Postdate[2] <> 0D) then
            SINV.Setfilter("Posting Date",'..%1',PostDate[2]);
        If Supp <> '' then SINV.Setrange("Supplier No.",Supp);
        If Brd <> '' then SINV.setrange(Brand,Brd);
        if Claim <> Claim::All then SINV.Setrange("Palatability Status",claim - 1);
        If Sinv.Findset then
        repeat
            Rec.Copy(Sinv);
            Rec.Insert(false);
        until Sinv.Next = 0;
        Win.close;
        Refress_data_msg(False);
        Currpage.Update(False);
    end;
    local procedure Refress_data_msg(OnOff:boolean)
    begin
        Clear(RefMsg);
        If OnOff then RefMsg := 'Data Refresh Required .. Press Display Data';
        CurrPage.update(false);
    end;
   local procedure Get_Qty_Totals():Decimal
    begin
        rec.CalcSums("Quantity (Base)");
        Exit(rec."Quantity (Base)")
    end;
    local procedure Get_Price_Totals():Decimal
    begin
        rec.CalcSums("Line Amount");
        Exit(rec."Line Amount")
    end;
    local procedure Get_Cost_Totals():Decimal
    begin
        rec.CalcSums("Unit Cost");
        Exit(rec."Unit Cost");
    end;
    local procedure Get_Profits(Flg:Boolean):Decimal
    var
       GP:Decimal;
       Price:Decimal;
    begin
        Clear(price);
        If rec.Quantity > 0 then Price := rec."Line Amount"/Rec.Quantity;
        GP := Price - rec."Unit Cost";
        If Flg then
        begin
            If Price > 0 then
               Exit(GP/Price * 100)
            else
                Exit(0);
        end    
        else
        begin
            If Rec."Unit Cost" > 0 then
                Exit(GP/Rec."Unit Cost" * 100)
            else
               Exit(100);
        end;       
    end;
    local procedure Get_Profit_Averages(Flg:Boolean):Decimal
    var
        SInvLine:record "Sales Invoice Line";
        GP:Decimal;
        Price:Decimal;
        Profits:Array[2] of Decimal;
    begin
        if Rec.Count = 0 then exit(0);
        Clear(Profits);
        SInvLine.CopyFilters(rec);
        If SInvLine.findset then
        repeat
            Clear(price);
            If SInvLine.Quantity > 0 then Price := SInvLine."Line Amount"/SInvLine.Quantity;
            GP := Price - SInvLine."Unit Cost";
            If flg then
            begin
                If Price > 0 then Profits[1] += GP/Price * 100;
            end        
            else
            Begin
                if  SInvLine."Unit Cost" > 0 then    
                    Profits[2] += GP/SInvLine."Unit Cost" * 100
                else
                    Profits[2] += 100;
            end;        
        until SInvLine.Next = 0;
        If flg then
            Exit(Profits[1]/SInvLine.Count)
        else
            exit(Profits[2]/SInvLine.Count);
    end;
    local procedure Get_Auto_Claim_Amount():Decimal;
    var
        SupReb:record "PC Supplier Brand Rebates";
    begin
        SupReb.Reset;
        SupReb.Setrange(Brand,Rec.Brand);
        If SupReb.Findset then Exit(Rec."Unit Cost" * Rec.Quantity * SupReb."Auto Order Rebate %"/100);    
        Exit(0);    
    end;

    trigger OnOpenPage()
    begin
        Clear(Postdate);
    end;
    var
        Supp:Code[20];
        reas:code[30];
        ReasLst:Text;
        Postdate:Array[2] of date;
        PstDate:date;
        Brd:Code[30];
        Claim:option All,Unclaimed,Claimed;
        RefMsg:text;
}