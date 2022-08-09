page 80024 "PC Shopify Order Recon"
{
    Caption = 'Shopify Order Reconciliation';
    PageType = Worksheet;
    UsageCategory = Tasks;
    ApplicationArea = All;
    SourceTable = "PC Shopify Order Header";
    InsertAllowed = false;
    //ModifyAllowed = false;
    //DeleteAllowed = false;
   
    layout
    {
        area(Content)
        {
            Group(Filters)
            {
                field("From Shopify Date Filter"; Recondate[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Recondate[2] <> 0D then
                            if Recondate[1] > Recondate[2] then Clear(Recondate[1]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Recondate[1]);
                        SetFilters();
                    end;
                }
                field("To Shopify Date Filter"; Recondate[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Recondate[1] <> 0D then
                            if Recondate[2] < Recondate[1] then Clear(Recondate[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Recondate[2]);
                        SetFilters();
                    end;
                }
                field("From Banking Date Filter"; Bankdate[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If BankDate[2] <> 0D then
                            if Bankdate[1] > Bankdate[2] then Clear(Bankdate[1]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Bankdate[1]);
                        SetFilters();
                    end;
                }
                field("From Banking Start Time Filter"; Banktime[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If BankTime[2] <> 0T then
                            if BankTime[1] > BankTime[2] then Clear(BankTime[1]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(BankTime[1]);
                        SetFilters();
                    end;
                }
                 field("To Banking Date Filter"; Bankdate[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Bankdate[1] <> 0D then
                            if Bankdate[2] < Bankdate[1] then Clear(Bankdate[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Bankdate[2]);
                        SetFilters();
                    end;
                }
               field("To Banking Start Time Filter"; BankTime[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If BankTime[1] <> 0T then
                            if BankTime[2] < BankTime[1] then Clear(BankTime[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(BankTime[2]);
                        SetFilters();
                    end;
                }
                  field("Payment Type Filter"; PayType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(PayType);
                        SetFilters();
                    end;
                }
                field("Transaction Type Filter"; TransType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(TransType);
                        SetFilters();
                    end;
                }
                field("Cash Receipts Filter"; Crec)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Crec);
                        SetFilters();
                    end;
                }
                 field("Invoice Applied Filter"; Inv)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Inv);
                        SetFilters();
                    end;
                }
               field("BC Order No Filter";BCORdNo)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(BCORdNo);
                        SetFilters();
                    end;
                }
                field("Shopify Order No Filter"; ordNo)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdNo);
                        SetFilters();
                    end;
                }
                field("Shopify Order ID Filter"; ordID)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdID);
                        SetFilters();
                    end;
                }
                Field("C";'Check Invoice Reconciliation')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        PAGE.RunModal(PAGE::"PC Check Inv Reconciliations");
                    end;    
                }
                  Field("Correction Value";CorrVal)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Confirm(StrSubstNo('Add Correction Value %1 Now',CorrVal),True) then
                        begin
                            If Not rec.get(0) then
                            begin
                                rec.init;
                                rec."Shopify Order ID" := 0;
                                Rec."BC Reference No." := 'CORRECTION';
                                Rec.insert;
                            end;
                            rec."Processed Date" := Today;
                            Rec."Processed Time" := Format(Time);
                            Rec."Cash Receipt Status" := Rec."Cash Receipt Status"::Applied;
                            Rec."Invoice Applied Status" := Rec."Invoice Applied Status"::Applied;
                            rec."Order Total" := Corrval;
                            rec."Order Type" := Rec."Order Type"::Invoice;
                            If Corrval < 0 then
                                rec."Order Type" := Rec."Order Type"::CreditMemo;
                            Rec.Modify;
                        end;    
                    end;    
                }
            }
            Group(Process)
            {
                Field("Receipt Posting Date";PstDate)
                {
                    Caption = 'Receipt Posting Date';
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        CurrPage.update(false);
                    end;    
                }
                Field("A";'Process Cash Receipts')
                {
                    ShowCaption = false;
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "PC Reconcillations";
                    begin
                        If (PayType <> PayType::" ") AND (PSTDate <> 0D) then
                        begin 
                            If Confirm(StrsubStno('Process Cash Receipts For Displayed Records Using Posting Date %1 Now',PSTDate),True) then
                            begin
                                Cu.Build_Cash_Receipts(rec,PSTDate);
                                Clear(PSTDate);
                                SetFilters();
                            end 
                        end       
                        else
                            Message('Select A Pay Type filter and Posting Date');
                        CurrPage.update(false);
                    end;
                 }
            }

            repeater(Group)
            {
                field("Shopify Order No.";rec."Shopify Order No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
 
                }
                field("Order Type";rec."Order Type")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Shopify Order Date";rec."Shopify Order Date")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Shopify Order Currency";rec."Shopify Order Currency")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Shopify Financial Status";rec."Shopify Financial Status")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Freight Total";rec."Freight Total")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Discount Total";rec."Discount Total")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Order Total";rec."Order Total")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Tax Total";rec."Tax Total")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("BC Reference No.";rec."BC Reference No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        SinvHdr:Record "Sales Invoice Header";
                        SCrdHdr:Record "Sales Cr.Memo Header";
                        SoHdr:Record "Sales Header";
                    begin
                        if SinvHdr.get(rec."BC Reference No.") then
                            Page.RunModal(Page::"Posted Sales Invoice",SinvHdr)
                        else if ScrdHdr.get(rec."BC Reference No.") then
                            Page.RunModal(Page::"Posted Sales Credit Memo",ScrdHdr)
                        else if SoHdr.get(Sohdr."Document Type"::"Credit Memo",rec."BC Reference No.") then
                            Page.RunModal(Page::"Sales Credit Memo",ScrdHdr)
                        else if SoHdr.get(Sohdr."Document Type"::"Invoice",rec."BC Reference No.") then
                            Page.RunModal(Page::"Sales Order",Sohdr);
                    end;
                    trigger OnAssistEdit()
                    var
                        SInv:Record "Sales Invoice Header";
                        SCrd:Record "Sales Cr.Memo Header";
                        BuffHdr:Record "PC Shopify Order Header";
                    begin
                        If (Rec."Order Type" = Rec."Order Type"::Invoice) 
                            And Not SInv.Get(rec."BC Reference No.") then
                       begin
                            If Confirm('Update Entry Now',True) then
                            begin
                                SInv.Reset;
                                Sinv.Setrange("Pre-assigned No.",Rec."BC Reference No.");
                                If Sinv.Findset then
                                begin
                                    BuffHdr.reset;
                                    BuffHdr.Setrange("BC Reference No.",Rec."BC Reference No.");
                                    If BuffHdr.Findset then
                                    begin
                                        BuffHdr.ModifyAll("BC Reference No.",SInv."No.",False);
                                        CurrPage.update(false);
                                    end;
                                end;       
                            end;
                        end;    
                        if (Rec."Order Type" = Rec."Order Type"::CreditMemo) 
                            And Not SCrd.Get(rec."BC Reference No.") then        
                        begin
                            If Confirm('Update Entry Now',True) then
                            begin
                                SCrd.Reset;
                                SCrd.Setrange("Pre-assigned No.",Rec."BC Reference No.");
                                If SCrd.Findset then
                                begin
                                    BuffHdr.reset;
                                    BuffHdr.Setrange("BC Reference No.",Rec."BC Reference No.");
                                    If BuffHdr.Findset then
                                    begin
                                        BuffHdr.ModifyAll("BC Reference No.",SCrd."No.",False);
                                        CurrPage.update(false);
                                    end;
                                end;       
                            end;
                        end;
                    end;    
                }
                field("Transaction Type";rec."Transaction Type")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                  }
                field("Payment Gate Way";rec."Payment Gate Way")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Processed Date";rec."Processed Date")
                {
                    ApplicationArea = All;
                    Caption = 'Banking Date';
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Processed Time";rec."Processed Time")
                {
                    ApplicationArea = All;
                    Caption = 'Banking Time';
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                  }
                field("Reference No.";rec."Reference No")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Shopify Order Id";rec."Shopify Order ID")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                 }
                field("Cash Receipts Status";rec."Cash Receipt Status")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    StyleExpr = rec."Cash Receipt Status" = rec."Cash Receipt Status"::Applied;
                }
                field("Invoice Applied Status";rec."Invoice Applied Status")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    StyleExpr = rec."Invoice Applied Status" = rec."Invoice Applied Status"::Applied;
                }
            }
            Group(Totals)
            {
                field("No of Orders";Rec.Count())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Sales Order Totals";Get_Sales_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Refund Order Totals";Get_Refund_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("BC Order Totals";Get_BC_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Expected Bank Total";Get_Sales_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Order Totals Unprocessed";Get_Unprocessed_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Process Cash Receipts")
            {
                ApplicationArea = All;
                trigger OnAction();
                var
                    Cu:Codeunit "PC Reconcillations";
                begin
                    If (PayType <> PayType::" ") AND (PSTDate <> 0D) then
                    begin 
                        If Confirm(StrsubStno('Process Cash Receipts For Displayed Records Using Posting Date %1 Now',PSTDate),True) then
                        begin
                            Cu.Build_Cash_Receipts(rec,PSTDate);
                            Clear(PSTDate);
                            SetFilters();
                        end 
                    end       
                    else
                        Message('Select A Pay Type filter and or Posting Date');
                end;
            }
        }
    }
    Local procedure Show_Order_Lines()
    var
        Pg: page "PC Shopify Order Lines";
        OrdL: Record "PC Shopify Order Lines";
    begin
        OrdL.reset;
        OrdL.Setrange(ShopifyID, rec.ID);
        If Ordl.FindSet() then begin
            Pg.SetTableView(OrdL);
            Pg.RunModal();
            CurrPage.update(false);
         end
        else
            Message('No Order Lines Exists');
    end;
    Local procedure Show_Shopify_Order()
    var 
        Pg:page  "PC Shopify Orders";
        OrdHdr:Record "PC Shopify Order Header";
    begin
        if OrDHdr.get(Rec.ID) then
        begin
            Pg.SetTableView(OrDHdr);
            Pg.RunModal();
        end
        else
            Message('No Order Exists');    
    end;
    local procedure Get_Sales_Totals():Decimal
    var
        buff:Record "PC Shopify Order Header";
    begin
        Buff.CopyFilters(Rec);
        If (TransType = TransType::" ") Or (TransType = TransType::sale) then
            Buff.Setrange("Transaction Type",'sale')
        else
            exit(0);    
        Buff.CalcSums("Order Total");
        //Buff.Calcsums("Tax Total");
        //Exit(Buff."Order Total" - Buff."Tax Total");  
        Exit(Buff."Order Total");
    end;
    local procedure Get_Refund_Totals():Decimal
    var
        buff:Record "PC Shopify Order Header";
                
    begin
        Buff.CopyFilters(Rec);
        Buff.SetFilter("BC Reference No.",'PCR*');
        Buff.CalcSums("Order Total");
        Buff.CalcSums("Tax Total");
        Exit(Buff."Order Total" + Buff."Tax Total");
        //Exit(Buff."Order Total");
    end;
    local procedure Get_BC_Totals():Decimal
    var
        Buff:record "PC Shopify Order Header";
        Tot:Decimal;
    begin
        Buff.CopyFilters(rec);    
        Buff.SetFilter("BC Reference No.",'INV*');
        Buff.CalcSums("Order Total");
        Tot := Buff."Order Total";
        Buff.CalcSums("Tax Total");
        Tot -= Buff."Tax Total";
        Buff.SetFilter("BC Reference No.",'PCR*');
        Buff.CalcSums("Order Total");
        Tot-= Buff."Order Total";
        Buff.CalcSums("Tax Total");
        Tot += Buff."Tax Total";
        If Buff.Get(0) then Tot+= Buff."Order Total";
        Exit(Tot);
    end;
    local procedure Get_Unprocessed_Totals():Decimal
    var
        Tot:Decimal;
    begin
        Tot := Get_Sales_Totals();
        If tot > 0 then Tot -= Get_BC_Totals();
        exit(Tot);
    end;
    local procedure SetFilters()
    begin
        rec.Reset;
        if (Recondate[1] <> 0D) AND (Recondate[2] <> 0D) then
            rec.SetRange("Shopify Order Date", Recondate[1], Recondate[2])
        else if (Recondate[1] <> 0D) then
            rec.Setfilter("Shopify Order Date", '%1..', Recondate[1])
        else if (Recondate[2] <> 0D) then
            rec.Setfilter("Shopify Order Date", '..%1', Recondate[2]);
        if (Bankdate[1] <> 0D) AND (Bankdate[2] <> 0D) then
            rec.SetRange("Processed Date", Bankdate[1], Bankdate[2])
        else if (Bankdate[1] <> 0D) then
            rec.Setfilter("Processed Date", '%1..', Bankdate[1])
        else if (Bankdate[2] <> 0D) then
            rec.Setfilter("Processed Date", '..%1', Bankdate[2]);
        if (BankTime[1] <> 0T) AND (BankTime[2] <> 0T) then
            rec.SetRange("Proc Time", BankTime[1],BankTime[2])
        else if (BankTime[1] <> 0T) then
            rec.Setfilter("Proc Time", '%1..',BankTime[1])
        else if (BankTime[2] <> 0T) then
            rec.Setfilter("Proc Time", '..%1',BankTime[2]);
        If Crec <> Crec::" "  then Rec.setrange("Cash Receipt Status",Crec -1);
        If Inv <> Inv::" "  then Rec.setrange("Invoice Applied Status",Inv -1);
        case TransType of
            TransType::sale: Rec.setrange("Transaction Type",'sale');
            TransType::refund: Rec.setrange("Transaction Type",'refund');
            TransType::promotion: Rec.setrange("Transaction Type",'promotion');
        end;
        case payType of
            PayType::wpay: Rec.setrange("Payment Gate Way",'wpay_gateway');
            payType::paypal: Rec.setrange("Payment Gate Way",'paypal');
            payType::after_pay: Rec.setfilter("Payment Gate Way",'afterpay|Afterpay');
            PayType::shopify_payments: Rec.SetFilter("Payment Gate Way",'shopify*');
            PayType::zip: Rec.Setfilter("Payment Gate Way",'zip*');
            PayType::market_place: Rec.SetFilter("Payment Gate Way",'market*');
            PayType::misc: Rec.setFilter("Payment Gate Way",'<>shopify*&<>wpay*&<>pay*&<>*fter*&<>zip*&<>market*');
        end;
        IF OrdNo <> 0 then rec.Setrange("Shopify Order No.",OrdNo);
        If OrdID <> 0 Then rec.Setrange("Shopify Order ID",OrdID);
        If BCORdNo <> '' then  Rec.SetRange("BC Reference No.",BCORdNo);
         Currpage.Update(False);
    end;
  
    var
        Recondate:Array[2] of Date;
        Bankdate:array[2] of date;
        BankTime:array[2] of time;
        Crec: option " ",UnApplied,Applied;
        Inv: option " ",UnApplied,Applied;
        TransType: option " ",sale,refund,promotion;
        PayType: option " ",wpay,shopify_payments,paypal,after_pay,zip,market_place,misc;
        OrdNo:Integer;
        OrdID:BigInteger;
        BCORdNo:Code[20];
        NAOrdFlg:Boolean;
        CorrVal:Decimal;
        PSTDate:Date;
}