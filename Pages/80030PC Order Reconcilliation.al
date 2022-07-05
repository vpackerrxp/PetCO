page 80030 "PC Order Reconciliation"
{
    Caption = 'Order Reconciliation';
    PageType = Worksheet;
    SourceTable = "PC Order Reconciliations";
    InsertAllowed = false;
    DeleteAllowed = true;
    layout
    {
        area(content)
        {
            Group(Filters)
            {
                field("From Order Date Filter"; OrdDateFilter[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If OrdDateFilter[2] <> 0D then
                            if OrdDateFilter[1] > OrdDateFilter[2] then Clear(OrdDateFilter[1]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdDateFilter[1]);
                        SetFilters();
                    end;
                }
                field("To Order Date Filter"; OrdDateFilter[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If OrdDateFilter[1] <> 0D then
                            if OrdDateFilter[2] < OrdDateFilter[1] then Clear(OrdDateFilter[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdDateFilter[2]);
                        SetFilters();
                    end;
                }
                field("Order Types Filter";OrdType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(OrdType);
                        SetFilters();
                    end;
                }
                field("Payment Gate Way Filter";Payments)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Payments);
                        SetFilters();
                    end;
                }
                field("Apply Status Filter";ApplyStat)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(ApplyStat);
                        SetFilters();
                    end;
                }
                field("CL";'Clear All Filters')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = False;
                    trigger OnDrillDown()
                    begin
                        Clear(OrdDateFilter);
                        Clear(Payments);
                        Clear(ApplyStat);
                        Clear(OrdType);
                        Setfilters();
                    end;
                }
            }
            Group(Processing)
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
                field("imp";'Import&Process Data')
                {
                    ApplicationArea = All;
                    StyleExpr = 'strongaccent';
                    ShowCaption = False;
                    trigger OnDrillDown()
                    var
                        cu:Codeunit "PC Import Export Routines";
                    begin
                        If MFee <> '' then
                            Cu.Import_Reconcilliation(Mfee)
                        else
                            Message('Please provide the Merchant Fee Account');    
                        CurrPage.update(false);
                    end;
                }
                field("Merchant Fee Account";MFee)
                {
                    ApplicationArea = All;
                    StyleExpr = 'strong';
                    TableRelation = "G/L Account";
                }
                field("exp";'Export Data')
                {
                    ApplicationArea = All;
                    StyleExpr = 'favorable';
                    ShowCaption = False;
                    ToolTip = 'Exports Unapplied Records';
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "PC Import Export Routines";
                    begin
                        If (Payments <> Payments::All) AND (PSTDate <> 0D)
                        AND (ApplyStat = ApplyStat::UnApplied) Then
                        begin 
                            If Confirm(StrsubStno('Export Displayed Records Using Posting Date %1 And Payment Type %2 Now'
                                                ,PSTDate,Payments),True) then
                            begin
                                Cu.Export_Reconcilliation_Data(rec,PSTDate);
                                Clear(PSTDate);
                                SetFilters();
                            end 
                        end       
                        else
                            Message('Ensure Pay Type filter/Apply Type Filter and Posting Date are defined correctly');
                        CurrPage.update(false);
                    end;
                }
            }

            repeater(General)
            {
                field("Shopify Order ID"; Rec."Shopify Order ID")
                {
                    ApplicationArea = All;
                }
                field("Shopify Order Type"; Rec."Shopify Order Type")
                {
                    ApplicationArea = All;
                }
                field("Shopify Order No"; Rec."Shopify Order No")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        OrdHdr:record "PC Shopify Order Header";
                        PG:Page "PC Shopify Orders";
                    begin
                        OrdHdr.reset;
                        OrdHdr.Setrange("Shopify Order No.",Rec."Shopify Order No");
                        OrdHdr.Setrange("Order Type",Rec."Shopify Order Type");
                        If OrdHdr.findset then
                        begin
                            PG.SetTableView(OrdHdr);
                            Pg.Run;
                        end
                        else
                            Message('Order not found in downloaded Shopify orders')    
                    end;    
                }
                field("Shopify Order Date"; Rec."Shopify Order Date")
                {
                    ApplicationArea = All;
                }
                field("BC Reference No.";Get_BC_Document())
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        SinvHdr: Record "Sales Invoice Header";
                        SCrdHdr: Record "Sales Cr.Memo Header";
                        CustLedg:record "Cust. Ledger Entry";
                    begin
                        Case Strmenu('Show Document,Show Remaining Amount',1) of
                            1:
                            Begin
                                if SinvHdr.get(Get_BC_Document()) then
                                    Page.RunModal(Page::"Posted Sales Invoice", SinvHdr)
                                else if ScrdHdr.get(Get_BC_Document()) then
                                    Page.RunModal(Page::"Posted Sales Credit Memo", ScrdHdr);
                                CurrPage.update(false);
                            end;
                            2:
                            begin
                                CustLedg.reset;
                                CustLedg.Setrange("Document Type",CustLedg."Document Type"::Invoice);
                                If Rec."Shopify Order Type" = Rec."Shopify Order Type"::Refund then
                                    CustLedg.Setrange("Document Type",CustLedg."Document Type"::"Credit Memo");
                                CustLedg.Setrange("Document No.",Get_BC_Document());
                                iF CustLedg.FindSet() then
                                begin
                                    CustLedg.CalcFields("Remaining Amount");
                                    If Rec."Shopify Order Type" = Rec."Shopify Order Type"::Invoice then
                                        Message(StrsubStno('Invoice Remaining Amount = %1',CustLedg."Remaining Amount"))
                                    else
                                        Message(StrsubStno('CreditNote Remaining Amount = %1',ABS(CustLedg."Remaining Amount")));
                                end
                                Else
                                    Message('Document Not Found!');
                            end;        
                        end;
                    end;    
                }
                field("Payment Gate Way"; Rec."Payment Gate Way")
                {
                    ApplicationArea = All;
                }
                field("Reference No";rec."Reference No")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Order Total"; Rec."Order Total")
                {
                    ApplicationArea = All;
                }
                field("Apply Status"; Rec."Apply Status")
                {
                    ApplicationArea = All;
                    StyleExpr = Styler;
                }
            }
            Group(Totals)
            {
                field("Filtered Order Count"; Rec.Count)
                {
                    ApplicationArea = All;
                }
                field("Filtered Sales Totals";Get_Sales_Totals(true))
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Filtered Refund Totals";Get_Sales_Totals(false))
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Total CashApplied Sales";Get_Totals(true))
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Total Completed Sales";Get_Totals(false))
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Styler := 'strong';
        If rec."Apply Status" = rec."Apply Status"::CashApplied then
            Styler := 'strongaccent'
        else If rec."Apply Status" = rec."Apply Status"::Completed then
            Styler := 'favorable';
    end;

    trigger OnOpenPage()
    begin
        ApplyStat := ApplyStat::UnApplied;
        MFee := '519000';
        Setfilters();
    end;
    Local Procedure Get_BC_Document():Code[20]
    var
        OrdHdr:record "PC Shopify Order Header";
    begin
        OrdHdr.Reset();
        OrdHdr.Setrange("Shopify Order ID",rec."Shopify Order ID");
        OrdHdr.Setrange("Order Type",Rec."Shopify Order Type");
        If OrdHdr.FindSet() then
            Exit(OrdHdr."BC Reference No.");
        Exit('');    
    end;

    local procedure Get_Sales_Totals(Mode:Boolean):Decimal
    var
        buff:Record "PC Order Reconciliations";
    begin
        Buff.CopyFilters(Rec);
        If Mode then
            Buff.Setrange("Shopify Order Type",Buff."Shopify Order Type"::Invoice)
        else    
            Buff.Setrange("Shopify Order Type",Buff."Shopify Order Type"::refund);
        If Buff.findset then
        begin
            Buff.CalcSums("Order Total");
            exit(Buff."Order Total");
        end;        
        exit(0);    
    end;
    local procedure Get_Totals(Mode:Boolean):Decimal
    var
        buff:Record "PC Order Reconciliations";
    begin
        Buff.Reset;
        If Mode then
            Buff.Setrange("Apply Status",Buff."Apply Status"::CashApplied)
        else    
            Buff.Setrange("Apply Status",Buff."Apply Status"::Completed);
        If Buff.findset then
        begin
            Buff.CalcSums("Order Total");
            exit(Buff."Order Total");
        end;        
        exit(0);    
    end;
    Local procedure Setfilters()
    Begin
        Rec.Reset();
        If OrdType <> OrdType::All then
            Rec.SetRange("Shopify Order Type",OrdType - 1);
        if (OrdDateFilter[1] <> 0D) AND (OrdDateFilter[2] <> 0D) then
            rec.SetRange("Shopify Order Date", OrdDateFilter[1], OrdDateFilter[2])
        else if (OrdDateFilter[1] <> 0D) then
            rec.Setfilter("Shopify Order Date", '%1..', OrdDateFilter[1])
        else if (OrdDateFilter[2] <> 0D) then
            rec.Setfilter("Shopify Order Date", '..%1', OrdDateFilter[2]);
        If Payments <> Payments::All then
            Rec.Setrange("Payment Gate Way",Payments);    
        If ApplyStat <> ApplyStat::All then
            Rec.Setrange("Apply Status",ApplyStat - 1); 
        CurrPage.update(False);       
    End;
    var
        Payments:Option All,"Shopify Pay",Paypal,AfterPay,Zip,MarketPlace,Misc;
        OrdDateFilter:Array[2] of Date;
        ApplyStat:Option All,UnApplied,CashApplied,Complete;
        OrdType:Option All,Invoice,Refund;
        pstDate:Date;
        Styler:text;
        MFee:code[20];
}
